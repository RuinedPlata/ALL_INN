extends SceneTree
## ALL IN 4.27: 48 armaduras (32 nuevas), identidad de forja, afinidad,
## pasivas TRAGAPERRAS y JACKPOT y economía de los pactos.
## Ejecutar: godot --headless --path . --script res://tests/PruebaTresConjuntos427.gd

const DB = preload("res://scripts/systems/ItemDatabase.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _equip(prefix: String, rarity: String) -> void:
    for slot in ["helmet", "chest", "legs", "boots"]:
        var result: Dictionary = InventoryManager.add_item("%s_%s_%s" % [prefix, slot, rarity])
        assert(bool(result["ok"]), "No se pudo crear armadura")
        assert(bool(InventoryManager.equip_item(int(result["entry"]["uid"]))["ok"]), "No se pudo equipar")

func _verify() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    PactManager.reset_pacts()
    var counts: Dictionary = {"black_jack": 0, "tragaperras": 0, "jackpot": 0}
    for id in DB.ITEM_DEFS.keys():
        var set_id: String = str(DB.ITEM_DEFS[id].get("set_id", ""))
        if counts.has(set_id):
            counts[set_id] = int(counts[set_id]) + 1
    assert(int(counts["black_jack"]) == 16)
    assert(int(counts["tragaperras"]) == 16)
    assert(int(counts["jackpot"]) == 16)
    var rarity_names: Array[String] = ["common", "rare", "epic", "legendary"]
    for prefix in ["bj", "tp", "jp"]:
        for slot in ["helmet", "chest", "legs", "boots"]:
            for rarity in rarity_names:
                var id: String = "%s_%s_%s" % [prefix, slot, rarity]
                assert(not DB.get_def(id).is_empty(), "Falta pieza " + id)
                assert(str(DB.get_def(id)["slot"]) == slot)
                assert(str(DB.get_def(id)["rarity"]) == rarity)
                assert(not DB.get_upgraded_stats(id, DB.level_cap(id)).is_empty())
                if rarity != "legendary":
                    var promoted: String = DB.ascended_item_id(id)
                    assert(not DB.get_def(promoted).is_empty(), "Ascensión rota: " + id)
                    assert(str(DB.get_def(promoted)["slot"]) == slot)
                    assert(str(DB.get_def(promoted)["set_id"]) == str(DB.get_def(id)["set_id"]))
    assert(is_equal_approx(float(DB.get_upgraded_stats("tp_boots_legendary", 7)["speed"]), 0.21))
    assert(is_equal_approx(float(DB.get_upgraded_stats("tp_boots_legendary", 7)["evasion"]), 0.20))
    assert(is_equal_approx(float(DB.get_upgraded_stats("jp_chest_legendary", 7)["parry"]), 0.20))
    assert(is_equal_approx(float(DB.get_upgraded_stats("jp_chest_legendary", 7)["damage_pct"]), 0.2625))
    assert(is_equal_approx(float(DB.get_upgraded_stats("jp_helmet_legendary", 7)["accuracy"]), 0.252))
    assert(float(DB.get_upgraded_stats("jp_legs_legendary", 7)["attack"]) < 0.0)
    assert(InventoryManager.black_jack_projectiles() == 1)
    _equip("tp", "epic")
    assert(InventoryManager.set_tier("tragaperras") == 1)
    assert(is_equal_approx(InventoryManager.tragaperras_shield_interval(), 25.0))
    assert(InventoryManager.black_jack_projectiles() == 1)
    RunManager._advance_set_shield(25.0)
    assert(RunManager.set_shield_active, "Escudo épico tras 25s sin daño")
    for attempt in range(100):
        if not RunManager.set_shield_active:
            break
        RunManager.damage_player(1)
    assert(not RunManager.set_shield_active)
    assert(RunManager.player_health == 3, "Escudo consumido antes de un corazón")
    _equip("tp", "legendary")
    assert(InventoryManager.set_tier("tragaperras") == 2)
    assert(is_equal_approx(InventoryManager.tragaperras_shield_interval(), 18.0))
    _equip("jp", "epic")
    assert(InventoryManager.set_tier("jackpot") == 1)
    assert(is_equal_approx(InventoryManager.jackpot_damage_multiplier(), 1.8))
    assert(InventoryManager.jackpot_attack_penalty() < 0.0)
    assert(InventoryManager.jackpot_tracking_enabled())
    _equip("jp", "legendary")
    assert(InventoryManager.set_tier("jackpot") == 2)
    assert(is_equal_approx(InventoryManager.jackpot_damage_multiplier(), 2.4))
    assert(InventoryManager.jackpot_charged_multiplier() > 1.0)
    assert(InventoryManager.tragaperras_shield_interval() < 0.0)
    assert(InventoryManager.black_jack_projectiles() == 1)
    assert(int(InventoryManager.armor_affinity_counts()["jackpot"]) == 4)
    for i in range(100):
        var dropped: String = RunManager.roll_armor_piece_id("rare")
        assert(str(DB.get_def(dropped).get("rarity", "")) == "rare")
        assert(DB.is_set_armor(dropped))
    # Ascensión real de dos piezas idénticas comunes al máximo.
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    RunManager.add_coins(5000)
    for prefix in ["tp", "jp"]:
        var item_id: String = "%s_helmet_common" % prefix
        var first: Dictionary = InventoryManager.add_item(item_id)
        var first_uid: int = int(first["entry"]["uid"])
        for n in range(5):
            InventoryManager.add_item(item_id)
        assert(bool(InventoryManager.fuse_item(first_uid)["ok"]))
        assert(bool(InventoryManager.fuse_item(first_uid)["ok"]))
        var donor_uid: int = -1
        for entry in InventoryManager.items:
            if int(entry["uid"]) != first_uid and str(entry["id"]) == item_id:
                donor_uid = int(entry["uid"])
                break
        assert(donor_uid > 0)
        assert(bool(InventoryManager.fuse_item(donor_uid)["ok"]))
        assert(bool(InventoryManager.fuse_item(donor_uid)["ok"]))
        assert(bool(InventoryManager.ascend_item(first_uid)["ok"]))
        assert(str(InventoryManager.find_entry(first_uid)["id"]) == "%s_helmet_rare" % prefix)
        assert(int(InventoryManager.find_entry(first_uid)["level"]) == 1)
    assert(PactManager.PACT_COST == 10)
    assert(PactManager.REROLL_COST == 50)
    var offers: Array[String] = PactManager.reroll_stackable_offers()
    assert(offers.size() == 3 and offers[0] != offers[1] and offers[1] != offers[2])
    for pact_id in offers:
        assert(pact_id in PactManager.STACKABLE)
    var before: int = RunManager.coins
    var result: Dictionary = PactManager.resolve_pact("filo")
    assert(bool(result["ok"]))
    assert(RunManager.coins == before - 10)
    RunManager.coins = 0
    assert(not bool(PactManager.resolve_pact("filo")["ok"]), "Sin saldo no debe resolverse la apuesta")
    print("ALL IN 4.27: 32 piezas nuevas, 48 totales, forja, escudo, jackpot, afinidad y pactos OK")
    quit(0)
