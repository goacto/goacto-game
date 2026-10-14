# PR2 proof: public (release) build

Checked by exporting with Godot 4.6-stable headless (`tools/export_web.sh` steps), serving locally with COOP/COEP headers, and loading the page in Playwright Chromium at 1366x768.

| Build | Command | `document.title` | Reset Scene |
|---|---|---|---|
| Before: production today (debug export) | `--export-debug "Web"` | `Mindscape (DEBUG)` | visible |
| After: public | `--export-release "Web"` -> `build/web` | `Mindscape` | hidden (`OS.is_debug_build()` gate) |
| Debug preview (kept) | `--export-debug "Web Debug Preview"` -> `build/web-debug` | `Mindscape (DEBUG)` | visible |

See public_build.svg. Script errors in the release export log: 0.
