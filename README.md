# HYPERSONIC

Original late-90s PC-style vertical scrolling combat shooter built in Godot 4.6.2.

**VX-94 VARIABLE STRIKE FIGHTER**

HYPERSONIC is centered on the **VX-94 Variable Strike Fighter (VSF)**, a 1999 imagined-future variable-geometry strike craft that can shift between fighter and bomber/attack configurations while operating from terrain-skimming altitude through near orbit. `Strike Wing '94` is retained only as a legacy/internal development alias and repository identifier.

## Current status

Playable 30-mission, three-sector campaign plus six secret sorties on `main`.

HYPERSONIC is under **release-candidate feature freeze**. The remaining work is release evidence, human play/balance judgement, presentation/audio correction, packaging and candidate identity—not new feature families.

Implemented now includes:

- approved EVAVO publisher splash and HYPERSONIC startup/title sequence
- deterministic save-isolated attract reel
- 640×360 logical canvas with nearest-neighbour 1280×720 desktop presentation
- sprite-built title, briefing, debrief, options, controls, pause and combat HUD
- production VX-94 fighter/bomber animation with ten-exposure wing sweep and banking states
- form-aware weapon mounts, muzzle positions and effect cues
- original procedural weapon/support/environment SFX and 12-cue tracker score
- four altitude bands: low / mid / high / orbital
- player-controlled altitude windows plus authored cinematic altitude transitions
- finite afterburner, persistent throttle and hypersonic travel/egress mechanics
- lateral mission-airspace recovery zones and abort countdowns
- long authored coast, refinery, city, mountain, harbor, desert, river and BLACK SKY routes
- 25-frame authored detonation suite with differentiated projectile/impact families
- eight primary weapon tiers from conventional cannon through Plasma Lance
- generator progression and era-specific efficiency
- five persistent airframe tiers
- seven onboard tactical support systems
- separate allied battlefield support and Atlas tanker/rearm sequence
- dedicated bomber precision-strike ordnance
- deterministic authored encounter beats, recovery windows and mastery secrets
- 30 core missions across Mercenary War, Machine War and BLACK SKY, plus six discoverable secret sorties
- four additional arcade/challenge modes with independent route/scoring rules
- 38 canonical enemy identities spanning air, ground, naval and orbital warfare, including nine bosses
- boss phases, weak-point behavior and signature attacks
- persistent campaign credits, equipment, branch choices and serviced airframe state
- versioned v13 local autosave with stable mission identity, validated backup recovery and v1-v12 migration compatibility
- campaign launch/ending cinematics, completion aftermath, credits and post-campaign presentation
- subtitles, reduced-shake, reduced-flash and enhanced-projectile-contrast accessibility controls
- mission-wide command radio with sector callsigns and priority cue handling
- priority-aware eight-voice procedural SFX allocation and critical-cue music ducking
- contextual Mission 1 control guidance that follows live keyboard rebindings
- controller-complete Sortie Bay maintenance/progression
- contextual controller Options / Flight Controls / tactical pause routing
- local zero-cost validation, native QA and exact-SHA Windows release evidence tooling

The obsolete prototype player/enemy/projectile polygons are removed from `main.gd`. Live presentation is owned by governed sprite/environment/UI/effect directors.

## Controls

### Keyboard flight

- Move: `WASD` or arrow keys
- Persistent throttle increase/decrease: `T` / `G`
- Primary fire: `Space`
- Emergency screen bomb: `X`
- Transform fighter / bomber: `Q`
- Afterburner: `Shift`
- Committed evasive roll: hold left/right and press `C`
- Climb one authorized altitude lane: `PageUp`
- Dive one authorized altitude lane: `PageDown`
- Countermeasure: `V`
- AIM-9 missile: `M`
- Bomber precision strike: `E`
- Onboard tactical support: `Z`
- Allied battlefield support: `F`
- Pause: `Esc`

Keyboard flight bindings can be reassigned from **FLIGHT CONTROLS**. The assignment station captures physical keys, swaps conflicts, persists changes and supports restoring authored defaults with `Backspace`.

### Controller flight

The in-flight pad mapping deliberately separates combat and pause:

- Move: left stick
- Persistent throttle: right stick vertical
- Primary fire: south face button / A
- **Screen Bomb: east face button / B**
- Tactical support: west face button / X
- Transform: north face button / Y
- Afterburner: left shoulder / LB
- Battlefield support: right shoulder / RB
- Countermeasure: left trigger / LT
- AIM-9 missile: right trigger / RT
- Evasive roll: left-stick click / L3
- Precision strike ordnance: right-stick click / R3
- Altitude: D-pad up/down
- **Pause: START**

B is not Pause while flying. This prevents a single controller press from both spending a Screen Bomb and opening tactical pause.

### Controller menus

Contextual mappings are intentionally different outside flight:

- normal menus: A confirm, B back
- Options: Y/X previous/next category, left stick navigate/adjust, B back
- Flight Controls: pad view/scroll only; B back; A cannot enter keyboard-only key listening
- tactical pause: A select/confirm, B resume/cancel, X quick restart confirmation
- paused Options: Y/X previous/next category, B return to Commands

### Sortie Bay / campaign maintenance

Keyboard:

- Launch: `Enter`
- Mission intelligence: `I`
- Buy next primary: `U`
- Buy next generator: `G`
- Buy next VX-94 airframe: `K`
- Cycle tactical support: `C`
- Buy next tactical support: `V`
- Repair hull: `H`
- Recharge shield: `J`
- Cycle battlefield support: `B`
- Cycle owned primary: `M`

Controller on the visible campaign Sortie Bay:

- A launch
- B back
- X buy primary
- Y buy generator
- LB service hull
- RB recharge shield
- L3 buy airframe
- R3 buy tactical support
- D-pad Left select tactical support
- D-pad Right select battlefield support
- RT select owned primary

The same physical buttons retain their normal combat meanings once the sortie begins.

### Mission flow

- Keyboard retry: `R`
- Keyboard pause: `Esc`
- Controller pause: `START`
- Controller Screen Bomb remains `B`

## Mission 1 onboarding

Coastal Intercept uses short instrument-style prompts rather than a modal tutorial. The first flight check is shown before the normal radio briefing begins; later prompts introduce throttle/geometry and altitude. Real homing threats expose countermeasure input. The mission's special hypersonic egress explicitly identifies the climb and afterburner commands required to clear the Mach gate.

Keyboard labels are read from the live `InputMap`, so prompts remain correct after rebinding.

## VX-94 combat roles

### Fighter configuration

- faster movement and tighter hit profile
- tighter primary spread and stronger air-target effectiveness
- stronger high/orbital afterburner efficiency
- wing-root conventional gun posture
- required for orbital operations

### Bomber configuration

- broader, slower attack posture
- stronger surface/naval damage
- wider weapon coverage
- improved tactical-support energy efficiency
- dedicated precision-strike ordnance
- deployed multi-barrel nose rotary cannon
- preferred at low altitude

## Altitude lanes

1. LOW
2. MID
3. HIGH
4. ORBITAL / ATMOS-SPACE

`PageUp` / `PageDown` or controller D-pad up/down moves one adjacent authorized band. Timed altitude-lane prompts identify tactical opportunities; major transitions remain authored set pieces.

## Technology eras

1. **Advanced conventional** — cannon, rockets, smart missiles, composite protection
2. **Electromagnetic** — EMP, magnetic defence, Needle Rail, advanced frames
3. **Directed energy** — Storm Cannon, field systems
4. **Strategic orbital** — Plasma Lance, Micro-Warhead Rack, orbital support

The campaign escalates from the Mercenary War through the autonomous Machine War and completes in BLACK SKY.

## Campaign economy and progression

Primary weapons, generators, airframes and tactical support are four independent **sequential ownership ladders**. Later tier sticker price is not the same as fresh-campaign acquisition cost because earlier paid tiers in that family must be owned first.

The repository therefore distinguishes:

- sticker cost
- cumulative acquisition cost
- actual next-purchasable item
- technology-era legality
- servicing liability
- branch-specific cash effects

Static projections are regression evidence, not permission to auto-tune the game.

## Project layout

Key runtime ownership:

- `scripts/main.gd` — core simulation/orchestration
- `scripts/input_bindings.gd` — universal flight/input contract
- `scripts/controller_sortie_bay_director.gd` — contextual campaign maintenance pad routing
- `scripts/controller_menu_context_director.gd` — contextual Options/Controls/flight-pause pad routing
- `scripts/first_sortie_guidance_director.gd` — bounded Mission 1 guidance
- `scripts/pause_director.gd` — tactical pause/options/restart/return surface
- `scripts/craft_form_director.gd` — form, altitude, throttle, afterburner and mission context
- `scripts/airframe_director.gd` — persistent structural progression
- `scripts/support_director.gd` — onboard tactical systems
- `scripts/battlefield_support_director.gd` — allied support/tanker
- `scripts/encounter_director.gd` — authored encounter sequencing
- `scripts/combat_art_director.gd` — combat sprite presentation
- `scripts/environment_director.gd` — terrain/weather/altitude presentation
- `scripts/pixel_ui_director.gd` — primary bitmap UI/HUD
- `scripts/retro_sfx_director.gd` — procedural SFX allocation/mix
- `scripts/retro_music_director.gd` — tracker score and critical ducking
- `scripts/campaign_save.gd` — campaign save/migration authority

Production/release authority:

- `docs/PORTFOLIO_RELEASE_TRANCHE.md`
- `docs/RELEASE_COMPLETION_AUDIT_2026-09-08.md`
- `docs/NATIVE_TEST_LAB_RELEASE_JOURNEYS.md`
- `docs/VULNERABLE_BALANCE_EVIDENCE.md`
- `docs/ECONOMY_PROGRESSION_EVIDENCE.md`
- `docs/RELEASE_SIGNOFF_TEMPLATE.json`
- `tools/validate.ps1`
- `tools/validate_windows_release.ps1`
- `tools/validate_windows_candidate.ps1`
- `tools/verify_release_contract.ps1`
- `tools/verify_release_contract_supplement.ps1`
- `tools/verify_native_release_handoff.ps1`
- `tools/verify_human_release_signoff.ps1`

## Validate locally

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\validate.ps1
```

When Godot 4.6.2 is available, validation runs the focused headless regressions and editor parser smoke test. Campaign validation executes all eight combinations of the controlled branch decisions; each route contains 27 successful sorties and the matrix collectively visits all 30 core missions.

## Automated Windows evidence

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\validate_windows_release.ps1
```

The complete gate uses one exact Godot 4.6.2 executable for:

1. release-contract validation
2. source/data/headless/editor validation
3. native 1280×720 performance stress
4. logical visual QA capture
5. eight-sortie integration telemetry
6. nine-case vulnerable pressure telemetry
7. economy/service/sequential-progression audit
8. 8-route × 4-difficulty progression projection
9. paired branch-economic analysis
10. 224 reserve-aware spending-strategy simulations
11. Windows embedded-PCK export
12. packaged startup/metadata verification
13. exact-SHA `build/windows/HYPERSONIC.release.json` receipt

Skipping a release evidence stage makes the run diagnostic and prevents the full receipt.

## Native Test Lab evidence

The project owns **10 required native journeys**:

- eight core journeys in `.evavo/godot-lab-native.json`
- two controller journeys in `.evavo/godot-lab-controller-sortie.json`

The controller set covers Sortie Bay maintenance, Options, Flight Controls, live Mission 1, START pause, paused Options and resume. Release evidence is pinned to the exact HYPERSONIC SHA, exact Test Lab SHA and exact Godot 4.6.2 in an interactive Windows session.

```powershell
.\tools\run_native_test_lab_release.ps1
```

Synthetic native journeys prove the declared interaction contract. They do not replace physical-controller feel review or human visual/audio/gameplay judgement.

## Candidate gate

`data/product_identity.json` remains a development identity until one exact SHA is intentionally selected as an external candidate.

A real candidate requires:

- non-`-dev` product identity synchronized with `export_presets.cfg`
- complete automated Windows evidence
- authoritative ten-journey native handoff
- exact-SHA human signoff from `docs/RELEASE_SIGNOFF_TEMPLATE.json`
- zero P0/P1 blockers

Then run:

```powershell
.\tools\validate_windows_candidate.ps1
```

The candidate gate verifies `HYPERSONIC.release.json` belongs to the same exact source SHA and product version.

## Direction

The target is an original, pixel-perfect late-90s PC shooter with the depth and authored discipline of the strongest era references without copying proprietary content.

Reference games can inform pacing, upgrade economy, stage rhythm, readability and genre grammar only. Do not copy proprietary names, maps, sprites, UI, sounds, dialogue, story beats or encounter layouts.

HYPERSONIC's own identity is:

- believable late-90s imagined-future military hardware
- transforming variable-geometry aerospace combat
- low-altitude bombing through orbital warfare
- meaningful altitude-lane decisions inside authored mission pacing
- mercenary conflict escalating into autonomous drone war
- visible allied support and tanker/rearm set pieces
- gradual conventional → electromagnetic → energy → strategic technology progression

## Infrastructure

- Godot 4.6.2
- GDScript-first gameplay foundation
- Windows desktop active release target
- keyboard and controller active player inputs
- no paid GitHub Actions/Vercel dependency
- local-first validation and release evidence

Copyright (c) EVAVO Studio.
