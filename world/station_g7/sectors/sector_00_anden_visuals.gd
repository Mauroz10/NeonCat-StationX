extends Node2D

const CYAN := Color("3ce9ff")
const CYAN_DIM := Color("167fa1")
const BLUE := Color("1779df")
const STEEL := Color("0f2d4f")
const STEEL_2 := Color("173f63")
const STEEL_3 := Color("1c5475")
const ORANGE := Color("ffb22f")
const RED := Color("ff3f5f")
const WHITE := Color("d9f7ff")
const MAGENTA := Color("d94be8")

var tick := 0.0


func _process(delta: float) -> void:
	tick += delta
	queue_redraw()


func _draw() -> void:
	_draw_station_shell()
	_draw_background_train()
	_draw_overhead_infrastructure()
	_draw_sector_sign()
	_draw_tram_bay()
	_draw_dash_return_chamber()
	_draw_floor_rail()
	_draw_warning_lights()


func _draw_station_shell() -> void:
	draw_rect(
		Rect2(-40.0, 150.0, 1110.0, 304.0),
		Color(0.025, 0.08, 0.17, 0.96)
	)

	for x in [30.0, 255.0, 505.0, 760.0, 1010.0]:
		draw_rect(Rect2(x, 172.0, 24.0, 282.0), Color("09172b"))
		draw_rect(Rect2(x + 5.0, 176.0, 5.0, 270.0), STEEL_3)
		draw_rect(Rect2(x + 15.0, 176.0, 4.0, 270.0), Color("07101f"))

		for y in range(195, 440, 44):
			draw_rect(Rect2(x - 3.0, float(y), 30.0, 5.0), STEEL_2)

	draw_rect(Rect2(-20.0, 154.0, 1090.0, 24.0), Color("081a31"))
	draw_rect(Rect2(-20.0, 174.0, 1090.0, 4.0), CYAN_DIM)


func _draw_background_train() -> void:
	var body := Rect2(55.0, 314.0, 920.0, 105.0)
	draw_rect(body, Color("112943"))
	draw_rect(Rect2(body.position.x, body.position.y, body.size.x, 7.0), Color("1b4268"))
	draw_rect(Rect2(body.position.x, body.end.y - 13.0, body.size.x, 5.0), CYAN_DIM)

	for car in range(4):
		var car_x := 72.0 + float(car) * 224.0
		draw_rect(Rect2(car_x, 328.0, 204.0, 76.0), Color("173757"))
		draw_rect(Rect2(car_x, 328.0, 204.0, 76.0), Color("275779"), false, 2.0)
		draw_rect(Rect2(car_x + 14.0, 340.0, 64.0, 31.0), Color("183e61"))
		draw_rect(Rect2(car_x + 87.0, 340.0, 42.0, 51.0), Color("0c213a"))
		draw_rect(Rect2(car_x + 138.0, 340.0, 51.0, 31.0), Color("183e61"))
		draw_rect(Rect2(car_x + 15.0, 378.0, 60.0, 5.0), ORANGE)
		draw_rect(Rect2(car_x + 140.0, 378.0, 45.0, 5.0), ORANGE)
		_label("G-7", Vector2(car_x + 14.0, 399.0), 14, Color("5faed0"))

	for x in range(105, 950, 190):
		draw_circle(Vector2(float(x), 421.0), 10.0, Color("06101f"))
		draw_circle(Vector2(float(x), 421.0), 5.0, Color("173f63"))


func _draw_overhead_infrastructure() -> void:
	for x in range(80, 980, 170):
		draw_line(Vector2(float(x), 180.0), Vector2(float(x) + 54.0, 236.0), STEEL_2, 5.0)
		draw_line(Vector2(float(x) + 54.0, 180.0), Vector2(float(x), 236.0), STEEL_2, 5.0)

	draw_rect(Rect2(90.0, 232.0, 830.0, 8.0), Color("0a2039"))
	draw_rect(Rect2(100.0, 236.0, 810.0, 3.0), CYAN_DIM)

	for x in [118.0, 356.0, 844.0]:
		draw_rect(Rect2(x, 182.0, 7.0, 62.0), Color("0b243e"))
		draw_rect(Rect2(x + 7.0, 184.0, 4.0, 58.0), BLUE)


func _draw_sector_sign() -> void:
	var sign := Rect2(58.0, 190.0, 318.0, 52.0)
	draw_rect(sign, Color("0b2848"))
	draw_rect(sign, CYAN_DIM, false, 2.0)
	draw_rect(Rect2(sign.position.x, sign.position.y, 9.0, sign.size.y), BLUE)
	draw_rect(Rect2(sign.position.x + 10.0, sign.position.y + 5.0, sign.size.x - 20.0, 3.0), CYAN_DIM)
	_label("SECTOR 01 · ANDÉN", Vector2(83.0, 222.0), 20, CYAN)
	_label("ESTACIÓN G-7", Vector2(83.0, 239.0), 11, Color("67a8c8"))


func _draw_tram_bay() -> void:
	var bay := Rect2(118.0, 264.0, 132.0, 172.0)
	draw_rect(bay, Color(0.03, 0.09, 0.16, 0.88))
	draw_rect(bay, STEEL_3, false, 3.0)
	draw_rect(Rect2(122.0, 268.0, 124.0, 5.0), CYAN)
	draw_rect(Rect2(128.0, 404.0, 112.0, 20.0), Color("0b263f"))
	draw_rect(Rect2(128.0, 404.0, 112.0, 20.0), CYAN_DIM, false, 2.0)
	_label("TRANVÍA G-7", Vector2(137.0, 292.0), 15, CYAN)
	_label("RUTA INTERNA", Vector2(137.0, 309.0), 10, Color("7aa9bf"))


func _draw_dash_return_chamber() -> void:
	# This opaque header intentionally covers the older backdrop label so the
	# Sector 00 presentation has a single, integrated sign.
	draw_rect(Rect2(476.0, 194.0, 234.0, 55.0), Color("07182c"))

	var chamber := Rect2(493.0, 220.0, 200.0, 201.0)
	draw_rect(chamber, Color(0.025, 0.065, 0.13, 0.90))
	draw_rect(chamber, STEEL_3, false, 5.0)
	draw_rect(Rect2(493.0, 220.0, 200.0, 26.0), Color("0c2d4a"))
	draw_rect(Rect2(493.0, 244.0, 200.0, 3.0), CYAN_DIM)
	_label("ACCESO DE RETORNO", Vector2(517.0, 239.0), 13, CYAN)

	for y in range(258, 390, 32):
		draw_rect(Rect2(497.0, float(y), 8.0, 18.0), ORANGE)
		draw_rect(Rect2(681.0, float(y), 8.0, 18.0), ORANGE)

	var pulse := 0.55 + sin(tick * 3.0) * 0.2
	draw_rect(Rect2(526.0, 258.0, 134.0, 33.0), Color(0.05, 0.25, 0.38, 0.88))
	draw_rect(
		Rect2(526.0, 258.0, 134.0, 33.0),
		Color(CYAN.r, CYAN.g, CYAN.b, pulse),
		false,
		2.0
	)
	_label("VUELVE CON DASH", Vector2(535.0, 280.0), 13, WHITE)

	draw_line(Vector2(545.0, 372.0), Vector2(641.0, 372.0), MAGENTA, 2.0)
	draw_line(Vector2(558.0, 379.0), Vector2(628.0, 379.0), CYAN_DIM, 2.0)


func _draw_floor_rail() -> void:
	draw_rect(Rect2(-20.0, 426.0, 1080.0, 8.0), Color("0a1c31"))
	draw_rect(Rect2(-20.0, 426.0, 1080.0, 3.0), CYAN_DIM)

	for x in range(20, 1040, 84):
		draw_rect(Rect2(float(x), 434.0, 54.0, 4.0), Color("164565"))


func _draw_warning_lights() -> void:
	for x in [92.0, 328.0, 742.0, 920.0]:
		var glow := 0.65 + sin(tick * 4.0 + x * 0.01) * 0.25
		draw_rect(Rect2(x, 250.0, 10.0, 18.0), Color("27151f"))
		draw_rect(Rect2(x + 2.0, 253.0, 6.0, 7.0), Color(RED.r, RED.g, RED.b, glow))

	for x in [272.0, 390.0, 708.0, 820.0]:
		draw_rect(Rect2(x, 288.0, 62.0, 4.0), CYAN)


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
