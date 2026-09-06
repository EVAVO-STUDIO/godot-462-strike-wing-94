from pathlib import Path
import difflib, hashlib, json, shutil, subprocess
import numpy as np
from PIL import Image

repo=Path(__file__).resolve().parents[2]
base=repo/'work/destruction_continuity_v2'
dest=repo/'assets/source/effects/destruction_continuity_v2'
dest.mkdir(exist_ok=True); (dest/'.gdignore').write_text('')
durations=[[2.3,2.3,2.3],[2.3,2.3,3.0],[3.0,3.0,3.0],[.96,1.35,.92],[1.1,.72,.96]]
same_position=json.loads((base/'same_position_checks.json').read_text())
assert same_position['status']=='exact_late_art_pixels_pass'
checks=[]
for group, times in enumerate(durations):
    paths=sorted((base/f'clipped_group_{group}').glob('frame_*.png')); assert len(paths)==73
    counts=[0,0,0]; early=[]; translated_differences=[]
    for frame,path in enumerate(paths):
        a=np.asarray(Image.open(path).convert('RGBA'))
        for i,duration in enumerate(times):
            # Match the central artwork areas at their exact integer row offset.
            x0=i*212; x1=min(640,(i+1)*212)
            difference=np.any(a[20:155,x0:x1]!=a[200:335,x0:x1],axis=2)
            if frame/24 > duration*.32:
                counts[i]+=1
                if difference.any(): translated_differences.append({'frame':frame,'case':i,'pixels':int(difference.sum())})
            if group<3 and frame==17:
                assert difference.any()
                early.append(int(difference.sum()))
    checks.append({'group':group,'frames':73,'late_compared_frames_per_case':counts,'translated_panel_pixel_differences':translated_differences,'early_boss_changed_pixels_at_0_708_seconds':early})
    d=dest/f'group_{group}';d.mkdir(exist_ok=True)
    for n in [0,5,6,17,18,23,24,36,60,72]: shutil.copy2(base/f'clipped_group_{group}/frame_{n:03}.png',d/f'frame_{n:03}.png')
for name in ['baseline.gd','candidate.gd','review.gd','review_unclipped.gd','source_binding.json','native.log','native_clipped.log','same_position.gd','same_position.log','same_position_checks.json','package.py']: shutil.copy2(base/name,dest/name)
shutil.copy2(repo/'work/build_destruction_continuity_v2.py',dest/'build_destruction_continuity_v2.py')
patch=''.join(difflib.unified_diff((base/'baseline.gd').read_text().splitlines(True),(base/'candidate.gd').read_text().splitlines(True),fromfile='a/scripts/combat_fx_director.gd',tofile='b/scripts/combat_fx_director.gd'))
(dest/'integration.patch').write_text(patch,newline='\n')
(dest/'verification.json').write_text(json.dumps({'scope':'365 native addressed comparison frames plus 730 sequential same-position renders: all nine bosses and six smaller representatives. Pixel comparisons cover central art areas, excluding labels. Not natural kills or frame-time profiling.','same_position':same_position,'translated_panel_checks':checks},indent=2)+'\n')
out=Path('C:/Users/User/Documents/Codex/2026-09-05/g/outputs')
shutil.copy2(base/'clipped_group_2/frame_017.png',out/'HYPERSONIC-boss-destruction-continuity.png')
subprocess.run(['ffmpeg','-y','-framerate','24','-i',str(base/'clipped_group_2/frame_%03d.png'),'-c:v','libx264','-crf','18','-pix_fmt','yuv420p',str(out/'HYPERSONIC-boss-destruction-continuity.mp4')],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
print(json.dumps(checks))
