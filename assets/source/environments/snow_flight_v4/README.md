# Snow flight art revision 4

The earlier Snow B effect now has an individual-particle flight study. Actual Particle Studio simulation supplies 96 states at 24 fps over a verified four-second period, preserving its restrained slate/ice colours, round flakes, turbulence and no-trail/no-bloom treatment. Depending on phase, 111–129 flakes are alive.

The Godot fixture adds integrated aircraft travel separately at 6/20/52 pixels per world-distance unit for distant/middle/near flakes. Each flake wraps with an eight-pixel offscreen margin; lifetime opacity preserves its birth/death fade. This avoids translating a finished snow bitmap or scaling the animation clock with throttle. Distant and middle flakes draw on layer 8 behind aircraft art at 12, with near flakes on 18. Both snow surfaces clip to the combat area and leave HUD lanes clear.

Pinned Godot 4.6.2 completed 120 mountain combat frames with actual firing, throttle and afterburner input. Frames 18/54/84/114 were inspected. Snow remains visible as small non-emissive flakes with clear separation from weapon effects and warning graphics. This is an art/motion fixture, not a production weather integration, completed flight model, or whole-mission playtest. No production scripts or campaign data changed.

Particle Studio's quality and seam reports are retained. Exact start/end particle identity is meaningful evidence, but its small raster probe cannot establish full-size snow visibility; use the inspected native captures. Full native sequences and sampled states remain reproducible under work; selected captures, original effect, builder and fixture are preserved here.

Still open: weather placement/density, altitude transitions, orbital exclusion, accessibility, blizzard visibility and wind/snow audio, plus later production integration. No commit or push yet. The full production goal remains active.
