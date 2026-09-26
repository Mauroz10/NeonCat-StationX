extends CharacterBody2D
class_name NeonPlayer

signal shot_requested(origin: Vector2, direction: float)
signal sound_requested(sound_name: String)
signal health_changed(current: int, maximum: int)
signal died
signal dash_started
signal animation_state_changed(state_name: String)
signal visual_state_updated

const MOVE_SPEED := 260.0
const GRAVITY := 1150.0
const JUMP_SPEED := -475.0
const DASH_SPEED := 650.0
const DASH_DURATION := 0.24
const DASH_COOLDOWN := 1.5
const PLAYER_HALF_HEIGHT := 17.0
const FLOOR_Y := 454.0

enum MotionState { NORMAL, DASHING, HURT, DISABLED }

@export var max_health := 5
var health := 5
var facing := 1.0
var jumps_used := 0
var double_jump_flash := 0.0
var jump_elapsed := 0.0
var dash_unlocked := false
var dash_timer := 0.0
var dash_cooldown := 0.0
var fire_timer := 0.0
var invulnerable := 0.0
var hurt_timer := 0.0
var motion_state := MotionState.NORMAL
var test_input_override: Dictionary = {}
var grounded_hint := true
var current_animation_state := "idle"

func _ready() -> void:
	health = max_health
	floor_snap_length = 4.0
	floor_max_angle = deg_to_rad(50.0)

func reset_player(spawn: Vector2, new_max_health: int = 5) -> void:
	global_position = spawn
	velocity = Vector2.ZERO
	max_health = new_max_health
	health = max_health
	facing = 1.0
	jumps_used = 0
	double_jump_flash = 0.0
	jump_elapsed = 0.0
	dash_timer = 0.0
	dash_cooldown = 0.0
	fire_timer = 0.0
	invulnerable = 0.0
	hurt_timer = 0.0
	motion_state = MotionState.NORMAL
	_set_dash_gate_collision(true)
	grounded_hint = true
	current_animation_state = "idle"
	animation_state_changed.emit(current_animation_state)
	health_changed.emit(health, max_health)

func set_max_health(value: int, heal_to_full: bool = false) -> void:
	max_health = maxi(1, value)
	if heal_to_full:
		health = max_health
	else:
		health = mini(health, max_health)
	health_changed.emit(health, max_health)

func add_max_health(amount: int, heal_amount: int = 0) -> void:
	max_health += amount
	health = mini(max_health, health + heal_amount)
	health_changed.emit(health, max_health)

func request_jump() -> void:
	test_input_override["jump"] = true

func request_dash() -> void:
	test_input_override["dash"] = true

func set_test_direction(value: float) -> void:
	test_input_override["direction"] = clampf(value, -1.0, 1.0)

func clear_test_input() -> void:
	test_input_override.clear()

func _physics_process(delta: float) -> void:
	simulate_step(delta)

func simulate_step(delta: float) -> void:
	if motion_state == MotionState.DISABLED:
		return
	_tick_timers(delta)
	var direction := _read_direction()
	if direction != 0.0:
		facing = direction
	var grounded := _prepare_ground_state()
	_handle_jump(grounded)
	_handle_dash()
	_apply_motion(direction, grounded, delta)
	_handle_fire()
	_update_animation_state()
	visual_state_updated.emit()
	test_input_override.erase("direction")

func _prepare_ground_state() -> bool:
	var grounded := _is_grounded_for_step()
	if grounded:
		jumps_used = 0
	elif jumps_used == 0:
		jumps_used = 1
	return grounded

func _handle_jump(grounded: bool) -> void:
	if not _consume_action("jump") or jumps_used >= 2:
		return
	velocity.y = JUMP_SPEED if grounded else JUMP_SPEED * 0.9
	if not grounded:
		double_jump_flash = 0.22
		# El prototipo original solo reproduce jump.wav en el segundo salto.
		sound_requested.emit("jump")
	jumps_used += 1
	jump_elapsed = 0.0
	grounded_hint = false

func _handle_dash() -> void:
	if not _consume_action("dash") or not dash_unlocked or dash_cooldown > 0.0:
		return
	dash_timer = DASH_DURATION
	dash_cooldown = DASH_COOLDOWN
	motion_state = MotionState.DASHING
	_set_dash_gate_collision(false)
	dash_started.emit()
	sound_requested.emit("dash")

func _apply_motion(direction: float, grounded: bool, delta: float) -> void:
	if dash_timer > 0.0:
		velocity.x = facing * DASH_SPEED
	else:
		if motion_state == MotionState.DASHING:
			motion_state = MotionState.NORMAL
			_set_dash_gate_collision(true)
		velocity.x = direction * MOVE_SPEED
	velocity.y += GRAVITY * delta
	if not grounded or velocity.y < 0.0:
		jump_elapsed += delta
	move_and_slide()
	if global_position.y > 590.0:
		died.emit()
		return
	if is_on_floor():
		grounded_hint = true
		if velocity.y >= 0.0:
			jumps_used = 0
	else:
		grounded_hint = false

func _handle_fire() -> void:
	if not _is_fire_pressed() or fire_timer > 0.0:
		return
	shot_requested.emit(global_position + Vector2(facing * 22.0, -3.0), facing)
	sound_requested.emit("shot")
	fire_timer = 0.22

func _update_animation_state() -> void:
	var next_state := "idle"
	if hurt_timer > 0.0:
		next_state = "hurt"
	elif dash_timer > 0.0:
		next_state = "dash"
	elif not _is_grounded_for_step():
		next_state = "jump"
	elif fire_timer > 0.10:
		next_state = "shoot"
	elif absf(velocity.x) > 10.0:
		next_state = "run"
	if next_state != current_animation_state:
		current_animation_state = next_state
		animation_state_changed.emit(current_animation_state)

func _tick_timers(delta: float) -> void:
	invulnerable = maxf(0.0, invulnerable - delta)
	double_jump_flash = maxf(0.0, double_jump_flash - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	if hurt_timer <= 0.0 and motion_state == MotionState.HURT:
		motion_state = MotionState.NORMAL
	fire_timer = maxf(0.0, fire_timer - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)

func _read_direction() -> float:
	if test_input_override.has("direction"):
		return float(test_input_override.direction)
	return Input.get_axis("move_left", "move_right")

func _consume_action(action: String) -> bool:
	if test_input_override.get(action, false) == true:
		test_input_override.erase(action)
		return true
	return Input.is_action_just_pressed(action)

func _is_fire_pressed() -> bool:
	if test_input_override.get("fire", false) == true:
		return true
	return Input.is_action_pressed("fire")

func _is_grounded_for_step() -> bool:
	return is_on_floor() or grounded_hint

func take_damage(amount: int, knockback_y: float = -270.0) -> bool:
	if invulnerable > 0.0 or dash_timer > 0.0 or motion_state == MotionState.DISABLED:
		return false
	health -= amount
	invulnerable = 1.0
	hurt_timer = 0.36
	velocity.y = knockback_y
	motion_state = MotionState.HURT
	sound_requested.emit("hurt")
	health_changed.emit(health, max_health)
	if health <= 0:
		died.emit()
	return true

func heal_full() -> void:
	health = max_health
	health_changed.emit(health, max_health)

func cancel_dash() -> void:
	dash_timer = 0.0
	if motion_state == MotionState.DASHING:
		motion_state = MotionState.NORMAL
	_set_dash_gate_collision(true)

func give_respawn_invulnerability() -> void:
	invulnerable = 1.5

func _set_dash_gate_collision(enabled: bool) -> void:
	# Layer 7 is reserved for barriers that only block the player outside dash.
	set_collision_mask_value(7, enabled)
