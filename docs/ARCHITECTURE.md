# Strike Wing '94 Runtime Architecture

## Current layers

- `main.gd` owns high-level game flow, player input, mission start state, live wave progression, bounded boss overtime, normal-enemy movement, weapon tier composition, exact accuracy counters, core projectile creation, screen-bomb resolution, spawn selection and the mission-local random stream.
- `content_catalog.gd` owns JSON loading and content access helpers.
- `combat_rules.gd`, `projectile_rules.gd`, `objective_rules.gd`, `progression_rules.gd` and the other `*_rules.gd` files own pure deterministic calculations.
- Focused directors provide cross-cutting behavior that genuinely spans systems, such as boss phases, result rewards, persistent service state and presentation overlays.
- `campaign_save.gd` is the canonical campaign persistence boundary and maintains a validated backup save.
- `data/` owns authored mission, enemy, weapon and campaign definitions.

## Game flow

`TITLE -> PLAYING -> RESULT -> TITLE`

The title phase presents the active mission briefing and service/loadout state. Playing owns the timed combat run. Result records mission completion or loss and supports retry/continue behavior.

## Mission state ownership

Mission state is initialized at the source in `main.gd`.

- Serviced hull/shield values come from `ServiceDirector` when available.
- Campaign-authored hull/shield maxima provide the fallback and clamp bounds.
- The active mission's authored `starting_wave` is applied at launch.
- Live wave progression uses `MissionStateRules.live_wave()` directly from the active mission and mission clock.

The earlier `MissionStateDirector` reconciliation layer has been removed. Do not restore a post-frame correction path for values that can be initialized correctly at mission start.

## Boss overtime ownership

Required boss encounters are resolved directly by the mission loop.

- At the authored mission deadline, `MissionFlowRules.should_hold_overtime()` determines whether the required boss objective is still incomplete and that boss is still alive.
- A live required boss can extend the mission for at most `45` seconds.
- Ordinary spawning remains suppressed while the boss is alive.
- Destroying the boss during overtime can still complete the mission normally.
- Reaching the hard overtime cap fails explicitly with `BOSS OVERTIME EXPIRED` rather than hanging indefinitely.
- If no required live boss justifies overtime, normal incomplete-objective failure occurs immediately at the deadline.

The earlier `MissionFlowDirector` pre-frame timer clamp has been removed, along with its obsolete `safe_pre_frame_time()` helper. The mission clock is allowed to advance naturally; overtime is an explicit bounded game state rather than a timer-rewind workaround.

## Bomb ownership

Screen bombs are resolved directly inside the weapon action that consumes the bomb.

- Ordinary enemies are registered as destroyed and award their bomb-clear score.
- Mission bosses remain in the live enemy array.
- Bosses take bounded nonlethal damage through `BombRules.apply_nonlethal_boss_damage()`.
- Enemy projectiles are cleared by the bomb.

The earlier `BombGuardDirector` hold/remove/restore workaround has been removed. Boss survival must be decided at the actual bomb-resolution source.

## Determinism

Each mission owns a dedicated `RandomNumberGenerator` in `main.gd`. It is reseeded from `RunSeedRules.mission_seed(mission_index)` whenever the mission launches or retries.

Gameplay randomness for enemy selection, spawn position, drift, turn rate, phase, initial fire timing and pickup rolls must use that mission-local generator. `RunSeedRules` is the single seed definition; the earlier reporting-only `RunSeedDirector` has been removed so there is no second runtime seed owner.

Spawn selection is fail-closed: if no authored spawn profile matches the active environment/wave, `_spawn_candidates()` returns no candidates. It must never broaden to every non-boss archetype.

## Enemy movement ownership

Normal enemy movement is applied directly in `_update_enemies()`.

- Each spawned enemy retains its authored `pattern` and initial `pattern_anchor_x`.
- `MovementPatternRules.adjusted_position()` is applied exactly once per normal-enemy frame after base vertical travel.
- `MovementPatternRules.clamp_x()` keeps authored motion inside the playfield.
- Bosses remain under the existing boss-specific runtime behavior and are not routed through normal-enemy patterns.

The earlier `MovementPatternDirector` catalogue lookup/post-frame adjustment layer has been removed. Movement metadata travels with the spawned enemy instead of being rediscovered every frame.

## Weapon progression ownership

Permanent and temporary weapon progression are represented separately at the source.

- `weapon_index` is always the permanent paid campaign tier.
- `temporary_weapon_boost` is sortie-only state and starts at zero for every launch.
- Weapon pickups increase only `temporary_weapon_boost`, bounded by the remaining primary tiers.
- `_active_weapon()` combines the permanent tier and temporary boost through `WeaponPickupRules.effective_index()`.
- `_clear_combat()` clears the temporary boost whenever the sortie ends or is abandoned.
- `campaign_save.gd` persists `weapon_index` directly; temporary boosts never enter the save schema.

The earlier `WeaponPickupDirector` mutate/restore reconciliation layer has been removed. A temporary pickup must never mutate persistent paid progression.

## Accuracy ownership

Accuracy is measured at the exact gameplay events that define it.

- `shots_fired` and `shots_hit` are sortie-local scene counters.
- Both counters reset to zero when a new sortie starts.
- When primary fire creates `count` player projectiles, `shots_fired` increases by exactly `count`.
- When a player bullet actually collides with an enemy in `_resolve_combat()`, `shots_hit` increases once for that bullet.
- Screen bombs do not change either accuracy counter.
- `RewardDirector` reads the finished sortie's `shots_fired` / `shots_hit` values directly and delegates bonus math to `RewardRules` / `AccuracyRules`.

The earlier `AccuracyDirector` input/timer/HP-snapshot inference layer has been removed. Accuracy must never be reconstructed after the frame when the exact fire and collision events are already available.

`RewardDirector` still provides result-transition idempotency. Its applied marker is cleared whenever a new sortie enters PLAYING, so retrying the same mission can legitimately earn bonuses again while repeated processing of one RESULT cannot double-award them.

## Projectile ownership

Enemy projectile packets are created directly in `main.gd`. Missile weapons receive their homing flag, speed, turn rate and lifetime at creation time. `BossDirector` can then steer any homing projectile through one common update path.

This intentionally replaced the earlier post-frame missile-tagging reconciliation layer. Do not reintroduce `MissileBehaviorDirector` or a spawn-safety sentinel director unless the direct source-of-truth design is no longer possible.

## Persistence

`campaign_save.gd` stores the canonical persistent campaign state: credits, mission index, paid weapon tier and serviced hull/shield condition. Temporary sortie weapon boosts are deliberately excluded by construction.

Before overwriting the primary save, a supported valid primary is copied to the backup path. Restore prefers the primary and falls back to the backup if the primary is corrupt or unsupported.

## Refactor direction

Continue removing compensating directors only where a responsibility can safely live at its true source of truth. Keep presentation-only overlays separate from simulation and keep cross-cutting systems modular when they genuinely coordinate multiple owners.

Systems should exchange compact state/events rather than infer behavior from unrelated arrays or duplicate authoritative state.

## Invariants

- Damage arithmetic remains deterministic and independent of rendering.
- Mission gameplay randomness is isolated from the global RNG and owned directly by the mission scene.
- Missing spawn configuration fails closed.
- Normal enemies retain authored movement metadata and are moved once per frame at source.
- Permanent paid weapon progression is never mutated by sortie pickups.
- Temporary weapon boosts are explicit sortie state and never persisted.
- Accuracy counters are incremented at projectile creation/collision source and never inferred after the frame.
- Homing metadata is created with the projectile, not inferred later.
- Mission hull/shield/wave are initialized correctly at source, not corrected later.
- Required boss overtime is explicit, bounded and cannot hang indefinitely.
- Screen bombs cannot kill or remove required bosses.
- A new sortie resets reward idempotency so retries can earn legitimate bonuses once.
- Content IDs are stable and unique.
- Production art can replace prototype drawing without changing game rules.
- Campaign state must never depend on GitHub Actions, cloud CI or network availability.
- Save files are versioned, sanitized and recoverable from a validated backup.
