# Retained mountain terrain v3

Three runtime chunks replace the pasted 48-row connector with road terminations and shared rocky terrain. The switchback pass and ice corridor each receive one northern tunnel and one southern covered approach; radar valley receives two of each. Every original central region x0–639/y104–923 is unchanged (1,574,400 pixels total). The radar pad and its runtime registration remain intact.

Inputs are immutable prepared source layers with origin paths and SHA-256 values in the manifest. Northern and southern generation prompts are retained. Built-in generation supplied candidate tunnel/rock material; EVAVO Art Studio registered it, applied an authored portal silhouette and assembled the retained layers. Concrete texture comes from the existing radar pad. No terrain is enlarged. The seam repeats one natural rock scanline to satisfy the existing exact boundary contract, without restoring the old broad pasted strip.

`tools/build_mountain_repair_v3.mjs` verifies every input hash, compiles/runs the Art Studio request in a fresh work directory, then verifies all three output hashes before writing runtime files. The existing mountain builder calls it while retaining the weather generation pipeline.

Nine addressed views of this exact candidate were individually reviewed on pinned Godot 4.6.2 in the isolated art checkout. Earlier F had 216 complete native moving frames; those support the preceding shared-terrain layout, not exact I-pixel certification. Failed opaque masks and the jagged ridge candidate were rejected and retained in work.

Main verification: the source-bound rebuild reproduced all three expected PNG hashes; full test_environment_seams.ps1 passed; pinned 4.6.2 import and nine-view capture completed without engine errors. Main offset-950 views for all three chunks were individually inspected.

Final runtime review uses the later production cloud and weather stack. Pinned Godot 4.6.2 captures at mission times 24, 74, and 118 cover low, mid, and high altitude over the switchback pass, ice-cliff corridor, and radar installation. Snow remains legible without obscuring roads, terrain transitions do not expose the retired connector bands, and altitude haze preserves target and route readability. Exact capture hashes and observations are retained in `runtime_final_review.json`; this closes the former transition/weather review item for the mountain family.
