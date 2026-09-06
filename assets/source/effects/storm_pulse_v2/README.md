# Storm Cannon pulse art

Four original 16x24 pixel frames, authored as SVG and rendered through EVAVO Art Studio without resampling or sharpening. Broad white/cream core, restrained blue-grey containment and short bipolar discharge tabs distinguish the area-discharge packet from the thin cyan rail and violet plasma projectiles. Existing projectile anchor is (8,7).

Status: reviewed and integrated. `ProjectileCueDirector` now routes only Storm Cannon projectiles through the dedicated `storm_pulse` family. Needle Rail retains its thin electromagnetic dart and Plasma Lance retains its strategic violet packet.

All four frames passed exact canvas, transparent edges and strict Sprite Studio QA with zero corrections. Five-colour and alpha proofs reviewed. Native 4.6.2 presentation fixture compared rail, Storm and plasma at 1x on ground/surf/water using the production anchor and four-sided dark underprint. This is a presentation fixture, not natural weapon firing or export validation. Raw-image loads for baseline resources generated export warnings in the scratch harness; no asset load failed, and this harness is not shipped.

Integration preserves the existing 510 px/s speed, three-shot spread, damage, energy demand and area-discharge rules. Native firing evidence verifies the dedicated packet, timing and enhanced-contrast path; full busy-sortie balance remains part of later gameplay telemetry. No gameplay behaviour changed in this art pass.
