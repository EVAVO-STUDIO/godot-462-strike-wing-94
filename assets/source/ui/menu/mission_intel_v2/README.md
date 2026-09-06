# Mission intelligence media refinement — integrated

Eight original sixteen-pixel symbols now distinguish threat warning, flight envelope, altitude profile, lane selection, branch routes, boss contact, allied formation and command advice. The original icon family is preserved. EVAVO Art Studio rendered the SVG masters; all eight alpha checks passed without threshold changes. The original/revised comparison and three representative six-background proofs were visually inspected.

A native current-main intelligence capture exposed underlying sortie text bleeding through the modal surface. A 24x24 opaque backing was assembled beneath the retained 32x32 bezel, preserving the outer four pixels exactly. The first shared-screen trial also hid the regular maintenance-bay background and was rejected. The final new operations_modal_screen_9slice.png is used only by intelligence, stores and pause. The original shared operations_screen_9slice.png is restored byte-for-byte. Three preload-path substitutions are the entire production script change for this media integration.

Final pinned Godot 4.6.2 captures of intelligence, stores and pause were visually inspected. The modal surfaces block background text while the maintenance bay remains visible outside them. Existing mission text, layout, icon ordering and commands are preserved. The mission-flow self-test passes, with the existing ObjectDB exit warning; this is not a full release-gate result.

Runtime rebuild: node tools/build_mission_intel_v2.mjs. The builder verifies all nine reviewed source hashes before writing any runtime output. runtime_manifest.json records the sources and destinations. Original masters, Art Studio recipes/receipts, proofs and native captures are retained here.

Remaining interface work includes broader mission/debrief review and readability of truncated labels in the existing stores schematic. This change does not finish the full interface or production-art objective.
