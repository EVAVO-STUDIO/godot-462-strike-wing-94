from pathlib import Path
from PIL import Image, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/cinematics/carrier_launch_v1"
RUNTIME = ROOT / "assets/runtime/cinematics/plates"

PLATES = {
    "launch_deck_ready": "launch_deck_ready_raw.png",
    "launch_cockpit": "launch_cockpit_raw.png",
    "launch_climbout": "launch_climbout_raw.png",
}


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    ratio = max(size[0] / image.width, size[1] / image.height)
    scaled = image.resize(
        (round(image.width * ratio), round(image.height * ratio)),
        Image.Resampling.LANCZOS,
    )
    left = (scaled.width - size[0]) // 2
    top = (scaled.height - size[1]) // 2
    return scaled.crop((left, top, left + size[0], top + size[1]))


def finish(image: Image.Image) -> Image.Image:
    image = cover(image.convert("RGB"), (640, 320))
    image = ImageEnhance.Color(image).enhance(0.86)
    image = ImageEnhance.Contrast(image).enhance(1.10)
    image = ImageEnhance.Sharpness(image).enhance(1.18)
    # Stable, game-sized limited palette with a light final cleanup pass.
    image = image.quantize(colors=96, method=Image.Quantize.MEDIANCUT).convert("RGB")
    return image.filter(ImageFilter.UnsharpMask(radius=0.7, percent=55, threshold=3))


def main() -> None:
    RUNTIME.mkdir(parents=True, exist_ok=True)
    for runtime_name, source_name in PLATES.items():
        source_path = SOURCE / source_name
        if not source_path.exists():
            raise FileNotFoundError(source_path)
        output_path = RUNTIME / f"{runtime_name}.png"
        finish(Image.open(source_path)).save(output_path, optimize=True)
        print(f"built {output_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
