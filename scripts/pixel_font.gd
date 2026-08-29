class_name PixelFont
extends RefCounted

const GLYPHS := {
	"A":["010","101","111","101","101"], "B":["110","101","110","101","110"],
	"C":["011","100","100","100","011"], "D":["110","101","101","101","110"],
	"E":["111","100","110","100","111"], "F":["111","100","110","100","100"],
	"G":["011","100","101","101","011"], "H":["101","101","111","101","101"],
	"I":["111","010","010","010","111"], "J":["001","001","001","101","010"],
	"K":["101","101","110","101","101"], "L":["100","100","100","100","111"],
	"M":["101","111","111","101","101"], "N":["101","111","111","111","101"],
	"O":["010","101","101","101","010"], "P":["110","101","110","100","100"],
	"Q":["010","101","101","011","001"], "R":["110","101","110","101","101"],
	"S":["011","100","010","001","110"], "T":["111","010","010","010","010"],
	"U":["101","101","101","101","111"], "V":["101","101","101","101","010"],
	"W":["101","101","111","111","101"], "X":["101","101","010","101","101"],
	"Y":["101","101","010","010","010"], "Z":["111","001","010","100","111"],
	"0":["111","101","101","101","111"], "1":["010","110","010","010","111"],
	"2":["110","001","010","100","111"], "3":["110","001","010","001","110"],
	"4":["101","101","111","001","001"], "5":["111","100","110","001","110"],
	"6":["011","100","111","101","111"], "7":["111","001","010","010","010"],
	"8":["111","101","111","101","111"], "9":["111","101","111","001","110"],
	"-":["000","000","111","000","000"], "+":["000","010","111","010","000"],
	"/":["001","001","010","100","100"], ":":["000","010","000","010","000"],
	".":["000","000","000","000","010"], "%":["101","001","010","100","101"],
	"'":["010","010","000","000","000"], "!":["010","010","010","000","010"],
	"?":["110","001","010","000","010"], "=":["000","111","000","111","000"],
	" ":["000","000","000","000","000"]
}

static func draw_text(target: CanvasItem, text: String, position: Vector2, scale: int = 1, color: Color = Color.WHITE, spacing: int = 1) -> float:
	var pixel := maxi(1, scale)
	var cursor_x := roundf(position.x)
	var cursor_y := roundf(position.y)
	var advance := (3 * pixel) + maxi(0, spacing)
	for raw_char in text.to_upper():
		var character := str(raw_char)
		var rows: Array = GLYPHS.get(character, GLYPHS["?"])
		for y in range(5):
			var row := str(rows[y])
			for x in range(3):
				if row.substr(x, 1) == "1":
					target.draw_rect(Rect2(cursor_x + x * pixel, cursor_y + y * pixel, pixel, pixel), color)
		cursor_x += advance
	return cursor_x - roundf(position.x)

static func text_width(text: String, scale: int = 1, spacing: int = 1) -> float:
	if text.is_empty():
		return 0.0
	var pixel := maxi(1, scale)
	return float(text.length() * ((3 * pixel) + maxi(0, spacing)) - maxi(0, spacing))

static func draw_centered(target: CanvasItem, text: String, center_x: float, y: float, scale: int = 1, color: Color = Color.WHITE, spacing: int = 1) -> void:
	var width := text_width(text, scale, spacing)
	draw_text(target, text, Vector2(roundf(center_x - width * 0.5), roundf(y)), scale, color, spacing)
