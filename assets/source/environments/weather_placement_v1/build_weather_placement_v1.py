from pathlib import Path
import hashlib, json

repo = Path(__file__).resolve().parents[1]
dest = repo / 'assets/source/environments/weather_placement_v1'
dest.mkdir(parents=True, exist_ok=True)
(dest / '.gdignore').write_text('')
selections = {
    'm02_refinery_run': ('drizzle', 'Light wet haze; preserve machinery and gunfire contrast.'),
    'm03_black_sea': ('rain', 'Sea squall beneath the cloud deck.'),
    'm06_black_flag': ('storm', 'Heavier maritime front for the returning fleet strike.'),
    's1_m08_river_hammer': ('rain', 'Rain over the flooded valley; bridge openings remain legible.'),
    's1_m09_mountain_eye': ('snow', 'Snow and spindrift at the established mountain storm wall.'),
    's1_m10_night_harbor': ('drizzle', 'Restrained rain in the blackout harbor; no bright white streak field.'),
    's2_m03_broken_truce': ('rain', 'Coastal rain with crisp allied markings and warnings.'),
    's2_m06_ghost_convoy': ('drizzle', 'Light rain over the abandoned city belt.'),
    's2_m08_swarm_sea': ('rain', 'Maritime rain with clear missile/drone silhouettes.'),
    's2_m09_silent_city': ('drizzle', 'Restrained city rain; retain factory and tunnel contrast.'),
    'sm01_black_wake': ('drizzle', 'A thinning maritime front beyond the fleet screen.'),
    'sm03_dead_frequency': ('storm', 'The briefing explicitly locates the relay inside a storm wall.'),
    'sm04_seed_manifest': ('drizzle', 'Match the parent city convoy setting after its selector is corrected.'),
    'sm05_submerged_cradle': ('rain', 'Match the parent Swarm Sea weather over the littoral approach.'),
}
rows = []
source_hashes = {}
for filename, campaign in [('missions.json', 'campaign'), ('secret_missions.json', 'secret')]:
    p = repo / 'data' / filename
    source_hashes[filename] = hashlib.sha256(p.read_bytes()).hexdigest()
    for mission in json.loads(p.read_text())['missions']:
        orbital = mission['environment'] == 'orbital'
        profile, reason = selections.get(mission['id'], ('clear', 'Retain existing clear atmosphere and authored cloud/terrain layers.'))
        if orbital:
            assert profile == 'clear'
            reason = 'Orbital vacuum: no precipitation or local cloud banks; retain distant Earth atmosphere.'
        rows.append({'mission_id': mission['id'], 'campaign': campaign,
                     'environment': mission['environment'], 'environment_variant': mission.get('environment_variant'),
                     'precipitation': profile, 'reason': reason, 'orbital_exclusion': orbital})
assert len(rows) == 36 and len({r['mission_id'] for r in rows}) == 36
assert set(selections) <= {r['mission_id'] for r in rows}
manifest = {
    'status': 'art_direction_delivery_not_runtime_configuration',
    'source_catalogue_sha256': source_hashes,
    'profiles': {'clear': None, 'drizzle': '../rain_flight_v4/drizzle_plan.json',
                 'rain': '../rain_flight_v4/rain_plan.json', 'storm': '../rain_flight_v4/storm_plan.json',
                 'snow': '../snow_flight_v4'},
    'altitude_precipitation_weights': {'low': 1.0, 'mid': 0.6, 'high': 0.0, 'orbital': 0.0},
    'altitude_note': 'High is treated as above the active precipitation deck. Cloud immersion is separate; never infer altitude from environment name alone.',
    'motion': 'Use integrated world distance per depth band plus independent wind/time. Never reset particle phase on throttle or altitude change.',
    'transition': 'Blend existing particle opacity with the actual altitude-transition ratio; keep identities and positions continuous.',
    'presentation': 'Clip to combat viewport. Keep HUD, lock warnings and radio text clear. No full-screen lightning flashes.',
    'accessibility': 'Existing reduced-effects preference must reduce weather density/opacity without changing threat visibility or weapon behavior.',
    'missions': rows,
}
(dest / 'placement.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8', newline='\n')
(dest / 'build_weather_placement_v1.py').write_bytes(Path(__file__).read_bytes())
print(json.dumps({'missions': len(rows), 'weather_counts': {p: sum(r['precipitation'] == p for r in rows) for p in manifest['profiles']}, 'orbital_exclusions': sum(r['orbital_exclusion'] for r in rows)}))
