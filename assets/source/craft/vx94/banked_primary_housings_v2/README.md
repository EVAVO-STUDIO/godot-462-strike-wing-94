# VX-94 banked primary housings

Forty candidate deployment states now cover fighter and bomber across all five existing bank poses. Original local SVG hardware is finished and assembled in EVAVO Art Studio, with separate near/far layers and explicit visual muzzle anchors. The retained aircraft artwork is preserved. The bomber housing draws beneath the nose; fighter housings follow the shoulders.

All 60 hardware layers pass native-alpha QA. All 100 six-background proof plates were inspected, covering individual layers and assembled craft. Sprite Studio packs 40 exposures as ten four-frame, 8 fps, non-looping animations with default strict checks: zero errors or duplicate frames. The combined airframe sprites still fail the edge-halo check; base-versus-candidate evidence is retained rather than loosening its threshold.

A standalone Godot 4.6.2 art fixture rendered 48 frames at 640x360, displaying every pose at native size and using the existing muzzle-flash art with the proposed anchors and barrel angles. Closed, intermediate and firing captures were inspected. This does not validate production projectile origins, flight controls or combat balance.

These are now integrated production runtime assets. Conventional primary weapons select the matching fighter/bomber and five-pose bank composite, while the live recovery timer advances the authored deployment and discharge states. The complete composite inherits the aircraft's existing altitude/pitch displacement and registered 64x72 pivot, keeping the hardware attached during actual flight.

## Source-matte review resolution

The generic edge-halo warning is resolved for these candidates. The checker flags partial dark pixels near brighter opaque pixels when black is considered a known matte. The original fighter mastering evidence declares #ef0bed magenta; the bomber declares #f6f6f6 and #fefefe checker colours. The bomber raw painting and fighter alpha master were inspected. Navy outlines are part of the painted craft, not a black source background. All 40 candidates pass with the union of those documented source mattes and the unchanged maximumHaloFraction 0.015. No pixels or thresholds were altered to obtain this result. Previous generic failures remain in alpha_evidence and edge_comparison.json. This resolves that diagnostic warning only; production integration and remaining hero states are still pending.
