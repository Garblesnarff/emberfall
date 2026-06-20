# Phase 6B Sprite Pipeline

Version: `0.6.1`

Phase 6B starts the runtime sprite-sheet pipeline by turning Meshy GLB exports into Godot `SpriteFrames` resources.

## Implemented

- Blender command path validated: `/Applications/Blender.app/Contents/MacOS/Blender`
- Meshy source exports remain outside the repo under `/Volumes/T7/ember_forge/raw_art/meshy`.
- `tools/art/prepare_meshy_sources.sh` extracts selected GLBs into `/private/tmp/emberfall_phase6b`.
- `tools/art/render_directional_sprites.py` renders transparent 96 px directional PNG frames through Blender.
- `tools/art/build_spriteframes.gd` builds Godot `SpriteFrames` resources from generated PNG sequences.
- `data/art/phase6b_sprite_manifest.json` defines enabled render/build targets.
- `crawler.tres` now uses `res://assets/sprites/enemies/crawler/crawler_spriteframes.tres`.
- `Enemy.gd` supports generated `walk_00` through `walk_07` directional animations while preserving placeholder fallback behavior.

## Secret Handling

Do not commit Meshy API keys. Use an environment variable or ignored local file:

```sh
export MESHY_API_KEY="..."
```

The current pipeline does not need to call Meshy because the GLB exports already exist locally.

## Regenerate Crawler

```sh
bash tools/art/prepare_meshy_sources.sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python tools/art/render_directional_sprites.py -- \
  --model /private/tmp/emberfall_phase6b/crawler/Meshy_AI_Emberclad_Golem_quadruped/Meshy_AI_Emberclad_Golem_quadruped_model_Animation_Walking_withSkin.glb \
  --entity crawler \
  --animation walk \
  --output assets/sprites/enemies/crawler/generated \
  --frame-size 96 \
  --frames 8 \
  --directions 8 \
  --samples 24
godot --headless --editor --path . --quit
godot --headless --path . --script tools/art/build_spriteframes.gd
```

## Deferred

- Cinder-Warden/player render target is staged in the manifest but disabled until we review scale/readability.
- Death/attack/idle variants are not rendered yet.
- Sprite atlas packing remains future work; current output uses individual imported PNG frames for inspectability.
- Full max-chaos readability review remains open until more entities receive generated sprites.
