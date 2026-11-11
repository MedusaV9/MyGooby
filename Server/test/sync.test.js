import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

function blob(text) {
  return Buffer.from(text).toString("base64");
}

async function boot(extra = {}) {
  const preset = extra.GOOBY_DATA;
  const dir = preset ? path.dirname(preset) : await mkdtemp(path.join(tmpdir(), "gooby-sync-"));
  const child = spawn(process.execPath, ["src/server.js"], {
    cwd: root,
    env: {
      ...process.env,
      PORT: "0",
      GOOBY_PORT: "0",
      GOOBY_DATA: preset || path.join(dir, "store.json"),
      GOOBY_SERVER_KEY: "test-key",
      ...extra,
    },
    stdio: ["ignore", "pipe", "pipe"],
  });
  let logs = "";
  child.stdout.on("data", (chunk) => {
    logs += chunk.toString();
  });
  child.stderr.on("data", (chunk) => {
    logs += chunk.toString();
  });
  const port = await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(logs || "server did not start")), 8000);
    child.stdout.on("data", () => {
      const match = logs.match(/listening on (\d+)/);
      if (!match) return;
      clearTimeout(timer);
      resolve(Number(match[1]));
    });
    child.on("exit", (code) => {
      clearTimeout(timer);
      reject(new Error(`server exited ${code}: ${logs}`));
    });
  });
  return {
    base: `http://127.0.0.1:${port}`,
    file: path.join(dir, "store.json"),
    async stop(options = {}) {
      child.kill("SIGTERM");
      await new Promise((resolve) => child.once("exit", resolve));
      if (!options.keep) await rm(dir, { recursive: true, force: true });
    },
  };
}

async function call(base, route, { method = "GET", key = "test-key", token, body, raw } = {}) {
  const headers = { Accept: "application/json" };
  if (key) headers["X-Gooby-Key"] = key;
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body !== undefined) {
    headers["Content-Type"] = "application/json";
    raw = JSON.stringify(body);
  }
  const response = await fetch(`${base}${route}`, { method, headers, body: raw });
  const text = await response.text();
  let json = null;
  if (text) {
    try {
      json = JSON.parse(text);
    } catch {
      json = text;
    }
  }
  return { status: response.status, json };
}

const channel = "ab".repeat(32);
const other = "cd".repeat(32);
const token = "11".repeat(32);
const slotA = "aa".repeat(16);
const slotB = "bb".repeat(16);

test("info is public and names the service", async () => {
  const server = await boot();
  try {
    const open = await call(server.base, "/v1/info", { key: "" });
    assert.equal(open.status, 200);
    assert.deepEqual(open.json, { service: "gooby-sync", version: 1, keyRequired: true, accounts: true });
    const missing = await call(server.base, `/v1/channels/${channel}`, { key: "" });
    assert.equal(missing.status, 401);
    const wrong = await call(server.base, `/v1/channels/${channel}`, { key: "nope", token });
    assert.equal(wrong.status, 401);
  } finally {
    await server.stop();
  }
});

test("two friends exchange sealed blobs and a stranger is refused", async () => {
  const server = await boot();
  try {
    const empty = await call(server.base, `/v1/channels/${channel}`, { token });
    assert.equal(empty.status, 200);
    assert.deepEqual(empty.json.slots, []);
    const putA = await call(server.base, `/v1/channels/${channel}/${slotA}`, {
      method: "PUT",
      token,
      body: { blob: blob("sealed-envelope-a") },
    });
    assert.equal(putA.status, 204);
    const putB = await call(server.base, `/v1/channels/${channel}/${slotB}`, {
      method: "PUT",
      token,
      body: { blob: blob("sealed-envelope-b") },
    });
    assert.equal(putB.status, 204);
    const listed = await call(server.base, `/v1/channels/${channel}`, { token });
    assert.equal(listed.status, 200);
    const bySlot = Object.fromEntries(listed.json.slots.map((row) => [row.slot, row.blob]));
    assert.equal(Buffer.from(bySlot[slotA], "base64").toString(), "sealed-envelope-a");
    assert.equal(Buffer.from(bySlot[slotB], "base64").toString(), "sealed-envelope-b");
    const stranger = await call(server.base, `/v1/channels/${channel}`, { token: "22".repeat(32) });
    assert.equal(stranger.status, 403);
    const stored = await readFile(server.file, "utf8");
    assert.equal(stored.includes("sealed-envelope-a"), false);
    assert.match(stored, new RegExp(slotA));
  } finally {
    await server.stop();
  }
});

test("a channel survives a restart", async () => {
  const server = await boot();
  try {
    const put = await call(server.base, `/v1/channels/${channel}/${slotA}`, {
      method: "PUT",
      token,
      body: { blob: blob("still-here") },
    });
    assert.equal(put.status, 204);
    await server.stop({ keep: true });
  } catch (error) {
    await server.stop();
    throw error;
  }
  const again = await boot({ GOOBY_DATA: server.file });
  try {
    const listed = await call(again.base, `/v1/channels/${channel}`, { token });
    assert.equal(listed.status, 200);
    assert.equal(Buffer.from(listed.json.slots[0].blob, "base64").toString(), "still-here");
    const refused = await call(again.base, `/v1/channels/${channel}/${slotB}`, {
      method: "PUT",
      token: "33".repeat(32),
      body: { blob: blob("nope") },
    });
    assert.equal(refused.status, 403);
  } finally {
    await again.stop();
  }
});

test("an invite can be claimed once", async () => {
  const server = await boot();
  try {
    const id = "ee".repeat(32);
    const created = await call(server.base, "/v1/invites", {
      method: "POST",
      body: { id, blob: blob("sealed-invite") },
    });
    assert.equal(created.status, 201);
    const again = await call(server.base, "/v1/invites", {
      method: "POST",
      body: { id, blob: blob("sealed-invite") },
    });
    assert.equal(again.status, 409);
    const claimed = await call(server.base, `/v1/invites/${id}/claim`, {
      method: "POST",
      body: {},
    });
    assert.equal(claimed.status, 200);
    assert.equal(Buffer.from(claimed.json.blob, "base64").toString(), "sealed-invite");
    const second = await call(server.base, `/v1/invites/${id}/claim`, {
      method: "POST",
      body: {},
    });
    assert.equal(second.status, 404);
  } finally {
    await server.stop();
  }
});

test("an expired invite cannot be claimed", async () => {
  const server = await boot({ GOOBY_INVITE_TTL_MS: "400" });
  try {
    const id = "ff".repeat(32);
    const created = await call(server.base, "/v1/invites", {
      method: "POST",
      body: { id, blob: blob("old-invite") },
    });
    assert.equal(created.status, 201);
    await new Promise((resolve) => setTimeout(resolve, 700));
    const claimed = await call(server.base, `/v1/invites/${id}/claim`, {
      method: "POST",
      body: {},
    });
    assert.equal(claimed.status, 404);
  } finally {
    await server.stop();
  }
});

test("oversized and malformed writes are rejected", async () => {
  const server = await boot({ GOOBY_MAX_BLOB: "8" });
  try {
    const big = await call(server.base, `/v1/channels/${other}/${slotA}`, {
      method: "PUT",
      token,
      body: { blob: blob("123456789") },
    });
    assert.equal(big.status, 413);
    const bad = await call(server.base, `/v1/channels/not-hex/${slotA}`, {
      method: "PUT",
      token,
      body: { blob: blob("x") },
    });
    assert.equal(bad.status, 400);
  } finally {
    await server.stop();
  }
});

test("accounts keep one save per person and share it across sessions", async () => {
  const server = await boot();
  const member = "11111111-1111-4111-8111-111111111111";
  try {
    const locked = await call(server.base, "/v1/accounts", {
      method: "POST",
      key: "",
      body: { name: "Ada", password: "correct-horse", memberId: member },
    });
    assert.equal(locked.status, 401);
    assert.equal(locked.json.error, "key");
    const created = await call(server.base, "/v1/accounts", {
      method: "POST",
      body: { name: "Ada", password: "correct-horse", memberId: member },
    });
    assert.equal(created.status, 201);
    assert.equal(created.json.memberId, member);
    const again = await call(server.base, "/v1/accounts", {
      method: "POST",
      body: { name: "ada", password: "correct-horse", memberId: member },
    });
    assert.equal(again.status, 409);
    assert.equal(again.json.error, "exists");
    const bad = await call(server.base, "/v1/sessions", {
      method: "POST",
      body: { name: "Ada", password: "wrong-password" },
    });
    assert.equal(bad.status, 401);
    assert.equal(bad.json.error, "password");
    const second = await call(server.base, "/v1/sessions", {
      method: "POST",
      body: { name: "Ada", password: "correct-horse" },
    });
    assert.equal(second.status, 200);
    assert.equal(second.json.memberId, member);
    assert.notEqual(second.json.token, created.json.token);
    const other = await call(server.base, "/v1/accounts", {
      method: "POST",
      body: {
        name: "Bea",
        password: "another-pass",
        memberId: "22222222-2222-4222-8222-222222222222",
      },
    });
    assert.equal(other.status, 201);
    const payload = blob("same-envelope-and-save");
    const put = await call(server.base, "/v1/account", {
      method: "PUT",
      token: created.json.token,
      body: { revision: 1, blob: payload },
    });
    assert.equal(put.status, 200);
    assert.equal(put.json.revision, 1);
    const pulled = await call(server.base, "/v1/account", { token: second.json.token });
    assert.equal(pulled.status, 200);
    assert.equal(pulled.json.revision, 1);
    assert.equal(Buffer.from(pulled.json.blob, "base64").toString(), "same-envelope-and-save");
    const stranger = await call(server.base, "/v1/account", { token: other.json.token });
    assert.equal(stranger.status, 200);
    assert.equal(stranger.json.revision, 0);
    assert.equal(stranger.json.blob, undefined);
    const clash = await call(server.base, "/v1/account", {
      method: "PUT",
      token: second.json.token,
      body: { revision: 1, blob: blob("older") },
    });
    assert.equal(clash.status, 409);
    assert.equal(clash.json.error, "conflict");
    assert.equal(clash.json.revision, 1);
    assert.equal(Buffer.from(clash.json.blob, "base64").toString(), "same-envelope-and-save");
    const next = await call(server.base, "/v1/account", {
      method: "PUT",
      token: second.json.token,
      body: { revision: 2, blob: blob("newer-save") },
    });
    assert.equal(next.status, 200);
    const stored = await readFile(server.file, "utf8");
    assert.equal(stored.includes("correct-horse"), false);
    assert.equal(stored.includes("another-pass"), false);
    assert.match(stored, /scrypt\$/);
    const bye = await call(server.base, "/v1/sessions", { method: "DELETE", token: second.json.token });
    assert.equal(bye.status, 204);
    const gone = await call(server.base, "/v1/account", { token: second.json.token });
    assert.equal(gone.status, 401);
    assert.equal(gone.json.error, "session");
    const still = await call(server.base, "/v1/account", { token: created.json.token });
    assert.equal(still.status, 200);
    assert.equal(Buffer.from(still.json.blob, "base64").toString(), "newer-save");
  } finally {
    await server.stop();
  }
});
