# EMBERFALL

Forge-themed arena survivors-like, ported from the playable HTML prototype into Godot 4.

Current version: `0.1.0` - Phase 1 Core Port.

## Play Test

```bash
godot --path .
```

Controls:

- `WASD` or arrow keys: move
- Mouse: aim
- `Space`: dash
- Auto-fire is always active

## Validate

```bash
godot --headless --path . --quit
godot --headless --fixed-fps 60 --path . --scene res://test/run_tests.tscn
```
