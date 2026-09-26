extends Node2D

const CYAN := Color("3ce9ff")
var game: Node
var touch_points: Dictionary = {}
var point_actions: Dictionary = {}

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if game == null or game.ui_paused:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_assign_point(event.index, event.position)
		else:
			_release_point(event.index)
	elif event is InputEventScreenDrag:
		var p := _logical_position(event.position)
		var current_action := str(point_actions.get(event.index, ""))
		var next_action := _button_action(p)
		if current_action != "" and current_action == next_action:
			touch_points[event.index] = p
			return
		_release_point(event.index)
		_assign_point(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_assign_point(-1, event.position)
		else:
			_release_point(-1)

func _logical_position(position: Vector2) -> Vector2:
	var viewport_size := get_viewport_rect().size
	return Vector2(position.x * 960.0 / viewport_size.x, position.y * 540.0 / viewport_size.y)

func _assign_point(index: int, position: Vector2) -> void:
	var p := _logical_position(position)
	if Rect2(750, 122, 86, 36).has_point(p):
		game.set_pause(true, true)
		return
	if Rect2(846, 122, 94, 36).has_point(p):
		game.set_pause(true, false)
		return
	var action := _button_action(p)
	if action == "interact":
		touch_points[index] = p
		point_actions[index] = action
		game.use_interaction()
		return
	if action != "":
		touch_points[index] = p
		point_actions[index] = action
		Input.action_press(action)

func _release_point(index: int) -> void:
	if point_actions.has(index):
		Input.action_release(str(point_actions[index]))
	point_actions.erase(index)
	touch_points.erase(index)

func reset_inputs() -> void:
	for action in point_actions.values():
		Input.action_release(str(action))
	point_actions.clear()
	touch_points.clear()

func _button_action(p: Vector2) -> String:
	if p.y <= 440.0:
		return ""
	if p.x < 118.0: return "move_left"
	if p.x < 240.0: return "move_right"
	if p.x > 820.0: return "fire"
	if p.x > 695.0: return "jump"
	if p.x > 570.0: return "dash"
	if p.x > 375.0 and p.x < 560.0 and game.interaction_name() != "": return "interact"
	return ""

func _draw() -> void:
	if game == null:
		return
	panel_button(Rect2(750, 122, 86, 36), "MAPA")
	panel_button(Rect2(846, 122, 94, 36), "PAUSA")
	button(Vector2(62, 487), "◀", Input.is_action_pressed("move_left"))
	button(Vector2(178, 487), "▶", Input.is_action_pressed("move_right"))
	button(Vector2(631, 487), "DASH" if game.player != null and game.player.dash_unlocked else "BLOQ.", Input.is_action_pressed("dash"))
	button(Vector2(758, 487), "SALTO", Input.is_action_pressed("jump"))
	button(Vector2(887, 487), "FUEGO", Input.is_action_pressed("fire"))
	if game.interaction_name() != "":
		button(Vector2(475, 487), "USAR", false)

func button(center: Vector2, name: String, active: bool) -> void:
	draw_circle(center, 40, Color("1c7199") if active else Color("122e59"))
	draw_arc(center, 40, 0, TAU, 36, CYAN if active else Color("398cbd"), 3)
	draw_string(ThemeDB.fallback_font, center + Vector2(-name.length() * 5, 6), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

func panel_button(rect: Rect2, text: String) -> void:
	draw_rect(rect, Color("16394b"))
	draw_rect(rect, CYAN, false, 1.5)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 24), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, CYAN)
