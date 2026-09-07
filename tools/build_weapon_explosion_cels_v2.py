from __future__ import annotations

import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/effects/weapon_explosions_v2"
RUNTIME = ROOT / "assets/runtime/effects/weapon_explosions"
REVIEW = ROOT / "work/weapon_explosion_cels_v2_review.png"
SCALE = 3


def canvas(size: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (size * SCALE, size * SCALE), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image, "RGBA")


def ellipse(draw, box, fill):
    draw.ellipse(tuple(int(v * SCALE) for v in box), fill=fill)


def polygon(draw, points, fill):
    draw.polygon([(int(x * SCALE), int(y * SCALE)) for x, y in points], fill=fill)


def line(draw, points, fill, width):
    draw.line([(int(x * SCALE), int(y * SCALE)) for x, y in points], fill=fill, width=max(1, int(width * SCALE)))


def finish(image: Image.Image, size: int) -> Image.Image:
    return image.resize((size, size), Image.Resampling.LANCZOS)


def missile_frame(index: int, count: int = 11) -> Image.Image:
    size = 128
    t = index / (count - 1)
    rng = random.Random(9400)
    image, draw = canvas(size)
    cx, cy = 64.0, 60.0
    flash = max(0.0, 1.0 - abs(t - 0.16) / 0.22)
    smoke = max(0.0, (t - 0.18) / 0.82)
    radius = 5.0 + 42.0 * math.sin(min(1.0, t * 1.22) * math.pi * 0.58)
    for ray in range(11):
        angle = ray * math.tau / 11.0 + rng.uniform(-0.31, 0.31)
        length = radius * rng.uniform(0.78, 1.38) * (1.0 - 0.42 * smoke)
        inner = 4.0 + radius * 0.24
        p0 = (cx + math.cos(angle) * inner, cy + math.sin(angle) * inner)
        p1 = (cx + math.cos(angle) * length, cy + math.sin(angle) * length)
        line(draw, [p0, p1], (255, 184, 74, int(220 * (1.0 - t))), 1.25)
    lobe_count = 13
    for lobe in range(lobe_count):
        angle = rng.uniform(0.0, math.tau)
        distance = radius * rng.uniform(0.08, 0.78)
        lobe_r = radius * rng.uniform(0.23, 0.46)
        x = cx + math.cos(angle) * distance + smoke * 7.0
        y = cy + math.sin(angle) * distance - smoke * (7.0 + rng.uniform(0.0, 13.0))
        soot = int(64 + 34 * smoke + rng.uniform(-10, 10))
        alpha = int(235 * (1.0 - 0.58 * t))
        ellipse(draw, (x - lobe_r, y - lobe_r * 0.82, x + lobe_r, y + lobe_r * 0.82), (soot, soot - 8, soot - 18, alpha))
    fire_alpha = int(245 * max(0.0, 1.0 - t * 1.08))
    for fire_lobe in range(7):
        angle = rng.uniform(0.0, math.tau)
        distance = radius * rng.uniform(0.02, 0.48)
        lobe_r = radius * rng.uniform(0.20, 0.38) * max(0.15, 1.0 - t * 0.62)
        x = cx + math.cos(angle) * distance
        y = cy + math.sin(angle) * distance
        colour = (238, 94, 24, fire_alpha) if fire_lobe > 1 else (255, 176, 55, fire_alpha)
        ellipse(draw, (x-lobe_r, y-lobe_r*0.82, x+lobe_r, y+lobe_r*0.82), colour)
    hot = radius * max(0.0, 0.42 * (1.0 - t * 1.7))
    if hot > 0.5:
        ellipse(draw, (cx-hot*0.8, cy-hot, cx+hot, cy+hot*0.72), (255, 234, 166, int(255*flash)))
    if t < 0.34:
        ring = 8.0 + t * 170.0
        draw.ellipse(tuple(int(v * SCALE) for v in (cx-ring, cy-ring, cx+ring, cy+ring)), outline=(255, 220, 150, int(210*(1.0-t/0.34))), width=2*SCALE)
    for fragment in range(10):
        angle = fragment * math.tau / 10.0 + rng.uniform(-0.25, 0.25)
        distance = radius * rng.uniform(0.72, 1.45)
        x = cx + math.cos(angle) * distance
        y = cy + math.sin(angle) * distance
        line(draw, [(x, y), (x - math.cos(angle) * 5, y - math.sin(angle) * 5)], (220, 196, 148, int(230*(1.0-t))), 1.4)
    return finish(image, size)


def rocket_frame(index: int, count: int = 8) -> Image.Image:
    size = 128
    t = index / (count - 1)
    rng = random.Random(18400 + index)
    image, draw = canvas(size)
    cx, ground = 64.0, 91.0
    growth = math.sin(min(1.0, t * 1.15) * math.pi * 0.58)
    fade = 1.0 - 0.68 * t
    base_w = 10.0 + 45.0 * growth
    base_h = 4.0 + 14.0 * growth
    for lobe in range(13):
        x = cx + rng.uniform(-base_w, base_w)
        y = ground + rng.uniform(-base_h * 0.35, base_h * 0.45)
        r = rng.uniform(5.0, 13.0) * growth
        ellipse(draw, (x-r, y-r*0.55, x+r, y+r*0.55), (106, 82, 55, int(220*fade)))
    column_h = 8.0 + 53.0 * growth
    column_w = 7.0 + 22.0 * growth * (1.0 - 0.44*t)
    for lobe in range(9):
        y = ground - rng.uniform(0.15, 0.92) * column_h
        taper = max(0.32, (ground-y)/column_h)
        x = cx + rng.uniform(-column_w, column_w) * (1.05 - taper*0.46)
        r = rng.uniform(7.0, 15.0) * growth
        shade = rng.choice([(70,65,58),(86,75,62),(103,82,62)])
        ellipse(draw, (x-r, y-r, x+r, y+r), (*shade, int(230*fade)))
    flame_h = column_h * max(0.0, 1.0 - t*1.28)
    flame_w = column_w * max(0.12, 1.0 - t)
    polygon(draw, [(cx-flame_w,ground-3),(cx-flame_w*0.55,ground-flame_h*0.72),(cx,ground-flame_h),(cx+flame_w*0.62,ground-flame_h*0.65),(cx+flame_w,ground-2)], (232,91,24,int(250*fade)))
    polygon(draw, [(cx-flame_w*0.42,ground-4),(cx,ground-flame_h*0.76),(cx+flame_w*0.38,ground-4)], (255,224,130,int(255*max(0.0,1.0-t*1.2))))
    for fragment in range(14):
        direction = -1 if fragment % 2 == 0 else 1
        x = cx + direction * rng.uniform(10.0, 52.0) * growth
        y = ground - rng.uniform(2.0, 25.0) * growth
        line(draw, [(x,y),(x-direction*rng.uniform(3.0,8.0),y+rng.uniform(1.0,5.0))], (194,151,88,int(220*fade)), 1.4)
    return finish(image, size)


def cannon_frame(index: int, count: int = 6) -> Image.Image:
    size = 64
    t = index / (count - 1)
    rng = random.Random(29400 + index)
    image, draw = canvas(size)
    cx, cy = 32.0, 31.0
    fade = 1.0 - t
    ellipse(draw, (cx-7*(1-t),cy-6*(1-t),cx+7*(1-t),cy+6*(1-t)), (255,231,175,int(255*fade)))
    for spark in range(18):
        angle = rng.uniform(-2.75, 0.42)
        length = rng.uniform(9.0, 32.0) * (0.48 + t)
        start = rng.uniform(1.0, 5.0)
        p0 = (cx + math.cos(angle)*start, cy + math.sin(angle)*start)
        p1 = (cx + math.cos(angle)*length, cy + math.sin(angle)*length)
        colour = (255,235,177,int(245*fade)) if spark < 8 else (235,119,43,int(220*fade))
        line(draw,[p0,p1],colour,1.15 if spark < 8 else 1.7)
    for chip in range(6):
        x = cx + rng.uniform(-22,20)*(0.3+t)
        y = cy + rng.uniform(-15,18)*(0.3+t)
        polygon(draw,[(x-2,y),(x+2,y-1),(x+1,y+2)],(155,164,162,int(210*fade)))
    return finish(image, size)


def save_family(name: str, count: int, frame_builder) -> list[Image.Image]:
    frames = [frame_builder(index, count) for index in range(count)]
    source_dir = SOURCE / name
    runtime_dir = RUNTIME / name
    source_dir.mkdir(parents=True, exist_ok=True)
    runtime_dir.mkdir(parents=True, exist_ok=True)
    for index, frame in enumerate(frames):
        frame.save(source_dir / f"frame_{index:04d}.png", optimize=True)
        frame.save(runtime_dir / f"frame_{index:04d}.png", optimize=True)
    return frames


def main():
    families = {
        "missile": save_family("missile", 11, missile_frame),
        "rocket": save_family("rocket", 8, rocket_frame),
        "cannon": save_family("cannon", 6, cannon_frame),
    }
    review = Image.new("RGB", (704, 416), (8, 12, 16))
    y = 0
    for name in ["missile", "rocket", "cannon"]:
        frames = families[name]
        thumb = 64
        for index, frame in enumerate(frames):
            plate = Image.new("RGBA", frame.size, (8,12,16,255))
            plate.alpha_composite(frame)
            review.paste(plate.convert("RGB").resize((thumb,thumb)), (index*thumb,y))
        y += 144 if name != "cannon" else 128
    REVIEW.parent.mkdir(parents=True, exist_ok=True)
    review.save(REVIEW, optimize=True)
    manifest = {
        "asset_family": "hypersonic_weapon_explosion_cels_v2",
        "method": "deterministic offline cel authoring with retained transparent canvases",
        "families": {
            "missile": {"frames": 11, "size": [128,128], "motion": "flash-pressure-fireball-smoke-fragment"},
            "rocket": {"frames": 8, "size": [128,128], "motion": "ground-coupled-dirt-flame-column-fragment"},
            "cannon": {"frames": 6, "size": [64,64], "motion": "directional-hot-metal-spall"},
        },
        "rules": ["No full-screen bloom", "No circular particle rosette", "Smoke and debris outlive the hot core", "Ground bursts remain vertically biased"],
    }
    SOURCE.mkdir(parents=True, exist_ok=True)
    (SOURCE / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Built 25 weapon explosion cels and {REVIEW}")


if __name__ == "__main__":
    main()
