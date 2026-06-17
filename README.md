# EMBERFALL

Forge-themed arena survivors-like, ported from the playable HTML prototype into Godot 4.

Current version: `0.5.6` - Phase 5 Steam & Polish foundations.

## Play Test

```bash
godot --path .
```

Controls:

- `WASD` or arrow keys: move
- Right stick: aim on controller
- Mouse: aim
- `Space`: dash
- `P` or Start: pause
- Auto-fire is always active

## Validate

```bash
godot --headless --path . --quit
godot --headless --fixed-fps 60 --path . --scene res://test/run_tests.tscn
```
