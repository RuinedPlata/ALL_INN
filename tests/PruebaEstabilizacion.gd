extends SceneTree
## Ejecutar: godot --headless --path . --script res://tests/PruebaEstabilizacion.gd
## Compara reglas de inventario, ascensión, costos, menús, rarezas y límites de rosas.

const DB = preload("res://scripts/systems/ItemDatabase.gd")
const LEVEL_SCRIPT = preload("res://scripts/systems/LevelManager.gd")

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    PactManager.reset_pacts()
    # Repetir el caso que dejaba una sola opción de pacto.
    PactManager.no_affinity_next_room = true
    PactManager.begin_room(2)
    for trial in range(300):
        var offers: Array[String] = PactManager.draw_offers()
        assert(offers.size() == 3, "Siempre tres pactos incluso tras Segunda Oportunidad")
        assert(offers[0] != offers[1] and offers[1] != offers[2] and offers[0] != offers[2])
    # Cada tirador rosa aporta uno al conteo. La IA nunca crea un quinto rosa.
    var level_manager: Node = LEVEL_SCRIPT.new()
    root.add_child(level_manager)
    for i in range(4):
        var ranged_marker := Node2D.new()
        ranged_marker.add_to_group("ranged_enemies")
        root.add_child(ranged_marker)
    assert(level_manager._active_ranged_count() == 4, "Conteo de tiradores simultáneos")
    for marker in get_nodes_in_group("ranged_enemies"):
        marker.queue_free()
    await process_frame
    assert(level_manager._active_ranged_count() == 0, "Cupo se libera tras eliminar tiradores")
    assert(int(DB.level_cap("bj_boots_rare")) == 4)
    # Con 0 monedas NO puede fusionarse ni cambiar niveles o rareza.
    var first: Dictionary = InventoryManager.add_item("bj_boots_rare")["entry"]
    var uid: int = int(first["uid"])
    for i in range(7):
        InventoryManager.add_item("bj_boots_rare")
    RunManager.coins = 0
    var first_cost: int = InventoryManager.get_fusion_cost(uid)
    assert(first_cost > 0)
    var broke_result: Dictionary = InventoryManager.fuse_item(uid)
    assert(not bool(broke_result["ok"]) and InventoryManager.get_item_level(uid) == 1, "Sin saldo no se fusiona")
    RunManager.add_coins(3000)
    # Subir el primer raro hasta Nv.4, luego el segundo raro hasta Nv.4.
    for i in range(3):
        assert(bool(InventoryManager.fuse_item(uid)["ok"]))
    assert(InventoryManager.get_item_level(uid) == 4)
    var second_uid: int = -1
    for entry in InventoryManager.items:
        if int(entry["uid"]) != uid:
            second_uid = int(entry["uid"])
            break
    assert(second_uid > 0)
    for i in range(3):
        assert(bool(InventoryManager.fuse_item(second_uid)["ok"]))
    assert(InventoryManager.get_item_level(second_uid) == 4)
    assert(not InventoryManager.get_ascension_candidate(uid).is_empty(), "Dos raras iguales Nv.4 habilitan ascensión")
    var last_cost: int = InventoryManager.get_ascension_cost(uid)
    assert(last_cost == 180, "Costo raro a épico debe estar definido y ser visible")
    var before_balance: int = RunManager.coins
    var old_power: float = DB.power_score("bj_boots_rare", 4, "rare")
    var result: Dictionary = InventoryManager.ascend_item(uid)
    assert(bool(result["ok"]), "Debe ascender rara -> épica")
    var ascended: Dictionary = InventoryManager.find_entry(uid)
    assert(str(ascended["id"]) == "bj_boots_epic" and str(ascended["rarity"]) == "epic" and int(ascended["level"]) == 1, "Identidad conservada y nivel reiniciado")
    assert(DB.power_score("bj_boots_epic", 1, "epic") > old_power, "La pieza ascendida no debe empeorar en fuerza ponderada")
    assert(RunManager.coins == before_balance - last_cost, "Ascensión debe cobrar exactamente una vez")
    assert(InventoryManager.items.size() == 1, "Donante consumido sin duplicaciones")
    # Pity en calidad, sin conceder bolsas de monedas ni tocar bonificaciones del jefe.
    RunManager.current_level = 40
    RunManager.quality_rolls_since_epic = RunManager.EPIC_PITY_QUALITY_ROLLS - 1
    assert(RunManager.roll_quality_loot_rarity() == "epic", "Pity épico")
    assert(RunManager.quality_rolls_since_epic == 0)
    var expected: int = RunManager.coins + 200
    RunManager.award_boss_coins(10)
    assert(RunManager.coins == expected, "Bono jefe sala 10 intacto")
    RunManager.award_boss_coins(10)
    assert(RunManager.coins == expected, "Bono de jefe no se duplica")
    print("ALL IN 4.19: validación de reglas completada")
    quit(0)
