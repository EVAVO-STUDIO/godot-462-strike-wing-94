"""Build the conventional ace interceptor and heavy bomber production cels."""
from hashlib import sha256
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / "assets/source/enemies/mercenary_air_heavy_v6"
RUNTIME = ROOT / "assets/runtime/enemies"
INK=(8,12,15,255); DARK=(25,34,38,255); STEEL=(57,70,72,255); MID=(105,116,110,255)
LIGHT=(184,188,169,255); TAN=(128,106,72,255); RED=(151,52,36,255); AMBER=(242,143,48,255); WHITE=(239,224,174,255)

def poly(d, pts, fill):
    d.polygon(pts, fill=fill); d.line(pts+[pts[0]], fill=INK, width=1)

def ace():
    im=Image.new("RGBA",(32,34),(0,0,0,0)); d=ImageDraw.Draw(im)
    poly(d,[(1,20),(4,13),(11,11),(13,5),(16,1),(19,5),(21,11),(28,13),(31,20),(25,22),(20,19),(20,27),(16,32),(12,27),(12,19),(7,22)],DARK)
    poly(d,[(3,19),(6,14),(13,12),(11,20),(6,21)],STEEL); poly(d,[(29,19),(26,14),(19,12),(21,20),(26,21)],MID)
    poly(d,[(13,7),(16,2),(19,7),(19,26),(16,32),(13,26)],LIGHT)
    d.polygon([(14,9),(16,5),(18,9),(18,14),(14,14)],fill=(38,75,89,255)); d.line([(14,9),(16,5),(18,9),(18,14),(14,14)],fill=INK,width=1)
    d.rectangle((6,17,9,19),fill=TAN,outline=INK); d.rectangle((23,17,26,19),fill=TAN,outline=INK)
    d.point((13,29),fill=AMBER); d.point((19,29),fill=AMBER); d.point((16,6),fill=WHITE)
    return im

def bomber():
    im=Image.new("RGBA",(50,42),(0,0,0,0)); d=ImageDraw.Draw(im)
    poly(d,[(2,25),(6,14),(17,11),(21,5),(25,2),(29,5),(33,11),(44,14),(48,25),(40,28),(31,24),(30,34),(25,40),(20,34),(19,24),(10,28)],DARK)
    poly(d,[(4,24),(8,15),(20,12),(17,25),(9,27)],STEEL); poly(d,[(46,24),(42,15),(30,12),(33,25),(41,27)],MID)
    poly(d,[(21,7),(25,2),(29,7),(30,33),(25,40),(20,33)],LIGHT)
    poly(d,[(13,14),(18,12),(17,23),(11,25)],TAN); poly(d,[(37,14),(32,12),(33,23),(39,25)],TAN)
    d.polygon([(23,9),(25,5),(27,9),(27,14),(23,14)],fill=(37,69,77,255)); d.line([(23,9),(25,5),(27,9),(27,14),(23,14)],fill=INK,width=1)
    d.rectangle((22,22,28,31),fill=DARK,outline=INK); d.line([(25,23),(25,30)],fill=AMBER)
    for x in (17,33): d.rectangle((x-2,12,x+2,16),fill=STEEL,outline=INK); d.point((x,35),fill=AMBER)
    d.point((25,6),fill=WHITE)
    return im

def bank(level,left):
    w,h=level.size; narrow=level.resize((round(w*.84),h),Image.Resampling.NEAREST); out=Image.new("RGBA",level.size,(0,0,0,0)); out.alpha_composite(narrow,((w-narrow.width)//2+(-2 if left else 2),0)); p=out.load()
    for y in range(h):
        for x in range(w):
            r,g,b,a=p[x,y]
            if a:
                lit=(x<w//2) if left else (x>w//2); k=1.14 if lit else .70
                p[x,y]=(min(255,int(r*k)),min(255,int(g*k)),min(255,int(b*k)),a)
    return out

def save(image,path): path.parent.mkdir(parents=True,exist_ok=True); image.save(path,optimize=True)

records=[]
for enemy_id,level in (("ace_interceptor",ace()),("heavy_bomber",bomber())):
    for pose,image in (("level",level),("left",bank(level,True)),("right",bank(level,False))):
        runtime=RUNTIME/(f"mercenary_air/{enemy_id}_idle.png" if pose=="level" else f"bank/{enemy_id}/{pose}.png")
        source=SOURCE/f"{enemy_id}_{pose}.png"; save(image,runtime); save(image,source)
        records.append({"id":enemy_id,"pose":pose,"runtime":runtime.relative_to(ROOT).as_posix(),"size":list(image.size),"visible_bounds":list(image.getbbox()),"sha256":sha256(runtime.read_bytes()).hexdigest().upper()})

# The interceptor's real high-speed state keeps the registered body and changes only exhaust intensity.
level=ace()
for i,colour in enumerate((RED,AMBER,WHITE,AMBER)):
    frame=level.copy(); d=ImageDraw.Draw(frame); d.point((13,30),fill=colour); d.point((19,30),fill=colour)
    save(frame,RUNTIME/f"unit_animation/ace_interceptor/thrust_{i}.png")

# The bomber bay animation modifies the ventral aperture on the authored airframe.
for name,height,flash in (("closed",1,False),("opening",3,False),("open",5,False),("fire",6,True)):
    frame=bomber(); d=ImageDraw.Draw(frame); d.rectangle((22,24,28,24+height),fill=INK); d.rectangle((24,25,26,max(25,23+height)),fill=AMBER if flash else STEEL)
    if flash: d.line([(25,30),(25,38)],fill=WHITE,width=2)
    save(frame,RUNTIME/f"air_specialist/heavy_bomber_bay_{name}.png")

manifest={"asset_family":"mercenary_air_heavy_v6","status":"runtime_integrated","identity":"late-1990s human military interceptor and bomber","visual_contract":["broad readable planforms","nose-down attack orientation","restrained gunmetal and warm service markings","coherent bank, thrust and bay cels","no alien, neon or ornamental silhouettes"],"collision_policy":"existing gameplay radii and hardpoint anchors remain authoritative","outputs":records}
(SOURCE/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")

catalog_path=ROOT/"assets/source/enemies/mercenary_air_asset_manifest.json"; catalog=json.loads(catalog_path.read_text(encoding="utf-8")); catalog["status"]="runtime_motion_v6"; catalog["v6_heavy_override"]="res://assets/source/enemies/mercenary_air_heavy_v6/manifest.json"
for entry in catalog["runtime"]:
    match=next((r for r in records if r["id"]==entry["id"] and r["pose"]=="level"),None)
    if match: entry["sha256"]=match["sha256"]
catalog_path.write_text(json.dumps(catalog,indent=2)+"\n",encoding="utf-8")
print("Built conventional interceptor and bomber production cels.")
