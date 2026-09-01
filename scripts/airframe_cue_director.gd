extends CanvasLayer
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const AirframeCueSurface = preload("res://scripts/airframe_cue_surface.gd")
const GAMEPLAY_ANCHOR := Vector2(24,29)
const AIRFRAME_ATTACHMENT_ART := {
	"fighter": {
		"armor": preload("res://assets/runtime/craft/vx94/gameplay/airframe/fighter_armor.png"),
		"reactive": preload("res://assets/runtime/craft/vx94/gameplay/airframe/fighter_reactive.png"),
		"magnetic": [preload("res://assets/runtime/craft/vx94/gameplay/airframe/fighter_magnetic_0.png"), preload("res://assets/runtime/craft/vx94/gameplay/airframe/fighter_magnetic_1.png"), preload("res://assets/runtime/craft/vx94/gameplay/airframe/fighter_magnetic_2.png")],
		"field": [preload("res://assets/runtime/craft/vx94/gameplay/airframe/fighter_field_0.png"), preload("res://assets/runtime/craft/vx94/gameplay/airframe/fighter_field_1.png"), preload("res://assets/runtime/craft/vx94/gameplay/airframe/fighter_field_2.png")],
	},
	"bomber": {
		"armor": preload("res://assets/runtime/craft/vx94/gameplay/airframe/bomber_armor.png"),
		"reactive": preload("res://assets/runtime/craft/vx94/gameplay/airframe/bomber_reactive.png"),
		"magnetic": [preload("res://assets/runtime/craft/vx94/gameplay/airframe/bomber_magnetic_0.png"), preload("res://assets/runtime/craft/vx94/gameplay/airframe/bomber_magnetic_1.png"), preload("res://assets/runtime/craft/vx94/gameplay/airframe/bomber_magnetic_2.png")],
		"field": [preload("res://assets/runtime/craft/vx94/gameplay/airframe/bomber_field_0.png"), preload("res://assets/runtime/craft/vx94/gameplay/airframe/bomber_field_1.png"), preload("res://assets/runtime/craft/vx94/gameplay/airframe/bomber_field_2.png")],
	},
}

var _surface: Control

func _ready() -> void:
	layer = 13
	_surface = AirframeCueSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(_delta: float) -> void:
	if _surface != null:
		_surface.queue_redraw()

func _draw_airframe_cues(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	var p: Vector2 = scene.get("player_position")
	var form := _craft_form()
	var art: Dictionary = AIRFRAME_ATTACHMENT_ART.get(form, AIRFRAME_ATTACHMENT_ART["fighter"])
	var origin := (p - GAMEPLAY_ANCHOR).round()
	var frame_index := int(floor((Time.get_ticks_msec() / 1000.0) * 7.0)) % 3
	match _airframe_id():
		"ceramic_titanium_frame":
			_draw_attachment(surface, origin, art["armor"])
		"reactive_alloy_frame":
			_draw_attachment(surface, origin, art["armor"])
			_draw_attachment(surface, origin, art["reactive"])
		"magneto_composite_frame":
			_draw_attachment(surface, origin, art["armor"])
			_draw_attachment(surface, origin, art["reactive"])
			_draw_attachment(surface, origin, art["magnetic"][frame_index])
		"field_coupled_frame":
			_draw_attachment(surface, origin, art["armor"])
			_draw_attachment(surface, origin, art["reactive"])
			_draw_attachment(surface, origin, art["magnetic"][frame_index])
			_draw_attachment(surface, origin, art["field"][frame_index])

func _draw_attachment(surface: CanvasItem, origin: Vector2, texture: Texture2D) -> void:
	surface.draw_texture(texture, origin)

func _airframe_id() -> String:
	var director := get_node_or_null("/root/AirframeDirector")
	if director != null and director.has_method("current_airframe"):
		var frame = director.call("current_airframe")
		if typeof(frame) == TYPE_DICTIONARY:
			return str(frame.get("id", "composite_frame_mk1"))
	return "composite_frame_mk1"

func _craft_form() -> String:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method("current_form"):
		return str(director.call("current_form"))
	return "fighter"

func _supports(scene: Object) -> bool:
	return SceneContractCache.supports(scene, ["phase", "player_position"])
