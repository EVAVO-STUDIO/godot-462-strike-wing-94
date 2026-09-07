from pathlib import Path
from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/runtime/environments/refinery_chunks"
MODULES = ROOT / "assets/runtime/environments/modular_refinery"
SOURCE = ROOT / "assets/source/environments/refinery_chunks/expanded_districts"
RUNTIME = ROOT / "assets/runtime/environments/refinery_chunks"
REVIEW = ROOT / "work/refinery_route_expansion_review.png"

DISTRICTS = [
    ("flare_service_yard", "tank_farm.png", [
        ("cracking_tower_a.png", (72, 172)), ("cracking_tower_c.png", (148, 166)),
        ("generator_house.png", (360, 226)), ("pipe_rack_long.png", (310, 390)),
        ("tank_cluster_mixed.png", (424, 676)),
    ], 0.94),
    ("pressure_grid", "cracking_corridor.png", [
        ("transformer_yard.png", (68, 210)), ("substation.png", (392, 224)),
        ("valve_manifold.png", (224, 450)), ("pump_bank.png", (462, 616)),
        ("cooling_bank.png", (74, 754)),
    ], 1.03),
    ("evacuation_terminal", "rail_loading.png", [
        ("maintenance_gantry.png", (205, 168)), ("generator_house.png", (368, 384)),
        ("tank_cluster_heavy.png", (72, 586)), ("transformer_yard.png", (348, 742)),
        ("hazard_lamps.png", (181, 916)),
    ], 0.98),
]

def composite_district(name, base_name, placements, contrast):
    original = Image.open(BASE / base_name).convert("RGBA")
    result = original.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    result = ImageEnhance.Contrast(result).enhance(contrast)
    # Restore the common connector after grading so all six districts retain
    # byte-identical entry and exit scanlines at any flight speed.
    result.paste(original.crop((0, 0, 640, 48)), (0, 0))
    result.paste(original.crop((0, 976, 640, 1024)), (0, 976))
    for module_name, position in placements:
        module = Image.open(MODULES / module_name).convert("RGBA")
        # Runtime construction sprites are intentionally crisp for combat use.
        # Grade their alpha into the geography plate so baked district landmarks
        # inherit the same night exposure instead of reading as pasted overlays.
        module.putalpha(module.getchannel("A").point(lambda alpha: int(alpha * 0.76)))
        result.alpha_composite(module, position)
    SOURCE.mkdir(parents=True, exist_ok=True)
    RUNTIME.mkdir(parents=True, exist_ok=True)
    result.save(SOURCE / f"{name}.png", optimize=True)
    result.save(RUNTIME / f"{name}.png", optimize=True)
    return result

def main():
    results = [composite_district(*district) for district in DISTRICTS]
    review = Image.new("RGB", (960, 512), (13, 20, 25))
    for index, district in enumerate(results):
        review.paste(district.convert("RGB").resize((320, 512)), (index * 320, 0))
    REVIEW.parent.mkdir(parents=True, exist_ok=True)
    review.save(REVIEW, optimize=True)
    print(f"Built {len(results)} refinery route districts and {REVIEW}")

if __name__ == "__main__":
    main()
