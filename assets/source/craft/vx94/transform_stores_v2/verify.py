from pathlib import Path
from PIL import Image
import numpy as np,json
b=Path('work/vx94_transform_stores_v2');entries=json.loads((b/'manifest.json').read_text())['entries'];c=json.loads(Path('work/vx94_transform_stores_v1/sprite_config.json').read_text());c['name']='vx94_transform_stores_family';c['animations']={};c['alignment']['manual_anchors']={};checks=[]
for e in entries:
 p=b/'composites'/(e['id']+'.png');out=np.array(Image.open(p).convert('RGBA'));box=Image.open(p).getchannel('A').getbbox();c['alignment']['manual_anchors'][e['id']]=[32-box[0],38-box[1]];anim=e['id'].rsplit('_',1)[0];c['animations'][anim]={'fps':18,'loop':False}
 base=np.array(Image.open(f"assets/runtime/craft/vx94/transform/{e['route']}_{e['exposure']:02}.png").convert('RGBA'))
 for side in range(2):
  layer=np.array(Image.open(b/'layers'/(e['id']+'_'+str(side)+'.png')).convert('RGBA'));assert ((layer[:,:,3]>0)&(base[:,:,3]>0)).any()
 if e['exposure']==0 or (e['route']=='bomber' and e['exposure']==9):
  form='fighter' if e['exposure']==0 else 'bomber';state='left_released' if e['kind']=='hunter_rack' and e['state']=='left_expended' else e['state'];prior=np.array(Image.open(f"work/vx94_external_stores_v3/composites/{form}_{e['kind']}_{state}.png").convert('RGBA'));assert np.array_equal(prior,out),e['id'];checks.append(e['id'])
 if e['route']=='bomber' and e['state']=='loaded':assert np.array_equal(out,np.array(Image.open(f"work/vx94_transform_stores_v1/composites/{e['kind']}_{e['exposure']:02}.png").convert('RGBA')))
(b/'sprite_config.json').write_text(json.dumps(c,indent=2)+'\n');(b/'registration.json').write_text(json.dumps({'endpoint_rgba_exact':checks,'previous_20_loaded_bomber_frames_exact':True,'all_240_hardware_layers_overlap':True},indent=2)+'\n');print('18 endpoint checks and 20 retained-frame checks pass; 240 layers attached')
