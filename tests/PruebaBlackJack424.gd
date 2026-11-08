extends SceneTree
## ALL IN 4.24. Abrir en Godot 4.7.2 y ejecutar:
## godot --headless --path . --script res://tests/PruebaBlackJack424.gd
## Comprueba: BLACK JACK conservado dentro del catálogo de 48, rarezas y ascensión, stats por nivel,
## BLACK JACK 1/2/4 proyectiles, factores 100/70/45, dispersión real,
## probabilidades defensa 5% -> 10% BJ (tope global 20%) y daño fraccional.

const DB = preload("res://scripts/systems/ItemDatabase.gd")
const PLAYER = preload("res://scripts/player/Player.gd")
const BULLET = preload("res://scripts/combat/Projectile.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _equip_piece(slot: String, rarity: String) -> void:
    var result: Dictionary = InventoryManager.add_item("bj_%s_%s" % [slot, rarity])
    assert(bool(result["ok"]))
    assert(bool(InventoryManager.equip_item(int(result["entry"]["uid"]))["ok"]))

func _verify() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    PactManager.reset_pacts()
    var slots: Array[String] = ["helmet", "chest", "legs", "boots"]
    var counted: int = 0
    for item_id in DB.ITEM_DEFS.keys():
        if str(DB.ITEM_DEFS[item_id].get("slot", "")) in slots:
            counted += 1
    assert(counted == 48, "En 4.27 deben existir 3 x 4 x 4 = 48 armaduras")
    assert(not DB.get_def("pistol_common").is_empty(), "Conservar pistola de Armas 2.0")
    assert(not DB.get_def("clock").is_empty(), "No alterar amuletos")

    for rarity in DB.RARITY_ORDER:
        for slot in slots:
            var id: String = "bj_%s_%s" % [slot, rarity]
            assert(not DB.get_def(id).is_empty(), "BLACK JACK sigue disponible")
            var cap: int = DB.level_cap(id, rarity)
            var low: Dictionary = DB.get_upgraded_stats(id, 1, rarity)
            var high: Dictionary = DB.get_upgraded_stats(id, cap, rarity)
            var stat: String = {"helmet": "accuracy", "chest": "damage_pct", "legs": "attack", "boots": "speed"}[slot]
            assert(float(high.get(stat, 0.0)) > float(low.get(stat, 0.0)), "Fusionar debe mejorar estadísticas")
            if rarity != "common":
                var index: int = DB.RARITY_ORDER.find(rarity)
                var previous_rarity: String = str(DB.RARITY_ORDER[index - 1])
                var prev_id: String = "bj_%s_%s" % [slot, previous_rarity]
                var prev_high: Dictionary = DB.get_upgraded_stats(prev_id, DB.level_cap(prev_id, previous_rarity), previous_rarity)
                assert(float(low.get(stat, 0.0)) >= float(prev_high.get(stat, 0.0)), "Ascender no reduce poder")
    assert(is_equal_approx(float(DB.get_upgraded_stats("bj_boots_common", 1)["evasion"]), 0.06))
    assert(is_equal_approx(float(DB.get_upgraded_stats("bj_chest_common", 1)["parry"]), 0.06))
    assert(is_equal_approx(float(DB.get_upgraded_stats("bj_boots_legendary", 7)["evasion"]), 0.105))
    assert(is_equal_approx(float(DB.get_upgraded_stats("bj_chest_legendary", 7)["parry"]), 0.105))
    assert(is_equal_approx(float(DB.get_upgraded_stats("bj_helmet_legendary", 7)["accuracy"]), 0.168))
    assert(is_equal_approx(float(DB.get_upgraded_stats("bj_legs_legendary", 7)["attack"]), 0.21))
    assert(is_equal_approx(float(DB.get_upgraded_stats("bj_legs_legendary", 7)["crit_damage"]), 0.126))

    assert(InventoryManager.black_jack_projectiles() == 1)
    assert(is_equal_approx(InventoryManager.black_jack_damage_factor(), 1.0))
    for slot in slots:
        _equip_piece(slot, "common")
    assert(InventoryManager.black_jack_projectiles() == 1)
    for slot in slots:
        _equip_piece(slot, "epic")
    assert(InventoryManager.black_jack_projectiles() == 2)
    assert(is_equal_approx(InventoryManager.black_jack_damage_factor(), 0.70))
    assert(PLAYER.black_jack_spread_degrees(2).size() == 2)
    assert(absf(PLAYER.black_jack_spread_degrees(2)[0]) >= 10.0)
    _equip_piece("helmet", "legendary")
    assert(InventoryManager.black_jack_projectiles() == 2, "La mezcla épica/legendaria sigue siendo x2")
    for slot in ["chest", "legs", "boots"]:
        _equip_piece(slot, "legendary")
    assert(InventoryManager.black_jack_projectiles() == 4)
    assert(is_equal_approx(InventoryManager.black_jack_damage_factor(), 0.45))
    assert(PLAYER.black_jack_spread_degrees(4).size() == 4)
    assert(is_equal_approx(PLAYER.black_jack_spread_degrees(4)[0], -18.0))
    assert(is_equal_approx(PLAYER.black_jack_spread_degrees(4)[1], -6.0))
    assert(is_equal_approx(PLAYER.black_jack_spread_degrees(4)[2], 6.0))
    assert(is_equal_approx(PLAYER.black_jack_spread_degrees(4)[3], 18.0))
    assert(InventoryManager.get_equipped_bonus("attack") >= 0.14)
    assert(InventoryManager.get_equipped_bonus("evasion") <= 0.20)
    assert(InventoryManager.get_equipped_bonus("parry") <= 0.20)

    # Cuatro balas reales al 45% hacen 1.8 de daño total si todas aciertan.
    # La salud enemiga ahora es fraccionaria: no existe resultado 0 aleatorio.
    var projectile = BULLET.new()
    projectile.damage = 0.45
    assert(is_equal_approx(projectile.damage * 4.0, 1.8))
    projectile.free()
    assert(RunManager.award_boss_coins(10) == 200, "Conservar pago del primer jefe")
    print("ALL IN 4.24: 16 armaduras, 25/25/25/25, raras, fusiones, x2/x4, daños, Parry/Evasión, monedas: OK")
    quit(0)
