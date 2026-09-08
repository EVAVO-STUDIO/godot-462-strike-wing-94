# HYPERSONIC Native Test Lab Release Journeys

Status: release-tranche native evidence contract  
Profile: `.evavo/godot-lab-native.json`  
Pinned Test Lab: `.evavo/godot-lab-native.lock.json`  
Runner: `tools/run_native_test_lab_release.ps1`

## Why this exists

Source checks, headless tests, visual fixtures and deterministic autoplay cannot prove that the actual Windows presentation behaves correctly when driven through a native window. HYPERSONIC therefore has a project-owned Godot Game Test Lab profile for repeatable native evidence.

The profile is deliberately split between **authentic front-door journeys** and **focused fixture journeys**.

Authentic front-door journeys start the configured `res://scenes/main.tscn` with no capture arguments and allow the complete EVAVO/HYPERSONIC startup sequence to finish before interacting with the game.

Focused fixture journeys use the project's existing `--capture-*` development arguments to enter a specific authored combat state. They are useful for visual/input/audio inspection of a known state, but they do not prove campaign progression, economy, unlocks or player survival up to that state.

Neither class of synthetic journey replaces human playtest authority.

## Authority lock

Native release evidence must use:

- the exact HYPERSONIC `main` HEAD SHA being reviewed;
- a clean HYPERSONIC worktree;
- the exact Godot Game Test Lab SHA pinned in `.evavo/godot-lab-native.lock.json`;
- a clean Test Lab worktree;
- the same exact Godot **4.6.2** executable required by HYPERSONIC's Windows release gate;
- a logged-in interactive Windows session for authoritative desktop evidence.

The project wrapper passes both exact SHAs to Test Lab. Updating the pinned Lab SHA is a deliberate authority change and requires re-reviewing the Test Lab native profile/schema/runner contract.

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

The wrapper resolves the governed Godot 4.6.2 executable through `tools/resolve_release_godot.ps1` and stores evidence under:

```text
work/test_lab_native/<exact-target-sha>/
```

Do not use `-AllowNonInteractive` for release evidence. That option exists only to exercise the contract in environments without an interactive desktop; Test Lab explicitly does not treat such a run as native desktop evidence.

## Authentic front-door journeys

### `front-door-keyboard-1280x720`

Proves the default desktop path at the authored presentation size:

1. let the full EVAVO + HYPERSONIC startup sequence complete;
2. capture main menu;
3. enter Sortie Bay through the normal campaign menu;
4. launch Mission 1 through the ordinary confirmation path;
5. capture ingress;
6. exercise movement, primary fire, transform and afterburner through live InputMap actions;
7. capture live combat;
8. open the in-mission pause command surface.

Required action validation confirms that primary campaign controls still expose both keyboard and gamepad events where expected.

### `front-door-keyboard-1920x1080`

Runs the genuine front door at 1920×1080 and captures both main menu and Sortie Bay. This is primarily a native scaling/layout guard against clipped or badly scaled custom-drawn presentation.

### `options-controls-keyboard`

Navigates from the genuine front door to Options and Flight Controls using the authored menu ordering. It proves that the current menu contract remains reachable without development fixtures and that the expected movement, throttle and missile actions exist.

### `front-door-synthetic-gamepad`

Runs the genuine front door with actual injected `InputEventJoypad*` events rather than semantic action-only steps. It exercises:

- controller confirmation into Sortie Bay;
- controller launch into Mission 1;
- left-stick movement;
- primary fire;
- transform;
- afterburner;
- altitude-up input.

The profile separately validates that those actions remain backed by the game's configured gamepad mappings.

## Focused fixture journeys

### `bomber-low-strike-fixture`

Loads the authored Mission 2 refinery state at low altitude in bomber form and exercises primary fire, strike ordnance and tactical support. It is a focused attack-role presentation/input inspection, not evidence that a fresh campaign has unlocked or afforded anything beyond its normal progression.

### `missile-countermeasure-fixture`

Loads the high-altitude missile-warning state and injects the configured left-trigger countermeasure axis plus evasive-roll/steering input. Use the checkpoints to review warning readability, countermeasure feedback, motion and audio priority.

### `orbital-combat-fixture`

Loads representative orbital combat and exercises primary fire, battlefield support and missile input. Use it for high-altitude readability, background separation, projectile contrast and sound-density review.

### `final-boss-fixture`

Loads the existing final-boss capture state and records Machine Ark pressure before/after active fire/support input. It proves that this authored state can be driven in a native window; it does **not** prove the complete Mission 30 journey, boss kill, campaign ending, credits or campaign economy.

Those remain separate campaign/human evidence requirements.

## Evidence expected from Test Lab

The native worker should retain the Test Lab evidence associated with the exact run, including where supported by the current Lab contract:

- journey reports and assertions;
- checkpoint frames/screenshots;
- control-tree/layout analysis;
- video/contact-sheet evidence;
- engine/runtime logs;
- performance summaries;
- synchronized audio evidence and derived waveform/spectrogram/media reports when native capture is enabled by the worker;
- exact Lab and target SHA provenance.

A passing synthetic journey means its declared interaction/assertion contract passed. It does not mean a human approved composition, animation, mix, game feel or balance.

## Required human review after native execution

A human reviewer should inspect the exact-SHA native evidence and still personally verify at least:

- startup duration, size and audio sync;
- title-to-menu transition quality;
- 720p and 1080p pixel scaling/readability;
- keyboard and controller responsiveness;
- Mission 1 onboarding without prior knowledge;
- HUD legibility while moving and firing;
- transform/afterburner clarity;
- missile warning/countermeasure priority;
- bomber attack readability;
- pause/options/control discoverability;
- orbital contrast and projectile readability;
- final boss visual/audio density;
- music/SFX/radio priority and fatigue over extended play;
- no visible developer fixtures in an ordinary campaign path.

The human release signoff remains bound to the exact target SHA and is validated separately by `tools/verify_human_release_signoff.ps1`.

## Engine boundary

Godot Game Test Lab may support newer maintenance engines for general QA. HYPERSONIC's release target remains exact Godot **4.6.2**. The project wrapper therefore supplies its own governed 4.6.2 executable explicitly rather than relying on Test Lab's default engine resolver.

## Scope boundary

Do not grow this profile into a second gameplay-test framework. Add a journey only when it closes a release evidence gap that is materially better proven in a native window. Deterministic rules and source/runtime integration stay in the repository's existing headless tests and telemetry tools.
