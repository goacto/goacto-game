# Proof: menu "199d ago" build stamp

## Cause
`godot/autoload/GameManager.gd` hardcodes:

```
const BUILD_TIMESTAMP: String = "20260328-220038"
```

`_create_version_overlay()` renders it as `v0.1.0-prototype | 20260328-220038 (199d ago)` via `_get_relative_time()`. The stamp was never refreshed on web export (`tools/export_web.sh` did not write it), so the live public build still carries the March 28, 2026 export time.

Before (live / playtest title screen, Oct 14 2026): see `before-menu-199d.png` — bottom bar shows `(199d ago)`.

Relative-time check: see `relative_time_check.txt` (March 28 → Oct 14 = 199 days).

## Fix (this PR)
1. Bump `BUILD_TIMESTAMP` to current UTC.
2. Make `tools/export_web.sh` stamp `BUILD_TIMESTAMP` before every Godot export so it cannot go stale again.

## After deploy (needs Zach merge + re-export)
Menu overlay should read roughly:
`v0.1.0-prototype | YYYYMMDD-HHMMSS (0d ago)` / minutes/hours — not `199d ago`.

**Note:** Source-only PR. Live `build/web/index.pck` still has the old stamp until someone runs `tools/export_web.sh` and redeploys `build/web`.
