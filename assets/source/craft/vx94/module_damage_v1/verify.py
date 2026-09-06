from pathlib import Path
from PIL import Image
import numpy as np,json,shutil
b=Path('work/vx94_module_damage_v1');entries=json.loads((b/'manifest.json').read_text())['entries'];c=json.loads(Path('work/vx94_dorsal_modules_v1/sprite_config.json').read_text());c['name']='vx94_module_damage';c['animations']={};c['alignment']['manual_anchors']={};(b/'sprite_input').mkdir(exist_ok=True);report=[]
for e in entries:
 p=b/'composites'/(e['id']+'.png');im=Image.open(p).convert('RGBA');out=np.array(im);box=im.getchannel('A').getbbox();name=e['id']+'_00';c['alignment']['manual_anchors'][name]=[32-box[0],38-box[1]];c['animations'][e['id']]={'fps':1,'loop':False};shutil.copy2(p,b/'sprite_input'/(name+'.png'))
 module=np.array(Image.open('work/vx94_dorsal_modules_v1/layers/'+e['base_id']+'.png').convert('RGBA'));layer=np.array(Image.open(b/'layers'/(e['id']+'.png')).convert('RGBA'));base=np.array(Image.open('work/vx94_dorsal_modules_v1/composites/'+e['base_id']+'.png').convert('RGBA'));mask=module[:,:,3]>0
 assert not ((layer[:,:,3]>0)&(~mask)).any(),e['id'];outside=(~mask)&(base[:,:,3]>0);assert np.array_equal(out[outside],base[outside]);assert np.array_equal(out[:,:,3],base[:,:,3]);changed=int(np.any(out!=base,axis=2)[mask].sum());assert changed>0
 report.append({'id':e['id'],'changed_module_pixels':changed,'damage_outside_module':0,'airframe_visible_exterior_unchanged':True,'alpha_unchanged':True})
(b/'sprite_config.json').write_text(json.dumps(c,indent=2)+'\n');(b/'registration.json').write_text(json.dumps(report,indent=2)+'\n');print('60 localized overlays; no outside-module damage; alpha unchanged')
(b/'review').mkdir(exist_ok=True);shutil.copy2('work/vx94_dorsal_modules_v1/review/project.godot',b/'review/project.godot');s=Path('work/vx94_dorsal_modules_v1/review/review.gd').read_text().replace('vx94_dorsal_modules_v1','vx94_module_damage_v1').replace('DORSAL MODULES','MODULE DAMAGE').replace('60 dorsal module states','60 localized module-damage states');(b/'review/review.gd').write_text(s)
