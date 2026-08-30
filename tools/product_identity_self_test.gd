extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var identity := root.get_node_or_null("ProductIdentity")
	_expect(identity != null, "ProductIdentity autoload should exist", failures)
	if identity != null:
		_expect(str(identity.call("title_primary")) == "HYPERSONIC", "production title should be HYPERSONIC", failures)
		_expect(str(identity.call("title_subtitle")) == "VX-94 VARIABLE STRIKE FIGHTER", "title hierarchy should identify the VX-94 VSF", failures)
		_expect(str(identity.call("save_path")) == "user://hypersonic_save.json", "save namespace should use HYPERSONIC identity", failures)
		_expect("user://strike_wing_94_save.json" in identity.call("legacy_save_paths"), "legacy save namespace should remain migratable", failures)
		_expect(str(identity.metadata.get("developer", "")) == "EVAVO Studio", "developer metadata should be centralized", failures)
		_expect(str(identity.metadata.get("publisher", "")) == "EVAVO Studio", "publisher metadata should be centralized", failures)
	if failures.is_empty():
		print("HYPERSONIC product identity self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
