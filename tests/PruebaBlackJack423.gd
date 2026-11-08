extends SceneTree
## Ejecutar con Godot 4.7.2:
## godot --headless --path . --script res://tests/PruebaBlackJack423.gd
## Revisa BLACK JACK dentro del nuevo catálogo, la ascensión y bonus ×2/×4.

const DB = preload("res://scripts/systems/ItemDatabase.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _equip(id: String) -> int:
    var result: Dictionary = InventoryManager.add_item(id)
    assert(bool(result["ok"]), "No se pudo crear pieza de prueba " + id)
    var uid: int = int(result["entry"]["uid"])
    assert(bool(InventoryManager.equip_item(uid)["ok"]), "No se pudo equipar " + id)
    return uid

func _verify() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    PactManager.reset_pacts()
    var armor_count: int = 0
    var original_ids: Array[String] = ["boots", "runner", "comet", "fugitive", "cloth_hood", "iron_shell"]
    for old_id in original_ids:
        assert(DB.get_def(old_id).is_empty(), "Quedó armadura obsoleta: " + old_id)
    for rarity in DB.RARITY_ORDER:
        var ids: Array[String] = []
        for slot in ["helmet", "chest", "legs", "boots"]:
            var id: String = "bj_%s_%s" % [slot, rarity]
            assert(not DB.get_def(id).is_empty(), "Falta " + id)
            assert(str(DB.get_def(id)["rarity"]) == rarity)
            assert(str(DB.get_def(id)["slot"]) == slot)
            ids.append(id)
            armor_count += 1
    assert(armor_count == 16)
    var armor_count_in_catalogue: int = 0
    for item_id in DB.ITEM_DEFS.keys():
        if str(DB.ITEM_DEFS[item_id].get("slot", "")) in ["helmet", "chest", "legs", "boots"]:
            armor_count_in_catalogue += 1
    assert(armor_count_in_catalogue == 48, "Deben coexistir los tres conjuntos")

    assert(InventoryManager.black_jack_projectiles() == 1)
    for slot in ["helmet", "chest", "legs", "boots"]:
        _equip("bj_%s_common" % slot)
    assert(InventoryManager.black_jack_progress() == 0)
    assert(InventoryManager.black_jack_projectiles() == 1, "Cuatro piezas comunes NO activan la pasiva")
    for slot in ["helmet", "chest", "legs", "boots"]:
        _equip("bj_%s_rare" % slot)
    assert(InventoryManager.black_jack_projectiles() == 1, "Cuatro piezas raras NO activan la pasiva")
    for slot in ["helmet", "chest", "legs"]:
        _equip("bj_%s_epic" % slot)
    assert(InventoryManager.black_jack_progress() == 3)
    assert(InventoryManager.black_jack_projectiles() == 1, "Tres épicas y una rara no activan ×2")
    _equip("bj_boots_epic")
    assert(InventoryManager.black_jack_progress() == 4)
    assert(InventoryManager.black_jack_projectiles() == 2, "Cuatro piezas épicas activan ×2")
    for slot in ["helmet", "chest", "legs"]:
        _equip("bj_%s_legendary" % slot)
    assert(InventoryManager.black_jack_projectiles() == 2, "Tres legendarias y una épica mantienen ×2")
    _equip("bj_boots_legendary")
    assert(InventoryManager.black_jack_projectiles() == 4, "Cuatro piezas legendarias activan ×4")
    var worn: Dictionary = InventoryManager.get_equipped_entry("boots")
    assert(bool(InventoryManager.unequip_item(int(worn["uid"]))["ok"]))
    assert(InventoryManager.black_jack_projectiles() == 1, "Al romper el conjunto se pierde la pasiva")

    RunManager.reset_run()
    InventoryManager.reset_inventory()
    var target: Dictionary = InventoryManager.add_item("bj_helmet_common")["entry"]
    var uid: int = int(target["uid"])
    for n in range(5):
        InventoryManager.add_item("bj_helmet_common")
    RunManager.add_coins(2500)
    for n in range(2):
        assert(bool(InventoryManager.fuse_item(uid)["ok"]))
    var other_uid: int = -1
    for entry in InventoryManager.items:
        if int(entry["uid"]) != uid:
            other_uid = int(entry["uid"])
            break
    assert(other_uid > 0)
    for n in range(2):
        assert(bool(InventoryManager.fuse_item(other_uid)["ok"]))
    assert(InventoryManager.get_item_level(uid) == 3)
    assert(InventoryManager.get_item_level(other_uid) == 3)
    var common_score: float = DB.power_score("bj_helmet_common", 3, "common")
    assert(bool(InventoryManager.ascend_item(uid)["ok"]))
    var promoted: Dictionary = InventoryManager.find_entry(uid)
    assert(str(promoted["id"]) == "bj_helmet_rare")
    assert(str(promoted["rarity"]) == "rare" and int(promoted["level"]) == 1)
    assert(DB.power_score(str(promoted["id"]), 1, "rare") > common_score)
    assert(InventoryManager.items.size() == 1, "Ascensión consume una de las dos piezas completas")
    assert(not DB.get_def("knife").is_empty(), "Armas placeholder no deben desaparecer")
    assert(not DB.get_def("clock").is_empty(), "Amuletos no deben desaparecer")
    assert(RunManager.award_boss_coins(10) == 200, "Preservar premio auditado")
    print("ALL IN 4.23.1: catálogo, 25%% por pieza, épico+ ×2, legendario ×4, ascensión verificados")
    quit(0)
