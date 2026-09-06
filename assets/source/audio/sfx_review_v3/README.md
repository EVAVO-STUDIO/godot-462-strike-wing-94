# Runtime sound-effect screening

Rendered all 32 existing event voices using the current Godot waveform function, original event specifications, 75% SFX / 80% radio gain, 22,050 Hz PCM and the production noise sequence. The renderer accounts for the noise sample consumed by the propulsion path before each voice. It excludes the propulsion bed itself, master gain, polyphony and music. WAVs include 0.1 seconds of trailing silence.

Audio Studio reviewed every isolated render: zero clipped samples and no detected issues. The largest active-window DC magnitude is about 0.0032 full scale. These results do not justify replacing the current event vocabulary wholesale. Abrupt gunfire attacks are intentional transient candidates, not automatically defects. Numeric screening does not establish listening quality or warning audibility in a crowded mix.

The runtime radio remains text plus procedural transmission/alert cues; this review does not claim recorded dialogue. Further integration review must cover the eight-voice limit, warning priority under sustained fire, music masking, master/SFX/radio controls and the new weather beds. Source hashes and exact original event specifications are retained. Production sound code is unchanged.

`render.log` retains an initial fixture-only script reflection parse failure; `render_final.log` records the corrected 32-voice render. The final renderer and Audio Studio review completed successfully.
