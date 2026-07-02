# Phase 7 Desktop Demo

Version `0.7.0` establishes the local demo contract for Windows, Linux, and macOS.

## Player Contract

- Waves 1 through 7 are playable.
- Kilnmaw remains the wave-5 boss.
- Forgehammer is the only selectable weapon.
- Clearing wave 7 opens a dedicated `DEMO COMPLETE` recap.
- Demo completion banks earned embers and updates best scores, but records neither a death nor a full-game victory.
- Meta-progression purchases and retail endless-mode actions are hidden.

## Build Contract

The three `Demo` export presets apply the `demo` feature tag and write into `exports/demo/`:

```bash
godot --headless --path . --export-release "Windows Demo"
godot --headless --path . --export-release "Linux Demo"
godot --headless --path . --export-release "macOS Demo"
```

Install the Godot `4.6.3.stable` export templates from **Editor > Manage Export Templates** before running these commands. Platform signing, notarization, and Steamworks dashboard setup remain external prerequisites. The local contract is validated with:

```bash
godot --headless --path . --script tools/check_phase7_readiness.gd
```

## Remaining Phase 7 Work

- Publish the Steam store page at least three months before launch.
- Capture and edit the gameplay trailer.
- Configure the Steam demo application and depots.
- Install export templates and produce signed release candidates.
- Complete platform smoke tests and Next Fest submission steps.
