from pathlib import Path

from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/runtime/environments/orbital_chunks"
SOURCE = ROOT / "assets/source/environments/orbital_chunks/expanded_districts"
RUNTIME = ROOT / "assets/runtime/environments/orbital_chunks"
REVIEW = ROOT / "work/orbital_route_expansion_review.png"

DISTRICTS = [
    ("dawn_rail_shadow", "kinetic_rail_platform.png", 1.08, 0.78, 1.02),
    ("debris_foundry", "dead_lattice.png", 1.12, 0.64, 0.90),
    ("ark_escape_vector", "ark_industrial_approach.png", 1.10, 0.72, 0.96),
]


def build_district(name, base_name, contrast, colour, brightness):
    original = Image.open(BASE / base_name).convert("RGBA")
    flipped = original.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    alpha = flipped.getchannel("A")
    result = ImageEnhance.Contrast(flipped.convert("RGB")).enhance(contrast)
    result = ImageEnhance.Color(result).enhance(colour)
    result = ImageEnhance.Brightness(result).enhance(brightness).convert("RGBA")
    result.putalpha(alpha)
    # Restore common transparent connectors after grading. Debris, thrusters,
    # weapon fire, satellites and the Earth limb remain independent layers.
    result.paste(original.crop((0, 0, 640, 48)), (0, 0))
    result.paste(original.crop((0, 976, 640, 1024)), (0, 976))
    SOURCE.mkdir(parents=True, exist_ok=True)
    RUNTIME.mkdir(parents=True, exist_ok=True)
    result.save(SOURCE / f"{name}.png", optimize=True)
    result.save(RUNTIME / f"{name}.png", optimize=True)
    return result


def main():
    results = [build_district(*district) for district in DISTRICTS]
    review = Image.new("RGB", (960, 512), (4, 9, 18))
    for index, district in enumerate(results):
        plate = Image.new("RGBA", district.size, (4, 9, 18, 255))
        plate.alpha_composite(district)
        review.paste(plate.convert("RGB").resize((320, 512)), (index * 320, 0))
    REVIEW.parent.mkdir(parents=True, exist_ok=True)
    review.save(REVIEW, optimize=True)
    print(f"Built {len(results)} orbital route districts and {REVIEW}")


if __name__ == "__main__":
    main()
