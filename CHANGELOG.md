# Changelog

## 0.5.2 - Phase 5 Control Hardening

- Added dedicated right-stick aim InputMap actions for Steam Input readiness.
- Added keyboard rebinding persistence through save settings.
- Added controller-focusable rebind and reset controls to Settings.
- Updated Phase 5 tests for right-stick aim, rebind persistence, Settings display, and reset behavior.
- Brought README and version docs up to the current Phase 5 version.

## 0.5.1 - Phase 5 Debug and Controller Defaults

- Added controller defaults for movement, dash, and pause.
- Added a lightweight debug strip with FPS, state, wave, and Steam availability.
- Improved menu focus defaults for controller navigation.

## 0.5.0 - Phase 5 Steam-Ready Foundations

- Added Steam-safe manager scaffolding that no-ops without GodotSteam.
- Added achievement event plumbing and local achievement/stat surfaces.
- Added pause and settings menus with persisted audio, shake, display, minimap, and FPS settings.
- Added AudioDirector bus, pool, volume, intensity, and pause foundations.
- Added Steam handoff documentation for future Steamworks setup.

## 0.4.0 - Phase 4 Meta & Bosses

- Added Forge menu, recap flow, concept art integration, meta-progression, and boss/victory flow foundations.

## 0.3.0 - Phase 3 Systems

- Added weapons, temperings, synergies, evolutions, objectives, drops, and chest upgrade flow.

## 0.2.0 - Phase 2 World

- Added full arena layout data with circular terrain blockers, lava strips, central anvil landmark, and visible world boundary.
- Added terrain collision for the player, custom terrain resolution for enemies, and projectile blocking against pillars.
- Added lava damage ticking for the player and enemies.
- Added minimap and edge threat chevrons for elite, boss, and boss-telegraph threats.
- Added splitter, hound, and Kilnmaw data resources.
- Implemented splitter child spawning, hound telegraphed charges, and Kilnmaw ring, fan, and charge patterns.
- Added boss telegraphing and fixed Kilnmaw landmark spawning on wave 5.
- Added LOD behavior that skips enemy separation checks beyond 1.5 viewports.
- Expanded the headless test harness with intentional scripted survival through wave 6.

## 0.1.0 - Phase 1 Core Port

- Created the Godot 4.6.3 GDScript project skeleton.
- Added Phase 1 autoloads and config structure.
- Implemented fixed 60 Hz core simulation.
- Implemented player movement, aim, dash, i-frames, auto-fire, hitstop, and screen shake constants from the prototype.
- Added spatial grid collision and packed-array MultiMesh bullet managers.
- Added data-driven crawler, brute, and spitter enemy resources.
- Added procedural placeholder SpriteFrames for enemies.
- Added basic arena, camera, and HUD.
- Added headless tests for determinism, pool integrity, spatial grid behavior, and prototype feel-parity constants.
