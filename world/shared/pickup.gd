extends Area2D
class_name NeonPickup

signal collected(pickup)

@export_enum("score", "secret") var pickup_type := "score"
@export var pickup_id := ""
@export var score_reward := 10
@export var max_health_reward := 0
@export var requires_dash := false
@export var collect_radius := 29.0
var consumed := false
var tick := 0.0
var candidate_player: NeonPlayer

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()

func _process(delta: float) -> void:
	tick += delta
	if candidate_player != null and is_instance_valid(candidate_player):
		try_collect(candidate_player)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body is NeonPlayer:
		candidate_player = body as NeonPlayer
		try_collect(candidate_player)

func _on_body_exited(body: Node) -> void:
	if body == candidate_player:
		candidate_player = null

func try_collect(player: NeonPlayer) -> bool:
	if consumed:
		return false
	if player.global_position.distance_to(global_position) >= collect_radius:
		return false
	if requires_dash and not player.dash_unlocked:
		return false
	consumed = true
	candidate_player = null
	collected.emit(self)
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	return true

func reset_pickup() -> void:
	consumed = false
	candidate_player = null
	visible = true
	$CollisionShape2D.disabled = false

func mark_consumed() -> void:
	consumed = true
	candidate_player = null
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)

func _draw() -> void:
	var bob := sin(tick * 4.0) * 4.0
	if pickup_type == "secret":
		draw_circle(Vector2(0, bob), 18, Color("60ffd0"))
		draw_circle(Vector2(0, bob), 10, Color("147d79"))
		draw_rect(Rect2(-3, bob - 7, 6, 14), Color.WHITE)
		draw_rect(Rect2(-7, bob - 3, 14, 6), Color.WHITE)
	else:
		draw_circle(Vector2(0, bob), 12, Color("ffd24f"))
		draw_circle(Vector2(0, bob), 6, Color("fff2ab"))
