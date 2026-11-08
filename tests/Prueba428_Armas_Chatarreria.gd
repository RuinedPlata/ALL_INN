extends SceneTree
## Ejecutar con Godot 4.7.2:
## godot --headless --path . --script res://tests/Prueba428_Armas_Chatarreria.gd
const DB = preload("res://scripts/systems/ItemDatabase.gd")
const PLAYER = preload("res://scripts/player/Player.gd")
const BULLET = preload("res://scripts/combat/Projectile.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    PactManager.reset_pacts()
    var armor_count: int = 0
    var weapon_count: int = 0
    var weapon_types: Dictionary = {}
    for item_id in DB.ITEM_DEFS.keys():
        var data: Dictionary = DB.get_def(str(item_id))
        if DB.is_set_armor(str(item_id)):
            armor_count += 1
        if str(data.get("weapon_type", "")) != "":
            weapon_count += 1
            weapon_types[str(data["weapon_type"])] = true
    assert(armor_count == 48, "Seguimos con 3 × 16 armaduras")
    assert(weapon_count == 16, "4 familias × 4 rarezas de armas")
    assert(weapon_types.size() == 4)
    for typ in ["pistol", "shotgun", "smg", "deagle"]:
        for rarity in DB.RARITY_ORDER:
            var item_id: String = "%s_%s" % [typ, rarity]
            assert(not DB.get_def(item_id).is_empty())
            assert(not DB.get_upgraded_stats(item_id, DB.level_cap(item_id)).is_empty())
            if rarity != "legendary":
                assert(not DB.get_def(DB.ascended_item_id(item_id)).is_empty())
    assert(PLAYER.weapon_pellet_count("shotgun") == 3)
    assert(PLAYER.weapon_pellet_count("pistol") == 1)
    assert(PLAYER.black_jack_spread_degrees(4).size() * PLAYER.weapon_pellet_count("shotgun") == 12)
    var bullet = BULLET.new()
    bullet.max_distance = 250.0
    bullet.falloff_start = 90.0
    bullet.falloff_minimum = 0.35
    assert(bullet.max_distance == 250.0)
    bullet.free()
    # Gate rareza de suelo: rareza 15+, épica 40+, legendaria 56+.
    assert(DB.enemy_quality_rarity_for_roll(14, 9999) == "common")
    assert(DB.enemy_quality_rarity_for_roll(15, 9999) == "rare")
    assert(DB.enemy_quality_rarity_for_roll(39, 9999) == "rare")
    assert(DB.enemy_quality_rarity_for_roll(40, 9999) == "epic")
    assert(DB.enemy_quality_rarity_for_roll(56, 9999) == "legendary")
    var rarity_rules: Dictionary = InventoryManager.SCRAP_RULES
    assert(str(rarity_rules["legendary"]["reward"]) == "epic")
    assert(int(rarity_rules["legendary"]["payout"]) == 1)
    assert(str(rarity_rules["epic"]["reward"]) == "rare")
    assert(int(rarity_rules["rare"]["payout"]) == 2)
    var worn_result: Dictionary = InventoryManager.add_item("tp_helmet_rare")
    var worn_uid: int = int(worn_result["entry"]["uid"])
    assert(bool(InventoryManager.equip_item(worn_uid)["ok"]))
    for n in range(10):
        assert(bool(InventoryManager.add_item("jp_helmet_epic")["ok"]))
    var preview: Dictionary = InventoryManager.scrap_preview("jp_helmet_epic", "epic", 10)
    assert(bool(preview["ok"]))
    assert(str(preview["reward_id"]) == "tp_helmet_rare")
    assert(int(preview["payout"]) == 2)
    var before: int = InventoryManager.items.size()
    var result: Dictionary = InventoryManager.scrap_wager("jp_helmet_epic", "epic", 10)
    assert(bool(result["ok"]))
    assert(int(result["wins"]) + int(result["lost"]) == 10)
    assert(int(result["payouts"]) == 2 * int(result["wins"]))
    assert(InventoryManager.items.size() == before - 10 + int(result["payouts"]))
    assert(int(InventoryManager.get_equipped_entry("helmet")["uid"]) == worn_uid)
    for item in InventoryManager.items:
        assert(str(item["id"]) == "tp_helmet_rare")
        assert(int(item["level"]) == 1)
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    var desired: Dictionary = InventoryManager.add_item("bj_boots_legendary")
    InventoryManager.equip_item(int(desired["entry"]["uid"]))
    var donor: Dictionary = InventoryManager.add_item("jp_boots_legendary")
    var check: Dictionary = InventoryManager.scrap_preview("jp_boots_legendary", "legendary", 1)
    assert(bool(check["ok"]))
    assert(str(check["reward_id"]) == "bj_boots_epic")
    assert(int(check["payout"]) == 1)
    assert(not bool(InventoryManager.scrap_preview("jp_boots_legendary", "legendary", 2)["ok"]))
    # Categorías estables con 10 armas y 7 sets futuros: cuotas, no recuentos.
    var categories: Dictionary = {"armor": 0, "weapon": 0, "charm": 0}
    for i in range(6000):
        var id: String = DB.roll_id("common")
        var data: Dictionary = DB.get_def(id)
        if DB.is_set_armor(id):
            categories["armor"] += 1
        elif str(data.get("weapon_type", "")) != "":
            categories["weapon"] += 1
        else:
            categories["charm"] += 1
    assert(int(categories["armor"]) > 3600 and int(categories["armor"]) < 4400)
    assert(int(categories["weapon"]) > 750 and int(categories["weapon"]) < 1650)
    assert(int(categories["charm"]) > 500 and int(categories["charm"]) < 1100)
    assert(PactManager.PACT_COST == 10)
    assert(PactManager.REROLL_COST == 50)
    print("ALL IN 4.28: catálogo, armas, dispersión, rarezas, chatarrería, inventario, payout, economía: OK")
    quit(0)
