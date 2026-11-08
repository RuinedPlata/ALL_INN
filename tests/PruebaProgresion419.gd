extends SceneTree
## Godot 4.3+: godot --headless --path . --script res://tests/PruebaProgresion419.gd
## Regresión: botín por umbrales de sala, garantía épica, economía y Sobrecarga x7.

const DB = preload("res://scripts/systems/ItemDatabase.gd")

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    PactManager.reset_pacts()

    # Verificación exhaustiva de los 10,000 resultados posibles de cada etapa.
    var chapters: Array[int] = [1, 10, 14, 15, 31, 39, 40, 50, 56, 90]
    for room in chapters:
        var allowed: Array[String] = ["common"]
        if room >= 15:
            allowed.append("rare")
        if room >= 40:
            allowed.append("epic")
        if room >= 56:
            allowed.append("legendary")
        var counts: Dictionary = {"common": 0, "rare": 0, "epic": 0, "legendary": 0}
        for roll in range(10000):
            var rarity: String = DB.enemy_quality_rarity_for_roll(room, roll)
            assert(rarity in allowed, "Drop prohibido en sala %d: %s" % [room, rarity])
            counts[rarity] = int(counts[rarity]) + 1
        assert(int(counts["common"]) > 0)
        if room >= 15:
            assert(int(counts["rare"]) > 0)
        if room >= 40:
            assert(int(counts["epic"]) > 0)
        if room >= 56:
            assert(int(counts["legendary"]) > 0)

    # La garantía de épico en tirada 25 NUNCA puede adelantar la progresión.
    for room in [1, 10, 15, 31, 39]:
        RunManager.current_level = room
        RunManager.quality_rolls_since_epic = 24
        for trial in range(100):
            var rarity: String = RunManager.roll_quality_loot_rarity()
            assert(rarity != "epic" and rarity != "legendary", "La protección contra mala suerte saltó el candado")
        assert(RunManager.quality_rolls_since_epic == 0)
    RunManager.current_level = 40
    RunManager.quality_rolls_since_epic = 24
    assert(RunManager.roll_quality_loot_rarity() == "epic", "Garantía épica en sala 40+ tras 25 tiradas")
    assert(RunManager.quality_rolls_since_epic == 0)
    for room in [1, 10, 14]:
        RunManager.current_level = room
        for trial in range(100):
            assert(RunManager.roll_guaranteed_loot_rarity() == "common", "Codicia no puede soltar raro antes de sala 15")

    # Ingreso base de una sala normal, exactamente una vez, incluso al descansar.
    RunManager.reset_run()
    assert(RunManager.coins == 100)
    assert(RunManager.award_normal_room_coins(1) == 10)
    assert(RunManager.coins == 110)
    assert(RunManager.award_normal_room_coins(1) == 0 and RunManager.coins == 110)
    assert(RunManager.award_normal_room_coins(10) == 0, "Sin pagos normales en salas de jefe")
    assert(RunManager.award_normal_room_coins(2) == 10 and RunManager.coins == 120)
    var before_boss: int = RunManager.coins
    assert(RunManager.award_boss_coins(10) == 200)
    assert(RunManager.coins == before_boss + 200, "Bono del jefe NO cambia")
    assert(RunManager.award_boss_coins(10) == 0)
    assert(RunManager.coins == before_boss + 200)
    assert(RunManager.NORMAL_ROOM_CASH_COINS == 30)

    # La 4.ª victoria estando ya en +3 concede exactamente 7 salas de Sobrecarga.
    PactManager.reset_pacts()
    PactManager.begin_room(1)
    PactManager.fortune["filo"] = 3
    RunManager.add_coins(1000) # La actualización 4.27 cobra 10 monedas por pacto.
    var activated: bool = false
    for trial in range(100):
        PactManager.fortune["filo"] = 3
        var outcome: Dictionary = PactManager.resolve_pact("filo")
        if bool(outcome["won"]):
            activated = true
            break
    assert(activated and PactManager.is_active("filo", "overload"))
    assert(int(PactManager.temporary["filo"]["expires"]) == 8)
    # Sobrecargas diferentes se combinan y no se cancelan entre ellas.
    PactManager.temporary["ritmo"] = {"kind": "overload", "expires": 8}
    PactManager.begin_room(7)
    assert(PactManager.is_active("filo", "overload") and PactManager.is_active("ritmo", "overload"))
    PactManager.begin_room(8)
    assert(not PactManager.is_active("filo", "overload") and not PactManager.is_active("ritmo", "overload"))
    print("ALL IN 4.19: progresión de botín, economía, jefes y 7 salas verificados")
    quit(0)
