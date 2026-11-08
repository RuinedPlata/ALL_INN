extends CharacterBody2D

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/Projectile.tscn")

# ALL IN 4.31.20 (variante C v2): sprites dibujados de dolor y equilibrio.
# Filas 0..7 idle; 8..15 caminata; 16..23 dano C v2 (4 poses/direccion).
# Dano ligado a hurt_cooldown ya existente. No hay otro temporizador.
# Los ojos se cierran, aprieta dientes y levanta una pierna hasta terminar
# la invulnerabilidad; luego vuelve al idle/caminata inmediatamente.
# Armas como capa visual independiente; no se cambia movimiento ni hitbox.
const BODY_ATLAS: Texture2D = preload("res://assets/player/skins/apostador/idle_8dir.png")
# Muertes desde la hoja de referencia aprobada: dos atlas limpios 4x2,
# misma celda y proporciones, sin sprites ni tiempos de muerte duplicados.
const BODY_DEATH_FACE_ATLAS: Texture2D = preload("res://assets/player/skins/apostador/death_face_4x2.png")
const BODY_DEATH_BACK_ATLAS: Texture2D = preload("res://assets/player/skins/apostador/death_back_4x2.png")
const BODY_DEATH_CELL: int = 96
const BODY_DEATH_COLUMNS: int = 4
const BODY_CELL: int = 64
const BODY_IDLE_FPS: float = 4.0
const BODY_WALK_FPS: float = 9.0
const BODY_WALK_FIRST_ROW: int = 8
const BODY_HURT_FIRST_ROW: int = 16
const BODY_HIT_RED_SECONDS: float = 0.10

const WEAPON_CELL: int = 48
const PISTOL_CELL: int = 32  # Pistola aprobada (4.31.33), no modificar.
const SHOTGUN_CELL: int = 32 # La ilustración ocupa aprox. 10-20% más dentro de la celda.
const SMG_CELL: int = 32     # Uzi con cargador extendido, 8 direcciones, 4 rarezas.
# Escopeta brújula 4.31.34: sólo visual; conserva proyectiles, daño y colisiones.
# Usa los mismos ocho índices de la pistola y su propio estado de seguimiento.
const SHOTGUN_ORBIT_RADIUS_X: float = 32.0
const SHOTGUN_ORBIT_RADIUS_Y: float = 30.0
# 4.31.35: subfusil flotante; conserva independientes la pistola y escopeta.
const SMG_ORBIT_RADIUS_X: float = 33.0
const SMG_ORBIT_RADIUS_Y: float = 31.0
# PISTOLA BRÚJULA 4.31.30: posición flotante independiente de las manos.
# Offset ligado a visual_direction (apuntado real), no a la caminata.
# La textura usa ocho ángulos discretos: evita rotar/alisar píxeles.
const PISTOL_ORBIT_CENTER: Vector2 = Vector2(0.0, -7.0)
const PISTOL_ORBIT_RADIUS_X: float = 31.0
const PISTOL_ORBIT_RADIUS_Y: float = 29.0
const PISTOL_ORBIT_FOLLOW: float = 13.0
const PISTOL_FLOAT_AMPLITUDE: float = 0.6
const PISTOL_FLOAT_SPEED: float = 5.0
# Reserva media celda más un píxel para que el sprite no se recorte en paredes.
const PISTOL_ARENA_MARGIN: float = 17.0 # 32/2 + 1
# Ajuste fino 4.31.31: corrección puntual para la dirección 3 (arriba-izquierda).
# La pistola sigue flotando libre, pero se desplaza unos píxeles para no invadir
# visualmente el cabello/cara en esa pose concreta.
const PISTOL_DIRECTION_NUDGES: Array[Vector2] = [
    Vector2.ZERO,
    Vector2.ZERO,
    Vector2.ZERO,
    Vector2(-4.0, -2.0),
    Vector2.ZERO,
    Vector2.ZERO,
    Vector2.ZERO,
    Vector2.ZERO
]
const WEAPON_SCALE: Vector2 = Vector2(0.90, 0.90)
const WEAPON_OFFSETS: Array[Vector2] = [
    Vector2(8.0, -1.0),   # abajo
    Vector2(2.0, -1.0),   # abajo-izquierda
    Vector2(-8.0, -4.0),  # izquierda
    Vector2(-7.0, -10.0), # arriba-izquierda
    Vector2(0.0, -15.0),  # arriba
    Vector2(7.0, -10.0),  # arriba-derecha
    Vector2(10.0, -4.0),  # derecha
    Vector2(5.0, -1.0)    # abajo-derecha
]
const WEAPON_BEHIND_DIRECTIONS := {3: true, 4: true, 5: true}
const WEAPON_ATLAS_PATHS := {
    "pistol_common": "res://assets/player/weapons/pistol_common_8dir.png",
    "pistol_rare": "res://assets/player/weapons/pistol_rare_8dir.png",
    "pistol_epic": "res://assets/player/weapons/pistol_epic_8dir.png",
    "pistol_legendary": "res://assets/player/weapons/pistol_legendary_8dir.png",
    "shotgun_common": "res://assets/player/weapons/shotgun_common_8dir.png",
    "shotgun_rare": "res://assets/player/weapons/shotgun_rare_8dir.png",
    "shotgun_epic": "res://assets/player/weapons/shotgun_epic_8dir.png",
    "shotgun_legendary": "res://assets/player/weapons/shotgun_legendary_8dir.png",
    "smg_common": "res://assets/player/weapons/smg_common_8dir.png",
    "smg_rare": "res://assets/player/weapons/smg_rare_8dir.png",
    "smg_epic": "res://assets/player/weapons/smg_epic_8dir.png",
    "smg_legendary": "res://assets/player/weapons/smg_legendary_8dir.png",
    "deagle_common": "res://assets/player/weapons/deagle_common_8dir.png",
    "deagle_rare": "res://assets/player/weapons/deagle_rare_8dir.png",
    "deagle_epic": "res://assets/player/weapons/deagle_epic_8dir.png",
    "deagle_legendary": "res://assets/player/weapons/deagle_legendary_8dir.png"
}

@onready var body_sprite: Sprite2D = $BodySprite
@onready var weapon_sprite: Sprite2D = $WeaponSprite
var sprite_elapsed: float = 0.0
var _weapon_texture_cache: Dictionary = {}
var _pistol_orbit_position: Vector2 = Vector2.ZERO
var _pistol_orbit_initialized: bool = false
var _shotgun_orbit_position: Vector2 = Vector2.ZERO
var _shotgun_orbit_initialized: bool = false
var _smg_orbit_position: Vector2 = Vector2.ZERO
var _smg_orbit_initialized: bool = false
var visual_direction: Vector2 = Vector2.DOWN
var visual_target_time: float = 0.0
var hurt_iframe_duration: float = 1.25
# No mostrar dolor cuando el golpe fue bloqueado/evadido. El cooldown
# de contacto se conserva para no cambiar el balance defensivo existente.
var hurt_visual_active: bool = false
# El joystick se crea despues del jugador; cache perezosa para no buscar
# el grupo completo 60 veces por segundo en Android.
var _touch_stick: Variant = null
var hurt_direction_index: int = 0
var death_cinematic_active: bool = false
var death_cinematic_variant: int = 0 # 0 = cara; 1 = espaldas

@export var move_speed: float = 188.0 # 20% menos que 235
@export var attack_interval: float = 0.75

var attack_timer: float = 0.0
var facing: Vector2 = Vector2.RIGHT
var hurt_cooldown: float = 0.0
var attack_count: int = 0
var jackpot_charged: bool = false

func _ready() -> void:
    _add_key_action("move_up", KEY_W)
    _add_key_action("move_up", KEY_UP)
    _add_key_action("move_down", KEY_S)
    _add_key_action("move_down", KEY_DOWN)
    _add_key_action("move_left", KEY_A)
    _add_key_action("move_left", KEY_LEFT)
    _add_key_action("move_right", KEY_D)
    _add_key_action("move_right", KEY_RIGHT)
    add_to_group("player")
    RunManager.parry_triggered.connect(_on_parry_triggered)
    body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    body_sprite.region_enabled = true
    body_sprite.offset = Vector2(0.0, -7.0)
    body_sprite.texture = BODY_ATLAS
    weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    weapon_sprite.region_enabled = true
    weapon_sprite.scale = WEAPON_SCALE
    weapon_sprite.centered = true
    weapon_sprite.visible = true
    _update_body_sprite()
    _update_weapon_sprite(0.0)


func _add_key_action(action_name: String, keycode: Key) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)
    var key_event := InputEventKey.new()
    key_event.keycode = keycode
    if not InputMap.action_has_event(action_name, key_event):
        InputMap.action_add_event(action_name, key_event)

func _physics_process(delta: float) -> void:
    if not RunManager.run_active or get_tree().paused:
        velocity = Vector2.ZERO
        return
    var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if not is_instance_valid(_touch_stick):
        _touch_stick = get_tree().get_first_node_in_group("mobile_joystick")
    # Teclado tiene prioridad: un joystick que quedó activo no secuestra WASD.
    if input_vector.length() < 0.10 and _touch_stick != null:
        var stick_direction: Vector2 = _touch_stick.get_direction()
        if stick_direction.length() > 0.12:
            input_vector = stick_direction
    input_vector = input_vector.limit_length(1.0)
    if input_vector.length() > 0.1:
        facing = input_vector.normalized()
        if visual_target_time <= 0.0:
            visual_direction = facing
    var curse_multiplier := 0.7 if RunManager.curse_remaining > 0.0 else 1.0
    var speed_bonus: float = RunManager.speed_bonus + RunManager.level_speed_bonus + InventoryManager.get_equipped_bonus("speed") + PactManager.get_stat("speed")
    # Un equipo con velocidad negativa no debe inmovilizar por completo al jugador.
    velocity = input_vector * move_speed * maxf(0.65, 1.0 + speed_bonus) * curse_multiplier
    move_and_slide()
    # No permitimos escapar de la arena visible: el juego aún no tiene cámara.
    var arena: Rect2 = RunManager.arena_rect
    global_position = global_position.clamp(arena.position + Vector2(29, 29), arena.end - Vector2(29, 29))
    var attack_bonus: float = RunManager.attack_bonus + InventoryManager.get_equipped_bonus("attack") + PactManager.get_stat("attack") + InventoryManager.jackpot_attack_penalty()
    attack_timer += delta
    if attack_timer >= attack_interval / maxf(0.35, 1.0 + attack_bonus):
        attack_timer = 0.0
        _auto_attack()
    hurt_cooldown = maxf(0.0, hurt_cooldown - delta)

func _auto_attack() -> void:
    var target: Node2D = _find_nearest_enemy()
    if target == null:
        return
    attack_count += 1
    # Eco: cada cuarto ataque es reforzado o falla según la apuesta.
    if attack_count % 4 == 0 and PactManager.is_echo_miss():
        return
    var direction: Vector2 = (target.global_position - global_position).normalized()
    # Orientación visual de la misma dirección del disparo real; sin arma falsa.
    visual_direction = direction
    visual_target_time = 0.28
    var base_damage: float = 1.0 + float(RunManager.level_damage_bonus) + InventoryManager.get_equipped_bonus("damage")
    var modifier: float = PactManager.damage_modifier()
    if modifier < 0.0 and randf() < -modifier:
        return
    # Salud enemiga fraccionaria: las bonificaciones pequeñas y las balas
    # BLACK JACK al 70%/45% siempre producen daño real cuando impactan.
    var chest_bonus: float = InventoryManager.get_equipped_bonus("damage_pct")
    var expected_damage: float = calculate_basic_attack_damage(base_damage, RunManager.level_damage_percent_bonus, chest_bonus)
    if modifier > 0.0 and randf() < modifier:
        expected_damage += maxf(1.0, base_damage)
    var crit_chance: float = clampf(InventoryManager.get_equipped_bonus("crit") + PactManager.crit_chance_bonus(), 0.0, 0.65)
    var critical: bool = randf() < crit_chance
    if critical:
        # Pantalones suben el DAÑO de cada crítico, no su probabilidad.
        expected_damage *= 2.0 + InventoryManager.get_equipped_bonus("crit_damage")
    expected_damage *= InventoryManager.jackpot_damage_multiplier()
    if jackpot_charged and InventoryManager.set_tier("jackpot") > 0:
        expected_damage *= InventoryManager.jackpot_charged_multiplier()
        jackpot_charged = false
    elif InventoryManager.set_tier("jackpot") == 0:
        jackpot_charged = false
    _fire_projectile(direction, expected_damage, critical)
    if (attack_count % 4 == 0 and PactManager.is_echo_extra()) or (attack_count % 3 == 0 and PactManager.is_active("ritmo", "overload")):
        _fire_projectile(direction.rotated(0.13), expected_damage, critical)

# Un único cálculo aditivo de daño base: no multiplica de nuevo el bonus
# por proyectil BLACK JACK ni altera la posibilidad de crítico o los pactos.
static func calculate_basic_attack_damage(base_damage: float, level_bonus: float, chest_bonus: float) -> float:
    return maxf(1.0, base_damage) * (1.0 + RunManager.PLAYER_GLOBAL_DAMAGE_BONUS + level_bonus + chest_bonus)

static func black_jack_spread_degrees(quantity: int) -> PackedFloat32Array:
    # Abanico simétrico y moderado: el legendario tiene cuatro rutas distintas
    # sin concentrarlas ni lanzar las balas exteriores demasiado lejos.
    match quantity:
        2:
            return PackedFloat32Array([-12.0, 12.0])
        4:
            return PackedFloat32Array([-18.0, -6.0, 6.0, 18.0])
        _:
            return PackedFloat32Array([0.0])

# Armas 2.0: el arma define los perdigones, la cadencia y el alcance;
# los sets transforman el disparo sin impedir mezclas entre especialidades.
static func weapon_pellet_count(weapon_type: String) -> int:
    return 3 if weapon_type == "shotgun" else 1

static func weapon_damage_factor(weapon_type: String) -> float:
    match weapon_type:
        "shotgun": return 0.52
        "smg": return 0.82 # 4.31: +12.3% daño por proyectil; no altera cadencia
        "deagle": return 1.30
        _: return 1.0

func _fire_projectile(direction: Vector2, damage: float, critical: bool) -> void:
    var weapon_type: String = InventoryManager.equipped_weapon_type()
    AudioDirector.play_sfx("shot_" + weapon_type)
    var quantity: int = InventoryManager.black_jack_projectiles()
    var factor: float = InventoryManager.black_jack_damage_factor()
    var angles: PackedFloat32Array = black_jack_spread_degrees(quantity)
    var pellets: int = weapon_pellet_count(weapon_type)
    var shot_number: int = 0
    var proc_step: int = maxi(1, int(ceil(float(quantity * pellets) / 4.0)))
    # Cada perdigón tiene ángulo propio; ×2/×4 multiplica abanicos reales.
    # Separaciones alternadas evitan superposiciones y tiros aparentemente ausentes.
    var fan_spacing: float = 15.0 if quantity == 1 else (7.5 if quantity == 2 else 3.5)
    for angle_degrees in angles:
        for pellet in range(pellets):
            var local_spread: float = (float(pellet) - float(pellets - 1) * 0.5) * fan_spacing if pellets > 1 else 0.0
            var final_angle: float = angle_degrees + local_spread
            if weapon_type == "smg":
                final_angle += randf_range(-3.0, 3.0)
            # Para proteger Android, las procs secundarias se limitan a cuatro
            # candidatos por ráfaga. TODOS los perdigones siguen haciendo daño.
            var secondary_proc: bool = shot_number % proc_step == 0
            _spawn_projectile(direction.rotated(deg_to_rad(final_angle)), damage * factor * weapon_damage_factor(weapon_type), critical, weapon_type, secondary_proc)
            shot_number += 1

func _spawn_projectile(direction: Vector2, damage: float, critical: bool, weapon_type: String = "pistol", allow_secondary: bool = true) -> void:
    var projectile = PROJECTILE_SCENE.instantiate()
    projectile.set("direction", direction)
    var bullet_speed: float = {"pistol": 430.0, "shotgun": 405.0, "smg": 480.0, "deagle": 570.0}.get(weapon_type, 430.0)
    projectile.set("speed", bullet_speed * (1.0 + RunManager.level_projectile_speed_bonus))
    projectile.set("damage", damage)
    projectile.set("max_distance", {"pistol": 750.0, "shotgun": 250.0, "smg": 590.0, "deagle": 840.0}.get(weapon_type, 750.0))
    projectile.set("falloff_start", 90.0 if weapon_type == "shotgun" else -1.0)
    projectile.set("falloff_minimum", 0.35 if weapon_type == "shotgun" else 1.0)
    projectile.set("weapon_visual", weapon_type)
    projectile.set("homing_strength", InventoryManager.get_equipped_bonus("accuracy"))
    projectile.set("jackpot_homing", InventoryManager.jackpot_tracking_enabled())
    projectile.set("chain_on_hit", allow_secondary and InventoryManager.has_active_weapon_relic())
    projectile.set("critical_splash", allow_secondary and critical and PactManager.is_active("instinto", "overload"))
    get_tree().current_scene.add_child(projectile)
    projectile.global_position = global_position

func _on_parry_triggered() -> void:
    # JACKPOT concentra la defensa en su siguiente ataque, sin proyectiles extra.
    if InventoryManager.set_tier("jackpot") > 0:
        jackpot_charged = true
        return
    # Contraataque independiente, SIN multiplicación BLACK JACK ni rayos.
    var enemy: Node2D = _find_nearest_enemy()
    if enemy != null and enemy.has_method("take_damage"):
        var base_damage: int = 1 + int(round(InventoryManager.get_equipped_bonus("damage")))
        enemy.take_damage(maxi(1, int(round(float(base_damage) * 0.5))))

func _find_nearest_enemy() -> Node2D:
    var nearest: Node2D = null
    var nearest_distance := INF
    var weapon_type: String = InventoryManager.equipped_weapon_type()
    var seek_radius: float = 280.0 if weapon_type == "shotgun" else (550.0 if weapon_type == "deagle" else 380.0)
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(enemy):
            continue
        var distance := global_position.distance_squared_to(enemy.global_position)
        if distance < nearest_distance and distance <= seek_radius * seek_radius:
            nearest_distance = distance
            nearest = enemy
    return nearest


func _process(delta: float) -> void:
    if get_tree().paused:
        return
    sprite_elapsed += delta
    visual_target_time = maxf(0.0, visual_target_time - delta)
    _update_body_sprite()
    _update_weapon_sprite(delta)

func _body_direction_index(direction_vector: Vector2) -> int:
    var angle: float = wrapf(direction_vector.angle() - PI * 0.5, 0.0, TAU)
    return posmod(roundi(angle / (PI * 0.25)), 8)

func _current_visual_direction_index(is_walking: bool) -> int:
    var direction_vector: Vector2 = facing if is_walking else visual_direction
    return _body_direction_index(direction_vector)

func _weapon_visual_key() -> String:
    var weapon_type: String = InventoryManager.equipped_weapon_type()
    var entry: Dictionary = InventoryManager.get_equipped_entry("weapon")
    var rarity: String = str(entry.get("rarity", "common")) if not entry.is_empty() else "common"
    var key: String = "%s_%s" % [weapon_type, rarity]
    if not WEAPON_ATLAS_PATHS.has(key):
        key = "pistol_common"
    return key

func _get_weapon_texture(key: String) -> Texture2D:
    if not _weapon_texture_cache.has(key):
        _weapon_texture_cache[key] = load(str(WEAPON_ATLAS_PATHS.get(key, WEAPON_ATLAS_PATHS["pistol_common"])))
    return _weapon_texture_cache[key]

func _update_weapon_sprite(delta: float) -> void:
    # Solo es una capa Sprite2D: sin Area2D ni CollisionShape2D.
    if weapon_sprite == null:
        return
    if death_cinematic_active or (hurt_visual_active and hurt_cooldown > 0.0):
        weapon_sprite.visible = false
        return
    weapon_sprite.visible = true
    var is_walking: bool = velocity.length_squared() > 16.0
    var key: String = _weapon_visual_key()
    var is_pistol: bool = key.begins_with("pistol_")
    var is_shotgun: bool = key.begins_with("shotgun_")
    var is_smg: bool = key.begins_with("smg_")
    # Las tres armas brújula siguen el apuntado real, no el sentido de caminar.
    var direction_index: int = _body_direction_index(visual_direction) if (is_pistol or is_shotgun or is_smg) else _current_visual_direction_index(is_walking)
    var desired_texture: Texture2D = _get_weapon_texture(key)
    if weapon_sprite.texture != desired_texture:
        weapon_sprite.texture = desired_texture
    var cell_size: int = PISTOL_CELL if is_pistol else (SHOTGUN_CELL if is_shotgun else (SMG_CELL if is_smg else WEAPON_CELL))
    var desired_region := Rect2(float(direction_index * cell_size), 0.0, float(cell_size), float(cell_size))
    if weapon_sprite.region_rect != desired_region:
        weapon_sprite.region_rect = desired_region
    var desired_position: Vector2
    if not is_smg:
        _smg_orbit_initialized = false
    if is_pistol:
        # La brújula sí se mueve en 360° en el espacio, pero la ilustración
        # cambia únicamente entre ocho sprites. Nunca rotamos la textura.
        var aim: Vector2 = visual_direction.normalized() if visual_direction.length_squared() > 0.001 else Vector2.DOWN
        # Incluimos el ajuste local de la vista 3 dentro del suavizado,
        # evitando el salto brusco que ocurría al sumarlo al final.
        var orbit_target: Vector2 = PISTOL_ORBIT_CENTER + Vector2(aim.x * PISTOL_ORBIT_RADIUS_X, aim.y * PISTOL_ORBIT_RADIUS_Y) + PISTOL_DIRECTION_NUDGES[direction_index]
        if not _pistol_orbit_initialized:
            _pistol_orbit_position = orbit_target
            _pistol_orbit_initialized = true
        else:
            # Seguimiento amortiguado: sin saltos bruscos cuando cambia la mira.
            var follow_weight: float = clampf(1.0 - exp(-PISTOL_ORBIT_FOLLOW * delta), 0.0, 1.0)
            _pistol_orbit_position = _pistol_orbit_position.lerp(orbit_target, follow_weight)
        var floating_position: Vector2 = _pistol_orbit_position + Vector2(0.0, sin(sprite_elapsed * PISTOL_FLOAT_SPEED) * PISTOL_FLOAT_AMPLITUDE)
        # La arena limita al jugador, pero no necesariamente su arma orbital.
        # Limitamos el centro del sprite para que la celda 32x32 quede dentro
        # de las paredes aun cuando el Apostador esté en una esquina.
        var arena: Rect2 = RunManager.arena_rect
        var inset: Vector2 = Vector2(PISTOL_ARENA_MARGIN, PISTOL_ARENA_MARGIN)
        var global_weapon_position: Vector2 = (global_position + floating_position).clamp(arena.position + inset, arena.end - inset)
        # Redondear primero en coordenadas globales evita un recorte de
        # medio pixel si el Apostador está entre píxeles al caminar.
        var pixel_snapped_world: Vector2 = Vector2(roundf(global_weapon_position.x), roundf(global_weapon_position.y))
        desired_position = pixel_snapped_world - global_position
        _shotgun_orbit_initialized = false
    elif is_shotgun:
        # Misma brújula visual de ocho direcciones, sin girar la textura.
        # Rama separada: NO se alteran los ajustes aprobados de la pistola.
        _pistol_orbit_initialized = false
        var shotgun_aim: Vector2 = visual_direction.normalized() if visual_direction.length_squared() > 0.001 else Vector2.DOWN
        var shotgun_orbit_target: Vector2 = PISTOL_ORBIT_CENTER + Vector2(shotgun_aim.x * SHOTGUN_ORBIT_RADIUS_X, shotgun_aim.y * SHOTGUN_ORBIT_RADIUS_Y)
        if not _shotgun_orbit_initialized:
            _shotgun_orbit_position = shotgun_orbit_target
            _shotgun_orbit_initialized = true
        else:
            var shotgun_follow_weight: float = clampf(1.0 - exp(-PISTOL_ORBIT_FOLLOW * delta), 0.0, 1.0)
            _shotgun_orbit_position = _shotgun_orbit_position.lerp(shotgun_orbit_target, shotgun_follow_weight)
        var shotgun_floating_position: Vector2 = _shotgun_orbit_position + Vector2(0.0, sin(sprite_elapsed * PISTOL_FLOAT_SPEED) * PISTOL_FLOAT_AMPLITUDE)
        # La celda de escopeta es 32x32, igual que la pistola. El arma no se
        # recorta contra la pared incluso cuando el jugador está en el borde.
        var shotgun_arena: Rect2 = RunManager.arena_rect
        var shotgun_inset: Vector2 = Vector2(PISTOL_ARENA_MARGIN, PISTOL_ARENA_MARGIN)
        var shotgun_global_weapon_position: Vector2 = (global_position + shotgun_floating_position).clamp(shotgun_arena.position + shotgun_inset, shotgun_arena.end - shotgun_inset)
        var shotgun_snapped_world: Vector2 = Vector2(roundf(shotgun_global_weapon_position.x), roundf(shotgun_global_weapon_position.y))
        desired_position = shotgun_snapped_world - global_position
    elif is_smg:
        # Brújula del subfusil: mismo método que la escopeta 4.31.34,
        # sin tocar física, proyectiles ni la orientación de las otras armas.
        _pistol_orbit_initialized = false
        _shotgun_orbit_initialized = false
        var smg_aim: Vector2 = visual_direction.normalized() if visual_direction.length_squared() > 0.001 else Vector2.DOWN
        var smg_orbit_target: Vector2 = PISTOL_ORBIT_CENTER + Vector2(smg_aim.x * SMG_ORBIT_RADIUS_X, smg_aim.y * SMG_ORBIT_RADIUS_Y)
        if not _smg_orbit_initialized:
            _smg_orbit_position = smg_orbit_target
            _smg_orbit_initialized = true
        else:
            var smg_follow_weight: float = clampf(1.0 - exp(-PISTOL_ORBIT_FOLLOW * delta), 0.0, 1.0)
            _smg_orbit_position = _smg_orbit_position.lerp(smg_orbit_target, smg_follow_weight)
        var smg_floating_position: Vector2 = _smg_orbit_position + Vector2(0.0, sin(sprite_elapsed * PISTOL_FLOAT_SPEED) * PISTOL_FLOAT_AMPLITUDE)
        # Mantener toda la celda de 32 px dentro de la arena, como escopeta/pistola.
        var smg_arena: Rect2 = RunManager.arena_rect
        var smg_inset: Vector2 = Vector2(PISTOL_ARENA_MARGIN, PISTOL_ARENA_MARGIN)
        var smg_global_weapon_position: Vector2 = (global_position + smg_floating_position).clamp(smg_arena.position + smg_inset, smg_arena.end - smg_inset)
        var smg_snapped_world: Vector2 = Vector2(roundf(smg_global_weapon_position.x), roundf(smg_global_weapon_position.y))
        desired_position = smg_snapped_world - global_position
    else:
        _pistol_orbit_initialized = false
        _shotgun_orbit_initialized = false
        desired_position = WEAPON_OFFSETS[direction_index]
    if weapon_sprite.position != desired_position:
        weapon_sprite.position = desired_position
    var desired_scale: Vector2 = Vector2.ONE if (is_pistol or is_shotgun or is_smg) else WEAPON_SCALE
    if weapon_sprite.scale != desired_scale:
        weapon_sprite.scale = desired_scale
    var desired_z: int = -1 if WEAPON_BEHIND_DIRECTIONS.has(direction_index) else 1
    if weapon_sprite.z_index != desired_z:
        weapon_sprite.z_index = desired_z

func _update_body_sprite() -> void:
    if body_sprite == null or death_cinematic_active:
        return
    # Al recibir dano se ve el golpe rojo, el dolor en la cara y finalmente
    # el esfuerzo exagerado por mantenerse de pie sobre UNA pierna.
    # El cuerpo no se aplasta ni se deforma: todas las poses son sprites.
    # Tras perder un corazon, no entra en la pose erguida hasta el fin de la proteccion.
    # Los pactos pueden acortar o alargar la proteccion sin desincronizarlo.
    var desired_region: Rect2
    if hurt_cooldown > 0.0 and hurt_visual_active:
        var elapsed: float = maxf(0.0, hurt_iframe_duration - hurt_cooldown)
        var progress: float = clampf(elapsed / maxf(0.001, hurt_iframe_duration), 0.0, 1.0)
        var hurt_frame: int = 0  # destello rojo real, al instante del golpe
        if elapsed < BODY_HIT_RED_SECONDS:
            hurt_frame = 0
        elif progress < 0.24:
            hurt_frame = 1  # cierra los ojos y aprieta los dientes
        elif progress < 0.54:
            hurt_frame = 2  # pierde equilibrio y levanta una pierna
        elif progress < 0.86:
            hurt_frame = 3  # fuerza para no caerse
        else:
            hurt_frame = 2  # aguanta sin recuperar la postura aun
        var hurt_row: int = BODY_HURT_FIRST_ROW + hurt_direction_index
        desired_region = Rect2(float(hurt_frame * BODY_CELL), float(hurt_row * BODY_CELL), float(BODY_CELL), float(BODY_CELL))
    else:
        # Camina hacia el input real; quieto mantiene la direccion de ataque.
        var is_walking: bool = velocity.length_squared() > 16.0
        var direction_vector: Vector2 = facing if is_walking else visual_direction
        var direction_index: int = _current_visual_direction_index(is_walking)
        var animation_fps: float = BODY_WALK_FPS if is_walking else BODY_IDLE_FPS
        var frame: int = int(sprite_elapsed * animation_fps) % 4
        if not is_walking and visual_target_time > 0.0:
            frame = 0
        var row: int = direction_index + (BODY_WALK_FIRST_ROW if is_walking else 0)
        desired_region = Rect2(float(frame * BODY_CELL), float(row * BODY_CELL), float(BODY_CELL), float(BODY_CELL))
    # No reasignar el mismo recorte/tono cada frame: solo cambian en keyframes.
    if body_sprite.region_rect != desired_region:
        body_sprite.region_rect = desired_region
    # Destello rojo inicial, despues parpadeo mientras hace equilibrio.
    # Regreso inmediato al sprite erguido al terminar hurt_cooldown.
    var desired_modulate: Color = Color.WHITE
    if hurt_visual_active and hurt_cooldown > 0.0 and hurt_iframe_duration - hurt_cooldown < BODY_HIT_RED_SECONDS:
        desired_modulate = Color(1.0, 0.22, 0.29, 1.0)
    elif hurt_visual_active and hurt_cooldown > 0.0 and int(hurt_cooldown * 11.0) % 2 == 0:
        desired_modulate = Color(1.0, 0.85, 0.86, 0.74)
    if body_sprite.modulate != desired_modulate:
        body_sprite.modulate = desired_modulate

# Reutiliza el comienzo del dano C v2. Main dirige los cuadros incluso con
# el mundo pausado: no hay un Timer extra ni interpolacion de Sprite2D.
func begin_death_cinematic(variant: int) -> void:
    # Se elige UNA variante aleatoria por muerte; la ruleta NO altera la elección.
    death_cinematic_variant = clampi(variant, 0, 1)
    death_cinematic_active = true
    velocity = Vector2.ZERO
    body_sprite.texture = BODY_ATLAS
    body_sprite.region_enabled = true
    body_sprite.offset = Vector2(0.0, -7.0)
    body_sprite.modulate = Color(1.0, 0.22, 0.29, 1.0)
    if weapon_sprite != null:
        weapon_sprite.visible = false

func show_death_cinematic_progress(elapsed: float, total_seconds: float, shared_hit_seconds: float) -> void:
    if not death_cinematic_active:
        return
    if elapsed < shared_hit_seconds:
        # Inicio compartido con el daño C v2: golpe rojo, dientes apretados,
        # equilibrio sobre una pierna. No recrear el golpe con otro script.
        body_sprite.texture = BODY_ATLAS
        body_sprite.offset = Vector2(0.0, -7.0)
        var frame: int = 0 if elapsed < 0.10 else (1 if elapsed < 0.17 else 2)
        body_sprite.region_rect = Rect2(float(frame * BODY_CELL), float((BODY_HURT_FIRST_ROW + hurt_direction_index) * BODY_CELL), float(BODY_CELL), float(BODY_CELL))
        body_sprite.modulate = Color(1.0, 0.22, 0.29, 1.0) if elapsed < 0.10 else Color.WHITE
        return
    # Una sola secuencia y temporizador para A o B. Sprite2D compartido.
    body_sprite.texture = BODY_DEATH_FACE_ATLAS if death_cinematic_variant == 0 else BODY_DEATH_BACK_ATLAS
    body_sprite.offset = Vector2(0.0, -11.0)
    var phase: float = clampf((elapsed - shared_hit_seconds) / maxf(0.001, total_seconds - shared_hit_seconds), 0.0, 1.0)
    var death_frame: int = 7 # El ultimo cuadro permanece hasta que se abre la UI.
    var thresholds: Array[float] = [0.12, 0.23, 0.34, 0.45, 0.57, 0.70, 0.82]
    for i in thresholds.size():
        if phase < thresholds[i]:
            death_frame = i
            break
    body_sprite.region_rect = Rect2(float((death_frame % BODY_DEATH_COLUMNS) * BODY_DEATH_CELL), float(int(death_frame / BODY_DEATH_COLUMNS) * BODY_DEATH_CELL), float(BODY_DEATH_CELL), float(BODY_DEATH_CELL))
    body_sprite.modulate = Color.WHITE

func reset_death_cinematic() -> void:
    death_cinematic_active = false
    hurt_visual_active = false
    # Reseteamos el seguimiento visual tras reanimar: sin arrastrar la
    # posición orbital previa a la cinemática de muerte.
    _pistol_orbit_initialized = false
    _shotgun_orbit_initialized = false
    _smg_orbit_initialized = false
    body_sprite.texture = BODY_ATLAS
    body_sprite.offset = Vector2(0.0, -7.0)
    body_sprite.modulate = Color.WHITE
    if weapon_sprite != null:
        weapon_sprite.visible = true
    _update_body_sprite()
    _update_weapon_sprite(0.0)

func receive_contact_damage(amount: int) -> void:
    if hurt_cooldown > 0.0 or not RunManager.run_active:
        return
    hurt_cooldown = clampf(1.25 + PactManager.iframe_bonus(), 0.65, 1.8)
    var look: Vector2 = facing if velocity.length_squared() > 16.0 else visual_direction
    hurt_direction_index = _body_direction_index(look)
    hurt_iframe_duration = hurt_cooldown
    hurt_visual_active = RunManager.damage_player(amount)
    _update_body_sprite()  # Impacto visual solo si perdió realmente vida.

func _draw() -> void:
    # Sombra bajo los pies: sin alterar colisión, tamaño del personaje ni stats.
    draw_circle(Vector2(0.0, 13.0), 11.0, Color(0.08, 0.055, 0.10, 0.50))

