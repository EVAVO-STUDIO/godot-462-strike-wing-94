# Destruction presentation — reviewed continuity direction

Status: presentation preview reviewed; gameplay renderer integration remains required after the art/design pass. No production code or explosion PNGs changed for this review.

Native Godot 4.6.2 addressed-frame fixtures exercised actual CombatFxDirector destruction drawing for light_tank, river_patrol and machine_ark over the existing coast scene. Durations used the production events: 0.92, 1.35 and 3.0 seconds respectively. Baseline and revised previews each retain 73 frames at 24 addressed frames/second. Fixture frames are not natural kills or performance measurements.

Finding: the initial Ark blast advances through its eight frames before the retained wreck starts at 32% of the three-second event (0.96 seconds). At 0.75 seconds the large craft is effectively absent, then its hull appears around one second. Earlier actual mission-29 combat footage independently corroborates the disappearance/return: elapsed 21.88 seconds (frame_0105) and 22.30 seconds (frame_0107) after the Ark reached zero HP at 21.03 seconds. Those are relative capture times, not death-event times.

Reviewed direction: retain the current wreck's initial pose beneath the blast from event start until the existing breakup begins. Then hand off to the existing drift, secondary explosions and fade without restarting them. The preview calls the existing orbital breakup drawer at ratio zero for the initial 0.96 seconds before drawing the normal explosion. This preserves the current artwork and event length, while preventing disappearance/reappearance. The paired 0.75-second images show the effect.

Required later integration: apply a continuous hull handoff to the relevant retained boss/vehicle families, maintain the original event lifetimes, render hull behind blast, and avoid duplicate hull rendering at the handoff. Verify all nine bosses plus representative ground/naval/air destruction in native sequences and natural kills. This Ark-only preview does not prove all-family acceptance.

Core impact/explosion art is retained: inspected bomb, water, dust, eight-stage explosion, damage smoke/fire and debris sheets. They already have clear material identity. A local Particle Studio military ground-burst probe was rendered and reviewed; its subdued smoke may be useful later, but it does not justify replacing the brighter existing hit flashes.
