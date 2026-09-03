# Hypersonic Mission Loop

Hypersonic flight is HYPERSONIC's strategic rhythm, not a disposable boost pickup.

## Core sortie shape

1. **Ingress:** launch or enter at high altitude, sweep the VX-94 into fighter geometry, commit afterburner, cross the sonic threshold and outrun the outer defence net.
2. **Break:** cancel hypersonic flight before the target area, trade speed for steering authority, and descend through the threat layers.
3. **Work:** deploy bomber geometry at low/mid altitude for bombing, interdiction, rescue cover, reconnaissance or precision destruction.
4. **Response:** completing or exposing the objective raises an interception clock. Hypersonic-capable enemy pairs enter from behind or the flanks and try to deny the climb corridor.
5. **Egress:** retract strike geometry, climb through the defended envelope, recommit to hypersonic flight and hold the escape corridor until extraction.

## Player contract

- `T` / `G` (or right-stick vertical) sets a persistent dry-power throttle. Minimum power still advances the route; military power accelerates geography and the closure of terrain-fixed contacts without turning local up/down movement into a fake speed control.
- Afterburner accelerates the same integrated world coordinate immediately, before the Mach latch. It is propulsion, not only a steering multiplier or a screen effect.
- Hold afterburner in fighter geometry to charge the Mach transition; releasing breaks the state.
- Entry reaches 4.4 times cruise world velocity over a decisive 0.12-second pressure break. Releasing afterburner begins a bounded 0.62-second Mach-recovery window: forward speed, contrail exposure and steering authority return progressively while every environment layer continues from the same integrated world coordinate. No layer may derive position from `mission_time * current_speed`, because that teleports geography when the speed state changes.
- High/orbital altitude is efficient and structurally safe. Mid altitude inflicts accumulating stress. Low altitude combines Mach overload with rapidly rising dynamic-pressure damage and can destroy a healthy airframe during a prolonged terrain-level run.
- Ground/sea targets and recovery pods are fixed to the moving world and close proportionally with forward power. Aircraft preserve more independent velocity, so interceptors can pursue instead of being dragged down-screen like scenery.
- Entry creates one unmistakable sonic boom and pressure ring. Sustained flight increases world-scroll speed and reduces local steering authority.
- Weapons remain available for pursuit encounters, but accuracy and positioning become difficult through the compressed control envelope.
- Bomber geometry cannot charge hypersonic flight. The player must make the transformation decision before ingress or escape.

## Enemy pursuit contract

Only explicitly tagged interceptors can cross the threshold: Ace Interceptor, Drone Hunter and Phase Interceptor. Pursuit groups enter as authored pairs, telegraph their wing sweep/engine flare, create smaller boom rings, and attack in high-speed slashing passes rather than sitting in ordinary formations.

## Mission-authoring rule

Hypersonic ingress/egress should frame selected sorties, not every mission. A mission using it must provide a readable safe high corridor, a meaningful reason to descend, a response escalation after objective exposure, and an extraction condition that tests commitment without forcing unavoidable low-altitude hull loss.
