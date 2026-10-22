# Mindscape polish: proof

Preview only. Do not merge without the owner's yes.

Base: main ca08302. Godot 4.6-stable, web export through `tools/export_web.sh` (same preset). Build stamp 20261022-210451 UTC (17:04 EDT). Verified in Chromium at 1440x900 and at 390x844.

## 1. Emoji showing as boxed codes
Root causes:
- `project.godot [gui] theme/default_font` is not a valid key, so no fallback font was ever installed. Glyphs missing from the UI font rendered as hex boxes (for example 01F3AF).
- Noto Color Emoji is a CBDT bitmap font. Godot only draws it with `disable_embedded_bitmaps=false` on the import.
- Share-card Labels in MilestoneShareManager are drawn in their own SubViewport and never picked up a theme fallback.

Fix:
- Added `assets/fonts/NotoColorEmoji-subset.ttf`, a 208-glyph subset of about 450 KB under the SIL OFL (license in `OFL-NotoColorEmoji.txt`). Its import sets bitmaps enabled.
- `scripts/ui/emoji_font.gd` installs it at startup from `ThemeConfig._init` as a fallback on ThemeDB.fallback_font and the default theme font.
- Every share-card Label gets an override to the same font.

Proof:
- `share-card-first-steps.png` and `share-card-evolution-10.png`: 1080x1080 cards, captured from the game's own Download button (blob intercepted).
- `hud-1440.png`, `hud-390.png` and `milestone-popup-1440.png`: pedestals, 🔊 and the pop-up.
- I viewed every shot. None has a boxed code.

## 2. "Aspect: Productivity"
The summary printed the raw habit domain. Productivity is a domain, not an Aspect. `scripts/ui/aspect_label.gd` maps domains through `GameManager.ASPECTS[*].domain`:
- productivity → Discipline
- growth → Courage
- learning → Creativity
- social → Compassion
- mindfulness → Wisdom
- health → Vitality

The summary uses the picked habit's domain first, because that is what earns the XP. Next it uses the script's Aspect. Otherwise it falls back to Discipline. See `session-complete-1440.png` and `session-complete-390.png`: General Focus now shows "Aspect: Discipline".

## 3. Footer
"Report Bugs and Share Feedback <3" (`footer-390.png`). In the hub, the status pill and the minimap now sit 28 px higher at every width, so the footer no longer overlaps them. At 390 the keyboard hint row (WASD, Scroll, ESC) is hidden; touch controls replace it.

## 4. Fit at 390
`scripts/ui/fit_viewport.gd` clamps the size of dialogs and panels to the viewport. Uses:
- Settings panel
- main-menu Import Save File: buttons wrap in an HFlowContainer
- JSON dialog
- bedroom save panel and import dialog
- hub header: tighter separation; the greeting is trimmed with an ellipsis; the date and save chip are hidden when narrow, so "Evolution N" is no longer clipped on the left

Also fixed: the Settings → Import JSON dialog drew its prompt text on top of the TextEdit. The prompt is now a Label inside the VBox.

Shots: `settings-390.png`, `settings-import-390.png`, `import-save-390.png`, `hud-390.png`.

## 5. Name sweep
There were no customer-facing hits in this repo. One internal hit, in docs/proof/build-timestamp/PROOF.md, was left.

## Tests
See `tests.txt`:
- test_mindscape_polish (new): 37 passed, 0 failed
- milestone_share: 12/0
- early_testing: 18/0
- irl_gifts: 22/0
- test_habit_manager fails to compile under `-s` (HabitManager autoload is missing). It fails the same way on main and is not caused by this PR.

## Known issues (not fixed here)
- Bedroom title bar at 390: the long cabin title is cut on both sides.
- At 390, after an Auto-Save import that lands in the bedroom, the console was not visible. I used Slot 1 → hub to verify.
- The status pill still overlaps the minimap in the hub. This was already true before this PR.
- Possible XP bug: `script_aspect` (an Aspect id) is passed as a domain when progress is awarded (focus_mode.gd ~1255). Not changed.
