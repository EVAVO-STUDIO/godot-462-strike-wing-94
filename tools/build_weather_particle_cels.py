from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "runtime" / "effects" / "weather" / "snow"
OUT.mkdir(parents=True, exist_ok=True)


def canvas():
    return Image.new("RGBA", (16, 16), (0, 0, 0, 0))


def save_distant():
    image = canvas()
    draw = ImageDraw.Draw(image)
    draw.point((8, 9), fill=(18, 25, 30, 120))
    draw.point((8, 8), fill=(158, 176, 184, 220))
    draw.point((7, 8), fill=(104, 126, 136, 150))
    image.save(OUT / "distant.png")


def save_middle():
    image = canvas()
    draw = ImageDraw.Draw(image)
    shadow = (17, 23, 27, 125)
    ice = (184, 201, 207, 225)
    light = (232, 241, 241, 245)
    draw.line((5, 9, 11, 9), fill=shadow, width=1)
    draw.line((8, 6, 8, 12), fill=shadow, width=1)
    draw.line((6, 7, 10, 11), fill=shadow, width=1)
    draw.line((5, 8, 11, 8), fill=ice, width=1)
    draw.line((8, 5, 8, 11), fill=ice, width=1)
    draw.line((6, 6, 10, 10), fill=ice, width=1)
    draw.point((8, 7), fill=light)
    image.save(OUT / "middle.png")


def save_near():
    image = canvas()
    draw = ImageDraw.Draw(image)
    shadow = (14, 20, 24, 145)
    edge = (151, 177, 188, 235)
    ice = (220, 233, 236, 250)
    light = (249, 252, 247, 255)
    arms = [((8, 3), (8, 13)), ((3, 8), (13, 8)), ((4, 4), (12, 12)), ((12, 4), (4, 12))]
    for start, end in arms:
        draw.line((start[0] + 1, start[1] + 1, end[0] + 1, end[1] + 1), fill=shadow, width=1)
    for start, end in arms:
        draw.line((*start, *end), fill=edge, width=1)
    draw.polygon(((8, 5), (11, 8), (8, 11), (5, 8)), fill=ice)
    draw.point((8, 7), fill=light)
    draw.point((7, 8), fill=light)
    image.save(OUT / "near.png")


save_distant()
save_middle()
save_near()
print(OUT)
