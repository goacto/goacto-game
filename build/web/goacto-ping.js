/* GOACTO first-party daily ping for Mindscape web (REQ v0.3.1 §4.6). Same rules as sdk/goacto-ping.ts:
 * at most one anonymous ping per app per device per local day; no cookies; skips on opt-out
 * (localStorage goacto:usage-optout:v1 = "1", set from Settings > Privacy) or Global Privacy Control. */
(function (root) {
  "use strict";
  var AID = "goacto:aid:v1", OPT_OUT = "goacto:usage-optout:v1";
  function pad(n) { return String(n).padStart(2, "0"); }
  function localDay(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()); }
  function sendDailyPing(app, env) {
    try {
      var nav = root.navigator || {};
      var gpc = env.gpc != null ? env.gpc : nav.globalPrivacyControl === true;
      var s = env.storage;
      if (gpc || s.getItem(OPT_OUT) === "1") return Promise.resolve(false);
      var day = localDay(env.now ? env.now() : new Date());
      var key = "goacto:ping-day:v1:" + app;
      if (s.getItem(key) === day) return Promise.resolve(false);
      var aid = s.getItem(AID), first = !aid;
      if (!aid) { aid = (env.uuid || function () { return root.crypto.randomUUID(); })(); s.setItem(AID, aid); }
      s.setItem(key, day);
      return env.fetch(env.endpoint || "https://siagentspace.com/api/ping", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ v: 1, app: app, day: day, aid: aid, first: first }),
        keepalive: true, credentials: "omit", mode: "cors"
      }).then(function (r) { return !!r.ok; }, function () { return false; });
    } catch (e) { return Promise.resolve(false); }
  }
  var api = { sendDailyPing: sendDailyPing };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else {
    root.goactoUsage = api;
    try { sendDailyPing("mindscape", { storage: root.localStorage, fetch: root.fetch.bind(root) }); } catch (e) {}
  }
})(typeof window !== "undefined" ? window : globalThis);
