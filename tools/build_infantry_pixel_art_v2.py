"""Build readable native-resolution conventional infantry cels for HYPERSONIC."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/runtime/enemies/infantry_layered"
REVIEW = ROOT / "assets/source/enemies/infantry_layered/infantry_runtime_v2_contact.png"
OUT.mkdir(parents=True, exist_ok=True)

P = {"ink":"#111715", "deep":"#283028", "olive":"#596044", "cloth":"#77775a",
     "edge":"#b0a77b", "skin":"#9b765b", "gun":"#30383a", "steel":"#899396",
     "flash":"#ffd568", "dust":"#796b51"}


def soldier(phase=0, firing=False, flinch=False, kneel=False):
    im = Image.new("RGBA", (14, 18), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    lean = -1 if flinch else 0
    # Helmet, visible shoulders, pack and torso form a readable top-down human.
    d.rectangle((5+lean,2,8+lean,5), fill=P["ink"]); d.rectangle((6+lean,2,7+lean,4), fill=P["edge"])
    d.rectangle((3+lean,5,10+lean,8), fill=P["ink"]); d.rectangle((4+lean,5,9+lean,7), fill=P["olive"])
    d.rectangle((5+lean,8,8+lean,12), fill=P["ink"]); d.rectangle((6+lean,8,7+lean,11), fill=P["cloth"])
    arm = phase % 2
    d.line((4+lean,7,2+lean,10+arm), fill=P["deep"], width=2)
    d.line((9+lean,7,11+lean,9-arm), fill=P["olive"], width=2)
    if kneel:
        d.line((5+lean,12,3+lean,15), fill=P["deep"], width=2); d.line((8+lean,12,10+lean,15), fill=P["deep"], width=2)
    else:
        d.line((5+lean,12,4+lean+arm,16), fill=P["deep"], width=2); d.line((8+lean,12,9+lean-arm,16), fill=P["olive"], width=2)
    # Long dark rifle and pale muzzle pixel prevent the pose reading as a blob.
    d.line((9+lean,7,11+lean,15), fill=P["ink"], width=2); d.point((11+lean,15), fill=P["steel"])
    if firing:
        d.point((11+lean,16), fill=P["flash"]); d.point((12+lean,17), fill=P["flash"])
    return im


def prone():
    im=Image.new("RGBA",(20,9),(0,0,0,0)); d=ImageDraw.Draw(im)
    d.ellipse((2,3,6,7),fill=P["ink"]); d.rectangle((5,2,13,7),fill=P["ink"]); d.rectangle((6,3,12,5),fill=P["olive"])
    d.line((11,4,19,4),fill=P["gun"],width=2); d.point((19,4),fill=P["steel"]); return im


def equipment(kind):
    sizes={"radio_operator":(12,16),"dropped_rifle":(12,9),"radio_pack":(9,11),"heavy_loader":(14,14),"heavy_spotter":(12,15),"heavy_tripod":(17,20),"heavy_tripod_recoil":(17,20),"heavy_ammo_crate":(10,10),"heavy_ammo_belt":(13,7),"fallen_rifleman":(19,11),"fallen_heavy":(19,11),"damaged_tripod":(13,12),"loose_helmet":(8,8),"loose_pack":(9,9),"hit_dust_0":(14,10),"hit_dust_1":(15,9)}
    im=Image.new("RGBA",sizes[kind],(0,0,0,0)); d=ImageDraw.Draw(im); w,h=im.size
    if kind in ("radio_operator","heavy_loader","heavy_spotter"):
        base=soldier(1,False,False,kind!="radio_operator"); im.alpha_composite(base.resize(im.size,Image.Resampling.NEAREST))
        if kind=="radio_operator": d.rectangle((1,5,4,10),fill=P["ink"]); d.line((2,5,1,1),fill=P["steel"])
    elif "tripod" in kind:
        d.line((w//2,3,w//2,h-4),fill=P["gun"],width=2); d.line((w//2,h//2,2,h-1),fill=P["ink"],width=2); d.line((w//2,h//2,w-3,h-1),fill=P["ink"],width=2); d.line((w//2,4,w//2+(2 if "recoil" in kind else 0),0),fill=P["steel"],width=2)
    elif kind in ("hit_dust_0","hit_dust_1"):
        d.ellipse((1,2,w-2,h-2),outline=P["dust"]); d.point((w//2,1),fill=P["edge"]); d.point((2,h//2),fill=P["dust"])
    elif kind=="dropped_rifle": d.line((1,h-2,w-2,1),fill=P["gun"],width=2)
    elif kind=="heavy_ammo_belt":
        for x in range(1,w-1,2): d.point((x,h//2),fill=P["edge"])
    elif "fallen" in kind:
        d.ellipse((1,3,5,7),fill=P["edge"]); d.rectangle((5,2,w-5,8),fill=P["olive"]); d.line((w-6,4,w-1,1),fill=P["gun"],width=2)
    else:
        d.rectangle((1,1,w-2,h-2),fill=P["ink"]); d.rectangle((2,2,w-3,h-3),fill=P["olive"]); d.line((2,h//2,w-3,h//2),fill=P["edge"])
    return im


assets={
 "rifle_advance_0":soldier(0),"rifle_advance_1":soldier(1),"rifle_advance_2":soldier(2),
 "rifle_aim":soldier(0,False,False,True),"rifle_fire":soldier(0,True),"rifle_flinch":soldier(0,False,True),
 "rifle_kneel":soldier(1,False,False,True),"rifle_kneel_fire":soldier(1,True,False,True),"rifle_prone":prone(),
}
for name in ("radio_operator","dropped_rifle","radio_pack","heavy_loader","heavy_spotter","heavy_tripod","heavy_tripod_recoil","heavy_ammo_crate","heavy_ammo_belt","fallen_rifleman","fallen_heavy","damaged_tripod","loose_helmet","loose_pack","hit_dust_0","hit_dust_1"):
    assets[name]=equipment(name)
REGISTERED = {
 "rifle_advance_0":(10,16),"rifle_advance_1":(10,16),"rifle_advance_2":(10,16),"rifle_aim":(12,14),"rifle_fire":(12,14),"rifle_flinch":(10,14),
 "rifle_kneel":(14,11),"rifle_kneel_fire":(14,11),"rifle_prone":(19,8),"radio_operator":(10,13),"dropped_rifle":(11,9),"radio_pack":(8,11),
 "heavy_loader":(13,12),"heavy_spotter":(10,13),"heavy_tripod":(15,19),"heavy_tripod_recoil":(15,19),"heavy_ammo_crate":(9,10),"heavy_ammo_belt":(12,6),
 "fallen_rifleman":(18,10),"fallen_heavy":(18,10),"damaged_tripod":(11,11),"loose_helmet":(8,8),"loose_pack":(9,9),"hit_dust_0":(13,9),"hit_dust_1":(14,8),
}
for name,im in list(assets.items()):
    target=REGISTERED[name]
    scale=min(target[0]/im.width,target[1]/im.height)
    fitted=im.resize((max(1,round(im.width*scale)),max(1,round(im.height*scale))),Image.Resampling.NEAREST)
    registered=Image.new("RGBA",target,(0,0,0,0))
    registered.alpha_composite(fitted,((target[0]-fitted.width)//2,(target[1]-fitted.height)//2))
    assets[name]=registered
    registered.save(OUT/f"{name}.png")

sheet=Image.new("RGBA",(320,120),(9,16,21,255)); d=ImageDraw.Draw(sheet)
for i,(name,im) in enumerate(assets.items()):
    x=(i%9)*35; y=(i//9)*40; sheet.alpha_composite(im,(x+(30-im.width)//2,y+2)); d.text((x,y+23),name[:5],fill="#9fb2ad")
REVIEW.parent.mkdir(parents=True,exist_ok=True); sheet.save(REVIEW)
print(f"built {len(assets)} infantry cels and {REVIEW}")
