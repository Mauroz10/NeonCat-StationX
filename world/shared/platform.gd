extends StaticBody2D

@export var size := Vector2(120, 18):
	set(value):
		size = value
		_apply_shape()
		queue_redraw()
@export var one_way := true
@export var collision_inset_x := 0.0
@export var fill_color := Color("173665")
@export var top_color := Color("3ce9ff")
@export var detail_color := Color("1779df")
@export var show_details := true

func _ready() -> void:
	add_to_group("platforms")
	_apply_shape()
	queue_redraw()

func _apply_shape() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return
	var shape := RectangleShape2D.new()
	shape.size = Vector2(maxf(1.0, size.x - collision_inset_x * 2.0), size.y)
	collision.shape = shape
	collision.one_way_collision = one_way

func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect, fill_color)
	draw_rect(Rect2(rect.position.x, rect.position.y, size.x, minf(7.0, size.y)), top_color)
	if show_details:
		var count := int(size.x / 28.0)
		for i in range(count):
			draw_rect(Rect2(rect.position.x + 10.0 + float(i) * 28.0, rect.position.y + minf(9.0, size.y - 5.0), 8, 4), detail_color)
