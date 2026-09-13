from pathlib import Path
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/runtime/support/battlefield/spectre_gunship"
PROOF = ROOT / "work/support_spectre_v3_contact.png"


def poly(draw, points, fill, outline=None):
    draw.polygon(points, fill=fill)
    if outline:
        draw.line(points + [points[0]], fill=outline, width=1, joint="curve")


def build_frame(bank: int, phase: int) -> Image.Image:
    im = Image.new("RGBA", (96, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ink = (20, 28, 34, 255)
    deep = (38, 50, 58, 255)
    mid = (72, 87, 95, 255)
    light = (125, 139, 142, 255)
    pale = (169, 176, 172, 255)
    amber = (183, 139, 59, 255)
    cy = 28
    # A bank compresses the receding wing and exposes a darker near-side flank.
    upper_tip = 8 + (5 if bank < 0 else -1 if bank > 0 else 0)
    lower_tip = 48 + (1 if bank < 0 else -5 if bank > 0 else 0)

    poly(d, [(9,cy),(24,22),(37,upper_tip),(57,upper_tip),(62,21),(83,24),(91,cy),(83,32),(62,35),(57,lower_tip),(37,lower_tip),(24,34)], deep, ink)
    poly(d, [(29,22),(39,upper_tip+1),(55,upper_tip+1),(57,22)], light if bank <= 0 else mid, ink)
    poly(d, [(29,34),(57,34),(55,lower_tip-1),(39,lower_tip-1)], light if bank >= 0 else mid, ink)
    d.line((41,upper_tip+3,53,upper_tip+3), fill=pale)
    d.line((41,lower_tip-3,53,lower_tip-3), fill=(89,104,109,255))

    # Long armoured transport fuselage and tailplane.
    poly(d, [(8,cy),(18,22),(75,21),(88,25),(92,cy),(88,31),(75,35),(18,34)], mid, ink)
    poly(d, [(10,cy),(20,23),(72,23),(84,26),(87,cy),(74,29),(20,30)], light)
    d.rectangle((25,27,73,34), fill=deep, outline=ink)
    d.line((27,28,69,28), fill=(112,127,131,255))
    d.rectangle((74,24,87,31), fill=(54,67,75,255), outline=ink)
    poly(d, [(76,21),(84,15),(90,16),(87,25)], mid, ink)
    poly(d, [(76,35),(87,31),(90,40),(84,41)], deep, ink)

    # Four nacelles establish the gunship's sustained-fire mass.
    glow = [(241,154,57,255),(255,192,76,255),(255,222,125,255),(255,180,66,255)][phase]
    for y in (14, 37):
        for x in (38, 52):
            d.rectangle((x,y,x+11,y+6), fill=(49,62,70,255), outline=ink)
            d.rectangle((x,y+1,x+2,y+5), fill=(16,24,29,255))
            d.line((x+4,y+1,x+9,y+1), fill=(118,132,135,255))
            d.point((x+11,y+3), fill=glow)

    # Cockpit glass, sensor blister, broadside cannon battery and service panels.
    d.rounded_rectangle((13,23,24,31), radius=3, fill=(17,42,54,255), outline=ink)
    d.rectangle((16,24,19,29), fill=(54,128,148,255))
    d.rectangle((20,24,22,29), fill=(34,83,104,255))
    d.line((15,23,22,23), fill=(148,205,206,255))
    d.ellipse((30,24,36,30), fill=(25,35,42,255), outline=ink)
    for x, length in ((25,8),(31,11),(38,14)):
        d.rectangle((x,34,x+1,34+length), fill=(25,32,36,255))
        d.point((x,35+length), fill=(151,163,160,255))
    for x in (43,51,59,67):
        d.rectangle((x,29,x+5,32), fill=(103,115,116,255), outline=(47,58,62,255))
    d.rectangle((45,10,50,12), fill=amber)
    d.rectangle((45,44,50,46), fill=amber)
    d.point((56,upper_tip), fill=(61,220,152,255) if phase in (0,2) else (34,75,59,255))
    d.point((56,lower_tip), fill=(239,76,62,255) if phase in (0,2) else (91,42,40,255))

    # Bank lighting is an authored state rather than a rotated flat card.
    if bank < 0:
        d.line((20,33,73,34), fill=(17,25,30,170), width=2)
        d.line((25,22,70,22), fill=(181,191,187,220))
    elif bank > 0:
        d.line((20,22,73,21), fill=(17,25,30,170), width=2)
        d.line((25,34,70,34), fill=(181,191,187,220))
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
    scale = 6
    proof = Image.new("RGBA", (96 * 4 * scale, 56 * 3 * scale), (15, 19, 23, 255))
    for row, frames in enumerate(rows):
        for column, image in enumerate(frames):
            proof.alpha_composite(image.resize((96*scale,56*scale), Image.Resampling.NEAREST), (column*96*scale,row*56*scale))
    PROOF.parent.mkdir(parents=True, exist_ok=True)
    proof.save(PROOF)
    print(f"wrote 12 bank/cadence frames, 4 compatibility frames and {PROOF}")


if __name__ == "__main__":
    main()
