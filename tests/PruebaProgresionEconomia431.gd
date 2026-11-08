extends SceneTree
## ALL IN 4.31: godot --headless --path . --script res://tests/PruebaProgresionEconomia431.gd
## Progresion de monedas, afinidad, rareza epica, armas en Chatarreria y subfusil.
const DB = preload("res://scripts/systems/ItemDatabase.gd")
const PLAYER = preload("res://scripts/player/Player.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    PactManager.reset_pacts()
    assert(RunManager.NORMAL_ROOM_COMPLETION_COINS == 10)
    assert(RunManager.award_normal_room_coins(1) == 10)
    assert(RunManager.award_normal_room_coins(1) == 0, "Una unica recompensa por sala")
    assert(RunManager.award_normal_room_coins(10) == 0, "Jefe sin bonificacion normal")
    assert(RunManager.get_normal_room_cash_reward(41) == 70, "COBRAR no cambia")
    for pair in [
        {"room": 1, "min": 4, "max": 7},
        {"room": 20, "min": 4, "max": 7},
        {"room": 21, "min": 6, "max": 9},
        {"room": 30, "min": 6, "max": 9},
        {"room": 31, "min": 8, "max": 11},
        {"room": 40, "min": 8, "max": 11},
        {"room": 41, "min": 10, "max": 13},
        {"room": 50, "min": 10, "max": 13},
        {"room": 51, "min": 12, "max": 15},
        {"room": 61, "min": 14, "max": 17}
    ]:
        var bracket: Vector2i = RunManager.enemy_kill_coin_range(int(pair["room"]))
        assert(bracket == Vector2i(int(pair["min"]), int(pair["max"])))
        RunManager.current_level = int(pair["room"])
        for i in range(25):
            var before: int = RunManager.coins
            var reward: int = RunManager.award_enemy_kill_coins()
            assert(reward >= bracket.x and reward <= bracket.y)
            assert(RunManager.coins == before + reward)
    RunManager.reset_run()
    assert(RunManager.award_boss_coins(10) == 200)
    assert(RunManager.award_boss_coins(10) == 0)

    # Rarezas: 10% epicas en una tirada de calidad 40-55 y pity mas rapido.
    assert(DB.enemy_quality_rarity_for_roll(39, 9999) == "rare")
    assert(DB.enemy_quality_rarity_for_roll(40, 8999) == "rare")
    assert(DB.enemy_quality_rarity_for_roll(40, 9000) == "epic")
    assert(DB.enemy_quality_rarity_for_roll(56, 9999) == "legendary")
    assert(RunManager.EPIC_PITY_QUALITY_ROLLS == 25)
    RunManager.current_level = 39
    RunManager.quality_rolls_since_epic = 24
    assert(RunManager.roll_quality_loot_rarity() != "epic")
    RunManager.current_level = 40
    RunManager.quality_rolls_since_epic = 24
    assert(RunManager.roll_quality_loot_rarity() == "epic")
    assert(RunManager.quality_rolls_since_epic == 0)

    # 65/23/12 de categoria sin que el catalogo de items afecte los pesos.
    var category_counts: Dictionary = {"armor": 0, "weapon": 0, "charm": 0}
    for i in range(8000):
        var id: String = DB.roll_id("common")
        var category: String = "charm"
        if DB.is_set_armor(id):
            category = "armor"
        elif str(DB.get_def(id).get("weapon_type", "")) != "":
            category = "weapon"
        category_counts[category] = int(category_counts[category]) + 1
    assert(absf(float(category_counts["armor"]) / 8000.0 - 0.65) < 0.035)
    assert(absf(float(category_counts["weapon"]) / 8000.0 - 0.23) < 0.035)
    assert(absf(float(category_counts["charm"]) / 8000.0 - 0.12) < 0.03)

    # Afinidad a la familia de arma EQUIPADA, sin bloquear otras armas.
    InventoryManager.reset_inventory()
    var smg: Dictionary = InventoryManager.add_item("smg_rare")
    assert(bool(InventoryManager.equip_item(int(smg["entry"]["uid"])).get("ok", false)))
    var weapon_counts: Dictionary = {"smg": 0, "pistol": 0, "shotgun": 0, "deagle": 0}
    for i in range(6000):
        var id: String = RunManager.roll_weapon_piece_id("rare")
        var typ: String = str(DB.get_def(id).get("weapon_type", ""))
        assert(weapon_counts.has(typ))
        weapon_counts[typ] = int(weapon_counts[typ]) + 1
    assert(absf(float(weapon_counts["smg"]) / 6000.0 - 0.45) < 0.045)
    for typ in ["pistol", "shotgun", "deagle"]:
        assert(int(weapon_counts[typ]) > 800, "Armas alternativas deben seguir apareciendo")
    assert(is_equal_approx(PLAYER.weapon_damage_factor("smg"), 0.82))

    # Armas en Chatarreria: apostar pistola epica por duplicados de subfusil raro.
    var donor: Dictionary = InventoryManager.add_item("pistol_epic")
    assert(bool(donor.get("ok", false)))
    var found_weapon: bool = false
    for group in InventoryManager.scrap_groups():
        if str(group["id"]) == "pistol_epic":
            found_weapon = true
    assert(found_weapon, "La Chatarreria debe mostrar armas")
    var preview: Dictionary = InventoryManager.scrap_preview("pistol_epic", "epic", 1)
    assert(bool(preview.get("ok", false)))
    assert(str(preview.get("reward_id", "")) == "smg_rare")
    assert(int(preview.get("payout", -1)) == 2)
    var result: Dictionary = InventoryManager.scrap_wager("pistol_epic", "epic", 1)
    assert(bool(result.get("ok", false)))
    assert(int(result["wins"]) + int(result["lost"]) == 1)
    assert(int(result["payouts"]) == int(result["wins"]) * 2)
    assert(str(InventoryManager.get_equipped_entry("weapon")["id"]) == "smg_rare")
    # Una legendaria sacrificada entrega EXACTAMENTE una epica si gana.
    var legendary: Dictionary = InventoryManager.add_item("deagle_legendary")
    assert(bool(legendary.get("ok", false)))
    var legendary_preview: Dictionary = InventoryManager.scrap_preview("deagle_legendary", "legendary", 1)
    assert(str(legendary_preview.get("reward_id", "")) == "smg_epic")
    assert(int(legendary_preview.get("payout", 0)) == 1)

    # El set dominante sigue teniendo preferencia y su pieza atrasada mejora en frecuencia.
    InventoryManager.reset_inventory()
    RunManager.reset_run()
    for slot in ["helmet", "chest", "legs"]:
        var armor: Dictionary = InventoryManager.add_item("bj_%s_epic" % slot)
        assert(bool(InventoryManager.equip_item(int(armor["entry"]["uid"])).get("ok", false)))
    var progress: Dictionary = InventoryManager.best_set_slot_rarities("black_jack")
    assert(int(progress["helmet"]) == 2 and int(progress["boots"]) == -1)
    var black_jack_count: int = 0
    var missing_boots_count: int = 0
    for i in range(9000):
        var id: String = RunManager.roll_armor_piece_id("epic")
        var definition: Dictionary = DB.get_def(id)
        if str(definition.get("set_id", "")) != "black_jack":
            continue
        black_jack_count += 1
        if str(definition.get("slot", "")) == "boots":
            missing_boots_count += 1
    assert(black_jack_count > 4800, "Debe conservarse la afinidad de conjunto")
    assert(float(missing_boots_count) / float(black_jack_count) > 0.285,
        "La ranura sin equipar debe ser mas frecuente que antes (19.2%)")

    print("ALL IN 4.31: economia escalonada, 10 fijas, afinidad de armas, botas atrasadas, pity y Chatarreria OK")
    quit(0)
