extends Node2D

@onready var player: NeonPlayer = get_parent() as NeonPlayer
@onready var sprite: AnimatedSprite2D = get_node("../Animator/AnimatedSprite2D") as AnimatedSprite2D
var afterimages: Array[Dictionary] = []
var afterimage_clock := 0.0

func _ready() -> void:
	player.dash_started.connect(_on_dash_started)

func _process(delta: float) -> void:
	if player.dash_timer > 0.0:
		afterimage_clock -= delta
		if afterimage_clock <= 0.0:
			_spawn_afterimage()
			afterimage_clock = 0.045
	for i in range(afterimages.size() - 1, -1, -1):
		var ghost_data: Dictionary = afterimages[i]
		ghost_data["life"] = float(ghost_data["life"]) - delta
		var ghost := ghost_data["sprite"] as Sprite2D
		if ghost != null and is_instance_valid(ghost):
			var alpha := 0.24 * maxf(0.0, float(ghost_data["life"])) / 0.26
			ghost.modulate = Color(0.55, 1.0, 0.78, alpha)
		if float(ghost_data["life"]) <= 0.0:
			if ghost != null and is_instance_valid(ghost):
				ghost.queue_free()
			afterimages.remove_at(i)
	queue_redraw()

func _on_dash_started() -> void:
	afterimage_clock = 0.0

func _spawn_afterimage() -> void:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return
	var ghost := Sprite2D.new()
	ghost.top_level = true
	ghost.centered = sprite.centered
	ghost.texture = texture
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.scale = sprite.global_scale
	ghost.flip_h = sprite.flip_h
	ghost.global_position = sprite.global_position
	ghost.z_index = 4
	ghost.modulate = Color(0.55, 1.0, 0.78, 0.24)
	add_child(ghost)
	afterimages.append({"sprite": ghost, "life": 0.26})

func clear() -> void:
	for ghost_data in afterimages:
		var ghost := ghost_data["sprite"] as Sprite2D
		if ghost != null and is_instance_valid(ghost):
			ghost.queue_free()
	afterimages.clear()
	queue_redraw()

func _draw() -> void:
	if player.double_jump_flash > 0.0:
		var burst := 1.0 - player.double_jump_flash / 0.22
		draw_arc(Vector2(0, 17), 14.0 + 24.0 * burst, 0.0, TAU, 24, Color(0.28, 1.0, 0.82, player.double_jump_flash / 0.22), 3.0)
	if player.dash_timer > 0.0:
		for i in range(4):
			var line_y := -22.0 + float(i) * 7.0
			var far_x := -player.facing * (65.0 + float(i % 3) * 12.0)
			var near_x := -player.facing * (18.0 + float(i % 2) * 8.0)
			draw_line(Vector2(far_x, line_y), Vector2(near_x, line_y), Color(0.20, 1.0, 0.48, 0.45 - float(i) * 0.06), 2.0 if i % 2 == 0 else 1.0)
