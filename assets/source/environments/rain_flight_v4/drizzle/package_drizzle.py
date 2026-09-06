from pathlib import Path
import json, shutil, subprocess

repo = Path(__file__).resolve().parents[2]
base = repo / 'work/rain_flight_v4'
dest = repo / 'assets/source/environments/rain_flight_v4'
out = Path('C:/Users/User/Documents/Codex/2026-09-05/g/outputs')
target = dest / 'drizzle'
target.mkdir(exist_ok=True)
native = base / 'native_drizzle_invulnerable'
data = json.loads((native / 'manifest.json').read_text())
assert len(data['frames']) == 120
speeds = [f['speed_multiplier'] for f in data['frames']]
assert max(speeds) > min(speeds)
for name in ['review_drizzle.gd', 'review_drizzle_invulnerable.gd', 'native_drizzle.log', 'native_drizzle_invulnerable.log', 'package_drizzle.py']:
    shutil.copy2(base / name, target / name)
shutil.copy2(native / 'manifest.json', target / 'manifest.json')
for i in [18, 54, 84, 114]:
    shutil.copy2(native / f'frame_{i:03}.png', target / f'frame_{i:03}.png')
review = {
    'status': 'native_drizzle_art_review_completed_not_runtime_integration',
    'native_frames': 120, 'reviewed_frames': [18, 54, 84, 114],
    'speed_range': [min(speeds), max(speeds)],
    'atmosphere_head_samples': 8064, 'maximum_head_error_pixels': 0.00006103515625,
    'capture_invulnerable': True,
    'finding': 'Drizzle is sparse and subtle over the dense refinery. Gunfire, lock reticle and radio remain legible in the inspected frames. This does not establish whole-mission readability.',
    'first_capture': 'Preserved in work/rain_flight_v4/native_drizzle. Aircraft died before completion; frame 114 is debrief and cannot establish combat-weather acceptance.',
    'open': ['altitude blending', 'orbital exclusion', 'reduced effects', 'audio mix', 'production adapter', 'normal-play validation'],
}
(target / 'review.json').write_text(json.dumps(review, indent=2) + '\n', encoding='utf-8')
readme = dest / 'README.md'
text = readme.read_text()
text = text.replace('Drizzle was compiled and loop-verified but did not receive a separate live capture in this pass.', 'Drizzle subsequently received a separate 120-frame native capture; see `drizzle/review.json`. Its first vulnerable capture reached aircraft destruction, so the completed art inspection uses invulnerability and does not establish survival balance.')
readme.write_text(text, encoding='utf-8', newline='\n')
manifest = json.loads((dest / 'manifest.json').read_text())
manifest['native_review']['drizzle'] = review
(dest / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
shutil.copy2(native / 'frame_084.png', out / 'HYPERSONIC-drizzle-flight.png')
subprocess.run(['ffmpeg', '-y', '-framerate', '12', '-i', str(native / 'frame_%03d.png'), '-c:v', 'libx264', '-crf', '18', '-pix_fmt', 'yuv420p', str(out / 'HYPERSONIC-drizzle-flight.mp4')], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print(json.dumps(review))
