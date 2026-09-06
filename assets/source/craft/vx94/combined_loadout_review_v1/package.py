from pathlib import Path
import shutil,json,hashlib
r=Path.cwd();b=r/'work/vx94_combined_loadouts_v1';d=r/'assets/source/craft/vx94/combined_loadout_review_v1';d.mkdir(parents=True,exist_ok=True);(d/'.gdignore').write_text('')
for name in ['composites','evidence','proofs','board','native','review']:shutil.copytree(b/name,d/name,dirs_exist_ok=True)
for p in b.iterdir():
 if p.is_file():shutil.copy2(p,d/p.name)
shutil.copy2(r/'work/build_vx94_combined_loadouts_v1.mjs',d/'build_vx94_combined_loadouts_v1.mjs')
# Snapshot exact image sources without changing the original hash-bound recipe.
request=json.loads((b/'request.json').read_text());sources=sorted({s for t in request['tasks'] for s in t['sources']})
for s in sources:
 target=d/'input_snapshot'/s;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(r/s,target)
(d/'source_inventory.json').write_text(json.dumps([{'path':p.relative_to(d).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in sorted(d.rglob('*')) if p.is_file()],indent=2)+'\n')
