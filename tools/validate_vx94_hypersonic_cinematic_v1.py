from __future__ import annotations
import json, subprocess
from pathlib import Path
from PIL import Image, ImageChops

ROOT=Path(__file__).resolve().parents[1]
PACKAGE=ROOT/"assets/source/cinematics/vx94_hypersonic_break_v1"

def require(condition:bool,message:str)->None:
    if not condition: raise AssertionError(message)

manifest=json.loads((PACKAGE/"manifest.json").read_text(encoding="utf-8"))
source=json.loads((PACKAGE/"source_manifest.json").read_text(encoding="utf-8"))
require(manifest["frame_rate"]==24 and manifest["frame_count"]==288,"cinematic timing must remain 12 seconds at 24 fps")
require(len(manifest["beats"])==6,"cinematic must retain its six authored editorial beats")
require(len(source["keys"])==5,"cinematic must retain five registered production keys")
require(any("no rain" in item for item in source["locks"]),"above-cloud precipitation rejection must remain explicit")
keys=[]
for item in source["keys"]:
    image=Image.open(PACKAGE/item["file"]).convert("RGB")
    require(image.width/image.height>1.6,"production key must remain widescreen")
    keys.append(image.resize((320,180)))
for index in range(len(keys)-1):
    require(ImageChops.difference(keys[index],keys[index+1]).getbbox() is not None,"adjacent production keys must be visually distinct")
probe=subprocess.run(["ffprobe","-v","error","-show_entries","stream=codec_name,width,height,r_frame_rate,duration","-of","json",str(PACKAGE/"vx94_hypersonic_break_v1.mp4")],check=True,capture_output=True,text=True)
stream=json.loads(probe.stdout)["streams"][0]
require(stream["codec_name"]=="h264" and stream["width"]==640 and stream["height"]==360,"review MP4 must remain H.264 at the game's 640x360 composition")
require(stream["r_frame_rate"]=="24/1" and abs(float(stream["duration"])-12.0)<0.01,"review MP4 duration and cadence must match the X-sheet")
for frame in (0,64,92,120,143,151,168,216,287):
    proof=Image.open(PACKAGE/f"proofs/frame_{frame:04d}.png")
    require(proof.size==(640,360),f"proof frame {frame} has invalid geometry")
print("HYPERSONIC VX-94 hypersonic cinematic v1 validation passed.")
