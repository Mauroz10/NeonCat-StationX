extends Area2D
class_name EnemyProjectile

signal expired(projectile)
signal player_hit(projectile, damage, knockback_y)

var velocity := Vector2.ZERO
var life := 2.0
var kind := "orb"
var damage := 1

func setup(origin: Vector2, new_velocity: Vector2, new_life: float, new_kind: String) -> void:
	global_position = origin
	velocity = new_velocity
	life = new_life
	kind = new_kind
	var shape := $CollisionShape2D.shape as CircleShape2D
	if shape != null:
		shape.radius = 18.0 if kind == "wave" else 10.0
	queue_redraw()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	life -= delta
	if life <= 0.0 or global_position.y > 469.0:
		expired.emit(self)
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is NeonPlayer:
		var knockback := -210.0
		player_hit.emit(self, damage, knockback)
		queue_free()

func _draw() -> void:
	match kind:
		"wave":
			draw_rect(Rect2(-17, -12, 34, 22), Color("ff9940"))
		"rain":
			draw_rect(Rect2(-6, -18, 12, 30), Color("ff5de5"))
		"turret":
			draw_circle(Vector2.ZERO, 9.0, Color("ff6a66"))
			draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
		_:
			draw_circle(Vector2.ZERO, 11.0, Color("ff9940"))
