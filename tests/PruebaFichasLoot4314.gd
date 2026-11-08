extends Node
# Ejecutar en Godot como escena de pruebas desde la pestaña de scripts (o incluir este nodo en un test runner).
const DB = preload("res://scripts/systems/ItemDatabase.gd")
const DROP_SCENE = preload("res://scenes/items/DroppedItem.tscn")
const RARITIES := ["common", "rare", "epic", "legendary"]
const SLOTS := ["helmet", "chest", "legs", "boots", "weapon", "charm"]

func _ready() -> void:
    var charm_ids: Dictionary = {
        "common": "clock", "rare": "metronome", "epic": "hourglass", "legendary": "house"
    }
    for rarity in RARITIES:
        for i in range(SLOTS.size()):
            var slot: String = SLOTS[i]
            var id: String = "bj_%s_%s" % [slot, rarity]
            if slot == "weapon":
                id = "pistol_%s" % rarity
            elif slot == "charm":
                id = str(charm_ids[rarity])
            assert(str(DB.get_def(id).get("slot", "")) == slot)
            var drop: Node2D = DROP_SCENE.instantiate() as Node2D
            drop.set("item_id", id)
            add_child(drop)
            var chip: Sprite2D = drop.get_node("Chip") as Sprite2D
            var glow: Sprite2D = drop.get_node("Glow") as Sprite2D
            assert(chip.texture != null and glow.texture != null)
            assert(chip.frame == i)
            assert(chip.hframes == 6 and chip.texture.get_size() == Vector2(336, 56))
            assert(glow.texture.get_size() == Vector2(64, 64))
            assert(chip.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
            drop.queue_free()
    print("[ALL IN 4.31.4] 24 fichas de loot, categorías y rarezas correctas")
    queue_free()
