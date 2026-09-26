extends Node2D

const WORLD_END := 8600.0
const FLOOR_Y := 454.0
const CYAN := Color("3ce9ff")
const BLUE := Color("1779df")
const ORANGE := Color("ff9940")
var tick := 0.0

func _process(delta: float) -> void:
	tick += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, WORLD_END, 540), Color("071531"))
	_draw_parallax()
	_draw_sector_details()
	_draw_navigation_details()
	_draw_boss_blast()

func _draw_parallax() -> void:
	var player := get_tree().get_first_node_in_group("player") as NeonPlayer
	var camera_x := 0.0
	if player != null:
		camera_x = clampf(player.global_position.x - 960.0 * 0.39, 0.0, WORLD_END - 960.0)
	for i in range(36):
		var star_screen_x := fposmod(float(i * 151 + 67) - camera_x * 0.2, 960.0)
		var star_y := float((i * 73 + 43) % 385)
		draw_circle(Vector2(camera_x + star_screen_x, star_y), 1.2, Color("3879ba"))
	for i in range(58):
		var bx := camera_x + float(i * 135) - camera_x * 0.4
		draw_rect(Rect2(bx, 230 + (i * 37) % 120, 105, 210), Color("0b2550"))
		for j in range(3):
			draw_rect(Rect2(bx + 12 + j * 29, 350, 9, 5), Color("114c80"))

func _draw_sector_details() -> void:
	for x in range(80, 2100, 390):
		draw_rect(Rect2(x, 245, 260, 120), Color("102d51"))
		for pane in range(4):
			draw_rect(Rect2(x + 12 + pane * 61, 255, 48, 70), Color("164568"))
		draw_line(Vector2(x, 372), Vector2(x + 280, 372), Color("27648a"), 3)
	for x in range(2230, 4030, 310):
		draw_rect(Rect2(x, 250, 70, 140), Color("133d45"))
		draw_rect(Rect2(x + 14, 275 + sin(tick * 2.0 + x) * 22.0, 42, 32), Color("296578"))
		draw_line(Vector2(x + 85, 210), Vector2(x + 85, 370), Color("32797b"), 4)
	for x in range(4160, 5850, 360):
		draw_rect(Rect2(x, 235, 105, 190), Color("231d44"))
		draw_circle(Vector2(x + 52, 308), 41, Color("49305d"))
		draw_arc(Vector2(x + 52, 308), 34, tick, tick + 5.0, 30, Color("b55ada"), 4)
		draw_line(Vector2(x + 15, 399), Vector2(x + 85, 399), Color("da65ca"), 3)
	for x in range(6010, 6800, 160):
		draw_line(Vector2(x, 220), Vector2(x, 400), Color("512b42"), 10)
	for x in range(7210, 8500, 260):
		draw_rect(Rect2(x, 230, 150, 155), Color("10384a"))
		for i in range(5):
			draw_line(Vector2(x + 12, 245 + i * 27), Vector2(x + 138, 245 + i * 27), Color("266b75"), 3)
	for room in [Rect2(2920, 154, 290, 82), Rect2(4650, 164, 270, 82)]:
		draw_rect(room, Color("102e43"))
		draw_rect(room, Color("42868b"), false, 2)
	_label("ALMACÉN SUPERIOR", Vector2(2934, 177), 13, CYAN)
	_label("CÁMARA DE RESERVA", Vector2(4660, 187), 13, CYAN)
	for sector in [
		{"start": 0.0, "end": 2150.0, "name": "01 · ANDÉN", "color": Color("153768")},
		{"start": 2150.0, "end": 4100.0, "name": "02 · TALLERES", "color": Color("124954")},
		{"start": 4100.0, "end": 5950.0, "name": "03 · REACTORES", "color": Color("49305d")},
		{"start": 5950.0, "end": 7050.0, "name": "04 · GUARDIÁN G-7", "color": Color("583247")},
		{"start": 7050.0, "end": WORLD_END, "name": "05 · SALIDA", "color": Color("184e62")}
	]:
		draw_rect(Rect2(sector.start, 159, sector.end - sector.start, 3), sector.color)
		draw_rect(Rect2(sector.start + 48.0, 190, 245, 38), sector.color)
		_label(sector.name, Vector2(sector.start + 58.0, 217), 19, CYAN)

func _draw_navigation_details() -> void:
	for gap in [Vector2(2510, 2650), Vector2(3900, 4050), Vector2(5460, 5610)]:
		draw_rect(Rect2(gap.x - 90.0, FLOOR_Y - 7.0, 68.0, 7.0), ORANGE)
		draw_rect(Rect2(gap.y + 22.0, FLOOR_Y - 7.0, 68.0, 7.0), ORANGE)
		_label("SALTA", Vector2(gap.x - 98.0, FLOOR_Y - 20.0), 15, ORANGE)
	for x in [290, 960, 1440, 2030, 2800, 3030, 3480, 4230, 4750, 5150, 5700, 6090, 6650, 7450, 8030]:
		draw_rect(Rect2(x, FLOOR_Y - 118, 12, 118), Color("20447c"))
		draw_rect(Rect2(x - 12, FLOOR_Y - 120, 35, 7), CYAN)
		draw_circle(Vector2(x + 6, FLOOR_Y - 155), 14, Color("1cc7ee"))
	var station := get_parent() as StationG7
	for marker_x in [1250.0, 1940.0, 3450.0, 5100.0, 5900.0, 6550.0, 7350.0]:
		var active := station != null and station.current_checkpoint.x >= marker_x
		draw_rect(Rect2(marker_x - 5.0, FLOOR_Y - 76.0, 10.0, 76.0), Color("257e8e"))
		draw_circle(Vector2(marker_x, FLOOR_Y - 82.0), 14.0, Color("53ff98") if active else Color("426582"))
		_label("CP", Vector2(marker_x - 13.0, FLOOR_Y - 104.0), 14, Color("53ff98") if active else CYAN)
	draw_rect(Rect2(6988, FLOOR_Y - 117, 40, 10), Color("bd55ef"))
	_label("VUELVE CON DASH", Vector2(512, 207), 15, CYAN)
	_label("DASH →", Vector2(6904, FLOOR_Y - 130), 18, CYAN)
	draw_rect(Rect2(8340, FLOOR_Y - 85, 25, 85), Color("278cba"))
	draw_circle(Vector2(8352, FLOOR_Y - 94), 18, CYAN)
	_label("SALIDA", Vector2(8302, FLOOR_Y - 126), 18, CYAN)

func _draw_boss_blast() -> void:
	var station := get_parent() as StationG7
	if station == null or station.boss_blast <= 0.0:
		return
	for i in range(16):
		var angle := float(i) / 16.0 * TAU
		var radius := (1.5 - station.boss_blast) * 110.0
		draw_circle(Vector2(6250, 405) + Vector2(cos(angle), sin(angle)) * radius, 4.0 + station.boss_blast * 3.0, Color(1.0, 0.6, 0.2, station.boss_blast / 1.5))

func _label(value: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
