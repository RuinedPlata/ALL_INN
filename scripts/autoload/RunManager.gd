extends Node
# Estadísticas de una partida y récord persistente en user://.
# Los objetos y monedas desaparecen al reiniciar; el récord no.
signal coins_changed(new_amount: int)
signal health_changed(new_amount: int)
signal player_hurt
signal stats_changed
signal run_ended
signal run_finished(extracted: bool)
signal enemy_killed
signal boss_defeated
signal boss_coins_awarded(room_number: int, amount: int)
signal level_gained(new_level: int)
signal death_roll_requested
signal hit_blocked
signal evasion_triggered
signal parry_triggered

const RECORD_PATH := "user://all_in_record.cfg"
const BOSS_REWARD_RULES = preload("res://scripts/systems/BossRewardRules.gd")
const ITEM_DB = preload("res://scripts/systems/ItemDatabase.gd")
const EPIC_PITY_QUALITY_ROLLS: int = 25  # 4.31: evita sequías de épicos desde sala 40.
const NORMAL_ROOM_COMPLETION_COINS: int = 10 # 4.31: ingreso fijo por sala normal, independientemente de COBRAR.
const NORMAL_ROOM_CASH_COINS: int = 30       # Premio inicial opcional; sube por bloque de 10 salas.
const NORMAL_ROOM_CASH_STEP_COINS: int = 10  # A partir de sala 11, +10 por bloque.
const ENEMY_KILL_COINS_MIN: int = 4 # Base salas 1-20; aumenta con el nivel.
const ENEMY_KILL_COINS_MAX: int = 7
const PLAYER_GLOBAL_DAMAGE_BONUS: float = 0.10 # +10% de daño base del jugador; se suma a nivel y pecho.

var arena_rect: Rect2 = Rect2(20.0, 72.0, 500.0, 790.0)
var coins: int = 100
var player_health: int = 3
var max_health: int = 3
var shield_charges: int = 0
var set_shield_active: bool = false
var set_shield_elapsed: float = 0.0
var set_shield_interval: float = -1.0
var revival_used: bool = false
var current_level: int = 1
var character_level: int = 1
var xp: int = 0
var xp_to_next: int = 12
var level_speed_bonus: float = 0.0
var level_damage_bonus: int = 0 # Compatibilidad con mejoras anteriores; la ruleta nueva utiliza porcentaje.
var level_damage_percent_bonus: float = 0.0
var level_projectile_speed_bonus: float = 0.0
var run_active: bool = true
var speed_bonus: float = 0.0
var attack_bonus: float = 0.0
var curse_remaining: float = 0.0
var enemies_defeated: int = 0
var rooms_cleared: int = 0
var bosses_defeated_count: int = 0
# Garantía contra repetir el premio de un jefe por una señal duplicada.
var boss_coin_rewards_paid: Dictionary = {}
var normal_room_coins_paid: Dictionary = {} # Salvaguarda: una sola entrega por sala no-jefe.
var bets_placed: int = 0
var bets_won: int = 0
var coins_earned: int = 0
var coins_spent: int = 0
var quality_rolls_since_epic: int = 0
var armor_drop_history: Dictionary = {} # Últimas piezas por rareza y conjunto, sin garantizar ciclos
var rest_choices: int = 0
var cash_choices: int = 0
var elapsed_time: float = 0.0
var debug_used: bool = false
var best_score: int = 0
var best_room: int = 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    var config := ConfigFile.new()
    if config.load(RECORD_PATH) == OK:
        best_score = maxi(0, int(config.get_value("records", "best_score", 0)))
        best_room = maxi(0, int(config.get_value("records", "best_room", 0)))

func _process(delta: float) -> void:
    if not run_active:
        return
    elapsed_time += delta
    _advance_set_shield(delta)
    if curse_remaining > 0.0:
        curse_remaining = maxf(0.0, curse_remaining - delta)
        stats_changed.emit()

func grant_xp(amount: int) -> void:
    if not run_active or amount <= 0:
        return
    xp += maxi(1, int(round(float(amount) * PactManager.hunter_xp_multiplier())))
    while xp >= xp_to_next:
        xp -= xp_to_next
        character_level += 1
        xp_to_next = 12 + (character_level - 1) * 7
        # La recompensa de nivel se asigna DESPUÉS, en una ruleta obligatoria.
        # No mejoramos daño automáticamente: así los objetos siguen importando.
        level_gained.emit(character_level)
    stats_changed.emit()


# ALL IN 4.21: solo estadísticas. Los modificadores NO tienen techo artificial.
# Distribución equitativa: 25% cada una (daño, cadencia, movimiento y proyectiles).
func award_level_roll() -> Dictionary:
    return award_level_roll_for_roll(randi_range(0, 9999))

# Variante determinista para pruebas. Cada resultado modifica UNA estadística,
# sin curar, aumentar vida máxima, crear escudos ni modificar las monedas.
func award_level_roll_for_roll(raw_roll: int) -> Dictionary:
    var roll: int = clampi(raw_roll, 0, 9999)
    var outcome: String = ""
    var stat: String = ""
    if roll < 2500:
        level_damage_percent_bonus += 0.04
        outcome = "+4% daño de ataques (se acumula durante esta partida)"
        stat = "damage"
    elif roll < 5000:
        attack_bonus += 0.04
        outcome = "+4% cadencia de disparo (se acumula durante esta partida)"
        stat = "attack"
    elif roll < 7500:
        level_speed_bonus += 0.03
        outcome = "+3% velocidad de movimiento (se acumula durante esta partida)"
        stat = "speed"
    else:
        level_projectile_speed_bonus += 0.06
        outcome = "+6% velocidad de proyectiles (se acumula durante esta partida)"
        stat = "projectile_speed"
    stats_changed.emit()
    return {"message": outcome, "stat": stat}

func get_normal_room_cash_reward(room_number: int) -> int:
    # Sala 1-9: 30; 11-19: 40; 21-29: 50; 31-39: 60; etc.
    # La décima sala siempre es un jefe y tiene su propia recompensa.
    if room_number <= 0 or room_number % 10 == 0:
        return 0
    var completed_blocks: int = int(floor(float(room_number - 1) / 10.0))
    return NORMAL_ROOM_CASH_COINS + completed_blocks * NORMAL_ROOM_CASH_STEP_COINS

func roll_quality_loot_rarity() -> String:
    # La garantía épica NO sortea el bloqueo de rareza de las primeras 31 salas.
    # Comenzamos a contar tiradas elegibles al abrir la sala 32.
    if current_level <= 39:
        quality_rolls_since_epic = 0
        return ITEM_DB.roll_drop_rarity(current_level)
    var rarity: String = "epic" if quality_rolls_since_epic >= EPIC_PITY_QUALITY_ROLLS - 1 else ITEM_DB.roll_drop_rarity(current_level)
    if rarity in ["epic", "legendary"]:
        quality_rolls_since_epic = 0
    else:
        quality_rolls_since_epic += 1
    return rarity

func _weighted_pick(options: Array[String], weights: Array[float]) -> String:
    var total: float = 0.0
    for weight in weights:
        total += maxf(0.0, weight)
    if total <= 0.0:
        return options.pick_random() if not options.is_empty() else ""
    var draw: float = randf() * total
    for i in range(options.size()):
        draw -= maxf(0.0, weights[i])
        if draw < 0.0:
            return options[i]
    return options.back()

func roll_armor_piece_id(rarity: String) -> String:
    # 60/20/20 si hay un set predominante ÚNICO. Empates ponderados:
    # dos sets equipados empatan por encima de un tercero sin piezas.
    if not ITEM_DB.RARITY_ORDER.has(rarity):
        return ""
    var sets: Array[String] = ["black_jack", "tragaperras", "jackpot"]
    var counts: Dictionary = InventoryManager.armor_affinity_counts()
    var best_count: int = 0
    var best_id: String = ""
    var tied: bool = false
    for set_id in sets:
        var count: int = int(counts.get(set_id, 0))
        if count > best_count:
            best_count = count
            best_id = set_id
            tied = false
        elif count == best_count and count > 0:
            tied = true
    var weights: Array[float] = []
    for set_id in sets:
        var weight: float = 1.0 / 3.0
        if best_count > 0:
            if tied:
                weight = 1.0 + 2.0 * float(int(counts.get(set_id, 0)))
            else:
                weight = 0.60 if set_id == best_id else 0.20
        weights.append(weight)
    var chosen_set: String = _weighted_pick(sets, weights)
    var prefix: String = str(ITEM_DB.ARMOR_SET_PREFIXES[chosen_set])
    var slots: Array[String] = ["helmet", "chest", "legs", "boots"]
    var slot_weights: Array[float] = []
    # Priorizar la pieza mas atrasada del set elegido, aunque este en la mochila.
    # No se fuerza una ranura: los duplicados y otras piezas siguen apareciendo.
    var slot_progress: Dictionary = InventoryManager.best_set_slot_rarities(chosen_set)
    var best_progress: int = -1
    var lowest_progress: int = 99
    for slot in slots:
        var progress: int = int(slot_progress.get(slot, -1))
        best_progress = maxi(best_progress, progress)
        lowest_progress = mini(lowest_progress, progress)
    var has_lagging_slots: bool = best_progress > lowest_progress
    var history_key: String = rarity + ":" + chosen_set
    var history: Array[String] = []
    if armor_drop_history.has(history_key):
        history.assign(armor_drop_history[history_key])
    for slot in slots:
        var weight: float = 1.0
        var entry: Dictionary = InventoryManager.get_equipped_entry(slot)
        if not entry.is_empty() and str(ITEM_DB.get_def(str(entry["id"])).get("set_id", "")) == chosen_set:
            weight *= 1.40 # Conservar duplicados utiles de la armadura equipada.
        if has_lagging_slots and int(slot_progress.get(slot, -1)) == lowest_progress:
            weight *= 2.0 # La ranura atrasada compite de verdad con las equipadas.
        # Reparto inteligente SUAVE; pueden repetirse piezas, no hay garantias.
        if history.size() >= 1 and history.back() == slot:
            weight *= 0.70
        if history.size() >= 2 and history[history.size() - 2] == slot:
            weight *= 0.75
        slot_weights.append(weight)
    var chosen_slot: String = _weighted_pick(slots, slot_weights)
    history.append(chosen_slot)
    if history.size() > 3:
        history.pop_front()
    armor_drop_history[history_key] = history
    return "%s_%s_%s" % [prefix, chosen_slot, rarity]

func roll_weapon_piece_id(rarity: String) -> String:
    # Afinidad hacia el arma 2.0 equipada: 45/18.33/18.33/18.33.
    # No modifica el porcentaje total de armas en el botin.
    if not ITEM_DB.RARITY_ORDER.has(rarity):
        return ""
    var types: Array[String] = ["pistol", "shotgun", "smg", "deagle"]
    var equipped_type: String = InventoryManager.equipped_weapon_affinity_type()
    var weights: Array[float] = []
    for typ in types:
        var weight: float = 0.25
        if equipped_type != "":
            weight = 0.45 if typ == equipped_type else (0.55 / 3.0)
        weights.append(weight)
    var chosen_type: String = _weighted_pick(types, weights)
    return "%s_%s" % [chosen_type, rarity]

func roll_black_jack_piece_id(rarity: String) -> String:
    # Alias de compatibilidad con pruebas antiguas; distribuidor multiconjunto.
    return roll_armor_piece_id(rarity)

func _advance_set_shield(delta: float) -> void:
    var target_interval: float = InventoryManager.tragaperras_shield_interval()
    if target_interval != set_shield_interval:
        set_shield_interval = target_interval
        set_shield_active = false
        set_shield_elapsed = 0.0
        health_changed.emit(player_health)
    if target_interval <= 0.0 or set_shield_active:
        return
    set_shield_elapsed = minf(target_interval, set_shield_elapsed + delta)
    if set_shield_elapsed >= target_interval:
        set_shield_active = true
        health_changed.emit(player_health)

func roll_guaranteed_loot_rarity() -> String:
    # La garantía de Codicia garantiza OBJETO, no calidad superior a la sala.
    return ITEM_DB.roll_drop_rarity(current_level)

func add_coins(amount: int) -> void:
    if amount <= 0 or not run_active:
        return
    coins += amount
    coins_earned += amount
    coins_changed.emit(coins)

# --- ECONOMÍA: pago base por completar una sala normal ---
func award_normal_room_coins(room_number: int) -> int:
    if not run_active or room_number <= 0 or room_number % 10 == 0:
        return 0
    if normal_room_coins_paid.has(room_number):
        return 0
    add_coins(NORMAL_ROOM_COMPLETION_COINS)
    normal_room_coins_paid[room_number] = NORMAL_ROOM_COMPLETION_COINS
    return NORMAL_ROOM_COMPLETION_COINS

# --- ECONOMÍA: bonos de jefe ---
# Solo award_boss_coins puede conceder estas monedas. Boss.gd comunica la derrota,
# Main.gd coordina la habitación y RunManager conserva el saldo y el registro.
func get_boss_coin_prize(room_number: int) -> int:
    return BOSS_REWARD_RULES.coins_for_room(room_number)

func get_boss_coins_paid(room_number: int) -> int:
    return int(boss_coin_rewards_paid.get(room_number, 0))

func award_boss_coins(room_number: int) -> int:
    var prize: int = get_boss_coin_prize(room_number)
    if prize <= 0:
        push_error("ALL IN: intento de pagar bono en sala no válida: %d" % room_number)
        return 0
    if boss_coin_rewards_paid.has(room_number):
        # Doble señal o cierre diferido: el premio YA está en el saldo.
        return 0
    if not run_active:
        push_error("ALL IN: bono de sala %d rechazado porque la partida terminó" % room_number)
        return 0

    var previous_balance: int = coins
    add_coins(prize)  # Misma vía de abono que usan todas las recompensas del juego.
    if coins != previous_balance + prize:
        push_error("ALL IN: no se acreditó el bono de sala %d: saldo previo %d, saldo nuevo %d" % [room_number, previous_balance, coins])
        return 0

    # Se registra como pagado DESPUÉS de confirmar el incremento del saldo.
    boss_coin_rewards_paid[room_number] = prize
    print("[ALL IN 4.16.2] JEFE SALA %d | ANTES: %d | BONO: +%d | DESPUÉS: %d" % [room_number, previous_balance, prize, coins])
    boss_coins_awarded.emit(room_number, prize)
    return prize

func spend_coins(amount: int) -> bool:
    if not run_active or amount <= 0 or coins < amount:
        return false
    coins -= amount
    coins_spent += amount
    coins_changed.emit(coins)
    return true

func get_effective_max_health() -> int:
    # El máximo de corazones es fijo para toda la partida.
    return max_health

func get_block_chance() -> float:
    # Los antiguos bonos de vida ahora son RESISTENCIA.
    # Armadura: +3.5 puntos porcentuales por punto.
    # Resistencia: +0.3 puntos porcentuales por punto.
    # Hasta 30% mantenemos el balance anterior. Después hay rendimientos
    # decrecientes hacia 45%: fusionar más armadura siempre aporta algo,
    # pero nunca permite inmunidad completa a golpes.
    var armor: float = InventoryManager.get_equipped_bonus("armor")
    var toughness: float = InventoryManager.get_equipped_bonus("health")
    var raw: float = maxf(0.0, armor * 0.035 + toughness * 0.003)
    var block: float = raw if raw <= 0.30 else 0.30 + 0.15 * (1.0 - exp(-(raw - 0.30) / 0.15))
    return clampf(block + PactManager.block_chance_bonus(), 0.0, 0.55)

func on_equipment_changed(_previous_max: int) -> void:
    # Cambiar equipo no cura ni incrementa el máximo de tres corazones.
    health_changed.emit(player_health)
    stats_changed.emit()

func heal_player(amount: int) -> void:
    if not run_active or amount <= 0:
        return
    player_health = mini(max_health, player_health + amount)
    health_changed.emit(player_health)

func damage_player(amount: int) -> bool:
    # true solo cuando pierde realmente un corazón. Un escudo, bloqueo,
    # parry o evasión no debe activar la animación de dolor del Apostador.
    if not run_active or amount <= 0:
        return false
    # El orden importa: evadir o hacer parry no consume un escudo almacenado.
    var evasion: float = clampf(InventoryManager.get_equipped_bonus("evasion"), 0.0, 0.20)
    if randf() < evasion:
        hit_blocked.emit()
        evasion_triggered.emit()
        return false
    var parry: float = clampf(InventoryManager.get_equipped_bonus("parry"), 0.0, 0.20)
    if randf() < parry:
        hit_blocked.emit()
        parry_triggered.emit()
        return false
    if set_shield_active:
        set_shield_active = false
        set_shield_elapsed = 0.0
        health_changed.emit(player_health)
        hit_blocked.emit()
        return false
    if shield_charges > 0:
        shield_charges -= 1
        stats_changed.emit()
        health_changed.emit(player_health)
        hit_blocked.emit()
        return false
    if randf() < get_block_chance():
        hit_blocked.emit()
        return false
    # Un impacto efectivo = UN corazón, independientemente de daño de bala.
    set_shield_elapsed = 0.0 # Recupera solo tras una ventana sin recibir daño.
    player_health = maxi(0, player_health - 1)
    player_hurt.emit()
    health_changed.emit(player_health)
    if player_health <= 0:
        run_active = false
        if not revival_used:
            revival_used = true
            death_roll_requested.emit()
        else:
            _update_record(false)
            run_ended.emit()
    return true

func resolve_death_roll() -> bool:
    # Solo puede resolverse cuando ya se ha consumido la oportunidad única.
    if run_active or not revival_used or player_health > 0:
        return false
    if randf() < 0.5:
        player_health = 1
        run_active = true
        health_changed.emit(player_health)
        stats_changed.emit()
        return true
    _update_record(false)
    run_ended.emit()
    return false

func apply_curse(seconds: float) -> void:
    if not run_active:
        return
    curse_remaining = maxf(curse_remaining, seconds)
    stats_changed.emit()

func enemy_kill_coin_range(room_number: int) -> Vector2i:
    # Progresion 4.31: 1-20=4-7; 21-30=6-9; 31-40=8-11;
    # 41-50=10-13; 51-60=12-15, continuando +2 cada 10 salas.
    var tier: int = maxi(0, int(floor(float(room_number - 21) / 10.0)) + 1) if room_number >= 21 else 0
    var bonus: int = tier * 2
    return Vector2i(ENEMY_KILL_COINS_MIN + bonus, ENEMY_KILL_COINS_MAX + bonus)

func award_enemy_kill_coins() -> int:
    # Una sola entrega por muerte confirmada; el jefe usa su bono propio.
    if not run_active:
        return 0
    var prize_range: Vector2i = enemy_kill_coin_range(current_level)
    var prize: int = randi_range(prize_range.x, prize_range.y)
    add_coins(prize)
    return prize

func enemy_defeated() -> void:
    if not run_active:
        return
    enemies_defeated += 1
    award_enemy_kill_coins()
    # La experiencia es por combate, independiente del dinero y el equipo.
    grant_xp(3 + mini(3, int((current_level - 1) / 4)))
    enemy_killed.emit()

func register_room_clear(is_boss: bool) -> void:
    if not run_active:
        return
    rooms_cleared += 1
    if is_boss:
        bosses_defeated_count += 1

func record_bet(won: bool) -> void:
    bets_placed += 1
    if won:
        bets_won += 1

func get_score(extracted: bool = false) -> int:
    # Puntuación clara y repetible. No depende de segundos ni de una tirada aleatoria.
    return rooms_cleared * 120 + bosses_defeated_count * 450 + enemies_defeated * 12 + bets_won * 80 + coins * 2 + (250 if extracted else 0)

func finish_run() -> void:
    if not run_active:
        return
    run_active = false
    _update_record(true)
    run_finished.emit(true)

func _update_record(extracted: bool) -> void:
    # Saltarse salas con F8 NO puede alterar los récords reales.
    if debug_used:
        return
    var score: int = get_score(extracted)
    best_score = maxi(best_score, score)
    best_room = maxi(best_room, rooms_cleared)
    var config := ConfigFile.new()
    config.set_value("records", "best_score", best_score)
    config.set_value("records", "best_room", best_room)
    var err: Error = config.save(RECORD_PATH)
    if err != OK:
        push_warning("No se pudo guardar el récord local: %d" % err)

func reset_run() -> void:
    # Un reinicio de partida DEBE reiniciar también los pactos del autoload.
    # Evita fortunas y efectos temporales heredados en pruebas, reinicios
    # programáticos o futuras pantallas que no recarguen la escena Main.
    PactManager.reset_pacts()
    coins = 100
    shield_charges = 0
    set_shield_active = false
    set_shield_elapsed = 0.0
    set_shield_interval = -1.0
    revival_used = false
    max_health = 3
    player_health = max_health
    current_level = 1
    character_level = 1
    xp = 0
    xp_to_next = 12
    level_speed_bonus = 0.0
    level_damage_bonus = 0
    level_damage_percent_bonus = 0.0
    level_projectile_speed_bonus = 0.0
    run_active = true
    speed_bonus = 0.0
    attack_bonus = 0.0
    curse_remaining = 0.0
    enemies_defeated = 0
    rooms_cleared = 0
    bosses_defeated_count = 0
    boss_coin_rewards_paid.clear()
    normal_room_coins_paid.clear()
    bets_placed = 0
    bets_won = 0
    coins_earned = 0
    coins_spent = 0
    quality_rolls_since_epic = 0
    armor_drop_history.clear()
    rest_choices = 0
    cash_choices = 0
    elapsed_time = 0.0
    debug_used = false
    coins_changed.emit(coins)
    health_changed.emit(player_health)
    stats_changed.emit()
