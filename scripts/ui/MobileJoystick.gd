extends Control
# 4.22: joystick flotante. Aparece donde empieza un toque LIBRE y sigue
# exclusivamente ese dedo; los menús y botones conservan su prioridad.
const STICK_RADIUS: float = 54.0

var active_touch: int = -1
var mouse_down: bool = false
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_to_group("mobile_joystick")
    hide()  # Solo aparece mientras se está controlando el movimiento.

func get_direction() -> Vector2:
    if get_tree().paused or not RunManager.run_active:
        return Vector2.ZERO
    return direction

func _can_start() -> bool:
    return RunManager.run_active and not get_tree().paused and active_touch == -1 and not mouse_down

func _process(_delta: float) -> void:
    # Evita controles pegados al abrir un menú o perder el dedo/mouse.
    if get_tree().paused or not RunManager.run_active or (mouse_down and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
        _reset_stick()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
        _reset_stick()

func cancel_touch() -> void:
    # Las interfaces detienen los controles explícitamente, también si un
    # toque se levantó en el mismo fotograma en que abrió un menú.
    _reset_stick()

func _reset_stick() -> void:
    if active_touch != -1 or mouse_down or direction != Vector2.ZERO or visible:
        active_touch = -1
        mouse_down = false
        direction = Vector2.ZERO
        hide()
        queue_redraw()

func _start_stick(screen_pos: Vector2, touch_index: int, from_mouse: bool) -> void:
    # Las coordenadas del evento son del viewport; no hay área fija inferior.
    global_position = screen_pos - size * 0.5
    active_touch = touch_index
    mouse_down = from_mouse
    direction = Vector2.ZERO
    show()
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    # Al llegar aquí, el GUI ya tuvo prioridad sobre el evento inicial.
    # Un toque sobre MOCHILA, PACTO, PAUSA o cualquier menú NO inicia movimiento.
    if not _can_start():
        return
    if event is InputEventScreenTouch and event.pressed:
        _start_stick(event.position, event.index, false)
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _start_stick(event.position, -1, true)
        get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
    # Continuaciones del dedo capturado: no pueden cambiar a otro dedo.
    if active_touch >= 0:
        if event is InputEventScreenDrag and event.index == active_touch:
            _set_direction(event.position)
            get_viewport().set_input_as_handled()
        elif event is InputEventScreenTouch and not event.pressed and event.index == active_touch:
            _reset_stick()
            get_viewport().set_input_as_handled()
    elif mouse_down:
        if event is InputEventMouseMotion:
            _set_direction(event.position)
            get_viewport().set_input_as_handled()
        elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
            _reset_stick()
            get_viewport().set_input_as_handled()

func _set_direction(screen_pos: Vector2) -> void:
    var center: Vector2 = global_position + size * 0.5
    direction = ((screen_pos - center) / STICK_RADIUS).limit_length(1.0)
    if direction.length() < 0.10:
        direction = Vector2.ZERO
    queue_redraw()

func _draw() -> void:
    var center: Vector2 = size * 0.5
    draw_circle(center, STICK_RADIUS + 8.0, Color("#262c3c", 0.72))
    draw_arc(center, STICK_RADIUS, 0, TAU, 56, Color("#87c7c1", 0.8), 3)
    draw_circle(center + direction * STICK_RADIUS, 24.0, Color("#71cbb7", 0.92))
    draw_circle(center + direction * STICK_RADIUS, 13.0, Color("#c4fff5", 0.8))
