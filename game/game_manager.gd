extends Node2D
class_name GameManager

const STATION_SCENE := preload("res://world/station_g7/station_g7.tscn")
const MINES_SCENE := preload("res://world/gateways/mines_lobby.tscn")
const FACTORY_SCENE := preload("res://world/gateways/factory_lobby.tscn")
const BULLET_SCENE := preload("res://projectiles/bullet.tscn")
const ENEMY_PROJECTILE_SCENE := preload("res://projectiles/enemy_projectile.tscn")
const FLOOR_Y := 454.0
const WORLD_END := 8600.0

@onready var active_world_root: Node2D = $WorldRoot/ActiveWorld
@onready var player: NeonPlayer = $WorldRoot/Player
@onready var player_projectiles: Node2D = $WorldRoot/PlayerProjectiles
@onready var enemy_projectiles: Node2D = $WorldRoot/EnemyProjectiles
@onready var camera_controller = $CameraController
@onready var audio_system = $StationAudio
@onready var hud = $UI/HUD
@onready var touch_controls = $UI/TouchControls
@onready var pause_menu = $UI/PauseMenu
@onready var map_ui = $UI/MapUI

var current_station: StationG7
var active_room: Node2D
var detached_station: StationG7
var station_return_position := Vector2(88.0, FLOOR_Y - 17.0)
var room_name := ""
var score := 0
var audio_enabled := true
var ui_paused := false
var map_open := false
var save_notice := ""
var save_notice_timer := 0.0
var unlock_timer := 0.0
var boss_blast := 0.0

func _ready() -> void:
	_configure_input_actions()
	player.add_to_group("player")
	player.shot_requested.connect(_on_player_shot_requested)
	player.sound_requested.connect(play_sound)
	player.died.connect(_on_player_died)
	camera_controller.set_target(player)
	hud.game = self
	touch_controls.game = self
	pause_menu.game = self
	map_ui.game = self
	if DisplayServer.has_feature(DisplayServer.FEATURE_ORIENTATION):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	reset_level()
	load_progress()

func _process(delta: float) -> void:
	if not ui_paused:
		save_notice_timer = maxf(0.0, save_notice_timer - delta)
		unlock_timer = maxf(0.0, unlock_timer - delta)
		boss_blast = maxf(0.0, boss_blast - delta)
	var boss_fight := room_name == "" and not boss_defeated() and player.global_position.x > 5940.0 and player.global_position.x < 6850.0
	audio_system.update_music(boss_fight, audio_enabled)

func _unhandled_input(event: InputEvent) -> void:
	if ui_paused:
		return
	if event.is_action_pressed("interact"):
		use_interaction()

func reset_level() -> void:
	set_pause(false)
	_clear_projectiles()
	_remove_all_worlds()
	current_station = STATION_SCENE.instantiate() as StationG7
	active_world_root.add_child(current_station)
	active_room = current_station
	detached_station = null
	room_name = ""
	score = 0
	audio_enabled = true
	save_notice = ""
	save_notice_timer = 0.0
	unlock_timer = 0.0
	boss_blast = 0.0
	station_return_position = Vector2(88.0, FLOOR_Y - 17.0)
	player.reset_player(station_return_position, 5)
	player.dash_unlocked = false
	player.motion_state = NeonPlayer.MotionState.NORMAL
	_connect_station(current_station)
	camera_controller.set_world_width(WORLD_END)
	camera_controller.set_target(player)

func _remove_all_worlds() -> void:
	if detached_station != null and is_instance_valid(detached_station) and detached_station.get_parent() == null:
		detached_station.free()
	for child in active_world_root.get_children():
		child.free()

func _connect_station(station: StationG7) -> void:
	station.score_awarded.connect(_on_score_awarded)
	station.max_health_awarded.connect(_on_max_health_awarded)
	station.checkpoint_reached.connect(_on_checkpoint_reached)
	station.save_requested.connect(save_progress)
	station.boss_defeated.connect(_on_boss_defeated)
	station.station_completed.connect(_on_station_completed)
	station.sound_requested.connect(play_sound)
	station.projectile_requested.connect(_spawn_enemy_projectile)
	station.notice_requested.connect(_show_notice)
	station.reconnect_runtime_nodes()

func save_progress() -> void:
	if room_name != "" or current_station == null:
		return
	var data := {
		"checkpoint_x": current_station.current_checkpoint.x,
		"boss_defeated": current_station.boss_was_defeated,
		"secret_collected": current_station.secret_collected,
		"route_rewards": current_station.route_rewards.duplicate(),
		"visited": current_station.visited.duplicate(),
		"station_complete": current_station.complete,
		"score": score,
		"audio_enabled": audio_enabled,
	}
	if SaveSystem.save_game(data):
		save_notice = "PROGRESO GUARDADO"
		save_notice_timer = 2.0

func load_progress() -> void:
	var data := SaveSystem.load_game()
	if data.is_empty():
		return
	current_station.apply_save(data)
	score = int(data.get("score", 0))
	audio_enabled = data.get("audio_enabled", true) == true
	var secret_health_bonus := 1 if data.get("secret_collected", false) == true else 0
	var saved_rewards: Array = data.get("route_rewards", [])
	var max_health := 5 + secret_health_bonus + saved_rewards.size()
	var spawn := Vector2(float(data.get("checkpoint_x", 88.0)), FLOOR_Y - 17.0)
	player.reset_player(spawn, max_health)
	player.dash_unlocked = data.get("boss_defeated", false) == true
	station_return_position = spawn
	camera_controller.set_target(player)
	save_notice = "PARTIDA CONTINUADA"
	save_notice_timer = 2.5

func start_new_game() -> void:
	SaveSystem.erase_game()
	reset_level()

func set_pause(value: bool, show_map: bool = false) -> void:
	ui_paused = value
	map_open = show_map if value else false
	touch_controls.reset_inputs()
	get_tree().paused = value
	audio_system.set_paused(value)

func interaction_name() -> String:
	if player == null:
		return ""
	if room_name != "":
		var gateway := active_room as GatewayRoom
		if gateway != null:
			var terminal := gateway.get_terminal(player.global_position)
			return terminal.prompt(true) if terminal != null else ""
		return ""
	if current_station == null:
		return ""
	var terminal := current_station.get_terminal(player.global_position)
	if terminal == null:
		return ""
	return terminal.prompt(current_station.boss_was_defeated)

func use_interaction() -> void:
	if player == null:
		return
	if room_name != "":
		var gateway := active_room as GatewayRoom
		if gateway != null and gateway.get_terminal(player.global_position) != null:
			leave_gateway()
		return
	var terminal := current_station.get_terminal(player.global_position)
	if terminal == null:
		return
	if terminal.terminal_type != "tram" and not current_station.boss_was_defeated:
		_show_notice("DERROTA A SENTINEL PARA ACTIVARLO", 3.0)
		return
	if terminal.terminal_type == "tram":
		if not current_station.boss_was_defeated:
			return
		player.global_position = Vector2(terminal.destination_x, FLOOR_Y - 17.0)
		player.velocity = Vector2.ZERO
		player.give_respawn_invulnerability()
		_clear_projectiles()
		player.get_node("Effects").call("clear")
		touch_controls.reset_inputs()
		play_sound("dash")
		_show_notice("TRANVÍA: DESTINO ALCANZADO", 2.0)
	elif terminal.terminal_type == "mines":
		enter_gateway("Minas Bioluminosas")
	elif terminal.terminal_type == "factory":
		enter_gateway("Fábrica Omega")

func enter_gateway(destination: String) -> void:
	if room_name != "" or current_station == null:
		return
	save_progress()
	station_return_position = player.global_position
	detached_station = current_station
	active_world_root.remove_child(detached_station)
	active_room = MINES_SCENE.instantiate() if destination == "Minas Bioluminosas" else FACTORY_SCENE.instantiate()
	active_world_root.add_child(active_room)
	room_name = destination
	player.global_position = Vector2(100.0, FLOOR_Y - 17.0)
	player.velocity = Vector2.ZERO
	player.jumps_used = 0
	player.grounded_hint = true
	player.cancel_dash()
	player.get_node("Effects").call("clear")
	touch_controls.reset_inputs()
	_clear_projectiles()
	camera_controller.set_world_width(1500.0)
	play_sound("pickup")

func leave_gateway() -> void:
	if room_name == "" or detached_station == null:
		return
	if active_room != null and active_room != detached_station:
		active_world_root.remove_child(active_room)
		active_room.queue_free()
	active_world_root.add_child(detached_station)
	current_station = detached_station
	active_room = current_station
	detached_station = null
	room_name = ""
	player.global_position = station_return_position
	player.velocity = Vector2.ZERO
	player.jumps_used = 0
	player.grounded_hint = true
	player.cancel_dash()
	player.get_node("Effects").call("clear")
	touch_controls.reset_inputs()
	player.give_respawn_invulnerability()
	_clear_projectiles()
	camera_controller.set_world_width(WORLD_END)
	save_progress()

func _on_player_shot_requested(origin: Vector2, direction: float) -> void:
	var bullet := BULLET_SCENE.instantiate() as PlayerBullet
	player_projectiles.add_child(bullet)
	bullet.setup(origin, direction)

func _spawn_enemy_projectile(origin: Vector2, projectile_velocity: Vector2, life: float, kind: String) -> void:
	var projectile := ENEMY_PROJECTILE_SCENE.instantiate() as EnemyProjectile
	enemy_projectiles.add_child(projectile)
	projectile.setup(origin, projectile_velocity, life, kind)
	projectile.player_hit.connect(_on_enemy_projectile_hit)

func _on_enemy_projectile_hit(_projectile: EnemyProjectile, damage: int, knockback_y: float) -> void:
	player.take_damage(damage, knockback_y)

func _on_player_died() -> void:
	respawn_player()

func respawn_player() -> void:
	if room_name == "":
		if not boss_defeated():
			var boss := current_station.get_boss()
			if boss != null:
				boss.reset_after_player_death()
		player.global_position = current_station.current_checkpoint
	else:
		player.global_position = Vector2(100.0, FLOOR_Y - 17.0)
	player.heal_full()
	player.velocity = Vector2.ZERO
	player.jumps_used = 0
	player.double_jump_flash = 0.0
	player.hurt_timer = 0.0
	player.give_respawn_invulnerability()
	_clear_enemy_projectiles()

func _on_score_awarded(amount: int) -> void:
	score += amount

func _on_max_health_awarded(amount: int, heal_to_full: bool) -> void:
	if heal_to_full:
		player.set_max_health(player.max_health + amount, true)
	else:
		player.add_max_health(amount, amount)

func _on_checkpoint_reached(position: Vector2) -> void:
	current_station.current_checkpoint = position

func _on_boss_defeated() -> void:
	player.dash_unlocked = true
	unlock_timer = 5.0
	boss_blast = 1.5
	_clear_enemy_projectiles()

func _on_station_completed() -> void:
	pass

func _show_notice(text: String, duration: float) -> void:
	save_notice = text
	save_notice_timer = duration

func play_sound(sound_name: String) -> void:
	if audio_enabled:
		audio_system.play_effect(sound_name)

func _clear_projectiles() -> void:
	for child in player_projectiles.get_children(): child.free()
	_clear_enemy_projectiles()

func _clear_enemy_projectiles() -> void:
	for child in enemy_projectiles.get_children(): child.free()

func get_enemy_projectile_count() -> int:
	return enemy_projectiles.get_child_count()

func clear_enemy_projectiles() -> void:
	_clear_enemy_projectiles()

func simulate_game_step(delta: float) -> void:
	if ui_paused:
		return
	player.simulate_step(delta)
	if room_name == "" and current_station != null:
		current_station.collect_nearby_pickups(player)

func get_active_enemy_count() -> int:
	if room_name != "" or current_station == null:
		return 0
	return current_station.get_enemy_nodes().size()

func station_player_x() -> float:
	return station_return_position.x if room_name != "" else player.global_position.x

func station_visited() -> Array[int]:
	var station := detached_station if room_name != "" else current_station
	return station.visited if station != null else []

func station_route_rewards() -> Array[String]:
	var station := detached_station if room_name != "" else current_station
	return station.route_rewards if station != null else []

func station_checkpoint_x() -> float:
	var station := detached_station if room_name != "" else current_station
	return station.current_checkpoint.x if station != null else 88.0

func secret_collected() -> bool:
	var station := detached_station if room_name != "" else current_station
	return station.secret_collected if station != null else false

func secret_count() -> int:
	var station := detached_station if room_name != "" else current_station
	if station == null:
		return 0
	return (1 if station.secret_collected else 0) + station.route_rewards.size()

func boss_defeated() -> bool:
	var station := detached_station if room_name != "" else current_station
	return station.boss_was_defeated if station != null else false

func station_complete() -> bool:
	var station := detached_station if room_name != "" else current_station
	return station.complete if station != null else false

func _configure_input_actions() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE, KEY_W, KEY_UP],
		"fire": [KEY_J, KEY_Z],
		"dash": [KEY_SHIFT],
		"interact": [KEY_E],
		"open_map": [KEY_M],
		"pause": [KEY_P, KEY_ESCAPE],
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			for keycode in bindings[action]:
				var key_event := InputEventKey.new()
				key_event.keycode = int(keycode)
				InputMap.action_add_event(action, key_event)

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_pause(true)
	elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
		if DisplayServer.has_feature(DisplayServer.FEATURE_ORIENTATION):
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
