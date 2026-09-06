# Hypersonic propulsion integration

The VX-94 now separates three propulsion states visually. Ordinary afterburner charge retains its compact orange plume. The hypersonic latch emits one 360 ms paired-engine pressure burst and the existing shallow sonic front while actual speed rises over the authored 0.12-second entry response. Hypersonic flight and recovery draw a four-exposure blue-white plume from both engine outlets. Exhaust registration follows fighter/bomber form, five bank poses and the current altitude-pitch offset.

Reduced Flashes scales the pressure burst and sonic front to 48% opacity. It does not dim the sustained blue engines, because those communicate the aircraft's current power state. The burst is edge broken and rear originated rather than a full-screen flash.

`tools/build_hypersonic_propulsion_v2.mjs` rebuilds ten runtime cels through EVAVO Art Studio and refuses changed source or output hashes. The original orange afterburner, paired ignition and sonic-front cels remain preserved in the canonical source package. The blue plume's Sprite Studio package passes strict loop QA. The expanding/fading burst fails generic sprite consistency limits; this is retained honestly. Its effect-specific test verifies monotonic expansion, final dissipation, exact unequal exposure timing and two outlets in all ten form/bank poses.

Pinned Godot 4.6.2 passes afterburner, hypersonic and propulsion tests. Two native 72-frame sequences use real charge, latch, acceleration to 4.4 and fuel exhaustion: one at full effects and one with Reduced Flashes. Frames 6, 8 and 16 were inspected for burst origin, overlap, blue-engine readability, HUD clearance and sustained state. Capture invulnerability means this is propulsion presentation evidence, not balance evidence. The visual QA matrix now includes full and reduced entry states in addition to its sustained Hypersonic Trial capture.

Sound synchronization and the complete release gates remain outstanding.
