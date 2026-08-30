extends CanvasLayer

const CombatFxSurface = preload("res://scripts/combat_fx_surface.gd")
const RetroSfxRules = preload("res://scripts/retro_sfx_rules.gd")
const ImpactArtLibrary = preload("res://scripts/impact_art_library.gd")
const PersistentEffectArtLibrary = preload("res://scripts/persistent_effect_art_library.gd")
const EXPLOSION_FRAMES := [
	preload("res://assets/runtime/effects/explosion/explosion_0.png"),
	preload("res://assets/runtime/effects/explosion/explosion_1.png"),
	preload("res://assets/runtime/effects/explosion/explosion_2.png"),
	preload("res://assets/runtime/effects/explosion/explosion_3.png"),
	preload("res://assets/runtime/effects/explosion/explosion_4.png"),
	preload("res://assets/runtime/effects/explosion/explosion_5.png"),
	preload("res://assets/runtime/effects/explosion/explosion_6.png"),
	preload("res://assets/runtime/effects/explosion/explosion_7.png"),
]

const MAX_EVENTS := 48
const HIT_SECONDS := 0.12
const EXPLOSION_SECONDS := 0.72
const BOSS_EXPLOSION_SECONDS := 1.05
const BOSS_DESTRUCTION_SECONDS := 2.30
const ORBITAL_BOSS_DESTRUCTION_SECONDS := 3.00
const NAVAL_SINK_SECONDS := 1.35
const PLAYER_HIT_SECONDS := 0.18
const NAVAL_WRECK_HULLS := {
	"river_patrol": preload("res://assets/runtime/enemies/mercenary_sea/river_patrol_idle.png"),
	"torpedo_boat": preload("res://assets/runtime/enemies/mercenary_sea/torpedo_boat_idle.png"),
	"fast_attack_craft": preload("res://assets/runtime/enemies/mercenary_sea/fast_attack_craft_idle.png"),
	"missile_corvette": preload("res://assets/runtime/enemies/mercenary_sea/missile_corvette_idle.png"),
}
const MERCENARY_BOSS_WRECK_HULLS := {
	"gunship_alpha": preload("res://assets/runtime/enemies/mercenary_boss/gunship_alpha_idle.png"),
	"armoured_train": preload("res://assets/runtime/enemies/mercenary_boss/armoured_train_idle.png"),
	"missile_cruiser": preload("res://assets/runtime/enemies/mercenary_boss/missile_cruiser_idle.png"),
}
const MACHINE_BOSS_WRECK_HULLS := {
	"swarm_controller": preload("res://assets/runtime/enemies/machine_boss/swarm_controller_idle_v2.png"),
	"ai_forge_core": preload("res://assets/runtime/enemies/machine_boss/ai_forge_core_idle_v2.png"),
}
const ORBITAL_BOSS_WRECK_HULLS := {
	"orbital_command_node": preload("res://assets/runtime/enemies/orbital_boss/orbital_command_node_idle_v2.png"),
	"phase_control_array": preload("res://assets/runtime/enemies/orbital_boss/phase_control_array_idle_v2.png"),
	"station_warden": preload("res://assets/runtime/enemies/orbital_boss/station_warden_idle.png"),
	"machine_ark": preload("res://assets/runtime/enemies/orbital_boss/machine_ark_idle.png"),
}
const GROUND_EMPLACEMENT_BREAKUP_FRAMES := {
	"fortified_turret": [
		preload("res://assets/runtime/effects/ground_breakup/fort_breakup_0.png"),
		preload("res://assets/runtime/effects/ground_breakup/fort_breakup_1.png"),
		preload("res://assets/runtime/effects/ground_breakup/fort_breakup_2.png"),
	],
	"coastal_flak": [
		preload("res://assets/runtime/effects/ground_breakup/flak_breakup_0.png"),
		preload("res://assets/runtime/effects/ground_breakup/flak_breakup_1.png"),
		preload("res://assets/runtime/effects/ground_breakup/flak_breakup_2.png"),
	],
}
const GROUND_MECH_WRECK_HULLS := {
	"security_patrol_mech": preload("res://assets/runtime/enemies/ground_mechs/security_patrol_mech_idle.png"),
	"autonomous_salvage_mech": preload("res://assets/runtime/enemies/ground_mechs/autonomous_salvage_mech_idle.png"),
}
const GROUND_VEHICLE_WRECK_LAYERS := {
	"light_tank": {
		"base": preload("res://assets/runtime/enemies/mercenary_ground/light_tank_idle.png"),
		"weapon": preload("res://assets/runtime/enemies/mercenary_ground_layered/light_tank_weapon.png"),
	},
	"sam_truck": {
		"base": preload("res://assets/runtime/enemies/mercenary_ground/sam_truck_idle.png"),
		"weapon": preload("res://assets/runtime/enemies/mercenary_ground_layered/sam_truck_weapon.png"),
	},
	"armoured_aa_carrier": {
		"base": preload("res://assets/runtime/enemies/mercenary_ground/armoured_aa_carrier_idle.png"),
		"weapon": preload("res://assets/runtime/enemies/mercenary_ground_layered/aa_carrier_weapon.png"),
	},
	"autonomous_armor": {
		"base": preload("res://assets/runtime/enemies/machine_ground_layered/autonomous_armor_base.png"),
		"weapon": preload("res://assets/runtime/enemies/machine_ground_layered/autonomous_armor_weapon.png"),
	},
	"factory_defence_node": {
		"base": preload("res://assets/runtime/enemies/machine_ground_layered/factory_defence_base.png"),
		"weapon": preload("res://assets/runtime/enemies/machine_ground_layered/factory_defence_weapon.png"),
	},
}

var _surface: Control
var _events: Array = []
var _previous_enemies: Array = []
var _previous_hull := -1
var _previous_shield := -1
var _serial := 0
var _hit_audio_cooldown := 0.0

func _ready() -> void:
	layer = 16
	process_priority = 80
	_surface = CombatFxSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	_hit_audio_cooldown = maxf(0.0, _hit_audio_cooldown - delta)
	_update_events(delta)
	_observe_combat()
	if _surface != null:
		_surface.queue_redraw()

func _observe_combat() -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		_previous_enemies.clear()
		_previous_hull = -1
		_previous_shield = -1
		return

	var current: Array = []
	for enemy in scene.get("enemies"):
		if typeof(enemy) == TYPE_DICTIONARY:
			current.append({
				"id": str(enemy.get("id", "enemy")),
				"position": Vector2(enemy.get("position", Vector2.ZERO)),
				"hp": int(enemy.get("hp", 0)),
				"boss": bool(enemy.get("boss", false)),
				"category": str(enemy.get("category", "air")),
				"faction": str(enemy.get("faction", "mercenary"))
			})

	var matched_current: Dictionary = {}
	for previous in _previous_enemies:
		var match_index := _nearest_match(previous, current, matched_current)
		var now: Dictionary = current[match_index] if match_index >= 0 else {}
		var observation := _observation_kind(previous, now, match_index >= 0)
		if match_index >= 0:
			matched_current[match_index] = true
		if observation == "hit":
			_emit("hit", Vector2(now.get("position", Vector2.ZERO)), 8.0, HIT_SECONDS, {"category": str(now.get("category", "air"))})
		elif observation == "destroyed":
			var kind := "boss_explosion" if bool(previous.get("boss", false)) else "explosion"
			var duration := BOSS_DESTRUCTION_SECONDS if kind == "boss_explosion" else EXPLOSION_SECONDS
			if kind=="boss_explosion" and ORBITAL_BOSS_WRECK_HULLS.has(str(previous.get("id",""))):
				duration=ORBITAL_BOSS_DESTRUCTION_SECONDS
			if kind != "boss_explosion" and str(previous.get("category", "air")) == "sea":
				duration = NAVAL_SINK_SECONDS
			if GROUND_MECH_WRECK_HULLS.has(str(previous.get("id", ""))):
				duration = 1.10
			if GROUND_VEHICLE_WRECK_LAYERS.has(str(previous.get("id", ""))):
				duration = 0.96
			var large_ground_wreck := GROUND_MECH_WRECK_HULLS.has(str(previous.get("id", ""))) or GROUND_VEHICLE_WRECK_LAYERS.has(str(previous.get("id", "")))
			var size := 28.0 if kind == "boss_explosion" else (19.0 if large_ground_wreck else 15.0)
			_emit(kind, Vector2(previous.get("position", Vector2.ZERO)), size, duration, {
				"enemy_id": str(previous.get("id", "enemy")),
				"category": str(previous.get("category", "air")),
				"faction": str(previous.get("faction", "mercenary"))
			})

	var hull := int(scene.get("hull"))
	var shield := int(scene.get("shield"))
	if (_previous_hull >= 0 and hull < _previous_hull) or (_previous_shield >= 0 and shield < _previous_shield):
		_emit("player_hit", Vector2(scene.get("player_position")), 13.0, PLAYER_HIT_SECONDS, {"shield": _previous_shield >= 0 and shield < _previous_shield})
	_previous_hull = hull
	_previous_shield = shield
	_previous_enemies = current

func _observation_kind(previous: Dictionary, current: Dictionary, matched: bool) -> String:
	if not matched:
		return "destroyed"
	if int(current.get("hp", 0)) < int(previous.get("hp", 0)):
		return "hit"
	return ""

func _nearest_match(previous: Dictionary, current: Array, used: Dictionary) -> int:
	var best := -1
	var best_distance := INF
	var previous_id := str(previous.get("id", ""))
	var previous_position: Vector2 = previous.get("position", Vector2.ZERO)
	for i in range(current.size()):
		if used.has(i):
			continue
		var candidate: Dictionary = current[i]
		if str(candidate.get("id", "")) != previous_id:
			continue
		var distance := previous_position.distance_squared_to(Vector2(candidate.get("position", Vector2.ZERO)))
		if distance < best_distance and distance <= 180.0 * 180.0:
			best_distance = distance
			best = i
	return best

func _emit(kind: String, position: Vector2, size: float, duration: float, metadata := {}) -> void:
	_serial += 1
	var event := {
		"kind": kind,
		"position": position,
		"size": size,
		"age": 0.0,
		"duration": duration,
		"serial": _serial
	}
	if typeof(metadata) == TYPE_DICTIONARY:
		for key in metadata:
			event[key] = metadata[key]
	_events.append(event)
	while _events.size() > MAX_EVENTS:
		_events.pop_front()
	_play_audio_for(kind)

func _play_audio_for(kind: String) -> void:
	var event_id := ""
	match kind:
		"hit":
			if _hit_audio_cooldown > 0.0:
				return
			_hit_audio_cooldown = 0.035
			event_id = RetroSfxRules.HIT
		"explosion":
			event_id = RetroSfxRules.EXPLOSION
		"boss_explosion":
			event_id = RetroSfxRules.BOSS_EXPLOSION
		"player_hit":
			event_id = RetroSfxRules.PLAYER_HIT
	if event_id == "":
		return
	var audio := get_node_or_null("/root/RetroSfxDirector")
	if audio != null and audio.has_method("play_event"):
		audio.call("play_event", event_id)

func _update_events(delta: float) -> void:
	for i in range(_events.size() - 1, -1, -1):
		var event: Dictionary = _events[i]
		event["age"] = float(event.get("age", 0.0)) + maxf(0.0, delta)
		if float(event["age"]) >= float(event.get("duration", 0.1)):
			_events.remove_at(i)
		else:
			_events[i] = event

func _draw_combat_fx(surface: CanvasItem) -> void:
	for event in _events:
		if typeof(event) != TYPE_DICTIONARY:
			continue
		var kind := str(event.get("kind", "hit"))
		var position: Vector2 = event.get("position", Vector2.ZERO)
		var duration := maxf(0.001, float(event.get("duration", 0.1)))
		var ratio := clampf(float(event.get("age", 0.0)) / duration, 0.0, 1.0)
		match kind:
			"hit":
				_draw_hit(surface, position, ratio, str(event.get("category", "air")))
			"explosion":
				_draw_explosion(surface, position, ratio, float(event.get("size", 15.0)), int(event.get("serial", 0)), false, str(event.get("category", "air")), str(event.get("faction", "mercenary")), str(event.get("enemy_id", "enemy")))
			"boss_explosion":
				_draw_explosion(surface, position, ratio, float(event.get("size", 28.0)), int(event.get("serial", 0)), true, str(event.get("category", "air")), str(event.get("faction", "mercenary")), str(event.get("enemy_id", "boss")))
			"player_hit":
				_draw_player_hit(surface, position, ratio, bool(event.get("shield", true)))

func _draw_hit(surface: CanvasItem, p: Vector2, ratio: float, category: String) -> void:
	var family := "water_impact" if category == "sea" else "armor_hit"
	var texture := ImpactArtLibrary.frame_for_ratio(family, ratio)
	surface.draw_texture(texture, (p - Vector2(12, 12)).round())

func _draw_explosion(surface: CanvasItem, p: Vector2, ratio: float, max_size: float, serial: int, boss: bool, category: String, faction: String, enemy_id: String) -> void:
	var visual_ratio := ratio
	if boss:
		var boss_duration := ORBITAL_BOSS_DESTRUCTION_SECONDS if ORBITAL_BOSS_WRECK_HULLS.has(enemy_id) else BOSS_DESTRUCTION_SECONDS
		visual_ratio = clampf(ratio * (boss_duration / BOSS_EXPLOSION_SECONDS),0.0,0.999)
	elif category == "sea":
		visual_ratio = clampf(ratio * (NAVAL_SINK_SECONDS / EXPLOSION_SECONDS),0.0,0.999)
	var blast_ratio := clampf(visual_ratio / 0.66, 0.0, 0.999)
	if category == "sea":
		var water := ImpactArtLibrary.frame_for_ratio("water_impact", clampf(visual_ratio / 0.72, 0.0, 0.999))
		var water_size := Vector2.ONE * lerpf(20.0, 38.0, visual_ratio)
		surface.draw_texture_rect(water, Rect2((p - water_size * 0.5).round(), water_size), false, Color(0.66,0.80,0.86,0.72*(1.0-visual_ratio*0.65)))
	var frame_index := clampi(int(floor(blast_ratio * float(EXPLOSION_FRAMES.size()))), 0, EXPLOSION_FRAMES.size() - 1)
	var frame: Texture2D = EXPLOSION_FRAMES[frame_index]
	var draw_size := roundf(max_size * (2.35 if boss else 2.20))
	surface.draw_texture_rect(frame, Rect2((p - Vector2.ONE * draw_size * 0.5).round(), Vector2.ONE * draw_size), false, Color(1,1,1,1.0-smoothstep(0.68,1.0,visual_ratio)))
	var radius := maxf(2.0, max_size * smoothstep(0.0, 1.0, visual_ratio))
	var debris := PersistentEffectArtLibrary.frame_for_ratio("debris", visual_ratio)
	var debris_size := Vector2.ONE * maxf(24.0, radius * (2.4 if boss else 2.0))
	var debris_tint := Color(0.78,0.86,0.90,1.0-visual_ratio) if faction == "autonomous" else Color(0.86,0.78,0.62,1.0-visual_ratio)
	surface.draw_texture_rect(debris, Rect2((p - debris_size * 0.5).round(), debris_size), false, debris_tint)
	_draw_destruction_consequence(surface, p, ratio, category, faction, enemy_id, serial, boss)

func _draw_destruction_consequence(surface: CanvasItem, p: Vector2, ratio: float, category: String, faction: String, enemy_id: String, serial: int, boss: bool) -> void:
	var late_ratio := clampf((ratio - 0.32) / 0.68, 0.0, 0.999)
	if late_ratio <= 0.0:
		return
	if MERCENARY_BOSS_WRECK_HULLS.has(enemy_id):
		_draw_mercenary_boss_breakup(surface,p,late_ratio,enemy_id,serial)
		return
	if MACHINE_BOSS_WRECK_HULLS.has(enemy_id):
		_draw_machine_boss_breakup(surface,p,late_ratio,enemy_id,serial)
		return
	if ORBITAL_BOSS_WRECK_HULLS.has(enemy_id):
		_draw_orbital_boss_breakup(surface,p,late_ratio,enemy_id,serial)
		return
	if category == "sea" and NAVAL_WRECK_HULLS.has(enemy_id):
		_draw_naval_sinking(surface, p, late_ratio, enemy_id, serial)
		return
	if GROUND_EMPLACEMENT_BREAKUP_FRAMES.has(enemy_id):
		_draw_ground_emplacement_breakup(surface,p,late_ratio,enemy_id,serial)
		return
	if GROUND_MECH_WRECK_HULLS.has(enemy_id):
		_draw_ground_mech_breakup(surface,p,late_ratio,enemy_id,serial,faction)
		return
	if GROUND_VEHICLE_WRECK_LAYERS.has(enemy_id):
		_draw_ground_vehicle_breakup(surface,p,late_ratio,enemy_id,serial,faction)
		return
	if enemy_id in ["mercenary_rifle_team", "mercenary_heavy_team"]:
		var dust := ImpactArtLibrary.frame_for_ratio("dust_impact", late_ratio)
		var dust_size := Vector2.ONE * lerpf(22.0, 38.0, late_ratio)
		surface.draw_texture_rect(dust, Rect2((p - dust_size * 0.5).round(), dust_size), false, Color(0.72,0.68,0.56,1.0-late_ratio))
		return
	if faction == "autonomous":
		var disruption := ImpactArtLibrary.frame_for_ratio("emp_disruption", late_ratio)
		var field_size := Vector2.ONE * lerpf(24.0, 42.0 if boss else 32.0, late_ratio)
		surface.draw_texture_rect(disruption, Rect2((p - field_size * 0.5).round(), field_size), false, Color(0.62,0.84,0.92,1.0-late_ratio))
	var phase := serial + int(floor(late_ratio * 4.0))
	var smoke := PersistentEffectArtLibrary.FRAMES["damage_smoke"][posmod(phase, 4)] as Texture2D
	var smoke_center := p + Vector2(-5.0 if category == "air" else 4.0, -8.0)
	var smoke_size := Vector2.ONE * (42.0 if boss else 28.0)
	surface.draw_texture_rect(smoke, Rect2((smoke_center - smoke_size * 0.5).round(), smoke_size), false, Color(0.68,0.70,0.68,0.82*(1.0-late_ratio)))
	if category == "ground" and faction != "autonomous" and late_ratio < 0.72:
		var fire := PersistentEffectArtLibrary.FRAMES["damage_fire"][posmod(phase + 1, 4)] as Texture2D
		surface.draw_texture_rect(fire, Rect2((p - Vector2(14,14)).round(), Vector2(28,28)), false, Color(0.94,0.76,0.48,1.0-late_ratio))

func _draw_ground_emplacement_breakup(surface: CanvasItem, p: Vector2, ratio: float, enemy_id: String, serial: int) -> void:
	var frames: Array = GROUND_EMPLACEMENT_BREAKUP_FRAMES[enemy_id]
	var frame_index := clampi(int(floor(ratio*3.0)),0,2)
	var wreck: Texture2D = frames[frame_index]
	var wreck_alpha := 1.0-smoothstep(0.80,1.0,ratio)
	surface.draw_texture(wreck,(p-wreck.get_size()*0.5).round(),Color(0.78,0.74,0.64,wreck_alpha))
	var dust := ImpactArtLibrary.frame_for_ratio("dust_impact",fmod(ratio*1.45,0.999))
	var dust_size := Vector2.ONE*lerpf(24,42,ratio)
	surface.draw_texture_rect(dust,Rect2((p+Vector2(0,5)-dust_size*0.5).round(),dust_size),false,Color(0.68,0.62,0.50,0.58*(1.0-ratio)))
	var phase := serial+frame_index
	if ratio<0.62:
		var fire: Texture2D = PersistentEffectArtLibrary.FRAMES["damage_fire"][posmod(phase,4)]
		surface.draw_texture_rect(fire,Rect2((p+Vector2(3,-2)-Vector2(11,11)).round(),Vector2(22,22)),false,Color(0.88,0.66,0.40,0.72*(1.0-ratio)))
	if ratio>0.28:
		var smoke: Texture2D = PersistentEffectArtLibrary.FRAMES["damage_smoke"][posmod(phase+1,4)]
		surface.draw_texture_rect(smoke,Rect2((p+Vector2(-4,-9)-Vector2(12,12)).round(),Vector2(24,24)),false,Color(0.57,0.58,0.54,0.62*(1.0-ratio)))

func _draw_ground_mech_breakup(surface: CanvasItem, p: Vector2, ratio: float, enemy_id: String, serial: int, faction: String) -> void:
	var hull: Texture2D = GROUND_MECH_WRECK_HULLS[enemy_id]
	var width := float(hull.get_width())
	var height := float(hull.get_height())
	var torso_height := floorf(height * 0.62)
	var lower_height := height - torso_height
	var half_width := floorf(width * 0.5)
	var direction := -1.0 if posmod(serial, 2) == 0 else 1.0
	var fade := 1.0 - smoothstep(0.78, 1.0, ratio)
	var tint := Color(0.52,0.56,0.55,fade) if faction == "autonomous" else Color(0.58,0.54,0.46,fade)

	# Preserve the authored clusters: the torso falls as one heavy assembly
	# while each lower actuator separates along a different trajectory.
	var torso_center := p + Vector2(direction * 7.0 * ratio, -height * 0.19 + 10.0 * ratio * ratio)
	surface.draw_set_transform(torso_center.round(), direction * 0.34 * ratio, Vector2.ONE)
	surface.draw_texture_rect_region(hull, Rect2(-width*0.5,-torso_height*0.5,width,torso_height), Rect2(0,0,width,torso_height), tint)
	surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	for side_index in range(2):
		var side := -1.0 if side_index == 0 else 1.0
		var source_x := 0.0 if side_index == 0 else half_width
		var section_width := half_width if side_index == 0 else width-half_width
		var leg_center := p + Vector2(side*(width*0.24+9.0*ratio),height*0.18+14.0*ratio*ratio)
		surface.draw_set_transform(leg_center.round(),side*0.42*ratio,Vector2.ONE)
		surface.draw_texture_rect_region(hull,Rect2(-section_width*0.5,-lower_height*0.5,section_width,lower_height),Rect2(source_x,torso_height,section_width,lower_height),tint)
		surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

	_draw_boss_breakup_burst(surface,p+Vector2(direction*4,-5),ratio-0.05,25.0)
	_draw_boss_breakup_burst(surface,p+Vector2(-direction*7,8),ratio-0.34,20.0)
	if faction == "autonomous":
		var disruption := ImpactArtLibrary.frame_for_ratio("emp_disruption",fmod(ratio*1.65,0.999))
		var field_size := Vector2.ONE*lerpf(28.0,48.0,ratio)
		surface.draw_texture_rect(disruption,Rect2((p-field_size*0.5).round(),field_size),false,Color(0.56,0.80,0.86,0.62*(1.0-ratio)))
	elif ratio > 0.22 and ratio < 0.82:
		var smoke: Texture2D = PersistentEffectArtLibrary.FRAMES["damage_smoke"][posmod(serial+int(ratio*7.0),4)]
		surface.draw_texture_rect(smoke,Rect2((p+Vector2(3,-12)-Vector2(14,14)).round(),Vector2(28,28)),false,Color(0.54,0.52,0.46,0.70*(1.0-ratio)))

func _draw_ground_vehicle_breakup(surface: CanvasItem, p: Vector2, ratio: float, enemy_id: String, serial: int, faction: String) -> void:
	var layers: Dictionary = GROUND_VEHICLE_WRECK_LAYERS[enemy_id]
	var chassis: Texture2D = layers["base"]
	var weapon: Texture2D = layers["weapon"]
	var direction := -1.0 if posmod(serial,2)==0 else 1.0
	var fade := 1.0-smoothstep(0.82,1.0,ratio)
	var cold := faction == "autonomous"
	var chassis_tint := Color(0.46,0.53,0.54,fade) if cold else Color(0.54,0.50,0.42,fade)
	var chassis_offset := Vector2(direction*3.0*ratio,7.0*ratio*ratio)
	surface.draw_set_transform((p+chassis_offset).round(),direction*0.12*ratio,Vector2(1.0,1.0-0.10*ratio))
	surface.draw_texture(chassis,-chassis.get_size()*0.5,chassis_tint)
	surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

	# The separately registered live weapon remains a distinct physical mass:
	# blast impulse lifts it off its traverse ring before it falls and rotates.
	var weapon_lift := sin(ratio*PI)*13.0
	var weapon_center := p+Vector2(-direction*8.0*ratio,-weapon_lift+5.0*ratio*ratio)
	surface.draw_set_transform(weapon_center.round(),direction*ratio*1.25,Vector2.ONE*0.84)
	surface.draw_texture(weapon,-weapon.get_size()*0.5,Color(chassis_tint,fade))
	surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	_draw_boss_breakup_burst(surface,p+Vector2(0,-2),ratio-0.06,24.0)
	var dust := ImpactArtLibrary.frame_for_ratio("dust_impact",fmod(ratio*1.52,0.999))
	var dust_size := Vector2.ONE*lerpf(24.0,42.0,ratio)
	surface.draw_texture_rect(dust,Rect2((p+Vector2(0,7)-dust_size*0.5).round(),dust_size),false,Color(0.60,0.58,0.50,0.52*(1.0-ratio)))
	if cold:
		var disruption := ImpactArtLibrary.frame_for_ratio("emp_disruption",fmod(ratio*1.72,0.999))
		var field_size := Vector2.ONE*lerpf(26.0,46.0,ratio)
		surface.draw_texture_rect(disruption,Rect2((p-field_size*0.5).round(),field_size),false,Color(0.55,0.79,0.85,0.58*(1.0-ratio)))
	elif ratio>0.28 and ratio<0.82:
		var fire: Texture2D = PersistentEffectArtLibrary.FRAMES["damage_fire"][posmod(serial+int(ratio*6.0),4)]
		surface.draw_texture_rect(fire,Rect2((p+Vector2(direction*4,-4)-Vector2(10,10)).round(),Vector2(20,20)),false,Color(0.88,0.65,0.38,0.70*(1.0-ratio)))

func _draw_naval_sinking(surface: CanvasItem, p: Vector2, ratio: float, enemy_id: String, serial: int) -> void:
	var hull: Texture2D = NAVAL_WRECK_HULLS[enemy_id]
	var list_direction := -1.0 if posmod(serial, 2) == 0 else 1.0
	var list_angle := list_direction * lerpf(0.025, 0.27, smoothstep(0.10, 1.0, ratio))
	var sink_offset := Vector2(list_direction * 2.5 * ratio, 9.0 * ratio * ratio)
	var sink_scale := Vector2(1.0 - 0.08 * ratio, 1.0 - 0.24 * ratio)
	var hull_alpha := 1.0 - smoothstep(0.72, 1.0, ratio)
	surface.draw_set_transform((p + sink_offset).round(), list_angle, sink_scale)
	surface.draw_texture(hull, -hull.get_size() * 0.5, Color(0.68, 0.74, 0.75, hull_alpha))
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var stage := clampi(int(floor(ratio * 4.0)), 0, 3)
	var displacement := ImpactArtLibrary.frame_for_ratio("water_impact", fmod(ratio * 1.7, 0.999))
	var bow := p + Vector2(list_direction * lerpf(3.0, 8.0, ratio), -hull.get_height() * 0.20 + 6.0 * ratio)
	var stern := p + Vector2(-list_direction * 4.0, hull.get_height() * 0.22 + 8.0 * ratio)
	var water_size := Vector2.ONE * lerpf(18.0, 34.0, ratio)
	surface.draw_texture_rect(displacement, Rect2((stern - water_size * 0.5).round(), water_size), false, Color(0.70, 0.84, 0.88, 0.78 * (1.0-ratio)))
	if stage >= 1:
		surface.draw_texture_rect(displacement, Rect2((bow - water_size * 0.40).round(), water_size * 0.80), false, Color(0.74, 0.86, 0.90, 0.62 * (1.0-ratio)))
	if stage >= 2 and ratio < 0.86:
		var smoke: Texture2D = PersistentEffectArtLibrary.FRAMES["damage_smoke"][posmod(serial + stage, 4)]
		surface.draw_texture_rect(smoke, Rect2((p + Vector2(3,-9) - Vector2(13,13)).round(), Vector2(26,26)), false, Color(0.52,0.56,0.56,0.62*(1.0-ratio)))

func _draw_mercenary_boss_breakup(surface: CanvasItem, p: Vector2, ratio: float, enemy_id: String, serial: int) -> void:
	var hull: Texture2D = MERCENARY_BOSS_WRECK_HULLS[enemy_id]
	var fade := 1.0-smoothstep(0.82,1.0,ratio)
	if enemy_id == "gunship_alpha":
		var roll := (-1.0 if posmod(serial,2)==0 else 1.0)*lerpf(0.02,0.34,ratio)
		surface.draw_set_transform((p+Vector2(5.0*ratio,15.0*ratio*ratio)).round(),roll,Vector2.ONE*(1.0-0.10*ratio))
		surface.draw_texture(hull,-hull.get_size()*0.5,Color(0.64,0.62,0.56,fade))
		surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		for event in [{"at":0.04,"point":Vector2(-22,-5)},{"at":0.24,"point":Vector2(22,-5)},{"at":0.48,"point":Vector2(0,14)},{"at":0.69,"point":Vector2(0,-18)}]:
			_draw_boss_breakup_burst(surface,p+event["point"],ratio-float(event["at"]),34.0)
	elif enemy_id == "armoured_train":
		var section_height := hull.get_height()/3.0
		for section in range(3):
			var local_ratio := clampf((ratio-float(section)*0.10)/0.90,0.0,1.0)
			var direction := -1.0 if section%2==0 else 1.0
			var source_region := Rect2(0,section_height*section,hull.get_width(),section_height)
			var section_center := Vector2(0,-hull.get_height()*0.5+section_height*(section+0.5))
			surface.draw_set_transform((p+section_center+Vector2(direction*12.0*local_ratio,8.0*local_ratio*local_ratio)).round(),direction*0.13*local_ratio,Vector2.ONE)
			surface.draw_texture_rect_region(hull,Rect2(-hull.get_width()*0.5,-section_height*0.5,hull.get_width(),section_height),source_region,Color(0.66,0.62,0.54,fade))
			surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
			_draw_boss_breakup_burst(surface,p+section_center,ratio-(0.10+section*0.20),36.0)
	else:
		var list_direction := -1.0 if posmod(serial,2)==0 else 1.0
		var angle := list_direction*lerpf(0.01,0.24,ratio)
		var offset := Vector2(list_direction*5.0*ratio,18.0*ratio*ratio)
		surface.draw_set_transform((p+offset).round(),angle,Vector2(1.0-0.08*ratio,1.0-0.28*ratio))
		surface.draw_texture(hull,-hull.get_size()*0.5,Color(0.61,0.65,0.62,fade))
		surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		for event in [{"at":0.06,"point":Vector2(-21,-7)},{"at":0.25,"point":Vector2(21,-7)},{"at":0.47,"point":Vector2(0,-35)},{"at":0.68,"point":Vector2(0,28)}]:
			_draw_boss_breakup_burst(surface,p+event["point"]+offset,ratio-float(event["at"]),38.0)
		var water := ImpactArtLibrary.frame_for_ratio("water_impact",fmod(ratio*1.6,0.999))
		var water_size := Vector2(lerpf(48,82,ratio),lerpf(30,54,ratio))
		surface.draw_texture_rect(water,Rect2((p+Vector2(0,56+18*ratio)-water_size*0.5).round(),water_size),false,Color(0.70,0.84,0.88,0.74*(1.0-ratio)))

func _draw_boss_breakup_burst(surface: CanvasItem, p: Vector2, local_ratio: float, size: float) -> void:
	if local_ratio < 0.0 or local_ratio >= 0.34:
		return
	var burst_ratio := clampf(local_ratio/0.34,0.0,0.999)
	var frame: Texture2D = EXPLOSION_FRAMES[clampi(int(floor(burst_ratio*EXPLOSION_FRAMES.size())),0,EXPLOSION_FRAMES.size()-1)]
	var draw_size := Vector2.ONE*size*lerpf(0.72,1.18,burst_ratio)
	surface.draw_texture_rect(frame,Rect2((p-draw_size*0.5).round(),draw_size),false,Color(1,1,1,1.0-smoothstep(0.72,1.0,burst_ratio)))

func _draw_machine_boss_breakup(surface: CanvasItem, p: Vector2, ratio: float, enemy_id: String, serial: int) -> void:
	var hull: Texture2D = MACHINE_BOSS_WRECK_HULLS[enemy_id]
	var fade := 1.0-smoothstep(0.84,1.0,ratio)
	if enemy_id=="swarm_controller":
		var section_width := hull.get_width()/3.0
		for section in range(3):
			var direction := float(section-1)
			var local_ratio := clampf((ratio-section*0.08)/0.92,0.0,1.0)
			var source_region := Rect2(section_width*section,0,section_width,hull.get_height())
			var section_center := Vector2(-hull.get_width()*0.5+section_width*(section+0.5),0)
			var drift := Vector2(direction*18.0*local_ratio,(8.0+absf(direction)*7.0)*local_ratio*local_ratio)
			surface.draw_set_transform((p+section_center+drift).round(),direction*0.24*local_ratio,Vector2.ONE)
			surface.draw_texture_rect_region(hull,Rect2(-section_width*0.5,-hull.get_height()*0.5,section_width,hull.get_height()),source_region,Color(0.54,0.64,0.65,fade))
			surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
			_draw_boss_breakup_burst(surface,p+section_center,ratio-(0.06+section*0.18),34.0)
		var emp := ImpactArtLibrary.frame_for_ratio("emp_disruption",fmod(ratio*1.45,0.999))
		var emp_size := Vector2.ONE*lerpf(58,108,ratio)
		surface.draw_texture_rect(emp,Rect2((p-emp_size*0.5).round(),emp_size),false,Color(0.56,0.78,0.82,0.55*(1.0-ratio)))
		return
	var central_fall := Vector2(0,12.0*ratio*ratio)
	var tread_width := 21.0
	var central_width := hull.get_width()-tread_width*2.0
	surface.draw_texture_rect_region(hull,Rect2((p+central_fall-Vector2(central_width,hull.get_height())*0.5).round(),Vector2(central_width,hull.get_height())),Rect2(tread_width,0,central_width,hull.get_height()),Color(0.52,0.49,0.42,fade))
	for side in [-1.0,1.0]:
		var source_x := 0.0 if side<0.0 else hull.get_width()-tread_width
		var source_region := Rect2(source_x,0,tread_width,hull.get_height())
		var tread_center := p+Vector2(side*(hull.get_width()*0.5-tread_width*0.5+18.0*ratio),8.0*ratio*ratio)
		surface.draw_set_transform(tread_center.round(),side*0.20*ratio,Vector2.ONE)
		surface.draw_texture_rect_region(hull,Rect2(-tread_width*0.5,-hull.get_height()*0.5,tread_width,hull.get_height()),source_region,Color(0.45,0.44,0.39,fade))
		surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	for event in [{"at":0.04,"point":Vector2(-34,-18)},{"at":0.23,"point":Vector2(0,-8)},{"at":0.42,"point":Vector2(31,-5)},{"at":0.62,"point":Vector2(0,28)}]:
		_draw_boss_breakup_burst(surface,p+event["point"]+central_fall,ratio-float(event["at"]),40.0)
	if ratio>0.34 and ratio<0.88:
		var smoke: Texture2D = PersistentEffectArtLibrary.FRAMES["damage_smoke"][posmod(serial+int(ratio*8.0),4)]
		surface.draw_texture_rect(smoke,Rect2((p+Vector2(2,-20)-Vector2(20,20)).round(),Vector2(40,40)),false,Color(0.48,0.47,0.42,0.68*(1.0-ratio)))

func _draw_orbital_boss_breakup(surface: CanvasItem, p: Vector2, ratio: float, enemy_id: String, serial: int) -> void:
	var hull: Texture2D = ORBITAL_BOSS_WRECK_HULLS[enemy_id]
	var fade := 1.0-smoothstep(0.86,1.0,ratio)
	if enemy_id=="phase_control_array":
		var half := hull.get_size()*0.5
		for row in range(2):
			for column in range(2):
				var index := row*2+column
				var local_ratio := clampf((ratio-index*0.06)/0.94,0.0,1.0)
				var direction := Vector2(-1.0 if column==0 else 1.0,-1.0 if row==0 else 1.0)
				var source_region := Rect2(Vector2(column,row)*half,half)
				var local_center := Vector2((column-0.5)*half.x,(row-0.5)*half.y)
				var drift := direction*local_ratio*18.0
				surface.draw_set_transform((p+local_center+drift).round(),direction.x*direction.y*0.20*local_ratio,Vector2.ONE)
				surface.draw_texture_rect_region(hull,Rect2(-half*0.5,half),source_region,Color(0.55,0.64,0.68,fade))
				surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
				_draw_boss_breakup_burst(surface,p+local_center,ratio-(0.08+index*0.14),36.0)
		var disruption := ImpactArtLibrary.frame_for_ratio("emp_disruption",fmod(ratio*1.55,0.999))
		var field_size := Vector2.ONE*lerpf(72,138,ratio)
		surface.draw_texture_rect(disruption,Rect2((p-field_size*0.5).round(),field_size),false,Color(0.56,0.76,0.80,0.58*(1.0-ratio)))
		return
	var section_count := 4 if enemy_id=="machine_ark" else 3
	var section_width := hull.get_width()/float(section_count)
	for section in range(section_count):
		var normalized := float(section)/maxf(1.0,float(section_count-1))*2.0-1.0
		var local_ratio := clampf((ratio-section*0.055)/0.95,0.0,1.0)
		var source_region := Rect2(section_width*section,0,section_width,hull.get_height())
		var section_center := Vector2(-hull.get_width()*0.5+section_width*(section+0.5),0)
		var vertical_bias := 12.0 if enemy_id=="station_warden" else (6.0+absf(normalized)*8.0)
		var drift := Vector2(normalized*24.0*local_ratio,vertical_bias*local_ratio*local_ratio)
		surface.draw_set_transform((p+section_center+drift).round(),normalized*0.22*local_ratio,Vector2.ONE)
		surface.draw_texture_rect_region(hull,Rect2(-Vector2(section_width,hull.get_height())*0.5,Vector2(section_width,hull.get_height())),source_region,Color(0.50,0.56,0.58,fade))
		surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		_draw_boss_breakup_burst(surface,p+section_center,ratio-(0.06+section*0.15),42.0 if enemy_id=="machine_ark" else 36.0)
	if ratio>0.28 and ratio<0.90:
		var debris: Texture2D = PersistentEffectArtLibrary.FRAMES["debris"][posmod(serial+int(ratio*10.0),4)]
		var debris_size := Vector2.ONE*lerpf(54,96,ratio)
		surface.draw_texture_rect(debris,Rect2((p-debris_size*0.5).round(),debris_size),false,Color(0.58,0.66,0.68,0.62*(1.0-ratio)))

func _draw_player_hit(surface: CanvasItem, p: Vector2, ratio: float, shield: bool) -> void:
	var texture := ImpactArtLibrary.frame_for_ratio("shield_hit" if shield else "armor_hit", ratio)
	var size := Vector2.ONE * 34.0 if shield else Vector2.ONE * 26.0
	surface.draw_texture_rect(texture, Rect2((p - size * 0.5).round(), size), false)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "enemies", "hull", "shield", "player_position"]:
		if not names.has(required):
			return false
	return true
