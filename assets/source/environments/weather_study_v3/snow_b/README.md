# Snow and spindrift study B

Original Particle Studio effect authored for HYPERSONIC. Three depth layers use non-emissive slate/ice-coloured discs, different fall speeds and turbulence, no spark trails or bloom. Four seconds, 12 held exposures/second, 640x304 transparent frames. Candidate A was rejected at native scale because its subpixel flakes largely vanished. B increases authored flake size 2.8 times; both source versions remain in work.

Particle Studio rendered all 48 B frames and reports a reproducible periodic model. Addressed last-to-first state step ratio 0.781078 is within its 1.5 limit. Its 64px raster probe returns all zero differences because these flakes are too small at that probe resolution: that portion of the report is NOT meaningful visual-loop evidence. At full size, each B frame has 298–392 pixels above alpha 32, with maximum alpha 166. Technical quality score 93 is not final art approval.

Art Studio composited every B frame over the retained native mountain capture at y34, leaving HUD strips outside the weather canvas. Frame 24 reviewed at native scale. The flakes are distinct from the long rain streaks and remain restrained; moving-world and enemy-projectile comparisons are still required. The existing mountain connector smears remain visible and are unresolved. Do not mistake those bands for generated snow or fog.

The MP4 contains the complete four-second candidate period. It is a composited art study over a fixed background, not integrated snowfall, flight-speed coupling, final storm density or a native running weather system. No runtime weather assets have been replaced.

Cloud follow-up: the existing high cloud PNG has meaningful alpha (7,765 fully transparent pixels of 12,800); its hidden grey RGB does not prove a baked matte. Inspected retained cloud sheet candidate 02, which has useful large, detailed cloud forms on a grey backdrop. Larger volume extraction requires careful alpha recovery and native compositing; preserve dark cloud shadows rather than cutting away all grey pixels. Current cloud renderer scales banks to 0.72–1.08 and applies low alpha, which also contributes to their faint presentation.
