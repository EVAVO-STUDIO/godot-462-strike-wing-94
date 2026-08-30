# HYPERSONIC Sprite Art Direction

## North star

HYPERSONIC should look like a serious Japanese near-future military animation project from 1995–1998 that was adapted into an exceptionally clear vertical arcade shooter. The reference qualities are functional Patlabor machinery, the grounded urban-military tension of 1990s Ghost in the Shell, and Raptor's instant top-down combat readability. We borrow qualities, never designs.

The world is slightly dark and realistic. Hardware has mass, maintenance access, serial logic, plausible joints, recoil paths, cooling, exhaust and crew scale. The arcade layer simplifies that realism into strong silhouettes and deliberate pixel clusters.

## Non-negotiable visual rules

- Orthographic top-down combat view. Perspective is only a subtle pre-rendered bevel, never an isometric camera.
- One dominant silhouette idea per unit. A unit must remain identifiable as a flat one-colour mask at runtime size.
- Large material blocks first, mechanical landmarks second, micro-detail last. Details that vanish at 1x are removed or hand-redrawn.
- Restrained faction palettes. Emissive colour indicates sensors, heat, power or weapons only; it is never decorative edge lighting.
- Human equipment shows crew scale, access hatches, bolts, hydraulics, ammunition paths and field repairs. Autonomous equipment visibly evolves from human industry instead of becoming alien sculpture.
- Useful asymmetry is encouraged: offset optics, replacement armour, external cabling, field-modified weapon pods and uneven wear.
- Pixel finish is authored: nearest-neighbour runtime display, controlled one-pixel highlights, clustered shadows, selective anti-aliasing and no blurry airbrush residue.
- Damage is physical and staged: lost panels, exposed machinery, smoke ports, heat discoloration and disabled subsystems—not a generic red tint.

## Anti-generic rejection list

Reject or repaint assets with: concentric glowing circles as the main identity; gratuitous cyan strips; perfectly mirrored greeble everywhere; unexplained floating parts; skull-like robot faces; saucer silhouettes; fantasy energy; glossy modern concept-art rendering; uniform edge wear; detail density that turns to noise at 1x; or silhouettes interchangeable with stock sci-fi mobile-game art.

## Faction language

### Human conventional forces

Late-Cold-War shapes pushed into the near future: slab armour, exposed hinges, analog sensor housings, canvas covers, warning paint, practical gun mounts and visible crew/service access. Charcoal, weathered gray-green, faded sand, oxide red recognition marks, amber optics.

### Autonomous escalation

Captured human factories reorganize familiar machinery. Chassis and fasteners remain plausible, but crew compartments disappear, sensors migrate, limbs become task-specific and replaceable, and cable/actuator routes become unnervingly efficient. Cold gray-blue, dirty pale alloy, graphite, minimal cyan-white logic indicators.

### BLACK SKY orbital systems

Vacuum hardware rather than alien craft: thermal ceramic, radiators, rails, attitude thrusters, antennae, pressure vessels and shielded apertures. Dark cobalt-black, graphite, aged pale ceramic, sparse cyan field hardware. Forms can become severe and unfamiliar, but every part must still suggest a physical job.

## Articulated sprite construction

Any rotating or moving weapon is delivered as registered layers sharing one integer pivot:

1. `base` — hull, chassis, tracks, legs or emplacement foundation.
2. `mount` — turret ring, shoulder, hip or launcher hinge; optional when baked into base.
3. `weapon` — turret, arm, launcher rack or sensor head, drawn facing runtime zero degrees (down).
4. `barrel` — optional separate recoil layer.
5. `muzzle` — optional short animation, additive-safe but palette controlled.
6. `shadow/contact` — optional ground contact only; never baked into airborne sprites.
7. `damage_1`, `damage_2`, `critical` — registered overlays or replacement layers.
8. `destroy` — authored debris/explosion sequence with at least one recognizable component breakup.

Rotation is performed in engine around the declared pivot. We do not pre-render dozens of blurry whole-vehicle angles when a clean layered assembly will look better. Mech limbs use separate upper/lower/foot layers only when their motion is visible at 1x; otherwise use a compact authored walk cycle.

## Ground-force expansion

- `mercenary_rifle_team`: four-to-six person fireteam represented as a readable clustered formation, with tiny muzzle cadence and scatter-on-hit frames.
- `mercenary_heavy_team`: crew-served autocannon or MANPADS team with a separately rotating/raising weapon layer.
- `security_patrol_mech`: 3–4 metre human-piloted utility/security walker; industrial knees, cockpit cage, rifle arm and shield/tool hardpoint.
- `autonomous_salvage_mech`: corrupted industrial loader with replaceable tool-arms and low, predatory gait; visibly descended from human construction equipment.
- `autonomous_quadruped`: compact logistics chassis repurposed around a rotating sensor/weapon mast.

Infantry are never comic toy soldiers or disposable red dots. Their small scale provides human contrast and makes the larger mechs feel genuinely large.

## Acceptance gate

Every sprite must pass: transparent-source inspection, coloured-plate halo check, silhouette mask check, palette-count check, exact 1x review, 4x nearest-neighbour review, pivot/layer registration test, representative in-engine capture, and motion test for every articulated component. Source-generation output is only raw material until this gate passes.
