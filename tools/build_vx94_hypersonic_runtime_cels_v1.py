from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/cinematics/vx94_hypersonic_break_v1/proofs"
OUTPUT = ROOT / "assets/runtime/cinematics/cel/vx94_hypersonic_break"
FRAMES = (0, 64, 92, 120, 143, 151, 168, 216, 287)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for output_index, source_index in enumerate(FRAMES):
        source = SOURCE / f"frame_{source_index:04d}.png"
        if not source.exists():
            raise FileNotFoundError(source)
        image = Image.open(source).convert("RGBA")
        if image.size != (640, 360):
            image = image.resize((640, 360), Image.Resampling.LANCZOS)
        image.save(OUTPUT / f"{output_index}.png", optimize=True)


if __name__ == "__main__":
    main()
