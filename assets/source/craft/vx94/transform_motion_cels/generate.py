from pathlib import Path
from PIL import Image, ImageDraw
import json

ROOT = Path(__file__).resolve().parents[5]
OUT = ROOT / "assets" / "runtime" / "craft" / "vx94" / "gameplay" / "transform_motion"
OUT.mkdir(parents=True, exist_ok=True)

ANCHOR = (32, 38)
START = ((-19, 10), (19, 10))
END = ((-8, 18), (8, 18))
PALETTES = {
    "bomber": ((255, 132, 54, 74), (255, 180, 84, 214), (255, 225, 156, 255)),
    "hypersonic": ((64, 180, 255, 78), (104, 226, 255, 224), (214, 250, 255, 255)),
}


def point(a, b, t):
    return (round(ANCHOR[0] + a[0] + (b[0] - a[0]) * t), round(ANCHOR[1] + a[1] + (b[1] - a[1]) * t))


for family, (trail, active, hot) in PALETTES.items():
    for exposure in range(10):
        t = exposure / 9.0
        strength = max(0.0, 1.0 - abs(t * 2.0 - 1.0))
        back = Image.new("RGBA", (64, 72))
        rear = ImageDraw.Draw(back)
        front = Image.new("RGBA", (64, 72))
        fore = ImageDraw.Draw(front)
        for side in range(2):
            start = point(START[side], END[side], 0.0)
            tip = point(START[side], END[side], t)
            if 0 < exposure < 9:
                rear.line((start, tip), fill=trail, width=3)
                rear.line((start, tip), fill=active, width=1)
                fore.rectangle((tip[0] - 1, tip[1] - 1, tip[0] + 1, tip[1] + 1), fill=active)
                fore.point(tip, fill=hot)
        if 0 < exposure < 9:
            for hx in (26, 38):
                fore.rectangle((hx - 1, 44, hx + 1, 46), outline=active)
                if exposure in (4, 5):
                    fore.point((hx - 2, 43), fill=hot)
                    fore.point((hx + 2, 47), fill=hot)
        if family == "hypersonic" and exposure == 9:
            rear.line((25, 57, 29, 61), fill=active, width=1)
            rear.line((39, 57, 35, 61), fill=active, width=1)
            fore.point((29, 61), fill=hot)
            fore.point((35, 61), fill=hot)
        back.save(OUT / f"{family}_back_{exposure:02d}.png")
        front.save(OUT / f"{family}_front_{exposure:02d}.png")

manifest = {
    "schema_version": 1,
    "identity": "VX-94 registered variable-geometry motion cels",
    "canvas": [64, 72],
    "anchor": list(ANCHOR),
    "families": list(PALETTES),
    "exposures": 10,
    "layers": ["back", "front"],
    "style": "held-pose late-90s military animation; palette-limited actuator trails",
}
(Path(__file__).parent / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
