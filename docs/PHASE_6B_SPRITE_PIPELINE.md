# Phase 6B Sprite Pipeline

Version: `0.6.3`

Phase 6B starts the runtime sprite-sheet pipeline by turning Meshy GLB exports into Godot `SpriteFrames` resources.

## Implemented

- Blender command path validated: `/Applications/Blender.app/Contents/MacOS/Blender`
- Meshy source exports remain outside the repo under `/Volumes/T7/ember_forge/raw_art/meshy`.
- `tools/art/prepare_meshy_sources.sh` extracts selected GLBs into `/private/tmp/emberfall_phase6b`.
- `tools/art/render_directional_sprites.py` renders transparent 96 px directional PNG frames through Blender.
- `tools/art/build_spriteframes.gd` builds Godot `SpriteFrames` resources from generated PNG sequences.
- `data/art/phase6b_sprite_manifest.json` defines enabled render/build targets.
- `crawler.tres` now uses `res://assets/sprites/enemies/crawler/crawler_spriteframes.tres`.
- The crawler has 8-direction walk, attack, and death sequences with 8 frames per direction.
- `Enemy.gd` selects directional walk/attack/death animations while preserving placeholder fallback behavior.
- Contact attacks trigger the crawler attack sequence without changing chase movement or damage timing.
- Lethal damage makes the crawler non-interactive while its deterministic death sequence finishes.
- The Blender renderer selects named actions explicitly from a multi-action GLB.
- The Cinder-Warden has 8-direction idle, walk, manual-fire attack, and dash sequences.
- Player renders use emission/exposure controls to remain the brightest white-hot combat silhouette.
- Root-motion recentering keeps charge and combo frames inside the fixed 96 px frame.

## Secret Handling

Do not commit Meshy API keys. Use an environment variable or ignored local file:

```sh
export MESHY_API_KEY="..."
```

The current pipeline does not need to call Meshy because the GLB exports already exist locally.

## Regenerate Crawler

The local crawler animation library remains outside the runtime project at `/Volumes/T7/ember_forge/raw_art/meshy/crawler_animation_library.glb`. It contains the `crawl`, `attack`, and `death` actions.

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python tools/art/render_directional_sprites.py -- \
  --model /Volumes/T7/ember_forge/raw_art/meshy/crawler_animation_library.glb \
  --entity crawler \
  --animation walk \
  --source-action crawl \
  --output assets/sprites/enemies/crawler/generated \
  --frame-size 96 \
  --frames 8 \
  --directions 8 \
  --samples 24
```

Repeat the render for `--animation attack --source-action attack` and `--animation death --source-action death`, then rebuild the resource:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script tools/art/build_spriteframes.gd
```

## Cinder-Warden Render Controls

Prepare all player GLBs with `bash tools/art/prepare_meshy_sources.sh`. Player renders use `--emission-strength 3.0 --exposure 1.2 --recenter-motion --ortho-padding 0.9`. The manifest records the source GLB, action, frame count, FPS, loop contract, and reproducible render settings for idle, locomotion, attack, and dash.

## Deferred

- Remaining enemy and boss animation sets are not rendered yet.
- Sprite atlas packing remains future work; current output uses individual imported PNG frames for inspectability.
- Full max-chaos readability review remains open until more entities receive generated sprites.
