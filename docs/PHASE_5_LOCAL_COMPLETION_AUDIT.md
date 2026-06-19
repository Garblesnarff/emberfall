# EMBERFALL Phase 5 Local Completion Audit

This audit marks the boundary between local Phase 5 work and future external Steamworks setup. It assumes no paid Steamworks app ID, no local GodotSteam binaries, and no real platform export templates are available yet.

## Local Scope Complete

- Steam calls are isolated behind `SteamManager` and the game runs without a Steam singleton.
- Achievement, stat, rich presence, Steam Cloud, and Steam Input contracts are represented in code.
- `data/steamworks_manifest.json` mirrors the future Steamworks dashboard contract.
- `docs/STEAMWORKS_DASHBOARD_CHECKLIST.md` provides the human dashboard checklist for the future external setup pass.
- Steam-target export presets exist for Windows, Linux, and macOS.
- Export presets use the `steam` feature tag and exclude `steam_appid.txt`, `exports/**`, and `reports/**`.
- Controller defaults, keyboard rebinding, pause/focus handling, debug Steam status, and Deck-resolution HUD checks are covered by tests.
- Local save stats, play time, achievements, and rich presence lifecycle are covered without requiring Steam.

## Required Local Validation

Run these after Phase 5 changes and before any future Steam build:

```bash
godot --headless --path . --quit
godot --headless --fixed-fps 60 --path . --scene res://test/run_tests.tscn
godot --headless --path . --script tools/check_phase5_readiness.gd
bash tools/run_gdunit.sh
```

Current known note: the custom Godot suite exits successfully but Godot prints a generic `ObjectDB instances leaked at exit` warning.

## External-Only Remainder

These cannot be completed or honestly verified until the Steamworks/GodotSteam/export environment exists:

- Steamworks partner app and real app ID.
- Local `steam_appid.txt` for Steam API testing.
- GodotSteam GDExtension binaries matching Godot 4.6.3 and the target platforms.
- Installed Godot export templates and real Windows/Linux/macOS export builds.
- Steamworks dashboard entries created from `data/steamworks_manifest.json`.
- Steam Cloud sync verification across machines or clean user-data folders.
- Steam Input official configuration and glyph verification through Steam.
- Steam overlay, achievement persistence, stat persistence, and rich presence verification through Steam.
- Steam Deck hardware performance and no-keyboard-required verification.

## Decision

Phase 5 is locally prepared as far as it can go without external Steam setup. Future work should start by completing `docs/STEAMWORKS_DASHBOARD_CHECKLIST.md`, then rerunning the validation commands above against real Steam-enabled exports.
