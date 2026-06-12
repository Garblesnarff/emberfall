# EMBERFALL v4 — Steam Edition PRD & Technical Architecture (Godot 4)
**Prepared for:** Codex agentic implementation (`/goal` workflow)
**Input artifacts:** This document + `emberfall.html` (the v2 JavaScript prototype — now the PLAYABLE DESIGN REFERENCE, not the codebase)
**Owner:** Rob / Hanson Foundry
**Target:** Steam (Windows/macOS/Linux + Steam Deck Verified)
**Date:** 2026-06-11
**Supersedes:** EMBERFALL_v3_PRD.md (web edition). This document is self-contained; do not consult v3.

---

## 0. How to Use This Document (Codex Instructions)

- **Engine: Godot 4.x (latest stable), GDScript.** Decision record in §1.2 — do not propose Unity, Phaser, or staying in vanilla JS.
- `emberfall.html` is the **reference implementation for game feel and balance**. When this document says "match the prototype," open that file and extract the exact constants (shake decay 0.85, hitstop frames, dash 9 frames at 13px/f with 14f i-frames, fire rates, enemy stats, scaling formulas). Feel parity with the prototype is an acceptance criterion, not a suggestion.
- Implement in **phase order** (§10). Each phase's Definition of Done gates the next.
- The **headless test suite (§9) must stay green** at every merge. A phase with red tests is not done.
- All tunables live in **Resource files (`.tres`) or `Config` autoload** — never inline in logic.
- Performance budgets (§8.5) are hard requirements. Degrade features, never frame rate.
- Art is produced by a parallel human+AI pipeline (§7). Code must never block on art: every entity ships with a **procedural placeholder** (colored polygon matching the prototype's shapes) behind the same SpriteFrames interface, swapped when real sheets land.

---

## 1. Vision, Market & Decision Records

### 1.1 Product vision
EMBERFALL is a forge-themed arena survivors-like: **twin-stick aimed combat × Vampire Survivors build-chasing × pre-rendered 3D art** (the Halls of Torment / Dead Cells pipeline). Charcoal-and-amber Hanson Foundry aesthetic. Sessions of 15–25 minutes; a run ends in victory at wave 20 (Aurum kill) or death; meta-progression makes every run a deposit.

**Market positioning:** $4.99–$7.99 launch price (verify genre comps at launch), survivors-like + twin-stick hybrid. Differentiators: aimed combat (most survivors-likes are auto-aim), dash-through-everything mobility, objective-driven movement (the genre's weakness is standing still), and a cohesive pre-rendered forge aesthetic.

### 1.2 Decision records (settled — do not relitigate)
| Decision | Choice | Rationale |
|---|---|---|
| Engine | **Godot 4 + GDScript** | Dedicated 2D renderer, native multi-platform Steam export, MIT license, GodotSteam for Steamworks, built-in input/audio/UI. Web prototype proved the design; Steam target demands native runtime. |
| Entity art | **Pre-rendered 3D → sprite sheets** | Meshy → Blender → orthographic renders. ~90% of real-time 3D's richness, zero per-frame lighting cost, consistency by construction (one lighting rig), preserves the entity budget the genre depends on. Proven commercially (Halls of Torment, Dead Cells). |
| Static/marketing art | **GPT Image 2** | Near-perfect text rendering (capsules/logos), reasoning mode, multi-image character consistency for portrait sets. |
| Physics | **Custom (ported from prototype)** for combat; Godot physics only for player-vs-terrain | Circle math + spatial grid already proven at target entity counts; avoids physics-engine overhead per projectile. |
| Networking | None. Single-player only. | Scope. |

---

## 2. Game Design Specification

> Mechanics below are the validated prototype design plus the v3 design work. Numbers marked ⟨proto⟩ must be extracted from `emberfall.html` verbatim.

### 2.1 Core loop
Move (WASD/left stick) + aim (mouse/right stick) + auto-fire + dash (Space/RT, i-frames, passes through everything) → clear waves → pick 1-of-3 Temperings between waves → chase synergies/evolutions → defeat 3 named bosses → wave 20 victory or death → bank embers → spend in Forge menu → run again.

### 2.2 World
- World 3200×2400 units, camera-follow with aim lookahead 80u, exponential lerp 0.08, clamped to bounds.
- Terrain: 4–7 circular pillars (block all movement + projectiles both sides), 2–3 lava strips (4 dmg/0.5s to player AND enemies; dash crosses safely), central anvil landmark, visible forge-wall boundary.
- Enemies spawn 60–140u outside the camera rect (never on-screen); bosses spawn at fixed landmarks with 1.5s telegraph.
- Minimap (toggleable) + edge-of-screen threat chevrons (elite/boss/objective, max 12, priority-sorted).

### 2.3 Player ⟨proto⟩
HP 100, speed/dash/i-frame/knockback values from prototype. Combo: +1 per kill, 3s decay, resets on damage taken, score multiplier ×(1+⌊combo/8⌋). Low-HP state <25%: heartbeat audio layer + pulsing vignette.

### 2.4 Enemies (base roster ⟨proto⟩ + elites)
crawler, brute, spitter (kiting ranged), splitter (→2 child crawlers), hound (telegraphed charge). Elite chance min(0.03+wave×0.006, 0.22): ×2.6 HP, ×1.12 speed, ×1.3 dmg, whitehot ring, guaranteed drop. HP scale: 1 + w×0.32 + w^1.6×0.02. Spawn director: queue per wave, active cap (§8.5), spawn interval max(6, 40−2w) ticks.

### 2.5 Wave objectives (one per wave, ~1-in-3 waves none)
1. **Ember Vein** — far-spawned harvest zone, 4s cumulative channel, +heart +25 embers +150 score, erupts 6 crawlers on first touch.
2. **Reignite the Braziers** — light 3 braziers (0.8s channel, damage interrupts) before wave end → bonus free Tempering pick.
3. **Distant Elite Bounty** — marked far elite, 45s despawn, drops a **chest** + 200 score.
- **Anvil Defense** (waves 7, 13, 19): anvil HP 300+40w; nearby enemies prefer it; survival offers a +30 max-HP blessing as a 4th card.

### 2.6 Weapons (pick at run start; unlocked via Forge)
| Weapon | Pattern | Identity |
|---|---|---|
| Forgehammer | aimed volley (prototype behavior) | balanced default |
| Slag Lance | slow single bolt, innate pierce 2 | sniper |
| Ember Maw | 130u cone, 8 ticks/s, applies burn | facehug DPS |
Each weapon levels to 5 via "Sharpen" cards always present in the pool.

### 2.7 Temperings (in-run upgrades) ⟨proto, 14 cards + 3 Forge-unlocked: Thorns, Magnet Coil, Second Wind⟩

### 2.8 Synergies (auto-active when requirements held; hinted on cards)
Detonating Brand (Branding Iron + Killing Edge≥2: burn deaths explode) · Arc Steel (Chain Spark≥2 + Piercing Slag≥2: instant arcs, +1 bounce) · Bulwark Orbit (Orbiting Anvil≥2 + Reforged Heart≥2: anvils eat enemy projectiles) · Blast Furnace (Nova Dash + Branding Iron: igniting nova, kills refund 30% dash) · Overclocked Bellows (Bellows≥4 + Quenched Legs≥2: stand-still 1s → +40% fire rate).

### 2.9 Evolutions (weapon L5 + linked Tempering + open a chest)
Forgehammer + Twin Hammers L3 → **Meteor Volley** (overhead AoE crashes at cursor) · Slag Lance + Piercing Slag L4 → **Railspike** (hitscan beam, 0.9s rhythm) · Ember Maw + Branding Iron → **Crucible Breath** (2× cone, 3-stack burn, burning ground). Chest UX: 0.3× slow-mo 1.2s, escalating SFX, reveal.

### 2.10 Bosses (chest + 100 embers each; intro banner + unique silhouette)
- **W5 — KILNMAW, The First Breach:** prototype moveset (ring / aimed fan / telegraphed charge).
- **W10 — THE SHATTERED CHOIR:** 3 bodies, shared HP bar, rotating synced fire; each ⅓ HP lost kills a body, survivors speed up.
- **W15 — AURUM, Forge-Tyrant:** P1 summons + lava pools; P2 (<50%) armor cracks, gains charge + 270° sweeping beam (1s telegraph, 3s sweep, dashable).
- **W20 — AURUM REKINDLED** (victory fight): Aurum + Kilnmaw pattern set. Kill = **FORGE SECURED** ending → stat recap, embers ×1.5, choose End Run / Endless (bosses cycle with stacking modifiers).

### 2.11 Meta-progression (Forge menu)
Embers bank 100% on death/victory. Unlocks: Slag Lance / Ember Maw (300 ea), Tempered Skin I–III (+5 HP; 150/300/600), Deep Pockets I–II (+10/20% embers; 200/400), Old Flame (start with 1 random Tempering; 250), card-pool unlocks ×3 (200 ea). First unlock reachable in ~2 median runs.

### 2.12 Stretch (post-launch candidates, do NOT build pre-1.0)
Daily Forge (seeded daily run), 2nd biome, additional weapons, leaderboards.

---

## 3. Godot Architecture

### 3.1 Project structure
```
emberfall/
├─ project.godot
├─ addons/godotsteam/          # GodotSteam GDExtension (§6)
├─ autoload/                   # singletons
│  ├─ Config.gd                # all tunables not in .tres
│  ├─ EventBus.gd              # global signals (§3.4)
│  ├─ GameState.gd             # run state machine: MENU/PLAY/UPGRADE/PAUSE/OVER/VICTORY
│  ├─ SaveManager.gd           # versioned save (§3.6)
│  ├─ MetaProgression.gd       # ember bank, unlocks
│  ├─ AudioDirector.gd         # SFX pools + layered music (§5)
│  └─ SteamManager.gd          # wraps GodotSteam; no-ops when Steam absent
├─ scenes/
│  ├─ main.tscn                # boot → menu
│  ├─ arena/arena.tscn         # world, terrain, camera, spawners
│  ├─ player/player.tscn
│  ├─ enemies/enemy.tscn       # ONE generic enemy scene, data-driven (§3.3)
│  ├─ bosses/boss.tscn         # generic boss scene + pattern components
│  ├─ projectiles/             # bullet_manager.tscn (player), enemy_bullet_manager.tscn
│  ├─ pickups/pickup.tscn, chest.tscn
│  ├─ vfx/                     # particles, dnums, nova, telegraphs
│  └─ ui/                      # hud.tscn, upgrade_panel.tscn, forge_menu.tscn,
│                              # pause.tscn, recap.tscn, settings.tscn, minimap.tscn
├─ scripts/systems/            # waves.gd, objectives.gd, combat.gd, synergies.gd,
│                              # spatial_grid.gd, camera_rig.gd, input_router.gd
├─ data/                       # ALL content as custom Resources (.tres)
│  ├─ enemies/*.tres           # EnemyData: stats, ai_profile, sprite_frames, drops
│  ├─ weapons/*.tres           # WeaponData incl. evolution requirements
│  ├─ temperings/*.tres        # TemperingData incl. synergy links
│  ├─ bosses/*.tres            # BossData: pattern list, phases
│  └─ arena_layout.tres        # terrain placement (seeded variants)
├─ assets/
│  ├─ sprites/{enemies,player,bosses,fx,ui}/   # sheets from the art pipeline (§7)
│  ├─ portraits/, capsules/                    # GPT Image 2 outputs
│  └─ audio/                                   # if any baked; default is synth (§5)
└─ test/                       # gdUnit4 suites (§9)
```

### 3.2 Simulation model (performance-critical — read carefully)
- **Fixed tick:** all gameplay in `_physics_process` at 60 Hz (`physics_ticks_per_second=60`). Prototype frame-count timers port 1:1 as tick counts. Hitstop/slow-mo via `Engine.time_scale` EXCEPT audio scheduling (real time).
- **Enemies:** pooled instances of one generic `enemy.tscn` (Node2D + AnimatedSprite2D), **no physics bodies**. Movement/collision = ported circle math + `spatial_grid.gd` (cell 80u, rebuilt per tick — port the prototype grid verbatim).
- **Projectiles: never one-node-per-bullet.** `bullet_manager.gd` owns packed arrays (pos/vel/life/pierce/bounce) and renders all bullets via **MultiMeshInstance2D** (one for player bullets, one per enemy-bullet color). Collision via the spatial grid.
- **Particles:** Godot `GPUParticles2D` for ambient embers/lava; pooled `CPUParticles2D` or a MultiMesh micro-system for burst effects (pick one; budget §8.5).
- **Damage numbers:** pooled Label nodes capped at 70, merge same-target hits within 6 ticks.
- **Player terrain collision:** CharacterBody2D vs StaticBody2D pillars/walls only (the one place Godot physics is used).
- **Culling:** Godot culls rendering automatically; the LOD rule still applies — enemies >1.5 viewports away skip separation checks and burn-particle emission.
- **Seeded RNG:** single `RandomNumberGenerator` in Config, seed logged per run (enables Daily Forge later + deterministic tests).

### 3.3 Data-driven content contract
Adding an enemy = 1 `EnemyData.tres` + (optionally) one named function in `ai_profiles.gd` + a SpriteFrames resource. Same pattern for weapons/temperings/bosses. **No stats in logic, ever.** Boss movesets compose named patterns from `patterns.gd` (ring, fan, charge, sweep_beam, summon, sync_rotate) — bosses are data lists of patterns, not bespoke scripts.

### 3.4 EventBus signals
`enemy_killed(data)`, `player_hurt(amount, source)`, `boss_phase(boss, phase)`, `chest_opened(contents)`, `wave_cleared(wave)`, `objective_done(id)`, `combo_changed(n)`, `run_ended(victory, stats)`. SFX, music intensity, VFX, shake, combo, stats, and **achievements** are all listeners. Combat never calls juice directly.

### 3.5 Input (input_router.gd)
Godot InputMap actions: move_*/aim via mouse position or right stick (deadzone 0.18 radial, last-input-wins arbitration), dash, pause. Controller: continuous fire while right stick deflected, reticle at aim×120u. Glyphs via Steam Input when available (§6).

### 3.6 Save (user://emberfall.save, JSON, versioned)
`{v:4, best:{wave,score,combo}, bank:{embers}, unlocks:{weapons,perks,cards}, settings:{sfx,music,shake,dnums,minimap,fps}, stats:{runs,kills,deaths,playMs,victories}}`. Corrupt → back up + fresh defaults, never crash. **Steam Cloud enabled** for this file (§6).

---

## 4. UI/UX Specification

- HUD: HP bar + dash meter (top-left), wave + remaining + objective (top-center), score/combo/embers (top-right), minimap (bottom-right), synergy icon row under HP.
- Upgrade panel: 3 cards (4 with anvil blessing), level badges, synergy/evolution "UNLOCKS:" hints. Full controller navigation (focus order on every panel — Steam Deck requirement).
- Death recap: killer name, wave, duration, build icons, embers banked, forge-flavored epitaph table. Victory recap: same + FORGE SECURED banner.
- Settings: SFX/music volume, screen-shake 0–100% (doubles as photosensitivity control; flash intensity follows it), damage numbers, minimap, FPS overlay, fullscreen/vsync, rebindable keys (Godot InputMap UI).
- Accessibility invariant: every threat distinguishable by **shape**, not color alone (prototype already complies — preserve when art lands).
- Auto-pause on focus loss; pause suspends audio.

---

## 5. Audio

- **SFX:** port the prototype's synthesized palette. Implementation: pre-render the synth SFX to short WAVs at build time via a Godot tool script (procedural authoring, baked runtime — best of both), played through pooled AudioStreamPlayers with ±5% pitch jitter; kill-streak pitch rises with combo (cap +4 semitones).
- **Music:** layered intensity stems, A minor ~92 BPM. Layer 0 drone (always) / 1 percussion (wave≥2) / 2 driving bass (combo>10 or boss) / 3 arp+hats (boss). Implemented as 4 synced AudioStreamPlayers with gain fades over 1 bar. Stems may be rendered from ZzFXM patterns offline or composed in any DAW — delivery is just 4 looping OGGs, ~2MB total.
- Boss themes: layer-3 variant per named boss (same stems, different arp pattern) — cheap identity.

---

## 6. Steam Integration (SteamManager autoload)

- **GodotSteam** GDExtension. ALL Steam calls behind SteamManager; game runs perfectly with Steam absent (dev + DRM-free builds).
- **Achievements (launch set, listeners on EventBus):** First Light (win wave 1), Slagbreaker (kill Kilnmaw), Choir Silencer (kill Choir), Tyrant's End (kill Aurum), FORGE SECURED (win a run), Untouchable (clear a wave ≥10 without damage), Centurion (100-kill combo), Evolved (first evolution), Full Bank (1000 embers banked), Old Hand (25 runs).
- **Steam Cloud:** the save file. **Rich presence:** "Wave 12 — Forging".
- **Steam Input:** official controller configs; show Steam glyphs when active.
- **Steam Deck Verified checklist (treat as requirements):** full controller support incl. all menus, legible text at 1280×800, default-to-gamepad when launched on Deck, no keyboard-required moments, stable 60 (or capped 40) on Deck hardware.
- Store assets via GPT Image 2 (§7.3). Verify current Steamworks capsule dimensions at upload time.

---

## 7. Art Pipeline (parallel track — Rob + Claude/Codex agents)

### 7.1 Entity pipeline: Meshy → Blender → sprite sheets
1. **Generate** (Meshy MCP / Claude Code skill): text-to-3D or image-to-3D per entity; Smart Remesh for clean topology; PBR textures in the forge palette (charcoal #15110c, ember #ffae42, hot #ff5e2b, slag-blue #4aa3b8 for ranged enemies). Auto-rig + animation where applicable (walk/attack/death).
2. **Stage** (Blender, driven via Blender MCP): import into the **master render template** `forge_rig.blend` — a single shared scene with: orthographic camera at the game's top-down-oblique angle (~50° pitch), three-point forge lighting (warm key from center-world direction, cool slag rim, low amber fill), transparent background, fixed unit scale (1 Blender unit = 32 px at render).
3. **Render** (Blender Python script, committed to repo): for each entity × animation: **8 directions × N frames** → PNG sequence → packed sheet. Naming: `{entity}_{anim}_{dir}_{frame}.png` → `{entity}.png` atlas + generated `SpriteFrames.tres`.
4. **Import:** Godot import preset (filter off for crisp pixels or on for painterly — pick ONE look in the first art review and lock it).
- **Sheet budgets:** small enemies 64–96 px/frame, brutes 128, bosses 256–320, player 96. Walk 8f, attack 6f, death 8f, idle 4f. Keep total VRAM for sprites <512MB uncompressed; use Godot's VRAM compression.
- **Consistency rule:** every entity renders through `forge_rig.blend`, no per-entity lighting edits. Cohesion is the pipeline's whole point.
- Player readability rule: the player must be the brightest whitehot element on screen; enemies stay in ember/red/slag bands.

### 7.2 VFX
Glows/trails/novas remain procedural in-engine (shaders + particles), matching the prototype's additive look. Do not pre-render VFX.

### 7.3 Static art (GPT Image 2)
Steam capsules (all required sizes), logo (its text rendering makes wordmark-in-art viable), three boss portraits + Aurum Rekindled variant (generate as one multi-image consistent set), victory/death screen art, Forge menu background. Same palette prompt block for everything. Budget: whatever looks best — these aren't runtime-constrained.

### 7.4 Placeholders
Until sheets land, every EnemyData points at procedurally generated placeholder SpriteFrames (the prototype's polygon shapes drawn to textures at boot). The game must always be fully playable art-free.

---

## 8. Performance

### 8.5 Budgets (Config constants, hard caps)
| Resource | Cap |
|---|---|
| Active enemies | 80 (raised from web's 60 — native headroom; spawn director queues the rest) |
| Player bullets | 300 (MultiMesh pool) |
| Enemy bullets | 500 (MultiMesh pools) |
| Burst particles | 600 across pools |
| Damage numbers | 70 (with merge rule) |
| Frame target | 60 FPS desktop & Steam Deck; sim ≤6ms, render ≤6ms on Deck |
- Debug overlay (backtick): FPS, sim/render ms, entity counts, grid cells, AI states, camera rect. Stripped from release builds via feature flag.

---

## 9. Testing (gdUnit4 + headless CI)

Run via `godot --headless` on every phase completion and before any task is declared done.
1. **Full-run sim:** scripted input + direct state manipulation drives waves 1–21: all enemy types, splitter children, elites, every objective type completing AND failing, all three bosses (Choir body-count assertions, Aurum phase-2 transition), chest→evolution, victory path, endless entry, death path, restart.
2. **Forced-build tests:** each weapon, each synergy, each evolution active for 600 ticks; assert expected damage events fire.
3. **Determinism:** same seed + scripted input twice → identical kill count at tick 5000.
4. **Save round-trip + corruption fallback + migration from missing file.**
5. **Pool integrity:** caps never exceeded; no orphaned active entities after run teardown.
6. **Feel-parity spot checks:** dash distance/duration, shake decay, hitstop length equal prototype constants ±0 (they're just numbers — assert them).

---

## 10. Phases & Definition of Done

| Phase | Scope | DoD |
|---|---|---|
| **1. Core port** | Project skeleton, autoloads, fixed-tick sim, spatial grid, player (move/dash/fire), MultiMesh bullets, crawler+brute+spitter via EnemyData, placeholder art system, HUD basics | Feel parity with prototype confirmed side-by-side; tests 3/5/6 green; 60 FPS at caps |
| **2. World** | Full arena + terrain, camera rig, culling/LOD, minimap, threat chevrons, off-screen spawning, splitter/hound/elites, Kilnmaw | Test 1 through wave 6; Deck-resolution legibility check |
| **3. Systems** | Waves/objectives/anvil defense, all Temperings, synergies, weapons, evolutions, chests, drops/combo/score | Tests 1–2 full green |
| **4. Meta & bosses** | Forge menu, save/cloud-ready schema, Choir, Aurum, victory/endless, recaps | Test 4 green; fresh-save-to-first-unlock ≤2 median runs |
| **5. Steam & polish** | GodotSteam, achievements, Steam Input/Deck pass, settings, audio (SFX bake + music stems), pause/focus handling, debug strip | Deck checklist complete; achievement events verified |
| **6. Art integration** | Sprite sheets replace placeholders as they land (parallel from Phase 2), boss portraits, capsules | One look locked; readability rule holds at max chaos |
| **7. Release prep** | Steam page (EARLY — wishlists start at page-live, not launch), trailer capture, demo build for Next Fest, pricing, build pipeline for Win/macOS/Linux | Page live ≥3 months pre-launch; demo = waves 1–7, Kilnmaw, 1 weapon |

**Guardrails:** no engine swaps, no networking, no additional languages (GDScript only; C# only if a profiled hotspot demands it — flag first). Permitted addons: GodotSteam, gdUnit4. Everything else needs a decision record added to §1.2.

---

## 11. Marketing-Adjacent Notes (for Rob, not Codex)
- The **Steam page is the launch:** capsule + 5 screenshots of maximum readable chaos + 30s gif-able trailer moments (nova through a horde, Aurum beam dash-through, evolution reveal slow-mo).
- Next Fest demo is the single biggest wishlist lever for this genre.
- The prototype remains a free web demo candidate (itch.io) pointing at the Steam page — zero extra work, pure funnel.