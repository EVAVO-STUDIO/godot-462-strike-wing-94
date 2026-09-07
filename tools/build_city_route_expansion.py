from pathlib import Path
from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/runtime/environments/city_chunks"
SOURCE = ROOT / "assets/source/environments/city_chunks/expanded_districts"
RUNTIME = ROOT / "assets/runtime/environments/city_chunks"
REVIEW = ROOT / "work/city_route_expansion_review.png"

DISTRICTS = [
    ("evacuation_grid", "freight_belt.png", 0.94, 0.88, 0.97),
    ("drainage_quarter", "flooded_underpass.png", 1.04, 0.78, 0.92),
    ("conversion_trench", "machine_foundations.png", 1.08, 0.70, 0.90),
]

def build_district(name, base_name, contrast, colour, brightness):
    original = Image.open(BASE / base_name).convert("RGB")
    result = original.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    result = ImageEnhance.Contrast(result).enhance(contrast)
    result = ImageEnhance.Color(result).enhance(colour)
    result = ImageEnhance.Brightness(result).enhance(brightness)
    # Preserve shared route connectors after grading. Destroyable targets,
    # protected sites, trains and traffic remain independent runtime layers.
    result.paste(original.crop((0, 0, 640, 48)), (0, 0))
    result.paste(original.crop((0, 976, 640, 1024)), (0, 976))
    SOURCE.mkdir(parents=True, exist_ok=True)
    RUNTIME.mkdir(parents=True, exist_ok=True)
    result.save(SOURCE / f"{name}.png", optimize=True)
    result.save(RUNTIME / f"{name}.png", optimize=True)
    return result

def main():
    results = [build_district(*district) for district in DISTRICTS]
    review = Image.new("RGB", (960, 512), (12, 18, 23))
    for index, district in enumerate(results):
        review.paste(district.resize((320, 512)), (index * 320, 0))
    REVIEW.parent.mkdir(parents=True, exist_ok=True)
    review.save(REVIEW, optimize=True)
    print(f"Built {len(results)} city route districts and {REVIEW}")

if __name__ == "__main__":
    main()
