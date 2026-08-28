extends CanvasLayer

const BossHudRules = preload("res://scripts/boss_hud_rules.gd")
const BossRules = preload("res://scripts/boss_rules.gd")

var _panel: PanelContainer
var _label: Label
var _bar: ProgressBar

func _ready() -> void:
	layer = 20
	_build_hud()

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		_panel.visible = false
		return
	var boss := _active_boss(scene)
	if boss.is_empty():
		_panel.visible = false
		return
	var hp := int(boss.get("hp", 0))
	var max_hp := maxi(1, int(boss.get("max_hp", hp)))
	var phase := int(boss.get("boss_phase", BossRules.phase_for(hp, max_hp)))
	_label.text = BossHudRules.hud_text(str(boss.get("id", "")), hp, max_hp, phase)
	_bar.value = BossHudRules.health_ratio(hp, max_hp) * 100.0
	_panel.visible = true

func _build_hud() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(164, 12)
	_panel.size = Vector2(312, 42)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(300, 34)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 13)
	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 100.0
	_bar.value = 100.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(300, 10)
	box.add_child(_label)
	box.add_child(_bar)
	_panel.add_child(box)
	add_child(_panel)
	_panel.visible = false

func _active_boss(scene: Object) -> Dictionary:
	var enemies = scene.get("enemies")
	if typeof(enemies) != TYPE_ARRAY:
		return {}
	for enemy in enemies:
		if typeof(enemy) == TYPE_DICTIONARY and bool(enemy.get("boss", false)) and int(enemy.get("hp", 0)) > 0:
			return enemy
	return {}

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("enemies")
