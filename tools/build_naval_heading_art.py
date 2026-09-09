"""Build the five reviewed 2.5D heading exposures for mercenary naval hulls.

The master hull remains the source of truth.  These are intentionally stepped
cel poses: nearest-neighbour projection, a small heel squeeze, and fixed turn
angles.  Runtime chooses a pose from physical lateral velocity rather than
spinning a sprite continuously.
"""

from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/runtime/enemies/mercenary_sea"
OUT_SOURCE = ROOT / "assets/source/enemies/naval_heading_v1"
OUT_RUNTIME = ROOT / "assets/runtime/enemies/naval_heading"
HULLS = ("river_patrol", "torpedo_boat", "fast_attack_craft", "missile_corvette")
POSES = (
    ("hard_left", -13.0, 0.91),
    ("left", -6.5, 0.965),
    ("neutral", 0.0, 1.0),
    ("right", 6.5, 0.965),
    ("hard_right", 13.0, 0.91),
)


def pose(master: Image.Image, angle: float, heel: float) -> Image.Image:
    width, height = master.size
    squeezed = master.resize((max(1, round(width * heel)), height), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", master.size, (0, 0, 0, 0))
    canvas.alpha_composite(squeezed, ((width - squeezed.width) // 2, 0))
    return canvas.rotate(angle, Image.Resampling.NEAREST, expand=False, fillcolor=(0, 0, 0, 0))


def main() -> None:
    OUT_SOURCE.mkdir(parents=True, exist_ok=True)
    OUT_RUNTIME.mkdir(parents=True, exist_ok=True)
    manifest = {"version": 1, "poses": [name for name, _, _ in POSES], "hulls": {}}
    for hull_id in HULLS:
        master = Image.open(SOURCE / f"{hull_id}_idle.png").convert("RGBA")
        hull_source = OUT_SOURCE / hull_id
        hull_runtime = OUT_RUNTIME / hull_id
        hull_source.mkdir(exist_ok=True)
        hull_runtime.mkdir(exist_ok=True)
        manifest["hulls"][hull_id] = {"canvas": list(master.size), "frames": []}
        for name, angle, heel in POSES:
            frame = pose(master, angle, heel)
            frame.save(hull_source / f"{name}.png")
            frame.save(hull_runtime / f"{name}.png")
            manifest["hulls"][hull_id]["frames"].append(
                {"name": name, "turn_degrees": angle, "heel_x": heel}
            )
    (OUT_SOURCE / "naval_heading_manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
