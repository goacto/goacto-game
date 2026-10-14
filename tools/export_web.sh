#!/usr/bin/env bash
# Export Mindscape for the web with Godot 4.6 (+ export templates).
#   Public build  -> build/web        (release: title "Mindscape", no Reset Scene, served at mindscape.goacto.com)
#   Debug preview -> build/web-debug  (debug: "(DEBUG)" title + Reset Scene; deploy only to a preview, never production)
set -euo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/../godot"
"$GODOT" --headless --import
mkdir -p ../build/web ../build/web-debug
"$GODOT" --headless --export-release "Web" ../build/web/index.html
"$GODOT" --headless --export-debug "Web Debug Preview" ../build/web-debug/index.html
echo "Release: build/web   Debug preview: build/web-debug"
