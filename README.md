# EMBERFALL

Forge-themed arena survivors-like, ported from the playable HTML prototype into Godot 4.

Current version: `0.5.16` - Phase 5 Steam & Polish foundations plus v4.2 amendment catch-up.

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
```
