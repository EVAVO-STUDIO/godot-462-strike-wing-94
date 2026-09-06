# Open-water detail recovery

Recovered fourteen temporal frames from the existing detailed sea_deep_tile, sea_surface_tile and sea_foam_tile sources through EVAVO Art Studio exact image-composite operations. Phase offsets are unchanged. All visible source pixels are retained exactly after wrapped offsets, except the intended final-row replacement; first/last rows match for every output. The independent NumPy/Pillow check only reads/compares pixels and does not generate the assets.

Root cause: build_open_water_art.ps1 used ImageMagick Src composition with default outside-overlay behavior when pasting a one-pixel seam row. The output became vertically extended row colours across the plate. The corrected builder limits Src to its overlay region. A direct deep_0 comparison against the Art Studio result has AE=0. Source sea tiles and finite buoy/debris art remain intact.

Native Godot 4.6.2 mission-2 capture at 48 seconds compared before/after. The recovered layers visibly restore waves beneath rain, ordnance and finite debris. All fourteen recovered PNGs are promoted to the main working tree. This repair restores prior source detail; it does not constitute acceptance of every weather/altitude transition or full open-water animation timing.

The broad environment seam gate was launched after promotion; its final result is in work/environment_review_v2/seam_tests.log. Canonical request, Art Studio receipt and fourteen-frame pixel verification are retained here.

Final seam-gate result: process exited 0. Existing complete environment seam suite passed after the water recovery.
