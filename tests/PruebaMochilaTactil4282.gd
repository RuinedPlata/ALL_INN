extends SceneTree
## Prueba de regresión de la interfaz 4.28.2.
## Ejecutar en PC con Godot 4.7.2:
## godot --headless --path . --script res://tests/PruebaMochilaTactil4282.gd
const MAIN = preload("res://scenes/main/Main.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    for n in range(40):
        assert(bool(InventoryManager.add_item("bj_helmet_common").get("ok", false)))
    var game = MAIN.instantiate()
    root.add_child(game)
    game.entry_pact_required = false
    game._close_menus(true)
    game._open_menu("inventory")
    for frame in range(16):
        await process_frame
    assert(game.active_menu == "inventory")
    assert(paused, "El combate permanece pausado mientras se administra equipo")
    assert(game.inventory_build_queue.is_empty(), "Las tarjetas se construyen en tandas")
    assert(game.inventory_filter_buttons.size() == 9, "Nueve filtros directos, sin PopupMenu")
    assert(game.inventory_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_ALWAYS)
    assert(game.inventory_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
    var scroll = game.inventory_scroll
    var bar = scroll.get_v_scroll_bar()
    assert(bar.max_value > bar.page, "40 objetos deben producir desplazamiento")
    assert(scroll.scroll_vertical == 0)

    # Un gesto táctil real pasa por el sistema de Input del viewport y Main._input.
    var touch := InputEventScreenTouch.new()
    touch.index = 4
    touch.pressed = true
    touch.position = scroll.get_global_transform_with_canvas() * Vector2(120, scroll.size.y - 30.0)
    Input.parse_input_event(touch)
    var drag := InputEventScreenDrag.new()
    drag.index = 4
    drag.position = scroll.get_global_transform_with_canvas() * Vector2(120, scroll.size.y - 150.0)
    Input.parse_input_event(drag)
    assert(scroll.scroll_vertical > 0, "El arrastre debe mover la lista")
    var drag_scroll: int = scroll.scroll_vertical
    var release := InputEventScreenTouch.new()
    release.index = 4
    release.pressed = false
    release.position = drag.position
    Input.parse_input_event(release)
    await process_frame
    assert(scroll.scroll_vertical >= drag_scroll, "Al soltar no se pierde el desplazamiento")

    # Cambiar filtros muchas veces no puede abrir un popup ni impedir el cierre.
    for i in [1, 3, 4, 0, 6, 2, 0]:
        game.inventory_filter_buttons[i].emit_signal("pressed")
        await process_frame
        assert(game.inventory_filter == game.INVENTORY_FILTERS[i])
        assert(game.active_menu == "inventory")
    game.inventory_sort_button.emit_signal("pressed")
    assert(game.inventory_sort == "rarity")
    game._scroll_inventory(1)
    await process_frame
    game._close_menus()
    assert(not paused, "Cerrar mochila debe reanudar el mundo")
    assert(game.active_menu == "", "No puede quedar un menú invisible bloqueando la partida")
    game.queue_free()
    await process_frame

    RunManager.reset_run()
    InventoryManager.reset_inventory()
    for n in range(4):
        assert(bool(InventoryManager.add_item("bj_boots_common").get("ok", false)))
    game = MAIN.instantiate()
    root.add_child(game)
    game.entry_pact_required = false
    game._close_menus(true)
    game._open_menu("inventory")
    await process_frame
    game.inventory_filter_buttons[6].emit_signal("pressed")
    await process_frame
    assert(game.inventory_filter == "boots")
    game._close_menus()
    assert(not paused and game.active_menu == "", "Los filtros tampoco bloquean una mochila pequeña")
    print("PASS ALL IN 4.28.2: 40 y 4 objetos; drag táctil, filtros, orden, cierre y reanudación")
    quit(0)
