extends Node

const SAVE_PATH := "user://emberfall.save"
const SAVE_VERSION := 4

var data := {}

func _ready() -> void:
	load_save()

func default_save() -> Dictionary:
	return {
		"v": SAVE_VERSION,
		"best": {"wave": 0, "score": 0, "combo": 0},
		"bank": {"embers": 0},
		"unlocks": {"weapons": ["forgehammer"], "perks": [], "cards": []},
		"settings": {"sfx": 1.0, "music": 1.0, "shake": 1.0, "dnums": true, "minimap": true, "fps": false},
		"stats": {"runs": 0, "kills": 0, "deaths": 0, "playMs": 0, "victories": 0},
	}

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		data = default_save()
		return
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or parsed.get("v", 0) != SAVE_VERSION:
		var backup := SAVE_PATH + ".corrupt"
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(backup))
		data = default_save()
		return
	data = parsed

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
