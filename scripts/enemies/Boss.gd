extends CharacterBody2D
# El Croupier (4.9): gira alrededor del jugador, rodea pilares y prepara embestidas.
# El daño se puede evitar: 0.7 s de aviso visible antes de la embestida.
const BULLET_SCENE: PackedScene = preload("res://scenes/combat/EnemyProjectile.tscn")
@export var max_health: int = 110
@export var move_speed: float = 90.0
@export var contact_damage: int = 13
var health: float = 110.0
var player: Node2D
var navigator
var route: Array[Vector2] = []
var route_timer: float = 0.0
var burst_timer: float = 2.75
var ring_timer: float = 3.25
var global_shot_cooldown: float = 0.0
const SHOT_RECOVERY: float = 1.35
var contact_timer: float = 0.0
var flash_timer: float = 0.0
var dead: bool = false
var spin_angle: float = 0.0
var strafe_sign: float = 1.0
var strafe_timer: float = 2.6
var dash_cooldown: float = 4.2
var dash_windup: float = 0.0
var dash_remaining: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
var stuck_seconds: float = 0.0
var previous_position: Vector2 = Vector2.ZERO

func _ready() -> void:
    health = max_health
    add_to_group("enemies")
    add_to_group("boss")
    player = get_tree().get_first_node_in_group("player")
    navigator = get_tree().get_first_node_in_group("room_navigation")
    previous_position = global_position
    strafe_sign = -1.0 if randf() < 0.5 else 1.0
    queue_redraw()

func _physics_process(delta: float) -> void:
    if dead or not RunManager.run_active:
        velocity = Vector2.ZERO
        return
    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player")
        return
    if not is_instance_valid(navigator):
        navigator = get_tree().get_first_node_in_group("room_navigation")
    var dist: float = global_position.distance_to(player.global_position)
    var toward: Vector2 = global_position.direction_to(player.global_position)
    var enraged: bool = health <= int(max_health * 0.5)
    var clear_view: bool = is_instance_valid(navigator) and navigator.clear_path(global_position, player.global_position, 61.0)
    contact_timer = maxf(0.0, contact_timer - delta)
    flash_timer = maxf(0.0, flash_timer - delta)
    dash_cooldown -= delta
    strafe_timer -= delta
    if strafe_timer <= 0.0:
        strafe_sign *= -1.0
        strafe_timer = randf_range(2.1, 3.4)

    # Embestida: telegráfica, bloqueable por pilares, distinta del movimiento normal.
    if dash_windup > 0.0:
        dash_windup -= delta
        velocity = Vector2.ZERO
        if dash_windup <= 0.0:
            dash_remaining = 0.39 if enraged else 0.34
    elif dash_remaining > 0.0:
        dash_remaining -= delta
        velocity = dash_direction * (365.0 if enraged else 310.0)
        move_and_slide()
        if get_slide_collision_count() > 0:
            dash_remaining = 0.0
        if dash_remaining <= 0.0:
            ring_timer = minf(ring_timer, 1.25)
            global_shot_cooldown = maxf(global_shot_cooldown, 1.15)
    else:
        var desired: float = 88.0 if enraged else 114.0
        var tangent: Vector2 = toward.orthogonal() * strafe_sign
        var movement: Vector2
        if not clear_view:
            # Un muro entre jefe y jugador: A* lo guía hasta la ruta disponible.
            movement = _navigate_toward_player(delta)
        elif dist > desired + 20.0:
            movement = (toward + tangent * 0.36).normalized()
        elif dist < 94.0:
            # No rehúye colisiones: presiona al jugador incluso a corta distancia.
            movement = (toward * 0.85 + tangent * 0.15).normalized()
        else:
            # Se mantiene móvil mientras dispara, en lugar de permanecer inmóvil.
            movement = (tangent + toward * clampf((dist - desired) / 135.0, -0.42, 0.42)).normalized()
        velocity = movement * (134.0 if enraged else 108.0)
        move_and_slide()
        if is_on_wall():
            strafe_sign *= -1.0
            strafe_timer = 1.3
        if global_position.distance_to(previous_position) < 0.6 and velocity.length() > 20.0:
            stuck_seconds += delta
        else:
            stuck_seconds = 0.0
        previous_position = global_position
        if stuck_seconds > 0.55:
            route_timer = 0.0
            strafe_sign *= -1.0
            stuck_seconds = 0.0
        if dash_cooldown <= 0.0 and dist > 70.0 and dist < 480.0 and clear_view:
            dash_direction = toward
            dash_windup = 0.72 if enraged else 0.85
            AudioDirector.play_sfx("boss_charge")
            dash_cooldown = 3.6 if enraged else 4.9

    if global_position.distance_to(player.global_position) <= 80.0 and contact_timer <= 0.0:
        player.receive_contact_damage(contact_damage)
        contact_timer = 1.1
    burst_timer -= delta
    ring_timer -= delta
    global_shot_cooldown = maxf(0.0, global_shot_cooldown - delta)
    # Sala 10: SOLO embestida anunciada y círculo de balas.
    # Sala 20: desbloquea abanico de 3; sala 30+: abanico de 5.
    # TODAS las ráfagas comparten un enfriamiento, también al enfurecerse.
    var allow_fire: bool = dash_windup <= 0.0 and dash_remaining <= 0.0 and global_shot_cooldown <= 0.0
    if allow_fire:
        if ring_timer <= 0.0:
            _fire_ring(10 if enraged else 8)
            spin_angle += 0.32
            ring_timer = 3.3 if enraged else 4.0
            global_shot_cooldown = SHOT_RECOVERY
            burst_timer = maxf(burst_timer, 1.6)
        elif RunManager.current_level >= 20 and burst_timer <= 0.0 and clear_view:
            _fire_fan(5 if RunManager.current_level >= 30 else 3)
            burst_timer = 2.5 if enraged else 3.2
            global_shot_cooldown = SHOT_RECOVERY
            ring_timer = maxf(ring_timer, 1.55)
    queue_redraw()

func _navigate_toward_player(delta: float) -> Vector2:
    if not is_instance_valid(navigator):
        return global_position.direction_to(player.global_position)
    route_timer -= delta
    if route_timer <= 0.0 or route.is_empty():
        route = navigator.get_route(global_position, player.global_position, 61.0)
        route_timer = 0.4
    while route.size() > 1 and global_position.distance_to(route[0]) < 22.0:
        route.pop_front()
    if route.is_empty():
        return global_position.direction_to(player.global_position)
    return global_position.direction_to(route[0])

func _fire_fan(count: int) -> void:
    AudioDirector.play_sfx("boss_ring")
    if not is_instance_valid(player):
        return
    var angle: float = global_position.angle_to_point(player.global_position)
    for i in range(count):
        var offset: float = (float(i) - float(count - 1) * 0.5) * 0.19
        _fire_bullet(Vector2.RIGHT.rotated(angle + offset), 225.0 if health <= max_health * 0.5 else 205.0, 11)

func _fire_ring(count: int) -> void:
    AudioDirector.play_sfx("boss_ring")
    for i in range(count):
        var angle: float = spin_angle + TAU * float(i) / float(count)
        _fire_bullet(Vector2.RIGHT.rotated(angle), 163.0, 9)

func _fire_bullet(direction: Vector2, shot_speed: float, shot_damage: int) -> void:
    var bullet: Area2D = BULLET_SCENE.instantiate() as Area2D
    bullet.set("direction", direction)
    bullet.set("speed", shot_speed)
    bullet.set("damage", shot_damage)
    get_tree().current_scene.add_child(bullet)
    bullet.global_position = global_position + direction * 65.0

func take_damage(amount: float) -> void:
    if dead:
        return
    health = maxf(0.0, health - amount)
    flash_timer = 0.13
    if health <= 0:
        AudioDirector.play_sfx("boss_defeat")
        dead = true
        # El jefe solo notifica que fue derrotado. Main.gd coordina
        # el pago ANTES de la experiencia y de abrir menús.
        RunManager.boss_defeated.emit()
        RunManager.grant_xp(20 + mini(20, RunManager.current_level))
        queue_free()
    else:
        queue_redraw()

func _draw() -> void:
    var tint: Color = Color("#f3a6d2") if flash_timer > 0.0 else Color("#8a4a99")
    draw_circle(Vector2(0, 8), 43, Color("#15101e"))
    draw_circle(Vector2.ZERO, 39, tint)
    draw_colored_polygon(PackedVector2Array([Vector2(-28,-20),Vector2(-40,-55),Vector2(-8,-35)]), Color("#cc81c5"))
    draw_colored_polygon(PackedVector2Array([Vector2(28,-20),Vector2(40,-55),Vector2(8,-35)]), Color("#cc81c5"))
    draw_circle(Vector2(-12,-5), 7, Color("#fbe3a2"))
    draw_circle(Vector2(12,-5), 7, Color("#fbe3a2"))
    draw_circle(Vector2(-12,-5), 3, Color("#1c1427"))
    draw_circle(Vector2(12,-5), 3, Color("#1c1427"))
    draw_arc(Vector2(0,13), 16, 0.1, PI - 0.1, 16, Color("#201329"), 3)
    draw_arc(Vector2(0,0), 47, 0, TAU, 44, Color("#f6cb70"), 2)
    draw_rect(Rect2(-43, -70, 86, 8), Color("#191521"), true)
    draw_rect(Rect2(-41, -68, 82.0 * float(health) / float(max_health), 4), Color("#f0bd76"), true)
    if dash_windup > 0.0:
        var length: float = 170.0
        draw_line(Vector2.ZERO, dash_direction * length, Color("#ff535b", 0.78), 11.0)
        draw_line(Vector2.ZERO, dash_direction * length, Color("#ffe6d9"), 2.0)
        draw_arc(Vector2.ZERO, 50, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - dash_windup / 0.85), 36, Color("#ff535b"), 4.0)
