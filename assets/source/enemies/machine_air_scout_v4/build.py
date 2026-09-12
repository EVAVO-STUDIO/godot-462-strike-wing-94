"""Build the compact machine-war reconnaissance delta and its held bank cels."""
from hashlib import sha256
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / "assets/source/enemies/machine_air_scout_v4"
RUNTIME = ROOT / "assets/runtime/enemies"
INK = (8, 15, 22, 255)
STEEL = (64, 78, 88, 255)
LIGHT = (138, 151, 153, 255)
PALE = (188, 190, 177, 255)
NAVY = (29, 47, 61, 255)
AMBER = (179, 107, 50, 255)
CYAN = (104, 210, 228, 255)
WHITE = (218, 244, 240, 255)

def polygon(draw, points, fill, outline=INK):
    draw.polygon(points, fill=fill)
    draw.line(points + [points[0]], fill=outline, width=1)

def build(bank):
    image = Image.new("RGBA", (24, 26), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    if bank == "level":
        polygon(d, [(1,15),(8,9),(10,8),(10,4),(12,2),(14,4),(14,8),(16,9),(23,15),(17,17),(15,16),(15,21),(12,24),(9,21),(9,16),(7,17)], STEEL)
        polygon(d, [(3,14),(9,10),(10,10),(9,15)], NAVY)
        polygon(d, [(21,14),(15,10),(14,10),(15,15)], LIGHT)
        d.line([(5,14),(9,13)], fill=PALE); d.line([(19,14),(15,13)], fill=PALE)
        d.rectangle((11,5,13,18), fill=PALE); d.line([(11,5),(12,3),(13,5)], fill=INK)
        d.rectangle((11,11,13,14), fill=NAVY); d.point((12,12), fill=WHITE); d.point((12,13), fill=CYAN)
        d.point((7,15), fill=AMBER); d.point((17,15), fill=AMBER)
        d.rectangle((11,19,13,22), fill=STEEL); d.point((12,23), fill=CYAN)
    else:
        lowered_left = bank == "left"
        broad = [(2,14),(9,9),(12,9),(13,14),(9,17)] if lowered_left else [(11,12),(15,10),(21,14),(16,16),(12,15)]
        narrow = [(11,12),(15,10),(20,13),(16,14),(12,14)] if lowered_left else [(3,15),(9,11),(12,11),(11,15),(8,16)]
        polygon(d, broad, LIGHT if lowered_left else STEEL)
        polygon(d, narrow, STEEL if lowered_left else LIGHT)
        polygon(d, [(10,4),(12,2),(14,5),(14,18),(12,24),(10,20)], PALE)
        d.rectangle((11,10,13,14), fill=NAVY); d.point((12,12), fill=WHITE); d.point((12,13), fill=CYAN)
        d.point((6 if lowered_left else 18,14), fill=AMBER)
        d.point((12,23), fill=CYAN)
    return image

outputs = {
    "level": RUNTIME / "machine_air/drone_scout_idle.png",
    "left": RUNTIME / "bank/drone_scout/left.png",
    "right": RUNTIME / "bank/drone_scout/right.png",
}
records = []
for pose, path in outputs.items():
    image = build(pose)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)
    source_path = SOURCE / f"drone_scout_{pose}.png"
    image.save(source_path, optimize=True)
    records.append({"pose": pose, "runtime": path.relative_to(ROOT).as_posix(), "size": list(image.size), "visible_bounds": list(image.getbbox()), "sha256": sha256(path.read_bytes()).hexdigest().upper()})
(SOURCE / "manifest.json").write_text(json.dumps({
    "asset_family": "machine_air_scout_v4",
    "status": "runtime_integrated",
    "identity": "compact unmanned reconnaissance delta derived from captured aerospace manufacture",
    "visual_contract": ["broad fixed-wing planform", "attack nose faces player", "localized sensor and exhaust light", "held coherent bank poses", "no humanoid silhouette"],
    "collision_policy": "existing eight-pixel gameplay radius remains authoritative",
    "outputs": records,
}, indent=2) + "\n", encoding="utf-8")
catalog_path = ROOT / "assets/source/enemies/machine_air_asset_manifest.json"
catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
catalog["status"] = "runtime_motion_v4"
catalog["scout_override"] = "res://assets/source/enemies/machine_air_scout_v4/manifest.json"
for entry in catalog["runtime"]:
    if entry["id"] == "drone_scout":
        entry["sha256"] = records[0]["sha256"]
catalog_path.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
print("Built machine scout level and two held bank poses.")
