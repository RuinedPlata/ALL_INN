extends SceneTree
## Godot 4.7.2: godot --headless --path . --script res://tests/PruebaEstabilidadMovil430.gd
## Sin cambios de balance. Ejecutar desde la carpeta del proyecto.
const MAIN = preload("res://scenes/main/Main.tscn")
const GENERATOR = preload("res://scripts/levels/RoomGenerator.gd")
const PLAYER = preload("res://scripts/player/Player.gd")
const DB = preload("res://scripts/systems/ItemDatabase.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    PactManager.reset_pacts()
    var game: Node2D = MAIN.instantiate() as Node2D
    root.add_child(game)
    game.entry_pact_required = false
    game._close_menus(true)
    await process_frame
    var full_size: Vector2 = game.get_viewport_rect().size
    assert(RunManager.arena_rect.position == Vector2.ZERO)
    assert(RunManager.arena_rect.size == full_size)
    assert(game.player.scale == Vector2(1.6, 1.6))
    assert(PLAYER.weapon_pellet_count("shotgun") == 3)
    assert(PLAYER.weapon_pellet_count("pistol") == 1)
    assert(PLAYER.black_jack_spread_degrees(4).size() == 4)

    var generator = GENERATOR.new()
    for room in [10, 20, 30, 40, 50]:
        assert(generator.generate(room, RunManager.arena_rect).is_empty(),
            "En una sala de jefe nunca deben generarse bloques")
        game._build_obstacles(room)
        assert(game.obstacles_root.get_child_count() == 0)
    var enemy_scene = preload("res://scenes/enemies/BasicEnemy.tscn")
    var enemy: CharacterBody2D = enemy_scene.instantiate()
    assert(enemy.collision_mask == 16, "Los enemigos solo chocan con escenarios; separación por IA")
    enemy.free()

    # Los IDs que el usuario reportó deben ser visibles en la Chatarrería
    # aunque se deba equipar otra armadura en esa ranura para apostarlos.
    for id in ["tp_helmet_common", "tp_legs_common", "jp_helmet_common"]:
        assert(bool(InventoryManager.add_item(id).get("ok", false)))
    var groups: Array[Dictionary] = InventoryManager.scrap_groups()
    assert(groups.size() == 3, "No ocultar armaduras por faltar una pieza equipada")
    for entry in groups:
        var preview: Dictionary = InventoryManager.scrap_preview(str(entry["id"]), str(entry["rarity"]), 1)
        assert(not bool(preview.get("ok", false)), "Sin equipo en esa ranura no se puede apostar")
    var worn_helmet: Dictionary = InventoryManager.add_item("bj_helmet_common")
    assert(bool(InventoryManager.equip_item(int(worn_helmet["entry"]["uid"])).get("ok", false)))
    var helmet_preview: Dictionary = InventoryManager.scrap_preview("tp_helmet_common", "common", 1)
    assert(bool(helmet_preview.get("ok", false)))
    assert(str(helmet_preview.get("reward_id", "")) == "bj_helmet_common")
    assert(DB.get_def("shotgun_common").get("weapon_type", "") == "shotgun")

    game._open_menu("scrap")
    await process_frame
    assert(game.active_menu == "scrap" and paused)
    game._close_menus(true)
    assert(not paused)
    game._open_menu("inventory")
    assert(game.active_menu == "inventory" and paused)
    game._close_menus(true)
    assert(not paused)
    assert(AudioDirector.music.stream != null)
    assert(AudioDirector.music.volume_db >= -6.0)
    print("PASS 4.30: pantalla completa, tamaño 1.6, jefes sin obstáculos, 3 perdigones, chatarrería visible, audio y reanudación")
    quit(0)
