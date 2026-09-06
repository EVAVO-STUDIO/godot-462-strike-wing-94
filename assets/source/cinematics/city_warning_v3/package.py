from pathlib import Path
import hashlib,json,shutil
repo=Path(__file__).resolve().parents[2]
dest=repo/'assets/source/cinematics/city_warning_v3'
base=repo/'work/city_warning_v3'
native=repo/'work/cinematic_art_review_v3_clean'
prior=repo/'work/cinematic_art_review_v2'
hash_file=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
rows=[]
for p in sorted(native.glob('*.png')):
    changed=p.name.startswith(('s2_consequence','end_action','end_consequence_final'))
    if not changed:assert hash_file(p)==hash_file(prior/p.name)
    rows.append({'file':p.name,'sha256':hash_file(p),'review':'directly_viewed_current' if changed else 'byte_identical_to_directly_viewed_prior'})
assert len(rows)==48
capture_dest=dest/'native';capture_dest.mkdir(exist_ok=True)
for p in native.glob('*'):shutil.copy2(p,capture_dest/p.name)
for name in ['native.log','native_clean.log','import.log','self_test.log','package.py']:shutil.copy2(base/name,dest/name)
for folder in ['evidence','proofs']:shutil.copytree(base/folder,dest/folder,dirs_exist_ok=True)
shutil.copy2(repo/'work/cinematic_art_review_v3.gd',dest/'capture_review.gd')
manifest=json.loads((dest/'manifest.json').read_text());manifest['status']='reviewed_runtime_art';manifest['builder']='tools/build_city_warning_v3.mjs'
for f in manifest['files']:
    assert hash_file(repo/'assets/runtime/cinematics/fx/machine_war'/f['target'])==f['sha256']
(dest/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',newline='\n')
(dest/'capture_review.json').write_text(json.dumps({'scope':'All twelve shots at four addressed exposures; not continuous playback, audio or campaign triggering.','frames':rows,'native_log':'native_clean.log','discarded_capture':'work/cinematic_art_review_v3: startup overlay obscured shots; not acceptance evidence'},indent=2)+'\n',newline='\n')
out=Path('C:/Users/User/Documents/Codex/2026-09-05/g/outputs')
shutil.copy2(native/'s2_consequence_0.png',out/'HYPERSONIC-machine-war-window.png')
print('Packaged four exact runtime cels and verified coverage of 48 native cinematic exposures.')
