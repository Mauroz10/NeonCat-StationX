extends Area2D
class_name InteractionTerminal

@export_enum("tram", "mines", "factory", "return") var terminal_type := "tram"
@export var destination_x := 0.0
@export var interaction_radius := 65.0

var enabled_visual := false
var tick := 0.0


func _ready() -> void:
	add_to_group("interaction_terminals")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(interaction_radius * 2.0, 70.0)
	$CollisionShape2D.shape = shape
	if terminal_type == "return":
		enabled_visual = true
	queue_redraw()


func _process(delta: float) -> void:
	tick += delta
	queue_redraw()


func set_enabled_visual(value: bool) -> void:
	if enabled_visual == value:
		return
	enabled_visual = value
	queue_redraw()


func is_near(player_position: Vector2) -> bool:
	return (
		absf(player_position.x - global_position.x) < interaction_radius
		and absf(player_position.y - 437.0) < 35.0
	)


func prompt(enabled: bool) -> String:
	match terminal_type:
		"tram":
			return "Tranvía: viajar al otro extremo" if enabled else ""
		"mines":
			return "Bajar a Minas" if enabled else "Ascensor: requiere energía del guardián"
		"factory":
			return "Entrar a Fábrica Omega" if enabled else "Fábrica: acceso sin energía"
		"return":
			return "Regresar a Estación G-7"
	return ""


func _draw() -> void:
	match terminal_type:
		"tram":
			_draw_tram_terminal()
		"mines":
			_draw_gateway_terminal("MINAS ↓")
		"factory":
			_draw_gateway_terminal("FÁBRICA →")
		"return":
			_draw_gateway_terminal("REGRESAR")


func _draw_tram_terminal() -> void:
	var cyan := Color("3ce9ff")
	var inactive := Color("445463")
	var active := Color("65e7ca")
	var frame := Color("1d5876")
	var pulse := 0.70 + sin(tick * 4.0) * 0.20
	var status := active if enabled_visual else inactive

	# Floor pedestal.
	draw_rect(Rect2(-48.0, -52.0, 96.0, 52.0), Color("0b2238"))
	draw_rect(Rect2(-48.0, -52.0, 96.0, 52.0), frame, false, 3.0)
	draw_rect(Rect2(-40.0, -46.0, 80.0, 5.0), cyan)
	draw_rect(Rect2(-35.0, -34.0, 70.0, 22.0), Color("0d3048"))
	draw_rect(Rect2(-35.0, -34.0, 70.0, 22.0), status, false, 2.0)

	# Holographic tower.
	draw_rect(Rect2(-27.0, -106.0, 54.0, 55.0), Color(0.02, 0.11, 0.19, 0.82))
	draw_rect(Rect2(-27.0, -106.0, 54.0, 55.0), Color(cyan.r, cyan.g, cyan.b, pulse), false, 2.0)
	draw_circle(Vector2(0.0, -79.0), 12.0, status)
	draw_circle(Vector2(0.0, -79.0), 5.0, Color("0b2238"))
	draw_line(Vector2(-5.0, -79.0), Vector2(5.0, -79.0), cyan, 2.0)

	_label("TRANVÍA G-7", Vector2(-51.0, -121.0), 14, cyan)
	_label("ONLINE" if enabled_visual else "SIN ENERGÍA", Vector2(-37.0, -17.0), 10, status)


func _draw_gateway_terminal(title: String) -> void:
	var cyan := Color("3ce9ff")
	var frame := Color("1d5876")
	var status := cyan if enabled_visual else Color("744953")
	var pulse := 0.65 + sin(tick * 3.0) * 0.18

	draw_rect(Rect2(-47.0, -104.0, 94.0, 104.0), Color("091a2b"))
	draw_rect(Rect2(-47.0, -104.0, 94.0, 104.0), frame, false, 3.0)
	draw_rect(Rect2(-40.0, -96.0, 80.0, 7.0), Color(status.r, status.g, status.b, pulse))
	draw_rect(Rect2(-31.0, -77.0, 62.0, 55.0), Color("0c2a40"))
	draw_rect(Rect2(-31.0, -77.0, 62.0, 55.0), status, false, 2.0)

	for y in [-64.0, -50.0, -36.0]:
		draw_line(Vector2(-14.0, y), Vector2(14.0, y), status, 2.0)

	_label(title, Vector2(-46.0, -118.0), 14, cyan)


func _label(value: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(
		ThemeDB.fallback_font,
		pos,
		value,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		color
	)
