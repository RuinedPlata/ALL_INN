extends RefCounted
# ALL IN 4.27: tres conjuntos, 48 variantes, 32 piezas nuevas.
# Se conservan las armas y amuletos existentes como placeholders; la forja funciona igual.
const ITEM_DEFS := {
    "knife": {"name": "Cuchillo de Cartón", "rarity": "common", "slot": "weapon", "sell": 6, "damage": 1, "description": "Más afilado de lo que parece."},
    "splinter": {"name": "Daga Astillada", "rarity": "common", "slot": "weapon", "sell": 7, "damage": 1, "crit": 0.02, "description": "Una pequeña posibilidad de crítico."},
    "blade": {"name": "Navaja de las Disculpas", "rarity": "rare", "slot": "weapon", "sell": 18, "damage": 2, "crit": 0.04, "description": "Pide perdón después del golpe."},
    "razor": {"name": "Navaja del Azar", "rarity": "epic", "slot": "weapon", "sell": 45, "damage": 3, "crit": 0.07, "description": "Los golpes decisivos importan."},
    "debt": {"name": "Deuda del Rey", "rarity": "legendary", "slot": "weapon", "sell": 100, "damage": 4, "crit": 0.12, "attack": 0.06, "description": "Cada acierto cobra intereses."},
    # Armas 2.0: 4 tipos; cada rareza tiene ID nativo para botín, fusión y ascensión.
    "pistol_common": {"name": "Pistola", "rarity": "common", "slot": "weapon", "weapon_type": "pistol", "sell": 9, "damage": 1.000, "attack": 0.0, "description": "Equilibrada: un proyectil preciso."},
    "pistol_rare": {"name": "Pistola", "rarity": "rare", "slot": "weapon", "weapon_type": "pistol", "sell": 22, "damage": 1.350, "attack": 0.0, "description": "Equilibrada: un proyectil preciso."},
    "pistol_epic": {"name": "Pistola", "rarity": "epic", "slot": "weapon", "weapon_type": "pistol", "sell": 52, "damage": 1.750, "attack": 0.0, "description": "Equilibrada: un proyectil preciso."},
    "pistol_legendary": {"name": "Pistola", "rarity": "legendary", "slot": "weapon", "weapon_type": "pistol", "sell": 110, "damage": 2.250, "attack": 0.0, "description": "Equilibrada: un proyectil preciso."},
    "shotgun_common": {"name": "Escopeta", "rarity": "common", "slot": "weapon", "weapon_type": "shotgun", "sell": 9, "damage": 0.500, "attack": -0.3, "description": "Tres perdigones separados de corto alcance."},
    "shotgun_rare": {"name": "Escopeta", "rarity": "rare", "slot": "weapon", "weapon_type": "shotgun", "sell": 22, "damage": 0.675, "attack": -0.3, "description": "Tres perdigones separados de corto alcance."},
    "shotgun_epic": {"name": "Escopeta", "rarity": "epic", "slot": "weapon", "weapon_type": "shotgun", "sell": 52, "damage": 0.875, "attack": -0.3, "description": "Tres perdigones separados de corto alcance."},
    "shotgun_legendary": {"name": "Escopeta", "rarity": "legendary", "slot": "weapon", "weapon_type": "shotgun", "sell": 110, "damage": 1.125, "attack": -0.3, "description": "Tres perdigones separados de corto alcance."},
    "smg_common": {"name": "Subfusil", "rarity": "common", "slot": "weapon", "weapon_type": "smg", "sell": 9, "damage": 0.350, "attack": 0.75, "description": "Cadencia alta, impacto bajo."},
    "smg_rare": {"name": "Subfusil", "rarity": "rare", "slot": "weapon", "weapon_type": "smg", "sell": 22, "damage": 0.472, "attack": 0.75, "description": "Cadencia alta, impacto bajo."},
    "smg_epic": {"name": "Subfusil", "rarity": "epic", "slot": "weapon", "weapon_type": "smg", "sell": 52, "damage": 0.612, "attack": 0.75, "description": "Cadencia alta, impacto bajo."},
    "smg_legendary": {"name": "Subfusil", "rarity": "legendary", "slot": "weapon", "weapon_type": "smg", "sell": 110, "damage": 0.787, "attack": 0.75, "description": "Cadencia alta, impacto bajo."},
    "deagle_common": {"name": "Desert Eagle", "rarity": "common", "slot": "weapon", "weapon_type": "deagle", "sell": 9, "damage": 2.500, "attack": -0.42, "description": "Un disparo lento y devastador."},
    "deagle_rare": {"name": "Desert Eagle", "rarity": "rare", "slot": "weapon", "weapon_type": "deagle", "sell": 22, "damage": 3.375, "attack": -0.42, "description": "Un disparo lento y devastador."},
    "deagle_epic": {"name": "Desert Eagle", "rarity": "epic", "slot": "weapon", "weapon_type": "deagle", "sell": 52, "damage": 4.375, "attack": -0.42, "description": "Un disparo lento y devastador."},
    "deagle_legendary": {"name": "Desert Eagle", "rarity": "legendary", "slot": "weapon", "weapon_type": "deagle", "sell": 110, "damage": 5.625, "attack": -0.42, "description": "Un disparo lento y devastador."},
    "clock": {"name": "Reloj Impaciente", "rarity": "common", "slot": "charm", "sell": 6, "attack": 0.08, "description": "Le adelanta la hora a tus ataques."},
    "dice": {"name": "Dado de Bolsillo", "rarity": "common", "slot": "charm", "sell": 7, "crit": 0.03, "health": 3, "description": "La fortuna se lleva cerca."},
    "metronome": {"name": "Metrónomo Tramposo", "rarity": "rare", "slot": "charm", "sell": 18, "attack": 0.17, "crit": 0.03, "description": "Nunca respeta su propio ritmo."},
    "hourglass": {"name": "Reloj del Último Segundo", "rarity": "epic", "slot": "charm", "sell": 45, "attack": 0.25, "speed": 0.05, "description": "Un instante más para decidir."},
    "house": {"name": "Corazón de la Casa", "rarity": "legendary", "slot": "charm", "sell": 100, "attack": 0.33, "crit": 0.08, "health": 12, "description": "La casa siempre gana. Casi siempre."},
    "croupier_blade": {"name": "Baraja del Croupier", "rarity": "boss", "slot": "weapon", "sell": 60, "damage": 2, "description": "Arma garantizada del primer jefe."},
    # BLACK JACK: 16 piezas preservadas.
    "bj_helmet_common": {"name": "Casco BLACK JACK", "rarity": "common", "slot": "helmet", "set_id": "black_jack", "set_piece": "helmet", "sell": 7, "description": "Guiado leve para una lluvia de disparos."},
    "bj_chest_common": {"name": "Pecho BLACK JACK", "rarity": "common", "slot": "chest", "set_id": "black_jack", "set_piece": "chest", "sell": 7, "description": "Potencia moderada y parry oportunista."},
    "bj_legs_common": {"name": "Pantalones BLACK JACK", "rarity": "common", "slot": "legs", "set_id": "black_jack", "set_piece": "legs", "sell": 7, "description": "Cadencia y daño crítico, no crítico garantizado."},
    "bj_boots_common": {"name": "Botas BLACK JACK", "rarity": "common", "slot": "boots", "set_id": "black_jack", "set_piece": "boots", "sell": 7, "description": "Movilidad y evasión sin invulnerabilidad."},
    "bj_helmet_rare": {"name": "Casco BLACK JACK", "rarity": "rare", "slot": "helmet", "set_id": "black_jack", "set_piece": "helmet", "sell": 18, "description": "Guiado leve para una lluvia de disparos."},
    "bj_chest_rare": {"name": "Pecho BLACK JACK", "rarity": "rare", "slot": "chest", "set_id": "black_jack", "set_piece": "chest", "sell": 18, "description": "Potencia moderada y parry oportunista."},
    "bj_legs_rare": {"name": "Pantalones BLACK JACK", "rarity": "rare", "slot": "legs", "set_id": "black_jack", "set_piece": "legs", "sell": 18, "description": "Cadencia y daño crítico, no crítico garantizado."},
    "bj_boots_rare": {"name": "Botas BLACK JACK", "rarity": "rare", "slot": "boots", "set_id": "black_jack", "set_piece": "boots", "sell": 18, "description": "Movilidad y evasión sin invulnerabilidad."},
    "bj_helmet_epic": {"name": "Casco BLACK JACK", "rarity": "epic", "slot": "helmet", "set_id": "black_jack", "set_piece": "helmet", "sell": 45, "description": "Guiado leve para una lluvia de disparos."},
    "bj_chest_epic": {"name": "Pecho BLACK JACK", "rarity": "epic", "slot": "chest", "set_id": "black_jack", "set_piece": "chest", "sell": 45, "description": "Potencia moderada y parry oportunista."},
    "bj_legs_epic": {"name": "Pantalones BLACK JACK", "rarity": "epic", "slot": "legs", "set_id": "black_jack", "set_piece": "legs", "sell": 45, "description": "Cadencia y daño crítico, no crítico garantizado."},
    "bj_boots_epic": {"name": "Botas BLACK JACK", "rarity": "epic", "slot": "boots", "set_id": "black_jack", "set_piece": "boots", "sell": 45, "description": "Movilidad y evasión sin invulnerabilidad."},
    "bj_helmet_legendary": {"name": "Casco BLACK JACK", "rarity": "legendary", "slot": "helmet", "set_id": "black_jack", "set_piece": "helmet", "sell": 100, "description": "Guiado leve para una lluvia de disparos."},
    "bj_chest_legendary": {"name": "Pecho BLACK JACK", "rarity": "legendary", "slot": "chest", "set_id": "black_jack", "set_piece": "chest", "sell": 100, "description": "Potencia moderada y parry oportunista."},
    "bj_legs_legendary": {"name": "Pantalones BLACK JACK", "rarity": "legendary", "slot": "legs", "set_id": "black_jack", "set_piece": "legs", "sell": 100, "description": "Cadencia y daño crítico, no crítico garantizado."},
    "bj_boots_legendary": {"name": "Botas BLACK JACK", "rarity": "legendary", "slot": "boots", "set_id": "black_jack", "set_piece": "boots", "sell": 100, "description": "Movilidad y evasión sin invulnerabilidad."},
    # TRAGAPERRAS y JACKPOT: 2 × 4 ranuras × 4 rarezas = 32 nuevas piezas.
    "tp_helmet_common": {"name": "Casco TRAGAPERRAS", "rarity": "common", "slot": "helmet", "set_id": "tragaperras", "set_piece": "helmet", "sell": 7, "description": "Movimiento seguro y puntería estable."},
    "tp_chest_common": {"name": "Pecho TRAGAPERRAS", "rarity": "common", "slot": "chest", "set_id": "tragaperras", "set_piece": "chest", "sell": 7, "description": "Resistencia con golpes ligeros."},
    "tp_legs_common": {"name": "Pantalones TRAGAPERRAS", "rarity": "common", "slot": "legs", "set_id": "tragaperras", "set_piece": "legs", "sell": 7, "description": "Cadencia cómoda para sobrevivir."},
    "tp_boots_common": {"name": "Botas TRAGAPERRAS", "rarity": "common", "slot": "boots", "set_id": "tragaperras", "set_piece": "boots", "sell": 7, "description": "Gran movilidad y evasión."},
    "tp_helmet_rare": {"name": "Casco TRAGAPERRAS", "rarity": "rare", "slot": "helmet", "set_id": "tragaperras", "set_piece": "helmet", "sell": 18, "description": "Movimiento seguro y puntería estable."},
    "tp_chest_rare": {"name": "Pecho TRAGAPERRAS", "rarity": "rare", "slot": "chest", "set_id": "tragaperras", "set_piece": "chest", "sell": 18, "description": "Resistencia con golpes ligeros."},
    "tp_legs_rare": {"name": "Pantalones TRAGAPERRAS", "rarity": "rare", "slot": "legs", "set_id": "tragaperras", "set_piece": "legs", "sell": 18, "description": "Cadencia cómoda para sobrevivir."},
    "tp_boots_rare": {"name": "Botas TRAGAPERRAS", "rarity": "rare", "slot": "boots", "set_id": "tragaperras", "set_piece": "boots", "sell": 18, "description": "Gran movilidad y evasión."},
    "tp_helmet_epic": {"name": "Casco TRAGAPERRAS", "rarity": "epic", "slot": "helmet", "set_id": "tragaperras", "set_piece": "helmet", "sell": 45, "description": "Movimiento seguro y puntería estable."},
    "tp_chest_epic": {"name": "Pecho TRAGAPERRAS", "rarity": "epic", "slot": "chest", "set_id": "tragaperras", "set_piece": "chest", "sell": 45, "description": "Resistencia con golpes ligeros."},
    "tp_legs_epic": {"name": "Pantalones TRAGAPERRAS", "rarity": "epic", "slot": "legs", "set_id": "tragaperras", "set_piece": "legs", "sell": 45, "description": "Cadencia cómoda para sobrevivir."},
    "tp_boots_epic": {"name": "Botas TRAGAPERRAS", "rarity": "epic", "slot": "boots", "set_id": "tragaperras", "set_piece": "boots", "sell": 45, "description": "Gran movilidad y evasión."},
    "tp_helmet_legendary": {"name": "Casco TRAGAPERRAS", "rarity": "legendary", "slot": "helmet", "set_id": "tragaperras", "set_piece": "helmet", "sell": 100, "description": "Movimiento seguro y puntería estable."},
    "tp_chest_legendary": {"name": "Pecho TRAGAPERRAS", "rarity": "legendary", "slot": "chest", "set_id": "tragaperras", "set_piece": "chest", "sell": 100, "description": "Resistencia con golpes ligeros."},
    "tp_legs_legendary": {"name": "Pantalones TRAGAPERRAS", "rarity": "legendary", "slot": "legs", "set_id": "tragaperras", "set_piece": "legs", "sell": 100, "description": "Cadencia cómoda para sobrevivir."},
    "tp_boots_legendary": {"name": "Botas TRAGAPERRAS", "rarity": "legendary", "slot": "boots", "set_id": "tragaperras", "set_piece": "boots", "sell": 100, "description": "Gran movilidad y evasión."},
    "jp_helmet_common": {"name": "Casco JACKPOT", "rarity": "common", "slot": "helmet", "set_id": "jackpot", "set_piece": "helmet", "sell": 7, "description": "Seguimiento agresivo del objetivo."},
    "jp_chest_common": {"name": "Pecho JACKPOT", "rarity": "common", "slot": "chest", "set_id": "jackpot", "set_piece": "chest", "sell": 7, "description": "Impactos devastadores y Parry."},
    "jp_legs_common": {"name": "Pantalones JACKPOT", "rarity": "common", "slot": "legs", "set_id": "jackpot", "set_piece": "legs", "sell": 7, "description": "Pocos disparos muy potentes."},
    "jp_boots_common": {"name": "Botas JACKPOT", "rarity": "common", "slot": "boots", "set_id": "jackpot", "set_piece": "boots", "sell": 7, "description": "Movilidad mínima y defensa puntual."},
    "jp_helmet_rare": {"name": "Casco JACKPOT", "rarity": "rare", "slot": "helmet", "set_id": "jackpot", "set_piece": "helmet", "sell": 18, "description": "Seguimiento agresivo del objetivo."},
    "jp_chest_rare": {"name": "Pecho JACKPOT", "rarity": "rare", "slot": "chest", "set_id": "jackpot", "set_piece": "chest", "sell": 18, "description": "Impactos devastadores y Parry."},
    "jp_legs_rare": {"name": "Pantalones JACKPOT", "rarity": "rare", "slot": "legs", "set_id": "jackpot", "set_piece": "legs", "sell": 18, "description": "Pocos disparos muy potentes."},
    "jp_boots_rare": {"name": "Botas JACKPOT", "rarity": "rare", "slot": "boots", "set_id": "jackpot", "set_piece": "boots", "sell": 18, "description": "Movilidad mínima y defensa puntual."},
    "jp_helmet_epic": {"name": "Casco JACKPOT", "rarity": "epic", "slot": "helmet", "set_id": "jackpot", "set_piece": "helmet", "sell": 45, "description": "Seguimiento agresivo del objetivo."},
    "jp_chest_epic": {"name": "Pecho JACKPOT", "rarity": "epic", "slot": "chest", "set_id": "jackpot", "set_piece": "chest", "sell": 45, "description": "Impactos devastadores y Parry."},
    "jp_legs_epic": {"name": "Pantalones JACKPOT", "rarity": "epic", "slot": "legs", "set_id": "jackpot", "set_piece": "legs", "sell": 45, "description": "Pocos disparos muy potentes."},
    "jp_boots_epic": {"name": "Botas JACKPOT", "rarity": "epic", "slot": "boots", "set_id": "jackpot", "set_piece": "boots", "sell": 45, "description": "Movilidad mínima y defensa puntual."},
    "jp_helmet_legendary": {"name": "Casco JACKPOT", "rarity": "legendary", "slot": "helmet", "set_id": "jackpot", "set_piece": "helmet", "sell": 100, "description": "Seguimiento agresivo del objetivo."},
    "jp_chest_legendary": {"name": "Pecho JACKPOT", "rarity": "legendary", "slot": "chest", "set_id": "jackpot", "set_piece": "chest", "sell": 100, "description": "Impactos devastadores y Parry."},
    "jp_legs_legendary": {"name": "Pantalones JACKPOT", "rarity": "legendary", "slot": "legs", "set_id": "jackpot", "set_piece": "legs", "sell": 100, "description": "Pocos disparos muy potentes."},
    "jp_boots_legendary": {"name": "Botas JACKPOT", "rarity": "legendary", "slot": "boots", "set_id": "jackpot", "set_piece": "boots", "sell": 100, "description": "Movilidad mínima y defensa puntual."},
}

const RARITY_NAMES := {"common": "COMÚN", "rare": "RARO", "epic": "ÉPICO", "legendary": "LEGENDARIO", "boss": "JEFE"}
const RARITY_COLORS := {"common": "#b6d3c6", "rare": "#7aa8ff", "epic": "#db83ff", "legendary": "#f5c25e", "boss": "#e8b493"}
const SLOT_NAMES := {"helmet": "Casco", "chest": "Pecho", "legs": "Pantalones", "boots": "Botas", "charm": "Amuleto", "weapon": "Arma"}
const SLOT_ORDER := ["helmet", "chest", "legs", "boots", "charm", "weapon"]

# El nivel comienza en 1: subir al nivel 3 común necesita 3 ejemplares en total.
# Las armas de jefe son recompensas especiales y no se fusionan.
const LEVEL_CAPS := {"common": 3, "rare": 4, "epic": 5, "legendary": 7, "boss": 1}
const NEXT_RARITY := {"common": "rare", "rare": "epic", "epic": "legendary"}
const RARITY_ORDER: Array[String] = ["common", "rare", "epic", "legendary"]
const POWER_WEIGHTS := {"damage": 8.0, "health": 0.15, "armor": 2.0, "speed": 60.0, "attack": 55.0, "crit": 45.0, "accuracy": 35.0, "damage_pct": 80.0, "crit_damage": 40.0, "evasion": 70.0, "parry": 80.0}

# Armaduras BLACK JACK: progresión suave por nivel sin multiplicadores heredados.
# Un valor de 0.10 significa +10% o 10% de probabilidad, según el atributo.
# Parry/evasión arrancan en 5%; el techo GLOBAL para futuros conjuntos será 20%,
# pero BLACK JACK se queda en 10% para reservar la defensa como especialidad ajena.
const BLACK_JACK_STAT_RANGES := {
    "helmet": {
        "accuracy": {"common": [0.05, 0.07], "rare": [0.08, 0.10], "epic": [0.11, 0.13], "legendary": [0.14, 0.16]}
    },
    "chest": {
        "damage_pct": {"common": [0.02, 0.03], "rare": [0.04, 0.05], "epic": [0.06, 0.08], "legendary": [0.09, 0.10]},
        "parry": {"common": [0.05, 0.06], "rare": [0.065, 0.075], "epic": [0.08, 0.09], "legendary": [0.095, 0.10]}
    },
    "legs": {
        "attack": {"common": [0.02, 0.04], "rare": [0.05, 0.07], "epic": [0.08, 0.12], "legendary": [0.14, 0.20]},
        "crit_damage": {"common": [0.04, 0.06], "rare": [0.065, 0.08], "epic": [0.085, 0.10], "legendary": [0.105, 0.12]}
    },
    "boots": {
        "speed": {"common": [0.02, 0.03], "rare": [0.04, 0.05], "epic": [0.055, 0.065], "legendary": [0.07, 0.08]},
        "evasion": {"common": [0.05, 0.06], "rare": [0.065, 0.075], "epic": [0.08, 0.09], "legendary": [0.095, 0.10]}
    }
}


# Estadísticas de los nuevos sets (Nv.1 -> máximo por rareza).
const TRAGAPERRAS_STAT_RANGES := {
    "helmet": {
        "accuracy": {"common": [0.04, 0.06], "rare": [0.07, 0.09], "epic": [0.1, 0.12], "legendary": [0.13, 0.15]},
    },
    "chest": {
        "damage_pct": {"common": [0.01, 0.025], "rare": [0.03, 0.04], "epic": [0.045, 0.055], "legendary": [0.055, 0.06]},
        "parry": {"common": [0.05, 0.06], "rare": [0.065, 0.08], "epic": [0.085, 0.1], "legendary": [0.11, 0.12]},
    },
    "legs": {
        "attack": {"common": [0.015, 0.025], "rare": [0.025, 0.04], "epic": [0.04, 0.06], "legendary": [0.065, 0.08]},
        "crit_damage": {"common": [0.02, 0.03], "rare": [0.035, 0.045], "epic": [0.05, 0.065], "legendary": [0.065, 0.08]},
    },
    "boots": {
        "speed": {"common": [0.04, 0.06], "rare": [0.065, 0.09], "epic": [0.1, 0.14], "legendary": [0.15, 0.2]},
        "evasion": {"common": [0.05, 0.07], "rare": [0.08, 0.11], "epic": [0.12, 0.16], "legendary": [0.17, 0.2]},
    },
}

const JACKPOT_STAT_RANGES := {
    "helmet": {
        "accuracy": {"common": [0.08, 0.1], "rare": [0.11, 0.14], "epic": [0.15, 0.18], "legendary": [0.2, 0.24]},
    },
    "chest": {
        "damage_pct": {"common": [0.07, 0.1], "rare": [0.11, 0.15], "epic": [0.16, 0.2], "legendary": [0.21, 0.25]},
        "parry": {"common": [0.05, 0.07], "rare": [0.08, 0.11], "epic": [0.12, 0.16], "legendary": [0.17, 0.2]},
    },
    "legs": {
        "attack": {"common": [-0.04, -0.05], "rare": [-0.06, -0.08], "epic": [-0.09, -0.11], "legendary": [-0.12, -0.15]},
        "crit_damage": {"common": [0.06, 0.09], "rare": [0.1, 0.16], "epic": [0.17, 0.26], "legendary": [0.27, 0.35]},
    },
    "boots": {
        "speed": {"common": [0.01, 0.025], "rare": [0.025, 0.035], "epic": [0.035, 0.045], "legendary": [0.045, 0.05]},
        "evasion": {"common": [0.05, 0.06], "rare": [0.065, 0.07], "epic": [0.075, 0.08], "legendary": [0.08, 0.08]},
    },
}

const ARMOR_SET_RANGES := {"black_jack": BLACK_JACK_STAT_RANGES, "tragaperras": TRAGAPERRAS_STAT_RANGES, "jackpot": JACKPOT_STAT_RANGES}
const ARMOR_SET_PREFIXES := {"black_jack": "bj", "tragaperras": "tp", "jackpot": "jp"}

static func black_jack_stat_ranges(slot: String, stat: String, rarity: String) -> Array:
    var slot_data: Dictionary = BLACK_JACK_STAT_RANGES.get(slot, {})
    var stat_data: Dictionary = slot_data.get(stat, {})
    return stat_data.get(rarity, [])

static func get_set_stats(item_id: String, level: int, rarity_override: String = "") -> Dictionary:
    var definition: Dictionary = get_def(item_id)
    var set_id: String = str(definition.get("set_id", ""))
    var slot: String = str(definition.get("set_piece", ""))
    var rarity: String = rarity_override if rarity_override != "" else str(definition.get("rarity", "common"))
    var cap: int = level_cap(item_id, rarity)
    var fraction: float = float(clampi(level, 1, cap) - 1) / float(maxi(1, cap - 1))
    var values: Dictionary = {}
    var set_ranges: Dictionary = ARMOR_SET_RANGES.get(set_id, {})
    var slot_ranges: Dictionary = set_ranges.get(slot, {})
    for stat in slot_ranges.keys():
        var ranges: Dictionary = slot_ranges[stat]
        var bounds: Array = ranges.get(rarity, [])
        if bounds.size() != 2:
            continue
        var value: float = lerpf(float(bounds[0]), float(bounds[1]), fraction)
        # 4.28: reforzar principalmente las rarezas bajas. Las penalizaciones
        # (JACKPOT) no empeoran al subir de categoría.
        var relative_buff: float = float({"common": 1.20, "rare": 1.15, "epic": 1.10, "legendary": 1.05}.get(rarity, 1.0))
        if value > 0.0:
            value *= relative_buff
        if str(stat) in ["evasion", "parry"]:
            value = minf(0.20, value)
        values[stat] = value
    return values

static func get_black_jack_stats(item_id: String, level: int, rarity_override: String = "") -> Dictionary:
    return get_set_stats(item_id, level, rarity_override)

static func get_def(item_id: String) -> Dictionary:
    return ITEM_DEFS.get(item_id, {})

static func is_black_jack_armor(item_id: String) -> bool:
    return str(get_def(item_id).get("set_id", "")) == "black_jack"

static func is_set_armor(item_id: String) -> bool:
    return ARMOR_SET_PREFIXES.has(str(get_def(item_id).get("set_id", "")))

static func armor_origin_id(item_id: String) -> String:
    var data: Dictionary = get_def(item_id)
    var prefix: String = str(ARMOR_SET_PREFIXES.get(str(data.get("set_id", "")), ""))
    if prefix == "":
        return item_id
    return "%s_%s_common" % [prefix, str(data["set_piece"])]

static func ascended_item_id(item_id: String) -> String:
    var data: Dictionary = get_def(item_id)
    var rarity: String = str(data.get("rarity", ""))
    if not NEXT_RARITY.has(rarity):
        return ""
    var prefix: String = str(ARMOR_SET_PREFIXES.get(str(data.get("set_id", "")), ""))
    if prefix != "":
        return "%s_%s_%s" % [prefix, str(data["set_piece"]), str(NEXT_RARITY[rarity])]
    if str(data.get("weapon_type", "")) != "":
        return "%s_%s" % [str(data["weapon_type"]), str(NEXT_RARITY[rarity])]
    # Los amuletos antiguos conservan su identidad.
    return item_id

static func level_cap(item_id: String, rarity_override: String = "") -> int:
    var definition: Dictionary = get_def(item_id)
    var rarity: String = rarity_override if rarity_override != "" else str(definition.get("rarity", "boss"))
    return int(LEVEL_CAPS.get(rarity, 1))

static func _score_positive(definition: Dictionary) -> float:
    var score: float = 0.0
    for stat in POWER_WEIGHTS.keys():
        score += maxf(0.0, float(definition.get(stat, 0.0))) * float(POWER_WEIGHTS[stat])
    return score

static func _score_negative(definition: Dictionary) -> float:
    var score: float = 0.0
    for stat in POWER_WEIGHTS.keys():
        score += minf(0.0, float(definition.get(stat, 0.0))) * float(POWER_WEIGHTS[stat])
    return score

static func get_upgrade_multiplier(item_id: String, level: int = 1, rarity_override: String = "") -> float:
    var definition: Dictionary = get_def(item_id)
    if not definition.is_empty() and str(definition.get("weapon_type", "")) != "":
        # No comparar subfusiles contra Desert Eagle: cada arquetipo evoluciona
        # con su propio rendimiento y la rareza controla su potencia inicial.
        return 1.0 + 0.18 * float(clampi(level, 1, level_cap(item_id, rarity_override)) - 1)
    # Las 16 variantes BLACK JACK conservan exactamente la fórmula original
    # de mejora por familia al subir rareza; no se reinicia el poder adquirido.
    var origin: String = armor_origin_id(item_id)
    if origin != item_id:
        var active_rarity: String = rarity_override if rarity_override != "" else str(definition.get("rarity", ""))
        return get_upgrade_multiplier(origin, level, active_rarity)
    var base_rarity: String = str(definition.get("rarity", ""))
    var rarity: String = rarity_override if rarity_override != "" else base_rarity
    var cap: int = level_cap(item_id, rarity)
    if definition.is_empty() or cap <= 1:
        return 1.0
    var actual_level: int = clampi(level, 1, cap)
    # Ascensión mínima: conserva ID/identidad, incrementa la categoría y reinicia Lv.1.
    # Lv.1 ascendido supera ligeramente al máximo de la rareza anterior.
    if rarity != base_rarity:
        var start: int = RARITY_ORDER.find(base_rarity)
        var finish: int = RARITY_ORDER.find(rarity)
        if start < 0 or finish <= start:
            return 1.0
        var inherited_power: float = 1.0
        for index in range(start, finish):
            var previous_rarity: String = RARITY_ORDER[index]
            var prev_cap: int = int(LEVEL_CAPS[previous_rarity])
            var previous_end: float = get_upgrade_multiplier(item_id, prev_cap) if index == start else 1.0 + 0.42 * float(prev_cap - 1)
            inherited_power *= previous_end * 1.08
        var upgraded_end: float = 1.0 + 0.42 * float(cap - 1)
        var ascended_ratio: float = float(actual_level - 1) / float(cap - 1)
        return inherited_power * lerpf(1.0, upgraded_end, ascended_ratio)
    # Una pieza al máximo supera, en potencia ponderada del MISMO espacio,
    # incluso a la mejor pieza base de la rareza superior.
    # El tipo de efecto puede seguir haciendo preferible otra pieza para una build.
    var own_positive: float = _score_positive(definition)
    var own_negative: float = _score_negative(definition)
    var minimum_end: float = 2.55 if rarity == "legendary" else 1.0 + 0.42 * float(cap - 1)
    var multiplier_at_cap: float = minimum_end
    if NEXT_RARITY.has(rarity) and own_positive > 0.0:
        var next_rarity: String = str(NEXT_RARITY[rarity])
        var strongest_next: float = 0.0
        for id in ITEM_DEFS.keys():
            var next_def: Dictionary = ITEM_DEFS[id]
            if str(next_def.get("slot", "")) != str(definition.get("slot", "")):
                continue
            if str(next_def.get("rarity", "")) != next_rarity:
                continue
            strongest_next = maxf(strongest_next, _score_positive(next_def) + _score_negative(next_def))
        # 10% de margen sobre el mejor artículo del siguiente escalón, al máximo.
        multiplier_at_cap = maxf(multiplier_at_cap, (strongest_next * 1.10 - own_negative) / own_positive)
    var ratio: float = float(actual_level - 1) / float(cap - 1)
    return lerpf(1.0, multiplier_at_cap, ratio)

static func get_upgraded_stats(item_id: String, level: int = 1, rarity_override: String = "") -> Dictionary:
    # El rework BLACK JACK usa rangos por rareza y nivel. Mantiene idénticas
    # reglas de duplicados, topes, precios y transición de ascensión.
    if is_set_armor(item_id):
        return get_set_stats(item_id, level, rarity_override)
    # Las estadísticas parten de la misma pieza de origen; al ascender solo
    # cambia el escalón de rareza y el nivel, nunca su identidad de conjunto.
    var definition: Dictionary = get_def(armor_origin_id(item_id))
    var result: Dictionary = {}
    if definition.is_empty():
        return result
    var multiplier: float = get_upgrade_multiplier(item_id, level, rarity_override)
    for stat in POWER_WEIGHTS.keys():
        var base: float = float(definition.get(stat, 0.0))
        # Los penalizadores no aumentan al mejorar un objeto.
        var upgraded: float = base * multiplier if base > 0.0 else base
        # Daño y armadura son puntos ENTEROS en juego: redondeamos hacia arriba
        # para que la fusión siempre conceda una mejora tangible.
        if base > 0.0 and stat in ["damage", "health", "armor"] and not definition.has("weapon_type"):
            upgraded = float(ceili(upgraded - 0.00001))
        result[stat] = upgraded
    return result

static func power_score(item_id: String, level: int = 1, rarity_override: String = "") -> float:
    var upgraded: Dictionary = get_upgraded_stats(item_id, level, rarity_override)
    return _score_positive(upgraded) + _score_negative(upgraded)

static func roll_id(rarity: String) -> String:
    # 4.31: categoria primero, 65% armaduras / 23% armas / 12% amuletos.
    # Los pesos son POR CATEGORIA, no por cantidad total de modelos; asi el
    # sistema escalará a 7 sets, 10 armas y más amuletos sin desplazar clases.
    var armors: Array[String] = []
    var weapons: Array[String] = []
    var charms: Array[String] = []
    for key in ITEM_DEFS.keys():
        var data: Dictionary = ITEM_DEFS[key]
        if str(data.get("rarity", "")) != rarity:
            continue
        if is_set_armor(str(key)):
            armors.append(str(key))
        elif str(data.get("weapon_type", "")) != "":
            weapons.append(str(key))
        elif str(data.get("slot", "")) == "charm":
            charms.append(str(key))
    # Un solo sorteo evita que la cuota se altere al aumentar el catalogo.
    var category_roll: float = randf()
    if category_roll < 0.65 and not armors.is_empty():
        return armors.pick_random()
    if category_roll < 0.88 and not weapons.is_empty():
        return weapons.pick_random()
    if not charms.is_empty():
        return charms.pick_random()
    if not weapons.is_empty():
        return weapons.pick_random()
    return armors.pick_random() if not armors.is_empty() else ""

static func enemy_quality_rarity_for_roll(room_number: int, raw_roll: int) -> String:
    # Calidad sólo dentro del tramo de tirada no común de enemigos.
    # Rareza rara progresiva, épicos del suelo desde 40, legendario desde 56.
    var roll: int = clampi(raw_roll, 0, 9999)
    if room_number <= 14:
        return "common"
    if room_number <= 20:
        return "rare" if roll >= 9200 else "common"  # 8% de calidad
    if room_number <= 30:
        return "rare" if roll >= 8000 else "common"  # 20%
    if room_number <= 39:
        return "rare" if roll >= 6500 else "common"  # 35%
    if room_number <= 55:
        if roll < 4800:
            return "common"
        return "rare" if roll < 9000 else "epic"  # 4.31: 10% epicas (antes 6%)
    if roll < 4000:
        return "common"
    if roll < 8600:
        return "rare"
    return "epic" if roll < 9900 else "legendary"

static func roll_drop_rarity(room_number: int = 1) -> String:
    return enemy_quality_rarity_for_roll(room_number, randi_range(0, 9999))

static func stat_text(item_id: String, level: int = 1, rarity_override: String = "") -> String:
    var item: Dictionary = get_def(item_id)
    if item.is_empty():
        return "Sin atributo"
    var upgraded: Dictionary = get_upgraded_stats(item_id, level, rarity_override)
    var parts: PackedStringArray = PackedStringArray()
    if str(item.get("weapon_type", "")) != "":
        var weapon_type: String = str(item["weapon_type"])
        var pellets: int = 3 if weapon_type == "shotgun" else 1
        var reach: int = int({"pistol": 750, "shotgun": 250, "smg": 590, "deagle": 840}.get(weapon_type, 750))
        return "Daño arma +%.2f · cadencia %+.0f%% · %d perdigón(es) · alcance %d" % [float(upgraded.get("damage", 0.0)), float(upgraded.get("attack", 0.0)) * 100.0, pellets, reach]
    if is_set_armor(item_id):
        var labels: Dictionary = {"accuracy": "precisión/guía", "damage_pct": "daño", "parry": "parry", "attack": "cadencia", "crit_damage": "daño crítico", "speed": "movilidad", "evasion": "evasión"}
        for stat in ["accuracy", "damage_pct", "parry", "attack", "crit_damage", "speed", "evasion"]:
            if upgraded.has(stat):
                parts.append("%+.1f%% %s" % [float(upgraded[stat]) * 100.0, str(labels[stat])])
        return " | ".join(parts)
    for stat in ["damage", "health", "armor"]:
        var value: float = float(upgraded.get(stat, 0.0))
        if not is_zero_approx(value):
            var label: String = {"damage": "daño", "health": "resistencia", "armor": "armadura"}[stat]
            parts.append("%+d %s" % [int(round(value)), label])
    for stat in ["speed", "attack", "crit"]:
        var value: float = float(upgraded.get(stat, 0.0))
        if not is_zero_approx(value):
            var label: String = {"speed": "velocidad", "attack": "cadencia", "crit": "crítico"}[stat]
            parts.append("%+d%% %s" % [int(round(value * 100.0)), label])
    if item.has("chain"):
        parts.append("RAYOS EN CADENA")
    return " | ".join(parts) if not parts.is_empty() else "Sin atributo"
