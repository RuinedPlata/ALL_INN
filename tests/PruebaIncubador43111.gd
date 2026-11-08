extends Node
# Attach as a node in a Godot test scene; checks structure without combat changes.
const INC: PackedScene = preload("res://scenes/enemies/SplitterEnemy.tscn")
const MINI: PackedScene = preload("res://scenes/enemies/SplitMinion.tscn")
const FX: PackedScene = preload("res://scenes/enemies/IncubatorDeathFX.tscn")
const IMP: PackedScene = preload("res://scenes/enemies/BasicEnemy.tscn")
const SKULL: PackedScene = preload("res://scenes/enemies/RangedEnemy.tscn")

func _ready() -> void:
    var incubator: CharacterBody2D = INC.instantiate() as CharacterBody2D
    var sprite: AnimatedSprite2D = incubator.get_node("IncubatorSprite") as AnimatedSprite2D
    var shadow: AnimatedSprite2D = incubator.get_node("IncubatorShadow") as AnimatedSprite2D
    assert(sprite.sprite_frames.get_frame_count("hover") == 4)
    assert(sprite.sprite_frames.get_animation_loop("hover"))
    assert(shadow.sprite_frames.get_frame_count("shadow") == 2)
    var inc_hit: CircleShape2D = (incubator.get_node("CollisionShape2D") as CollisionShape2D).shape as CircleShape2D
    assert(inc_hit != null and inc_hit.radius == 15.0)
    for i in range(4):
        var img: Image = sprite.sprite_frames.get_frame_texture("hover", i).get_image()
        assert(img.get_size() == Vector2i(64, 64))
        assert(img.get_pixel(0, 0).a < 0.01)
    var fx: AnimatedSprite2D = FX.instantiate() as AnimatedSprite2D
    assert(fx.sprite_frames.get_frame_count("burst") == 5)
    assert(not fx.sprite_frames.get_animation_loop("burst"))
    assert(fx.get_node_or_null("CollisionShape2D") == null)
    var mini: CharacterBody2D = MINI.instantiate() as CharacterBody2D
    assert(mini.get_node_or_null("MiniIgnelSprite") != null)
    var mini_hit: CircleShape2D = (mini.get_node("CollisionShape2D") as CollisionShape2D).shape as CircleShape2D
    assert(mini_hit != null and mini_hit.radius == 9.0)
    assert(mini.get_node_or_null("IgnelSprite") == null)
    var imp: CharacterBody2D = IMP.instantiate() as CharacterBody2D
    var skull: CharacterBody2D = SKULL.instantiate() as CharacterBody2D
    assert(imp.get_node_or_null("IncubatorSprite") == null)
    assert(skull.get_node_or_null("IncubatorSprite") == null)
    for obj in [incubator, mini, imp, skull, fx]:
        obj.free()
    print("[ALL IN 4.31.11] Cráneo Incubador, sombras, minis y FX correctos")
    queue_free()
