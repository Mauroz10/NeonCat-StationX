extends Node2D

const CYAN := Color("3ce9ff")
const CYAN_SOFT := Color("8df4ff")
const BLUE_DARK := Color(0.025, 0.075, 0.16, 0.94)
const BLUE_MID := Color("12355c")
const BLUE_EDGE := Color("2f86bf")
const RED_HEART := Color("ff4f6d")
const HEART_EMPTY := Color("29425f")
const GOLD := Color("ffc928")
const GREEN := Color("53ff98")
const WHITE := Color("eaf9ff")
const PLAYER_PORTRAIT: Texture2D = preload(
    "res://assets/characters/player/player_portrait.png"
)

var game: Node


func _process(_delta: float) -> void:
    queue_redraw()


func _draw() -> void:
    if game == null or game.player == null:
        return

    _draw_player_panel()
    _draw_collectible_panel()
    _draw_temporary_notice()
    _draw_interaction_prompt()


func _draw_player_panel() -> void:
    var panel := Rect2(12, 10, 280, 78)
    _panel(panel)

    var portrait_frame := Rect2(18, 16, 60, 60)
    draw_rect(portrait_frame, Color("071628"))
    draw_rect(portrait_frame, BLUE_EDGE, false, 2.0)
    draw_texture_rect(
        PLAYER_PORTRAIT,
        Rect2(20, 18, 56, 56),
        false
    )

    var health_x := 88.0
    for i in range(game.player.max_health):
        _heart(
            Vector2(health_x + float(i) * 20.0, 20.0),
            i < game.player.health
        )

    _lightning(Vector2(88, 55))

    var bar_rect := Rect2(109, 57, 145, 12)
    draw_rect(bar_rect, Color("17314f"))
    draw_rect(bar_rect, BLUE_EDGE, false, 1.5)

    var dash_charge := 0.0
    if game.player.dash_unlocked:
        dash_charge = clampf(
            1.0 - game.player.dash_cooldown / 1.5,
            0.0,
            1.0
        )

    draw_rect(
        Rect2(
            bar_rect.position + Vector2(2, 2),
            Vector2(
                (bar_rect.size.x - 4.0) * dash_charge,
                bar_rect.size.y - 4.0
            )
        ),
        CYAN
    )

    for i in range(2):
        draw_circle(
            Vector2(266.0 + float(i) * 10.0, 63.0),
            3.3,
            CYAN
            if game.player.jumps_used <= i
            else HEART_EMPTY
        )


func _draw_collectible_panel() -> void:
    var panel := Rect2(730, 10, 218, 54)
    _panel(panel)

    _coin(Vector2(752, 37))
    label(
        "%03d" % game.score,
        Vector2(772, 45),
        21,
        WHITE
    )

    draw_line(
        Vector2(836, 18),
        Vector2(836, 56),
        Color("1d537e"),
        2.0
    )

    _secret_icon(Vector2(862, 37))
    label(
        "%d/3" % game.secret_count(),
        Vector2(884, 45),
        20,
        WHITE
    )


func _draw_temporary_notice() -> void:
    var notice := ""
    var notice_color := CYAN_SOFT

    if game.unlock_timer > 0.0:
        notice = "DASH DESBLOQUEADO"
        notice_color = CYAN
    elif game.save_notice_timer > 0.0:
        notice = str(game.save_notice)
        notice_color = GREEN

    if notice == "":
        return

    var rect := Rect2(330, 16, 300, 42)
    draw_rect(rect, Color(0.02, 0.08, 0.16, 0.92))
    draw_rect(rect, notice_color, false, 1.5)
    draw_string(
        ThemeDB.fallback_font,
        Vector2(rect.position.x, rect.position.y + 27),
        notice,
        HORIZONTAL_ALIGNMENT_CENTER,
        rect.size.x,
        17,
        notice_color
    )


func _draw_interaction_prompt() -> void:
    var prompt := str(game.interaction_name())
    if prompt == "":
        return

    var rect := Rect2(320, 392, 320, 36)
    draw_rect(rect, Color(0.02, 0.08, 0.16, 0.88))
    draw_rect(rect, CYAN, false, 1.5)
    draw_string(
        ThemeDB.fallback_font,
        Vector2(rect.position.x, rect.position.y + 24),
        prompt,
        HORIZONTAL_ALIGNMENT_CENTER,
        rect.size.x,
        15,
        CYAN_SOFT
    )


func _panel(rect: Rect2) -> void:
    draw_rect(rect, BLUE_DARK)
    draw_rect(rect, Color("0d2a4d"), false, 3.0)
    draw_rect(
        Rect2(rect.position + Vector2(3, 3), rect.size - Vector2(6, 6)),
        BLUE_EDGE,
        false,
        1.0
    )


func _heart(pos: Vector2, filled: bool) -> void:
    var color := RED_HEART if filled else HEART_EMPTY
    draw_rect(Rect2(pos + Vector2(3, 0), Vector2(5, 5)), color)
    draw_rect(Rect2(pos + Vector2(11, 0), Vector2(5, 5)), color)
    draw_rect(Rect2(pos + Vector2(0, 4), Vector2(19, 7)), color)
    draw_rect(Rect2(pos + Vector2(3, 11), Vector2(13, 4)), color)
    draw_rect(Rect2(pos + Vector2(6, 15), Vector2(7, 4)), color)


func _lightning(pos: Vector2) -> void:
    var points := PackedVector2Array([
        pos + Vector2(8, 0),
        pos + Vector2(1, 11),
        pos + Vector2(7, 11),
        pos + Vector2(3, 22),
        pos + Vector2(17, 8),
        pos + Vector2(10, 8),
        pos + Vector2(14, 0),
    ])
    draw_colored_polygon(points, CYAN)


func _coin(center: Vector2) -> void:
    var points := PackedVector2Array([
        center + Vector2(-7, -10),
        center + Vector2(7, -10),
        center + Vector2(10, -6),
        center + Vector2(10, 6),
        center + Vector2(7, 10),
        center + Vector2(-7, 10),
        center + Vector2(-10, 6),
        center + Vector2(-10, -6),
    ])
    draw_colored_polygon(points, GOLD)
    draw_polyline(
        PackedVector2Array([
            center + Vector2(-4, -7),
            center + Vector2(4, -7),
            center + Vector2(7, -4),
            center + Vector2(7, 4),
            center + Vector2(4, 7),
            center + Vector2(-4, 7),
            center + Vector2(-7, 4),
            center + Vector2(-7, -4),
            center + Vector2(-4, -7),
        ]),
        Color("ff7a18"),
        2.0
    )


func _secret_icon(center: Vector2) -> void:
    draw_circle(center, 10.0, CYAN, false, 3.0)
    draw_circle(center, 3.0, CYAN)
    for i in range(8):
        var angle := TAU * float(i) / 8.0
        var direction := Vector2(cos(angle), sin(angle))
        draw_line(
            center + direction * 10.0,
            center + direction * 14.0,
            CYAN,
            3.0
        )


func label(
    value: String,
    pos: Vector2,
    size: int,
    color: Color
) -> void:
    draw_string(
        ThemeDB.fallback_font,
        pos,
        value,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        size,
        color
    )
