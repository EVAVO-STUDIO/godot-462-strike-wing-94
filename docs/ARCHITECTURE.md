# Strike Wing '94 Runtime Architecture

## Current layers

- `main.gd` owns high-level game flow, player input, mission start state, live wave progression, bounded boss overtime, core projectile creation, screen-bomb resolution, spawn selection and the mission-local random stream.
- `content_catalog.gd` owns JSON loading and content access helpers.
- `combat_rules.gd`, `projectile_rules.gd`, `objective_rules.gd`, `progression_rules.gd` and the other `*_rules.gd` files own pure deterministic calculations.
- Focused directors provide cross-cutting behavior that genuinely spans systems, such as boss phases, movement patterns, temporary weapon progression, rewards, persistent service state and presentation overlays.
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

Gameplay randomness for enemy selection, spawn position, drift, turn rate, phase, initial fire timing and pickup rolls must use that mission-local generator. `RunSeedDirector` may expose/report the current seed, but it must not mutate Godot's global RNG.

Spawn selection is fail-closed: if no authored spawn profile matches the active environment/wave, `_spawn_candidates()` returns no candidates. It must never broaden to every non-boss archetype.

## Projectile ownership

Enemy projectile packets are created directly in `main.gd`. Missile weapons receive their homing flag, speed, turn rate and lifetime at creation time. `BossDirector` can then steer any homing projectile through one common update path.

This intentionally replaced the earlier post-frame missile-tagging reconciliation layer. Do not reintroduce `MissileBehaviorDirector` or a spawn-safety sentinel director unless the direct source-of-truth design is no longer possible.

## Persistence

`campaign_save.gd` stores the canonical persistent campaign state: credits, mission index, paid weapon tier and serviced hull/shield condition. Temporary sortie weapon boosts are deliberately excluded.

Before overwriting the primary save, a supported valid primary is copied to the backup path. Restore prefers the primary and falls back to the backup if the primary is corrupt or unsupported.

## Refactor direction

Continue removing compensating directors only where a responsibility can safely live at its true source of truth. Keep presentation-only overlays separate from simulation and keep cross-cutting systems modular when they genuinely coordinate multiple owners.

Systems should exchange compact state/events rather than infer behavior from unrelated arrays or duplicate authoritative state.

## Invariants

- Damage arithmetic remains deterministic and independent of rendering.
- Mission gameplay randomness is isolated from the global RNG.
- Missing spawn configuration fails closed.
- Homing metadata is created with the projectile, not inferred later.
- Mission hull/shield/wave are initialized correctly at source, not corrected later.
- Required boss overtime is explicit, bounded and cannot hang indefinitely.
- Screen bombs cannot kill or remove required bosses.
- Content IDs are stable and unique.
- Production art can replace prototype drawing without changing game rules.
- Campaign state must never depend on GitHub Actions, cloud CI or network availability.
- Save files are versioned, sanitized and recoverable from a validated backup.
