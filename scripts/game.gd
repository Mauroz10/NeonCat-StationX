extends Node2D
## Prototipo autocontenido: un nivel, controles táctiles y dibujos originales.

const W := 960.0
const H := 540.0
const WORLD_END := 3300.0
const GATE_X := 2700.0
const SECRET_LEFT := 500.0
const SECRET_RIGHT := 670.0
const CAT_SHEET := preload("res://assets/astro_gato_clean.png")
const CAT_REGION := Rect2(135, 80, 984, 1095)
const CAT_SCALE := 55.0 / 1095.0
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
var dash_unlocked := false
var boss_defeated := false
var secret_collected := false
var boss_phase := "windup"
var boss_timer := 1.2
var boss_attack_index := 0
var boss_invulnerable := 0.0
var unlock_timer := 0.0
var invulnerable := 0.0
var fire_timer := 0.0
var dash_timer := 0.0
var dash_cooldown := 0.0
var afterimage_clock := 0.0
var tick := 0.0
var touch := {"left": false, "right": false, "jump": false, "fire": false, "dash": false}
var touch_points: Dictionary = {}
var jump_requested := false
var dash_requested := false
var bullets: Array[Dictionary] = []
var enemy_shots: Array[Dictionary] = []
var afterimages: Array[Dictionary] = []
var cat_sprite: Sprite2D
var echo_sprites: Array[Sprite2D] = []
var enemies: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var platforms := [Rect2(350, 372, 140, 18), Rect2(525, 310, 135, 16), Rect2(695, 337, 150, 18),
	Rect2(1100, 376, 155, 18), Rect2(1510, 348, 160, 18), Rect2(1870, 377, 145, 18),
	Rect2(2930, 373, 140, 18)]

func _ready() -> void:
	cat_sprite = make_cat_sprite()
	cat_sprite.name = "AstroGato"
	cat_sprite.z_index = 2
	add_child(cat_sprite)
	for i in range(5):
		var echo := make_cat_sprite()
		echo.name = "DashEcho%d" % i
		echo.modulate = Color(0.35, 1.0, 0.70, 0.0)
		echo.visible = false
		echo.z_index = 1
		add_child(echo)
		echo_sprites.append(echo)
	reset_level()

func make_cat_sprite() -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = CAT_SHEET
	sprite.region_enabled = true
	sprite.region_rect = CAT_REGION
	sprite.centered = false
	sprite.scale = Vector2(CAT_SCALE, CAT_SCALE)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite

func reset_level() -> void:
	player = Vector2(88, FLOOR_Y - 17)
	checkpoint = player
	velocity = Vector2.ZERO
	max_health = 5
	health = max_health
	score = 0
	won = false
	dash_unlocked = false
	boss_defeated = false
	secret_collected = false
	boss_phase = "windup"
	boss_timer = 1.2
	boss_attack_index = 0
	boss_invulnerable = 0.0
	unlock_timer = 0.0
	dash_timer = 0.0
	dash_cooldown = 0.0
	afterimage_clock = 0.0
	invulnerable = 0.0
	bullets.clear()
	enemy_shots.clear()
	afterimages.clear()
	enemies = [
		{"x": 465.0, "y": FLOOR_Y - 18.0, "hp": 2, "left": 385.0, "right": 620.0, "dir": 1.0},
		{"x": 840.0, "y": FLOOR_Y - 18.0, "hp": 3, "left": 785.0, "right": 1020.0, "dir": -1.0, "train": true},
		{"x": 1230.0, "y": FLOOR_Y - 18.0, "hp": 3, "left": 1150.0, "right": 1410.0, "dir": 1.0},
		{"x": 1730.0, "y": FLOOR_Y - 18.0, "hp": 3, "left": 1630.0, "right": 1840.0, "dir": -1.0},
		{"x": 2200.0, "y": FLOOR_Y - 36.0, "hp": 6, "left": 2180.0, "right": 2230.0, "dir": -1.0, "boss": true}
	]
	pickups = [{"x": 410.0, "y": 340.0}, {"x": 755.0, "y": 305.0},
		{"x": 1160.0, "y": 345.0}, {"x": 1590.0, "y": 317.0},
		{"x": 1940.0, "y": 345.0}]
	camera_x = 0.0
	update_cat_sprites()
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
		update_cat_sprites()
		queue_redraw()
		return
	invulnerable = maxf(0.0, invulnerable - delta)
	fire_timer = maxf(0.0, fire_timer - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	for i in range(afterimages.size() - 1, -1, -1):
		var ghost := afterimages[i]
		ghost.life -= delta
		if ghost.life <= 0.0: afterimages.remove_at(i)
	var direction := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or touch.left: direction -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or touch.right: direction += 1.0
	if direction != 0.0: facing = direction
	var was_on_ground := on_ground()
	if jump_requested and was_on_ground: velocity.y = JUMP_SPEED
	jump_requested = false
	if dash_requested and dash_unlocked and dash_cooldown <= 0.0:
		dash_timer = 0.24
		dash_cooldown = 1.5
		afterimage_clock = 0.0
	dash_requested = false
	if dash_timer > 0.0:
		afterimage_clock -= delta
		if afterimage_clock <= 0.0:
			afterimages.append({"pos": player, "life": 0.20, "facing": facing, "pose": current_cat_pose()})
			afterimage_clock = 0.045
	velocity.x = facing * 650.0 if dash_timer > 0.0 else direction * MOVE_SPEED
	velocity.y += GRAVITY * delta
	var old_feet := player.y + 17.0
	player += velocity * delta
	player.x = clampf(player.x, 18.0, WORLD_END - 20.0)
	# Desvío elevado: se ve al principio, pero solo se entra tras desbloquear dash.
	if dash_timer <= 0.0 and player.y - 17.0 < 410.0:
		block_vertical_gate(SECRET_LEFT, 16.0, velocity.x)
		block_vertical_gate(SECRET_RIGHT, 16.0, velocity.x)
	# La compuerta ocupa toda la altura; solo se atraviesa durante el dash.
	if dash_timer <= 0.0:
		block_vertical_gate(GATE_X, 16.0, velocity.x)
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
			var train_hit: bool = enemy.has("train") and absf(bullet.pos.y - enemy.y) < 21.0 and (bullet.pos.x - enemy.x) * enemy.dir > -85.0 and (bullet.pos.x - enemy.x) * enemy.dir < 21.0
			if train_hit or (not enemy.has("train") and absf(bullet.pos.x - enemy.x) < radius and absf(bullet.pos.y - enemy.y) < radius):
				if enemy.has("boss"):
					# El núcleo naranja solo queda expuesto tras cada ataque.
					if boss_phase == "exposed":
						if absf(bullet.pos.x - enemy.x) >= 19.0 or absf(bullet.pos.y - (enemy.y + 12.0)) >= 16.0:
							continue # La bala pasa el blindaje abierto hasta alcanzar el núcleo.
						if boss_invulnerable <= 0.0:
							enemy.hp -= 1
							boss_invulnerable = 0.25
				else:
					enemy.hp -= 1
				hit = true
				break
		if hit or bullet.life <= 0.0: bullets.remove_at(i)
	for i in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[i]
		if enemy.hp <= 0:
			if enemy.has("boss"):
				boss_defeated = true
				dash_unlocked = true
				unlock_timer = 5.0
				checkpoint = Vector2(2420.0, FLOOR_Y - 17.0)
				enemy_shots.clear()
			score += 100 if enemy.has("boss") else 20
			enemies.remove_at(i)
			continue
		enemy.x += enemy.dir * (22.0 if enemy.has("boss") else (65.0 if enemy.has("train") else 95.0)) * delta
		if enemy.x < enemy.left or enemy.x > enemy.right: enemy.dir *= -1.0
		var radius := 42.0 if enemy.has("boss") else 24.0
		var train_contact: bool = enemy.has("train") and (player.x - enemy.x) * enemy.dir > -90.0 and (player.x - enemy.x) * enemy.dir < 26.0
		if (train_contact or (not enemy.has("train") and absf(player.x - enemy.x) < radius)) and absf(player.y - enemy.y) < 29.0 and invulnerable <= 0.0 and dash_timer <= 0.0:
			health -= 1
			invulnerable = 1.0
			velocity.y = -270.0
			if health <= 0: respawn()
	if not boss_defeated and player.x > 1880.0:
		update_boss(delta)
	update_enemy_shots(delta)
	boss_invulnerable = maxf(0.0, boss_invulnerable - delta)
	unlock_timer = maxf(0.0, unlock_timer - delta)
	for i in range(pickups.size() - 1, -1, -1):
		if player.distance_to(Vector2(pickups[i].x, pickups[i].y)) < 29.0:
			score += 10
			pickups.remove_at(i)
	if not secret_collected and player.distance_to(Vector2(593.0, 267.0)) < 32.0:
		secret_collected = true
		score += 50
		max_health += 1
		health += 1
	if player.x > 1200 and checkpoint.x < 1200: checkpoint = Vector2(1250, FLOOR_Y - 17)
	if player.x > 1900.0 and checkpoint.x < 1900.0: checkpoint = Vector2(1940.0, FLOOR_Y - 17.0)
	if boss_defeated and player.x > 3140.0: won = true
	camera_x = clampf(player.x - W * 0.39, 0.0, WORLD_END - W)
	update_cat_sprites()
	queue_redraw()

func current_cat_pose() -> int:
	if dash_timer > 0.0: return 4
	if not on_ground(): return 3
	if fire_timer > 0.10: return 2
	if absf(velocity.x) > 10.0: return 3 + int(tick * 8.0) % 2
	return 0

func place_cat_sprite(sprite: Sprite2D, point: Vector2, _pose: int, look: float) -> void:
	# Una sola pose aprobada hasta que existan fotogramas de animación.
	sprite.position = Vector2(point.x - camera_x - CAT_REGION.size.x * CAT_SCALE * 0.5, point.y + 17.0 - 55.0)
	sprite.flip_h = look < 0.0

func update_cat_sprites() -> void:
	cat_sprite.visible = not won and (invulnerable <= 0.0 or int(tick * 14.0) % 2 == 0)
	place_cat_sprite(cat_sprite, player, current_cat_pose(), facing)
	for i in range(echo_sprites.size()):
		var echo := echo_sprites[i]
		if i < afterimages.size() and not won:
			var snapshot := afterimages[i]
			echo.visible = true
			echo.modulate = Color(0.35, 1.0, 0.70, 0.50 * snapshot.life / 0.20)
			place_cat_sprite(echo, snapshot.pos, snapshot.pose, snapshot.facing)
		else:
			echo.visible = false

func block_vertical_gate(gate_x: float, width: float, moving: float) -> void:
	if player.x > gate_x - 15.0 and player.x < gate_x + width + 15.0:
		if moving > 0.0: player.x = gate_x - 15.0
		elif moving < 0.0: player.x = gate_x + width + 15.0

func update_boss(delta: float) -> void:
	boss_timer -= delta
	if boss_timer > 0.0: return
	if boss_phase == "windup":
		var boss_x := 2200.0
		for enemy in enemies:
			if enemy.has("boss"): boss_x = enemy.x
		match boss_attack_index % 3:
			0: # Tres proyectiles en abanico: saltar o separarse.
				var toward := (player - Vector2(boss_x, FLOOR_Y - 31.0)).normalized()
				for offset in [-0.3, 0.0, 0.3]:
					enemy_shots.append({"pos": Vector2(boss_x, FLOOR_Y - 31.0), "vel": toward.rotated(offset) * 255.0, "life": 2.5, "kind": "orb"})
			1: # Onda baja que se evita saltando.
				enemy_shots.append({"pos": Vector2(boss_x - 42.0, FLOOR_Y - 10.0), "vel": Vector2(-340.0, 0.0), "life": 2.1, "kind": "wave"})
			2: # Descarga vertical en tres posiciones cerca del jugador.
				for offset in [-85.0, 0.0, 85.0]:
					enemy_shots.append({"pos": Vector2(clampf(player.x + offset, 1920.0, 2420.0), 70.0), "vel": Vector2(0.0, 300.0), "life": 1.5, "kind": "rain"})
		boss_phase = "exposed"
		boss_timer = 2.0
	else:
		boss_attack_index += 1
		boss_phase = "windup"
		boss_timer = 1.05

func update_enemy_shots(delta: float) -> void:
	var player_defeated := false
	for i in range(enemy_shots.size() - 1, -1, -1):
		var shot := enemy_shots[i]
		shot.pos += shot.vel * delta
		shot.life -= delta
		var radius := 21.0 if shot.kind == "wave" else 13.0
		if shot.pos.distance_to(player) < radius + 12.0 and invulnerable <= 0.0 and dash_timer <= 0.0:
			health -= 1
			invulnerable = 1.0
			velocity.y = -210.0
			shot.life = 0.0
			if health <= 0: player_defeated = true
		if shot.life <= 0.0 or shot.pos.y > FLOOR_Y + 15.0:
			enemy_shots.remove_at(i)
	if player_defeated: respawn()

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
	enemy_shots.clear()

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
	for i in range(int(WORLD_END / 29.0) + 1):
		var fx := float(i * 29)
		draw_rect(Rect2(fx, FLOOR_Y + 26, 15, 5), Color("194a80"))
	for platform in platforms:
		draw_rect(platform, Color("173665"))
		draw_rect(Rect2(platform.position.x, platform.position.y, platform.size.x, 5), CYAN)
		for i in range(int(platform.size.x / 28.0)):
			draw_rect(Rect2(platform.position.x + 10 + i * 28, platform.position.y + 9, 8, 4), BLUE)
	for x in [290, 960, 1440, 2030, 2800, 3030]:
		draw_rect(Rect2(x, FLOOR_Y - 118, 12, 118), Color("20447c"))
		draw_rect(Rect2(x - 12, FLOOR_Y - 120, 35, 7), CYAN)
		draw_circle(Vector2(x + 6, FLOOR_Y - 155), 14, Color("1cc7ee"))
	for item in pickups:
		var center := Vector2(item.x, item.y + sin(tick * 4.0) * 3.0)
		draw_circle(center, 12, Color("ffd24f"))
		draw_circle(center, 6, Color("fff2ab"))
	# Sala opcional de la primera pantalla: el premio queda a la vista.
	for x in [SECRET_LEFT, SECRET_RIGHT]:
		draw_rect(Rect2(x, 0, 16, 410), Color("b536d9") if dash_timer <= 0.0 else Color(0.5, 0.4, 1.0, 0.25))
	label("VUELVE CON DASH", Vector2(512, 207), 15, CYAN)
	if not secret_collected:
		var prize := Vector2(593, 267 + sin(tick * 4.0) * 4.0)
		draw_circle(prize, 18, Color("60ffd0"))
		draw_circle(prize, 10, Color("147d79"))
		draw_rect(Rect2(prize.x - 3, prize.y - 7, 6, 14), Color.WHITE)
		draw_rect(Rect2(prize.x - 7, prize.y - 3, 14, 6), Color.WHITE)
	# La energía cierra el paso tanto por el suelo como por el aire.
	draw_rect(Rect2(GATE_X, 0, 16, FLOOR_Y), Color("e03ef2") if dash_timer <= 0.0 else Color("6196e7", 0.3))
	draw_rect(Rect2(GATE_X - 12, FLOOR_Y - 117, 40, 10), Color("bd55ef"))
	label("DASH →", Vector2(GATE_X - 96, FLOOR_Y - 130), 18, CYAN)
	draw_rect(Rect2(3120, FLOOR_Y - 85, 25, 85), Color("278cba"))
	draw_circle(Vector2(3132, FLOOR_Y - 94), 18, CYAN)
	label("SALIDA", Vector2(3082, FLOOR_Y - 126), 18, CYAN)
	for enemy in enemies:
		var c := Vector2(enemy.x, enemy.y)
		if enemy.has("boss"):
			draw_rect(Rect2(c.x - 39, c.y - 36, 78, 70), Color("3b3b72"))
			draw_rect(Rect2(c.x - 32, c.y - 29, 64, 55), Color("8c4cc2"))
			draw_rect(Rect2(c.x - 22, c.y + 2, 44, 20), Color("111e42"))
			draw_circle(c + Vector2(0, 12), 14, ORANGE if boss_phase == "exposed" else Color("263358"))
			draw_circle(c + Vector2(0, 12), 7, Color("fff4aa") if boss_phase == "exposed" else Color("8197bb"))
			if boss_phase == "windup":
				draw_arc(c, 52, 0, TAU, 24, ORANGE, 3)
				label(["ABANICO", "ONDA", "DESCARGA"][boss_attack_index % 3], c + Vector2(-43, -71), 14, ORANGE)
			draw_rect(Rect2(c.x - 39, c.y - 56, 78 * float(enemy.hp) / 6.0, 6), ORANGE)
		else:
			if enemy.has("train"):
				for segment in range(1, 4):
					var tail_x: float = c.x - enemy.dir * float(segment * 23)
					draw_rect(Rect2(tail_x - 11, c.y - 10, 22, 24), Color("146585"))
					draw_circle(Vector2(tail_x, c.y + 11), 5, CYAN)
			draw_rect(Rect2(c.x - 18, c.y - 17, 36, 34), Color("38517e"))
			draw_rect(Rect2(c.x - 13, c.y - 12, 26, 19), Color("208baf"))
			draw_rect(Rect2(c.x - 9, c.y - 6, 18, 6), ORANGE)
	for bullet in bullets:
		draw_rect(Rect2(bullet.pos.x - 7, bullet.pos.y - 3, 14, 6), CYAN)
		draw_rect(Rect2(bullet.pos.x - 2, bullet.pos.y - 2, 8, 4), Color.WHITE)
	for shot in enemy_shots:
		if shot.kind == "wave":
			draw_rect(Rect2(shot.pos.x - 17, shot.pos.y - 12, 34, 22), ORANGE)
		elif shot.kind == "rain":
			draw_rect(Rect2(shot.pos.x - 6, shot.pos.y - 18, 12, 30), Color("ff5de5"))
		else:
			draw_circle(shot.pos, 11, ORANGE)
	draw_set_transform(Vector2.ZERO)
	draw_hud()
	if won:
		draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.04, 0.12, 0.82))
		label("¡ESTACIÓN G-7 SUPERADA!", Vector2(235, 230), 31, CYAN)
		label("Toca aquí para jugar otra vez", Vector2(342, 290), 18, Color.WHITE)

func draw_hud() -> void:
	draw_rect(Rect2(12, 12, 322, 68), Color("0b2244"))
	label("ESTACIÓN G-7  ·  PROTOTIPO", Vector2(23, 38), 19, CYAN)
	for i in range(max_health):
		draw_rect(Rect2(24 + i * 29, 52, 21, 16), ORANGE if i < health else Color("324865"))
	label("ENERGÍA: %d" % score, Vector2(168, 68), 16, Color.WHITE)
	var icon := Vector2(360, 65)
	draw_circle(icon, 15, Color("16385a"))
	draw_arc(icon, 15, 0, TAU, 24, Color("506887"), 3)
	if dash_unlocked:
		var charge := clampf(1.0 - dash_cooldown / 1.5, 0.0, 1.0)
		if charge > 0.0:
			draw_arc(icon, 15, -PI / 2.0, -PI / 2.0 + TAU * charge, 24, Color("53ff98"), 4)
	label("D", icon + Vector2(-6, 6), 17, Color("53ff98") if dash_unlocked else Color("506887"))
	label("A / D: mover  ·  ESPACIO: saltar  ·  J: disparar  ·  SHIFT: dash", Vector2(350, 32), 15, Color("bbdfff"))
	if unlock_timer > 0.0:
		label("¡DASH DESBLOQUEADO! Cruza la compuerta violeta", Vector2(280, 106), 21, CYAN)
	elif not dash_unlocked:
		label("Regresa luego por el ítem verde · Derrota al guardián", Vector2(390, 61), 16, ORANGE)
	else:
		label("DASH listo" if dash_cooldown <= 0.0 else "DASH recargando", Vector2(530, 61), 17, CYAN)
	if dash_unlocked and not secret_collected and player.x > 1350.0:
		label("Opcional: regresa a la primera pantalla por el ítem verde", Vector2(305, 104), 17, Color("53ff98"))
	button(Vector2(62, 467), "◀", touch.left)
	button(Vector2(178, 467), "▶", touch.right)
	button(Vector2(631, 467), "DASH" if dash_unlocked else "BLOQ.", touch.dash and dash_unlocked)
	button(Vector2(758, 467), "SALTO", touch.jump)
	button(Vector2(887, 467), "FUEGO", touch.fire)

func button(center: Vector2, name: String, active: bool) -> void:
	draw_circle(center, 48, Color("1c7199") if active else Color("122e59"))
	draw_arc(center, 48, 0, TAU, 36, CYAN if active else Color("398cbd"), 3)
	label(name, center + Vector2(-name.length() * 5, 6), 18, Color.WHITE)

func label(value: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
