# Strike Wing '94 Runtime Architecture

## Current layers

- `main.gd` owns high-level game flow, player input, mission start state, live wave progression, bounded boss overtime, normal-enemy movement, weapon/generator progression, serviced airframe state, exact accuracy counters, mission reward payout, weapon energy, core projectile creation, screen-bomb resolution, filler spawn selection and the mission-local random stream.
- `SupportDirector` owns the permanent tactical support loadout, unlock/selection state, support cooldowns and support activation behavior.
- `EncounterDirector` owns authored stage sequencing: timed encounter beats, deterministic formation entry, recovery windows and performance-gated secrets.
- `BossDirector` owns boss phase-specific orchestration and homing projectile steering.
- `PixelUiDirector` owns the primary title/result/gameplay HUD, boss bar and missile-warning presentation through an original integer-grid bitmap renderer.
- `ProjectileCueDirector` remains a presentation-only overlay for projectile-local visual cues.
- `content_catalog.gd` owns JSON loading and content access helpers.
- `*_rules.gd` files own pure deterministic calculations.
- `campaign_save.gd` is the canonical campaign persistence boundary and maintains a validated backup save.
- `data/` owns authored mission, enemy, weapon, generator, support-system and campaign definitions.
- `docs/90S_SHOOTER_BIBLE.md` defines the production/game-design quality bar for the finished shooter.

## Game flow

`TITLE -> PLAYING -> RESULT -> TITLE`

The title phase presents mission briefing, weapon/generator/support progression and airframe servicing. Playing owns the timed combat run. Result records mission completion or loss and supports retry/continue behavior.

## Pixel-perfect UI ownership

The visible interface is rendered on the same 640x360 logical grid as gameplay.

- `PixelFont` is an original 3x5 bitmap glyph set rendered from integer `draw_rect()` pixels.
- `PixelUiSurface` is a parser-safe 640x360 draw surface owned by `PixelUiDirector`.
- Title and result phases are fully covered by the pixel UI, so the underlying prototype fallback-font text does not define the shipped presentation.
- Gameplay HUD uses hard-edged hull, shield and energy meters plus compact bomb/wave/time/score readouts.
- Boss HP/phase presentation and missile warnings are drawn by the same bitmap HUD rather than separate Godot widget panels.
- Phase 3 retains an explicit `WEAK` cue in the boss bar.
- Selected support identity is visible in both title/shop and gameplay HUD.
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

The earlier `MissionStateDirector` and `ServiceDirector` reconciliation layers have been removed.

## Generator and weapon-energy ownership

Generator progression is a permanent campaign choice and energy is sortie-local runtime state.

- `generator_index` selects the permanent purchased generator tier.
- `data/generators.json` defines capacity, recharge rate and cost.
- `energy` starts at the active generator's capacity for each sortie.
- `EnergyRules.recharge()` restores energy continuously during play.
- Primary weapons define `energy_cost` in `data/weapons.json`.
- Primary fire occurs only when enough energy is available and then consumes its authored cost.
- Generator upgrades improve both capacity and recharge rate.
- Tactical support systems draw from that same energy pool, so generator choice affects both primary sustained fire and support availability.

## Tactical support-system ownership

`SupportDirector` provides a second permanent tactical build dimension without copying another game's front/rear/sidekick slot structure.

Current original support packages are:

- `Twin Rocket Pods`: efficient twin forward burst.
- `Crosswind Cannons`: wide three-way coverage.
- `Hunter Rack`: slower homing support rounds with bounded turn rate/lifetime.
- `Point Defence Pod`: removes only a bounded number of nearby hostile projectiles inside an authored radius.

Controls:

- `C` cycles among unlocked support systems on the title screen.
- `V` purchases the next support unlock.
- `Z` activates the selected support during a sortie.

Rules:

- Support unlock costs increase through the authored catalogue.
- Selected support can never exceed the highest unlocked tier.
- Offensive support projectiles use the same player projectile array/collision path as primary fire.
- Offensive support creation increments `shots_fired`, so the existing accuracy statistic remains internally consistent when support shots score hits.
- Hunter rounds are steered before the scene's normal projectile movement step.
- Point defence does not spend energy if no hostile projectile is inside its radius.
- Point defence has both radius and maximum-target caps and is not a screen-clear substitute.
- Support activation has its own cooldown and consumes the shared generator energy pool.

`SupportDirector.support_state()` and `restore_support_state()` are the public persistence boundary for support selection/unlocks.

## Authored encounter sequencing

Mission pacing is intentionally split between authored stage beats and filler spawning.

`EncounterDirector` is an intentional stage-script owner rather than a reconciliation layer.

- Each mission defines ordered `encounter_beats` in `data/missions.json`.
- A beat can name exact enemy archetypes/counts, an entry formation, a HUD label, a guaranteed recovery pickup and a bounded filler-spawn suppression window.
- `EncounterRules` validates timing, enemy caps, pickups, formations and secret conditions.
- Authored enemies still spawn through `main.gd::_spawn_enemy()` and therefore share the common RNG/scaling/movement/combat/objective path.
- Supported formation shapes are `line`, `wedge`, `split`, `column`, `stagger` and controlled `scatter`.
- Each mission combines multiple formation shapes, a recovery window, a mastery secret and a boss lead-in.

### Mastery secrets

Each mission contains an optional performance-gated secret beat using accuracy, score or conserved-bomb conditions. Missing a secret never blocks progression; successful discovery can produce an elite encounter and/or guaranteed pickup.

## Boss overtime ownership

Required boss encounters are resolved directly by the mission loop with a hard 45-second overtime cap. Ordinary spawning remains suppressed while a required boss is alive, and expired overtime fails explicitly rather than hanging.

## Bomb ownership

Screen bombs are resolved directly inside the weapon action. Ordinary enemies can be cleared; mission bosses stay in the live array and take bounded nonlethal bomb damage. Enemy projectiles are cleared.

## Determinism

Each mission owns a dedicated `RandomNumberGenerator` in `main.gd`, reseeded from `RunSeedRules.mission_seed(mission_index)` whenever the mission launches or retries. Spawn selection is fail-closed when no authored profile matches.

## Enemy movement ownership

Normal enemy movement is applied directly in `_update_enemies()`. Spawned enemies retain authored `pattern` and `pattern_anchor_x`; bosses remain under boss-specific behavior.

## Weapon progression ownership

- `weapon_index` is always the permanent paid campaign tier.
- `temporary_weapon_boost` is sortie-only state.
- Pickups increase only the temporary boost.
- `_active_weapon()` combines permanent tier and temporary boost.
- Temporary boosts never enter the save schema.

## Accuracy and reward ownership

- `shots_fired` increments when offensive player projectiles are created, including offensive support projectiles.
- `shots_hit` increments when those projectiles collide with enemies.
- `_finish_mission()` computes the successful payout exactly once before cleanup.
- Payout combines score, objective, no-damage, boss and accuracy bonuses.

## Projectile ownership

Enemy projectile packets are created directly in `main.gd`. Missile homing metadata exists from creation. Support Hunter rounds use a separate player-side homing tag owned by `SupportDirector` before normal bullet movement.

## Persistence

`campaign_save.gd` schema v4 stores:

- credits;
- mission index;
- permanent weapon tier;
- permanent generator tier;
- serviced hull;
- serviced shield;
- selected support index;
- highest unlocked support index.

Temporary weapon boosts, current energy and support cooldown are deliberately excluded. Supported v1-v3 saves remain migration-compatible. Valid primary saves are backed up before replacement.

## Refactor direction

Keep source ownership direct, presentation separate from simulation, and stage/loadout orchestration modular only where it genuinely owns a distinct game concept.

The next major expansion should move into environment-specific pixel stage presentation/parallax and stronger boss signature attacks, because the campaign/loadout systems now have substantially more depth than the prototype battlefield art.

## Invariants

- Gameplay randomness is isolated from the global RNG.
- Missing spawn configuration fails closed.
- Authored encounter beats are ordered, capped and never spawn bosses through the regular beat path.
- Secret conditions never block mission progression.
- Permanent progression is never mutated by temporary pickups.
- Weapon, generator and support choices create interacting campaign tradeoffs.
- Support point defence remains spatially and numerically bounded.
- Accuracy and rewards are source-owned, not inferred after frames.
- Boss overtime is bounded and cannot hang indefinitely.
- Screen bombs cannot kill/remove required bosses.
- Primary interface presentation uses the original bitmap renderer and integer-grid pixel surfaces.
- Production art follows `90S_SHOOTER_BIBLE.md`.
- Campaign state never depends on GitHub Actions, cloud CI or network availability.
- Save files are versioned, sanitized and recoverable from a validated backup.
