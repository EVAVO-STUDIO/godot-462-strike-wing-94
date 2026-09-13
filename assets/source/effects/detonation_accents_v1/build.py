from pathlib import Path
import hashlib, json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
SOURCE = Path(__file__).resolve().parent
RUNTIME = ROOT / "assets/runtime/effects/detonation_accents"
RUNTIME.mkdir(parents=True, exist_ok=True)

def save(name, index, image):
    folder = RUNTIME / name
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / f"{index}.png"
    image.save(path, optimize=True)
    source_path = SOURCE / f"{name}_{index}.png"
    image.save(source_path, optimize=True)
    return {"family": name, "frame": index, "size": list(image.size),
            "runtime": path.relative_to(ROOT).as_posix(),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest().upper()}

outputs = []
flash_radii = [(3, 6), (6, 11), (9, 14), (11, 15)]
for i, (core, shell) in enumerate(flash_radii):
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    cx, cy = 15, 16
    d.ellipse((cx-shell, cy-shell//2, cx+shell, cy+shell//2), fill=(106, 45, 18, 150-i*28))
    d.ellipse((cx-core-2, cy-core//2, cx+core+2, cy+core//2), fill=(255, 130, 36, 230-i*25))
    d.ellipse((cx-core//2, cy-core//3, cx+core//2, cy+core//3), fill=(255, 242, 190, 255-i*24))
    if i < 3:
        d.polygon([(cx-2-shell,cy),(cx-5-shell,cy-1),(cx-9-shell,cy+1),(cx-4-shell,cy+2)], fill=(230,92,28,180-i*35))
    outputs.append(save("ignition_flash", i, im))

for i in range(4):
    im = Image.new("RGBA", (10, 10))
    d = ImageDraw.Draw(im)
    length = 5-i
    d.line((1, 8, 1+length, 8-length), fill=(75, 39, 22, 230-i*35), width=3)
    d.line((2, 7, 2+length, 7-length), fill=(255, 125, 34, 255-i*32), width=2)
    d.point((2+length, 7-length), fill=(255, 244, 185, 255-i*25))
    outputs.append(save("hot_fragment", i, im))

(SOURCE / "manifest.json").write_text(json.dumps({
    "asset_family": "detonation_accents_v1",
    "style": "registered late-90s pixel-cel ignition and incandescent metal",
    "contract": ["transparent RGBA", "no procedural circles", "no vector-line fragments", "deterministic four-exposure animation"],
    "outputs": outputs
}, indent=2) + "\n")
