# HYPERSONIC Release Completion Audit — 2026-09-08

Status: **release candidate / feature freeze**  
Portfolio tranche: `docs/PORTFOLIO_RELEASE_TRANCHE.md`  
Active release target: **Windows Desktop**  
Required engine for candidate evidence: **Godot 4.6.2**

## Executive judgement

HYPERSONIC is no longer blocked by missing campaign architecture. The repository already contains a playable 30-mission three-sector campaign, six secret sorties, campaign endings/credits, persistent progression, mature combat systems, governed runtime art, accessibility, automated campaign-route coverage, performance profiling, broad visual capture, bounded live gameplay telemetry and a packaged Windows smoke test.

The remaining release work is **proof, human judgement, balance closure and candidate identity**, not new feature families.

The correct production behaviour is therefore:

1. keep the feature freeze;
2. run the exact Windows automated gate from clean `main`;
3. fix defects exposed by that evidence;
4. complete a human campaign/controller/visual/audio/balance signoff against one exact SHA;
5. promote the product version from `0.1.0-dev` to an explicit candidate version only when that SHA is intended to become a real external candidate;
6. run `tools/validate_windows_candidate.ps1` with no skipped stages.

## What the repository already proves structurally

### Campaign breadth

- 30 authored core missions across three sectors.
- Six secret sorties.
- Campaign completion, ending cinematic, credits and post-campaign state exist.
- Campaign validation exercises all eight combinations of the controlled branch decisions through real mission-result and advancement code.
- Each deterministic branch route records 27 successful sorties; the combined matrix visits all 30 core missions.

### Persistence

- Current campaign save authority is schema v13.
- Stable mission IDs protect campaign position from index drift.
- Primary and backup saves are validated before restoration.
- Supported older save schemas are migrated through the current authority.
- Campaign completion, difficulties, secret discovery, mode records, branch decisions, intelligence, career statistics, loadout, airframe and support progression are persisted.

### Automated native release stack

`tools/validate_windows_release.ps1` now owns the complete automated Windows evidence chain:

1. resolve one exact Godot 4.6.2 executable;
2. source/data/editor/headless self-test validation;
3. native 1280×720 production-combat performance stress;
4. canonical 640×360 logical visual QA capture matrix;
5. eight-sortie bounded gameplay/system-usage telemetry;
6. canonical embedded-PCK Windows export;
7. packaged executable metadata and startup smoke verification;
8. exact-SHA package receipt when no stage was skipped.

A run with `-SkipPerformance`, `-SkipVisualQa` or `-SkipPlaytestTelemetry` is diagnostic only and deliberately does not issue the exact-SHA release receipt.

### Performance contract

The production stress profile is designed around the active runtime stack rather than an empty synthetic scene. The declared release contract requires at least 60 average FPS and a p95 frame time no worse than 16.67 ms under its governed stress density.

### Presentation evidence

The visual matrix covers front door, title transformation, menus, stores/loadout, options/accessibility, controls, intelligence, secret operations, branch choice, multiple game modes, weather, long-route environments, enemy and surface families, support effects, altitude transitions, fighter/bomber states, bay states, warnings, pause states, debriefs, final boss, ending shots and credits.

This is broad automated presentation evidence, but it remains a **logical 640×360 capture authority**, not human judgement of the displayed 1280×720/desktop experience.

### Gameplay telemetry

The bounded autopilot matrix exercises representative first, bomber-heavy, difficult-air, altitude-choice, machine-reveal, orbital-transition, secret and final sorties. It requires live combat, confirmed hits/destruction, transformation, altitude changes, evasive roll, countermeasures, tactical support, battlefield support, ordnance and readable density limits.

This proves integration and system reachability. It does not prove that the game feels good for a human.

## Release-truth hardening added by this audit

### Exact engine authority

`tools/resolve_release_godot.ps1` now rejects a release audit unless the resolved engine reports Godot 4.6.2. The release wrapper resolves the engine once and passes the same executable to every native stage.

### Exact-SHA packaged-build receipt

`tools/write_windows_release_receipt.ps1` records:

- repository and branch;
- exact HEAD SHA;
- local `origin/main` SHA when available;
- clean-worktree status;
- Godot version;
- executable path, byte size and SHA-256;
- Windows company/product/file metadata;
- product-identity version;
- explicit statement that human campaign/visual/audio review remains separate.

It refuses to issue a receipt from a dirty worktree, non-`main` branch or a HEAD that differs from the locally known `origin/main`.

### Human signoff is now an explicit authority

`docs/RELEASE_SIGNOFF_TEMPLATE.json` defines the human review evidence expected for:

- full campaign completion;
- keyboard journey;
- controller journey;
- onboarding without README/developer help;
- balance/no trivial dominant strategy/no progress wall;
- native 1280×720 presentation;
- 1920×1080 or fullscreen presentation;
- HUD/warning readability;
- reduced-flash/accessibility behaviour;
- audio cue priority and clipping/masking;
- zero unresolved P0/P1 blockers.

The completed review belongs at ignored `work/release_signoff.json`. `tools/verify_human_release_signoff.ps1` rejects stale signoff whose `head_sha` is not the exact current source SHA.

### Final candidate gate

`tools/validate_windows_candidate.ps1` is intentionally stricter than the automated release audit. It:

- rejects a `-dev` product identity;
- requires product identity and Windows export product version to agree;
- runs the complete automated Windows gate with no skip path;
- verifies exact-SHA human signoff;
- verifies the resulting release receipt belongs to the current source SHA and product identity version.

Passing this gate is still not store-publication authority; it is the local technical/human candidate boundary.

## Remaining P0 work

### P0.1 Run the exact automated Windows gate

This audit was performed from repository evidence through the GitHub-connected environment. That environment does not constitute the required Windows Godot execution host.

On the actual Windows production workstation/Test Lab, run:

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\validate_windows_release.ps1
```

Do not use skip switches for candidate evidence.

### P0.2 Complete human end-to-end campaign review

A human must complete the campaign from a clean start on the candidate SHA and record defects affecting:

- mission clarity;
- difficulty spikes;
- grind or upgrade walls;
- dominant weapon/support strategies;
- route/altitude/form readability;
- checkpoint/retry friction;
- boss readability and duration;
- ending/credits return flow;
- save/restore confidence.

At minimum, complete one keyboard campaign journey and representative controller campaign coverage sufficient to prove all gameplay commands and menus remain practical.

### P0.3 Human visual/audio signoff

Review the actual desktop presentation, not only the logical capture files. Check native 1280×720 and 1920×1080/fullscreen output, especially:

- warning priority under heavy effects;
- enemy/projectile/background separation;
- text/HUD legibility;
- weather masking;
- transformation/altitude cues;
- low-health and shield-collapse feedback;
- reduced-flash mode;
- music versus missile/radio/objective cues;
- repeated high-density explosions and boss phases.

### P0.4 Zero P0/P1 defects on the chosen candidate SHA

Human signoff cannot be reused after source changes. Any fix changes the SHA and requires the relevant evidence to be refreshed.

## Remaining P1 work

### Candidate version identity

`data/product_identity.json` currently declares `0.1.0-dev`. Keep that while normal development continues. When a real external candidate is intentionally cut, promote it to an explicit candidate/release version and make `export_presets.cfg` match exactly. The final candidate gate refuses `-dev` by design.

### README/save-version drift

Current save authority is v13 while older README text still describes v12/v1-v11 migration. Update player/developer documentation to v13/v1-v12 and keep structural validation tied to the save authority so this cannot drift again.

### Human difficulty matrix

Automation proves mission reachability, not commercial balance. Human review should cover at least the lowest, default and highest intended campaign difficulty profiles, with special attention to:

- early upgrade affordability;
- repair/recharge economy;
- bomber route reward/risk;
- high-altitude fighter reward/risk;
- support-system usefulness;
- late-game energy weapon dominance;
- final-sector attrition and boss pacing.

## Scope that is explicitly not release work

Do not add during this tranche:

- another campaign sector;
- another aircraft family;
- another major game mode;
- a new meta-progression architecture;
- a renderer rewrite;
- broader world/collision architecture merely because it is interesting;
- new platform targets before the Windows candidate closes.

These are post-release/backlog decisions unless a measured candidate blocker demonstrates that the existing implementation cannot be repaired.

## Candidate command

After human review has produced `work/release_signoff.json` for the exact intended SHA and the product identity has been promoted from `-dev`:

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\validate_windows_candidate.ps1
```

A successful result means the repository has both automated exact-SHA Windows evidence and exact-SHA human signoff under the governed v1 release contract.
