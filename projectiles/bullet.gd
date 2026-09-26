extends Area2D
class_name PlayerBullet

signal expired(projectile)
signal hit_enemy(enemy, projectile)

const SPEED := 670.0
const LIFETIME := 1.3
var direction := 1.0
var life := LIFETIME

func setup(origin: Vector2, new_direction: float) -> void:
	global_position = origin
	direction = signf(new_direction) if new_direction != 0.0 else 1.0

func _physics_process(delta: float) -> void:
	global_position.x += direction * SPEED * delta
	life -= delta
	if life <= 0.0:
		expired.emit(self)
		queue_free()

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area2D) -> void:
	var target: Node = area if area.has_method("receive_player_bullet") else area.get_parent()
	if target != null and target.has_method("receive_player_bullet"):
		if target.call("receive_player_bullet", global_position):
			hit_enemy.emit(target, self)
			queue_free()

func _on_body_entered(body: Node) -> void:
	if body != null and body.has_method("receive_player_bullet"):
		if body.receive_player_bullet(global_position):
			hit_enemy.emit(body, self)
			queue_free()

func _draw() -> void:
	draw_rect(Rect2(-7, -3, 14, 6), Color("3ce9ff"))
	draw_rect(Rect2(-2, -2, 8, 4), Color.WHITE)
