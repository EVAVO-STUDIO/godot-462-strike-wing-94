# HYPERSONIC allied strike aircraft, revision 2

Original Rapier fighter, Hammer bomber and Atlas tanker geometry, lit and rendered locally with Blender 5.2.1 LTS. Four exposures retain the same body silhouette while changing restrained engine/navigation-light emission. EVAVO Art Studio downsamples the retained transparent renders; Sprite Studio verifies four-frame timing, stable pivots and silhouette, and supplies Godot delivery candidates. Runtime retains the existing loose-frame interface and sizes (48x28, 64x36 and 112x64).

This offline source folder has `.gdignore`. Godot must import the runtime PNGs, not launch its Blender importer for these provenance files. Without this boundary, headless 4.6.2 can return zero while aborting pending texture reimports because the editor Blender path is unset. Inspect import logs as well as exit status. The canonical external art rebuild still reads every retained source normally.

`manifest.json` identifies immutable render/SVG source hashes, finishing settings and reviewed output hashes. Run `node tools/build_support_aircraft_v2.mjs` from the game repository to reconstruct all thirteen runtime images. The builder verifies every result before writing any runtime file. `EVAVO_ART_STUDIO` can override the local Studio checkout path. The retained Blender generator is source provenance; canonical rebuilds use retained renders, avoiding renderer-version drift.

The conventional strike bomb uses an original crisp-edge SVG with shaded steel casing, tail fins and restrained identification band. It retains its 16x32 canvas and existing position contract while reducing the visible silhouette.

Reviewed evidence: all sixteen revision-E aircraft candidate frames passed exact dimensions/transparent-edge checks; all four candidate families passed Sprite Studio strict checks. Rapier and Hammer native Godot 4.6.2 coast fixtures and five-colour/alpha proof plates were inspected before promoting their eight frames. Strike bomb inspected in the native bomber fixture and proof plates. No gameplay rules changed. These fixtures do not establish natural support activation, difficulty balance or full-sortie acceptance.

Atlas was subsequently reviewed in the native refuelling fixture, including a magnified hose/wing-root connection detail, and its four frames promoted. Existing hose, contact and transfer instruments are preserved.

Gunship is deliberately absent from this runtime revision. Its revised visible battery has projected muzzle positions retained for later integration; it must not replace the current production family until the firing origins are verified.
