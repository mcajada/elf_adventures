extends CharacterBody2D

const BASE_MOVE_SPEED := 120.0
const MIN_SCALE := 0.2
const MAX_SCALE := 2.0
const ACCEL_TIME := 0.5
const DECEL_TIME := 0.4
const ARRIVE_THRESHOLD := 5.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var parts_root: Node2D = $Parts
@onready var shadow: Node2D = $Shadow

var is_moving := false
var rest_poses := {}
var depth_scale := 1.0
var move_factor := 0.0
var last_direction := Vector2.ZERO
var click_target := Vector2.ZERO
var has_click_target := false

func _ready() -> void:
	for child in parts_root.get_children():
		rest_poses[child.name] = {
			"position": child.position,
			"rotation": child.rotation,
			"scale": child.scale,
		}
	depth_scale = _scale_for_y(position.y)
	_apply_scale()
	anim_player.play("stand")

func _reset_parts() -> void:
	for child in parts_root.get_children():
		if child.name in rest_poses:
			child.position = rest_poses[child.name]["position"]
			child.rotation = rest_poses[child.name]["rotation"]
			child.scale = rest_poses[child.name]["scale"]

func _scale_for_y(y: float) -> float:
	var t := clampf(y / 623.0, 0.0, 1.0)
	return lerpf(MIN_SCALE, MAX_SCALE, t)

func _apply_scale() -> void:
	parts_root.scale = Vector2(depth_scale, depth_scale)
	shadow.scale = Vector2(depth_scale, depth_scale)
	shadow.modulate.a = clampf(depth_scale * 0.5, 0.1, 0.45)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Solve for node Y that places feet at click Y.
		# Feet visual Y = node_y + FEET_OFFSET * scale_for_y(node_y)
		# Since scale is linear: scale = MIN + (MAX-MIN) * y / 623
		# We can solve: click_y = node_y + 155 * (MIN + (MAX-MIN) * node_y / 623)
		# => click_y = node_y * (1 + 155*(MAX-MIN)/623) + 155*MIN
		var feet_offset: float = 155.0
		var scale_slope: float = (MAX_SCALE - MIN_SCALE) / 623.0
		var node_y: float = (event.position.y - feet_offset * MIN_SCALE) / (1.0 + feet_offset * scale_slope)
		click_target = Vector2(event.position.x, node_y)
		has_click_target = true

func _get_move_direction() -> Vector2:
	var kbd_dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		kbd_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		kbd_dir.y += 1
	if Input.is_action_pressed("move_left"):
		kbd_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		kbd_dir.x += 1

	# Keyboard input cancels click target
	if kbd_dir != Vector2.ZERO:
		has_click_target = false
		return kbd_dir.normalized()

	# Click-to-move
	if has_click_target:
		var to_target := click_target - position
		if to_target.length() < ARRIVE_THRESHOLD:
			has_click_target = false
			return Vector2.ZERO
		return to_target.normalized()

	return Vector2.ZERO

func _physics_process(delta: float) -> void:
	var direction := _get_move_direction()

	var wants_move := direction != Vector2.ZERO
	if wants_move:
		move_factor = minf(move_factor + delta / ACCEL_TIME, 1.0)
		last_direction = direction
	else:
		move_factor = maxf(move_factor - delta / DECEL_TIME, 0.0)

	var depth_speed := lerpf(20.0, BASE_MOVE_SPEED, clampf(depth_scale / MAX_SCALE, 0.0, 1.0))
	var speed := depth_speed * move_factor

	var move_dir := last_direction if move_factor > 0.0 else Vector2.ZERO
	velocity = move_dir * speed

	var new_pos := position + velocity * delta

	# Clamp to arrive exactly at click target (don't overshoot)
	if has_click_target:
		var remaining := click_target - position
		if velocity.length() * delta > remaining.length():
			new_pos = click_target
			has_click_target = false

	var s := _scale_for_y(new_pos.y)
	var margin_top := 160.0 * s
	var margin_bottom := 170.0 * s
	var margin_left := 130.0 * s
	var margin_right := 100.0 * s

	new_pos.x = clampf(new_pos.x, margin_left, 1024.0 - margin_right)
	new_pos.y = clampf(new_pos.y, margin_top, 623.0 - margin_bottom)

	var old_pos := position
	position = new_pos
	var actually_moved := position.distance_to(old_pos) > 0.1

	if actually_moved and not is_moving:
		_reset_parts()
		anim_player.play("walk")
		is_moving = true
	elif not actually_moved and is_moving:
		_reset_parts()
		anim_player.play("stand")
		is_moving = false

	if is_moving:
		var anim_speed := clampf(move_factor * depth_scale * 1.5, 0.3, 2.0)
		anim_player.speed_scale = anim_speed
	else:
		anim_player.speed_scale = 1.0

	depth_scale = _scale_for_y(position.y)
	_apply_scale()

	z_index = int(position.y)
