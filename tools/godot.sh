#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$project_root" == /workspace/* ]]; then
 export XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/.runtime/data}"
 export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/.runtime/cache}"
 export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/.runtime/config}"
 mkdir -p "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
fi
godot_binary="${GODOT_BIN:-/workspace/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64}"
if [[ ! -x "$godot_binary" ]]; then godot_binary="$(command -v godot4 || command -v godot)"; fi
exec "$godot_binary" --path "$project_root" "$@"
