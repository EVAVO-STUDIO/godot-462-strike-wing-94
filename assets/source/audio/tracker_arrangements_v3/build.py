from pathlib import Path
import json,copy,hashlib
root=Path.cwd();source=root/'data/music_tracks.json';tracks=json.loads(source.read_text())['tracks'];out=root/'work/tracker_arrangements_v3';plans=[]
forms={
'hangar_signal':[('intro',4),('theme',8),('answer',4),('break',4),('theme',8),('outro',4)],
'title_vector':[('intro',2),('theme',6),('answer',4),('drive',8),('break',4),('theme',6),('outro',2)],
'salt_wake':[('intro',4),('theme',8),('answer',4),('break',4),('drive',8),('outro',4)],
'furnace_alarm':[('intro',2),('drive',6),('answer',4),('drive',8),('break',2),('theme',6),('outro',4)],
'machine_pressure':[('intro',4),('theme',4),('answer',4),('drive',8),('break',4),('drive',6),('outro',2)],
'dead_factory':[('intro',8),('theme',4),('answer',4),('break',4),('theme',8),('outro',4)],
'ghost_signal':[('intro',2),('theme',6),('break',2),('answer',6),('drive',8),('theme',6),('outro',2)],
'black_sky':[('intro',8),('theme',8),('break',4),('answer',4),('theme',4),('outro',4)],
'thin_blue':[('intro',4),('theme',8),('answer',4),('break',4),('drive',8),('outro',4)],
'ark_descent':[('intro',2),('drive',6),('answer',4),('drive',8),('break',2),('drive',8),('outro',2)],
'after_action':[('intro',4),('theme',8),('answer',4),('break',4),('theme',4),('outro',8)]}
for base in tracks:
 if base['id'] not in forms:continue
 bars=[]
 for section,count in forms[base['id']]:
  for local in range(count):
   t=copy.deepcopy(base)
   if section=='intro':
    t['lead']=[-1]*16;t['snare']=[0]*16;t['kick']=[1 if i in [0,8] else 0 for i in range(16)]
   elif section=='answer':
    shift=4 if base['role'] in ['sector_2','sector_3'] else 8;t['lead']=base['lead'][shift:]+base['lead'][:shift];t['lead'][12:]=base['lead'][12:]
    if local%2==1:t['lead']=[n if i%4!=3 else -1 for i,n in enumerate(t['lead'])]
   elif section=='break':
    t['lead']=[n if i%4==0 else -1 for i,n in enumerate(base['lead'])];t['snare']=[0]*16;t['kick']=[1 if i in [0,8] else 0 for i in range(16)]
   elif section=='drive' and local%4==3:t['snare'][14:]=[1,1]
   elif section=='outro':
    t['lead']=[n if i%2==0 else -1 for i,n in enumerate(base['lead'])]
    if local>=count-2:t['lead']=[-1]*16;t['snare']=[0]*16
   bars.append({'bar':len(bars)+1,'section':section,'track':t})
 assert len(bars)==32
 plan={'id':base['id'],'name':base['name'],'role':base['role'],'bpm':base['bpm'],'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'bars':bars,'scope':'Authored screening arrangement retaining original timbre, tempo and pitch vocabulary; not listening-approved or seamless-loop certified'}
 path=out/(base['id']+'.json');path.write_text(json.dumps(plan,indent=2)+'\n');plans.append(path.name)
(out/'index.json').write_text(json.dumps({'plans':plans,'retained_separate':'assets/source/audio/steel_vector_arrangement_v2'},indent=2)+'\n');print(f'{len(plans)} distinct 32-bar arrangements')
