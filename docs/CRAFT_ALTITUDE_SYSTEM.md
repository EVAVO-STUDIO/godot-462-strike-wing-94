# VX-94 Craft and Altitude System

This document is the implementation contract for the VX-94 Strike Wing variable-geometry aircraft and four-altitude combat model.

## Variable-geometry craft

The VX-94 is one physically continuous aircraft. It does not turn into a humanoid/mech form.

The cockpit, fuselage, propulsion core and main structure remain recognisable. The transformation is a believable combat reconfiguration:

- the main wings rotate around visible hinge plates;
- fighter geometry sweeps those wings back into a narrow high-speed planform;
- bomber geometry opens them into a broad attack wing;
- fighter wing-root cannon packs retract/move inward as bomber geometry deploys;
- the bomber nose rotary cannon extends from the forward fuselage as the wings open;
- the nose rotary retracts flush when returning to fighter configuration;
- under-wing hardpoints remain physically readable for rockets, missiles, bombs and other stores.

The transformation is a stance change, not a magical morph.

## Fighter configuration

Purpose: interception, dogfighting, upper atmosphere and orbital combat.

Runtime characteristics:

- movement multiplier 1.16;
- tighter body and hostile-projectile profile;
- primary spread multiplier 0.78;
- air-target attack multiplier 1.18 before altitude modifier;
- normal tactical-support energy cost;
- stronger afterburner burst and better high/orbital afterburner efficiency;
- narrow swept-wing silhouette.

### Fighter weapon posture

Conventional multi-shot guns fire from the wing roots / wing cannon packs.

The nose rotary is folded away, leaving a cleaner forward fuselage for speed.

Weapons with their own dedicated emitter logic remain centreline where appropriate:

- Needle Rail;
- Storm Cannon;
- Plasma Lance;
- other future specialist centreline systems.

Missiles, rockets, bombs and later equipment may use visible wing, under-wing or upper-fuselage hardpoints where the art and weapon role support it.

## Bomber configuration

Purpose: terrain following, bombing, anti-armour, anti-ship and sustained heavy strike work.

The visual stance is deliberately closer to a heavy late-1990s attack-aircraft idea: broad wing, visible nacelles and pylons, strong forward gun posture. It may evoke the brutal functionality of an A-10-style attack aircraft without copying an A-10 shape or proprietary design.

Runtime characteristics:

- movement multiplier 0.82;
- wider body/projectile risk profile;
- primary spread multiplier 1.22;
- primary direct-damage multiplier 1.12;
- ground/sea attack multiplier 1.35 before altitude modifier;
- tactical-support energy multiplier 0.88;
- precision strike ordnance available at low/mid altitude;
- wide deployed attack-wing silhouette.

### Bomber nose rotary

Conventional ballistic primaries use a deployable multi-barrel nose cannon in bomber mode.

The assembly:

- extends from a recessed forward-fuselage housing during the wing-open transition;
- is visibly multi-barrel in the pixel silhouette;
- uses the same physical mount position for projectile creation and muzzle flash;
- receives an original low, ripping procedural rotary sound;
- retracts into the fuselage as fighter geometry returns.

The sound should provide the emotional weight of a huge attack-aircraft rotary gun without using or imitating a copyrighted real-world recording.

## Transformation timing and feedback

Default input: `Q`.

Rules:

- 1.05 s anti-spam transform cooldown;
- 0.82 s primary/secondary weapon interlock during the mechanical change;
- visual wing sweep uses ten held exposures across 0.92 s;
- wing tips move around explicit hinge geometry rather than simply scaling the sprite wider;
- nose-gun deployment and wing-cannon retraction happen during the same animation;
- dedicated actuator SFX starts the transition and a separate mechanical latch confirms the settled ready state;
- orbital combat forces fighter configuration.

The transformation must remain readable at 640x360 and should feel cool because the mechanics are visible, not because it hides itself behind bloom or particles.

## Primary projectile mounts

`CraftFormDirector.primary_mount_offsets()` is the canonical presentation/gameplay mount contract.

`main.gd::_update_weapons()` creates bullets at those exact offsets. Presentation layers also consume the same concept for muzzle flashes.

This prevents the aircraft art showing one weapon location while collision/projectiles originate somewhere else.

## Four altitude lanes

Ordered lanes:

1. LOW
2. MID
3. HIGH
4. ORBITAL / ATMOS-SPACE

Manual changes are adjacent only. A player cannot jump LOW directly to HIGH or MID directly to ORBITAL.

## Low altitude

Ground visual scale 1.00.

- strongest surface interaction;
- roads, structures, armour and ships are large/readable;
- ground attack altitude multiplier 1.25;
- air attack multiplier 0.90;
- bomber normally preferred;
- low-altitude bomber afterburner burns reserve faster and is an emergency escape tool rather than a permanent speed stance.

## Mid altitude

Ground visual scale 0.68.

- hybrid air/surface combat;
- low cloud layers;
- both forms useful;
- ground attack multiplier 0.92;
- air attack multiplier 1.00;
- tanker hookups can operate on assigned missions.

## High altitude

Ground visual scale 0.34.

- cloud-top interception and drone warfare;
- ordinary surface targets cease to be the normal combat vocabulary;
- ground attack multiplier 0.45;
- air attack multiplier 1.12;
- fighter strongly preferred;
- fighter afterburner is more efficient;
- tanker, fighter and rail support become important.

## Orbital / atmosphere-space

Ground visual scale 0.12.

- no normal terrain-target gameplay;
- fighter configuration mandatory;
- air/orbital attack multiplier 1.18;
- strongest afterburner efficiency;
- sparse stars, atmosphere glow and station-scale structures;
- rail/orbital support and autonomous exo units dominate.

## Optional altitude-lane choice

Some missions intentionally allow player-selected altitude changes for a bounded time window.

Controls:

- `PageUp`: climb one available lane;
- `PageDown`: descend one available lane.

The bottom HUD shows an `ALTITUDE LANE` prompt only while a choice window is active.

Current examples include:

- Coastal Intercept: MID/HIGH interception lanes;
- Refinery Run: LOW/MID strike lanes;
- Black Sea: LOW/MID sea-strike lanes;
- Breakwater: MID/HIGH air-superiority lanes;
- Furnace Line: LOW/MID attack lanes;
- Ghost Sky: MID/HIGH cloud-intercept lanes;
- Machine Furnace: LOW/MID/HIGH factory-attack lanes;
- Blue Fire: MID/HIGH phase-intercept lanes before the scripted orbital ascent.

These choices let the player trade surface access, target scale, support availability and fighter/bomber effectiveness without turning every mission into unrestricted altitude roaming.

## Route-specific opportunities

Altitude choice is not only a visual or damage multiplier. Selected missions contain optional encounter beats that exist only if the player reaches the authored lane in the intended VX-94 configuration.

Mission Intelligence reads those conditions directly from the encounter schedule and reports them as `ROUTES LOW+BMB`, `ROUTES HIGH+FTR`, or both where appropriate. There is no second route metadata catalogue.

### LOW + bomber route

This is a deliberate low-level strike run, not simply a larger ground-target damage multiplier.

Current behavior:

- route-specific ground/sea enemies are tagged `strike_priority` when their beat spawns;
- the bombing computer prioritizes those targets inside its assist cone;
- route targets receive a stronger green boxed designation;
- dedicated `E` precision ordnance is the intended kill method;
- an ordnance kill on a route target awards a bounded +450 score bonus;
- guns may still kill the target normally, but do not receive the precision-route bonus;
- holding a steady LOW+BMB line with a valid surface lock builds bombing-computer stability over about 0.65 seconds;
- hard lateral movement bleeds stability rapidly;
- full stability tightens the aim radius and cuts low-altitude time-to-impact to about 72% of the normal value;
- the HUD exposes `STB###` plus a small stability bar;
- precision ordnance has its own shock/debris impact presentation and original low impact voice.

The intended feel is a dangerous attack run: staying straight improves the solution, while flak/missiles force the player to decide when to abandon stability and jink.

### HIGH + fighter route

This is a high-speed air-interception challenge rather than a bombing equivalent with different targets.

Current behavior:

- route-specific aerial enemies are tagged `intercept_priority`;
- those targets receive a bounded +450 increase to their ordinary core combat value;
- the existing `main.gd` destruction/score path therefore awards the value naturally, with no route-specific score watcher;
- dedicated corner brackets and `INT ###` distance/closure cues identify the targets;
- the cue explicitly reminds the player `SHIFT AB`, because afterburner is an intended interception tool but never mandatory;
- the route presentation only appears while the player remains HIGH+FTR.

This route should reward speed, positioning, accurate cannon/rail work and aggressive interception rather than steady bombing-computer alignment.

### Route asymmetry invariant

Do not flatten these routes into the same generic mechanic.

- LOW+BMB rewards precision attack-run execution and dedicated strike ordnance.
- HIGH+FTR rewards high-value intercept kills through the normal weapon/combat loop.

Both may use encounter rewards or pickups, but their core skill test should remain different.

## Scripted altitude transitions

Major set pieces remain authored and cannot be bypassed by manual lane selection.

Examples:

- Black Flag: MID -> LOW sea-skimming attack -> MID flagship phase;
- Black Horizon: HIGH -> ORBITAL breakout;
- Blue Fire: HIGH -> ORBITAL phase-array ascent;
- Machine Ark: HIGH preparation/rearm phase -> ORBITAL final burn at 156 seconds.

## Altitude transition presentation

Scripted and manual altitude changes share one transition owner.

The transition lasts about 1.15 seconds and includes:

- directional `CLIMB` / `DIVE` pixel cue;
- moving cloud bands;
- speed brackets;
- a subtle VX-94 pitch cue;
- separate rising/falling procedural SFX;
- interpolated surface-target scale between the old/new altitude instead of a one-frame size pop;
- blended parallax speed;
- blended terrain-detail scale;
- blended cloud density;
- blended atmospheric horizon glow;
- orbital starfield fade during atmosphere-space transitions.

## Altitude and enemy vocabulary

Altitude affects which normal enemies may appear, not just how they are rendered.

- LOW/MID may include air, ground and naval archetypes;
- HIGH/ORBITAL exclude ordinary ground/sea archetypes;
- bosses remain allowed where mission design requires them.

`CraftFormDirector` publishes altitude-filtered copies of the authored filler spawn profiles before the core scene processes spawning. `EncounterDirector` independently applies the same pure `AltitudeRules` filter to authored beats. This prevents filler and set-piece content from disagreeing.

Processing order is intentional:

1. CraftFormDirector / altitude context: -30
2. EncounterDirector: -20
3. SupportDirector: -5
4. core scene: default priority

A same-frame climb therefore changes encounter eligibility before that frame's encounter or filler spawn is resolved.

## Damage interaction

Player projectile damage resolves from:

1. authored weapon/support damage;
2. craft-form attack multiplier;
3. altitude target-class multiplier.

Surface classes are `ground` and `sea`. Air/boss classes use the air multiplier unless a boss-specific rule overrides it.

## Battlefield support interaction

Support remains altitude-gated.

Atlas tanker is especially important because a complete hookup can restore:

- generator energy;
- bounded hull/shield;
- bombs;
- tactical-support readiness;
- precision strike ordnance;
- afterburner reserve.

Mission 12 intentionally keeps the VX-94 at HIGH until after its rearm window, then performs the authored orbital burn.

## Controls

- movement: WASD / arrows
- persistent throttle: T / G (controller right stick vertical)
- primary: Space
- emergency screen bomb: X
- precision bomber ordnance: E
- tactical support: Z
- transform fighter/bomber: Q
- afterburner: Shift
- optional altitude climb: PageUp
- optional altitude dive: PageDown
- cycle tactical support: C
- buy tactical support: V
- cycle battlefield support: B
- call battlefield support: F
- mission intelligence: I
- buy primary: U
- buy generator: G
- buy airframe: K
- hull service: H
- shield service: J

## Production invariants

- no magical/mech transformation;
- wing sweep must remain hinge-based and visible;
- fighter guns and bomber nose gun must use the same mount geometry for art, muzzle flash and projectile origin;
- bomber rotary sound must remain original/procedural;
- optional altitude changes are adjacent-lane only and window-gated;
- scripted altitude transitions remain authored mission beats;
- altitude choices must alter eligible normal enemy vocabulary;
- LOW+BMB and HIGH+FTR route rewards must remain mechanically asymmetric;
- orbital flight always forces fighter geometry;
- transition FX never obscure incoming projectiles.
