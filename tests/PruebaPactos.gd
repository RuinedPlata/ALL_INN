extends SceneTree
## Ejecutar con Godot 4.3+: godot --headless --path . --script res://tests/PruebaPactos.gd
## Se mantiene independiente de la escena Main y su interfaz.

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    RunManager.reset_run()
    PactManager.reset_pacts()
    assert(is_equal_approx(PactManager.SUCCESS_CHANCE, 0.60), "Pactos normales deben tener 60% éxito")
    PactManager.begin_room(1)
    var offers: Array[String] = PactManager.draw_offers()
    assert(offers.size() == 3, "La sala debe mostrar tres opciones")
    assert(str(PactManager.PACTS[offers[0]]["family"]) == "economy", "Primera: economía")
    assert(str(PactManager.PACTS[offers[1]]["family"]) == "combat", "Segunda: combate")
    assert(offers[0] != offers[1] and offers[1] != offers[2], "No mostrar duplicados")
    # Simulamos la probabilidad ejecutando las reglas reales del gestor.
    seed(174017)
    RunManager.add_coins(10000) # Fondos para mil pactos de prueba a 10 monedas.
    var victories: int = 0
    var tries: int = 1000
    for i in range(tries):
        var result: Dictionary = PactManager.resolve_pact("filo")
        assert(bool(result["ok"]))
        victories += int(bool(result["won"]))
    var rate: float = float(victories) / float(tries)
    assert(rate > 0.54 and rate < 0.66, "La distribución debe aproximarse al 60/40")
    # 1000 pactos * 10 monedas = 10 000 (saldo inicial de 100 intacto).
    assert(RunManager.coins == 100, "Cada pacto debe descontar 10 monedas")
    # Las Sobrecargas y Crisis no exceden sus límites normales.
    var stack: int = int(PactManager.fortune.get("filo", 0))
    assert(stack >= -3 and stack <= 3)
    PactManager.temporary["filo"] = {"kind": "overload", "expires": 8}
    PactManager.begin_room(7)
    assert(PactManager.is_active("filo", "overload"), "Sobrecarga dura siete salas")
    PactManager.begin_room(8)
    assert(not PactManager.is_active("filo", "overload"), "La Sobrecarga termina al comenzar la octava")
    PactManager.extra_next_room = true
    PactManager.begin_room(9)
    assert(PactManager.extra_this_room and not PactManager.extra_next_room)
    var bonus_offers: Array[String] = PactManager.draw_offers(true)
    assert(not ("segunda" in bonus_offers), "No permitir bonus encadenados")
    PactManager.no_affinity_next_room = true
    PactManager.begin_room(10)
    assert(PactManager.no_affinity_this_room, "La penalización de Segunda Oportunidad desactiva afinidad")
    for trial in range(100):
        assert(PactManager.draw_offers(false).size() == 3, "Nunca menos de 3 pactos")
        assert(PactManager.draw_offers(true).size() == 3, "También en oportunidad extra")
    print("ALL IN 4.19: pruebas de pactos completadas. Frecuencia observada: %.1f%%." % (rate * 100.0))
    quit(0)
