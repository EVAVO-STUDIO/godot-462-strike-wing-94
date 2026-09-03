extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const CombatArtDirector = preload("res://scripts/combat_art_director.gd")

const ENVIRONMENT_MASTERS := [
	"coast/coastal_strike_zone_loop_v1.png", "industrial/refinery_night_loop_v1.png",
	"water/storm_sea_loop_v1.png", "desert/desert_front_loop_v1.png",
	"river/river_corridor_loop_v1.png", "mountain/mountain_radar_loop_v1.png",
	"harbor/night_harbor_loop_v1.png", "machine_furnace/machine_furnace_loop_v1.png",
	"city/city_outskirts_loop_v1.png", "high_atmosphere/stratospheric_cloud_deck_loop_v1.png",
	"orbital/black_sky_station_loop_v1.png",
]
const SUPPORT_FAMILIES := ["atlas_tanker", "rapier_fighter", "hammer_bomber", "spectre_gunship"]
const MOTION_MANIFESTS := [
	"ground_mechs_asset_manifest.json", "mercenary_infantry_asset_manifest.json",
	"mercenary_air_asset_manifest.json", "machine_air_asset_manifest.json", "orbital_air_asset_manifest.json",
	"mercenary_sea_asset_manifest.json", "machine_ground_asset_manifest.json",
	"mercenary_ground_asset_manifest.json",
	"mercenary_boss_asset_manifest.json", "machine_boss_asset_manifest.json", "orbital_boss_asset_manifest.json",
]
const LAYERED_RUNTIME_MANIFESTS := [
	"res://assets/source/effects/combat_fx_v2/combat_fx_v2_manifest.json",
	"res://assets/source/enemies/machine_air_layered/machine_air_layered_manifest.json",
	"res://assets/source/enemies/machine_boss_layered/machine_boss_layered_manifest.json",
	"res://assets/source/enemies/mercenary_boss_layered/mercenary_boss_layered_manifest.json",
	"res://assets/source/enemies/orbital_air_layered/orbital_air_layered_manifest.json",
	"res://assets/source/enemies/orbital_boss_layered/orbital_boss_layered_manifest.json",
]

var failures: Array[String] = []

func _initialize() -> void:
	_test_canonical_content()
	_test_environment_coverage()
	_test_support_coverage()
	_test_motion_manifests()
	_test_layered_runtime_manifests()
	_test_presentation_coverage()
	if failures.is_empty():
		print("HYPERSONIC production-art coverage self-test passed: 38 enemies, 30 missions, 11 environments, 4 support families.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_canonical_content() -> void:
	var enemy_data: Dictionary = ContentCatalog.load_json("res://data/enemies.json")
	var enemies: Array = enemy_data.get("enemies", [])
	_expect(enemies.size() == 38, "production coverage should retain all 38 canonical enemy archetypes")
	var boss_count := 0
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var enemy_id := str(enemy.get("id", ""))
		_expect(CombatArtDirector.has_production_art(enemy_id), "canonical enemy lacks registered runtime production art: %s" % enemy_id)
		if bool(enemy.get("boss", false)): boss_count += 1
	_expect(boss_count == 9, "all nine canonical bosses should remain represented")
	var missions: Array = ContentCatalog.load_json("res://data/missions.json").get("missions", [])
	_expect(missions.size() == 30, "production campaign should retain 30 core missions")
	for mission in missions:
		if typeof(mission) == TYPE_DICTIONARY:
			_expect(not str(mission.get("environment", "")).is_empty(), "mission lacks an authored environment identity: %s" % str(mission.get("id", "")))

func _test_environment_coverage() -> void:
	for relative_path in ENVIRONMENT_MASTERS:
		var texture := load("res://assets/runtime/environments/%s" % relative_path)
		_expect(texture is Texture2D and texture.get_size() == Vector2(640,720), "environment master should retain reviewed 640x720 geometry: %s" % relative_path)

func _test_support_coverage() -> void:
	for family in SUPPORT_FAMILIES:
		for frame_index in range(4):
			_expect(load("res://assets/runtime/support/battlefield/%s/%d.png" % [family, frame_index]) is Texture2D, "allied support animation frame is missing: %s/%d" % [family, frame_index])

func _test_motion_manifests() -> void:
	for file_name in MOTION_MANIFESTS:
		var data: Dictionary = ContentCatalog.load_json("res://assets/source/enemies/%s" % file_name)
		_expect(typeof(data) == TYPE_DICTIONARY, "enemy production manifest should parse: %s" % file_name)
		_expect(str(data.get("status", "")).contains("runtime"), "enemy production manifest should declare runtime status: %s" % file_name)
		_expect(data.has("runtime_animation"), "animated enemy family should declare completed runtime animation: %s" % file_name)

func _test_layered_runtime_manifests() -> void:
	for manifest_path in LAYERED_RUNTIME_MANIFESTS:
		var data: Dictionary = ContentCatalog.load_json(manifest_path)
		_expect(typeof(data) == TYPE_DICTIONARY, "layered production manifest should parse: %s" % manifest_path)
		_expect(str(data.get("status", "")).contains("runtime"), "live layered production art must not remain labelled as a candidate: %s" % manifest_path)

func _test_presentation_coverage() -> void:
	var title := load("res://assets/runtime/title/hypersonic_wordmark_v3.png")
	var menu := load("res://assets/runtime/ui/menu/sortie_bay_backdrop_v1.png")
	_expect(title is Texture2D and title.get_size() == Vector2(500,80), "reviewed HYPERSONIC title sprite should remain production-ready")
	_expect(menu is Texture2D and menu.get_size() == Vector2(640,360), "reviewed sortie-bay menu environment should remain production-ready")
	_expect(ContentCatalog.load_json("res://data/cinematics.json").get("sequences", []).size() == 3, "campaign presentation should retain two sector transitions and an ending")
	for family in ["human_turbine", "machine_thruster", "orbital_impulse"]:
		for frame_index in range(4):
			_expect(load("res://assets/runtime/effects/enemy_propulsion/%s/%d.png" % [family, frame_index]) is Texture2D, "hostile propulsion art is missing: %s/%d" % [family, frame_index])

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
