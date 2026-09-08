# HYPERSONIC Agent Instructions

This repository is an EVAVO **release candidate**. The current task is to finish and ship the existing game, not expand its feature surface.

Before making changes, read:

1. `README.md`
2. `docs/PORTFOLIO_RELEASE_TRANCHE.md`
3. the repo's validation/release documentation relevant to the files being changed

## Non-negotiable production rule

The scope policy is **freeze**. Work should close release defects, improve presentation/feel, balance existing systems, integrate final or approved runtime media, harden persistence/performance, improve onboarding/accessibility, or prove the Windows package.

Do not add a new campaign sector, aircraft family, game mode, meta-progression layer or renderer architecture unless an evidenced release blocker cannot be corrected inside the existing design.

## Evidence rule

Do not describe the game as release-ready from source inspection alone. Native Godot execution, packaged-build startup, representative gameplay, performance and human visual/playtest evidence remain required.

## Repository rule

Work on `main` and keep changes bounded to the current release tranche. New ideas belong in post-release backlog rather than v1 scope.
