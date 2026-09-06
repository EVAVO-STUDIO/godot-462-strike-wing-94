from pathlib import Path
from PIL import Image
import numpy as np,json,shutil
b=Path('work/vx94_pitch_relief_v3');r=json.loads((b/'registration.json').read_text())
for f in ['fighter','bomber']:
 a=np.array(Image.open(f'assets/runtime/craft/vx94/gameplay/bank/{f}_neutral.png').convert('RGBA'));c=np.array(Image.open(b/'clean'/f'{f}_neutral.png').convert('RGBA')); mask=a[:,:,3]>0;d=np.abs(a.astype(int)-c.astype(int))
 r[f+'_neutral_registration'].update(visible_max_channel_error=int(d[mask].max()),opaque_rgba_exact=bool(np.array_equal(a[a[:,:,3]==255],c[a[:,:,3]==255])),changed_visible_pixels=int(np.any(d[mask]>0,axis=1).sum()))
(b/'registration.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps({k:v for k,v in r.items() if k.endswith('registration')}))
