# High-altitude cloud companions

Three 320x160 finished masters replace high_mass_b/c/d: swept anvil, broken cumulus pair and irregular front. They complement the separate cloud_volume_v3 high_mass_a master. Existing production travel, wind, shadow and altitude behavior are unchanged.

Built-in image generation produced a source sheet, then corrected the rejected side-on projection toward overhead volumes. The final prompt, immutable source, recovered alpha and recovery evidence are retained. Art Studio recovered the actual magenta matte (#eb12ea), separated rows exactly, downsampled without enlargement, and added transparent padding. An initial contain-resize added opaque padding and was rejected. The corrected files have meaningful alpha and transparent margins.

Default matte-colour QA incorrectly flags some legitimate ivory cloud highlights. Source-bound expectations test actual magentas and green contamination at the unchanged 0.015 halo limit. All three pass. All six-background proofs were inspected; no recovery threshold was widened. The explicit expectations and proof/evidence files are retained.

Main's pinned Godot 4.6.2 import and 72-frame production-renderer capture completed. Frames 12,36,60,71 were individually inspected with firing and throttle/afterburner input. This is coastal high-altitude evidence, not all-weather/all-altitude or full loop acceptance. Low/mid clouds and rain/snow remain open. The canonical finished masters are delivered by tools/build_cloud_family_v3.mjs, which checks all hashes before writes; it does not claim deterministic regeneration of the generative source.
