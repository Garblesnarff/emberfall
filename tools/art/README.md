# Phase 6B Art Pipeline

This folder holds the local Meshy-to-Blender-to-Godot sprite pipeline. It does not store API keys.

## Local Setup

Use the Meshy API key only through your shell or an ignored local file. Do not commit it.

```sh
export MESHY_API_KEY="..."
```

Blender is expected at:

```sh
/Applications/Blender.app/Contents/MacOS/Blender
```

## First Target

The first runtime target is the crawler walk sheet. Source Meshy exports live outside the repo at:

```sh
/Volumes/T7/ember_forge/raw_art/meshy
```

Prepare extracted GLBs:

```sh
bash tools/art/prepare_meshy_sources.sh
```

Render crawler frames:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python tools/art/render_directional_sprites.py -- \
  --model /private/tmp/emberfall_phase6b/crawler/Meshy_AI_Emberclad_Golem_quadruped/Meshy_AI_Emberclad_Golem_quadruped_model_Animation_Walking_withSkin.glb \
  --entity crawler \
  --animation walk \
  --output assets/sprites/enemies/crawler/generated \
  --frame-size 96 \
  --frames 8 \
  --directions 8
```

Import the rendered PNGs and build Godot SpriteFrames:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script tools/art/build_spriteframes.gd -- res://data/art/phase6b_sprite_manifest.json
```

## Notes

- `data/art/phase6b_sprite_manifest.json` is the source of truth for local render targets.
- Runtime sprite resources should land under `assets/sprites/**`.
- Meshy source archives remain outside the repo until we decide which source assets should be versioned.
- Animated entity art should preserve the readability rule: the Cinder-Warden must remain the brightest white-hot silhouette.
