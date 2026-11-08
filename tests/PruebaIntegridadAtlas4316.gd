extends Node
# ALL IN 4.31.6: cargar como script de un nodo en una escena de prueba de Godot.
# Las pruebas visuales necesitan confirmación en el dispositivo Android.
const DROP_SCENE = preload("res://scenes/items/DroppedItem.tscn")
const BULLET_SCENE = preload("res://scenes/combat/Projectile.tscn")
const RARITIES := ["common", "rare", "epic", "legendary"]
const SLOTS := ["helmet", "chest", "legs", "boots", "weapon", "charm"]
const ATLAS_SIZE := Vector2i(336, 56)
const FRAME_SIZE := 56
const MARGIN := 3

func _ready() -> void:
    var ids: Dictionary = {"common": "clock", "rare": "metronome", "epic": "hourglass", "legendary": "house"}
    for rarity in RARITIES:
        for col in range(SLOTS.size()):
            var item_id: String = "bj_%s_%s" % [SLOTS[col], rarity]
            if SLOTS[col] == "weapon":
                item_id = "pistol_%s" % rarity
            elif SLOTS[col] == "charm":
                item_id = str(ids[rarity])
            var drop = DROP_SCENE.instantiate()
            drop.item_id = item_id
            add_child(drop)
            var chip: Sprite2D = drop.get_node("Chip")
            var glow: Sprite2D = drop.get_node("Glow")
            assert(drop.z_index == 1)
            assert(chip.frame == col)
            assert(chip.hframes == 6)
            assert(chip.texture.get_size() == Vector2(ATLAS_SIZE))
            assert(glow.texture != null)
            var img: Image = chip.texture.get_image()
            # Ningún sprite puede llegar a los bordes de su celda.
            for y in range(FRAME_SIZE):
                for x in range(FRAME_SIZE):
                    if x < MARGIN or y < MARGIN or x >= FRAME_SIZE - MARGIN or y >= FRAME_SIZE - MARGIN:
                        assert(img.get_pixel(col * FRAME_SIZE + x, y).a == 0.0)
            drop.free()
    var projectile = BULLET_SCENE.instantiate()
    add_child(projectile)
    assert(projectile.get("_sweep_query") != null)
    projectile.free()
    print("[ALL IN 4.31.6] Atlas: 24/24 celdas sin corte; capas y consultas cargadas")
    queue_free()
