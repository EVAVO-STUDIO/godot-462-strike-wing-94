extends CanvasLayer

const CombatArtSurface = preload("res://scripts/combat_art_surface.gd")
const AltitudeRules = preload("res://scripts/altitude_rules.gd")
const MERCENARY_AIR_SPRITES := {
	"scout_falcon": preload("res://assets/runtime/enemies/mercenary_air/scout_falcon_idle.png"),
	"gunship_mk1": preload("res://assets/runtime/enemies/mercenary_air/gunship_mk1_idle.png"),
	"attack_chopper": preload("res://assets/runtime/enemies/mercenary_air/attack_chopper_idle.png"),
	"ace_interceptor": preload("res://assets/runtime/enemies/mercenary_air/ace_interceptor_idle.png"),
	"heavy_bomber": preload("res://assets/runtime/enemies/mercenary_air/heavy_bomber_idle.png"),
}
const MERCENARY_GROUND_SPRITES := {
	"light_tank": preload("res://assets/runtime/enemies/mercenary_ground/light_tank_idle.png"),
	"sam_truck": preload("res://assets/runtime/enemies/mercenary_ground/sam_truck_idle.png"),
	"fortified_turret": preload("res://assets/runtime/enemies/mercenary_ground/fortified_turret_idle.png"),
	"coastal_flak": preload("res://assets/runtime/enemies/mercenary_ground/coastal_flak_idle.png"),
	"armoured_aa_carrier": preload("res://assets/runtime/enemies/mercenary_ground/armoured_aa_carrier_idle.png"),
}
const MERCENARY_SEA_SPRITES := {
	"river_patrol": preload("res://assets/runtime/enemies/mercenary_sea/river_patrol_idle.png"),
	"torpedo_boat": preload("res://assets/runtime/enemies/mercenary_sea/torpedo_boat_idle.png"),
	"fast_attack_craft": preload("res://assets/runtime/enemies/mercenary_sea/fast_attack_craft_idle.png"),
	"missile_corvette": preload("res://assets/runtime/enemies/mercenary_sea/missile_corvette_idle.png"),
}
const MACHINE_AIR_SPRITES := {
	"drone_scout": preload("res://assets/runtime/enemies/machine_air/drone_scout_idle.png"),
	"drone_hunter": preload("res://assets/runtime/enemies/machine_air/drone_hunter_idle.png"),
	"drone_bomber": preload("res://assets/runtime/enemies/machine_air/drone_bomber_idle.png"),
	"drone_missile_node": preload("res://assets/runtime/enemies/machine_air/drone_missile_node_idle.png"),
}
const MACHINE_GROUND_SPRITES := {
	"autonomous_armor": preload("res://assets/runtime/enemies/machine_ground/autonomous_armor_idle.png"),
	"factory_defence_node": preload("res://assets/runtime/enemies/machine_ground/factory_defence_node_idle.png"),
}
const ORBITAL_AIR_SPRITES := {
	"exo_drone": preload("res://assets/runtime/enemies/orbital_air/exo_drone_idle.png"),
	"orbital_sentry": preload("res://assets/runtime/enemies/orbital_air/orbital_sentry_idle.png"),
	"phase_interceptor": preload("res://assets/runtime/enemies/orbital_air/phase_interceptor_idle.png"),
	"beam_sentry": preload("res://assets/runtime/enemies/orbital_air/beam_sentry_idle.png"),
	"orbital_lancer": preload("res://assets/runtime/enemies/orbital_air/orbital_lancer_idle.png"),
}
const MERCENARY_BOSS_SPRITES := {
	"gunship_alpha": preload("res://assets/runtime/enemies/mercenary_boss/gunship_alpha_idle.png"),
	"armoured_train": preload("res://assets/runtime/enemies/mercenary_boss/armoured_train_idle.png"),
	"missile_cruiser": preload("res://assets/runtime/enemies/mercenary_boss/missile_cruiser_idle.png"),
}
const MACHINE_BOSS_SPRITES := {
	"swarm_controller": preload("res://assets/runtime/enemies/machine_boss/swarm_controller_idle.png"),
	"ai_forge_core": preload("res://assets/runtime/enemies/machine_boss/ai_forge_core_idle.png"),
}
const ORBITAL_BOSS_SPRITES := {
	"orbital_command_node": preload("res://assets/runtime/enemies/orbital_boss/orbital_command_node_idle.png"),
	"phase_control_array": preload("res://assets/runtime/enemies/orbital_boss/phase_control_array_idle.png"),
}

const PLAYER := Color("d9e0e5")
const PLAYER_DARK := Color("667985")
const PLAYER_GLASS := Color("6aa4c8")
const PLAYER_ENGINE := Color("e8ca6a")
const PLAYER_GUN := Color("3d4a52")
const PLAYER_MUZZLE := Color("e7c46a")
const MERC_AIR := Color("9f5049")
const MERC_DARK := Color("4d3e3a")
const SURFACE := Color("766b55")
const SURFACE_DARK := Color("3d3a31")
const AI := Color("b7c7ca")
const AI_DARK := Color("45545a")
const AI_CORE := Color("67c3a5")
const BOSS := Color("c86054")
const BOSS_DARK := Color("55322f")
const TRANSFORM_VISUAL_SECONDS := 0.42

var _surface: Control
var _visual_sweep := 0.0

func _ready() -> void:
	layer = 12
	_surface = CombatArtSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	var target := 1.0 if _craft_form() == "bomber" else 0.0
	_visual_sweep = move_toward(_visual_sweep, target, maxf(0.0, delta) / TRANSFORM_VISUAL_SECONDS)
	if _surface != null:
		_surface.queue_redraw()

func _draw_combat_art(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	for enemy in scene.get("enemies"):
		if typeof(enemy) == TYPE_DICTIONARY:
			_draw_enemy(surface, enemy)
	_draw_player(surface, scene.get("player_position"))

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("player_position") and names.has("enemies")

func _draw_player(surface: CanvasItem, position: Vector2) -> void:
	var p := position + _altitude_pitch_offset()
	if _visual_sweep <= 0.02:
		_draw_fighter(surface, p)
	elif _visual_sweep >= 0.98:
		_draw_bomber(surface, p)
	else:
		_draw_transforming(surface, p, _visual_sweep)

func _draw_transforming(surface: CanvasItem, p: Vector2, sweep: float) -> void:
	var t := smoothstep(0.0, 1.0, clampf(sweep, 0.0, 1.0))
	var hinge_l := p + Vector2(-7, 3)
	var hinge_r := p + Vector2(7, 3)
	var fighter_tip_l := p + Vector2(-18, 11)
	var fighter_tip_r := p + Vector2(18, 11)
	var bomber_tip_l := p + Vector2(-31, 5)
	var bomber_tip_r := p + Vector2(31, 5)
	var tip_l := fighter_tip_l.lerp(bomber_tip_l, t)
	var tip_r := fighter_tip_r.lerp(bomber_tip_r, t)
	var trailing_l := p + Vector2(-lerpf(8.0, 25.0, t), lerpf(9.0, 13.0, t))
	var trailing_r := p + Vector2(lerpf(8.0, 25.0, t), lerpf(9.0, 13.0, t))
	surface.draw_colored_polygon(PackedVector2Array([
		p+Vector2(0,-21), p+Vector2(-5,-8), hinge_l, tip_l, trailing_l,
		p+Vector2(-7,17), p+Vector2(0,12), p+Vector2(7,17), trailing_r, tip_r, hinge_r, p+Vector2(5,-8)
	]), PLAYER)
	surface.draw_colored_polygon(PackedVector2Array([
		p+Vector2(0,lerpf(-15.0,-14.0,t)), p+Vector2(-4,-4), p+Vector2(0,5), p+Vector2(4,-4)
	]), PLAYER_GLASS)
	# Visible variable-geometry hinge plates.
	for hinge in [hinge_l, hinge_r]:
		surface.draw_rect(Rect2(roundf(hinge.x)-2, roundf(hinge.y)-2, 4, 4), PLAYER_DARK)
	var engine_span := roundf(lerpf(6.0, 12.0, t))
	surface.draw_rect(Rect2(p.x-engine_span-2, p.y+12, 4, 4), PLAYER_ENGINE)
	surface.draw_rect(Rect2(p.x+engine_span-2, p.y+12, 4, 4), PLAYER_ENGINE)
	# Fighter wing-root cannons slide inward/retract as bomber geometry deploys.
	var wing_gun_alpha := clampf(1.0 - t * 1.35, 0.0, 1.0)
	if wing_gun_alpha > 0.02:
		var gun_color := Color(PLAYER_GUN, wing_gun_alpha)
		var lx := lerpf(-13.0, -7.0, t)
		var rx := -lx
		surface.draw_rect(Rect2(p.x+lx-2,p.y-9,4,8),gun_color)
		surface.draw_rect(Rect2(p.x+rx-2,p.y-9,4,8),gun_color)
	# Bomber rotary cannon extends from the forward fuselage as the wings open.
	var deploy := smoothstep(0.18, 0.92, t)
	_draw_rotary_cannon(surface, p, deploy)

func _draw_fighter(surface: CanvasItem, p: Vector2) -> void:
	surface.draw_colored_polygon(PackedVector2Array([
		p + Vector2(0,-21), p + Vector2(-5,-7), p + Vector2(-18,11),
		p + Vector2(-8,8), p + Vector2(-5,16), p + Vector2(0,11),
		p + Vector2(5,16), p + Vector2(8,8), p + Vector2(18,11), p + Vector2(5,-7)
	]), PLAYER)
	surface.draw_colored_polygon(PackedVector2Array([
		p + Vector2(0,-15), p + Vector2(-4,-4), p + Vector2(0,5), p + Vector2(4,-4)
	]), PLAYER_GLASS)
	surface.draw_rect(Rect2(p.x-2, p.y+6, 4, 8), PLAYER_DARK)
	surface.draw_rect(Rect2(p.x-8, p.y+13, 4, 3), PLAYER_ENGINE)
	surface.draw_rect(Rect2(p.x+4, p.y+13, 4, 3), PLAYER_ENGINE)
	# Swept-wing hinge and two dedicated wing-root cannon packs.
	for side in [-1.0, 1.0]:
		var hinge := p + Vector2(7.0*side,3)
		surface.draw_line(hinge, p + Vector2(18.0*side,11), PLAYER_DARK, 2)
		surface.draw_rect(Rect2(p.x+11.0*side-2,p.y-10,4,8),PLAYER_GUN)
		surface.draw_line(Vector2(p.x+11.0*side,p.y-10),Vector2(p.x+11.0*side,p.y-15),PLAYER_GUN,2)
	# Folded rotary housing remains visible but flush with the nose.
	surface.draw_rect(Rect2(p.x-3,p.y-20,6,3),PLAYER_DARK)

func _draw_bomber(surface: CanvasItem, p: Vector2) -> void:
	# Broad attack configuration: straight-ish deployed wings and heavier nacelle posture.
	surface.draw_colored_polygon(PackedVector2Array([
		p + Vector2(0,-20), p + Vector2(-6,-8), p + Vector2(-31,4),
		p + Vector2(-30,10), p + Vector2(-12,10), p + Vector2(-8,18),
		p + Vector2(0,13), p + Vector2(8,18), p + Vector2(12,10),
		p + Vector2(30,10), p + Vector2(31,4), p + Vector2(6,-8)
	]), PLAYER)
	surface.draw_rect(Rect2(p.x-23, p.y+6, 46, 4), PLAYER_DARK)
	surface.draw_colored_polygon(PackedVector2Array([
		p + Vector2(0,-14), p + Vector2(-5,-3), p + Vector2(0,5), p + Vector2(5,-3)
	]), PLAYER_GLASS)
	# Twin engine nacelles / reinforced attack-frame shoulders.
	for x in [-12, 8]:
		surface.draw_rect(Rect2(p.x+x,p.y+9,5,8),PLAYER_DARK)
		surface.draw_rect(Rect2(p.x+x,p.y+15,5,3),PLAYER_ENGINE)
	# Under-wing hardpoints make bombs/rockets/missiles physically believable.
	for x in [-24,-16,13,21]:
		surface.draw_rect(Rect2(p.x+x,p.y+10,3,5),PLAYER_DARK)
	_draw_rotary_cannon(surface, p, 1.0)

func _draw_rotary_cannon(surface: CanvasItem, p: Vector2, deploy: float) -> void:
	var t := clampf(deploy,0.0,1.0)
	if t <= 0.01:
		return
	var housing_top := lerpf(-19.0,-24.0,t)
	var barrel_tip := lerpf(-21.0,-33.0,t)
	surface.draw_rect(Rect2(p.x-4,p.y+housing_top,8,maxf(3.0,7.0*t)),PLAYER_GUN)
	for x in [-2.0,0.0,2.0]:
		surface.draw_line(Vector2(p.x+x,p.y+housing_top-1),Vector2(p.x+x,p.y+barrel_tip),PLAYER_GUN,1.0)
	if t > 0.82:
		surface.draw_rect(Rect2(p.x-3,p.y+barrel_tip-2,6,2),PLAYER_MUZZLE)

func _draw_enemy(surface: CanvasItem, enemy: Dictionary) -> void:
	var p: Vector2 = enemy.get("position", Vector2.ZERO)
	var enemy_id := str(enemy.get("id", ""))
	var is_boss := bool(enemy.get("boss", false))
	var faction := str(enemy.get("faction", "mercenary"))
	var category := str(enemy.get("category", "air"))
	var scale := _surface_target_scale() if category in ["ground", "sea"] else 1.0
	if category in ["ground", "sea"] and scale < 0.25 and not is_boss:
		return
	if is_boss:
		if MERCENARY_BOSS_SPRITES.has(enemy_id):
			_draw_production_sprite(surface, p, MERCENARY_BOSS_SPRITES[enemy_id])
		elif MACHINE_BOSS_SPRITES.has(enemy_id):
			_draw_production_sprite(surface, p, MACHINE_BOSS_SPRITES[enemy_id])
		elif ORBITAL_BOSS_SPRITES.has(enemy_id):
			_draw_production_sprite(surface, p, ORBITAL_BOSS_SPRITES[enemy_id])
		else:
			_draw_boss(surface, p, enemy_id, faction)
	elif faction == "autonomous" and category == "ground" and MACHINE_GROUND_SPRITES.has(enemy_id):
		_draw_production_sprite(surface, p, MACHINE_GROUND_SPRITES[enemy_id], scale)
	elif faction == "autonomous" and ORBITAL_AIR_SPRITES.has(enemy_id):
		_draw_production_sprite(surface, p, ORBITAL_AIR_SPRITES[enemy_id])
	elif faction == "autonomous" and MACHINE_AIR_SPRITES.has(enemy_id):
		_draw_production_sprite(surface, p, MACHINE_AIR_SPRITES[enemy_id])
	elif faction == "autonomous":
		_draw_autonomous(surface, p, enemy_id, category, scale)
	elif category == "ground" and MERCENARY_GROUND_SPRITES.has(enemy_id):
		_draw_production_sprite(surface, p, MERCENARY_GROUND_SPRITES[enemy_id], scale)
	elif category == "ground":
		_draw_ground(surface, p, scale)
	elif category == "sea" and MERCENARY_SEA_SPRITES.has(enemy_id):
		_draw_production_sprite(surface, p, MERCENARY_SEA_SPRITES[enemy_id], scale)
	elif category == "sea":
		_draw_sea(surface, p, scale)
	elif MERCENARY_AIR_SPRITES.has(enemy_id):
		_draw_production_sprite(surface, p, MERCENARY_AIR_SPRITES[enemy_id])
	else:
		_draw_air(surface, p)

func _draw_production_sprite(surface: CanvasItem, p: Vector2, texture: Texture2D, scale: float = 1.0) -> void:
	var size := texture.get_size() * scale
	var destination := Rect2((p - size * 0.5).round(), size.round())
	surface.draw_texture_rect(texture, destination, false)

func _draw_air(surface: CanvasItem, p: Vector2) -> void:
	surface.draw_colored_polygon(PackedVector2Array([
		p+Vector2(0,12), p+Vector2(-15,-7), p+Vector2(-5,-4),
		p+Vector2(0,-10), p+Vector2(5,-4), p+Vector2(15,-7)
	]), MERC_AIR)
	surface.draw_rect(Rect2(p.x-3,p.y-7,6,15), MERC_DARK)
	surface.draw_rect(Rect2(p.x-8,p.y-6,3,3), Color("d3a56c"))
	surface.draw_rect(Rect2(p.x+5,p.y-6,3,3), Color("d3a56c"))

func _scaled(v: Vector2, scale: float) -> Vector2:
	return Vector2(roundf(v.x * scale), roundf(v.y * scale))

func _draw_ground(surface: CanvasItem, p: Vector2, scale: float) -> void:
	var s := clampf(scale, 0.45, 1.0)
	var w := roundf(26.0 * s)
	var h := roundf(14.0 * s)
	surface.draw_rect(Rect2(p.x-w*0.5,p.y-h*0.5,w,h), SURFACE)
	var turret_w := roundf(18.0 * s)
	surface.draw_rect(Rect2(p.x-turret_w*0.5,p.y-roundf(11.0*s),turret_w,maxf(3.0,roundf(7.0*s))), SURFACE_DARK)
	surface.draw_line(p+_scaled(Vector2(1,-12),s), p+_scaled(Vector2(11,-17),s), SURFACE_DARK, maxf(1.0,roundf(2.0*s)))
	var track_y := p.y + roundf(6.0*s)
	surface.draw_line(Vector2(p.x-w*0.4,track_y), Vector2(p.x+w*0.4,track_y), Color("252722"), maxf(1.0,roundf(2.0*s)))

func _draw_sea(surface: CanvasItem, p: Vector2, scale: float) -> void:
	var s := clampf(scale, 0.45, 1.0)
	surface.draw_colored_polygon(PackedVector2Array([
		p+_scaled(Vector2(0,-16),s), p+_scaled(Vector2(-12,9),s), p+_scaled(Vector2(-8,14),s),
		p+_scaled(Vector2(8,14),s), p+_scaled(Vector2(12,9),s)
	]), SURFACE)
	var cabin_w := maxf(4.0,roundf(10.0*s))
	var cabin_h := maxf(5.0,roundf(12.0*s))
	surface.draw_rect(Rect2(p.x-cabin_w*0.5,p.y-roundf(6.0*s),cabin_w,cabin_h), SURFACE_DARK)

func _draw_autonomous(surface: CanvasItem, p: Vector2, id: String, category: String, scale: float = 1.0) -> void:
	if category == "ground":
		var s := clampf(scale, 0.45, 1.0)
		var w := roundf(24.0*s)
		var h := roundf(18.0*s)
		surface.draw_rect(Rect2(p.x-w*0.5,p.y-h*0.5,w,h), AI_DARK)
		surface.draw_rect(Rect2(p.x-roundf(8.0*s),p.y-roundf(13.0*s),roundf(16.0*s),maxf(4.0,roundf(8.0*s))), AI)
		var core := maxf(3.0,roundf(6.0*s))
		surface.draw_rect(Rect2(p.x-core*0.5,p.y-core*0.5,core,core), AI_CORE)
		return
	var wide := 18.0 if id in ["drone_bomber","orbital_sentry","beam_sentry"] else 13.0
	surface.draw_colored_polygon(PackedVector2Array([
		p+Vector2(0,13), p+Vector2(-wide,-4), p+Vector2(-6,-10),
		p+Vector2(0,-6), p+Vector2(6,-10), p+Vector2(wide,-4)
	]), AI)
	surface.draw_rect(Rect2(p.x-3,p.y-4,6,7), AI_CORE)
	surface.draw_line(p+Vector2(-wide+3,-3), p+Vector2(-5,5), AI_DARK, 2)
	surface.draw_line(p+Vector2(wide-3,-3), p+Vector2(5,5), AI_DARK, 2)

func _draw_boss(surface: CanvasItem, p: Vector2, id: String, faction: String) -> void:
	if id == "phase_control_array":
		_draw_phase_array(surface, p)
		return
	if id == "station_warden":
		_draw_station_warden(surface, p)
		return
	if id == "machine_ark":
		_draw_machine_ark(surface, p)
		return
	var body := AI if faction == "autonomous" else BOSS
	var dark := AI_DARK if faction == "autonomous" else BOSS_DARK
	var half_width := 34.0
	if id in ["missile_cruiser","orbital_command_node"]:
		half_width = 43.0
	elif id in ["armoured_train","ai_forge_core"]:
		half_width = 38.0
	surface.draw_colored_polygon(PackedVector2Array([
		p+Vector2(0,24), p+Vector2(-half_width,0), p+Vector2(-25,-15),
		p+Vector2(0,-20), p+Vector2(25,-15), p+Vector2(half_width,0)
	]), body)
	surface.draw_rect(Rect2(p.x-15,p.y-9,30,19), dark)
	surface.draw_rect(Rect2(p.x-5,p.y-14,10,10), AI_CORE if faction == "autonomous" else Color("e1b16d"))
	for x in [-25,20]:
		surface.draw_rect(Rect2(p.x+x,p.y+5,6,4), dark)

func _draw_phase_array(surface: CanvasItem, p: Vector2) -> void:
	surface.draw_arc(p, 32.0, 0.0, TAU, 20, AI, 5.0)
	surface.draw_arc(p, 22.0, 0.0, TAU, 16, AI_DARK, 3.0)
	surface.draw_rect(Rect2(p.x-7,p.y-7,14,14), AI_CORE)
	for axis in [Vector2(0,-40), Vector2(40,0), Vector2(0,40), Vector2(-40,0)]:
		surface.draw_line(p + axis.normalized()*20.0, p + axis, AI, 4.0)
		surface.draw_rect(Rect2((p+axis).x-4,(p+axis).y-4,8,8), AI_DARK)

func _draw_station_warden(surface: CanvasItem, p: Vector2) -> void:
	surface.draw_rect(Rect2(p.x-15,p.y-38,30,76), AI_DARK)
	surface.draw_rect(Rect2(p.x-50,p.y-11,100,22), AI)
	surface.draw_rect(Rect2(p.x-27,p.y-19,54,38), AI_DARK)
	surface.draw_rect(Rect2(p.x-8,p.y-8,16,16), AI_CORE)
	for x in [-44,-32,26,38]:
		surface.draw_rect(Rect2(p.x+x,p.y-5,7,10), AI_CORE)

func _draw_machine_ark(surface: CanvasItem, p: Vector2) -> void:
	surface.draw_colored_polygon(PackedVector2Array([
		p+Vector2(0,-32), p+Vector2(-34,-22), p+Vector2(-62,-4), p+Vector2(-54,22),
		p+Vector2(-18,30), p+Vector2(8,24), p+Vector2(58,18), p+Vector2(68,-2),
		p+Vector2(44,-22), p+Vector2(18,-28)
	]), AI)
	surface.draw_rect(Rect2(p.x-34,p.y-13,72,28), AI_DARK)
	surface.draw_rect(Rect2(p.x-9,p.y-18,18,18), AI_CORE)
	surface.draw_rect(Rect2(p.x-42,p.y+1,10,10), AI_CORE)
	surface.draw_rect(Rect2(p.x+31,p.y+2,10,10), AI_CORE)
	for x in [-50,-32,22,42]:
		surface.draw_rect(Rect2(p.x+x,p.y+18,8,4), Color("6aa4c8"))

func _surface_target_scale() -> float:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null:
		if director.has_method("altitude_transition_active") and bool(director.call("altitude_transition_active")):
			return AltitudeRules.transition_ground_scale(str(director.call("altitude_transition_from")), str(director.call("altitude_transition_to")), float(director.call("altitude_transition_ratio")))
		if director.has_method("current_altitude"):
			return AltitudeRules.ground_scale(str(director.call("current_altitude")))
	return AltitudeRules.ground_scale(AltitudeRules.MID)

func _altitude_pitch_offset() -> Vector2:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director == null or not director.has_method("altitude_transition_active") or not bool(director.call("altitude_transition_active")):
		return Vector2.ZERO
	var ratio := float(director.call("altitude_transition_ratio"))
	var direction := int(director.call("altitude_transition_direction"))
	return Vector2(0, -roundf(sin(ratio * PI) * 4.0 * float(direction)))

func _craft_form() -> String:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method("current_form"):
		return str(director.call("current_form"))
	return "fighter"
