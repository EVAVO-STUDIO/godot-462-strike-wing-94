# Strike Wing '94 Runtime Architecture

## Current ownership model

Strike Wing uses direct source ownership for simulation state and focused directors only where a subsystem genuinely spans authored campaign data, equipment state or presentation.

The architecture rule is simple:

> If the scene can know the correct answer when the event occurs, calculate it there. Use a director only when the concept is genuinely cross-cutting and has a stable public contract.

## Core scene

`main.gd` owns:

- `TITLE -> PLAYING -> RESULT` flow;
- player movement;
- mission timer and wave progression;
- permanent weapon and generator indices exposed to persistence;
- sortie energy;
- persistent serviced hull/shield values;
- direct primary-fire projectile creation;
- permanent weapon tier plus sortie-only temporary weapon boost;
- exact shots-fired / shots-hit counters;
- normal enemy movement and projectile creation;
- normal homing missile packet creation;
- screen-bomb resolution;
- direct successful-mission reward payout;
- deterministic filler spawning through the mission-local RNG;
- craft-form multipliers at movement/fire/damage/contact source;
- hostile-projectile collision using the current VX-94 fighter/bomber hit profile.

Do not reintroduce post-frame repair layers for state that `main.gd` can calculate correctly at source.

## Runtime directors

### `CraftFormDirector`

Owns VX-94 variable geometry plus the active altitude/mission context.

Responsibilities:

- reads `data/campaign_world.json`;
- `Q` toggles fighter/bomber configuration where legal;
- 0.65 s anti-spam transform cooldown;
- 0.24 s primary/secondary weapon interlock during geometry changes;
- mission-recommended launch configuration;
- timed altitude transitions;
- forced fighter retraction when an altitude cannot support bomber geometry;
- publishes campaign technology era into `ProgressionRules`;
- publishes active generator context before tactical support runs;
- exposes movement/contact/projectile-hit/spread/damage/support multipliers;
- exposes public `mission_context()`.

`main.gd` consumes those values at the actual simulation source.

### `AirframeDirector`

Owns the persistent VX-94 structural frame tier.

Control:

- `K`: buy next airframe.

The five current tiers are:

1. Composite Frame Mk I;
2. Ceramic-Titanium Frame;
3. Reactive Alloy Frame;
4. Magneto-Composite Frame;
5. Field-Coupled Frame.

Airframe purchases use the same central technology/credit gate as weapons and generators.

`AirframeDirector` publishes the active frame into `MissionStateRules`; therefore existing `_max_hull()` / `_max_shield()` calls automatically affect:

- mission launch durability;
- servicing limits;
- tanker restoration limits;
- HUD meter maxima;
- save clamping.

Installing a larger frame does not give a free repair/refill. Existing serviced values remain and can be serviced up to the new capacity.

### `EncounterDirector`

Owns authored level scripting rather than generic random-wave repair.

- timed encounter beats;
- deterministic formation entry;
- filler-spawn suppression / breathing windows;
- guaranteed recovery pickups;
- performance-gated secrets;
- common enemy spawn path through `main.gd::_spawn_enemy()`.

Formation vocabulary:

- line;
- wedge;
- split;
- column;
- stagger;
- controlled scatter.

### `SupportDirector`

Owns the player's onboard tactical-support slot.

Current systems:

- Twin Rocket Pods;
- Crosswind Cannons;
- Hunter Rack;
- Point Defence Pod;
- EMP Disruptor;
- Magnetic Screen.

All consume the same generator energy pool as the primary weapon.

Important rules:

- bomber configuration reduces tactical-support energy cost;
- Pulse/Overdrive generators can improve matching-era tactical energy efficiency;
- EMP only targets autonomous enemies;
- EMP resistance escalates through the autonomous roster;
- Magnetic Screen bends hostile projectiles away and breaks homing rather than acting as bonus HP;
- point defence does not spend energy without a valid threat;
- public `support_state()` / `restore_support_state()` form the save boundary;
- `rearm_support()` is the Atlas tanker rearm contract.

### `DirectedEnergyDirector`

Owns the Storm Cannon's directed-energy pulse behavior.

The direct projectile remains a normal `main.gd` player projectile.

A Storm packet can discharge once when it enters a target cluster:

- 15 px trigger envelope;
- 30 px secondary pulse radius;
- maximum two secondary targets;
- one secondary damage point;
- secondary damage is nonlethal, so score/objective/destruction bookkeeping remains owned by the core collision path.

This gives Storm Cannon an area-control role without duplicating the primary kill owner.

### `BattlefieldSupportDirector`

Owns mission-assigned allied battlefield assets, separate from onboard tactical equipment.

Controls:

- `B`: cycle assigned asset;
- `F`: call selected asset.

Current assets:

- Spectre Heavy Gunship;
- Atlas Tanker;
- Rapier Fighter Flight;
- Hammer Bomber Flight;
- Cruise Missile Battery;
- Longshot Rail Battery;
- Orbital Strike Platform.

Rules:

- availability comes from mission context;
- altitude restrictions are authored per asset;
- target counts and cooldowns are bounded;
- normal kills register objective progress and score;
- boss damage is always nonlethal;
- immediate support calls have distinct pixel set-piece presentation rather than invisible damage events.

#### Atlas tanker

The tanker is an interactive mid/high-altitude support set piece.

- visible transport and hose;
- 30 px hookup radius;
- 3.5 s maintained formation requirement;
- hookup progress decays rather than resetting instantly;
- connected player receives bounded hull/shield/energy restoration;
- completion grants two bombs up to cap;
- completion resets tactical-support cooldown;
- completion refills dedicated strike ordnance.

### `StrikeOrdnanceDirector`

Owns precision ground-attack ordnance, separate from the emergency `X` screen bomb.

Control:

- `E`: release precision strike ordnance.

Rules:

- bomber configuration required;
- low/mid altitude only;
- six-round sortie rack;
- delayed impact reticle;
- low altitude has the strongest surface-strike performance;
- mid altitude is less efficient;
- prioritises ground/sea targets;
- boss damage remains nonlethal;
- Atlas tanker can refill the rack.

### `EnvironmentDirector`

Owns deterministic low-alpha pixel battlefield overlays.

Current profiles:

- coast;
- industrial;
- open water;
- high cloud;
- orbital.

Environment + active altitude drive:

- parallax rate;
- ground-detail scale;
- cloud density;
- atmospheric horizon treatment;
- ordinary ground-detail visibility.

The environment must never compromise enemy/projectile readability.

### `BossDirector`

Owns boss phase behavior, homing-projectile steering and autonomous boss signature attacks.

Autonomous signatures currently include:

- Swarm Controller converging swarm salvos;
- AI Forge Core heavy guided missile batteries;
- Orbital Command Node high-speed kinetic lanes.

Phase 3 exposes the weak point. Screen bombs and allied support can damage bosses but cannot bypass the fight by killing them outright.

### `CombatArtDirector`

Presentation-only production combat-art owner.

It draws over the simulation with hard-edged integer-grid silhouettes for:

- VX-94 fighter;
- VX-94 bomber;
- 0.34 s physical wing-sweep transition;
- mercenary aircraft;
- ground vehicles;
- naval targets;
- autonomous drones/ground machines;
- human and autonomous bosses.

Surface target art scales through `AltitudeRules.ground_scale()`:

- full scale at low altitude;
- smaller at mid altitude;
- ordinary surface silhouettes suppressed at high/orbital altitude.

The visual transform shows moving span/shoulder/engine geometry and explicit hinge marks instead of a magical morph.

See `docs/VX94_COMBAT_ART_DIRECTION.md`.

### `ElectromagneticCueDirector`

Presentation-only electromagnetic feedback:

- magnetic field cue around VX-94;
- EMP disruption marks around affected autonomous enemies.

No bloom-heavy modern sci-fi treatment.

### `ProjectileCueDirector`

Presentation-only projectile language for both enemy and player fire.

Player projectile families:

- warm ballistic streaks;
- Needle Rail kinetic dart / long wake;
- Storm Cannon compact directed-energy pulse;
- tactical-support rounds with their own green/teal signature.

Enemy projectile cues distinguish burst, cannon and homing missile threats.

### `PixelUiDirector`

Owns the primary bitmap title/result/HUD surface.

It displays:

- hull/shield/energy;
- bombs/wave/time/score;
- weapon;
- generator;
- airframe;
- tactical support;
- battlefield support;
- fighter/bomber form;
- altitude band;
- current technology era (`CONV / EM / DE / ORB` in flight);
- boss HP/phase/weak point;
- missile warning;
- encounter/support status.

Title/loadout controls currently include:

- `U` weapon;
- `G` generator;
- `K` airframe;
- `C` tactical support selection;
- `V` tactical support purchase;
- `H/J` servicing;
- `B/F` battlefield support;
- `Q` transform in flight.

Primary UI uses the original 3x5 `PixelFont` on the 640x360 logical grid, not Godot widget chrome.

## Persistence

### `CampaignSave`

Canonical campaign save schema is **v5**.

Persistent state:

- credits;
- mission index;
- permanent primary weapon tier;
- generator tier;
- airframe tier;
- serviced hull;
- serviced shield;
- tactical-support selected index;
- tactical-support highest unlocked index.

Transient state intentionally not saved:

- temporary weapon boost;
- current energy;
- active support cooldowns;
- fighter/bomber form;
- active altitude transition progress;
- current strike ordnance during an unfinished sortie.

Restore ordering is important:

1. restore airframe tier;
2. publish new durability capacity;
3. clamp serviced hull/shield against that capacity;
4. restore remaining campaign equipment/state.

This prevents an upgraded frame from being truncated to the old 100/100 base limits.

Save versions v1-v4 remain migration-compatible. A supported valid primary is copied to a backup before replacement; restore prefers primary and can recover from backup.

## Technology progression

Canonical eras:

1. advanced conventional;
2. electromagnetic;
3. directed energy;
4. strategic orbital.

`ProgressionRules` carries the current campaign era and fails closed on malformed required technology.

The central gate is used by:

- primary weapons;
- generators;
- airframes;
- tactical-support equipment.

Already-owned later technology remains usable when replaying earlier missions, but new purchases and temporary weapon boosts cannot jump ahead of the active campaign era.

## Primary weapon identities

Current primary progression includes seven tiers.

Notable late-game identities:

### Needle Rail

- electromagnetic era;
- precision kinetic role;
- one fast projectile;
- two additional penetrations;
- one accuracy hit maximum per fired slug even when it pierces several targets.

### Storm Cannon

- directed-energy era;
- three strong compact pulse packets;
- tight spread;
- high generator demand;
- bounded one-shot secondary cluster discharge;
- visually distinct pulse language.

The technology ladder should create battlefield roles rather than only larger damage numbers.

## Variable-geometry VX-94

The craft is a physically coherent 1999 imagined-future aerospace weapon, not a humanoid/mecha transformation.

### Fighter

- swept narrow planform;
- faster movement;
- tighter body/projectile hit profiles;
- tighter primary spread;
- better air effectiveness;
- high/orbital preference.

### Bomber

- broad deployed wing;
- slower movement;
- wider risk profile;
- wider primary coverage;
- stronger surface/ship effectiveness;
- more efficient tactical-support energy use;
- precision strike ordnance availability;
- low-altitude preference.

## Four altitude bands

1. low;
2. mid;
3. high;
4. orbital / atmosphere-space.

Altitude changes:

- surface visual scale;
- surface-vs-air effectiveness;
- support availability;
- environment presentation;
- legal craft configuration.

Current authored dynamic transitions include:

- Black Flag: mid -> low sea-skimming attack -> mid flagship fight;
- Black Horizon: high -> orbital breakout.

Orbital flight requires fighter configuration.

## Campaign structure

Current playable campaign contains nine missions.

### Act I: Mercenary War

1. Coastal Intercept
2. Refinery Run
3. Black Sea
4. Breakwater
5. Furnace Line
6. Black Flag

### Act II: Autonomous Drone War

7. Ghost Sky
8. Machine Furnace
9. Black Horizon

The second act introduces autonomous fighters, bombers, missile nodes, armour, factory defences, exo drones, orbital sentries and three autonomous bosses.

### External contact

External/alien contact remains defined as a future threat phase but is intentionally not yet inserted into playable missions. The military/AI war must remain the core identity long enough for any external escalation to feel earned.

## Authored stage rhythm

Every current mission includes:

- at least five encounter beats;
- at least three formation geometries;
- a recovery/pacing window;
- a performance mastery secret;
- a boss lead-in;
- deterministic filler spawns between authored beats.

Secrets currently use accuracy, score or conserved-bomb gates and never block progression.

## Determinism

Each sortie owns a dedicated `RandomNumberGenerator` seeded through `RunSeedRules.mission_seed(mission_index)` on launch/retry.

Gameplay randomness uses that stream. Missing spawn profiles fail closed rather than broadening to arbitrary enemies.

## Removed reconciliation layers

These obsolete repair systems must remain absent:

- SpawnSafetyDirector;
- MissileBehaviorDirector;
- MissionStateDirector;
- BombGuardDirector;
- MissionFlowDirector;
- MovementPatternDirector;
- RunSeedDirector;
- WeaponPickupDirector;
- AccuracyDirector;
- RewardDirector;
- ServiceDirector;
- BossHudDirector;
- ThreatWarningDirector.

Their responsibilities were moved to source ownership or intentionally consolidated presentation owners.

## Validation

`tools/validate.ps1` performs structural/data/save checks without network or paid CI.

When Godot 4.6.2 is available locally it runs focused suites covering:

- base runtime rules;
- rewards/accuracy;
- service/energy/airframes/directed energy;
- mission flow/projectiles;
- save recovery/migration;
- authored encounters/secrets/formations;
- tactical support;
- craft form/altitude/interlock/tech HUD;
- battlefield support/tanker/set pieces;
- environment presentation;
- strike ordnance;
- technology progression;
- autonomous boss signatures;
- production combat art;
- editor smoke parsing.

## Remaining production cutover

`main.gd` still contains temporary prototype player/enemy drawing underneath `CombatArtDirector`.

Do **not** add another masking layer.

Once a real Godot visual smoke/playtest confirms the production combat-art layer correctly covers every live target family, remove the prototype player/enemy drawing directly from `main.gd` so `CombatArtDirector` becomes the sole combat-art presentation owner.

## Invariants

- No GitHub Actions or paid cloud runtime dependency.
- Gameplay remains usable offline.
- Campaign saves are versioned, sanitized and backup-recoverable.
- Gameplay randomness is isolated from the global RNG.
- Missing content fails closed.
- Boss bypass through bombs/support/secondary Storm discharge is prohibited.
- Transformation and altitude are real gameplay systems.
- Orbital combat requires fighter geometry.
- Tactical support and battlefield support remain distinct concepts.
- Airframe installation never grants a free service refill.
- Environment and combat-art layers never compromise projectile/enemy readability.
- Pixel presentation follows `docs/90S_SHOOTER_BIBLE.md`.
- Campaign/world canon follows `docs/CAMPAIGN_CANON.md`.
