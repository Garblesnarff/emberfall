extends Node

const SFX_POOL_SIZE := 8
const BUS_MASTER := "Master"
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"

var sfx_players: Array[AudioStreamPlayer] = []
var sfx_cursor := 0
var last_sfx: StringName = &""
var intensity := 0.0
var audio_paused := false
var sfx_volume := 1.0
var music_volume := 1.0

func _ready() -> void:
	_ensure_buses()
	_build_sfx_pool()
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
	player.stream = _make_click_stream(id)
	player.play()

func set_intensity(value: float) -> void:
	intensity = clampf(value, 0.0, 1.0)

func set_audio_paused(paused: bool) -> void:
	audio_paused = paused
	for player in sfx_players:
		player.stream_paused = paused

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

func _make_click_stream(_id: StringName) -> AudioStreamGenerator:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = 0.05
	return stream
