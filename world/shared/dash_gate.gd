extends StaticBody2D

@export var size := Vector2(16, 454):
	set(value):
		size = value
		_apply_shape()
		queue_redraw()
@export var gate_color := Color("3ce9ff")

var tick := 0.0


func _ready() -> void:
	_apply_shape()
	queue_redraw()


func _process(delta: float) -> void:
	tick += delta
	queue_redraw()


func _apply_shape() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return

	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape


func _draw() -> void:
	var player := get_tree().get_first_node_in_group("player") as NeonPlayer
	var dashing := player != null and player.dash_timer > 0.0
	var pulse := 0.55 + sin(tick * 5.0) * 0.18
	var energy_alpha := 0.10 if dashing else 0.22
	var edge_alpha := 0.28 if dashing else pulse
	var rect := Rect2(-size * 0.5, size)

	# Transparent energy field instead of a solid magenta wall.
	draw_rect(
		rect,
		Color(gate_color.r, gate_color.g, gate_color.b, energy_alpha)
	)

	if size.y >= size.x:
		_draw_vertical_gate(rect, edge_alpha)
	else:
		_draw_horizontal_gate(rect, edge_alpha)


func _draw_vertical_gate(rect: Rect2, edge_alpha: float) -> void:
	var edge := Color(gate_color.r, gate_color.g, gate_color.b, edge_alpha)
	draw_rect(Rect2(rect.position.x - 5.0, rect.position.y, 5.0, rect.size.y), Color("0b2740"))
	draw_rect(Rect2(rect.end.x, rect.position.y, 5.0, rect.size.y), Color("0b2740"))
	draw_line(Vector2(rect.position.x, rect.position.y), Vector2(rect.position.x, rect.end.y), edge, 2.0)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.end.y), edge, 2.0)

	var y := rect.position.y + 14.0
	while y < rect.end.y - 8.0:
		draw_line(
			Vector2(rect.position.x + 2.0, y),
			Vector2(rect.end.x - 2.0, y + 6.0),
			Color(gate_color.r, gate_color.g, gate_color.b, edge_alpha * 0.65),
			1.0
		)
		y += 24.0

	for point_y in [rect.position.y + 8.0, rect.end.y - 8.0]:
		draw_circle(Vector2(rect.position.x - 2.5, point_y), 3.0, Color("ffb22f"))
		draw_circle(Vector2(rect.end.x + 2.5, point_y), 3.0, Color("ffb22f"))


func _draw_horizontal_gate(rect: Rect2, edge_alpha: float) -> void:
	var edge := Color(gate_color.r, gate_color.g, gate_color.b, edge_alpha)
	draw_rect(Rect2(rect.position.x, rect.position.y - 5.0, rect.size.x, 5.0), Color("0b2740"))
	draw_rect(Rect2(rect.position.x, rect.end.y, rect.size.x, 5.0), Color("0b2740"))
	draw_line(Vector2(rect.position.x, rect.position.y), Vector2(rect.end.x, rect.position.y), edge, 2.0)
	draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.end.y), edge, 2.0)

	var x := rect.position.x + 14.0
	while x < rect.end.x - 8.0:
		draw_line(
			Vector2(x, rect.position.y + 1.0),
			Vector2(x + 8.0, rect.end.y - 1.0),
			Color(gate_color.r, gate_color.g, gate_color.b, edge_alpha * 0.65),
			1.0
		)
		x += 28.0
