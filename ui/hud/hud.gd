extends Node2D

const WORLD_END := 8600.0
const CYAN := Color("3ce9ff")
const ORANGE := Color("ff9940")
const BUILD_LABEL := "0.3.0 · G7"
var game: Node

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if game == null or game.player == null:
		return
	var progress_x := game.station_player_x()
	draw_rect(Rect2(24, 91, 235, 5), Color("264465"))
	draw_rect(Rect2(24, 91, 235.0 * clampf(progress_x / WORLD_END, 0.0, 1.0), 5), CYAN)
	label("RECORRIDO %d%%" % int(progress_x / WORLD_END * 100.0), Vector2(24, 115), 14, CYAN)
	if game.save_notice_timer > 0.0:
		label(game.save_notice, Vector2(720, 112), 17, Color("53ff98"))
	draw_rect(Rect2(12, 12, 322, 68), Color("0b2244"))
	label("ESTACIÓN G-7" if game.room_name == "" else game.room_name.to_upper(), Vector2(23, 38), 18, CYAN)
	for i in range(game.player.max_health):
		draw_rect(Rect2(24 + i * 20, 52, 14, 16), ORANGE if i < game.player.health else Color("324865"))
	label("ENERGÍA: %d" % game.score, Vector2(195, 68), 16, Color.WHITE)
	var icon := Vector2(360, 65)
	draw_circle(icon, 15, Color("16385a"))
	draw_arc(icon, 15, 0, TAU, 24, Color("506887"), 3)
	if game.player.dash_unlocked:
		var charge := clampf(1.0 - game.player.dash_cooldown / 1.5, 0.0, 1.0)
		if charge > 0.0:
			draw_arc(icon, 15, -PI / 2.0, -PI / 2.0 + TAU * charge, 24, Color("53ff98"), 4)
	label("D", icon + Vector2(-6, 6), 17, Color("53ff98") if game.player.dash_unlocked else Color("506887"))
	for i in range(2):
		draw_circle(Vector2(872.0 + float(i) * 17.0, 65.0), 5.0, CYAN if game.player.jumps_used <= i else Color("3b5471"))
	label("2× SALTO", Vector2(845, 88), 13, CYAN)
	label("NEON CAT  ·  " + BUILD_LABEL, Vector2(350, 32), 15, Color("bbdfff"))
	if game.unlock_timer > 0.0:
		label("¡DASH DESBLOQUEADO! Cruza la compuerta violeta", Vector2(280, 106), 21, CYAN)
	elif not game.player.dash_unlocked:
		label("Regresa luego por el ítem verde · Derrota al guardián", Vector2(390, 61), 16, ORANGE)
	else:
		label("DASH listo" if game.player.dash_cooldown <= 0.0 else "DASH recargando", Vector2(530, 61), 17, CYAN)
	if game.player.dash_unlocked and not game.secret_collected() and progress_x > 1350.0:
		label("Tranvía activo: vuelve por el ítem verde", Vector2(305, 104), 17, Color("53ff98"))
	var prompt := game.interaction_name()
	if prompt != "":
		label(prompt, Vector2(340, 397), 17, CYAN)

func label(value: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
