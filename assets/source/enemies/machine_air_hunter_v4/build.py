"""Build the machine-war hunter interceptor and coherent held bank cels."""
from hashlib import sha256
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / "assets/source/enemies/machine_air_hunter_v4"
RUNTIME = ROOT / "assets/runtime/enemies"
INK = (8, 15, 22, 255)
GUNMETAL = (54, 67, 77, 255)
NAVY = (26, 43, 57, 255)
STEEL = (117, 132, 137, 255)
PALE = (184, 188, 180, 255)
AMBER = (177, 101, 47, 255)
CYAN = (72, 184, 211, 255)
WHITE = (221, 245, 239, 255)

def poly(draw, points, fill):
    draw.polygon(points, fill=fill)
    draw.line(points + [points[0]], fill=INK, width=1)

def level():
    image = Image.new("RGBA", (30, 30), (0, 0, 0, 0)); d = ImageDraw.Draw(image)
    # Broad cranked-delta shoulder with two captured-airframe engine booms.
    poly(d, [(2,16),(8,10),(12,9),(15,3),(18,9),(22,10),(28,16),(22,18),(18,17),(18,23),(15,28),(12,23),(12,17),(8,18)], GUNMETAL)
    poly(d, [(4,15),(9,11),(13,11),(11,16),(7,17)], NAVY)
    poly(d, [(26,15),(21,11),(17,11),(19,16),(23,17)], STEEL)
    d.line([(5,15),(11,13)], fill=PALE); d.line([(25,15),(19,13)], fill=PALE)
    poly(d, [(13,8),(15,3),(17,8),(17,22),(15,28),(13,22)], PALE)
    d.rectangle((13,13,17,17), fill=NAVY); d.rectangle((14,14,16,16), fill=CYAN); d.point((15,14), fill=WHITE)
    d.rectangle((9,17,12,23), fill=GUNMETAL); d.rectangle((18,17,21,23), fill=STEEL)
    d.point((10,23), fill=CYAN); d.point((20,23), fill=CYAN)
    d.point((7,16), fill=AMBER); d.point((23,16), fill=AMBER)
    return image

def bank(left):
    image = Image.new("RGBA", (30, 30), (0, 0, 0, 0)); d = ImageDraw.Draw(image)
    if left:
        poly(d, [(2,17),(8,10),(14,9),(15,15),(10,20),(5,19)], STEEL)
        poly(d, [(14,11),(19,10),(27,15),(22,17),(16,16)], GUNMETAL)
    else:
        poly(d, [(3,15),(11,10),(16,11),(14,16),(8,17)], GUNMETAL)
        poly(d, [(16,9),(22,10),(28,17),(25,19),(20,20),(15,15)], STEEL)
    poly(d, [(13,7),(15,3),(17,8),(17,22),(15,28),(13,22)], PALE)
    d.rectangle((13,13,17,17), fill=NAVY); d.rectangle((14,14,16,16), fill=CYAN); d.point((15,14), fill=WHITE)
    d.rectangle((9 if left else 18,17,12 if left else 21,23), fill=GUNMETAL)
    d.point((10 if left else 20,23), fill=CYAN)
    d.point((6 if left else 24,17), fill=AMBER)
    return image

outputs = {
    "level": (level(), RUNTIME / "machine_air/drone_hunter_idle.png"),
    "left": (bank(True), RUNTIME / "bank/drone_hunter/left.png"),
    "right": (bank(False), RUNTIME / "bank/drone_hunter/right.png"),
}
records = []
for pose, (image, path) in outputs.items():
    path.parent.mkdir(parents=True, exist_ok=True); image.save(path, optimize=True)
    source_path = SOURCE / f"drone_hunter_{pose}.png"; image.save(source_path, optimize=True)
    records.append({"pose":pose,"runtime":path.relative_to(ROOT).as_posix(),"size":list(image.size),"visible_bounds":list(image.getbbox()),"sha256":sha256(path.read_bytes()).hexdigest().upper()})
(SOURCE / "manifest.json").write_text(json.dumps({
    "asset_family":"machine_air_hunter_v4","status":"runtime_integrated",
    "identity":"twin-boom autonomous interceptor descended from captured human aerospace tooling",
    "visual_contract":["broad cranked-delta planform","attack nose faces player","physically attached twin engine booms","localized core and exhaust light","coherent held bank poses","no humanoid silhouette"],
    "collision_policy":"existing ten-pixel gameplay radius remains authoritative","outputs":records,
},indent=2)+"\n",encoding="utf-8")
catalog_path = ROOT / "assets/source/enemies/machine_air_asset_manifest.json"
catalog = json.loads(catalog_path.read_text(encoding="utf-8")); catalog["status"] = "runtime_motion_v4"
catalog["hunter_override"] = "res://assets/source/enemies/machine_air_hunter_v4/manifest.json"
for entry in catalog["runtime"]:
    if entry["id"] == "drone_hunter": entry["sha256"] = records[0]["sha256"]
catalog_path.write_text(json.dumps(catalog,indent=2)+"\n",encoding="utf-8")
print("Built machine hunter level and two held bank poses.")
