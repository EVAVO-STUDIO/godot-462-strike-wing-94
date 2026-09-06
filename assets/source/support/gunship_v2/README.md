# Spectre gunship artwork — integrated revision F

`.gdignore` keeps these offline Blender/source candidates out of Godot's runtime import scan. External Art Studio and Blender source rebuilds can still read them. Do not remove this boundary merely to expose an unintegrated candidate to the editor.

Original Blender revision F: forward three-barrel battery remains visible ahead of the wing. Four transparent exposures have passed exact-size/edge checks and Sprite Studio strict QA without corrections. Native 4.6.2 fixture reviewed, including visible weapons and the current emitter mismatch.

Revision F is the runtime replacement. `BattlefieldSupportDirector` now emits from the three projected centre offsets in `muzzle_design.json`: approximately (-19.64,13.05), (-15.37,13.05), and (-11.1,13.05). Tracer and impact exposures are staggered across the battery so the three visible guns read independently. Native firing evidence is retained under `work/support_art_v2/spectre_runtime_f`.

The Blender generator retains original camera/material geometry and emission cadence. EVAVO Art Studio final-size masters and receipts remain in `work/support_art_v2/native_f`; source render masters here allow regeneration. Focused runtime QA covers the firing set piece; natural campaign support balance remains part of the later gameplay telemetry pass.
