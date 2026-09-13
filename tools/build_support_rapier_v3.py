from pathlib import Path
from PIL import Image, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/support/aircraft_v3/rapier_fighter/mastered_v1.png"
OUTPUT = ROOT / "assets/runtime/support/battlefield/rapier_fighter"
FRAME_SIZE = (48, 28)
CONTENT_SIZE = (46, 26)
ENGINE_POINTS = ((37, 8), (37, 19))


def alpha_bounds(image: Image.Image) -> tuple[int, int, int, int]:
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise RuntimeError("Rapier master has no visible alpha content")
    return bounds


def build_base() -> Image.Image:
    source = Image.open(SOURCE).convert("RGBA")
    if any(source.getpixel(point)[3] != 0 for point in ((0, 0), (source.width - 1, 0), (0, source.height - 1), (source.width - 1, source.height - 1))):
        raise RuntimeError("Rapier master must retain transparent canvas corners")
    aircraft = source.crop(alpha_bounds(source)).resize(CONTENT_SIZE, Image.Resampling.LANCZOS)
    rgb = ImageEnhance.Contrast(aircraft.convert("RGB")).enhance(1.12)
    aircraft = Image.merge("RGBA", (*rgb.split(), aircraft.getchannel("A"))).filter(ImageFilter.UnsharpMask(radius=0.65, percent=72, threshold=3))
    frame = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
    frame.alpha_composite(aircraft, (1, 1))
    return frame


def engine_cadence(frame: Image.Image, phase: int) -> None:
    palette = ((205, 91, 22, 220), (255, 153, 41, 245), (255, 214, 112, 255), (255, 128, 28, 238))
    core = palette[phase]
    halo = (255, 119, 24, (40, 64, 88, 58)[phase])
    pixels = frame.load()
    for x, y in ENGINE_POINTS:
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            px, py = x + dx, y + dy
            current = pixels[px, py]
            pixels[px, py] = tuple(max(current[i], halo[i]) for i in range(4))
        pixels[x, y] = core
        if phase == 2:
            pixels[x - 1, y] = (255, 184, 64, 250)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    base = build_base()
    for phase in range(4):
        frame = base.copy()
        engine_cadence(frame, phase)
        frame.save(OUTPUT / f"{phase}.png", optimize=True)
    contact = Image.new("RGBA", (FRAME_SIZE[0] * 12, FRAME_SIZE[1] * 12 * 4), (14, 18, 20, 255))
    for phase in range(4):
        enlarged = Image.open(OUTPUT / f"{phase}.png").resize((FRAME_SIZE[0] * 12, FRAME_SIZE[1] * 12), Image.Resampling.NEAREST)
        contact.alpha_composite(enlarged, (0, phase * FRAME_SIZE[1] * 12))
    proof = ROOT / "work/support_rapier_v3_contact.png"
    proof.parent.mkdir(parents=True, exist_ok=True)
    contact.convert("RGB").save(proof, quality=94)
    print(f"Built 4 Rapier frames and {proof}")


if __name__ == "__main__":
    main()
