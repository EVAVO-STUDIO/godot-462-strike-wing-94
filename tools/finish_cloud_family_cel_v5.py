"""Finish the reviewed cloud family as restrained military cel art.

The twelve authored banks keep their silhouettes and native alpha.  This pass
only unifies colour, value grouping, and edge treatment across source sets.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "assets/runtime/environments/clouds"
SOURCE = ROOT / "assets/source/environments/cloud_family_cel_v5"
ORIGINALS = SOURCE / "originals"
V4_MANIFEST = ROOT / "assets/source/environments/cloud_family_v3/runtime_integration_v4.json"

PALETTES = {
    "low_wisp": [
        (73, 91, 103), (91, 110, 121), (111, 130, 140), (134, 151, 160),
        (158, 174, 182), (185, 198, 204), (213, 222, 226),
    ],
    "mid_broken": [
        (62, 77, 89), (79, 96, 108), (98, 116, 128), (120, 138, 149),
        (145, 161, 171), (173, 187, 195), (204, 214, 219),
    ],
    "high_mass": [
        (52, 67, 82), (69, 85, 101), (88, 105, 120), (109, 126, 140),
        (133, 149, 162), (160, 174, 185), (192, 203, 211),
    ],
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def family_for(name: str) -> str:
    return next(key for key in PALETTES if key in name)


def finish(source: Image.Image, family: str) -> Image.Image:
    image = source.convert("RGBA")
    alpha = image.getchannel("A")
    # A small blur is used only to classify broad value masses. The authored
    # alpha and silhouette remain untouched.
    value = image.convert("L").filter(ImageFilter.GaussianBlur(radius=1.15))
    a = alpha.load()
    v = value.load()
    out = Image.new("RGBA", image.size)
    dst = out.load()
    palette = PALETTES[family]
    width, height = image.size
    for y in range(height):
        for x in range(width):
            native_alpha = a[x, y]
            if native_alpha <= 3:
                continue
            level = min(6, max(0, (v[x, y] * 7) // 256))
            # Alpha-gradient edges receive one controlled highlight step. This
            # gives banks a hand-inked rim without a dark sticker outline.
            neighbour_min = min(
                a[max(0, x - 1), y], a[min(width - 1, x + 1), y],
                a[x, max(0, y - 1)], a[x, min(height - 1, y + 1)],
            )
            if native_alpha > 76 and neighbour_min < native_alpha - 42:
                level = min(6, level + 1)
            red, green, blue = palette[level]
            # Sixteen alpha exposures preserve antialiasing while removing the
            # noisy near-transparent resampling values of mixed source renders.
            cel_alpha = min(255, ((native_alpha + 7) // 16) * 16)
            dst[x, y] = (red, green, blue, cel_alpha)
    return out


def main() -> None:
    previous = json.loads(V4_MANIFEST.read_text(encoding="utf-8"))
    expected = {Path(item["path"]).name: item["sha256"] for item in previous["files"]}
    SOURCE.mkdir(parents=True, exist_ok=True)
    delivered = []
    for original in sorted(ORIGINALS.glob("cloud_bank_*.png")):
        if sha256(original) != expected.get(original.name):
            raise RuntimeError(f"Reviewed v4 input changed: {original.name}")
        family = family_for(original.name)
        output = finish(Image.open(original), family)
        source_output = SOURCE / original.name
        output.save(source_output, optimize=True)
        path = RUNTIME / original.name
        output.save(path, optimize=True)
        delivered.append({
            "path": str(path.relative_to(ROOT)).replace("\\", "/"),
            "family": family,
            "sha256": sha256(path),
        })
    manifest = {
        "schema": "hypersonic_cloud_family_cel_v5",
        "status": "deterministic_finished_runtime",
        "source_policy": "reviewed v4 silhouettes and native alpha; unified seven-value cel palettes",
        "alpha_exposures": 16,
        "files": delivered,
    }
    (SOURCE / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Finished {len(delivered)} cloud banks into one cel-art family.")


if __name__ == "__main__":
    main()
