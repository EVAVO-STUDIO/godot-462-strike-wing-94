from pathlib import Path
import json,shutil
from PIL import Image
base=Path(__file__).resolve().parent;folder=base/'sprite_input';folder.mkdir(exist_ok=True)
anchors={};animations={}
poses=['dive_18','dive_12','dive_06','neutral','climb_06','climb_12','climb_18']
for form in ['fighter','bomber']:
 animations[form]={'fps':8,'loop':False}
 for i,pose in enumerate(poses):
  p=base/f'clean/{form}_{pose}.png';name=f'{form}_{i:02}';box=Image.open(p).getchannel('A').getbbox()
  assert box and box[0]>0 and box[1]>0 and box[2]<64 and box[3]<72
  shutil.copy2(p,folder/(name+'.png'));anchors[name]=[32-box[0],38-box[1]]
config={'name':'vx94_pitch_relief','pixel_art':True,'cleanup':{'background':'none','despeckle_min_area':0,'clear_hidden_rgb':True},'extraction':{'mode':'frames'},'alignment':{'anchor':'manual','canvas_width':64,'canvas_height':72,'pivot_x':32,'pivot_y':38,'padding':0,'manual_anchors':anchors},'qa':{'strict':True,'contracts':{'required_animations':['fighter','bomber'],'frame_count_rules':[{'pattern':'fighter','exact':7},{'pattern':'bomber','exact':7}]}},'animations':animations,'export':{'godot':True,'generic_json':True,'integration_contract':True},'previews':{'enabled':True,'gif':True,'contact_sheet':True,'onion_skin':True}}
(base/'sprite_config.json').write_text(json.dumps(config,indent=2)+'\n')
