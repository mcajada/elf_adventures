extends Node2D

@onready var label: Label = $Label

var bubble_padding := Vector2(16, 10)
var padding_v := 8.0
var tail_height := 12.0
var corner_radius := 10.0
var max_width := 250.0

func _ready() -> void:
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	modulate.a = 0.9

func show_text(text: String) -> void:
	label.text = text
	if text.length() > 50:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.custom_minimum_size.x = max_width - bubble_padding.x * 2
		label.size.x = max_width - bubble_padding.x * 2
		label.size.y = 0
	else:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size.x = 0
		label.size = Vector2(0, 0)
	visible = true
	# Wait a frame for the label to layout, then redraw
	await get_tree().process_frame
	queue_redraw()

func hide_bubble() -> void:
	visible = false

func _rounded_rect_points(rect: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var corners := [
		Vector2(rect.position.x + radius, rect.position.y + radius),
		Vector2(rect.end.x - radius, rect.position.y + radius),
		Vector2(rect.end.x - radius, rect.end.y - radius),
		Vector2(rect.position.x + radius, rect.end.y - radius),
	]
	var start_angles := [PI, PI * 1.5, 0.0, PI * 0.5]
	for i in range(4):
		for j in range(9):
			var angle: float = start_angles[i] + j * (PI * 0.5) / 8.0
			points.append(corners[i] + Vector2(cos(angle), sin(angle)) * radius)
	return points

func _draw() -> void:
	if not label or label.text == "":
		return
	var label_size: Vector2
	if label.autowrap_mode != TextServer.AUTOWRAP_OFF:
		var font := label.get_theme_font("font")
		var font_size := label.get_theme_font_size("font_size")
		var line_h := font.get_height(font_size)
		var lines := label.get_line_count()
		label_size = Vector2(label.size.x, lines * line_h)
	else:
		label_size = label.get_minimum_size()
	var is_wrapped := label.autowrap_mode != TextServer.AUTOWRAP_OFF
	var box_w := label_size.x + bubble_padding.x * 2
	var box_h := label_size.y + padding_v * 2

	# Anchor: bottom-right at (0, 0). Grows left and up.
	var rect := Rect2(-box_w, -box_h - tail_height, box_w, box_h)

	var y_adjust := 0.0
	if is_wrapped:
		var font := label.get_theme_font("font")
		var fsize := label.get_theme_font_size("font_size")
		y_adjust = (font.get_ascent(fsize) - font.get_descent(fsize)) * 0.5
	label.position = Vector2(-box_w + bubble_padding.x, -box_h - tail_height + padding_v - y_adjust)
	label.size = label_size
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	# Rounded rect background
	var rect_points := _rounded_rect_points(rect, corner_radius)
	draw_colored_polygon(rect_points, Color.BLACK)

	# Tail at bottom-right, pointing down-right toward sprite
	var tail_points := PackedVector2Array([
		Vector2(-24, -tail_height),
		Vector2(20, 0),
		Vector2(-8, -tail_height),
	])
	draw_colored_polygon(tail_points, Color.BLACK)

	# Border
	rect_points.append(rect_points[0])
	draw_polyline(rect_points, Color.BLACK, 2.0)
	draw_polyline(tail_points, Color.BLACK, 2.0)
