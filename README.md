# EMBERFALL

Forge-themed arena survivors-like, ported from the playable HTML prototype into Godot 4.

Current version: `0.6.2` - Phase 6B crawler and Cinder-Warden animation integration.

## Play Test

```bash
godot --path .
```

Controls:

- `WASD` or arrow keys: move
- Right stick: aim on controller
- Mouse: aim
- Left mouse or `F`: fire
- Right stick deflection: aim and fire on controller
- `Space`: dash
- `P` or Start: pause

## Validate

```bash
godot --headless --path . --quit
godot --headless --fixed-fps 60 --path . --scene res://test/run_tests.tscn
godot --headless --path . --script tools/check_phase6_art_readiness.gd
godot --headless --path . --script tools/art/build_spriteframes.gd
```
