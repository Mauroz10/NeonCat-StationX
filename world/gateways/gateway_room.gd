extends Node2D
class_name GatewayRoom

@export var room_title := "Minas Bioluminosas"
@export var mine_theme := true
var tick := 0.0

func _ready() -> void:
	add_to_group("gateway_room")

func _process(delta: float) -> void:
	tick += delta
	queue_redraw()

func get_terminal(player_position: Vector2) -> InteractionTerminal:
	for terminal in get_tree().get_nodes_in_group("interaction_terminals"):
		if is_ancestor_of(terminal) and terminal is InteractionTerminal and terminal.is_near(player_position):
			return terminal
	return null

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1500, 540), Color("061e25") if mine_theme else Color("281b25"))
	for x in range(0, 1500, 105):
		if mine_theme:
			draw_colored_polygon(PackedVector2Array([Vector2(x, 450), Vector2(x + 25, 300 + x % 85), Vector2(x + 70, 450)]), Color("194f55"))
			draw_circle(Vector2(x + 40, 350), 8, Color("42d8b2"))
		else:
			draw_rect(Rect2(x, 190, 24, 260), Color("533440"))
			draw_circle(Vector2(x + 55, 285), 28, Color("914d40"))
			draw_arc(Vector2(x + 55, 285), 20, tick, tick + 4, 16, Color("ff9940"), 4)
	_label("← REGRESAR A ESTACIÓN G-7", Vector2(25, 340), 18, Color("3ce9ff"))
	_label("VESTÍBULO · " + room_title.to_upper(), Vector2(350, 180), 24, Color("3ce9ff"))
	draw_rect(Rect2(1370, 190, 35, 264), Color("536572"))
	_label("COMPUERTA EXTERIOR SELLADA", Vector2(1050, 230), 17, Color("ff9940"))

func _label(value: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
