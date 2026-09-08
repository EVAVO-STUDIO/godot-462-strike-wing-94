"""Build HYPERSONIC's deterministic, original storm thunder transient."""
from __future__ import annotations

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/audio/weather_audio_v1/thunder/thunder_strike.wav"
RUNTIME = ROOT / "assets/runtime/audio/weather/thunder_strike.wav"
MANIFEST = ROOT / "assets/source/audio/weather_audio_v1/thunder/audio_review.json"
RATE = 22050
DURATION = 3.2


def build() -> list[tuple[float, float]]:
    rng = random.Random(9494)
    frames: list[tuple[float, float]] = []
    low = 0.0
    roll = 0.0
    for index in range(round(RATE * DURATION)):
        t = index / RATE
        noise = rng.uniform(-1.0, 1.0)
        low += 0.018 * (noise - low)
        roll += 0.0045 * (noise - roll)
        crack = math.exp(-t * 34.0) * (0.50 * noise + 0.34 * math.sin(2 * math.pi * 83 * t))
        body_env = (1.0 - math.exp(-t * 24.0)) * math.exp(-t * 1.55)
        body = body_env * (1.75 * low + 0.62 * roll + 0.12 * math.sin(2 * math.pi * 41 * t))
        echo = 0.0
        for delay, gain, freq in ((0.31, 0.24, 37), (0.68, 0.17, 29), (1.12, 0.11, 23)):
            age = t - delay
            if age >= 0:
                echo += gain * math.exp(-age * 1.8) * (roll * 2.2 + math.sin(2 * math.pi * freq * age) * 0.12)
        fade = min(1.0, t / 0.004, (DURATION - t) / 0.12)
        mono = max(-0.92, min(0.92, (crack + body + echo) * fade))
        width = low * body_env * 0.10
        frames.append((mono + width, mono - width))
    return frames


def write_wav(path: Path, frames: list[tuple[float, float]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = bytearray()
    for left, right in frames:
        pcm.extend(struct.pack("<hh", round(max(-1, min(1, left)) * 32767), round(max(-1, min(1, right)) * 32767)))
    with wave.open(str(path), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm)


frames = build()
write_wav(SOURCE, frames)
write_wav(RUNTIME, frames)
digest = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
peak = max(max(abs(a), abs(b)) for a, b in frames)
MANIFEST.write_text(json.dumps({
    "schema": "hypersonic_audio_studio_transient_v1",
    "identity": "distant conventional thunder: dry crack, low pressure body, three irregular rolls",
    "source": "tools/build_weather_thunder.py",
    "runtime": "res://assets/runtime/audio/weather/thunder_strike.wav",
    "sha256": digest,
    "sample_rate": RATE,
    "channels": 2,
    "duration_seconds": DURATION,
    "peak": round(peak, 6),
    "clipped_samples": 0,
    "loop": False,
    "review_status": "runtime_candidate_pending_final_listen"
}, indent=2) + "\n", encoding="utf-8")
print(f"built {RUNTIME} sha256={digest} peak={peak:.4f}")
