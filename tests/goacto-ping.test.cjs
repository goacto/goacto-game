const { test } = require("node:test");
const assert = require("node:assert/strict");
const { sendDailyPing } = require("../build/web/goacto-ping.js");
const mem = () => { const m = new Map(); return { getItem: (k) => m.get(k) ?? null, setItem: (k, v) => m.set(k, v), removeItem: (k) => m.delete(k) }; };

test("one mindscape ping per local day, minimal body, CORS, no credentials", async () => {
  const calls = [];
  const env = { storage: mem(), gpc: false, uuid: () => "6f1c2a0e-5b7d-4c1a-9e2f-3a4b5c6d7e8f", now: () => new Date(2026, 9, 15, 9),
    fetch: async (u, o) => { calls.push([u, o]); return { ok: true }; } };
  assert.equal(await sendDailyPing("mindscape", env), true);
  assert.equal(await sendDailyPing("mindscape", env), false);
  assert.equal(calls.length, 1);
  assert.equal(calls[0][0], "https://siagentspace.com/api/ping");
  assert.deepEqual(JSON.parse(calls[0][1].body), { v: 1, app: "mindscape", day: "2026-10-15", aid: "6f1c2a0e-5b7d-4c1a-9e2f-3a4b5c6d7e8f", first: true });
  assert.equal(calls[0][1].credentials, "omit");
});
test("opt-out (Settings > Privacy) or GPC sends nothing", async () => {
  let n = 0; const f = async () => { n++; return { ok: true }; };
  const s = mem(); s.setItem("goacto:usage-optout:v1", "1");
  assert.equal(await sendDailyPing("mindscape", { storage: s, fetch: f, gpc: false }), false);
  assert.equal(await sendDailyPing("mindscape", { storage: mem(), fetch: f, gpc: true }), false);
  assert.equal(n, 0);
});
test("network failure never throws", async () => {
  assert.equal(await sendDailyPing("mindscape", { storage: mem(), gpc: false, uuid: () => "x", fetch: async () => { throw new Error("offline"); } }), false);
});
