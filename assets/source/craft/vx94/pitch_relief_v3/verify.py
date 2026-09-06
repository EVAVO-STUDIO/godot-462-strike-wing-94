from pathlib import Path
from PIL import Image
import numpy as np,json
b=Path('work/vx94_pitch_relief_v3'); report={}
for p in sorted((b/'native').glob('*.png')):
 a=np.array(Image.open(p).convert('RGBA')); c=np.array(Image.open(b/'clean'/p.name).convert('RGBA')); visible=a[:,:,3]>0
 assert np.array_equal(a[visible],c[visible]) and np.array_equal(a[:,:,3],c[:,:,3])
 report[p.stem]={'visible_rgba_unchanged':True,'hidden_rgb_nonzero':int(np.any(c[:,:,:3][~visible],axis=1).sum())}
for form in ['fighter','bomber']:
 a=np.array(Image.open(f'assets/runtime/craft/vx94/gameplay/bank/{form}_neutral.png').convert('RGBA')); c=np.array(Image.open(b/'clean'/f'{form}_neutral.png').convert('RGBA'))
 report[form+'_neutral_registration']={'alpha_exact':bool(np.array_equal(a[:,:,3],c[:,:,3])),'visible_rgba_exact':bool(np.array_equal(a[a[:,:,3]>0],c[a[:,:,3]>0]))}
(b/'registration.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items() if k.endswith('registration')}))
