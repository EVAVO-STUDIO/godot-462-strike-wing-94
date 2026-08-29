# Strike Wing '94 Runtime Architecture

## Current layers

- `main.gd` owns high-level game flow, player input, core projectile creation, spawn selection and the mission-local random stream.
- `content_catalog.gd` owns JSON loading and content access helpers.
- `combat_rules.gd`, `projectile_rules.gd`, `objective_rules.gd`, `progression_rules.gd` and the other `*_rules.gd` files own pure deterministic calculations.
- Focused directors provide cross-cutting runtime behavior such as boss phases, overtime, movement patterns, temporary weapon progression, rewards, service state and UI overlays.
- `campaign_save.gd` is the canonical campaign persistence boundary and maintains a validated backup save.
- `data/` owns authored mission, enemy, weapon and campaign definitions.

## Game flow

`TITLE -> PLAYING -> RESULT -> TITLE`

The title phase presents the active mission briefing and service/loadout state. Playing owns the timed combat run. Result records mission completion or loss and supports retry/continue behavior.

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

Continue removing compensating directors when a responsibility can safely live at its true source of truth. Good candidates are hard-coded mission-start state and screen-bomb behavior. Keep presentation-only overlays separate from simulation.

Systems should exchange compact state/events rather than infer behavior from unrelated arrays or duplicate authoritative state.

## Invariants

- Damage arithmetic remains deterministic and independent of rendering.
- Mission gameplay randomness is isolated from the global RNG.
- Missing spawn configuration fails closed.
- Homing metadata is created with the projectile, not inferred later.
- Content IDs are stable and unique.
- Production art can replace prototype drawing without changing game rules.
- Campaign state must never depend on GitHub Actions, cloud CI or network availability.
- Save files are versioned, sanitized and recoverable from a validated backup.
