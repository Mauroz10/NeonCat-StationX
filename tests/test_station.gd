extends SceneTree
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, name: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + name)
	else:
		print("PASS: " + name)

func run_checks() -> void:
	if OS.get_environment("NEON_TEST_RUN") != "1":
		printerr("Ejecuta las pruebas con NEON_TEST_RUN=1 y XDG_DATA_HOME temporal.")
		quit(1)
		return
	var game: GameManager = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame

	game.reset_level()
	game.player.request_jump()
	game.simulate_game_step(1.0 / 60.0)
	check(game.player.jumps_used == 1 and game.player.velocity.y < 0, "primer salto")
	game.player.request_jump()
	game.simulate_game_step(1.0 / 60.0)
	check(game.player.jumps_used == 2 and game.player.double_jump_flash > 0, "doble salto")
	game.player.request_jump()
	var previous: float = game.player.velocity.y
	game.simulate_game_step(1.0 / 60.0)
	check(game.player.jumps_used == 2 and game.player.velocity.y > previous, "no tercer salto")

	game.player.global_position = Vector2(2580, 440)
	game.player.velocity = Vector2.ZERO
	game.player.grounded_hint = false
	for i in range(12):
		game.simulate_game_step(1.0 / 60.0)
	check(game.player.global_position.y > 450, "pozo permite caer sin suelo invisible")

	game.reset_level()
	game.player.global_position = Vector2(3060, 188)
	game.current_station.collect_nearby_pickups(game.player)
	check(game.player.max_health == 6 and game.current_station.route_rewards.has("workshop"), "secreto elevado y recompensa")
	game.current_station.collect_nearby_pickups(game.player)
	check(game.player.max_health == 6, "recompensa una sola vez")

	game.current_station.boss_was_defeated = true
	game.player.dash_unlocked = true
	game.player.global_position = Vector2(6630, 437)
	game.use_interaction()
	check(game.player.global_position.x == 180, "tranvía vuelve al inicio")
	game.use_interaction()
	check(game.player.global_position.x == 6630, "tranvía de regreso al jefe")

	game.player.global_position = Vector2(1780, 437)
	var enemy_count: int = game.get_active_enemy_count()
	game.use_interaction()
	check(game.room_name == "Minas Bioluminosas" and game.get_active_enemy_count() == 0, "entrada a Minas")
	game.use_interaction()
	check(game.room_name == "" and game.player.global_position.x == 1780 and game.get_active_enemy_count() == enemy_count, "regreso conserva enemigos y estación")

	game.player.global_position = Vector2(8330, 437)
	game.use_interaction()
	check(game.room_name == "Fábrica Omega", "entrada a Fábrica")
	game.leave_gateway()

	game.set_pause(true, true)
	var old_x: float = game.player.global_position.x
	game.simulate_game_step(0.5)
	check(game.player.global_position.x == old_x and game.map_open, "mapa congela el juego")
	game.set_pause(false)

	game.current_station.current_checkpoint = Vector2(6550, 437)
	game.current_station.complete = true
	game.save_progress()
	game.reset_level()
	game.load_progress()
	check(game.boss_defeated() and game.station_complete() and game.player.max_health == 6 and game.player.global_position.x == 6550, "guardado v3 restaura progreso")

	game.reset_level()
	game.player.global_position = Vector2(6010, 437)
	var boss := game.current_station.get_boss()
	boss.health = 5
	boss._physics_process(1.0 / 60.0)
	check(boss.is_enraged, "segunda fase a mitad de vida")

	boss.boss_attack_index = 0
	boss.boss_phase = "windup"
	boss.force_attack_now(game.player.global_position)
	check(game.get_enemy_projectile_count() == 5, "segunda fase dispara cinco proyectiles")
	game.clear_enemy_projectiles()
	boss.boss_attack_index = 2
	boss.boss_phase = "windup"
	boss.force_attack_now(game.player.global_position)
	check(game.get_enemy_projectile_count() == 5, "descarga de segunda fase")

	boss.health = 0
	boss._physics_process(1.0 / 60.0)
	check(game.boss_defeated() and game.player.dash_unlocked and game.boss_blast > 0, "derrota del jefe y recompensa")

	game.reset_level()
	game.player.global_position = Vector2(593, 267)
	game.current_station.collect_nearby_pickups(game.player)
	check(not game.current_station.secret_collected, "secreto inicial requiere dash desbloqueado")
	game.player.dash_unlocked = true
	game.current_station.collect_nearby_pickups(game.player)
	check(game.current_station.secret_collected, "secreto inicial disponible tras conseguir dash")

	game.reset_level()
	game.player.global_position = Vector2(3250, 437)
	var turret_x := 0.0
	var target_turret: TurretEnemy
	for turret in game.current_station.get_turrets():
		if turret.global_position.x < 3400:
			target_turret = turret as TurretEnemy
			turret_x = target_turret.global_position.x
			target_turret.charge = 0.0
			break
	if target_turret != null:
		target_turret._physics_process(1.0 / 60.0)
	check(game.get_enemy_projectile_count() >= 1, "torreta dispara al jugador cercano")
	check(target_turret != null and target_turret.global_position.x == turret_x, "torreta permanece fija")

	game.reset_level()
	game.player.global_position = Vector2(1780, 437)
	game.use_interaction()
	check(game.room_name == "", "portal bloqueado antes del jefe")

	for version in [1, 2]:
		var file := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.WRITE)
		file.store_string(JSON.stringify({"version": version, "checkpoint_x": 2420.0 if version == 1 else 6550.0, "boss_defeated": true, "secret_collected": true}))
		file.close()
		game.reset_level()
		game.load_progress()
		check(game.player.global_position.x == 6550 and game.player.dash_unlocked and game.player.max_health == 6, "migración de guardado v%d" % version)

	game.set_pause(false)
	game.queue_free()
	await process_frame
	await process_frame
	print("RESULT: ", failures, " failures")
	quit(failures)
