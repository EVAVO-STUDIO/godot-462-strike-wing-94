extends CanvasLayer

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const PlayerMountRules = preload("res://scripts/player_mount_rules.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const LoadoutSchematicSurface = preload("res://scripts/loadout_schematic_surface.gd")

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
	layer = 30
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
	if scene != null and _has_property(scene, "phase") and int(scene.get("phase")) == 0:
		if Input.is_action_just_pressed("toggle_loadout_schematic"):
			_open = not _open
	else:
		_open = false
	if _surface != null:
		_surface.queue_redraw()

func draw_schematic(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _has_property(scene, "phase") or int(scene.get("phase")) != 0:
		return
	if not _open:
		surface.draw_rect(Rect2(462, 334, 78, 15), BG)
		surface.draw_rect(Rect2(462, 334, 78, 15), BORDER, false, 1.0)
		PixelFont.draw_centered(surface, "L STORES", 501, 339, 1, MUTED, 1)
		return

	surface.draw_rect(Rect2(38, 54, 564, 266), BG)
	surface.draw_rect(Rect2(38, 54, 564, 266), BORDER, false, 1.0)
	surface.draw_rect(Rect2(42, 58, 556, 258), PANEL, false, 1.0)
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
	var body := Color(0.72,0.78,0.81,0.65)
	var dark := Color(0.30,0.38,0.43,0.72)
	if form == "fighter":
		surface.draw_colored_polygon(PackedVector2Array([
			p+Vector2(0,-54),p+Vector2(-10,-18),p+Vector2(-57,28),p+Vector2(-25,19),p+Vector2(-14,48),p+Vector2(0,33),p+Vector2(14,48),p+Vector2(25,19),p+Vector2(57,28),p+Vector2(10,-18)
		]), body)
		surface.draw_line(p+Vector2(-18,6),p+Vector2(-58,31),dark,2)
		surface.draw_line(p+Vector2(18,6),p+Vector2(58,31),dark,2)
	else:
		surface.draw_colored_polygon(PackedVector2Array([
			p+Vector2(0,-50),p+Vector2(-11,-20),p+Vector2(-82,8),p+Vector2(-76,30),p+Vector2(-30,26),p+Vector2(-18,49),p+Vector2(0,34),p+Vector2(18,49),p+Vector2(30,26),p+Vector2(76,30),p+Vector2(82,8),p+Vector2(11,-20)
		]), body)
		surface.draw_rect(Rect2(p.x-62,p.y+18,124,7),dark)
		surface.draw_rect(Rect2(p.x-5,p.y-66,10,18),dark)

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
		var mount_color := ACTIVE_MOUNT if active else MOUNT
		surface.draw_rect(Rect2(roundf(point.x)-3,roundf(point.y)-3,7,7),mount_color,false,2.0 if active else 1.0)
		if active:
			surface.draw_rect(Rect2(roundf(point.x)-1,roundf(point.y)-1,3,3),mount_color)
		if shown < 7:
			var name := str(mount.get("name", mount.get("id", "MOUNT"))).to_upper()
			var side := -1.0 if point.x < p.x else 1.0
			if absf(point.x-p.x) < 6.0:
				side = 1.0
			var label_x := p.x - 128.0 if side < 0 else p.x + 72.0
			var label_y := p.y - 62.0 + shown * 15.0
			var label_color := ACTIVE_MOUNT if active else MUTED
			surface.draw_line(point,Vector2(label_x + (58 if side < 0 else 0),label_y+3),Color(mount_color,0.55 if active else 0.35),1.0)
			PixelFont.draw_text(surface,_clip(name,18),Vector2(label_x,label_y),1,label_color,1)
			shown += 1

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
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

func _ensure_action() -> void:
	if not InputMap.has_action("toggle_loadout_schematic"):
		InputMap.add_action("toggle_loadout_schematic")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_L
	if not InputMap.action_has_event("toggle_loadout_schematic", event):
		InputMap.action_add_event("toggle_loadout_schematic", event)
