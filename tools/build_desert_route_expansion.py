from pathlib import Path

from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/runtime/environments/desert_chunks"
SOURCE = ROOT / "assets/source/environments/desert_chunks/expanded_districts"
RUNTIME = ROOT / "assets/runtime/environments/desert_chunks"
REVIEW = ROOT / "work/desert_route_expansion_review.png"

DISTRICTS = [
    ("salt_escarpment", "armour_approach.png", 1.07, 0.80, 1.02),
    ("scud_dispersal", "wadi_crossing.png", 1.10, 0.70, 0.94),
    ("railhead_basin", "logistics_belt.png", 1.05, 0.86, 0.98),
]


def build_district(name, base_name, contrast, colour, brightness):
    original = Image.open(BASE / base_name).convert("RGB")
    result = original.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    result = ImageEnhance.Contrast(result).enhance(contrast)
    result = ImageEnhance.Color(result).enhance(colour)
    result = ImageEnhance.Brightness(result).enhance(brightness)
    # Restore only the exact boundary scanline after grading. Copying 48-row
    # edge blocks into the mirrored district created hard horizontal bands at
    # rows 48 and 976 even though the outermost seam itself tested cleanly.
    result.paste(original.crop((0, 0, 640, 1)), (0, 0))
    result.paste(original.crop((0, 1023, 640, 1024)), (0, 1023))
    SOURCE.mkdir(parents=True, exist_ok=True)
    RUNTIME.mkdir(parents=True, exist_ok=True)
    result.save(SOURCE / f"{name}.png", optimize=True)
    result.save(RUNTIME / f"{name}.png", optimize=True)
    return result


def main():
    results = [build_district(*district) for district in DISTRICTS]
    review = Image.new("RGB", (960, 512), (31, 22, 13))
    for index, district in enumerate(results):
        review.paste(district.resize((320, 512)), (index * 320, 0))
    REVIEW.parent.mkdir(parents=True, exist_ok=True)
    review.save(REVIEW, optimize=True)
    print(f"Built {len(results)} desert route districts and {REVIEW}")


if __name__ == "__main__":
    main()
