extends Node2D

@onready var label: Label = $Label

var bubble_padding := Vector2(16, 10)
var padding_v := 8.0
var tail_height := 12.0
var corner_radius := 10.0
var max_width := 180.0
var viewport_margin := 8.0

func _ready() -> void:
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	modulate.a = 0.9

func show_text(text: String) -> void:
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var avail_w := _available_width()
	label.custom_minimum_size.x = avail_w - bubble_padding.x * 2
	label.size.x = avail_w - bubble_padding.x * 2
	label.size.y = 0
	visible = true
	await get_tree().process_frame
	queue_redraw()

func _available_width() -> float:
	var vp_width := get_viewport_rect().size.x
	var global_x := global_position.x
	var parent_scale: float = get_parent().get_node("Parts").scale.x
	var effective_scale: float = absf(parent_scale)
	# Bubble grows leftward from its position, so available width is
	# from the left margin to our global x, divided by our effective scale
	var left_space := (global_x - viewport_margin) / effective_scale
	var right_space := (vp_width - global_x - viewport_margin) / effective_scale
	var available := maxf(left_space, right_space)
	return clampf(available, 80.0, max_width)

func _process(_delta: float) -> void:
	if visible and label.text != "":
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
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var line_h := font.get_height(font_size)
	var lines := label.get_line_count()
	label_size = Vector2(label.size.x, lines * line_h)

	var box_w := label_size.x + bubble_padding.x * 2
	var box_h := label_size.y + padding_v * 2

	# Clamp bubble position to stay within viewport
	var vp := get_viewport_rect().size
	var gp := global_position
	var gt := global_transform
	var sx := absf(gt.x.x) if gt.x.x != 0.0 else absf(gt.x.y)
	if sx == 0.0:
		sx = 1.0

	# Default anchor: bottom-right at (0,0), grows left and up
	var offset_x := 0.0
	# Check if bubble goes off the left edge
	var left_global := gp.x + (-box_w) * sx
	if left_global < viewport_margin:
		offset_x = (viewport_margin - left_global) / sx
	# Check if bubble goes off the right edge
	var right_global := gp.x + offset_x * sx
	if right_global > vp.x - viewport_margin:
		offset_x -= (right_global - (vp.x - viewport_margin)) / sx

	# Check top edge
	var offset_y := 0.0
	var top_global := gp.y + (-box_h - tail_height) * sx
	if top_global < viewport_margin:
		offset_y = (viewport_margin - top_global) / sx

	var rect := Rect2(-box_w + offset_x, -box_h - tail_height + offset_y, box_w, box_h)

	var y_adjust := (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	label.position = Vector2(rect.position.x + bubble_padding.x, rect.position.y + padding_v - y_adjust)
	label.size = label_size
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	# Rounded rect background
	var rect_points := _rounded_rect_points(rect, corner_radius)
	draw_colored_polygon(rect_points, Color.BLACK)

	# Tail pointing from bubble bottom toward character
	var tail_margin := 15.0
	var tail_half_w := 8.0
	var left_limit := rect.position.x + tail_margin + tail_half_w
	var right_limit := rect.end.x - tail_margin - tail_half_w
	var tail_base_x := clampf(0.0, left_limit, right_limit)
	var tail_points := PackedVector2Array([
		Vector2(tail_base_x - tail_half_w, rect.end.y),
		Vector2(0, rect.end.y + tail_height),
		Vector2(tail_base_x + tail_half_w, rect.end.y),
	])
	draw_colored_polygon(tail_points, Color.BLACK)

	# Border
	rect_points.append(rect_points[0])
	draw_polyline(rect_points, Color.BLACK, 2.0)
	draw_polyline(tail_points, Color.BLACK, 2.0)
