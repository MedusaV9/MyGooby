import http from "node:http";
import { createHash, timingSafeEqual } from "node:crypto";
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

const state = { channels: {}, invites: {} };
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

function decodeBlob(value) {
  if (typeof value !== "string" || value.length === 0 || value.length > BODY_LIMIT) return null;
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(value)) return null;
  const bytes = Buffer.from(value, "base64");
  if (bytes.length === 0 || bytes.length > MAX_BLOB) return null;
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
  } catch (error) {
    if (error.code !== "ENOENT") {
      console.error(`gooby-sync store unreadable, starting empty: ${error.message}`);
    }
  }
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    let failed = false;
    req.on("data", (chunk) => {
      size += chunk.length;
      if (size > BODY_LIMIT) {
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

async function jsonBody(req) {
  const raw = await readBody(req);
  if (raw.length === 0) return {};
  return JSON.parse(raw.toString("utf8"));
}

function info() {
  return { service: "gooby-sync", version: 1, keyRequired: SERVER_KEY.length > 0 };
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
