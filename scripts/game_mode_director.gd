extends Node

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const GameModeRules = preload("res://scripts/game_mode_rules.gd")

var _modes: Array = []
var _active: Dictionary = {}
var _campaign_snapshot: Dictionary = {}

func _ready() -> void:
	var data = ContentCatalog.load_json("res://data/game_modes.json")
	var missions_data = ContentCatalog.load_json("res://data/missions.json")
	var mission_ids: Array[String] = []
	if typeof(missions_data) == TYPE_DICTIONARY:
		for mission in missions_data.get("missions", []):
			if typeof(mission) == TYPE_DICTIONARY:
				mission_ids.append(str(mission.get("id", "")))
	if typeof(data) == TYPE_DICTIONARY:
		_modes = GameModeRules.sanitize_modes(data.get("modes", []),mission_ids)

func modes() -> Array:
	return _modes.duplicate(true)

func mode_count() -> int:
	return _modes.size()

func mode_at(index: int) -> Dictionary:
	if _modes.is_empty(): return {}
	return _modes[clampi(index,0,_modes.size()-1)].duplicate(true)

func active_mode() -> Dictionary:
	return _active.duplicate(true)

func active() -> bool:
	return not _active.is_empty()

func start_selected(scene: Object, selection: int) -> bool:
	if scene == null or _modes.is_empty(): return false
	_active = _modes[clampi(selection,0,_modes.size()-1)].duplicate(true)
	_campaign_snapshot = _snapshot_campaign(scene)
	_set_if(scene,"game_mode",str(_active.get("id","arcade")))
	_set_if(scene,"mode_name",str(_active.get("name","ARCADE")))
	_set_if(scene,"mode_rule_summary",str(_active.get("tagline","ONE CREDIT")))
	_set_if(scene,"mode_route_index",0)
	_set_if(scene,"mode_route_total",_active.get("missions",[]).size())
	_set_if(scene,"mode_lives",maxi(1,int(_active.get("lives",1))))
	_set_if(scene,"mode_total_score",0)
	_apply_loadout(scene)
	return _prepare_route_mission(scene,0)

func record_result(scene: Object, success: bool, sortie_score: int) -> void:
	if not active() or scene == null: return
	_set_if(scene,"mode_total_score",int(scene.get("mode_total_score"))+maxi(0,sortie_score))
	if not success:
		_set_if(scene,"mode_lives",maxi(0,int(scene.get("mode_lives"))-1))

func advance_result(scene: Object, success: bool) -> String:
	if not active() or scene == null: return "campaign"
	var route_index := int(scene.get("mode_route_index"))
	if success:
		route_index += 1
		if route_index >= _active.get("missions",[]).size():
			_end_run(scene)
			return "complete"
	elif int(scene.get("mode_lives")) <= 0:
		_end_run(scene)
		return "failed"
	_set_if(scene,"mode_route_index",route_index)
	_prepare_route_mission(scene,route_index)
	return "continue"

func enemy_hp(base_hp: int) -> int:
	return GameModeRules.scaled_hp(base_hp,_active) if active() else maxi(1,base_hp)

func enemy_speed(base_speed: float) -> float:
	return GameModeRules.scaled_speed(base_speed,_active) if active() else base_speed

func score_value(base_score: int) -> int:
	return GameModeRules.scaled_score(base_score,_active) if active() else base_score

func _prepare_route_mission(scene: Object, route_index: int) -> bool:
	var route: Array = _active.get("missions",[])
	if route_index < 0 or route_index >= route.size(): return false
	var index := _mission_index_for_id(scene,str(route[route_index]))
	if index < 0: return false
	_set_if(scene,"mission_index",index)
	if scene.has_method("_prepare_mission"): scene.call("_prepare_mission",index)
	_set_if(scene,"phase",0)
	_set_if(scene,"front_end_screen","sortie")
	return true

func _apply_loadout(scene: Object) -> void:
	_set_if(scene,"weapon_index",int(_active.get("weapon_index",0)))
	_set_if(scene,"generator_index",int(_active.get("generator_index",0)))
	var airframe := get_node_or_null("/root/AirframeDirector")
	if airframe != null and airframe.has_method("restore_airframe_state"):
		airframe.call("restore_airframe_state",int(_active.get("airframe_index",0)))
	var support := get_node_or_null("/root/SupportDirector")
	if support != null and support.has_method("restore_support_state"):
		var support_index := int(_active.get("support_index",0))
		support.call("restore_support_state",support_index,support_index)
	var max_hull := int(scene.call("_max_hull")) if scene.has_method("_max_hull") else 100
	var max_shield := int(scene.call("_max_shield")) if scene.has_method("_max_shield") else 100
	_set_if(scene,"service_hull",max_hull)
	_set_if(scene,"service_shield",max_shield)

func _snapshot_campaign(scene: Object) -> Dictionary:
	var airframe := get_node_or_null("/root/AirframeDirector")
	var support := get_node_or_null("/root/SupportDirector")
	return {
		"credits":int(scene.get("credits")),"mission_index":int(scene.get("mission_index")),
		"weapon_index":int(scene.get("weapon_index")),"generator_index":int(scene.get("generator_index")),
		"service_hull":int(scene.get("service_hull")),"service_shield":int(scene.get("service_shield")),
		"airframe_index":int(airframe.call("airframe_state").get("airframe_index",0)) if airframe != null and airframe.has_method("airframe_state") else 0,
		"support":support.call("support_state") if support != null and support.has_method("support_state") else {}
	}

func _end_run(scene: Object) -> void:
	var snapshot := _campaign_snapshot.duplicate(true)
	_active = {}
	_campaign_snapshot = {}
	for key in ["credits","mission_index","weapon_index","generator_index","service_hull","service_shield"]:
		if snapshot.has(key): _set_if(scene,key,snapshot[key])
	var airframe := get_node_or_null("/root/AirframeDirector")
	if airframe != null and airframe.has_method("restore_airframe_state"):
		airframe.call("restore_airframe_state",int(snapshot.get("airframe_index",0)))
	var support := get_node_or_null("/root/SupportDirector")
	var support_state: Dictionary = snapshot.get("support",{})
	if support != null and support.has_method("restore_support_state"):
		support.call("restore_support_state",int(support_state.get("selected_index",0)),int(support_state.get("unlocked_index",0)))
	_set_if(scene,"game_mode","campaign")
	_set_if(scene,"phase",0)
	_set_if(scene,"front_end_screen","modes")
	if scene.has_method("_prepare_mission"): scene.call("_prepare_mission",int(snapshot.get("mission_index",0)))

func _mission_index_for_id(scene: Object, mission_id: String) -> int:
	var catalog = scene.get("mission_catalog")
	if typeof(catalog) != TYPE_ARRAY: return -1
	for i in range(catalog.size()):
		if str(catalog[i].get("id","")) == mission_id: return i
	return -1

func _set_if(scene: Object, property_name: String, value: Variant) -> void:
	for property in scene.get_property_list():
		if str(property.get("name","")) == property_name:
			scene.set(property_name,value)
			return
