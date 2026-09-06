# Large cloud volume — reviewed art candidate

One original 320x160 cloud bank, built from a generated large source referencing the existing cloud style. Retains blue-slate shadow volume, ivory highlights, irregular wisps and internal holes. Final cloud art and six-background proof were inspected; no runtime texture or renderer was replaced.

## Production path

Two direct local Blender source studies were rejected for smooth, solid silhouettes. A built-in image-generation draft returned painted checkerboard RGB and was rejected for transparency. A second built-in edit requested flat magenta; immutable returned source is retained here. Art Studio recovered the declared matte and suppressed chroma spill. Hidden RGB was cleared through a source-bound sandbox operation at alpha threshold zero, with exact visible-pixel and alpha preservation verified. Art Studio downsampled to 320x160 without enlargement.

The default quality matte list also includes legitimate cloud highlight/shadow colours. Final expectations bind the actual magenta source colours plus green spill detection; the halo fraction limit remains 0.015. No threshold was increased. Native-alpha mastering uses bleed radius zero, retaining canonical hidden RGB. Final quality passes. The intermediate two-/four-pixel defringe experiments are NOT the final source: the accepted candidate preserves the original downsampled cloud shading. The proof, exact expectations and quality evidence are included.

## Native moving review

96 captures in pinned Godot 4.6.2 over actual coastal gameplay. Scratch overlay reads the scene's accumulated route distance; actual throttle-down/up/down input changes existing world-speed values. Reviewed frames 48 and 72. Cloud drift is travel-dependent, with separate lateral wind, and the sampled aircraft/target cues remain legible. This is one bank and one route/altitude review, not all-weather, all-altitude acceptance. The review movie uses manifest mission-time deltas rather than assuming every capture interval was identical.

The production game still needs the requested camera/forward-flight revision, higher-lethality damage design, full rain/snow integration, additional cloud-family coverage and moving combat review. No afterburner, hypersonic, mountain, secret-sortie or orbital acceptance is implied by this fixture. Existing cloud sources remain intact.

## Final built-in edit prompt

Precise background edit of this cloud asset. Preserve the cloud's shape, detailed blue-grey shadows, bright ivory ridges, internal gaps and scale. Replace the ENTIRE painted white/light-grey checkerboard with ONE absolutely flat solid saturated magenta #FF00FF. Every background pixel, all four corners, all outside margins and gaps between cloud wisps must be this exact solid magenta. NO checkerboard, no gradient, no texture in the background, no transparency-preview UI. Do not recolour any cloud material magenta; avoid edge colour spill. Keep the cloud completely within frame with at least a small magenta margin on every side. This is a chroma-matte production source for deterministic alpha recovery, so the perfectly flat magenta background is mandatory. Do not add anything else.

The earlier generation prompt requested a unique irregular storm bank in the retained sheet's detailed cold overcast style, one wide 2:1 asset with native alpha, internal gaps, slate shadows, ivory highlights and no scenery. Its checkerboard result was rejected and remains under work/cloud_volume_v3_c, alongside the failed inspection report. No local neural-generation worker is claimed.

## Production integration follow-up

The 320x160 master now replaces runtime cloud_bank_high_mass_a.png in the main working tree. The other eleven cloud identities remain intact. tools/build_cloud_bank_v3.mjs verifies the canonical finished-master hash before installing it; this is delivery from a reviewed finished source, not a claim that the original generative operation is deterministic.

The actual production renderer was reviewed over coast (72 moving frames, inspected 12/36/60/71), mountain and cloud-top captures. Existing throttle and afterburner inputs produced speed multipliers 0.62–4.4; no scratch cloud overlay was used. The environment self-test passed with the existing ObjectDB exit-leak warning. This completes one cloud identity improvement, not full weather, all-altitude acceptance, flight-camera design, lethal damage or release validation.
