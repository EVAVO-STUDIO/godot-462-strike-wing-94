extends Node

const IDENTITY_PATH := "res://data/product_identity.json"
const FALLBACK := {
	"full_title": "HYPERSONIC",
	"aircraft_designation": "VX-94",
	"aircraft_class": "Variable Strike Fighter",
	"aircraft_class_abbreviation": "VSF",
	"developer": "EVAVO Studio",
	"publisher": "EVAVO Studio",
	"window_title": "HYPERSONIC",
	"executable_title": "HYPERSONIC",
	"title_screen": {"primary":"HYPERSONIC", "subtitle":"VX-94 VARIABLE STRIKE FIGHTER"},
	"version": "0.0.0-dev",
	"copyright": "Copyright (c) EVAVO Studio",
	"save_namespace": "hypersonic",
	"store": {"name":"HYPERSONIC", "short_name":"HYPERSONIC", "tagline":"VX-94 VARIABLE STRIKE FIGHTER"},
	"legacy_aliases": [],
	"legacy_save_namespaces": ["strike_wing_94"]
}

var metadata: Dictionary = FALLBACK.duplicate(true)

func _enter_tree() -> void:
	metadata = _load_identity()
	ProjectSettings.set_setting("application/config/name", text("window_title"))
	DisplayServer.window_set_title(text("window_title"))

func text(key: String, fallback: String = "") -> String:
	return str(metadata.get(key, fallback))

func title_primary() -> String:
	return str(_section("title_screen").get("primary", text("full_title", "HYPERSONIC")))

func title_subtitle() -> String:
	return str(_section("title_screen").get("subtitle", "%s %s" % [text("aircraft_designation"), text("aircraft_class").to_upper()]))

func save_path() -> String:
	return "user://%s_save.json" % text("save_namespace", "hypersonic")

func backup_save_path() -> String:
	return "user://%s_save.bak.json" % text("save_namespace", "hypersonic")

func legacy_save_paths() -> Array[String]:
	var paths: Array[String] = []
	for legacy_namespace in metadata.get("legacy_save_namespaces", []):
		var normalized := str(legacy_namespace).strip_edges()
		if not normalized.is_empty() and normalized != text("save_namespace"):
			paths.append("user://%s_save.json" % normalized)
	return paths

func _section(key: String) -> Dictionary:
	var value = metadata.get(key, {})
	return value if typeof(value) == TYPE_DICTIONARY else {}

func _load_identity() -> Dictionary:
	var file := FileAccess.open(IDENTITY_PATH, FileAccess.READ)
	if file == null:
		push_error("HYPERSONIC product identity is missing: %s" % IDENTITY_PATH)
		return FALLBACK.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("HYPERSONIC product identity is malformed: %s" % IDENTITY_PATH)
		return FALLBACK.duplicate(true)
	var result := FALLBACK.duplicate(true)
	result.merge(parsed, true)
	return result
