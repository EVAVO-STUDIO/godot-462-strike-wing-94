from pathlib import Path
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/runtime/support/battlefield/atlas_tanker"
PROOF = ROOT / "work/support_atlas_v3_contact.png"


def poly(draw, points, fill, outline=None):
    draw.polygon(points, fill=fill)
    if outline:
        draw.line(points + [points[0]], fill=outline, width=1, joint="curve")


def build_frame(bank: int, phase: int) -> Image.Image:
    im = Image.new("RGBA", (112, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ink = (19, 27, 33, 255)
    deep = (39, 51, 59, 255)
    mid = (75, 90, 98, 255)
    light = (128, 142, 144, 255)
    pale = (174, 181, 177, 255)
    amber = (188, 145, 62, 255)
    cy = 32
    upper_tip = 6 + (6 if bank < 0 else -1 if bank > 0 else 0)
    lower_tip = 58 + (1 if bank < 0 else -6 if bank > 0 else 0)

    # Long-range tanker wing with enough span to read as a different class.
    poly(d, [(8,cy),(28,25),(43,upper_tip),(67,upper_tip),(73,24),(98,27),(106,cy),(98,37),(73,40),(67,lower_tip),(43,lower_tip),(28,39)], deep, ink)
    poly(d, [(31,25),(45,upper_tip+1),(65,upper_tip+1),(68,25)], light if bank <= 0 else mid, ink)
    poly(d, [(31,39),(68,39),(65,lower_tip-1),(45,lower_tip-1)], light if bank >= 0 else mid, ink)
    d.line((47,upper_tip+3,63,upper_tip+3), fill=pale)
    d.line((47,lower_tip-3,63,lower_tip-3), fill=(91,105,109,255))

    # Deep centre fuselage and dorsal fuel-transfer spine.
    poly(d, [(6,cy),(18,25),(88,24),(103,28),(108,cy),(103,36),(88,40),(18,39)], mid, ink)
    poly(d, [(8,cy),(21,27),(85,27),(98,30),(101,32),(87,34),(21,35)], light)
    d.rectangle((24,31,88,39), fill=deep, outline=ink)
    d.rectangle((37,26,82,31), fill=(55,69,78,255), outline=ink)
    d.rectangle((42,27,76,29), fill=(103,117,122,255))
    for x in (43,51,59,67,75):
        d.point((x,30), fill=(29,39,46,255))

    # Four engines with small held heat changes.
    glow = [(239,151,55,255),(255,188,73,255),(255,220,120,255),(255,177,64,255)][phase]
    for y in (14, 43):
        for x in (39, 59):
            d.rectangle((x,y,x+14,y+7), fill=(49,62,70,255), outline=ink)
            d.rectangle((x,y+1,x+3,y+6), fill=(16,24,29,255))
            d.line((x+5,y+1,x+12,y+1), fill=(119,133,136,255))
            d.rectangle((x+14,y+2,x+15,y+5), fill=glow)

    # Flight deck, tanker markings, transfer station and tail structure.
    d.rounded_rectangle((13,27,27,36), radius=3, fill=(16,42,54,255), outline=ink)
    d.rectangle((16,28,20,34), fill=(58,135,154,255))
    d.rectangle((21,28,25,34), fill=(34,82,102,255))
    d.line((15,27,25,27), fill=(151,207,208,255))
    d.rectangle((29,34,36,39), fill=(25,35,41,255), outline=ink)
    d.rectangle((31,36,34,38), fill=(201,170,91,255))
    d.rectangle((46,9,53,12), fill=amber)
    d.rectangle((46,52,53,55), fill=amber)
    d.rectangle((77,28,84,32), fill=(147,153,145,255), outline=(45,56,61,255))
    poly(d, [(88,24),(98,15),(105,16),(102,29)], mid, ink)
    poly(d, [(88,40),(102,35),(105,48),(98,49)], deep, ink)
    d.point((66,upper_tip), fill=(62,221,153,255) if phase in (0,2) else (34,75,59,255))
    d.point((66,lower_tip), fill=(240,76,62,255) if phase in (0,2) else (91,42,40,255))

    if bank < 0:
        d.line((20,38,88,39), fill=(17,25,30,180), width=2)
        d.line((27,25,84,24), fill=(184,193,189,220))
    elif bank > 0:
        d.line((20,25,88,24), fill=(17,25,30,180), width=2)
        d.line((27,39,84,40), fill=(184,193,189,220))
    return im


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    banks = (("left", -1), ("level", 0), ("right", 1))
    rows = []
    for name, value in banks:
        frames = [build_frame(value, phase) for phase in range(4)]
        rows.append(frames)
        for phase, image in enumerate(frames):
            image.save(OUT / f"{name}_{phase}.png")
            if name == "level":
                image.save(OUT / f"{phase}.png")
    scale = 5
    proof = Image.new("RGBA", (112*4*scale,64*3*scale), (15,19,23,255))
    for row, frames in enumerate(rows):
        for column, image in enumerate(frames):
            proof.alpha_composite(image.resize((112*scale,64*scale),Image.Resampling.NEAREST),(column*112*scale,row*64*scale))
    PROOF.parent.mkdir(parents=True, exist_ok=True)
    proof.save(PROOF)
    print(f"wrote 12 Atlas bank/cadence frames, 4 compatibility frames and {PROOF}")


if __name__ == "__main__":
    main()
