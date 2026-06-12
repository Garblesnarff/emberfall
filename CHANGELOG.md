# Changelog

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
