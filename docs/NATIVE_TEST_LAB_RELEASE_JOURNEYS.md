# HYPERSONIC Native Test Lab Release Journeys

Status: release-tranche native evidence contract  
Core profile: `.evavo/godot-lab-native.json`  
Controller-front-end profile: `.evavo/godot-lab-controller-sortie.json`  
Pinned Test Lab: `.evavo/godot-lab-native.lock.json`  
Runner: `tools/run_native_test_lab_release.ps1`

## Why this exists

Source checks, headless tests, visual fixtures and deterministic autoplay cannot prove that the actual Windows presentation behaves correctly when driven through a native window. HYPERSONIC therefore owns repeatable Godot Game Test Lab profiles for native release evidence.

The governed release set contains **ten required journeys**:

- four authentic front-door/core journeys;
- four focused combat fixture journeys;
- one authentic controller-maintenance journey;
- one authentic controller Options/Flight-Controls navigation journey.

Authentic front-door journeys start `res://scenes/main.tscn` with no capture arguments and allow the complete EVAVO/HYPERSONIC startup sequence to finish before interacting with the game.

Focused fixture journeys use existing `--capture-*` development arguments to enter a specific authored combat state. They are useful for visual/input/audio inspection of a known state, but they do not prove campaign progression, economy, unlocks or player survival up to that state.

Neither class of synthetic journey replaces human playtest authority.

## Authority lock

Native release evidence must use:

- the exact HYPERSONIC `main` HEAD SHA being reviewed;
- a clean HYPERSONIC worktree;
- the exact Godot Game Test Lab SHA pinned in `.evavo/godot-lab-native.lock.json`;
- a clean Test Lab worktree;
- the same exact Godot **4.6.2** executable required by HYPERSONIC's Windows release gate;
- a logged-in interactive Windows session for authoritative desktop evidence.

The project wrapper passes both exact SHAs to Test Lab. Updating the pinned Lab SHA is a deliberate authority change and requires re-reviewing the Test Lab profiles/schema/runner contract.

The final native handoff must record `required_journey_count = 10`, `controller_sortie_required = true` and `controller_menu_required = true`. `tools/verify_native_release_handoff.ps1` rejects older evidence or handoffs missing `.evavo/godot-lab-controller-sortie.json`.

## Run locally

With the default sibling checkout layout:

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\run_native_test_lab_release.ps1
```

If Test Lab lives elsewhere:

```powershell
.\tools\run_native_test_lab_release.ps1 `
  -LabRoot D:\Tools\godot-game-test-lab
```

The wrapper resolves governed Godot 4.6.2 through `tools/resolve_release_godot.ps1` and stores evidence beneath:

```text
work/test_lab_native/<exact-target-sha>/
```

The core profile writes to the target-SHA artifact directory; the two controller front-end journeys write beneath its `controller_sortie/` child.

Do not use `-AllowNonInteractive` for release evidence. That option exists only to exercise the contract in environments without an interactive desktop; Test Lab explicitly does not treat such a run as native desktop evidence and the project wrapper does not issue an authoritative handoff.

## Authentic front-door journeys

### `front-door-keyboard-1280x720`

Proves the default desktop path at the authored presentation size: full startup, main menu, Sortie Bay, ordinary Mission 1 launch, ingress, movement, primary fire, transform, afterburner, live combat and pause.

### `front-door-keyboard-1920x1080`

Runs the genuine front door at 1920×1080 and captures both main menu and Sortie Bay. This is primarily a native scaling/layout guard against clipped or badly scaled custom-drawn presentation.

### `options-controls-keyboard`

Navigates from the genuine front door to Options and Flight Controls using the authored menu ordering. It proves the keyboard-facing menu contract remains reachable without development fixtures.

### `front-door-synthetic-gamepad`

Runs the genuine front door with actual injected `InputEventJoypad*` events rather than semantic action-only steps. It exercises controller confirmation, launch, left-stick movement, primary fire, transform, afterburner and altitude-up input.

### `controller-sortie-bay-maintenance`

This authentic no-fixture journey exists because controller progression is a release-critical campaign path, not a combat action set. After reaching the real Sortie Bay it injects physical joypad events for:

- X — buy primary;
- Y — buy generator;
- LB — service hull;
- RB — recharge shield;
- L3 — buy airframe;
- R3 — buy tactical support;
- D-pad Left — select tactical support;
- D-pad Right — select battlefield support;
- RT — select owned primary.

The sortie-bay router exposes QA metadata only after a physical joypad event passes the real campaign-sortie visibility gate. A purchase may legitimately fail because the fresh campaign has only 2,500 credits; the authority being proven here is **command reachability and contextual routing**, not fabricated purchasing power.

### `controller-options-controls-navigation`

This second controller-specific front-door journey closes two menu-context defects that combat testing could not expose.

It navigates the real main menu to **System Options**, verifies the contextual pad contract, returns with B, opens **Flight Controls**, verifies controller A cannot enter the keyboard-only rebind listener, then returns with B.

The governed controller menu contract is:

- Options: Y/X change category, left stick selects/adjusts rows, A adjusts forward, B returns;
- Flight Controls: pad navigation is view-only, left stick scrolls, B returns, and A is suppressed so a controller-only player cannot become trapped waiting for an `InputEventKey`.

The journey asserts metadata receipts from `ControllerMenuContextDirector` for Options configuration, previous/next category, B/back, Controls configuration and suppressed A/confirm.

These remaps exist only while the corresponding front-end screen is active. Leaving those screens restores the exact universal/in-flight controller map.

## Focused fixture journeys

### `bomber-low-strike-fixture`

Loads Mission 2 at low altitude in bomber form and exercises primary fire, strike ordnance and tactical support.

### `missile-countermeasure-fixture`

Loads the high-altitude missile-warning state and injects the configured left-trigger countermeasure axis plus evasive-roll/steering input.

### `orbital-combat-fixture`

Loads representative orbital combat and exercises primary fire, battlefield support and missile input.

### `final-boss-fixture`

Loads the existing final-boss capture state and records Machine Ark pressure before/after active fire/support input. It does **not** prove the complete Mission 30 journey, boss kill, campaign ending, credits or campaign economy.

## Evidence expected from Test Lab

The native worker should retain evidence associated with the exact run, including where supported by the current Lab contract:

- journey reports and assertions;
- checkpoint frames/screenshots;
- control-tree/layout analysis;
- video/contact-sheet evidence;
- engine/runtime logs;
- performance summaries;
- synchronized audio evidence and derived waveform/spectrogram/media reports when native capture is enabled;
- exact Lab and target SHA provenance;
- controller-sortie and controller-menu metadata receipts.

A passing synthetic journey means its declared interaction/assertion contract passed. It does not mean a human approved composition, animation, mix, game feel or balance.

## Required human review after native execution

A human reviewer should inspect the exact-SHA native evidence and still personally verify at least:

- startup duration, size and audio sync;
- title-to-menu transition quality;
- 720p and 1080p pixel scaling/readability;
- keyboard and controller responsiveness;
- controller purchase/service/select discoverability on the Sortie Bay;
- controller Options navigation and B/back behavior;
- controller Flight Controls behavior without entering keyboard-only listening;
- Mission 1 onboarding without README or developer help;
- HUD legibility while moving and firing;
- transform/afterburner clarity;
- missile warning/countermeasure priority;
- bomber attack readability;
- pause/options/control discoverability;
- orbital contrast and projectile readability;
- final boss visual/audio density;
- music/SFX/radio priority and fatigue over extended play;
- no visible developer fixtures in an ordinary campaign path.

`docs/RELEASE_SIGNOFF_TEMPLATE.json` includes both `native_test_lab.controller_maintenance_reviewed` and `native_test_lab.controller_menu_navigation_reviewed`. The final candidate gate requires both and separately validates the ten-journey handoff.

## Engine boundary

Godot Game Test Lab may support newer maintenance engines for general QA. HYPERSONIC's release target remains exact Godot **4.6.2**. The project wrapper therefore supplies its own governed 4.6.2 executable explicitly rather than relying on Test Lab's default engine resolver.

## Scope boundary

Do not grow these profiles into a second gameplay-test framework. Add a journey only when it closes a release evidence gap materially better proven in a native window. Deterministic rules and source/runtime integration stay in the repository's existing headless tests and telemetry tools.
