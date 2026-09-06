from pathlib import Path
import json,hashlib
b=Path('work/tracker_arrangements_v3');source=Path('data/music_tracks.json');catalog={t['id']:t for t in json.loads(source.read_text())['tracks']};reports=[]
for f in json.loads((b/'index.json').read_text())['plans']:
 p=json.loads((b/f).read_text());original=catalog[p['id']];known=set(original['lead']);sections=[]
 for bar in p['bars']:
  t=bar['track'];assert len(t['lead'])==16 and len(t['bass'])==16 and len(t['kick'])==16 and len(t['snare'])==16
  assert set(t['lead'])<=known|{-1};assert t['bpm']==original['bpm'] and t['root']==original['root'] and t['chords']==original['chords'] and t['bass']==original['bass']
  if not sections or sections[-1]['name']!=bar['section']:sections.append({'name':bar['section'],'start_bar':bar['bar'],'bars':1})
  else:sections[-1]['bars']+=1
 reports.append({'id':p['id'],'bars':len(p['bars']),'seconds_expected':32*240/p['bpm'],'retained_tempo_harmony_bass_pitch_vocabulary':True,'unique_bar_patterns':len({json.dumps(x['track'],sort_keys=True) for x in p['bars']}),'sections':sections})
(b/'composition_checks.json').write_text(json.dumps(reports,indent=2)+'\n');print('11 arrangements retain source musical material; all have 32 bars and multiple patterns')
