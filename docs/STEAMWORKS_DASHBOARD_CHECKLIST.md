# EMBERFALL Steamworks Dashboard Checklist

Use `data/steamworks_manifest.json` as the source of truth for names and API IDs. This checklist is for the future Steamworks partner dashboard pass after an app ID exists.

## App Identity

- Create the Steamworks app and record the app ID outside source control.
- Create a local `steam_appid.txt` only on machines that need Steam API testing.
- Keep `steam_appid.txt` uncommitted; `.gitignore` and the Steam export presets already exclude it.

## Achievements

Create one Steam achievement per manifest entry:

| API Name | Display Name | Trigger |
| --- | --- | --- |
| `ACH_FIRST_LIGHT` | First Light | Clear wave 1 |
| `ACH_SLAGBREAKER` | Slagbreaker | Kill Kilnmaw |
| `ACH_CHOIR_SILENCER` | Choir Silencer | Kill the Shattered Choir |
| `ACH_TYRANTS_END` | Tyrant's End | Kill Aurum |
| `ACH_FORGE_SECURED` | FORGE SECURED | Win a run |
| `ACH_UNTOUCHABLE` | Untouchable | Clear wave 10 or later without damage |
| `ACH_CENTURION` | Centurion | Reach a 100-kill combo |
| `ACH_EVOLVED` | Evolved | Claim the first weapon evolution |
| `ACH_FULL_BANK` | Full Bank | Bank 1000 embers |
| `ACH_OLD_HAND` | Old Hand | Complete 25 runs |

## Stats

Create integer Steam stats for:

| API Name | Type |
| --- | --- |
| `STAT_RUNS` | int |
| `STAT_KILLS` | int |
| `STAT_DEATHS` | int |
| `STAT_PLAY_MS` | int |
| `STAT_VICTORIES` | int |
| `STAT_BEST_WAVE` | int |
| `STAT_BEST_SCORE` | int |
| `STAT_BEST_COMBO` | int |
| `STAT_EMBERS` | int |

## Steam Cloud

- Enable Steam Cloud for the app.
- Map the save file from `user://emberfall.save` to remote path `emberfall.save`.
- Verify the save survives across two machines or two clean user-data folders before release.

## Rich Presence

Configure rich presence to display the `status` key values emitted by `SteamManager`:

- `In the Forge`
- `Wave 1 - Forging`
- `Wave %d - Forging`
- `Forge Secured`
- `Forge Cold at Wave %d`

## Steam Input

Create an official controller configuration using these action names:

| Action Name | Default Binding |
| --- | --- |
| `Move` | Left stick |
| `Aim` | Right stick |
| `Dash` | A / RB |
| `Pause` | Start |
| `MenuAccept` | A |
| `MenuBack` | B |
| `MenuNavigate` | D-pad |

## Build Verification

Before uploading a Steam build:

```bash
godot --headless --path . --quit
godot --headless --fixed-fps 60 --path . --scene res://test/run_tests.tscn
godot --headless --path . --script tools/check_phase5_readiness.gd
bash tools/run_gdunit.sh
```

Then verify on real exports:

- Steam overlay opens.
- Achievements unlock and persist.
- Stats update after a run.
- Rich presence changes from Forge to wave to victory/defeat.
- Cloud save syncs.
- Controller works in every menu and gameplay flow.
- Steam Deck runs at the selected performance target with readable text at 1280x800.
