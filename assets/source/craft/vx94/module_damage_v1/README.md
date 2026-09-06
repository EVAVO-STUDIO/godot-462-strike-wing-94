# VX-94 localized dorsal-module damage

Sixty scarred/burnt art variants cover the three reviewed dorsal housings, both forms and five banks. Separate original SVG damage layers depict localized soot, fractured surface detail and exposed edges. Art Studio masks each overlay to the corresponding module silhouette before retained-layer assembly.

All sixty overlays have zero damage pixels outside their module. Visible airframe pixels outside the module and the entire composite alpha remain unchanged. These are cosmetic presentation choices, not component-health mechanics or survivable-hit counts. Do not infer that a craft survives a missile strike to display these variants.

Art Studio alpha checks: sixty passed, zero failures at unchanged source-matte limits. All three intact/scarred/burnt boards were visually inspected, plus three representative six-background proofs. Sprite Studio strict PASS as sixty static named states; no animation continuity is claimed.

Pinned Godot 4.6.2 captured sixty native 1x/3x fixtures. Burnt point-defence fighter neutral, burnt EMP bomber hard-left and burnt magnetic-screen bomber hard-right were inspected. No live damage event was simulated by this art fixture.

Runtime ordering now keeps hull scratches beneath the mounted module and applies equipment-local scars above it. Surviving gun or fragment damage selects scarred then burnt module art from the live hull ratio; catastrophic missile lethality remains unchanged and does not imply a missile-survivable module state.
