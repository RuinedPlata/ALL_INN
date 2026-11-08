extends SceneTree
## Godot 4.7.2: godot --headless --path . --script res://tests/PruebaHUDCorazones4311.gd
const MAIN = preload("res://scenes/main/Main.tscn")
const NORMAL_FULL = preload("res://assets/hud/normal_full.png")
const NORMAL_EMPTY = preload("res://assets/hud/normal_empty.png")
const EXTRA_FULL = preload("res://assets/hud/extra_full.png")
const EXTRA_EMPTY = preload("res://assets/hud/extra_empty.png")

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

    assert(RunManager.max_health == 3, "La partida debe seguir con tres corazones")
    assert(game.compact_heart_icons.size() == 3)
    for i in range(3):
        assert(game.compact_heart_icons[i].texture == NORMAL_FULL)
        assert(game.compact_heart_icons[i].mouse_filter == Control.MOUSE_FILTER_IGNORE)

    game._update_health_label(2)
    assert(game.compact_heart_icons[0].texture == NORMAL_FULL)
    assert(game.compact_heart_icons[1].texture == NORMAL_FULL)
    assert(game.compact_heart_icons[2].texture == NORMAL_EMPTY)
    var saved: TextureRect = game.compact_heart_icons[0]
    game._update_health_label(1)
    assert(game.compact_heart_icons[0] == saved, "No reconstruir iconos por cada golpe")

    # Simular solo la CAPACIDAD VISUAL para futuros extras; no equipar amuletos.
    RunManager.max_health = 5
    game._update_health_label(4)
    assert(game.compact_heart_icons.size() == 5)
    assert(game.compact_heart_icons[3].texture == EXTRA_FULL)
    assert(game.compact_heart_icons[4].texture == EXTRA_EMPTY)
    RunManager.max_health = 3
    game._update_health_label(3)
    assert(game.compact_heart_icons.size() == 3)
    assert(game.compact_heart_icons[0].texture == NORMAL_FULL)

    assert(game.compact_shield != null and not game.compact_shield.visible)
    game._open_menu("inventory")
    assert(game.active_menu == "inventory" and paused)
    game._close_menus(true)
    assert(not paused)
    print("PASS 4.31.1: HUD iconos pixel art, daño/curación, futuros extras, joystick sin bloqueo")
    quit(0)
