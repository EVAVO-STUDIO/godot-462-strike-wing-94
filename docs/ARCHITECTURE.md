# Strike Wing '94 Runtime Architecture

## Current ownership model

Strike Wing uses direct source ownership for simulation state and small directors only where a subsystem genuinely spans the scene or authored campaign data.

### Core scene

`main.gd` owns:

- game phase flow;
- player movement;
- mission timing and wave progression;
- permanent weapon/generator indices exposed to persistence;
- sortie energy;
- permanent serviced hull/shield state;
- direct primary-fire projectile creation;
- exact shots-fired / shots-hit counters;
- normal enemy movement and weapon packets;
- screen-bomb resolution;
- direct successful-mission reward payout;
- deterministic filler spawning through the mission-local RNG;
- craft-form multipliers at the actual movement/fire/damage/contact source.

Do not reintroduce post-frame repair layers for state that `main.gd` can calculate correctly when the event happens.

## Runtime directors

### `CraftFormDirector`

Owns the VX-94 variable-geometry configuration and current mission altitude envelope.

- reads mission context from `data/campaign_world.json`;
- fighter/bomber transformation on `Q`;
- 0.65 second transform lockout;
- mission-recommended initial configuration;
- orbital missions lock bomber configuration out;
- exposes speed, contact, spread, attack and support-energy multipliers;
- exposes public `mission_context()` for other systems.

`main.gd` consumes these values directly at movement, fire, target-damage and body-contact source points.

See `docs/CRAFT_ALTITUDE_SYSTEM.md`.

### `EncounterDirector`

Owns authored stage sequencing.

- timed encounter beats;
- deterministic formation entry;
- filler-spawn suppression windows;
- recovery pickups;
- performance-gated secrets;
- common spawn path through `main.gd::_spawn_enemy()`.

It is a level-script owner, not a reconciliation layer.

### `SupportDirector`

Owns the player's permanent tactical support equipment slot.

Current tactical systems:

- Twin Rocket Pods;
- Crosswind Cannons;
- Hunter Rack;
- Point Defence Pod.

The selected support consumes the same generator energy pool as primary fire. Bomber configuration reduces tactical-support energy cost. Public `support_state()` / `restore_support_state()` form the save boundary, while `rearm_support()` gives the Atlas tanker a clean rearm API.

### `BattlefieldSupportDirector`

Owns mission-assigned allied support assets rather than the player's equipment slot.

Controls:

- `B`: cycle assigned battlefield support;
- `F`: call selected support.

Current assets:

- Spectre Heavy Gunship;
- Atlas Tanker;
- Rapier Fighter Flight;
- Hammer Bomber Flight;
- Cruise Missile Battery;
- Longshot Rail Battery;
- Orbital Strike Platform.

Support availability comes from the active mission context and is altitude-gated.

Allied strike rules:

- bounded target counts;
- normal kills register mission objective progress and score;
- boss damage is always nonlethal;
- long cooldowns keep battlefield support strategic rather than functioning as another primary weapon.

#### Atlas tanker

The tanker is the first spatial support set piece.

- visible future transport and hose;
- mid/high altitude only;
- 30 px hookup radius;
- 3.5 seconds of maintained formation required;
- hookup progress decays gradually when broken;
- connected player receives bounded hull/shield/energy restoration;
- successful hookup grants two bombs up to the cap and rearms tactical support.

### `EnvironmentDirector`

Owns deterministic low-alpha pixel battlefield overlays.

Environment profiles:

- coast;
- industrial;
- open water;
- high cloud;
- orbital.

`EnvironmentRules` combines the authored environment with current altitude to drive:

- parallax speed;
- ground-detail scale;
- cloud density;
- atmospheric horizon glow;
- whether normal ground detail is shown.

The overlay is deliberately restrained so enemies/projectiles remain the highest visual priority.

### `BossDirector`

Owns boss phase behaviour and common homing-projectile steering.

Boss phase 3 exposes the weak point. Screen bombs and allied support can damage bosses but cannot bypass the encounter by killing them directly.

### `PixelUiDirector`

Owns title, result and gameplay instrumentation through the original bitmap renderer.

It displays:

- hull/shield/energy;
- bombs/wave/time/score;
- weapon;
- tactical support;
- battlefield support;
- fighter/bomber configuration;
- altitude band;
- boss HP/phase/weak-point cue;
- missile warnings;
- encounter and support status messages.

Primary UI uses the original 3x5 `PixelFont` and a 640x360 integer-grid surface, not Godot `PanelContainer`, `Label` or `ProgressBar` chrome.

### `ProjectileCueDirector`

Presentation-only spatial projectile cues. It remains separate from HUD chrome because its visual responsibility lives around moving hostile projectiles.

### `CampaignSave`

Canonical campaign persistence boundary.

Current schema v4 stores:

- credits;
- mission index;
- permanent primary tier;
- generator tier;
- serviced hull;
- serviced shield;
- selected tactical-support index;
- highest unlocked tactical-support index.

Temporary weapon boost, current energy, support cooldowns and fighter/bomber form are sortie/mission context state and are not persisted.

Supported v1-v3 saves remain migration-compatible. Before primary replacement, a supported valid primary is copied to the backup save; restore prefers primary and can recover from backup.

## Variable-geometry craft

The VX-94 is a physically coherent 1999 near-future aircraft, not a humanoid transformer.

### Fighter

- swept/narrow silhouette;
- faster movement;
- tighter contact profile;
- tighter gun spread;
- better aerial effectiveness;
- preferred high/orbital configuration.

### Bomber

- broad deployed-wing silhouette;
- slower movement;
- wider contact profile;
- wider primary coverage;
- stronger surface/ship effectiveness;
- better tactical-support energy efficiency;
- preferred low-altitude strike configuration.

Final art should animate wing sweep, hardpoint posture and control-surface movement with a small number of deliberate pixel frames.

## Four altitude bands

The canonical order is:

1. low;
2. mid;
3. high;
4. orbital / atmosphere-space.

Altitude modifies ground visual scale and surface-vs-air effectiveness. Low/mid support normal surface warfare; high/orbital focus increasingly on air, drone and orbital targets. Orbital flight requires fighter configuration.

## Campaign structure

Current campaign contains nine authored missions.

### Act I: Mercenary War

1. Coastal Intercept
2. Refinery Run
3. Black Sea
4. Breakwater
5. Furnace Line
6. Black Flag

The opening establishes black-market conventional warfare and begins the move toward electromagnetic systems.

### Act II: Autonomous Drone War

7. Ghost Sky — first high-altitude autonomous swarm and Swarm Controller.
8. Machine Furnace — mercenary holdouts overlap with autonomous factory forces and AI Forge Core.
9. Black Horizon — first orbital mission and Orbital Command Node.

The human faction intentionally overlaps with the AI transition instead of vanishing instantly.

### External Contact

Defined as an optional future threat phase but not yet inserted into playable missions. This preserves the military/AI identity long enough for it to matter before any alien escalation.

See `docs/CAMPAIGN_CANON.md`.

## Authored stage rhythm

Every mission includes:

- at least five encounter beats;
- at least three formation geometries;
- recovery/pacing window;
- performance mastery secret;
- boss lead-in;
- deterministic filler profile between authored beats.

Formation vocabulary:

- line;
- wedge;
- split;
- column;
- stagger;
- controlled scatter.

Secrets currently use accuracy, score or conserved-bomb gates and never block campaign progression.

## Determinism

Each mission owns a dedicated `RandomNumberGenerator` reseeded from `RunSeedRules.mission_seed(mission_index)` on launch/retry.

Gameplay randomness uses that stream. Missing spawn profiles fail closed instead of broadening to arbitrary enemies.

## Energy and progression

Permanent build dimensions currently include:

- primary weapon tier;
- generator tier;
- tactical support unlock/selection;
- serviced airframe condition.

The shared energy system means a powerful weapon, tactical support choice and generator tier interact instead of forming independent flat upgrades.

## Removed reconciliation layers

The following obsolete runtime repair systems must remain absent:

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

Their responsibilities were either moved to the actual source of truth or absorbed into the unified pixel presentation layer.

## Validation

`tools/validate.ps1` performs structural/data checks without requiring network or paid CI.

When a local Godot 4.6.2 executable is available it also runs focused headless tests covering:

- base runtime rules;
- rewards/accuracy;
- service/energy;
- mission flow/projectiles;
- save recovery;
- authored encounters/secrets/formations;
- tactical support;
- craft form and altitude;
- battlefield support/tanker;
- environment presentation;
- editor smoke parsing.

## Current direct follow-up

One craft collision refinement is intentionally still pending rather than hidden behind another director: hostile projectile collision in `main.gd::_update_enemy_bullets()` still uses the previous fixed hit radius. The next safe direct scene edit should expose a dedicated fighter/bomber projectile-hit profile there, keeping collision ownership at the actual projectile-hit source.

## Invariants

- No GitHub Actions or paid cloud runtime dependency.
- Gameplay remains usable offline.
- Campaign saves are versioned, sanitized and recoverable.
- Gameplay randomness is isolated from the global RNG.
- Missing content fails closed.
- Boss bypasses through bombs/support are prohibited.
- Transformation and altitude are gameplay systems, not cosmetic labels.
- Orbital combat locks the VX-94 to fighter configuration.
- Tactical and battlefield support are distinct concepts.
- Environment overlays never compromise projectile/enemy readability.
- Pixel presentation follows `docs/90S_SHOOTER_BIBLE.md`.
- Campaign/world canon follows `docs/CAMPAIGN_CANON.md`.
