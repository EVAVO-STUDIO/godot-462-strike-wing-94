extends CanvasLayer

const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const PlayerMountRules = preload("res://scripts/player_mount_rules.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const LoadoutSchematicSurface = preload("res://scripts/loadout_schematic_surface.gd")
const UiSpriteRenderer = preload("res://scripts/ui_sprite_renderer.gd")
const OPERATIONS_PANEL := preload("res://assets/runtime/ui/menu/operations_panel_9slice.png")
const OPERATIONS_SCREEN := preload("res://assets/runtime/ui/menu/operations_screen_9slice.png")
const MOUNT_SOCKET := preload("res://assets/runtime/ui/menu/loadout_schematic/mount_socket.png")
const MOUNT_SOCKET_ACTIVE := preload("res://assets/runtime/ui/menu/loadout_schematic/mount_socket_active.png")
const HARNESS := preload("res://assets/runtime/ui/menu/loadout_schematic/harness.png")
const HARNESS_ACTIVE := preload("res://assets/runtime/ui/menu/loadout_schematic/harness_active.png")
const VX94_PLANFORMS := {
	"fighter": preload("res://assets/runtime/craft/vx94/vx94_fighter_v1.png"),
	"bomber": preload("res://assets/runtime/craft/vx94/vx94_bomber_v1.png"),
}

const BG := Color("070a0e")
const PANEL := Color("10171d")
const BORDER := Color("40515d")
const TEXT := Color("d9e0e5")
const MUTED := Color("778a96")
const BLUE := Color("6aa4c8")
const GOLD := Color("e8ca6a")
const MOUNT := Color("72c7b2")
const ACTIVE_MOUNT := Color("f0d87a")

var _surface: Control
var _open := false
var _mounts: Array = []

func _ready() -> void:
	layer = 32
	var data = ContentCatalog.load_json("res://data/player_mounts.json")
	if typeof(data) == TYPE_DICTIONARY:
		_mounts = data.get("mounts", [])
	_surface = LoadoutSchematicSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)
	_ensure_action()

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != null and _sortie_front_end(scene):
		if Input.is_action_just_pressed("toggle_loadout_schematic"):
			_open = not _open
	else:
		_open = false
	if _surface != null:
		_surface.queue_redraw()

func draw_schematic(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _sortie_front_end(scene):
		return
	if not _open:
		UiSpriteRenderer.draw_nine_slice(surface, OPERATIONS_PANEL, Rect2(462, 334, 78, 15), 5)
		PixelFont.draw_centered(surface, "L STORES", 501, 339, 1, MUTED, 1)
		return

	UiSpriteRenderer.draw_nine_slice(surface, OPERATIONS_SCREEN, Rect2(38, 54, 564, 266), 8)
	PixelFont.draw_centered(surface, "VX-94 STORES / VARIABLE GEOMETRY", 320, 68, 2, GOLD, 1)
	_draw_planform(surface, Vector2(176, 176), "fighter")
	_draw_planform(surface, Vector2(464, 176), "bomber")
	PixelFont.draw_centered(surface, "FIGHTER", 176, 100, 1, BLUE, 1)
	PixelFont.draw_centered(surface, "BOMBER / ATTACK", 464, 100, 1, BLUE, 1)
	_draw_mounts(surface, Vector2(176, 176), "fighter")
	_draw_mounts(surface, Vector2(464, 176), "bomber")
	_draw_installed(surface)
	PixelFont.draw_centered(surface, "GOLD = INSTALLED / ACTIVE STATION", 320, 293, 1, GOLD, 1)
	PixelFont.draw_centered(surface, "L CLOSE   Q CHANGES COMBAT GEOMETRY IN SORTIE", 320, 306, 1, MUTED, 1)

func _draw_planform(surface: CanvasItem, p: Vector2, form: String) -> void:
	var texture: Texture2D = VX94_PLANFORMS.get(form)
	if texture == null:
		return
	var size := texture.get_size() * 2.25
	surface.draw_texture_rect(texture, Rect2((p - size * 0.5).round(), size.round()), false, Color(0.78,0.86,0.88,0.82))

func _draw_mounts(surface: CanvasItem, p: Vector2, form: String) -> void:
	var shown := 0
	for mount in _mounts:
		if typeof(mount) != TYPE_DICTIONARY:
			continue
		var forms: Array = mount.get("forms", [])
		if form not in forms:
			continue
		var key := "%s_offset" % form
		var raw = mount.get(key, [0,0])
		if typeof(raw) != TYPE_ARRAY or raw.size() < 2:
			continue
		var local := Vector2(float(raw[0]) * 2.25, float(raw[1]) * 2.25)
		var point := p + local
		var active := _mount_active(mount, form)
		if shown < 7:
			var name := str(mount.get("name", mount.get("id", "MOUNT"))).to_upper()
			var side := -1.0 if point.x < p.x else 1.0
			if absf(point.x-p.x) < 6.0:
				side = 1.0
			var label_x := p.x - 128.0 if side < 0 else p.x + 72.0
			var label_y := p.y - 62.0 + shown * 15.0
			var label_color := ACTIVE_MOUNT if active else MUTED
			var endpoint := Vector2(label_x + (58 if side < 0 else 0),label_y+3)
			_draw_harness(surface, HARNESS_ACTIVE if active else HARNESS, point, endpoint, 4.0, 0.72 if active else 0.48)
			PixelFont.draw_text(surface,_clip(name,18),Vector2(label_x,label_y),1,label_color,1)
			shown += 1
		var socket: Texture2D = MOUNT_SOCKET_ACTIVE if active else MOUNT_SOCKET
		surface.draw_texture(socket, (point - socket.get_size() * 0.5).round())

func _draw_harness(surface: CanvasItem, texture: Texture2D, start: Vector2, finish: Vector2, height: float, alpha: float) -> void:
	var delta := finish - start
	if delta.length() < 1.0:
		return
	surface.draw_set_transform(start, delta.angle(), Vector2(delta.length() / texture.get_width(), height / texture.get_height()))
	surface.draw_texture(texture, Vector2(0,-texture.get_height()*0.5), Color(1,1,1,alpha))
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _mount_active(mount: Dictionary, form: String) -> bool:
	var roles = mount.get("roles", [])
	if typeof(roles) != TYPE_ARRAY:
		return false
	var primary := _active_weapon()
	var primary_role := PlayerMountRules.primary_role(primary, form)
	if primary_role in roles:
		return true
	var support := _active_support()
	var support_role := PlayerMountRules.support_role(support)
	if support_role != "" and support_role in roles:
		return true
	var support_type := str(support.get("type", ""))
	if support_type in ["emp", "magnetic"] and support_type in roles:
		return true
	if support_type == "defence" and "sensor" in roles:
		return true
	if form == "bomber" and "precision_bomb" in roles and _strike_ordnance_available():
		return true
	return false

func _active_weapon() -> Dictionary:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("_active_weapon"):
		var value = scene.call("_active_weapon")
		if typeof(value) == TYPE_DICTIONARY:
			return value
	return {}

func _active_support() -> Dictionary:
	var support_node := get_node_or_null("/root/SupportDirector")
	if support_node != null and support_node.has_method("current_support"):
		var value = support_node.call("current_support")
		if typeof(value) == TYPE_DICTIONARY:
			return value
	return {}

func _strike_ordnance_available() -> bool:
	var strike := get_node_or_null("/root/StrikeOrdnanceDirector")
	return strike != null and strike.has_method("ordnance_count") and int(strike.call("ordnance_count")) > 0

func _draw_installed(surface: CanvasItem) -> void:
	var primary := _scene_item_name("_active_weapon", "PRIMARY")
	var generator := _scene_item_name("_active_generator", "GENERATOR")
	var support := "NO SUPPORT"
	var support_node := get_node_or_null("/root/SupportDirector")
	if support_node != null and support_node.has_method("current_support_name"):
		support = str(support_node.call("current_support_name")).to_upper()
	var airframe := "STANDARD FRAME"
	var airframe_node := get_node_or_null("/root/AirframeDirector")
	if airframe_node != null and airframe_node.has_method("current_airframe_name"):
		airframe = str(airframe_node.call("current_airframe_name")).to_upper()
	PixelFont.draw_text(surface,"PRIMARY  %s" % _clip(primary,24),Vector2(52,267),1,TEXT,1)
	PixelFont.draw_text(surface,"TACTICAL %s" % _clip(support,24),Vector2(52,280),1,TEXT,1)
	PixelFont.draw_text(surface,"GEN      %s" % _clip(generator,22),Vector2(348,267),1,TEXT,1)
	PixelFont.draw_text(surface,"FRAME    %s" % _clip(airframe,22),Vector2(348,280),1,TEXT,1)

func _scene_item_name(method_name: String, fallback: String) -> String:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method(method_name):
		var value = scene.call(method_name)
		if typeof(value) == TYPE_DICTIONARY:
			return str(value.get("name", fallback)).to_upper()
	return fallback

func _clip(text: String, max_chars: int) -> String:
	var value := text.to_upper().replace("_", " ")
	return value if value.length() <= max_chars else value.substr(0,maxi(0,max_chars-1)) + "."

func _has_property(object: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(object, property_name)

func _sortie_front_end(scene: Object) -> bool:
	return _has_property(scene, "phase") and int(scene.get("phase")) == 0 and (not _has_property(scene, "front_end_screen") or str(scene.get("front_end_screen")) == "sortie")

func _ensure_action() -> void:
	if not InputMap.has_action("toggle_loadout_schematic"):
		InputMap.add_action("toggle_loadout_schematic")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_L
	if not InputMap.action_has_event("toggle_loadout_schematic", event):
		InputMap.action_add_event("toggle_loadout_schematic", event)
