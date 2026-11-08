extends SceneTree
## ALL IN 4.31.32: regresiones de sprites/órbita/límites y resurrección.
## Ejecución: godot --headless --path . --script res://tests/PruebaPistolaBrujula43132.gd
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    var player: Node2D = PLAYER_SCENE.instantiate() as Node2D
    root.add_child(player)
    player.set_physics_process(false)
    player.set_process(false)
    var arena: Rect2 = RunManager.arena_rect
    var margin: float = 17.0 # Celda pistol 32 / 2 + 1.
    var directions: Array[Vector2] = [
        Vector2.DOWN, Vector2(-1.0, 1.0).normalized(), Vector2.LEFT,
        Vector2(-1.0, -1.0).normalized(), Vector2.UP,
        Vector2(1.0, -1.0).normalized(), Vector2.RIGHT,
        Vector2(1.0, 1.0).normalized()
    ]
    var rarity_names: Array[String] = ["common", "rare", "epic", "legendary"]
    for rarity in rarity_names:
        var item_id: String = "pistol_%s" % rarity
        var added: Dictionary = InventoryManager.add_item(item_id)
        assert(bool(added.get("ok", false)), "No se pudo obtener pistola: %s" % rarity)
        var equipped: Dictionary = InventoryManager.equip_item(int(added["entry"]["uid"]))
        assert(bool(equipped.get("ok", false)), "No se pudo equipar pistola: %s" % rarity)
        for i in directions.size():
            player.position = arena.position + Vector2(29.0, 29.0)
            player.set("visual_direction", directions[i])
            player.set("_pistol_orbit_initialized", false)
            player.call("_update_weapon_sprite", 0.016)
            var sprite: Sprite2D = player.get_node("WeaponSprite") as Sprite2D
            assert(sprite.visible, "Sprite oculto en %s dir %d" % [rarity, i])
            assert(sprite.region_rect.position.x == float(i * 32), "Dirección errónea %s dir %d" % [rarity, i])
            assert(sprite.global_position.x >= arena.position.x + margin - 0.01, "Recorte a la izquierda")
            assert(sprite.global_position.y >= arena.position.y + margin - 0.01, "Recorte arriba")
            player.position = arena.end - Vector2(29.0, 29.0)
            player.set("_pistol_orbit_initialized", false)
            player.call("_update_weapon_sprite", 0.016)
            assert(sprite.global_position.x <= arena.end.x - margin + 0.01, "Recorte a la derecha")
            assert(sprite.global_position.y <= arena.end.y - margin + 0.01, "Recorte abajo")
    # La vista 3 debe entrar en la interpolación, no saltar al final.
    player.position = arena.get_center()
    player.set("visual_direction", Vector2.LEFT)
    player.set("_pistol_orbit_initialized", false)
    player.call("_update_weapon_sprite", 0.016)
    var previous_orbit: Vector2 = player.get("_pistol_orbit_position")
    player.set("visual_direction", Vector2(-1.0, -1.0).normalized())
    player.call("_update_weapon_sprite", 0.016)
    var next_orbit: Vector2 = player.get("_pistol_orbit_position")
    var aim_up_left: Vector2 = Vector2(-1.0, -1.0).normalized()
    var dir3_target: Vector2 = Vector2(0.0, -7.0) + Vector2(aim_up_left.x * 31.0, aim_up_left.y * 29.0) + Vector2(-4.0, -2.0)
    var expected_alpha: float = clampf(1.0 - exp(-13.0 * 0.016), 0.0, 1.0)
    assert(next_orbit.distance_to(previous_orbit.lerp(dir3_target, expected_alpha)) < 0.02, "El ajuste de dirección 3 no fue suavizado")
    # La función antes llamada sin argumento debe funcionar durante el regreso de muerte.
    player.call("begin_death_cinematic", 0)
    player.call("reset_death_cinematic")
    assert(not bool(player.get("death_cinematic_active")), "La muerte quedó activa tras reanimar")
    player.queue_free()
    print("ALL IN 4.31.32: cuatro rarezas, ocho direcciones, límites y resurrección: OK")
    quit(0)
