from pathlib import Path
from PIL import Image
import numpy as np,json
b=Path('work/vx94_combined_loadouts_v1');report=[]
for e in json.loads((b/'manifest.json').read_text())['entries']:
 f,k,w=e['form'],e['bank'],e['weapon'];path=Path('work/vx94_banked_housings/composites')/f'{f}_{k}_3.png' if w=='ballistic' else Path('work/vx94_specialist_housings_v2/composites')/f'{w}_{f}_{k}_2.png'
 original=np.array(Image.open(path).convert('RGBA'));out=np.array(Image.open(b/'composites'/(e['id']+'.png')).convert('RGBA'));mask=(original[:,:,3]>0)|(out[:,:,3]>0);count=int((np.any(original!=out,axis=2)&mask).sum());assert count>0,e['id'];report.append({'id':e['id'],'visible_support_difference_pixels':count})
(b/'combined_visibility.json').write_text(json.dumps(report,indent=2)+'\n');print('All 50 supports contribute visible pixels; min='+str(min(e['visible_support_difference_pixels'] for e in report)))
