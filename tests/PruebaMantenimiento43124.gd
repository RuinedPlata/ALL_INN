extends SceneTree
## ALL IN 4.31.24: prueba de regresion de reinicios, pactos y golpes.
## Godot: godot --headless --path . --script res://tests/PruebaMantenimiento43124.gd

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    # Una partida NUEVA no hereda fortuna ni estados de salas anteriores.
    InventoryManager.reset_inventory()
    RunManager.reset_run()
    PactManager.begin_room(1)
    _assert_pacts_clean("inicio de partida")
    assert(RunManager.coins == 100, "El saldo inicial debe ser 100")
    assert(is_equal_approx(PactManager.SUCCESS_CHANCE, 0.60), "Mantener pactos 60/40")

    # Cada una de las tres ofertas debe abrir sin modificar la fortuna.
    for attempt in range(20):
        var offers: Array[String] = PactManager.draw_offers()
        assert(offers.size() == 3, "Tres opciones de pacto por sala")
        assert(offers[0] != offers[1] and offers[1] != offers[2] and offers[0] != offers[2], "No duplicar ofertas")
        assert(int(PactManager.fortune.get(offers[0], 0)) == 0, "Ofrecer no modifica fortuna")
    _assert_pacts_clean("ofertas gratuitas")

    # Una apuesta sí altera los acumulables; el siguiente reinicio lo limpia.
    var result: Dictionary = PactManager.resolve_pact("filo")
    assert(bool(result.get("ok", false)), "Se debe poder apostar")
    assert(abs(int(PactManager.fortune.get("filo", 0))) == 1, "Primera apuesta: +1 o -1")
    assert(RunManager.bets_placed == 1, "Registrar la apuesta")
    PactManager.temporary["filo"] = {"kind": "crisis", "expires": 7}
    PactManager.extra_next_room = true
    PactManager.no_affinity_next_room = true
    PactManager.hunter_next = -1
    PactManager.begin_room(3)
    RunManager.reset_run()  # IMPORTANTE: sin llamar reset_pacts() por separado.
    PactManager.begin_room(1)
    _assert_pacts_clean("reinicio desde otro sistema")
    assert(RunManager.bets_placed == 0, "Reiniciar estadisticas de apuestas")

    # Golpe bloqueado: no resta corazon ni devuelve 'hubo daño'.
    RunManager.shield_charges = 1
    var blocked: bool = RunManager.damage_player(1)
    assert(not blocked, "El escudo debe evitar la reaccion de daño")
    assert(RunManager.player_health == 3 and RunManager.shield_charges == 0, "El escudo absorbe un golpe")
    var hurt: bool = RunManager.damage_player(1)
    assert(hurt, "Golpe sin escudo: se pierde corazon")
    assert(RunManager.player_health == 2, "Un golpe efectivo = un corazon")

    # Un reinicio completo vuelve a salud y pactos base.
    RunManager.reset_run()
    assert(RunManager.player_health == 3 and RunManager.run_active, "Restaurar tres corazones")
    _assert_pacts_clean("segundo reinicio")
    print("ALL IN 4.31.24: pactos, reinicio, oferta inicial y defensa: OK")
    quit(0)

func _assert_pacts_clean(context: String) -> void:
    assert(PactManager.fortune.is_empty(), "%s: fortuna no vacia" % context)
    assert(PactManager.temporary.is_empty(), "%s: bonus temporales heredados" % context)
    assert(PactManager.fortune_summary() == "Sin pactos acumulados", "%s: resumen incorrecto" % context)
    assert(PactManager.room_number == 1, "%s: sala incorrecta" % context)
    assert(not PactManager.extra_this_room and not PactManager.extra_next_room, "%s: pacto extra heredado" % context)
    assert(not PactManager.no_affinity_this_room and not PactManager.no_affinity_next_room, "%s: afinidad anterior" % context)
    assert(PactManager.hunter_this_room == 0 and PactManager.hunter_next == 0, "%s: cazador heredado" % context)
    for stat in ["loot", "coins", "sell", "damage", "attack", "crit", "speed", "block", "iframes"]:
        assert(is_zero_approx(PactManager.get_stat(stat)), "%s: modificador %s distinto de cero" % [context, stat])
