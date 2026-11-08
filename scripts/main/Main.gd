extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/BasicEnemy.tscn")
const LEVEL_MANAGER_SCRIPT = preload("res://scripts/systems/LevelManager.gd")
const DROP_SCENE: PackedScene = preload("res://scenes/items/DroppedItem.tscn")
const DB = preload("res://scripts/systems/ItemDatabase.gd")
const OBSTACLE_SCRIPT = preload("res://scripts/levels/Obstacle.gd")
const ROOM_GENERATOR_SCRIPT = preload("res://scripts/levels/RoomGenerator.gd")
const ROOM_BACKDROP_SCRIPT = preload("res://scripts/visual/RoomBackdrop.gd")
const ROOM_THEME_CATALOG = preload("res://scripts/visual/RoomThemeCatalog.gd")
# Recursos visuales del HUD (no afectan colisiones, salud ni daño).
const HUD_HEART_FULL = preload("res://assets/hud/normal_full.png")
const HUD_HEART_EMPTY = preload("res://assets/hud/normal_empty.png")
const HUD_HEART_EXTRA_FULL = preload("res://assets/hud/extra_full.png")
const HUD_HEART_EXTRA_EMPTY = preload("res://assets/hud/extra_empty.png")
# Moneda infernal: seis fotogramas PNG transparentes a 64 px.
# Solo se anima el icono del HUD. Los ingresos siguen siendo directos.
const HUD_COIN_FRAMES = [
    preload("res://assets/hud/coin_00.png"),
    preload("res://assets/hud/coin_01.png"),
    preload("res://assets/hud/coin_02.png"),
    preload("res://assets/hud/coin_03.png"),
    preload("res://assets/hud/coin_04.png"),
    preload("res://assets/hud/coin_05.png")
]
const COIN_FRAME_SECONDS: float = 0.14
const BASE_HUD_HEARTS: int = 3

var player: CharacterBody2D
var enemies_root: Node2D
var obstacles_root: Node2D
var room_navigation
var room_generator
var room_backdrop
var level_manager
var room_label: Label
var next_panel: PanelContainer
var next_prompt: Label
var next_button: Button
var room_rest_button: Button
var room_cash_button: Button
var cashout_button: Button
var room_choice_made: bool = false
var summary_panel: PanelContainer
var summary_title: Label
var summary_details: Label
var record_label: Label
var hud_timer: float = 0.0
var boss_reward_panel: PanelContainer
var boss_gamble_button: Button
var boss_bonus_label: Label
var boss_reward_resolved: bool = false
var combat_label: Label
var coin_label: Label
var health_label: Label
var stats_label: Label
var bag_label: Label
var equipment_label: Label
var status_label: Label
var compact_health: HBoxContainer
var compact_heart_icons: Array[TextureRect] = []
var compact_shield: Label
var compact_coins: Label
var compact_coin_icon: TextureRect
var coin_frame_timer: float = 0.0
var coin_frame_index: int = 0
var compact_room: Label
# 4.31.2: cache del HUD, sin reconstrucciones ni reasignaciones redundantes.
var _heart_last_amount: int = -999
var _heart_last_maximum: int = -999
# Diagnostico OPT-IN en Android; no altera estadisticas ni Game/Engine.time_scale.
var perf_overlay: Label
var perf_button: Button
var perf_enabled: bool = false
var perf_refresh_timer: float = 0.0
var perf_min_fps: int = 10000
var perf_slow_samples: int = 0
var toast_previous: String = ""
var toast_countdown: float = 0.0
var detail_pause_label: Label
var inventory_panel: PanelContainer
var pause_panel: PanelContainer
var weapon_lab_panel: PanelContainer
var weapon_lab_status: Label
var scrap_panel: PanelContainer
var scrap_list: VBoxContainer
var scrap_scroll: ScrollContainer
var scrap_status: Label
# La Chatarrería usa la misma captura táctil resistente a botones que la mochila.
var scrap_drag_touch: int = -1
var scrap_drag_last_y: float = 0.0
var scrap_drag_accumulated: float = 0.0
var scrap_touch_scrolled: bool = false
var scrap_scroll_touched: bool = false
var scrap_scroll_generation: int = 0
var scrap_build_saved_scroll: int = 0
var scrap_build_queue: Array[Dictionary] = []
var scrap_confirmation: ConfirmationDialog
var pending_scrap: Dictionary = {}
var pause_overlay: ColorRect
var inventory_list: VBoxContainer
var inventory_scroll: ScrollContainer
var inventory_title: Label
var inventory_equipped_label: Label
var inventory_filter_buttons: Array[Button] = []
var inventory_sort_button: Button
var inventory_drag_touch: int = -1
var inventory_drag_last_y: float = 0.0
var inventory_drag_accumulated: float = 0.0
var inventory_touch_scrolled: bool = false
var inventory_scroll_generation: int = 0
var inventory_filter: String = "all"
var inventory_sort: String = "type"
# Inventario móvil: construir tarjetas en tandas evita bloquear un fotograma
# cuando la mochila contiene varias decenas de objetos.
var inventory_build_queue: Array[Dictionary] = []
var inventory_build_saved_scroll: int = 0
var inventory_scroll_touched: bool = false
var inventory_rebuild_scheduled: bool = false
const INVENTORY_CARDS_PER_FRAME: int = 5
const INVENTORY_FILTERS := ["all", "equipped", "weapon", "helmet", "chest", "legs", "boots", "charm", "relic"]
const INVENTORY_SORTS := ["type", "rarity", "level", "name"]
var active_menu: String = "" # "", "pacts", "inventory", "pause", "boss_reward", "level_roll"
var xp_label: Label
var level_notice_timer: float = 0.0
var restart_pending: bool = false
# Cada nueva sala ofrece UNA apuesta o la opción de guardar monedas.
var portal_ready: bool = false
var walls_root: Node2D
# Las ruletas de nivel son gratuitas e ineludibles; pueden acumularse.
var pending_level_rolls: Array[int] = []
var level_roll_panel: PanelContainer
var level_roll_description: Label
var level_roll_spin_button: Button
var level_roll_accept_button: Button
var level_roll_spun: bool = false
# Solo una tirada de 50/50 tras la primera muerte de la partida.
var death_roll_panel: PanelContainer
var death_roll_button: Button
var death_roll_label: Label
# Ambas muertes A/B esperan antes de la UI; no cambia la ruleta 50/50.
const DEATH_CINEMATIC_DURATION: float = 1.48
const DEATH_SHARED_HIT_DURATION: float = 0.24
var death_cinematic_elapsed: float = -1.0
var death_cinematic_to_roll: bool = false
var death_cinematic_shown: bool = false
var death_cinematic_variant: int = 0 # se elige 0=A o 1=B en cada muerte real
# 4.20: mochila de 50 espacios libres, equipo fuera de la mochila y filtros. Pactos 4.19 intactos.
var pact_panel: PanelContainer
var pact_header: Label
var pact_detail: Label
var pact_skip_button: Button
var pact_reroll_button: Button
var pact_rerolled: bool = false
var pact_choice_buttons: Array[Button] = []
var pact_choice_labels: Array[Label] = []
var pact_choice_cards: Array[PanelContainer] = []
var pact_offers: Array[String] = []
var entry_pact_required: bool = false
var bonus_pact_remaining: bool = false
var pact_menu_is_extra: bool = false
var pact_pause_summary: Label
var black_jack_debug_kit_given: bool = false
var debug_set_kits_given: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    # Inicialización de una escena nueva: ninguna oferta debe heredar
    # modificadores de una instancia Main previa del mismo proceso.
    PactManager.reset_pacts()
    _create_world()
    level_manager = LEVEL_MANAGER_SCRIPT.new()
    level_manager.name = "LevelManager"
    level_manager.process_mode = Node.PROCESS_MODE_PAUSABLE
    add_child(level_manager)
    var impact_layer = preload("res://scripts/systems/CombatFeedback.gd").new()
    impact_layer.name = "CombatFeedback"
    impact_layer.z_index = 4 # Impactos encima del combate, no de la interfaz CanvasLayer.
    add_child(impact_layer)
    level_manager.setup(enemies_root, player)
    _create_hud()
    RunManager.coins_changed.connect(_update_coin_label)
    RunManager.boss_coins_awarded.connect(_on_boss_coins_awarded)
    RunManager.health_changed.connect(_update_health_label)
    RunManager.player_hurt.connect(_on_player_hurt)
    RunManager.stats_changed.connect(_update_stats_label)
    RunManager.level_gained.connect(_on_level_gained)
    RunManager.run_ended.connect(_on_run_ended)
    RunManager.death_roll_requested.connect(_on_death_roll_requested)
    RunManager.hit_blocked.connect(_on_hit_blocked)
    RunManager.evasion_triggered.connect(_on_evasion_triggered)
    RunManager.parry_triggered.connect(_on_parry_triggered)
    RunManager.run_finished.connect(_on_run_finished)
    RunManager.enemy_killed.connect(level_manager.register_enemy_death)
    RunManager.boss_defeated.connect(_on_boss_defeated)
    level_manager.room_started.connect(_on_room_started)
    level_manager.room_progress.connect(_on_room_progress)
    level_manager.room_cleared.connect(_on_room_cleared)
    InventoryManager.inventory_changed.connect(_on_inventory_changed)
    InventoryManager.item_collected.connect(_on_item_collected)
    PactManager.pacts_changed.connect(_on_pacts_changed)
    _update_coin_label(RunManager.coins)
    _update_health_label(RunManager.player_health)
    _update_stats_label()
    _on_inventory_changed()
    if InventoryManager.get_equipped_entry("weapon").is_empty():
        var starter: Dictionary = InventoryManager.add_item("pistol_common")
        if bool(starter.get("ok", false)):
            InventoryManager.equip_item(int(starter["entry"]["uid"]))
    _begin_room(1)

func _create_world() -> void:
    # 4.30: arena ocupa TODO el viewport. HUD/joystick se superponen sin
    # recortar el mundo; paredes físicas fuera de los límites visibles.
    var viewport: Vector2 = get_viewport_rect().size
    RunManager.arena_rect = Rect2(Vector2.ZERO, viewport)
    # 4.31.38: capa puramente visual, SIEMPRE detrás del combate.
    room_backdrop = ROOM_BACKDROP_SCRIPT.new()
    room_backdrop.name = "RoomBackdrop"
    add_child(room_backdrop)
    _build_arena_walls()
    obstacles_root = Node2D.new()
    obstacles_root.name = "Obstacles"
    obstacles_root.process_mode = Node.PROCESS_MODE_PAUSABLE
    add_child(obstacles_root)
    room_navigation = preload("res://scripts/levels/RoomNavigation.gd").new()
    room_navigation.name = "RoomNavigation"
    add_child(room_navigation)
    room_generator = ROOM_GENERATOR_SCRIPT.new()
    enemies_root = Node2D.new()
    enemies_root.name = "Enemies"
    # Main siempre procesa atajos, pero sus hijos de combate NO deben
    # heredar PROCESS_MODE_ALWAYS: congelamos enemigos durante la pausa.
    enemies_root.process_mode = Node.PROCESS_MODE_PAUSABLE
    enemies_root.z_index = 2 # Actores visibles por encima de cualquier ficha en el suelo.
    add_child(enemies_root)
    player = PLAYER_SCENE.instantiate()
    player.scale = Vector2(1.6, 1.6)
    player.z_index = 2 # Nunca tapado por fichas, sin tocar su colisión.
    player.process_mode = Node.PROCESS_MODE_PAUSABLE
    player.position = RunManager.arena_rect.get_center()
    add_child(player)

func _build_arena_walls() -> void:
    # Antes eran bordes dibujados, ahora son colisiones reales de capa 16:
    # jugador, enemigos, jefe y proyectiles no podrán cruzarlos.
    walls_root = Node2D.new()
    walls_root.name = "ArenaWalls"
    walls_root.process_mode = Node.PROCESS_MODE_PAUSABLE
    add_child(walls_root)
    var r: Rect2 = RunManager.arena_rect
    var thickness: float = 32.0
    var specs: Array = [
        [Vector2(r.get_center().x, r.position.y - thickness * 0.5), Vector2(r.size.x + thickness * 2.0, thickness)],
        [Vector2(r.get_center().x, r.end.y + thickness * 0.5), Vector2(r.size.x + thickness * 2.0, thickness)],
        [Vector2(r.position.x - thickness * 0.5, r.get_center().y), Vector2(thickness, r.size.y + thickness * 2.0)],
        [Vector2(r.end.x + thickness * 0.5, r.get_center().y), Vector2(thickness, r.size.y + thickness * 2.0)]
    ]
    for spec in specs:
        var wall := StaticBody2D.new()
        wall.collision_layer = 16
        wall.collision_mask = 0
        wall.position = spec[0]
        var shape := RectangleShape2D.new()
        shape.size = spec[1]
        var collider := CollisionShape2D.new()
        collider.shape = shape
        wall.add_child(collider)
        walls_root.add_child(wall)

func _create_hud() -> void:
    var hud := CanvasLayer.new()
    hud.name = "HUD"
    hud.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(hud)
    var panel := PanelContainer.new()
    panel.position = Vector2(10, 10)
    panel.custom_minimum_size = Vector2(298, 174)
    panel.visible = false # Datos detallados disponibles en pausa.
    hud.add_child(panel)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var column := VBoxContainer.new()
    panel.add_child(column)
    coin_label = Label.new()
    column.add_child(coin_label)
    health_label = Label.new()
    column.add_child(health_label)
    stats_label = Label.new()
    stats_label.add_theme_font_size_override("font_size", 12)
    column.add_child(stats_label)
    xp_label = Label.new()
    xp_label.add_theme_font_size_override("font_size", 12)
    xp_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(xp_label)
    bag_label = Label.new()
    column.add_child(bag_label)
    combat_label = Label.new()
    column.add_child(combat_label)
    room_label = Label.new()
    column.add_child(room_label)
    var equipment_panel := PanelContainer.new()
    equipment_panel.position = Vector2(311, 10)
    equipment_panel.custom_minimum_size = Vector2(218, 199)
    equipment_panel.visible = false
    hud.add_child(equipment_panel)
    equipment_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    equipment_label = Label.new()
    equipment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    equipment_label.add_theme_font_size_override("font_size", 11)
    equipment_panel.add_child(equipment_label)
    record_label = Label.new()
    record_label.position = Vector2(312, 193)
    record_label.custom_minimum_size = Vector2(214, 30)
    hud.add_child(record_label)
    record_label.visible = false
    status_label = Label.new()
    status_label.add_theme_font_size_override("font_size", 13)
    status_label.position = Vector2(22, 72)
    status_label.custom_minimum_size = Vector2(get_viewport_rect().size.x - 44.0, 38)
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.text = "ALL IN 4.30 | Estabilidad móvil"
    status_label.visible = false
    hud.add_child(status_label)
    status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var help := Label.new()
    help.text = "PC: WASD · I mochila · B apuesta · Esc pausa · F8 jefe"
    help.position = Vector2(198, get_viewport_rect().size.y - 19)
    help.add_theme_font_size_override("font_size", 11)
    hud.add_child(help)
    help.visible = false
    help.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # Barra compacta: VIDA / SALA / MONEDAS. El resto se consulta en PAUSA.
    var top_bar := PanelContainer.new()
    top_bar.name = "HUDCompacto429"
    top_bar.position = Vector2(10, 8)
    top_bar.size = Vector2(get_viewport_rect().size.x - 20.0, 52)
    top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_bar)
    var top_row := HBoxContainer.new()
    top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top_bar.add_child(top_row)
    # HUD con iconos en lugar de caracteres Unicode: legibles en Android
    # y sin depender de la fuente del sistema para dibujar los corazones.
    compact_health = HBoxContainer.new()
    compact_health.name = "CorazonesPixelHUD"
    compact_health.custom_minimum_size = Vector2(106, 40)
    compact_health.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    compact_health.alignment = BoxContainer.ALIGNMENT_BEGIN
    compact_health.add_theme_constant_override("separation", 1)
    compact_health.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top_row.add_child(compact_health)
    # Mantener la indicación original del escudo de TRAGAPERRAS.
    compact_shield = Label.new()
    compact_shield.name = "EscudoTragaperras"
    compact_shield.text = "◇"
    compact_shield.visible = false
    compact_shield.add_theme_font_size_override("font_size", 18)
    compact_shield.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top_row.add_child(compact_shield)
    compact_room = Label.new()
    compact_room.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    compact_room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    compact_room.add_theme_font_size_override("font_size", 16)
    compact_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top_row.add_child(compact_room)
    # Moneda animada más contador: HBox no intercepta el joystick ni los menús.
    var coin_box := HBoxContainer.new()
    coin_box.name = "ContadorMonedaInfernal"
    coin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    coin_box.alignment = BoxContainer.ALIGNMENT_END
    coin_box.add_theme_constant_override("separation", 3)
    coin_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top_row.add_child(coin_box)
    compact_coin_icon = TextureRect.new()
    compact_coin_icon.name = "MonedaInfernalAnimada"
    compact_coin_icon.custom_minimum_size = Vector2(34, 34)
    compact_coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    compact_coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    compact_coin_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    compact_coin_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    compact_coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    compact_coin_icon.texture = HUD_COIN_FRAMES[0]
    coin_box.add_child(compact_coin_icon)
    compact_coins = Label.new()
    compact_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    compact_coins.add_theme_font_size_override("font_size", 19)
    compact_coins.mouse_filter = Control.MOUSE_FILTER_IGNORE
    coin_box.add_child(compact_coins)
    # HUD de diagnostico de rendimiento, oculto salvo activacion manual.
    perf_overlay = Label.new()
    perf_overlay.name = "DiagnosticoFPS4312"
    perf_overlay.position = Vector2(10, 68)
    perf_overlay.custom_minimum_size = Vector2(430, 50)
    perf_overlay.add_theme_font_size_override("font_size", 13)
    perf_overlay.add_theme_color_override("font_color", Color("#f5e8c4"))
    perf_overlay.add_theme_color_override("font_shadow_color", Color(0.05, 0.05, 0.08, 0.95))
    perf_overlay.add_theme_constant_override("shadow_offset_x", 1)
    perf_overlay.add_theme_constant_override("shadow_offset_y", 1)
    perf_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    perf_overlay.visible = false
    hud.add_child(perf_overlay)
    # Overlay oscuro para que se note que el mundo está congelado.
    # IGNORE deja que los controles de los menús sigan recibiendo clics.
    pause_overlay = ColorRect.new()
    pause_overlay.name = "PauseOverlay"
    pause_overlay.position = Vector2.ZERO
    pause_overlay.size = get_viewport_rect().size
    pause_overlay.color = Color(0.07, 0.06, 0.12, 0.66)
    pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    pause_overlay.visible = false
    hud.add_child(pause_overlay)
    # Las apuestas normales ahora son pactos gratuitos (60/40).
    _create_pact_menu(hud)
    _create_inventory_menu(hud)
    _create_pause_menu(hud)
    _create_weapon_lab_menu(hud)
    _create_scrap_menu(hud)
    _create_next_menu(hud)
    _create_boss_reward_menu(hud)
    _create_level_roll_menu(hud)
    _create_death_roll_menu(hud)
    _create_summary_menu(hud)
    _create_touch_controls(hud)

func _create_touch_controls(hud: CanvasLayer) -> void:
    # Joystick libre: se despliega en cualquier toque no consumido por la UI.
    var joystick = preload("res://scripts/ui/MobileJoystick.gd").new()
    joystick.name = "MobileJoystick"
    joystick.position = Vector2.ZERO
    joystick.size = Vector2(150, 150)
    hud.add_child(joystick)
    var buttons: Array = [
        ["MOCHILA", Vector2(get_viewport_rect().size.x - 240.0, get_viewport_rect().size.y - 65.0), Callable(self, "_touch_inventory")],
        ["PACTO", Vector2(get_viewport_rect().size.x - 128.0, get_viewport_rect().size.y - 65.0), Callable(self, "_touch_betting")],
        ["PAUSA", Vector2(get_viewport_rect().size.x - 184.0, get_viewport_rect().size.y - 125.0), Callable(self, "_touch_pause")]
    ]
    for info in buttons:
        var button := Button.new()
        button.text = str(info[0])
        button.position = info[1]
        button.size = Vector2(104, 48)
        button.pressed.connect(info[2])
        hud.add_child(button)

func _touch_inventory() -> void:
    if active_menu == "inventory":
        _close_menus()
    elif active_menu == "" and RunManager.run_active:
        _open_menu("inventory")

func _touch_betting() -> void:
    _try_open_bonus_pact()

func _touch_pause() -> void:
    if active_menu == "pause":
        _close_menus()
    elif active_menu == "" and RunManager.run_active:
        _open_menu("pause")

func _create_pact_menu(hud: CanvasLayer) -> void:
    pact_panel = PanelContainer.new()
    pact_panel.name = "PactosDelDestino"
    pact_panel.position = Vector2(22, 256)
    pact_panel.custom_minimum_size = Vector2(496, 540)
    pact_panel.visible = false
    hud.add_child(pact_panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 6)
    pact_panel.add_child(column)
    pact_header = Label.new()
    pact_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pact_header.text = "PACTOS DEL DESTINO — 10 monedas · 60/40"
    column.add_child(pact_header)
    pact_detail = Label.new()
    pact_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    pact_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pact_detail.add_theme_font_size_override("font_size", 12)
    column.add_child(pact_detail)
    for i in range(3):
        var card := PanelContainer.new()
        column.add_child(card)
        pact_choice_cards.append(card)
        var content := VBoxContainer.new()
        content.add_theme_constant_override("separation", 2)
        card.add_child(content)
        var info := Label.new()
        info.add_theme_font_size_override("font_size", 12)
        info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        content.add_child(info)
        pact_choice_labels.append(info)
        var choose := Button.new()
        choose.text = "APOSTAR (10 monedas) — 60% / 40%"
        choose.pressed.connect(_on_pact_chosen.bind(i))
        content.add_child(choose)
        pact_choice_buttons.append(choose)
    pact_reroll_button = Button.new()
    pact_reroll_button.text = "RE-ROLL 3 PACTOS — 50 monedas (1 vez)"
    pact_reroll_button.pressed.connect(_on_pact_reroll)
    column.add_child(pact_reroll_button)
    pact_skip_button = Button.new()
    pact_skip_button.text = "NO APOSTAR — conservar mi fortuna"
    pact_skip_button.pressed.connect(_skip_pact)
    column.add_child(pact_skip_button)
    var caption := Label.new()
    caption.text = "Re-roll entre los 9 acumulables. Pueden repetirse las opciones anteriores."
    caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    caption.add_theme_font_size_override("font_size", 11)
    column.add_child(caption)

func _prepare_pact_menu(is_extra: bool) -> void:
    pact_menu_is_extra = is_extra
    pact_rerolled = false
    pact_offers = PactManager.draw_offers(is_extra)
    _render_pact_offers()

func _render_pact_offers() -> void:
    pact_header.text = "PACTO ADICIONAL" if pact_menu_is_extra else "PACTOS DEL DESTINO"
    pact_detail.text = "APOSTAR: 10 monedas | Re-roll: 50 monedas (1 vez) | Saldo: %d\nVictoria 60%% · Derrota 40%%. Rango posible: −3 a +3. Sobrecarga: 7 salas." % RunManager.coins
    pact_reroll_button.disabled = pact_rerolled or RunManager.coins < PactManager.REROLL_COST
    pact_reroll_button.text = "RE-ROLL UTILIZADO" if pact_rerolled else "RE-ROLL 3 PACTOS — 50 monedas (1 vez)"
    for i in range(pact_choice_buttons.size()):
        var available: bool = i < pact_offers.size()
        pact_choice_buttons[i].visible = available
        pact_choice_cards[i].visible = available
        if not available:
            continue
        pact_choice_buttons[i].disabled = RunManager.coins < PactManager.PACT_COST
        var pact_id: String = pact_offers[i]
        var definition: Dictionary = PactManager.PACTS[pact_id]
        var stack: int = int(PactManager.fortune.get(pact_id, 0))
        # Mostrar el estado ACTUAL, no el posible resultado (+/-) de apostar.
        # En sala 1 siempre comienza en cero hasta resolver un pacto.
        var suffix: String = " | Especial"
        if pact_id in PactManager.STACKABLE:
            suffix = " | Fortuna 0 (sin modificar)" if stack == 0 else " | Fortuna %+d" % stack
        pact_choice_labels[i].text = "%s%s\n%s" % [str(definition["name"]), suffix, str(definition["desc"])]
    pact_skip_button.text = "NO APOSTAR — seguir sin riesgo"

func _on_pact_reroll() -> void:
    if active_menu != "pacts" or pact_rerolled:
        return
    if not RunManager.spend_coins(PactManager.REROLL_COST):
        _render_pact_offers()
        return
    pact_rerolled = true
    pact_offers = PactManager.reroll_stackable_offers()
    _render_pact_offers()

func _on_pact_chosen(index: int) -> void:
    if active_menu != "pacts" or index < 0 or index >= pact_offers.size():
        return
    var result: Dictionary = PactManager.resolve_pact(pact_offers[index], pact_menu_is_extra)
    if not bool(result["ok"]):
        status_label.text = str(result["message"])
        return
    if pact_menu_is_extra:
        bonus_pact_remaining = false
    else:
        entry_pact_required = false
    _close_menus(true)
    status_label.text = str(result["message"])
    if bonus_pact_remaining:
        status_label.text += " | B: pacto adicional disponible."

func _skip_pact() -> void:
    if active_menu != "pacts":
        return
    if pact_menu_is_extra:
        bonus_pact_remaining = false
    else:
        entry_pact_required = false
    _close_menus(true)
    status_label.text = "No apostaste. Tus acumulaciones se conservan."
    if bonus_pact_remaining:
        status_label.text += " | B: pacto adicional disponible."

func _try_open_bonus_pact() -> void:
    if active_menu != "" or not RunManager.run_active:
        return
    if level_manager.cleared or entry_pact_required:
        status_label.text = "La oportunidad normal se ofrece al entrar a la sala."
    elif bonus_pact_remaining:
        _prepare_pact_menu(true)
        _open_menu("pacts")
    else:
        status_label.text = "No tienes pactos extra. Puedes ganarlos con Segunda Oportunidad."

func _on_pacts_changed() -> void:
    if is_instance_valid(pact_pause_summary):
        pact_pause_summary.text = PactManager.fortune_summary()
    if is_instance_valid(stats_label):
        _update_stats_label()

func _create_inventory_menu(hud: CanvasLayer) -> void:
    # La cabecera siempre permanece visible. Solo las tarjetas se desplazan.
    # Antes el resumen de siete líneas hacía crecer el PanelContainer y podía
    # dejar el botón Salir fuera de la pantalla en dispositivos móviles.
    inventory_panel = PanelContainer.new()
    inventory_panel.name = "MochilaTactil"
    inventory_panel.position = Vector2(12, 136)
    inventory_panel.size = Vector2(516, 678)
    inventory_panel.visible = false
    inventory_panel.process_mode = Node.PROCESS_MODE_ALWAYS
    hud.add_child(inventory_panel)
    var layout := VBoxContainer.new()
    layout.mouse_filter = Control.MOUSE_FILTER_PASS
    layout.add_theme_constant_override("separation", 4)
    inventory_panel.add_child(layout)

    var header := HBoxContainer.new()
    header.mouse_filter = Control.MOUSE_FILTER_PASS
    layout.add_child(header)
    inventory_title = Label.new()
    inventory_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    inventory_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    inventory_title.add_theme_font_size_override("font_size", 14)
    header.add_child(inventory_title)
    var exit_button := Button.new()
    exit_button.text = "CERRAR Y JUGAR"
    exit_button.custom_minimum_size = Vector2(152, 42)
    exit_button.pressed.connect(_close_menus)
    header.add_child(exit_button)

    # El detalle completo se consulta en el filtro EQUIPO, sin consumir la
    # altura que necesita la lista para deslizarse en Android.
    inventory_equipped_label = Label.new()
    inventory_equipped_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    inventory_equipped_label.clip_text = true
    inventory_equipped_label.add_theme_font_size_override("font_size", 11)
    layout.add_child(inventory_equipped_label)

    var filters_grid := GridContainer.new()
    filters_grid.columns = 5
    filters_grid.mouse_filter = Control.MOUSE_FILTER_PASS
    filters_grid.add_theme_constant_override("h_separation", 3)
    filters_grid.add_theme_constant_override("v_separation", 3)
    layout.add_child(filters_grid)
    var filter_names := ["TODOS", "EQUIPO", "ARMAS", "CASCOS", "PECHOS", "PANT.", "BOTAS", "AMULET.", "RELIQ."]
    inventory_filter_buttons.clear()
    for index in range(filter_names.size()):
        var choice := Button.new()
        choice.text = filter_names[index]
        choice.custom_minimum_size = Vector2(94, 34)
        choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        choice.add_theme_font_size_override("font_size", 10)
        choice.pressed.connect(_on_inventory_filter_selected.bind(index))
        filters_grid.add_child(choice)
        inventory_filter_buttons.append(choice)

    var tools := HBoxContainer.new()
    tools.mouse_filter = Control.MOUSE_FILTER_PASS
    tools.add_theme_constant_override("separation", 5)
    layout.add_child(tools)
    inventory_sort_button = Button.new()
    inventory_sort_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    inventory_sort_button.pressed.connect(_cycle_inventory_sort)
    tools.add_child(inventory_sort_button)
    var up_button := Button.new()
    up_button.text = "▲ SUBIR"
    up_button.custom_minimum_size = Vector2(102, 38)
    up_button.pressed.connect(_scroll_inventory.bind(-1))
    tools.add_child(up_button)
    var down_button := Button.new()
    down_button.text = "▼ BAJAR"
    down_button.custom_minimum_size = Vector2(102, 38)
    down_button.pressed.connect(_scroll_inventory.bind(1))
    tools.add_child(down_button)

    inventory_scroll = ScrollContainer.new()
    inventory_scroll.name = "MochilaScroll"
    inventory_scroll.custom_minimum_size = Vector2(0, 215)
    inventory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    inventory_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    inventory_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
    inventory_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
    inventory_scroll.scroll_deadzone = 6
    inventory_scroll.get_v_scroll_bar().custom_minimum_size = Vector2(24, 0)
    layout.add_child(inventory_scroll)
    inventory_list = VBoxContainer.new()
    inventory_list.mouse_filter = Control.MOUSE_FILTER_PASS
    inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    inventory_list.add_theme_constant_override("separation", 5)
    inventory_scroll.add_child(inventory_list)

    var scrap_button := Button.new()
    scrap_button.text = "CHATARRERÍA — apostar armas o armaduras"
    scrap_button.custom_minimum_size = Vector2(0, 42)
    scrap_button.pressed.connect(_open_menu.bind("scrap"))
    layout.add_child(scrap_button)
    _update_inventory_filter_buttons()
    _update_inventory_sort_button()

func _update_inventory_filter_buttons() -> void:
    for index in range(inventory_filter_buttons.size()):
        var button: Button = inventory_filter_buttons[index]
        var selected: bool = INVENTORY_FILTERS[index] == inventory_filter
        button.modulate = Color(0.68, 1.0, 0.78) if selected else Color.WHITE

func _update_inventory_sort_button() -> void:
    if is_instance_valid(inventory_sort_button):
        var labels := {"type": "TIPO", "rarity": "RAREZA", "level": "NIVEL", "name": "NOMBRE"}
        inventory_sort_button.text = "ORDEN: %s ↻" % str(labels.get(inventory_sort, "TIPO"))

func _on_inventory_filter_selected(index: int) -> void:
    if active_menu != "inventory":
        return
    var next_filter: String = INVENTORY_FILTERS[clampi(index, 0, INVENTORY_FILTERS.size() - 1)]
    if next_filter == inventory_filter:
        return # Evita destruir y recrear tarjetas al pulsar el mismo filtro.
    inventory_filter = next_filter
    _update_inventory_filter_buttons()
    inventory_scroll.scroll_vertical = 0
    _rebuild_inventory_list()

func _cycle_inventory_sort() -> void:
    if active_menu != "inventory":
        return
    var position: int = INVENTORY_SORTS.find(inventory_sort)
    inventory_sort = INVENTORY_SORTS[(position + 1) % INVENTORY_SORTS.size()]
    _update_inventory_sort_button()
    inventory_scroll.scroll_vertical = 0
    _rebuild_inventory_list()

func _scroll_inventory(direction: int) -> void:
    if active_menu != "inventory" or not is_instance_valid(inventory_scroll):
        return
    inventory_scroll_touched = true
    var step: int = maxi(96, roundi(inventory_scroll.size.y * 0.70))
    inventory_scroll.scroll_vertical = maxi(0, inventory_scroll.scroll_vertical + direction * step)

func _input(event: InputEvent) -> void:
    if active_menu == "scrap" and is_instance_valid(scrap_scroll):
        inventory_drag_touch = -1
        _handle_scrap_touch(event)
        return
    scrap_drag_touch = -1
    # La interfaz móvil NO depende únicamente del gesto nativo del ScrollContainer.
    # Al arrastrar sobre una tarjeta, manejamos el dedo por su índice incluso
    # si un botón hijo retiene el evento de GUI. Los toques normales siguen
    # llegando a los botones. Nunca capturamos dedos fuera del scroll.
    if active_menu != "inventory" or not is_instance_valid(inventory_scroll):
        inventory_drag_touch = -1
        return
    if event is InputEventScreenTouch:
        if event.pressed and inventory_drag_touch == -1:
            var local_pos: Vector2 = inventory_scroll.get_global_transform_with_canvas().affine_inverse() * event.position
            if Rect2(Vector2.ZERO, inventory_scroll.size).has_point(local_pos):
                inventory_drag_touch = event.index
                inventory_drag_last_y = local_pos.y
                inventory_drag_accumulated = 0.0
                inventory_touch_scrolled = false
        elif not event.pressed and event.index == inventory_drag_touch:
            inventory_drag_touch = -1
            # Un arrastre no debe activar accidentalmente Equipar o Vender.
            call_deferred("_clear_inventory_drag_guard")
    elif event is InputEventScreenDrag and event.index == inventory_drag_touch:
        var local_pos: Vector2 = inventory_scroll.get_global_transform_with_canvas().affine_inverse() * event.position
        var delta_y: float = local_pos.y - inventory_drag_last_y
        inventory_drag_last_y = local_pos.y
        inventory_drag_accumulated += delta_y
        # Menos de 10 px es un toque normal sobre Equipar/Vender, no un scroll.
        if not inventory_touch_scrolled and absf(inventory_drag_accumulated) < 10.0:
            return
        if not inventory_touch_scrolled:
            inventory_touch_scrolled = true
            inventory_scroll_touched = true
            delta_y = inventory_drag_accumulated
        inventory_scroll.scroll_vertical = maxi(0, inventory_scroll.scroll_vertical - roundi(delta_y))
        get_viewport().set_input_as_handled()

func _clear_inventory_drag_guard() -> void:
    inventory_touch_scrolled = false

func _create_pause_menu(hud: CanvasLayer) -> void:
    pause_panel = PanelContainer.new()
    pause_panel.name = "PauseMenu"
    pause_panel.position = Vector2(32, 120)
    pause_panel.custom_minimum_size = Vector2(476, 0)
    pause_panel.visible = false
    hud.add_child(pause_panel)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 6)
    pause_panel.add_child(layout)
    var header := HBoxContainer.new()
    layout.add_child(header)
    var title := Label.new()
    title.text = "PARTIDA EN PAUSA"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    perf_button = Button.new()
    perf_button.text = "FPS: OFF"
    perf_button.custom_minimum_size = Vector2(100, 36)
    perf_button.pressed.connect(_toggle_performance_overlay)
    header.add_child(perf_button)
    var explanation := Label.new()
    explanation.text = "Los enemigos, proyectiles y cronómetros están detenidos."
    explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    layout.add_child(explanation)
    pact_pause_summary = Label.new()
    pact_pause_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    pact_pause_summary.add_theme_font_size_override("font_size", 11)
    pact_pause_summary.text = "Pactos: ninguno"
    layout.add_child(pact_pause_summary)
    detail_pause_label = Label.new()
    detail_pause_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detail_pause_label.add_theme_font_size_override("font_size", 10)
    detail_pause_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layout.add_child(detail_pause_label)
    var resume_button := Button.new()
    resume_button.text = "Continuar (Esc / P)"
    resume_button.pressed.connect(_close_menus)
    layout.add_child(resume_button)
    var scrap_button := Button.new()
    scrap_button.text = "CHATARRERÍA — apostar armaduras y armas"
    scrap_button.pressed.connect(_open_menu.bind("scrap"))
    layout.add_child(scrap_button)
    var inventory_button := Button.new()
    inventory_button.text = "Abrir mochila (I)"
    inventory_button.pressed.connect(_open_menu.bind("inventory"))
    layout.add_child(inventory_button)
    # Botón de PRUEBA, también disponible con pantalla táctil en Android.
    var test_black_jack_button := Button.new()
    test_black_jack_button.text = "PRUEBA BLACK JACK (kit + monedas; sin récord)"
    test_black_jack_button.pressed.connect(_debug_grant_fusion_kit)
    layout.add_child(test_black_jack_button)
    for set_id in ["tragaperras", "jackpot"]:
        var set_button := Button.new()
        set_button.text = "PRUEBA %s (4 épicas + 4 legendarias)" % set_id.to_upper()
        set_button.pressed.connect(_debug_grant_set_kit.bind(set_id))
        layout.add_child(set_button)
    var weapon_button := Button.new()
    weapon_button.text = "LABORATORIO DE ARMAS (4 modelos x 4 rarezas)"
    weapon_button.pressed.connect(_open_menu.bind("weapon_lab"))
    layout.add_child(weapon_button)
    var bet_button := Button.new()
    bet_button.text = "Los pactos aparecen al entrar en cada sala"
    bet_button.disabled = true
    bet_button.pressed.connect(_open_menu.bind("betting"))
    layout.add_child(bet_button)

func _create_scrap_menu(hud: CanvasLayer) -> void:
    # Panel limitado al área útil de 540×960. Solo se desplaza el listado;
    # CERRAR Y JUGAR permanece accesible incluso con inventario completo.
    scrap_panel = PanelContainer.new()
    scrap_panel.name = "ChatarreriaTactil"
    scrap_panel.position = Vector2(12, 136)
    scrap_panel.size = Vector2(516, 678)
    scrap_panel.process_mode = Node.PROCESS_MODE_ALWAYS
    scrap_panel.visible = false
    hud.add_child(scrap_panel)
    var layout := VBoxContainer.new()
    layout.mouse_filter = Control.MOUSE_FILTER_PASS
    layout.add_theme_constant_override("separation", 5)
    scrap_panel.add_child(layout)

    var header := HBoxContainer.new()
    header.mouse_filter = Control.MOUSE_FILTER_PASS
    layout.add_child(header)
    var headline := Label.new()
    headline.text = "TODO O BASURA"
    headline.mouse_filter = Control.MOUSE_FILTER_IGNORE
    headline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    headline.add_theme_font_size_override("font_size", 15)
    header.add_child(headline)
    var close_button := Button.new()
    close_button.text = "CERRAR Y JUGAR"
    close_button.custom_minimum_size = Vector2(155, 44)
    close_button.pressed.connect(_close_menus)
    header.add_child(close_button)

    var explanation := Label.new()
    explanation.mouse_filter = Control.MOUSE_FILTER_IGNORE
    explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    explanation.add_theme_font_size_override("font_size", 11)
    explanation.text = "Sacrifica armaduras para conseguir piezas de la MISMA ranura que llevas equipada. Puedes apostar 1 o todos los duplicados; cada pieza tiene su propia tirada."
    layout.add_child(explanation)

    scrap_status = Label.new()
    scrap_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
    scrap_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    scrap_status.max_lines_visible = 2
    scrap_status.add_theme_font_size_override("font_size", 11)
    scrap_status.text = "Elige un arma o armadura de la lista para apostar."
    layout.add_child(scrap_status)

    var controls := HBoxContainer.new()
    controls.mouse_filter = Control.MOUSE_FILTER_PASS
    controls.add_theme_constant_override("separation", 5)
    layout.add_child(controls)
    var back_button := Button.new()
    back_button.text = "◀ MOCHILA"
    back_button.custom_minimum_size = Vector2(150, 42)
    back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    back_button.pressed.connect(_open_menu.bind("inventory"))
    controls.add_child(back_button)
    var up_button := Button.new()
    up_button.text = "▲ SUBIR"
    up_button.custom_minimum_size = Vector2(112, 42)
    up_button.pressed.connect(_scroll_scrap.bind(-1))
    controls.add_child(up_button)
    var down_button := Button.new()
    down_button.text = "▼ BAJAR"
    down_button.custom_minimum_size = Vector2(112, 42)
    down_button.pressed.connect(_scroll_scrap.bind(1))
    controls.add_child(down_button)

    scrap_scroll = ScrollContainer.new()
    scrap_scroll.name = "ChatarreriaScroll"
    scrap_scroll.custom_minimum_size = Vector2(0, 215)
    scrap_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scrap_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scrap_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scrap_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
    scrap_scroll.scroll_deadzone = 6
    scrap_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
    scrap_scroll.get_v_scroll_bar().custom_minimum_size = Vector2(26, 0)
    layout.add_child(scrap_scroll)
    scrap_list = VBoxContainer.new()
    scrap_list.mouse_filter = Control.MOUSE_FILTER_PASS
    scrap_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scrap_list.add_theme_constant_override("separation", 5)
    scrap_scroll.add_child(scrap_list)

    scrap_confirmation = ConfirmationDialog.new()
    scrap_confirmation.process_mode = Node.PROCESS_MODE_ALWAYS
    scrap_confirmation.title = "Confirmar apuesta de equipamiento"
    scrap_confirmation.confirmed.connect(_confirm_scrap)
    add_child(scrap_confirmation)

func _scroll_scrap(direction: int) -> void:
    if active_menu != "scrap" or not is_instance_valid(scrap_scroll):
        return
    scrap_scroll_touched = true
    var step: int = maxi(96, roundi(scrap_scroll.size.y * 0.70))
    scrap_scroll.scroll_vertical = maxi(0, scrap_scroll.scroll_vertical + direction * step)

func _handle_scrap_touch(event: InputEvent) -> void:
    # Dedo capturado por índice. Las tarjetas tienen botones, por eso el gesto
    # se administra desde _input, antes de que la GUI consuma el arrastre.
    if is_instance_valid(scrap_confirmation) and scrap_confirmation.visible:
        scrap_drag_touch = -1
        return
    if event is InputEventScreenTouch:
        if event.pressed and scrap_drag_touch == -1:
            var local_pos: Vector2 = scrap_scroll.get_global_transform_with_canvas().affine_inverse() * event.position
            if Rect2(Vector2.ZERO, scrap_scroll.size).has_point(local_pos):
                scrap_drag_touch = event.index
                scrap_drag_last_y = local_pos.y
                scrap_drag_accumulated = 0.0
                scrap_touch_scrolled = false
        elif not event.pressed and event.index == scrap_drag_touch:
            scrap_drag_touch = -1
            call_deferred("_clear_scrap_drag_guard")
    elif event is InputEventScreenDrag and event.index == scrap_drag_touch:
        var local_pos: Vector2 = scrap_scroll.get_global_transform_with_canvas().affine_inverse() * event.position
        var delta_y: float = local_pos.y - scrap_drag_last_y
        scrap_drag_last_y = local_pos.y
        scrap_drag_accumulated += delta_y
        if not scrap_touch_scrolled and absf(scrap_drag_accumulated) < 10.0:
            return
        if not scrap_touch_scrolled:
            scrap_touch_scrolled = true
            scrap_scroll_touched = true
            delta_y = scrap_drag_accumulated
        scrap_scroll.scroll_vertical = maxi(0, scrap_scroll.scroll_vertical - roundi(delta_y))
        get_viewport().set_input_as_handled()

func _clear_scrap_drag_guard() -> void:
    scrap_touch_scrolled = false

func _refresh_scrap_menu() -> void:
    if not is_instance_valid(scrap_list):
        return
    scrap_build_queue.clear()
    scrap_scroll_generation += 1
    scrap_build_saved_scroll = scrap_scroll.scroll_vertical if is_instance_valid(scrap_scroll) else 0
    scrap_scroll_touched = false
    for child in scrap_list.get_children():
        scrap_list.remove_child(child)
        child.queue_free()
    scrap_build_queue = InventoryManager.scrap_groups()
    if scrap_build_queue.is_empty():
        var empty := Label.new()
        empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        empty.text = "No hay armas ni armaduras en la mochila para apostar."
        empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
        scrap_list.add_child(empty)
    else:
        _populate_scrap_batch()

func _restore_scrap_scroll(saved: int, generation: int) -> void:
    if active_menu == "scrap" and generation == scrap_scroll_generation and is_instance_valid(scrap_scroll) and not scrap_scroll_touched:
        scrap_scroll.scroll_vertical = saved

func _populate_scrap_batch() -> void:
    if active_menu != "scrap":
        scrap_build_queue.clear()
        return
    for _batch in range(mini(5, scrap_build_queue.size())):
        var entry: Dictionary = scrap_build_queue.pop_front()
        var item_id: String = str(entry["id"])
        var rarity: String = str(entry["rarity"])
        var count: int = int(entry["count"])
        var preview: Dictionary = InventoryManager.scrap_preview(item_id, rarity, 1)
        var target_id: String = str(preview.get("reward_id", ""))
        var target_label: String = str(DB.get_def(target_id).get("name", "sin pieza equipada"))
        var rule: Dictionary = InventoryManager.SCRAP_RULES.get(rarity, {})
        var card := VBoxContainer.new()
        card.mouse_filter = Control.MOUSE_FILTER_PASS
        card.add_theme_constant_override("separation", 2)
        scrap_list.add_child(card)
        var title := Label.new()
        title.mouse_filter = Control.MOUSE_FILTER_IGNORE
        title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        title.text = "%s (%s) ×%d → %s (%s) ×%d | %.0f%% de éxito" % [
            str(DB.get_def(item_id).get("name", "")), str(DB.RARITY_NAMES.get(rarity, rarity)), count,
            target_label, str(DB.RARITY_NAMES.get(str(rule.get("reward", "common")), "")),
            int(rule.get("payout", 1)), float(rule.get("chance", 0.0)) * 100.0]
        title.add_theme_font_size_override("font_size", 11)
        card.add_child(title)
        if not bool(preview.get("ok", false)):
            var explanation_label := Label.new()
            explanation_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
            explanation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            explanation_label.text = "No disponible: " + str(preview.get("message", "Revisa el equipo de esa ranura."))
            explanation_label.add_theme_font_size_override("font_size", 10)
            card.add_child(explanation_label)
        var actions := HBoxContainer.new()
        actions.mouse_filter = Control.MOUSE_FILTER_PASS
        card.add_child(actions)
        var one := Button.new()
        one.text = "Apostar 1"
        one.mouse_filter = Control.MOUSE_FILTER_PASS
        one.custom_minimum_size = Vector2(0, 42)
        one.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        one.disabled = not bool(preview.get("ok", false))
        one.pressed.connect(_request_scrap.bind(item_id, rarity, 1))
        actions.add_child(one)
        var all := Button.new()
        all.text = "Todos (%d)" % count
        all.mouse_filter = Control.MOUSE_FILTER_PASS
        all.custom_minimum_size = Vector2(0, 42)
        all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var all_preview: Dictionary = InventoryManager.scrap_preview(item_id, rarity, count)
        all.disabled = not bool(all_preview.get("ok", false))
        all.tooltip_text = str(all_preview.get("message", "Una tirada por pieza; una sola animación."))
        all.pressed.connect(_request_scrap.bind(item_id, rarity, count))
        actions.add_child(all)
        var divider := HSeparator.new()
        divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card.add_child(divider)
    if scrap_build_queue.is_empty() and not scrap_scroll_touched:
        call_deferred("_restore_scrap_scroll", scrap_build_saved_scroll, scrap_scroll_generation)

func _request_scrap(item_id: String, rarity: String, count: int) -> void:
    if active_menu != "scrap" or scrap_touch_scrolled:
        return
    var info: Dictionary = InventoryManager.scrap_preview(item_id, rarity, count)
    if not bool(info.get("ok", false)):
        scrap_status.text = str(info.get("message", "Apuesta inválida"))
        return
    pending_scrap = {"id": item_id, "rarity": rarity, "amount": count}
    var prize_name: String = str(DB.get_def(str(info["reward_id"])).get("name", ""))
    var description: String = "¿Sacrificar %d × %s (%s)?\nProbabilidad por pieza: %.0f%%\nSi ganas: %d × %s (%s) por acierto.\nNo se transfieren mejoras. Puedes perder TODAS las piezas." % [
        count, str(DB.get_def(item_id)["name"]), str(DB.RARITY_NAMES[rarity]),
        float(info["chance"]) * 100.0, int(info["payout"]), prize_name, str(DB.RARITY_NAMES[str(info["reward_rarity"])])]
    scrap_confirmation.dialog_text = description
    scrap_confirmation.popup_centered(Vector2i(466, 255))

func _confirm_scrap() -> void:
    if pending_scrap.is_empty() or active_menu != "scrap":
        return
    var result: Dictionary = InventoryManager.scrap_wager(str(pending_scrap["id"]), str(pending_scrap["rarity"]), int(pending_scrap["amount"]))
    pending_scrap.clear()
    scrap_status.text = str(result.get("message", "Apuesta fallida."))
    scrap_status.tooltip_text = scrap_status.text
    _refresh_scrap_menu()

func _create_next_menu(hud: CanvasLayer) -> void:
    next_panel = PanelContainer.new()
    next_panel.position = Vector2(32, 580)
    next_panel.custom_minimum_size = Vector2(476, 166)
    next_panel.visible = false
    hud.add_child(next_panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 7)
    next_panel.add_child(column)
    next_prompt = Label.new()
    next_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    next_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(next_prompt)
    var choices := HBoxContainer.new()
    column.add_child(choices)
    room_rest_button = Button.new()
    room_rest_button.text = "DESCANSAR: +1 corazón"
    room_rest_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    room_rest_button.pressed.connect(_choose_room_reward.bind(true))
    choices.add_child(room_rest_button)
    room_cash_button = Button.new()
    room_cash_button.text = "COBRAR monedas crecientes"
    room_cash_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    room_cash_button.pressed.connect(_choose_room_reward.bind(false))
    choices.add_child(room_cash_button)
    next_button = Button.new()
    next_button.text = "La salida aparece a la DERECHA al escoger premio"
    next_button.disabled = true
    next_button.visible = false
    column.add_child(next_button)
    cashout_button = Button.new()
    cashout_button.text = "RETIRARSE: cerrar partida con victoria"
    cashout_button.pressed.connect(_cash_out_run)
    column.add_child(cashout_button)
    _update_next_panel()

func _create_boss_reward_menu(hud: CanvasLayer) -> void:
    boss_reward_panel = PanelContainer.new()
    boss_reward_panel.position = Vector2(20, 360)
    boss_reward_panel.custom_minimum_size = Vector2(500, 330)
    boss_reward_panel.visible = false
    hud.add_child(boss_reward_panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 11)
    boss_reward_panel.add_child(column)
    var title := Label.new()
    title.text = "VENCISTE AL CROUPIER — APUESTA POR SU RELIQUIA"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(title)
    boss_bonus_label = Label.new()
    boss_bonus_label.text = "Derrota al jefe para obtener monedas."
    boss_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(boss_bonus_label)
    var info := Label.new()
    info.text = "COBRAR: Baraja del Croupier (+2 daño), garantizada.\nAPOSTAR: arriesgas el arma + 50 monedas por la MARCA DEL CROUPIER.\nÉxito 50%: recibes el arma Y una reliquia que electrifica cualquier arma.\nFallo: pierdes las dos recompensas y sufres 18 s de maldición."
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(info)
    var claim := Button.new()
    claim.text = "COBRAR — Baraja del Croupier (100%)"
    claim.pressed.connect(_resolve_boss_reward.bind(false))
    column.add_child(claim)
    boss_gamble_button = Button.new()
    boss_gamble_button.text = "APOSTAR arma + 50 monedas | 50% RELIQUIA"
    boss_gamble_button.pressed.connect(_resolve_boss_reward.bind(true))
    column.add_child(boss_gamble_button)
    var note := Label.new()
    note.text = "La elección es definitiva para este jefe."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(note)

func _create_level_roll_menu(hud: CanvasLayer) -> void:
    level_roll_panel = PanelContainer.new()
    level_roll_panel.position = Vector2(30, 372)
    level_roll_panel.custom_minimum_size = Vector2(480, 255)
    level_roll_panel.visible = false
    hud.add_child(level_roll_panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 13)
    level_roll_panel.add_child(column)
    var title := Label.new()
    title.text = "¡SUBISTE DE NIVEL! — RULETA OBLIGATORIA"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(title)
    level_roll_description = Label.new()
    level_roll_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    level_roll_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    level_roll_description.text = "Gratis: solo estadísticas acumulables.\n25% DAÑO (+4%) | 25% CADENCIA (+4%)\n25% MOVIMIENTO (+3%) | 25% PROYECTIL (+6%)."
    column.add_child(level_roll_description)
    level_roll_spin_button = Button.new()
    level_roll_spin_button.text = "GIRAR RULETA GRATIS"
    level_roll_spin_button.pressed.connect(_spin_level_roll)
    column.add_child(level_roll_spin_button)
    level_roll_accept_button = Button.new()
    level_roll_accept_button.text = "ACEPTAR MEJORA Y CONTINUAR"
    level_roll_accept_button.disabled = true
    level_roll_accept_button.pressed.connect(_accept_level_roll)
    column.add_child(level_roll_accept_button)

func _create_death_roll_menu(hud: CanvasLayer) -> void:
    death_roll_panel = PanelContainer.new()
    death_roll_panel.position = Vector2(27, 354)
    death_roll_panel.custom_minimum_size = Vector2(486, 282)
    death_roll_panel.visible = false
    hud.add_child(death_roll_panel)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 14)
    death_roll_panel.add_child(layout)
    var title := Label.new()
    title.text = "ÚLTIMA APUESTA — ¿DESAFIAR A LA MUERTE?"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(title)
    death_roll_label = Label.new()
    death_roll_label.text = "50%: revives con 1 corazón.\n50%: la partida termina.\nEsta oportunidad solo existe UNA vez por partida."
    death_roll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    death_roll_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    layout.add_child(death_roll_label)
    death_roll_button = Button.new()
    death_roll_button.text = "GIRAR: 50 / 50"
    death_roll_button.pressed.connect(_spin_death_roll)
    layout.add_child(death_roll_button)

func _begin_room(number: int) -> void:
    # Fondo independiente: cambiar de sala no toca navegación, colisiones ni IA.
    var theme: Dictionary = ROOM_THEME_CATALOG.theme_for_room(number)
    room_backdrop.configure(theme, RunManager.arena_rect)
    # Los objetos, monedas y maldiciones persisten ENTRE salas.
    # No hay curación automática: descansar es una decisión de riesgo.
    _close_menus(true)
    entry_pact_required = false
    bonus_pact_remaining = false
    portal_ready = false
    next_panel.visible = false
    room_choice_made = false
    boss_reward_resolved = false
    for child in enemies_root.get_children():
        enemies_root.remove_child(child)
        child.queue_free()
    _build_obstacles(number)
    for bullet in get_tree().get_nodes_in_group("room_projectiles"):
        bullet.queue_free()
    for drop in get_tree().get_nodes_in_group("room_drops"):
        drop.queue_free()
    player.global_position = RunManager.arena_rect.get_center()
    PactManager.begin_room(number)
    bonus_pact_remaining = PactManager.extra_this_room
    level_manager.start_room(number)
    _update_next_panel()
    queue_redraw()
    if RunManager.run_active:
        entry_pact_required = true
        _prepare_pact_menu(false)
        # La sala espera la decisión; no se puede cerrar mediante Escape.
        _open_menu("pacts")
        status_label.text = "SALA %d | Elige uno de los pactos gratuitos o no apuestes." % number

func _build_obstacles(number: int) -> void:
    for old in obstacles_root.get_children():
        obstacles_root.remove_child(old)
        old.queue_free()
    # 4.30: jefe sin obstáculos; en salas normales se validan caminos con el
    # radio físico de los cuerpos a escala 1.6x, nunca con 2x obsoleto.
    var layout: Array = [] if number % 10 == 0 else room_generator.generate(number, RunManager.arena_rect)
    room_navigation.configure(layout, get_viewport_rect().size, RunManager.arena_rect)
    for entry in layout:
        var obstacle = OBSTACLE_SCRIPT.new()
        obstacle.set("half_size", entry[1])
        obstacle.position = entry[0]
        obstacle.add_to_group("room_obstacles")
        obstacles_root.add_child(obstacle)

func _on_room_started(level: int, total: int, is_boss: bool) -> void:
    room_label.text = "JEFE — Habitación %d" % level if is_boss else "Habitación %d — Derrota a %d enemigos" % [level, total]
    if is_instance_valid(compact_room):
        compact_room.text = "JEFE %d" % level if is_boss else "SALA %d" % level
    status_label.text = "JEFE: EL CROUPIER | Esquiva sus ráfagas." if is_boss else "Habitación %d | Elimina la oleada y recoge el botín." % level
    _on_room_progress(0, total)

func _on_room_progress(killed: int, total: int) -> void:
    combat_label.text = "Eliminados: %d / %d | En pantalla: %d" % [killed, total, enemies_root.get_child_count()]

# --- RECOMPENSAS DE JEFE: único camino de acreditación ---
# Evento de muerte -> saldo -> progreso de habitación -> experiencia/ruletas.
func _on_boss_defeated() -> void:
    if level_manager == null or not level_manager.boss_room:
        push_error("ALL IN: derrota de jefe fuera de una habitación de jefe")
        return
    _ensure_boss_bonus(level_manager.level)
    level_manager.register_boss_death()

func _ensure_boss_bonus(room_number: int) -> void:
    var expected: int = RunManager.get_boss_coin_prize(room_number)
    if expected <= 0:
        push_error("ALL IN: la habitación %d no corresponde a un jefe" % room_number)
        return
    RunManager.award_boss_coins(room_number)
    if RunManager.get_boss_coins_paid(room_number) != expected:
        push_error("ALL IN: el bono de sala %d NO está registrado; comprueba la consola de Godot" % room_number)
    # Refrescar también de forma explícita por si la interfaz estaba pausada.
    _update_coin_label(RunManager.coins)

func _on_room_cleared(is_boss: bool) -> void:
    if not RunManager.run_active:
        return
    RunManager.register_room_clear(is_boss)
    # No hay bolsas de monedas en suelo. Un pequeño ingreso fijo en salas normales
    # permite descansar sin bloquear toda la economía de fusiones.
    if not is_boss:
        RunManager.award_normal_room_coins(level_manager.level)
    if is_boss:
        # Respaldo idempotente del cierre de sala; nunca duplica un bono pagado.
        _ensure_boss_bonus(level_manager.level)
        var boss_bonus: int = RunManager.get_boss_coins_paid(level_manager.level)
        if boss_bonus > 0:
            boss_bonus_label.text = "BONO ACREDITADO: +%d MONEDAS | Saldo: %d. Puedes apostar por la reliquia." % [boss_bonus, RunManager.coins]
        else:
            boss_bonus_label.text = "ERROR: bono sin acreditar; consulta el panel Salida/Output de Godot."
    # Las balas de la oleada dejan de ser peligrosas al completar el combate.
    for bullet in get_tree().get_nodes_in_group("room_projectiles"):
        bullet.queue_free()
    if is_boss:
        if pending_level_rolls.is_empty():
            boss_gamble_button.disabled = RunManager.coins < 50
            _open_menu("boss_reward")
        else:
            call_deferred("_show_pending_level_roll")
    else:
        _update_next_panel()
        next_panel.visible = true
        status_label.text = "¡SALA %d SUPERADA! +%d monedas fijas. Recoge equipo, descansa o cobra y sal por la derecha." % [RunManager.current_level, RunManager.NORMAL_ROOM_COMPLETION_COINS]

func _update_next_panel() -> void:
    if next_button == null:
        return
    var boss: bool = level_manager != null and level_manager.boss_room
    room_rest_button.visible = not boss and not room_choice_made
    room_cash_button.visible = not boss and not room_choice_made
    room_cash_button.text = "COBRAR: +%d monedas extra" % maxi(1, int(round(float(RunManager.get_normal_room_cash_reward(level_manager.level)) * PactManager.coin_factor())))
    next_button.disabled = true
    cashout_button.visible = boss and boss_reward_resolved
    if boss:
        next_prompt.text = "¡JEFE DERROTADO! Retírate con la victoria o cruza la puerta derecha."
    elif room_choice_made:
        next_prompt.text = "Recompensa elegida. Sal por la PUERTA de la derecha."
    else:
        next_prompt.text = "¡SALA SUPERADA! +%d monedas fijas. Elige DESCANSAR o COBRAR (+%d base)." % [RunManager.NORMAL_ROOM_COMPLETION_COINS, RunManager.get_normal_room_cash_reward(level_manager.level)]

func _choose_room_reward(rest: bool) -> void:
    if not RunManager.run_active or not level_manager.cleared or level_manager.boss_room or room_choice_made:
        return
    room_choice_made = true
    if rest:
        var before: int = RunManager.player_health
        RunManager.heal_player(1)
        RunManager.rest_choices += 1
        status_label.text = "DESCANSO: recuperaste %d corazón(es). La puerta está a la derecha." % (RunManager.player_health - before)
    else:
        var payout: int = maxi(1, int(round(float(RunManager.get_normal_room_cash_reward(level_manager.level)) * PactManager.coin_factor())))
        RunManager.add_coins(payout)
        RunManager.cash_choices += 1
        status_label.text = "COBRASTE %d monedas (incluye efecto Recaudador/Cazador). La puerta está a la derecha." % payout
    portal_ready = true
    next_panel.visible = false
    queue_redraw()
    _update_next_panel()
    status_label.text += " Sal por la puerta iluminada a la derecha."

func _cash_out_run() -> void:
    if not RunManager.run_active or not level_manager.cleared or not level_manager.boss_room or not boss_reward_resolved:
        return
    RunManager.finish_run()

func _deliver_boss_item_by_id(item_id: String) -> String:
    var definition: Dictionary = DB.get_def(item_id)
    var result: Dictionary = InventoryManager.add_item(item_id)
    if not bool(result["ok"]):
        var drop: Node2D = DROP_SCENE.instantiate() as Node2D
        drop.set("item_id", item_id)
        get_tree().current_scene.add_child(drop)
        drop.global_position = player.global_position + Vector2(45, 0)
        return "%s (en el suelo: mochila llena)" % str(definition["name"])
    return str(definition["name"])

func _resolve_boss_reward(gamble: bool) -> void:
    if boss_reward_resolved or not RunManager.run_active:
        return
    if gamble and not RunManager.spend_coins(50):
        status_label.text = "Necesitas 50 monedas para apostar; puedes cobrar el premio seguro."
        return
    boss_reward_resolved = true
    if not gamble:
        status_label.text = "COBRASTE el arma del jefe: %s." % _deliver_boss_item_by_id("croupier_blade")
    elif randf() < 0.50:
        RunManager.record_bet(true)
        var weapon_name: String = _deliver_boss_item_by_id("croupier_blade")
        InventoryManager.grant_relic("croupier_mark")
        status_label.text = "¡RELIQUIA! %s + Marca del Croupier. Equipa cualquier arma para activar rayos." % weapon_name
    else:
        RunManager.record_bet(false)
        RunManager.apply_curse(18.0)
        status_label.text = "PERDISTE: 50 monedas, arma y reliquia. Maldición 18 s."
    room_choice_made = true
    _close_menus(true)
    _update_next_panel()
    next_panel.visible = true
    portal_ready = true
    queue_redraw()

func _try_exit_through_portal() -> void:
    if not portal_ready or not level_manager.cleared or not room_choice_made or not pending_level_rolls.is_empty() or active_menu != "":
        return
    portal_ready = false  # Impide ejecutar la transición varias veces en el mismo frame.
    # Levantamos los objetos cercanos automáticamente si hay espacio; los demás
    # quedan en la sala anterior, tal como ocurre al abandonar un cuarto de mazmorra.
    var collected: int = 0
    var remaining: int = 0
    for drop in get_tree().get_nodes_in_group("room_drops"):
        if not is_instance_valid(drop) or not drop.has_method("collect_to_player"):
            continue
        if drop.is_queued_for_deletion():
            continue
        if InventoryManager.is_full():
            remaining += 1
        else:
            if drop.has_method("collect_item_to_player") and drop.collect_item_to_player():
                collected += 1
            else:
                remaining += 1
    _advance_room()
    if collected > 0:
        status_label.text = "PUERTA: %d objeto(s) recuperados. %s" % [collected, status_label.text]
    if remaining > 0:
        status_label.text += " | Quedaron %d objeto(s) en la sala anterior por mochila llena." % remaining

func _advance_room() -> void:
    if not RunManager.run_active or not level_manager.cleared:
        return
    if active_menu != "" or not room_choice_made or not pending_level_rolls.is_empty():
        status_label.text = "Elige el premio de sala y busca la PUERTA a la derecha."
        return
    if level_manager.boss_room and not boss_reward_resolved:
        return
    _begin_room(RunManager.current_level + 1)

func _debug_grant_fusion_kit() -> void:
    if black_jack_debug_kit_given:
        status_label.text = "BLACK JACK: kit de prueba ya recibido en esta partida."
        return
    # F7 o botón de pausa: conjuntos común, épico y legendario;
    # más duplicados para comprobar las mismas fusiones/ascensiones.
    var kit: Array[String] = []
    for slot in ["helmet", "chest", "legs", "boots"]:
        kit.append("bj_%s_common" % slot)
        kit.append("bj_%s_epic" % slot)
        kit.append("bj_%s_legendary" % slot)
    for i in range(6):
        kit.append("bj_helmet_common")
    for i in range(8):
        kit.append("bj_chest_rare")
    if InventoryManager.items.size() + kit.size() > InventoryManager.CAPACITY:
        status_label.text = "F7 necesita %d espacios libres." % kit.size()
        return
    RunManager.debug_used = true
    black_jack_debug_kit_given = true
    for item_id in kit:
        InventoryManager.add_item(item_id)
    RunManager.add_coins(4000)
    status_label.text = "BLACK JACK: épico 2 balas al 70%%; legendario 4 al 45%%. Récord desactivado."

func _debug_grant_set_kit(set_id: String) -> void:
    if debug_set_kits_given.has(set_id):
        status_label.text = "Kit %s ya recibido en esta partida." % set_id.to_upper()
        return
    var prefix: String = str(DB.ARMOR_SET_PREFIXES.get(set_id, ""))
    if prefix == "":
        return
    var kit: Array[String] = []
    for slot in ["helmet", "chest", "legs", "boots"]:
        kit.append("%s_%s_epic" % [prefix, slot])
        kit.append("%s_%s_legendary" % [prefix, slot])
    if InventoryManager.items.size() + kit.size() > InventoryManager.CAPACITY:
        status_label.text = "Necesitas %d espacios libres para este kit." % kit.size()
        return
    RunManager.debug_used = true
    debug_set_kits_given[set_id] = true
    for item_id in kit:
        InventoryManager.add_item(item_id)
    RunManager.add_coins(1500)
    status_label.text = "PRUEBA %s lista. Equipa las cuatro piezas épicas/legendarias. Récord desactivado." % set_id.to_upper()

func _create_weapon_lab_menu(hud: CanvasLayer) -> void:
    # Laboratorio interno accesible tanto en PC como con pantalla táctil.
    # Cada botón crea (una sola vez) y EQUIPA la combinación elegida.
    # No entregamos 16 piezas de golpe ni alteramos el inventario normal.
    weapon_lab_panel = PanelContainer.new()
    weapon_lab_panel.name = "LaboratorioArmas43130"
    weapon_lab_panel.position = Vector2(16, 165)
    weapon_lab_panel.custom_minimum_size = Vector2(508, 0)
    weapon_lab_panel.visible = false
    hud.add_child(weapon_lab_panel)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 8)
    weapon_lab_panel.add_child(layout)
    var heading := Label.new()
    heading.text = "LABORATORIO DE ARMAS | 4.31.32"
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 16)
    layout.add_child(heading)
    var explanation := Label.new()
    explanation.text = "Toca una rareza para obtenerla y equiparla al instante.\nSolo pruebas: desactiva el récord de esta partida."
    explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    explanation.add_theme_font_size_override("font_size", 12)
    layout.add_child(explanation)
    var rarity_names: Array[String] = ["COMÚN", "RARA", "ÉPICA", "LEGENDARIA"]
    var rarity_ids: Array[String] = ["common", "rare", "epic", "legendary"]
    var weapon_names: Array[String] = ["PISTOLA", "ESCOPETA", "SUBFUSIL", "DESERT EAGLE"]
    var weapon_ids: Array[String] = ["pistol", "shotgun", "smg", "deagle"]
    for weapon_index in range(weapon_ids.size()):
        var row_heading := Label.new()
        row_heading.text = weapon_names[weapon_index]
        row_heading.add_theme_font_size_override("font_size", 12)
        layout.add_child(row_heading)
        var choices := HBoxContainer.new()
        choices.alignment = BoxContainer.ALIGNMENT_CENTER
        choices.add_theme_constant_override("separation", 3)
        layout.add_child(choices)
        for rarity_index in range(rarity_ids.size()):
            var choice := Button.new()
            choice.text = rarity_names[rarity_index]
            choice.custom_minimum_size = Vector2(115, 45)
            choice.add_theme_font_size_override("font_size", 10)
            choice.pressed.connect(_debug_select_weapon.bind(weapon_ids[weapon_index], rarity_ids[rarity_index]))
            choices.add_child(choice)
    weapon_lab_status = Label.new()
    weapon_lab_status.text = "Selecciona cualquier arma para probarla en el escenario."
    weapon_lab_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    weapon_lab_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    weapon_lab_status.add_theme_font_size_override("font_size", 11)
    layout.add_child(weapon_lab_status)
    var back_button := Button.new()
    back_button.text = "VOLVER A PAUSA"
    back_button.custom_minimum_size = Vector2(0, 46)
    back_button.pressed.connect(_open_menu.bind("pause"))
    layout.add_child(back_button)
    var play_button := Button.new()
    play_button.text = "CERRAR LABORATORIO Y PROBAR"
    play_button.custom_minimum_size = Vector2(0, 46)
    play_button.pressed.connect(_close_menus)
    layout.add_child(play_button)

func _debug_select_weapon(weapon_type: String, rarity: String) -> void:
    if not RunManager.run_active or active_menu != "weapon_lab":
        return
    var item_id: String = "%s_%s" % [weapon_type, rarity]
    # Al seleccionar una variante ya obtenida, la reutilizamos sin duplicarla.
    var already_equipped: Dictionary = InventoryManager.get_equipped_entry("weapon")
    if not already_equipped.is_empty() and str(already_equipped.get("id", "")) == item_id and str(already_equipped.get("rarity", "")) == rarity:
        weapon_lab_status.text = "Esa arma ya está equipada. Cierra el menú para verla."
        return
    var target_uid: int = -1
    for entry in InventoryManager.items:
        if str(entry.get("id", "")) == item_id and str(entry.get("rarity", "")) == rarity:
            target_uid = int(entry["uid"])
            break
    if target_uid < 0:
        var result: Dictionary = InventoryManager.add_item(item_id)
        if not bool(result.get("ok", false)):
            weapon_lab_status.text = str(result.get("message", "No hay espacio para esa arma."))
            return
        target_uid = int(result["entry"]["uid"])
    var equipped_result: Dictionary = InventoryManager.equip_item(target_uid)
    if not bool(equipped_result.get("ok", false)):
        weapon_lab_status.text = str(equipped_result.get("message", "No se pudo equipar."))
        return
    RunManager.debug_used = true
    weapon_lab_status.text = "%s / %s equipada. Cierra el menú para revisar las 8 direcciones. (SIN RÉCORD)" % [weapon_type.to_upper(), rarity.to_upper()]

func _debug_jump_to_boss() -> void:
    # Exclusivamente para probar la etapa 4. Eliminar en una versión final.
    if not RunManager.run_active:
        return
    _close_menus()
    RunManager.debug_used = true
    RunManager.player_health = RunManager.max_health
    RunManager.health_changed.emit(RunManager.player_health)
    var result: Dictionary = InventoryManager.add_item("pistol_rare")
    if bool(result["ok"]):
        InventoryManager.equip_item(int(result["entry"]["uid"]))
    _begin_room(10)
    status_label.text = "PRUEBA F8 | El jefe aparece en sala 10. Esta partida NO registra récord."

func _on_boss_coins_awarded(room_number: int, amount: int) -> void:
    # Confirmación visible inmediata, incluso si se abre después una ruleta de nivel.
    if is_instance_valid(status_label):
        status_label.text = "¡JEFE DE SALA %d DERROTADO! +%d MONEDAS | Saldo: %d" % [room_number, amount, RunManager.coins]
    if is_instance_valid(boss_bonus_label):
        boss_bonus_label.text = "¡BONO RECIBIDO! +%d MONEDAS | Saldo actual: %d" % [amount, RunManager.coins]

func _update_coin_label(amount: int) -> void:
    coin_label.text = "Monedas: %d" % amount
    if is_instance_valid(compact_coins):
        compact_coins.text = str(amount)
    if active_menu == "pacts" and is_instance_valid(pact_reroll_button):
        _render_pact_offers()
    if active_menu == "inventory" and is_instance_valid(inventory_list):
        # El dinero y el inventario pueden cambiar en una misma fusión.
        # Coalescer ambas señales evita dos reconstrucciones de 50 tarjetas.
        _schedule_inventory_rebuild()

func _update_health_label(amount: int) -> void:
    # Los tres corazones normales siguen siendo el límite ACTUAL.
    # El HUD admite más iconos para un futuro amuleto/conjunto, pero
    # esta actualización NO concede vida extra ni cambia el combate.
    var maximum: int = maxi(0, RunManager.get_effective_max_health())
    var hearts := ""
    for i in range(maximum):
        hearts += "♥ " if i < amount else "♡ "
    var set_shield: String = ""
    if RunManager.set_shield_active:
        set_shield = " | ESCUDO TP: LISTO"
    elif RunManager.set_shield_interval > 0.0:
        set_shield = " | ESCUDO TP: RECARGANDO"
    health_label.text = "CORAZONES: %s | Escudo: %d%s" % [hearts, RunManager.shield_charges, set_shield]
    var previous_health: int = _heart_last_amount
    _render_pixel_hearts(amount, maximum)
    # Solo animamos el daño REAL; parry/evasión/escudo no afectan corazones.
    if previous_health >= 0 and amount < previous_health:
        _animate_lost_heart(amount)
    if is_instance_valid(compact_shield) and compact_shield.visible != RunManager.set_shield_active:
        compact_shield.visible = RunManager.set_shield_active

func _render_pixel_hearts(amount: int, maximum: int) -> void:
    if not is_instance_valid(compact_health):
        return
    if (_heart_last_amount == amount and _heart_last_maximum == maximum
            and compact_heart_icons.size() == maximum):
        return
    # Crear/destruir solo si CAMBIA el máximo, no cada vez que se recibe daño.
    while compact_heart_icons.size() < maximum:
        var icon := TextureRect.new()
        icon.name = "Corazon_%02d" % (compact_heart_icons.size() + 1)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        compact_health.add_child(icon)
        compact_heart_icons.append(icon)
    while compact_heart_icons.size() > maximum:
        var removed: TextureRect = compact_heart_icons.pop_back()
        compact_health.remove_child(removed)
        removed.queue_free()
    # Ajuste preventivo de ancho para futuras builds con más de 3 corazones.
    var edge: float = 28.0 if maximum <= 6 else (24.0 if maximum <= 9 else 20.0)
    for i in range(compact_heart_icons.size()):
        var icon: TextureRect = compact_heart_icons[i]
        var desired_size := Vector2(edge, edge)
        if icon.custom_minimum_size != desired_size:
            icon.custom_minimum_size = desired_size
        var extra: bool = i >= BASE_HUD_HEARTS
        var target_texture: Texture2D
        if extra:
            target_texture = HUD_HEART_EXTRA_FULL if i < amount else HUD_HEART_EXTRA_EMPTY
        else:
            target_texture = HUD_HEART_FULL if i < amount else HUD_HEART_EMPTY
        if icon.texture != target_texture:
            icon.texture = target_texture
    _heart_last_amount = amount
    _heart_last_maximum = maximum

# Pequeño golpe visual del corazón que se acaba de vaciar: sin modificar vida.
# Se anima un control existente y no se crean texturas/timers cada fotograma.
func _animate_lost_heart(health_after_hit: int) -> void:
    if health_after_hit < 0 or health_after_hit >= compact_heart_icons.size():
        return
    var heart: TextureRect = compact_heart_icons[health_after_hit]
    if not is_instance_valid(heart):
        return
    # El contenedor conserva su tamaño; el escalado es solamente visual.
    heart.pivot_offset = heart.custom_minimum_size * 0.5
    heart.scale = Vector2(1.17, 1.17)
    heart.modulate = Color(1.0, 0.48, 0.48, 1.0)
    var pulse: Tween = create_tween()
    pulse.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    pulse.set_parallel(true)
    pulse.tween_property(heart, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    pulse.tween_property(heart, "modulate", Color.WHITE, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _update_stats_label() -> void:
    var curse := " | MALDICIÓN: %d s" % int(ceil(RunManager.curse_remaining)) if RunManager.curse_remaining > 0.0 else ""
    var speed := int(round(100.0 * (RunManager.speed_bonus + RunManager.level_speed_bonus + InventoryManager.get_equipped_bonus("speed") + PactManager.get_stat("speed"))))
    var attack := int(round(100.0 * (RunManager.attack_bonus + InventoryManager.get_equipped_bonus("attack") + PactManager.get_stat("attack") + InventoryManager.jackpot_attack_penalty())))
    var damage: float = 1.0 + float(RunManager.level_damage_bonus) + InventoryManager.get_equipped_bonus("damage")
    var level_pct := int(round(RunManager.level_damage_percent_bonus * 100.0))
    var chest_pct := int(round(InventoryManager.get_equipped_bonus("damage_pct") * 100.0))
    var pact_pct := int(round(PactManager.damage_modifier() * 100.0))
    var crit := int(round(100.0 * clampf(InventoryManager.get_equipped_bonus("crit") + PactManager.crit_chance_bonus(), 0.0, 0.65)))
    var critical_bonus := int(round(InventoryManager.get_equipped_bonus("crit_damage") * 100.0))
    var aim := int(round(InventoryManager.get_equipped_bonus("accuracy") * 100.0))
    var evade := int(round(InventoryManager.get_equipped_bonus("evasion") * 100.0))
    var parry := int(round(InventoryManager.get_equipped_bonus("parry") * 100.0))
    var block_pct := int(round(100.0 * RunManager.get_block_chance()))
    var projectile_pct := int(round(RunManager.level_projectile_speed_bonus * 100.0))
    var base_pct: int = int(round(RunManager.PLAYER_GLOBAL_DAMAGE_BONUS * 100.0))
    stats_label.text = "Daño %.2f (+%d%% base/%d%% pecho/%d%% Nv./%+d%% pacto) | Crít. %d%% (+%d%% daño)\nPrec. %d%% | Evas. %d%% | Parry %d%% | Bloq. %d%%\nVel. %+d%% | Cad. %+d%% | Proy. %+d%%%s" % [damage, base_pct, chest_pct, level_pct, pact_pct, crit, critical_bonus, aim, evade, parry, block_pct, speed, attack, projectile_pct, curse]
    if xp_label != null:
        xp_label.text = "PERSONAJE Nv. %d | XP %d/%d | Resistencia de equipo evita impactos" % [RunManager.character_level, RunManager.xp, RunManager.xp_to_next]
    if is_instance_valid(detail_pause_label) and is_instance_valid(equipment_label):
        detail_pause_label.text = xp_label.text + "\n" + stats_label.text + "\n" + equipment_label.text.substr(0, 120)

func _on_inventory_changed() -> void:
    bag_label.text = "Mochila: %d/%d | I: administrar" % [InventoryManager.items.size(), InventoryManager.CAPACITY]
    equipment_label.text = "EQUIPO\nCasco: %s\nPecho: %s\nPantalón: %s\nBotas: %s\nAmuleto: %s\nArma: %s\nReliquia: %s" % [
        InventoryManager.get_slot_name("helmet"),
        InventoryManager.get_slot_name("chest"),
        InventoryManager.get_slot_name("legs"),
        InventoryManager.get_slot_name("boots"),
        InventoryManager.get_slot_name("charm"),
        InventoryManager.get_slot_name("weapon"),
        InventoryManager.get_relic_name()
    ]
    equipment_label.text += "\nBLACK JACK %d/4 · DISPAROS x%d | TP %d/4 · ESCUDO | JP %d/4 · DAÑO x%.1f" % [InventoryManager.black_jack_progress(), InventoryManager.black_jack_projectiles(), InventoryManager.set_progress("tragaperras"), InventoryManager.set_progress("jackpot"), InventoryManager.jackpot_damage_multiplier()]
    if is_instance_valid(inventory_equipped_label):
        inventory_equipped_label.text = "EN USO: %d piezas · BJ %d/4 · TP %d/4 · JP %d/4" % [
            InventoryManager.get_equipped_count(), InventoryManager.black_jack_progress(),
            InventoryManager.set_progress("tragaperras"), InventoryManager.set_progress("jackpot")
        ]
    _update_stats_label()
    _update_health_label(RunManager.player_health)
    if active_menu == "inventory":
        _schedule_inventory_rebuild()

func _on_item_collected(item_name: String) -> void:
    status_label.text = "BOTÍN: %s | Abre el inventario con I." % item_name

func _schedule_inventory_rebuild() -> void:
    if inventory_rebuild_scheduled:
        return
    inventory_rebuild_scheduled = true
    call_deferred("_run_inventory_rebuild")

func _run_inventory_rebuild() -> void:
    inventory_rebuild_scheduled = false
    if active_menu == "inventory":
        _rebuild_inventory_list()

func _rebuild_inventory_list() -> void:
    if not is_instance_valid(inventory_list):
        return
    # No reconstruir durante el combate ni crear hasta 50 tarjetas en un frame.
    inventory_build_queue.clear()
    inventory_scroll_generation += 1
    var old_scroll: int = inventory_scroll.scroll_vertical if is_instance_valid(inventory_scroll) else 0
    inventory_build_saved_scroll = old_scroll
    inventory_scroll_touched = false
    for child in inventory_list.get_children():
        inventory_list.remove_child(child)
        child.queue_free()
    inventory_title.text = "MOCHILA %d/%d · %d equipados + reliquia" % [
        InventoryManager.items.size(), InventoryManager.CAPACITY,
        InventoryManager.get_equipped_count()
    ]
    if inventory_filter == "relic":
        var relic_label := Label.new()
        relic_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        relic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        relic_label.text = "RELIQUIA ACTIVA: %s\nLas reliquias de jefe son especiales: no ocupan mochila ni se venden o fusionan como armaduras." % InventoryManager.get_relic_name()
        inventory_list.add_child(relic_label)
        return
    if inventory_filter == "equipped":
        var count := 0
        for slot in DB.SLOT_ORDER:
            var worn: Dictionary = InventoryManager.get_equipped_entry(str(slot))
            if worn.is_empty():
                var empty_slot := Label.new()
                empty_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
                empty_slot.text = "%s: VACÍO" % str(DB.SLOT_NAMES[str(slot)])
                inventory_list.add_child(empty_slot)
            else:
                _add_inventory_card(worn, true)
                count += 1
        if count == 0:
            var placeholder := Label.new()
            placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
            placeholder.text = "Todavía no llevas objetos equipados. Ve a 'Todos' para equiparte."
            placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            inventory_list.add_child(placeholder)
        return
    if inventory_filter != "all":
        var worn_entry: Dictionary = InventoryManager.get_equipped_entry(inventory_filter)
        if not worn_entry.is_empty():
            _add_inventory_section("PUESTA (no ocupa mochila)")
            _add_inventory_card(worn_entry, true)
    var backpack: Array[Dictionary] = []
    for entry in InventoryManager.items:
        if inventory_filter == "all" or str(DB.get_def(str(entry["id"]))["slot"]) == inventory_filter:
            backpack.append(entry)
    backpack.sort_custom(_compare_inventory_entries)
    _add_inventory_section("EN MOCHILA · %d pieza(s)" % backpack.size())
    if backpack.is_empty():
        var empty_label := Label.new()
        empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        empty_label.text = "No hay objetos guardados en esta categoría."
        inventory_list.add_child(empty_label)
    inventory_build_queue = backpack
    # Primera tanda visible de inmediato; resto repartido entre fotogramas.
    _populate_inventory_batch()

func _populate_inventory_batch() -> void:
    if active_menu != "inventory" or not is_instance_valid(inventory_list):
        inventory_build_queue.clear()
        return
    for index in range(mini(INVENTORY_CARDS_PER_FRAME, inventory_build_queue.size())):
        var entry: Dictionary = inventory_build_queue.pop_front()
        _add_inventory_card(entry, false)
    if inventory_build_queue.is_empty() and not inventory_scroll_touched:
        call_deferred("_restore_inventory_scroll", inventory_build_saved_scroll, inventory_scroll_generation)

func _add_inventory_section(title: String) -> void:
    var heading := Label.new()
    heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
    heading.text = title
    heading.add_theme_font_size_override("font_size", 12)
    inventory_list.add_child(heading)

func _compare_inventory_entries(a: Dictionary, b: Dictionary) -> bool:
    var a_def: Dictionary = DB.get_def(str(a["id"]))
    var b_def: Dictionary = DB.get_def(str(b["id"]))
    var a_type: int = DB.SLOT_ORDER.find(str(a_def["slot"]))
    var b_type: int = DB.SLOT_ORDER.find(str(b_def["slot"]))
    var a_rarity: int = DB.RARITY_ORDER.find(InventoryManager.get_entry_rarity(a))
    var b_rarity: int = DB.RARITY_ORDER.find(InventoryManager.get_entry_rarity(b))
    match inventory_sort:
        "rarity":
            if a_rarity != b_rarity:
                return a_rarity > b_rarity
        "level":
            if int(a["level"]) != int(b["level"]):
                return int(a["level"]) > int(b["level"])
        "name":
            if str(a_def["name"]) != str(b_def["name"]):
                return str(a_def["name"]) < str(b_def["name"])
        _:
            if a_type != b_type:
                return a_type < b_type
    return int(a["uid"]) < int(b["uid"])

func _add_inventory_card(entry: Dictionary, worn: bool) -> void:
    var uid: int = int(entry["uid"])
    var item_id: String = str(entry["id"])
    var definition: Dictionary = DB.get_def(item_id)
    var lvl: int = int(entry.get("level", 1))
    var rarity: String = InventoryManager.get_entry_rarity(entry)
    var cap: int = DB.level_cap(item_id, rarity)
    var candidate: Dictionary = InventoryManager.get_fusion_candidate(uid)
    var fusion_cost: int = InventoryManager.get_fusion_cost(uid)
    var ascension_candidate: Dictionary = InventoryManager.get_ascension_candidate(uid)
    var ascension_cost: int = InventoryManager.get_ascension_cost(uid)
    var card := VBoxContainer.new()
    card.mouse_filter = Control.MOUSE_FILTER_PASS
    card.add_theme_constant_override("separation", 3)
    inventory_list.add_child(card)
    var detail := Label.new()
    detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
    detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var equipped_suffix: String = " [EQUIPADO · NO OCUPA MOCHILA]" if worn else " [MOCHILA]"
    detail.text = "%s | Nv.%d/%d%s\n%s · %s · Poder %.1f\n%s" % [
        str(definition["name"]), lvl, cap, equipped_suffix,
        str(DB.RARITY_NAMES[rarity]), str(DB.SLOT_NAMES[str(definition["slot"])]), DB.power_score(item_id, lvl, rarity),
        DB.stat_text(item_id, lvl, rarity)
    ]
    detail.modulate = Color(str(DB.RARITY_COLORS[rarity]))
    card.add_child(detail)
    var actions := HBoxContainer.new()
    # Los botones pueden pulsarse; arrastrar a través de ellos desplaza la lista.
    actions.mouse_filter = Control.MOUSE_FILTER_PASS
    actions.add_theme_constant_override("separation", 5)
    card.add_child(actions)
    var equipment_button := Button.new()
    equipment_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    equipment_button.text = "Quitar" if worn else "Equipar"
    equipment_button.disabled = worn and InventoryManager.is_full()
    equipment_button.tooltip_text = "Necesitas espacio en mochila para quitar la pieza." if worn else "Colocar en su ranura. Si había otra pieza, vuelve a la mochila."
    equipment_button.mouse_filter = Control.MOUSE_FILTER_PASS
    equipment_button.pressed.connect(_on_equip_pressed.bind(uid))
    actions.add_child(equipment_button)
    var fusion_button := Button.new()
    fusion_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    fusion_button.text = "MÁXIMO" if lvl >= cap else ("Fusionar Nv.%d · %d M" % [lvl + int(candidate.get("level", 0)), fusion_cost] if not candidate.is_empty() else "Sin duplicado")
    fusion_button.disabled = candidate.is_empty() or RunManager.coins < fusion_cost
    fusion_button.tooltip_text = "Fusión: consume un duplicado guardado, misma pieza y rareza. Precio: %d monedas; saldo: %d." % [fusion_cost, RunManager.coins]
    fusion_button.mouse_filter = Control.MOUSE_FILTER_PASS
    fusion_button.pressed.connect(_on_fuse_pressed.bind(uid))
    actions.add_child(fusion_button)
    if lvl >= cap and DB.NEXT_RARITY.has(rarity):
        var ascension_button := Button.new()
        ascension_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        ascension_button.text = "ASCENDER %s · %d M" % [str(DB.RARITY_NAMES[str(DB.NEXT_RARITY[rarity])]), ascension_cost] if not ascension_candidate.is_empty() else "Ascensión: 2 al máx · %d M" % ascension_cost
        ascension_button.disabled = ascension_candidate.is_empty() or RunManager.coins < ascension_cost
        ascension_button.tooltip_text = "Necesitas dos piezas idénticas de la misma rareza, ambas Nv.%d, y %d monedas. Puedes ascender la equipada." % [cap, ascension_cost]
        ascension_button.mouse_filter = Control.MOUSE_FILTER_PASS
        ascension_button.pressed.connect(_on_ascend_pressed.bind(uid))
        card.add_child(ascension_button)
    var sell_button := Button.new()
    sell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sell_button.text = "En uso" if worn else "Vender %d M" % InventoryManager.get_sell_price(uid)
    sell_button.disabled = worn
    sell_button.mouse_filter = Control.MOUSE_FILTER_PASS
    sell_button.pressed.connect(_on_sell_pressed.bind(uid))
    actions.add_child(sell_button)
    var divider := HSeparator.new()
    divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(divider)

func _restore_inventory_scroll(saved: int, generation: int) -> void:
    if active_menu == "inventory" and generation == inventory_scroll_generation and is_instance_valid(inventory_scroll) and not inventory_scroll_touched:
        inventory_scroll.scroll_vertical = saved

func _on_fuse_pressed(uid: int) -> void:
    if inventory_touch_scrolled:
        return
    var result: Dictionary = InventoryManager.fuse_item(uid)
    status_label.text = str(result["message"])

func _on_ascend_pressed(uid: int) -> void:
    if inventory_touch_scrolled:
        return
    var result: Dictionary = InventoryManager.ascend_item(uid)
    status_label.text = str(result["message"])

func _on_equip_pressed(uid: int) -> void:
    if inventory_touch_scrolled:
        return
    var result: Dictionary
    if InventoryManager.is_equipped(uid):
        result = InventoryManager.unequip_item(uid)
    else:
        result = InventoryManager.equip_item(uid)
    status_label.text = str(result["message"])

func _on_sell_pressed(uid: int) -> void:
    if inventory_touch_scrolled:
        return
    var result: Dictionary = InventoryManager.sell_item(uid)
    status_label.text = str(result["message"])

func _on_level_gained(new_level: int) -> void:
    pending_level_rolls.append(new_level)
    status_label.text = "¡PERSONAJE NIVEL %d! Tienes una ruleta gratuita obligatoria." % new_level
    # La muerte del enemigo puede estar ocurriendo dentro de una señal física.
    call_deferred("_show_pending_level_roll")

func _show_pending_level_roll() -> void:
    if not RunManager.run_active or pending_level_rolls.is_empty():
        return
    if active_menu == "level_roll":
        return
    # Nunca ocultamos otra recompensa obligatoria.
    if active_menu != "":
        return
    _start_level_roll()

func _start_level_roll() -> void:
    if pending_level_rolls.is_empty() or not RunManager.run_active:
        return
    level_roll_spun = false
    level_roll_spin_button.disabled = false
    level_roll_accept_button.disabled = true
    level_roll_description.text = "NIVEL %d — Gira gratis. SOLO ESTADÍSTICAS.\n25%% daño (+4%%) | 25%% cadencia (+4%%)\n25%% movimiento (+3%%) | 25%% velocidad de proyectil (+6%%)." % pending_level_rolls[0]
    _open_menu("level_roll")

func _spin_level_roll() -> void:
    if active_menu != "level_roll" or level_roll_spun:
        return
    level_roll_spun = true
    var reward: Dictionary = RunManager.award_level_roll()
    level_roll_description.text = "NIVEL %d — ¡PREMIO!\n%s" % [pending_level_rolls[0], str(reward["message"])]
    level_roll_spin_button.disabled = true
    level_roll_accept_button.disabled = false
    _update_health_label(RunManager.player_health)
    _update_stats_label()

func _accept_level_roll() -> void:
    if active_menu != "level_roll" or not level_roll_spun:
        return
    pending_level_rolls.pop_front()
    _close_menus(true)
    if not pending_level_rolls.is_empty():
        _start_level_roll()
    elif level_manager != null and level_manager.cleared and level_manager.boss_room and not boss_reward_resolved:
        boss_gamble_button.disabled = RunManager.coins < 50
        _open_menu("boss_reward")


func _toggle_performance_overlay() -> void:
    perf_enabled = not perf_enabled
    if is_instance_valid(perf_button):
        perf_button.text = "FPS: ON" if perf_enabled else "FPS: OFF"
    if is_instance_valid(perf_overlay):
        perf_overlay.visible = perf_enabled
    perf_refresh_timer = 0.0
    perf_min_fps = 10000
    perf_slow_samples = 0
    # El monitor no modifica Engine.time_scale, pitch_scale ni la pausa.

func _update_performance_overlay() -> void:
    if not perf_enabled or not is_instance_valid(perf_overlay):
        return
    var fps: int = Engine.get_frames_per_second()
    if fps > 0 and not get_tree().paused:
        perf_min_fps = mini(perf_min_fps, fps)
        if fps < 45:
            perf_slow_samples += 1
    var min_text: String = "--" if perf_min_fps == 10000 else str(perf_min_fps)
    var frame_ms: float = 1000.0 / maxf(1.0, float(fps))
    var audio_pitch: float = AudioDirector.music.pitch_scale if is_instance_valid(AudioDirector.music) else 0.0
    var audio_playing: bool = is_instance_valid(AudioDirector.music) and AudioDirector.music.playing and not AudioDirector.music.stream_paused
    var count: int = enemies_root.get_child_count() if is_instance_valid(enemies_root) else 0
    perf_overlay.text = "FPS %d | min %s | %.1f ms | Enemigos %d\nTiempo %.2f | Audio %.2fx %s | Muestras <45: %d" % [
        fps, min_text, frame_ms, count, Engine.time_scale, audio_pitch,
        "ON" if audio_playing else "PAUSA", perf_slow_samples]

func _process(delta: float) -> void:
    # Main funciona durante pausa para finalizar la animacion ANTES de la UI.
    if death_cinematic_elapsed >= 0.0:
        death_cinematic_elapsed += delta
        if is_instance_valid(player):
            player.call("show_death_cinematic_progress", death_cinematic_elapsed, DEATH_CINEMATIC_DURATION, DEATH_SHARED_HIT_DURATION)
        if death_cinematic_elapsed >= DEATH_CINEMATIC_DURATION:
            death_cinematic_elapsed = -1.0
            if death_cinematic_to_roll:
                _show_death_roll()
            else:
                _show_run_summary(false)
    # Main está en PROCESS_MODE_ALWAYS para que el inventario siga respondiendo
    # aun cuando el mundo se encuentra pausado.
    # Una sola textura cada 0.14 s, no un nodo/partícula por moneda ganada.
    if RunManager.run_active and not get_tree().paused and is_instance_valid(compact_coin_icon):
        coin_frame_timer += delta
        if coin_frame_timer >= COIN_FRAME_SECONDS:
            var advance: int = int(coin_frame_timer / COIN_FRAME_SECONDS)
            coin_frame_timer = fmod(coin_frame_timer, COIN_FRAME_SECONDS)
            coin_frame_index = (coin_frame_index + advance) % HUD_COIN_FRAMES.size()
            compact_coin_icon.texture = HUD_COIN_FRAMES[coin_frame_index]
    if perf_enabled:
        perf_refresh_timer -= delta
        if perf_refresh_timer <= 0.0:
            perf_refresh_timer = 0.5
            _update_performance_overlay()
    if active_menu == "inventory" and not inventory_build_queue.is_empty():
        _populate_inventory_batch()
    if active_menu == "scrap" and not scrap_build_queue.is_empty():
        _populate_scrap_batch()
    hud_timer -= delta
    # Notificaciones transitorias: no ocupan 200 píxeles de pantalla permanentemente.
    if active_menu == "" and RunManager.run_active:
        if status_label.text != toast_previous:
            toast_previous = status_label.text
            toast_countdown = 2.6
        else:
            toast_countdown = maxf(0.0, toast_countdown - delta)
        status_label.visible = toast_countdown > 0.0
    else:
        status_label.visible = false
    if level_notice_timer > 0.0:
        level_notice_timer -= delta
    if RunManager.run_active and not get_tree().paused and portal_ready and active_menu == "" and level_manager.cleared and room_choice_made:
        var r: Rect2 = RunManager.arena_rect
        if player.global_position.distance_to(Vector2(r.end.x - 29.0, r.get_center().y)) <= 37.0:
            _try_exit_through_portal()
    if hud_timer <= 0.0 and record_label != null:
        hud_timer = 0.25
        record_label.text = "Puntos: %d | Récord: %d" % [RunManager.get_score(), RunManager.best_score]

func _open_menu(menu: String) -> void:
    if not RunManager.run_active:
        return
    # Una ruleta obligatoria no puede cerrarse con el teclado ni otro menú.
    if active_menu == "level_roll" and menu != "level_roll":
        return
    if active_menu == "pacts" and entry_pact_required and menu != "pacts":
        return
    for stick in get_tree().get_nodes_in_group("mobile_joystick"):
        stick.cancel_touch()
    inventory_drag_touch = -1
    inventory_drag_accumulated = 0.0
    inventory_touch_scrolled = false
    scrap_drag_touch = -1
    scrap_drag_accumulated = 0.0
    scrap_touch_scrolled = false
    active_menu = menu
    pact_panel.visible = menu == "pacts"
    inventory_panel.visible = menu == "inventory"
    if menu == "inventory":
        _rebuild_inventory_list()
    scrap_panel.visible = menu == "scrap"
    if is_instance_valid(scrap_confirmation) and scrap_confirmation.visible:
        scrap_confirmation.hide()
        pending_scrap.clear()
    if menu == "scrap":
        scrap_scroll.scroll_vertical = 0
        _refresh_scrap_menu()
    pause_panel.visible = menu == "pause"
    weapon_lab_panel.visible = menu == "weapon_lab"
    if menu == "pause":
        _update_stats_label()
    boss_reward_panel.visible = menu == "boss_reward"
    level_roll_panel.visible = menu == "level_roll"
    pause_overlay.visible = true
    get_tree().paused = true

func _close_menus(force: bool = false) -> void:
    if not force and (active_menu == "level_roll" or active_menu == "boss_reward" or active_menu == "death_roll" or (active_menu == "pacts" and entry_pact_required)):
        return
    for stick in get_tree().get_nodes_in_group("mobile_joystick"):
        stick.cancel_touch()
    active_menu = ""
    inventory_drag_touch = -1
    inventory_drag_accumulated = 0.0
    inventory_touch_scrolled = false
    scrap_drag_touch = -1
    scrap_drag_accumulated = 0.0
    scrap_touch_scrolled = false
    inventory_build_queue.clear()
    scrap_build_queue.clear()
    pending_scrap.clear()
    if is_instance_valid(scrap_confirmation) and scrap_confirmation.visible:
        scrap_confirmation.hide()
    scrap_panel.visible = false
    pact_panel.visible = false
    inventory_panel.visible = false
    pause_panel.visible = false
    weapon_lab_panel.visible = false
    boss_reward_panel.visible = false
    level_roll_panel.visible = false
    death_roll_panel.visible = false
    if summary_panel != null:
        summary_panel.visible = false
    pause_overlay.visible = false
    get_tree().paused = false
    # Si el último enemigo otorgó XP mientras otro menú estaba abierto,
    # la ruleta obligatoria no se pierde al cerrar ese menú.
    if not pending_level_rolls.is_empty() and RunManager.run_active:
        call_deferred("_show_pending_level_roll")

func _on_player_hurt() -> void:
    AudioDirector.play_sfx("hurt_player")
    var visual: Node = get_tree().get_first_node_in_group("combat_feedback")
    if visual != null and is_instance_valid(player):
        visual.add_impact(player.global_position, "player", 2.5)

func _on_evasion_triggered() -> void:
    AudioDirector.play_sfx("evasion")
    var visual: Node = get_tree().get_first_node_in_group("combat_feedback")
    if visual != null and is_instance_valid(player):
        visual.add_impact(player.global_position, "evasion")
    if is_instance_valid(status_label):
        status_label.text = "¡EVASIÓN! Evitaste el impacto sin gastar escudo."

func _on_parry_triggered() -> void:
    AudioDirector.play_sfx("parry")
    var visual: Node = get_tree().get_first_node_in_group("combat_feedback")
    if visual != null and is_instance_valid(player):
        visual.add_impact(player.global_position, "parry")
    if is_instance_valid(status_label):
        status_label.text = "¡PARRY! Bloqueaste un impacto y contraatacaste."

func _on_hit_blocked() -> void:
    if status_label != null:
        status_label.text = "¡IMPACTO BLOQUEADO! La protección evitó perder un corazón."
    _update_health_label(RunManager.player_health)

func _on_death_roll_requested() -> void:
    # En la primera muerte, el 50/50 espera la cinematica A o B completa.
    call_deferred("_begin_death_cinematic", true)

func _begin_death_cinematic(should_offer_roll: bool) -> void:
    if RunManager.run_active or death_cinematic_elapsed >= 0.0:
        return
    # Si fallo la ruleta, esta MISMA muerte ya fue mostrada: no repetirla.
    if death_cinematic_shown:
        if should_offer_roll:
            _show_death_roll()
        else:
            _show_run_summary(false)
        return
    death_cinematic_shown = true
    death_cinematic_to_roll = should_offer_roll
    death_cinematic_variant = randi_range(0, 1)
    _close_menus(true)
    active_menu = "death_cinematic"
    get_tree().paused = true
    death_cinematic_elapsed = 0.0
    if is_instance_valid(player):
        player.call("begin_death_cinematic", death_cinematic_variant)
        player.call("show_death_cinematic_progress", 0.0, DEATH_CINEMATIC_DURATION, DEATH_SHARED_HIT_DURATION)

func _show_death_roll() -> void:
    if RunManager.run_active or active_menu == "summary":
        return
    active_menu = "death_roll"
    death_roll_button.disabled = false
    death_roll_label.text = "50% REVIVIR con ♥ 1  |  50% FIN DE PARTIDA\nUna oportunidad por partida: al caer otra vez, se termina."
    death_roll_panel.visible = true
    pause_overlay.visible = true
    get_tree().paused = true
    status_label.text = "La casa te ofrece una última apuesta..."

func _spin_death_roll() -> void:
    if active_menu != "death_roll" or death_roll_button.disabled:
        return
    death_roll_button.disabled = true
    if RunManager.resolve_death_roll():
        # Ventana de gracia para no perder el corazón revivido inmediatamente.
        player.call("reset_death_cinematic")
        player.set("hurt_cooldown", 1.6)
        player.set("hurt_iframe_duration", 1.6)
        death_cinematic_shown = false  # otra muerte se reproduce normalmente
        _close_menus(true)
        status_label.text = "¡REVIVISTE CON UN CORAZÓN! No habrá otra oportunidad."
        _update_health_label(RunManager.player_health)
    # En caso de fallo RunManager.run_ended emite la pantalla de resultados.

func _on_run_ended() -> void:
    # Segunda muerte: nueva seleccion A/B, sin ruleta adicional.
    # Si fallo el 50/50, ya se habia visto y se muestra solo el resumen.
    call_deferred("_begin_death_cinematic", false)

func _on_run_finished(_extracted: bool) -> void:
    _show_run_summary(true)

func _show_run_summary(extracted: bool) -> void:
    _close_menus(true)
    next_panel.visible = false
    summary_title.text = "¡VICTORIA! TE RETIRASTE A TIEMPO" if extracted else "FIN DE PARTIDA — LA CASA GANÓ"
    var total_minutes: int = int(RunManager.elapsed_time / 60.0)
    var seconds: int = int(RunManager.elapsed_time) % 60
    summary_details.text = "Habitaciones: %d   |   Jefes: %d   |   Enemigos: %d\nApuestas ganadas: %d/%d   |   Descansos: %d   |   Cobros: %d\nMonedas restantes: %d   |   Ganadas: %d   |   Gastadas: %d\nTiempo activo: %02d:%02d\nPUNTUACIÓN: %d   |   MEJOR: %d" % [
        RunManager.rooms_cleared, RunManager.bosses_defeated_count, RunManager.enemies_defeated,
        RunManager.bets_won, RunManager.bets_placed, RunManager.rest_choices, RunManager.cash_choices,
        RunManager.coins, RunManager.coins_earned, RunManager.coins_spent,
        total_minutes, seconds, RunManager.get_score(extracted), RunManager.best_score
    ]
    if RunManager.debug_used:
        summary_details.text += "\nPRUEBA F7/F8: resultado no guardado como récord."
    summary_panel.visible = true
    pause_overlay.visible = true
    active_menu = "summary"
    status_label.text = "Partida terminada. Pulsa R o el botón de revancha para comenzar otra."
    get_tree().paused = true

func _create_summary_menu(hud: CanvasLayer) -> void:
    summary_panel = PanelContainer.new()
    summary_panel.position = Vector2(20, 350)
    summary_panel.custom_minimum_size = Vector2(500, 285)
    summary_panel.visible = false
    hud.add_child(summary_panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 13)
    summary_panel.add_child(column)
    summary_title = Label.new()
    summary_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(summary_title)
    summary_details = Label.new()
    summary_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(summary_details)
    var restart_button := Button.new()
    restart_button.text = "NUEVA PARTIDA (R)"
    restart_button.pressed.connect(_request_restart)
    column.add_child(restart_button)

func _request_restart() -> void:
    if RunManager.run_active or restart_pending or active_menu == "death_roll":
        return
    restart_pending = true
    call_deferred("_restart_run")

func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed and not event.echo):
        return
    if event.keycode == KEY_R and not RunManager.run_active:
        get_viewport().set_input_as_handled()
        if active_menu == "summary":
            _request_restart()
        return
    if not RunManager.run_active:
        return
    if active_menu == "boss_reward" or active_menu == "level_roll" or (active_menu == "pacts" and entry_pact_required):
        get_viewport().set_input_as_handled()
        return # Estas decisiones se resuelven en sus botones, no con Escape.
    match event.keycode:
        KEY_N:
            status_label.text = "Para continuar, cruza la PUERTA luminosa de la pared derecha."
            get_viewport().set_input_as_handled()
        KEY_F7:
            if active_menu == "":
                _debug_grant_fusion_kit()
            get_viewport().set_input_as_handled()
        KEY_F9:
            var fps: int = int(Engine.get_frames_per_second())
            var current_speed: float = player.velocity.length()
            status_label.text = "DIAGNÓSTICO FPS %d | Vel. %.1f px/s | Enemigos %d | Rosas %d | Pausa %s" % [fps, current_speed, enemies_root.get_child_count(), level_manager._active_ranged_count(), str(get_tree().paused)]
            get_viewport().set_input_as_handled()
        KEY_F8:
            if active_menu == "":
                _debug_jump_to_boss()
            get_viewport().set_input_as_handled()
        KEY_F10:
            # Prueba de arte/combate del Incubador; disponible solo en el editor.
            if OS.has_feature("editor") and active_menu == "":
                _debug_spawn_incubator()
            get_viewport().set_input_as_handled()
        KEY_I:
            if active_menu == "inventory":
                _close_menus()
            else:
                _open_menu("inventory")
            get_viewport().set_input_as_handled()
        KEY_B:
            _try_open_bonus_pact()
            get_viewport().set_input_as_handled()
        KEY_ESCAPE:
            if active_menu == "":
                _open_menu("pause")
            else:
                _close_menus()
            get_viewport().set_input_as_handled()
        KEY_P:
            if active_menu == "pause":
                _close_menus()
            else:
                _open_menu("pause")
            get_viewport().set_input_as_handled()

func _debug_spawn_incubator() -> void:
    # F10: permite probar el tercer enemigo sin jugar hasta la sala 25.
    # No cambia el RNG de apariciones ni las estadísticas de las partidas normales.
    if level_manager == null or not level_manager.active or level_manager.cleared or level_manager.boss_room:
        status_label.text = "PRUEBA INCUBADOR: entra a una sala normal activa."
        return
    const INCUBATOR_SCENE: PackedScene = preload("res://scenes/enemies/SplitterEnemy.tscn")
    var test_enemy: CharacterBody2D = INCUBATOR_SCENE.instantiate() as CharacterBody2D
    test_enemy.set("max_health", 12)
    test_enemy.set("move_speed", 72.0)
    test_enemy.set("contact_damage", 1)
    test_enemy.scale = Vector2(1.6, 1.6)
    test_enemy.position = room_navigation.closest_walkable(player.global_position + Vector2(0, -205), 24.0)
    # Cuenta como enemigo extra para que la puerta no se abra antes de matarlo.
    level_manager.goal += 1
    level_manager.spawned += 1
    enemies_root.add_child(test_enemy)
    RunManager.debug_used = true  # Una partida de prueba no sobrescribe récords.
    room_label.text = "Habitación %d — Derrota a %d enemigos" % [level_manager.level, level_manager.goal]
    _on_room_progress(level_manager.killed, level_manager.goal)
    status_label.text = "PRUEBA F10: ¡Cráneo Incubador! Derrótalo: debe liberar 2 mini-Cráneos Ígneos."

func _restart_run() -> void:
    # Se ejecuta al terminar el evento de teclado, no dentro de _unhandled_input.
    if not is_inside_tree():
        return
    get_tree().paused = false
    InventoryManager.reset_inventory()
    RunManager.reset_run()
    # Evita reemplazar la escena durante notificaciones o señales.
    get_tree().call_deferred("reload_current_scene")

func _draw() -> void:
    var arena: Rect2 = RunManager.arena_rect
    # El fondo animado se dibuja en RoomBackdrop (z = -50); NUNCA por encima
    # de enemigos, proyectiles, obstáculos o HUD. El fallback clásico queda.
    if room_backdrop == null or not room_backdrop.has_active_theme():
        var viewport_size := get_viewport_rect().size
        var full := Rect2(Vector2.ZERO, viewport_size)
        draw_rect(full, Color("#15161e"), true)
        var palettes := [Color("#25212b"), Color("#252832"), Color("#302532"), Color("#26302d")]
        var floor_color: Color = palettes[int((RunManager.current_level - 1) / 3) % palettes.size()]
        draw_rect(arena, floor_color, true)
        for x in range(int(arena.position.x + 25), int(arena.end.x - 20), 43):
            for y in range(int(arena.position.y + 25), int(arena.end.y - 20), 43):
                draw_circle(Vector2(x, y), 1.2, Color("#41404a"))
        # Borde visual clásico coincide con las paredes físicas.
        draw_rect(arena, Color("#867c94"), false, 3.0)
    if RunManager.current_level % 10 == 0:
        draw_arc(arena.get_center(), 100, 0.0, TAU, 64, Color("#a978b8"), 2)
    if portal_ready and room_choice_made:
        var center: Vector2 = Vector2(arena.end.x - 30.0, arena.get_center().y)
        draw_rect(Rect2(center - Vector2(16, 40), Vector2(32, 80)), Color("#0d161f"), true)
        draw_rect(Rect2(center - Vector2(14, 37), Vector2(28, 74)), Color("#63d5bc"), true)
        draw_rect(Rect2(center - Vector2(9, 30), Vector2(18, 60)), Color("#b7fff0"), true)
        draw_arc(center, 46, 0, TAU, 40, Color("#b7fff0", 0.65), 2)
