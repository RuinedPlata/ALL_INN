extends Node
const DB = preload("res://scripts/systems/ItemDatabase.gd")
# El máximo es POR TIPO DE APUESTA. Un legendario de ALL IN nunca es consagrado.
const BETS := [
    {"name": "SEGURA", "cost": 30, "chance": 0.50, "max_chance": 0.85, "rarity": "common", "curse": 5.0},
    {"name": "MEDIA", "cost": 75, "chance": 0.35, "max_chance": 0.65, "rarity": "rare", "curse": 10.0},
    {"name": "ALL IN", "cost": 150, "chance": 0.07, "max_chance": 0.25, "rarity": "legendary", "curse": 16.0}
]
# Precio de UN punto porcentual para cada tier: 6, 10 y 20 monedas.
# Así cada opción es viable sin superar los 510 del ALL IN máximo.
const COINS_PER_POINT_BY_TIER: Array[int] = [6, 10, 20]

func get_coins_per_point(index: int) -> int:
    if index < 0 or index >= COINS_PER_POINT_BY_TIER.size():
        return 0
    return COINS_PER_POINT_BY_TIER[index]

func get_max_extra(index: int) -> int:
    if index < 0 or index >= BETS.size():
        return 0
    return int(round((float(BETS[index]["max_chance"]) - float(BETS[index]["chance"])) * 100.0)) * get_coins_per_point(index)

func get_total_cost(index: int, extra_coins: int) -> int:
    if index < 0 or index >= BETS.size():
        return -1
    return int(BETS[index]["cost"]) + clampi(extra_coins, 0, get_max_extra(index))

func get_chance(index: int, extra_coins: int) -> float:
    if index < 0 or index >= BETS.size():
        return 0.0
    var points: int = int(clampi(extra_coins, 0, get_max_extra(index)) / get_coins_per_point(index))
    return minf(float(BETS[index]["max_chance"]), float(BETS[index]["chance"]) + float(points) / 100.0)

func place_bet(index: int, extra_coins: int = 0) -> Dictionary:
    if index < 0 or index >= BETS.size():
        return {"ok": false, "message": "Apuesta inválida."}
    if extra_coins < 0 or extra_coins > get_max_extra(index) or extra_coins % get_coins_per_point(index) != 0:
        return {"ok": false, "message": "Extra inválido para esta ruleta."}
    if not RunManager.run_active:
        return {"ok": false, "message": "La partida ha terminado."}
    if InventoryManager.is_full():
        return {"ok": false, "message": "Inventario lleno. Vende algo antes de apostar."}
    var bet: Dictionary = BETS[index]
    var cost: int = get_total_cost(index, extra_coins)
    var chance: float = get_chance(index, extra_coins)
    if not RunManager.spend_coins(cost):
        return {"ok": false, "message": "Necesitas %d monedas." % cost}
    if randf() < chance:
        var item_id: String = DB.roll_id(str(bet["rarity"]))
        if DB.is_set_armor(item_id):
            item_id = RunManager.roll_armor_piece_id(str(bet["rarity"]))
        elif str(DB.get_def(item_id).get("weapon_type", "")) != "":
            item_id = RunManager.roll_weapon_piece_id(str(bet["rarity"]))
        var result: Dictionary = InventoryManager.add_item(item_id)
        if not bool(result["ok"]):
            RunManager.add_coins(cost)
            return {"ok": false, "message": str(result["message"])}
        RunManager.record_bet(true)
        var item_def: Dictionary = DB.get_def(item_id)
        return {"ok": true, "won": true, "message": "¡GANASTE! [%s] %s (%.0f%% de éxito)." % [DB.RARITY_NAMES[str(bet["rarity"])], str(item_def["name"]), chance * 100.0]}
    RunManager.record_bet(false)
    var curse_time: float = float(bet["curse"])
    RunManager.apply_curse(curse_time)
    return {"ok": true, "won": false, "message": "PERDISTE %d monedas (incluye %d extra). Maldición -30%% velocidad (%d s)." % [cost, extra_coins, int(curse_time)]}
