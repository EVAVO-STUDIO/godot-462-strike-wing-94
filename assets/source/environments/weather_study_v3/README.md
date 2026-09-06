# Weather art study, 6 September 2026

User direction: improve rain, snow and cloud art; ground scrolling must follow actual aircraft travel and acceleration, without forward flight stopping at a screen-space wall; direct missile/rocket hits should usually destroy the airframe. Full working direction is retained in work/FLIGHT_WEATHER_DIRECTION.md.

Executed the actual local Atmosphere Studio rain-field 1.1.0 compiler and checksum/reproduction verifier. The 640x304 request uses three depth bands, seed 9406, an eight-second cycle and restrained slate-blue light. Two requests yielded 32 and 49 particles. Stored plans and 48 sampled states each. A native Godot 4.6.2 scratch surface renders those states over a retained refinery gameplay capture, excluding the top and bottom HUD lanes. Both 48-frame runs completed without engine errors.

Inspected light-rain frames 12/36 and denser-rain frame 24. The light version is drizzle; the denser version is more legible but some foreground streaks are long and could resemble tracers. Neither is approved as final weather. Next compare shorter foreground streaks, wind and actual moving flight, including hostile projectile readability. Do not infer speed response from these fixed-background captures.

The two-second MP4 is an excerpt from an eight-second plan, not a seamless loop. No snow implementation or final cloud improvement has been claimed. No production weather code, flight control, incoming damage or campaign data was changed in this study. Raw plan/state files remain available to integrate once the art and design are reviewed.

The 48 cinematic exposures captured earlier this turn remain under work/cinematic_art_review_v2. They have not yet all been visually inspected; capture completion alone is not cinematic approval.
