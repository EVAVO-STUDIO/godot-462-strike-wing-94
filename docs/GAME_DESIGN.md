# Strike Wing '94 — Game Design Foundation

## North star

Build an original 1990s PC vertical combat shooter with immediate arcade handling, readable battlefield threats, satisfying weapon progression, and a campaign/shop loop that feels native to the DOS/VGA era without reproducing proprietary content from any existing game.

## Core loop

1. Read a short mission briefing.
2. Choose weapons and consumables within a budget.
3. Fly a 2D vertical-scrolling combat mission.
4. Destroy air and ground targets while managing hull, shields and limited secondary weapons.
5. Defeat a set-piece boss or objective.
6. Convert score/objective completion into credits and medals.
7. Repair, upgrade and move to the next mission.

## Combat rules

- Movement must remain responsive and predictable.
- Air targets can collide with the player and later gain projectile attacks.
- Ground targets are distinct from air targets and will use ground-targeting weapons once that system lands.
- Primary weapons are repeatable and upgradeable.
- Secondary weapons are powerful, limited and tactical.
- Damage is absorbed by shields before hull.
- Enemy patterns should be learnable rather than random noise.
- Bosses should expose readable phases and destructible sub-targets.

## Presentation

- Internal canvas: 640×360, nearest-neighbour filtering.
- Chunky, authored pixel silhouettes rather than smooth vector art in production.
- High-contrast HUD with compact numeric information.
- Palette and typography should evoke 1993–1996 PC action games while remaining original.
- Production art replaces the current code-drawn placeholders without changing the gameplay interfaces.

## Content architecture

- `data/weapons.json`: weapon definitions and economy values.
- `data/missions.json`: campaign mission metadata.
- Future data files: enemy archetypes, bosses, shops, upgrades, difficulty profiles and campaign state.
- Gameplay code should consume IDs and data rather than branching on display names.

## Near-term implementation order

1. Split player, projectile, enemy and mission director into dedicated scripts/nodes.
2. Load weapons and missions from JSON.
3. Add enemy projectiles and ground targets.
4. Add objective completion/failure states.
5. Add mission briefing and debrief screens.
6. Add credits, repair and shop progression.
7. Add first boss with multiple phases.
8. Add audio event hooks and production pixel assets.
9. Add deterministic test scenarios and headless smoke validation.
10. Add controller mappings and export presets only after the desktop loop is stable.

## Guardrails

- No copied maps, sprites, names, sound effects, UI layouts or enemy designs from Raptor, Raiden, Tyrian or other reference games.
- No paid GitHub Actions requirement. Validation must run locally and be suitable for the existing EVAVO local automation/tooling stack.
- Temporary generated/build/cache files must stay out of Git.
