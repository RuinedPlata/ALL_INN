extends AnimatedSprite2D
# Solo animación: no cuenta como enemigo, no tiene colisión ni retrasa la oleada.
func _ready() -> void:
    animation_finished.connect(queue_free)
    play("vanish")
