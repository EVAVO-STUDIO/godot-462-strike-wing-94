from pathlib import Path
from math import sin, tau
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/runtime/environments/mountain_weather_animation"
SOURCE = ROOT / "assets/source/environments/mountain_snow_shear_v2"
WIDTH, HEIGHT = 224, 144
FRAMES = 6


def ribbon_points(y: float, phase: float, thickness: float) -> list[tuple[float, float]]:
    top = []
    bottom = []
    for x in range(-20, WIDTH + 31, 12):
        wave = sin(x * 0.041 + phase) * 4.0 + sin(x * 0.089 + phase * 0.7) * 2.0
        top.append((x, y + wave - thickness * 0.5))
        bottom.append((x, y + wave + thickness * 0.5))
    return top + list(reversed(bottom))


def build_frame(index: int) -> Image.Image:
    image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    mist = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(mist)
    phase = index / FRAMES * tau
    for band, (y, thickness, alpha) in enumerate(((28, 13, 34), (66, 18, 42), (96, 11, 29))):
        shifted_y = y + sin(phase + band * 1.8) * 5.0
        draw.polygon(ribbon_points(shifted_y, phase + band, thickness), fill=(190, 204, 211, alpha))
        draw.line(ribbon_points(shifted_y - thickness * 0.26, phase + band, 1.0)[:20], fill=(226, 232, 234, alpha + 12), width=1)
    mist = mist.filter(ImageFilter.GaussianBlur(2.2))
    image.alpha_composite(mist)
    flecks = ImageDraw.Draw(image)
    for n in range(18):
        x = int((n * 47 + index * 19 + 13) % WIDTH)
        y = int((n * 29 + index * 11 + 7) % HEIGHT)
        size = 1 if n % 4 else 2
        alpha = 36 + (n * 11 % 35)
        flecks.ellipse((x - size, y - size, x + size, y + size), fill=(222, 229, 231, alpha))
    return image


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    SOURCE.mkdir(parents=True, exist_ok=True)
    contact = Image.new("RGBA", (WIDTH * 3, HEIGHT * 2), (9, 16, 21, 255))
    for index in range(FRAMES):
        frame = build_frame(index)
        frame.save(OUTPUT / f"shear_{index}.png", optimize=True)
        contact.alpha_composite(frame, ((index % 3) * WIDTH, (index // 3) * HEIGHT))
    contact.convert("RGB").save(SOURCE / "mountain_snow_shear_contact_sheet.png", optimize=True)


if __name__ == "__main__":
    main()
