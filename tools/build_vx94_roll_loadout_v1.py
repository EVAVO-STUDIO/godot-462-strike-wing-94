from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
GAMEPLAY = ROOT / "assets/runtime/craft/vx94/gameplay"
OUTPUT = GAMEPLAY / "roll_loadouts"
SOURCE = ROOT / "assets/source/craft/vx94/evasive_roll_loadout_v1"
FAMILIES = ("ballistic", "needle_rail", "storm_cannon", "plasma_lance")


def visible_component(base_path: Path, mounted_path: Path) -> Image.Image:
    base = Image.open(base_path).convert("RGBA")
    mounted = Image.open(mounted_path).convert("RGBA")
    if base.size != mounted.size:
        raise ValueError(f"geometry mismatch: {base_path} / {mounted_path}")
    result = Image.new("RGBA", base.size, (0, 0, 0, 0))
    source_pixels = mounted.load()
    base_pixels = base.load()
    output_pixels = result.load()
    for y in range(base.height):
        for x in range(base.width):
            source = source_pixels[x, y]
            if source[3] and source != base_pixels[x, y]:
                output_pixels[x, y] = source
    if result.getbbox() is None:
        raise ValueError(f"no mounted component found in {mounted_path}")
    return result


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    SOURCE.mkdir(parents=True, exist_ok=True)
    records: list[dict[str, object]] = []
    for form in ("fighter", "bomber"):
        base = GAMEPLAY / "bank" / f"{form}_neutral.png"
        for family in FAMILIES:
            mounted = (
                GAMEPLAY / "primary_housings" / f"{form}_neutral_2.png"
                if family == "ballistic"
                else GAMEPLAY / "specialist_housings" / f"{family}_{form}_neutral_2.png"
            )
            name = f"{family}_{form}.png"
            destination = OUTPUT / name
            component = visible_component(base, mounted)
            component.save(destination, optimize=True)
            records.append(
                {
                    "id": f"{family}_{form}",
                    "base": base.relative_to(ROOT).as_posix(),
                    "mounted": mounted.relative_to(ROOT).as_posix(),
                    "runtime": destination.relative_to(ROOT).as_posix(),
                    "geometry": list(component.size),
                    "visible_bounds": list(component.getbbox() or ()),
                    "sha256": sha256(destination),
                }
            )
    manifest = {
        "schema": "hypersonic_vx94_evasive_roll_loadout_v1",
        "method": "exact changed-pixel extraction from approved neutral bank and mounted composites",
        "anchor": [32, 36],
        "records": records,
    }
    (SOURCE / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Built {len(records)} transparent VX-94 evasive-roll loadout layers.")


if __name__ == "__main__":
    main()
