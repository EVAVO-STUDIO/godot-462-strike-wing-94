"""Assemble a review sheet for every canonical hostile runtime silhouette."""
from __future__ import annotations

import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/source/enemies/review/HYPERSONIC-combat-roster-runtime-contact-sheet.png"
enemies = json.loads((ROOT / "data/enemies.json").read_text(encoding="utf-8"))["enemies"]
runtime = ROOT / "assets/runtime/enemies"


def find_sprite(enemy_id: str) -> Path:
    matches = list(runtime.rglob(f"{enemy_id}_idle.png"))
    if not matches:
        matches = [p for p in runtime.rglob("*.png") if enemy_id in p.name or enemy_id in p.parts]
    preferred = [p for p in matches if "layered" not in p.parts and "bank" not in p.parts and "animation" not in p.parts]
    return (preferred or matches)[0]


cell_w, cell_h, cols = 190, 150, 5
rows = (len(enemies) + cols - 1) // cols
sheet = Image.new("RGB", (cell_w * cols, 42 + cell_h * rows), "#091015")
draw = ImageDraw.Draw(sheet)
font = ImageFont.load_default()
draw.text((14, 12), "HYPERSONIC // CANONICAL HOSTILE RUNTIME ART // 38 IDENTITIES", fill="#b7d2d6", font=font)

for index, enemy in enumerate(enemies):
    x, y = (index % cols) * cell_w, 42 + (index // cols) * cell_h
    draw.rectangle((x + 4, y + 4, x + cell_w - 5, y + cell_h - 5), fill="#101b20", outline="#31505a")
    sprite_path = find_sprite(enemy["id"])
    sprite = Image.open(sprite_path).convert("RGBA")
    scale = min(4, max(1, min(116 // sprite.width, 92 // sprite.height)))
    sprite = sprite.resize((sprite.width * scale, sprite.height * scale), Image.Resampling.NEAREST)
    px = x + (cell_w - sprite.width) // 2
    py = y + 15 + (92 - sprite.height) // 2
    sheet.alpha_composite(sprite, (px, py)) if sheet.mode == "RGBA" else sheet.paste(sprite, (px, py), sprite)
    label = enemy["id"].replace("_", " ").upper()
    draw.text((x + 10, y + 112), label, fill="#d7ded8", font=font)
    draw.text((x + 10, y + 128), f"{enemy['class'].upper()}  {sprite_path.parent.name}", fill="#77939a", font=font)

OUT.parent.mkdir(parents=True, exist_ok=True)
sheet.save(OUT)
print(OUT)
