extends EnemyBase

@export var patrol_left := 0.0
@export var patrol_right := 0.0
@export var direction := 1.0
@export var move_speed := 95.0
var initial_position := Vector2.ZERO
var initial_direction := 1.0

func _ready() -> void:
	initial_position = global_position
	initial_direction = direction
	super()

func reset_enemy() -> void:
	global_position = initial_position
	direction = initial_direction
	super.reset_enemy()

func _physics_process(_delta: float) -> void:
	if dead:
		return
	velocity = Vector2(direction * move_speed, 0.0)
	move_and_slide()
	if global_position.x < patrol_left or global_position.x > patrol_right:
		direction *= -1.0
	emit_contact_damage_if_needed()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-18, -17, 36, 34), Color("38517e"))
	draw_rect(Rect2(-13, -12, 26, 19), Color("208baf"))
	draw_rect(Rect2(-9, -6, 18, 6), Color("ff9940"))
