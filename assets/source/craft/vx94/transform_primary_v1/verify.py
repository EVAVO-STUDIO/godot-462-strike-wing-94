from pathlib import Path
from PIL import Image
import numpy as np,json
b=Path('work/vx94_transform_primary_v1');entries=json.loads((b/'manifest.json').read_text())['entries'];c=json.loads(Path('work/vx94_transform_stores_v1/sprite_config.json').read_text());c['name']='vx94_transform_primary';c['animations']={};c['alignment']['manual_anchors']={};endpoints=[]
for e in entries:
 p=b/'composites'/(e['id']+'.png');box=Image.open(p).getchannel('A').getbbox();c['alignment']['manual_anchors'][e['id']]=[32-box[0],38-box[1]];c['animations'][e['route']+'_'+e['weapon']]={'fps':18,'loop':False}
 if e['exposure']==0 or (e['route']=='bomber' and e['exposure']==9):
  f=e['hardware_form'];w=e['weapon'];n=e['hardware_exposure'];source=Path('work/vx94_banked_housings/composites')/f'{f}_neutral_{n}.png' if w=='ballistic' else Path('work/vx94_specialist_housings_v2/composites')/f'{w}_{f}_neutral_{n}.png';assert np.array_equal(np.array(Image.open(source).convert('RGBA')),np.array(Image.open(p).convert('RGBA'))),e['id'];endpoints.append(e['id'])
(b/'sprite_config.json').write_text(json.dumps(c,indent=2)+'\n');(b/'registration.json').write_text(json.dumps({'exact_endpoints':endpoints},indent=2)+'\n');print('12 shared primary endpoints exact')
