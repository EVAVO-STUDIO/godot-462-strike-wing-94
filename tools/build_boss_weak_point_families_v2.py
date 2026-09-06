from pathlib import Path
from PIL import Image
import hashlib, json

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/runtime/enemies/boss_weak_point"
OUTPUT = SOURCE
MANIFEST_DIR = ROOT / "assets/source/enemies/boss_weak_point_v2"
COLORS = {
    "conventional": ((255, 166, 51), (255, 222, 126)),
    "machine": ((242, 61, 39), (255, 151, 71)),
    "orbital": ((63, 218, 255), (190, 250, 255)),
}

def recolor(source: Image.Image, base, highlight) -> Image.Image:
    result = Image.new("RGBA", source.size)
    pixels = []
    source_pixels = source.load()
    for y in range(source.height):
        for x in range(source.width):
            red, green, blue, alpha = source_pixels[x, y]
            intensity = max(red, green, blue) / 255.0
            hot = max(0.0, min(1.0, (intensity - 0.58) / 0.42))
            color = tuple(round(base[i] * (1.0-hot) + highlight[i] * hot) for i in range(3))
            pixels.append((*color, alpha))
    result.putdata(pixels)
    return result

MANIFEST_DIR.mkdir(parents=True, exist_ok=True)
records = []
for family, palette in COLORS.items():
    target_dir = OUTPUT / family
    target_dir.mkdir(parents=True, exist_ok=True)
    for frame in range(4):
        source_path = SOURCE / f"cue_{frame}.png"
        target_path = target_dir / f"cue_{frame}.png"
        recolor(Image.open(source_path).convert("RGBA"), *palette).save(target_path, optimize=True)
        records.append({
            "family": family,
            "frame": frame,
            "runtime": target_path.relative_to(ROOT).as_posix(),
            "sha256": hashlib.sha256(target_path.read_bytes()).hexdigest(),
        })

manifest = {
    "schema": "hypersonic_boss_weak_point_families_v2",
    "source": "assets/runtime/enemies/boss_weak_point/cue_0..3.png",
    "geometry": "18x18",
    "contract": "Conventional amber acquisition brackets, autonomous red-orange scan marks and BLACK SKY cyan aperture marks; final color baked into transparent runtime rasters.",
    "assets": records,
}
(MANIFEST_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
