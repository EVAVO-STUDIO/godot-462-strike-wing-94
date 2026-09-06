# Campaign sortie review

Design direction for integration, not a record of completed balance changes. All 30 canonical campaign IDs and six secret IDs are retained below. The companion audit records current durations, beat gates, secrets, required objectives and source hashes. Apply the route/elapsed-time separation in `PRODUCTION_DESIGN.md` to every ordinary sortie. Actual pressure, earnings and completion still require vulnerable gameplay evidence.

## Mercenary War

| Sortie | Pacing and mastery direction |
| --- | --- |
| m01_coastal_intercept | Teach throttle through actual ground travel before the scout screen; preserve the resupply gap and telegraph the command approach. Introduce missile avoidance before lethal guided pressure. |
| m02_refinery_run | Preview LOW bomber stability before the attack window; let the player slow for rail-column targeting without generic timer failure. Retain maintenance recovery. |
| m03_black_sea | Separate patrol, missile screen and cruiser approach; hint the pursuit-vector secret before its accuracy/target opportunity. |
| m04_breakwater | Make HIGH fighter interception a visible alternative to surface pressure. Explain both branch consequences before selection. |
| m05_furnace_line | Keep surface strike commitment and the hidden-armory opportunity; place a short safe transform/rearm gap before the command train. |
| m06_black_flag | Use the heavier sea front to distinguish the return visit; reserve an escape lane between corvette launches and cruiser fire. |
| s1_m07_desert_lance | Show the chosen Breakwater consequence in the escort/support package. Convey pursuit urgency spatially; any countdown must identify the escaping column. |
| s1_m08_river_hammer | Preserve bridge-route legibility in rain. Separate recovery corridor and cruiser barrage so slowing to line up is a meaningful choice. |
| s1_m09_mountain_eye | Preview the climb through snow and the radar approach. Keep the high-altitude duel legible above the precipitation deck. |
| s1_m10_night_harbor | Preserve blackout target contrast. Place vesper_last_screen deliberately before/within command arrival instead of after an unrelated default gate. |

## Machine War

| Sortie | Pacing and mastery direction |
| --- | --- |
| m07_ghost_sky | Introduce coordinated drones through a readable probe, then the HIGH fighter route and dead-frequency clue; avoid filler masking the new behavior. |
| m08_machine_furnace | Contrast human holdouts with machine defenses using existing identities. Give the forge's vulnerable phase a clear preparation interval. |
| s2_m03_broken_truce | Make allied silhouettes and ceasefire context unambiguous under coastal rain. Explain the factory-versus-bomber branch tradeoff. |
| s2_m04_dead_factory | Keep the silent assembly-line approach. Resolve forge_conveyor relative to command arrival; preserve the ground-suppression consequence. |
| s2_m05_iron_rain | Stage bomber/drone release as identifiable groups. Keep shepherd_ring in the command sequence and preserve the airborne-suppression consequence. |
| s2_m06_ghost_convoy | Apply the selected ground/air escort reduction visibly. Preserve foundry_train_shell and preview the manifest opportunity before the train. |
| s2_m07_red_circuit | Separate field-array warnings from ordinary tracers. Resolve field_array_guard as the last approach/command beat, with EMP preparation time. |
| s2_m08_swarm_sea | Alternate launch pressure and targetable cradles. Preserve ocean_swarm_wall without compressing it into the command spawn; hint bathymetry recovery. |
| s2_m09_silent_city | Retain the evacuated-city setting and distributed-factory identity. Put distributed_forge in an explicit command approach, not beyond a default gate. |
| s2_m10_machine_crown | Use relay layers and existing phase cues to culminate the sector. Preserve black_sky_gate and a readable transition into the upper-atmosphere operation. |

## BLACK SKY

| Sortie | Pacing and mastery direction |
| --- | --- |
| m09_black_horizon | Teach the atmospheric-to-orbital transition and changed contact vocabulary. Exclude local weather in orbital scenery and preserve distant Earth atmosphere. |
| s3_m02_thin_blue_line | Make relay defense and the flight-package transition readable. Resolve blockade_node before the command handoff; allow the announced form/altitude change. |
| m10_blue_fire | Distinguish field-coupled phases with retained weak-point art. Present the rail-platform versus launch-site branch consequences clearly. |
| s3_m04_kinetic_dawn | Give Longshot support a marked target and preparation window. Preserve rail_platform_shell and the later rail-support consequence. |
| s3_m05_orbitfall | Make debris trajectories distinct from missiles and scenery. Preserve orbitfall_control and the launch-site/Atlas recovery consequence. |
| m11_cold_station | Apply the selected support opportunity once. Keep the Warden's construction-stage weak points and a recovery beat before concentrated fire. |
| s3_m07_dead_satellite | Preserve dark-lattice silhouette readability and the intelligence-core opportunity. Resolve lattice_warden as a deliberate command encounter. |
| s3_m08_black_sky | Stage the planetary curtain's existing field/strategic cues. Preserve curtain_anchor and give fleet targeting a clear confirmation. |
| s3_m09_last_horizon | Communicate containment and allied battery alignment. Preserve last_horizon_wall with a survivable recognition gap before final command pressure. |
| m12_machine_ark | Keep the final orbital burn, three-phase escalation and allied support. Validate a real kill, continuous retained wreckage, re-entry and the quiet coastal-watch ending. |

## Secret sorties

| Sortie | Pacing and mastery direction |
| --- | --- |
| sm01_black_wake | Retain the covert ace pursuit and its own encounter/radio context. Give faster closure a readable high-lane interception opportunity. |
| sm02_furnace_vault | Preserve LOW bomber depot/rail identity and limited preparation before demolition pressure; reveal any actual countdown explicitly. |
| sm03_dead_frequency | Retain storm-wall relay hunting and the authored core descent. Fade precipitation with altitude and give enough descent warning to engage the required core. |
| sm04_seed_manifest | Resolve the actual city/evacuation-grid selector. Use its own factory/convoy beats and ground-support opportunities, never Coastal Intercept fallback data. |
| sm05_submerged_cradle | Preserve littoral strike into launch climb. Keep required phase-array access valid through the altitude transition and use maritime rain rather than orbital precipitation. |
| sm06_dead_satellite | Keep the blind-orbit command intercept distinct from the normal dead-satellite sortie. Retain its own guidance objective, contacts and orbital support context. |

## Evidence limits and implementation checks

The current eight-sortie telemetry is eight short invulnerable runs, not eight completed campaigns or boss encounters. Its low hit counts are useful signals for aim/closure review, not sufficient evidence for weapon nerfs or reward changes. Each specific change above must be verified against actual gameplay after flight/camera integration.

Check all six unlock paths, near-miss feedback and replay access. Check every optional lane against required target eligibility. For each branch, verify the saved decision, exactly-once consequence and reconvergence. Use the nine distinct existing boss identities in Boss Rush rather than counting duplicated mission entries. Preserve all mission and secret IDs for save compatibility.
