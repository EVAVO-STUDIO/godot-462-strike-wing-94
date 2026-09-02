# HYPERSONIC Art and Level Production Architecture

This is the production contract for the final 640x360 game. It replaces the
idea that a level can be finished by stretching or looping one large generated
painting. Art is approved only after native gameplay and motion review.

## What the reference games actually did

### Raptor: compact tiles plus independent actors

The released/reconstructed Raptor source defines a 9-column by 150-row map of
32x32 blocks (`MAP_COLS`, `MAP_ROWS`, `MAP_BLOCKSIZE`). Only eight rows are kept
on screen. Its tile renderer advances the field one pixel, then moves to the
next map row every 32 pixels. Tiles have separate damage, death, value and
replacement state; ground animations inherit the world scroll. Enemy/actor
records are independent of the tile field.

This explains Raptor's clarity and destructibility, but also the visible grid
and repeated motifs we should improve on.

Authoritative implementation:

- https://github.com/skynettx/raptor/blob/master/src/rap.h
- https://github.com/skynettx/raptor/blob/master/src/tile.cpp
- https://github.com/skynettx/raptor/blob/master/src/anims.cpp
- https://github.com/skynettx/raptor/blob/master/src/loadsave.h

### Tyrian: three tile planes and deliberate interleaving

OpenTyrian preserves three independently positioned background maps. Their
source tiles are 24x28 pixels. Background 1 is the opaque foundation;
backgrounds 2 and 3 have their own scroll rates, delays and horizontal offsets.
Background 2 can be opaque, transparent/blended, or synchronized with layer 1
for effects such as water. The renderer deliberately inserts these planes at
different points around ground enemies, sky enemies, top enemies, player shots,
filters and star fields. This is not one flattened image pretending to have
depth: draw order and motion create the depth.

Authoritative implementation:

- https://github.com/opentyrian/opentyrian/blob/master/src/backgrnd.c
- https://github.com/opentyrian/opentyrian/blob/master/src/tyrian2.c
- https://github.com/opentyrian/opentyrian/blob/master/src/varz.h

## HYPERSONIC's better hybrid

Use authored macro-geography for identity and small repeatable material tiles
only where matter is genuinely homogeneous. Keep landmarks, destructibles,
weather and activity independent. This retains Raptor/Tyrian readability while
avoiding a 32px checkerboard or an obvious three-image loop.

Every environment is assembled from these planes, back to front:

1. **Far field (0.12-0.30x world rate):** atmospheric colour, deep sea,
   distant cloud shadow, city glow, terrain haze or star field. Seamless tiles
   are appropriate here because detail is broad and low contrast.
2. **Primary geography (1.00x world rate):** native-width authored districts.
   Ground/sea families use 640x1024 macro chunks. A final mission route must
   select at least six chunks or 6144px before an exact district can repeat;
   adjacent missions rotate and branch the sequence rather than merely changing
   its starting phase.
3. **Material/activity plane (0.72-1.00x):** water chop, shoreline wash,
   runway lights, traffic, machinery, cloud shadow or current. These are sparse
   masks/tiles and registered animation slots, never an opaque duplicate scene.
4. **World objects (1.00x):** bridges, radar, cranes, turrets, troops, vehicles,
   structures and destructibles. Complete objects remain transparent sprites
   with stable world coordinates; rotating or damageable parts remain layered.
5. **Near field (1.08-1.35x):** cloud banks, spray, smoke wisps, foreground
   gantries and contrails. It may cross the player only when altitude rules say
   it should and may not hide threats for longer than a brief authored beat.
6. **Transient effects:** rain, lightning illumination, impacts, wakes, debris,
   sonic boom and hypersonic streaks. These are event-driven and do not define
   the underlying geography.

Godot's `Parallax2D` supports independent `scroll_scale`, `scroll_offset` and
`repeat_size`, but HYPERSONIC may keep its deterministic CanvasItem renderer as
long as it enforces the same explicit plane contract:
https://docs.godotengine.org/en/4.x/classes/class_parallax2d.html

## Audit of the current implementation

The repository already contains the beginnings of this hybrid. Do not throw it
away. `environment_director.gd` currently supports native-width geography
chunks, independent deep/surface/foam water animation, finite sea props,
shoreline wash, cloud families, weather, refinery activity, registered
landmarks and separately pivoted machinery such as the mountain radar dish.

The production gaps are narrower and more important than simply generating
more paintings:

- most ground families are hard-coded three-chunk cycles, so an exact district
  returns after 3072px;
- route order, animation slots and finite prop placement live in GDScript
  instead of mission-authorable data;
- some layer offsets are integrated from mission time rather than one shared
  world-distance value, which risks drift during speed changes;
- layer metadata is implicit in draw functions, making asset validation and
  Art Studio export difficult;
- spatial and temporal seam checks are not yet expressed as asset gates;
- the route has no explicit connector vocabulary, so compatible edges depend
  on each painting happening to match the next.

The next environment rewrite is therefore a data and validation migration over
the working renderer, not a new rendering system for its own sake.

## Data-authored route contract

Each mission selects a route manifest. A minimal manifest has this shape:

```json
{
  "id": "coast_dawn_route_a",
  "native_width": 640,
  "world_length": 8192,
  "planes": [
    {"id":"deep_sea", "kind":"seamless_loop", "ratio":0.22},
    {"id":"geography", "kind":"chunk_route", "ratio":1.0},
    {"id":"shore_activity", "kind":"registered_animation", "ratio":1.0},
    {"id":"low_cloud", "kind":"finite_field", "ratio":1.16}
  ],
  "districts": [
    {"asset":"coast/seawall_run", "north":"sea_straight_a", "south":"sea_inlet_a"},
    {"asset":"coast/defended_inlet", "north":"sea_inlet_a", "south":"sea_cliff_b"}
  ]
}
```

Connector tags are authored facts, not guesses made from filenames. Validation
rejects adjacent districts whose south/north tags differ. Route length is
measured in world pixels and finite events use that same coordinate system.
Normal, afterburner and hypersonic flight therefore traverse one consistent
route rather than three loosely synchronized animations.

Route manifests may branch or introduce one-off set pieces, but they must stay
deterministic for capture tests, replay and encounter synchronization. A
district texture never contains a target that gameplay expects to destroy;
the district contains only its pad, shadow receiver, wake mask or foundation.

## Large images, chunks and tiles

- Never use a mission-long image that will be enlarged. Runtime geography must
  be authored at 640px width or higher and may only be cropped or downsampled.
- A single huge image is allowed only for a finite, non-repeating set piece or
  cinematic transition. It still needs native-resolution review and must not
  carry animated subjects baked into it.
- Use 640x1024 macro chunks for recognisable districts: coast bends, road
  switchbacks, harbor basins, cloud fronts and orbital installations.
- Use 64/128/256px seamless material tiles for sea texture, sand drift, cloud
  shadow, stars and broad illumination. Provide at least four phase/shape
  variants and distribute them with a deterministic mission seed.
- Use transition chunks or edge masks between materially different districts.
  Do not blur a 20-50px strip to conceal incompatible art; the source geometry
  itself must share edge colour, value, direction and scale.
- Avoid exact landmark repetition. A repeated material texture is acceptable;
  the same airbase, crater, road junction or cloud vortex every 3072px is not.

## Animation taxonomy

Choose the smallest honest technique for each motion.

### Seamless temporal loops

Use for continuous, locally repeating matter: sea chop, foam crawl, cloud
shadow, rain sheet, heat shimmer, current, warning lights and machinery belts.

- 6-12 held frames at 6-12 fps for a late-90s cadence.
- First/last temporal seam and all four spatial edges must close.
- Keep a stable mean luminance so the whole screen does not pulse.
- Phase-offset instances; never start every loop on frame zero.
- Palette/colour cycling is valid for tiny light bands, emissive strips and
  flowing highlights, not for moving large objects.

### Finite world-registered animation

Use for waves hitting a particular shore, steam vents, lightning cells, radar
sweeps, traffic, lifts, doors, fires and damage. Store world X/Y, frame count,
fps, phase, draw plane and bounds. It scrolls with geography and can leave the
screen; it does not wallpaper the viewport.

### One-shot event animation

Use for explosions, collapses, splashes, debris, missile impacts, sonic booms
and hypersonic entry. These have anticipation/impact/decay timing, a pivot and
an explicit completion frame; they never loop.

### Mechanical sprite animation

Use authored frames for VX-94 transformation, banking and pursuer conversion.
Godot can consume separate frames or a registered sheet through
`AnimatedSprite2D`/`SpriteFrames`; `AnimationPlayer` is reserved for coordinated
multi-layer motion. Do not rotate a flat aircraft bitmap to fake banking.
Official implementation options:
https://docs.godotengine.org/en/4.5/tutorials/2d/2d_sprite_animation.html

## Sprite-family planning contract

Plan a gameplay object as a family, not as one attractive PNG. Every family
starts with an orthographic construction board and a value/silhouette test at
native gameplay size. Perspective, light direction and palette remain fixed
across every pose.

Required deliverables by family:

| Family | Authored poses / layers | Typical cadence |
| --- | --- | --- |
| VX-94 and hypersonic pursuers | neutral; 4 left banks; 4 right banks; bomber and fighter endpoints; 8-12 transformation frames; engine, shadow, hardpoint and damage overlays | banks selected by input; transformation 12-18 fps with held settle |
| conventional aircraft | neutral; 2-4 banks each side; attack/recoil pose; damage state; shadow; muzzle/exhaust anchors | pose-driven, not bitmap rotation |
| helicopter | fuselage banks; rotor loop separate from fuselage; chin gun/turret separate; damage rotor; shadow | rotor 8-12 fps, fuselage pose-driven |
| turret / vehicle / ship | hull/base; rotating weapon; muzzle/recoil; shadow/wake; damage and destroyed base | rotation by layered part only when its top-down form supports it |
| troop / mech | 4-direction or mission-facing locomotion; attack; hit; death; weapon overlay where required | 6-10 fps with deliberate holds |
| HUD instrument | frame; fill/mask; tick marks; icon states; warning lamp; disabled/damaged variant | event-driven; warning lamps 4-8 fps |
| effect | anticipation if needed; impact; expansion; breakup; smoke/debris tail | one-shot, 8-15 fps |

Aircraft roll is represented by redrawn volume: visible upper/side surfaces,
changed wing foreshortening, canopy shift and shadow response. Even a 20-frame
source study should normally be reduced to a smaller set of excellent held
poses in gameplay; extra source frames are retained only if native-speed motion
review proves that they add readable volume rather than mush.

Every sprite manifest records:

- native canvas and visible bounds;
- visual centre, gameplay centre and collision region;
- ground-contact or shadow anchor;
- muzzle, exhaust, missile, damage and attachment anchors per pose;
- draw plane and occlusion rules;
- pose names, frame exposure and valid transitions;
- component pivots for every separately rotating/recoiling part;
- palette ramp, outline policy and reference light vector;
- source master, reduction method and runtime output hashes.

Generated concept art is never a runtime sprite merely because it has a
transparent background. It must pass silhouette cleanup, perspective
consistency, component separation, native-size pixel-cluster work, alpha-fringe
inspection and animation continuity review. Runtime sheets are assembled from
approved frames by deterministic tooling; the atlas itself is not painted as a
single generative image.

## Scroll and altitude contract

- Forward flight moves world geography from the top of the playfield toward the
  bottom. Positive craft speed must never visually reverse this direction.
- One authoritative world-distance value drives geography, objects, collision,
  shadows and world-registered animation. Each visual plane derives its offset
  from that value; it must not integrate its own unrelated clock.
- Hypersonic mode multiplies world distance. It does not swap to a reversed
  animation or smear the authored base into unreadable blur. Use restrained
  directional streak, exposure flash and shockwave overlays while landmarks
  still advance consistently.
- Altitude changes scale, contrast, cloud occlusion, shadow separation and
  perceived layer rate. It does not change the world coordinate of a landmark.
- The full 640x324 combat viewport must be covered at every fractional scroll
  offset, speed and transition state.

## Art planning and deliverables

Before making an environment family, create a route board containing:

- value-only combat-readability thumbnail;
- palette ramp and material swatches;
- six or more named macro-district thumbnails;
- connector/transition plan;
- far, primary, activity, object, near and transient plane list;
- animation list classified as seamless, finite or one-shot;
- landmark and destructible placements;
- low/mid/high/orbital and normal/hypersonic capture targets.

Each runtime asset requires source provenance and metadata for native size,
pivot/anchor, world bounds, plane, nominal scroll ratio, loop length, fps,
phase policy, alpha mode and collision/destruction linkage where applicable.

## Acceptance gates

Automation is necessary but not sufficient.

1. **Native stills:** inspect at 640x360 without browser/app scaling at normal,
   low and high altitude.
2. **Motion:** review at normal, afterburner and hypersonic speeds through at
   least two complete geography cycles. Check direction, temporal cadence,
   joins, duplicate landmarks and foreground occlusion.
3. **Combat read:** inspect dense bullets, missiles, locks, pickups and ground
   targets. Background detail yields locally behind threats without becoming a
   flat dark wash.
4. **Spatial seams:** every repeating tile and adjacent chunk edge reports zero
   pixel error after final import/colour conversion.
5. **Temporal seams:** loop frame N to frame 0 is reviewed both numerically and
   in motion; no global brightness jump or frozen edge.
6. **No enlargement:** builders and import settings prove every runtime source
   is native size or downsampled.
7. **No synthetic tells:** reject malformed perspective, repeated circular
   motifs, incoherent roads/coastlines, duplicated structures, texture mush and
   decorative detail that has no physical or gameplay role.
8. **Route diversity:** compare captures from all missions sharing a family;
   starting phase alone does not count as a different level.
9. **Speed continuity:** record the same route crossing normal, afterburner and
   hypersonic transitions. No plane reverses, jumps phase or separates from its
   registered object when the speed multiplier changes.
10. **Sprite volume:** bank and transform contact sheets are reviewed in motion
    and frame-stepped. Aircraft must gain believable side/upper-surface volume;
    flat bitmap rotation is an automatic rejection.
11. **Layer isolation:** alpha previews prove that rotating weapons, rotors,
    wakes, shadows, damage and emissive effects contain no baked remnant of the
    parent layer.
12. **HUD load:** dense-combat captures must keep permanent HUD coverage below
    the approved budget; contextual lock, mission and warning elements expire
    or collapse rather than accumulating on screen.

## Immediate implementation order

1. Make Cloud Top the first reference implementation of this contract: native
   overhead geography, explicit far/primary/turbulence/near planes, six-district
   route sequencing and normal/hypersonic motion evidence.
2. Extend environment metadata from a three-chunk loop to per-mission route
   sequences with connectors and registered animation slots.
3. Apply the architecture to the early vertical-slice coast mission and judge a
   full combat run, not just terrain stills.
4. Propagate only after the vertical slice proves readability and variety.
