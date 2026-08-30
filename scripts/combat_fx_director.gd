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
			if kind != "boss_explosion" and str(previous.get("category", "air")) == "sea":
				duration = NAVAL_SINK_SECONDS
			var size := 28.0 if kind == "boss_explosion" else 15.0
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
		visual_ratio = clampf(ratio * (BOSS_DESTRUCTION_SECONDS / BOSS_EXPLOSION_SECONDS),0.0,0.999)
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
	if category == "sea" and NAVAL_WRECK_HULLS.has(enemy_id):
		_draw_naval_sinking(surface, p, late_ratio, enemy_id, serial)
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
