from pathlib import Path
import shutil,json,hashlib
r=Path.cwd();b=r/'work/vx94_external_stores_v3';d=r/'assets/source/craft/vx94/external_stores_v3';d.mkdir(parents=True,exist_ok=True);(d/'.gdignore').write_text('')
for name in ['layers','composites','evidence','proofs','sprite','board','native','review']:shutil.copytree(b/name,d/name,dirs_exist_ok=True)
for p in b.iterdir():
 if p.is_file():shutil.copy2(p,d/p.name)
shutil.copy2(r/'work/build_vx94_external_stores_v3.mjs',d/'build_vx94_external_stores_v3.mjs')
(d/'originals').mkdir(exist_ok=True)
for form in ['fighter','bomber']:shutil.copy2(r/f'assets/runtime/craft/vx94/gameplay/bank/{form}_neutral.png',d/'originals'/f'{form}_neutral.png')
files=[{'path':p.relative_to(d).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in sorted(d.rglob('*')) if p.is_file()]
(d/'source_inventory.json').write_text(json.dumps(files,indent=2)+'\n')
