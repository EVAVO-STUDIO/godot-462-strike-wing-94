# Strike Wing '94 — VX-94 Combat Art Direction

## Purpose

This document locks the production direction for the live battlefield presentation. Strike Wing '94 should look like a professionally authored late-1990s PC/VGA shooter imagining a near-future military aircraft, not a modern vector game wearing a pixel filter.

## VX-94 visual identity

The VX-94 Strike Wing is a variable-geometry aerospace strike aircraft, not a transforming robot.

Permanent physical anchors:

- one recognizable central fuselage
- visible cockpit/canopy
- visible engine/exhaust logic
- conventional-looking control surfaces and hardpoints
- reinforced late-1990s aerospace panel language
- no magical geometry or impossible disappearing mass

### Fighter configuration

- swept/retracted wing planform
- narrow frontal/combat silhouette
- forward-biased weapon posture
- compact exhaust grouping
- high-speed interceptor visual language
- strongest visual fit at high/orbital altitude

### Bomber configuration

- visibly expanded wing span
- lower/wider posture
- readable hardpoint/payload region
- multiple exhaust/hardpoint accents
- stable strike-platform visual language
- strongest visual fit at low/mid altitude

### Transformation presentation

Wing geometry must visibly sweep between forms. Current presentation target is approximately 0.34 seconds.

The motion should read mechanically through:

- changing wing span
- changing shoulder geometry
- moving engine/hardpoint spacing
- visible hinge marks
- no flash, dissolve, morph or energy effect used to hide the movement

Gameplay form selection may become active immediately for responsiveness; the visual sweep catches up quickly and clearly.

## Altitude and target scale

Altitude must change what the battlefield looks like, not just the HUD label.

### Low altitude

- surface targets at full authored pixel scale
- largest terrain/ship/building readability
- bomber form feels physically close to targets
- smoke, wake, road, roof and emplacement details are readable

### Mid altitude

- ground/sea target art scales down significantly
- cloud/atmosphere layers become more important
- surface targets remain identifiable but no longer dominate the screen

### High altitude

- ordinary surface-target presentation should be heavily diminished or suppressed
- air formations/cloud layers dominate
- exceptional strategic structures may still appear when explicitly authored

### Orbital

- ordinary terrestrial target sprites are not part of normal combat presentation
- orbital installations, satellites, station structures and exo-atmospheric machines use dedicated art

The live combat-art overlay currently consumes the same altitude scale contract used by environment/gameplay rules.

## Enemy visual families

### Mercenary / criminal army

Human hardware should look field-maintained, conventional and dangerous:

- recognisable wings, hulls, turrets, tracks and ship superstructures
- muted military red/brown/steel/olive families
- hot engine/muzzle accents
- believable external weapon mounts
- silhouette first, small detail second

### Autonomous machine army

The AI army must not look like repainted mercenary equipment.

Use:

- colder alloy palette
- compact luminous machine-core accents
- fewer human cockpit cues
- unusual but still functional control surfaces
- symmetric sensor/weapon geometry
- increasingly non-human proportions through the drone-war act

Early drones should still look derived from human military technology. Orbital machines may become substantially more alien in geometry without implying biological alien origin.

## Boss scale

Bosses need readable mass before detail.

- boss silhouettes substantially exceed ordinary enemies
- multiple weapon/emitter regions should be visible
- phase-three weak points must have a logical physical location
- human bosses retain recognizable platform lineage
- AI bosses progressively expose cores, emitters, command arrays and machine geometry

## Player projectile language

Technology progression must be visible in flight.

### Conventional ballistic

- warm yellow/amber streaks
- compact hard-edged projectile heads
- restrained trails

### Needle Rail / kinetic

- very thin cyan-white high-speed tracer
- long, clean wake
- no glowing magic orb
- visually reads as an extremely fast physical penetrator

### Directed energy / Storm Cannon

- compact blue-white pulse packet
- small hard-edged outer ring
- short energy wake
- remains legible against cloud/orbital backgrounds

### Tactical support rounds

- distinct green/teal support signature
- homing rounds gain a small targeting ring
- must never be confused with hostile missiles

## Allied battlefield support presentation

All support calls need visible battlefield presence.

### Rapier fighter flight

Three fast friendly silhouettes crossing the combat space in formation with brief tracer fire.

### Hammer bomber flight

Heavy wide silhouettes crossing opposite the fighter vector with visible strike-release lines.

### Spectre heavy gunship

Large loitering side-profile aircraft with lateral fire lines toward surface targets.

### Atlas tanker

Persistent visible tanker body, hose and connection corridor. The tanker remains the most interactive support set piece.

### Cruise missile support

Visible incoming missile path tied to the actual priority target, followed by a restrained impact ring.

### Longshot rail battery

Short target-charge cue followed by a clean vertical kinetic line. Avoid giant modern laser beams.

### Orbital strike

Several narrow descending kinetic/energy lanes with discrete impacts, not one opaque screen flash.

## Pixel rules

- logical battlefield remains 640×360
- presentation targets integer coordinates wherever practical
- 2× nearest-neighbour output remains the reference presentation
- avoid antialiased vector-looking silhouettes
- no bloom dependency
- no CRT filter used to hide weak source art
- no overly smooth procedural curves when a hand-shaped pixel silhouette is appropriate
- silhouette/readability outrank micro-detail

## Current ownership

`CombatArtDirector` owns presentation-only player/enemy silhouette rendering.

`ProjectileCueDirector` owns projectile readability/presentation.

`BattlefieldSupportDirector` owns battlefield-support effects and their short visual set pieces.

Simulation/collision remains in the gameplay source systems.

## Required cleanup before final art replacement

The prototype combat polygons still drawn directly by `main.gd` must eventually be removed once the new combat-art layer has passed a real Godot visual smoke test. This is especially important for altitude-scaled surface targets because a smaller production silhouette can expose part of the larger placeholder underneath.

Do not solve that by adding another masking/correction director. The final architecture should simply stop drawing prototype player/enemy art in `main.gd` once production presentation is proven.

After that cutover, production sprite sheets can replace the procedural combat-art silhouettes while keeping the same simulation owners and visual contracts.
