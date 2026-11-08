extends StaticBody2D
# Obstáculo sólido y visible; también bloquea balas de ambos bandos.
@export var half_size: Vector2 = Vector2(30, 45)
var collision_shape: CollisionShape2D

func _ready() -> void:
    collision_layer = 16
    collision_mask = 0
    collision_shape = CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = half_size * 2.0
    collision_shape.shape = shape
    add_child(collision_shape)
    queue_redraw()

func _draw() -> void:
    var size: Vector2 = half_size * 2.0
    draw_rect(Rect2(-half_size + Vector2(4, 7), size), Color("#15121e"), true)
    draw_rect(Rect2(-half_size, size), Color("#5a5269"), true)
    draw_rect(Rect2(-half_size + Vector2(5, 5), size - Vector2(10, 10)), Color("#807389"), true)
    draw_line(Vector2(-half_size.x + 7, -half_size.y + 10), Vector2(half_size.x - 7, -half_size.y + 10), Color("#b3a2ba"), 2.0)
    draw_circle(Vector2(-half_size.x + 12, -half_size.y + 12), 3.0, Color("#bf96dc"))
