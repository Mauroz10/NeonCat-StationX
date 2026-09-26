extends Area2D
class_name TurretEnemy

signal defeated(enemy)
signal sound_requested(sound_name: String)
signal projectile_requested(origin: Vector2, velocity: Vector2, life: float, kind: String)
signal contact_damage(player, amount: int)

@export var max_health := 2
@export var shot_charge := 1.7
var health := 2
var charge := 1.7
var dead := false
var initial_position := Vector2.ZERO
var contact_player: NeonPlayer

func _ready() -> void:
	initial_position = global_position
	health = max_health
	charge = shot_charge
	add_to_group("enemies")
	$ContactArea.body_entered.connect(_on_body_entered)
	$ContactArea.body_exited.connect(_on_body_exited)
	queue_redraw()

func reset_enemy() -> void:
	global_position = initial_position
	health = max_health
	charge = shot_charge
	dead = false
	contact_player = null
	visible = true
	set_physics_process(true)
	queue_redraw()

func receive_player_bullet(_hit_position: Vector2) -> bool:
	if dead:
		return false
	health -= 1
	sound_requested.emit("hit")
	if health <= 0:
		dead = true
		defeated.emit(self)
	queue_redraw()
	return true

func _physics_process(delta: float) -> void:
	if dead:
		return
	var player := get_tree().get_first_node_in_group("player") as NeonPlayer
	if player != null and absf(player.global_position.x - global_position.x) < 420.0:
		charge -= delta
		if charge <= 0.0:
			var aim := (player.global_position - global_position).normalized()
			projectile_requested.emit(global_position, aim * 260.0, 2.0, "turret")
			charge = 2.5
			sound_requested.emit("enemy_shot")
	if contact_player != null and is_instance_valid(contact_player):
		contact_damage.emit(contact_player, 1)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body is NeonPlayer and not dead:
		contact_player = body as NeonPlayer
		contact_damage.emit(contact_player, 1)

func _on_body_exited(body: Node) -> void:
	if body == contact_player:
		contact_player = null

func _draw() -> void:
	draw_rect(Rect2(-16, -15, 32, 30), Color("32496b"))
	draw_circle(Vector2.ZERO, 10.0, Color("ff6a66") if charge < 0.55 else Color("3ce9ff"))
