extends Node2D

@onready var player: NeonPlayer = get_parent() as NeonPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const LOOPED_STATES := ["idle", "walk", "run"]
const AUTO_STATES := ["land", "death", "victory", "dash_unlock"]

func _ready() -> void:
    player.animation_state_changed.connect(_on_animation_state_changed)
    player.visual_state_updated.connect(_sync_motion_frame)
    _on_animation_state_changed("idle")

func _process(_delta: float) -> void:
    sprite.flip_h = player.facing < 0.0
    sprite.visible = (
        player.hurt_timer > 0.0
        or player.invulnerable <= 0.0
        or int(Time.get_ticks_msec() / 70) % 2 == 0
    )
    sprite.modulate = (
        Color(1.0, 0.65, 0.65)
        if player.hurt_timer > 0.0
        else Color.WHITE
    )

func _on_animation_state_changed(state_name: String) -> void:
    var animation_name := StringName(state_name)
    if not sprite.sprite_frames.has_animation(animation_name):
        animation_name = &"idle"

    if state_name in LOOPED_STATES or state_name in AUTO_STATES:
        sprite.play(animation_name)
    else:
        sprite.animation = animation_name
        sprite.pause()

    _sync_motion_frame()

func _sync_motion_frame() -> void:
    match player.current_animation_state:
        "hit":
            sprite.frame = (
                0 if player.hurt_timer > 0.24
                else (1 if player.hurt_timer > 0.12 else 2)
            )

        "dash":
            sprite.frame = (
                0 if player.dash_timer > 0.18
                else (1 if player.dash_timer > 0.12 else (2 if player.dash_timer > 0.06 else 3))
            )

        "jump":
            sprite.frame = (
                0 if player.jump_elapsed < 0.11
                else (1 if player.velocity.y < -110.0 else (2 if player.velocity.y < 180.0 else 3))
            )

        "double_jump":
            sprite.frame = (
                0 if player.double_jump_flash > 0.165
                else (1 if player.double_jump_flash > 0.11 else (2 if player.double_jump_flash > 0.055 else 3))
            )

        "shoot":
            sprite.frame = (
                0 if player.fire_timer > 0.165
                else (1 if player.fire_timer > 0.11 else (2 if player.fire_timer > 0.055 else 3))
            )
