# EMBERFALL v4.2 Catch-Up Audit

Version: `0.5.15`

This audit records the Godot-side catch-up to the EMBERFALL v4.2 amendment before Phase 6 art integration.

## Implemented

- Swelter heat aura:
  - Heat-scaled aura radius and slow use the v4.2 values in `Config`.
  - Normal enemies inside the aura are slowed; bosses are not slowed.
  - White-heat scorch starts at 70 Forge Heat and scales from current shot damage.
  - Placeholder aura ring and heat-scaled crown visuals are drawn on the Cinder-Warden.
- Bounded boss ladder:
  - Core mode bosses are fixed at wave 5 Kilnmaw, wave 10 Choir, wave 15 Aurum, wave 20 Aurum Rekindled.
  - Core mode does not repeat bosses after wave 20; Endless remains an optional victory-lap flow.
- Homing projectile primitive:
  - Enemy bullets now support a generic homing strength field.
  - Shattered Choir Mourn tears use that homing flag.
- Shattered Choir:
  - Single shared HP pool represented by the boss health.
  - Focused body damage determines which body falls at 67% and 34%.
  - Survivors inherit fallen voices and speed up as bodies fall.
  - Beat intervals tighten from 60 to 42 to 30 ticks.
  - Mourn, Vesper, and Harrow attack primitives are represented.
  - Tether telegraph/snap state and segment damage are implemented.
  - Reprise/final chord/shatter state is implemented.
- Aurum / Aurum Rekindled:
  - Wave 15 Aurum uses crown integrity HP and heat-based damage multipliers.
  - Siphon drains Forge Heat while the player is on the active beam.
  - Crown crack triggers retreat state and does not end the run in victory.
  - Wave 20 Aurum Rekindled uses exposed HP, geysers, barrage/sweep/slam primitives, low-HP fervor, and victory on death.
- Re-Strikings direction:
  - Existing meta remains unlock-first and avoids large flat-power expansion.
  - No unspecced v4.2 future synergy/build-archetype content was added.

## Verified

- Custom headless suite covers:
  - Swelter tuning and effects.
  - Homing projectile steering.
  - Boss ladder placement and no core repeat after wave 20.
  - Aurum cold/white-heat crown multipliers.
  - Choir focused fall order, inheritance, beat tightening, homing tears, tether damage, reprise, and shatter.
  - Aurum siphon, retreat, Rekindled geyser damage, and low-HP fervor.
- gdUnit resource contracts cover v4.2 boss resource stats and pattern names.
- Phase 5 readiness check remains compatible with the `0.5.14` version bump.

## Deferred

- Final rendered art and animation polish remain Phase 6 work.
- Future build archetypes, additional synergies, and deeper Re-Strikings content remain deferred until a later amendment specifies tuned values.
