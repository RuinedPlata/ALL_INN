extends SceneTree
## Godot 4.3+: godot --headless --path . --script res://tests/PruebaEconomiaYNiveles421.gd
## Regresión 4.21 adaptada a 4.24.1: escala de monedas + ruleta de ESTADÍSTICAS 25% cada una.

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    PactManager.reset_pacts()

    var examples: Dictionary = {
        1: 30, 9: 30, 11: 40, 19: 40,
        21: 50, 29: 50, 31: 60, 39: 60,
        41: 70, 49: 70, 51: 80, 91: 120
    }
    for room in examples.keys():
        assert(RunManager.get_normal_room_cash_reward(int(room)) == int(examples[room]), "Escalado incorrecto sala %d" % int(room))
    for boss_room in [10, 20, 30, 40, 50]:
        assert(RunManager.get_normal_room_cash_reward(boss_room) == 0, "Un jefe no usa recompensa de sala normal")
    assert(RunManager.get_normal_room_cash_reward(0) == 0)
    assert(RunManager.NORMAL_ROOM_COMPLETION_COINS == 10, "Ingreso fijo 4.31 = 10")
    assert(RunManager.award_normal_room_coins(11) == 10)
    assert(RunManager.award_normal_room_coins(11) == 0, "Pago fijo duplicado")
    assert(RunManager.award_boss_coins(10) == 200, "No alterar bonos de jefes")
    assert(RunManager.award_boss_coins(10) == 0, "Pago de jefe duplicado")
    assert(RunManager.award_boss_coins(20) == 250)

    RunManager.reset_run()
    RunManager.player_health = 2
    var original_max: int = RunManager.max_health
    var original_shields: int = RunManager.shield_charges
    var counts: Dictionary = {"damage": 0, "attack": 0, "speed": 0, "projectile_speed": 0}
    for roll in range(10000):
        var result: Dictionary = RunManager.award_level_roll_for_roll(roll)
        var stat: String = str(result["stat"])
        assert(counts.has(stat), "Premio de nivel no es una estadística: %s" % stat)
        counts[stat] = int(counts[stat]) + 1
        assert(RunManager.player_health == 2, "La ruleta curó al jugador")
        assert(RunManager.max_health == original_max, "La ruleta otorgó corazón máximo")
        assert(RunManager.shield_charges == original_shields, "La ruleta otorgó escudo")
    assert(counts["damage"] == 2500)
    assert(counts["attack"] == 2500)
    assert(counts["speed"] == 2500)
    assert(counts["projectile_speed"] == 2500)
    assert(RunManager.level_damage_percent_bonus > 1.0, "Daño debería poder superar +100%")
    assert(RunManager.attack_bonus > 1.0, "Cadencia debería poder superar +100%")
    assert(RunManager.level_speed_bonus > 1.0, "Movimiento debería poder superar +100%")
    assert(RunManager.level_projectile_speed_bonus > 1.0, "Proyectiles deberían poder superar +100%")

    RunManager.reset_run()
    assert(is_zero_approx(RunManager.level_damage_percent_bonus))
    assert(is_zero_approx(RunManager.level_projectile_speed_bonus))
    assert(is_zero_approx(RunManager.level_speed_bonus))
    assert(is_zero_approx(RunManager.attack_bonus))
    print("ALL IN 4.24.1: economía, ruleta solo estadísticas (25% cada una) y reinicio verificados")
    quit(0)
