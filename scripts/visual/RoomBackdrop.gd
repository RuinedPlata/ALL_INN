extends Node2D
## ALL IN 4.31.38 — fondo modular y luces decorativas (cero colisiones).
## Un Sprite2D fijo + un Sprite2D animado: no renderiza el GIF entero por frame.
## Se mantiene por debajo de Main, los obstáculos, actores, proyectiles y CanvasLayer.

var _floor: Sprite2D
var _lights: Sprite2D
var _frames: Array[Texture2D] = []
var _area: Rect2 = Rect2()
var _fps: float = 5.55
var _elapsed: float = 0.0
var _frame: int = 0
var _active: bool = false
var _theme_id: String = ""
var _animate_lights: bool = true

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    z_index = -50
    _floor = Sprite2D.new()
    _floor.name = "FloorStatic"
    _floor.centered = false
    _floor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(_floor)
    _lights = Sprite2D.new()
    _lights.name = "AmbientLights"
    _lights.centered = false
    _lights.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(_lights)
    set_process(false)

func has_active_theme() -> bool:
    return _active

func active_theme_id() -> String:
    return _theme_id

func configure(config: Dictionary, area: Rect2) -> void:
    var target_id: String = str(config.get("id", ""))
    var background: Texture2D = config.get("floor", null) as Texture2D
    if background == null:
        clear_theme()
        return
    if _active and target_id == _theme_id and _area == area:
        return # Sala siguiente con el mismo fondo: conservar fase y texturas.
    _area = area
    _theme_id = target_id
    _fps = maxf(1.0, float(config.get("fps", 5.55)))
    _frames.clear()
    for frame in config.get("frames", []):
        if frame is Texture2D:
            _frames.append(frame as Texture2D)
    _floor.texture = background
    _frame = 0
    _elapsed = 0.0
    _lights.texture = _frames[0] if not _frames.is_empty() else null
    _active = true
    _place_sprites()
    _refresh_animation()

func clear_theme() -> void:
    _active = false
    _theme_id = ""
    _frames.clear()
    _floor.texture = null
    _lights.texture = null
    _lights.visible = false
    set_process(false)

func set_ambient_animation_enabled(enabled: bool) -> void:
    # Listo para una futura opción gráfica en Android, sin tocar gameplay.
    _animate_lights = enabled
    _refresh_animation()

func _refresh_animation() -> void:
    _lights.visible = _active and _animate_lights and not _frames.is_empty()
    set_process(_lights.visible and _frames.size() > 1)

func _place_sprites() -> void:
    if _floor.texture == null:
        return
    var tex_size: Vector2 = _floor.texture.get_size()
    _floor.position = _area.position
    _floor.scale = Vector2(_area.size.x / tex_size.x, _area.size.y / tex_size.y)
    _lights.position = _area.position
    _lights.scale = _floor.scale

func _process(delta: float) -> void:
    if not _animate_lights or _frames.size() < 2:
        return
    _elapsed += delta
    var step: float = 1.0 / _fps
    if _elapsed < step:
        return
    var advance: int = int(_elapsed / step)
    _elapsed -= float(advance) * step
    _frame = (_frame + advance) % _frames.size()
    _lights.texture = _frames[_frame] # Solo 5.55 cambios por segundo.
