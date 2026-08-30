# EVAVO Splash Provenance

HYPERSONIC uses the approved EVAVO publisher-ident plate and sparkle frames from `EVAVO-STUDIO/battle-chess` remote `main`.

- Authority commit inspected: `12a1138b` (`Restore RAW ART front door splash`)
- Runtime manifest: `assets/runtime/brand/front_door_raw_art_v1/manifest_v1.json`
- Canonical plate SHA-256: `d834faf8795c85eadaf80c50278b0638d8d1b7025c92dc58d40d98a6eeaec232`
- Identity lock: approved open-bar E and complete metallic frame
- Runtime geometry: 640×360, unchanged
- Sparkle geometry: 64×64 at logical position 568×66, 12 fps, one pass

The HYPERSONIC startup director preserves the approved EVAVO plate, sparkle assets, placement, reveal/fade timings, and minimum readable exposure. It replaces Battle Chess-specific title content only after the publisher ident has faded to black.

`tools/validate.ps1` verifies the canonical plate and boundary sparkle hashes so the approved identity cannot drift accidentally.
