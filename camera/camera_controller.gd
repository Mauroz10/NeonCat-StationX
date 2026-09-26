extends Node2D

const VIEWPORT_WIDTH := 960.0
const VIEWPORT_HEIGHT := 540.0
const LOOK_AHEAD := 105.6
@onready var camera: Camera2D = $Camera2D
var target: NeonPlayer
var world_width := 8600.0

func set_target(player: NeonPlayer) -> void:
	target = player
	_update_now()

func set_world_width(value: float) -> void:
	world_width = value
	camera.limit_left = 0
	camera.limit_right = int(value)
	camera.limit_top = 0
	camera.limit_bottom = int(VIEWPORT_HEIGHT)
	_update_now()

func _process(_delta: float) -> void:
	_update_now()

func _update_now() -> void:
	if target == null:
		return
	var center_x := clampf(target.global_position.x + LOOK_AHEAD, VIEWPORT_WIDTH * 0.5, world_width - VIEWPORT_WIDTH * 0.5)
	global_position = Vector2(center_x, VIEWPORT_HEIGHT * 0.5)
