extends Area2D
class_name InteractionTerminal

@export_enum("tram", "mines", "factory", "return") var terminal_type := "tram"
@export var destination_x := 0.0
@export var interaction_radius := 65.0
var enabled_visual := false

func _ready() -> void:
	add_to_group("interaction_terminals")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(interaction_radius * 2.0, 70.0)
	$CollisionShape2D.shape = shape
	if terminal_type == "return":
		enabled_visual = true
	queue_redraw()

func set_enabled_visual(value: bool) -> void:
	if enabled_visual == value:
		return
	enabled_visual = value
	queue_redraw()

func is_near(player_position: Vector2) -> bool:
	return absf(player_position.x - global_position.x) < interaction_radius and absf(player_position.y - 437.0) < 35.0

func prompt(enabled: bool) -> String:
	match terminal_type:
		"tram": return "Tranvía: viajar al otro extremo" if enabled else ""
		"mines": return "Bajar a Minas" if enabled else "Ascensor: requiere energía del guardián"
		"factory": return "Entrar a Fábrica Omega" if enabled else "Fábrica: acceso sin energía"
		"return": return "Regresar a Estación G-7"
	return ""

func _draw() -> void:
	match terminal_type:
		"tram":
			draw_rect(Rect2(-42, -62, 84, 62), Color("245469") if enabled_visual else Color("263344"))
			draw_rect(Rect2(-31, -51, 62, 27), Color("65e7ca") if enabled_visual else Color("445463"))
			_label("TRANVÍA", Vector2(-42, -77), 16, Color("3ce9ff"))
		"mines":
			draw_rect(Rect2(-42, -100, 84, 100), Color("10222f"))
			draw_rect(Rect2(-42, -100, 84, 100), Color("3ce9ff") if enabled_visual else Color("744953"), false, 4)
			_label("MINAS ↓", Vector2(-44, -115), 15, Color("3ce9ff"))
		"factory":
			draw_rect(Rect2(-42, -100, 84, 100), Color("10222f"))
			draw_rect(Rect2(-42, -100, 84, 100), Color("3ce9ff") if enabled_visual else Color("744953"), false, 4)
			_label("FÁBRICA →", Vector2(-44, -115), 15, Color("3ce9ff"))

func _label(value: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
