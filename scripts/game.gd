extends Node2D
## Prototipo autocontenido: un nivel, controles táctiles y dibujos originales.

const W := 960.0
const H := 540.0
const WORLD_END := 2500.0
const FLOOR_Y := 454.0
const MOVE_SPEED := 260.0
const GRAVITY := 1150.0
const JUMP_SPEED := -475.0
const CYAN := Color("3ce9ff")
const BLUE := Color("1779df")
const DARK := Color("071531")
const ORANGE := Color("ff9940")

var player := Vector2(88.0, FLOOR_Y - 17.0)
var velocity := Vector2.ZERO
var camera_x := 0.0
var facing := 1.0
var health := 5
var max_health := 5
var score := 0
var checkpoint := Vector2(88.0, FLOOR_Y - 17.0)
var won := false
var invulnerable := 0.0
var fire_timer := 0.0
var dash_timer := 0.0
var dash_cooldown := 0.0
var tick := 0.0
var touch := {"left": false, "right": false, "jump": false, "fire": false, "dash": false}
var touch_points: Dictionary = {}
var jump_requested := false
var dash_requested := false
var bullets: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var platforms := [Rect2(350, 372, 140, 18), Rect2(695, 337, 150, 18),
	Rect2(1100, 376, 155, 18), Rect2(1510, 348, 160, 18), Rect2(1870, 377, 145, 18)]

func _ready() -> void:
	reset_level()

func reset_level() -> void:
	player = Vector2(88, FLOOR_Y - 17)
	checkpoint = player
	velocity = Vector2.ZERO
	health = max_health
	score = 0
	won = false
	bullets.clear()
	enemies = [
		{"x": 465.0, "y": FLOOR_Y - 18.0, "hp": 2, "left": 385.0, "right": 620.0, "dir": 1.0},
		{"x": 840.0, "y": FLOOR_Y - 18.0, "hp": 2, "left": 785.0, "right": 1000.0, "dir": -1.0},
		{"x": 1230.0, "y": FLOOR_Y - 18.0, "hp": 3, "left": 1150.0, "right": 1410.0, "dir": 1.0},
		{"x": 1730.0, "y": FLOOR_Y - 18.0, "hp": 3, "left": 1630.0, "right": 1840.0, "dir": -1.0},
		{"x": 2190.0, "y": FLOOR_Y - 36.0, "hp": 12, "left": 2100.0, "right": 2295.0, "dir": -1.0, "boss": true}
	]
	pickups = [{"x": 410.0, "y": 340.0}, {"x": 755.0, "y": 305.0},
		{"x": 1160.0, "y": 345.0}, {"x": 1590.0, "y": 317.0},
		{"x": 1940.0, "y": 345.0}]
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_W or event.keycode == KEY_UP:
			jump_requested = true
		if event.keycode == KEY_SHIFT:
			dash_requested = true
		if event.keycode == KEY_R and won:
			reset_level()
	if event is InputEventScreenTouch:
		if event.pressed: touch_points[event.index] = event.position
		else: touch_points.erase(event.index)
		refresh_touch()
	if event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		refresh_touch()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: touch_points[-1] = event.position
		else: touch_points.erase(-1)
		refresh_touch()

func refresh_touch() -> void:
	var previous_jump: bool = touch.jump
	var previous_dash: bool = touch.dash
	for key in touch: touch[key] = false
	for pos in touch_points.values():
		var button := get_touch_button(pos)
		if button != "": touch[button] = true
	if touch.jump and not previous_jump: jump_requested = true
	if touch.dash and not previous_dash: dash_requested = true

func get_touch_button(pos: Vector2) -> String:
	var p := Vector2(pos.x * W / get_viewport_rect().size.x, pos.y * H / get_viewport_rect().size.y)
	if p.y > 400:
		if p.x < 118: return "left"
		if p.x < 240: return "right"
		if p.x > 820: return "fire"
		if p.x > 695: return "jump"
		if p.x > 570: return "dash"
	if won and p.x > 350 and p.x < 610 and p.y > 265: reset_level()
	return ""

func _physics_process(delta: float) -> void:
	tick += delta
	if won:
		queue_redraw()
		return
	invulnerable = maxf(0.0, invulnerable - delta)
	fire_timer = maxf(0.0, fire_timer - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	var direction := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or touch.left: direction -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or touch.right: direction += 1.0
	if direction != 0.0: facing = direction
	var was_on_ground := on_ground()
	if jump_requested and was_on_ground: velocity.y = JUMP_SPEED
	jump_requested = false
	if dash_requested and dash_cooldown <= 0.0:
		dash_timer = 0.17
		dash_cooldown = 1.5
	dash_requested = false
	velocity.x = facing * 650.0 if dash_timer > 0.0 else direction * MOVE_SPEED
	velocity.y += GRAVITY * delta
	var old_feet := player.y + 17.0
	player += velocity * delta
	player.x = clampf(player.x, 18.0, WORLD_END - 20.0)
	if player.y + 17.0 >= FLOOR_Y:
		player.y = FLOOR_Y - 17.0
		velocity.y = 0.0
	elif velocity.y >= 0.0:
		for platform in platforms:
			if player.x + 15.0 > platform.position.x and player.x - 15.0 < platform.end.x and old_feet <= platform.position.y + 5.0 and player.y + 17.0 >= platform.position.y:
				player.y = platform.position.y - 17.0
				velocity.y = 0.0
				break
	if (touch.fire or Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_Z)) and fire_timer <= 0.0:
		bullets.append({"pos": player + Vector2(facing * 22.0, -3.0), "dir": facing, "life": 1.3})
		fire_timer = 0.22
	for i in range(bullets.size() - 1, -1, -1):
		var bullet := bullets[i]
		bullet.pos.x += bullet.dir * 670.0 * delta
		bullet.life -= delta
		var hit := false
		for enemy in enemies:
			var radius := 37.0 if enemy.has("boss") else 21.0
			if absf(bullet.pos.x - enemy.x) < radius and absf(bullet.pos.y - enemy.y) < radius:
				enemy.hp -= 1
				hit = true
				break
		if hit or bullet.life <= 0.0: bullets.remove_at(i)
	for i in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[i]
		if enemy.hp <= 0:
			if enemy.has("boss"): won = true
			score += 100 if enemy.has("boss") else 20
			enemies.remove_at(i)
			continue
		enemy.x += enemy.dir * (75.0 if enemy.has("boss") else 95.0) * delta
		if enemy.x < enemy.left or enemy.x > enemy.right: enemy.dir *= -1.0
		var radius := 42.0 if enemy.has("boss") else 24.0
		if absf(player.x - enemy.x) < radius and absf(player.y - enemy.y) < 29.0 and invulnerable <= 0.0 and dash_timer <= 0.0:
			health -= 1
			invulnerable = 1.0
			velocity.y = -270.0
			if health <= 0: respawn()
	for i in range(pickups.size() - 1, -1, -1):
		if player.distance_to(Vector2(pickups[i].x, pickups[i].y)) < 29.0:
			score += 10
			pickups.remove_at(i)
	if player.x > 1200 and checkpoint.x < 1200: checkpoint = Vector2(1250, FLOOR_Y - 17)
	camera_x = clampf(player.x - W * 0.39, 0.0, WORLD_END - W)
	queue_redraw()

func on_ground() -> bool:
	if player.y + 17.0 >= FLOOR_Y - 1.0: return true
	for platform in platforms:
		if absf(player.y + 17.0 - platform.position.y) <= 2.0 and player.x + 15.0 > platform.position.x and player.x - 15.0 < platform.end.x: return true
	return false

func respawn() -> void:
	player = checkpoint
	health = max_health
	velocity = Vector2.ZERO
	invulnerable = 1.5

func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), DARK)
	for i in range(36):
		var star_x := fposmod(float(i * 151 + 67) - camera_x * 0.2, W)
		var star_y := float((i * 73 + 43) % 385)
		draw_circle(Vector2(star_x, star_y), 1.2, Color("3879ba"))
	for i in range(21):
		var bx := float(i * 135) - camera_x * 0.4
		draw_rect(Rect2(bx, 230 + (i * 37) % 120, 105, 210), Color("0b2550"))
		for j in range(3): draw_rect(Rect2(bx + 12 + j * 29, 350, 9, 5), Color("114c80"))
	draw_set_transform(Vector2(-camera_x, 0))
	draw_rect(Rect2(0, FLOOR_Y, WORLD_END, 86), Color("102854"))
	draw_rect(Rect2(0, FLOOR_Y, WORLD_END, 7), BLUE)
	for i in range(100):
		var fx := float(i * 29)
		draw_rect(Rect2(fx, FLOOR_Y + 26, 15, 5), Color("194a80"))
	for platform in platforms:
		draw_rect(platform, Color("173665"))
		draw_rect(Rect2(platform.position.x, platform.position.y, platform.size.x, 5), CYAN)
		for i in range(int(platform.size.x / 28.0)):
			draw_rect(Rect2(platform.position.x + 10 + i * 28, platform.position.y + 9, 8, 4), BLUE)
	for x in [290, 960, 1440, 2030]:
		draw_rect(Rect2(x, FLOOR_Y - 118, 12, 118), Color("20447c"))
		draw_rect(Rect2(x - 12, FLOOR_Y - 120, 35, 7), CYAN)
		draw_circle(Vector2(x + 6, FLOOR_Y - 155), 14, Color("1cc7ee"))
	for item in pickups:
		var center := Vector2(item.x, item.y + sin(tick * 4.0) * 3.0)
		draw_circle(center, 12, Color("ffd24f"))
		draw_circle(center, 6, Color("fff2ab"))
	for enemy in enemies:
		var c := Vector2(enemy.x, enemy.y)
		if enemy.has("boss"):
			draw_rect(Rect2(c.x - 39, c.y - 36, 78, 70), Color("3b3b72"))
			draw_rect(Rect2(c.x - 32, c.y - 29, 64, 55), Color("8c4cc2"))
			draw_rect(Rect2(c.x - 22, c.y - 10, 44, 17), Color("111e42"))
			draw_rect(Rect2(c.x - 18, c.y - 6, 10, 7), ORANGE)
			draw_rect(Rect2(c.x + 8, c.y - 6, 10, 7), ORANGE)
			draw_rect(Rect2(c.x - 39, c.y - 56, 78 * float(enemy.hp) / 12.0, 6), ORANGE)
		else:
			draw_rect(Rect2(c.x - 18, c.y - 17, 36, 34), Color("38517e"))
			draw_rect(Rect2(c.x - 13, c.y - 12, 26, 19), Color("208baf"))
			draw_rect(Rect2(c.x - 9, c.y - 6, 18, 6), ORANGE)
	for bullet in bullets:
		draw_rect(Rect2(bullet.pos.x - 7, bullet.pos.y - 3, 14, 6), CYAN)
		draw_rect(Rect2(bullet.pos.x - 2, bullet.pos.y - 2, 8, 4), Color.WHITE)
	if invulnerable <= 0.0 or int(tick * 14) % 2 == 0:
		draw_cat(player)
	draw_set_transform(Vector2.ZERO)
	draw_hud()
	if won:
		draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.04, 0.12, 0.82))
		label("¡GUARDIÁN G-7 DERROTADO!", Vector2(235, 230), 31, CYAN)
		label("Toca aquí para jugar otra vez", Vector2(342, 290), 18, Color.WHITE)

func draw_cat(c: Vector2) -> void:
	var outline := Color("0c1329")
	draw_rect(Rect2(c.x - 14, c.y - 13, 29, 29), outline)
	draw_rect(Rect2(c.x - 12, c.y - 12, 25, 24), Color("e58e4d"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-13, -11), c + Vector2(-14, -27), c + Vector2(-3, -17)]), outline)
	draw_colored_polygon(PackedVector2Array([c + Vector2(2, -17), c + Vector2(13, -27), c + Vector2(13, -11)]), outline)
	draw_rect(Rect2(c.x - 11, c.y - 5, 24, 11), Color("fff1d2"))
	draw_rect(Rect2(c.x - 4, c.y + 5, 20, 13), BLUE)
	draw_rect(Rect2(c.x - 12, c.y + 12, 9, 6), Color("278fe8"))
	draw_rect(Rect2(c.x + 7, c.y + 12, 9, 6), Color("278fe8"))
	draw_rect(Rect2(c.x + facing * 4 - 2, c.y - 8, 4, 5), Color("151c32"))
	var gun_x := c.x + 16.0 if facing > 0.0 else c.x - 35.0
	var muzzle_x := c.x + 24.0 if facing > 0.0 else c.x - 32.0
	draw_rect(Rect2(gun_x, c.y + 1, 19, 7), Color("4398cb"))
	draw_rect(Rect2(muzzle_x, c.y + 2, 8, 5), CYAN)
	draw_arc(c + Vector2(-facing * 11, 6), 14, 0.2, 3.5, 12, Color("ef9c53"), 5)

func draw_hud() -> void:
	draw_rect(Rect2(12, 12, 322, 68), Color("0b2244"))
	label("ESTACIÓN G-7  ·  PROTOTIPO", Vector2(23, 38), 19, CYAN)
	for i in range(max_health):
		draw_rect(Rect2(24 + i * 29, 52, 21, 16), ORANGE if i < health else Color("324865"))
	label("ENERGÍA: %d" % score, Vector2(168, 68), 16, Color.WHITE)
	label("A / D: mover  ·  ESPACIO: saltar  ·  J: disparar  ·  SHIFT: dash", Vector2(350, 32), 15, Color("bbdfff"))
	button(Vector2(62, 467), "◀", touch.left)
	button(Vector2(178, 467), "▶", touch.right)
	button(Vector2(631, 467), "DASH", touch.dash)
	button(Vector2(758, 467), "SALTO", touch.jump)
	button(Vector2(887, 467), "FUEGO", touch.fire)

func button(center: Vector2, name: String, active: bool) -> void:
	draw_circle(center, 48, Color("1c7199") if active else Color("122e59"))
	draw_arc(center, 48, 0, TAU, 36, CYAN if active else Color("398cbd"), 3)
	label(name, center + Vector2(-name.length() * 5, 6), 18, Color.WHITE)

func label(value: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
