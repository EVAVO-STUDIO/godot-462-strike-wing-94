extends CanvasLayer

const ThreatWarningRules = preload("res://scripts/threat_warning_rules.gd")

var _panel: PanelContainer
var _label: Label

func _ready() -> void:
	layer = 21
	_build_hud()

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		_panel.visible = false
		return
	var bullets = scene.get("enemy_bullets")
	var player_position: Vector2 = scene.get("player_position")
	var count := ThreatWarningRules.homing_count(bullets)
	var distance := ThreatWarningRules.nearest_homing_distance(bullets, player_position)
	var text := ThreatWarningRules.warning_text(distance, count)
	if text == "":
		_panel.visible = false
		return
	_label.text = text
	_panel.visible = true

func _build_hud() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(190, 58)
	_panel.size = Vector2(260, 28)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 11)
	_label.custom_minimum_size = Vector2(248, 18)
	_panel.add_child(_label)
	add_child(_panel)
	_panel.visible = false

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("enemy_bullets") and names.has("player_position")
