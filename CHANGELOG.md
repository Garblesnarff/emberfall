# Changelog

## 0.6.2 - Phase 6B Runtime Animation Expansion

- Added complete 8-direction crawler walk, attack, and death sequences.
- Added 8-direction Cinder-Warden locomotion, manual-fire attack, and dash sequences.
- Added explicit Blender action selection, root-motion recentering, exposure, and emission render controls.
- Kept crawler death playback non-interactive and synchronized attack feedback with actual contact damage.
- Added headless contracts for animation directions, frame budgets, loop modes, and runtime state transitions.

## 0.6.1 - Phase 6B Crawler Sprite Pipeline

- Added a local Meshy-to-Blender-to-Godot sprite pipeline for directional rendered sprites.
- Rendered the first crawler 8-direction walk sequence from the Meshy GLB export.
- Generated and wired `crawler_spriteframes.tres` into `crawler.tres`.
- Added directional enemy animation selection for generated `walk_00` through `walk_07` animations.
- Documented local Meshy key handling without storing secrets in source.

## 0.6.0 - Phase 6A Static Art Integration

- Promoted menu, wordmark, victory, defeat, boss portrait, and capsule art into production asset folders.
- Updated Forge and recap screens to load production UI art instead of concept-source paths.
- Added a static art manifest and Phase 6A readiness checker for canonical asset paths.
- Added headless tests for static art loading and production UI references.

## 0.5.16 - Manual Fire Gate

- Added a dedicated `fire` input action for left mouse / keyboard fire.
- Changed player weapons from always-on auto-fire to fire-only-while-held behavior.
- Preserved controller continuous fire while the right stick is deflected.
- Added a headless regression test for manual fire gating and heat gain.

## 0.5.15 - v4.2 Boss Spec Closure

- Made Shattered Choir bodies orbit the player at the v4.2 radius.
- Added Harrow Drossling placeholder summons under the non-boss enemy cap.
- Added Aurum Tax placeholder summons for the wave-15 duel.
- Expanded headless tests for Choir orbit/adds and Aurum Tax behavior.

## 0.5.14 - v4.2 Amendment Catch-Up

- Added the Swelter heat aura with heat-scaled slow, white-heat scorch, and placeholder heat/crown visuals.
- Added generic homing enemy projectile support and wired Choir Mourn tears through it.
- Updated the bounded boss ladder resources and behavior for Choir, Aurum, and Aurum Rekindled v4.2 specs.
- Added Shattered Choir shared-pool body fall, inheritance, tether, and reprise behavior checks.
- Added Aurum crown heat multiplier, siphon drain, wave-15 retreat, Rekindled geyser, and low-HP fervor checks.

## 0.5.13 - Phase 5 Local Completion Audit

- Added `docs/PHASE_5_LOCAL_COMPLETION_AUDIT.md` to record the local Phase 5 completion boundary.
- Linked the audit from the Steam handoff and release readiness docs.
- Expanded readiness checks to require the local completion audit and external-only remainder notes.

## 0.5.12 - Phase 5 Dashboard Checklist

- Added `docs/STEAMWORKS_DASHBOARD_CHECKLIST.md` for the future Steamworks dashboard setup pass.
- Linked the checklist to the machine-readable Steamworks manifest and readiness docs.
- Expanded readiness checks to ensure the dashboard checklist stays present and aligned with key API names.

## 0.5.11 - Phase 5 Steamworks Manifest

- Added `data/steamworks_manifest.json` as the machine-readable future Steamworks dashboard contract.
- Validated manifest achievements, stats, input actions, cloud save path, and export targets in the Phase 5 readiness checker.
- Documented the manifest as the handoff source for future Steamworks setup.

## 0.5.10 - Phase 5 Export Hygiene

- Excluded local Steam/test/export artifacts from all Steam export presets.
- Expanded the Phase 5 readiness checker to enforce export preset exclude filters.
- Documented that `steam_appid.txt` is local-only and excluded from Steam exports.

## 0.5.9 - Phase 5 Steam Input Contract

- Added stable Steam Input action names and local controller glyph fallback text.
- Documented the future Steam Input config names for the Steamworks handoff.
- Expanded readiness checks and tests to catch Steam Input action drift.

## 0.5.8 - Phase 5 Readiness Check

- Added a headless Phase 5 readiness checker for export presets, Steam API maps, gitignored local files, and handoff docs.
- Documented the readiness checker alongside the existing Godot validation commands.
- Synced project and export preset versions for the new local readiness pass.

## 0.5.7 - Phase 5 Stats and Export Sync

- Synced Steam export preset versions with the project version.
- Added local Steam stat mapping for save totals and best-run records.
- Recorded run play time into the save schema's `stats.playMs` field.
- Ensured final run recap/save data is committed before run-ended listeners react.

## 0.5.6 - Phase 5 Rich Presence Lifecycle

- Added run-started and wave-started EventBus signals for Steam-facing state updates.
- Wired SteamManager rich presence to Forge, run start, wave start, victory, and defeat states.
- Added no-Steam tests for automatic rich presence transitions.

## 0.5.5 - Phase 5 Export Readiness

- Added Steam-target Godot export presets for Windows, Linux, and macOS.
- Added release-readiness documentation for local validation, export templates, and future Steam requirements.
- Added automated checks that export presets load, use the `steam` feature tag, and write to ignored local export directories.

## 0.5.4 - Phase 5 Deck Navigation Hardening

- Added controller UI defaults for accept, cancel, and d-pad navigation.
- Added controller/keyboard action navigation for in-run upgrade choices.
- Added selected-card HUD marking for upgrade choices.
- Expanded tests for upgrade selection, UI accept/navigation mappings, and 1280x800 selected-choice readability.

## 0.5.3 - Phase 5 Audio Event Polish

- Connected AudioDirector to gameplay events for kills, hurt, boss phases, chest opens, wave clears, combo changes, and run endings.
- Added procedural placeholder WAV SFX generation and caching for Steam-free polish testing.
- Added audio intensity updates from combat pressure events.
- Expanded Phase 5 tests for event-driven audio reactions and generated SFX data.

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
