# Strike Wing '94 Runtime Architecture

## Current layers

- `main.gd` owns high-level game flow, player input, mission start state, live wave progression, bounded boss overtime, normal-enemy movement, weapon/generator progression, serviced airframe state, exact accuracy counters, mission reward payout, weapon energy, core projectile creation, screen-bomb resolution, filler spawn selection and the mission-local random stream.
- `EncounterDirector` owns authored stage sequencing: timed encounter beats, deterministic formation entry, recovery windows and performance-gated secrets.
- `BossDirector` owns boss phase-specific orchestration and homing projectile steering.
- `PixelUiDirector` owns the primary title/result/gameplay HUD, boss bar and missile-warning presentation through an original integer-grid bitmap renderer.
- `ProjectileCueDirector` remains a presentation-only overlay for projectile-local visual cues.
- `content_catalog.gd` owns JSON loading and content access helpers.
- `*_rules.gd` files own pure deterministic calculations.
- `campaign_save.gd` is the canonical campaign persistence boundary and maintains a validated backup save.
- `data/` owns authored mission, enemy, weapon, generator and campaign definitions.
- `docs/90S_SHOOTER_BIBLE.md` defines the production/game-design quality bar for the finished shooter.

## Game flow

`TITLE -> PLAYING -> RESULT -> TITLE`

The title phase presents mission briefing, weapon/generator progression and airframe servicing. Playing owns the timed combat run. Result records mission completion or loss and supports retry/continue behavior.

## Pixel-perfect UI ownership

The visible interface is rendered on the same 640x360 logical grid as gameplay.

- `PixelFont` is an original 3x5 bitmap glyph set rendered from integer `draw_rect()` pixels.
- `PixelUiSurface` is a parser-safe 640x360 draw surface owned by `PixelUiDirector`.
- Title and result phases are fully covered by the pixel UI, so the underlying prototype fallback-font text does not define the shipped presentation.
- Gameplay HUD uses hard-edged hull, shield and energy meters plus compact bomb/wave/time/score readouts.
- Boss HP/phase presentation and missile warnings are drawn by the same bitmap HUD rather than separate Godot `PanelContainer`, `Label` or `ProgressBar` widgets.
- Phase 3 retains an explicit `WEAK` cue in the boss bar.
- `ProjectileCueDirector` remains separate because it draws spatial cues around live projectiles, not UI chrome.

The earlier `BossHudDirector`, `BossHudRules` and `ThreatWarningDirector` widget layers have been removed. `ThreatWarningRules` remains as pure warning logic consumed by the pixel UI.

## Mission and airframe ownership

Mission and service state are initialized at the source in `main.gd`.

- `service_hull` and `service_shield` are persistent scene-owned campaign fields.
- Successful sorties capture their surviving hull/shield directly into those service fields.
- Failed sorties do not overwrite the pre-sortie serviced condition.
- H/J title actions repair/recharge those persistent values through `ServiceRules`.
- Campaign-authored hull/shield maxima provide clamp bounds.
- The active mission's authored `starting_wave` is applied at launch.
- Live wave progression uses `MissionStateRules.live_wave()` directly from the active mission and mission clock.

The earlier `MissionStateDirector` and `ServiceDirector` reconciliation layers have been removed. Do not restore post-frame correction paths for state that the scene can own directly.

## Generator and weapon-energy ownership

Generator progression is a permanent campaign choice and energy is sortie-local runtime state.

- `generator_index` selects the permanent purchased generator tier.
- `data/generators.json` defines capacity, recharge rate and cost.
- `energy` starts at the active generator's capacity for each sortie.
- `EnergyRules.recharge()` restores energy continuously during play.
- Primary weapons define `energy_cost` in `data/weapons.json`.
- Primary fire occurs only when `EnergyRules.can_fire()` succeeds and then consumes energy through `EnergyRules.consume()`.
- Generator upgrades improve both capacity and recharge rate, creating a sustained-fire tradeoff rather than a flat weapon-DPS ladder.
- The gameplay HUD exposes current energy through an integer pixel meter.

This system is intentionally inspired by the strategic depth of strong 1990s PC shooters while using original weapons, generator names, tuning and presentation.

## Authored encounter sequencing

Mission pacing is intentionally split between authored stage beats and filler spawning.

`EncounterDirector` is an intentional stage-script owner rather than a reconciliation layer.

- Each mission defines ordered `encounter_beats` in `data/missions.json`.
- A beat can name exact enemy archetypes/counts, an entry formation, a HUD label, a guaranteed recovery pickup and a bounded filler-spawn suppression window.
- `EncounterRules` expands enemy counts with a hard per-beat cap and validates timing, pickups, formations and secret conditions.
- The director spawns enemies through `main.gd::_spawn_enemy()`, so authored enemies use the same mission RNG, wave scaling, movement rules, combat rules and objective tracking as filler enemies.
- Immediately after spawn, only entry lane / vertical staging / `pattern_anchor_x` are adjusted to the authored formation point.
- Supported formation shapes are `line`, `wedge`, `split`, `column`, `stagger` and controlled `scatter`.
- Each mission combines at least three formation shapes, a recovery window and a boss lead-in.
- Filler spawn profiles continue between authored beats so stages stay alive without becoming fully scripted corridors.

### Mastery secrets

Each mission contains an optional performance-gated secret beat.

Supported conditions are:

- accuracy at or above a threshold with a meaningful minimum-shot sample;
- score at or above a threshold;
- conserving at least an authored number of bombs.

A missed secret is silently consumed and never blocks progression. A successful secret can create an elite encounter and/or guaranteed pickup and is briefly surfaced as `SECRET - ...`.

## Boss overtime ownership

Required boss encounters are resolved directly by the mission loop.

- At the authored mission deadline, `MissionFlowRules.should_hold_overtime()` determines whether the required boss objective is still incomplete and that boss is still alive.
- A live required boss can extend the mission for at most `45` seconds.
- Ordinary spawning remains suppressed while the boss is alive.
- Destroying the boss during overtime can still complete the mission normally.
- Reaching the hard overtime cap fails explicitly with `BOSS OVERTIME EXPIRED` rather than hanging indefinitely.

## Bomb ownership

Screen bombs are resolved directly inside the weapon action that consumes the bomb.

- Ordinary enemies are registered as destroyed and award their bomb-clear score.
- Mission bosses remain in the live enemy array.
- Bosses take bounded nonlethal damage through `BombRules.apply_nonlethal_boss_damage()`.
- Enemy projectiles are cleared by the bomb.

## Determinism

Each mission owns a dedicated `RandomNumberGenerator` in `main.gd`, reseeded from `RunSeedRules.mission_seed(mission_index)` whenever the mission launches or retries.

Gameplay randomness for enemy selection, spawn position, drift, turn rate, phase, initial fire timing and pickup rolls uses that mission-local generator. Spawn selection is fail-closed when no authored profile matches.

## Enemy movement ownership

Normal enemy movement is applied directly in `_update_enemies()`.

- Spawned enemies retain authored `pattern` and `pattern_anchor_x`.
- `MovementPatternRules.adjusted_position()` is applied exactly once per normal-enemy frame after base vertical travel.
- `MovementPatternRules.clamp_x()` keeps authored motion inside the playfield.
- Bosses remain under boss-specific runtime behavior.

## Weapon progression ownership

Permanent and temporary weapon progression are represented separately at the source.

- `weapon_index` is always the permanent paid campaign tier.
- `temporary_weapon_boost` is sortie-only state and starts at zero for every launch.
- Weapon pickups increase only the temporary boost, bounded by remaining primary tiers.
- `_active_weapon()` combines permanent tier and temporary boost through `WeaponPickupRules.effective_index()`.
- `campaign_save.gd` persists `weapon_index` directly; temporary boosts never enter the save schema.

## Accuracy and reward ownership

Accuracy and payout are resolved at their defining gameplay sources.

- `shots_fired` increments when player projectiles are created.
- `shots_hit` increments when those projectiles collide with enemies.
- `_finish_mission()` computes the complete successful payout exactly once before combat cleanup.
- Payout combines score reward, objective bonus, no-damage bonus, boss bonus and accuracy bonus through pure rules.

## Projectile ownership

Enemy projectile packets are created directly in `main.gd`. Missile weapons receive their homing flag, speed, turn rate and lifetime at creation time. `BossDirector` then steers any homing projectile through one common update path.

## Persistence

`campaign_save.gd` schema v3 stores:

- credits;
- mission index;
- permanent weapon tier;
- permanent generator tier;
- serviced hull;
- serviced shield.

Temporary sortie boosts and current energy are deliberately excluded. Supported v1/v2 saves can migrate, and valid primary state is copied to a backup before replacement.

## Refactor direction

Keep source ownership direct, presentation separate from simulation, and stage orchestration modular only when it genuinely coordinates authored level content.

The next major gameplay expansion should build on the working 1990s-shooter foundation with original support systems / wingman-style choices, more environment-specific stage presentation and stronger boss signature attacks while preserving deterministic rules and the pixel-art constraints in `90S_SHOOTER_BIBLE.md`.

## Invariants

- Gameplay randomness is isolated from the global RNG.
- Missing spawn configuration fails closed.
- Authored encounter beats are ordered, capped and never spawn bosses through the regular beat path.
- Each mission contains recovery/pacing, a mastery secret and multiple formation shapes.
- Secret conditions never block mission progression.
- Permanent progression is never mutated by temporary pickups.
- Generator tier is persistent; current energy is sortie-local.
- Accuracy and rewards are source-owned, not inferred after frames.
- Boss overtime is bounded and cannot hang indefinitely.
- Screen bombs cannot kill/remove required bosses.
- Primary interface presentation uses the original bitmap renderer and integer-grid pixel surfaces, not modern widget chrome.
- Production art follows `90S_SHOOTER_BIBLE.md`.
- Campaign state never depends on GitHub Actions, cloud CI or network availability.
- Save files are versioned, sanitized and recoverable from a validated backup.
