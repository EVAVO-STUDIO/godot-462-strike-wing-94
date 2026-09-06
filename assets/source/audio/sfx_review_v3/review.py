from pathlib import Path
import json,sys,wave
import numpy as np
sys.path.insert(0,'C:/Gitrepos/evavo-audio-studio/migration/local-ai-audio-v1')
from audio_review import review_audio,make_repair_plan
base=Path(__file__).resolve().parent
rows=[]
for event in json.loads((base/'manifest.json').read_text())['events']:
    path=base/event['filename']
    review=review_audio(path,role='sfx').to_dict()
    (base/(event['id']+'_review.json')).write_text(json.dumps(review,indent=2)+'\n')
    with wave.open(str(path),'rb') as wav: samples=np.frombuffer(wav.readframes(wav.getnframes()),dtype='<i2').astype(float)/32768
    active=samples[:round(event['spec']['duration']*22050)]
    rows.append({'id':event['id'],'wave':event['spec']['wave'],'mean_active':float(active.mean()),'peak':float(np.max(np.abs(samples))),'first_sample':float(samples[0]),'last_active_sample':float(active[-1]),'issues':review['issues'],'clipped_samples':review['metrics']['clippedSamples']})
(base/'summary.json').write_text(json.dumps(rows,indent=2)+'\n')
print(json.dumps({'events':len(rows),'clipped':sum(r['clipped_samples'] for r in rows),'largest_active_dc':sorted([{'id':r['id'],'dc':r['mean_active']} for r in rows],key=lambda r:abs(r['dc']),reverse=True)[:6],'flagged':[{'id':r['id'],'issues':r['issues']} for r in rows if r['issues']]},indent=2))
