extends Node
# Inventario por run. La rareza activa vive en cada pieza; su identidad (ID) no cambia al ascender.
signal inventory_changed
signal item_collected(item_name: String)

const DB = preload("res://scripts/systems/ItemDatabase.gd")
const CAPACITY: int = 50
const FUSION_BASE_COST := {"common": 12, "rare": 30, "epic": 70, "legendary": 135}
const ASCENSION_COST := {"common": 90, "rare": 180, "epic": 420}
const SCRAP_RULES := {
    "common": {"chance": 0.55, "payout": 1, "reward": "common"},
    "rare": {"chance": 0.70, "payout": 2, "reward": "common"},
    "epic": {"chance": 0.78, "payout": 2, "reward": "rare"},
    "legendary": {"chance": 0.85, "payout": 1, "reward": "epic"}
}


var items: Array[Dictionary] = []  # SOLO piezas en mochila; equipadas no ocupan espacio.
var equipped: Dictionary = {"helmet": -1, "chest": -1, "legs": -1, "boots": -1, "charm": -1, "weapon": -1}
var equipped_items: Dictionary = {}  # slot -> entrada {uid, id, rarity, level}
var next_uid: int = 1
var active_relic: String = ""

func equipped_weapon_type() -> String:
    var entry: Dictionary = get_equipped_entry("weapon")
    if entry.is_empty():
        return "pistol"
    return str(DB.get_def(str(entry["id"])).get("weapon_type", "pistol"))

func equipped_weapon_affinity_type() -> String:
    # Vacio cuando el slot no tiene una de las cuatro armas 2.0.
    var entry: Dictionary = get_equipped_entry("weapon")
    if entry.is_empty():
        return ""
    return str(DB.get_def(str(entry["id"])).get("weapon_type", ""))

func has_active_weapon_relic() -> bool:
    return active_relic == "croupier_mark" and int(equipped.get("weapon", -1)) >= 0

func get_relic_name() -> String:
    return "Marca del Croupier" if active_relic == "croupier_mark" else "Ninguna"

func grant_relic(relic_id: String) -> void:
    if relic_id == "croupier_mark":
        active_relic = relic_id
        inventory_changed.emit()

func is_full() -> bool:
    return items.size() >= CAPACITY

func get_entry_rarity(entry: Dictionary) -> String:
    if entry.is_empty():
        return ""
    return str(entry.get("rarity", DB.get_def(str(entry["id"])).get("rarity", "")))

func add_item(item_id: String) -> Dictionary:
    var definition: Dictionary = DB.get_def(item_id)
    if definition.is_empty():
        return {"ok": false, "message": "Objeto desconocido."}
    if is_full():
        return {"ok": false, "message": "Inventario lleno (%d/%d). Abre I y vende algo." % [items.size(), CAPACITY]}
    var entry: Dictionary = {"uid": next_uid, "id": item_id, "rarity": str(definition["rarity"]), "level": 1}
    next_uid += 1
    items.append(entry)
    inventory_changed.emit()
    item_collected.emit(str(definition["name"]))
    return {"ok": true, "entry": entry, "message": "Recogiste %s." % str(definition["name"])}

func find_entry(uid: int) -> Dictionary:
    for entry in items:
        if int(entry["uid"]) == uid:
            return entry
    for entry in equipped_items.values():
        if int(entry["uid"]) == uid:
            return entry
    return {}

func get_equipped_entry(slot: String) -> Dictionary:
    return equipped_items.get(slot, {})

func get_equipped_count() -> int:
    return equipped_items.size()

func get_owned_entries() -> Array[Dictionary]:
    # Para afinidad de botín: también interesan los duplicados de una pieza puesta.
    var result: Array[Dictionary] = []
    result.append_array(items)
    for entry in equipped_items.values():
        result.append(entry)
    return result

func _update_entry(uid: int, property: String, value: Variant) -> void:
    # Un objeto puede estar tanto en la mochila como en un espacio equipado.
    for i in range(items.size()):
        if int(items[i]["uid"]) == uid:
            items[i][property] = value
            return
    for slot in equipped_items.keys():
        if int(equipped_items[slot]["uid"]) == uid:
            equipped_items[slot][property] = value
            return

func is_equipped(uid: int) -> bool:
    return equipped.values().has(uid)

func get_item_level(uid: int) -> int:
    var entry: Dictionary = find_entry(uid)
    return int(entry.get("level", 1)) if not entry.is_empty() else 0

func get_fusion_candidate(uid: int) -> Dictionary:
    var target: Dictionary = find_entry(uid)
    if target.is_empty():
        return {}
    var rarity: String = get_entry_rarity(target)
    var cap: int = DB.level_cap(str(target["id"]), rarity)
    var current: int = int(target["level"])
    if current >= cap:
        return {}
    var candidate: Dictionary = {}
    for entry in items:
        if int(entry["uid"]) == uid or str(entry["id"]) != str(target["id"]):
            continue
        if get_entry_rarity(entry) != rarity or is_equipped(int(entry["uid"])):
            continue
        var donor_level: int = int(entry["level"])
        if current + donor_level > cap:
            continue
        if candidate.is_empty() or donor_level < int(candidate["level"]):
            candidate = entry
    return candidate

func get_fusion_cost(uid: int) -> int:
    var target: Dictionary = find_entry(uid)
    var donor: Dictionary = get_fusion_candidate(uid)
    if target.is_empty() or donor.is_empty():
        return -1
    var base: int = int(FUSION_BASE_COST.get(get_entry_rarity(target), 0))
    if base <= 0:
        return -1
    return base + int(round(base * 0.32 * float(int(target["level"]) - 1))) + int(round(base * 0.25 * float(int(donor["level"]) - 1)))

func _consume_donor(uid: int) -> void:
    for i in range(items.size() - 1, -1, -1):
        if int(items[i]["uid"]) == uid:
            items.remove_at(i)
            return

func fuse_item(uid: int) -> Dictionary:
    var target: Dictionary = find_entry(uid)
    var donor: Dictionary = get_fusion_candidate(uid)
    if target.is_empty() or donor.is_empty():
        return {"ok": false, "message": "Fusión imposible: falta duplicado EXACTO, misma rareza, sin equipar y sin exceder máximo."}
    var cost: int = get_fusion_cost(uid)
    if cost <= 0 or not RunManager.spend_coins(cost):
        return {"ok": false, "message": "FUSIÓN: necesitas %d monedas (tienes %d)." % [cost, RunManager.coins]}
    var donor_level: int = int(donor["level"])
    var donor_uid: int = int(donor["uid"])
    var rarity: String = get_entry_rarity(target)
    var next_level: int = int(target["level"]) + donor_level
    _update_entry(uid, "level", next_level)
    _consume_donor(donor_uid)
    if is_equipped(uid):
        RunManager.on_equipment_changed(RunManager.get_effective_max_health())
    inventory_changed.emit()
    return {"ok": true, "message": "¡FUSIÓN! %s [%s] Nv.%d/%d. Costó %d monedas." % [str(DB.get_def(str(target["id"]))["name"]), str(DB.RARITY_NAMES[rarity]), next_level, DB.level_cap(str(target["id"]), rarity), cost]}

func get_ascension_candidate(uid: int) -> Dictionary:
    var target: Dictionary = find_entry(uid)
    if target.is_empty():
        return {}
    var rarity: String = get_entry_rarity(target)
    if not DB.NEXT_RARITY.has(rarity) or int(target["level"]) != DB.level_cap(str(target["id"]), rarity):
        return {}
    for entry in items:
        if int(entry["uid"]) == uid or str(entry["id"]) != str(target["id"]):
            continue
        if is_equipped(int(entry["uid"])) or get_entry_rarity(entry) != rarity:
            continue
        if int(entry["level"]) == DB.level_cap(str(entry["id"]), rarity):
            return entry
    return {}

func get_ascension_cost(uid: int) -> int:
    var target: Dictionary = find_entry(uid)
    if target.is_empty():
        return -1
    var rarity: String = get_entry_rarity(target)
    if not DB.NEXT_RARITY.has(rarity) or int(target["level"]) < DB.level_cap(str(target["id"]), rarity):
        return -1
    return int(ASCENSION_COST.get(rarity, -1))

func ascend_item(uid: int) -> Dictionary:
    var target: Dictionary = find_entry(uid)
    var donor: Dictionary = get_ascension_candidate(uid)
    if target.is_empty() or donor.is_empty():
        return {"ok": false, "message": "ASCENSIÓN: se necesitan DOS piezas idénticas de la misma rareza, AMBAS al máximo. Una puede estar equipada."}
    var cost: int = get_ascension_cost(uid)
    if cost <= 0 or not RunManager.spend_coins(cost):
        return {"ok": false, "message": "ASCENSIÓN: necesitas %d monedas (tienes %d)." % [cost, RunManager.coins]}
    var previous_rarity: String = get_entry_rarity(target)
    var new_rarity: String = str(DB.NEXT_RARITY[previous_rarity])
    var old_id: String = str(target["id"])
    var promoted_id: String = DB.ascended_item_id(old_id)
    if promoted_id == "" or DB.get_def(promoted_id).is_empty():
        return {"ok": false, "message": "Ascensión: no existe la versión superior de esta pieza."}
    _update_entry(uid, "id", promoted_id)
    _update_entry(uid, "rarity", new_rarity)
    _update_entry(uid, "level", 1)
    _consume_donor(int(donor["uid"]))
    if is_equipped(uid):
        RunManager.on_equipment_changed(RunManager.get_effective_max_health())
    inventory_changed.emit()
    return {"ok": true, "message": "¡ASCENSIÓN! %s conserva su identidad: %s -> %s Nv.1. Costó %d monedas." % [str(DB.get_def(str(target["id"]))["name"]), str(DB.RARITY_NAMES[previous_rarity]), str(DB.RARITY_NAMES[new_rarity]), cost]}

func equip_item(uid: int) -> Dictionary:
    var entry: Dictionary = find_entry(uid)
    if entry.is_empty() or is_equipped(uid):
        return {"ok": false, "message": "El objeto no está disponible en la mochila."}
    var definition: Dictionary = DB.get_def(str(entry["id"]))
    var slot: String = str(definition.get("slot", ""))
    if not equipped.has(slot):
        return {"ok": false, "message": "Esta pieza no tiene ranura equipable."}
    var backpack_index: int = -1
    for i in range(items.size()):
        if int(items[i]["uid"]) == uid:
            backpack_index = i
            break
    if backpack_index < 0:
        return {"ok": false, "message": "El objeto no está disponible en la mochila."}
    var previous_max: int = RunManager.get_effective_max_health()
    # El intercambio es atómico: se retira primero la nueva pieza de la mochila
    # y después se devuelve la antigua. Nunca rebasa los 50 espacios.
    var old_equipment: Dictionary = get_equipped_entry(slot)
    items.remove_at(backpack_index)
    if not old_equipment.is_empty():
        items.append(old_equipment)
    equipped[slot] = uid
    equipped_items[slot] = entry
    RunManager.on_equipment_changed(previous_max)
    inventory_changed.emit()
    return {"ok": true, "message": "Equipaste %s%s. Mochila %d/%d." % [str(definition["name"]), " (la pieza anterior volvió a la mochila)" if not old_equipment.is_empty() else "", items.size(), CAPACITY]}

func unequip_item(uid: int) -> Dictionary:
    if not is_equipped(uid):
        return {"ok": false, "message": "Ese objeto no está equipado."}
    if is_full():
        return {"ok": false, "message": "Mochila llena (%d/%d). Vende o fusiona una pieza antes de desequipar. Puedes cambiar equipo directamente." % [items.size(), CAPACITY]}
    var previous_max: int = RunManager.get_effective_max_health()
    for slot in equipped.keys():
        if int(equipped[slot]) == uid:
            var entry: Dictionary = get_equipped_entry(slot)
            if entry.is_empty():
                return {"ok": false, "message": "Error: ranura equipada vacía."}
            items.append(entry)
            equipped[slot] = -1
            equipped_items.erase(slot)
            RunManager.on_equipment_changed(previous_max)
            inventory_changed.emit()
            return {"ok": true, "message": "Desequipaste %s. Mochila %d/%d." % [str(DB.get_def(str(entry["id"]))["name"]), items.size(), CAPACITY]}
    return {"ok": false, "message": "La ranura equipada no se encontró."}

func get_sell_price(uid: int) -> int:
    var entry: Dictionary = find_entry(uid)
    if entry.is_empty():
        return 0
    var definition: Dictionary = DB.get_def(str(entry["id"]))
    var rarity: String = get_entry_rarity(entry)
    # Una pieza ascendida vale según su rareza ACTUAL, no la rareza original del ID.
    var base_rarity: String = str(definition["rarity"])
    var value: int = int(definition["sell"])
    if rarity != base_rarity:
        value = maxi(value, int({"common": 6, "rare": 18, "epic": 45, "legendary": 100}.get(rarity, value)))
    var price: int = maxi(1, int(round(float(value * int(entry["level"])) * PactManager.sale_factor())))
    if PactManager.is_active("mercader", "overload") and not PactManager.special_sale_used:
        price += 50
    return price

func sell_item(uid: int) -> Dictionary:
    var entry: Dictionary = find_entry(uid)
    if entry.is_empty():
        return {"ok": false, "message": "No existe ese objeto."}
    if is_equipped(uid):
        return {"ok": false, "message": "Desequipa ese objeto antes de venderlo."}
    var price: int = get_sell_price(uid)
    var expected_bonus: int = 50 if PactManager.is_active("mercader", "overload") and not PactManager.special_sale_used else 0
    PactManager.take_sale_overload_bonus()  # Consume el bono mostrado (no lo duplica).
    _consume_donor(uid)
    RunManager.add_coins(price)
    inventory_changed.emit()
    return {"ok": true, "message": "Vendiste %s por %d monedas%s." % [str(DB.get_def(str(entry["id"]))["name"]), price, " (incluye Sobrecarga +50)" if expected_bonus > 0 else ""]}

# CHATARRERÍA 4.28. Mismo espacio y conjunto EQUIPADO de la pieza
# entregada. NUNCA permite apostar lo puesto; recompensa de rareza inferior.
func scrap_groups() -> Array[Dictionary]:
    # Los niveles se agrupan por ID y rareza: al apostar se pierden las
    # mejoras previas, lo que se confirma en la interfaz.
    var groups: Dictionary = {}
    for entry in items:
        var item_id: String = str(entry["id"])
        var definition: Dictionary = DB.get_def(item_id)
        if not DB.is_set_armor(item_id) and str(definition.get("slot", "")) != "weapon":
            continue
        # Mostrar armaduras y armas de la mochila. Si falta una pieza
        # equipada en la ranura, la UI explica por qué no se puede apostar.
        var rarity: String = get_entry_rarity(entry)
        var key: String = "%s|%s" % [item_id, rarity]
        if not groups.has(key):
            groups[key] = {"id": item_id, "rarity": rarity, "count": 0}
        groups[key]["count"] = int(groups[key]["count"]) + 1
    var result: Array[Dictionary] = []
    for data in groups.values():
        result.append(data)
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return str(a["id"]) + str(a["rarity"]) < str(b["id"]) + str(b["rarity"])
    )
    return result

func scrap_preview(item_id: String, rarity: String, amount: int) -> Dictionary:
    var definition: Dictionary = DB.get_def(item_id)
    var is_armor: bool = DB.is_set_armor(item_id)
    var is_weapon: bool = str(definition.get("slot", "")) == "weapon"
    if (not is_armor and not is_weapon) or not SCRAP_RULES.has(rarity) or amount <= 0:
        return {"ok": false, "message": "Selecciona un arma o una armadura válida (común a legendaria)."}
    var slot: String = str(definition["slot"])
    var worn: Dictionary = get_equipped_entry(slot)
    if worn.is_empty():
        return {"ok": false, "message": "Equipa un objeto de la misma ranura para elegir el premio."}
    if is_armor and not DB.is_set_armor(str(worn["id"])):
        return {"ok": false, "message": "Equipa una armadura de ese tipo para elegir el premio."}
    if is_weapon and str(DB.get_def(str(worn["id"])).get("weapon_type", "")) == "":
        return {"ok": false, "message": "Equipa una pistola, escopeta, subfusil o Desert Eagle para elegir el premio."}
    var available: int = 0
    for entry in items:
        if str(entry["id"]) == item_id and get_entry_rarity(entry) == rarity:
            available += 1
    if amount > available:
        return {"ok": false, "message": "No tienes suficientes duplicados para apostar."}
    var rule: Dictionary = SCRAP_RULES[rarity]
    var worn_definition: Dictionary = DB.get_def(str(worn["id"]))
    var target_id: String = ""
    if is_armor:
        var set_id: String = str(worn_definition.get("set_id", ""))
        target_id = "%s_%s_%s" % [str(DB.ARMOR_SET_PREFIXES.get(set_id, "")), slot, str(rule["reward"])]
    else:
        target_id = "%s_%s" % [str(worn_definition.get("weapon_type", "")), str(rule["reward"])]
    if DB.get_def(target_id).is_empty():
        return {"ok": false, "message": "El premio de esta combinación no existe."}
    var possible_slots: int = items.size() - amount + amount * int(rule["payout"])
    if possible_slots > CAPACITY:
        return {"ok": false, "message": "Libera %d espacios de mochila para cubrir incluso el premio máximo." % (possible_slots - CAPACITY)}
    return {"ok": true, "amount": amount, "chance": float(rule["chance"]), "payout": int(rule["payout"]), "reward_id": target_id, "reward_rarity": str(rule["reward"]), "available": available}

func scrap_wager(item_id: String, rarity: String, amount: int) -> Dictionary:
    var info: Dictionary = scrap_preview(item_id, rarity, amount)
    if not bool(info.get("ok", false)):
        return info
    # Foto atómica del premio: cambiar equipo durante la tirada no modifica la recompensa.
    var prize_id: String = str(info["reward_id"])
    var donated: int = 0
    var won: int = 0
    for i in range(items.size() - 1, -1, -1):
        if donated >= amount:
            break
        if str(items[i]["id"]) != item_id or get_entry_rarity(items[i]) != rarity:
            continue
        donated += 1
        if randf() < float(info["chance"]):
            won += 1
        items.remove_at(i)
    var payouts: int = won * int(info["payout"])
    for i in range(payouts):
        items.append({"uid": next_uid, "id": prize_id, "rarity": str(info["reward_rarity"]), "level": 1})
        next_uid += 1
    inventory_changed.emit()
    return {"ok": true, "wagers": donated, "wins": won, "lost": donated - won, "payouts": payouts, "reward_id": prize_id,
        "message": "CHATARRERÍA: %d apuestas, %d victorias, %d pérdidas. ¡Recibiste %d × %s!" % [donated, won, donated - won, payouts, str(DB.get_def(prize_id)["name"])]}

func black_jack_progress() -> int:
    # Cuenta solo piezas BLACK JACK equipadas de rareza épica o legendaria.
    # Las comunes y raras no activan la pasiva, aunque el conjunto esté completo.
    var eligible: int = 0
    for slot in ["helmet", "chest", "legs", "boots"]:
        var entry: Dictionary = get_equipped_entry(slot)
        if entry.is_empty() or not DB.is_black_jack_armor(str(entry["id"])):
            continue
        if get_entry_rarity(entry) in ["epic", "legendary"]:
            eligible += 1
    return eligible

func black_jack_projectiles() -> int:
    # ×1 si no hay 4 piezas BLACK JACK de rareza épica o superior.
    # ×2 con las cuatro épicas o superiores (se permiten mezclas épica/legendaria).
    # ×4 exclusivamente con las cuatro piezas legendarias.
    if black_jack_progress() != 4:
        return 1
    for slot in ["helmet", "chest", "legs", "boots"]:
        if get_entry_rarity(get_equipped_entry(slot)) != "legendary":
            return 2
    return 4

func black_jack_damage_factor() -> float:
    # No cambia las armas, solo distribuye el daño entre proyectiles físicos.
    match black_jack_projectiles():
        2:
            return 0.70
        4:
            return 0.45
        _:
            return 1.0

func set_progress(set_id: String) -> int:
    var eligible: int = 0
    for slot in ["helmet", "chest", "legs", "boots"]:
        var entry: Dictionary = get_equipped_entry(slot)
        if entry.is_empty():
            continue
        var definition: Dictionary = DB.get_def(str(entry["id"]))
        if str(definition.get("set_id", "")) == set_id and get_entry_rarity(entry) in ["epic", "legendary"]:
            eligible += 1
    return eligible

func set_tier(set_id: String) -> int:
    # 0 = sin conjunto épico completo, 1 = épico/mezcla, 2 = cuatro legendarias.
    if set_progress(set_id) != 4:
        return 0
    for slot in ["helmet", "chest", "legs", "boots"]:
        if get_entry_rarity(get_equipped_entry(slot)) != "legendary":
            return 1
    return 2

func tragaperras_shield_interval() -> float:
    match set_tier("tragaperras"):
        1:
            return 25.0
        2:
            return 18.0
    return -1.0

func jackpot_damage_multiplier() -> float:
    match set_tier("jackpot"):
        1:
            return 1.8
        2:
            return 2.4
    return 1.0

func jackpot_attack_penalty() -> float:
    match set_tier("jackpot"):
        1:
            return -0.12
        2:
            return -0.20
    return 0.0

func jackpot_charged_multiplier() -> float:
    match set_tier("jackpot"):
        1:
            return 1.3
        2:
            return 1.5
    return 1.0

func jackpot_tracking_enabled() -> bool:
    var helmet: Dictionary = get_equipped_entry("helmet")
    return not helmet.is_empty() and str(DB.get_def(str(helmet["id"])).get("set_id", "")) == "jackpot"

func armor_affinity_counts() -> Dictionary:
    var counts: Dictionary = {"black_jack": 0, "tragaperras": 0, "jackpot": 0}
    for slot in ["helmet", "chest", "legs", "boots"]:
        var entry: Dictionary = get_equipped_entry(slot)
        if entry.is_empty():
            continue
        var set_id: String = str(DB.get_def(str(entry["id"])).get("set_id", ""))
        if counts.has(set_id):
            counts[set_id] = int(counts[set_id]) + 1
    return counts

func best_set_slot_rarities(set_id: String) -> Dictionary:
    # Mejor rareza que YA poseemos por ranura de un set, equipada o en mochila.
    # Evita premiar una ranura vacia de la bolsa si ya hay una epica guardada.
    var progress: Dictionary = {"helmet": -1, "chest": -1, "legs": -1, "boots": -1}
    for entry in get_owned_entries():
        var definition: Dictionary = DB.get_def(str(entry["id"]))
        if str(definition.get("set_id", "")) != set_id:
            continue
        var slot: String = str(definition.get("slot", ""))
        if progress.has(slot):
            var rarity_index: int = DB.RARITY_ORDER.find(get_entry_rarity(entry))
            progress[slot] = maxi(int(progress[slot]), rarity_index)
    return progress

func get_equipped_bonus(stat: String) -> float:
    var total: float = 0.0
    for entry in equipped_items.values():
        total += float(DB.get_upgraded_stats(str(entry["id"]), int(entry["level"]), get_entry_rarity(entry)).get(stat, 0.0))
    return total

func get_slot_name(slot: String) -> String:
    var uid: int = int(equipped.get(slot, -1))
    var entry: Dictionary = find_entry(uid)
    if entry.is_empty():
        return "Vacío"
    return "%s %s Nv.%d" % [str(DB.RARITY_NAMES.get(get_entry_rarity(entry), "")), str(DB.get_def(str(entry["id"]))["name"]), int(entry["level"])]

func reset_inventory() -> void:
    items.clear()
    equipped = {"helmet": -1, "chest": -1, "legs": -1, "boots": -1, "charm": -1, "weapon": -1}
    equipped_items.clear()
    next_uid = 1
    active_relic = ""
    inventory_changed.emit()
