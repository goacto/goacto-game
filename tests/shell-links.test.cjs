const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const html = fs.readFileSync(path.join(__dirname, "../build/web/index.html"), "utf8");

const FOCUS_URL = "https://focus.goacto.com";
const GUIDE_URL = "https://goacto.com/pages/atomic-habits";
const FOCUS_LINE = "Mindscape: practice focus as a short browser game. Want a simple daily focus tracker? Try Focus Log.";

function anchors(source) {
  return source.match(/<a\b[^>]*>[\s\S]*?<\/a>/gi) || [];
}

function attr(tag, name) {
  const m = tag.match(new RegExp("\\b" + name + "\\s*=\\s*[\"']([^\"']*)[\"']", "i"));
  return m ? m[1] : "";
}

function text(tag) {
  return tag.replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim();
}

function tagHidden(tag) {
  return /\bhidden\b/i.test(tag.split(">")[0]) || /display\s*:\s*none/i.test(tag) || /aria-hidden\s*=\s*["']true["']/i.test(tag);
}

function cssHides(source, id) {
  const re = new RegExp("#" + id + "\\s*\\{[^}]*\\}", "g");
  let m;
  while ((m = re.exec(source))) {
    if (/display\s*:\s*none/i.test(m[0])) return true;
  }
  return false;
}

test("Focus Log link and free book guide stay visible in the web shell", () => {
  const desc = html.match(/<meta\s+name="description"\s+content="([^"]*)"/i);
  assert.ok(desc, "meta description missing");
  assert.ok(desc[1].includes(FOCUS_LINE), "meta description dropped the Focus Log line");
  assert.ok(desc[1].includes("Growing Ourselves and Contributing To Others"), "mission line must keep 'and'");

  const focus = anchors(html).filter((a) => attr(a, "href").replace(/\/$/, "") === FOCUS_URL);
  assert.equal(focus.length, 1, "Focus Log link missing from the shell");
  assert.equal(tagHidden(focus[0]), false, "Focus Log link must stay visible");
  assert.equal(cssHides(html, "focus-log-diff"), false, "Focus Log line must stay visible");
  assert.equal(text(focus[0]), "Focus Log");
  assert.ok(html.includes(FOCUS_LINE.replace("Focus Log.", "")), "Focus Log sentence missing from the shell");

  const guide = anchors(html).filter((a) => attr(a, "href").replace(/\/$/, "") === GUIDE_URL);
  assert.equal(guide.length, 1, "free book guide link missing from the shell");
  assert.equal(tagHidden(guide[0]), false, "free book guide link must stay visible");
  assert.equal(cssHides(html, "book-guide"), false, "free book guide link must stay visible");
  assert.equal(cssHides(html, "shell-footer"), false, "book guide footer must stay visible");
  assert.equal(text(guide[0]), "Free one-page book guide");
});

test("AppToText and SI Agent Space signup anchors stay hidden when present", () => {
  for (const a of anchors(html)) {
    const blob = (attr(a, "href") + " " + text(a)).toLowerCase();
    const appToText = blob.includes("apptotext") || blob.includes("app-to-text") || blob.includes("app to text");
    const signup = /siagentspace\.com/.test(blob) && /sign[- ]?up|signup|register/.test(blob);
    const named = blob.includes("si agent space") && /sign[- ]?up|signup/.test(blob);
    if (appToText || signup || named) {
      assert.equal(tagHidden(a) || cssHides(html, attr(a, "id")), true, "visible disallowed link: " + attr(a, "href"));
    }
  }
});
