extends EnemyBase

@export var patrol_left := 0.0
@export var patrol_right := 0.0
@export var direction := 1.0
@export var move_speed := 60.0
@export var shot_charge := 2.0
var base_y := 0.0
var charge := 2.0
var tick := 0.0
var initial_position := Vector2.ZERO
var initial_direction := 1.0

func _ready() -> void:
	initial_position = global_position
	initial_direction = direction
	base_y = global_position.y
	charge = shot_charge
	super()

func reset_enemy() -> void:
	global_position = initial_position
	direction = initial_direction
	base_y = initial_position.y
	charge = shot_charge
	tick = 0.0
	super.reset_enemy()

func _physics_process(delta: float) -> void:
	if dead:
		return
	tick += delta
	var projected_x := global_position.x + direction * move_speed * delta
	var target_y := base_y + sin(tick * 2.6 + projected_x * 0.01) * 20.0
	velocity = Vector2(direction * move_speed, (target_y - global_position.y) / maxf(delta, 0.000001))
	move_and_slide()
	if global_position.x < patrol_left or global_position.x > patrol_right:
		direction *= -1.0
	var player := get_tree().get_first_node_in_group("player") as NeonPlayer
	if player != null and absf(player.global_position.x - global_position.x) < 420.0:
		charge -= delta
		if charge <= 0.0:
			var aim := (player.global_position - global_position).normalized()
			projectile_requested.emit(global_position, aim * 260.0, 2.0, "turret")
			charge = 2.8
			sound_requested.emit("enemy_shot")
	emit_contact_damage_if_needed()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 15.0, Color("274b75"))
	draw_circle(Vector2.ZERO, 7.0, Color("ff9940") if charge < 0.55 else Color("3ce9ff"))
	for side in [-1.0, 1.0]:
		draw_line(Vector2(side * 12.0, 0), Vector2(side * 30.0, sin(tick * 20.0) * 8.0), Color("3ce9ff"), 4)
