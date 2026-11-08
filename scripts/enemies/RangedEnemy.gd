extends "res://scripts/enemies/BasicEnemy.gd"
# Patrón legible: recolocarse -> apuntar -> 2 disparos -> 1.7s expuesto.
# Nunca avanza mientras dispara. Los amarillos heredan este sistema
# con estados de menor duración y un disparo dirigido predictivo.
const ENEMY_BULLET_SCENE: PackedScene = preload("res://scenes/combat/EnemyProjectile.tscn")
const IGNEL_BULLET_SCENE: PackedScene = preload("res://scenes/combat/IgnelFireball.tscn")
const IGNEL_DEATH_SCENE: PackedScene = preload("res://scenes/enemies/IgnelDeathFX.tscn")

# Solo RangedEnemy.tscn tiene estos nodos. SplitMinion hereda el script,
# pero conserva su arte y proyectiles anteriores sin cambios.
@onready var ignel_sprite: AnimatedSprite2D = get_node_or_null("IgnelSprite") as AnimatedSprite2D
@onready var ignel_shadow: AnimatedSprite2D = get_node_or_null("IgnelShadow") as AnimatedSprite2D
var ignel_phase: float = 0.0
var ignel_prev_state: String = "reposition"
var ignel_flash_on: bool = false
var ignel_attack_hold: float = 0.0

@export var preferred_distance: float = 205.0
@export var burst_count: int = 2
@export var shot_gap: float = 0.24
@export var stationary_after_burst: float = 1.65
@export var reposition_duration: float = 1.25
@export var windup_duration: float = 0.33
@export var aim_lead_factor: float = 0.0

var state: String = "reposition"
var state_timer: float = 1.25
var shots_left: int = 0
var gap_timer: float = 0.0
var strafe_sign: float = 1.0
var strafe_timer: float = 2.5

func _ready() -> void:
    super._ready()
    remove_from_group("melee_enemies")  # Es un tirador, no un morado flanqueador.
    add_to_group("ranged_enemies")
    burst_count = 1 if RunManager.current_level <= 20 else 2
    state_timer = randf_range(0.8, 1.4)
    strafe_sign = -1.0 if randf() < 0.5 else 1.0
    strafe_timer = randf_range(1.8, 3.0)
    if ignel_sprite != null:
        ignel_sprite.play("hover")
        if ignel_shadow != null:
            ignel_shadow.play("shadow")

func _physics_process(delta: float) -> void:
    if not RunManager.run_active or dying:
        velocity = Vector2.ZERO
        return
    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player")
        return
    if not is_instance_valid(navigator):
        navigator = get_tree().get_first_node_in_group("room_navigation")
    contact_timer = maxf(0.0, contact_timer - delta)
    flash_timer = maxf(0.0, flash_timer - delta)
    var to_player: Vector2 = player.global_position - global_position
    var dist: float = to_player.length()
    var toward: Vector2 = to_player.normalized() if dist > 0.1 else Vector2.ZERO
    var clear_view: bool = is_instance_valid(navigator) and navigator.clear_path(global_position, player.global_position, 13.0)
    state_timer -= delta
    if state == "reposition":
        strafe_timer -= delta
        if strafe_timer <= 0.0:
            strafe_sign *= -1.0
            strafe_timer = randf_range(1.4, 2.5)
        if not clear_view:
            velocity = _navigate_toward_player(delta) * move_speed
        elif dist > preferred_distance + 30.0:
            velocity = (toward * 0.86 + toward.orthogonal() * strafe_sign * 0.3).normalized() * move_speed
        elif dist < preferred_distance - 45.0:
            velocity = (-toward * 0.72 + toward.orthogonal() * strafe_sign * 0.4).normalized() * move_speed
        else:
            velocity = toward.orthogonal() * strafe_sign * move_speed * 0.65
        # Un tirador también se aparta de aliados (antes solo lo hacían morados).
        velocity += _friendly_separation() * move_speed * 0.42
        move_and_slide()
        if is_on_wall():
            # Evita repetir la misma dirección al chocar con un obstáculo.
            route.clear()
            route_timer = 0.0
            strafe_sign *= -1.0
            strafe_timer = 1.0
        if state_timer <= 0.0 and clear_view and dist < 430.0:
            state = "windup"
            state_timer = windup_duration
        elif state_timer <= 0.0:
            state_timer = 0.40
    elif state == "windup":
        velocity = Vector2.ZERO
        if state_timer <= 0.0:
            state = "burst"
            shots_left = burst_count
            gap_timer = 0.0
    elif state == "burst":
        velocity = Vector2.ZERO
        gap_timer -= delta
        if shots_left > 0 and gap_timer <= 0.0:
            _fire_at_player()
            shots_left -= 1
            gap_timer = shot_gap
        if shots_left <= 0:
            state = "recover"
            state_timer = stationary_after_burst
    else: # recover
        velocity = Vector2.ZERO
        if state_timer <= 0.0:
            state = "reposition"
            state_timer = reposition_duration
    if global_position.distance_to(player.global_position) <= 42.0 and contact_timer <= 0.0:
        player.receive_contact_damage(contact_damage)
        contact_timer = 0.95
    _update_ignel_visual(delta)
    queue_redraw()

func _update_ignel_visual(delta: float) -> void:
    if ignel_sprite == null:
        return
    # Levitación sutil desacoplada de hitbox, navegación y estado de ataque.
    ignel_phase += delta * 4.2
    ignel_attack_hold = maxf(0.0, ignel_attack_hold - delta)
    ignel_sprite.position.y = -6.0 + sin(ignel_phase) * 1.8
    if state == "windup" and ignel_prev_state != "windup":
        ignel_sprite.play("attack")
    elif state == "reposition" or (state == "recover" and ignel_attack_hold <= 0.0):
        if ignel_sprite.animation != "hover":
            ignel_sprite.play("hover")
    ignel_prev_state = state
    var hit_now: bool = flash_timer > 0.0
    if hit_now != ignel_flash_on:
        ignel_flash_on = hit_now
        ignel_sprite.modulate = Color("#ff7979") if hit_now else Color.WHITE

func take_damage(amount: float) -> void:
    if dying:
        return
    if ignel_sprite != null and health - amount <= 0.0:
        # El enemigo muere con super.take_damage en este mismo fotograma.
        # El humo es una escena aparte sin IA, colisiones ni cuenta de enemigos.
        var effect: AnimatedSprite2D = IGNEL_DEATH_SCENE.instantiate() as AnimatedSprite2D
        get_tree().current_scene.add_child(effect)
        effect.global_position = global_position + Vector2(0, -6)
        effect.scale = global_scale
        # Evita una silueta temporal duplicada mientras queue_free se confirma.
        ignel_sprite.visible = false
        if ignel_shadow != null:
            ignel_shadow.visible = false
        collision_layer = 0
        collision_mask = 0
    super.take_damage(amount)

func _fire_at_player() -> void:
    if not is_instance_valid(player):
        return
    var aim_position: Vector2 = player.global_position
    if player is CharacterBody2D and aim_lead_factor > 0.0:
        var flight_time: float = minf(0.50, global_position.distance_to(aim_position) / 210.0)
        aim_position += (player as CharacterBody2D).velocity * flight_time * aim_lead_factor
    var fire_dir: Vector2 = global_position.direction_to(aim_position)
    if fire_dir.length_squared() < 0.01:
        return
    AudioDirector.play_sfx("shot_enemy")
    # Solo Cráneo Ignel usa el proyectil nuevo. Boss y SplitMinion, intactos.
    var bullet_scene: PackedScene = IGNEL_BULLET_SCENE if ignel_sprite != null else ENEMY_BULLET_SCENE
    var bullet: Area2D = bullet_scene.instantiate() as Area2D
    bullet.set("direction", fire_dir)
    if ignel_sprite != null:
        ignel_sprite.play("attack")
        ignel_attack_hold = 0.32 # Permite ver la apertura de boca tras el último tiro.
        bullet.rotation = fire_dir.angle()
    get_tree().current_scene.add_child(bullet)
    bullet.global_position = global_position + fire_dir * 30.0

func _draw() -> void:
    if ignel_sprite != null:
        # Mantener las señales de peligro y la barra, pero no pintar el viejo
        # círculo rosa bajo el cráneo. Así no hay dos enemigos superpuestos.
        if state == "windup" or state == "burst":
            draw_arc(Vector2.ZERO, 17, 0.0, TAU, 18, Color("#ffdf7b"), 2.0)
        elif state == "recover":
            draw_arc(Vector2.ZERO, 17, 0.0, TAU, 18, Color("#84ddc5"), 2.0)
        _draw_health_bar()
        return
    var body_color: Color = Color("#ee9bb4") if flash_timer > 0.0 else Color("#af4278")
    draw_circle(Vector2(0, 3), 13.0, Color("#17151d"))
    draw_circle(Vector2.ZERO, 12.0, body_color)
    draw_colored_polygon(PackedVector2Array([Vector2(-12, -5), Vector2(-17, -12), Vector2(-7, -8)]), Color("#e75a8b"))
    draw_colored_polygon(PackedVector2Array([Vector2(12, -5), Vector2(17, -12), Vector2(7, -8)]), Color("#e75a8b"))
    draw_circle(Vector2(-4, -2), 2.0, Color.WHITE)
    draw_circle(Vector2(4, -2), 2.0, Color.WHITE)
    draw_circle(Vector2(-4, -2), 1.0, Color("#251522"))
    draw_circle(Vector2(4, -2), 1.0, Color("#251522"))
    # Símbolo sencillo para reconocer la ventana de peligro.
    if state == "windup" or state == "burst":
        draw_arc(Vector2.ZERO, 17, 0.0, TAU, 18, Color("#ffdf7b"), 2.0)
    elif state == "recover":
        draw_arc(Vector2.ZERO, 17, 0.0, TAU, 18, Color("#84ddc5"), 2.0)
    _draw_health_bar()
