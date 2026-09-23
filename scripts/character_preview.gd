extends Node2D

const W := 960.0
const H := 540.0
const FLOOR_Y := 454.0
const DARK := Color("071531")
const CYAN := Color("3ce9ff")
const BLUE := Color("1779df")
const ORANGE := Color("ff9940")
const PREVIEW_REGION := Rect2i(135, 80, 984, 1095)
const PREVIEW_HEIGHTS := [48.0, 55.0, 64.0]
const PREVIEW_POINTS := [
	Vector2(230.0, FLOOR_Y),
	Vector2(380.0, FLOOR_Y),
	Vector2(545.0, FLOOR_Y)
]

func _ready() -> void:
	var image := Image.load_from_file("res://assets/astro_gato_clean.png")
	var texture := ImageTexture.create_from_image(image)
	for i in range(PREVIEW_HEIGHTS.size()):
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.region_enabled = true
		sprite.region_rect = PREVIEW_REGION
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE * (PREVIEW_HEIGHTS[i] / float(PREVIEW_REGION.size.y))
		sprite.position = Vector2(
			PREVIEW_POINTS[i].x - float(PREVIEW_REGION.size.x) * sprite.scale.x * 0.5,
			PREVIEW_POINTS[i].y - float(PREVIEW_REGION.size.y) * sprite.scale.y
		)
		sprite.z_index = 5
		add_child(sprite)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), DARK)
	for i in range(36):
		var star_x := fposmod(float(i * 151 + 67), W)
		var star_y := float((i * 73 + 43) % 385)
		draw_circle(Vector2(star_x, star_y), 1.2, Color("3879ba"))
	for i in range(8):
		var bx := float(i * 135)
		draw_rect(Rect2(bx, 230 + (i * 37) % 120, 105, 210), Color("0b2550"))
		for j in range(3):
			draw_rect(Rect2(bx + 12 + j * 29, 350, 9, 5), Color("114c80"))
	draw_rect(Rect2(0, FLOOR_Y, W, 86), Color("102854"))
	draw_rect(Rect2(0, FLOOR_Y, W, 7), BLUE)
	for i in range(int(W / 29.0) + 1):
		draw_rect(Rect2(float(i * 29), FLOOR_Y + 26, 15, 5), Color("194a80"))
	var platforms := [Rect2(350, 372, 140, 18), Rect2(525, 310, 135, 16), Rect2(695, 337, 150, 18)]
	for platform in platforms:
		draw_rect(platform, Color("173665"))
		draw_rect(Rect2(platform.position.x, platform.position.y, platform.size.x, 5), CYAN)
	for x in [290, 760]:
		draw_rect(Rect2(x, FLOOR_Y - 118, 12, 118), Color("20447c"))
		draw_rect(Rect2(x - 12, FLOOR_Y - 120, 35, 7), CYAN)
		draw_circle(Vector2(x + 6, FLOOR_Y - 155), 14, Color("1cc7ee"))
	draw_rect(Rect2(465 - 18, FLOOR_Y - 35, 36, 34), Color("38517e"))
	draw_rect(Rect2(465 - 13, FLOOR_Y - 30, 26, 19), Color("208baf"))
	draw_rect(Rect2(465 - 9, FLOOR_Y - 24, 18, 6), ORANGE)
	draw_rect(Rect2(14, 12, 330, 68), Color("0b2244"))
	label("ESTACION G-7  ·  PRUEBA VISUAL", Vector2(25, 39), 19, CYAN)
	for i in range(5):
		draw_rect(Rect2(26 + i * 29, 52, 21, 16), ORANGE)
	draw_rect(Rect2(170, 122, 500, 68), Color(0.02, 0.05, 0.12, 0.84))
	label("PRUEBA DE TAMANO DEL NUEVO ASTRO-GATO", Vector2(190, 150), 22, CYAN)
	label("Vista horizontal Android 960x540", Vector2(190, 177), 16, Color.WHITE)
	label("48 px", Vector2(203, FLOOR_Y + 35), 16, Color.WHITE)
	label("55 px  RECOMENDADO", Vector2(303, FLOOR_Y + 35), 16, Color("53ff98"))
	label("64 px", Vector2(520, FLOOR_Y + 35), 16, Color.WHITE)

func label(value: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
