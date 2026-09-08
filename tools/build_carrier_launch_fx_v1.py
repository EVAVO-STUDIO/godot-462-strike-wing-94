from pathlib import Path
from PIL import Image, ImageDraw
import random


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/runtime/cinematics/fx/carrier_launch"
SIZE = (640, 272)


def frame() -> Image.Image:
    return Image.new("RGBA", SIZE, (0, 0, 0, 0))


def deck(index: int) -> Image.Image:
    image = frame()
    draw = ImageDraw.Draw(image, "RGBA")
    rng = random.Random(9400 + index)
    for _ in range(34):
        x = rng.randrange(-20, 660)
        y = rng.randrange(0, 250)
        length = rng.randrange(7, 17)
        draw.line((x, y, x - length, y + length * 2), fill=(155, 193, 211, 32), width=1)
    pulse = (54, 30, 16, 10)[index]
    for x, y in ((90, 220), (228, 230), (516, 225)):
        draw.ellipse((x - 6, y - 3, x + 6, y + 3), fill=(255, 170, 72, pulse))
    return image


def cockpit(index: int) -> Image.Image:
    image = frame()
    draw = ImageDraw.Draw(image, "RGBA")
    rng = random.Random(9410 + index)
    for _ in range(22):
        x = rng.randrange(0, 360)
        y = rng.randrange(0, 190)
        draw.line((x, y, x - 3, y + rng.randrange(5, 12)), fill=(177, 213, 225, 34), width=1)
    indicator = (82, 120, 82, 52)[index]
    draw.rectangle((44, 204, 50, 208), fill=(90, 226, 204, indicator))
    draw.rectangle((67, 212, 73, 216), fill=(248, 178, 70, indicator))
    return image


def airborne(index: int) -> Image.Image:
    image = frame()
    draw = ImageDraw.Draw(image, "RGBA")
    # Short conventional exhaust flicker. Hypersonic blue flare is reserved for
    # the later, altitude-safe acceleration beat.
    length = (4, 7, 5, 8)[index]
    alpha = (48, 76, 58, 84)[index]
    for x in (310, 330):
        draw.polygon(((x - 3, 109), (x + 3, 109), (x + 1, 109 + length), (x - 1, 109 + length)), fill=(255, 151, 66, alpha))
    return image


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    builders = {"launch_deck": deck, "launch_pilot": cockpit, "launch_airborne": airborne}
    for shot, builder in builders.items():
        for index in range(4):
            path = OUT / f"{shot}_{index}.png"
            builder(index).save(path, optimize=True)
            print(f"built {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
