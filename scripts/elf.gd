extends CharacterBody2D

const MOVE_SPEED := 1.0
const MIN_SCALE := 0.2
const MAX_SCALE := 2.0
const SCALE_SPEED := 0.5

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var parts_root: Node2D = $Parts

var is_moving := false
var rest_poses := {}
var depth_scale := 1.0

func _ready() -> void:
	for child in parts_root.get_children():
		rest_poses[child.name] = {
			"position": child.position,
			"rotation": child.rotation,
			"scale": child.scale,
		}
	depth_scale = _scale_for_y(position.y)
	parts_root.scale = Vector2(depth_scale, depth_scale)
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

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1

	velocity = direction * MOVE_SPEED * 60.0

	var new_pos := position + velocity * delta

	# Estimate sprite extents at current scale for screen clamping
	var s := _scale_for_y(new_pos.y)
	var margin_top := 160.0 * s
	var margin_bottom := 170.0 * s
	var margin_left := 130.0 * s
	var margin_right := 100.0 * s

	new_pos.x = clampf(new_pos.x, margin_left, 1024.0 - margin_right)
	new_pos.y = clampf(new_pos.y, margin_top, 623.0 - margin_bottom)

	var old_pos := position
	position = new_pos
	var actually_moved := position.distance_to(old_pos) > 0.01

	if actually_moved and not is_moving:
		_reset_parts()
		anim_player.play("run")
		is_moving = true
	elif not actually_moved and is_moving:
		_reset_parts()
		anim_player.play("stand")
		is_moving = false

	depth_scale = _scale_for_y(position.y)
	parts_root.scale = Vector2(depth_scale, depth_scale)
