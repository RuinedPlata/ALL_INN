extends SceneTree
## Prueba de regresión para Godot 4.7.2 PC/Android:
## godot --headless --path . --script res://tests/PruebaChatarreriaTactil4283.gd
## No modifica balance ni apuesta piezas reales al probar los controles.
const MAIN = preload("res://scenes/main/Main.tscn")
const DB = preload("res://scripts/systems/ItemDatabase.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    for slot in ["helmet", "chest", "legs", "boots"]:
        var result: Dictionary = InventoryManager.add_item("tp_%s_common" % slot)
        assert(bool(result.get("ok", false)))
        assert(bool(InventoryManager.equip_item(int(result["entry"]["uid"])).get("ok", false)))

    # 40 grupos DIFERENTES: cada ID se representa una sola vez, para comprobar
    # desplazamiento real en vez de un lote de 40 duplicados que solo forma una tarjeta.
    var ids: Array = DB.ITEM_DEFS.keys()
    ids.sort()
    var donor_count: int = 0
    for id_value in ids:
        var item_id: String = str(id_value)
        if not DB.is_set_armor(item_id):
            continue
        assert(bool(InventoryManager.add_item(item_id).get("ok", false)))
        donor_count += 1
        if donor_count >= 40:
            break
    assert(donor_count == 40)

    var game = MAIN.instantiate()
    root.add_child(game)
    game.entry_pact_required = false
    game._close_menus(true)
    game._open_menu("scrap")
    for frame in range(14):
        await process_frame
    assert(game.active_menu == "scrap")
    assert(paused, "Chatarrería debe detener el combate")
    assert(game.scrap_build_queue.is_empty(), "Las tarjetas se agregan en tandas")
    assert(game.scrap_list.get_child_count() == 40)
    var scroll: ScrollContainer = game.scrap_scroll
    assert(scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_ALWAYS)
    assert(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
    var bar: VScrollBar = scroll.get_v_scroll_bar()
    assert(bar.max_value > bar.page, "40 tipos deben dar altura desplazable")

    # Dedo situado encima de una tarjeta; gesto dirigido a Main._input para
    # probar captura incluso cuando las tarjetas contienen botones.
    var start_pos: Vector2 = scroll.get_global_transform_with_canvas() * Vector2(125, scroll.size.y - 30)
    var end_pos: Vector2 = scroll.get_global_transform_with_canvas() * Vector2(125, scroll.size.y - 170)
    var down := InputEventScreenTouch.new()
    down.index = 6
    down.pressed = true
    down.position = start_pos
    Input.parse_input_event(down)
    var drag := InputEventScreenDrag.new()
    drag.index = 6
    drag.position = end_pos
    Input.parse_input_event(drag)
    assert(scroll.scroll_vertical > 0, "Arrastrar debe desplazar Chatarrería")
    assert(game.scrap_touch_scrolled, "El swipe se distingue de un clic de APOSTAR")
    var before: int = InventoryManager.items.size()
    # El gesto no puede abrir la apuesta si algún botón recibe un click tardío.
    var any_group: Dictionary = InventoryManager.scrap_groups()[0]
    game._request_scrap(str(any_group["id"]), str(any_group["rarity"]), 1)
    assert(game.pending_scrap.is_empty())
    assert(InventoryManager.items.size() == before)
    var up := InputEventScreenTouch.new()
    up.index = 6
    up.pressed = false
    up.position = end_pos
    Input.parse_input_event(up)
    await process_frame
    game._scroll_scrap(1)
    await process_frame
    assert(scroll.scroll_vertical > 0, "Botón BAJAR permite navegación alternativa")

    # El botón Volver y Salir deben reanudar el movimiento sin dejar la pausa pegada.
    game._open_menu("inventory")
    assert(game.active_menu == "inventory" and paused)
    game._close_menus()
    assert(game.active_menu == "" and not paused, "Volver a jugar despausa")
    game.queue_free()
    await process_frame

    # Mochila pequeña: aun SIN scrollbar activo, salir siempre funciona.
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    var equipped: Dictionary = InventoryManager.add_item("bj_helmet_common")
    assert(bool(InventoryManager.equip_item(int(equipped["entry"]["uid"])).get("ok", false)))
    assert(bool(InventoryManager.add_item("jp_helmet_common").get("ok", false)))
    game = MAIN.instantiate()
    root.add_child(game)
    game.entry_pact_required = false
    game._close_menus(true)
    game._open_menu("scrap")
    await process_frame
    assert(game.scrap_list.get_child_count() == 1)
    game._close_menus()
    assert(not paused and game.active_menu == "")
    print("PASS 4.28.3: 40 tipos y 1 tipo; swipe, botón alternativo, guardia de apuestas, mochila, cierre y despausa")
    quit(0)
