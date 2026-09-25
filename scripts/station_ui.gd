extends Node2D

var game: Node2D
var confirm_restart := false
const CYAN := Color("60ecd8")
const MAP_BUTTON := Rect2(750, 122, 86, 36)
const PAUSE_BUTTON := Rect2(846, 122, 94, 36)

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			game.set_pause(not game.ui_paused)
			confirm_restart = false
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M:
			game.set_pause(not (game.ui_paused and game.map_open), true)
			confirm_restart = false
			get_viewport().set_input_as_handled()
	var pressed: bool = false
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch:
		pressed = event.pressed
		pos = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		pos = event.position
	if not pressed: return
	if game.ui_paused:
		get_viewport().set_input_as_handled()
		if Rect2(770, 70, 130, 42).has_point(pos):
			game.set_pause(false)
			confirm_restart = false
		elif not game.map_open:
			if Rect2(310, 180, 340, 46).has_point(pos): game.set_pause(false)
			elif Rect2(310, 240, 340, 46).has_point(pos): game.map_open = true
			elif Rect2(310, 300, 340, 46).has_point(pos):
				game.audio_enabled = not game.audio_enabled
				game.save_progress()
			elif Rect2(310, 360, 340, 46).has_point(pos):
				if confirm_restart:
					game.start_new_game()
					game.set_pause(false)
					confirm_restart = false
				else: confirm_restart = true
		return
	if MAP_BUTTON.has_point(pos):
		game.set_pause(true, true)
		get_viewport().set_input_as_handled()
	elif PAUSE_BUTTON.has_point(pos):
		game.set_pause(true)
		get_viewport().set_input_as_handled()

func caption(value: String, pos: Vector2, size: int = 18, color: Color = Color.WHITE) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func panel_button(rect: Rect2, text: String) -> void:
	draw_rect(rect, Color("16394b"))
	draw_rect(rect, CYAN, false, 1.5)
	caption(text, rect.position + Vector2(13, rect.size.y * 0.5 + 6), 17, CYAN)

func _draw() -> void:
	panel_button(MAP_BUTTON, "MAPA")
	panel_button(PAUSE_BUTTON, "PAUSA")
	if not game.ui_paused: return
	draw_rect(Rect2(0, 0, 960, 540), Color(0.015, 0.035, 0.08, 0.97))
	panel_button(Rect2(770, 70, 130, 42), "VOLVER")
	caption("MAPA · ESTACIÓN G-7" if game.map_open else "PAUSA", Vector2(65, 101), 29, CYAN)
	if game.map_open:
		draw_map()
		return
	panel_button(Rect2(310, 180, 340, 46), "CONTINUAR")
	panel_button(Rect2(310, 240, 340, 46), "VER MAPA")
	panel_button(Rect2(310, 300, 340, 46), "SONIDO: " + ("ACTIVO" if game.audio_enabled else "APAGADO"))
	panel_button(Rect2(310, 360, 340, 46), "CONFIRMAR: BORRAR PARTIDA" if confirm_restart else "EMPEZAR DE NUEVO")
	caption("A/D: mover   Espacio: doble salto   J: disparar   Shift: dash", Vector2(165, 451), 17)
	caption("E: usar terminal   M: mapa   P/Esc: pausa", Vector2(265, 481), 17)

func draw_map() -> void:
	var labels: Array[String] = ["ANDÉN", "ACCESO", "TALLER", "ALMACÉN", "POZOS", "REACTOR", "SENTINEL", "DASH", "OMEGA"]
	for i in range(9):
		var x: float = 62.0 + float(i) * 92.0
		var explored: bool = game.visited.has(i)
		draw_rect(Rect2(x, 267, 84, 58), Color("245d64") if explored else Color("182534"))
		draw_rect(Rect2(x, 267, 84, 58), CYAN if explored else Color("4e5e71"), false, 1.5)
		caption(labels[i] if explored else "?", Vector2(x + 5, 301), 13, CYAN if explored else Color("738397"))
		if i < 8: draw_line(Vector2(x + 84, 294), Vector2(x + 92, 294), Color("6d94a3"), 3)
	if game.visited.has(0):
		draw_line(Vector2(104, 230), Vector2(104, 267), CYAN, 2)
		draw_rect(Rect2(65, 187, 110, 43), Color("285651"))
		caption("VIDA ✓" if game.secret_collected else "CON DASH", Vector2(72, 215), 14, CYAN)
	for cp in [1250.0, 1940.0, 3450.0, 5100.0, 5900.0, 6550.0, 7350.0]:
		if game.visited.has(int(cp / 960.0)):
			var cx: float = 62.0 + cp / 8600.0 * 820.0
			draw_rect(Rect2(cx - 3, 314, 6, 6), Color("7cffb7") if game.checkpoint.x >= cp else Color("607488"))
	# Los caminos superiores solo se revelan al visitar sus sectores.
	for branch in [{"cell": 3, "x": 335.0, "id": "workshop"}, {"cell": 4, "x": 465.0, "id": "reactor"}]:
		if game.visited.has(branch.cell):
			draw_line(Vector2(branch.x + 38.0, 230), Vector2(branch.x + 38.0, 267), CYAN, 2)
			draw_rect(Rect2(branch.x, 187, 116, 43), Color("285651"))
			caption("VIDA ✓" if game.route_rewards.has(branch.id) else "RUTA ALTA", Vector2(branch.x + 7.0, 215), 14, CYAN)
	if game.visited.has(1):
		draw_line(Vector2(199, 325), Vector2(199, 371), CYAN, 2)
		caption("↓ MINAS", Vector2(167, 395), 15, CYAN)
	if game.boss_defeated:
		draw_line(Vector2(80, 349), Vector2(700, 349), Color("f5c779"), 2)
		caption("TRANVÍA ACTIVO", Vector2(420, 372), 15, Color("f5c779"))
	var station_x: float = float(game.player.x)
	if game.room_name != "": station_x = float(game.station_snapshot.player.x)
	var marker: float = 62.0 + clampf(station_x / 8600.0, 0.0, 1.0) * 820.0
	draw_circle(Vector2(marker, 251), 7, Color("ffcb68"))
	caption("TÚ", Vector2(marker - 11, 241), 13, Color("ffcb68"))
	caption("Descubierto: %d/9  ·  Secretos: %d/3" % [game.visited.size(), game.route_rewards.size() + int(game.secret_collected)], Vector2(65, 447), 20, CYAN)
	caption("G-7 completada · accesos habilitados" if game.station_complete else ("Cruza la compuerta con dash" if game.boss_defeated else "Objetivo: derrotar a Sentinel-G7"), Vector2(65, 481), 18)
