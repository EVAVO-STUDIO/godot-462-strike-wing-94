from pathlib import Path
from PIL import Image
import numpy as np,json,shutil
b=Path('work/vx94_transform_stores_v1');e=json.loads((b/'manifest.json').read_text())['entries'];a={};report=[]
for v in e:
 p=b/'composites'/(v['id']+'.png');box=Image.open(p).getchannel('A').getbbox();a[v['id']]=[32-box[0],38-box[1]]
 base=np.array(Image.open(f"assets/runtime/craft/vx94/transform/bomber_{v['exposure']:02}.png").convert('RGBA'))
 for side in range(2):
  layer=np.array(Image.open(b/'layers'/(v['id']+'_'+str(side)+'.png')).convert('RGBA'));n=int(((layer[:,:,3]>0)&(base[:,:,3]>0)).sum());assert n>0;report.append({'id':v['id'],'side':side,'attachment_overlap':n})
 if v['exposure'] in [0,9]:
  f='fighter' if v['exposure']==0 else 'bomber';original=np.array(Image.open(f"work/vx94_external_stores_v3/composites/{f}_{v['kind']}_loaded.png").convert('RGBA'));assert np.array_equal(original,np.array(Image.open(p).convert('RGBA'))),v['id']
config={'name':'vx94_transform_stores','pixel_art':True,'cleanup':{'background':'none','despeckle_min_area':0,'clear_hidden_rgb':True},'extraction':{'mode':'frames'},'alignment':{'anchor':'manual','canvas_width':64,'canvas_height':72,'pivot_x':32,'pivot_y':38,'padding':0,'manual_anchors':a},'qa':{'strict':True},'animations':{k:{'fps':18,'loop':False}for k in ['hunter_rack','twin_rocket_pods']},'export':{'godot':True,'generic_json':True,'integration_contract':True},'previews':{'enabled':True,'gif':True,'contact_sheet':True,'onion_skin':True}}
(b/'sprite_config.json').write_text(json.dumps(config,indent=2)+'\n');(b/'registration.json').write_text(json.dumps({'four_endpoint_composites_rgba_exact':True,'layers':report},indent=2)+'\n');print('Four endpoints exact; all forty hardware layers overlap airframe')
