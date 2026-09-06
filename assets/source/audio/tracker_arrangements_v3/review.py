from pathlib import Path
import json,subprocess
b=Path(__file__).resolve().parent;index=json.loads((b/'index.json').read_text());rows=[]
for file in index['plans']:
 plan=json.loads((b/file).read_text());name=plan['id'];
 if 'TRACKER_ARRANGED '+name+' ' not in (b/'render.log').read_text():continue
 raw=b/(name+'_raw.wav');wav=b/(name+'_review.wav');report=b/(name+'_audio_review.json')
 if report.exists():
  r=json.loads(report.read_text());rows.append({'id':name,'duration_seconds':r.get('duration_seconds'),'issues':r.get('issues'),'metrics':r.get('metrics')});continue
 subprocess.run(['ffmpeg','-y','-i',str(raw),'-af','highpass=f=20','-c:a','pcm_s16le',str(wav)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 subprocess.run(['python','C:/Gitrepos/evavo-audio-studio/migration/local-ai-audio-v1/evavo_ai_audio.py','review',str(wav),'--role','music','--output',str(report),'--repair-plan',str(b/(name+'_repair.json'))],check=True,stdout=subprocess.DEVNULL)
 r=json.loads(report.read_text());rows.append({'id':name,'duration_seconds':r.get('duration_seconds'),'issues':r.get('issues'),'metrics':r.get('metrics')});print('AUDIO_REVIEW '+name,flush=True)
(b/'review_summary.json').write_text(json.dumps(rows,indent=2)+'\n')
