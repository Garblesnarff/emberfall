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

The first runtime target is the crawler directional animation set. Source Meshy exports live outside the repo at:

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
  --model /Volumes/T7/ember_forge/raw_art/meshy/crawler_animation_library.glb \
  --entity crawler \
  --animation walk \
  --source-action crawl \
  --output assets/sprites/enemies/crawler/generated \
  --frame-size 96 \
  --frames 8 \
  --directions 8
```

Pack the rendered PNG sequences, import the atlases, and build Godot SpriteFrames:

```sh
godot --headless --path . --script tools/art/pack_sprite_atlases.gd
godot --headless --editor --path . --quit
godot --headless --path . --script tools/art/build_spriteframes.gd -- res://data/art/phase6b_sprite_manifest.json
```

## Notes

- `data/art/phase6b_sprite_manifest.json` is the source of truth for local render targets.
- Animation entries can specify `source_action` and whether the generated Godot animation should `loop`.
- `--recenter-motion` removes source root motion from fixed-frame sprite renders.
- `--emission-strength` and `--exposure` provide reproducible player-readability treatment.
- Runtime sprite resources should land under `assets/sprites/**`.
- Runtime `SpriteFrames` reference packed atlases; individual frames remain inspectable pipeline sources and are excluded from release exports.
- Meshy source archives remain outside the repo until we decide which source assets should be versioned.
- Animated entity art should preserve the readability rule: the Cinder-Warden must remain the brightest white-hot silhouette.
