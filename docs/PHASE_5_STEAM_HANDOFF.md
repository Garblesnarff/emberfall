# EMBERFALL Phase 5 Steam Handoff

Phase 5 can progress without a paid Steamworks app by keeping every Steam touchpoint behind `SteamManager`.

## Implemented Locally

- `SteamManager` detects GodotSteam dynamically and safely no-ops when Steam is absent.
- `AchievementManager` listens to `EventBus` and unlocks the PRD achievement set through `SteamManager`.
- Settings persist through `SaveManager` and apply to audio, shake/flash, damage numbers, minimap, FPS, fullscreen, and vsync.
- Pause and settings menus work during a paused tree.
- Focus loss auto-pauses active runs.
- `AudioDirector` owns SFX/Music buses, a small pooled SFX surface, volume settings, intensity state, and pause/resume state.

## Future Steamworks Inputs

- Steam app ID.
- GodotSteam GDExtension binaries matching Godot 4.6.3 and target exports.
- Achievement definitions using these API IDs:
  - `ACH_FIRST_LIGHT`
  - `ACH_SLAGBREAKER`
  - `ACH_CHOIR_SILENCER`
  - `ACH_TYRANTS_END`
  - `ACH_FORGE_SECURED`
  - `ACH_UNTOUCHABLE`
  - `ACH_CENTURION`
  - `ACH_EVOLVED`
  - `ACH_FULL_BANK`
  - `ACH_OLD_HAND`
- Steam Cloud mapping for `user://emberfall.save`.
- Steam Input official controller config and Deck verification pass.

## Local Files

Use `steam_appid.txt` only for local Steam testing. It is intentionally gitignored.
