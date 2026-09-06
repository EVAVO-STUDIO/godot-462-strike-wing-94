# Forward flight integration

W/Up and S/Down now command throttle during a sortie; T/G remain available. A/D steer laterally. Menus retain their directional navigation. Commanded power and actual speed remain separate, with the existing acceleration, afterburner and Mach recovery response.

The aircraft advances without a longitudinal screen boundary. Its route coordinate is unbounded; the camera follows that coordinate with a smooth speed-dependent look-ahead. Terrain uses camera distance, while encounters and arrival gates use aircraft distance. Existing contact closure already includes forward speed, so retained projectiles, contacts, combat effects and strike markers receive only the additional camera projection adjustment. Airborne closure now also decreases below cruise. Lateral edge limits and collision separation remain.

Camera settling is bounded so deceleration cannot scroll terrain backward. Terrain layers retain authored parallax; route coordinates are cruise-seconds, not calibrated metres or a physical airspeed claim. The gameplay camera keeps the airframe between y=234 and approximately 277 across the existing power range, preserving instrument clearance.

## Evidence

Pinned Godot 4.6.2: runtime and hypersonic self-tests pass. `flight_camera_self_test.gd` checks real input commands, duplicate-binding saturation, camera response, contact/projectile projection, unbounded travel and monotonic camera travel under hard deceleration. It requires capture mode to isolate saves and is registered in validate.ps1.

Native fixture: `work/campaign_design_v3/capture_forward_flight.gd`; accepted evidence: `work/campaign_design_v3/native_forward_flight_v2/`. 120 frames cover minimum power, acceleration, afterburner/Mach travel and deceleration. Actual speed reached 0.62, 1.36 and 4.4, then returned to 0.62. Camera distance advanced throughout with zero backward samples. Selected frames 23, 71 and 95 were visually inspected for airframe/HUD clearance, cloud and terrain motion context, and boss presentation.

The first capture is retained separately: it revealed a backward settling step, fixed by bounding camera adjustment, and lost simulated input when native focus changed. The accepted fixture holds its staged input every frame. Capture invulnerability is explicit: this is presentation and motion evidence, not a survival/balance acceptance run. Full release gates and eight-sortie telemetry remain outstanding for the combined production changes.
