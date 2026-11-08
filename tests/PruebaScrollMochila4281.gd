extends SceneTree
## Godot --headless --path . --script res://tests/PruebaScrollMochila4281.gd
## Prueba de regresión: 40 objetos y contenedores que propagan el gesto táctil.
const MAIN_SCENE = preload("res://scenes/main/Main.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    for n in range(40):
        var result: Dictionary = InventoryManager.add_item("bj_helmet_common")
        assert(bool(result.get("ok", false)), "Debe caber el objeto %d" % n)
    var main = MAIN_SCENE.instantiate()
    root.add_child(main)
    # Abrir la mochila ignorando el pacto de entrada, SOLO en este test.
    main.entry_pact_required = false
    main._close_menus(true)
    main._open_menu("inventory")
    for frame in range(16):
        await process_frame
    var scroll: ScrollContainer = main.inventory_scroll
    assert(scroll != null)
    assert(scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_ALWAYS)
    assert(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
    assert(main.inventory_list.mouse_filter == Control.MOUSE_FILTER_PASS)
    assert(main.inventory_build_queue.is_empty(), "Terminó de crear 40 tarjetas")
    var cards: int = 0
    for card in main.inventory_list.get_children():
        if card is VBoxContainer:
            cards += 1
            assert(card.mouse_filter == Control.MOUSE_FILTER_PASS, "El contenedor de tarjeta no debe bloquear el scroll")
            for child in card.get_children():
                if child is Label:
                    assert(child.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Etiquetas no deben capturar drag")
                if child is HBoxContainer:
                    assert(child.mouse_filter == Control.MOUSE_FILTER_PASS, "Botonera deja pasar drag")
                    for button in child.get_children():
                        if button is Button:
                            assert(button.mouse_filter == Control.MOUSE_FILTER_PASS, "El botón permite arrastrar")
    assert(cards >= 40, "Se crearon las cuarenta tarjetas")
    var bar: VScrollBar = scroll.get_v_scroll_bar()
    assert(bar.max_value > bar.page, "La lista debe superar el alto visible")
    scroll.scroll_vertical = 300
    assert(scroll.scroll_vertical > 0, "El scroll vertical debe poder cambiar")
    await process_frame
    assert(scroll.scroll_vertical > 0, "La posición no debe reiniciarse espontáneamente")
    print("PASS ALL IN 4.28.1: mochila de 40, controles y desplazamiento vertical")
    quit(0)
