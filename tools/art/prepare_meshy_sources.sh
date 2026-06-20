#!/usr/bin/env bash
set -euo pipefail

ROOT="/Volumes/T7/ember_forge/raw_art/meshy"
OUT="/private/tmp/emberfall_phase6b"

mkdir -p "$OUT/crawler" "$OUT/cinder_warden"

unzip -o "$ROOT/crawler_rigged.zip" \
  "Meshy_AI_Emberclad_Golem_quadruped/Meshy_AI_Emberclad_Golem_quadruped_model_Animation_Walking_withSkin.glb" \
  -d "$OUT/crawler" >/dev/null

unzip -o "$ROOT/cinder_warden_rigged.zip" \
  "Meshy_AI_Molten_Obsidian_Knigh_biped/Meshy_AI_Molten_Obsidian_Knigh_biped_Animation_Walking_withSkin.glb" \
  -d "$OUT/cinder_warden" >/dev/null

printf "Prepared Meshy GLB sources in %s\n" "$OUT"
