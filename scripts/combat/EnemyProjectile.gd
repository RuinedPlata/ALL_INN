extends Area2D
# Proyectil enemigo: nunca daña a otros enemigos, solo al jugador.

@export var speed: float = 205.0
@export var damage: int = 12
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.DOWN
var age: float = 0.0
var spent: bool = false

func _ready() -> void:
    # Se instancian bajo Main (ALWAYS), pero deben detenerse en los menús.
    process_mode = Node.PROCESS_MODE_PAUSABLE
    add_to_group("room_projectiles")
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    if spent:
        return
    if not RunManager.run_active:
        queue_free()
        return
    global_position += direction * speed * delta
    age += delta
    if age >= lifetime:
        queue_free()

func _on_body_entered(body: Node2D) -> void:
    if spent:
        return
    if (body.collision_layer & 16) != 0:
        spent = true
        queue_free()
    elif body.is_in_group("player") and body.has_method("receive_contact_damage"):
        spent = true
        body.receive_contact_damage(damage)
        queue_free()

func _draw() -> void:
    draw_circle(Vector2.ZERO, 7.0, Color("#301526"))
    draw_circle(Vector2.ZERO, 5.3, Color("#ff779f"))
    draw_circle(Vector2(-1.4, -1.7), 1.5, Color("#fff0c7"))
