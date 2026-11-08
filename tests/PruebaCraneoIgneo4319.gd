extends Node
# Test de estructura v4.31.9. Ejecutar como nodo desde Godot para validar importación.
const RANGED_SCENE: PackedScene = preload("res://scenes/enemies/RangedEnemy.tscn")
const SPLIT_MINION_SCENE: PackedScene = preload("res://scenes/enemies/SplitMinion.tscn")
const BASIC_SCENE: PackedScene = preload("res://scenes/enemies/BasicEnemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/enemies/Boss.tscn")
const FIREBALL_SCENE: PackedScene = preload("res://scenes/combat/IgnelFireball.tscn")
const FIREBALL_OLD: PackedScene = preload("res://scenes/combat/EnemyProjectile.tscn")
const DEATH_SCENE: PackedScene = preload("res://scenes/enemies/IgnelDeathFX.tscn")

func _ready() -> void:
    var skull: Node2D = RANGED_SCENE.instantiate() as Node2D
    var sprite: AnimatedSprite2D = skull.get_node("IgnelSprite") as AnimatedSprite2D
    var shadow: AnimatedSprite2D = skull.get_node("IgnelShadow") as AnimatedSprite2D
    assert(sprite != null and shadow != null)
    assert(sprite.sprite_frames.get_frame_count("hover") == 4)
    assert(sprite.sprite_frames.get_frame_count("attack") == 4)
    assert(sprite.sprite_frames.get_animation_loop("hover"))
    assert(not sprite.sprite_frames.get_animation_loop("attack"))
    assert(shadow.sprite_frames.get_frame_count("shadow") == 2)
    for anim_name in ["hover", "attack"]:
        for i in range(sprite.sprite_frames.get_frame_count(anim_name)):
            var texture: Texture2D = sprite.sprite_frames.get_frame_texture(anim_name, i)
            assert(texture.get_size() == Vector2(64, 64))
            assert(texture.get_image().get_pixel(0, 0).a < 0.01)
    var fireball: Area2D = FIREBALL_SCENE.instantiate() as Area2D
    var normal: Area2D = FIREBALL_OLD.instantiate() as Area2D
    assert(fireball.get("speed") == normal.get("speed"))
    assert(fireball.get("damage") == normal.get("damage"))
    assert(fireball.collision_layer == normal.collision_layer)
    assert(fireball.collision_mask == normal.collision_mask)
    assert((fireball.get_node("FireSprite") as AnimatedSprite2D).sprite_frames.get_frame_count("travel") == 4)
    var fx: AnimatedSprite2D = DEATH_SCENE.instantiate() as AnimatedSprite2D
    assert(fx.sprite_frames.get_frame_count("burst") == 5)
    assert(fx.get_node_or_null("CollisionShape2D") == null)
    assert(not fx.is_in_group("enemies"))
    # No hay fuga del nuevo sprite a IMP, mini-cráneos o jefe.
    var imp: Node2D = BASIC_SCENE.instantiate() as Node2D
    var small: Node2D = SPLIT_MINION_SCENE.instantiate() as Node2D
    var boss: Node2D = BOSS_SCENE.instantiate() as Node2D
    assert(imp.get_node_or_null("IgnelSprite") == null)
    assert(small.get_node_or_null("IgnelSprite") == null)
    assert(boss.get_node_or_null("IgnelSprite") == null)
    for obj in [skull, fireball, normal, fx, imp, small, boss]:
        obj.free()
    print("[ALL IN 4.31.9] Cráneo Ígneo: sprites y separación de enemigos OK")
    queue_free()
