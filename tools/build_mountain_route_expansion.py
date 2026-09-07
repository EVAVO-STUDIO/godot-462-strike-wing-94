from pathlib import Path
from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/runtime/environments/mountain_chunks"
SOURCE = ROOT / "assets/source/environments/mountain_chunks/expanded_districts"
RUNTIME = ROOT / "assets/runtime/environments/mountain_chunks"
REVIEW = ROOT / "work/mountain_route_expansion_review.png"

DISTRICTS = [
    ("glacial_switchbacks", "switchback_pass.png", 1.06, 0.88, 1.02),
    ("command_bowl", "radar_service_valley.png", 1.08, 0.72, 0.91),
    ("avalanche_cut", "ice_cliff_corridor.png", 1.12, 0.82, 0.97),
]

def build_district(name, base_name, contrast, colour, brightness):
    original = Image.open(BASE / base_name).convert("RGBA")
    result = original.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    rgb = ImageEnhance.Contrast(result.convert("RGB")).enhance(contrast)
    rgb = ImageEnhance.Color(rgb).enhance(colour)
    result = ImageEnhance.Brightness(rgb).enhance(brightness).convert("RGBA")
    # Restore common connectors after grading. Radar sites, vehicles and storm
    # particles remain independent world-registered gameplay layers.
    result.paste(original.crop((0, 0, 640, 48)), (0, 0))
    result.paste(original.crop((0, 976, 640, 1024)), (0, 976))
    SOURCE.mkdir(parents=True, exist_ok=True)
    RUNTIME.mkdir(parents=True, exist_ok=True)
    result.save(SOURCE / f"{name}.png", optimize=True)
    result.save(RUNTIME / f"{name}.png", optimize=True)
    return result

def main():
    results = [build_district(*district) for district in DISTRICTS]
    review = Image.new("RGB", (960, 512), (10, 17, 25))
    for index, district in enumerate(results):
        review.paste(district.convert("RGB").resize((320, 512)), (index * 320, 0))
    REVIEW.parent.mkdir(parents=True, exist_ok=True)
    review.save(REVIEW, optimize=True)
    print(f"Built {len(results)} mountain route districts and {REVIEW}")

if __name__ == "__main__":
    main()
