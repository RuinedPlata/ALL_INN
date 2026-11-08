extends Node2D
# AStar 2D compartido. Tiene en cuenta los cuatro límites físicos reales.
const CELL: float = 20.0
var normal_grid: AStarGrid2D = AStarGrid2D.new()
var boss_grid: AStarGrid2D = AStarGrid2D.new()
var arena_rect: Rect2 = Rect2(20, 72, 500, 790)
var world_size: Vector2 = Vector2(540, 960)
var obstacles: Array[Rect2] = []

func _ready() -> void:
    add_to_group("room_navigation")

func configure(layout: Array, bounds: Vector2, arena: Rect2) -> void:
    world_size = bounds
    arena_rect = arena
    obstacles.clear()
    for entry in layout:
        var half: Vector2 = entry[1]
        obstacles.append(Rect2(entry[0] - half, half * 2.0))
    _build_grid(normal_grid, 27.0)
    _build_grid(boss_grid, 65.0)

func _build_grid(grid: AStarGrid2D, radius: float) -> void:
    grid.region = Rect2i(0, 0, ceili(world_size.x / CELL), ceili(world_size.y / CELL))
    grid.cell_size = Vector2(CELL, CELL)
    grid.offset = Vector2.ONE * (CELL * 0.5)
    grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    grid.update()
    for x in range(grid.region.size.x):
        for y in range(grid.region.size.y):
            var pos: Vector2 = Vector2(float(x) * CELL + CELL * 0.5, float(y) * CELL + CELL * 0.5)
            var blocked: bool = pos.x < arena_rect.position.x + radius + 4.0 or pos.x > arena_rect.end.x - radius - 4.0 or pos.y < arena_rect.position.y + radius + 4.0 or pos.y > arena_rect.end.y - radius - 4.0
            for rect in obstacles:
                if rect.grow(radius + 4.0).has_point(pos):
                    blocked = true
                    break
            if blocked:
                grid.set_point_solid(Vector2i(x, y))

func closest_walkable(target: Vector2, radius: float) -> Vector2:
    # Ajusta un objetivo de flanqueo dentro del área navegable. Si apunta
    # a un pilar, buscamos la celda libre más próxima, evitando bloqueos.
    var grid: AStarGrid2D = boss_grid if radius >= 30.0 else normal_grid
    var cell := Vector2i(floori(target.x / CELL), floori(target.y / CELL))
    var open_cell: Vector2i = _nearest_open(grid, cell)
    if open_cell.x < 0:
        return arena_rect.get_center()
    return grid.get_point_position(open_cell)

func clear_path(a: Vector2, b: Vector2, radius: float) -> bool:
    var shift: Vector2 = a.direction_to(b).orthogonal() * radius
    for offset in [Vector2.ZERO, shift, -shift]:
        var query := PhysicsRayQueryParameters2D.create(a + offset, b + offset, 16)
        query.hit_from_inside = true
        if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
            return false
    return true

func get_route(origin: Vector2, destination: Vector2, radius: float) -> Array[Vector2]:
    var result: Array[Vector2] = []
    if origin.distance_to(destination) < 1.0:
        return result
    if clear_path(origin, destination, radius):
        result.append(destination)
        return result
    var grid: AStarGrid2D = boss_grid if radius >= 30.0 else normal_grid
    var from_id: Vector2i = _nearest_open(grid, Vector2i(floori(origin.x / CELL), floori(origin.y / CELL)))
    var to_id: Vector2i = _nearest_open(grid, Vector2i(floori(destination.x / CELL), floori(destination.y / CELL)))
    if from_id.x < 0 or to_id.x < 0:
        return result
    var path: Array[Vector2i] = grid.get_id_path(from_id, to_id)
    for id in path:
        result.append(grid.get_point_position(id))
    if not result.is_empty() and origin.distance_to(result[0]) < CELL * 0.8:
        result.pop_front()
    return result

func _nearest_open(grid: AStarGrid2D, from_id: Vector2i) -> Vector2i:
    for radius in range(0, 9):
        var nearest := Vector2i(-1, -1)
        var distance: float = INF
        for x in range(maxi(0, from_id.x - radius), mini(grid.region.size.x - 1, from_id.x + radius) + 1):
            for y in range(maxi(0, from_id.y - radius), mini(grid.region.size.y - 1, from_id.y + radius) + 1):
                var cell := Vector2i(x, y)
                if grid.is_point_solid(cell):
                    continue
                var dist: float = Vector2(cell).distance_squared_to(Vector2(from_id))
                if dist < distance:
                    distance = dist
                    nearest = cell
        if nearest.x >= 0:
            return nearest
    return Vector2i(-1, -1)
