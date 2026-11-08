extends "res://scripts/combat/EnemyProjectile.gd"
# Mantiene la lógica de colisión, daño, alcance y velocidad del disparo enemigo.
# Solo sustituye el dibujo del proyectil rosado por su animación de fuego.
func _ready() -> void:
    super._ready()
    $FireSprite.play("travel")

func _draw() -> void:
    pass # El Sprite2D reemplaza los círculos pintados por el proyectil genérico.
