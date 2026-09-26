extends CharacterBody2D
class_name EnemyBase

signal defeated(enemy)
signal sound_requested(sound_name: String)
signal contact_damage(player, amount: int)
signal projectile_requested(origin: Vector2, velocity: Vector2, life: float, kind: String)

@export var max_health := 2
@export var contact_damage_amount := 1
var health := 2
var dead := false
var contact_player: NeonPlayer

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	var contact_area := get_node_or_null("ContactArea") as Area2D
	if contact_area != null:
		contact_area.body_entered.connect(_on_contact_body_entered)
		contact_area.body_exited.connect(_on_contact_body_exited)
	queue_redraw()

func reset_enemy() -> void:
	health = max_health
	dead = false
	contact_player = null
	visible = true
	set_physics_process(true)
	queue_redraw()

func receive_player_bullet(_hit_position: Vector2) -> bool:
	if dead:
		return false
	take_damage(1)
	return true

func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	sound_requested.emit("hit")
	if health <= 0:
		_die()
	queue_redraw()

func _die() -> void:
	if dead:
		return
	dead = true
	contact_player = null
	defeated.emit(self)

func _on_contact_body_entered(body: Node) -> void:
	if body is NeonPlayer and not dead:
		contact_player = body as NeonPlayer
		contact_damage.emit(contact_player, contact_damage_amount)

func _on_contact_body_exited(body: Node) -> void:
	if body == contact_player:
		contact_player = null

func emit_contact_damage_if_needed() -> void:
	if contact_player != null and is_instance_valid(contact_player) and not dead:
		contact_damage.emit(contact_player, contact_damage_amount)
