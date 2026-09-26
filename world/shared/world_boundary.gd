extends StaticBody2D

@export var size := Vector2(64.0, 540.0):
	set(value):
		size = value
		_apply_shape()

func _ready() -> void:
	_apply_shape()

func _apply_shape() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
