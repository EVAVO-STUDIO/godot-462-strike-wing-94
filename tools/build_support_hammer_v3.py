from pathlib import Path
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/runtime/support/battlefield/hammer_bomber"
PROOF = ROOT / "work/support_hammer_v3_contact.png"


def polygon(draw, points, fill, outline=None):
    draw.polygon(points, fill=fill)
    if outline:
        draw.line(points + [points[0]], fill=outline, width=1, joint="curve")


def frame(phase: int, bank: int = 0) -> Image.Image:
    im = Image.new("RGBA", (64, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ink = (24, 33, 40, 255)
    deep = (43, 55, 64, 255)
    mid = (83, 99, 108, 255)
    light = (139, 151, 153, 255)
    pale = (178, 185, 181, 255)

    # Heavy delta planform, designed at its final display resolution.
    polygon(d, [(4,18),(18,13),(29,3),(45,3),(43,12),(58,15),(62,18),(58,21),(43,24),(45,33),(29,33),(18,23)], deep, ink)
    polygon(d, [(17,14),(30,4),(43,4),(39,14),(31,17)], light)
    polygon(d, [(17,22),(31,19),(39,22),(43,32),(30,32)], mid)
    polygon(d, [(4,18),(20,14),(49,15),(59,18),(49,20),(20,21)], mid, ink)
    polygon(d, [(5,18),(19,15),(27,16),(22,18)], pale)

    # Reinforced spine and recessed ventral strike bay.
    d.rectangle((20,14,49,20), fill=(69,84,94,255), outline=ink)
    d.rectangle((27,16,45,19), fill=(29,38,46,255))
    d.line((28,16,44,16), fill=(117,130,136,255))
    for x in (30,35,40,45):
        d.point((x,20), fill=(181,152,83,255))

    # Paired buried engines and intake lips.
    for y in (10,23):
        d.rectangle((25,y,47,y+4), fill=(58,72,82,255), outline=ink)
        d.rectangle((25,y+1,28,y+3), fill=(18,27,34,255))
        d.line((30,y+1,44,y+1), fill=(115,130,138,255))
        d.point((36,y+3), fill=(31,42,50,255))
        core = [(255,183,74,255),(255,209,104,255),(255,232,155,255),(255,201,86,255)][phase]
        d.rectangle((47,y+1,48,y+3), fill=core)

    # Cockpit, service panels and restrained squadron markings.
    d.rounded_rectangle((12,15,20,20), radius=2, fill=(17,44,58,255), outline=ink)
    d.rectangle((14,16,16,19), fill=(62,143,165,255))
    d.rectangle((17,16,19,19), fill=(38,99,124,255))
    d.line((13,15,19,15), fill=(151,211,214,255))
    for box in ((31,7,35,9),(36,7,39,9),(31,27,35,29),(36,27,39,29)):
        d.rectangle(box, outline=(65,76,80,255))
    d.rectangle((38,5,41,6), fill=(190,147,65,255))
    d.rectangle((38,30,41,31), fill=(190,147,65,255))
    d.line((23,12,40,12), fill=(48,61,69,255))
    d.line((23,24,40,24), fill=(48,61,69,255))

    nav_on = phase in (0, 2)
    d.point((43,3), fill=(78,230,163,255) if nav_on else (37,85,67,255))
    d.point((43,33), fill=(244,80,67,255) if nav_on else (96,45,43,255))
    if bank == 0:
        return im
    cy = 18
    upper = im.crop((0,0,64,cy))
    lower = im.crop((0,cy,64,36))
    upper_height, lower_height = ((15,17) if bank < 0 else (17,15))
    posed = Image.new("RGBA", (64,36), (0,0,0,0))
    posed.alpha_composite(upper.resize((64,upper_height),Image.Resampling.NEAREST),(0,cy-upper_height))
    posed.alpha_composite(lower.resize((64,lower_height),Image.Resampling.NEAREST),(0,cy))
    pixels = posed.load()
    y_range = range(cy,36) if bank < 0 else range(0,cy)
    for y in y_range:
        for x in range(64):
            r,g,b,a = pixels[x,y]
            if a:
                pixels[x,y] = (int(r*0.74),int(g*0.78),int(b*0.81),a)
    return posed


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    banks = (("left",-1),("level",0),("right",1))
    rows = []
    for name,value in banks:
        frames = [frame(i,value) for i in range(4)]
        rows.append(frames)
        for i,im in enumerate(frames):
            im.save(OUT / f"{name}_{i}.png")
            if name == "level":
                im.save(OUT / f"{i}.png")
    scale = 8
    proof = Image.new("RGBA",(64*4*scale,36*3*scale),(15,19,23,255))
    for row,frames in enumerate(rows):
        for column,im in enumerate(frames):
            proof.alpha_composite(im.resize((64*scale,36*scale),Image.Resampling.NEAREST),(column*64*scale,row*36*scale))
    PROOF.parent.mkdir(parents=True, exist_ok=True)
    proof.save(PROOF)
    print(f"wrote 12 Hammer bank/cadence frames, 4 compatibility frames and {PROOF}")


if __name__ == "__main__":
    main()
