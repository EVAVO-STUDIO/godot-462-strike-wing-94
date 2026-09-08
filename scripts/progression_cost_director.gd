extends CanvasLayer

const PixelFont = preload("res://scripts/pixel_font.gd")
const ProgressionCostSurface = preload("res://scripts/progression_cost_surface.gd")
const TechProgressionRules = preload("res://scripts/tech_progression_rules.gd")

const GREEN := Color("67c3a5")
const GOLD := Color("e8ca6a")
const MUTED := Color("7f909b")
const RED := Color("dc6655")
const BLUE := Color("6aa4c8")
const PANEL := Color("070a0e")
const PAD_LEGEND := "PAD X WPN  Y PWR  L3 FRAME  R3 TACT  LB HULL  RB SHLD  RT SELECT"

var _surface: Control

func _ready() -> void:
	layer = 31
	if DisplayServer.get_name() == "headless":
		return
	_surface = ProgressionCostSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(_delta: float) -> void:
	if _surface != null:
		_surface.queue_redraw()

func draw_progression_costs(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if not _sortie_bay_active(scene):
		return
	var credits := int(scene.get("credits"))
	var tech_era := _tech_era()

	_draw_purchase_tag(surface, Vector2(340, 224), _next_weapon(scene), tech_era, credits)
	_draw_purchase_tag(surface, Vector2(340, 239), _next_generator(scene), tech_era, credits)
	_draw_purchase_tag(surface, Vector2(340, 254), _next_airframe(), tech_era, credits)
	_draw_purchase_tag(surface, Vector2(340, 269), _next_support(), tech_era, credits)

	var campaign := _campaign_config(scene)
	var service_hull := int(scene.get("service_hull")) if _has_property(scene, "service_hull") else int(scene.get("hull"))
	var service_shield := int(scene.get("service_shield")) if _has_property(scene, "service_shield") else int(scene.get("shield"))
	var max_hull := _call_int(scene, "_max_hull", 100)
	var max_shield := _call_int(scene, "_max_shield", 100)
	var hull_cost := maxi(0, max_hull - service_hull) * maxi(0, int(campaign.get("repair_cost_per_hull", 0)))
	var shield_cost := maxi(0, max_shield - service_shield) * maxi(0, int(campaign.get("shield_recharge_cost_per_point", 0)))
	_draw_service_tag(surface, Vector2(570, 243), hull_cost, credits)
	_draw_service_tag(surface, Vector2(570, 258), shield_cost, credits)

	# The underlying airframe panel used to say Q SWEEP in the hangar even
	# though wing geometry is an in-flight command. Replace that misleading hint
	# with the actual context, then expose the full controller maintenance map in
	# the otherwise unused gutter above the launch rail.
	surface.draw_rect(Rect2(490, 160, 112, 15), PANEL)
	PixelFont.draw_text(surface, "FORM IN FLIGHT", Vector2(493, 166), 1, BLUE, 1)
	PixelFont.draw_centered(surface, PAD_LEGEND, 320, 299, 1, MUTED, 1)

func _sortie_bay_active(scene: Node) -> bool:
	if scene == null:
		return false
	if not _has_property(scene, "phase") or int(scene.get("phase")) != 0:
		return false
	if not _has_property(scene, "front_end_screen") or str(scene.get("front_end_screen")) != "sortie":
		return false
	if _has_property(scene, "game_mode") and str(scene.get("game_mode")) != "campaign":
		return false
	var startup := get_node_or_null("/root/StartupSequenceDirector")
	if startup != null and startup.has_method("is_complete") and not bool(startup.call("is_complete")):
		return false
	return true

func _next_weapon(scene: Node) -> Dictionary:
	if scene == null or not scene.has_method("_primary_weapons") or not _has_property(scene, "weapon_index"):
		return {}
	var primaries = scene.call("_primary_weapons")
	return _next_catalog_item(primaries, int(scene.get("weapon_index")))

func _next_generator(scene: Node) -> Dictionary:
	if scene == null or not _has_property(scene, "generator_catalog") or not _has_property(scene, "generator_index"):
		return {}
	return _next_catalog_item(scene.get("generator_catalog"), int(scene.get("generator_index")))

func _next_airframe() -> Dictionary:
	var director := get_node_or_null("/root/AirframeDirector")
	if director == null:
		return {}
	return _next_catalog_item(director.get("airframe_catalog"), int(director.get("airframe_index")))

func _next_support() -> Dictionary:
	var director := get_node_or_null("/root/SupportDirector")
	if director == null:
		return {}
	return _next_catalog_item(director.get("support_catalog"), int(director.get("unlocked_index")))

func _next_catalog_item(value: Variant, current_index: int) -> Dictionary:
	if typeof(value) != TYPE_ARRAY:
		return {}
	var catalog: Array = value
	var next_index := current_index + 1
	if next_index < 0 or next_index >= catalog.size():
		return {}
	var item = catalog[next_index]
	return item if typeof(item) == TYPE_DICTIONARY else {}

func _purchase_tag(item: Dictionary, current_tech_era: String, credits: int) -> Dictionary:
	if item.is_empty():
		return {"text":"MAX", "tone":"muted"}
	var cost := maxi(0, int(item.get("cost", 0)))
	var required_era := str(item.get("unlock_tech_era", "advanced_conventional"))
	if not TechProgressionRules.can_unlock(required_era, current_tech_era):
		return {"text":"LOCK %s" % _short_era(required_era), "tone":"muted"}
	return {
		"text":">%06d" % cost,
		"tone":"ready" if credits >= cost else "price"
	}

func _draw_purchase_tag(surface: CanvasItem, position: Vector2, item: Dictionary, tech_era: String, credits: int) -> void:
	var tag := _purchase_tag(item, tech_era, credits)
	PixelFont.draw_text(surface, str(tag.get("text", "")), position, 1, _tone_color(str(tag.get("tone", "muted"))), 1)

func _draw_service_tag(surface: CanvasItem, position: Vector2, cost: int, credits: int) -> void:
	var text := "FULL" if cost <= 0 else "%04dC" % mini(cost, 9999)
	var tone := "ready" if cost <= 0 or credits >= cost else "danger"
	PixelFont.draw_text(surface, text, position, 1, _tone_color(tone), 1)

func _campaign_config(scene: Node) -> Dictionary:
	if scene != null and scene.has_method("_campaign_config"):
		var value = scene.call("_campaign_config")
		if typeof(value) == TYPE_DICTIONARY:
			return value
	return {}

func _tech_era() -> String:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method("mission_context"):
		var context = director.call("mission_context")
		if typeof(context) == TYPE_DICTIONARY:
			return TechProgressionRules.sanitize_era(str(context.get("tech_era", "advanced_conventional")))
	return "advanced_conventional"

func _short_era(era_id: String) -> String:
	match TechProgressionRules.sanitize_era(era_id):
		"electromagnetic": return "EM"
		"directed_energy": return "DE"
		"strategic_orbital": return "OR"
	return "CV"

func _tone_color(tone: String) -> Color:
	match tone:
		"ready": return GREEN
		"price": return GOLD
		"danger": return RED
	return MUTED

func _call_int(object: Object, method_name: String, fallback: int) -> int:
	return int(object.call(method_name)) if object != null and object.has_method(method_name) else fallback

func _has_property(object: Object, property_name: String) -> bool:
	if object == null:
		return false
	for item in object.get_property_list():
		if str(item.get("name", "")) == property_name:
			return true
	return false
