"""Build held-frame cel effects for battlefield rail and orbital support."""
from pathlib import Path
from PIL import Image, ImageDraw
import json, hashlib, random

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets/source/support/strike_cel_v3"
OUT = ROOT / "assets/runtime/support/battlefield/strike_cel_v3"
SRC.mkdir(parents=True, exist_ok=True)
OUT.mkdir(parents=True, exist_ok=True)


def beam(kind: str, frame: int) -> Image.Image:
    w, h = (28, 192)
    im = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(im)
    rng = random.Random(9400 + frame + (100 if kind == "orbital" else 0))
    if kind == "rail":
        d.rectangle((4, 0, 23, h), fill=(20, 92, 126, 32))
        d.rectangle((8, 0, 19, h), fill=(30, 173, 211, 92))
        d.rectangle((11, 0, 16, h), fill=(112, 227, 242, 210))
        d.rectangle((13, 0, 14, h), fill=(238, 255, 250, 255))
        for y in range(10 + frame * 3, h, 29):
            side = -1 if rng.random() < .5 else 1
            d.line((14, y, 14 + side * rng.randint(7, 12), y + rng.randint(5, 10)), fill=(79, 204, 231, 180), width=1)
    else:
        d.rectangle((2, 0, 25, h), fill=(96, 136, 161, 34))
        d.rectangle((7, 0, 20, h), fill=(154, 198, 211, 92))
        d.rectangle((11, 0, 16, h), fill=(218, 239, 226, 214))
        d.rectangle((13, 0, 14, h), fill=(255, 246, 190, 255))
        for y in range(8 + frame * 5, h, 31):
            d.rectangle((5, y, 22, y + 2), fill=(229, 188, 91, 190))
            d.rectangle((9, y + 3, 18, y + 4), fill=(245, 224, 153, 150))
    return im


def impact(kind: str, frame: int) -> Image.Image:
    size = 112 if kind == "orbital" else 96
    im = Image.new("RGBA", (size, size))
    d = ImageDraw.Draw(im)
    c = size // 2
    t = frame / 3.0
    if kind == "rail":
        palette = [(226,255,247,255),(93,220,239,230),(25,126,180,190)]
    else:
        palette = [(255,247,190,255),(255,174,67,235),(174,61,31,200)]
    outer = int(13 + 34 * t)
    inner = max(4, int(12 - 6 * t))
    d.ellipse((c-outer,c-outer//2,c+outer,c+outer//2), outline=palette[2], width=3)
    d.ellipse((c-outer+4,c-outer//2+2,c+outer-4,c+outer//2-2), outline=palette[1], width=2)
    d.ellipse((c-inner,c-inner,c+inner,c+inner), fill=palette[0])
    rng = random.Random(4620 + frame + (200 if kind == "orbital" else 0))
    spokes = 12 if kind == "orbital" else 8
    import math
    for i in range(spokes):
        a = math.tau * i / spokes + rng.uniform(-.11,.11)
        r0 = inner + 2
        r1 = int(outer * rng.uniform(.72,1.12))
        p0=(c+math.cos(a)*r0,c+math.sin(a)*r0)
        p1=(c+math.cos(a)*r1,c+math.sin(a)*r1)
        d.line((p0,p1), fill=palette[1], width=2 if frame < 2 else 1)
    if kind == "orbital":
        for _ in range(7):
            x=c+rng.randint(-outer,outer); y=c+rng.randint(-outer//2,outer//2)
            d.rectangle((x,y,x+2,y+2), fill=(82,67,54,210))
    return im


files=[]
for kind in ("rail", "orbital"):
    for frame in range(4):
        for name, image in ((f"{kind}_beam_{frame}.png", beam(kind, frame)), (f"{kind}_impact_{frame}.png", impact(kind, frame))):
            image.save(SRC/name, optimize=True)
            image.save(OUT/name, optimize=True)
            digest=hashlib.sha256((OUT/name).read_bytes()).hexdigest().upper()
            files.append({"path":str((OUT/name).relative_to(ROOT)).replace("\\","/"),"sha256":digest})
(SRC/"manifest.json").write_text(json.dumps({"schema":"hypersonic_support_strike_cel_v3","style":"held-frame late-90s military cel energy","files":files},indent=2)+"\n")
print(f"Built {len(files)} support-strike cel frames.")
