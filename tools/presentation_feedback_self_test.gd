extends SceneTree
var failures:Array[String]=[]
func _initialize()->void:
	var feedback:Node=load("res://scripts/presentation_feedback_director.gd").new()
	feedback.set("_trauma",0.1);feedback.set("_flash",0.05);feedback.call("trigger_feedback",0.72,0.34)
	_expect(absf(float(feedback.get("_trauma"))-0.72)<0.001,"damage feedback should raise bounded trauma")
	_expect(absf(float(feedback.get("_flash"))-0.34)<0.001,"damage feedback should raise bounded flash exposure")
	feedback.free()
	var source:=_source("res://scripts/presentation_feedback_director.gd")
	_expect(source.contains("screen_shake_ratio") and source.contains("reduced_flashes"),"feedback presentation should consume both accessibility controls")
	_expect(source.contains("scene.position=Vector2") and source.contains("_trauma*_trauma*4.0"),"world-only shake should be restrained and non-linear")
	_expect(source.contains("--capture-feedback=damage"),"feedback visual QA should expose a deterministic damage state")
	var project:=_source("res://project.godot")
	_expect(project.contains('PresentationFeedbackDirector="*res://scripts/presentation_feedback_director.gd"'),"presentation feedback should be a canonical project service")
	var ui:=_source("res://scripts/pixel_ui_director.gd")
	_expect(ui.contains("category_global_index") and ui.contains("Q / X CATEGORY"),"system options should expose controller-navigable category pages")
	if failures.is_empty():print("HYPERSONIC presentation feedback self-test passed.");quit(0);return
	for failure in failures:push_error(failure)
	quit(1)
func _source(path:String)->String:
	var file:=FileAccess.open(path,FileAccess.READ);return file.get_as_text() if file!=null else ""
func _expect(condition:bool,message:String)->void:
	if not condition:failures.append(message)
