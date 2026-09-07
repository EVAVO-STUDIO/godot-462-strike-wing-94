from pathlib import Path
from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/runtime/environments/harbor_chunks"
SOURCE = ROOT / "assets/source/environments/harbor_chunks/expanded_districts"
RUNTIME = ROOT / "assets/runtime/environments/harbor_chunks"
REVIEW = ROOT / "work/harbor_route_expansion_review.png"

DISTRICTS = [
    ("offshore_mole", "outer_breakwater.png", 1.04, 0.84, 0.95),
    ("drydock_row", "repair_basin.png", 1.08, 0.72, 0.91),
    ("blackout_basin", "command_docks.png", 1.11, 0.66, 0.86),
]

def build_district(name, base_name, contrast, colour, brightness):
    original = Image.open(BASE / base_name).convert("RGB")
    result = original.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    result = ImageEnhance.Contrast(result).enhance(contrast)
    result = ImageEnhance.Color(result).enhance(colour)
    result = ImageEnhance.Brightness(result).enhance(brightness)
    # Reapply only the exact outer scanline after grading. Wide inherited edge
    # blocks created hard bands inside every mirrored harbor district.
    result.paste(original.crop((0, 0, 640, 1)), (0, 0))
    result.paste(original.crop((0, 1023, 640, 1024)), (0, 1023))
    SOURCE.mkdir(parents=True, exist_ok=True)
    RUNTIME.mkdir(parents=True, exist_ok=True)
    result.save(SOURCE / f"{name}.png", optimize=True)
    result.save(RUNTIME / f"{name}.png", optimize=True)
    return result

def main():
    results = [build_district(*district) for district in DISTRICTS]
    review = Image.new("RGB", (960, 512), (5, 13, 22))
    for index, district in enumerate(results):
        review.paste(district.resize((320, 512)), (index * 320, 0))
    REVIEW.parent.mkdir(parents=True, exist_ok=True)
    review.save(REVIEW, optimize=True)
    print(f"Built {len(results)} harbor route districts and {REVIEW}")

if __name__ == "__main__":
    main()
