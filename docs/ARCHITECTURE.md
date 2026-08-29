# Strike Wing '94 Runtime Architecture

## Current layers

- `main.gd` owns high-level game flow, player input, mission start state, live wave progression, bounded boss overtime, normal-enemy movement, weapon/generator progression, serviced airframe state, exact accuracy counters, mission reward payout, weapon energy, core projectile creation, screen-bomb resolution, spawn selection and the mission-local random stream.
- `content_catalog.gd` owns JSON loading and content access helpers.
- `combat_rules.gd`, `projectile_rules.gd`, `objective_rules.gd`, `progression_rules.gd` and the other `*_rules.gd` files own pure deterministic calculations.
- Focused directors are now limited to genuinely cross-cutting boss/presentation behavior rather than post-frame state reconciliation.
- `campaign_save.gd` is the canonical campaign persistence boundary and maintains a validated backup save.
- `data/` owns authored mission, enemy, weapon, generator and campaign definitions.
- `docs/90S_SHOOTER_BIBLE.md` defines the production/game-design quality bar for the finished shooter.

## Game flow

`TITLE -> PLAYING -> RESULT -> TITLE`

The title phase presents mission briefing, weapon/generator progression and airframe servicing. Playing owns the timed combat run. Result records mission completion or loss and supports retry/continue behavior.

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
- The gameplay HUD exposes current energy as a percentage.

This system is intentionally inspired by the strategic depth of strong 1990s PC shooters while using original weapons, generator names, tuning and presentation.

## Boss overtime ownership

Required boss encounters are resolved directly by the mission loop.

- At the authored mission deadline, `MissionFlowRules.should_hold_overtime()` determines whether the required boss objective is still incomplete and that boss is still alive.
- A live required boss can extend the mission for at most `45` seconds.
- Ordinary spawning remains suppressed while the boss is alive.
- Destroying the boss during overtime can still complete the mission normally.
- Reaching the hard overtime cap fails explicitly with `BOSS OVERTIME EXPIRED` rather than hanging indefinitely.
- If no required live boss justifies overtime, normal incomplete-objective failure occurs immediately at the deadline.

The earlier `MissionFlowDirector` pre-frame timer clamp has been removed, along with its obsolete `safe_pre_frame_time()` helper.

## Bomb ownership

Screen bombs are resolved directly inside the weapon action that consumes the bomb.

- Ordinary enemies are registered as destroyed and award their bomb-clear score.
- Mission bosses remain in the live enemy array.
- Bosses take bounded nonlethal damage through `BombRules.apply_nonlethal_boss_damage()`.
- Enemy projectiles are cleared by the bomb.

The earlier `BombGuardDirector` hold/remove/restore workaround has been removed.

## Determinism

Each mission owns a dedicated `RandomNumberGenerator` in `main.gd`. It is reseeded from `RunSeedRules.mission_seed(mission_index)` whenever the mission launches or retries.

Gameplay randomness for enemy selection, spawn position, drift, turn rate, phase, initial fire timing and pickup rolls must use that mission-local generator. `RunSeedRules` is the single seed definition; the earlier reporting-only `RunSeedDirector` has been removed.

Spawn selection is fail-closed: if no authored spawn profile matches the active environment/wave, `_spawn_candidates()` returns no candidates. It must never broaden to every non-boss archetype.

## Enemy movement ownership

Normal enemy movement is applied directly in `_update_enemies()`.

- Each spawned enemy retains its authored `pattern` and initial `pattern_anchor_x`.
- `MovementPatternRules.adjusted_position()` is applied exactly once per normal-enemy frame after base vertical travel.
- `MovementPatternRules.clamp_x()` keeps authored motion inside the playfield.
- Bosses remain under the existing boss-specific runtime behavior and are not routed through normal-enemy patterns.

The earlier `MovementPatternDirector` catalogue lookup/post-frame adjustment layer has been removed.

## Weapon progression ownership

Permanent and temporary weapon progression are represented separately at the source.

- `weapon_index` is always the permanent paid campaign tier.
- `temporary_weapon_boost` is sortie-only state and starts at zero for every launch.
- Weapon pickups increase only `temporary_weapon_boost`, bounded by the remaining primary tiers.
- `_active_weapon()` combines permanent tier and temporary boost through `WeaponPickupRules.effective_index()`.
- `_clear_combat()` clears the temporary boost whenever the sortie ends or is abandoned.
- `campaign_save.gd` persists `weapon_index` directly; temporary boosts never enter the save schema.

The earlier `WeaponPickupDirector` mutate/restore reconciliation layer has been removed.

## Accuracy and reward ownership

Accuracy and payout are both resolved at their defining gameplay sources.

- `shots_fired` and `shots_hit` are sortie-local scene counters.
- Both counters reset to zero when a new sortie starts.
- Primary fire increments `shots_fired` by the exact number of projectiles created.
- A player projectile collision increments `shots_hit` exactly once for that projectile.
- Screen bombs do not affect accuracy counters.
- `_finish_mission()` computes the complete successful payout exactly once before combat cleanup.
- The payout combines score reward, objective bonus, no-damage bonus, boss bonus and accuracy bonus through `RewardRules` / `AccuracyRules`.
- The result line is built from that same single payout calculation.

The earlier `AccuracyDirector` HP-snapshot inference layer and `RewardDirector` result-transition layer have both been removed.

## Projectile ownership

Enemy projectile packets are created directly in `main.gd`. Missile weapons receive their homing flag, speed, turn rate and lifetime at creation time. `BossDirector` can then steer any homing projectile through one common update path.

This intentionally replaced the earlier post-frame missile-tagging reconciliation layer.

## Persistence

`campaign_save.gd` schema v3 stores the canonical persistent campaign state:

- credits;
- mission index;
- permanent weapon tier;
- permanent generator tier;
- serviced hull;
- serviced shield.

Temporary sortie weapon boosts and current sortie energy are deliberately excluded.

The loader accepts supported older v1/v2 campaign saves. Before overwriting the primary save, a supported valid primary is copied to the backup path. Restore prefers the primary and falls back to the backup if the primary is corrupt or unsupported.

## Refactor direction

Continue removing compensating directors only where a responsibility can safely live at its true source of truth. Keep presentation-only overlays separate from simulation and keep cross-cutting systems modular when they genuinely coordinate multiple owners.

The next major design expansion should favor authored 1990s-shooter depth: secondary/rear systems, wingman/drone choices, encounter blocks, secret/bonus routes and stronger audiovisual identity, while maintaining deterministic rules and the pixel-art production constraints in `90S_SHOOTER_BIBLE.md`.

## Invariants

- Damage arithmetic remains deterministic and independent of rendering.
- Mission gameplay randomness is isolated from the global RNG and owned directly by the mission scene.
- Missing spawn configuration fails closed.
- Normal enemies retain authored movement metadata and are moved once per frame at source.
- Permanent paid weapon progression is never mutated by sortie pickups.
- Temporary weapon boosts are explicit sortie state and never persisted.
- Generator tier is persistent; current energy is sortie-local.
- Stronger sustained fire requires sufficient generator output.
- Accuracy counters are incremented at projectile creation/collision source and never inferred after the frame.
- Successful mission payout is calculated and applied exactly once in `_finish_mission()`.
- Homing metadata is created with the projectile, not inferred later.
- Mission hull/shield/wave are initialized correctly at source, not corrected later.
- Successful sorties capture service condition; failed sorties do not overwrite it.
- Required boss overtime is explicit, bounded and cannot hang indefinitely.
- Screen bombs cannot kill or remove required bosses.
- Content IDs are stable and unique.
- Production art must follow the pixel-grid/readability rules in `90S_SHOOTER_BIBLE.md`.
- Campaign state must never depend on GitHub Actions, cloud CI or network availability.
- Save files are versioned, sanitized and recoverable from a validated backup.
