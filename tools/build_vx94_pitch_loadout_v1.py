from __future__ import annotations

import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/craft/vx94/pitch_relief_v3/clean"
CONVENTIONAL = ROOT / "assets/source/craft/vx94/banked_primary_housings_v2/layers"
SPECIALIST = ROOT / "assets/source/craft/vx94/specialist_housings_v2/layers"
RUNTIME = ROOT / "assets/runtime/craft/vx94/gameplay"
PITCH_OUT = RUNTIME / "pitch"
PRIMARY_OUT = RUNTIME / "pitch_primary"

FORMS = ("fighter", "bomber")
PITCHES = ("dive_18", "dive_12", "dive_06", "neutral", "climb_06", "climb_12", "climb_18")
FAMILIES = ("ballistic", "needle_rail", "storm_cannon", "plasma_lance")
STATES = range(4)


def load(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    if image.size != (64, 72):
        raise ValueError(f"{path} is {image.size}, expected 64x72")
    return image


def over(base: Image.Image, layer: Path) -> Image.Image:
    if not layer.exists():
        return base
    return Image.alpha_composite(base, load(layer))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def build() -> None:
    PITCH_OUT.mkdir(parents=True, exist_ok=True)
    PRIMARY_OUT.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    for form in FORMS:
        for pitch in PITCHES:
            source = SOURCE / f"{form}_{pitch}.png"
            pitch_target = PITCH_OUT / f"{form}_{pitch}.png"
            shutil.copyfile(source, pitch_target)
            written.append(pitch_target)
            airframe = load(source)
            for family in FAMILIES:
                for state in STATES:
                    if family == "ballistic":
                        prefix = f"{form}_neutral_{state}"
                        if form == "fighter":
                            composite = over(Image.new("RGBA", (64, 72)), CONVENTIONAL / f"{prefix}_0.png")
                            composite = Image.alpha_composite(composite, airframe)
                            composite = over(composite, CONVENTIONAL / f"{prefix}_1.png")
                        else:
                            composite = over(Image.new("RGBA", (64, 72)), CONVENTIONAL / f"{prefix}_0.png")
                            composite = Image.alpha_composite(composite, airframe)
                    else:
                        prefix = f"{family}_{form}_neutral_{state}"
                        composite = over(Image.new("RGBA", (64, 72)), SPECIALIST / f"{prefix}.png")
                        composite = Image.alpha_composite(composite, airframe)
                        composite = over(composite, SPECIALIST / f"{prefix}_aperture.png")
                    target = PRIMARY_OUT / f"{family}_{form}_{pitch}_{state}.png"
                    composite.save(target, optimize=True)
                    written.append(target)

    receipt = {
        "schema": "hypersonic_vx94_pitch_loadout_runtime_v1",
        "status": "generated_candidate",
        "canvas": [64, 72],
        "pivot": [32, 38],
        "forms": list(FORMS),
        "pitch_states": list(PITCHES),
        "weapon_families": list(FAMILIES),
        "hardware_states": 4,
        "pitch_frames": 14,
        "weapon_pitch_composites": 224,
        "source_policy": "Immutable reviewed pitch airframes plus retained separated weapon layers.",
        "files": [
            {"path": path.relative_to(ROOT).as_posix(), "sha256": sha256(path)}
            for path in written
        ],
    }
    receipt_path = ROOT / "assets/source/craft/vx94/pitch_relief_v3/runtime_loadout_integration.json"
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    build()
