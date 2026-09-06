# VX-94 pitch relief art candidate

Retained fighter and bomber painting mapped onto original shallow Blender relief meshes. Seven angles per form: -18/-12/-6/0/+6/+12/+18 degrees. Positive pitch raises the nose. This is an art study, not a full aircraft model or production flight integration.

Blender 5.2.1 LTS, orthographic camera, packed original textures, point-sampled Cycles rendering; Art Studio exact nearest export and hidden-RGB cleanup; Sprite Studio strict packing. Fourteen frames, twelve distinct: the +6-degree frame is identical to neutral for each form at native size. Do not advertise seven distinct motion exposures.

All fourteen alpha checks pass using the retained source's known mattes, without relaxing halo limits. Cleanup preserves every visible RGBA value and all alpha. All six-background proofs were visually inspected. Neutral render alpha and opaque colour match the original exactly; partially transparent RGB differs by at most 2/255 due to rendering. Preserve original neutral sprites during eventual integration.

Sprite Studio: zero errors/warnings; palette distance .263158; silhouette delta .045510; centroid jump .008950. The earlier antialiased v2 failed palette distance .906; preserved under work/vx94_pitch_relief_v2. Initial v3 alpha checks failed hidden RGB; the exact cleanup and successful checks are retained here. No thresholds were relaxed.

Pinned Godot 4.6.2 produced 52 native-size fixture captures. Climb/dive extremes and neutral were reviewed. These are presentation fixtures, not gameplay or aerodynamic evidence. Selected captures are retained here; full sequence is under work/vx94_pitch_relief_v3/native_review.

Open: bank-plus-pitch combinations, mounted hardware and damage registration, stronger pitch readability if live flight needs it, pose timing driven by actual aircraft state. No production flight, scrolling, damage, economy or campaign changes in this package.

The earlier generated climb image changed tail topology and softened detail; it was rejected. Sources remain under work/vx94_pitch_v1. The retained-art relief approach preserves identity more closely.

## Runtime loadout integration

The fourteen reviewed climb/dive airframes now ship as 224 weapon-mounted composites covering both forms, seven pitch states, four primary families and four hardware states. Separated under-airframe and aperture layers preserve the real pitch silhouette. Live Godot capture verifies fighter climb and bomber dive with Storm Cannon firing, external stores, damage, cloud sweep and altitude cues; the registered neutral store/module/damage layers remain visible throughout.
