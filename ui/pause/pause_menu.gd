extends Node2D

const CYAN := Color("60ecd8")
var game: Node
var confirm_restart := false

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if game == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("pause"):
			game.set_pause(not game.ui_paused, false)
			confirm_restart = false
		elif event.is_action_pressed("open_map"):
			game.set_pause(not (game.ui_paused and game.map_open), true)
			confirm_restart = false
	if not game.ui_paused or game.map_open:
		return
	var pressed := false
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch:
		pressed = event.pressed
		pos = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		pos = event.position
	if not pressed:
		return
	if Rect2(310, 180, 340, 46).has_point(pos):
		game.set_pause(false)
	elif Rect2(310, 240, 340, 46).has_point(pos):
		game.set_pause(true, true)
	elif Rect2(310, 300, 340, 46).has_point(pos):
		game.audio_enabled = not game.audio_enabled
		game.save_progress()
	elif Rect2(310, 360, 340, 46).has_point(pos):
		if confirm_restart:
			game.start_new_game()
			game.set_pause(false)
			confirm_restart = false
		else:
			confirm_restart = true

func _draw() -> void:
	if game == null or not game.ui_paused or game.map_open:
		return
	draw_rect(Rect2(0, 0, 960, 540), Color(0.015, 0.035, 0.08, 0.97))
	caption("PAUSA", Vector2(65, 101), 29, CYAN)
	panel_button(Rect2(310, 180, 340, 46), "CONTINUAR")
	panel_button(Rect2(310, 240, 340, 46), "VER MAPA")
	panel_button(Rect2(310, 300, 340, 46), "SONIDO: " + ("ACTIVO" if game.audio_enabled else "APAGADO"))
	panel_button(Rect2(310, 360, 340, 46), "CONFIRMAR: BORRAR PARTIDA" if confirm_restart else "EMPEZAR DE NUEVO")
	caption("A/D: mover   Espacio: doble salto   J: disparar   Shift: dash", Vector2(165, 451), 17)
	caption("E: usar terminal   M: mapa   P/Esc: pausa", Vector2(265, 481), 17)

func panel_button(rect: Rect2, text: String) -> void:
	draw_rect(rect, Color("16394b"))
	draw_rect(rect, CYAN, false, 1.5)
	caption(text, rect.position + Vector2(13, rect.size.y * 0.5 + 6), 17, CYAN)

func caption(value: String, pos: Vector2, size: int = 18, color: Color = Color.WHITE) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
