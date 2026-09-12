"""Build the VX-94 paired magnesium flare cels at registered runtime geometry."""
from hashlib import sha256
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[4]
SOURCE=ROOT/"assets/source/effects/countermeasure_v3"
RUNTIME=ROOT/"assets/runtime/effects/countermeasure"
WHITE=(255,249,218,255); PALE=(255,222,129,255); ORANGE=(249,129,43,255)
RED=(174,55,27,255); SMOKE=(118,121,113,190); SOOT=(52,58,58,150)

def flare_pair(index):
    im=Image.new("RGBA",(48,56),(0,0,0,0)); d=ImageDraw.Draw(im)
    stages=[((18,8),(30,8),4,8),((15,13),(33,13),4,14),((11,20),(37,20),3,20),((7,28),(41,28),2,24)]
    left,right,head,trail=stages[index]
    for side,(x,y) in ((-1,left),(1,right)):
        # Broken grey wake follows the ejecting cartridge and cools toward the aircraft.
        if index>=1:
            points=[(x+side*2,y-6),(x+side*3,y-10),(x+side*2,y-14)]
            if index>=2: points += [(x,y-18),(x-side*2,y-22)]
            d.line(points,fill=SOOT,width=3)
            d.line(points[:-1],fill=SMOKE,width=1)
        # Long tapered incandescent tail reads after the runtime half-scale reduction.
        d.polygon([(x-2,y+head-1),(x+2,y+head-1),(x+1,y+trail),(x,y+trail+4),(x-1,y+trail)],fill=RED)
        d.polygon([(x-2,y+2),(x+2,y+2),(x+1,y+head+5),(x-1,y+head+7)],fill=ORANGE)
        d.rectangle((x-head//2,y-head//2,x+head//2,y+head//2),fill=PALE)
        d.rectangle((x-1,y-1,x+1,y+1),fill=WHITE)
        d.point((x,y-2),fill=WHITE)
        if index<2:
            d.line([(x-5,y),(x+5,y)],fill=PALE,width=1); d.line([(x,y-5),(x,y+5)],fill=PALE,width=1)
    return im

records=[]
for index in range(4):
    image=flare_pair(index); runtime=RUNTIME/f"flare_{index}.png"; source=SOURCE/f"flare_{index}.png"
    runtime.parent.mkdir(parents=True,exist_ok=True); source.parent.mkdir(parents=True,exist_ok=True)
    image.save(runtime,optimize=True); image.save(source,optimize=True)
    records.append({"frame":index,"runtime":runtime.relative_to(ROOT).as_posix(),"size":[48,56],"visible_bounds":list(image.getbbox()),"sha256":sha256(runtime.read_bytes()).hexdigest().upper()})

manifest={"asset_family":"vx94_countermeasure_burst_v3","status":"runtime_integrated","method":"deterministic paired magnesium flare cel authoring","registration":{"pivot":[24,10],"runtime_scale":[0.60,0.60]},"salvo":{"paired_cartridges_per_cel":2,"staggered_events":5,"total_decoys":10,"delays_seconds":[0.0,0.045,0.09,0.135,0.18]},"visual_contract":["white-hot magnesium cores survive native runtime scale","orange-red thermal tails remain attached to each cartridge","broken cool-grey smoke follows physical ejection bearings","paired bodies diverge without forming a symmetric arcade rosette"],"outputs":records}
(SOURCE/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
legacy=ROOT/"assets/source/effects/countermeasure_v2/manifest.json"; data=json.loads(legacy.read_text(encoding="utf-8")); data["runtime_override"]="res://assets/source/effects/countermeasure_v3/manifest.json"; data["runtime_sha256"]=[r["sha256"] for r in records]; data["deployment_presentation"]="five staggered paired-cartridge releases per charge"; data["salvo_timing_seconds"]=[0.0,0.045,0.09,0.135,0.18]; data["runtime_scale"]=0.60; legacy.write_text(json.dumps(data,indent=2)+"\n",encoding="utf-8")
print("Built four paired VX-94 magnesium flare cels.")
