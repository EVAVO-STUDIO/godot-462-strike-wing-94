# HYPERSONIC Vulnerable Balance Evidence

Status: release-tranche evidence contract  
Owner: `tools/run_vulnerable_balance_telemetry.ps1`  
Output: ignored `work/vulnerable_balance/summary.json`

## Purpose

The existing bounded autoplay matrix deliberately uses invulnerability because its job is to prove system reachability and integration. That is useful release evidence, but it cannot reveal whether ordinary hostile fire, missile pressure, recovery cadence or difficulty scaling can actually destroy the player.

The vulnerable balance matrix is a separate source-runtime evidence lane. It deliberately **does not** pass `--capture-invulnerable`.

It answers narrower questions:

- does the real player-damage path remain active on every sampled difficulty;
- how much damage does the deterministic pilot absorb per game minute;
- which damage source dominates a pressure window;
- does a bounded pilot survive the requested window or end early;
- how do hit rate, destruction rate and score rate move under live pressure;
- are missile/countermeasure systems active during vulnerable play;
- does combat density remain within the intended readable envelope;
- do representative bomber, high-altitude, machine-war and orbital windows still exercise real combat while vulnerable.

It does **not** certify difficulty, fun, fairness, campaign affordability or a release candidate.

## Governed matrix

The current matrix contains:

1. Mission 1 / Cadet / mid fighter
2. Mission 1 / Combat / mid fighter
3. Mission 1 / Veteran / mid fighter
4. Mission 1 / Ace / mid fighter
5. Mission 2 / Combat / low bomber
6. Mission 9 / Combat / high fighter
7. Mission 12 / Combat / machine-war pressure
8. Mission 26 / Combat / orbital fighter
9. Mission 30 / Combat / synthetic late-command pressure window

Mission 1 is repeated across all four campaign difficulty profiles so pressure can be compared against an otherwise stable authored scenario. The remaining cases sample major role/era transitions.

The final-command case deliberately uses a synthetic elapsed-time start to inspect late-sortie pressure. It is not evidence that a fresh player can reach that state with the same hull, shield, ammunition or economy.

## Run locally

```powershell
Set-Location C:\GitRepos\godot-462-strike-wing-94
.\tools\run_vulnerable_balance_telemetry.ps1
```

The runner resolves the same governed Godot 4.6.2 release executable used by the Windows release gate.

Evidence stays under ignored `work/` and therefore does not dirty or enlarge the player source tree.

## Recorded fields

Each case records:

- exact mission identity;
- requested difficulty, form and altitude;
- whether the case was vulnerable;
- requested and elapsed game seconds;
- survival ratio;
- whether the full window completed;
- ending phase;
- damage taken and damage per minute;
- dominant and complete damage-source breakdown;
- shots, hits and accuracy;
- targets destroyed and kills per minute;
- score earned and score per minute;
- hostile missiles launched;
- countermeasure decoys and charges spent;
- maximum enemy and hostile-projectile density;
- accepted tactical, battlefield-support and ordnance uses.

The summary additionally records exact Git HEAD and Godot version, and explicitly records `invulnerability: false`.

## Interpretation rules

### Never auto-tune from one deterministic pilot

A deterministic pilot is intentionally repeatable, not representative of a good human player. It can repeatedly enter the same bad lane, waste a support system, miss an obvious threat or accidentally discover a strong pattern.

Therefore:

- an early ending is a **review signal**, not proof that a mission is too hard;
- a full Ace window is not proof that Ace is too easy;
- lower damage on a harder difficulty is not automatically a defect;
- weak accuracy is not automatically a weapon-balance defect;
- high score rate may come from the bot's route or target selection rather than player-facing economy balance.

### Changes require corroboration

Before changing authored balance, corroborate the signal with at least one of:

- a vulnerable human keyboard journey;
- a vulnerable controller journey;
- repeatable evidence from a second bounded pilot/profile;
- mission-specific runtime evidence showing an unavoidable or invalid interaction;
- economy traces from actual completed sorties;
- direct inspection proving a difficulty multiplier or reward rule is misapplied.

### Keep difficulty honest

Difficulty should primarily change pressure, timing, recovery and elite composition. It should not silently grant enemies impossible information, invalidate telegraphs, make required targets unreachable or create a campaign economy wall.

The current authored profiles already vary spawn/fire cadence, projectile speed, elite frequency, warning time, pickup rate and rewards. Human review must determine whether those differences feel fair.

## Human balance evidence still required

The exact-SHA human signoff must cover at least:

- Cadet onboarding and recovery generosity;
- Combat as the authored default campaign experience;
- Ace warning readability under dense pressure;
- early upgrade affordability;
- repair and shield-recharge costs after imperfect victories;
- bomber route risk/reward;
- high-altitude fighter risk/reward;
- usefulness of tactical and battlefield support;
- whether later energy weapons trivialize earlier systems;
- final-sector attrition and boss duration;
- whether any purchase order becomes obviously mandatory;
- whether a player can recover economically after a bad but successful sortie.

## Test Lab handoff

Godot Game Test Lab is the preferred native evidence runner because it can retain exact replay traces, screenshots, video and synchronized audio while driving keyboard, mouse, semantic actions and synthetic gamepads.

The source-only vulnerable matrix should be run first. Then use Test Lab on the same exact SHA for native journeys that exercise:

1. new-player keyboard onboarding into Mission 1;
2. controller front door, sortie bay and Mission 1;
3. bomber transformation and low-altitude strike loop;
4. missile warning -> countermeasure -> recovery;
5. pause/options/rebind/accessibility flow during a live campaign;
6. a late-machine or orbital mission with real vulnerability;
7. repeated post-sortie repair/purchase decisions;
8. representative boss pressure with audio/video capture.

Native Lab evidence remains diagnostic until a human reviews the captured journey and completes the exact-SHA release signoff.

## Release boundary

`tools/validate_windows_release.ps1` runs this matrix by default. `-SkipVulnerableBalance` is diagnosis-only. A run that skips vulnerable balance evidence cannot issue the exact-SHA packaged release receipt.

The final candidate gate still requires human signoff. Vulnerable autoplay evidence cannot satisfy that authority by itself.
