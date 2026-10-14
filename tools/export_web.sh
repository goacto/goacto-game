#!/usr/bin/env bash
# Export Mindscape for the web with Godot 4.6 (+ export templates).
#   Public build  -> build/web        (release: title "Mindscape", no Reset Scene, served at mindscape.goacto.com)
#   Debug preview -> build/web-debug  (debug: "(DEBUG)" title + Reset Scene; deploy only to a preview, never production)
set -euo pipefail
GODOT="${GODOT:-godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/godot"

# Stamp BUILD_TIMESTAMP so the menu overlay never shows a stale "Nd ago".
STAMP="$(date -u +%Y%m%d-%H%M%S)"
python3 - << PY
from pathlib import Path
import re
stamp = "${STAMP}"
p = Path("autoload/GameManager.gd")
text = p.read_text()
new, n = re.subn(
    r'const BUILD_TIMESTAMP: String = "[^"]*"',
    f'const BUILD_TIMESTAMP: String = "{stamp}"',
    text,
    count=1,
)
if n != 1:
    raise SystemExit(f"BUILD_TIMESTAMP replace failed (n={n})")
p.write_text(new)
print(f"Stamped BUILD_TIMESTAMP={stamp}")
PY

"$GODOT" --headless --import
mkdir -p ../build/web ../build/web-debug
"$GODOT" --headless --export-release "Web" ../build/web/index.html
"$GODOT" --headless --export-debug "Web Debug Preview" ../build/web-debug/index.html
echo "Release: build/web   Debug preview: build/web-debug   stamp: $STAMP"
