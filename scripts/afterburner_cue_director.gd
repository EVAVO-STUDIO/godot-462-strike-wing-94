extends CanvasLayer

const PixelFont = preload("res://scripts/pixel_font.gd")
const AfterburnerCueSurface = preload("res://scripts/afterburner_cue_surface.gd")
const PersistentEffectArtLibrary = preload("res://scripts/persistent_effect_art_library.gd")
const PROPULSION_NORMAL := preload("res://assets/runtime/ui/hud/propulsion_instrument/normal.png")
const PROPULSION_BURNING := preload("res://assets/runtime/ui/hud/propulsion_instrument/burning.png")
const PROPULSION_RESERVE_LOW := preload("res://assets/runtime/ui/hud/propulsion_instrument/reserve_low.png")
const PROPULSION_HYPERSONIC := preload("res://assets/runtime/ui/hud/propulsion_instrument/hypersonic_latched.png")
const PROPULSION_FUEL_FILL := preload("res://assets/runtime/ui/hud/propulsion_instrument/fuel_fill.png")
const PROPULSION_CHARGE_FILL := preload("res://assets/runtime/ui/hud/propulsion_instrument/charge_fill.png")

const PANEL := Color("070a0e")
const BORDER := Color("34414b")
const TEXT := Color("d9e0e5")
const FUEL := Color("e8ca6a")
const HOT := Color("e8894f")
const CORE := Color("d9e9ff")
const ALERT := Color("ff6757")
const CHARGE := Color("86bed2")

var _surface: Control
var _boom_age := 99.0
var _last_hypersonic := false

func _ready() -> void:
	layer = 14
	_surface = AfterburnerCueSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	_boom_age += maxf(0.0, delta)
	var craft := get_node_or_null("/root/CraftFormDirector")
	var active := craft != null and craft.has_method("hypersonic_active") and bool(craft.call("hypersonic_active"))
	if active and not _last_hypersonic:
		_boom_age = 0.0
	_last_hypersonic = active
	if _surface != null:
		_surface.queue_redraw()

func draw_afterburner(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	var craft := get_node_or_null("/root/CraftFormDirector")
	if scene == null or craft == null or not _has_property(scene, "phase") or int(scene.get("phase")) != 1:
		return
	if not craft.has_method("afterburner_ratio"):
		return
	var ratio := clampf(float(craft.call("afterburner_ratio")), 0.0, 1.0)
	var charge_ratio := clampf(float(craft.call("hypersonic_charge_ratio")),0.0,1.0) if craft.has_method("hypersonic_charge_ratio") else 0.0
	var burning := craft.has_method("afterburner_active") and bool(craft.call("afterburner_active"))
	var hypersonic := craft.has_method("hypersonic_active") and bool(craft.call("hypersonic_active"))
	_draw_meter(surface, ratio, charge_ratio, burning, hypersonic)
	if burning and _has_property(scene, "player_position"):
		_draw_flame(surface, scene.get("player_position"), str(craft.call("current_form")) if craft.has_method("current_form") else "fighter", hypersonic)
	if _boom_age < 0.42 and _has_property(scene, "player_position"):
		var t := _boom_age / 0.42
		var texture := PersistentEffectArtLibrary.frame_for_ratio("sonic_boom", t)
		var draw_size := roundf(lerpf(64.0, 236.0, t))
		var p: Vector2 = scene.get("player_position")
		surface.draw_texture_rect(texture, Rect2((p - Vector2.ONE * draw_size * 0.5).round(), Vector2.ONE * draw_size), false, Color(1,1,1,1.0-t))
		if _boom_age < 0.12:
			var flash_ratio := 1.0 - _boom_age / 0.12
			surface.draw_circle((p + Vector2(0,15)).round(), lerpf(4.0,22.0,flash_ratio), Color(0.86,0.94,1.0,flash_ratio*0.88))

func _draw_meter(surface: CanvasItem, ratio: float, charge_ratio: float, burning: bool, hypersonic: bool) -> void:
	var frame: Texture2D = PROPULSION_HYPERSONIC if hypersonic else (PROPULSION_RESERVE_LOW if ratio <= 0.20 else (PROPULSION_BURNING if burning else PROPULSION_NORMAL))
	var position := Vector2(14,315)
	surface.draw_texture(frame, position)
	PixelFont.draw_text(surface, "AB", position + Vector2(7,3), 1, ALERT if ratio <= 0.20 else FUEL, 1)
	PixelFont.draw_text(surface, "MACH" if hypersonic else "GEOM", position + Vector2(91,3), 1, CORE if hypersonic else CHARGE, 1)
	var exposure := clampi(int(roundf(charge_ratio * 9.0)) + 1, 1, 10) if charge_ratio > 0.0 else 0
	PixelFont.draw_text(surface, "%02d" % exposure if exposure > 0 else "--", position + Vector2(115,3), 1, CORE if hypersonic else CHARGE, 1)
	_draw_fill(surface, PROPULSION_FUEL_FILL, position + Vector2(25,5), ratio)
	var stepped_charge := float(floori(charge_ratio * 10.0)) / 10.0
	_draw_fill(surface, PROPULSION_CHARGE_FILL, position + Vector2(141,5), stepped_charge)

func _draw_fill(surface: CanvasItem, texture: Texture2D, position: Vector2, ratio: float) -> void:
	var width := floorf(float(texture.get_width()) * clampf(ratio,0.0,1.0))
	if width > 0.0:
		surface.draw_texture_rect_region(texture,Rect2(position,Vector2(width,texture.get_height())),Rect2(0,0,width,texture.get_height()))

func _draw_flame(surface: CanvasItem, p: Vector2, form: String, hypersonic: bool) -> void:
	var offset := Vector2(-16, 14 if form == "fighter" else 15)
	if hypersonic:
		var contrail := PersistentEffectArtLibrary.frame_for_clock("contrail", 7.0)
		surface.draw_texture(contrail, (p + offset + Vector2(0,12)).round(), Color(0.84,0.92,0.95,0.82))
	var plume := PersistentEffectArtLibrary.frame_for_clock("afterburner", 12.0)
	surface.draw_texture(plume, (p + offset).round())

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false
