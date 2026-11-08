extends SceneTree
# Ejecutar en Godot: godot --headless --path . --script res://tests/PruebaRendimiento4312.gd
const MAIN = preload("res://scenes/main/Main.tscn")
const NORMAL_FULL = preload("res://assets/hud/normal_full.png")
const NORMAL_EMPTY = preload("res://assets/hud/normal_empty.png")

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
    assert(game.compact_heart_icons.size() == 3)
    var icon: TextureRect = game.compact_heart_icons[0]
    game._update_health_label(3)
    assert(game.compact_heart_icons[0] == icon)
    assert(game.compact_heart_icons[0].texture == NORMAL_FULL)
    game._update_health_label(2)
    assert(game.compact_heart_icons[2].texture == NORMAL_EMPTY)
    var original_time: float = Engine.time_scale
    var original_pitch: float = AudioDirector.music.pitch_scale
    game._toggle_performance_overlay()
    assert(game.perf_enabled)
    assert(game.perf_overlay.visible)
    assert(game.perf_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE)
    assert(Engine.time_scale == original_time)
    assert(AudioDirector.music.pitch_scale == original_pitch)
    game._update_performance_overlay()
    game._toggle_performance_overlay()
    assert(not game.perf_enabled and not game.perf_overlay.visible)
    assert(Engine.time_scale == original_time)
    assert(AudioDirector.music.pitch_scale == original_pitch)
    print("PASS 4.31.2 HUD cache y diagnóstico pasivo sin alterar velocidades ni audio")
    quit(0)
