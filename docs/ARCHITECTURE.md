# Strike Wing '94 Runtime Architecture

## Current ownership model

Strike Wing uses direct source ownership for simulation state and focused directors only where a subsystem genuinely spans authored campaign data, equipment state or presentation.

Architecture rule:

> If the scene can know the correct answer when the event occurs, calculate it there. Use a director only when the concept is genuinely cross-cutting and has a stable public contract.

## Core scene

`main.gd` owns:

- `TITLE -> PLAYING -> RESULT` flow;
- player movement;
- mission timer and wave progression;
- permanent weapon/generator indices exposed to persistence;
- sortie energy;
- persistent serviced hull/shield values;
- direct primary-fire projectile creation;
- permanent weapon tier plus sortie-only temporary boost;
- exact shots-fired / shots-hit counters;
- normal enemy movement/projectile creation;
- normal homing missile packets;
- screen-bomb resolution;
- direct successful-mission reward payout;
- deterministic filler spawning through the mission-local RNG;
- craft-form multipliers at movement/fire/damage/contact source;
- hostile-projectile collision using the active fighter/bomber hit profile.

Do not reintroduce post-frame repair layers for state that can be correct at source.

## Runtime directors

### `CraftFormDirector`

Owns VX-94 variable geometry plus active altitude/mission context.

- reads `data/campaign_world.json`;
- `Q` toggles fighter/bomber where legal;
- 0.65 s anti-spam cooldown;
- 0.24 s primary/secondary weapons interlock during geometry changes;
- mission-recommended launch configuration;
- timed altitude transitions;
- forced fighter retraction where bomber geometry is illegal;
- publishes campaign technology era into `ProgressionRules`;
- publishes active generator context before tactical support runs;
- exposes movement/contact/projectile-hit/spread/damage/support multipliers;
- exposes public `mission_context()`.

### `AirframeDirector`

Owns persistent VX-94 structural frame tier.

Control:

- `K`: buy next airframe.

Current frames:

1. Composite Frame Mk I
2. Ceramic-Titanium Frame
3. Reactive Alloy Frame
4. Magneto-Composite Frame
5. Field-Coupled Frame

The active frame is published into both:

- `MissionStateRules` for hull/shield capacity;
- `CombatRules` for bounded incoming-damage resistance.

Current incoming-damage multipliers progress from `1.00` to `0.80`.

Airframes therefore change the existing canonical durability model rather than creating another hidden health pool.

Installing a larger frame never grants a free repair/refill. Existing serviced values remain and may then be serviced up to the new capacity.

### `EncounterDirector`

Owns authored stage sequencing:

- timed encounter beats;
- deterministic formation entry;
- filler-spawn suppression / breathing windows;
- recovery pickups;
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

Owns onboard tactical support.

Current systems:

- Twin Rocket Pods;
- Crosswind Cannons;
- Hunter Rack;
- Point Defence Pod;
- EMP Disruptor;
- Magnetic Screen.

Rules:

- common generator energy pool;
- bomber support-energy bonus;
- matching-era generator efficiency;
- EMP only affects autonomous units;
- EMP resistance escalates but never becomes immunity;
- Magnetic Screen bends hostile projectiles and breaks homing;
- point defence does not spend energy without a threat;
- public `support_state()` / `restore_support_state()` save boundary;
- `rearm_support()` Atlas contract.

### `DirectedEnergyDirector`

Owns Storm Cannon pulse discharge.

The direct Storm projectile remains a normal player projectile in `main.gd`.

A Storm packet may discharge once:

- 15 px trigger envelope;
- 30 px secondary radius;
- max two secondary targets;
- one secondary damage point;
- secondary damage always nonlethal.

Kills, score and objective bookkeeping therefore stay in the normal collision path.

### `BattlefieldSupportDirector`

Owns mission-assigned allied assets, separate from onboard tactical equipment.

Controls:

- `B`: cycle assigned support;
- `F`: call selected support.

Current assets:

- Spectre Heavy Gunship;
- Atlas Tanker;
- Rapier Fighter Flight;
- Hammer Bomber Flight;
- Cruise Missile Battery;
- Longshot Rail Battery;
- Orbital Strike Platform.

Rules:

- mission-context availability;
- altitude restrictions;
- bounded target counts/cooldowns;
- normal kills register objective progress and score;
- boss damage is nonlethal;
- fighter/bomber/gunship/missile/rail/orbital calls have distinct pixel set pieces.

#### Atlas tanker

- mid/high altitude only;
- visible transport/hose;
- 30 px hookup radius;
- 3.5 s maintained formation;
- hookup progress decays rather than resets;
- bounded hull/shield/energy restoration;
- +2 bombs up to cap;
- tactical support reset;
- precision strike ordnance refill.

### `StrikeOrdnanceDirector`

Owns precision ground attack, separate from the `X` emergency screen bomb.

Control:

- `E`: release strike ordnance.

Rules:

- bomber form required;
- low/mid altitude only;
- six-round sortie rack;
- delayed targeting/impact;
- strongest at low altitude;
- surface/ship target preference;
- nonlethal boss handling;
- Atlas can refill it.

### `EnvironmentDirector`

Owns deterministic low-alpha battlefield overlays.

Profiles:

- coast;
- industrial;
- open water;
- high cloud;
- orbital.

Environment + active altitude drive parallax, target scale, cloud density, horizon treatment and ordinary surface-detail visibility.

### `BossDirector`

Owns boss phase behavior, homing steering and autonomous signature attacks.

Current bespoke autonomous bosses:

1. Swarm Controller
2. AI Forge Core
3. Orbital Command Node
4. Phase Control Array
5. Station Warden
6. Machine Ark

Each has its own signature interval, projectile count, damage/speed curve and telegraph.

Late signatures include phase-array crosslocks, Warden energy-grid salvos and Machine Ark strategic kinetic lanes.

Phase 3 exposes the weak point. Screen bombs, battlefield support and Storm secondary discharge cannot bypass boss fights.

### `CombatArtDirector`

Presentation-only combat-art owner.

Draws hard-edged integer-grid silhouettes for:

- VX-94 fighter;
- VX-94 bomber;
- 0.34 s physical wing-sweep transition;
- mercenary aircraft;
- ground/naval targets;
- autonomous machines;
- boss-scale targets.

Late bosses have dedicated geometry:

- Phase Control Array: concentric ring-array structure;
- Station Warden: fortified cross-station structure;
- Machine Ark: broad asymmetric command/carrier hull with multiple visible cores.

Surface art uses `AltitudeRules.ground_scale()` and ordinary ground/sea silhouettes disappear when the VX-94 is effectively too high for normal visual engagement.

### `ElectromagneticCueDirector`

Presentation-only feedback for:

- Magnetic Screen field;
- EMP-disrupted autonomous units.

### `ProjectileCueDirector`

Presentation-only projectile language for enemy and player fire.

Player families:

- warm ballistic streaks;
- Needle Rail kinetic dart / wake;
- Storm Cannon energy pulse;
- tactical-support rounds.

### `PixelUiDirector`

Primary bitmap title/result/HUD owner.

Displays:

- hull/shield/energy;
- bombs/wave/time/score;
- weapon;
- generator;
- airframe;
- tactical support;
- battlefield support;
- fighter/bomber form;
- altitude;
- technology era (`CONV / EM / DE / ORB`);
- boss HP/phase/weak point;
- missile warning;
- encounter/support status.

Title controls:

- `U` weapon;
- `G` generator;
- `K` airframe;
- `C` tactical support select;
- `V` tactical support buy;
- `H/J` service;
- `B/F` battlefield support;
- `Q` transform in flight.

Primary UI stays on the original 3x5 bitmap font and 640x360 logical grid.

## Persistence

`CampaignSave` is canonical schema **v5**.

Persistent state:

- credits;
- mission index;
- primary weapon tier;
- generator tier;
- airframe tier;
- serviced hull/shield;
- tactical support selection/unlock.

Transient state intentionally omitted:

- temporary weapon boost;
- current energy;
- active support cooldowns;
- fighter/bomber form;
- altitude-transition progress;
- unfinished-sortie strike ordnance.

Restore order:

1. restore airframe;
2. publish durability/resistance context;
3. clamp serviced hull/shield against upgraded capacity;
4. restore remaining campaign state.

Save v1-v4 remains migration-compatible, with validated backup recovery.

## Technology progression

Canonical eras:

1. advanced conventional;
2. electromagnetic;
3. directed energy;
4. strategic orbital.

The central gate is used by weapons, generators, airframes and tactical support.

Already-owned later technology may be used in replays, but new purchases and temporary boosts cannot jump ahead of the active campaign era.

## Primary weapon identities

### Needle Rail

- electromagnetic era;
- precision kinetic role;
- single high-speed projectile;
- two additional penetrations;
- at most one accuracy registration per slug.

### Storm Cannon

- directed-energy era;
- three strong compact pulse packets;
- tight spread;
- high generator demand;
- bounded one-shot cluster discharge;
- secondary discharge cannot kill.

## Variable-geometry VX-94

### Fighter

- swept/narrow planform;
- faster movement;
- tighter contact/projectile profiles;
- tighter primary spread;
- stronger air effectiveness;
- high/orbital preference.

### Bomber

- broad deployed wing;
- slower movement;
- wider risk profile;
- stronger surface/ship effectiveness;
- wider primary coverage;
- support-energy bonus;
- precision strike availability;
- low-altitude preference.

## Four altitude bands

1. low;
2. mid;
3. high;
4. orbital / atmosphere-space.

Altitude affects target scale/effectiveness, support availability, environment and legal craft configuration.

Authored transitions currently include:

- Black Flag: mid -> low -> mid;
- Black Horizon: high -> orbital;
- Blue Fire: high -> orbital.

Orbital flight requires fighter configuration.

## Campaign structure

Current playable campaign contains **30 missions** across three complete ten-sortie episodes. Secret/optional mission branching remains a separate content track.

### Act I: Mercenary War

1. Coastal Intercept
2. Refinery Run
3. Black Sea
4. Breakwater
5. Furnace Line
6. Black Flag
7. Desert Lance
8. River Hammer
9. Mountain Eye
10. Night Harbor

### Act II: Autonomous Drone War

11. Ghost Sky
12. Machine Furnace
13. Broken Truce
14. Dead Factory
15. Iron Rain
16. Ghost Convoy
17. Red Circuit
18. Swarm Sea
19. Silent City
20. Machine Crown

### Act III: BLACK SKY

21. Black Horizon
22. Thin Blue Line
23. Blue Fire
24. Kinetic Dawn
25. Orbitfall
26. Cold Station
27. Dead Satellite
28. Black Sky
29. Last Horizon
30. Machine Ark

Era pacing:

- M1-4: advanced conventional;
- M5-16: electromagnetic transition and machine-war emergence;
- M17-23: directed-energy escalation into orbit;
- M24-30: strategic-orbital BLACK SKY campaign.

Late autonomous vocabulary adds Phase Interceptor, Beam Sentry and Orbital Lancer instead of endlessly reusing early drones.

### External contact

External/alien contact remains a future phase and is intentionally outside the current campaign. The machine war ends first.

## Authored stage rhythm

Every mission requires:

- at least five encounter beats;
- at least three formation geometries;
- recovery/pacing window;
- mastery secret;
- boss lead-in;
- deterministic filler spawning between beats.

Secrets use accuracy, score or conserved-bomb gates and never block progression.

## Determinism

Each sortie owns a dedicated `RandomNumberGenerator` seeded through `RunSeedRules.mission_seed(mission_index)`.

Gameplay randomness uses that stream. Missing spawn profiles fail closed.

## Removed reconciliation layers

These must remain absent:

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

## Validation

`tools/validate.ps1` performs local structural/data/save checks without network or paid CI.

With Godot 4.6.2 available it runs focused suites covering runtime rules, rewards, service/energy/airframes, mission flow, save recovery, encounters, tactical/battlefield support, craft/altitude, environment, ordnance, tech progression, boss signatures and combat art, followed by editor smoke parsing.

## Production presentation cutover

The temporary prototype player/enemy/projectile drawing has been removed from `main.gd` after live visual capture confirmed production presentation coverage.

- `CombatArtDirector` is the sole craft/enemy presentation owner.
- `ProjectileCueDirector` is the sole projectile presentation owner.
- `main.gd` retains authoritative simulation/collision and the pickup marker until a dedicated pickup-art owner replaces it.
- Do not reintroduce prototype geometry or add a masking/correction layer.

## Invariants

- No GitHub Actions or paid cloud runtime dependency.
- Offline play remains possible.
- Saves are versioned, sanitized and backup-recoverable.
- Gameplay randomness is isolated from global RNG.
- Missing content fails closed.
- Boss bypass through bombs/support/Storm secondary discharge is prohibited.
- Transformation and altitude are gameplay systems.
- Orbital combat requires fighter geometry.
- Tactical and battlefield support remain distinct.
- Airframe upgrades never grant free service refill.
- Airframe resistance remains bounded and uses canonical `CombatRules` damage resolution.
- Environment/combat-art layers cannot compromise projectile/enemy readability.
- Pixel presentation follows `docs/90S_SHOOTER_BIBLE.md`.
- Campaign canon follows `docs/CAMPAIGN_CANON.md`.
