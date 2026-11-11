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
    assert.deepEqual(open.json, { service: "gooby-sync", version: 1, keyRequired: true });
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
