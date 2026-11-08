extends RefCounted
# Generador procedural PARA ARENAS VERTICALES. Cada partida recibe semilla nueva.
# No acepta un mapa si obstruye ruta de jugador, enemigo, jefe o salida.
const CELL: float = 20.0
const NORMAL_RADIUS: float = 27.0
const BOSS_RADIUS: float = 65.0
const MAX_TRIES: int = 60
var run_seed: int = 0

func _init() -> void:
    var seed_rng := RandomNumberGenerator.new()
    seed_rng.randomize()
    run_seed = int(seed_rng.randi())

func generate(room_number: int, arena: Rect2) -> Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = run_seed ^ (room_number * 1000003)
    var is_boss: bool = room_number % 10 == 0
    if is_boss:
        return [] # Jefes: sin pilares; embestida y círculo siempre esquivables.
    for _attempt in range(MAX_TRIES):
        var layout: Array = _candidate(rng, arena, is_boss)
        if layout.size() >= (1 if is_boss else 2) and (not is_boss or _connected(layout, arena, BOSS_RADIUS)) and _connected(layout, arena, NORMAL_RADIUS):
            return layout
    # Nunca entregar una sala sin salida: distribución de reserva validada.
    var fallback: Array = [
        [Vector2(arena.position.x + arena.size.x * 0.28, arena.position.y + arena.size.y * 0.53), Vector2(25.0, 33.0)],
        [Vector2(arena.position.x + arena.size.x * 0.72, arena.position.y + arena.size.y * 0.53), Vector2(25.0, 33.0)]
    ]
    if _connected(fallback, arena, BOSS_RADIUS) and _connected(fallback, arena, NORMAL_RADIUS):
        return fallback
    return [] # Arena vacía antes que una mazmorra imposible.

func _candidate(rng: RandomNumberGenerator, arena: Rect2, boss_room: bool) -> Array:
    var anchors: Array[Vector2] = [
        Vector2(0.25, 0.25), Vector2(0.5, 0.28), Vector2(0.75, 0.25),
        Vector2(0.25, 0.43), Vector2(0.75, 0.43),
        Vector2(0.25, 0.64), Vector2(0.75, 0.64),
        Vector2(0.25, 0.8), Vector2(0.50, 0.77), Vector2(0.75, 0.8)
    ]
    var order: Array[int] = []
    for i in range(anchors.size()):
        order.append(i)
    for i in range(order.size() - 1, 0, -1):
        var j: int = rng.randi_range(0, i)
        var prev: int = order[i]
        order[i] = order[j]
        order[j] = prev
    var placed: Array = []
    var target: int = rng.randi_range(1, 3) if boss_room else rng.randi_range(2, 4)
    var player_spawn: Vector2 = arena.get_center()
    var boss_spawn: Vector2 = Vector2(arena.get_center().x, arena.position.y + 135.0)
    var exit_point: Vector2 = Vector2(arena.end.x - 30.0, arena.get_center().y)
    for index in order:
        if placed.size() >= target:
            break
        var anchor: Vector2 = anchors[index]
        var p: Vector2 = arena.position + Vector2(anchor.x * arena.size.x, anchor.y * arena.size.y)
        p += Vector2(rng.randf_range(-16.0, 16.0), rng.randf_range(-22.0, 22.0))
        var half: Vector2 = Vector2(float(rng.randi_range(20, 34)), float(rng.randi_range(24, 41)))
        if rng.randf() < 0.35:
            half = Vector2(float(rng.randi_range(31, 43)), float(rng.randi_range(19, 27)))
        var obstacle := Rect2(p - half, half * 2.0)
        if not arena.grow(-58.0).encloses(obstacle):
            continue
        var forbidden: bool = false
        for point in [player_spawn, boss_spawn, exit_point]:
            if obstacle.grow(96.0).has_point(point):
                forbidden = true
        if forbidden:
            continue
        for old in placed:
            var oldrect := Rect2(old[0] - old[1], old[1] * 2.0)
            if obstacle.grow(86.0).intersects(oldrect.grow(86.0)):
                forbidden = true
                break
        if not forbidden:
            placed.append([p, half])
    return placed

func _connected(layout: Array, arena: Rect2, radius: float) -> bool:
    # Cuadrícula en coordenadas de mundo; dimensiones limitadas al final del arena.
    var grid := AStarGrid2D.new()
    grid.region = Rect2i(0, 0, ceili((arena.end.x + 25.0) / CELL), ceili((arena.end.y + 25.0) / CELL))
    grid.cell_size = Vector2(CELL, CELL)
    grid.offset = Vector2(CELL * 0.5, CELL * 0.5)
    grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    grid.update()
    for x in range(grid.region.size.x):
        for y in range(grid.region.size.y):
            var pos := Vector2(float(x) * CELL + CELL * 0.5, float(y) * CELL + CELL * 0.5)
            var solid: bool = (pos.x < arena.position.x + radius + 4.0 or pos.x > arena.end.x - radius - 4.0 or pos.y < arena.position.y + radius + 4.0 or pos.y > arena.end.y - radius - 4.0)
            for entry in layout:
                var half: Vector2 = entry[1]
                var center: Vector2 = entry[0]
                if Rect2(center - half - Vector2.ONE * (radius + 4.0), (half + Vector2.ONE * (radius + 4.0)) * 2.0).has_point(pos):
                    solid = true
                    break
            if solid:
                grid.set_point_solid(Vector2i(x, y))
    var margin: float = 104.0
    var checks: Array[Vector2] = [
        arena.get_center(),
        Vector2(arena.get_center().x, arena.position.y + 105.0),
        Vector2(arena.end.x - 104.0, arena.get_center().y),
        arena.position + Vector2(margin, margin),
        Vector2(arena.end.x - margin, arena.position.y + margin),
        Vector2(arena.position.x + margin, arena.end.y - margin),
        arena.end - Vector2(margin, margin),
        Vector2(arena.position.x + margin, arena.get_center().y),
        Vector2(arena.end.x - margin, arena.get_center().y)
    ]
    var origin: Vector2i = _cell(checks[0])
    if grid.is_point_solid(origin):
        return false
    for pos in checks:
        var end: Vector2i = _cell(pos)
        if grid.is_point_solid(end) or grid.get_id_path(origin, end).is_empty():
            return false
    return true

func _cell(p: Vector2) -> Vector2i:
    return Vector2i(floori(p.x / CELL), floori(p.y / CELL))
