extends SceneTree

const SAVE_SYSTEM_SCRIPT := preload(
	"res://autoload/save_system.gd"
)

const TEST_SAVE_PATH := "user://station_g7_save.json"

var failures: int = 0


func _initialize() -> void:
	call_deferred("run_checks")


func check(value: bool, name: String) -> void:
	if not value:
		failures += 1
		printerr(
			"FAIL: " + name
		)
	else:
		print(
			"PASS: " + name
		)


func run_checks() -> void:
	if OS.get_environment("NEON_TEST_RUN") != "1":
		printerr(
			"Ejecuta las pruebas con NEON_TEST_RUN=1 y XDG_DATA_HOME temporal."
		)
		quit(1)
		return

	# Cuando Godot ejecuta este archivo directamente con --script,
	# garantizamos que exista /root/SaveSystem.
	if root.get_node_or_null("SaveSystem") == null:
		var save_system: Node = SAVE_SYSTEM_SCRIPT.new()
		save_system.name = "SaveSystem"
		root.add_child(save_system)

	# Empezar siempre las pruebas sin un guardado anterior.
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(
				TEST_SAVE_PATH
			)
		)

	var packed_game: PackedScene = load(
		"res://scenes/game.tscn"
	)

	if packed_game == null:
		printerr(
			"FAIL: no se pudo cargar scenes/game.tscn"
		)
		quit(1)
		return

	var game: GameManager = (
		packed_game.instantiate()
		as GameManager
	)

	if game == null:
		printerr(
			"FAIL: game.tscn no creó un GameManager válido"
		)
		quit(1)
		return

	root.add_child(game)

	await process_frame

	# ---------------------------------------------------------
	# 1. PRIMER SALTO
	# ---------------------------------------------------------

	game.reset_level()

	game.player.request_jump()

	game.simulate_game_step(
		1.0 / 60.0
	)

	check(
		game.player.jumps_used == 1
		and game.player.velocity.y < 0,
		"primer salto"
	)

	# ---------------------------------------------------------
	# 2. DOBLE SALTO
	# ---------------------------------------------------------

	game.player.request_jump()

	game.simulate_game_step(
		1.0 / 60.0
	)

	check(
		game.player.jumps_used == 2
		and game.player.double_jump_flash > 0,
		"doble salto"
	)

	# ---------------------------------------------------------
	# 3. NO TERCER SALTO
	# ---------------------------------------------------------

	game.player.request_jump()

	var previous: float = (
		game.player.velocity.y
	)

	game.simulate_game_step(
		1.0 / 60.0
	)

	check(
		game.player.jumps_used == 2
		and game.player.velocity.y > previous,
		"no tercer salto"
	)

	# ---------------------------------------------------------
	# 4. POZO SIN SUELO INVISIBLE
	# ---------------------------------------------------------

	game.player.global_position = Vector2(
		2580,
		440
	)

	game.player.velocity = Vector2.ZERO
	game.player.grounded_hint = false

	for _i in range(12):
		game.simulate_game_step(
			1.0 / 60.0
		)

	check(
		game.player.global_position.y > 450,
		"pozo permite caer sin suelo invisible"
	)

	# ---------------------------------------------------------
	# 5. SECRETO ELEVADO
	# ---------------------------------------------------------

	game.reset_level()

	game.player.global_position = Vector2(
		3060,
		188
	)

	game.current_station.collect_nearby_pickups(
		game.player
	)

	check(
		game.player.max_health == 6
		and game.current_station.route_rewards.has(
			"workshop"
		),
		"secreto elevado y recompensa"
	)

	# ---------------------------------------------------------
	# 6. RECOMPENSA UNA SOLA VEZ
	# ---------------------------------------------------------

	game.current_station.collect_nearby_pickups(
		game.player
	)

	check(
		game.player.max_health == 6,
		"recompensa una sola vez"
	)

	# ---------------------------------------------------------
	# 7. TRANVÍA VUELVE AL INICIO
	# ---------------------------------------------------------

	game.current_station.boss_was_defeated = true
	game.player.dash_unlocked = true

	game.player.global_position = Vector2(
		6630,
		437
	)

	game.use_interaction()

	check(
		game.player.global_position.x == 180,
		"tranvía vuelve al inicio"
	)

	# ---------------------------------------------------------
	# 8. TRANVÍA DE REGRESO AL JEFE
	# ---------------------------------------------------------

	game.use_interaction()

	check(
		game.player.global_position.x == 6630,
		"tranvía de regreso al jefe"
	)

	# ---------------------------------------------------------
	# 9. ENTRADA A MINAS
	# ---------------------------------------------------------

	game.player.global_position = Vector2(
		1780,
		437
	)

	var enemy_count: int = (
		game.get_active_enemy_count()
	)

	game.use_interaction()

	check(
		game.room_name == "Minas Bioluminosas"
		and game.get_active_enemy_count() == 0,
		"entrada a Minas"
	)

	# ---------------------------------------------------------
	# 10. REGRESO CONSERVA ESTACIÓN
	# ---------------------------------------------------------

	game.use_interaction()

	check(
		game.room_name == ""
		and game.player.global_position.x == 1780
		and game.get_active_enemy_count() == enemy_count,
		"regreso conserva enemigos y estación"
	)

	# ---------------------------------------------------------
	# 11. ENTRADA A FÁBRICA
	# ---------------------------------------------------------

	game.player.global_position = Vector2(
		8330,
		437
	)

	game.use_interaction()

	check(
		game.room_name == "Fábrica Omega",
		"entrada a Fábrica"
	)

	game.leave_gateway()

	# ---------------------------------------------------------
	# 12. MAPA CONGELA EL JUEGO
	# ---------------------------------------------------------

	game.set_pause(
		true,
		true
	)

	var old_x: float = (
		game.player.global_position.x
	)

	game.simulate_game_step(
		0.5
	)

	check(
		game.player.global_position.x == old_x
		and game.map_open,
		"mapa congela el juego"
	)

	game.set_pause(false)

	# ---------------------------------------------------------
	# 13. GUARDADO V3
	# ---------------------------------------------------------

	game.current_station.current_checkpoint = Vector2(
		6550,
		437
	)

	game.current_station.complete = true

	# Conservamos el estado del jefe derrotado y el secreto que
	# ya se obtuvieron durante las pruebas anteriores.
	game.save_progress()

	game.reset_level()
	game.load_progress()

	check(
		game.boss_defeated()
		and game.station_complete()
		and game.player.max_health == 6
		and game.player.global_position.x == 6550,
		"guardado v3 restaura progreso"
	)

	# ---------------------------------------------------------
	# 14. SEGUNDA FASE A MITAD DE VIDA
	# ---------------------------------------------------------

	game.reset_level()

	game.player.global_position = Vector2(
		6010,
		437
	)

	var boss: SentinelBoss = (
		game.current_station.get_boss()
	)

	if boss != null:
		boss.health = 5

		boss._physics_process(
			1.0 / 60.0
		)

	check(
		boss != null
		and boss.is_enraged,
		"segunda fase a mitad de vida"
	)

	# ---------------------------------------------------------
	# 15. SEGUNDA FASE DISPARA CINCO PROYECTILES
	# ---------------------------------------------------------

	if boss != null:
		boss.boss_attack_index = 0
		boss.boss_phase = "windup"

		boss.force_attack_now(
			game.player.global_position
		)

	check(
		game.get_enemy_projectile_count() == 5,
		"segunda fase dispara cinco proyectiles"
	)

	game.clear_enemy_projectiles()

	# ---------------------------------------------------------
	# 16. DESCARGA DE SEGUNDA FASE
	# ---------------------------------------------------------

	if boss != null:
		boss.boss_attack_index = 2
		boss.boss_phase = "windup"

		boss.force_attack_now(
			game.player.global_position
		)

	check(
		game.get_enemy_projectile_count() == 5,
		"descarga de segunda fase"
	)

	# ---------------------------------------------------------
	# 17. DERROTA DEL JEFE
	# ---------------------------------------------------------

	if boss != null:
		boss.health = 0

		boss._physics_process(
			1.0 / 60.0
		)

	check(
		game.boss_defeated()
		and game.player.dash_unlocked
		and game.boss_blast > 0,
		"derrota del jefe y recompensa"
	)

	# ---------------------------------------------------------
	# 18. SECRETO INICIAL REQUIERE DASH
	# ---------------------------------------------------------

	game.reset_level()

	game.player.global_position = Vector2(
		593,
		267
	)

	game.current_station.collect_nearby_pickups(
		game.player
	)

	check(
		not game.current_station.secret_collected,
		"secreto inicial requiere dash desbloqueado"
	)

	# ---------------------------------------------------------
	# 19. SECRETO DISPONIBLE CON DASH
	# ---------------------------------------------------------

	game.player.dash_unlocked = true

	game.current_station.collect_nearby_pickups(
		game.player
	)

	check(
		game.current_station.secret_collected,
		"secreto inicial disponible tras conseguir dash"
	)

	# ---------------------------------------------------------
	# 20. TORRETA DISPARA
	# ---------------------------------------------------------

	game.reset_level()

	game.player.global_position = Vector2(
		3250,
		437
	)

	var turret_x: float = 0.0
	var target_turret: TurretEnemy = null

	for turret in game.current_station.get_turrets():
		if turret.global_position.x < 3400:
			target_turret = (
				turret
				as TurretEnemy
			)

			if target_turret != null:
				turret_x = (
					target_turret.global_position.x
				)

				target_turret.charge = 0.0

			break

	if target_turret != null:
		target_turret._physics_process(
			1.0 / 60.0
		)

	check(
		game.get_enemy_projectile_count() >= 1,
		"torreta dispara al jugador cercano"
	)

	# ---------------------------------------------------------
	# 21. TORRETA PERMANECE FIJA
	# ---------------------------------------------------------

	check(
		target_turret != null
		and target_turret.global_position.x == turret_x,
		"torreta permanece fija"
	)

	# ---------------------------------------------------------
	# 22. PORTAL BLOQUEADO ANTES DEL JEFE
	# ---------------------------------------------------------

	game.reset_level()

	game.player.global_position = Vector2(
		1780,
		437
	)

	game.use_interaction()

	check(
		game.room_name == "",
		"portal bloqueado antes del jefe"
	)

	# ---------------------------------------------------------
	# 23 Y 24. MIGRACIONES V1 Y V2
	# ---------------------------------------------------------

	for version in [1, 2]:
		var checkpoint_x: float = (
			2420.0
			if version == 1
			else 6550.0
		)

		var legacy_data: Dictionary = {
			"version": version,
			"checkpoint_x": checkpoint_x,
			"boss_defeated": true,
			"secret_collected": true,
		}

		var file: FileAccess = FileAccess.open(
			TEST_SAVE_PATH,
			FileAccess.WRITE
		)

		if file == null:
			check(
				false,
				"migración de guardado v%d" % version
			)
			continue

		file.store_string(
			JSON.stringify(
				legacy_data
			)
		)

		file.close()

		game.reset_level()
		game.load_progress()

		check(
			game.player.global_position.x == 6550
			and game.player.dash_unlocked
			and game.player.max_health == 6,
			"migración de guardado v%d" % version
		)

	# ---------------------------------------------------------
	# LIMPIEZA
	# ---------------------------------------------------------

	game.set_pause(false)

	game.queue_free()

	await process_frame
	await process_frame

	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(
				TEST_SAVE_PATH
			)
		)

	print(
		"RESULT: ",
		failures,
		" failures"
	)

	quit(failures)