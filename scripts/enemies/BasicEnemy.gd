extends CharacterBody2D

const DROP_SCENE: PackedScene = preload("res://scenes/items/DroppedItem.tscn")
const IMP_DEATH_SCENE: PackedScene = preload("res://scenes/enemies/ImpDeathFX.tscn")
const DB = preload("res://scripts/systems/ItemDatabase.gd")

@export var max_health: int = 3
@export var move_speed: float = 72.0
@export var contact_damage: int = 8
@export var coin_reward_min: int = 9
@export var coin_reward_max: int = 17
@export var disengage_after_contact: bool = true

var health: float
var player: Node2D
var contact_timer: float = 0.0
var flash_timer: float = 0.0
var dying: bool = false
var navigator
var route: Array[Vector2] = []
var route_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var stuck_timer: float = 0.0
# Rol asignado al aparecer: 0 = perseguidor, 1 = flanqueo izquierdo,
# 2 = flanqueo derecho. Se reasigna por sala en LevelManager.
@export_range(0, 2) var flank_role: int = 0
var tactical_target: Vector2 = Vector2.ZERO
# Un morado que acaba de golpear no debe quedarse empujando al jugador:
# se aparta unos instantes y vuelve a buscar una aproximación táctica.
var retreat_timer: float = 0.0
var retreat_side: float = 1.0
# Solo la escena BasicEnemy contiene ImpSprite; las escenas derivadas conservan su arte.
@onready var imp_sprite: AnimatedSprite2D = get_node_or_null("ImpSprite") as AnimatedSprite2D
var imp_hit_flash: bool = false

func _ready() -> void:
    health = max_health
    add_to_group("enemies")
    add_to_group("melee_enemies")
    player = get_tree().get_first_node_in_group("player")
    navigator = get_tree().get_first_node_in_group("room_navigation")
    last_position = global_position
    retreat_side = -1.0 if (flank_role == 1 or (flank_role == 0 and randf() < 0.5)) else 1.0
    if imp_sprite != null:
        imp_sprite.animation_finished.connect(_on_imp_animation_finished)
        imp_sprite.play("chase")

func _physics_process(delta: float) -> void:
    if not RunManager.run_active or dying:
        velocity = Vector2.ZERO
        return
    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player")
        return
    contact_timer = maxf(0.0, contact_timer - delta)
    retreat_timer = maxf(0.0, retreat_timer - delta)
    flash_timer = maxf(0.0, flash_timer - delta)
    var distance: float = global_position.distance_to(player.global_position)
    var direction: Vector2 = _retreat_from_player() if retreat_timer > 0.0 else _navigate_toward_player(delta)
    # Fuera de la retirada, la separación evita que se amontonen.
    if retreat_timer <= 0.0 and distance > 42.0:
        direction = (direction + _friendly_separation() * 0.45).normalized()
    velocity = direction * (move_speed * 1.12 if retreat_timer > 0.0 else move_speed)
    move_and_slide()
    if imp_sprite != null:
        _update_imp_visual()
    if is_on_wall() and retreat_timer <= 0.0:
        # Una ruta que topó un bloque no se sigue ciegamente un segundo más.
        route.clear()
        route_timer = 0.0
    # El contacto ocurre solo cuando es un nuevo ataque. Después, el enemigo
    # se aparta: no se queda presionando al jugador hasta el próximo golpe.
    if retreat_timer <= 0.0 and global_position.distance_to(player.global_position) <= 42.0 and contact_timer <= 0.0:
        if imp_sprite != null:
            imp_sprite.play("attack")
        player.receive_contact_damage(contact_damage)
        contact_timer = 1.15
        if disengage_after_contact:
            retreat_timer = 0.72
            route.clear()
            route_timer = 0.0
            retreat_side *= -1.0
    queue_redraw()

func _retreat_from_player() -> Vector2:
    if not is_instance_valid(player):
        return Vector2.ZERO
    var away: Vector2 = player.global_position.direction_to(global_position)
    if away.length_squared() < 0.01:
        away = Vector2.RIGHT * retreat_side
    # Pequeño desplazamiento lateral para evitar que el jugador y el enemigo
    # queden en una línea de empujones. La colisión con obstáculos permanece.
    var movement: Vector2 = (away + away.orthogonal() * retreat_side * 0.25).normalized()
    return movement

func _navigate_toward_player(delta: float) -> Vector2:
    if not is_instance_valid(player):
        return Vector2.ZERO
    if not is_instance_valid(navigator):
        navigator = get_tree().get_first_node_in_group("room_navigation")

    # Un único morado persigue normalmente. En grupos, uno presiona de
    # frente mientras los otros buscan cortar el paso por izquierda/derecha.
    # Se limitan los ángulos y la predicción para que el ataque sea legible.
    # La búsqueda de celda transitable cuesta CPU: solo recalcularla al renovar la ruta.
    if not is_instance_valid(navigator):
        return global_position.direction_to(_choose_target())
    route_timer -= delta
    var moved: float = global_position.distance_to(last_position)
    last_position = global_position
    if moved < 0.35 and velocity.length() > 10.0:
        stuck_timer += delta
    else:
        stuck_timer = 0.0

    if route_timer <= 0.0 or stuck_timer > 0.65:
        var target: Vector2 = player.global_position if stuck_timer > 0.65 else _choose_target()
        if navigator.has_method("closest_walkable"):
            target = navigator.closest_walkable(target, 24.0)
        tactical_target = target
        route = navigator.get_route(global_position, target, 24.0)
        route_timer = randf_range(0.40, 0.60)
        stuck_timer = 0.0

    while not route.is_empty() and global_position.distance_to(route[0]) < 12.0:
        route.pop_front()
    if route.is_empty():
        # Nunca caminar contra un muro cuando A* no pudo trazar una ruta.
        if navigator.clear_path(global_position, player.global_position, 20.0):
            return global_position.direction_to(player.global_position)
        route_timer = 0.0
        return Vector2.ZERO
    return global_position.direction_to(route[0])

func _choose_target() -> Vector2:
    var player_pos: Vector2 = player.global_position
    var distance: float = global_position.distance_to(player_pos)
    # Al entrar en distancia de contacto, todos tratan de alcanzar al jugador.
    if distance < 44.0 or flank_role == 0:
        return player_pos
    # Si no hay compañeros morados vivos, abandonamos el flanqueo.
    var allies: int = 0
    for unit in get_tree().get_nodes_in_group("melee_enemies"):
        if is_instance_valid(unit) and not unit.is_queued_for_deletion():
            allies += 1
    if allies < 2:
        return player_pos

    var player_motion: Vector2 = Vector2.ZERO
    if player is CharacterBody2D:
        player_motion = (player as CharacterBody2D).velocity
    # Si el jugador corre, anticipamos su trayectoria; si está quieto,
    # creamos una pinza a partir de la dirección actual de aproximación.
    var ahead: Vector2 = player_motion.normalized() if player_motion.length() > 24.0 else global_position.direction_to(player_pos)
    if ahead.length_squared() < 0.01:
        return player_pos
    var side: Vector2 = ahead.orthogonal() * (-1.0 if flank_role == 1 else 1.0)
    var lead: float = clampf(player_motion.length() * 0.23, 0.0, 49.0)
    # No buscamos posiciones demasiado alejadas: en particular el objetivo
    # debe caer en la zona navegable incluso si el jugador se pega a un muro.
    return player_pos + ahead * (22.0 + lead) + side * 52.0

func _friendly_separation() -> Vector2:
    var separation: Vector2 = Vector2.ZERO
    for unit in get_tree().get_nodes_in_group("enemies"):
        if unit == self or not is_instance_valid(unit) or unit.is_queued_for_deletion():
            continue
        var offset: Vector2 = global_position - (unit as Node2D).global_position
        var distance: float = offset.length()
        if distance > 0.001 and distance < 62.0:
            separation += offset.normalized() * ((62.0 - distance) / 62.0)
    return separation.limit_length(1.0)

func _steer_to_player() -> Vector2:
    # Compatibilidad con futuras variantes heredadas.
    return _navigate_toward_player(0.0)

func take_damage(amount: float) -> void:
    if dying:
        return
    health -= amount
    flash_timer = 0.12
    if health <= 0:
        dying = true
        if imp_sprite != null:
            _spawn_imp_death_fx()
        RunManager.enemy_defeated()
        # Sin bolsas: 60% común, 30% calidad escalonada por sala, 10% nada.
        # Pactos y garantía de épico TAMBIÉN respetan los bloqueos de sala.
        # Codicia modifica SOLO el tramo de calidad; se respeta un botín por enemigo.
        var forced_item: bool = PactManager.consume_guaranteed_item()
        var drop_roll: float = randf()
        var rarity: String = ""
        if forced_item:
            rarity = RunManager.roll_guaranteed_loot_rarity()
        elif drop_roll < 0.60:
            rarity = "common"
        elif drop_roll < 0.60 + PactManager.item_probability():
            rarity = RunManager.roll_quality_loot_rarity()
        if rarity != "":
            var item_id: String = _choose_loot_id(rarity)
            if item_id != "":
                var drop = DROP_SCENE.instantiate()
                drop.set("item_id", item_id)
                get_tree().current_scene.add_child(drop)
                drop.global_position = global_position + Vector2(12, -5)
        queue_free()

func _choose_loot_id(rarity: String) -> String:
    # Afinidad a piezas existentes: facilita reunir duplicados SIN garantizarlo.
    # Solo reaparecen IDs nativos de la rareza tirada (una ascensión no crea drops nuevos).
    var normal_id: String = DB.roll_id(rarity)
    # Selección de equipo de armadura: afinidad por conjunto 60/20/20
    # y peso por pieza equipada 1.4, con antirrachas suaves.
    if DB.is_set_armor(normal_id):
        return RunManager.roll_armor_piece_id(rarity)
    if str(DB.get_def(normal_id).get("weapon_type", "")) != "":
        return RunManager.roll_weapon_piece_id(rarity)
    # Amuletos no reciben afinidad.
    return normal_id

func _on_imp_animation_finished() -> void:
    if is_instance_valid(imp_sprite) and not dying and imp_sprite.animation == "attack":
        imp_sprite.play("chase")

func _update_imp_visual() -> void:
    # Un solo sprite animado y volteado horizontalmente según la posición del jugador.
    # No cambiar posición, colisiones, velocidad ni comportamiento de navegación.
    if absf(player.global_position.x - global_position.x) > 7.0:
        imp_sprite.flip_h = player.global_position.x < global_position.x
    var hit_now: bool = flash_timer > 0.0
    if hit_now != imp_hit_flash:
        imp_hit_flash = hit_now
        imp_sprite.modulate = Color("#ff7676") if hit_now else Color.WHITE

func _spawn_imp_death_fx() -> void:
    # Se libera el enemigo en el mismo fotograma para no retrasar el loot ni la sala.
    # El FX visual va a la escena principal y no se incluye en enemies_root.
    var effect: AnimatedSprite2D = IMP_DEATH_SCENE.instantiate() as AnimatedSprite2D
    get_tree().current_scene.add_child(effect)
    effect.global_position = global_position
    effect.scale = global_scale
    effect.flip_h = imp_sprite.flip_h

func _draw() -> void:
    if imp_sprite != null:
        # El cuerpo antiguo se sustituye SOLO en BasicEnemy.tscn; subclasses
        # como RangedEnemy/SplitterEnemy tienen su propia función _draw.
        draw_circle(Vector2(0, 15), 10.5, Color(0.08, 0.03, 0.09, 0.28))
        _draw_health_bar()
        return
    var body_color := Color("#e47a91") if flash_timer > 0.0 else Color("#8d6bc2")
    draw_circle(Vector2(0, 3), 13, Color("#17151d"))
    draw_circle(Vector2.ZERO, 12, body_color)
    draw_colored_polygon(PackedVector2Array([Vector2(-9, -7), Vector2(-13, -16), Vector2(-3, -10)]), Color("#c18ce0"))
    draw_colored_polygon(PackedVector2Array([Vector2(9, -7), Vector2(13, -16), Vector2(3, -10)]), Color("#c18ce0"))
    draw_circle(Vector2(-4, -1), 2.0, Color("#fff0cf"))
    draw_circle(Vector2(4, -1), 2.0, Color("#fff0cf"))
    draw_circle(Vector2(-4, -1), 1.0, Color("#292333"))
    draw_circle(Vector2(4, -1), 1.0, Color("#292333"))
    _draw_health_bar()

func _draw_health_bar() -> void:
    var pct: float = clampf(maxf(0.0, health) / float(maxi(1, max_health)), 0.0, 1.0)
    draw_rect(Rect2(-18, -26, 36, 5), Color("#191923"), true)
    draw_rect(Rect2(-17, -25, 34.0 * pct, 3), Color("#ef856d"), true)
