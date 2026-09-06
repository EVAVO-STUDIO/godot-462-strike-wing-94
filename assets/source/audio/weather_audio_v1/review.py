from pathlib import Path
import sys,json
sys.path.insert(0,'C:/Gitrepos/evavo-audio-studio/migration/local-ai-audio-v1')
from audio_review import review_audio,make_repair_plan
base=Path(__file__).resolve().parent
rows=[]
for name in ['rain','storm','snow_wind']:
    source=base/name/'generated_sfx.wav'
    report=review_audio(source,role='ambience',loop_start=0.0,loop_end=16.0)
    value=report.to_dict()
    (base/name/'audio_review.json').write_text(json.dumps(value,indent=2)+'\n')
    (base/name/'repair_plan.json').write_text(json.dumps(make_repair_plan(report),indent=2)+'\n')
    rows.append({'id':name,'issues':value['issues'],'metrics':value['metrics']})
(base/'summary.json').write_text(json.dumps(rows,indent=2)+'\n')
print(json.dumps(rows,indent=2))
