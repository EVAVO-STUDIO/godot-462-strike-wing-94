# User direction — 6 September 2026

Preserve the full HYPERSONIC campaign and art-first → design → necessary-code sequence. The user explicitly prioritizes better art, rain, snow and clouds; actual acceleration/deceleration with scrolling tied to aircraft speed rather than restricting how far forward it can fly; and a vulnerable airframe where a direct Sidewinder-like missile or rocket hit will usually destroy it.

## Acceptance direction

- Weather has distinct rain, snow/spindrift and cloud forms, restrained military colours and altitude-appropriate placement. No precipitation in orbital vacuum. Maintain visual separation from tracers, missiles and warnings.
- Surface/cloud relative motion follows actual integrated travel, with continuous acceleration and deceleration. Cloud depth and wind remain distinct from terrain motion. Avoid a canned speed-line overlay as the sole speed cue.
- Forward flight must not end at a screen-space wall. Review camera following, aircraft position and relative enemy/projectile motion together. Avoid a cosmetic removal of clamps that simply sends the aircraft off-screen.
- Hull survivability is limited. Direct guided-missile and rocket hits are normally catastrophic; near misses, fragments and grazing gunfire may permit damage and recovery. Preserve the existing support, countermeasure, upgrade and save systems while revising how their protection fits this direction. No numerical lethality balance has yet been approved or implemented.
- Encounter spacing, lock warnings, evasion opportunities and mission duration must be reviewed against the faster travel and higher lethality. Do not merely multiply incoming damage while retaining unavoidable contacts.

## Current evidence

`FlightSpeedRules` already maps throttle to world multipliers 0.62–1.36, afterburner 1.78, plus existing hypersonic behavior. Main advances route distance from this multiplier. Main `_update_player` still independently clamps the aircraft centre to a rectangular screen region. These findings call for preserving and completing the existing speed model.

Atmosphere Studio's verified local rain-field compiler/evaluator is used for a 640x304, three-depth-band art study. It is a candidate, not a runtime weather integration or a snow generator. Current rain accents and mountain/cloud art remain available for comparison. Cinematic review captured all 48 addressed exposures before this steering; its evidence remains under work/cinematic_art_review_v2 for later inspection.
