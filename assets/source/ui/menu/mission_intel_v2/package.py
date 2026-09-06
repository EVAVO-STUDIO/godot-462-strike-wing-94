from pathlib import Path
from PIL import Image
import numpy as np,json,shutil,hashlib
b=Path('work/mission_intel_icons_v2');d=Path('assets/source/ui/menu/mission_intel_v2');d.mkdir(parents=True,exist_ok=True);(d/'.gdignore').write_text('');shutil.copytree(b,d,dirs_exist_ok=True)
a=np.array(Image.open(b/'originals/operations_screen_9slice.png').convert('RGBA'));c=np.array(Image.open(b/'screen/operations_screen_9slice.png').convert('RGBA'));mask=np.ones((32,32),bool);mask[4:28,4:28]=False;assert np.array_equal(a[mask],c[mask]);assert (c[4:28,4:28,3]==255).all()
files=[]
for p in sorted((d/'icons').glob('*.png')):files.append({'source':p.relative_to(d).as_posix(),'runtime':'assets/runtime/ui/menu/mission_intel/'+p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
p=d/'screen/operations_screen_9slice.png';files.append({'source':p.relative_to(d).as_posix(),'runtime':'assets/runtime/ui/menu/'+p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()});(d/'runtime_manifest.json').write_text(json.dumps({'status':'reviewed_for_runtime','files':files,'opaque_inner_surface':[4,4,24,24],'outer_four_pixel_border_exact':True},indent=2)+'\n')
