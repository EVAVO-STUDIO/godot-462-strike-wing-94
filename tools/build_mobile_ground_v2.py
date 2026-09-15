from pathlib import Path
from PIL import Image, ImageDraw
import hashlib, json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/runtime/enemies/mobile_ground_layered"
SRC = ROOT / "assets/source/enemies/mobile_ground_v2"

P = {
    "outline": (20, 25, 26, 255), "track": (38, 42, 40, 255),
    "track_hi": (102, 105, 91, 255), "dark": (55, 61, 58, 255),
    "armor": (139, 132, 105, 255), "armor_hi": (184, 172, 132, 255),
    "armor_lo": (94, 91, 75, 255), "red": (143, 55, 38, 255),
    "glass": (48, 79, 82, 255), "metal": (113, 119, 110, 255),
    "rubber": (30, 33, 32, 255), "scorch": (34, 30, 27, 210),
    "hot": (226, 121, 43, 255), "missile": (205, 198, 169, 255),
}

def img(size): return Image.new("RGBA", size, (0, 0, 0, 0))
def poly(d, xy, fill, outline=P["outline"]): d.polygon(xy, fill=fill, outline=outline)
def rect(d, xy, fill, outline=None): d.rectangle(xy, fill=fill, outline=outline)
def line(d, xy, fill, width=1): d.line(xy, fill=fill, width=width)

def tank_base(frame=0):
    im=img((36,44)); d=ImageDraw.Draw(im)
    rect(d,(2,5,7,38),P["track"],P["outline"]); rect(d,(28,5,33,38),P["track"],P["outline"])
    for y in range(7+frame%3,38,5):
        line(d,(3,y,6,y),P["track_hi"]); line(d,(29,y,32,y),P["track_hi"])
    poly(d,[(8,3),(27,3),(30,10),(29,35),(25,41),(10,41),(6,35),(6,10)],P["armor"])
    rect(d,(10,5,25,10),P["armor_hi"]); rect(d,(9,31,26,38),P["armor_lo"])
    line(d,(8,14,27,14),P["armor_hi"]); line(d,(9,29,26,29),P["outline"])
    rect(d,(8,17,11,25),P["red"]); rect(d,(24,17,27,25),P["red"])
    d.ellipse((12,14,23,25),fill=P["outline"]); d.ellipse((14,16,21,23),fill=P["dark"])
    rect(d,(12,34,23,36),P["metal"]); return im

def sam_base(frame=0):
    im=img((32,46)); d=ImageDraw.Draw(im)
    for y in (6,16,29,39):
        rect(d,(1,y,5,y+5),P["rubber"],P["outline"]); rect(d,(26,y,30,y+5),P["rubber"],P["outline"])
        if (y+frame)%2: rect(d,(2,y+1,4,y+2),P["track_hi"]); rect(d,(27,y+1,29,y+2),P["track_hi"])
    poly(d,[(7,2),(24,2),(27,8),(26,41),(22,44),(9,44),(5,40),(5,8)],P["armor"])
    rect(d,(8,4,23,12),P["armor_hi"]); rect(d,(9,5,14,8),P["glass"]); rect(d,(17,5,22,8),P["glass"])
    rect(d,(8,15,23,35),P["armor_lo"],P["outline"]); line(d,(15,15,15,35),P["outline"])
    rect(d,(7,37,24,41),P["dark"]); rect(d,(6,24,8,30),P["red"])
    d.ellipse((11,19,20,28),fill=P["outline"]); d.ellipse((13,21,18,26),fill=P["dark"]); return im

def aa_base(frame=0):
    im=img((40,46)); d=ImageDraw.Draw(im)
    rect(d,(2,4,8,41),P["track"],P["outline"]); rect(d,(31,4,37,41),P["track"],P["outline"])
    for y in range(6+frame%3,41,5):
        line(d,(3,y,7,y),P["track_hi"]); line(d,(32,y,36,y),P["track_hi"])
    poly(d,[(10,2),(29,2),(33,9),(32,38),(28,43),(11,43),(7,38),(7,9)],P["armor"])
    rect(d,(11,4,28,10),P["armor_hi"]); rect(d,(10,32,29,39),P["armor_lo"])
    rect(d,(9,13,12,25),P["red"]); rect(d,(27,13,30,25),P["red"])
    d.ellipse((13,14,26,27),fill=P["outline"]); d.ellipse((16,17,23,24),fill=P["dark"])
    rect(d,(13,35,26,37),P["metal"]); return im

def tank_turret():
    im=img((44,44)); d=ImageDraw.Draw(im)
    poly(d,[(14,15),(29,15),(34,21),(31,29),(13,29),(10,22)],P["armor"])
    rect(d,(15,17,28,20),P["armor_hi"]); d.ellipse((18,20,25,27),fill=P["dark"])
    rect(d,(12,23,15,26),P["red"]); return im

def tank_barrel():
    im=img((44,44)); d=ImageDraw.Draw(im)
    rect(d,(20,22,23,41),P["outline"]); rect(d,(21,23,22,40),P["metal"]); rect(d,(19,39,24,43),P["dark"])
    return im

def launcher(stage):
    im=img((44,44)); d=ImageDraw.Draw(im)
    if stage==0:
        rect(d,(12,17,31,28),P["dark"],P["outline"])
        for x in (14,20,26): rect(d,(x,15,x+3,27),P["missile"],P["outline"])
    else:
        lean={1:4,2:0,3:-2}[stage]
        rect(d,(11,18,32,30),P["armor_lo"],P["outline"])
        for x in (13,20,27):
            poly(d,[(x+lean,5),(x+3+lean,5),(x+4,24),(x,24)],P["missile"])
            poly(d,[(x+lean,3),(x+3+lean,5),(x+lean,7)],P["red"])
        if stage==3:
            rect(d,(13,25,17,30),P["hot"]); rect(d,(27,25,31,30),P["hot"])
    d.ellipse((18,19,25,26),fill=P["outline"]); return im

def aa_head():
    im=img((48,48)); d=ImageDraw.Draw(im)
    poly(d,[(15,17),(32,17),(35,23),(31,31),(16,31),(12,24)],P["armor"])
    rect(d,(17,19,30,22),P["armor_hi"]); d.ellipse((20,22,27,29),fill=P["glass"])
    return im

def aa_barrels():
    im=img((48,48)); d=ImageDraw.Draw(im)
    for x in (20,26):
        rect(d,(x,23,x+2,45),P["outline"]); rect(d,(x+1,24,x+1,43),P["metal"]); rect(d,(x-1,43,x+3,47),P["dark"])
    return im

def damage(size, kind):
    im=img(size); d=ImageDraw.Draw(im); cx=size[0]//2
    d.ellipse((cx-8,size[1]//2-7,cx+8,size[1]//2+8),fill=P["scorch"])
    line(d,(cx-7,size[1]//2-4,cx+5,size[1]//2+5),(15,15,14,240),2)
    line(d,(cx+5,size[1]//2-6,cx-3,size[1]//2+7),P["hot"],1)
    if kind=="sam": rect(d,(cx-10,size[1]//2+7,cx-5,size[1]//2+9),P["dark"])
    return im

def save(rel, im, outputs):
    path=OUT/rel; path.parent.mkdir(parents=True,exist_ok=True); im.save(path,optimize=True)
    outputs.append({"runtime":str(path.relative_to(ROOT)).replace('\\','/'),"size":list(im.size),"sha256":hashlib.sha256(path.read_bytes()).hexdigest()})

def main():
    outputs=[]
    bases={"light_tank":tank_base,"sam_truck":sam_base,"aa_carrier":aa_base}
    for unit,fn in bases.items():
        save(f"{unit}_base.png",fn(0),outputs)
        for frame in range(4): save(f"locomotion/{unit}/{frame}.png",fn(frame),outputs)
    save("light_tank_turret.png",tank_turret(),outputs); save("light_tank_barrel.png",tank_barrel(),outputs)
    for n,s in (("stowed",0),("rising",1),("deployed",2),("launch",3)): save(f"sam_launcher_{n}.png",launcher(s),outputs)
    save("aa_weapon_head.png",aa_head(),outputs); save("aa_twin_barrels.png",aa_barrels(),outputs)
    save("light_tank_damage.png",damage((36,44),"tank"),outputs)
    save("sam_truck_damage.png",damage((32,46),"sam"),outputs)
    save("aa_carrier_damage.png",damage((40,46),"aa"),outputs)
    SRC.mkdir(parents=True,exist_ok=True)
    builder=hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    manifest={"asset_family":"mercenary_mobile_ground_v2","status":"runtime_review_candidate","projection":"orthographic top-down, attack direction downscreen","art_direction":"Native-scale late-1990s military pixel/cel vehicles with broad readable value groups, mechanical articulation and restrained recognition marks.","builder":{"path":"tools/build_mobile_ground_v2.py","sha256":builder},"animation_contract":["four registered track or wheel contact exposures","turrets and launchers remain independent centered layers","SAM launcher moves through stowed, rising, deployed and launch exposures","damage overlays expose scorched armor and hot structural tears without arcade flashing"],"outputs":outputs}
    (SRC/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    sheet=Image.new("RGBA",(480,220),(11,15,17,255))
    def unit_preview(base, layers, x, y, damage_layer=None):
        canvas=img((56,56)); canvas.alpha_composite(base,((56-base.width)//2,(56-base.height)//2))
        for layer in layers: canvas.alpha_composite(layer,((56-layer.width)//2,(56-layer.height)//2))
        if damage_layer: canvas.alpha_composite(damage_layer,((56-damage_layer.width)//2,(56-damage_layer.height)//2))
        sheet.alpha_composite(canvas.resize((168,168),Image.Resampling.NEAREST),(x,y))
    unit_preview(tank_base(0),[tank_turret(),tank_barrel()],0,12)
    unit_preview(sam_base(0),[launcher(2)],156,12)
    unit_preview(aa_base(0),[aa_head(),aa_barrels()],312,12)
    for i,art in enumerate((launcher(0),launcher(1),launcher(2),launcher(3))):
        sheet.alpha_composite(art,(150+i*48,172))
    sheet.save(ROOT/"work/mobile_ground_v2_contact.png")

if __name__ == "__main__": main()
