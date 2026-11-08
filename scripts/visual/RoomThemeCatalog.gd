extends RefCounted
## Catálogo reutilizable: al añadir otro escenario, solo registrar sus recursos aquí.
## RoomBackdrop.gd y la lógica del combate permanecen independientes.

const FICHA_FLOOR = preload("res://assets/rooms/ficha_infernal/floor.png")
const FICHA_LIGHTS = [
    preload("res://assets/rooms/ficha_infernal/lights_00.png"),
    preload("res://assets/rooms/ficha_infernal/lights_01.png"),
    preload("res://assets/rooms/ficha_infernal/lights_02.png"),
    preload("res://assets/rooms/ficha_infernal/lights_03.png"),
    preload("res://assets/rooms/ficha_infernal/lights_04.png"),
    preload("res://assets/rooms/ficha_infernal/lights_05.png"),
]

# Grupo de PRUEBA 4.31.38: Ficha Infernal en todas las salas.
# Al aprobar más escenarios, aquí puede decidirse una rotación por bloques
# sin editar Main.gd, enemigos, obstáculos ni ninguna hitbox.
static func theme_for_room(_room_number: int) -> Dictionary:
    return theme_by_id("ficha_infernal")

static func theme_by_id(theme_id: String) -> Dictionary:
    match theme_id:
        "ficha_infernal":
            return {"id": "ficha_infernal", "floor": FICHA_FLOOR,
                    "frames": FICHA_LIGHTS, "fps": 5.55}
        _:
            return {} # Main recupera el suelo clásico si no hay tema.
