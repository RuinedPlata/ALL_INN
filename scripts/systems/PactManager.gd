extends Node
## Pactos normales: costo 10 monedas, 60% éxito / 40% fracaso.
## Mantiene la fortuna -3..+3 y efectos temporales por número de sala.
## La ruleta extraordinaria ALL IN queda fuera de esta versión.

signal pacts_changed

const SUCCESS_CHANCE: float = 0.60
const PACT_COST: int = 10
const REROLL_COST: int = 50
const LIMIT: int = 3
const OVERLOAD_ROOMS: int = 7 # Número de la suerte: sala actual + siguientes 6.
const SPECIAL_EFFECT_ROOMS: int = 2 # Eco del Destino mantiene su duración previa.

const PACTS := {
    "codicia": {"name": "Codicia", "family": "economy", "stat": "loot", "step": 0.03, "desc": "Probabilidad de objeto +3 / -3 puntos por tirada"},
    "recaudador": {"name": "Recaudador", "family": "economy", "stat": "coins", "step": 0.08, "desc": "Al COBRAR recompensa de sala: +8% / -8% monedas"},
    # El pacto Mercader ajusta ventas. Los costos de forja se muestran por separado.
    "mercader": {"name": "Pacto del Mercader", "family": "economy", "stat": "sell", "step": 0.08, "desc": "Valor de venta +8% / -8%"},
    "filo": {"name": "Filo del Destino", "family": "combat", "stat": "damage", "step": 0.04, "desc": "Daño medio de ataque +4% / -4%"},
    "ritmo": {"name": "Ritmo Frenético", "family": "combat", "stat": "attack", "step": 0.05, "desc": "Cadencia +5% / -5%"},
    "instinto": {"name": "Instinto Asesino", "family": "combat", "stat": "crit", "step": 0.03, "desc": "Prob. crítica +3 / -3 puntos"},
    "paso": {"name": "Paso Fantasma", "family": "survival", "stat": "speed", "step": 0.04, "desc": "Velocidad +4% / -4%"},
    "coraza": {"name": "Coraza del Destino", "family": "survival", "stat": "block", "step": 0.02, "desc": "Bloqueo +2 / -2 puntos"},
    "aliento": {"name": "Último Aliento", "family": "survival", "stat": "iframes", "step": 0.10, "desc": "Invulnerabilidad tras golpe +0.1 / -0.1 s"},
    "eco": {"name": "Eco del Destino", "family": "special", "desc": "Éxito: tiro extra cada 4 ataques; fallo: se cancela cada cuarto ataque. 2 salas"},
    "cazador": {"name": "Pacto del Cazador", "family": "special", "desc": "Próxima sala: enemigos +15% vida. Victoria: XP y cobro de sala +25%"},
    "segunda": {"name": "Segunda Oportunidad", "family": "special", "desc": "Éxito: pacto extra próxima sala; fallo: 3 opciones sin afinidad próxima sala"}
}

const STACKABLE: Array[String] = ["codicia", "recaudador", "mercader", "filo", "ritmo", "instinto", "paso", "coraza", "aliento"]
const ECONOMY: Array[String] = ["codicia", "recaudador", "mercader"]
const COMBAT: Array[String] = ["filo", "ritmo", "instinto"]
const WILDCARD: Array[String] = ["paso", "coraza", "aliento", "eco", "cazador", "segunda"]

var fortune: Dictionary = {}        # pacto -> entero [-3,3]
var temporary: Dictionary = {}      # pacto -> {kind, expires} (sala final excluida)
var room_number: int = 1
var extra_next_room: bool = false
var extra_this_room: bool = false
var no_affinity_next_room: bool = false
var no_affinity_this_room: bool = false
var hunter_next: int = 0           # +1 premio, -1 castigo, 0 ninguno
var hunter_this_room: int = 0
var guaranteed_drop_used: bool = false
var special_sale_used: bool = false

func reset_pacts() -> void:
    fortune.clear()
    temporary.clear()
    room_number = 1
    extra_next_room = false
    extra_this_room = false
    no_affinity_next_room = false
    no_affinity_this_room = false
    hunter_next = 0
    hunter_this_room = 0
    guaranteed_drop_used = false
    special_sale_used = false
    pacts_changed.emit()

func begin_room(number: int) -> void:
    room_number = number
    extra_this_room = extra_next_room
    extra_next_room = false
    no_affinity_this_room = no_affinity_next_room
    no_affinity_next_room = false
    hunter_this_room = hunter_next
    hunter_next = 0
    for key in temporary.keys():
        if number >= int(temporary[key]["expires"]):
            temporary.erase(key)
    pacts_changed.emit()

func is_active(pact_id: String, kind: String) -> bool:
    return temporary.has(pact_id) and str(temporary[pact_id]["kind"]) == kind

func get_stat(stat: String) -> float:
    var total: float = 0.0
    for key in STACKABLE:
        var entry: Dictionary = PACTS[key]
        if str(entry["stat"]) != stat:
            continue
        total += int(fortune.get(key, 0)) * float(entry["step"])
        if is_active(key, "crisis"):
            total -= float(entry["step"]) * 2.0
    # Sobrecarga de Filo ya no perfora enemigos: la perforación se reserva
    # para efectos consagrados futuros. Sigue otorgando una ventaja temporal.
    if stat == "damage" and is_active("filo", "overload"):
        total += 0.08
    if stat == "speed" and is_active("paso", "overload"):
        total += 0.10
    if stat == "coins" and is_active("recaudador", "overload"):
        total += 0.40
    if stat == "iframes" and is_active("aliento", "overload"):
        total += 0.55
    return total

func coin_factor() -> float:
    var hunter_bonus: float = 0.25 if hunter_this_room == 1 else 0.0
    return clampf(1.0 + get_stat("coins") + hunter_bonus, 0.25, 2.0)

func sale_factor() -> float:
    return clampf(1.0 + get_stat("sell"), 0.50, 1.50)

func take_sale_overload_bonus() -> int:
    if is_active("mercader", "overload") and not special_sale_used:
        special_sale_used = true
        return 50
    return 0

func item_probability() -> float:
    return clampf(0.30 + get_stat("loot"), 0.05, 0.55)

func consume_guaranteed_item() -> bool:
    if is_active("codicia", "overload") and not guaranteed_drop_used:
        guaranteed_drop_used = true
        return true
    return false

func damage_modifier() -> float:
    return clampf(get_stat("damage"), -0.20, 0.30)

func crit_chance_bonus() -> float:
    return get_stat("crit")

func block_chance_bonus() -> float:
    return get_stat("block")

func iframe_bonus() -> float:
    return get_stat("iframes")

func hunter_health_multiplier() -> float:
    return 1.15 if hunter_this_room != 0 else 1.0

func hunter_xp_multiplier() -> float:
    return 1.25 if hunter_this_room == 1 else 1.0

func is_echo_extra() -> bool:
    return is_active("eco", "win")

func is_echo_miss() -> bool:
    return is_active("eco", "lose")

func _choose_weighted(pool: Array[String], excluded: Array[String], use_affinity: bool = true) -> String:
    var weighted: Array[String] = []
    for pact_id in pool:
        if pact_id in excluded:
            continue
        weighted.append(pact_id)
        if use_affinity and int(fortune.get(pact_id, 0)) != 0:
            weighted.append(pact_id)
    if weighted.is_empty():
        return ""
    return weighted[randi_range(0, weighted.size() - 1)]

func draw_offers(is_extra: bool = false) -> Array[String]:
    # INVARIANTE: tres opciones distintas SIEMPRE, incluso tras perder Segunda Oportunidad.
    # Su derrota únicamente desactiva la afinidad en la sala siguiente.
    var offers: Array[String] = []
    var affinity_enabled: bool = not no_affinity_this_room
    offers.append(_choose_weighted(ECONOMY, offers, affinity_enabled))
    offers.append(_choose_weighted(COMBAT, offers, affinity_enabled))
    var pool: Array[String] = []
    pool.append_array(WILDCARD)
    if is_extra:
        pool.erase("segunda")  # Las apuestas extra no generan otras extras.
    offers.append(_choose_weighted(pool, offers, affinity_enabled))
    assert(offers.size() == 3 and not offers.has(""), "ALL IN: la mesa debe ofrecer tres pactos")
    return offers

func reroll_stackable_offers() -> Array[String]:
    # 3 de 9 pactos acumulables, distintos dentro de la misma tirada.
    # NO excluye los anteriores: pueden repetirse 1, 2 o los mismos 3.
    var pool: Array[String] = []
    pool.append_array(STACKABLE)
    pool.shuffle()
    var offers: Array[String] = [pool[0], pool[1], pool[2]]
    return offers

func resolve_pact(pact_id: String, is_extra: bool = false) -> Dictionary:
    if not PACTS.has(pact_id) or not RunManager.run_active:
        return {"ok": false, "message": "Pacto inválido o partida finalizada."}
    if is_extra and pact_id == "segunda":
        return {"ok": false, "message": "No puedes encadenar Segundas Oportunidades."}
    if not RunManager.spend_coins(PACT_COST):
        return {"ok": false, "message": "Este pacto cuesta 10 monedas. Necesitas conseguir más para apostar."}
    var won: bool = randf() < SUCCESS_CHANCE
    var entry: Dictionary = PACTS[pact_id]
    var result_text: String = ""
    if pact_id in STACKABLE:
        var previous: int = int(fortune.get(pact_id, 0))
        if won and previous == LIMIT:
            temporary[pact_id] = {"kind": "overload", "expires": room_number + OVERLOAD_ROOMS}
            if pact_id == "coraza":
                RunManager.shield_charges = mini(1, RunManager.shield_charges + 1)
            elif pact_id == "codicia":
                guaranteed_drop_used = false
            elif pact_id == "mercader":
                special_sale_used = false
            result_text = "¡SOBRECARGA! %s (%d salas, combinable)." % [str(entry["name"]), OVERLOAD_ROOMS]
        elif not won and previous == -LIMIT:
            temporary[pact_id] = {"kind": "crisis", "expires": room_number + 1}
            result_text = "¡CRISIS! %s (esta sala)." % str(entry["name"])
        else:
            fortune[pact_id] = clampi(previous + (1 if won else -1), -LIMIT, LIMIT)
            result_text = "%s: fortuna %+d / 3." % [str(entry["name"]), int(fortune[pact_id])]
    else:
        if pact_id == "eco":
            temporary["eco"] = {"kind": "win" if won else "lose", "expires": room_number + SPECIAL_EFFECT_ROOMS}
            result_text = "Eco: tiro extra cada 4 ataques." if won else "Eco: cada 4º ataque falla."
        elif pact_id == "cazador":
            hunter_next = 1 if won else -1
            result_text = "Próxima sala: enemigos +15% vida y monedas/XP +25%." if won else "Próxima sala: enemigos +15% vida, sin premio."
        elif pact_id == "segunda":
            if won:
                extra_next_room = true
                result_text = "¡Una oportunidad adicional de pacto en la próxima sala!"
            else:
                no_affinity_next_room = true
                result_text = "Próxima sala: tres opciones, pero sin bonificación de afinidad."
    RunManager.record_bet(won)
    RunManager.stats_changed.emit()
    pacts_changed.emit()
    return {"ok": true, "won": won, "message": ("VICTORIA 60%. " if won else "DERROTA 40%. ") + result_text}

func fortune_summary() -> String:
    var active: Array[String] = []
    for key in STACKABLE:
        var value: int = int(fortune.get(key, 0))
        if value != 0:
            active.append("%s %+d" % [str(PACTS[key]["name"]), value])
    if active.is_empty():
        return "Sin pactos acumulados"
    return " | ".join(active)
