extends Node
# Ejecutar opcionalmente desde Godot para revisar sprites y capas de la 4.31.5.
const DB = preload("res://scripts/systems/ItemDatabase.gd")
const DROP_SCENE = preload("res://scenes/items/DroppedItem.tscn")
const PLAYER_SCENE = preload("res://scenes/player/Player.tscn")
const BULLET = preload("res://scenes/combat/Projectile.tscn")
const ENEMY_BULLET = preload("res://scenes/combat/EnemyProjectile.tscn")
const RARITIES := ["common", "rare", "epic", "legendary"]
const SLOTS := ["helmet", "chest", "legs", "boots", "weapon", "charm"]

func _ready() -> void:
    for rarity in RARITIES:
        for i in range(SLOTS.size()):
            var slot: String = SLOTS[i]
            var sample_id: String = "bj_%s_%s" % [slot, rarity]
            if slot == "weapon":
                sample_id = "pistol_%s" % rarity
            if slot == "charm":
                sample_id = {"common":"clock", "rare":"metronome", "epic":"hourglass", "legendary":"house"}[rarity]
            assert(not DB.get_def(sample_id).is_empty())
            var drop: Node2D = DROP_SCENE.instantiate()
            drop.item_id = sample_id
            add_child(drop)
            assert(drop.z_index == 1)
            assert(drop.get_node("Glow").texture != null)
            assert(drop.get_node("Chip").frame == i)
            drop.queue_free()
    var bullet: Node2D = BULLET.instantiate()
    var enemy_bullet: Node2D = ENEMY_BULLET.instantiate()
    assert(bullet.z_index == 3 and enemy_bullet.z_index == 3)
    bullet.free()
    enemy_bullet.free()
    print("[ALL IN 4.31.5] Presentacion de fichas y capas verificada; revisar HUD en telefono")
    queue_free()
