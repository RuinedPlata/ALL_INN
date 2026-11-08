extends AnimatedSprite2D
# Efecto EXCLUSIVAMENTE visual: no tiene hitbox, grupos ni lógica de combate.
func _ready() -> void:
    animation_finished.connect(queue_free)
    play("burst")
