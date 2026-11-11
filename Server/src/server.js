import http from "node:http";
import { createHash, randomBytes, scryptSync, timingSafeEqual } from "node:crypto";
import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const PORT = Number(process.env.PORT || process.env.GOOBY_PORT || 8080);
const SERVER_KEY = process.env.GOOBY_SERVER_KEY || "";
const DATA_PATH = process.env.GOOBY_DATA || path.join(process.cwd(), "data", "store.json");
const MAX_BLOB = Number(process.env.GOOBY_MAX_BLOB || 24 * 1024);
const BODY_LIMIT = Number(process.env.GOOBY_BODY_LIMIT || 96 * 1024);
const INVITE_TTL = Number(process.env.GOOBY_INVITE_TTL_MS || 72 * 60 * 60 * 1000);
const SLOT_TTL = Number(process.env.GOOBY_SLOT_TTL_MS || 14 * 24 * 60 * 60 * 1000);
const MAX_CHANNELS = Number(process.env.GOOBY_MAX_CHANNELS || 5000);
const MAX_INVITES = Number(process.env.GOOBY_MAX_INVITES || 2000);
const MAX_SLOTS = 4;
const RATE_LIMIT = Number(process.env.GOOBY_RATE_PER_MINUTE || 180);
const MAX_ACCOUNT_BLOB = Number(process.env.GOOBY_MAX_ACCOUNT_BLOB || 8 * 1024 * 1024);
const ACCOUNT_BODY = Number(process.env.GOOBY_ACCOUNT_BODY || 12 * 1024 * 1024);
const MAX_ACCOUNTS = Number(process.env.GOOBY_MAX_ACCOUNTS || 500);

const state = { channels: {}, invites: {}, accounts: {}, names: {}, sessions: {} };
const hits = new Map();
let chain = Promise.resolve();

function locked(work) {
  const run = chain.then(work, work);
  chain = run.then(
    () => {},
    () => {}
  );
  return run;
}

function send(res, status, payload) {
  const body = payload === undefined ? "" : JSON.stringify(payload);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "Content-Length": Buffer.byteLength(body),
  });
  res.end(body);
}

function fail(res, status, error) {
  send(res, status, { error });
}

function same(left, right) {
  const a = Buffer.from(left);
  const b = Buffer.from(right);
  if (a.length !== b.length || a.length === 0) return false;
  return timingSafeEqual(a, b);
}

function authorized(req) {
  if (!SERVER_KEY) return true;
  return same(req.headers["x-gooby-key"] || "", SERVER_KEY);
}

function bearer(req) {
  const header = req.headers.authorization || "";
  const match = /^Bearer ([0-9a-f]{64})$/i.exec(header);
  return match ? match[1].toLowerCase() : "";
}

function hex(value, size) {
  return new RegExp(`^[0-9a-f]{${size}}$`, "i").test(value || "");
}

function decodeBlob(value, max = MAX_BLOB) {
  if (typeof value !== "string" || value.length === 0 || value.length > max * 2 + 16) return null;
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(value)) return null;
  const bytes = Buffer.from(value, "base64");
  if (bytes.length === 0 || bytes.length > max) return null;
  return bytes.toString("base64");
}

function limited(req) {
  const now = Date.now();
  const key = req.socket.remoteAddress || "local";
  const row = hits.get(key);
  if (!row || now - row.start >= 60_000) {
    hits.set(key, { start: now, count: 1 });
    return false;
  }
  row.count += 1;
  return row.count > RATE_LIMIT;
}

function prune(now = Date.now()) {
  for (const [id, channel] of Object.entries(state.channels)) {
    for (const [slot, row] of Object.entries(channel.slots)) {
      if (now - row.at > SLOT_TTL) delete channel.slots[slot];
    }
    if (Object.keys(channel.slots).length === 0 && now - channel.touched > SLOT_TTL) {
      delete state.channels[id];
    }
  }
  for (const [id, invite] of Object.entries(state.invites)) {
    if (now - invite.at > INVITE_TTL) delete state.invites[id];
  }
  const channels = Object.entries(state.channels).sort((a, b) => a[1].touched - b[1].touched);
  while (channels.length > MAX_CHANNELS) {
    const [id] = channels.shift();
    delete state.channels[id];
  }
  const invites = Object.entries(state.invites).sort((a, b) => a[1].at - b[1].at);
  while (invites.length > MAX_INVITES) {
    const [id] = invites.shift();
    delete state.invites[id];
  }
}

async function persist() {
  prune();
  await mkdir(path.dirname(DATA_PATH), { recursive: true });
  const tmp = `${DATA_PATH}.tmp`;
  await writeFile(tmp, JSON.stringify(state));
  await rename(tmp, DATA_PATH);
}

async function load() {
  try {
    const parsed = JSON.parse(await readFile(DATA_PATH, "utf8"));
    state.channels = parsed.channels && typeof parsed.channels === "object" ? parsed.channels : {};
    state.invites = parsed.invites && typeof parsed.invites === "object" ? parsed.invites : {};
    state.accounts = parsed.accounts && typeof parsed.accounts === "object" ? parsed.accounts : {};
    state.names = parsed.names && typeof parsed.names === "object" ? parsed.names : {};
    state.sessions = parsed.sessions && typeof parsed.sessions === "object" ? parsed.sessions : {};
  } catch (error) {
    if (error.code !== "ENOENT") {
      console.error(`gooby-sync store unreadable, starting empty: ${error.message}`);
    }
  }
}

function readBody(req, limit = BODY_LIMIT) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    let failed = false;
    req.on("data", (chunk) => {
      size += chunk.length;
      if (size > limit) {
        failed = true;
        reject(Object.assign(new Error("too_big"), { status: 413 }));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on("end", () => {
      if (!failed) resolve(Buffer.concat(chunks));
    });
    req.on("error", (error) => {
      if (!failed) reject(error);
    });
  });
}

async function jsonBody(req, limit = BODY_LIMIT) {
  const raw = await readBody(req, limit);
  if (raw.length === 0) return {};
  return JSON.parse(raw.toString("utf8"));
}

function info() {
  return { service: "gooby-sync", version: 1, keyRequired: SERVER_KEY.length > 0, accounts: true };
}

function listSlots(channelID, token) {
  const channel = state.channels[channelID];
  if (!channel) return { slots: [] };
  if (!same(channel.tokenHash, createHash("sha256").update(token).digest("hex"))) {
    return { error: "forbidden" };
  }
  channel.touched = Date.now();
  const slots = Object.entries(channel.slots).map(([slot, row]) => ({
    slot,
    blob: row.blob,
    at: row.at,
  }));
  return { slots };
}

function writeSlot(channelID, slot, token, blob) {
  const tokenHash = createHash("sha256").update(token).digest("hex");
  let channel = state.channels[channelID];
  if (!channel) {
    channel = { tokenHash, touched: Date.now(), slots: {} };
    state.channels[channelID] = channel;
  } else if (!same(channel.tokenHash, tokenHash)) {
    return { error: "forbidden" };
  }
  channel.touched = Date.now();
  channel.slots[slot] = { blob, at: Date.now() };
  const extra = Object.entries(channel.slots).sort((a, b) => a[1].at - b[1].at);
  while (extra.length > MAX_SLOTS) {
    const [old] = extra.shift();
    delete channel.slots[old];
  }
  return { ok: true };
}

function normalizeName(name) {
  return String(name || "").trim().toLowerCase();
}

function isUUID(value) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value || "");
}

function hashPassword(password) {
  const salt = randomBytes(16);
  const hash = scryptSync(password, salt, 32);
  return `scrypt$${salt.toString("base64")}$${hash.toString("base64")}`;
}

function checkPassword(password, stored) {
  const parts = String(stored || "").split("$");
  if (parts.length !== 3 || parts[0] !== "scrypt") return false;
  const salt = Buffer.from(parts[1], "base64");
  const expected = Buffer.from(parts[2], "base64");
  if (salt.length === 0 || expected.length === 0) return false;
  const hash = scryptSync(password, salt, expected.length);
  if (hash.length !== expected.length) return false;
  return timingSafeEqual(hash, expected);
}

function sessionHash(token) {
  return createHash("sha256").update(token).digest("hex");
}

function accountFor(req) {
  const token = bearer(req);
  if (!token) return null;
  const id = state.sessions[sessionHash(token)];
  return id ? state.accounts[id] : null;
}

function createAccount(name, password, memberId) {
  const display = String(name || "").trim();
  const key = normalizeName(display);
  if (key.length < 1 || key.length > 80) return { error: "name", status: 400 };
  if (typeof password !== "string" || password.length < 8 || password.length > 200) {
    return { error: "password", status: 400 };
  }
  if (!isUUID(memberId)) return { error: "member", status: 400 };
  if (state.names[key]) return { error: "exists", status: 409 };
  if (Object.keys(state.accounts).length >= MAX_ACCOUNTS) return { error: "busy", status: 429 };
  const id = randomBytes(16).toString("hex");
  const token = randomBytes(32).toString("hex");
  const hash = sessionHash(token);
  state.accounts[id] = {
    name: display,
    passwordHash: hashPassword(password),
    memberId,
    bundle: { revision: 0 },
    sessions: [hash],
  };
  state.names[key] = id;
  state.sessions[hash] = id;
  return { accountId: id, memberId, token };
}

function openSession(name, password) {
  const id = state.names[normalizeName(name)];
  const account = id && state.accounts[id];
  if (!account || typeof password !== "string" || !checkPassword(password, account.passwordHash)) {
    return { error: "password", status: 401 };
  }
  const token = randomBytes(32).toString("hex");
  const hash = sessionHash(token);
  account.sessions.push(hash);
  while (account.sessions.length > 8) {
    const old = account.sessions.shift();
    delete state.sessions[old];
  }
  state.sessions[hash] = id;
  return { accountId: id, memberId: account.memberId, token };
}

function closeSession(token) {
  if (!token) return false;
  const hash = sessionHash(token);
  const id = state.sessions[hash];
  if (!id) return false;
  delete state.sessions[hash];
  const account = state.accounts[id];
  if (account) account.sessions = account.sessions.filter((item) => item !== hash);
  return true;
}

function accountDocument(account) {
  const bundle = account.bundle || { revision: 0 };
  if (!bundle.blob) return { revision: bundle.revision || 0 };
  return { revision: bundle.revision, blob: bundle.blob };
}

function writeAccount(account, revision, blob) {
  const current = account.bundle?.revision || 0;
  if (revision !== current + 1) {
    const doc = accountDocument(account);
    return { conflict: true, revision: doc.revision, blob: doc.blob };
  }
  account.bundle = { revision, blob, at: Date.now() };
  return { revision };
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url || "/", "http://localhost");
  const parts = url.pathname.split("/").filter(Boolean);
  locked(async () => {
    if (limited(req)) return fail(res, 429, "busy");
    if (req.method === "GET" && (url.pathname === "/" || url.pathname === "/v1/info")) {
      return send(res, 200, info());
    }
    if (!authorized(req)) return fail(res, 401, "key");
    try {
      if (req.method === "GET" && parts[0] === "v1" && parts[1] === "channels" && parts.length === 3) {
        if (!hex(parts[2], 64)) return fail(res, 400, "channel");
        const token = bearer(req);
        if (!token) return fail(res, 400, "token");
        const listed = listSlots(parts[2].toLowerCase(), token);
        if (listed.error) return fail(res, 403, listed.error);
        return send(res, 200, listed);
      }
      if (req.method === "PUT" && parts[0] === "v1" && parts[1] === "channels" && parts.length === 4) {
        if (!hex(parts[2], 64) || !hex(parts[3], 32)) return fail(res, 400, "channel");
        const token = bearer(req);
        if (!token) return fail(res, 400, "token");
        const body = await jsonBody(req);
        const blob = decodeBlob(body.blob);
        if (!blob) return fail(res, 413, "blob");
        const written = writeSlot(parts[2].toLowerCase(), parts[3].toLowerCase(), token, blob);
        if (written.error) return fail(res, 403, written.error);
        await persist();
        return send(res, 204);
      }
      if (req.method === "POST" && parts[0] === "v1" && parts[1] === "invites" && parts.length === 2) {
        const body = await jsonBody(req);
        if (!hex(body.id, 64)) return fail(res, 400, "invite");
        const blob = decodeBlob(body.blob);
        if (!blob) return fail(res, 413, "blob");
        const id = body.id.toLowerCase();
        const existing = state.invites[id];
        if (existing && Date.now() - existing.at <= INVITE_TTL) return fail(res, 409, "exists");
        state.invites[id] = { blob, at: Date.now() };
        await persist();
        return send(res, 201, { ok: true });
      }
      if (req.method === "POST" && parts[0] === "v1" && parts[1] === "accounts" && parts.length === 2) {
        const body = await jsonBody(req);
        const created = createAccount(body.name, body.password, body.memberId);
        if (created.error) return fail(res, created.status, created.error);
        await persist();
        return send(res, 201, {
          accountId: created.accountId,
          memberId: created.memberId,
          token: created.token,
        });
      }
      if (req.method === "POST" && parts[0] === "v1" && parts[1] === "sessions" && parts.length === 2) {
        const body = await jsonBody(req);
        const session = openSession(body.name, body.password);
        if (session.error) return fail(res, session.status, session.error);
        await persist();
        return send(res, 200, {
          accountId: session.accountId,
          memberId: session.memberId,
          token: session.token,
        });
      }
      if (req.method === "DELETE" && parts[0] === "v1" && parts[1] === "sessions" && parts.length === 2) {
        if (!closeSession(bearer(req))) return fail(res, 401, "session");
        await persist();
        return send(res, 204);
      }
      if (req.method === "GET" && parts[0] === "v1" && parts[1] === "account" && parts.length === 2) {
        const account = accountFor(req);
        if (!account) return fail(res, 401, "session");
        return send(res, 200, accountDocument(account));
      }
      if (req.method === "PUT" && parts[0] === "v1" && parts[1] === "account" && parts.length === 2) {
        const account = accountFor(req);
        if (!account) return fail(res, 401, "session");
        const body = await jsonBody(req, ACCOUNT_BODY);
        const blob = decodeBlob(body.blob, MAX_ACCOUNT_BLOB);
        if (!blob || !Number.isInteger(body.revision) || body.revision < 1) return fail(res, 400, "blob");
        const written = writeAccount(account, body.revision, blob);
        if (written.conflict) {
          return send(res, 409, { error: "conflict", revision: written.revision, blob: written.blob });
        }
        await persist();
        return send(res, 200, { revision: written.revision });
      }
      if (req.method === "POST" && parts[0] === "v1" && parts[1] === "invites" && parts[3] === "claim" && parts.length === 4) {
        if (!hex(parts[2], 64)) return fail(res, 400, "invite");
        await jsonBody(req);
        const id = parts[2].toLowerCase();
        const invite = state.invites[id];
        if (!invite || Date.now() - invite.at > INVITE_TTL) {
          if (invite) delete state.invites[id];
          return fail(res, 404, "missing");
        }
        delete state.invites[id];
        await persist();
        return send(res, 200, { blob: invite.blob });
      }
      return fail(res, 404, "not_found");
    } catch (error) {
      if (error.status === 413) return fail(res, 413, "blob");
      return fail(res, 400, "bad_request");
    }
  }).catch(() => {
    if (!res.headersSent) fail(res, 500, "failed");
  });
});

const isMain = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
  await load();
  server.listen(PORT, "0.0.0.0", () => {
    const address = server.address();
    const port = address && typeof address === "object" ? address.port : PORT;
    console.log(`gooby-sync listening on ${port}`);
  });
}
