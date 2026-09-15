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


def bank_pose(level: Image.Image, bank: int) -> Image.Image:
    if bank == 0:
        return level.copy()
    cy = FRAME_SIZE[1] // 2
    upper = level.crop((0, 0, FRAME_SIZE[0], cy))
    lower = level.crop((0, cy, FRAME_SIZE[0], FRAME_SIZE[1]))
    upper_height, lower_height = ((11, 13) if bank < 0 else (13, 11))
    posed = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
    posed.alpha_composite(upper.resize((FRAME_SIZE[0], upper_height), Image.Resampling.LANCZOS), (0, cy-upper_height))
    posed.alpha_composite(lower.resize((FRAME_SIZE[0], lower_height), Image.Resampling.LANCZOS), (0, cy))
    pixels = posed.load()
    y_range = range(cy, FRAME_SIZE[1]) if bank < 0 else range(0, cy)
    for y in y_range:
        for x in range(FRAME_SIZE[0]):
            r, g, b, a = pixels[x, y]
            if a:
                pixels[x, y] = (int(r*0.76), int(g*0.79), int(b*0.82), a)
    return posed


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    base = build_base()
    banks = (("left", -1), ("level", 0), ("right", 1))
    rows = []
    for name, value in banks:
        frames = []
        for phase in range(4):
            posed = bank_pose(base, value)
            engine_cadence(posed, phase)
            posed.save(OUTPUT / f"{name}_{phase}.png", optimize=True)
            if name == "level":
                posed.save(OUTPUT / f"{phase}.png", optimize=True)
            frames.append(posed)
        rows.append(frames)
    scale = 10
    contact = Image.new("RGBA", (FRAME_SIZE[0]*4*scale,FRAME_SIZE[1]*3*scale),(14,18,20,255))
    for row, frames in enumerate(rows):
        for column, frame in enumerate(frames):
            contact.alpha_composite(frame.resize((FRAME_SIZE[0]*scale,FRAME_SIZE[1]*scale),Image.Resampling.NEAREST),(column*FRAME_SIZE[0]*scale,row*FRAME_SIZE[1]*scale))
    proof = ROOT / "work/support_rapier_v3_contact.png"
    proof.parent.mkdir(parents=True, exist_ok=True)
    contact.convert("RGB").save(proof, quality=94)
    print(f"Built 12 Rapier bank/cadence frames, 4 compatibility frames and {proof}")


if __name__ == "__main__":
    main()
