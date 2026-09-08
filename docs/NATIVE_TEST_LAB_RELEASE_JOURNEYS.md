# HYPERSONIC Native Test Lab Release Journeys

Status: release-tranche native evidence contract  
Core profile: `.evavo/godot-lab-native.json`  
Controller profile: `.evavo/godot-lab-controller-sortie.json`  
Pinned Test Lab: `.evavo/godot-lab-native.lock.json`  
Runner: `tools/run_native_test_lab_release.ps1`

## Why this exists

Source checks, headless tests, visual fixtures and deterministic autoplay cannot prove that the actual Windows presentation behaves correctly when driven through a native window. HYPERSONIC therefore owns repeatable Godot Game Test Lab profiles for native release evidence.

The governed release set contains **ten required journeys**:

- four authentic core/front-door journeys;
- four focused combat fixture journeys;
- two authentic controller front-end journeys.

Authentic front-door journeys start `res://scenes/main.tscn` with no capture arguments and allow the full EVAVO/HYPERSONIC startup sequence to finish before interaction. Focused fixture journeys may use existing `--capture-*` development arguments to inspect one authored combat state, but they do not prove campaign progression, economy, unlocks or survival up to that state.

Neither class replaces human playtest authority.

## Authority lock

Release evidence must use:

- exact HYPERSONIC `main` HEAD;
- clean HYPERSONIC worktree;
- exact Test Lab SHA pinned in `.evavo/godot-lab-native.lock.json`;
- clean Test Lab worktree;
- exact Godot **4.6.2** supplied by HYPERSONIC;
- logged-in interactive Windows session.

The final handoff must record `required_journey_count = 10`, `controller_sortie_required = true` and `controller_menu_required = true`. `tools/verify_native_release_handoff.ps1` rejects older handoffs.

## Run locally

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\run_native_test_lab_release.ps1
```

If Test Lab is elsewhere:

```powershell
.\tools\run_native_test_lab_release.ps1 `
  -LabRoot D:\Tools\godot-game-test-lab
```

Evidence belongs under `work/test_lab_native/<exact-target-sha>/`.

Do not use `-AllowNonInteractive` for release evidence. It is contract-test-only and cannot create the authoritative native handoff.

## Authentic front-door journeys

### `front-door-keyboard-1280x720`

Covers full startup, main menu, Sortie Bay, Mission 1 ingress/live combat and pause entry at the authored 720p desktop presentation size.

### `front-door-keyboard-1920x1080`

Covers genuine startup/main menu/Sortie Bay at 1080p for native scaling and clipping review.

### `options-controls-keyboard`

Covers normal keyboard navigation into Options and the keyboard assignment station.

### `front-door-synthetic-gamepad`

Uses physical synthetic joypad events for genuine menu confirmation, launch, left-stick movement, fire, transform, afterburner and altitude input.

### `controller-sortie-bay-maintenance`

Authentic no-fixture controller progression journey. On the real campaign Sortie Bay it exercises:

- X — buy primary;
- Y — buy generator;
- LB — service hull;
- RB — recharge shield;
- L3 — buy airframe;
- R3 — buy tactical support;
- D-pad Left — select tactical support;
- D-pad Right — select battlefield support;
- RT — select owned primary.

The router publishes QA receipts only after physical events pass the visible campaign-Sortie-Bay gate. Fresh-campaign purchases may legitimately fail for lack of credits; this journey proves command reachability and contextual routing, not fake purchasing power.

### `controller-options-controls-navigation`

This authentic controller journey now covers the full controller front-end context that release candidates depend on:

1. enter Options from the real main menu;
2. use Y/X for category navigation while B remains Back;
3. return with B;
4. enter Flight Controls;
5. prove A is suppressed there so a controller-only player cannot enter keyboard-only key listening;
6. return with B;
7. enter the real campaign Sortie Bay and launch Mission 1;
8. prove flight controller context maps **START to Pause while B remains Screen Bomb**;
9. open tactical pause through START;
10. enter paused Options;
11. use Y/X for categories and B to return to pause Commands;
12. use B to resume live gameplay.

This journey asserts controller-context metadata for normal Options, Flight Controls, flight START pause, and paused Options. It closes the specific class of conflicts caused by reusing combat buttons in menus without changing the in-flight combat map.

## Controller truth boundary

The intended controller model is now explicit:

- flight: B = Screen Bomb, START = Pause;
- normal menus: B = Back/Cancel;
- Options: Y/X category, left stick adjusts/navigates, B = Back;
- Flight Controls: pad is view/scroll only, B = Back, A cannot start keyboard key listening;
- tactical pause: A = Select/Confirm, B = Resume/Cancel, X = quick Restart confirmation;
- paused Options: Y/X category, B = Commands.

Keyboard rebinding remains authoritative for keyboard labels. Mission 1 contextual guidance reads the live keyboard InputMap so prompts cannot drift after a rebind.

## Focused fixture journeys

### `bomber-low-strike-fixture`

Mission 2 low-altitude bomber attack with primary fire, strike ordnance and tactical support.

### `missile-countermeasure-fixture`

High-altitude warning state with countermeasure and evasive input for warning/audio priority review.

### `orbital-combat-fixture`

Representative orbital combat for projectile/background separation, support and missile review.

### `final-boss-fixture`

Machine Ark pressure state for native visual/audio density. It does not prove the full Mission 30 journey, ending or campaign economy.

## Evidence expected from Test Lab

Retain where supported:

- journey reports/assertions;
- checkpoint frames/screenshots;
- control-tree/layout analysis;
- video/contact-sheet evidence;
- engine/runtime logs;
- performance summaries;
- synchronized audio evidence;
- exact Lab/target SHA provenance;
- controller routing metadata receipts.

A passing synthetic journey proves its declared interaction contract only. It does not mean a human approved composition, animation, audio mix, game feel or balance.

## Human review

The exact-SHA reviewer must still verify startup quality, 720p/1080p scaling, keyboard/controller responsiveness, Sortie Bay maintenance clarity, controller Options/Controls/pause behavior, Mission 1 onboarding without README/developer help, HUD readability, transform/afterburner clarity, missile warning priority, bomber readability, orbital contrast, final-boss density and extended music/SFX/radio fatigue.

`docs/RELEASE_SIGNOFF_TEMPLATE.json` therefore includes both `native_test_lab.controller_maintenance_reviewed` and `native_test_lab.controller_menu_navigation_reviewed`.

## Engine and scope boundary

Test Lab may support newer engines for general QA. HYPERSONIC release evidence remains pinned to Godot **4.6.2**.

Do not grow these profiles into a second gameplay framework. Add or expand a journey only when it closes a release evidence gap materially better proven in a native window. Deterministic rules and source/runtime integration remain in the repository's existing self-tests and telemetry tools.
