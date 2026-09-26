extends Node2D
class_name StationG7

signal score_awarded(amount: int)
signal max_health_awarded(amount: int, heal_to_full: bool)
signal checkpoint_reached(position: Vector2)
signal save_requested
signal boss_defeated
signal station_completed
signal sound_requested(sound_name: String)
signal projectile_requested(origin: Vector2, velocity: Vector2, life: float, kind: String)
signal notice_requested(text: String, duration: float)

const FLOOR_Y := 454.0
const WORLD_END := 8600.0
const BOSS_HEALTH := 10

var visited: Array[int] = []
var route_rewards: Array[String] = []
var secret_collected := false
var boss_was_defeated := false
var complete := false
var current_checkpoint := Vector2(88.0, FLOOR_Y - 17.0)
var boss_blast := 0.0

func _ready() -> void:
	add_to_group("station_g7")
	_connect_runtime_nodes()
	_update_terminal_visuals()

func _physics_process(delta: float) -> void:
	boss_blast = maxf(0.0, boss_blast - delta)
	var player := get_tree().get_first_node_in_group("player") as NeonPlayer
	if player == null:
		return
	_update_exploration(player)
	_update_checkpoints(player)
	_update_terminal_visuals()
	if boss_was_defeated and player.global_position.x > 8210.0 and not complete:
		complete = true
		sound_requested.emit("victory")
		save_requested.emit()
		station_completed.emit()
		notice_requested.emit("ESTACIÓN G-7 COMPLETADA", 5.0)

func _connect_runtime_nodes() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_ancestor_of(enemy):
			continue
		_connect_signal_once(enemy, "defeated", Callable(self, "_on_enemy_defeated"))
		_connect_signal_once(enemy, "sound_requested", Callable(self, "_relay_sound"))
		_connect_signal_once(enemy, "projectile_requested", Callable(self, "_relay_projectile"))
		_connect_signal_once(enemy, "contact_damage", Callable(self, "_on_contact_damage"))
		if enemy is SentinelBoss:
			_connect_signal_once(enemy, "enraged", Callable(self, "_on_boss_enraged"))
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if is_ancestor_of(pickup) and pickup is NeonPickup:
			_connect_signal_once(pickup, "collected", Callable(self, "_on_pickup_collected"))

func _connect_signal_once(node: Node, signal_name: StringName, callable: Callable) -> void:
	if node.has_signal(signal_name) and not node.is_connected(signal_name, callable):
		node.connect(signal_name, callable)

func reconnect_runtime_nodes() -> void:
	_connect_runtime_nodes()

func _on_enemy_defeated(enemy: Node) -> void:
	if enemy is SentinelBoss:
		boss_was_defeated = true
		boss_blast = 1.5
		score_awarded.emit(100)
		sound_requested.emit("victory")
		sound_requested.emit("pickup")
		checkpoint_reached.emit(Vector2(6550.0, FLOOR_Y - 17.0))
		current_checkpoint = Vector2(6550.0, FLOOR_Y - 17.0)
		boss_defeated.emit()
		save_requested.emit()
	else:
		score_awarded.emit(20)
		sound_requested.emit("pickup")
		enemy.queue_free()

func _on_contact_damage(player: NeonPlayer, amount: int) -> void:
	player.take_damage(amount)

func _relay_sound(sound_name: String) -> void:
	sound_requested.emit(sound_name)

func _relay_projectile(origin: Vector2, projectile_velocity: Vector2, life: float, kind: String) -> void:
	projectile_requested.emit(origin, projectile_velocity, life, kind)

func _on_boss_enraged() -> void:
	notice_requested.emit("SENTINEL: SOBRECARGA", 3.0)

func _on_pickup_collected(pickup: NeonPickup) -> void:
	sound_requested.emit("pickup")
	score_awarded.emit(pickup.score_reward)
	if pickup.pickup_type == "secret":
		if pickup.pickup_id == "initial":
			secret_collected = true
		else:
			if not route_rewards.has(pickup.pickup_id):
				route_rewards.append(pickup.pickup_id)
		if pickup.max_health_reward > 0:
			max_health_awarded.emit(pickup.max_health_reward, pickup.pickup_id != "initial")
		if pickup.pickup_id != "initial":
			notice_requested.emit("SECRETO: VIDA MÁXIMA +1", 3.0)
		save_requested.emit()

func _update_exploration(player: NeonPlayer) -> void:
	var cell := clampi(int(player.global_position.x / 960.0), 0, 8)
	if not visited.has(cell):
		visited.append(cell)
		save_requested.emit()

func _update_checkpoints(player: NeonPlayer) -> void:
	var points := get_tree().get_nodes_in_group("checkpoints")
	for node in points:
		if not is_ancestor_of(node) or not node is NeonCheckpoint:
			continue
		var checkpoint := node as NeonCheckpoint
		if checkpoint.requires_boss_defeated and not boss_was_defeated:
			continue
		if player.global_position.x > checkpoint.threshold_x and current_checkpoint.x < checkpoint.threshold_x:
			current_checkpoint = Vector2(checkpoint.spawn_x, FLOOR_Y - 17.0)
			checkpoint_reached.emit(current_checkpoint)
			save_requested.emit()

func _update_terminal_visuals() -> void:
	for terminal in get_tree().get_nodes_in_group("interaction_terminals"):
		if is_ancestor_of(terminal) and terminal is InteractionTerminal:
			terminal.set_enabled_visual(boss_was_defeated)

func collect_nearby_pickups(player: NeonPlayer) -> void:
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if is_ancestor_of(pickup) and pickup is NeonPickup:
			pickup.try_collect(player)

func get_boss() -> SentinelBoss:
	return get_tree().get_first_node_in_group("boss") as SentinelBoss

func get_enemy_nodes() -> Array[Node]:
	var result: Array[Node] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_ancestor_of(enemy):
			result.append(enemy)
	return result

func get_turrets() -> Array[Node]:
	var result: Array[Node] = []
	for enemy in get_enemy_nodes():
		if enemy is TurretEnemy:
			result.append(enemy)
	return result

func get_terminal(player_position: Vector2) -> InteractionTerminal:
	for terminal in get_tree().get_nodes_in_group("interaction_terminals"):
		if is_ancestor_of(terminal) and terminal is InteractionTerminal and terminal.is_near(player_position):
			return terminal
	return null

func apply_save(data: Dictionary) -> void:
	boss_was_defeated = data.get("boss_defeated", false) == true
	secret_collected = data.get("secret_collected", false) == true
	route_rewards.clear()
	for reward in data.get("route_rewards", []):
		if reward in ["workshop", "reactor"] and not route_rewards.has(str(reward)):
			route_rewards.append(str(reward))
	visited.clear()
	for cell in data.get("visited", []):
		if (cell is int or cell is float) and int(cell) >= 0 and int(cell) < 9 and not visited.has(int(cell)):
			visited.append(int(cell))
	complete = data.get("station_complete", false) == true
	current_checkpoint = Vector2(float(data.get("checkpoint_x", 88.0)), FLOOR_Y - 17.0)
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if not is_ancestor_of(pickup) or not pickup is NeonPickup:
			continue
		if pickup.pickup_id == "initial" and secret_collected:
			pickup.mark_consumed()
		elif pickup.pickup_id != "" and route_rewards.has(pickup.pickup_id):
			pickup.mark_consumed()
	if boss_was_defeated:
		var boss := get_boss()
		if boss != null:
			boss.free()
