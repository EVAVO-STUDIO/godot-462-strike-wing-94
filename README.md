# Strike Wing '94

Original 90s PC-style vertical scrolling combat shooter built in Godot 4.6.2.

Strike Wing '94 is now centered on the **VX-94 Strike Wing**, a 1999 imagined-future variable-geometry strike craft that can shift between a narrow fighter configuration and a wide bomber/attack configuration while operating from terrain-skimming altitude through near orbit.

## Current status

Playable 12-mission campaign foundation on `main`.

Implemented now:

- 640×360 logical canvas with nearest-neighbour presentation to 1280×720
- bitmap/pixel title, briefing, result and combat HUD
- VX-94 fighter / bomber transformation with visible wing sweep
- short weapons interlock during geometry changes
- four altitude bands: low / mid / high / orbital
- authored altitude transitions inside missions
- finite afterburner reserve with Atlas tanker refuel
- mission-intelligence overlay with threat/altitude/form/tech/boss/support information
- eight primary weapon tiers from conventional cannon through Plasma Lance
- generator capacity/recharge progression and matching-era efficiency
- five persistent airframe tiers with increasing hull/shield capacity and bounded damage resistance
- seven onboard tactical support systems including EMP, Magnetic Screen and Micro-Warhead Rack
- separate allied battlefield support: fighter flight, bomber flight, gunship, tanker, cruise missile, rail and orbital strike
- interactive Atlas tanker hose hookup / rearm / refuel sequence
- dedicated bomber precision-strike ordnance at low/mid altitude
- deterministic authored encounter beats, formations, recovery windows and mastery secrets
- 12-mission campaign: mercenary war → autonomous drone war → directed-energy escalation → strategic orbital endgame
- autonomous late-war enemy families and six bespoke AI bosses
- boss phase / weak-point behavior and signature attacks
- Needle Rail penetration, Storm Cannon pulse discharge and Plasma Lance field discharge
- bounded strategic Micro-Warhead pre-impact blast
- persistent campaign credits, equipment and serviced airframe state
- versioned v5 local autosave with validated backup recovery and v1-v4 migration compatibility
- production-oriented integer-grid combat-art overlays for the VX-94, enemies, bosses, projectiles, airframes and support set pieces
- local PowerShell validation with optional Godot headless test/editor smoke pass

The remaining major visual cutover is removing the old prototype player/enemy polygons from `main.gd` after a real Godot visual smoke test confirms the production combat-art layer covers every live target state correctly.

## Controls

### Flight

- Move: `WASD` or arrow keys
- Primary fire: `Space`
- Afterburner: `Shift`
- Transform fighter / bomber: `Q`
- Emergency screen bomb: `X`
- Bomber precision strike: `E`
- Onboard tactical support: `Z`
- Call selected allied battlefield support: `F`

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

- faster movement
- tighter contact and projectile-hit profile
- tighter primary spread
- stronger air-target effectiveness
- stronger afterburner burst
- required for orbital operations

### Bomber configuration

- slower, wider strike posture
- stronger surface / naval damage
- wider weapon coverage
- more efficient tactical-support energy use
- enables dedicated precision strike ordnance
- preferred at low altitude

## Technology eras

1. **Advanced conventional** — cannon, rockets, smart missiles, composite/ceramic protection
2. **Electromagnetic** — EMP, magnetic defence, Needle Rail, Magneto-Composite frame
3. **Directed energy** — Storm Cannon, advanced field systems, Field-Coupled frame
4. **Strategic orbital** — Plasma Lance, Micro-Warhead Rack, orbital/strategic support

The current playable campaign ends the machine war at Mission 12. External/alien contact remains deliberately outside the current campaign so the military/AI conflict gets a complete arc first.

## Project layout

- `project.godot` — Godot configuration and focused runtime autoloads
- `scenes/` — game scenes
- `scripts/main.gd` — core playable simulation/orchestration layer
- `scripts/craft_form_director.gd` — VX-94 form, altitude, afterburner and mission-context owner
- `scripts/airframe_director.gd` — persistent structural frame progression
- `scripts/encounter_director.gd` — authored mission beat sequencing
- `scripts/support_director.gd` — onboard tactical systems
- `scripts/battlefield_support_director.gd` — allied battlefield support and Atlas tanker
- `scripts/strike_ordnance_director.gd` — bomber precision-strike ordnance
- `scripts/directed_energy_director.gd` — Storm / Plasma secondary field behavior
- `scripts/strategic_warhead_director.gd` — bounded Micro-Warhead blast behavior/presentation
- `scripts/combat_art_director.gd` — production combat silhouette presentation
- `scripts/pixel_ui_director.gd` — primary bitmap UI/HUD
- `scripts/mission_intel_director.gd` — toggleable pre-mission tactical intelligence
- `scripts/campaign_save.gd` — versioned campaign autosave/restore
- `data/` — weapons, generators, airframes, enemies, missions, spawn/environment profiles and campaign context
- `docs/90S_SHOOTER_BIBLE.md` — 90s shooter quality/style rules
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

## Direction

The target is an original, pixel-perfect 90s PC shooter with the depth and authored discipline of the best era references without copying their proprietary content.

Reference games can inform pacing, upgrade economy, stage rhythm, readability and genre grammar only. Do not copy proprietary names, maps, sprites, UI, sounds, dialogue, story beats or encounter layouts.

Strike Wing's own identity is:

- believable late-90s imagined-future military hardware
- transforming variable-geometry aerospace combat
- low-altitude bombing through orbital warfare
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
