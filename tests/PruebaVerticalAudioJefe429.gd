extends SceneTree
## Prueba estructural en Godot (el motor debe estar instalado localmente):
## godot --headless --path . --script res://tests/PruebaVerticalAudioJefe429.gd
const MAIN = preload("res://scenes/main/Main.tscn")
const BOSS = preload("res://scripts/enemies/Boss.gd")

func _initialize() -> void:
    call_deferred("_run_checks")

func _run_checks() -> void:
    InventoryManager.reset_inventory()
    RunManager.reset_run()
    PactManager.reset_pacts()
    var game: Node2D = MAIN.instantiate() as Node2D
    root.add_child(game)
    game.entry_pact_required = false
    game._close_menus(true)
    await process_frame
    assert(game.player.scale == Vector2(1.6, 1.6))
    assert(RunManager.arena_rect.size.y > RunManager.arena_rect.size.x * 1.5)
    assert(game.compact_health != null and game.compact_coins != null and game.compact_room != null)
    assert(game.compact_room.text.begins_with("SALA"))
    assert(AudioDirector.music.stream != null)
    for sound_name in AudioDirector.SOUND_NAMES:
        assert(AudioDirector.sfx.has(sound_name))
        assert(AudioDirector.sfx[sound_name] != null)
    var impact: Node = get_first_node_in_group("combat_feedback")
    assert(impact != null)
    impact.add_impact(game.player.global_position, "enemy", 1.0)
    assert(impact.marks.size() == 1)
    assert(InventoryManager.get_equipped_entry("weapon").size() > 0)
    var boss: CharacterBody2D = BOSS.new()
    assert(boss.SHOT_RECOVERY >= 1.0)
    assert(boss.global_shot_cooldown == 0.0)
    boss.free()
    game._open_menu("inventory")
    assert(game.active_menu == "inventory" and paused)
    game._close_menus(true)
    assert(not paused)
    game._open_menu("scrap")
    assert(game.active_menu == "scrap" and paused)
    game._close_menus(true)
    assert(not paused)
    print("PASS 4.29: arena vertical completa, tamaño x1.6, HUD compacto, música y 13 SFX, impactos, boss, mochila y chatarrería")
    quit(0)
