from pathlib import Path
import hashlib, json

repo = Path(__file__).resolve().parents[1]
out = repo / 'work/destruction_continuity_v2'
out.mkdir(exist_ok=True)
source = repo / 'scripts/combat_fx_director.gd'
original = source.read_text()
(out / 'baseline.gd').write_text(original, newline='\n')
families = [
 ('MERCENARY_BOSS_WRECK_HULLS', '_draw_mercenary_boss_breakup', False),
 ('MACHINE_BOSS_WRECK_HULLS', '_draw_machine_boss_breakup', False),
 ('ORBITAL_BOSS_WRECK_HULLS', '_draw_orbital_boss_breakup', False),
 ('NAVAL_WRECK_HULLS', '_draw_naval_sinking', False),
 ('GROUND_EMPLACEMENT_BREAKUP_FRAMES', '_draw_ground_emplacement_breakup', False),
 ('GROUND_MECH_WRECK_HULLS', '_draw_ground_mech_breakup', True),
 ('GROUND_VEHICLE_WRECK_LAYERS', '_draw_ground_vehicle_breakup', True),
 ('AIRFRAME_WRECK_HULLS', '_draw_airframe_breakup', True),
]
helper = '\nfunc _draw_initial_retained_wreck(surface: CanvasItem, p: Vector2, enemy_id: String, serial: int, faction: String) -> void:\n'
for family, method, faction in families:
    helper += f'\tif {family}.has(enemy_id):\n\t\t{method}(surface, p, 0.0, enemy_id, serial' + (', faction' if faction else '') + ')\n\t\treturn\n'
anchor = '\tvar event_duration := EXPLOSION_SECONDS\n'
assert original.count(anchor) == 1
candidate = original.replace(anchor, '\t# Preserve retained material under the blast until existing breakup takes over.\n\tif ratio <= 0.32:\n\t\t_draw_initial_retained_wreck(surface, p, enemy_id, serial, faction)\n' + anchor) + helper
(out / 'candidate.gd').write_text(candidate, newline='\n')
(out / 'source_binding.json').write_text(json.dumps({'source': str(source), 'sha256': hashlib.sha256(source.read_bytes()).hexdigest(), 'status': 'art_preview_not_production_integration', 'change': 'Hold the existing breakup pose at zero under the early blast, through ratio 0.32 inclusive. Existing late breakup remains unchanged.'}, indent=2) + '\n')
print('Created source-bound baseline and retained-hull candidate.')
