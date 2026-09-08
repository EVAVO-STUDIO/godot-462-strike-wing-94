#!/usr/bin/env python3
"""Build the registered cel-fog plate used while the VX-94 crosses a cloud deck."""

from __future__ import annotations

import json
import random
from hashlib import sha256
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/runtime/ui/hud/altitude_transition/atmospheric_veil.png"
SOURCE = ROOT / "assets/source/environments/altitude_transition_veil_v2"
WIDTH, HEIGHT, SEED = 624, 304, 94062


def noise_layer(rng: random.Random, columns: int, rows: int, blur: float) -> Image.Image:
    coarse = Image.new("L", (columns, rows))
    coarse.putdata([rng.randrange(18, 238) for _ in range(columns * rows)])
    return coarse.resize((WIDTH, HEIGHT), Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(blur))


def build() -> Image.Image:
    rng = random.Random(SEED)
    broad = noise_layer(rng, 9, 5, 13.0)
    detail = noise_layer(rng, 23, 12, 4.5)
    density = ImageChops.blend(broad, detail, 0.34)

    # Keep the fog as overlapping cel masses rather than a rectangular wipe.
    mask = Image.new("L", (WIDTH, HEIGHT), 0)
    pixels = mask.load()
    source = density.load()
    for y in range(HEIGHT):
        edge_y = min(1.0, y / 42.0, (HEIGHT - 1 - y) / 42.0)
        for x in range(WIDTH):
            edge_x = min(1.0, x / 54.0, (WIDTH - 1 - x) / 54.0)
            edge = max(0.0, min(edge_x, edge_y))
            shaped = max(0.0, (source[x, y] - 76) / 179.0) * edge
            pixels[x, y] = min(176, int(shaped * 176) // 16 * 16)

    image = Image.new("RGBA", (WIDTH, HEIGHT), (190, 211, 220, 0))
    image.putalpha(mask)
    return image


def main() -> int:
    image = build()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    SOURCE.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT, "PNG", optimize=True)
    digest = sha256(OUTPUT.read_bytes()).hexdigest()
    manifest = {
        "schema_version": 1,
        "asset": "altitude_transition_veil_v2",
        "seed": SEED,
        "geometry": [WIDTH, HEIGHT],
        "style": "irregular limited-alpha cel fog; no scanline or checkerboard content",
        "runtime": str(OUTPUT.relative_to(ROOT)).replace("\\", "/"),
        "sha256": digest,
    }
    (SOURCE / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"built {OUTPUT.relative_to(ROOT)} {digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
