extends SceneTree
## ALL IN 4.26 — regresión: recompensas por muerte y daño básico con BLACK JACK.
## Godot 4.7.2: godot --headless --path . --script res://tests/PruebaBalance426.gd

const PLAYER = preload("res://scripts/player/Player.gd")

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    RunManager.reset_run()
    InventoryManager.reset_inventory()
    PactManager.reset_pacts()

    assert(RunManager.ENEMY_KILL_COINS_MIN == 4)
    assert(RunManager.ENEMY_KILL_COINS_MAX == 7)
    assert(is_equal_approx(RunManager.PLAYER_GLOBAL_DAMAGE_BONUS, 0.10))

    var start_coins: int = RunManager.coins
    var distributed: Dictionary = {}
    var total: int = 0
    for i in range(500):
        var previous: int = RunManager.coins
        var award: int = RunManager.award_enemy_kill_coins()
        assert(award >= 4 and award <= 7, "Recompensa de enemigo fuera de 4..7")
        assert(RunManager.coins == previous + award, "Recompensa no acreditada exactamente una vez")
        distributed[award] = true
        total += award
    assert(total == RunManager.coins - start_coins)
    assert(distributed.size() == 4, "Deben poder aparecer 4, 5, 6 y 7 monedas")

    # Daño 1 -> 1.1, y estadísticas aditivas: 1 + 10% base + 4% nivel + 10% pecho.
    assert(is_equal_approx(PLAYER.calculate_basic_attack_damage(1, 0.0, 0.0), 1.10))
    assert(is_equal_approx(PLAYER.calculate_basic_attack_damage(1, 0.04, 0.10), 1.24))
    assert(is_equal_approx(PLAYER.calculate_basic_attack_damage(2, 0.04, 0.10), 2.48))
    # BLACK JACK sigue distribuyendo daño; no multiplica el bono base 2/4 veces.
    assert(is_equal_approx(PLAYER.calculate_basic_attack_damage(1, 0.0, 0.0) * 0.70, 0.77))
    assert(is_equal_approx(PLAYER.calculate_basic_attack_damage(1, 0.0, 0.0) * 0.45, 0.495))
    assert(PLAYER.black_jack_spread_degrees(4).size() == 4)

    # Premios anteriores, jefes y ruleta no cambian.
    assert(RunManager.NORMAL_ROOM_COMPLETION_COINS == 10)
    assert(RunManager.get_normal_room_cash_reward(11) == 40)
    RunManager.reset_run()
    assert(RunManager.award_boss_coins(10) == 200)
    assert(RunManager.award_boss_coins(10) == 0, "No pagar doble premio a un jefe")
    RunManager.run_active = false
    assert(RunManager.award_enemy_kill_coins() == 0, "No pagar con la partida terminada")
    print("ALL IN 4.26: economía 4–7, daño global +10%, BLACK JACK, jefes: OK")
    quit(0)
