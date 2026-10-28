#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
engine_dir=/workspace/tools/godot-4.4.1
engine="$engine_dir/Godot_v4.4.1-stable_linux.x86_64"
if [[ ! -x "$engine" ]] || [[ "$("$engine" --version)" != 4.4.1.stable.* ]]; then
 mkdir -p "$engine_dir"
 curl -fsSL --retry 2 https://github.com/godotengine/godot-builds/releases/download/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64.zip -o "$engine_dir/godot.zip"
 curl -fsSL --retry 2 https://github.com/godotengine/godot-builds/releases/download/4.4.1-stable/SHA512-SUMS.txt -o "$engine_dir/SHA512-SUMS.txt"
 python - "$engine_dir" <<'PY'
import sys,pathlib,zipfile,hashlib
p=pathlib.Path(sys.argv[1])
expected=next(l.split()[0] for l in (p/'SHA512-SUMS.txt').read_text().splitlines() if l.endswith('Godot_v4.4.1-stable_linux.x86_64.zip'))
assert hashlib.sha512((p/'godot.zip').read_bytes()).hexdigest()==expected, 'Godot checksum mismatch'
with zipfile.ZipFile(p/'godot.zip') as z:z.extractall(p)
(p/'Godot_v4.4.1-stable_linux.x86_64').chmod(0o755)
PY
fi
"$project_root/tools/godot.sh" --headless --editor --import --quit
