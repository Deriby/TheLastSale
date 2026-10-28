#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_data="$(mktemp -d /tmp/ultima-venda-tests.XXXXXX)"
trap 'rm -rf -- "$test_data"' EXIT
XDG_DATA_HOME="$test_data" timeout 180 "$project_root/tools/godot.sh" --headless --audio-driver Dummy res://tests/integration.tscn
