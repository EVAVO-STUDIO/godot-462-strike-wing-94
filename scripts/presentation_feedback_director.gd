extends CanvasLayer
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")
const FeedbackSurface=preload("res://scripts/presentation_feedback_surface.gd")
var _surface:Control
var _scene_id:=0
var _last_damage:=0
var _last_destroyed:=0
var _trauma:=0.0
var _flash:=0.0
var _phase:=0.0
var _capture_triggered:=false
func _ready()->void:
	layer=24;_surface=FeedbackSurface.new();_surface.director=self;_surface.size=Vector2(640,360);_surface.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(_surface)
func _process(delta:float)->void:
	var scene:=get_tree().current_scene
	if scene==null or not _supports(scene):_reset_scene(scene);return
	if scene.get_instance_id()!=_scene_id:
		_scene_id=scene.get_instance_id();_last_damage=int(scene.get("damage_taken"));_last_destroyed=int(scene.get("targets_destroyed"));_trauma=0.0;_flash=0.0
	if not _capture_triggered and "--capture-feedback=damage" in OS.get_cmdline_user_args() and int(scene.get("phase"))==1:
		_capture_triggered=true;trigger_feedback(0.78,0.30)
	var damage:=int(scene.get("damage_taken"));var destroyed:=int(scene.get("targets_destroyed"))
	if damage>_last_damage:_trauma=maxf(_trauma,0.72);_flash=maxf(_flash,0.34)
	if destroyed>_last_destroyed:_trauma=maxf(_trauma,0.18)
	_last_damage=damage;_last_destroyed=destroyed;_phase+=delta*44.0;_trauma=maxf(0.0,_trauma-delta*2.7);_flash=maxf(0.0,_flash-delta*2.9)
	var settings:=get_node_or_null("/root/SettingsDirector")
	var shake_ratio:=float(settings.call("screen_shake_ratio")) if settings!=null and settings.has_method("screen_shake_ratio") else 0.75
	var amplitude:=_trauma*_trauma*4.0*shake_ratio
	scene.position=Vector2(sin(_phase*1.7),cos(_phase*2.3))*amplitude if int(scene.get("phase"))==1 else Vector2.ZERO
	if _surface!=null:_surface.queue_redraw()
func draw_feedback(surface:CanvasItem)->void:
	if _flash<=0.0:return
	var settings:=get_node_or_null("/root/SettingsDirector")
	var scale:=0.28 if settings!=null and settings.has_method("reduced_flashes") and bool(settings.call("reduced_flashes")) else 1.0
	surface.draw_rect(Rect2(0,0,640,360),Color(0.78,0.18,0.08,_flash*scale))
func trigger_feedback(trauma:float,flash:float=0.0)->void:
	_trauma=maxf(_trauma,clampf(trauma,0.0,1.0));_flash=maxf(_flash,clampf(flash,0.0,0.5))
func _reset_scene(scene:Node)->void:
	if scene!=null and scene is Node2D:scene.position=Vector2.ZERO
	_trauma=0.0;_flash=0.0
func _supports(scene:Object)->bool:
	if not scene is Node2D:return false
	return SceneContractCache.supports(scene,["phase","damage_taken","targets_destroyed"])
