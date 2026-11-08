extends Node
# Test de regresión para ejecutarse dentro de Godot 4.x.
func _ready() -> void:
    var gd := load("res://scripts/main/Main.gd")
    var game: Node2D = gd.new()
    add_child(game)
    await get_tree().process_frame
    assert(game.compact_coin_icon != null)
    assert(game.compact_coin_icon.texture != null)
    assert(game.compact_coin_icon.mouse_filter == Control.MOUSE_FILTER_IGNORE)
    assert(game.compact_coin_icon.expand_mode == TextureRect.EXPAND_IGNORE_SIZE)
    for i in range(6):
        var png: Texture2D = load("res://assets/hud/coin_%02d.png" % i)
        assert(png != null)
        assert(png.get_size() == Vector2(64, 64))
    var funds: int = RunManager.coins
    RunManager.add_coins(10)
    assert(RunManager.coins == funds + 10)
    assert(game.compact_coins.text == str(funds + 10))
    assert(game.compact_coin_icon.texture != null)
    print("[ALL IN 4.31.3] Moneda infernal: referencias y saldo correctos")
    queue_free()
