extends CharacterBody2D
class_name SentinelBoss

signal defeated(enemy)
signal sound_requested(sound_name: String)
signal projectile_requested(origin: Vector2, velocity: Vector2, life: float, kind: String)
signal enraged
signal contact_damage(player, amount: int)

const MAX_HEALTH := 10
const CORE_OFFSET := Vector2(-4.0, -30.0)
const FLOOR_Y := 454.0
const ARENA_LEFT := 5940.0
const ARENA_RIGHT := 6850.0

@export var patrol_left := 6210.0
@export var patrol_right := 6290.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var health := MAX_HEALTH
var direction := -1.0
var boss_phase := "windup"
var boss_timer := 1.2
var boss_attack_index := 0
var boss_invulnerable := 0.0
var boss_rain_target := 6200.0
var is_enraged := false
var dead := false
var phase_controller: SentinelPhase = SentinelPhaseOne.new()
var initial_position := Vector2.ZERO
var tick := 0.0
var contact_player: NeonPlayer

var combat_active := false
var phase_transitioning := false
var death_started := false
var death_impact_played := false

func _ready() -> void:
	initial_position = global_position
	add_to_group("enemies")
	add_to_group("boss")
	$ContactArea.body_entered.connect(_on_contact_body_entered)
	$ContactArea.body_exited.connect(_on_contact_body_exited)
	sprite.animation_finished.connect(_on_visual_animation_finished)
	sprite.frame_changed.connect(_on_visual_frame_changed)
	_play_visual(&"walk", true)
	queue_redraw()

func reset_boss() -> void:
	global_position = initial_position
	health = MAX_HEALTH
	direction = -1.0
	boss_phase = "windup"
	boss_timer = 1.2
	boss_attack_index = 0
	boss_invulnerable = 0.0
	boss_rain_target = 6200.0
	is_enraged = false
	dead = false
	combat_active = false
	phase_transitioning = false
	death_started = false
	death_impact_played = false
	contact_player = null
	phase_controller = SentinelPhaseOne.new()
	velocity = Vector2.ZERO
	if not is_in_group("enemies"):
		add_to_group("enemies")
	if not is_in_group("boss"):
		add_to_group("boss")
	visible = true
	set_physics_process(true)
	_update_hitboxes()
	_play_visual(&"walk", true)
	queue_redraw()

func reset_after_player_death() -> void:
	health = MAX_HEALTH
	boss_phase = "windup"
	boss_timer = 1.5
	boss_attack_index = 0
	boss_invulnerable = 0.0
	is_enraged = false
	dead = false
	combat_active = false
	phase_transitioning = false
	death_started = false
	death_impact_played = false
	contact_player = null
	phase_controller = SentinelPhaseOne.new()
	velocity = Vector2.ZERO
	visible = true
	set_physics_process(true)
	_update_hitboxes()
	_play_visual(&"walk", true)
	queue_redraw()

func _physics_process(delta: float) -> void:
	tick += delta
	_evaluate_health_state()
	_update_hitboxes()
	if dead:
		velocity = Vector2.ZERO
		return

	boss_invulnerable = maxf(0.0, boss_invulnerable - delta)
	_update_visual_tint()

	velocity = Vector2(direction * 22.0, 0.0)
	move_and_slide()
	if global_position.x < patrol_left or global_position.x > patrol_right:
		direction *= -1.0

	var player := get_tree().get_first_node_in_group("player") as NeonPlayer
	var player_in_arena := player != null and player.global_position.x > ARENA_LEFT and player.global_position.x < ARENA_RIGHT
	if player_in_arena:
		sprite.flip_h = player.global_position.x < global_position.x
		if not combat_active:
			combat_active = true
			if boss_phase == "exposed":
				_play_visual(&"core_exposed", true)
			else:
				_begin_windup_visual()
		update_attack(delta, player.global_position)
	else:
		combat_active = false
		sprite.flip_h = direction > 0.0
		if not _visual_is_transient():
			_play_visual(&"walk")

	if contact_player != null and is_instance_valid(contact_player):
		contact_damage.emit(contact_player, 1)
	queue_redraw()

func receive_player_bullet(hit_position: Vector2) -> bool:
	if dead:
		return false
	if boss_phase != "exposed":
		return true
	var weakpoint := global_position + CORE_OFFSET
	if absf(hit_position.x - weakpoint.x) >= 19.0 or absf(hit_position.y - weakpoint.y) >= 16.0:
		return false
	if boss_invulnerable > 0.0:
		return true
	health -= 1
	boss_invulnerable = 0.25
	sound_requested.emit("sentinel_hit")
	_play_visual(&"hit", true)
	_evaluate_health_state()
	_update_hitboxes()
	queue_redraw()
	return true

func _evaluate_health_state() -> void:
	if dead:
		return
	if health <= 0:
		dead = true
		death_started = true
		contact_player = null
		velocity = Vector2.ZERO
		phase_transitioning = false
		remove_from_group("enemies")
		remove_from_group("boss")
		_update_hitboxes()
		sound_requested.emit("sentinel_death_fault")
		_play_visual(&"death", true)
		defeated.emit(self)
		queue_redraw()
		return
	if health <= MAX_HEALTH / 2 and not is_enraged:
		is_enraged = true
		phase_controller = SentinelPhaseTwo.new()
		boss_phase = "windup"
		boss_timer = 1.4
		phase_transitioning = true
		enraged.emit()
		sound_requested.emit("sentinel_phase2")
		_play_visual(&"phase_transition", true)

func _update_hitboxes() -> void:
	if not is_node_ready():
		return
	var exposed := boss_phase == "exposed" and not dead
	$ArmorHitbox.collision_layer = 0 if exposed or dead else 4
	$WeakPoint.collision_layer = 4 if exposed else 0

func update_attack(delta: float, player_position: Vector2) -> void:
	boss_timer -= delta
	if boss_timer > 0.0:
		return
	if boss_phase == "windup":
		_execute_attack(player_position)
		phase_transitioning = false
		boss_phase = "exposed"
		boss_timer = phase_controller.exposed_duration()
		_play_release_visual()
	else:
		boss_attack_index += 1
		boss_phase = "windup"
		boss_timer = phase_controller.windup_duration()
		if boss_attack_index % 3 == 2:
			boss_rain_target = clampf(player_position.x, 6085.0, 6435.0)
		_begin_windup_visual()
	_update_hitboxes()

func _execute_attack(player_position: Vector2) -> void:
	sound_requested.emit("sentinel_shot")
	match boss_attack_index % 3:
		0:
			var toward := (player_position - Vector2(global_position.x, FLOOR_Y - 31.0)).normalized()
			for offset in phase_controller.fan_offsets():
				projectile_requested.emit(Vector2(global_position.x, FLOOR_Y - 31.0), toward.rotated(float(offset)) * phase_controller.fan_speed(), 2.5, "orb")
		1:
			var wave_sign := -1.0 if player_position.x < global_position.x else 1.0
			projectile_requested.emit(Vector2(global_position.x - 42.0, FLOOR_Y - 10.0), Vector2(wave_sign * phase_controller.wave_speed(), 0.0), 2.1, "wave")
		2:
			for offset in phase_controller.rain_offsets():
				var strike_x := clampf(boss_rain_target + float(offset), 6000.0, 6520.0)
				projectile_requested.emit(Vector2(strike_x, 70.0), Vector2(0.0, 300.0), 1.5, "rain")

func _begin_windup_visual() -> void:
	if dead or phase_transitioning:
		return
	if boss_attack_index % 3 == 2:
		sound_requested.emit("sentinel_charge")
		_play_visual(&"vertical_charge", true)
	else:
		_play_visual(&"shoot_charge", true)

func _play_release_visual() -> void:
	if dead:
		return
	if boss_attack_index % 3 == 2:
		_play_visual(&"vertical_release", true)
	else:
		_play_visual(&"shoot_release", true)

func force_attack_now(player_position: Vector2) -> void:
	boss_timer = 0.0
	update_attack(0.01, player_position)

func _play_visual(animation_name: StringName, restart: bool = false) -> void:
	if not is_node_ready():
		return
	if restart or sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)

func _visual_is_transient() -> bool:
	return sprite.animation in [&"hit", &"shoot_release", &"vertical_release", &"phase_transition", &"core_open", &"death"]

func _on_visual_animation_finished() -> void:
	if dead:
		if sprite.animation == &"death":
			sprite.stop()
			sprite.frame = sprite.sprite_frames.get_frame_count(&"death") - 1
		return
	match sprite.animation:
		&"hit":
			_restore_visual_for_state()
		&"shoot_release", &"vertical_release":
			if boss_phase == "exposed":
				_play_visual(&"core_open", true)
		&"core_open":
			if boss_phase == "exposed":
				_play_visual(&"core_exposed", true)
		&"phase_transition":
			# Hold the final overload pose until the original windup timer completes.
			pass

func _on_visual_frame_changed() -> void:
	if dead and sprite.animation == &"death" and sprite.frame == 3 and not death_impact_played:
		death_impact_played = true
		sound_requested.emit("sentinel_death_impact")

func _restore_visual_for_state() -> void:
	if dead:
		_play_visual(&"death")
	elif phase_transitioning:
		_play_visual(&"phase_transition")
	elif boss_phase == "exposed":
		_play_visual(&"core_exposed", true)
	elif combat_active:
		_begin_windup_visual()
	else:
		_play_visual(&"walk")

func _update_visual_tint() -> void:
	if boss_invulnerable > 0.0:
		sprite.modulate = Color(1.75, 1.25, 1.25)
	elif is_enraged:
		# Phase two is communicated mainly by the animation; this subtle tint keeps its cyan energy brighter.
		sprite.modulate = Color(0.92, 1.08, 1.12)
	else:
		sprite.modulate = Color.WHITE

func _on_contact_body_entered(body: Node) -> void:
	if body is NeonPlayer and not dead:
		contact_player = body as NeonPlayer
		contact_damage.emit(contact_player, 1)

func _on_contact_body_exited(body: Node) -> void:
	if body == contact_player:
		contact_player = null

func _draw() -> void:
	if dead:
		return
	var c := Vector2.ZERO
	draw_circle(CORE_OFFSET, 11.0, Color("ffab31") if boss_phase == "exposed" else Color("30304d"))
	if boss_phase == "exposed":
		draw_arc(CORE_OFFSET, 20.0 + sin(tick * 12.0) * 3.0, 0.0, TAU, 20, Color("ffffff") if boss_invulnerable > 0.0 else Color("ffce64"), 3.0)
	if boss_phase == "windup":
		draw_arc(c, 60.0, 0, TAU, 24, Color("ff9940"), 3)
		if phase_transitioning:
			_label("SOBRECARGA", Vector2(-50, -118), 14, Color("60ecd8"))
		else:
			_label(["ABANICO", "ONDA", "DESCARGA"][boss_attack_index % 3], Vector2(-43, -118), 14, Color("ff9940"))
		if boss_attack_index % 3 == 2 and not phase_transitioning:
			for offset in phase_controller.rain_offsets():
				var strike_x := clampf(boss_rain_target + float(offset), 6000.0, 6520.0) - global_position.x
				draw_rect(Rect2(strike_x - 12.0, FLOOR_Y - global_position.y - 5.0, 24.0, 5.0), Color("ff5de5"))
				draw_line(Vector2(strike_x, 85.0 - global_position.y), Vector2(strike_x, FLOOR_Y - global_position.y - 8.0), Color(1.0, 0.36, 0.9, 0.28), 2.0)
	else:
		_label("¡DISPARA AL NÚCLEO!", Vector2(-98, -147), 17, Color("ffdf83"))
	var bar_width := 96.0
	draw_rect(Rect2(-bar_width * 0.5, -118.0, bar_width, 6), Color("283453"))
	draw_rect(Rect2(-bar_width * 0.5, -118.0, bar_width * float(maxi(health, 0)) / float(MAX_HEALTH), 6), Color("ff9940"))

func _label(value: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
