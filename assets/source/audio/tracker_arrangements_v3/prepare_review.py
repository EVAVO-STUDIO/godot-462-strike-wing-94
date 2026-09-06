from pathlib import Path
p=Path('work/tracker_arrangements_v3/review.py');s=p.read_text();s=s.replace("plan=json.loads((b/file).read_text());name=plan['id'];raw=", "plan=json.loads((b/file).read_text());name=plan['id'];\n if 'TRACKER_ARRANGED '+name+' ' not in (b/'render.log').read_text():continue\n raw=")
s=s.replace(" subprocess.run(['ffmpeg'", " if report.exists():\n  r=json.loads(report.read_text());rows.append({'id':name,'duration_seconds':r.get('duration_seconds'),'issues':r.get('issues'),'metrics':r.get('metrics')});continue\n subprocess.run(['ffmpeg'")
p.write_text(s)
