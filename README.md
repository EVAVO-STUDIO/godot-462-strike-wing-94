# HYPERSONIC

Original 90s PC-style vertical scrolling combat shooter built in Godot 4.6.2.

**VX-94 VARIABLE STRIKE FIGHTER**

HYPERSONIC is centered on the **VX-94 Variable Strike Fighter (VSF)**, a 1999 imagined-future variable-geometry strike craft that can shift between a narrow fighter configuration and a wide bomber/attack configuration while operating from terrain-skimming altitude through near orbit. `Strike Wing '94` is retained only as a legacy/internal development alias and repository identifier.

## Current status

Playable 30-mission, three-sector campaign plus six secret sorties on `main`.

Implemented now:

- approved EVAVO publisher splash with canonical plate/sparkle assets, black transition, and skippable HYPERSONIC title sequence
- deterministic save-isolated arcade attract reel with VX-94 transformation, hypersonic pursuit, weapons and Machine Ark showcase
- 640×360 logical canvas with nearest-neighbour presentation to 1280×720
- governed sprite-built title, briefing, debrief, options, pause and combat HUD presentation
- production VX-94 fighter / bomber sprite animation with a mechanical wing-sweep transition, held key poses and separate banking cels
- fighter wing-root cannon posture and bomber-deployed nose rotary cannon
- form-aware projectile muzzle positions and matching muzzle-flash presentation
- original procedural fighter / bomber rotary / rail / energy / support SFX
- original 12-cue tracker score with three rotating combat identities for each campaign sector
- short weapons interlock during geometry changes
- four altitude bands: low / mid / high / orbital
- authored cinematic altitude transitions plus bounded player-selectable altitude-lane windows
- PageUp/PageDown adjacent-lane choices where the mission allows them
- animated climb/dive cloud sweep, pitch cue, target-scale interpolation and separate climb/dive SFX
- finite afterburner reserve with form/altitude efficiency and Atlas tanker refuel
- mission-intelligence overlay with threat/altitude/form/tech/boss/support information and tactical support advice
- eight primary weapon tiers from conventional cannon through Plasma Lance
- generator capacity/recharge progression and matching-era efficiency
- five persistent airframe tiers with increasing hull/shield capacity and bounded damage resistance
- seven onboard tactical support systems including EMP, Magnetic Screen and Micro-Warhead Rack
- separate allied battlefield support: fighter flight, bomber flight, gunship, tanker, cruise missile, rail and orbital strike
- interactive Atlas tanker hose hookup / rearm / refuel sequence
- dedicated bomber precision-strike ordnance at low/mid altitude
- deterministic authored encounter beats, formations, recovery windows and mastery secrets
- 30 core missions across Mercenary War, Machine War and BLACK SKY, plus six discoverable secret sorties
- arcade assault and authored challenge routes with independent scoring/progression rules
- 38 canonical enemy identities spanning air, ground, naval and orbital warfare, including nine bosses
- boss phase / weak-point behavior and signature attacks
- Needle Rail penetration, Storm Cannon pulse discharge and Plasma Lance field discharge
- bounded strategic Micro-Warhead pre-impact blast
- persistent campaign credits, equipment and serviced airframe state
- versioned v6 local autosave with stable mission identity, validated backup recovery and v1-v5 migration compatibility
- verified layered runtime art for the VX-94, enemies, bosses, projectiles, airframes, support set pieces and cinematic hero cels
- modular, seam-tested coast/refinery environment stacks with animated water, surf, cloud, smoke and weather layers
- campaign launch/ending cinematics, completion aftermath, credits and post-campaign presentation
- persistent subtitles, reduced-shake, reduced-flash and enhanced-projectile-contrast accessibility controls
- mission-wide command radio with sector callsigns, authored briefing/contact/boss calls, transceiver cues and subtitle control
- local PowerShell validation with optional Godot headless test/editor smoke pass

The obsolete player/enemy/projectile polygons have been removed from `main.gd`. Live combat now resolves through governed sprite manifests and dedicated presentation directors; environment seam gates, art-contract tests and real Godot capture passes protect the active production stack.

## Controls

### Flight

- Move: `WASD` or arrow keys
- Primary fire: `Space`
- Afterburner: `Shift`
- Transform fighter / bomber: `Q`
- Optional altitude climb during an authored lane window: `PageUp`
- Optional altitude dive during an authored lane window: `PageDown`
- Emergency screen bomb: `X`
- Bomber precision strike: `E`
- Onboard tactical support: `Z`
- Call selected allied battlefield support: `F`

Controller defaults use Godot's standard Xbox/PlayStation-style mapping:

- Move: left stick
- Primary / confirm: south face button
- Screen bomb / cancel: east face button
- Tactical support: west face button
- Transform: north face button
- Afterburner: left shoulder
- Battlefield support: right shoulder
- Altitude: D-pad up/down
- Cycle tactical/battlefield support: D-pad left/right
- Precision strike ordnance: right-stick click

Keyboard flight bindings can be reassigned from **FLIGHT CONTROLS** on the main menu. The assignment station captures physical keys, swaps conflicts so both actions remain reachable, persists changes in the local options file, preserves controller bindings, and supports restoring the authored defaults with `Backspace`.

### Briefing / loadout

- Launch / continue: `Enter`
- Mission intelligence overlay: `I`
- Buy next primary weapon: `U`
- Buy next generator: `G`
- Buy next VX-94 airframe: `K`
- Cycle unlocked tactical support: `C`
- Buy next tactical support: `V`
- Repair hull to current airframe capacity: `H`
- Recharge shields to current airframe capacity: `J`
- Cycle mission-assigned battlefield support: `B`

### Mission flow

- Retry failed mission: `R`
- Return from active mission: `Esc`

## VX-94 combat roles

### Fighter configuration

- wings sweep back around visible hinge points
- faster movement
- tighter contact and projectile-hit profile
- tighter primary spread
- stronger air-target effectiveness
- stronger afterburner burst and better high/orbital efficiency
- conventional multi-shot guns fire from dedicated wing-root cannon packs
- nose rotary is folded/retracted into the forward fuselage
- wing / under-wing / upper-fuselage hardpoints can support missiles, rockets and later specialist stores
- required for orbital operations

### Bomber configuration

- wings open into a broad, heavier attack posture
- slower and wider, with greater surface-strike risk/reward
- stronger surface / naval damage
- wider weapon coverage
- more efficient tactical-support energy use
- enables dedicated precision strike ordnance
- exposes under-wing hardpoints for bombs, rockets and missiles
- deploys a large multi-barrel nose rotary cannon for conventional ballistic primaries
- nose rotary has its own original low ripping procedural sound and muzzle/spool cue
- preferred at low altitude

The bomber attitude intentionally evokes the brutal functionality of late-90s attack-aircraft design without copying a real A-10 silhouette or using a real GAU-8 recording.

## Altitude lanes

The four ordered lanes are:

1. LOW
2. MID
3. HIGH
4. ORBITAL / ATMOS-SPACE

Some missions open a bounded `ALTITUDE LANE` choice window. While that prompt is visible, `PageUp` or `PageDown` moves exactly one adjacent band. The player cannot freely jump multiple bands or bypass scripted mission choreography.

Major mission transitions remain authored set pieces, including Black Flag's sea-skimming descent and Machine Ark's final orbital burn.

A climb/dive lasts roughly 1.15 seconds visually and includes moving cloud bands, a subtle craft pitch, interpolated surface-target scale and direction-specific procedural audio.

## Technology eras

1. **Advanced conventional** — cannon, rockets, smart missiles, composite/ceramic protection
2. **Electromagnetic** — EMP, magnetic defence, Needle Rail, Magneto-Composite frame
3. **Directed energy** — Storm Cannon, advanced field systems, Field-Coupled frame
4. **Strategic orbital** — Plasma Lance, Micro-Warhead Rack, orbital/strategic support

The playable campaign escalates from the Mercenary War through the autonomous Machine War and completes in the near-Earth BLACK SKY campaign. The fiction remains a coherent human/machine military conflict rather than pivoting to generic alien warfare.

## Project layout

- `project.godot` — Godot configuration and focused runtime autoloads
- `scenes/` — game scenes
- `scripts/main.gd` — core playable simulation/orchestration layer
- `scripts/craft_form_director.gd` — VX-94 form, altitude lanes, mounts, afterburner and mission context
- `scripts/altitude_transition_director.gd` — climb/dive and altitude-lane presentation
- `scripts/weapon_mount_cue_director.gd` — mount-aware fighter / bomber firing feedback
- `scripts/retro_sfx_director.gd` — procedural original 90s-style SFX
- `scripts/airframe_director.gd` — persistent structural frame progression
- `scripts/encounter_director.gd` — authored mission beat sequencing
- `scripts/support_director.gd` — onboard tactical systems
- `scripts/battlefield_support_director.gd` — allied battlefield support and Atlas tanker
- `scripts/strike_ordnance_director.gd` — bomber precision-strike ordnance
- `scripts/directed_energy_director.gd` — Storm / Plasma secondary field behavior
- `scripts/strategic_warhead_director.gd` — bounded Micro-Warhead blast behavior/presentation
- `scripts/combat_art_director.gd` — governed layered combat-sprite presentation and animation selection
- `scripts/environment_director.gd` — modular terrain, water, cloud, weather and altitude presentation
- `scripts/campaign_cinematic_director.gd` — launch, escalation and ending cinematic sequencing
- `scripts/game_mode_director.gd` — arcade/challenge route ownership and score progression
- `scripts/settings_director.gd` — persistent video, audio, control, accessibility and difficulty settings
- `scripts/pixel_ui_director.gd` — primary bitmap UI/HUD
- `scripts/mission_intel_director.gd` — toggleable pre-mission tactical intelligence
- `scripts/campaign_save.gd` — versioned campaign autosave/restore
- `data/` — weapons, generators, airframes, 30 core missions, secret sorties, modes, enemies, cinematics, environment profiles and campaign context
- `docs/90S_SHOOTER_BIBLE.md` — 90s shooter quality/style rules
- `docs/CRAFT_ALTITUDE_SYSTEM.md` — authoritative transform / mounts / altitude-lane contract
- `docs/CAMPAIGN_CANON.md` — campaign/world canon
- `docs/STRATEGIC_ORBITAL_ENDGAME.md` — M12 / ORB-era contract
- `docs/VX94_COMBAT_ART_DIRECTION.md` — production combat-art direction
- `docs/ARCHITECTURE.md` — runtime ownership and invariants
- `tools/validate.ps1` — zero-cost local structural + optional Godot validation

## Validate locally

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\validate.ps1
```

If Godot is not on `PATH`, set `GODOT_BIN` or pass `-GodotBin`. Structural/data/save/content checks still run without the engine executable; when Godot 4.6.2 is found, the script also runs the focused headless self-tests and editor parser smoke test.

## Export for Windows

Install the export templates matching the Godot editor version, then run:

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\export_windows.ps1
.\tools\verify_windows_export.ps1
```

The canonical `Windows Desktop` preset produces a single embedded-PCK executable at `build/windows/HYPERSONIC.exe`. Source-production art, documentation, tools and local work captures are excluded from the player package. The export and verification scripts refuse paths outside the repository's ignored `build` directory. Verification checks Windows identity metadata and launches the packaged game through a deterministic headless front-door smoke test.

## Direction

The target is an original, pixel-perfect 90s PC shooter with the depth and authored discipline of the best era references without copying their proprietary content.

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
- desktop-first
- later controller/web/mobile support where appropriate
- no dependency on paid GitHub Actions or Vercel services
- local validation and automation are first-class

Copyright (c) EVAVO Studio.
