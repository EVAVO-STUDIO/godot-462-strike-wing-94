# Re-entry FX v3

Replaces the four end_action overlays only. Removes the screen-fixed white bow arc and long straight orange/cream trails that detached from the panning VX-94. Retains the strong existing re-entry atmosphere plate and bomber cels, with six small heated fragments in the lower atmospheric column. Four authored SVG exposures, 640x272, 3 fps. No gameplay, narrative, camera or audio change.

EVAVO Art Studio rasterized each immutable SVG. All four actual cinematic exposures were inspected in native Godot 4.6.2 in the isolated review checkout. The other ending shots remain intact. `tools/build_reentry_fx_v3.mjs` verifies source and output hashes before writing; the existing ending builder invokes it for this family.

Sprite Studio strict packing/registration checks pass with a particle-specific contract. Translating tiny fragments can have disjoint masks, so max_silhouette_delta is 1.0; area variance is tightened to 0.05 and centroid jump to 0.04, with exact four-frame count, fixed pivot/canvas and 3 fps preserved. The initial rigid-silhouette default failed as expected and is retained in work; it is not claimed as a pass. This contract does not apply to aircraft or other stable-body sprites.

After promotion, main's pinned 4.6.2 import completed without engine errors, the campaign cinematic self-test passed, and a fresh main native ending capture was inspected. The self-test still emits the previously observed ObjectDB exit-leak warning. All four Art Studio transparency checks passed and their six-background proofs were inspected. Native review proves this art presentation, not natural campaign triggers, final soundtrack, or the full release gate. All broader requirements remain subject to final validation.
