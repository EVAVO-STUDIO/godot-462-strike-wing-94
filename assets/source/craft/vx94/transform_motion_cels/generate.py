from pathlib import Path
from PIL import Image, ImageDraw
import json

ROOT = Path(__file__).resolve().parents[5]
OUT = ROOT / "assets" / "runtime" / "craft" / "vx94" / "gameplay" / "transform_motion"
OUT.mkdir(parents=True, exist_ok=True)

ANCHOR = (32, 38)
# Registered gameplay-space wing-tip travel. The previous marks lived low on
# the nacelles and disappeared into the fuselage; these follow the actual main
# plane tuck from broad fighter geometry toward the hypersonic rails.
TIP_PATHS = {
    "bomber": (((14, 38), (23, 31)), ((50, 38), (41, 31))),
    "hypersonic": (((14, 38), (22, 49)), ((50, 38), (42, 49))),
}
HINGES = ((25, 35), (38, 35))
PALETTES = {
    "bomber": ((255, 132, 54, 74), (255, 180, 84, 214), (255, 225, 156, 255)),
    "hypersonic": ((64, 180, 255, 78), (104, 226, 255, 224), (214, 250, 255, 255)),
}


def point(a, b, t):
    return (round(a[0] + (b[0] - a[0]) * t), round(a[1] + (b[1] - a[1]) * t))


for family, (trail, active, hot) in PALETTES.items():
    for exposure in range(10):
        t = exposure / 9.0
        strength = max(0.0, 1.0 - abs(t * 2.0 - 1.0))
        back = Image.new("RGBA", (64, 72))
        rear = ImageDraw.Draw(back)
        front = Image.new("RGBA", (64, 72))
        fore = ImageDraw.Draw(front)
        for side in range(2):
            path = TIP_PATHS[family][side]
            start = path[0]
            tip = point(path[0], path[1], t)
            if 0 < exposure < 9:
                # Two held afterimages communicate fast mechanical travel while
                # remaining discrete cel animation rather than a vector effect.
                ghost = point(start, tip, 0.48)
                rear.line((start, ghost), fill=trail, width=3)
                rear.line((ghost, tip), fill=active, width=2)
                rear.point(point(start,tip,0.24),fill=active)
                fore.rectangle((tip[0] - 1, tip[1] - 2, tip[0] + 1, tip[1] + 2), fill=active)
                fore.point(tip, fill=hot)
        if 0 < exposure < 9:
            for hx, hy in HINGES:
                fore.rectangle((hx - 2, hy - 2, hx + 2, hy + 2), outline=active)
                if exposure in (3, 4, 5, 6):
                    fore.line((hx-1,hy,hx+1,hy),fill=hot,width=1)
        if family == "hypersonic" and exposure == 9:
            for side, path in enumerate(TIP_PATHS[family]):
                tip = path[1]
                direction = 1 if side == 0 else -1
                rear.line((tip[0],tip[1],tip[0]+direction*4,tip[1]+3),fill=active,width=2)
                fore.rectangle((tip[0]-1,tip[1]-1,tip[0]+1,tip[1]+1),outline=hot)
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
    "style": "held-pose late-90s military animation; registered wing-tip afterimages, hinge lamps and palette-limited actuator trails",
}
(Path(__file__).parent / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
