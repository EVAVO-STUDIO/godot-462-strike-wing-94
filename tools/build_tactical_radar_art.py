from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "runtime" / "ui" / "hud" / "tactical_radar"
OUT.mkdir(parents=True, exist_ok=True)


def frame():
    image = Image.new("RGBA", (100, 80), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    # The terrain remains visible through the glass. Corners and broken rules
    # imply a late-90s avionics bezel without laying a dark rectangle over play.
    d.rectangle((1, 1, 98, 78), fill=(3, 14, 18, 66))
    for a, b, c in [((1,9),(1,1),(14,1)),((85,1),(98,1),(98,9)),
                    ((1,70),(1,78),(14,78)),((85,78),(98,78),(98,70))]:
        d.line((a,b,c), fill=(82, 145, 145, 205), width=1)
    d.line((5,14,31,14), fill=(75,132,128,150))
    d.line((69,14,94,14), fill=(75,132,128,150))
    for y in range(22, 75, 8):
        d.line((7,y,92,y), fill=(20,60,59,35))
    # Forward-flight presentation: the narrow end is the long-range horizon and
    # the wide end is the aircraft. Three broken range gates read cleanly over
    # detailed terrain while retaining the late-90s monochrome scope character.
    d.line((50, 17, 50, 74), fill=(52, 105, 94, 110))
    d.line((28, 18, 43, 74), fill=(28, 66, 62, 82))
    d.line((72, 18, 57, 74), fill=(28, 66, 62, 82))
    for box in ((34, 23, 66, 44), (25, 29, 75, 59), (16, 36, 84, 77)):
        d.arc(box, 202, 255, fill=(62, 120, 106, 190), width=1)
        d.arc(box, 285, 338, fill=(62, 120, 106, 190), width=1)
    for y in (24, 36, 51):
        d.line((47, y, 49, y), fill=(104, 174, 147, 180))
        d.line((51, y, 53, y), fill=(104, 174, 147, 180))
    image.save(OUT / "scope.png")


def airframe_blueprint(name, bomber=False):
    image = Image.new("RGBA", (42, 42), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    ink = (134, 221, 202, 238)
    dim = (57, 126, 122, 205)
    # Orthographic VX-94 planform, drawn as broken technical contours rather
    # than a filled arcade life icon. Bomber mode exposes the broader wing.
    nose, tail = 3, 37
    d.line((21,nose,18,11,18,31,21,tail), fill=ink, width=1)
    d.line((21,nose,24,11,24,31,21,tail), fill=ink, width=1)
    span = 18 if bomber else 14
    shoulder = 15 if bomber else 18
    d.line((18,shoulder,21-span,29,18,27), fill=ink, width=1)
    d.line((24,shoulder,21+span,29,24,27), fill=ink, width=1)
    d.line((18,30,12,36,19,33), fill=dim, width=1)
    d.line((24,30,30,36,23,33), fill=dim, width=1)
    d.line((19,12,23,12), fill=dim)
    d.line((19,22,23,22), fill=dim)
    d.point((21,8), fill=(216,239,217,255))
    image.save(OUT / f"airframe_{name}.png")


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
airframe_blueprint("fighter")
airframe_blueprint("bomber", True)
icon("player", [(3,1),(2,2),(3,2),(4,2),(1,3),(2,3),(3,3),(4,3),(5,3),(3,4),(3,5)], (205,235,220,255))
icon("air", [(3,1),(2,2),(4,2),(1,3),(5,3),(2,4),(3,4),(4,4)], (222,104,77,255))
icon("ground", [(1,1),(2,1),(3,1),(4,1),(5,1),(1,2),(5,2),(1,3),(5,3),(1,4),(2,4),(3,4),(4,4),(5,4)], (226,189,83,255))
icon("sea", [(1,2),(2,2),(3,2),(4,2),(5,2),(2,3),(3,3),(4,3),(3,4)], (89,169,190,255))
icon("boss", [(3,0),(2,1),(4,1),(1,2),(5,2),(0,3),(6,3),(1,4),(5,4),(2,5),(3,6),(4,5)], (242,75,66,255))
icon("missile", [(3,0),(2,2),(3,1),(4,2),(3,3),(3,4),(2,5),(4,5)], (255,78,58,255))
icon("objective", [(3,0),(3,1),(0,3),(1,3),(2,3),(3,3),(4,3),(5,3),(6,3),(3,4),(3,5),(3,6)], (101,205,169,255))
icon("protected", [(2,1),(3,1),(4,1),(1,2),(5,2),(1,3),(5,3),(1,4),(5,4),(2,5),(3,5),(4,5)], (104,181,210,255))
icon("altitude_up", [(3,1),(2,2),(3,2),(4,2),(1,3),(2,3),(3,3),(4,3),(5,3)], (132,205,215,255), False)
icon("altitude_down", [(1,2),(2,2),(3,2),(4,2),(5,2),(2,3),(3,3),(4,3),(3,4)], (226,189,83,255), False)
icon("altitude_level", [(1,3),(2,3),(3,3),(4,3),(5,3)], (117,169,150,255), False)
world_marker("objective_marker", (105, 211, 172, 255))
world_marker("protected_marker", (104, 181, 210, 255), True)
print(OUT)
