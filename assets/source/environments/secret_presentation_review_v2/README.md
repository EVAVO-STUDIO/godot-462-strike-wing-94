# Six secret sorties: native art evidence

Pinned Godot 4.6.2, current main plus reviewed uncommitted art. Each manifest entry records its exact Git HEAD, requested form and altitude, capture time 52 seconds, and engine exit status. These are staged gameplay captures after an initial jump to mission time; they do not prove discovery, encounter chronology, boss balance, or full sortie completion.

## Import correction

The first two runs (`secret_art_review_v2` and `_imported`) retained stale water textures. The first editor import returned zero but its log reported an unset Blender path and aborted before texture reimport. Added `.gdignore` to the two newly retained offline support Blender source folders. A second pinned editor import completed texture reimport without an ERROR. This `_current` run uses the recovered wave textures; the original files and rejected captures remain intact as evidence. Do not call the first import successful merely because its process returned zero.

## Integration findings for the code phase

- Seed Manifest explicitly requests `environment_variant: city_outskirts`, but `EnvironmentDirector._mission_variant` and `_mission_seed` read `mission_catalog[mission_index]` instead of the active secret mission. Its native capture consequently shows refinery scenery. Preserve the existing city art and secret canon; correct the selector after the art/design pass.
- All six captures display `CONTACT // GUNSHIP PROBE`, a beat from the first normal mission. `EncounterDirector._active_mission` also reads the normal catalog directly. This is consistent with the native evidence and warrants a real secret-sortie encounter test, not a cosmetic radio-label replacement.
- Surface spawn-lane selection in `main.gd` likewise reads the normal catalog variant. Review it with the same active-mission correction so units remain on the intended terrain.

The six secret mission definitions, requirements, rewards, objectives, enemy lists and canon have not been edited. The source selectors above are recorded defects, not implemented fixes.
