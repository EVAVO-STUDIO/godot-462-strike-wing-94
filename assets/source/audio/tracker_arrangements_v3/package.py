from pathlib import Path
import json,shutil,subprocess,hashlib
b=Path('work/tracker_arrangements_v3');d=Path('assets/source/audio/tracker_arrangements_v3');d.mkdir(parents=True,exist_ok=True);(d/'.gdignore').write_text('');o=Path('C:/Users/User/Documents/Codex/2026-09-05/g/outputs');rows=[]
for file in json.loads((b/'index.json').read_text())['plans']:
 p=json.loads((b/file).read_text());name=p['id'];wav=b/(name+('_softened.wav' if name=='title_vector' else '_review.wav'));rp=b/(name+('_softened_review.json' if name=='title_vector' else '_audio_review.json'));r=json.loads(rp.read_text());assert not r['issues'] and r['metrics']['clippedSamples']==0
 preview=o/('HYPERSONIC-'+name+'-arrangement.ogg');subprocess.run(['ffmpeg','-y','-i',str(wav),'-af','volume=0.52','-c:a','libvorbis','-q:a','6',str(preview)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 rows.append({'id':name,'bars':32,'bpm':p['bpm'],'seconds':r['duration_seconds'],'dc':r['metrics']['dc'],'clipped_samples':0,'detected_issues':0,'review_variant':wav.name,'wav_sha256':hashlib.sha256(wav.read_bytes()).hexdigest(),'audition_gain':.52})
for p in b.iterdir():
 if p.is_file() and p.suffix in ['.json','.py','.gd','.log']:shutil.copy2(p,d/p.name)
shutil.copy2('scripts/retro_music_director.gd',d/'synthesizer_snapshot.gd.txt');shutil.copy2('data/music_tracks.json',d/'original_tracks.json')
(d/'delivery_manifest.json').write_text(json.dumps({'status':'screening_candidates_not_runtime_or_listening_approved','tracks':rows,'steel_vector':'../steel_vector_arrangement_v2','render_engine':'Godot 4.6.2 stable 71f334935'},indent=2)+'\n');print(json.dumps({'tracks':len(rows),'seconds':round(sum(x['seconds'] for x in rows),2),'max_abs_dc':max(abs(x['dc']) for x in rows)}))
