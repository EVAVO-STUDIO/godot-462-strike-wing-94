# VX-94 combined loadout art review

Fifty assemblies combine existing reviewed primary and support hardware: ballistic + Twin Rocket Pods; Needle Rail + Hunter Rack; Plasma Lance + Magnetic Screen; Storm Cannon + EMP Disruptor; ballistic + Point Defence. Each has fighter/bomber forms and all five bank poses. Only one primary and one support are represented at a time.

Art Studio assembles original layers in depth order: support/primary underbody equipment, retained airframe, visible primary hardware/apertures, with dorsal hardware in the upper layer group. Each recipe records the exact draw order and source hashes. Input snapshots preserve reproducibility without overwriting source candidates. These assemblies are review media, not another runtime atlas.

All five boards were visually inspected. All fifty alpha checks pass at the existing source-matte limits. Every support contributes visible pixels compared with the corresponding primary-only composite (minimum 65 changed visible pixels). This proves it was not accidentally hidden by a duplicate airframe layer; it does not certify every possible loadout.

Pinned Godot 4.6.2 produced fifty native fixtures. Five captures covering all five loadouts were visually inspected at 1x/3x, along with three representative six-background proofs. The inspected combinations do not obscure the canopy or produce detached stores. No live firing, damage, pitch/transformation or gameplay timing was exercised.

Open integration ordering: base airframe pose, underbody hardware, surface hardware, hull damage clipped to the active silhouette, then transient effects. Dorsal module damage needs its own treatment rather than painting underlying hull scratches above intact equipment. Transforming pylons and ventral/strategic bay release remain unfinished. Production input, scrolling, lethality and support selection remain unchanged.
