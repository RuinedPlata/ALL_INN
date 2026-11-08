extends SceneTree
## Ejecución desde la carpeta de project.godot:
## godot --headless --path . --script res://tests/PruebaInventario420.gd
## Verifica mochila de 50, intercambio sin duplicados, capacidad, fusiones
## y ascensión de piezas equipadas. Prueba independiente de una partida real.

func _initialize() -> void:
    call_deferred("_verify")

func _assert_unique_uids() -> void:
    var seen: Dictionary = {}
    for entry in InventoryManager.items:
        var uid: int = int(entry["uid"])
        assert(not seen.has(uid), "UID repetido en mochila")
        seen[uid] = true
    for entry in InventoryManager.equipped_items.values():
        var uid: int = int(entry["uid"])
        assert(not seen.has(uid), "La misma pieza no puede aparecer equipada y en mochila")
        seen[uid] = true

func _verify() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    PactManager.reset_pacts()
    assert(InventoryManager.CAPACITY == 50, "La mochila debe admitir 50 piezas almacenadas")
    var boots_a: Dictionary = InventoryManager.add_item("bj_boots_common")
    assert(bool(boots_a["ok"]))
    var first_uid: int = int(boots_a["entry"]["uid"])
    assert(bool(InventoryManager.equip_item(first_uid)["ok"]))
    assert(InventoryManager.items.size() == 0, "Equipar libera el espacio de mochila")
    assert(InventoryManager.get_equipped_count() == 1)
    assert(InventoryManager.get_owned_entries().size() == 1, "Afinidad de botín incluye piezas equipadas")
    assert(InventoryManager.find_entry(first_uid).get("id", "") == "bj_boots_common")
    assert(InventoryManager.get_equipped_bonus("speed") > 0.0, "El equipo separado sigue dando estadísticas")
    var boots_b: Dictionary = InventoryManager.add_item("bj_boots_rare")
    var second_uid: int = int(boots_b["entry"]["uid"])
    assert(bool(InventoryManager.equip_item(second_uid)["ok"]))
    assert(InventoryManager.items.size() == 1, "Intercambiar devuelve la pieza anterior")
    assert(int(InventoryManager.items[0]["uid"]) == first_uid)
    assert(InventoryManager.is_equipped(second_uid))
    assert(not InventoryManager.is_equipped(first_uid))
    _assert_unique_uids()
    while InventoryManager.items.size() < InventoryManager.CAPACITY:
        assert(bool(InventoryManager.add_item("knife")["ok"]))
    assert(InventoryManager.is_full())
    assert(not bool(InventoryManager.add_item("knife")["ok"]), "No permitir pieza número 51")
    assert(not bool(InventoryManager.unequip_item(second_uid)["ok"]), "No desequipar si mochila llena")
    var stored_uid: int = int(InventoryManager.items[0]["uid"])
    assert(bool(InventoryManager.equip_item(stored_uid)["ok"]), "Cambiar arma/armadura con mochila llena debe ser posible")
    assert(InventoryManager.items.size() == 50, "El intercambio no cambia el número de guardados")
    assert(InventoryManager.get_equipped_count() == 1)
    _assert_unique_uids()
    assert(not bool(InventoryManager.sell_item(stored_uid)["ok"]), "No vender equipo puesto")
    assert(bool(InventoryManager.sell_item(second_uid)["ok"]), "La pieza cambiada regresa a la mochila y puede venderse")
    assert(InventoryManager.items.size() == 49)
    assert(bool(InventoryManager.unequip_item(stored_uid)["ok"]))
    assert(InventoryManager.items.size() == 50)
    assert(InventoryManager.get_equipped_count() == 0)
    _assert_unique_uids()

    # La pieza EQUIPADA debe poder consumir copias almacenadas para fusionar y ascender.
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    PactManager.reset_pacts()
    var target: Dictionary = InventoryManager.add_item("bj_boots_rare")["entry"]
    var target_uid: int = int(target["uid"])
    for i in range(7):
        assert(bool(InventoryManager.add_item("bj_boots_rare")["ok"]))
    assert(bool(InventoryManager.equip_item(target_uid)["ok"]))
    assert(InventoryManager.items.size() == 7)
    RunManager.add_coins(3000)
    for i in range(3):
        assert(bool(InventoryManager.fuse_item(target_uid)["ok"]), "La pieza equipada puede fusionarse")
    assert(InventoryManager.get_item_level(target_uid) == 4)
    var second_target: int = int(InventoryManager.items[0]["uid"])
    for i in range(3):
        assert(bool(InventoryManager.fuse_item(second_target)["ok"]))
    assert(InventoryManager.get_item_level(second_target) == 4)
    assert(not InventoryManager.get_ascension_candidate(target_uid).is_empty())
    assert(bool(InventoryManager.ascend_item(target_uid)["ok"]), "Ascender pieza equipada")
    var ascended: Dictionary = InventoryManager.get_equipped_entry("boots")
    assert(int(ascended["uid"]) == target_uid)
    assert(str(ascended["id"]) == "bj_boots_epic" and str(ascended["rarity"]) == "epic" and int(ascended["level"]) == 1)
    assert(InventoryManager.items.size() == 0, "Donantes consumidos una sola vez")
    assert(InventoryManager.get_equipped_count() == 1)
    _assert_unique_uids()
    print("ALL IN 4.20: pruebas de inventario completadas")
    quit(0)
