"""Build coherent machine bomber and missile-node aircraft with held bank cels."""
from hashlib import sha256
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / "assets/source/enemies/machine_air_heavy_v4"
RUNTIME = ROOT / "assets/runtime/enemies"
INK=(8,15,22,255); DARK=(29,43,54,255); METAL=(60,73,81,255)
STEEL=(112,126,130,255); PALE=(177,181,174,255); AMBER=(175,100,45,255)
CYAN=(70,187,211,255); WHITE=(222,244,238,255)

def poly(draw, points, fill):
    draw.polygon(points,fill=fill); draw.line(points+[points[0]],fill=INK,width=1)

def bomber(pose):
    im=Image.new("RGBA",(44,38),(0,0,0,0)); d=ImageDraw.Draw(im)
    if pose=="level":
        poly(d,[(2,22),(9,14),(17,11),(22,3),(27,11),(35,14),(42,22),(34,23),(29,21),(27,31),(22,36),(17,31),(15,21),(10,23)],METAL)
        poly(d,[(4,21),(11,15),(18,13),(15,21),(9,23)],DARK)
        poly(d,[(40,21),(33,15),(26,13),(29,21),(35,23)],STEEL)
        d.line([(7,20),(17,16)],fill=PALE); d.line([(37,20),(27,16)],fill=PALE)
    elif pose=="left":
        poly(d,[(2,23),(10,13),(23,11),(24,19),(15,26),(7,26)],STEEL)
        poly(d,[(22,14),(31,14),(41,20),(35,23),(25,21)],METAL)
    else:
        poly(d,[(3,20),(13,14),(22,14),(19,21),(9,23)],METAL)
        poly(d,[(21,11),(34,13),(42,23),(37,26),(29,26),(20,19)],STEEL)
    poly(d,[(18,11),(22,3),(26,11),(27,29),(22,36),(17,29)],PALE)
    d.rectangle((19,15,25,20),fill=DARK); d.rectangle((21,16,23,18),fill=CYAN); d.point((22,16),fill=WHITE)
    d.rectangle((18,23,26,29),fill=METAL); d.line([(19,25),(25,25)],fill=INK)
    d.point((13 if pose!="right" else 32,22),fill=AMBER); d.point((31 if pose!="left" else 12,22),fill=AMBER)
    d.point((19,31),fill=CYAN); d.point((25,31),fill=CYAN)
    return im

def missile_node(pose):
    im=Image.new("RGBA",(38,36),(0,0,0,0)); d=ImageDraw.Draw(im)
    if pose=="level":
        poly(d,[(2,18),(7,10),(14,9),(19,3),(24,9),(31,10),(36,18),(31,25),(24,25),(19,33),(14,25),(7,25)],METAL)
        poly(d,[(4,18),(8,11),(15,11),(13,24),(7,23)],DARK)
        poly(d,[(34,18),(30,11),(23,11),(25,24),(31,23)],STEEL)
    elif pose=="left":
        poly(d,[(2,20),(8,9),(19,9),(20,18),(13,27),(6,25)],STEEL)
        poly(d,[(18,12),(27,10),(36,17),(31,23),(21,21)],METAL)
    else:
        poly(d,[(2,17),(11,10),(20,12),(17,21),(7,23)],METAL)
        poly(d,[(19,9),(30,9),(36,20),(32,25),(25,27),(18,18)],STEEL)
    poly(d,[(15,10),(19,3),(23,10),(24,26),(19,33),(14,26)],PALE)
    # Four attached launcher coffins remain legible beneath the live hatch cels.
    for x,y in [(7,12),(27,12),(7,21),(27,21)]:
        d.rectangle((x,y,x+4,y+6),fill=DARK,outline=INK); d.line([(x+1,y+1),(x+3,y+1)],fill=AMBER)
    d.rectangle((16,14,22,20),fill=DARK); d.rectangle((18,15,20,18),fill=CYAN); d.point((19,15),fill=WHITE)
    d.point((16,28),fill=CYAN); d.point((22,28),fill=CYAN)
    return im

families={
    "drone_bomber":{"size":[44,38],"factory":bomber,"collision":"existing fourteen-pixel gameplay radius remains authoritative"},
    "drone_missile_node":{"size":[38,36],"factory":missile_node,"collision":"existing thirteen-pixel gameplay radius remains authoritative"},
}
records=[]
for enemy_id,data in families.items():
    for pose in ["level","left","right"]:
        image=data["factory"](pose)
        runtime=RUNTIME/(f"machine_air/{enemy_id}_idle.png" if pose=="level" else f"bank/{enemy_id}/{pose}.png")
        runtime.parent.mkdir(parents=True,exist_ok=True); image.save(runtime,optimize=True)
        source=SOURCE/f"{enemy_id}_{pose}.png"; image.save(source,optimize=True)
        records.append({"id":enemy_id,"pose":pose,"runtime":runtime.relative_to(ROOT).as_posix(),"size":list(image.size),"visible_bounds":list(image.getbbox()),"sha256":sha256(runtime.read_bytes()).hexdigest().upper()})
(SOURCE/"manifest.json").write_text(json.dumps({
    "asset_family":"machine_air_heavy_v4","status":"runtime_integrated",
    "visual_contract":["captured human aerospace ancestry","broad fixed-wing planforms","physically connected bays and launcher coffins","localized sensor and exhaust emission","coherent held bank poses","no humanoid silhouettes"],
    "identities":{"drone_bomber":"heavy unmanned flying-wing strike aircraft","drone_missile_node":"four-coffin autonomous arsenal aircraft"},
    "collision_policy":{key:value["collision"] for key,value in families.items()},"outputs":records,
},indent=2)+"\n",encoding="utf-8")
catalog_path=ROOT/"assets/source/enemies/machine_air_asset_manifest.json"
catalog=json.loads(catalog_path.read_text(encoding="utf-8")); catalog["status"]="runtime_motion_v4"
catalog["heavy_override"]="res://assets/source/enemies/machine_air_heavy_v4/manifest.json"
for entry in catalog["runtime"]:
    match=next((record for record in records if record["id"]==entry["id"] and record["pose"]=="level"),None)
    if match: entry["sha256"]=match["sha256"]
catalog_path.write_text(json.dumps(catalog,indent=2)+"\n",encoding="utf-8")
print("Built machine bomber and missile-node level/bank poses.")
