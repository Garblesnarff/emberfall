extends Node

const SAVE_PATH := "user://emberfall.save"
const SAVE_VERSION := 4

var data := {}

func _ready() -> void:
	load_save()
	Config.apply_settings(data.get("settings", {}))

func default_save() -> Dictionary:
	return {
		"v": SAVE_VERSION,
		"best": {"wave": 0, "score": 0, "combo": 0},
		"bank": {"embers": 0},
		"unlocks": {"weapons": ["forgehammer"], "perks": [], "cards": []},
		"settings": {"sfx": 1.0, "music": 1.0, "shake": 1.0, "dnums": true, "minimap": true, "fps": false, "fullscreen": false, "vsync": true, "bindings": Config.default_keyboard_bindings()},
		"stats": {"runs": 0, "kills": 0, "deaths": 0, "playMs": 0, "victories": 0},
	}

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		data = default_save()
		return
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var json := JSON.new()
	if json.parse(text) != OK:
		_backup_corrupt_save()
		data = default_save()
		return
	var parsed = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		_backup_corrupt_save()
		data = default_save()
		return
	data = _migrate(parsed)
	save()

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func update_setting(key: String, value: Variant) -> void:
	data = _migrate(data)
	data.settings[key] = value
	save()
	Config.apply_settings(data.settings)
	AudioDirector.apply_settings()

func update_key_binding(action: StringName, keycode: int) -> void:
	data = _migrate(data)
	data.settings.bindings[String(action)] = keycode
	save()
	Config.set_keyboard_binding(action, keycode)

func reset_key_bindings() -> void:
	data = _migrate(data)
	data.settings.bindings = Config.reset_keyboard_bindings()
	save()

func _migrate(source: Dictionary) -> Dictionary:
	var migrated := default_save()
	if int(source.get("v", 0)) > SAVE_VERSION:
		_backup_corrupt_save()
		return migrated
	for key in source.keys():
		if key == "v":
			continue
		if typeof(source[key]) == TYPE_DICTIONARY and typeof(migrated.get(key)) == TYPE_DICTIONARY:
			for sub_key in source[key].keys():
				if typeof(source[key][sub_key]) == TYPE_DICTIONARY and typeof(migrated[key].get(sub_key)) == TYPE_DICTIONARY:
					for nested_key in source[key][sub_key].keys():
						migrated[key][sub_key][nested_key] = source[key][sub_key][nested_key]
				else:
					migrated[key][sub_key] = source[key][sub_key]
		else:
			migrated[key] = source[key]
	migrated.v = SAVE_VERSION
	return migrated

func _backup_corrupt_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(SAVE_PATH + ".corrupt"))

func record_run(victory: bool, wave: int, score: int, combo: int, kills: int, embers: int, play_ms: int = 0) -> void:
	data = _migrate(data)
	data.best.wave = max(int(data.best.wave), wave)
	data.best.score = max(int(data.best.score), score)
	data.best.combo = max(int(data.best.combo), combo)
	data.bank.embers = int(data.bank.embers) + embers
	data.stats.runs = int(data.stats.runs) + 1
	data.stats.kills = int(data.stats.kills) + kills
	data.stats.deaths = int(data.stats.deaths) + (0 if victory else 1)
	data.stats.playMs = int(data.stats.playMs) + max(play_ms, 0)
	data.stats.victories = int(data.stats.victories) + (1 if victory else 0)
	save()
	SteamManager.sync_save_stats(data)

func record_demo_run(wave: int, score: int, combo: int, kills: int, embers: int, play_ms: int = 0) -> void:
	data = _migrate(data)
	data.best.wave = max(int(data.best.wave), wave)
	data.best.score = max(int(data.best.score), score)
	data.best.combo = max(int(data.best.combo), combo)
	data.bank.embers = int(data.bank.embers) + embers
	data.stats.runs = int(data.stats.runs) + 1
	data.stats.kills = int(data.stats.kills) + kills
	data.stats.playMs = int(data.stats.playMs) + max(play_ms, 0)
	save()
	SteamManager.sync_save_stats(data)
