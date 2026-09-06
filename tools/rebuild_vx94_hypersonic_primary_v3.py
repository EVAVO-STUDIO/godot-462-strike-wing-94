from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
OLD = ROOT / "assets/source/craft/vx94/transform_v3/originals"
NEW = ROOT / "assets/runtime/craft/vx94/transform"
PRIMARY = ROOT / "assets/runtime/craft/vx94/gameplay/transform_primary"
SOURCE = ROOT / "assets/source/craft/vx94/transform_v3"
FAMILIES = ("ballistic", "needle_rail", "storm_cannon", "plasma_lance")


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rebuild_primary(index: int, family: str) -> None:
    old_body = Image.open(OLD / f"hypersonic_{index:02d}.png").convert("RGBA")
    new_body = Image.open(NEW / f"hypersonic_{index:02d}.png").convert("RGBA")
    old_mounted = Image.open(PRIMARY / f"hypersonic_{family}_{index:02d}.png").convert("RGBA")
    result = new_body.copy()
    ratio = index / 9.0
    inward = round(3.0 * ratio * ratio * (3.0 - 2.0 * ratio)) if family == "ballistic" else 0
    for y in range(72):
        for x in range(64):
            pixel = old_mounted.getpixel((x, y))
            if not pixel[3] or pixel == old_body.getpixel((x, y)):
                continue
            target_x = x + inward if x < 32 else x - inward
            if 0 <= target_x < 64:
                result.alpha_composite(Image.new("RGBA", (1, 1), pixel), (target_x, y))
    result.save(PRIMARY / f"hypersonic_{family}_{index:02d}.png", optimize=True)


def main() -> None:
    records: list[dict[str, object]] = []
    for index in range(10):
        for family in FAMILIES:
            rebuild_primary(index, family)
        frame = NEW / f"hypersonic_{index:02d}.png"
        records.append(
            {
                "exposure": index,
                "runtime": frame.relative_to(ROOT).as_posix(),
                "sha256": sha(frame),
                "visible_bounds": list(Image.open(frame).convert("RGBA").getbbox() or ()),
            }
        )
    manifest = {
        "schema": "hypersonic_vx94_transform_v3",
        "source_components": "assets/source/craft/vx94/transform_v2/components",
        "preserved_predecessor": "assets/source/craft/vx94/transform_v3/originals",
        "wing_angle_degrees": [-22.0, -65.0],
        "tail_angle_degrees": [-18.0, -45.0],
        "registered_canvas": [64, 72],
        "frames": records,
    }
    (SOURCE / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print("Rebuilt forty mounted-primary composites on the deep-sweep VX-94 exposures.")


if __name__ == "__main__":
    main()
