# HYPERSONIC tracker presentation review

Status: measured screening renders, not final music/mix/listening approval. Production music and its twelve original motifs are unchanged.

Exported all twelve cues by invoking the actual RetroMusicDirector sample function with its initial noise seed. Each excerpt covers two repetitions of the current 16-step pattern, before saved mixer gain. 22,050 Hz, mono PCM16; each sample is the same as either channel of the runtime dual-mono generator. Export process completed with all twelve WAVs. Raw and DC-cleaned candidate files remain in work/audio_review_v2.

Used the EVAVO Audio Studio reusable FFprobe/loudness/astats functions from its migration analyzer. Its Brass & Brine project contract was not applied to HYPERSONIC, and no release authority is implied. Analyzer SHA and exact cue WAV hashes are in the reports. These short excerpts are useful for DC/peak screening, not full-song loudness acceptance.

Findings:

- Each cue repeats a single 16-step pattern; actual pattern lengths span approximately 1.46–2.61 seconds. Preserve these motifs, then develop longer arrangements and transitions suitable for missions and cinematics.
- Raw cue DC offset ranges from approximately -0.0128 to -0.0207. A 20 Hz high-pass candidate reduces it to between -0.000015 and +0.000032, with measured integrated loudness changing by no more than 0.01 LU in these excerpts.
- Raw true peaks range from -4.95 to -1.87 dBTP. A few isolated samples reach the runtime 0.72 limiter; this is distinct from PCM full-scale clipping.
- Excerpt end/start discontinuity is recorded for screening only: runtime oscillators/noise continue across pattern boundaries. These extracted WAVs are not approved seamless loops and must not simply replace the runtime generator.

Next production work: preserve thematic motifs while developing complete arrangements; review instrument envelopes and transitions; audition SFX/radio/music together in native gameplay; choose mastering and playback changes only after that evidence. Do not claim musical listening from the numerical reports. The current environment exposed no audio-listening analysis tool, so subjective approval is still pending.

Audition reel: twelve DC-cleaned excerpts at the existing default gain (master .80 × music .65), separated by half-second silence. It is a screening aid, not a gameplay recording or final release asset. No audio has been installed into runtime.
