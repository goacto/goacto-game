# Mindscape audit — 2026-11-05

One pass on the live site [https://mindscape.goacto.com](https://mindscape.goacto.com) (HTML `last-modified` Thu, 05 Nov 2026 17:20:53 GMT) and the tree at `main` `1427e13` ("M2: Quiet workbook link after Focus Chamber").

Scope: first minute on a phone, day-2 hooks and empty states, the quiet $7 workbook path, client-bundle keys, response headers, npm audit highs. Security is report only. No auth, RLS, secret, or Stripe changes.

Draft PR **#20** ("Phone first 30 seconds", head `2b67028`, branch `cursor/phone-first-minute-b051`) is open and must not be merged from this pass. It owns the portrait rotate pill and the intro letterbox. This audit does not repeat that work. Where a finding sits next to #20, it says so.

## Top 5

### 1. UX — High — After Play, a 390px phone draws a 1366-wide game

**What.** `godot/project.godot` sets a 1366×768 viewport, `canvas_items` stretch, `aspect=expand`. On a 390×844 CSS window the width is the limit, so the scale is `390/1366 ≈ 0.29`. A 60px button is about **17px** tall and 22px type is about **6px**. Turned sideways (844×390) the height is the limit (`390/768 ≈ 0.51`), so the same button is about **31px** and type about **11px**. Both are under a 44px tap target. The HTML Play gate is not this bug: at 390×844 it is readable, the tagline wraps, and Play is a normal CSS button.

**Fix.** A phone layout or a real UI scale for controls (menu, skip, hub, daily-reward claim). The rotate pill and the intro letterbox on #20 do not change this scale. Do not duplicate them.

**Effort.** Large. Not in this PR.

**390px screenshot.** After Play, main menu, 390×844, portrait. Frame the "Begin Journey" control with the surrounding title. A second frame at 844×390 (landscape) shows the same control still short of 44px. Do not use the Play gate for this shot. #20's pill will sit on top of later previews; crop it out or note it so the shot is about control size, not the pill.

### 2. UX — Medium — The first minute is a download, then a cutscene, then a ship to search

**What.** Play waits on `index.wasm` (37,686,550 bytes) plus `index.pck` (50,463,024 bytes), about 85 MB, before any scene. A new game then runs `intro_part1` (11 dialogue lines) and lands in the kitchen, where Dr. Lumina tells the player to search the ship for a console. `intro_part2` (12 more lines) is the scene that finally says "First step: a Focus Session." Skip exists, and #20 / the phone-first work already places Skip and Back. Skip of part 1 still drops the player in the kitchen, not in a focus timer. A phone session does not reach a habit, an empty state, or the workbook inside the first minute unless the player already knows to skip and where the console is.

**Fix.** After Play (or after one Skip), offer a single "Start a focus session" action that does not require the ship search. Leave the cutscene in place for people who want it. #20 already adds a one-line "what a session is" on the gate; do not rewrite that copy here.

**Effort.** Medium.

**390px screenshot.** Three frames at 390×844, same new profile: (1) the Play gate with the 85 MB line, (2) the first intro line ("Year 3,847…") with Skip visible, (3) the kitchen line that sends the player to search the ship. The point of the set is how many screens sit before a focus timer. #20 is letterboxing frame 2; this audit does not reshoot that layout.

### 3. Retention — High — Day 2 exists only inside the hub, on this device

**What.** `GameManager.check_daily_login()` is only called from `mindscape_hub.gd` (`_check_daily_login`). The popup waits until onboarding and tutorial tooltips finish. There is no email, no web push, and no notification permission. Godot's web preset has `progressive_web_app/enabled=false`. The manifest file is served, and this PR links it, but nothing reminds a person who does not come back. The day-1 reward string is "Welcome back, Traveler!" (`DAILY_REWARDS` day 1), including the first visit. A gap greater than one calendar day sets `login_streak` back to 1 with no grace day. Empty states do exist later ("No focus sessions recorded yet" in the observatory and the bedroom; "Come back tomorrow" only after the garden is watered). None of them are on the shell or on the path in finding 2. Saves stay in this browser.

**Fix.** When a first session ends, say when to come back and what is waiting (the day-2 reward), in the shell or at session end. Change the day-1 string so the first visit is not "welcome back." Add a one-day grace before a streak reset. `GameManager.gd` is already edited on #20 (build stamp). Land the copy change on its own after that, or on top of #20, so the two drafts do not fight.

**Effort.** Medium for the copy and the end-of-session line. Large if it grows into push or email.

**390px screenshot.** Hub, second calendar day, 390×844, daily-reward panel ("Day 2", streak, Claim). Pair it with a shot of the same panel on a brand-new profile so "Welcome back, Traveler!" is visible on day 1. Include the browser chrome so it is obvious there is no badge and no install prompt.

### 4. Retention — Medium — The $7 workbook is one quiet line after a finished focus session

**What.** `godot/scripts/ui/quiet_link.gd` is the only purchase path. Copy: "Want a next step? The 30-Day Habit Builder workbook ($7)". URL: `https://goacto.com/products/30-day-habit-builder-workbook` with utm params. It is created once, in `focus_mode.gd` `_show_session_summary`, under a 60px "Continue to Journal" button. It is not on the menu, not on an empty state, and not reachable in the first minute (finding 2). The link color `(0.6, 0.65, 0.75)` on panel `(0.1, 0.12, 0.18)` is about **6.7:1**, so this is not a contrast failure. It is a placement and size failure. At the portrait scale in finding 1, 14px type is about **4px** on screen. The panel is 450 game-pixels wide inside a 1366-wide viewport, so it fits the Godot layout and is still tiny on the phone. PR #12 asked for one quiet link and no pop-up. This pass does not make it louder.

**Fix.** Keep a single link and no pop-up. Repeat the same line somewhere a player actually stands on day 2 (session end is right; the empty "no focus sessions" state is the other honest place). Phone readability is the scale fix in finding 1, not a second button.

**Effort.** Small for a second placement of the same link. The phone size is the large fix in finding 1.

**390px screenshot.** Session-complete panel at 390×844 after a focus session. The frame must include the whole sentence and "($7)", plus "Continue to Journal" above it, so a reviewer can see the link is present and how small it is. Do not crop to the desktop 1366 layout.

### 5. Security — Medium — A device id is written and sent before the privacy control exists

**What.** `build/web/goacto-ping.js` is in the document head (also `html/head_include` on the Web export preset). On load, before Play, it writes `goacto:aid:v1` (a random UUID) and `goacto:ping-day:v1:mindscape` to `localStorage`, then POSTs `{v, app, day, aid, first}` to `https://siagentspace.com/api/ping`. The write happens before the fetch. Opt-out is `goacto:usage-optout:v1` or Global Privacy Control. The only UI for that flag is Settings → "Share anonymous usage count", which sits behind the 85 MB load. No account, no Stripe, no Supabase key in that script. This pass does not change the ping.

**Fix.** Do not mint or send the id until the player has seen the privacy toggle, or keep the id on-device until they opt in. Report only here.

**Effort.** Small in the shell script. Needs a product decision on opt-in versus opt-out. Not done in this PR.

**Headers, keys, and npm** are part of this check and are spelled out below. They are not separate top-line items.

## Security checks (report only)

### Response headers

`curl -sI https://mindscape.goacto.com/` on 5 Nov 2026:

| Header | Live value |
| --- | --- |
| Strict-Transport-Security | `max-age=63072000` (Vercel) |
| Cross-Origin-Opener-Policy | `same-origin` |
| Cross-Origin-Embedder-Policy | `require-corp` |
| Cache-Control (HTML) | `no-cache` |
| Access-Control-Allow-Origin | `*` |
| Content-Security-Policy | absent |
| X-Content-Type-Options | absent |
| Referrer-Policy | absent |
| Permissions-Policy | absent |
| X-Frame-Options / CSP `frame-ancestors` | absent |

`index.js`, `index.wasm`, and `index.pck` also send `Cross-Origin-Resource-Policy: same-origin` and a one-year immutable cache. COOP and COEP are required for the Godot web build. The gap is the missing lock-down headers. Severity for those gaps alone is **Low**: the site has no login and no payment form. A script injection would still see the device id and the local save. Do not add CSP in a drive-by; `require-corp` plus a strict script list is easy to get wrong and blank the game.

### Client bundle keys

Scanned `index.html`, `index.js`, `goacto-ping.js`, `play-progress.js`, `index.wasm`, and `index.pck` for Stripe live/test keys, AWS access-key ids, Google API keys, GitHub tokens, Slack tokens, Supabase hosts, JWT-shaped strings, and `api_key`/`secret` assignments.

- No such credentials in the shell scripts or the HTML.
- `index.wasm` contains PEM *header labels* (`BEGIN PRIVATE KEY`, `BEGIN CERTIFICATE`, and the RSA/EC variants) as a null-terminated string table in the engine, with no key body after them. It also contains the Godot engine documentation string that mentions `https://sentry.io/welcome/`. That is not a project DSN.
- `index.pck` is a Godot 4.6 `GDPC` pack. `scripts/ui/quiet_link.gdc` and `scripts/shop/irl_gifts.gdc` are in the pack. Script strings are not plaintext in the pack, so a raw scan does not print the workbook URL or the shop codes. The source of `irl_gifts.gd` still has two discount-code literals while `GIFT_CODES_ENABLED` is false (the comment says the codes are not in Shopify yet). They ship inside the client whenever that script is exported. Severity **Low**. Do not flip the flag, and do not treat the pack as a place to hide a code. The values are intentionally not repeated in this file.

### npm audit

There is no `package.json`, lockfile, or npm project in this repo. **npm audit highs: 0 (not applicable).** The web client is the Godot export plus three hand-written scripts.

## Tiny fixes in this PR

These do not touch the rotate pill, the intro letterbox, the gate copy #20 is rewriting, or any security control.

1. **Play gate can be pinch-zoomed, and Play shows a focus ring.** `touch-action: none` was on `body`, so the one readable phone screen could not zoom. It is now `manipulation` on `body` and `none` on `#canvas` only. `#play-btn:focus-visible` draws a 3px cream outline. The button size is unchanged.
2. **The existing manifest is linked.** `index.manifest.json` was already exported and served, and the HTML did not point at it. The shell now has `rel=manifest` plus the mobile-web-app capable metas. `godot/export_presets.cfg` head include for the Web preset carries the same tags so the next export does not drop them. `progressive_web_app/enabled` stays false. This does not add a service worker, offline cache, or a reminder. It only lets a browser use the name and icon that were already on the server.

## Left alone on purpose

- Draft #20. Not merged. Rotate pill, intro letterbox, ghost title, build stamp, and the three gate lines ("what a session is", "Use Wi-Fi", "Loads about 85 MB") stay on that branch.
- The quiet-link copy, URL, and single placement from #12.
- `goacto-ping.js`, headers, discount-code flag, Stripe, auth.
- No new web export of `index.pck`. The scale and day-2 fixes need Godot work and a pack rebuild; they are not tiny.

## How this was checked

- Live headers and asset lengths via `curl -sI` against `mindscape.goacto.com`.
- Live Play gate captured at 390×844. The tagline wraps on three lines, the 85 MB line is intact, and Play sits in the middle of the screen with empty space above and below. No rotate pill on production (that pill is only on #20).
- Scale numbers come from the viewport and stretch mode in `project.godot`, applied to the button sizes in `main_menu.tscn` and the link size in `quiet_link.gd`. The post-Play menu was not booted in this pass; that boot is the 85 MB download finding 2 is about.
- Bundle scan as described above. `OPTIONS` to the ping host from this environment returned 403; the finding is from the script, which stores the id before the request.
