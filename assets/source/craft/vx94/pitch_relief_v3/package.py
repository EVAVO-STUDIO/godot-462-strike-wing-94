from pathlib import Path
import shutil,json,hashlib
repo=Path.cwd();b=repo/'work/vx94_pitch_relief_v3';d=repo/'assets/source/craft/vx94/pitch_relief_v3';d.mkdir(parents=True,exist_ok=True);(d/'.gdignore').write_text('')
for name in ['fighter','bomber','clean','clean_evidence','clean_proofs','sprite_clean','board','proof_full','review']:
 shutil.copytree(b/name,d/name,dirs_exist_ok=True)
for p in b.iterdir():
 if p.is_file() and p.suffix in ['.json','.py','.mjs','.log']:shutil.copy2(p,d/p.name)
shutil.copy2(repo/'work/build_vx94_pitch_relief_v3.py',d/'build_vx94_pitch_relief_v3.py')
(d/'originals').mkdir(exist_ok=True)
for form in ['fighter','bomber']:shutil.copy2(repo/f'assets/runtime/craft/vx94/gameplay/bank/{form}_neutral.png',d/'originals'/f'{form}_neutral.png')
(d/'native_review').mkdir(exist_ok=True)
for n in [0,12,36,48]:shutil.copy2(b/f'native_review/frame_{n:03}.png',d/f'native_review/frame_{n:03}.png')
files=[{'path':str(p.relative_to(d)).replace('\\','/'),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in sorted(d.rglob('*')) if p.is_file()]
(d/'manifest.json').write_text(json.dumps({'status':'reviewed_source_candidate_not_runtime','frames':14,'forms':2,'distinct_frames':12,'pitch_degrees':[-18,-12,-6,0,6,12,18],'canvas':[64,72],'pivot':[32,38],'files':files},indent=2)+'\n')
