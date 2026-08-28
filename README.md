# Strike Wing '94

Original 90s DOS-style vertical scrolling combat shooter built in Godot 4.6.2.

## Current status

Playable campaign foundation on `main`.

Implemented now:

- 640×360 nearest-neighbour game canvas
- title / briefing → mission → result flow
- keyboard movement and data-driven primary weapons
- limited screen-clearing secondary bombs
- enemy spawning with environment/wave-specific spawn profiles
- air, ground and sea enemy archetypes
- enemy projectile fire and aimed attack patterns
- shield-before-hull damage model
- pickups for shields, repairs, bombs and weapon upgrades
- mission bosses wired from mission `boss_id` references
- persistent campaign credits and purchasable weapon progression
- versioned local autosave in `user://strike_wing_94_save.json`
- mission objective contracts for survival, named-target destruction and destroy-count bonuses
- reusable objective evaluation rules ready for runtime objective HUD/mission gating
- code-drawn placeholder battlefield/HUD for gameplay iteration
- local PowerShell validation with optional Godot headless smoke test

The temporary code-drawn art is deliberately disposable. Production pixel art can replace it without redefining the underlying combat and campaign rules.

## Controls

- Move: `WASD` or arrow keys
- Primary fire: `Space`
- Secondary bomb: `X`
- Buy next primary weapon from briefing: `U`
- Launch / continue: `Enter`
- Retry failed mission: `R`
- Return from active mission: `Esc`

## Project layout

- `project.godot` — Godot project configuration and `CampaignSave` autoload
- `scenes/` — game scenes
- `scripts/main.gd` — current playable orchestration layer
- `scripts/content_catalog.gd` — validated JSON loading helper
- `scripts/combat_rules.gd` — damage/wave/combat arithmetic
- `scripts/projectile_rules.gd` — projectile and enemy-fire rules
- `scripts/progression_rules.gd` — weapon purchases and mission rewards
- `scripts/objective_rules.gd` — objective progress/completion/bonus evaluation
- `scripts/campaign_save.gd` — versioned local campaign autosave/restore
- `data/weapons.json` — weapon definitions and costs
- `data/enemies.json` — enemy and boss archetypes
- `data/missions.json` — missions, briefings, bosses and objective contracts
- `data/spawn_profiles.json` — environment/wave encounter composition
- `data/campaign.json` — campaign ordering, economy and save configuration
- `docs/GAME_DESIGN.md` — game-design direction
- `docs/ARCHITECTURE.md` — system boundaries and refactor direction
- `docs/QA.md` — regression and integrity checklist
- `tools/validate.ps1` — zero-cost local validation

## Validate locally

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\validate.ps1
```

If Godot is not on `PATH`, set `GODOT_BIN` or pass `-GodotBin`. Structural, JSON, cross-reference, objective and save configuration checks still run without the engine executable.

## Direction

The target is an original 1993–1996-style PC shooter with authored missions, air/ground/sea combat, repair/shop progression, distinct weapons, large bosses, readable enemy patterns and strong pixel presentation.

Reference games may inform pacing and genre grammar only. Do not copy proprietary names, maps, sprites, UI, sounds or encounter content.

## Infrastructure

- Godot 4.6.2
- GDScript-first gameplay foundation
- desktop-first
- later controller/web/mobile support where appropriate
- no dependency on paid GitHub Actions or Vercel services
- local validation and automation are first-class

Copyright (c) EVAVO Studio.
