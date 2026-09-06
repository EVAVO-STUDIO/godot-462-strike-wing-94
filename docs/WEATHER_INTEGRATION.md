# Weather integration

Runtime precipitation now consumes the reviewed Atmosphere Studio rain plans and Particle Studio snow exposures. `data/weather/placement.json` explicitly maps all 30 campaign and six secret sorties. Nine orbital routes are excluded. Low/mid/high/orbital precipitation weights are 1.0/0.6/0.0/0.0, blended through the actual altitude transition. Particle identity and wind time do not restart on a throttle, altitude or accessibility change.

Rain uses short slate streaks across three depths; snow retains the full 96-exposure, four-second particle cycle. Integrated camera distance supplies depth-dependent travel, independently of wind/fall time. Distant/middle precipitation sits behind aircraft and near precipitation ahead. Parent clipping controls exclude the top instrument and bottom radio lanes. Reduced Flashes reduces opacity to 55% without touching threats. The old unconditional open-water rain accents are no longer drawn.

Environment seed and variant lookup now consume the actual active mission, including secrets. Seed Manifest consequently uses its authored city variant. No campaign IDs or save fields changed.

Rebuild delivery with `python tools/build_weather_delivery.py`. It verifies reviewed source hashes and the source campaign catalogue hashes before writing runtime delivery. Complete snow states are retained in the canonical source package, so rebuilding does not depend on scratch work.

## Verification and limits

Pinned Godot 4.6.2 weather, environment and secret-mission self-tests pass. The weather test is registered in validate.ps1 and covers all 36 mappings, orbital exclusions, secret context, altitude fades, bounded streak lengths, travel response, 96 snow exposures and clipping structure. Four weather cases have been added to the native visual QA matrix.

Accepted native evidence: `work/weather_integration_v1/native_v2_{drizzle,rain,storm,snow}`; 84 frames each, 336 total. All begin with full low-altitude precipitation, accelerate, enable Reduced Flashes at frame 54, and climb at frame 66 until precipitation reaches zero. Drizzle/rain reach 1.78 speed; storm/snow reach approximately 4.08/4.14. Selected native images were inspected, including both high-speed states and the snow fade. The rain is deliberately subtle over dense terrain and remains distinct from orange gunfire. Source review package: `assets/source/environments/weather_integration_v1`.

The first harness stopped on an incorrect fixture mission index; this was corrected without altering runtime mapping. An intermediate complete capture used mid altitude for two cases because mission-entry initialization had not yet settled; it is retained separately. Accepted captures wait for that initialization before setting the test condition. All use explicit invulnerability: no survival or damage-balance conclusion is drawn.

The reviewed Audio Studio rain and snow-wind masters are now byte-identical runtime resources under `assets/runtime/audio/weather`. Both 16-second stereo 22.05 kHz loops have zero seam delta and no clipped samples. The weather renderer keeps both clocks running and crossfades their levels so altitude or mission transitions never restart the ambience. Drizzle, rain, storm and snow have distinct restrained gains; the same altitude weight drives audio and precipitation, and actual world speed changes airflow gain by no more than twelve percent and pitch from 0.96 to 1.04. Master and SFX settings apply after the authored weather level, leaving radio and missile-warning tones foregrounded.

`assets/source/audio/weather_audio_v1/runtime_integration.json` records hashes and the mix contract. `outputs/HYPERSONIC-weather-runtime-mix-candidate.ogg` is the concrete listening candidate. Technical, live loop-mode and crossfade tests pass; the Audio Studio receipts still require final in-game listening approval before release lock.

Full native stress, Windows release gate, expanded visual matrix and eight-sortie telemetry remain outstanding for the overall production changes. These focused captures do not establish final release quality.
