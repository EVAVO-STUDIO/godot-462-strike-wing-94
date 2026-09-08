# HYPERSONIC Release Completion Audit — 2026-09-08

Status: **release candidate / feature freeze**  
Portfolio tranche: `docs/PORTFOLIO_RELEASE_TRANCHE.md`  
Active release target: **Windows Desktop**  
Required engine for candidate evidence: **Godot 4.6.2**

## Executive judgement

HYPERSONIC is no longer blocked by missing campaign architecture. The repository contains a playable 30-mission three-sector campaign, six secret sorties, endings/credits, persistent progression, mature combat, governed runtime art/audio, accessibility, all-branch campaign-route coverage, performance/visual instrumentation, vulnerable pressure evidence, sequential economy analysis, ten native Test Lab journeys and a packaged Windows verification path.

The remaining release work is **execute evidence on the real Windows host, judge the game, fix measured defects and cut an intentional candidate identity**. It is not new feature-family work.

Correct production behaviour:

1. keep the feature freeze;
2. run the complete exact-engine Windows automated gate from clean `main`;
3. run the pinned exact-SHA native Test Lab set in an interactive Windows session;
4. inspect vulnerable pressure, economy, route, branch, spending-strategy, video, screenshot, log and audio evidence;
5. fix only evidenced release defects and refresh affected evidence after each source change;
6. complete exact-SHA human campaign/controller/onboarding/visual/audio/balance signoff;
7. promote `0.1.0-dev` only when that SHA is intentionally becoming an external candidate;
8. run `tools/validate_windows_candidate.ps1` with no skipped evidence.

## Structurally proven

### Campaign breadth and routing

- 30 authored core missions across Mercenary War, Machine War and BLACK SKY.
- Six secret sorties.
- Campaign completion, ending cinematic, credits and post-campaign state.
- All eight combinations of the three controlled binary branch decisions execute through real result/advancement code.
- Each governed branch route contains 27 sorties; the combined matrix visits all 30 core missions.

### Persistence

- Campaign save schema v13.
- Stable mission IDs protect campaign position from index drift.
- Validated primary/backup restoration.
- v1-v12 migrations supported.
- Completion, difficulties, secrets, records, branch choices, intelligence, career statistics, loadout, airframe and support progression persist.
- README save-version language is contract-checked against runtime authority.

### Automated Windows evidence chain

`tools/validate_windows_release.ps1` owns the complete local automated chain:

1. primary release-contract verification;
2. supplemental controller/onboarding release-contract verification;
3. exact Godot 4.6.2 resolution;
4. source/data/editor/headless self-test validation;
5. native 1280×720 production-combat performance stress;
6. canonical logical visual QA matrix;
7. eight-sortie bounded integration/system-usage telemetry;
8. nine-case vulnerable pressure/difficulty telemetry;
9. authored economy/service/sequential-progression audit;
10. eight campaign routes × four difficulties projection;
11. paired branch-choice economic dominance analysis;
12. 224 reserve-aware progression spending simulations;
13. canonical embedded-PCK Windows export;
14. packaged executable metadata/startup verification;
15. exact-SHA package receipt when no release stage was skipped.

Any release skip switch makes the run diagnostic and prevents the full receipt.

### Performance and presentation

The performance profile exercises the production combat stack and requires at least 60 average FPS with p95 frame time no worse than 16.67 ms under governed stress density.

The visual matrix covers startup/title, menus, Sortie Bay, options/accessibility, controls, intelligence, secret operations, branch decisions, modes, weather, routes, enemy/surface families, support, altitude/transform states, warnings, pause, debrief, final boss, ending and credits. Logical captures prove state reachability and capture integrity, not human desktop approval.

### Vulnerable pressure evidence

`tools/run_vulnerable_balance_telemetry.ps1` removes invulnerability and records nine pressure windows: Mission 1 at all four difficulties plus bomber, difficult-air, machine-war, orbital and late final-command cases. It records survival ratio, damage rate/source, accuracy, kills, score rate, missile/countermeasure use and density.

Deterministic-bot death is a review signal, not automatic balance authority.

### Economy and progression evidence

`tools/run_economy_progression_audit.ps1` models the real sequential ownership ladders for primary weapons, generators, airframes and tactical support. It distinguishes individual sticker cost from cumulative acquisition cost and guards conservative first-mission affordability after a harsh service reserve.

`tools/run_route_progression_projection.ps1` projects all 8 routes × 4 difficulties × 27 sorties using zero score, guaranteed fixed success rewards, branch bonuses, technology-era legality and worst-survivable starting-airframe service reserve.

`tools/analyze_branch_economic_dominance.ps1` pairs routes that differ in only one branch decision, isolating branch cash and upgrade-timing effects rather than comparing unrelated campaigns.

`tools/simulate_progression_spending_strategies.ps1` runs 224 conservative simulations across save-only, weapon-first, generator-first, airframe-first, support-first, cheapest-next and balanced-round-robin policies. It tests structural solvency and choice availability without pretending cross-family gameplay utility is numerically equivalent.

None of these tools may auto-tune prices/rewards. Human vulnerable play remains balance authority.

## Controller and onboarding hardening

### Sortie Bay progression is now controller-complete

The campaign previously exposed combat controller support while major maintenance/progression commands remained keyboard-only. `ControllerSortieBayDirector` now contextually maps physical pad controls on the visible campaign Sortie Bay only:

- X buy primary;
- Y buy generator;
- LB hull service;
- RB shield recharge;
- L3 airframe upgrade;
- R3 tactical-support upgrade;
- D-pad Left/Right support selection;
- RT owned-primary selection;
- A launch;
- B back.

The same physical controls retain their combat meanings in flight.

### Flight pause no longer collides with Screen Bomb

The old universal mapping made controller B both `fire_secondary` and `cancel`, allowing one B press to spend a Screen Bomb and request pause in the same frame.

The governed contextual mapping is now:

- **flight:** B = Screen Bomb; START = Pause;
- **normal menus:** B = Back/Cancel;
- **tactical pause:** B = Resume/Cancel;
- **Options:** Y/X category and B = Back;
- **paused Options:** Y/X category and B = Commands.

`tools/pause_self_test.gd` proves the temporary InputMap transitions and restoration.

### Flight Controls cannot trap a controller-only player

The Flight Controls page edits keyboard assignments. Controller A is therefore suppressed on that page; a pad may inspect/scroll but cannot enter a keyboard-only key-listening state. B returns normally.

### Mission 1 contextual guidance

Mission 1 now teaches essential commands without a modal tutorial. The first flight-check beat occurs before the normal radio briefing starts, avoiding simultaneous narrative/control instruction. Later prompts introduce throttle/geometry and altitude; real homing threats expose countermeasure controls; the special Coastal Intercept egress explicitly identifies climb and afterburner inputs.

Keyboard labels are read from the live InputMap, so rebindings remain truthful. The basic flight prompt also identifies `ESC/START PAUSE`.

## Native Test Lab authority

The release set contains **10 required native journeys**:

- eight core journeys in `.evavo/godot-lab-native.json`;
- two authentic controller journeys in `.evavo/godot-lab-controller-sortie.json`.

The controller journeys prove Sortie Bay maintenance/progression routing plus Options/Flight-Controls navigation, live Mission 1, START pause, paused Options and resume using physical synthetic joypad events.

Pinned Test Lab SHA:

`32693ba39a3360dac6cdafd116da930d52553184`

`tools/run_native_test_lab_release.ps1` requires clean HYPERSONIC `main`, clean pinned Test Lab, exact target SHA, exact Godot 4.6.2 and an interactive Windows session. Noninteractive execution cannot issue authoritative handoff evidence.

`tools/verify_native_release_handoff.ps1` rejects stale handoffs unless `required_journey_count = 10`, controller Sortie Bay evidence is required, controller menu/pause evidence is required, and all provenance matches the exact current SHA.

## Critical audio cue protection

The procedural SFX runtime retains its eight-voice ceiling but uses priority-aware admission rather than blind FIFO eviction. Missile warnings, shield collapse and command alerts outrank routine weapon/impact chatter. A short critical window ducks lower-priority procedural/propulsion sound, and tracker music receives a smoothed critical-warning duck request.

Existing audio regressions protect that policy. Human listening remains required.

## Release-truth hardening

### Exact engine and package provenance

`tools/resolve_release_godot.ps1` rejects release evidence unless the engine identifies as Godot 4.6.2. `tools/write_windows_release_receipt.ps1` records exact SHA/branch, local `origin/main`, clean-worktree status, Godot version, executable path/size/SHA-256, Windows metadata and product identity.

### Human signoff authority

`docs/RELEASE_SIGNOFF_TEMPLATE.json` is schema v4. Signoff must belong to the exact source SHA and explicitly cover:

- all ten native journeys;
- controller maintenance review;
- controller Options/Flight-Controls/pause navigation review;
- retained checkpoint/log/audio review;
- complete campaign;
- keyboard and controller coverage;
- onboarding without README/developer help;
- vulnerable difficulty evidence;
- sequential economy, route projection, branch dominance and spending-strategy evidence;
- no trivial dominant strategy or progression wall;
- native 720p and 1080p/fullscreen presentation;
- HUD/warning/accessibility behavior;
- critical audio readability/no masked warnings;
- zero unresolved P0/P1 blockers.

`tools/verify_human_release_signoff.ps1` now calls the centralized ten-journey native handoff verifier and independently validates the vulnerable/economy evidence matrices before accepting the human flags.

### Final candidate gate

`tools/validate_windows_candidate.ps1` rejects `-dev`, requires product/export versions to match, runs the complete automated gate, verifies exact-SHA human signoff and ten-journey native authority, then verifies the package receipt belongs to the same SHA/version.

Passing it is a local candidate boundary, not store-publication authority.

## Remaining P0 work

### P0.1 Execute the complete Windows automated gate

This GitHub-connected session can inspect and change source but is not the required native Windows Godot host.

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\validate_windows_release.ps1
```

No skip switches for candidate evidence.

### P0.2 Execute all ten pinned native Test Lab journeys

Run the project-owned native wrapper from the clean target and clean pinned Test Lab checkout. Review video/checkpoints/log/audio evidence; do not treat process exit alone as presentation approval.

### P0.3 Human end-to-end campaign and controller review

A human must complete the campaign from a clean start on the intended SHA and judge mission clarity, difficulty, upgrade/repair economy, dominant strategies, route/form/altitude readability, retries, bosses, ending/credits and save/restore confidence.

A physical controller should verify real feel in addition to synthetic pad evidence, including Sortie Bay progression, Options, Flight Controls, START pause, paused Options and resume.

### P0.4 Human visual/audio review

Review actual desktop presentation and sound, especially warning priority under density, projectile/background separation, weather masking, low-health/shield-collapse cues, reduced-flash behavior and music versus missile/radio/objective cues.

### P0.5 Zero P0/P1 defects on selected candidate SHA

Any source fix changes the SHA and invalidates stale exact-SHA evidence/signoff. Refresh affected evidence.

## Remaining P1 work

### Candidate version identity

`data/product_identity.json` remains `0.1.0-dev` intentionally. Promote it and synchronize `export_presets.cfg` only when a specific evidence-complete SHA is deliberately becoming an external RC/release candidate.

### Human difficulty/economy judgement

Human review must still judge realistic service costs, all difficulty bands, fighter/bomber reward-risk, progression-family usefulness, sequential acquisition friction, late-game energy/strategic dominance, final-sector attrition and whether branch bonuses create an undesirable economically dominant route.

## Scope excluded from this tranche

Do not add another sector, aircraft family, major mode, meta-progression architecture, renderer rewrite, speculative world/collision rewrite or new platform target before Windows closes.

## Candidate command

After exact-SHA evidence has actually run and been reviewed, `work/release_signoff.json` is complete for that SHA, and product identity has deliberately moved off `-dev`:

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\validate_windows_candidate.ps1
```

A pass means automated Windows evidence, ten-journey native evidence, human campaign/controller/onboarding/visual/audio/balance signoff and package provenance all agree on one source identity.
