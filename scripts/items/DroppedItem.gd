extends Node2D
# ALL IN 4.31.6 — atlas completos y procesamiento ligero del botín.
# La obtención, el ID, la rareza, el inventario y las probabilidades no cambian.
const DB = preload("res://scripts/systems/ItemDatabase.gd")

# Cuatro atlas compartidos: 6 fotogramas de 56 x 56 px, con margen transparente.
const CHIP_ATLASES := {
    "common": preload("res://assets/loot/chips_common.png"),
    "rare": preload("res://assets/loot/chips_rare.png"),
    "epic": preload("res://assets/loot/chips_epic.png"),
    "legendary": preload("res://assets/loot/chips_legendary.png")
}
const GLOW_IMAGES := {
    "common": preload("res://assets/loot/glow_common.png"),
    "rare": preload("res://assets/loot/glow_rare.png"),
    "epic": preload("res://assets/loot/glow_epic.png"),
    "legendary": preload("res://assets/loot/glow_legendary.png")
}
const PICKUP_DISTANCE_SQUARED: float = 28.0 * 28.0
const SLOT_FRAMES := {
    "helmet": 0,
    "chest": 1,
    "legs": 2,
    "boots": 3,
    "weapon": 4,
    "charm": 5
}

var item_id: String = ""
var player: Node2D
var elapsed: float = 0.0
var collected: bool = false
@onready var glow_sprite: Sprite2D = $Glow
@onready var chip_sprite: Sprite2D = $Chip

func _ready() -> void:
    # Pausa y z_index se declaran una sola vez en la escena DroppedItem.tscn.
    add_to_group("room_drops")
    player = get_tree().get_first_node_in_group("player")
    _configure_art()

func _configure_art() -> void:
    var definition: Dictionary = DB.get_def(item_id)
    if definition.is_empty():
        chip_sprite.visible = false
        glow_sprite.visible = false
        return
    var rarity: String = str(definition.get("rarity", "common"))
    # El premio especial de jefe utiliza la presentación dorada; no cambia la rareza real.
    if not CHIP_ATLASES.has(rarity):
        rarity = "legendary" if rarity == "boss" else "common"
    var slot: String = str(definition.get("slot", ""))
    chip_sprite.texture = CHIP_ATLASES[rarity]
    chip_sprite.hframes = 6
    chip_sprite.vframes = 1
    chip_sprite.frame = int(SLOT_FRAMES.get(slot, 4))
    glow_sprite.texture = GLOW_IMAGES[rarity]
    # Filtrado nearest definido en la escena, sin reconfigurarlo por objeto.
    chip_sprite.position = Vector2(0.0, -5.0)
    glow_sprite.position = Vector2(0.0, -2.0)

func _process(delta: float) -> void:
    if not RunManager.run_active:
        return
    elapsed += delta
    # Solo transformaciones de dos Sprite2D: sin dibujar polígonos ni crear texturas por frame.
    var phase: float = elapsed * 3.4
    chip_sprite.position.y = -5.0 + sin(phase) * 2.0
    glow_sprite.modulate.a = 0.69 + 0.12 * sin(phase - 1.2)
    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player")
        return
    # Evita una raíz cuadrada en cada ficha y fotograma.
    if global_position.distance_squared_to(player.global_position) <= PICKUP_DISTANCE_SQUARED:
        collect_item_to_player()

func collect_item_to_player() -> bool:
    if collected or is_queued_for_deletion() or not RunManager.run_active or InventoryManager.is_full():
        return false
    var result: Dictionary = InventoryManager.add_item(item_id)
    if bool(result["ok"]):
        collected = true
        queue_free()
        return true
    return false
