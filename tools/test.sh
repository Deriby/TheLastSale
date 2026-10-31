#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_data="$(mktemp -d "${TMPDIR:-/tmp}/ultima-venda-tests.XXXXXX")"
trap 'rm -rf -- "$test_data"' EXIT
for scene in integration friday_integration saturday_integration sunday_integration supply_integration natural_motion_integration locomotion_integration psx_integration title_integration; do
 XDG_DATA_HOME="$test_data" timeout 300 "$project_root/tools/godot.sh" --headless --audio-driver Dummy "res://tests/$scene.tscn"
done
