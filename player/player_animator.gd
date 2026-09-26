extends Node

@onready var player: NeonPlayer = get_parent() as NeonPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const RUN_SCALE := 55.0 / 650.0
const JUMP_SCALE := 55.0 / 696.0
const SHOOT_SCALE := 55.0 / 680.0
const DASH_SCALE := 55.0 / 680.0
const HURT_SCALE := 55.0 / 685.0

func _ready() -> void:
	player.animation_state_changed.connect(_on_animation_state_changed)
	player.visual_state_updated.connect(_sync_motion_frame)
	sprite.frame_changed.connect(_apply_frame_layout)
	_on_animation_state_changed("idle")

func _process(_delta: float) -> void:
	sprite.flip_h = player.facing < 0.0
	sprite.visible = player.hurt_timer > 0.0 or player.invulnerable <= 0.0 or int(Time.get_ticks_msec() / 70) % 2 == 0
	sprite.modulate = Color(1.0, 0.65, 0.65) if player.hurt_timer > 0.0 else Color.WHITE

func _on_animation_state_changed(state_name: String) -> void:
	if state_name in ["idle", "run"]:
		sprite.play(state_name)
	else:
		sprite.animation = state_name
		sprite.pause()
	_sync_motion_frame()
	_apply_frame_layout()

func _sync_motion_frame() -> void:
	match player.current_animation_state:
		"hurt":
			sprite.frame = 0 if player.hurt_timer > 0.24 else (1 if player.hurt_timer > 0.12 else 2)
		"dash":
			sprite.frame = 0 if player.dash_timer > 0.18 else (1 if player.dash_timer > 0.05 else 2)
		"jump":
			sprite.frame = 0 if player.jump_elapsed < 0.11 else (1 if player.velocity.y < -110.0 else (2 if player.velocity.y < 180.0 else 3))
		"shoot":
			sprite.frame = 0 if player.fire_timer > 0.16 else (1 if player.fire_timer > 0.08 else 2)
	_apply_frame_layout()

func _apply_frame_layout() -> void:
	match player.current_animation_state:
		"idle":
			var texture := sprite.sprite_frames.get_frame_texture(&"idle", sprite.frame) as AtlasTexture
			var region_height := texture.region.size.y if texture != null else 651.0
			var region_width := texture.region.size.x if texture != null else 531.0
			var scale_factor := 55.0 / region_height
			sprite.scale = Vector2.ONE * scale_factor
			sprite.position = Vector2(-region_width * scale_factor * 0.5, -38.0)
		"run":
			sprite.scale = Vector2.ONE * RUN_SCALE
			sprite.position = Vector2(-543.0 * RUN_SCALE * 0.5, 17.0 - 690.0 * RUN_SCALE)
		"jump":
			var texture := sprite.sprite_frames.get_frame_texture(&"jump", sprite.frame) as AtlasTexture
			var region_size := texture.region.size if texture != null else Vector2(495, 520)
			sprite.scale = Vector2.ONE * JUMP_SCALE
			sprite.position = Vector2(-region_size.x * JUMP_SCALE * 0.5, -16.0 - region_size.y * JUMP_SCALE * 0.5)
		"shoot":
			sprite.scale = Vector2.ONE * SHOOT_SCALE
			sprite.position = Vector2(-724.0 * SHOOT_SCALE * 0.5, 17.0 - 700.0 * SHOOT_SCALE)
		"dash":
			sprite.scale = Vector2.ONE * DASH_SCALE
			sprite.position = Vector2(-724.0 * DASH_SCALE * 0.5, 17.0 - 700.0 * DASH_SCALE)
		"hurt":
			sprite.scale = Vector2.ONE * HURT_SCALE
			sprite.position = Vector2(-724.0 * HURT_SCALE * 0.5, 17.0 - 724.0 * HURT_SCALE)
