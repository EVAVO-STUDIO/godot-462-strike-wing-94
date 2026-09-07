from pathlib import Path
from PIL import Image, ImageDraw
import json

ROOT = Path(__file__).resolve().parents[5]
OUT = ROOT / "assets" / "runtime" / "effects" / "projectiles" / "homing_missile"
OUT.mkdir(parents=True, exist_ok=True)

plumes = [
    [(7, 14), (8, 14), (7, 15), (8, 15), (7, 16), (8, 16), (7, 18)],
    [(7, 14), (8, 14), (6, 15), (9, 15), (7, 16), (8, 16), (7, 17), (8, 19)],
    [(7, 14), (8, 14), (7, 15), (8, 15), (6, 16), (9, 16), (7, 18), (8, 20)],
    [(7, 14), (8, 14), (6, 15), (9, 15), (7, 16), (8, 17), (7, 19), (8, 21)],
]

for frame_index, plume in enumerate(plumes):
    image = Image.new("RGBA", (16, 24))
    draw = ImageDraw.Draw(image)
    # Fixed airframe and pivot: the animation changes combustion only.
    draw.polygon([(7, 1), (9, 3), (9, 11), (11, 14), (9, 13), (9, 15), (6, 15), (6, 13), (4, 14), (6, 11), (6, 3)], fill=(18, 25, 29, 255))
    draw.polygon([(8, 2), (8, 11), (10, 13), (8, 12), (8, 14), (7, 14), (7, 12), (5, 13), (7, 11), (7, 3)], fill=(184, 191, 188, 255))
    draw.point((8, 2), fill=(238, 231, 204, 255))
    draw.line((7, 7, 8, 7), fill=(176, 48, 38, 255), width=1)
    draw.point((7, 10), fill=(102, 113, 113, 255))
    for index, point in enumerate(plume):
        color = (255, 238, 170, 255) if index < 2 else ((255, 132, 38, 235) if index < 6 else (173, 54, 28, 168))
        draw.point(point, fill=color)
    image.save(OUT / f"{frame_index}.png")

manifest = {
    "schema_version": 2,
    "identity": "hostile heat-seeking missile in flight",
    "canvas": [16, 24],
    "pivot": [8, 7],
    "frames": 4,
    "invariants": ["fixed airframe silhouette", "fixed seeker and fin registration", "exhaust animation only"],
    "style": "late-90s military cel ordnance; pale body, red identification band, hot chemical exhaust",
}
(Path(__file__).parent / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
