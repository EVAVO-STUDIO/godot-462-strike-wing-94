"""Build four native-pixel roll exposures for the VX-94 precision bomb."""
from hashlib import sha256
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / "assets/source/effects/precision_bomb_v2"
RUNTIME = ROOT / "assets/runtime/effects/projectiles/precision_bomb"

INK = (8, 12, 14, 255)
DARK = (34, 43, 45, 255)
STEEL = (151, 164, 161, 255)
LIGHT = (224, 226, 206, 255)
OLIVE = (116, 111, 59, 255)
AMBER = (232, 161, 54, 255)


def frame(index: int) -> Image.Image:
    image = Image.new("RGBA", (16, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    # A compact cruciform tail reads from above while the asymmetric highlight
    # and fin width provide four restrained roll exposures.
    fin = [3, 2, 3, 2][index]
    center = [8, 8, 7, 7][index]
    draw.polygon([(center, 2), (center - fin, 7), (center - 2, 9),
                  (center + 2, 9), (center + fin, 7)], fill=INK)
    draw.polygon([(center, 3), (center - fin + 1, 7), (center - 1, 8),
                  (center + 1, 8), (center + fin - 1, 7)], fill=DARK)
    draw.rounded_rectangle((center - 3, 6, center + 3, 19), radius=2, fill=INK)
    draw.rounded_rectangle((center - 2, 7, center + 2, 18), radius=1, fill=STEEL)
    draw.rectangle((center - 2, 9, center + 2, 11), fill=OLIVE)
    draw.point((center - 1 if index < 2 else center + 1, 8), fill=LIGHT)
    draw.point((center, 10), fill=AMBER)
    draw.polygon([(center - 2, 18), (center + 2, 18), (center, 22)], fill=INK)
    draw.polygon([(center - 1, 18), (center + 1, 18), (center, 21)], fill=LIGHT)
    return image


records = []
SOURCE.mkdir(parents=True, exist_ok=True)
RUNTIME.mkdir(parents=True, exist_ok=True)
for index in range(4):
    image = frame(index)
    runtime = RUNTIME / f"{index}.png"
    source = SOURCE / f"{index}.png"
    image.save(runtime, optimize=True)
    image.save(source, optimize=True)
    records.append({
        "frame": index,
        "runtime": runtime.relative_to(ROOT).as_posix(),
        "size": list(image.size),
        "visible_bounds": list(image.getbbox()),
        "sha256": sha256(runtime.read_bytes()).hexdigest().upper(),
    })

(SOURCE / "manifest.json").write_text(json.dumps({
    "asset_family": "vx94_precision_bomb_v2",
    "status": "runtime_integrated",
    "projection": "top-down guided bomb, nose downscreen",
    "visual_contract": [
        "dark outline remains legible over terrain",
        "steel body cannot be mistaken for a tracer or HUD marker",
        "tail fins and guidance band survive native gameplay scale",
        "four exposures imply axial roll without changing topology",
    ],
    "outputs": records,
}, indent=2) + "\n", encoding="utf-8")
print("Built four VX-94 precision bomb roll exposures.")
