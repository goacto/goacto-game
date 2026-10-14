# PR1 proof: playtest bugs (report: CoS playtest Oct 14, 2026 ~4:55 AM ET)

How it was checked: Godot 4.6-stable headless `--export-debug "Web"`, served locally with COOP/COEP, and driven by Playwright Chromium (1366x768, timezone America/New_York). A test-only autoload (`TestHarness.gd`, **not** part of this PR) drives each repro step through the real input path (`Input.parse_input_event`) and logs `[HARNESS]` lines. BEFORE = `main` (fab7140) + only the parse-error fixes (otherwise `bedroom.gd` doesn't compile at HEAD). AFTER = this branch.

| # | Report repro | Before | After |
|---|---|---|---|
| 1 | Kitchen + Master Key, save Slot 1, Title > Load > Slot 1 | `resumed_in=Bedroom popups=["Master Key Activated"]` | `resumed_in=Kitchen popups=[]` (load_room.svg) |
| 2 | Save at ~05:30 EDT | `slot1 label='2026-10-14 09:30'` (UTC) | `slot1 label='2026-10-14 05:30' browser_local='2026-10-14 05:30'` |
| 3 | Food Synthesizer > SPACE > Menu | `pause=true dialogue_visible=true` | `pause=true dialogue_visible=false` (menu_overlap.svg) |
| 4 | Esc from Settings | not reproduced by the scripted path (both builds: back in Kitchen, no dialogue) | defensive fix: Esc consumed + single back; opening Menu discards any open line |
| 5 | Accessibility dropdowns blank | blank on live site | `FontSizeOption text='Medium'`, `ColorblindOption text='None'` (accessibility.svg); also fixed calls to non-existent `set_accessibility_setting` |
| 6 | Telescope stays 0/6 | all 6 objects outside the 400x350 scope (`inside_scope=false`), +/= did nothing, `discovered=0/6` | `inside_scope=true` x6, `zoom after '=': 1.25`, `discovered=6/6 saved=6` (telescope.svg). Also fixed `_ready` crash on missing `FocusAnalytics` position |
| 7a | Missing `res://assets/sprites/ui/icon.png` | console: `Error opening file 'res://assets/sprites/ui/icon.png'` | 0 occurrences (new `icon.svg`) |
| 7b | Service worker registration fails | `pageerror: Failed to register a ServiceWorker` | 0 occurrences (PWA off in preset; removed from served `build/web`) |

Also fixed: three parse errors on `main` (bedroom.gd:5726, mindscape_north.gd:2512, mindscape_west.gd missing `_add_label`/`show_dialogue`) that break any fresh export.
