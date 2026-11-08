extends Node
# Una habitación = una oleada FINITA. Cada décima habitación es un jefe.
signal room_started(level: int, goal: int, is_boss: bool)
signal room_progress(killed: int, total: int)
signal room_cleared(is_boss: bool)

const MELEE_SCENE: PackedScene = preload("res://scenes/enemies/BasicEnemy.tscn")
const RANGED_SCENE: PackedScene = preload("res://scenes/enemies/RangedEnemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/enemies/Boss.tscn")
const SPLITTER_SCENE: PackedScene = preload("res://scenes/enemies/SplitterEnemy.tscn")

var arena_rect: Rect2 = Rect2(20, 72, 500, 790)
var enemies_root: Node2D
var player: Node2D
var level: int = 1
var goal: int = 0
var spawned: int = 0
var killed: int = 0
var boss_room: bool = false
var active: bool = false
var cleared: bool = false
var spawn_cooldown: float = 0.0
var wave_number: int = 0
var melee_spawn_count: int = 0

func setup(enemies_container: Node2D, player_node: Node2D) -> void:
    enemies_root = enemies_container
    player = player_node
    arena_rect = RunManager.arena_rect

func start_room(next_level: int) -> void:
    level = next_level
    RunManager.current_level = level
    spawned = 0
    melee_spawn_count = 0
    killed = 0
    cleared = false
    active = true
    spawn_cooldown = 0.65
    boss_room = (level % 10 == 0)
    # 3 enemigos en la primera habitación, progresión suave.
    goal = 1 if boss_room else mini(3 + level, 11)
    wave_number = int(level / 10)
    room_started.emit(level, goal, boss_room)
    room_progress.emit(0, goal)

func _process(delta: float) -> void:
    if not active or cleared or not RunManager.run_active or get_tree().paused:
        return
    if spawned >= goal:
        # Las crías del divisor no suman muertes de oleada, pero debemos
        # eliminarlas antes de abrir la puerta.
        if killed >= goal:
            _check_cleared()
        return
    # Limitar simultáneos: sin una oleada infinita de enemigos.
    var max_on_screen: int = mini(4 + int(level / 6), 8)
    if not boss_room and enemies_root.get_child_count() >= max_on_screen:
        return
    spawn_cooldown -= delta
    if spawn_cooldown <= 0.0:
        if boss_room:
            _spawn_boss()
        else:
            _spawn_normal_enemy()
        spawned += 1
        spawn_cooldown = maxf(0.42, 1.05 - float(level) * 0.035)

func _spawn_normal_enemy() -> void:
    # Rosas desde la sala 5; verdes divisores desde la 25. Progresión gradual.
    var ranged_chance: float = 0.0 if level < 5 else minf(0.18 + float(level - 5) * 0.008, 0.38)
    var splitter_chance: float = 0.0 if level < 25 else minf(0.08 + float(level - 25) * 0.005, 0.22)
    var is_splitter: bool = randf() < splitter_chance and _active_splitter_count() < 2
    # El límite es SIMULTÁNEO, no un límite total por habitación.
    # Al morir uno, el RNG puede generar otro rosa si quedan enemigos por crear.
    var use_ranged: bool = not is_splitter and randf() < ranged_chance and _active_ranged_count() < 3
    var enemy_scene: PackedScene = SPLITTER_SCENE if is_splitter else (RANGED_SCENE if use_ranged else MELEE_SCENE)
    var enemy: Node2D = enemy_scene.instantiate() as Node2D
    var extra_health: int = int((level - 1) / 5)
    var base_health: int = (8 if is_splitter else (5 if use_ranged else 5)) + extra_health
    # Tras cada jefe, vida x1.30 gradual en lugar de x1.50 escalonado.
    var boss_stages: int = int((level - 1) / 10)
    enemy.set("max_health", int(ceil(float(base_health) * pow(1.30, boss_stages) * PactManager.hunter_health_multiplier())))
    enemy.set("move_speed", minf(72.0 + float(level - 1) * 2.0, 112.0))
    enemy.set("contact_damage", mini(8 + int((level - 1) / 4), 14))
    if not is_splitter and not use_ranged:
        enemy.set("flank_role", melee_spawn_count % 3)
        melee_spawn_count += 1
    if use_ranged:
        enemy.set("burst_count", 1 if level <= 20 else 2)
    enemy.scale = Vector2(1.6, 1.6)
    enemy.position = _edge_spawn_position()
    enemies_root.add_child(enemy)

func _active_splitter_count() -> int:
    var count: int = 0
    for unit in enemies_root.get_children():
        if is_instance_valid(unit) and not unit.is_queued_for_deletion() and unit.is_in_group("splitter_enemies"):
            count += 1
    return count

func _active_ranged_count() -> int:
    var count: int = 0
    for unit in get_tree().get_nodes_in_group("ranged_enemies"):
        if is_instance_valid(unit) and not unit.is_queued_for_deletion():
            count += 1
    return count

func _spawn_boss() -> void:
    var boss: Node2D = BOSS_SCENE.instantiate() as Node2D
    boss.set("max_health", 110 + (wave_number - 1) * 50)
    boss.scale = Vector2(1.6, 1.6)
    boss.position = Vector2(arena_rect.get_center().x, arena_rect.position.y + 135.0)
    enemies_root.add_child(boss)

func _edge_spawn_position() -> Vector2:
    # Las apariciones usan los bordes interiores de la arena vertical,
    # nunca los bordes de la ventana o las zonas de interfaz.
    var r: Rect2 = arena_rect
    var pos := _random_edge_point(r)
    for attempt in range(32):
        if _is_spawn_clear(pos):
            return pos
        pos = _random_edge_point(r)
    return pos

func _random_edge_point(r: Rect2) -> Vector2:
    match randi_range(0, 3):
        0: return Vector2(randf_range(r.position.x + 65, r.end.x - 65), r.position.y + 61)
        1: return Vector2(randf_range(r.position.x + 65, r.end.x - 65), r.end.y - 61)
        2: return Vector2(r.position.x + 62, randf_range(r.position.y + 90, r.end.y - 90))
        _: return Vector2(r.end.x - 62, randf_range(r.position.y + 90, r.end.y - 90))

func _is_spawn_clear(pos: Vector2) -> bool:
    if is_instance_valid(player) and pos.distance_to(player.global_position) < 170.0:
        return false
    for other in enemies_root.get_children():
        if is_instance_valid(other) and pos.distance_to(other.position) < 58.0:
            return false
    for obstacle in get_tree().get_nodes_in_group("room_obstacles"):
        var half: Vector2 = obstacle.get("half_size")
        if absf(pos.x - obstacle.global_position.x) < half.x + 30.0 and absf(pos.y - obstacle.global_position.y) < half.y + 30.0:
            return false
    return true

func register_enemy_death() -> void:
    if not active or cleared or boss_room:
        return
    killed += 1
    room_progress.emit(killed, goal)
    call_deferred("_check_cleared")

func register_boss_death() -> void:
    if not active or cleared or not boss_room:
        return
    killed = 1
    room_progress.emit(killed, goal)
    call_deferred("_check_cleared")

func _check_cleared() -> void:
    if cleared or not active or not RunManager.run_active:
        return
    if spawned == goal and killed >= goal and not _living_enemies_remain():
        active = false
        cleared = true
        room_cleared.emit(boss_room)

func _living_enemies_remain() -> bool:
    for enemy in enemies_root.get_children():
        if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
            return true
    return false
