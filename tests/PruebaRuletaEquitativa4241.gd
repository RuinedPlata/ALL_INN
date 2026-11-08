extends SceneTree
## Godot 4.7.2: godot --headless --path . --script res://tests/PruebaRuletaEquitativa4241.gd
## Asegura 25% EXACTO (2.500 de 10.000 valores) para cada premio de nivel.

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    RunManager.reset_run()
    var boundaries: Dictionary = {
        0: "damage", 2499: "damage",
        2500: "attack", 4999: "attack",
        5000: "speed", 7499: "speed",
        7500: "projectile_speed", 9999: "projectile_speed"
    }
    for raw_roll in boundaries.keys():
        var result: Dictionary = RunManager.award_level_roll_for_roll(int(raw_roll))
        assert(str(result["stat"]) == str(boundaries[raw_roll]), "Límite incorrecto para tirada %d" % int(raw_roll))
    RunManager.reset_run()
    RunManager.player_health = 2
    var original_max: int = RunManager.max_health
    var original_shields: int = RunManager.shield_charges
    var counts: Dictionary = {"damage": 0, "attack": 0, "speed": 0, "projectile_speed": 0}
    for roll in range(10000):
        var result: Dictionary = RunManager.award_level_roll_for_roll(roll)
        var stat: String = str(result["stat"])
        assert(counts.has(stat), "Premio no contemplado: %s" % stat)
        counts[stat] = int(counts[stat]) + 1
    for stat in counts.keys():
        assert(int(counts[stat]) == 2500, "Se esperaba 25%% en %s; obtenido %d" % [stat, int(counts[stat])])
    assert(RunManager.player_health == 2, "La ruleta no debe curar")
    assert(RunManager.max_health == original_max, "La ruleta no debe aumentar corazones")
    assert(RunManager.shield_charges == original_shields, "La ruleta no debe otorgar escudos")
    assert(is_equal_approx(RunManager.level_damage_percent_bonus, 100.0), "+4% daño incorrecto")
    assert(is_equal_approx(RunManager.attack_bonus, 100.0), "+4% cadencia incorrecto")
    assert(is_equal_approx(RunManager.level_speed_bonus, 75.0), "+3% movimiento incorrecto")
    assert(is_equal_approx(RunManager.level_projectile_speed_bonus, 150.0), "+6% velocidad de proyectil incorrecto")
    print("ALL IN 4.24.1: cuatro premios con probabilidad idéntica del 25%; sin corazones ni escudos")
    quit(0)
