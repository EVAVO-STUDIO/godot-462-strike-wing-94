extends CanvasLayer

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const CreditsSurface = preload("res://scripts/credits_surface.gd")
const FRAME := preload("res://assets/runtime/ui/credits/credits_frame.png")
const WORDMARK := preload("res://assets/runtime/title/hypersonic_wordmark_v1.png")
const VX94 := preload("res://assets/runtime/cinematics/subjects/ending/vx94_fighter_0.png")
const PLATES := {
	"ark": preload("res://assets/runtime/cinematics/plates/end_ark_fall.png"),
	"reentry": preload("res://assets/runtime/cinematics/plates/end_reentry.png"),
	"city": preload("res://assets/runtime/cinematics/plates/end_city_silence.png"),
	"watch": preload("res://assets/runtime/cinematics/plates/end_watch.png"),
	"title": preload("res://assets/runtime/cinematics/plates/end_title_sky.png"),
}

var _pages: Array = []
var _active := false
var _page_index := 0
var _elapsed := 0.0
var _surface: Control

func _ready() -> void:
	layer = 92
	var data = ContentCatalog.load_json("res://data/credits.json")
	if typeof(data) == TYPE_DICTIONARY:
		_pages = data.get("pages", [])
	_surface = CreditsSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640,360)
	_surface.custom_minimum_size = Vector2(640,360)
	_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_surface)
	_surface.visible = false
	if "--capture-credits" in OS.get_cmdline_user_args():
		call_deferred("begin")

func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	var page := _current_page()
	if page.is_empty():
		finish()
		return
	if Input.is_action_just_pressed("cancel"):
		finish()
	elif Input.is_action_just_pressed("confirm") and _elapsed >= 0.45:
		_advance()
	elif _elapsed >= float(page.get("duration", 4.0)):
		_advance()
	if _surface != null:
		_surface.queue_redraw()

func begin() -> void:
	if _pages.is_empty():
		return
	_active = true
	_page_index = 0
	_elapsed = 0.0
	if _surface != null:
		_surface.visible = true
		_surface.queue_redraw()

func credits_active() -> bool:
	return _active

func finish() -> void:
	_active = false
	_page_index = 0
	_elapsed = 0.0
	if _surface != null:
		_surface.visible = false
	_return_to_front_door()

func _advance() -> void:
	_page_index += 1
	_elapsed = 0.0
	if _page_index >= _pages.size():
		finish()

func _current_page() -> Dictionary:
	if _page_index < 0 or _page_index >= _pages.size():
		return {}
	return _pages[_page_index] if typeof(_pages[_page_index]) == TYPE_DICTIONARY else {}

func draw_credits(surface: CanvasItem) -> void:
	var page := _current_page()
	if page.is_empty():
		return
	var duration := maxf(0.1, float(page.get("duration", 4.0)))
	var ratio := clampf(_elapsed / duration, 0.0, 1.0)
	var fade := minf(clampf(ratio / 0.12,0.0,1.0),clampf((1.0-ratio)/0.12,0.0,1.0))
	surface.draw_rect(Rect2(0,0,640,360),Color("020407"))
	var plate: Texture2D = PLATES.get(str(page.get("plate", "title")), PLATES["title"])
	surface.draw_texture_rect_region(plate,Rect2(0,0,640,360),Rect2(0,0,640,320),Color(0.42,0.48,0.52,fade*0.72))
	surface.draw_rect(Rect2(0,0,640,360),Color(0.01,0.02,0.03,0.56*fade))
	surface.draw_texture(FRAME,Vector2(16,16),Color(1,1,1,fade))
	if _page_index == 0:
		surface.draw_texture_rect(WORDMARK,Rect2(92,62,456,58),false,Color(1,1,1,fade))
		PixelFont.draw_centered(surface,"VX-94 VARIABLE STRIKE FIGHTER",320,128,1,Color(0.42,0.64,0.78,fade),1)
		PixelFont.draw_centered(surface,str(page.get("heading", "")),320,200,1,Color(0.93,0.82,0.44,fade),1)
		PixelFont.draw_centered(surface,str(page.get("lines", ["EVAVO STUDIO"])[0]),320,226,2,Color(0.86,0.91,0.92,fade),1)
	else:
		PixelFont.draw_centered(surface,str(page.get("heading", "")),320,82,2,Color(0.93,0.82,0.44,fade),1)
		var lines: Array = page.get("lines", [])
		var start_y := 126 - maxi(0,lines.size()-3)*7
		for i in range(lines.size()):
			var color := Color(0.42,0.64,0.78,fade) if i < lines.size()-1 else Color(0.86,0.91,0.92,fade)
			PixelFont.draw_centered(surface,str(lines[i]),320,start_y+i*26,1,color,1)
	if bool(page.get("vx94", false)):
		surface.draw_texture_rect(VX94,Rect2(282,190,76,84),false,Color(0.90,0.94,0.95,fade))
	PixelFont.draw_text(surface,"EVAVO STUDIO // HYPERSONIC",Vector2(30,324),1,Color(0.32,0.42,0.48,fade),1)
	PixelFont.draw_text(surface,"%02d / %02d" % [_page_index+1,_pages.size()],Vector2(562,324),1,Color(0.32,0.42,0.48,fade),1)
	PixelFont.draw_centered(surface,"ENTER ADVANCE   ESC SKIP",320,342,1,Color(0.32,0.42,0.48,fade),1)

func _return_to_front_door() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	for property in scene.get_property_list():
		if str(property.get("name", "")) == "phase": scene.set("phase",0)
		elif str(property.get("name", "")) == "front_end_screen": scene.set("front_end_screen","main_menu")
		elif str(property.get("name", "")) == "menu_selection": scene.set("menu_selection",0)
	if scene.has_method("queue_redraw"):
		scene.call("queue_redraw")
