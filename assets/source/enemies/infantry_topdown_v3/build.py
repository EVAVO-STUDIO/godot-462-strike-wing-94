"""Build top-down/three-quarter infantry cels for the vertical battlefield."""
from hashlib import sha256
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[4]; SOURCE=ROOT/"assets/source/enemies/infantry_topdown_v3"; RUNTIME=ROOT/"assets/runtime/enemies/infantry_layered"
# Restrained late-90s field palette. Infantry must read as cloth, webbing and
# blued steel embedded in the terrain, never as luminous radar symbology.
INK=(12,16,15,255); OLIVE=(48,54,38,255); OLIVE_L=(80,82,53,255); HELMET=(119,111,73,255); SKIN=(126,91,61,255); GUN=(53,62,62,255); STEEL=(108,117,114,255); TAN=(101,81,53,255); FLASH=(255,211,102,255)

def soldier(size,pose="advance",role="rifle",step=0):
    w,h=size; x=w//2; im=Image.new("RGBA",size,(0,0,0,0));d=ImageDraw.Draw(im)
    head_y=2; d.ellipse((x-2,head_y-1,x+2,head_y+3),fill=INK);d.ellipse((x-1,head_y,x+1,head_y+2),fill=HELMET);d.point((x,head_y),fill=(174,161,103,255))
    if pose in ("kneel","kneel_fire"):
        d.polygon([(x-3,4),(x+3,4),(x+2,8),(x-2,8)],fill=OLIVE_L);d.line([(x-2,7),(x-4,9)],fill=OLIVE,width=2);d.line([(x+2,7),(x+4,9)],fill=OLIVE,width=2)
    else:
        d.polygon([(x-3,5),(x+3,5),(x+2,10),(x-2,10)],fill=INK);d.rectangle((x-2,5,x+2,9),fill=OLIVE_L);d.rectangle((x-1,6,x+1,9),fill=OLIVE)
        left= x-3-(1 if step==1 else 0); right=x+3+(1 if step==2 else 0); y=min(h-2,13)
        d.line([(x-1,9),(left,y)],fill=INK,width=2);d.line([(x+1,9),(right,y)],fill=INK,width=2);d.point((left,y),fill=TAN);d.point((right,y),fill=TAN)
    # Shoulder-held weapons point downscreen toward the approaching VX-94.
    gun_x=x+3 if role!="radio" else x-3; d.line([(gun_x,5),(gun_x,min(h-2,12))],fill=INK,width=3);d.line([(gun_x,5),(gun_x,min(h-2,12))],fill=GUN,width=1);d.point((gun_x,min(h-1,13)),fill=STEEL)
    if role=="radio": d.rectangle((x-3,5,x-2,9),fill=TAN);d.line([(x-3,5),(x-4,1)],fill=STEEL)
    if pose in ("fire","kneel_fire"):
        muzzle_y=min(h-1,13)
        d.point((gun_x,muzzle_y),fill=FLASH);d.point((gun_x-1,max(0,muzzle_y-1)),fill=FLASH)
        if pose=="kneel_fire": d.point((gun_x+1,muzzle_y),fill=(255,157,61,255))
    if pose=="flinch":
        return im.rotate(14,resample=Image.Resampling.NEAREST,expand=False,fillcolor=(0,0,0,0))
    return im

def tripod(recoil=False):
    im=Image.new("RGBA",(15,19),(0,0,0,0));d=ImageDraw.Draw(im);x=7
    d.line([(x,8),(2,16)],fill=INK,width=3);d.line([(x,8),(12,16)],fill=INK,width=3);d.line([(x,8),(x,17)],fill=INK,width=3)
    d.line([(x,8),(2,16)],fill=GUN);d.line([(x,8),(12,16)],fill=GUN);d.rectangle((5,5,9,10),fill=INK);d.rectangle((6,6,8,9),fill=STEEL)
    end=17 if not recoil else 14;d.line([(7,7),(7,end)],fill=INK,width=3);d.line([(7,7),(7,end)],fill=STEEL);d.point((7,end),fill=FLASH if recoil else GUN)
    return im

images={
 "rifle_advance_0":soldier((10,16),step=0),"rifle_advance_1":soldier((10,16),step=1),"rifle_advance_2":soldier((10,16),step=2),
 "rifle_aim":soldier((12,14)),"rifle_fire":soldier((12,14),pose="fire"),"rifle_flinch":soldier((10,14),pose="flinch"),
 "rifle_kneel":soldier((14,11),pose="kneel"),"rifle_kneel_fire":soldier((14,11),pose="kneel_fire"),"radio_operator":soldier((10,13),role="radio"),
 "heavy_loader":soldier((13,12),role="radio",step=1),"heavy_spotter":soldier((10,13),role="radio",step=2),
 "heavy_tripod":tripod(False),"heavy_tripod_recoil":tripod(True),
}
records=[]
for name,image in images.items():
    runtime=RUNTIME/f"{name}.png";source=SOURCE/f"{name}.png";runtime.parent.mkdir(parents=True,exist_ok=True);source.parent.mkdir(parents=True,exist_ok=True);image.save(runtime,optimize=True);image.save(source,optimize=True)
    records.append({"id":name,"runtime":runtime.relative_to(ROOT).as_posix(),"size":list(image.size),"visible_bounds":list(image.getbbox()),"sha256":sha256(runtime.read_bytes()).hexdigest().upper()})
(SOURCE/"manifest.json").write_text(json.dumps({"asset_family":"mercenary_infantry_topdown_v3","status":"runtime_integrated","projection":"top-down three-quarter, attack direction downscreen","visual_contract":["helmet and shoulder masses establish human scale","feet and formation shadow anchor every member to terrain","weapons point toward the player approach axis","gait, firing, flinch, crew roles and tripod recoil remain distinct","no side-view platformer silhouettes"],"outputs":records},indent=2)+"\n",encoding="utf-8")
print("Built thirteen top-down infantry and crew cels.")
