# Phase 6A Static Art Integration

Version: `0.6.0`

Phase 6A promotes the existing concept art into stable production asset locations and wires the currently available static UI surfaces to those production paths.

## Production Asset Paths

- Runtime UI art: `res://assets/sprites/ui/`
- Boss portraits: `res://assets/portraits/`
- Capsules: `res://assets/capsules/`
- Source/reference concepts: `res://assets/concepts/`

`res://data/static_art_manifest.json` is the machine-readable source of truth for the promoted static art set.

## Wired

- Forge menu background: `res://assets/sprites/ui/menu_background.png`
- Forge menu wordmark: `res://assets/sprites/ui/word_mark.png`
- Victory recap background: `res://assets/sprites/ui/victory_screen.png`
- Defeat recap background: `res://assets/sprites/ui/defeat_screen.png`

## Staged For Later Use

- Boss portraits for Kilnmaw, Shattered Choir, Aurum, and Aurum Rekindled are available in `res://assets/portraits/`.
- Steam/store capsule source images are available in `res://assets/capsules/`.
- `hero_banner.png` is available in `res://assets/sprites/ui/` for future title, trailer, or release-prep use.

## Deferred

- Animated player, enemy, and boss sprite sheets remain Phase 6B+ work.
- The Meshy to Blender to packed SpriteFrames pipeline is not implemented in Phase 6A.
- Final readability tuning at maximum chaos remains open until entity sprite sheets replace procedural placeholders.

## Validation

Run:

```sh
godot --headless --path . --script tools/check_phase6_art_readiness.gd
godot --headless --fixed-fps 60 --path . --scene res://test/run_tests.tscn
bash tools/run_gdunit.sh
```
