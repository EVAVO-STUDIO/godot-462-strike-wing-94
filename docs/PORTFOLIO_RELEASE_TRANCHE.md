# HYPERSONIC — Portfolio Release Tranche

Status: **release candidate**  
Portfolio score: **92/100**  
Scope policy: **freeze**  
Canonical source: `EVAVO-STUDIO/GodotGameFoundationKit/data/release_tranches_v1.json`

## Objective

Turn the existing 30-mission campaign and secret-sortie game into a store-quality Windows candidate without adding new mission families or major systems.

## Work that is allowed now

- release/export correctness
- complete campaign playthrough defects
- mission pacing and difficulty balance
- weapon economy and usability
- controller/keyboard onboarding and accessibility
- HUD readability
- weather, destruction, transformation and threat feedback
- final/approved runtime art integration
- audio mix and critical-cue priority
- performance, save and package validation
- store/demo-facing presentation once the candidate is stable

## Must prove before promotion

1. A clean Windows release export starts from a clean checkout.
2. The complete campaign can be played end-to-end without blocker or save corruption.
3. Keyboard and controller journeys are complete and readable.
4. Difficulty and weapon economy produce no dominant trivial strategy or progress wall.
5. Busy combat scenes meet governed performance targets.
6. HUD, weather, destruction, transformation and threat cues pass native visual review.
7. Music, weapon, engine, radio, impact and weather buses are balanced without clipping or masked critical cues.
8. The release package excludes source art, docs, tools and developer-only surfaces.
9. First-session onboarding explains movement, altitude, transformation, weapons and mission objectives without developer help.

## Stop-work list

Do **not** add a new campaign sector, aircraft family, game mode, meta-progression layer or renderer architecture unless a demonstrated release blocker cannot be corrected inside the existing design.

New ideas go to post-release backlog. They do not expand v1.

## Promotion gate

All must-prove items require exact-SHA evidence and a full human campaign review with no unresolved P0/P1 blocker.
