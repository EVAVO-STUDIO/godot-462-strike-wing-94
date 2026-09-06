# VX-94 external stores: neutral art candidate

Original SVG hardware, rendered with EVAVO Art Studio and assembled beneath the retained airframe painting. Five loadouts: fighter/bomber Hunter Rack, fighter/bomber Twin Rocket Pods, bomber precision bombs. Fifteen static named states: both sides loaded, left side expended/released, both sides empty. Thirty separate hardware layers retain future release and pose independence.

Missiles have muted ceramic noses, forward canards, conventional tail fins and subdued identification bands. Rocket pods retain their housing after firing; three nose pixels per side change from occupied tubes to dark empty tubes. Bombs use olive bodies and compact tails. Wing occlusion is intentional; the ventral strike bay is a separate, unfinished asset task.

Neutral-only visual anchors are recorded in manifest.json. They are not production projectile origins. Missile/bomb disappearance changes 47–54 visible pixels per side; rocket occupancy changes three pixels while preserving the pod silhouette. These subtle states need release effects and HUD ammunition feedback during integration.

Art Studio: all fifteen source-matte alpha checks pass at unchanged limits. Representative six-background proofs for all five loadouts were visually inspected. All fifteen states packed as single-frame named Sprite Studio states, strict PASS, zero warnings/errors. Zero sequence metrics are expected for static states and do not prove animation continuity. One duplicate is the shared empty bomber rail configuration.

Pinned Godot 4.6.2 rendered fifteen 640x360 fixtures at native 1x and enlarged 3x. Rocket loaded/left-expended and bomber bomb-loaded captures were inspected, together with loadout boards and proofs. These are art fixtures, not live firing, campaign or flight evidence.

Earlier v1/v2 prototypes remain under work. V1 rocket fronts were too hidden. V2 incorrectly removed expended rocket pods; v3 preserves the hardware and changes only the tube contents.

Remaining: five bank poses, pitch/transformation handling, damage layering, physical release anchors and exhaust clearance, ventral/strategic bays, dorsal modules, live gameplay integration and capture. No production code, loadout balance, ammunition economy or damage values changed.
