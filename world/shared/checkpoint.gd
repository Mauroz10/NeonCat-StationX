extends Node2D
class_name NeonCheckpoint

@export var threshold_x := 0.0
@export var spawn_x := 0.0
@export var requires_boss_defeated := false

func _ready() -> void:
	add_to_group("checkpoints")
