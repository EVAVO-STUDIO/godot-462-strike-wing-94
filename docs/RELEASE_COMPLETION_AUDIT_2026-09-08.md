# HYPERSONIC Release Completion Audit — 2026-09-08

Status: **release candidate / feature freeze**  
Portfolio tranche: `docs/PORTFOLIO_RELEASE_TRANCHE.md`  
Active release target: **Windows Desktop**  
Required engine for candidate evidence: **Godot 4.6.2**

## Executive judgement

HYPERSONIC is no longer blocked by missing campaign architecture. The repository contains a playable 30-mission three-sector campaign, six secret sorties, endings/credits, persistent progression, mature combat systems, governed runtime art/audio, accessibility, all-branch campaign-route coverage, performance profiling, broad visual capture, bounded integration telemetry, vulnerable pressure instrumentation, sequential economy/progression evidence, exact-SHA native Test Lab contracts and a packaged Windows verification path.

The remaining release work is **execute the evidence on the real Windows host, judge the game, fix measured defects and cut an intentional candidate identity**. It is not new feature-family work.

The correct production behaviour is:

1. keep the feature freeze;
2. run the complete exact-engine Windows automated gate from clean `main`;
3. run the pinned exact-SHA native Test Lab journeys in the interactive Windows session;
4. inspect vulnerable pressure, economy, route, video, screenshot, log and audio evidence;
5. fix only evidenced release defects and refresh affected evidence after every source change;
6. complete the exact-SHA human campaign/controller/visual/audio/balance signoff;
7. promote `0.1.0-dev` only when the selected SHA is intentionally becoming an external candidate;
8. run `tools/validate_windows_candidate.ps1` with no skipped evidence.

## What the repository proves structurally

### Campaign breadth and routing

- 30 authored core missions across Mercenary War, Machine War and BLACK SKY.
- Six secret sorties.
- Campaign completion, ending cinematic, credits and post-campaign state exist.
- Campaign validation exercises all eight combinations of the three controlled binary branch decisions through real mission-result and advancement code.
- Every governed branch route contains 27 sorties; together the route matrix visits all 30 core missions.

### Persistence

- Current campaign save authority is schema v13.
- Stable mission IDs protect campaign position from index drift.
- Primary and backup saves are validated before restoration.
- v1-v12 save migration remains supported under the current authority.
- Campaign completion, difficulties, secret discovery, mode records, branch decisions, intelligence, career statistics, loadout, airframe and support progression are persisted.
- README save-version language is contract-checked against the runtime authority so this drift cannot silently return.

### Automated Windows release stack

`tools/validate_windows_release.ps1` owns the complete automated Windows evidence chain:

1. release-contract verification;
2. resolve one exact Godot 4.6.2 executable;
3. source/data/editor/headless self-test validation;
4. native 1280×720 production-combat performance stress;
5. canonical 640×360 logical visual QA matrix;
6. eight-sortie bounded integration/system-usage telemetry;
7. nine-case **vulnerable** pressure/difficulty telemetry;
8. authored economy/service/sequential-progression audit;
9. all eight campaign branch routes projected across all four difficulties;
10. canonical embedded-PCK Windows export;
11. packaged executable metadata/startup verification;
12. exact-SHA package receipt when no stage was skipped.

A run using any release skip switch is diagnostic. It deliberately cannot issue the full exact-SHA release receipt.

### Performance contract

The production stress profile exercises the active combat runtime rather than an empty synthetic scene. The governed contract requires at least 60 average FPS and p95 frame time no worse than 16.67 ms under its declared stress density.

### Presentation evidence

The logical visual matrix covers front door, title transformation, menus, stores/loadout, options/accessibility, controls, intelligence, secret operations, branch choice, game modes, weather, long routes, enemy/surface families, support effects, altitude transitions, fighter/bomber states, bay states, warnings, pause, debriefs, final boss, ending shots and credits.

This proves broad state reachability and capture integrity. It does **not** replace human judgement of the real displayed 1280×720, 1920×1080 or fullscreen experience.

### Integration telemetry

The bounded autopilot matrix exercises representative first, bomber-heavy, difficult-air, altitude-choice, machine-reveal, orbital-transition, secret and final sorties. It requires live combat, hits/destruction, transformation, altitude changes, evasive roll, countermeasures, tactical support, battlefield support, ordnance and bounded combat density.

These runs intentionally use invulnerability for integration reach. They prove systems integrate; they do not prove survivability or feel.

### Vulnerable pressure evidence

`tools/run_vulnerable_balance_telemetry.ps1` removes invulnerability and records nine governed pressure windows:

- Mission 1 on Cadet, Combat, Veteran and Ace;
- low-altitude bomber pressure;
- high-altitude fighter pressure;
- Machine War pressure;
- orbital pressure;
- late final-command pressure.

It records survival ratio, damage rate/source, accuracy, kills, score rate, missiles, countermeasures, system use and density. Early deterministic-bot death is a review signal, not automatic permission to change difficulty.

### Sequential economy and progression evidence

`tools/run_economy_progression_audit.ps1` validates the authored economy and models the real sequential ownership ladders for primary weapons, generators, airframes and tactical support.

The evidence distinguishes individual `sticker_cost` from `cumulative_acquisition_cost`, identifies the four actually-next-purchasable fresh-campaign choices and checks a deliberately harsh Mission-1 affordability reserve after near-loss hull plus empty-shield servicing.

`tools/run_route_progression_projection.ps1` then projects:

- 8 real campaign branch routes;
- 4 difficulties;
- 27 sorties per route;
- zero score;
- guaranteed fixed rewards only;
- selected branch bonuses;
- worst-survivable starting-airframe full-service reserve after every successful sortie;
- technology-era legality;
- cumulative acquisition cost for each independent progression family.

Any never-reachable tier is a human-review signal. The stress projection is not a target economy and must never auto-tune prices.

### Native Test Lab release evidence contract

`.evavo/godot-lab-native.json` owns eight HYPERSONIC native journeys including authentic keyboard front-door flows at 1280×720 and 1920×1080, Options/Controls, synthetic-gamepad front door/combat, bomber combat, missile/countermeasure recovery, orbital combat and final-boss pressure.

The release handoff is pinned to Godot Game Test Lab SHA:

`32693ba39a3360dac6cdafd116da930d52553184`

`tools/run_native_test_lab_release.ps1` requires:

- clean HYPERSONIC `main`;
- clean Test Lab at the pinned SHA;
- exact HYPERSONIC target SHA;
- exact Godot 4.6.2;
- an interactive Windows desktop session for authoritative native evidence.

Noninteractive/contract-test execution cannot issue the authoritative native handoff.

### Critical audio cue protection

The procedural SFX runtime retains its eight-voice ceiling but no longer uses blind FIFO eviction under load. Critical cockpit/command cues now outrank routine gunfire and impact chatter.

A short critical-cue window ducks lower-priority procedural chatter/propulsion, and the tracker music accepts a smoothed critical-warning duck request. Ordinary gunfire, explosions and normal spectacle do not constantly pump the music. Existing SFX/music regression tests protect the priority and ducking contract.

This reduces a concrete release risk: missile warnings, shield collapse and command alerts can no longer be displaced merely because the procedural voice pool was already saturated with routine effects.

## Release-truth hardening

### Exact engine authority

`tools/resolve_release_godot.ps1` rejects release evidence unless the resolved engine identifies as Godot 4.6.2. Release stages receive the same resolved executable rather than independently finding arbitrary Godot installations.

### Exact-SHA packaged-build receipt

`tools/write_windows_release_receipt.ps1` records source SHA/branch, local `origin/main`, clean-worktree state, Godot version, executable path/size/SHA-256, Windows metadata and product identity. It refuses a dirty worktree, non-`main` source or source that differs from the locally known `origin/main`.

### Human signoff is an evidence authority

`docs/RELEASE_SIGNOFF_TEMPLATE.json` is now schema v3. Human signoff must belong to the exact current HYPERSONIC SHA and explicitly cover:

- pinned native Test Lab handoff and retained media/log/audio review;
- complete campaign review;
- keyboard and controller coverage;
- onboarding without README/developer help;
- vulnerable difficulty evidence;
- sequential economy and all-route progression evidence;
- no trivial dominant strategy or progression wall;
- native 1280×720 and 1920×1080/fullscreen presentation;
- HUD/warning/accessibility behaviour;
- critical audio readability and no warning masking/clipping;
- zero unresolved P0/P1 blockers.

`tools/verify_human_release_signoff.ps1` rejects stale or mismatched evidence. The vulnerable summary, economy audit, route projection and native Test Lab handoff must all match the exact source SHA; their governed schemas/matrices are checked before the human `passed` flags are accepted.

### Final candidate gate

`tools/validate_windows_candidate.ps1` is stricter than the automated release audit. It:

- rejects a `-dev` product identity;
- requires product identity and Windows export product version to agree;
- runs the complete automated Windows gate with no skip path;
- verifies exact-SHA human signoff and its evidence chain;
- verifies the resulting package receipt belongs to the exact current source SHA and product version.

Passing it is a local technical/human candidate boundary, not store-publication authority.

## Remaining P0 work

### P0.1 Execute the complete Windows automated gate

The GitHub-connected session can inspect and change source but is not the required native Windows Godot execution authority.

On the actual production workstation:

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\validate_windows_release.ps1
```

Do not use skip switches for candidate evidence.

### P0.2 Execute pinned native Test Lab journeys

From the clean target and clean pinned Lab checkout, run the project-owned HYPERSONIC native handoff wrapper. Review its retained videos, checkpoints, logs and audio rather than treating a runner exit code as visual/audio approval.

### P0.3 Complete human end-to-end campaign review

A human must complete the campaign from a clean start on the intended source SHA and record defects affecting mission clarity, difficulty spikes, upgrade/repair economy, dominant strategies, route/form/altitude readability, retry friction, bosses, ending/credits flow and save/restore confidence.

At minimum, complete a keyboard campaign and representative physical-controller coverage sufficient to establish practical command/menu usability. Synthetic gamepad Test Lab evidence does not prove physical-device feel.

### P0.4 Complete human visual/audio review

Review the actual desktop presentation and sound, especially warning priority under heavy effects, projectile/background separation, weather masking, low-health/shield-collapse feedback, reduced-flash behaviour and music versus missile/radio/objective cues.

### P0.5 Zero P0/P1 defects on the selected candidate SHA

Any source fix changes the SHA and invalidates stale exact-SHA evidence/signoff. Refresh the affected evidence rather than carrying approval across source changes.

## Remaining P1 work

### Candidate version identity

`data/product_identity.json` remains `0.1.0-dev` intentionally. Keep that during ordinary defect closure. Only when a specific SHA has completed the required evidence should it be promoted to an explicit RC/release identity and synchronized with `export_presets.cfg`.

### Human difficulty/economy judgement

Automation provides reproducible hypotheses, not commercial balance certification. Human review must still judge:

- Cadet, Combat and Ace pressure, with Veteran sampled between them;
- early upgrade affordability after realistic rather than worst-case servicing;
- repair/recharge economy over repeated missions;
- bomber versus fighter reward/risk;
- usefulness of all progression families;
- sequential acquisition friction versus meaningful choice;
- late-game energy and strategic-system dominance;
- final-sector attrition and boss duration;
- whether branch bonuses produce unintended economically dominant route choices.

Do not change prices or rewards merely because the harsh route stress projection produces an early/late acquisition milestone.

## Scope explicitly excluded from this tranche

Do not add:

- another campaign sector;
- another aircraft family;
- another major game mode;
- new meta-progression architecture;
- renderer rewrite;
- speculative collision/world rewrite;
- new platform targets before Windows closes.

Those are post-release/backlog decisions unless a measured candidate blocker proves the existing implementation cannot be repaired.

## Candidate command

After the exact-SHA evidence has been executed/reviewed, `work/release_signoff.json` is complete for that same SHA, and product identity has deliberately moved off `-dev`:

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\validate_windows_candidate.ps1
```

A pass means HYPERSONIC has matched automated Windows evidence, native Test Lab evidence, human campaign/visual/audio/balance signoff and package provenance on one governed source identity.
