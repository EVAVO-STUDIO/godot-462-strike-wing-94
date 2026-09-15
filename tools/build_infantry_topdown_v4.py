from pathlib import Path
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/runtime/enemies/infantry_layered"
PROOF = ROOT / "work/infantry_topdown_v4_contact.png"

INK = (18, 23, 21, 255)
SHADOW = (30, 36, 30, 255)
OLIVE_DARK = (48, 55, 37, 255)
OLIVE = (72, 78, 48, 255)
OLIVE_LIGHT = (101, 103, 62, 255)
HELMET = (82, 84, 55, 255)
HELMET_LIGHT = (126, 122, 72, 255)
WEBBING = (125, 101, 62, 255)
METAL = (91, 101, 98, 255)
METAL_LIGHT = (151, 158, 147, 255)
FLASH = (255, 211, 94, 255)


def canvas(size):
    return Image.new("RGBA", size, (0, 0, 0, 0))


def standing(size, gait=0, aiming=False, firing=False, flinch=False, radio=False):
    im = canvas(size); d = ImageDraw.Draw(im); w, h = size; cx = w // 2
    # Helmet, neck shadow and shoulder line establish the top-down read.
    d.rectangle((cx-2,1,cx+1,2), fill=INK)
    d.rectangle((cx-2,2,cx+2,4), fill=HELMET)
    d.point((cx-1,2), fill=HELMET_LIGHT)
    d.rectangle((cx-1,5,cx,5), fill=SHADOW)
    left_shoulder = cx-3-(1 if flinch else 0); right_shoulder = cx+2
    d.rectangle((left_shoulder,5,right_shoulder,7), fill=OLIVE_DARK)
    d.rectangle((cx-2,6,cx+1,10), fill=OLIVE)
    d.point((cx-1,6), fill=OLIVE_LIGHT)
    d.rectangle((cx-2,8,cx+1,8), fill=WEBBING)
    # Arms and rifle remain narrow, directional shapes rather than a bright pole.
    if aiming:
        d.rectangle((cx+2,6,cx+4,7), fill=OLIVE_DARK)
        d.rectangle((cx+4,6,cx+5,10), fill=METAL)
        d.point((cx+5,11), fill=FLASH if firing else METAL_LIGHT)
    else:
        d.point((cx-3,8), fill=OLIVE)
        d.rectangle((cx+2,7,cx+3,11), fill=METAL)
    if radio:
        d.rectangle((max(0,cx-4),6,max(0,cx-3),10), fill=WEBBING)
        d.point((max(0,cx-4),5), fill=METAL_LIGHT)
        d.line((max(0,cx-4),5,max(0,cx-4),1), fill=METAL)
    # Alternating boots give a real gait at this scale.
    lx = cx-2 + (-1 if gait == 1 else 0); rx = cx+1 + (1 if gait == 2 else 0)
    d.line((cx-1,10,lx,h-2), fill=OLIVE_DARK, width=2)
    d.line((cx+1,10,rx,h-2-(1 if gait == 1 else 0)), fill=OLIVE_DARK, width=2)
    d.point((max(0,lx-1),h-1), fill=SHADOW); d.point((min(w-1,rx+1),h-1), fill=SHADOW)
    return im


def kneeling(firing=False):
    im = canvas((14,11)); d = ImageDraw.Draw(im); cx=6
    d.rectangle((cx-2,1,cx+2,3),fill=HELMET); d.point((cx-1,1),fill=HELMET_LIGHT)
    d.rectangle((cx-3,4,cx+2,6),fill=OLIVE_DARK); d.rectangle((cx-1,4,cx+2,8),fill=OLIVE)
    d.line((cx+2,5,12,5),fill=METAL); d.point((13,5),fill=FLASH if firing else METAL_LIGHT)
    d.line((cx-1,7,2,9),fill=OLIVE_DARK,width=2); d.line((cx+1,8,8,10),fill=OLIVE_DARK,width=2)
    return im


def prone():
    im=canvas((19,8)); d=ImageDraw.Draw(im)
    d.rectangle((1,3,4,5),fill=HELMET); d.point((2,3),fill=HELMET_LIGHT)
    d.rectangle((5,2,12,6),fill=OLIVE_DARK); d.rectangle((6,3,10,5),fill=OLIVE)
    d.line((11,3,17,3),fill=METAL); d.point((18,3),fill=METAL_LIGHT)
    d.point((13,6),fill=SHADOW); d.point((15,6),fill=SHADOW)
    return im


def crew(size, role):
    if role == "loader":
        im=standing(size,gait=1); d=ImageDraw.Draw(im); d.rectangle((1,4,3,9),fill=WEBBING); d.point((2,3),fill=METAL_LIGHT); return im
    return standing(size,aiming=True,radio=True)


def tripod(recoil=False):
    im=canvas((15,19)); d=ImageDraw.Draw(im); cx=7; muzzle_y=4+(1 if recoil else 0)
    d.rectangle((cx-2,muzzle_y,cx+2,muzzle_y+2),fill=INK)
    d.rectangle((cx-1,muzzle_y,cx+1,muzzle_y+5),fill=METAL)
    d.point((cx,muzzle_y),fill=FLASH if recoil else METAL_LIGHT)
    d.rectangle((cx-2,10,cx+2,12),fill=OLIVE_DARK)
    d.line((cx,11,1,18),fill=METAL,width=2); d.line((cx,11,13,18),fill=METAL,width=2); d.line((cx,12,cx,18),fill=METAL)
    d.point((1,18),fill=SHADOW); d.point((13,18),fill=SHADOW)
    return im


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    assets = {
        "rifle_advance_0": standing((10,16),0), "rifle_advance_1": standing((10,16),1), "rifle_advance_2": standing((10,16),2),
        "rifle_aim": standing((12,14),aiming=True), "rifle_fire": standing((12,14),aiming=True,firing=True),
        "rifle_flinch": standing((10,14),flinch=True), "rifle_kneel": kneeling(False), "rifle_kneel_fire": kneeling(True),
        "rifle_prone": prone(), "radio_operator": standing((10,13),radio=True),
        "heavy_loader": crew((13,12),"loader"), "heavy_spotter": crew((10,13),"spotter"),
        "heavy_tripod": tripod(False), "heavy_tripod_recoil": tripod(True),
    }
    for name,image in assets.items(): image.save(OUT/f"{name}.png")
    cell=(228,220); scale=12; names=list(assets); proof=Image.new("RGBA",(cell[0]*4,cell[1]*4),(16,20,22,255)); pd=ImageDraw.Draw(proof)
    for i,name in enumerate(names):
        image=assets[name].resize((assets[name].width*scale,assets[name].height*scale),Image.Resampling.NEAREST)
        x=(i%4)*cell[0]+(cell[0]-image.width)//2; y=(i//4)*cell[1]+24
        proof.alpha_composite(image,(x,y)); pd.text(((i%4)*cell[0]+6,(i//4)*cell[1]+6),name,fill=(186,204,196,255))
    PROOF.parent.mkdir(parents=True,exist_ok=True); proof.save(PROOF)
    print(f"wrote {len(assets)} top-down infantry cels and {PROOF}")


if __name__ == "__main__": main()
