extends Node2D
# Una sola capa de impactos: sin crear un nodo por cada perdigón.
# Los golpes simultáneos se fusionan espacialmente para Android.
const LIFETIME: float = 0.21
const MAX_MARKS: int = 36
var marks: Array[Dictionary] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    add_to_group("combat_feedback")

func add_impact(where: Vector2, kind: String, strength: float = 1.0) -> void:
    var color: Color = Color("#fff0a3")
    match kind:
        "enemy": color = Color("#ffe3a1")
        "player": color = Color("#ff557e")
        "parry": color = Color("#77d9ff")
        "evasion": color = Color("#a9ffc8")
        "block": color = Color("#b5ddff")
        "boss": color = Color("#ffe4ab")
    for i in range(marks.size()):
        if marks[i]["kind"] == kind and (marks[i]["pos"] as Vector2).distance_squared_to(where) < 196.0 and float(marks[i]["age"]) < 0.07:
            marks[i]["size"] = minf(17.0, float(marks[i]["size"]) + 2.0)
            return
    if marks.size() >= MAX_MARKS:
        marks.pop_front()
    marks.append({"pos": where, "kind": kind, "color": color, "age": 0.0, "size": clampf(6.0 + strength * 1.6, 7.0, 14.0)})
    queue_redraw()

func _process(delta: float) -> void:
    if marks.is_empty():
        return
    for i in range(marks.size() - 1, -1, -1):
        marks[i]["age"] = float(marks[i]["age"]) + delta
        if float(marks[i]["age"]) >= LIFETIME:
            marks.remove_at(i)
    queue_redraw()

func _draw() -> void:
    for mark in marks:
        var t: float = float(mark["age"]) / LIFETIME
        var color: Color = mark["color"]
        color.a = 0.9 * (1.0 - t)
        var center: Vector2 = mark["pos"]
        var radius: float = float(mark["size"]) * (0.55 + 0.85 * t)
        draw_arc(center, radius, 0.0, TAU, 12, color, 2.1)
        draw_line(center + Vector2(-radius - 3.0, 0.0), center + Vector2(-radius * 0.35, 0.0), color, 2.0)
        draw_line(center + Vector2(radius * 0.35, 0.0), center + Vector2(radius + 3.0, 0.0), color, 2.0)
        draw_line(center + Vector2(0.0, -radius - 3.0), center + Vector2(0.0, -radius * 0.35), color, 2.0)
        draw_line(center + Vector2(0.0, radius * 0.35), center + Vector2(0.0, radius + 3.0), color, 2.0)
