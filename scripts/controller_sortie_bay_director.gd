extends Node

# Controller-only sortie-bay routing. Keep the in-flight InputMap compact and
# context-neutral: these physical buttons are interpreted as progression/service
# commands only while the campaign sortie bay is actually visible.
const SORTIE_BUTTON_ACTIONS := {
	JOY_BUTTON_X: "buy_primary",
	JOY_BUTTON_Y: "buy_generator",
	JOY_BUTTON_LEFT_SHOULDER: "service_hull",
	JOY_BUTTON_RIGHT_SHOULDER: "service_shield",
	JOY_BUTTON_LEFT_STICK: "buy_airframe",
	JOY_BUTTON_RIGHT_STICK: "buy_support",
	JOY_BUTTON_DPAD_LEFT: "cycle_support",
	JOY_BUTTON_DPAD_RIGHT: "cycle_battlefield_support"
}

var last_action := ""
var action_serial := 0

func _ready() -> void:
	process_priority = -40

func _input(event: InputEvent) -> void:
	if not event is InputEventJoypadButton or not event.pressed:
		return
	var scene := get_tree().current_scene
	if not _sortie_bay_active(scene):
		return
	var button := int((event as InputEventJoypadButton).button_index)
	if not SORTIE_BUTTON_ACTIONS.has(button):
		return
	var action := str(SORTIE_BUTTON_ACTIONS[button])
	if _dispatch(scene, action):
		last_action = action
		action_serial += 1
		get_viewport().set_input_as_handled()

func _dispatch(scene: Node, action: String) -> bool:
	match action:
		"buy_primary":
			return _call_scene(scene, "_try_buy_next_weapon")
		"buy_generator":
			return _call_scene(scene, "_try_buy_next_generator")
		"service_hull":
			return _call_scene(scene, "_service_hull_full")
		"service_shield":
			return _call_scene(scene, "_service_shield_full")
		"buy_airframe":
			var airframe := get_node_or_null("/root/AirframeDirector")
			if airframe != null and airframe.has_method("_buy_next_airframe"):
				airframe.call("_buy_next_airframe", scene)
				return true
		"buy_support":
			var support := get_node_or_null("/root/SupportDirector")
			if support != null and support.has_method("_buy_next_support"):
				support.call("_buy_next_support", scene)
				return true
		"cycle_support":
			var support := get_node_or_null("/root/SupportDirector")
			if support != null and support.has_method("current_support_name"):
				var catalogue = support.get("support_catalog")
				var unlocked_index := int(support.get("unlocked_index"))
				if typeof(catalogue) == TYPE_ARRAY and not catalogue.is_empty():
					var selected_index := posmod(int(support.get("selected_index")) + 1, clampi(unlocked_index + 1, 1, catalogue.size()))
					support.set("selected_index", selected_index)
					_set_status(scene, "SUPPORT %s" % str(support.call("current_support_name")).to_upper())
					return true
		"cycle_battlefield_support":
			var battlefield := get_node_or_null("/root/BattlefieldSupportDirector")
			if battlefield != null and battlefield.has_method("_cycle"):
				battlefield.call("_cycle", scene)
				return true
	return false

func _call_scene(scene: Node, method_name: String) -> bool:
	if scene != null and scene.has_method(method_name):
		scene.call(method_name)
		return true
	return false

func _set_status(scene: Node, text: String) -> void:
	if scene == null:
		return
	if _has_property(scene, "status_text"):
		scene.set("status_text", text)
	if _has_property(scene, "status_timer"):
		scene.set("status_timer", 2.0)

func _sortie_bay_active(scene: Node) -> bool:
	if scene == null or not _has_property(scene, "phase") or int(scene.get("phase")) != 0:
		return false
	if not _has_property(scene, "front_end_screen") or str(scene.get("front_end_screen")) != "sortie":
		return false
	if _has_property(scene, "game_mode") and str(scene.get("game_mode")) != "campaign":
		return false
	var startup := get_node_or_null("/root/StartupSequenceDirector")
	if startup != null and startup.has_method("is_complete") and not bool(startup.call("is_complete")):
		return false
	return true

func binding_summary() -> Dictionary:
	return {
		"x":"BUY PRIMARY",
		"y":"BUY GENERATOR",
		"lb":"SERVICE HULL",
		"rb":"RECHARGE SHIELD",
		"l3":"BUY AIRFRAME",
		"r3":"BUY TACTICAL",
		"dpad_left":"SELECT TACTICAL",
		"dpad_right":"SELECT BATTLEFIELD",
		"rt":"SELECT PRIMARY",
		"a":"LAUNCH",
		"b":"BACK"
	}

func _has_property(object: Object, property_name: String) -> bool:
	if object == null:
		return false
	for item in object.get_property_list():
		if str(item.get("name", "")) == property_name:
			return true
	return false
