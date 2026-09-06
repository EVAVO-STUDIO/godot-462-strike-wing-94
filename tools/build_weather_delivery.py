"""Repackage reviewed EVAVO weather samples; no generation or approval implied."""
import hashlib
import json
from pathlib import Path
import shutil

root = Path(__file__).resolve().parents[1]
source = root / "assets/source/environments"
hashes = json.loads((source / "weather_placement_v1/runtime_source_hashes.json").read_text())
for relative, expected in hashes.items():
    if hashlib.sha256((root / relative).read_bytes()).hexdigest() != expected:
        raise SystemExit(f"Reviewed weather input changed: {relative}")
placement = json.loads((source / "weather_placement_v1/placement.json").read_text())
for name, expected in placement["source_catalogue_sha256"].items():
    if hashlib.sha256((root / "data" / name).read_bytes()).hexdigest() != expected:
        raise SystemExit(f"Weather placement needs review for changed catalogue: {name}")
out = root / "data/weather"
out.mkdir(exist_ok=True)
for name in ["drizzle", "rain", "storm"]:
    shutil.copyfile(source / f"rain_flight_v4/{name}_plan.json", out / f"{name}_plan.json")
shutil.copyfile(source / "snow_flight_v4/states.json", out / "snow_states.json")
config = {
    "schema_version": 1,
    "altitude_weights": placement["altitude_precipitation_weights"],
    "missions": {row["mission_id"]: row["precipitation"] for row in placement["missions"]},
    "orbital_exclusions": [row["mission_id"] for row in placement["missions"] if row["orbital_exclusion"]],
}
(out / "placement.json").write_text(json.dumps(config, indent=2) + "\n", newline="\n")
print("Weather delivery rebuilt from hash-verified reviewed sources.")
