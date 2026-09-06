# Stores schematic readability — integrated

The prior schematic clipped station names to eighteen characters and labelled only seven stations per form. The bomber consequently omitted its strategic penetrator bay and dorsal mission module. The current layout numbers station callouts and places full legends beneath the two aircraft: seven fighter stations and nine bomber stations. Mount data, socket positions relative to the scaled aircraft, equipment selection and weapon behaviour are unchanged.

The existing PixelFont width rule confirms every legend label fits its column and every row ends above the installed-equipment summary. Native Godot 4.6.2 captures were visually inspected, including all labels and both diagrams. The mission-flow self-test passes with the existing ObjectDB shutdown warning.

The gold key now says COMPATIBLE LOADOUT STATION. The existing role-based highlighting identifies compatible stations and does not prove every station currently contains or fires a store. This wording reflects the existing selection logic without changing gameplay.

The retained connector and socket art remain in use. The integrated layout lives in scripts/loadout_schematic_director.gd. Broader interface, gameplay and release QA remain open.

## Native matrix coverage — 2026-09-07

The opened schematic is now a deterministic visual-QA state through `--capture-stores-schematic`; normal L-key behavior is unchanged. A fresh pinned Godot 4.6.2 capture at 640x360 confirms all seven fighter and nine bomber legends, installed-equipment rows, title and footer fit within the modal surface. `front_stores_schematic` is part of the standard matrix so later typography or mount-catalogue changes must retain this evidence.
