from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

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


def save_lightning(index, reveal, opacity):
    size = (160, 224)
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    path = [(78, -4), (72, 24), (82, 39), (65, 64), (71, 82), (53, 108), (61, 127), (42, 153), (49, 170), (31, 218)]
    branches = [
        [(70, 65), (43, 79), (31, 104)],
        [(57, 111), (84, 126), (103, 151)],
        [(47, 156), (23, 169), (10, 192)],
    ]
    visible_count = max(2, round(len(path) * reveal))
    visible_path = path[:visible_count]
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.line(visible_path, fill=(84, 174, 226, round(150 * opacity)), width=7, joint="curve")
    for branch in branches:
        if branch[0][1] <= visible_path[-1][1]:
            glow_draw.line(branch, fill=(73, 151, 210, round(105 * opacity)), width=5, joint="curve")
    glow = glow.filter(ImageFilter.GaussianBlur(3.0))
    image.alpha_composite(glow)
    draw = ImageDraw.Draw(image)
    draw.line(visible_path, fill=(194, 231, 247, round(245 * opacity)), width=2, joint="curve")
    draw.line(visible_path, fill=(248, 252, 238, round(255 * opacity)), width=1, joint="curve")
    for branch in branches:
        if branch[0][1] <= visible_path[-1][1]:
            draw.line(branch, fill=(151, 211, 239, round(220 * opacity)), width=1, joint="curve")
    image.save(OUT.parent / f"lightning_{index}.png")


save_lightning(0, 0.58, 0.90)
save_lightning(1, 1.00, 1.00)
save_lightning(2, 1.00, 0.48)
print(OUT)
