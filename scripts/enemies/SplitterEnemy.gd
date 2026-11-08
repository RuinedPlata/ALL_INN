extends "res://scripts/enemies/BasicEnemy.gd"
# Aparece a partir de la sala 11. Al morir libera dos tiradores veloces.
const CHILD_SCENE: PackedScene = preload("res://scenes/enemies/SplitMinion.tscn")
const INCUBATOR_DEATH_SCENE: PackedScene = preload("res://scenes/enemies/IncubatorDeathFX.tscn")
@onready var incubator_sprite: AnimatedSprite2D = get_node_or_null("IncubatorSprite") as AnimatedSprite2D
@onready var incubator_shadow: AnimatedSprite2D = get_node_or_null("IncubatorShadow") as AnimatedSprite2D
var incubator_phase: float = 0.0
var incubator_flash: bool = false

func _ready() -> void:
    super._ready()
    add_to_group("splitter_enemies")
    if incubator_sprite != null:
        incubator_sprite.play("hover")
        if incubator_shadow != null:
            incubator_shadow.play("shadow")

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if incubator_sprite == null or dying or not RunManager.run_active:
        return
    # Hover is purely cosmetic: never moves the physical body or collision shape.
    incubator_phase += delta * 3.7
    incubator_sprite.position.y = -5.0 + sin(incubator_phase) * 1.5
    var hit_now: bool = flash_timer > 0.0
    if incubator_flash != hit_now:
        incubator_flash = hit_now
        incubator_sprite.modulate = Color("#ff7777") if hit_now else Color.WHITE

func take_damage(amount: float) -> void:
    if dying:
        return
    var lethal: bool = health - amount <= 0
    var death_position: Vector2 = global_position
    # Death FX has no collision/enemy group, and does not delay drops or children.
    if lethal and incubator_sprite != null:
        var effect: AnimatedSprite2D = INCUBATOR_DEATH_SCENE.instantiate() as AnimatedSprite2D
        get_tree().current_scene.add_child(effect)
        effect.global_position = global_position + Vector2(0, -5)
        effect.scale = global_scale
        incubator_sprite.visible = false
        if incubator_shadow != null:
            incubator_shadow.visible = false
        collision_layer = 0
        collision_mask = 0
    # El padre cuenta como una sola muerte y ofrece como máximo UN botín.
    super.take_damage(amount)
    if lethal and RunManager.run_active:
        _spawn_children(death_position)

func _spawn_children(center: Vector2) -> void:
    var root: Node = get_parent()
    var navigator_node: Node = get_tree().get_first_node_in_group("room_navigation")
    for i in range(2):
        var child: CharacterBody2D = CHILD_SCENE.instantiate() as CharacterBody2D
        child.set("max_health", 1)
        child.set("move_speed", 122.0 + clampf(float(RunManager.current_level - 25), 0.0, 18.0))
        child.set("attack_cooldown", 1.15)
        child.set("contact_damage", 4)
        child.scale = Vector2(1.6, 1.6)
        var offset: Vector2 = Vector2(-43, 0) if i == 0 else Vector2(43, 0)
        var spawn_point: Vector2 = center + offset
        if is_instance_valid(navigator_node):
            # Hijos de tamaño 1.6x: escoger SIEMPRE una celda navegable,
            # incluso si el divisor murió junto a un obstáculo o un borde.
            spawn_point = navigator_node.closest_walkable(spawn_point, 18.0)
        child.global_position = spawn_point
        root.add_child(child)

func _draw() -> void:
    if incubator_sprite != null:
        _draw_health_bar()
        return
    var color: Color = Color("#b0e1a5") if flash_timer > 0.0 else Color("#4c9a79")
    draw_circle(Vector2.ZERO, 15, color)
    draw_circle(Vector2(-5, -2), 2.5, Color.WHITE)
    draw_circle(Vector2(5, -2), 2.5, Color.WHITE)
    draw_circle(Vector2(-5, -2), 1.1, Color("#233b34"))
    draw_circle(Vector2(5, -2), 1.1, Color("#233b34"))
    draw_line(Vector2(-9, 9), Vector2(9, 9), Color("#233b34"), 2.0)
    _draw_health_bar()
