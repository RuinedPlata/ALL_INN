extends AnimatedSprite2D
# Only a visual effect: no hitbox, no loot, no group "enemies".
func _ready() -> void:
    animation_finished.connect(queue_free)
    play("burst")
