# VX-94 Craft and Altitude System

This document is the implementation contract for the VX-94 Strike Wing variable-geometry aircraft and the four-altitude combat model.

## Variable-geometry craft

The VX-94 is one physically continuous aircraft. It does not transform into a humanoid/mech form.

The cockpit, fuselage, engines and core structure remain recognisable while wing sweep, lifting surfaces, hardpoint posture and control geometry change between two combat configurations.

### Fighter configuration

Purpose: interception, dogfighting, upper atmosphere and orbital combat.

Runtime characteristics:

- movement multiplier: 1.16;
- tighter body-contact profile;
- primary spread multiplier: 0.78;
- air-target attack multiplier: 1.18;
- normal tactical-support energy consumption;
- visually narrow swept-wing silhouette.

### Bomber configuration

Purpose: terrain following, bombing, anti-armour, anti-ship and sustained support-heavy strike work.

Runtime characteristics:

- movement multiplier: 0.82;
- wider body-contact profile;
- primary spread multiplier: 1.22;
- primary direct damage multiplier: 1.12;
- ground/sea attack multiplier: 1.35 before altitude modifier;
- tactical-support energy cost multiplier: 0.88;
- visually broad deployed-wing silhouette.

### Transformation

- default input: `Q`;
- short 0.65 second transformation lockout;
- mission context chooses the recommended configuration on mission change;
- low/mid/high altitude can use both configurations;
- orbital combat locks the craft to fighter configuration;
- transformation must remain a tactical decision, never a rapid animation exploit.

Final sprite animation should visibly move wing sweep and hardpoint geometry through a small number of hand-authored pixel frames.

## Altitude bands

### Low

Ground visual scale: 1.00.

Gameplay:

- strongest ground/sea interaction;
- terrain, buildings, roads, armour and ships appear largest;
- ground attack receives altitude multiplier 1.25;
- air attack receives altitude multiplier 0.90;
- bomber configuration is normally preferred;
- gunship, bomber and missile support are especially appropriate.

### Mid

Ground visual scale: 0.68.

Gameplay:

- hybrid air/surface combat;
- low cloud bands can cross the battlefield;
- both forms are useful;
- ground attack multiplier 0.92;
- air attack multiplier 1.00;
- tanker hookups are available on assigned missions.

### High

Ground visual scale: 0.34.

Gameplay:

- cloud-top interception;
- conventional ground targets no longer form the normal combat vocabulary;
- ground attack multiplier 0.45;
- air attack multiplier 1.12;
- fighter configuration is strongly preferred;
- tanker, fighter and rail support become important.

`Ghost Sky` is the first current high-altitude mission.

### Orbital / atmosphere-space

Ground visual scale: 0.12.

Gameplay:

- no normal terrain-target combat;
- fighter configuration mandatory;
- air/orbital attack multiplier 1.18;
- sparse stars, atmospheric curvature/glow and orbital structures replace normal terrain motifs;
- rail/orbital support can appear;
- autonomous exo-drones and orbital sentries become the normal combat vocabulary.

`Black Horizon` is the first current orbital mission.

## Damage interaction

Player projectile damage is resolved from three layers:

1. authored weapon/support damage;
2. craft-form attack multiplier;
3. altitude target-class multiplier.

Surface classes are `ground` and `sea`; normal aerial/boss classes use the air multiplier.

This means form and altitude both have tactical meaning. A bomber at low altitude is substantially better at attacking surface forces, while a fighter at high/orbital altitude is substantially better against aerial threats.

Boss-specific rules still take precedence where required (for example, nonlethal screen-bomb or allied-support damage).

## Environment presentation

`EnvironmentDirector` renders deterministic, low-alpha pixel overlays over the prototype battlefield.

Environment profiles:

- coast;
- industrial;
- open water;
- high cloud;
- orbital.

Altitude affects:

- parallax velocity;
- terrain-detail scale;
- cloud density;
- horizon glow;
- whether normal ground detail is present.

The overlay must never obscure combat silhouettes. Environment richness should come from structured pixel motifs and palette/scroll behaviour, not blur, bloom or noisy particles.

## Campaign phase transition

Current mission order now contains two implemented acts.

### Mercenary War

Missions 1-6:

1. Coastal Intercept
2. Refinery Run
3. Black Sea
4. Breakwater
5. Furnace Line
6. Black Flag

These establish the 1999 near-future military world and gradually introduce electromagnetic technology.

### Autonomous Drone War

Missions 7-9:

7. Ghost Sky - first high-altitude swarm engagement and Swarm Controller boss.
8. Machine Furnace - human holdouts and autonomous factory forces overlap; AI Forge Core boss.
9. Black Horizon - first atmosphere/orbital assault; Orbital Command Node boss.

This overlap is intentional. The human enemy does not vanish the instant the AI becomes active.

### External Contact

Still reserved for later campaign work. No alien faction has been inserted into the current nine missions.

## Battlefield support

Mission context assigns a limited list of allied assets. The player cycles assigned support with `B` and calls it with `F`.

Current support catalogue:

- Spectre Heavy Gunship;
- Atlas Tanker;
- Rapier Fighter Flight;
- Hammer Bomber Flight;
- Cruise Missile Battery;
- Longshot Rail Battery;
- Orbital Strike Platform.

Every support package is altitude-gated.

### Atlas tanker hookup

The Atlas is the first fully spatial support set piece.

- available only at mid/high altitude on assigned missions;
- visible large transport silhouette and trailing hose;
- player must hold inside a 30 px hookup radius;
- connection must be maintained for 3.5 seconds;
- breaking formation decays progress gradually rather than instantly resetting it;
- while connected, energy, shield and hull recover at bounded rates;
- full hookup adds two bombs (capped at five) and resets tactical-support cooldown;
- failure to complete before the tanker window closes yields no completion reward.

The final art pass should show a recognisable future tanker, articulated hose/basket and an obvious but compact connection cue.

## Allied strike safety

Battlefield support is powerful but cannot replace boss gameplay.

- ordinary support kills register normal objective destruction and score;
- support attacks are target-count bounded;
- boss damage is clamped nonlethally to at least 1 HP;
- orbital strike is not a universal screen delete;
- cooldowns remain long enough that support is a strategic event rather than a second primary weapon.

## Controls

- movement: WASD / arrows;
- primary: Space;
- screen bomb: X;
- tactical support: Z;
- transform fighter/bomber: Q;
- cycle tactical support: C;
- buy tactical support: V;
- cycle battlefield support: B;
- call battlefield support: F;
- buy primary: U;
- buy generator: G;
- hull service: H;
- shield service: J.

## Remaining direct integration work

Do not add a collision-reconciliation director.

The player-body contact profile is already form-aware. The remaining collision refinement is to make the hostile-projectile hit radius directly consume a dedicated fighter/bomber projectile-hit profile inside `main.gd::_update_enemy_bullets()`. That should be done at the source in the scene on the next safe direct scene edit.
