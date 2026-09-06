from pathlib import Path
from PIL import Image
import json,shutil,numpy as np
b=Path('work/vx94_dorsal_modules_v1');e=json.loads((b/'manifest.json').read_text())['entries'];a={};an={};report=[];(b/'sprite_input').mkdir(exist_ok=True)
for v in e:
 p=b/'composites'/(v['id']+'.png');im=Image.open(p).convert('RGBA');box=im.getchannel('A').getbbox();name=v['id']+'_00';a[name]=[32-box[0],38-box[1]];an[v['id']]={'fps':1,'loop':False};shutil.copy2(p,b/'sprite_input'/(name+'.png'))
 layer=np.array(Image.open(b/'layers'/(v['id']+'.png')).convert('RGBA'));original=np.array(Image.open(f"assets/runtime/craft/vx94/gameplay/bank/{v['form']}_{v['bank']}.png").convert('RGBA'));out=np.array(im);mask=layer[:,:,3]>0
 assert np.array_equal(original[~mask],out[~mask]),v['id']
 if v['state']=='active':
  idle=np.array(Image.open(b/'composites'/(v['id'].replace('_active_','_idle_')+'.png')).convert('RGBA'));changed=int(np.any(idle!=out,axis=2).sum());assert changed>0;report.append({'id':v['id'],'status_pixels':changed,'outside_module_unchanged':True})
config={'name':'vx94_dorsal_modules','pixel_art':True,'cleanup':{'background':'none','despeckle_min_area':0,'clear_hidden_rgb':True},'extraction':{'mode':'frames'},'alignment':{'anchor':'manual','canvas_width':64,'canvas_height':72,'pivot_x':32,'pivot_y':38,'padding':0,'manual_anchors':a},'qa':{'strict':True},'animations':an,'export':{'godot':True,'generic_json':True,'integration_contract':True},'previews':{'enabled':True,'contact_sheet':True}}
(b/'sprite_config.json').write_text(json.dumps(config,indent=2)+'\n');(b/'registration.json').write_text(json.dumps(report,indent=2)+'\n');print('60 composite exteriors unchanged; 30 active indicators visible')
(b/'review').mkdir(exist_ok=True);shutil.copy2('work/vx94_banked_stores_v2/review/project.godot',b/'review/project.godot');s=Path('work/vx94_banked_stores_v2/review/review.gd').read_text().replace('vx94_banked_stores_v2','vx94_dorsal_modules_v1').replace('75 named bank/loadout states','60 dorsal module states').replace('PHYSICAL STORES','DORSAL MODULES').replace('under-wing hardware','dorsal hardware');(b/'review/review.gd').write_text(s)
