extends StaticBody2D

@export var size := Vector2(16, 454):
	set(value):
		size = value
		_apply_shape()
		queue_redraw()
@export var gate_color := Color("e03ef2")

func _ready() -> void:
	_apply_shape()
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _apply_shape() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape

func _draw() -> void:
	var draw_color := gate_color
	var player := get_tree().get_first_node_in_group("player") as NeonPlayer
	if player != null and player.dash_timer > 0.0:
		draw_color.a = 0.25
	draw_rect(Rect2(-size * 0.5, size), draw_color)
