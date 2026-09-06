from pathlib import Path
from PIL import Image
import numpy as np,json,shutil
b=Path('work/vx94_banked_stores_v2');e=json.loads((b/'manifest.json').read_text())['entries'];a={};an={};reports=[];(b/'sprite_input').mkdir(exist_ok=True)
for v in e:
 p=b/'composites'/(v['id']+'.png');im=Image.open(p).convert('RGBA');box=im.getchannel('A').getbbox();name=v['id']+'_00';a[name]=[32-box[0],38-box[1]];an[v['id']]={'fps':1,'loop':False};shutil.copy2(p,b/'sprite_input'/(name+'.png'))
 base=np.array(Image.open(f"assets/runtime/craft/vx94/gameplay/bank/{v['form']}_{v['bank']}.png").convert('RGBA'))
 for side in range(2):
  layer=np.array(Image.open(b/'layers'/(v['id']+'_'+str(side)+'.png')).convert('RGBA'));overlap=int(((layer[:,:,3]>0)&(base[:,:,3]>0)).sum());assert overlap>0,(v['id'],side);reports.append({'id':v['id'],'side':side,'under_airframe_pixels':overlap})
 if v['bank']=='neutral':
  original=np.array(Image.open('work/vx94_external_stores_v3/composites/'+v['id'].removesuffix('_neutral')+'.png').convert('RGBA'));assert np.array_equal(original,np.array(im)),v['id']
config={'name':'vx94_banked_stores','pixel_art':True,'cleanup':{'background':'none','despeckle_min_area':0,'clear_hidden_rgb':True},'extraction':{'mode':'frames'},'alignment':{'anchor':'manual','canvas_width':64,'canvas_height':72,'pivot_x':32,'pivot_y':38,'padding':0,'manual_anchors':a},'qa':{'strict':True},'animations':an,'export':{'godot':True,'generic_json':True,'integration_contract':True},'previews':{'enabled':True,'contact_sheet':True}}
(b/'sprite_config.json').write_text(json.dumps(config,indent=2)+'\n');(b/'attachment.json').write_text(json.dumps({'neutral_15_rgba_exact':True,'layers':reports},indent=2)+'\n');print('150 layers overlap airframe; 15 neutral RGBA exact')
(b/'review').mkdir(exist_ok=True);shutil.copy2('work/vx94_external_stores_v3/review/project.godot',b/'review/project.godot')
s=Path('work/vx94_external_stores_v3/review/review.gd').read_text().replace('vx94_external_stores_v3','vx94_banked_stores_v2').replace('15 named loadout states','75 named bank/loadout states');(b/'review/review.gd').write_text(s)
