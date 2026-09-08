#!/usr/bin/env python3
from __future__ import annotations
from collections import deque
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter
import json

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/"assets/source/surface_sites/mercenary_war_v2"
OUT=ROOT/"assets/runtime/surface_sites"
NAMES=["strategic_silo","ballistic_launcher","field_artillery","radar_site","logistics_truck","ammo_depot","civilian_village","field_clinic"]
CELL_W=418

def border_connected_alpha(cell:Image.Image)->Image.Image:
    rgb=cell.convert("RGB"); w,h=rgb.size
    removable=bytearray(w*h)
    for y in range(h):
        for x in range(w):
            r,g,b=rgb.getpixel((x,y))
            # Generated checker is neutral and much brighter than the painted
            # subject. Flood connectivity protects enclosed white missile and
            # clinic pixels even when their values approach the matte.
            if min(r,g,b)>=218 and max(r,g,b)-min(r,g,b)<=13:
                removable[y*w+x]=1
    seen=bytearray(w*h); queue=deque()
    for x in range(w):
        queue.extend(((x,0),(x,h-1)))
    for y in range(h):
        queue.extend(((0,y),(w-1,y)))
    while queue:
        x,y=queue.popleft(); i=y*w+x
        if seen[i] or not removable[i]: continue
        seen[i]=1
        if x: queue.append((x-1,y))
        if x+1<w: queue.append((x+1,y))
        if y: queue.append((x,y-1))
        if y+1<h: queue.append((x,y+1))
    alpha=Image.new("L",(w,h),255); alpha.putdata([0 if value else 255 for value in seen])
    # One-pixel inward feather suppresses the light checker fringe without
    # softening the final 48-pixel silhouette.
    alpha=alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.45))
    result=rgb.convert("RGBA"); result.putalpha(alpha)
    return result

def normalize(cell:Image.Image)->Image.Image:
    alpha=cell.getchannel("A"); box=alpha.getbbox()
    if not box: raise RuntimeError("empty extracted site")
    subject=cell.crop(box)
    max_w,max_h=43,42
    scale=min(max_w/subject.width,max_h/subject.height)
    subject=subject.resize((max(1,round(subject.width*scale)),max(1,round(subject.height*scale))),Image.Resampling.LANCZOS)
    result=Image.new("RGBA",(48,48),(0,0,0,0))
    x=(48-subject.width)//2; y=45-subject.height
    result.alpha_composite(subject,(x,y))
    return result

def main()->None:
    raw=Image.open(SRC/"surface_sites_raw.png").convert("RGB")
    OUT.mkdir(parents=True,exist_ok=True)
    extracted={}
    for index,name in enumerate(NAMES):
        col=index%4; row=index//4
        left=col*CELL_W; right=(col+1)*CELL_W if col<3 else raw.width
        top=0 if row==0 else raw.height//2; bottom=raw.height//2 if row==0 else raw.height
        site=normalize(border_connected_alpha(raw.crop((left,top,right,bottom))))
        site.save(OUT/f"{name}.png",optimize=True)
        extracted[name]=site
    anim=OUT/"animation"
    for folder in ("radar_site","field_artillery","ballistic_launcher"):
        (anim/folder).mkdir(parents=True,exist_ok=True)
    # Held cels retain registered geometry. Small lighting/recoil substitutions
    # show operation without regenerating or warping the vehicle identity.
    radar=extracted["radar_site"]
    for index,brightness in enumerate((0.88,1.0,1.10,1.0)):
        frame=radar.copy()
        if brightness!=1.0:
            overlay=Image.new("RGBA",frame.size,(210,229,220,round(abs(brightness-1.0)*110)))
            if brightness<1.0: overlay=Image.new("RGBA",frame.size,(8,15,15,20))
            overlay.putalpha(ImageChops.multiply(frame.getchannel("A"),overlay.getchannel("A")))
            frame=Image.alpha_composite(frame,overlay)
        frame.save(anim/"radar_site"/f"{index}.png",optimize=True)
    extracted["field_artillery"].save(anim/"field_artillery"/"0.png",optimize=True)
    recoil=Image.new("RGBA",(48,48),(0,0,0,0)); recoil.alpha_composite(extracted["field_artillery"],(0,2))
    recoil.save(anim/"field_artillery"/"1.png",optimize=True)
    for index in range(3):
        extracted["ballistic_launcher"].save(anim/"ballistic_launcher"/f"{index}.png",optimize=True)
    sheet=Image.new("RGBA",(192,96),(18,23,22,255))
    for index,name in enumerate(NAMES):
        sheet.alpha_composite(extracted[name],((index%4)*48,(index//4)*48))
    sheet.save(SRC/"surface_site_contact_sheet.png",optimize=True)
    manifest={
      "schema_version":5,"identity":"late-1990s military cel sprite family","canvas":[48,48],
      "source":"surface_sites_raw.png","military":NAMES[:6],"protected":NAMES[6:],
      "perspective":"shared 70-degree oblique orthographic route-forward view",
      "alpha":"border-connected neutral checker recovery; source retained immutable",
      "animation":{"radar_site":{"frames":4,"fps":3.0},"field_artillery":{"frames":2,"trigger":"recoil_timer"},"ballistic_launcher":{"frames":3,"sequence":"registered held deployment"}},
      "rules":["thin ink outline and two-step cel value structure","one shared upper-left light direction","only field_clinic carries a red cross","protected sites remain subdued rather than arcade-bright","all static and held animation cels share one registered source identity"]}
    (SRC/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    print("built 8 registered surface-site cel sprites and 9 held animation cels")

if __name__=="__main__": main()
