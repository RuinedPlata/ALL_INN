extends SceneTree
## Ejecutar: godot --headless --path . --script res://tests/PruebaMovilEconomia422.gd
## Pruebas de lógica de joystick flotante y monedas por eliminación.

const JOYSTICK_SCRIPT = preload("res://scripts/ui/MobileJoystick.gd")

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    RunManager.reset_run()
    assert(RunManager.ENEMY_KILL_COINS_MIN == 4)
    assert(RunManager.ENEMY_KILL_COINS_MAX == 7)
    var total: int = 0
    var initial_balance: int = RunManager.coins
    var prizes_seen: Dictionary = {}
    for i in range(300):
        var before: int = RunManager.coins
        var prize: int = RunManager.award_enemy_kill_coins()
        assert(prize >= 4 and prize <= 7, "Recompensa fuera de intervalo")
        assert(RunManager.coins == before + prize, "No se abonaron monedas")
        total += prize
        prizes_seen[prize] = true
    assert(total == RunManager.coins - initial_balance, "Acreditación inconsistente")
    assert(prizes_seen.size() == 4, "La economía debería ofrecer los cuatro valores (4,5,6,7)")
    assert(RunManager.award_normal_room_coins(1) == 10, "La recompensa fija 4.31 debe ser 10")
    assert(RunManager.get_normal_room_cash_reward(1) == 30, "Premio COBRAR debe mantenerse")
    assert(RunManager.award_boss_coins(10) == 200, "Premio jefe debe permanecer intacto")
    RunManager.run_active = false
    var balance_after_end: int = RunManager.coins
    assert(RunManager.award_enemy_kill_coins() == 0, "No premiar al terminar la partida")
    assert(RunManager.coins == balance_after_end)

    RunManager.reset_run()
    var stick = JOYSTICK_SCRIPT.new()
    stick.size = Vector2(150, 150)
    root.add_child(stick)
    assert(not stick.visible, "Joystick inicial debe estar oculto")
    var touch: InputEventScreenTouch = InputEventScreenTouch.new()
    touch.index = 3
    touch.pressed = true
    touch.position = Vector2(410, 630)
    stick._unhandled_input(touch)
    assert(stick.visible and stick.active_touch == 3, "No se capturó el primer toque")
    assert(stick.get_direction() == Vector2.ZERO, "No debe moverse antes de arrastrar")
    assert(stick.global_position.distance_to(Vector2(335, 555)) < 0.1, "Joystick debe nacer donde se tocó")

    var swipe: InputEventScreenDrag = InputEventScreenDrag.new()
    swipe.index = 3
    swipe.position = Vector2(470, 630)
    stick._input(swipe)
    assert(stick.get_direction().x > 0.99, "El dedo capturado no dirigió el movimiento")
    var second_finger: InputEventScreenDrag = InputEventScreenDrag.new()
    second_finger.index = 8
    second_finger.position = Vector2(50, 60)
    stick._input(second_finger)
    assert(stick.get_direction().x > 0.99, "Otro dedo secuestró el joystick")

    paused = true
    stick._process(0.0)
    assert(stick.get_direction() == Vector2.ZERO and not stick.visible, "El joystick debe apagarse con el menú")
    paused = false
    touch.pressed = true
    stick._unhandled_input(touch)
    touch.pressed = false
    stick._input(touch)
    assert(stick.get_direction() == Vector2.ZERO and not stick.visible, "Soltar el dedo debe detener al jugador")
    stick.queue_free()
    print("ALL IN 4.22: joystick dinámico, pausa, multitouch y monedas por eliminación verificados")
    quit(0)
