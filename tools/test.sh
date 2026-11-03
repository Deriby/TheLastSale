#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_data="$(mktemp -d "${TMPDIR:-/tmp}/ultima-venda-tests.XXXXXX")"
trap 'rm -rf -- "$test_data"' EXIT
for scene in integration friday_integration saturday_integration sunday_integration supply_integration natural_motion_integration locomotion_integration protagonist_gait_integration psx_integration title_integration everyday_integration friday_story_integration scares_integration watching_integration saturday_unease_integration sunday_climax_integration desktop_integration guidance_integration release_review_integration campaign_route_integration title_music_integration horror_direction_integration panels_integration visual_direction_integration; do
 scene_timeout=300
 if [[ "$scene" == campaign_route_integration ]]; then scene_timeout=600; fi
 XDG_DATA_HOME="$test_data/$scene" timeout "$scene_timeout" "$project_root/tools/godot.sh" --headless --audio-driver Dummy "res://tests/$scene.tscn"
done
