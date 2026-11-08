extends Area2D

@export var speed: float = 430.0
@export var damage: float = 1.0
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var age: float = 0.0
var chain_on_hit: bool = false
var critical_splash: bool = false
var spent: bool = false # Cualquier choque válido consume la bala: sin perforación de enemigos.
var jackpot_homing: bool = false
var homing_strength: float = 0.0 # Casco: 0.05 común -> 0.16 BLACK JACK legendario.
var launch_direction: Vector2 = Vector2.RIGHT
var travelled: float = 0.0
var max_distance: float = 750.0
var falloff_start: float = -1.0
var falloff_minimum: float = 1.0
var weapon_visual: String = "pistol"
var homing_target_direction: Vector2 = Vector2.ZERO
var homing_refresh_timer: float = 0.0
# Evita crear una consulta física y un arreglo de exclusiones en CADA frame por bala.
var _sweep_query: PhysicsRayQueryParameters2D

func _ready() -> void:
    # Se instancian bajo Main (ALWAYS), pero deben detenerse en los menús.
    process_mode = Node.PROCESS_MODE_PAUSABLE
    add_to_group("room_projectiles")
    body_entered.connect(_on_body_entered)
    launch_direction = direction.normalized()
    var excluded: Array[RID] = [get_rid()]
    _sweep_query = PhysicsRayQueryParameters2D.create(Vector2.ZERO, Vector2.ZERO, 18, excluded)
    _sweep_query.collide_with_bodies = true
    _sweep_query.collide_with_areas = false
    _sweep_query.hit_from_inside = true

func _physics_process(delta: float) -> void:
    if spent:
        return
    _guide_towards_enemy(delta)
    # Sweep continuo: el área física por sí sola puede saltarse un cuerpo
    # si una mejora de nivel hace que la bala cruce muchos píxeles por frame.
    var start_pos: Vector2 = global_position
    var remaining: float = max_distance - travelled
    if remaining <= 0.0:
        spent = true
        queue_free()
        return
    var step: Vector2 = direction * minf(speed * delta, remaining)
    var end_pos: Vector2 = start_pos + step
    if step.length_squared() > 0.0001:
        _sweep_query.from = start_pos
        _sweep_query.to = end_pos
        var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(_sweep_query)
        if not hit.is_empty() and hit.get("collider") is Node2D:
            global_position = hit["position"]
            travelled += start_pos.distance_to(global_position)
            _on_body_entered(hit["collider"] as Node2D)
            if spent:
                return
    global_position = end_pos
    travelled += step.length()
    age += delta
    if age >= lifetime or travelled >= max_distance:
        spent = true
        queue_free()
    queue_redraw()

func _guide_towards_enemy(delta: float) -> void:
    # Cacheamos la búsqueda de enemigos durante 0.12s por bala para Android.
    # La dirección puede corregirse cada fotograma, pero siempre respetando
    # el cono original: el abanico no converge inevitablemente a un enemigo.
    if homing_strength <= 0.0 or travelled > (710.0 if jackpot_homing else 320.0):
        return
    var max_correction: float = deg_to_rad(25.0 + 220.0 * clampf(homing_strength, 0.0, 0.25)) if jackpot_homing else deg_to_rad(2.0 + 60.0 * clampf(homing_strength, 0.0, 0.20))
    # El guiado de JACKPOT no puede juntar en el mismo píxel tres perdigones:
    # la escopeta conserva su cono (centrado por su excelente autoapuntado).
    if weapon_visual == "shotgun":
        max_correction = minf(max_correction, deg_to_rad(3.0))
    homing_refresh_timer -= delta
    if homing_refresh_timer <= 0.0:
        homing_refresh_timer = 0.09 if jackpot_homing else 0.12
        homing_target_direction = Vector2.ZERO
        var best_score: float = INF
        for enemy in get_tree().get_nodes_in_group("enemies"):
            if not is_instance_valid(enemy) or not (enemy is Node2D):
                continue
            var displacement: Vector2 = enemy.global_position - global_position
            var distance: float = displacement.length()
            if distance < 12.0 or distance > (420.0 if jackpot_homing else 285.0):
                continue
            var toward: Vector2 = displacement / distance
            var launch_offset: float = absf(launch_direction.angle_to(toward))
            if launch_offset > max_correction + deg_to_rad(18.0 if jackpot_homing else 13.0):
                continue
            var score: float = distance + absf(direction.angle_to(toward)) * 160.0
            if score < best_score:
                best_score = score
                homing_target_direction = toward
    if homing_target_direction == Vector2.ZERO:
        return
    var offset: float = clampf(launch_direction.angle_to(homing_target_direction), -max_correction, max_correction)
    var desired: Vector2 = launch_direction.rotated(offset)
    var correction: float = direction.angle_to(desired)
    var turn_rate: float = (2.0 + 10.0 * clampf(homing_strength, 0.0, 0.25)) if jackpot_homing else (0.7 + 14.0 * clampf(homing_strength, 0.0, 0.20))
    direction = direction.rotated(clampf(correction, -turn_rate * delta, turn_rate * delta)).normalized()

func _on_body_entered(body: Node2D) -> void:
    if spent or not is_instance_valid(body):
        return
    if (body.collision_layer & 16) != 0:
        spent = true
        queue_free()
        return
    if not body.is_in_group("enemies") or not body.has_method("take_damage"):
        return
    # Disparos reales 70%/45%: NO hacer tiradas de 0/1 al impactar.
    # Ahora cada bala causa exactamente su daño fraccionario y el enemigo
    # mantiene su salud en float. Incluso una bala de 0.45 registra daño.
    spent = true
    var distance_factor: float = 1.0
    if falloff_start >= 0.0 and max_distance > falloff_start:
        var ratio: float = clampf((travelled - falloff_start) / (max_distance - falloff_start), 0.0, 1.0)
        distance_factor = lerpf(1.0, falloff_minimum, ratio)
    var actual_damage: float = maxf(0.0, damage * distance_factor)
    if actual_damage > 0.0:
        var feedback: Node = get_tree().get_first_node_in_group("combat_feedback")
        if feedback != null:
            feedback.add_impact(global_position, "enemy", actual_damage)
        AudioDirector.play_sfx("hit_enemy")
        body.take_damage(actual_damage)
        if chain_on_hit:
            _apply_chain_lightning(body, actual_damage)
        if critical_splash:
            _crit_explosion(body, actual_damage)
    queue_free()

func _crit_explosion(hit: Node2D, actual_damage: float) -> void:
    # Una explosión por impacto crítico directo. No encadena explosiones ni rayos.
    var nearby: Array[Node2D] = []
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if is_instance_valid(enemy) and enemy != hit and enemy.global_position.distance_to(hit.global_position) < 70.0:
            nearby.append(enemy)
        if nearby.size() >= 2:
            break
    for other in nearby:
        other.take_damage(maxf(0.1, actual_damage * 0.35))

func _apply_chain_lightning(first_target: Node2D, actual_damage: float) -> void:
    # Efecto de la reliquia Marca del Croupier: daño automático a 1 enemigo
    # dentro de 175 píxeles del objetivo inicial. No salta a obstáculos.
    var origin: Vector2 = first_target.global_position
    var struck: Array[Node2D] = [first_target]
    for _jump in range(1):
        var nearest: Node2D = null
        var best_distance: float = 175.0 * 175.0
        for candidate in get_tree().get_nodes_in_group("enemies"):
            if not is_instance_valid(candidate) or candidate in struck:
                continue
            var dist: float = origin.distance_squared_to(candidate.global_position)
            if dist < best_distance:
                best_distance = dist
                nearest = candidate
        if nearest == null:
            break
        struck.append(nearest)
        _flash_chain(origin, nearest.global_position)
        origin = nearest.global_position
        nearest.take_damage(maxf(0.1, actual_damage * 0.65))

func _flash_chain(from_position: Vector2, to_position: Vector2) -> void:
    # Breve trazo turquesa que permite percibir la reliquia.
    var lightning := Line2D.new()
    lightning.width = 3.5
    lightning.default_color = Color("#a8ffec")
    lightning.points = PackedVector2Array([from_position, to_position])
    lightning.process_mode = Node.PROCESS_MODE_PAUSABLE
    get_tree().current_scene.add_child(lightning)
    var fade: Tween = lightning.create_tween()
    fade.tween_property(lightning, "modulate:a", 0.0, 0.15)
    fade.tween_callback(lightning.queue_free)

func _draw() -> void:
    var bullet_radius: float = 3.0 if weapon_visual == "shotgun" else (4.0 if weapon_visual == "smg" else (6.0 if weapon_visual == "deagle" else 5.0))
    draw_circle(Vector2.ZERO, bullet_radius, Color("#baf9e8") if chain_on_hit else (Color("#ff9871") if weapon_visual == "deagle" else Color("#ffe08a")))
    draw_circle(Vector2.ZERO, bullet_radius * 0.48, Color("#fff8dc"))
