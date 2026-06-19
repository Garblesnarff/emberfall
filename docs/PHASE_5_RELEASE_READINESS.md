# EMBERFALL Phase 5 Release Readiness

This project is set up to keep Steam integration optional until a Steamworks app ID and GodotSteam binaries exist.

`data/steamworks_manifest.json` is the local, non-secret manifest for the future Steamworks dashboard setup. The readiness check validates it against the code contracts in `SteamManager`. `docs/STEAMWORKS_DASHBOARD_CHECKLIST.md` turns that manifest into the dashboard setup checklist for the future external pass. `docs/PHASE_5_LOCAL_COMPLETION_AUDIT.md` records the boundary between completed local work and external Steam setup.

## Local Export Presets

`export_presets.cfg` defines three Steam-target export presets:

- `Windows Steam` -> `exports/windows/EMBERFALL.exe`
- `Linux Steam` -> `exports/linux/EMBERFALL.x86_64`
- `macOS Steam` -> `exports/macos/EMBERFALL.zip`

The `exports/` directory is ignored so local binaries do not enter source control. The presets use the `steam` custom feature tag so future Steam-only code paths can be feature-gated cleanly while normal editor/headless runs remain DRM-free. They also exclude local dev-only files such as `steam_appid.txt`, `exports/**`, and `reports/**`.

## Local Validation

Run these before pushing Phase 5 changes:

```bash
godot --headless --path . --quit
godot --headless --fixed-fps 60 --path . --scene res://test/run_tests.tscn
godot --headless --path . --script tools/check_phase5_readiness.gd
bash tools/run_gdunit.sh
```

Actual binary exports also require Godot export templates installed locally. Steam-enabled exports additionally require the future GodotSteam GDExtension binaries.

## Still Requires Steam Setup

- Steam app ID and `steam_appid.txt` for local Steam testing. Keep `steam_appid.txt` local only; the Steam export presets explicitly exclude it.
- GodotSteam GDExtension binaries for Godot 4.6.3 and each target platform.
- Steamworks dashboard entries generated from `data/steamworks_manifest.json` and checked against `docs/STEAMWORKS_DASHBOARD_CHECKLIST.md`.
- Steamworks achievements matching `SteamManager.ACHIEVEMENTS`.
- Steamworks stats matching `SteamManager.STATS`.
- Steam Cloud mapping for `user://emberfall.save`.
- Steam Input configuration matching `SteamManager.INPUT_ACTIONS` and glyph verification.
- Steam Deck hardware pass for stable performance and no keyboard-required flows.
