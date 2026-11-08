extends SceneTree
## godot --headless --path . --script res://tests/PruebaFondo43138.gd
const CATALOG = preload("res://scripts/visual/RoomThemeCatalog.gd")
const BACKDROP = preload("res://scripts/visual/RoomBackdrop.gd")

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var theme: Dictionary = CATALOG.theme_for_room(1)
    assert(str(theme.get("id", "")) == "ficha_infernal", "Catálogo incorrecto")
    var floor: Texture2D = theme.get("floor", null) as Texture2D
    assert(floor != null and floor.get_size() == Vector2(180, 320), "Fondo debe ser 180×320")
    var frames: Array = theme.get("frames", [])
    assert(frames.size() == 6, "Se esperan seis capas de luces")
    for frame in frames:
        assert(frame is Texture2D and frame.get_size() == Vector2(180, 320), "Capa de luces con tamaño incorrecto")
    var backdrop: Node2D = BACKDROP.new() as Node2D
    root.add_child(backdrop)
    backdrop.call("configure", theme, Rect2(Vector2.ZERO, Vector2(540, 960)))
    assert(bool(backdrop.call("has_active_theme")), "El tema debe estar activo")
    assert(backdrop.z_index < 0, "El fondo debe estar detrás del combate")
    var floor_sprite: Sprite2D = backdrop.get_node("FloorStatic") as Sprite2D
    var light_sprite: Sprite2D = backdrop.get_node("AmbientLights") as Sprite2D
    assert(floor_sprite != null, "Falta Sprite2D estático")
    assert(light_sprite != null, "Falta Sprite2D de luces")
    assert(floor_sprite.scale == Vector2(3.0, 3.0), "Escalado pixel-art incorrecto")
    assert(CATALOG.theme_for_room(30).get("id") == "ficha_infernal", "Cambio inesperado de sala")
    backdrop.call("set_ambient_animation_enabled", false)
    assert(not light_sprite.visible, "Las luces deben poder desactivarse")
    backdrop.call("set_ambient_animation_enabled", true)
    assert(light_sprite.visible, "Las luces deben poder activarse")
    print("ALL IN 4.31.38: fondo, catálogo, seis luces y capas OK")
    quit(0)
