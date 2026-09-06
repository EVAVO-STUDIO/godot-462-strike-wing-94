# Route timing integration

Ordinary mission expiry now follows travelled route distance, matching authored encounter and altitude gates. Wave escalation follows the same distance, so slowing down no longer increases wave difficulty merely by extending elapsed time. Real elapsed time remains available for cooldowns and survival objectives. Boss overtime still expires after 45 real seconds once the route is exhausted with a required boss alive; hypersonic egress retains its separate countdown.

Command gates now follow the last non-secret authored beat by at least eight cruise-distance units. Route length retains nominal duration unless a late command approach needs extension, in which case it leaves at least 24 distance units beyond that gate. Secret beats do not delay ordinary completion. These are initial spacing values; high-speed recognition and natural boss pacing still require integrated flight testing.

The HUD displays ETA from remaining route distance and current speed, OT during boss overtime, and the existing clock for egress. It no longer presents a fixed elapsed-time countdown as though slower flight were disallowed.

Pinned Godot 4.6.2 verification: `route_timing_self_test.gd` passes 36 slow approaches beyond the former elapsed deadline, 36 boss-gate boundaries and 36 overtime boundaries. It uses actual main-scene update/spawn logic, isolated capture saves and invulnerability; it is not a completed-sortie balance test. The test is registered in `tools/validate.ps1`. Existing runtime, mission-flow, hypersonic and encounter self-tests also pass.

A native 60-frame Coastal Intercept fixture begins at elapsed 151 seconds and minimum-power route progress. It remains in gameplay with a positive, decreasing ETA; frames 0, 30 and 59 were inspected. Native files and logs are under `work/campaign_design_v3`. The fixture intentionally starts beyond the old deadline and does not establish natural mission duration or combat survival.

Still required: camera-followed forward flight, consistent entity-relative motion, high-speed encounter spacing, damage classification/lethality, full vulnerable sorties and the final Windows release gate. No full release claim follows from these focused checks.
