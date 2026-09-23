extends Node2D
## Prototipo autocontenido: un nivel, controles táctiles y dibujos originales.

const W := 960.0
const H := 540.0
const WORLD_END := 8600.0
const GATE_X := 7000.0
const BOSS_X := 6250.0
const SECRET_LEFT := 500.0
const SECRET_RIGHT := 670.0
const OLD_CAT_SHEET := preload("res://assets/astro_gato.jpg")
const CAT_KEY_SHADER := preload("res://shaders/remove_green.gdshader")
const CAT_REGION := Rect2(135, 80, 984, 1095)
const CAT_SCALE := 55.0 / 1095.0
const RUN_FRAME := Rect2(0, 0, 543, 724)
const RUN_SCALE := 55.0 / 650.0
const JUMP_FRAME_WIDTH := 887.0
const JUMP_SCALE := 55.0 / 850.0
const JUMP_V2_SCALE := 55.0 / 696.0
const SHOOT_FRAME_WIDTH := 724.0
const SHOOT_SCALE := 55.0 / 680.0
const DASH_FRAME_WIDTH := 724.0
const DASH_SCALE := 55.0 / 680.0
const HURT_FRAME_WIDTH := 887.0
const HURT_SCALE := 55.0 / 850.0
const HURT_V2_FRAME_WIDTH := 724.0
const HURT_V2_SCALE := 55.0 / 685.0
const BOSS_SCALE := 100.0 / 1206.0
const BOSS_CORE_OFFSET := Vector2(-4.0, -30.0)
const SAVE_PATH := "user://station_g7_save.json"
const JUMP_V2_REGIONS := [
	Rect2(48, 168, 495, 520), Rect2(544, 21, 503, 684),
	Rect2(1093, 9, 536, 696), Rect2(1629, 24, 521, 676)
]
const IDLE_REGIONS := [
	Rect2(12, 15, 531, 651), Rect2(544, 73, 538, 589),
	Rect2(1095, 25, 533, 681), Rect2(1634, 109, 530, 553)
]
const OLD_CAT_SCALE := 0.15
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
var dash_origin := Vector2.ZERO
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
var boss_sprite: Sprite2D
var boss_core_sprite: Sprite2D
var echo_sprites: Array[Sprite2D] = []
var clean_cat_texture: Texture2D
var run_cat_texture: Texture2D
var idle_cat_texture: Texture2D
var jump_cat_texture: Texture2D
var jump_v2_texture: Texture2D
var shoot_cat_texture: Texture2D
var dash_cat_texture: Texture2D
var dash_fast_texture: Texture2D
var hurt_cat_texture: Texture2D
var hurt_v2_texture: Texture2D
var hurt_timer := 0.0
var save_notice_timer := 0.0
var save_notice := ""
var jump_elapsed := 0.0
var old_cat_regions: Array[Rect2] = [
	Rect2(40, 80, 310, 365), Rect2(350, 80, 300, 365),
	Rect2(660, 80, 330, 365), Rect2(1030, 80, 280, 365),
	Rect2(1330, 80, 275, 365), Rect2(1610, 80, 318, 365)
]
var enemies: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var platforms := [Rect2(350, 372, 140, 18), Rect2(525, 310, 135, 16), Rect2(695, 337, 150, 18),
	Rect2(1100, 376, 155, 18), Rect2(1510, 348, 160, 18), Rect2(1870, 377, 145, 18),
	Rect2(2280, 372, 150, 18), Rect2(2480, 370, 220, 18), Rect2(2810, 328, 145, 18),
	Rect2(3220, 376, 165, 18), Rect2(3670, 335, 160, 18), Rect2(3860, 370, 210, 18),
	Rect2(4300, 375, 160, 18), Rect2(4710, 323, 150, 18), Rect2(5280, 365, 160, 18),
	Rect2(5430, 370, 230, 18), Rect2(5770, 319, 145, 18),
	Rect2(7250, 370, 150, 18), Rect2(7550, 330, 145, 18), Rect2(7810, 365, 170, 18)]
var floor_gaps := [Vector2(2510.0, 2650.0), Vector2(3900.0, 4050.0), Vector2(5460.0, 5610.0)]

func over_floor_gap(x: float) -> bool:
	for gap in floor_gaps:
		if x > gap.x and x < gap.y: return true
	return false

func _ready() -> void:
	var clean_path := "res://assets/astro_gato_clean.png"
	if ResourceLoader.exists(clean_path):
		clean_cat_texture = load(clean_path) as Texture2D
	if ResourceLoader.exists("res://assets/astro_gato_run.png"):
		run_cat_texture = load("res://assets/astro_gato_run.png") as Texture2D
	if ResourceLoader.exists("res://assets/astro_gato_idle.png"):
		idle_cat_texture = load("res://assets/astro_gato_idle.png") as Texture2D
	if ResourceLoader.exists("res://assets/astro_gato_jump.png"):
		jump_cat_texture = load("res://assets/astro_gato_jump.png") as Texture2D
	if ResourceLoader.exists("res://assets/astro_gato_jump_v2.png"):
		jump_v2_texture = load("res://assets/astro_gato_jump_v2.png") as Texture2D
	if ResourceLoader.exists("res://assets/astro_gato_shoot.png"):
		shoot_cat_texture = load("res://assets/astro_gato_shoot.png") as Texture2D
	if ResourceLoader.exists("res://assets/astro_gato_dash.png"):
		dash_cat_texture = load("res://assets/astro_gato_dash.png") as Texture2D
	if ResourceLoader.exists("res://assets/astro_gato_dash_fast.png"):
		dash_fast_texture = load("res://assets/astro_gato_dash_fast.png") as Texture2D
	if ResourceLoader.exists("res://assets/astro_gato_hurt.png"):
		hurt_cat_texture = load("res://assets/astro_gato_hurt.png") as Texture2D
	if ResourceLoader.exists("res://assets/astro_gato_hurt_v2.png"):
		hurt_v2_texture = load("res://assets/astro_gato_hurt_v2.png") as Texture2D
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
	if ResourceLoader.exists("res://assets/sentinel_g7_concept.png"):
		boss_sprite = Sprite2D.new()
		boss_sprite.texture = load("res://assets/sentinel_g7_concept.png") as Texture2D
		boss_sprite.centered = false
		boss_sprite.scale = Vector2.ONE * BOSS_SCALE
		boss_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		boss_sprite.z_index = 2
		add_child(boss_sprite)
		var core_image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
		core_image.fill(Color.TRANSPARENT)
		for core_y in range(24):
			for core_x in range(24):
				var core_pixel := Vector2(core_x - 11.5, core_y - 11.5)
				if core_pixel.length_squared() < 120.0:
					core_image.set_pixel(core_x, core_y, Color.WHITE)
		boss_core_sprite = Sprite2D.new()
		boss_core_sprite.texture = ImageTexture.create_from_image(core_image)
		boss_core_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		boss_core_sprite.z_index = 3
		add_child(boss_core_sprite)
	reset_level()
	load_progress()

func make_cat_sprite() -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = clean_cat_texture if clean_cat_texture != null else OLD_CAT_SHEET
	sprite.region_enabled = true
	sprite.region_rect = CAT_REGION if clean_cat_texture != null else old_cat_regions[0]
	sprite.centered = false
	var scale_factor := CAT_SCALE if clean_cat_texture != null else OLD_CAT_SCALE
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if clean_cat_texture == null:
		var sprite_material := ShaderMaterial.new()
		sprite_material.shader = CAT_KEY_SHADER
		sprite.material = sprite_material
	return sprite

func reset_level() -> void:
	player = Vector2(88, FLOOR_Y - 17)
	checkpoint = player
	velocity = Vector2.ZERO
	jump_elapsed = 0.0
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
	hurt_timer = 0.0
	save_notice_timer = 0.0
	save_notice = ""
	dash_origin = player
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
		{"x": 2300.0, "y": FLOOR_Y - 18.0, "hp": 2, "left": 2220.0, "right": 2430.0, "dir": 1.0},
		{"x": 3000.0, "y": FLOOR_Y - 18.0, "hp": 3, "left": 2890.0, "right": 3160.0, "dir": -1.0},
		{"x": 3600.0, "y": FLOOR_Y - 18.0, "hp": 3, "left": 3500.0, "right": 3770.0, "dir": 1.0, "train": true},
		{"x": 4550.0, "y": FLOOR_Y - 18.0, "hp": 2, "left": 4460.0, "right": 4690.0, "dir": -1.0},
		{"x": 4990.0, "y": FLOOR_Y - 18.0, "hp": 3, "left": 4890.0, "right": 5170.0, "dir": 1.0},
		{"x": 5750.0, "y": FLOOR_Y - 18.0, "hp": 3, "left": 5660.0, "right": 5890.0, "dir": -1.0},
		{"x": BOSS_X, "y": FLOOR_Y - 36.0, "hp": 6, "left": 6210.0, "right": 6290.0, "dir": -1.0, "boss": true}
	]
	pickups = [{"x": 410.0, "y": 340.0}, {"x": 755.0, "y": 305.0},
		{"x": 1160.0, "y": 345.0}, {"x": 1590.0, "y": 317.0},
		{"x": 1940.0, "y": 345.0}, {"x": 2850.0, "y": 297.0},
		{"x": 3730.0, "y": 305.0}, {"x": 4760.0, "y": 295.0},
		{"x": 5810.0, "y": 287.0}, {"x": 7640.0, "y": 299.0}]
	camera_x = 0.0
	update_cat_sprites()
	update_boss_sprite()
	queue_redraw()

func save_progress() -> void:
	var save_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		push_warning("No se pudo guardar el progreso de Estación G-7")
		return
	var data := {
		"version": 2,
		"checkpoint_x": checkpoint.x,
		"boss_defeated": boss_defeated,
		"secret_collected": secret_collected
	}
	save_file.store_string(JSON.stringify(data))
	save_file.close()
	save_notice = "PROGRESO GUARDADO"
	save_notice_timer = 2.0

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var save_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null: return
	var parsed: Variant = JSON.parse_string(save_file.get_as_text())
	if not parsed is Dictionary or not [1, 2].has(parsed.get("version", 0)): return
	var saved_x: Variant = parsed.get("checkpoint_x", 88.0)
	if not saved_x is float and not saved_x is int: return
	if not [88.0, 1250.0, 1940.0, 2420.0, 3450.0, 5100.0, 5900.0, 6550.0, 7350.0].has(float(saved_x)): return
	if parsed.get("version", 0) == 1 and parsed.get("boss_defeated", false) == true and float(saved_x) == 2420.0:
		saved_x = 6550.0
	checkpoint = Vector2(float(saved_x), FLOOR_Y - 17.0)
	player = checkpoint
	boss_defeated = parsed.get("boss_defeated", false) == true
	dash_unlocked = boss_defeated
	secret_collected = parsed.get("secret_collected", false) == true
	max_health = 6 if secret_collected else 5
	health = max_health
	if boss_defeated:
		for i in range(enemies.size() - 1, -1, -1):
			if enemies[i].has("boss"): enemies.remove_at(i)
	camera_x = clampf(player.x - W * 0.39, 0.0, WORLD_END - W)
	update_cat_sprites()
	update_boss_sprite()
	save_notice = "PARTIDA CONTINUADA"
	save_notice_timer = 2.5
	queue_redraw()

func start_new_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	reset_level()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_W or event.keycode == KEY_UP:
			jump_requested = true
		if event.keycode == KEY_SHIFT:
			dash_requested = true
		if event.keycode == KEY_R and won:
			start_new_game()
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
	if won and p.x > 350 and p.x < 610 and p.y > 265: start_new_game()
	return ""

func _physics_process(delta: float) -> void:
	tick += delta
	if won:
		update_cat_sprites()
		queue_redraw()
		return
	invulnerable = maxf(0.0, invulnerable - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	save_notice_timer = maxf(0.0, save_notice_timer - delta)
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
	if jump_requested and was_on_ground:
		velocity.y = JUMP_SPEED
		jump_elapsed = 0.0
	jump_requested = false
	if dash_requested and dash_unlocked and dash_cooldown <= 0.0:
		dash_timer = 0.24
		dash_origin = player
		dash_cooldown = 1.5
		afterimage_clock = 0.0
	dash_requested = false
	if dash_timer > 0.0:
		afterimage_clock -= delta
		if afterimage_clock <= 0.0:
			afterimages.append({"pos": player, "life": 0.26, "facing": facing, "pose": current_cat_pose()})
			afterimage_clock = 0.045
	velocity.x = facing * 650.0 if dash_timer > 0.0 else direction * MOVE_SPEED
	velocity.y += GRAVITY * delta
	var old_feet := player.y + 17.0
	player += velocity * delta
	if not was_on_ground or velocity.y < 0.0: jump_elapsed += delta
	player.x = clampf(player.x, 18.0, WORLD_END - 20.0)
	# Desvío elevado: se ve al principio, pero solo se entra tras desbloquear dash.
	if dash_timer <= 0.0 and player.y - 17.0 < 410.0:
		block_vertical_gate(SECRET_LEFT, 16.0, velocity.x)
		block_vertical_gate(SECRET_RIGHT, 16.0, velocity.x)
	# La compuerta ocupa toda la altura; solo se atraviesa durante el dash.
	if dash_timer <= 0.0:
		block_vertical_gate(GATE_X, 16.0, velocity.x)
	if player.y + 17.0 >= FLOOR_Y and not over_floor_gap(player.x):
		player.y = FLOOR_Y - 17.0
		velocity.y = 0.0
	elif velocity.y >= 0.0:
		for platform in platforms:
			if player.x + 15.0 > platform.position.x and player.x - 15.0 < platform.end.x and old_feet <= platform.position.y + 5.0 and player.y + 17.0 >= platform.position.y:
				player.y = platform.position.y - 17.0
				velocity.y = 0.0
				break
	if player.y > H + 50.0:
		respawn()
	if (touch.fire or Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_Z)) and fire_timer <= 0.0:
		bullets.append({"pos": player + Vector2(facing * 22.0, -3.0), "dir": facing, "life": 1.3})
		fire_timer = 0.22
	for i in range(bullets.size() - 1, -1, -1):
		var bullet := bullets[i]
		bullet.pos.x += bullet.dir * 670.0 * delta
		bullet.life -= delta
		var hit := false
		for enemy in enemies:
			var radius := 55.0 if enemy.has("boss") and boss_sprite != null else (37.0 if enemy.has("boss") else 21.0)
			var train_hit: bool = enemy.has("train") and absf(bullet.pos.y - enemy.y) < 21.0 and (bullet.pos.x - enemy.x) * enemy.dir > -85.0 and (bullet.pos.x - enemy.x) * enemy.dir < 21.0
			if train_hit or (not enemy.has("train") and absf(bullet.pos.x - enemy.x) < radius and absf(bullet.pos.y - enemy.y) < radius):
				if enemy.has("boss"):
					# El núcleo naranja solo queda expuesto tras cada ataque.
					if boss_phase == "exposed":
						var weakpoint := Vector2(enemy.x, enemy.y) + (BOSS_CORE_OFFSET if boss_sprite != null else Vector2(0.0, 12.0))
						if absf(bullet.pos.x - weakpoint.x) >= 19.0 or absf(bullet.pos.y - weakpoint.y) >= 16.0:
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
				checkpoint = Vector2(6550.0, FLOOR_Y - 17.0)
				enemy_shots.clear()
				save_progress()
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
			hurt_timer = 0.36
			velocity.y = -270.0
			if health <= 0: respawn()
	if not boss_defeated and player.x > 5940.0:
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
		save_progress()
	if player.x > 1200 and checkpoint.x < 1200:
		checkpoint = Vector2(1250, FLOOR_Y - 17)
		save_progress()
	if player.x > 1900.0 and checkpoint.x < 1900.0:
		checkpoint = Vector2(1940.0, FLOOR_Y - 17.0)
		save_progress()
	if player.x > 3400.0 and checkpoint.x < 3400.0:
		checkpoint = Vector2(3450.0, FLOOR_Y - 17.0)
		save_progress()
	if player.x > 5050.0 and checkpoint.x < 5050.0:
		checkpoint = Vector2(5100.0, FLOOR_Y - 17.0)
		save_progress()
	if player.x > 5850.0 and checkpoint.x < 5850.0:
		checkpoint = Vector2(5900.0, FLOOR_Y - 17.0)
		save_progress()
	if boss_defeated and player.x > 7300.0 and checkpoint.x < 7300.0:
		checkpoint = Vector2(7350.0, FLOOR_Y - 17.0)
		save_progress()
	if boss_defeated and player.x > 8350.0: won = true
	camera_x = clampf(player.x - W * 0.39, 0.0, WORLD_END - W)
	update_cat_sprites()
	update_boss_sprite()
	queue_redraw()

func update_boss_sprite() -> void:
	if boss_sprite == null: return
	boss_sprite.visible = false
	boss_core_sprite.visible = false
	for enemy in enemies:
		if enemy.has("boss"):
			boss_sprite.visible = true
			boss_sprite.position = Vector2(enemy.x - camera_x - 1305.0 * BOSS_SCALE * 0.5, FLOOR_Y - 1206.0 * BOSS_SCALE)
			boss_core_sprite.visible = true
			boss_core_sprite.position = Vector2(enemy.x - camera_x, enemy.y) + BOSS_CORE_OFFSET
			boss_core_sprite.modulate = Color("ffab31") if boss_phase == "exposed" else Color("30304d")
			return

func current_cat_pose() -> int:
	if dash_timer > 0.0: return 4
	if not on_ground(): return 3
	if fire_timer > 0.10: return 2
	if absf(velocity.x) > 10.0: return 3 + int(tick * 8.0) % 2
	return 0

func place_cat_sprite(sprite: Sprite2D, point: Vector2, pose: int, look: float, is_echo: bool = false) -> void:
	if clean_cat_texture != null:
		if hurt_v2_texture != null and hurt_timer > 0.0 and not is_echo:
			var hurt_frame := 0 if hurt_timer > 0.24 else (1 if hurt_timer > 0.12 else 2)
			sprite.texture = hurt_v2_texture
			sprite.region_rect = Rect2(hurt_frame * HURT_V2_FRAME_WIDTH, 0.0, HURT_V2_FRAME_WIDTH, 724.0)
			sprite.scale = Vector2.ONE * HURT_V2_SCALE
			sprite.position = Vector2(point.x - camera_x - HURT_V2_FRAME_WIDTH * HURT_V2_SCALE * 0.5, point.y + 17.0 - 724.0 * HURT_V2_SCALE)
		elif hurt_cat_texture != null and hurt_timer > 0.0 and not is_echo:
			var hurt_frame := 0 if hurt_timer > 0.18 else 1
			sprite.texture = hurt_cat_texture
			sprite.region_rect = Rect2(hurt_frame * HURT_FRAME_WIDTH, 0.0, HURT_FRAME_WIDTH, 887.0)
			sprite.scale = Vector2.ONE * HURT_SCALE
			sprite.position = Vector2(point.x - camera_x - HURT_FRAME_WIDTH * HURT_SCALE * 0.5, point.y + 17.0 - 867.0 * HURT_SCALE)
		elif (dash_fast_texture != null or dash_cat_texture != null) and (dash_timer > 0.0 or is_echo and pose == 4):
			var dash_frame := 0 if dash_timer > 0.18 else (1 if dash_timer > 0.05 else 2)
			sprite.texture = dash_fast_texture if dash_fast_texture != null else dash_cat_texture
			sprite.region_rect = Rect2(dash_frame * DASH_FRAME_WIDTH, 0.0, DASH_FRAME_WIDTH, 724.0)
			sprite.scale = Vector2.ONE * DASH_SCALE
			sprite.position = Vector2(point.x - camera_x - DASH_FRAME_WIDTH * DASH_SCALE * 0.5, point.y + 17.0 - 700.0 * DASH_SCALE)
		elif jump_v2_texture != null and not on_ground():
			var jump_frame := 0 if jump_elapsed < 0.11 else (1 if velocity.y < -110.0 else (2 if velocity.y < 180.0 else 3))
			var jump_rect: Rect2 = JUMP_V2_REGIONS[jump_frame]
			sprite.texture = jump_v2_texture
			sprite.region_rect = jump_rect
			sprite.scale = Vector2.ONE * JUMP_V2_SCALE
			sprite.position = Vector2(point.x - camera_x - jump_rect.size.x * JUMP_V2_SCALE * 0.5, point.y - 16.0 - jump_rect.size.y * JUMP_V2_SCALE * 0.5)
		elif jump_cat_texture != null and dash_timer <= 0.0 and not on_ground():
			var jump_frame := 0 if velocity.y < 0.0 else 1
			sprite.texture = jump_cat_texture
			sprite.region_rect = Rect2(jump_frame * JUMP_FRAME_WIDTH, 0.0, JUMP_FRAME_WIDTH, 887.0)
			sprite.scale = Vector2.ONE * JUMP_SCALE
			sprite.position = Vector2(point.x - camera_x - JUMP_FRAME_WIDTH * JUMP_SCALE * 0.5, point.y - 17.0 - 425.0 * JUMP_SCALE)
		elif shoot_cat_texture != null and fire_timer > 0.0 and dash_timer <= 0.0 and on_ground():
			var shoot_frame := 0 if fire_timer > 0.16 else (1 if fire_timer > 0.08 else 2)
			sprite.texture = shoot_cat_texture
			sprite.region_rect = Rect2(shoot_frame * SHOOT_FRAME_WIDTH, 0.0, SHOOT_FRAME_WIDTH, 724.0)
			sprite.scale = Vector2.ONE * SHOOT_SCALE
			sprite.position = Vector2(point.x - camera_x - SHOOT_FRAME_WIDTH * SHOOT_SCALE * 0.5, point.y + 17.0 - 700.0 * SHOOT_SCALE)
		elif run_cat_texture != null and pose >= 3 and pose <= 4 and dash_timer <= 0.0 and absf(velocity.x) > 10.0 and on_ground():
			var frame := int(tick * 9.0) % 4
			sprite.texture = run_cat_texture
			sprite.region_rect = Rect2(frame * RUN_FRAME.size.x, 0, RUN_FRAME.size.x, RUN_FRAME.size.y)
			sprite.scale = Vector2.ONE * RUN_SCALE
			sprite.position = Vector2(point.x - camera_x - RUN_FRAME.size.x * RUN_SCALE * 0.5, point.y + 17.0 - 690.0 * RUN_SCALE)
		elif idle_cat_texture != null and pose == 0 and absf(velocity.x) <= 10.0 and on_ground():
			# Las dos poses con proporciones más consistentes evitan cambios bruscos de tamaño.
			var idle_frame := (int(tick * 2.0) % 2) * 2
			var idle_rect: Rect2 = IDLE_REGIONS[idle_frame]
			var idle_scale := 55.0 / idle_rect.size.y
			sprite.texture = idle_cat_texture
			sprite.region_rect = idle_rect
			sprite.scale = Vector2.ONE * idle_scale
			sprite.position = Vector2(point.x - camera_x - idle_rect.size.x * idle_scale * 0.5, point.y + 17.0 - 55.0)
		else:
			sprite.texture = clean_cat_texture
			sprite.region_rect = CAT_REGION
			sprite.scale = Vector2.ONE * CAT_SCALE
			sprite.position = Vector2(point.x - camera_x - CAT_REGION.size.x * CAT_SCALE * 0.5, point.y + 17.0 - 55.0)
	else:
		var frame_rect := old_cat_regions[pose]
		sprite.region_rect = frame_rect
		sprite.position = Vector2(point.x - camera_x - frame_rect.size.x * OLD_CAT_SCALE * 0.5, point.y - 38.0)
	sprite.flip_h = look < 0.0

func update_cat_sprites() -> void:
	cat_sprite.visible = not won and (hurt_timer > 0.0 or invulnerable <= 0.0 or int(tick * 14.0) % 2 == 0)
	cat_sprite.modulate = Color(1.0, 0.65, 0.65) if hurt_timer > 0.0 else Color.WHITE
	place_cat_sprite(cat_sprite, player, current_cat_pose(), facing)
	for i in range(echo_sprites.size()):
		var echo := echo_sprites[i]
		if i < afterimages.size() and not won:
			var snapshot := afterimages[i]
			echo.visible = true
			echo.modulate = Color(0.28, 0.94, 0.75, 0.62 * snapshot.life / 0.26)
			place_cat_sprite(echo, snapshot.pos, snapshot.pose, snapshot.facing, true)
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
		var boss_x := BOSS_X
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
					enemy_shots.append({"pos": Vector2(clampf(player.x + offset, 6000.0, 6520.0), 70.0), "vel": Vector2(0.0, 300.0), "life": 1.5, "kind": "rain"})
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
			hurt_timer = 0.36
			velocity.y = -210.0
			shot.life = 0.0
			if health <= 0: player_defeated = true
		if shot.life <= 0.0 or shot.pos.y > FLOOR_Y + 15.0:
			enemy_shots.remove_at(i)
	if player_defeated: respawn()

func on_ground() -> bool:
	if player.y + 17.0 >= FLOOR_Y - 1.0 and not over_floor_gap(player.x): return true
	for platform in platforms:
		if absf(player.y + 17.0 - platform.position.y) <= 2.0 and player.x + 15.0 > platform.position.x and player.x - 15.0 < platform.end.x: return true
	return false

func respawn() -> void:
	player = checkpoint
	health = max_health
	velocity = Vector2.ZERO
	hurt_timer = 0.0
	invulnerable = 1.5
	enemy_shots.clear()

func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), DARK)
	for i in range(36):
		var star_x := fposmod(float(i * 151 + 67) - camera_x * 0.2, W)
		var star_y := float((i * 73 + 43) % 385)
		draw_circle(Vector2(star_x, star_y), 1.2, Color("3879ba"))
	for i in range(58):
		var bx := float(i * 135) - camera_x * 0.4
		draw_rect(Rect2(bx, 230 + (i * 37) % 120, 105, 210), Color("0b2550"))
		for j in range(3): draw_rect(Rect2(bx + 12 + j * 29, 350, 9, 5), Color("114c80"))
	draw_set_transform(Vector2(-camera_x, 0))
	# Sectores reconocibles para orientarse en el recorrido ampliado.
	for sector in [
		{"start": 0.0, "end": 2150.0, "name": "01 · ANDÉN", "color": Color("153768")},
		{"start": 2150.0, "end": 4100.0, "name": "02 · TALLERES", "color": Color("124954")},
		{"start": 4100.0, "end": 5950.0, "name": "03 · REACTORES", "color": Color("49305d")},
		{"start": 5950.0, "end": 7050.0, "name": "04 · GUARDIÁN G-7", "color": Color("583247")},
		{"start": 7050.0, "end": WORLD_END, "name": "05 · SALIDA", "color": Color("184e62")}
	]:
		draw_rect(Rect2(sector.start, 165, sector.end - sector.start, 11), sector.color)
		draw_rect(Rect2(sector.start + 48.0, 190, 245, 38), sector.color)
		label(sector.name, Vector2(sector.start + 58.0, 217), 19, CYAN)
	var floor_start := 0.0
	for gap in floor_gaps:
		draw_rect(Rect2(floor_start, FLOOR_Y, gap.x - floor_start, 86), Color("102854"))
		draw_rect(Rect2(floor_start, FLOOR_Y, gap.x - floor_start, 7), BLUE)
		floor_start = gap.y
	draw_rect(Rect2(floor_start, FLOOR_Y, WORLD_END - floor_start, 86), Color("102854"))
	draw_rect(Rect2(floor_start, FLOOR_Y, WORLD_END - floor_start, 7), BLUE)
	for i in range(int(WORLD_END / 29.0) + 1):
		var fx := float(i * 29)
		if not over_floor_gap(fx): draw_rect(Rect2(fx, FLOOR_Y + 26, 15, 5), Color("194a80"))
	for gap in floor_gaps:
		draw_rect(Rect2(gap.x - 90.0, FLOOR_Y - 7.0, 68.0, 7.0), ORANGE)
		draw_rect(Rect2(gap.y + 22.0, FLOOR_Y - 7.0, 68.0, 7.0), ORANGE)
		label("SALTA", Vector2(gap.x - 98.0, FLOOR_Y - 20.0), 15, ORANGE)
	for platform in platforms:
		draw_rect(platform, Color("173665"))
		draw_rect(Rect2(platform.position.x, platform.position.y, platform.size.x, 5), CYAN)
		for i in range(int(platform.size.x / 28.0)):
			draw_rect(Rect2(platform.position.x + 10 + i * 28, platform.position.y + 9, 8, 4), BLUE)
	for x in [290, 960, 1440, 2030, 2800, 3030, 3480, 4230, 4750, 5150, 5700, 6090, 6650, 7450, 8030]:
		draw_rect(Rect2(x, FLOOR_Y - 118, 12, 118), Color("20447c"))
		draw_rect(Rect2(x - 12, FLOOR_Y - 120, 35, 7), CYAN)
		draw_circle(Vector2(x + 6, FLOOR_Y - 155), 14, Color("1cc7ee"))
	for marker_x in [1250.0, 1940.0, 3450.0, 5100.0, 5900.0, 6550.0, 7350.0]:
		var active: bool = checkpoint.x >= float(marker_x)
		draw_rect(Rect2(marker_x - 5.0, FLOOR_Y - 76.0, 10.0, 76.0), Color("257e8e"))
		draw_circle(Vector2(marker_x, FLOOR_Y - 82.0), 14.0, Color("53ff98") if active else Color("426582"))
		label("CP", Vector2(marker_x - 13.0, FLOOR_Y - 104.0), 14, Color("53ff98") if active else CYAN)
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
	draw_rect(Rect2(8340, FLOOR_Y - 85, 25, 85), Color("278cba"))
	draw_circle(Vector2(8352, FLOOR_Y - 94), 18, CYAN)
	label("SALIDA", Vector2(8302, FLOOR_Y - 126), 18, CYAN)
	for enemy in enemies:
		var c := Vector2(enemy.x, enemy.y)
		if enemy.has("boss"):
			if boss_sprite == null:
				draw_rect(Rect2(c.x - 39, c.y - 36, 78, 70), Color("3b3b72"))
				draw_rect(Rect2(c.x - 32, c.y - 29, 64, 55), Color("8c4cc2"))
				draw_rect(Rect2(c.x - 22, c.y + 2, 44, 20), Color("111e42"))
				draw_circle(c + Vector2(0, 12), 14, ORANGE if boss_phase == "exposed" else Color("263358"))
				draw_circle(c + Vector2(0, 12), 7, Color("fff4aa") if boss_phase == "exposed" else Color("8197bb"))
			elif boss_phase == "exposed":
				draw_arc(c + BOSS_CORE_OFFSET, 17.0, 0.0, TAU, 20, Color("ffce64"), 2.0)
			if boss_phase == "windup":
				draw_arc(c, 60.0 if boss_sprite != null else 52.0, 0, TAU, 24, ORANGE, 3)
				label(["ABANICO", "ONDA", "DESCARGA"][boss_attack_index % 3], c + Vector2(-43, -118 if boss_sprite != null else -71), 14, ORANGE)
			var bar_width := 96.0 if boss_sprite != null else 78.0
			draw_rect(Rect2(c.x - bar_width * 0.5, c.y - (118.0 if boss_sprite != null else 56.0), bar_width * float(enemy.hp) / 6.0, 6), ORANGE)
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
	if dash_timer > 0.0 and not won:
		# Destello de arranque, copias en movimiento y frenada, según la referencia.
		if dash_timer > 0.185:
			draw_arc(player + Vector2(-facing * 8.0, 2.0), 29.0, 0.4, TAU - 0.4, 22, Color(0.25, 1.0, 0.73, 0.85), 3.0)
			draw_arc(player + Vector2(-facing * 8.0, 2.0), 35.0, 0.9, TAU - 0.9, 22, Color(0.21, 1.0, 0.45, 0.44), 2.0)
		if dash_timer > 0.13 and dash_timer <= 0.20:
			var flash_x := dash_origin.x + facing * 19.0
			draw_line(Vector2(flash_x, dash_origin.y - 47.0), Vector2(flash_x, dash_origin.y + 19.0), Color(0.24, 1.0, 0.83, 0.72), 4.0)
			draw_line(Vector2(flash_x + facing * 3.0, dash_origin.y - 30.0), Vector2(flash_x + facing * 3.0, dash_origin.y + 10.0), Color.WHITE, 1.0)
		if dash_timer < 0.065:
			draw_arc(player + Vector2(0.0, 8.0), 20.0, 0.2, PI - 0.2, 16, Color(0.25, 1.0, 0.73, dash_timer * 10.0), 2.0)
		for i in range(4):
			var offset := float(i) * 7.0
			var line_y := player.y - 22.0 + offset
			var wobble := sin(tick * 56.0 + float(i) * 2.1) * 5.0
			var far_x := player.x - facing * (65.0 + float(i % 3) * 12.0 + wobble)
			var near_x := player.x - facing * (18.0 + float(i % 2) * 8.0)
			draw_line(Vector2(far_x, line_y), Vector2(near_x, line_y), Color(0.20, 1.0, 0.48, 0.45 - float(i) * 0.06), 2.0 if i % 2 == 0 else 1.0)
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
	draw_rect(Rect2(24, 91, 235, 5), Color("264465"))
	draw_rect(Rect2(24, 91, 235.0 * clampf(player.x / WORLD_END, 0.0, 1.0), 5), CYAN)
	label("RECORRIDO %d%%" % int(player.x / WORLD_END * 100.0), Vector2(24, 115), 14, CYAN)
	if save_notice_timer > 0.0:
		label(save_notice, Vector2(720, 112), 17, Color("53ff98"))
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
