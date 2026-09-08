"""Finish the reviewed civilian-village concept into a registered 48px sprite."""

from collections import deque
from pathlib import Path

from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/surface_sites/mercenary_war_v2/civilian_village_v2_raw.png"
OUTPUT = ROOT / "assets/runtime/surface_sites/civilian_village_v2.png"


def background_candidate(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _alpha = pixel
    high = max(red, green, blue)
    low = min(red, green, blue)
    # The source checker is neutral grey. Saturated foliage, earth, roofs and
    # paths stop the border flood even when their values overlap the checker.
    return high >= 72 and high - low <= 23


def main() -> None:
    image = Image.open(SOURCE).convert("RGBA")
    pixels = image.load()
    width, height = image.size
    queue: deque[tuple[int, int]] = deque()
    visited: set[tuple[int, int]] = set()
    for x in range(width):
        queue.extend(((x, 0), (x, height - 1)))
    for y in range(height):
        queue.extend(((0, y), (width - 1, y)))
    while queue:
        x, y = queue.popleft()
        if (x, y) in visited or not background_candidate(pixels[x, y]):
            continue
        visited.add((x, y))
        pixels[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height:
                queue.append((nx, ny))

    bounds = image.getbbox()
    if bounds is None:
        raise SystemExit("civilian village extraction removed the complete subject")
    subject = image.crop(bounds)
    subject.thumbnail((44, 44), Image.Resampling.LANCZOS)
    subject = ImageEnhance.Contrast(subject).enhance(1.08)
    canvas = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    canvas.alpha_composite(subject, ((48 - subject.width) // 2, (48 - subject.height) // 2))
    alpha = canvas.getchannel("A")
    alpha_minimum, alpha_maximum = alpha.getextrema()
    if alpha_minimum != 0 or alpha_maximum < 254:
        raise SystemExit("transparent sprite contract failed: output lacks meaningful alpha")
    if any(canvas.getpixel(point)[3] != 0 for point in ((0, 0), (47, 0), (0, 47), (47, 47))):
        raise SystemExit("transparent sprite contract failed: canvas corners are not clear")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUTPUT, optimize=True)
    print(f"Built {OUTPUT.relative_to(ROOT)} at 48x48 with restored alpha")


if __name__ == "__main__":
    main()
