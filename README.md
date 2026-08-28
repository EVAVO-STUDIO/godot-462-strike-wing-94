# Strike Wing '94

Original 90s DOS-style vertical scrolling combat shooter built in Godot 4.6.2.

## Current status

Playable foundation on `main`.

Implemented now:

- 640×360 nearest-neighbour game canvas
- keyboard movement
- twin primary fire
- limited screen-clearing secondary bombs
- enemy spawning and wave escalation
- enemy movement patterns
- projectile/enemy collision
- shield-before-hull damage model
- scoring and run reset behavior
- code-drawn placeholder battlefield/HUD for gameplay iteration
- data-driven initial weapon catalogue
- data-driven initial mission catalogue
- local PowerShell validation with optional Godot headless smoke test

The temporary code-drawn art is deliberately disposable. Production pixel art can replace it without redefining the underlying combat rules.

## Controls

- Move: `WASD` or arrow keys
- Primary fire: `Space`
- Secondary bomb: `X`

## Project layout

- `project.godot` — Godot project configuration
- `scenes/` — game scenes
- `scripts/` — runtime gameplay code
- `data/weapons.json` — weapon definitions/economy seed data
- `data/missions.json` — campaign mission seed data
- `docs/GAME_DESIGN.md` — design pillars, architecture and roadmap
- `tools/validate.ps1` — zero-cost local validation

## Validate locally

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\validate.ps1
```

If Godot is not on `PATH`, set `GODOT_BIN` or pass `-GodotBin` to the script. Structural and JSON checks still run when no engine executable is found.

## Direction

The target is an original 1993–1996-style PC shooter with air and ground targets, campaign briefings, repair/shop progression, distinct weapons, large bosses, readable enemy patterns and strong authored pixel presentation.

Reference games may inform pacing and genre grammar only. Do not copy proprietary names, maps, sprites, UI, sounds or encounter content.

## Infrastructure

- Godot 4.6.2
- GDScript-first gameplay foundation
- desktop-first
- later controller/web/mobile support where appropriate
- no dependency on paid GitHub Actions or Vercel services
- local validation and automation are first-class

Copyright (c) EVAVO Studio.
