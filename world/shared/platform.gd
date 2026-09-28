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
	shape.size = Vector2(
		maxf(1.0, size.x - collision_inset_x * 2.0),
		size.y
	)
	collision.shape = shape
	collision.one_way_collision = one_way


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	var top_h := minf(6.0, size.y)

	# Main industrial body.
	draw_rect(rect, fill_color)
	draw_rect(Rect2(rect.position.x, rect.position.y, size.x, top_h), top_color)

	# Dark underside gives the platform more depth without changing collision.
	if size.y >= 12.0:
		draw_rect(
			Rect2(rect.position.x, rect.end.y - 4.0, size.x, 4.0),
			Color("07182a")
		)

	if not show_details:
		return

	# End caps.
	var cap_w := minf(10.0, size.x * 0.12)
	draw_rect(Rect2(rect.position.x, rect.position.y + top_h, cap_w, maxf(1.0, size.y - top_h)), Color("0a2039"))
	draw_rect(Rect2(rect.end.x - cap_w, rect.position.y + top_h, cap_w, maxf(1.0, size.y - top_h)), Color("0a2039"))

	# Repeating luminous service modules.
	var module_count := maxi(1, int(size.x / 34.0))
	for i in range(module_count):
		var module_x := rect.position.x + 14.0 + float(i) * 34.0
		if module_x + 15.0 >= rect.end.x - cap_w:
			break
		draw_rect(
			Rect2(module_x, rect.position.y + minf(9.0, size.y - 5.0), 14.0, 3.0),
			detail_color
		)

	# Small structural bolts.
	if size.y >= 14.0:
		draw_circle(Vector2(rect.position.x + 7.0, rect.end.y - 6.0), 1.5, Color("6aa6bf"))
		draw_circle(Vector2(rect.end.x - 7.0, rect.end.y - 6.0), 1.5, Color("6aa6bf"))
