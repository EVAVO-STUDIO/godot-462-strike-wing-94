#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw
import json
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/runtime/surface_sites"
SRC = ROOT / "assets/source/surface_sites/mercenary_war_v1"
S = 48

PAL = {
    "outline": (15, 20, 20, 255), "shadow": (27, 31, 28, 180),
    "dark": (47, 54, 47, 255), "olive": (78, 83, 59, 255),
    "tan": (128, 117, 79, 255), "edge": (181, 164, 109, 255),
    "metal": (104, 111, 105, 255), "light": (191, 199, 183, 255),
    "red": (154, 50, 36, 255), "white": (224, 220, 197, 255),
    "civil": (123, 132, 127, 255), "roof": (92, 70, 58, 255),
    "glass": (72, 113, 124, 255), "yellow": (215, 180, 68, 255),
}

def canvas(): return Image.new("RGBA", (S, S), (0, 0, 0, 0))
def shadow(d, box): d.ellipse(box, fill=PAL["shadow"])
def rect(d, box, fill, outline="outline", w=1): d.rectangle(box, fill=PAL[fill], outline=PAL[outline] if outline else None, width=w)
def line(d, pts, fill="edge", w=1): d.line(pts, fill=PAL[fill], width=w)

def silo():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(5,17,44,43))
    d.polygon([(8,12),(37,10),(43,18),(40,38),(11,41),(5,32)],fill=PAL["dark"],outline=PAL["outline"])
    d.polygon([(10,14),(35,12),(40,19),(37,36),(13,38),(8,31)],fill=PAL["tan"],outline=PAL["edge"])
    d.ellipse((13,14,36,37),fill=PAL["outline"]); d.ellipse((16,17,33,34),fill=PAL["metal"]); d.ellipse((19,20,30,31),fill=PAL["dark"])
    line(d,(17,24,32,24),"light",2); line(d,(24,18,24,33),"light",1); rect(d,(7,20,11,29),"olive"); rect(d,(37,19,41,28),"olive"); rect(d,(20,10,27,13),"red")
    return im

def scud():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(7,9,41,44))
    rect(d,(11,6,36,41),"dark"); rect(d,(14,8,33,39),"olive"); rect(d,(15,29,32,38),"tan")
    for y in (11,20,31,38): rect(d,(8,y,13,y+4),"outline",None); rect(d,(34,y,39,y+4),"outline",None)
    d.polygon([(20,31),(20,8),(24,3),(28,8),(28,31)],fill=PAL["light"],outline=PAL["outline"])
    line(d,(22,9,26,9),"white",1); rect(d,(19,29,29,33),"red"); rect(d,(17,34,30,38),"dark")
    return im

def ballistic_pose(angle_degrees):
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(7,8,41,44)); rect(d,(11,9,36,41),"dark"); rect(d,(14,11,33,39),"olive")
    for y in (13,25,35): rect(d,(8,y,13,y+4),"outline",None); rect(d,(34,y,39,y+4),"outline",None)
    rect(d,(16,30,31,38),"tan"); line(d,(18,32,29,32),"edge",1)
    angle=math.radians(angle_degrees); base=(24,30); tip=(base[0]+math.cos(angle)*24, base[1]-math.sin(angle)*24)
    line(d,(base,tip),"outline",7); line(d,(base,tip),"light",4)
    nx,ny=math.cos(angle),-math.sin(angle); px,py=-ny,nx
    d.polygon([(tip[0]+nx*4,tip[1]+ny*4),(tip[0]-nx*3+px*3,tip[1]-ny*3+py*3),(tip[0]-nx*3-px*3,tip[1]-ny*3-py*3)],fill=PAL["light"],outline=PAL["outline"])
    line(d,((base[0]-px*5,base[1]-py*5),(base[0]+px*5,base[1]+py*5)),"red",3)
    return im

def artillery():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(5,17,43,43))
    d.polygon([(8,34),(18,25),(30,25),(40,34),(36,39),(27,32),(21,32),(12,39)],fill=PAL["dark"],outline=PAL["outline"])
    d.ellipse((15,20,33,36),fill=PAL["outline"]); d.ellipse((18,22,30,33),fill=PAL["tan"]); d.ellipse((21,25,27,31),fill=PAL["olive"])
    line(d,(24,27,24,3),"outline",6); line(d,(24,27,24,4),"metal",3); line(d,(25,6,25,22),"light",1); rect(d,(10,35,15,40),"olive"); rect(d,(33,35,38,40),"olive")
    return im

def radar():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(6,14,43,43)); rect(d,(10,18,38,40),"dark"); rect(d,(13,20,35,37),"olive")
    rect(d,(7,23,12,35),"outline",None); rect(d,(36,23,41,35),"outline",None); rect(d,(17,28,31,36),"tan")
    d.ellipse((11,5,37,25),fill=PAL["outline"]); d.pieslice((13,7,35,23),180,360,fill=PAL["light"]); d.pieslice((16,10,32,22),180,360,fill=PAL["glass"])
    line(d,(24,18,24,29),"metal",3); line(d,(14,16,34,16),"edge",1); rect(d,(22,4,26,8),"red"); return im

def logistics():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(8,5,40,44)); rect(d,(11,5,36,42),"dark"); rect(d,(14,8,33,39),"olive")
    rect(d,(15,9,32,27),"tan"); line(d,(18,11,18,25),"edge",1); line(d,(28,11,28,25),"edge",1)
    rect(d,(15,29,32,38),"dark"); rect(d,(17,30,30,34),"glass"); line(d,(23,30,23,35),"light",1)
    for y in (10,22,34): rect(d,(8,y,13,y+5),"outline",None); rect(d,(34,y,39,y+5),"outline",None)
    return im

def ammo_depot():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(4,11,45,43))
    d.polygon([(6,12),(42,12),(45,21),(42,40),(6,40),(3,30)],fill=PAL["dark"],outline=PAL["outline"])
    for x,y in ((9,16),(21,16),(9,27),(21,27)): rect(d,(x,y,x+9,y+7),"olive"); line(d,(x+2,y+2,x+7,y+2),"edge",1)
    d.polygon([(36,19),(41,28),(31,28)],fill=PAL["yellow"],outline=PAL["outline"]); line(d,(36,21,36,25),"outline",1); rect(d,(35,27,37,28),"outline",None)
    return im

def village():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(3,10,46,44))
    d.polygon([(5,10),(23,8),(25,27),(7,30)],fill=PAL["outline"]); d.polygon([(8,12),(20,11),(22,24),(9,27)],fill=PAL["roof"]); line(d,(15,11,16,25),"civil",2)
    d.polygon([(25,15),(43,12),(45,35),(27,39)],fill=PAL["outline"]); d.polygon([(28,17),(40,15),(42,32),(29,36)],fill=PAL["civil"]); line(d,(34,16,35,34),"light",2)
    rect(d,(10,30,16,36),"dark"); rect(d,(20,29,24,33),"glass"); rect(d,(39,35,43,39),"dark")
    return im

def clinic():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(5,9,44,44))
    d.polygon([(7,10),(39,8),(43,38),(10,42)],fill=PAL["outline"]); d.polygon([(10,13),(36,11),(39,35),(12,38)],fill=PAL["white"])
    line(d,(12,18,37,16),"civil",1); line(d,(14,34,38,31),"civil",1)
    d.polygon([(21,16),(28,15),(29,22),(35,21),(36,28),(29,29),(30,35),(23,36),(22,29),(16,30),(15,23),(22,22)],fill=PAL["red"],outline=PAL["outline"])
    rect(d,(8,31,13,39),"civil"); rect(d,(37,27,42,36),"civil"); return im

ASSETS={"strategic_silo":silo,"ballistic_launcher":scud,"field_artillery":artillery,"radar_site":radar,"logistics_truck":logistics,"ammo_depot":ammo_depot,"civilian_village":village,"field_clinic":clinic}
OUT.mkdir(parents=True,exist_ok=True); SRC.mkdir(parents=True,exist_ok=True)
for name,fn in ASSETS.items(): fn().save(OUT/f"{name}.png")

# Held mechanical cels keep late-90s pixel clarity while making installations
# feel operated rather than pasted onto the terrain.
ANIM = OUT / "animation"
(ANIM / "radar_site").mkdir(parents=True, exist_ok=True)
(ANIM / "field_artillery").mkdir(parents=True, exist_ok=True)
(ANIM / "ballistic_launcher").mkdir(parents=True, exist_ok=True)
(ANIM / "damage").mkdir(parents=True, exist_ok=True)
radar_base = radar()
for index, angle in enumerate((-18, -6, 6, 18)):
    frame = radar_base.copy()
    # Replace the antenna head with a nearest-neighbour rotated mechanical cel.
    ImageDraw.Draw(frame).rectangle((5, 0, 42, 23), fill=(0, 0, 0, 0))
    head = radar_base.crop((5, 0, 43, 24)).rotate(angle, resample=Image.Resampling.NEAREST, center=(18, 17))
    frame.alpha_composite(head, (5, 0))
    frame.save(ANIM / "radar_site" / f"{index}.png")
artillery_base = artillery()
artillery_base.save(ANIM / "field_artillery" / "0.png")
recoil = artillery_base.copy()
ImageDraw.Draw(recoil).rectangle((18, 0, 30, 25), fill=(0, 0, 0, 0))
barrel = artillery_base.crop((18, 0, 31, 26))
recoil.alpha_composite(barrel, (18, 4))
recoil.save(ANIM / "field_artillery" / "1.png")
for index, angle in enumerate((8, 42, 78)):
    ballistic_pose(angle).save(ANIM / "ballistic_launcher" / f"{index}.png")
for index in range(2):
    damage = canvas(); dd = ImageDraw.Draw(damage)
    if index == 0:
        dd.polygon([(11,19),(17,15),(21,20),(27,14),(34,19),(30,25),(36,31),(27,30),(22,36),(18,29),(10,31),(15,24)], fill=(37,31,25,150))
        line(dd, [(13,20),(20,24),(17,31)], "outline", 2); line(dd, [(28,16),(25,24),(34,29)], "red", 2)
    else:
        dd.polygon([(7,16),(15,11),(21,17),(28,9),(39,17),(34,25),(42,31),(31,35),(24,42),(17,34),(6,37),(12,26)], fill=(24,24,22,205))
        line(dd, [(10,17),(20,23),(14,34)], "outline", 3); line(dd, [(31,12),(25,24),(38,31)], "red", 3)
        dd.rectangle((20,21,27,28), fill=(217,102,38,180)); dd.rectangle((22,23,25,27), fill=(255,201,74,220))
    damage.save(ANIM / "damage" / f"{index}.png")
sheet=Image.new("RGBA",(S*4,S*2),(18,23,22,255))
for i,(name,fn) in enumerate(ASSETS.items()): sheet.alpha_composite(fn(),((i%4)*S,(i//4)*S))
sheet.save(SRC/"surface_site_contact_sheet.png")
(SRC/"manifest.json").write_text(json.dumps({"schema_version":4,"identity":"believable late-1990s imagined-future military pixel art","canvas":[48,48],"military":["strategic_silo","ballistic_launcher","field_artillery","radar_site","logistics_truck","ammo_depot"],"protected":["civilian_village","field_clinic"],"animation":{"radar_site":{"frames":4,"fps":3.0},"field_artillery":{"frames":2,"trigger":"recoil_timer"},"ballistic_launcher":{"frames":3,"sequence":"stowed_rising_deployed"},"damage":{"frames":2,"thresholds":[0.62,0.32]}},"rules":["red-cross clinic and slate-roof homes are protected contacts","military silhouettes remain readable at native 640x360 gameplay scale","surface sites are separate from the established 38-enemy identity roster","mechanical motion uses held nearest-neighbour cels","damaged sites use registered breach overlays before persistent smoke and fire"]},indent=2)+"\n",encoding="utf-8")
print(f"built {len(ASSETS)} surface-site sprites")
