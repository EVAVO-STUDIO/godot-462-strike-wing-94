from __future__ import annotations
import json, math, shutil, subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageEnhance

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"assets/source/cinematics/vx94_hypersonic_break_v1"
KEYS=OUT/"keys"; WORK=ROOT/"work/vx94_hypersonic_break_v1/frames"
FPS=24; FRAME_COUNT=288; SIZE=(640,360)

def key(name:str)->Image.Image:
    source=Image.open(KEYS/name).convert("RGB")
    scale=max(SIZE[0]/source.width,SIZE[1]/source.height)
    source=source.resize((round(source.width*scale),round(source.height*scale)),Image.Resampling.LANCZOS)
    left=(source.width-640)//2; top=(source.height-360)//2
    return source.crop((left,top,left+640,top+360))

def held_blend(a:Image.Image,b:Image.Image,frame:int,start:int,end:int,drawings:int)->Image.Image:
    ratio=max(0.0,min(1.0,(frame-start)/max(1,end-start)))
    exposure=round(ratio*(drawings-1))/max(1,drawings-1)
    return Image.blend(a,b,exposure)

def speed_treatment(source:Image.Image,ratio:float,frame:int)->Image.Image:
    zoom=1.0+ratio*0.055
    scaled=source.resize((round(640*zoom),round(360*zoom)),Image.Resampling.LANCZOS)
    left=(scaled.width-640)//2
    top=min(scaled.height-360,(scaled.height-360)//2+round(ratio*7))
    image=scaled.crop((left,top,left+640,top+360))
    # A rear tracking camera keeps the VX-94 readable while peripheral cloud
    # detail tears away from the shared horizon vanishing point. Hold the
    # treatment on threes so it reads as authored late-90s cel effects rather
    # than smooth digital rain or generic motion blur.
    exposure=(frame-170)//3
    overlay=Image.new("RGBA",SIZE,(0,0,0,0))
    draw=ImageDraw.Draw(overlay)
    vanish=(320.0,104.0)
    shear_count=round(4+ratio*18)
    for index in range(shear_count):
        seed=exposure*37+index*71
        side=-1 if index%2==0 else 1
        x=vanish[0]+side*(82+(seed*29)%238)
        y=132+(seed*43)%190
        dx=x-vanish[0]; dy=y-vanish[1]
        length=(8+ratio*38)*(0.72+((seed*17)%31)/50.0)
        magnitude=max(1.0,math.hypot(dx,dy))
        ux=dx/magnitude; uy=dy/magnitude
        start=(round(x-ux*length*0.22),round(y-uy*length*0.22))
        end=(round(x+ux*length),round(y+uy*length))
        alpha=round(22+ratio*54)
        draw.line((start,end),fill=(172,205,218,alpha),width=1)
        if ratio>0.62 and index%4==0:
            draw.line(((start[0],start[1]+1),(end[0],end[1]+1)),fill=(95,153,188,alpha//2),width=1)
    return Image.alpha_composite(image.convert("RGBA"),overlay).convert("RGB")

def letterbox(image:Image.Image)->Image.Image:
    draw=ImageDraw.Draw(image)
    draw.rectangle((0,0,640,17),fill=(4,8,13))
    draw.rectangle((0,343,640,359),fill=(4,8,13))
    return image

def build()->None:
    WORK.mkdir(parents=True,exist_ok=True)
    for old in WORK.glob("*.png"): old.unlink()
    open_pose=key("vx94_open.png"); midpoint=key("vx94_midpoint.png")
    tucked=key("vx94_tucked.png"); ignition=key("vx94_ignition.png")
    acceleration=key("vx94_acceleration.png")
    proof_frames={0,64,92,120,143,151,168,216,287}
    proof_dir=OUT/"proofs"; proof_dir.mkdir(parents=True,exist_ok=True)
    for old in proof_dir.glob("*.png"): old.unlink()
    for frame in range(FRAME_COUNT):
        if frame<52: image=open_pose.copy()
        elif frame<84: image=held_blend(open_pose,midpoint,frame,52,83,5)
        elif frame<116: image=held_blend(midpoint,tucked,frame,84,115,5)
        elif frame<138: image=tucked.copy()
        elif frame<151: image=held_blend(tucked,ignition,frame,138,150,4)
        elif frame<170:
            image=ignition.copy()
            image=ImageEnhance.Brightness(image).enhance(1.0+0.035*math.sin((frame-151)*math.pi/5.0))
        else:
            speed_ratio=min(1.0,(frame-170)/70.0)
            image=speed_treatment(acceleration,speed_ratio,frame)
        image=letterbox(image)
        image.save(WORK/f"frame_{frame:04d}.png",optimize=True)
        if frame in proof_frames: image.save(proof_dir/f"frame_{frame:04d}.png",optimize=True)
    manifest={
      "schema_version":2,"sequence":"vx94_hypersonic_break","logical_size":"640x360",
      "frame_rate":FPS,"frame_count":FRAME_COUNT,"duration_seconds":FRAME_COUNT/FPS,
      "identity_lock":"Four registered keys preserve one camera, horizon, fuselage, canopy, twin-nacelle and twin-tail identity.",
      "beats":[
        {"frames":[0,51],"beat":"level cloud-flight establishment"},
        {"frames":[52,115],"beat":"ten held mechanical wing exposures across two registered breakdowns"},
        {"frames":[116,137],"beat":"locked hypersonic geometry hold"},
        {"frames":[138,150],"beat":"four-exposure blue engine ignition"},
        {"frames":[151,169],"beat":"held engine-axis pressure-ring impact"},
        {"frames":[170,287],"beat":"ring clears; three-frame peripheral cloud-shear cels and blue exhaust accelerate from the shared vanishing point"}],
      "rejections":["aircraft identity drift","wing change after ignition","shockwave detached from engine axis","vertical rain-like speed lines","low-over-water impossible scale","generic neon science-fiction treatment"]}
    (OUT/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    ffmpeg=shutil.which("ffmpeg")
    if not ffmpeg: raise RuntimeError("ffmpeg is required to build the reviewable MP4")
    subprocess.run([ffmpeg,"-loglevel","error","-y","-framerate",str(FPS),"-i",str(WORK/"frame_%04d.png"),"-c:v","libx264","-pix_fmt","yuv420p","-crf","17","-movflags","+faststart",str(OUT/"vx94_hypersonic_break_v1.mp4")],check=True)
    print(f"Built {FRAME_COUNT} registered VX-94 cinematic frames and MP4 at {OUT}")

if __name__=="__main__": build()
