extends Node

const SFX_POOL_SIZE := 8
const BUS_MASTER := "Master"
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"
const SFX_DEFS := {
	&"enemy_kill": {"freq": 340.0, "duration": 0.055},
	&"boss_kill": {"freq": 120.0, "duration": 0.18},
	&"player_hurt": {"freq": 95.0, "duration": 0.16},
	&"wave_clear": {"freq": 520.0, "duration": 0.14},
	&"chest_open": {"freq": 760.0, "duration": 0.18},
	&"victory": {"freq": 880.0, "duration": 0.24},
	&"defeat": {"freq": 70.0, "duration": 0.28},
}
const BOSS_IDS := [&"kilnmaw", &"choir", &"aurum", &"aurum_rekindled"]
const MIX_RATE := 22050
const AMPLITUDE := 0.32

var sfx_players: Array[AudioStreamPlayer] = []
var sfx_cursor := 0
var sfx_stream_cache: Dictionary = {}
var last_sfx: StringName = &""
var intensity := 0.0
var audio_paused := false
var sfx_volume := 1.0
var music_volume := 1.0
var event_bus_connected := false

func _ready() -> void:
	_ensure_buses()
	_build_sfx_pool()
	_connect_event_bus()
	apply_settings()

func apply_settings() -> void:
	if SaveManager.data.is_empty():
		return
	var settings: Dictionary = SaveManager.data.get("settings", {})
	sfx_volume = clampf(float(settings.get("sfx", 1.0)), 0.0, 1.0)
	music_volume = clampf(float(settings.get("music", 1.0)), 0.0, 1.0)
	_set_bus_volume(BUS_SFX, sfx_volume)
	_set_bus_volume(BUS_MUSIC, music_volume)

func play_sfx(id: StringName, pitch_jitter := true) -> void:
	last_sfx = id
	if sfx_players.is_empty() or sfx_volume <= 0.0:
		return
	var player := sfx_players[sfx_cursor]
	sfx_cursor = (sfx_cursor + 1) % sfx_players.size()
	player.pitch_scale = Config.randf_range(0.95, 1.05) if pitch_jitter else 1.0
	player.stream = _sfx_stream(id)
	player.play()

func set_intensity(value: float) -> void:
	intensity = clampf(value, 0.0, 1.0)

func set_audio_paused(paused: bool) -> void:
	audio_paused = paused
	for player in sfx_players:
		player.stream_paused = paused

func reset_for_tests() -> void:
	last_sfx = &""
	intensity = 0.0
	audio_paused = false
	sfx_cursor = 0

func _build_sfx_pool() -> void:
	if not sfx_players.is_empty():
		return
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		sfx_players.append(player)

func _ensure_buses() -> void:
	for bus_name in [BUS_SFX, BUS_MUSIC]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, bus_name)

func _set_bus_volume(bus_name: String, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(max(value, 0.0001)))
	AudioServer.set_bus_mute(index, value <= 0.0)

func _connect_event_bus() -> void:
	if event_bus_connected:
		return
	event_bus_connected = true
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_hurt.connect(_on_player_hurt)
	EventBus.boss_phase.connect(_on_boss_phase)
	EventBus.chest_opened.connect(_on_chest_opened)
	EventBus.wave_cleared.connect(_on_wave_cleared)
	EventBus.combo_changed.connect(_on_combo_changed)
	EventBus.run_ended.connect(_on_run_ended)

func _on_enemy_killed(data: Resource) -> void:
	var enemy_id := StringName(data.get("id")) if data else &""
	play_sfx(&"boss_kill" if BOSS_IDS.has(enemy_id) else &"enemy_kill")

func _on_player_hurt(_amount: float, _source: Variant) -> void:
	set_intensity(max(intensity, 0.75))
	play_sfx(&"player_hurt", false)

func _on_boss_phase(_boss: Node, _phase: int) -> void:
	set_intensity(1.0)
	play_sfx(&"boss_kill", false)

func _on_chest_opened(_contents: Array) -> void:
	play_sfx(&"chest_open")

func _on_wave_cleared(_wave: int) -> void:
	set_intensity(0.35)
	play_sfx(&"wave_clear")

func _on_combo_changed(n: int) -> void:
	set_intensity(max(intensity, clampf(float(n) / 100.0, 0.0, 1.0)))

func _on_run_ended(victory: bool, _stats: Dictionary) -> void:
	set_intensity(0.0)
	play_sfx(&"victory" if victory else &"defeat", false)

func _sfx_stream(id: StringName) -> AudioStreamWAV:
	if sfx_stream_cache.has(id):
		return sfx_stream_cache[id]
	var def: Dictionary = SFX_DEFS.get(id, SFX_DEFS[&"enemy_kill"])
	var stream := _make_tone_stream(float(def.freq), float(def.duration))
	sfx_stream_cache[id] = stream
	return stream

func _make_tone_stream(freq: float, duration: float) -> AudioStreamWAV:
	var sample_count := maxi(1, int(duration * float(MIX_RATE)))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / float(MIX_RATE)
		var envelope := 1.0 - (float(i) / float(sample_count))
		var sample := sin(TAU * freq * t) * envelope * AMPLITUDE
		bytes.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
