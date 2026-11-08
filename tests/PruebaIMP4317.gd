extends Node
# Validación visual estructural v4.31.7: ejecutar como nodo de una escena de prueba.
const IMP_SCENE: PackedScene = preload("res://scenes/enemies/BasicEnemy.tscn")
const RANGED_SCENE: PackedScene = preload("res://scenes/enemies/RangedEnemy.tscn")
const SPLITTER_SCENE: PackedScene = preload("res://scenes/enemies/SplitterEnemy.tscn")
const IMP_FX_SCENE: PackedScene = preload("res://scenes/enemies/ImpDeathFX.tscn")

func _ready() -> void:
    var imp: CharacterBody2D = IMP_SCENE.instantiate() as CharacterBody2D
    add_child(imp)
    var sprite: AnimatedSprite2D = imp.get_node("ImpSprite") as AnimatedSprite2D
    assert(sprite != null)
    assert(sprite.sprite_frames.get_frame_count("chase") == 4)
    assert(sprite.sprite_frames.get_frame_count("attack") == 4)
    assert(sprite.sprite_frames.get_animation_loop("chase"))
    assert(not sprite.sprite_frames.get_animation_loop("attack"))
    for anim in ["chase", "attack"]:
        for i in range(sprite.sprite_frames.get_frame_count(anim)):
            var tex: Texture2D = sprite.sprite_frames.get_frame_texture(anim, i)
            assert(tex.get_size() == Vector2(64.0, 64.0))
            var image: Image = tex.get_image()
            assert(image.get_pixel(0, 0).a < 0.01)
    var fx: AnimatedSprite2D = IMP_FX_SCENE.instantiate() as AnimatedSprite2D
    assert(fx.sprite_frames.get_frame_count("vanish") == 7) # Base 4.31.8: IMP Polish Pass
    assert(not fx.sprite_frames.get_animation_loop("vanish"))
    fx.free()
    for scene in [RANGED_SCENE, SPLITTER_SCENE]:
        var other: Node2D = scene.instantiate() as Node2D
        add_child(other)
        assert(other.get_node_or_null("ImpSprite") == null)
        other.queue_free()
    imp.queue_free()
    print("[ALL IN 4.31.7] IMP: sprites, animaciones, transparencia, herencia OK")
    queue_free()
