from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "runtime" / "ui" / "hud" / "tactical_radar"
OUT.mkdir(parents=True, exist_ok=True)


def frame():
    image = Image.new("RGBA", (120, 76), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    d.rectangle((0, 0, 119, 75), fill=(4, 12, 15, 218), outline=(75, 112, 116, 245))
    d.rectangle((2, 2, 117, 73), outline=(18, 43, 48, 255))
    d.polygon(((0, 0), (17, 0), (10, 4), (0, 4)), fill=(126, 154, 150, 230))
    d.polygon(((119, 75), (102, 75), (109, 71), (119, 71)), fill=(72, 99, 101, 230))
    d.rectangle((8, 12, 111, 68), fill=(5, 20, 20, 232), outline=(52, 95, 91, 255))
    for y in range(16, 68, 4):
        d.line((9, y, 110, y), fill=(12, 39, 37, 90))
    d.line((60, 14, 60, 66), fill=(40, 83, 76, 145))
    d.line((10, 40, 110, 40), fill=(32, 72, 67, 125))
    d.line((35, 14, 48, 66), fill=(28, 66, 62, 115))
    d.line((85, 14, 72, 66), fill=(28, 66, 62, 115))
    d.arc((25, 35, 95, 84), 202, 338, fill=(47, 91, 82, 150), width=1)
    d.rectangle((8, 7, 31, 9), fill=(61, 111, 99, 210))
    d.rectangle((92, 7, 111, 9), fill=(31, 67, 64, 230))
    image.save(OUT / "scope.png")


def icon(name, pixels, colour, shadow=True):
    image = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    if shadow:
        for x, y in pixels:
            if x + 1 < 8 and y + 1 < 8:
                d.point((x + 1, y + 1), fill=(2, 6, 7, 210))
    for x, y in pixels:
        d.point((x, y), fill=colour)
    image.save(OUT / f"{name}.png")


def world_marker(name, colour, protected=False):
    image = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    dark = (4, 10, 11, 220)
    corners = [((2, 8), (2, 2), (8, 2)), ((19, 2), (25, 2), (25, 8)),
               ((2, 19), (2, 25), (8, 25)), ((19, 25), (25, 25), (25, 19))]
    for points in corners:
        shifted = [(x + 1, y + 1) for x, y in points]
        d.line(shifted, fill=dark, width=2)
        d.line(points, fill=colour, width=2)
    if protected:
        d.rectangle((12, 5, 15, 22), fill=dark)
        d.rectangle((5, 12, 22, 15), fill=dark)
        d.rectangle((13, 6, 14, 21), fill=colour)
        d.rectangle((6, 13, 21, 14), fill=colour)
    else:
        d.polygon(((14,4),(18,8),(14,12),(10,8)), fill=dark)
        d.line(((14,5),(17,8),(14,11),(11,8),(14,5)), fill=colour, width=1)
    image.save(OUT / f"{name}.png")


frame()
icon("player", [(3,1),(2,2),(3,2),(4,2),(1,3),(2,3),(3,3),(4,3),(5,3),(3,4),(3,5)], (205,235,220,255))
icon("air", [(3,1),(2,2),(4,2),(1,3),(5,3),(2,4),(3,4),(4,4)], (222,104,77,255))
icon("ground", [(1,1),(2,1),(3,1),(4,1),(5,1),(1,2),(5,2),(1,3),(5,3),(1,4),(2,4),(3,4),(4,4),(5,4)], (226,189,83,255))
icon("sea", [(1,2),(2,2),(3,2),(4,2),(5,2),(2,3),(3,3),(4,3),(3,4)], (89,169,190,255))
icon("boss", [(3,0),(2,1),(4,1),(1,2),(5,2),(0,3),(6,3),(1,4),(5,4),(2,5),(3,6),(4,5)], (242,75,66,255))
icon("missile", [(3,0),(2,2),(3,1),(4,2),(3,3),(3,4),(2,5),(4,5)], (255,78,58,255))
icon("objective", [(3,0),(3,1),(0,3),(1,3),(2,3),(3,3),(4,3),(5,3),(6,3),(3,4),(3,5),(3,6)], (101,205,169,255))
icon("protected", [(2,1),(3,1),(4,1),(1,2),(5,2),(1,3),(5,3),(1,4),(5,4),(2,5),(3,5),(4,5)], (104,181,210,255))
world_marker("objective_marker", (105, 211, 172, 255))
world_marker("protected_marker", (104, 181, 210, 255), True)
print(OUT)
