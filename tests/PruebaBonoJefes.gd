extends SceneTree
## Prueba AUTOMÁTICA con Godot (no necesita pulsar F8).
## Ejecutar: godot --headless --path . --script res://tests/PruebaBonoJefes.gd
## Verifica que derrotar al jefe paga +200/+250 una sola vez.

var failures: int = 0

func _initialize() -> void:
    call_deferred("_run_tests")

func _expect(actual: int, expected: int, context: String) -> void:
    if actual != expected:
        failures += 1
        push_error("FALLO [%s]: esperado %d, recibido %d" % [context, expected, actual])
    else:
        print("OK [%s]: %d" % [context, actual])

func _run_tests() -> void:
    var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
    var main: Node2D = main_scene.instantiate() as Node2D
    root.add_child(main)
    await process_frame

    # Asegurar estado limpio; las pruebas usan el controlador y la escena real.
    RunManager.reset_run()
    await _defeat_boss(main, 10, 200)
    await _defeat_boss(main, 20, 250)
    _expect(RunManager.get_boss_coin_prize(30), 300, "regla jefe de sala 30")
    _expect(RunManager.get_boss_coin_prize(9), 0, "sin premio fuera de jefe")

    paused = false
    if failures == 0:
        print("RESULTADO: TODOS LOS TESTS DE MONEDAS DE JEFE PASARON")
    else:
        push_error("RESULTADO: %d pruebas fallaron" % failures)
    quit(0 if failures == 0 else 1)

func _defeat_boss(main: Node2D, room: int, prize: int) -> void:
    main._begin_room(room)
    main.level_manager._spawn_boss()
    main.level_manager.spawned = 1
    var boss: Node2D = main.enemies_root.get_child(0) as Node2D
    var previous_balance: int = RunManager.coins
    boss.take_damage(999999)
    _expect(RunManager.coins, previous_balance + prize, "saldo tras jefe sala %d" % room)
    _expect(RunManager.get_boss_coins_paid(room), prize, "premio registrado sala %d" % room)
    RunManager.boss_defeated.emit()  # Repetición de señal: jamás duplica el pago.
    _expect(RunManager.coins, previous_balance + prize, "señal duplicada sala %d" % room)
    await process_frame
