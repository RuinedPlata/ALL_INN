extends RefCounted
## Reglas de bonificación por jefe. No modifica monedas ni menús.
## Cada décima habitación contiene un jefe: 10, 20, 30...

const ROOMS_PER_BOSS: int = 10
const FIRST_BOSS_PRIZE: int = 200
const PRIZE_PER_NEXT_BOSS: int = 50

static func coins_for_room(room_number: int) -> int:
    if room_number < ROOMS_PER_BOSS or room_number % ROOMS_PER_BOSS != 0:
        return 0
    var boss_index: int = int(room_number / ROOMS_PER_BOSS)
    return FIRST_BOSS_PRIZE + (boss_index - 1) * PRIZE_PER_NEXT_BOSS
