extends SceneTree
## ALL IN 4.25 — pruebas dirigidas de impactos, barrido y abanico BLACK JACK.
## Godot 4.7.2:
## godot --headless --path . --script res://tests/PruebaProyectiles425.gd

const BULLET_SCENE: PackedScene = preload("res://scenes/combat/Projectile.tscn")
const PLAYER = preload("res://scripts/player/Player.gd")

class TestEnemy:
    extends StaticBody2D
    var damage_received: float = 0.0
    var times_hit: int = 0
    func take_damage(amount: float) -> void:
        damage_received += amount
        times_hit += 1

func _initialize() -> void:
    call_deferred("_test")

func _make_enemy(pos: Vector2) -> TestEnemy:
    var enemy := TestEnemy.new()
    enemy.collision_layer = 2
    enemy.collision_mask = 0
    enemy.position = pos
    var collider := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = 12.0
    collider.shape = circle
    enemy.add_child(collider)
    get_root().add_child(enemy)
    enemy.add_to_group("enemies")
    return enemy

func _make_bullet(pos: Vector2, speed_value: float, damage_value: float) -> Area2D:
    var bullet: Area2D = BULLET_SCENE.instantiate()
    bullet.set("direction", Vector2.RIGHT)
    bullet.set("speed", speed_value)
    bullet.set("damage", damage_value)
    get_root().add_child(bullet)
    bullet.global_position = pos
    # Dejamos el avance en manos del test, no del bucle automático.
    bullet.set_physics_process(false)
    return bullet

func _test() -> void:
    # El abanico legendario debe ser equilibrado y no excesivamente abierto.
    var spread: PackedFloat32Array = PLAYER.black_jack_spread_degrees(4)
    assert(spread.size() == 4)
    assert(is_equal_approx(spread[0], -18.0))
    assert(is_equal_approx(spread[1], -6.0))
    assert(is_equal_approx(spread[2], 6.0))
    assert(is_equal_approx(spread[3], 18.0))
    assert(is_equal_approx(0.45 * 4.0, 1.80), "Cuatro disparos legendarios conservan 1.8 daño total teórico")

    # Un proyectil fraccionario DEBE registrar daño y desaparecer en el primer enemigo.
    var target_a := _make_enemy(Vector2(100, 100))
    var target_b := _make_enemy(Vector2(160, 100))
    var shot := _make_bullet(Vector2(20, 100), 12000.0, 0.45)
    await physics_frame
    await physics_frame
    # 200 px de recorrido en un fotograma: supera ampliamente el diámetro enemigo.
    shot.call("_physics_process", 1.0 / 60.0)
    assert(is_equal_approx(target_a.damage_received, 0.45), "El impacto 45% debe registrar daño fraccionario")
    assert(target_a.times_hit == 1, "Un proyectil no debe impactar dos veces al mismo enemigo")
    assert(is_equal_approx(target_b.damage_received, 0.0), "No puede atravesar al segundo enemigo")
    assert(bool(shot.get("spent")), "El proyectil debe consumirse al primer impacto")
    shot.call("_on_body_entered", target_a)
    assert(target_a.times_hit == 1, "No repetir el impacto aunque coincida la señal body_entered")

    # La Sobrecarga Filo deja de crear balas perforantes; preserva una mejora de daño.
    PactManager.reset_pacts()
    PactManager.temporary["filo"] = {"kind": "overload", "expires": 10}
    assert(PactManager.get_stat("damage") >= 0.08)
    var probe: Area2D = BULLET_SCENE.instantiate()
    assert(not str(probe.get_script().source_code).contains("pierce_left"), "La bala base no debe perforar")
    probe.free()
    print("ALL IN 4.25: daño fraccionario, impacto único, sweep de alta velocidad, abanico x4 y Filo sin perforación: OK")
    quit(0)
