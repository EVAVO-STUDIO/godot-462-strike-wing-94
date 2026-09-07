from pathlib import Path

from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/runtime/environments/river_chunks"
SOURCE = ROOT / "assets/source/environments/river_chunks/expanded_districts"
RUNTIME = ROOT / "assets/runtime/environments/river_chunks"
REVIEW = ROOT / "work/river_route_expansion_review.png"

DISTRICTS = [
    ("evacuation_floodway", "floodplain.png", 1.06, 0.86, 1.01),
    ("artillery_island", "defended_crossing.png", 1.10, 0.73, 0.93),
    ("estuary_shipyard", "industrial_bend.png", 1.08, 0.79, 0.96),
]


def build_district(name, base_name, contrast, colour, brightness):
    original = Image.open(BASE / base_name).convert("RGB")
    result = original.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    result = ImageEnhance.Contrast(result).enhance(contrast)
    result = ImageEnhance.Color(result).enhance(colour)
    result = ImageEnhance.Brightness(result).enhance(brightness)
    # Restore shared water connectors after grading. The complete bridge,
    # patrol craft, wakes, current, artillery and protected traffic stay separate.
    result.paste(original.crop((0, 0, 640, 48)), (0, 0))
    result.paste(original.crop((0, 976, 640, 1024)), (0, 976))
    SOURCE.mkdir(parents=True, exist_ok=True)
    RUNTIME.mkdir(parents=True, exist_ok=True)
    result.save(SOURCE / f"{name}.png", optimize=True)
    result.save(RUNTIME / f"{name}.png", optimize=True)
    return result


def main():
    results = [build_district(*district) for district in DISTRICTS]
    review = Image.new("RGB", (960, 512), (8, 24, 23))
    for index, district in enumerate(results):
        review.paste(district.resize((320, 512)), (index * 320, 0))
    REVIEW.parent.mkdir(parents=True, exist_ok=True)
    review.save(REVIEW, optimize=True)
    print(f"Built {len(results)} river route districts and {REVIEW}")


if __name__ == "__main__":
    main()
