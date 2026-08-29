# Strike Wing '94 — 90s Shooter Bible

Strike Wing '94 should feel like a lost high-end PC vertical shooter from the mid-to-late 1990s that has been finished with modern production discipline, not like a modern game wearing a pixel-art filter.

The reference set includes the design strengths of classic PC and arcade shooters such as Tyrian, Raptor, Raiden and related 1990s vertical shooters. These are reference points for pacing, readability, customization depth and production discipline only. Do not copy proprietary ships, enemies, levels, UI layouts, sounds, music, text, names, weapon designs or artwork.

## Pixel-perfect presentation

- Logical game canvas: 640x360.
- Default desktop presentation: 1280x720 at an exact 2x scale.
- Nearest-neighbour texture filtering only.
- Gameplay sprites, HUD glyphs and collision-critical effects must be positioned on integer logical pixels whenever practical.
- Avoid arbitrary subpixel camera drift, fractional UI placement and smoothing that produces crawling or soft edges.
- Pixel clusters should be intentionally drawn. Do not use AI-smoothed edges, vector-like gradients or high-resolution art downsampled without a deliberate pixel cleanup pass.
- Sprite silhouette must remain readable at native 640x360 scale, not only when enlarged.

## Visual language

The world is military-industrial near-future 1994 alternate history rather than generic space fantasy.

Use:

- chunky hand-shaped silhouettes;
- strong top-down value separation;
- restrained per-scene palettes;
- painted/dithered cloud banks, smoke, haze and water;
- runway lights, tracer flashes, exhaust, wakes and debris;
- 3-5 parallax bands where appropriate;
- deliberate transparency/dither effects that evoke high-end VGA artwork;
- environment-specific palettes and landmarks;
- readable damage flashes and projectile silhouettes.

Avoid:

- modern bloom-heavy neon;
- glossy mobile-game UI;
- excessive particles that hide hitboxes;
- generic AI concept-art detail;
- photorealistic textures pasted into pixel scenes;
- flat vector icons;
- fake CRT filters as a substitute for good pixel art.

## Sprite production

Every combat sprite needs a production sheet specification before final art:

- logical bounding box;
- visual center;
- collision center/radius;
- shadow footprint where used;
- muzzle points;
- engine/exhaust points;
- damage/spark anchors;
- animation frame count;
- facing/turn variants where needed;
- destroyed/debris frames where needed.

Recommended scale bands:

- light aircraft: 20-34 px wide;
- heavy aircraft: 32-52 px wide;
- ground/sea units: 20-56 px footprint depending on class;
- bosses: 70-160 px footprint, with enough negative space around weak points for readable projectile play.

Bosses should look large because of authored silhouette, animation and staging, not merely because a small sprite was scaled up.

## Animation

Prefer small, high-quality animation sets over excessive interpolation.

Useful animation channels:

- banking left/right;
- rotor/turbine/propeller cycles;
- engine pulse/exhaust;
- turret tracking;
- missile hatch opening;
- recoil;
- weak-point exposure;
- damage state;
- destruction sequence.

Animation should communicate gameplay state. A player should often understand that an attack is coming before reading a HUD warning.

## Projectile readability

Every projectile family needs a distinct silhouette and motion language.

- rapid cannon: compact bright streak;
- heavy cannon: larger slower slug with stronger impact;
- missile: body/trail plus tracking cue;
- burst spread: recognizable fan geometry;
- boss special: unique telegraph before release.

Enemy fire must remain readable over every environment palette. Dangerous projectiles get stronger contrast, not merely more visual noise.

## Controls and movement

Classic PC shooter responsiveness is a core benchmark.

- Player input should feel immediate.
- Do not add decorative inertia that makes precision dodging unreliable.
- Movement speed must support deliberate lane changes without trivializing aimed fire.
- Damage should usually feel attributable to a visible mistake rather than ambiguous collision clutter.
- Collision footprint may be slightly smaller than the visual aircraft if this improves fairness, but it must remain consistent and learnable.

## Campaign rhythm

A mission is not just a timer with random enemies.

Each mission should have authored beats such as:

1. visual/environment introduction;
2. low-pressure formation teaching the local enemy vocabulary;
3. first mixed threat;
4. environmental landmark or tactical change;
5. pressure wave;
6. short recovery/reward beat;
7. elite or special formation;
8. pre-boss tension;
9. boss or climax;
10. result/economy decision.

Spawn profiles remain data-driven, but mission pacing should increasingly support authored encounter blocks and special formations rather than relying entirely on interval spawning.

## Variety without randomness soup

Tyrian-style longevity came partly from surprise and unusually broad content variety. Strike Wing should pursue that feeling through original content:

- environment-specific enemy rosters;
- rare elite formations;
- optional bonus targets;
- hidden pickup conditions;
- alternate objective opportunities;
- short secret encounter branches;
- unusual mission modifiers;
- memorable one-off set pieces.

Secrets should reward observation or mastery. They should not require copying arbitrary hidden triggers from another game.

## Upgrade economy

Between-sortie customization must create real build choices.

Permanent campaign state currently includes:

- primary weapon tier;
- generator tier;
- credits;
- serviced hull;
- serviced shield.

Temporary sortie weapon pickups remain separate from permanent progression.

Weapons should differ by behavior, not only DPS:

- balanced;
- spread/control;
- rapid pressure;
- burst;
- heavy impact;
- precision/high velocity;
- high-output endgame.

Generator progression creates the sustained-fire tradeoff:

- stronger weapons consume more energy;
- a weak generator can still equip a strong weapon but cannot sustain maximum fire indefinitely;
- better generators improve both capacity and recharge rate;
- the player can choose between buying the next weapon, improving sustained output, or repairing the airframe.

Future loadout depth may add original rear/secondary systems, wingmen/drones and defensive modules, but each slot must create a distinct tactical choice and remain readable in the HUD.

## Shields and hull

The game should be forgiving enough to support a campaign economy without becoming trivial.

- Shield absorbs damage before hull.
- Surviving hull/shield condition carries into the next sortie after success.
- Repair/recharge costs create meaningful post-mission decisions.
- Pickups can provide tactical recovery during a mission.
- Avoid surprise one-hit kills outside clearly telegraphed special threats.

## Boss design

Bosses need more than large health pools.

Each boss should have:

- a recognizable entrance;
- three readable phases;
- phase-specific movement and fire patterns;
- visible transition cues;
- a final exposed/critical phase;
- at least one signature attack;
- enough downtime to read patterns;
- attacks compatible with the mission's learned enemy vocabulary.

Boss phase 3 currently exposes the weak point. Final artwork/animation should make that state visually obvious before the player reads the HUD.

## Audio direction

Music should evoke high-quality 1990s PC tracker/MIDI energy without imitating copyrighted melodies.

Aim for:

- strong mission themes;
- immediately identifiable boss cue;
- punchy cannon transients;
- heavier low-frequency impact for large weapons;
- distinct missile lock/launch sounds;
- mechanical service/shop UI sounds;
- short reward stingers.

Sound effects should remain short and mix cleanly under dense combat.

## UI direction

The HUD should look like purpose-built 1990s military game instrumentation rather than a modern glass dashboard.

- bitmap/pixel-compatible typography;
- compact numeric readouts;
- strong alignment to the pixel grid;
- restrained color hierarchy;
- obvious health/shield/energy/bomb state;
- readable boss health/phase;
- clear missile warning;
- minimal decorative chrome.

The title/shop screen should make weapon, generator, airframe condition and credits understandable at a glance.

## Production rule

Every new feature must answer at least one of these questions:

- Does it improve moment-to-moment combat decisions?
- Does it make an enemy/weapon/environment more memorable?
- Does it create a meaningful campaign economy choice?
- Does it improve readability or fairness?
- Does it strengthen the authentic 1990s PC-shooter presentation?
- Does it increase replayability through authored variety rather than filler?

If the answer is no, it probably does not belong in Strike Wing '94.
