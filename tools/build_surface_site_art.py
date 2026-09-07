#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw
import json

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
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(7,12,41,40)); rect(d,(8,9,39,38),"dark"); rect(d,(11,12,36,35),"tan")
    d.ellipse((14,15,33,34),fill=PAL["outline"]); d.ellipse((16,17,31,32),fill=PAL["metal"]); line(d,(16,24,31,24),"light",2)
    rect(d,(7,17,11,30),"olive"); rect(d,(36,17,40,30),"olive"); rect(d,(20,8,27,12),"red")
    return im

def scud():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(5,14,43,41)); rect(d,(8,16,39,38),"olive"); rect(d,(5,19,13,35),"dark"); rect(d,(34,19,42,35),"dark")
    rect(d,(12,17,35,34),"tan"); d.polygon([(15,17),(20,7),(30,7),(35,17)],fill=PAL["dark"],outline=PAL["outline"])
    d.polygon([(20,26),(22,7),(27,3),(30,7),(29,27)],fill=PAL["light"],outline=PAL["outline"]); rect(d,(20,25,30,30),"red")
    return im

def artillery():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(6,15,42,41)); d.ellipse((7,23,19,39),fill=PAL["dark"],outline=PAL["outline"]); d.ellipse((29,23,41,39),fill=PAL["dark"],outline=PAL["outline"])
    rect(d,(13,20,35,35),"olive"); d.ellipse((17,16,31,30),fill=PAL["tan"],outline=PAL["outline"]); line(d,(24,18,24,3),"outline",5); line(d,(24,18,24,3),"metal",3); rect(d,(9,34,39,38),"dark")
    return im

def radar():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(6,20,42,42)); rect(d,(8,23,40,39),"olive"); rect(d,(18,14,29,29),"metal"); line(d,(23,16,23,8),"light",2)
    d.arc((8,3,38,24),195,345,fill=PAL["outline"],width=4); d.arc((10,5,36,22),195,345,fill=PAL["light"],width=2); line(d,(14,15,33,8),"metal",2)
    rect(d,(6,27,11,36),"dark"); rect(d,(37,27,42,36),"dark"); return im

def logistics():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(5,13,43,41)); rect(d,(7,13,40,37),"olive"); rect(d,(10,16,26,34),"tan"); rect(d,(27,16,39,34),"dark"); rect(d,(29,18,37,24),"glass")
    for x in (10,22,34): d.ellipse((x-4,32,x+4,40),fill=PAL["outline"]); d.ellipse((x-2,34,x+2,38),fill=PAL["metal"])
    line(d,(12,19,24,19),"edge",2); return im

def ammo_depot():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(4,12,44,42)); rect(d,(6,13,42,39),"dark"); rect(d,(9,16,39,37),"olive")
    for x,y in ((12,18),(23,18),(12,27),(23,27)): rect(d,(x,y,x+8,y+6),"tan")
    d.polygon([(34,20),(38,27),(30,27)],fill=PAL["yellow"],outline=PAL["outline"]); line(d,(34,22,34,25),"outline",1); return im

def village():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(3,12,45,43));
    rect(d,(5,20,22,39),"civil"); d.polygon([(3,21),(13,11),(24,21)],fill=PAL["roof"],outline=PAL["outline"]); rect(d,(10,27,16,39),"dark"); rect(d,(17,24,21,29),"glass")
    rect(d,(26,18,43,39),"light"); d.polygon([(24,19),(34,9),(45,19)],fill=PAL["roof"],outline=PAL["outline"]); rect(d,(31,27,37,39),"dark"); rect(d,(27,22,31,27),"glass")
    return im

def clinic():
    im=canvas(); d=ImageDraw.Draw(im); shadow(d,(4,12,44,43)); rect(d,(6,14,42,40),"white"); rect(d,(9,18,39,38),"civil"); rect(d,(18,24,30,40),"dark")
    rect(d,(20,15,28,30),"red",None); rect(d,(16,19,32,26),"red",None); line(d,(8,33,40,33),"light",2); return im

ASSETS={"strategic_silo":silo,"ballistic_launcher":scud,"field_artillery":artillery,"radar_site":radar,"logistics_truck":logistics,"ammo_depot":ammo_depot,"civilian_village":village,"field_clinic":clinic}
OUT.mkdir(parents=True,exist_ok=True); SRC.mkdir(parents=True,exist_ok=True)
for name,fn in ASSETS.items(): fn().save(OUT/f"{name}.png")

# Held mechanical cels keep late-90s pixel clarity while making installations
# feel operated rather than pasted onto the terrain.
ANIM = OUT / "animation"
(ANIM / "radar_site").mkdir(parents=True, exist_ok=True)
(ANIM / "field_artillery").mkdir(parents=True, exist_ok=True)
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
(SRC/"manifest.json").write_text(json.dumps({"schema_version":3,"identity":"believable late-1990s imagined-future military pixel art","canvas":[48,48],"military":["strategic_silo","ballistic_launcher","field_artillery","radar_site","logistics_truck","ammo_depot"],"protected":["civilian_village","field_clinic"],"animation":{"radar_site":{"frames":4,"fps":3.0},"field_artillery":{"frames":2,"trigger":"recoil_timer"},"damage":{"frames":2,"thresholds":[0.62,0.32]}},"rules":["red-cross clinic and slate-roof homes are protected contacts","military silhouettes remain readable at native 640x360 gameplay scale","surface sites are separate from the established 38-enemy identity roster","mechanical motion uses held nearest-neighbour cels","damaged sites use registered breach overlays before persistent smoke and fire"]},indent=2)+"\n",encoding="utf-8")
print(f"built {len(ASSETS)} surface-site sprites")
