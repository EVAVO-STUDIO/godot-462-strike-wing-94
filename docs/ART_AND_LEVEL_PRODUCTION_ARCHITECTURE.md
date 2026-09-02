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

## Immediate implementation order

1. Make Cloud Top the first reference implementation of this contract: native
   overhead geography, explicit far/primary/turbulence/near planes, six-district
   route sequencing and normal/hypersonic motion evidence.
2. Extend environment metadata from a three-chunk loop to per-mission route
   sequences with connectors and registered animation slots.
3. Apply the architecture to the early vertical-slice coast mission and judge a
   full combat run, not just terrain stills.
4. Propagate only after the vertical slice proves readability and variety.

