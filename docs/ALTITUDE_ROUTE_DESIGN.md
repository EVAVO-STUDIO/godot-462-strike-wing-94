# Strike Wing '94 — Altitude Route Design

This document defines how optional altitude lanes change gameplay without turning the campaign into unrestricted free-roaming altitude selection.

## Core principle

Altitude is a tactical route choice inside authored mission windows.

A lane choice must change at least two of the following:

- eligible enemy vocabulary;
- target scale/readability;
- VX-94 form effectiveness;
- support availability;
- optional encounter opportunity;
- attack-run/intercept mastery feedback;
- risk profile.

A lane must never be only a background swap.

## LOW + BOMBER route

This is the close-attack route.

Expected feel:

- broad VX-94 attack wing;
- deployed nose rotary cannon;
- visible bombs/rockets/missiles on bomber-compatible pylons;
- large readable surface targets;
- higher exposure to SAM/AAA/armour/naval fire;
- reduced afterburner efficiency;
- precision bombing-computer gameplay.

### Bombing-computer mastery

The route uses `StrikeOrdnanceRules` and `StrikeOrdnanceDirector`.

A stable attack run requires:

- bomber configuration;
- LOW altitude;
- a valid surface target lock;
- minimal hard lateral input;
- no active altitude transition.

Stability builds over a short bounded interval. Full stability:

- shortens bomb time-to-impact;
- tightens aim error/reticle radius;
- gives clearer HUD feedback;
- improves the feel of a deliberate low-level attack run without turning bombing into a slow simulator.

Altitude transitions safe the bombing computer. Precision ordnance cannot be released while climbing/diving.

### Route-priority targets

Authored LOW+BMB route beats can tag surface targets `strike_priority`.

The bombing computer prioritises these targets within its assist envelope. A route-priority target receives stronger reticle language.

A precision-ordnance kill on a route-priority target can grant a small bounded route score in addition to the target's normal combat value.

This score bonus must stay small enough that players choosing another valid route are not economically punished.

### Physical weapon presentation

Primary ballistic fire in bomber configuration uses the deployed nose rotary mount.

Precision ordnance releases from the authored `ventral_strike_bay` in `player_mounts.json` and visibly travels from the aircraft toward the ground reticle before impact.

The release has a dedicated procedural rack/clunk sound and the impact has a separate heavy strike sound.

## HIGH + FIGHTER route

This is the interception route.

Expected feel:

- narrow swept-wing VX-94;
- wing-root cannon posture;
- tighter hit profile;
- stronger air-target effectiveness;
- efficient afterburner use;
- surface units filtered out of normal encounter/filler vocabulary;
- marked ace/drone interception opportunities.

### Route-priority targets

Authored HIGH+FTR route beats can tag air targets `intercept_priority`.

Those targets receive:

- intercept brackets;
- closure/distance cue;
- a bounded additional core target value;
- `HIGH INTERCEPT  SHIFT AB` presentation.

The extra value is authored into the enemy packet before the core combat loop resolves the kill. Presentation systems must never mutate score.

### Intercept chain

`InterceptRouteDirector` maintains a short presentation-only chain when marked targets are destroyed rapidly.

Rules:

- only active in HIGH + FIGHTER;
- chain timeout is short;
- chain count is capped;
- leaving HIGH fighter configuration immediately ends the current chain;
- score gain is used only as evidence that a disappearing marked target was destroyed rather than flying off-screen;
- the chain does not award additional score itself.

The point is feedback and mastery, not another economy layer.

## MID routes

MID is the hybrid envelope.

Mission authors may use it as:

- the safe/general-purpose route;
- tanker-support corridor;
- transition lane between low strike and high interception;
- mixed air/surface encounter space;
- a lower-risk choice with fewer specialised bonus opportunities.

MID should remain useful. LOW and HIGH must not become objectively correct answers for every mission.

## ORBITAL

ORBITAL is normally an authored late-game transition or fixed mission envelope rather than a freely selected general route.

Rules:

- fighter configuration mandatory;
- no ordinary terrestrial filler;
- exo/orbital enemy vocabulary;
- strongest high-speed/afterburner context;
- rail, directed-energy, Plasma and strategic systems become increasingly relevant;
- large station/command targets replace ordinary terrain targets.

## Authored route conditions

Supported encounter condition types include:

- `altitude_is`
- `form_is`
- `altitude_form`

Use `altitude_form` for the strongest form-specific route opportunities.

Current examples:

- Refinery Run — LOW+BMB armoured route;
- Breakwater — HIGH+FTR intercept route;
- Furnace Line — LOW+BMB AA breakthrough;
- Ghost Sky — HIGH+FTR hunter route.

These are optional. Missing a route opportunity must never block mission completion.

## Spawn consistency

Both generic filler and authored encounter beats consume `AltitudeRules.allows_enemy_archetype()`.

Processing order is intentional:

1. `PlayerMountDirector` loads physical aircraft mount data;
2. `CraftFormDirector` publishes current altitude/form and filtered spawn profiles;
3. `EncounterDirector` applies authored beats using the same altitude filter;
4. `SupportDirector` applies onboard support;
5. core `main.gd` simulation runs.

This prevents a same-frame altitude transition from creating ground targets in a HIGH route or sea units in ORBITAL combat.

## Transition safety

During the approximately 1.15 second altitude change:

- Q geometry switching is locked;
- precision bombing release is safed;
- low-level attack-run stability decays;
- enemy/environment scale interpolates;
- cloud/parallax/horizon treatment blends;
- climb/dive audio and visual cues play.

The maneuver should feel physical without creating a long non-interactive cinematic.

## Future route authoring

When expanding Missions 8–12 or later content, prefer new route-specific encounters over flat stat bonuses.

Good examples:

- LOW+BMB anti-radar corridor exposing a shielded factory entrance;
- MID tanker corridor trading bonus targets for rearm safety;
- HIGH+FTR ace/drone pursuit yielding a weapon cache;
- HIGH-to-ORBITAL interception route that changes the pre-boss escort composition.

Avoid:

- huge route-exclusive credit rewards;
- mandatory secrets;
- routes that simply halve damage or double score;
- surface targets appearing invisibly at HIGH altitude;
- free altitude switching that bypasses authored set pieces.
