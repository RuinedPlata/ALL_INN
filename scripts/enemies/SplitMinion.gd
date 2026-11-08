extends "res://scripts/enemies/RangedEnemy.gd"
# Un solo impacto mata al mini-Cráneo Ígneo. Misma IA y economia del minion amarillo anterior.
# No ocupa cupos rosa ni cuenta como muerte de oleada; conserva monedas y XP.
const MINI_DEATH_SCENE: PackedScene = preload("res://scenes/enemies/IgnelDeathFX.tscn")
@onready var mini_sprite: AnimatedSprite2D = get_node_or_null("MiniIgnelSprite") as AnimatedSprite2D
@onready var mini_shadow: AnimatedSprite2D = get_node_or_null("MiniIgnelShadow") as AnimatedSprite2D
var mini_phase: float = 0.0
var mini_prev_state: String = "reposition"
var mini_hit_flash: bool = false
func _ready() -> void:
    super._ready()
    remove_from_group("ranged_enemies")  # Amarillo: no ocupa los 4 cupos de enemigos ROSAS.
    max_health = 1
    health = 1
    burst_count = 1
    windup_duration = 0.16
    stationary_after_burst = 0.32
    reposition_duration = 0.48
    preferred_distance = 165.0
    aim_lead_factor = 0.65
    state_timer = randf_range(0.2, 0.6)
    if mini_sprite != null:
        mini_sprite.play("hover")
        if mini_shadow != null:
            mini_shadow.play("shadow")

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if mini_sprite == null or dying or not RunManager.run_active:
        return
    mini_phase += delta * 5.5
    mini_sprite.position.y = -3.0 + sin(mini_phase) * 1.2
    if state == "windup" and mini_prev_state != "windup":
        mini_sprite.play("attack")
    elif state == "reposition" or state == "recover":
        if mini_sprite.animation != "hover":
            mini_sprite.play("hover")
    mini_prev_state = state
    var hit_now: bool = flash_timer > 0.0
    if mini_hit_flash != hit_now:
        mini_hit_flash = hit_now
        mini_sprite.modulate = Color("#ff7777") if hit_now else Color.WHITE

func take_damage(amount: float) -> void:
    if dying:
        return
    health = maxf(0.0, health - amount)
    flash_timer = 0.13
    if health <= 0:
        dying = true
        if mini_sprite != null:
            var fx: AnimatedSprite2D = MINI_DEATH_SCENE.instantiate() as AnimatedSprite2D
            get_tree().current_scene.add_child(fx)
            fx.global_position = global_position + Vector2(0, -3)
            fx.scale = global_scale * 0.57
            mini_sprite.visible = false
            if mini_shadow != null:
                mini_shadow.visible = false
        # Los amarillos no cuentan para cerrar la oleada, pero sí son
        # enemigos derrotados y entregan las mismas 2-5 monedas directas.
        RunManager.award_enemy_kill_coins()
        RunManager.grant_xp(1)
        queue_free()
    else:
        queue_redraw()

func _draw() -> void:
    if mini_sprite != null:
        if state == "windup":
            draw_arc(Vector2.ZERO, 13, 0.0, TAU, 14, Color("#ffbc6d"), 2.0)
        _draw_health_bar()
        return
    var tint: Color = Color("#eff4c0") if flash_timer > 0.0 else Color("#b9bd4c")
    draw_circle(Vector2.ZERO, 9.0, tint)
    draw_circle(Vector2(-3, -2), 1.5, Color("#191c20"))
    draw_circle(Vector2(3, -2), 1.5, Color("#191c20"))
    if state == "windup":
        draw_arc(Vector2.ZERO, 13, 0.0, TAU, 14, Color("#ffbc6d"), 2.0)
    _draw_health_bar()
