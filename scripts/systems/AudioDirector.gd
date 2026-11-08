extends Node
# Audio central para móviles: una voz por disparo, NO una por perdigón.
# Reutiliza reproductores; limita la repetición de impactos simultáneos.
const SOUND_NAMES := ["shot_pistol", "shot_shotgun", "shot_smg", "shot_deagle", "shot_enemy", "hit_enemy", "hurt_player", "parry", "evasion", "shield", "boss_ring", "boss_charge", "boss_defeat"]
const VOICES: int = 10
var sfx: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_index: int = 0
var last_play_ms: Dictionary = {}
var music: AudioStreamPlayer
var music_enabled: bool = true
var sfx_enabled: bool = true

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for sound_name in SOUND_NAMES:
        sfx[sound_name] = load("res://audio/%s.wav" % sound_name)
    for index in range(VOICES):
        var voice := AudioStreamPlayer.new()
        voice.name = "Efecto%d" % index
        voice.volume_db = -7.0
        voice.process_mode = Node.PROCESS_MODE_ALWAYS
        add_child(voice)
        voices.append(voice)
    music = AudioStreamPlayer.new()
    music.name = "MusicaPartida"
    music.volume_db = -4.0
    music.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(music)
    var track: AudioStream = load("res://audio/ALL_IN_Fiebre_Del_Casino_loop.ogg")
    if track == null:
        push_warning("ALL IN: el OGG no se pudo cargar; utilizando respaldo WAV.")
        track = load("res://audio/ALL_IN_Fiebre_Del_Casino_respaldo.wav")
    var ogg: AudioStreamOggVorbis = track as AudioStreamOggVorbis
    if ogg != null:
        ogg.loop = true
    var wave: AudioStreamWAV = track as AudioStreamWAV
    if wave != null:
        wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
    music.stream = track
    if music_enabled and music.stream != null:
        music.play()
    elif music.stream == null:
        push_error("ALL IN: sin archivo de música de partida disponible.")

func _process(_delta: float) -> void:
    if music == null or not music_enabled:
        return
    # El estado de pausa debe actualizarse incluso cuando is_playing false
    # bajo algunos controladores móviles tras suspender/reanudar la app.
    var should_pause: bool = get_tree().paused
    # Evitar escribir la propiedad del mezclador 60+ veces por segundo.
    # La música conserva su velocidad y pitch; solo cambia al pausar/reanudar.
    if music.stream_paused != should_pause:
        music.stream_paused = should_pause
    if not should_pause and not music.playing and music.stream != null:
        music.play()

func play_sfx(sound_name: String) -> void:
    if not sfx_enabled or not sfx.has(sound_name):
        return
    var minimum_gap: int = 72 if sound_name == "hit_enemy" else (65 if sound_name.begins_with("shot_") else 110)
    var now: int = Time.get_ticks_msec()
    if now - int(last_play_ms.get(sound_name, -100000)) < minimum_gap:
        return
    last_play_ms[sound_name] = now
    var voice: AudioStreamPlayer = voices[voice_index]
    voice_index = (voice_index + 1) % VOICES
    voice.stop()
    voice.stream = sfx[sound_name]
    voice.pitch_scale = randf_range(0.97, 1.03)
    voice.play()

func set_music_enabled(enabled: bool) -> void:
    music_enabled = enabled
    if music == null:
        return
    if enabled and not music.playing:
        music.play()
    elif not enabled:
        music.stop()

func set_sfx_enabled(enabled: bool) -> void:
    sfx_enabled = enabled
