# HYPERSONIC Agent Instructions

This repository is an EVAVO **release candidate**. The current task is to finish and ship the existing game, not expand its feature surface.

Before making changes, read:

1. `README.md`
2. `docs/PORTFOLIO_RELEASE_TRANCHE.md`
3. `docs/RELEASE_COMPLETION_AUDIT_2026-09-08.md`
4. `docs/VULNERABLE_BALANCE_EVIDENCE.md` when touching difficulty, damage, mission pressure or combat survivability
5. `docs/ECONOMY_PROGRESSION_EVIDENCE.md` when touching rewards, repair/recharge prices, progression costs, weapons, generators, airframes or support purchases
6. the repo's validation/release documentation relevant to the files being changed

## Non-negotiable production rule

The scope policy is **freeze**. Work should close release defects, improve presentation/feel, balance existing systems, integrate final or approved runtime media, harden persistence/performance, improve onboarding/accessibility, or prove the Windows package.

Do not add a new campaign sector, aircraft family, game mode, meta-progression layer or renderer architecture unless an evidenced release blocker cannot be corrected inside the existing design.

## Balance rule

Do not tune difficulty, rewards, damage, repair costs, equipment prices, weapons or mission pressure from an invulnerable autoplay trace, one deterministic vulnerable bot run or the static affordability model alone. Use `tools/run_vulnerable_balance_telemetry.ps1` as a repeatable pressure signal and `tools/run_economy_progression_audit.ps1` as a structural progression signal. Corroborate material balance changes with vulnerable completed-sortie/human Test Lab evidence or a directly proven runtime defect.

## Evidence rule

Do not describe the game as release-ready from source inspection alone. Native Godot execution, packaged-build startup, representative vulnerable gameplay, performance and human visual/playtest/audio/balance evidence remain required.

## Repository rule

Work on `main` and keep changes bounded to the current release tranche. New ideas belong in post-release backlog rather than v1 scope.
