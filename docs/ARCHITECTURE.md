# Strike Wing '94 Runtime Architecture

## Current layers

- `main.gd` owns high-level game flow, player input, temporary rendering and orchestration.
- `content_catalog.gd` owns JSON loading and content access helpers.
- `combat_rules.gd` owns pure combat arithmetic and timing rules that should remain testable without scene state.
- `data/` owns authored mission, enemy, weapon and campaign definitions.

## Game flow

`TITLE -> PLAYING -> RESULT -> TITLE`

The title phase presents the active mission briefing. Playing owns the timed combat run. Result records mission completion or loss and supports retry/continue behavior.

## Refactor direction

As gameplay grows, move responsibilities out of `main.gd` in this order:

1. projectile simulation
2. enemy/spawn director
3. player aircraft state
4. mission controller
5. campaign/profile persistence
6. presentation/HUD

Systems should exchange compact state/events rather than reaching into each other's internal arrays.

## Invariants

- Damage arithmetic remains deterministic and independent of rendering.
- Content IDs are stable and unique.
- Production art can replace prototype drawing without changing game rules.
- Campaign state must never depend on GitHub Actions, cloud CI or network availability.
- Save files should eventually be versioned and migration-safe.
