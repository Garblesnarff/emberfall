extends Node

const ACHIEVEMENTS := {
	&"first_light": "ACH_FIRST_LIGHT",
	&"slagbreaker": "ACH_SLAGBREAKER",
	&"choir_silencer": "ACH_CHOIR_SILENCER",
	&"tyrants_end": "ACH_TYRANTS_END",
	&"forge_secured": "ACH_FORGE_SECURED",
	&"untouchable": "ACH_UNTOUCHABLE",
	&"centurion": "ACH_CENTURION",
	&"evolved": "ACH_EVOLVED",
	&"full_bank": "ACH_FULL_BANK",
	&"old_hand": "ACH_OLD_HAND",
}

var available := false
var initialized := false
var steam: Object
var unlocked_achievements: Dictionary = {}
var rich_presence: Dictionary = {}
var cloud_enabled := false
var stats_store_requests := 0
var event_bus_connected := false

func _ready() -> void:
	initialize()
	_connect_event_bus()
	set_rich_presence("status", "In the Forge")

func initialize() -> bool:
	if initialized:
		return available
	initialized = true
	if Engine.has_singleton("Steam"):
		steam = Engine.get_singleton("Steam")
		available = _try_steam_init()
	cloud_enabled = available
	return available

func is_available() -> bool:
	return available

func unlock_achievement(id: StringName) -> void:
	var api_name := achievement_api_name(id)
	if api_name == "":
		return
	unlocked_achievements[id] = true
	if available and steam and steam.has_method("setAchievement"):
		steam.call("setAchievement", api_name)
	store_stats()

func achievement_api_name(id: StringName) -> String:
	return String(ACHIEVEMENTS.get(id, ""))

func set_rich_presence(key: String, value := "") -> void:
	rich_presence[key] = value
	if available and steam and steam.has_method("setRichPresence"):
		steam.call("setRichPresence", key, value)

func store_stats() -> void:
	stats_store_requests += 1
	if available and steam and steam.has_method("storeStats"):
		steam.call("storeStats")

func set_cloud_enabled(enabled: bool) -> void:
	cloud_enabled = enabled and available
	if available and steam and steam.has_method("setSyncPlatforms"):
		steam.call("setSyncPlatforms", 0xffffffff if cloud_enabled else 0)

func reset_for_tests() -> void:
	unlocked_achievements.clear()
	rich_presence.clear()
	stats_store_requests = 0
	set_rich_presence("status", "In the Forge")

func _try_steam_init() -> bool:
	if not steam:
		return false
	if steam.has_method("steamInitEx"):
		var result = steam.call("steamInitEx")
		if typeof(result) == TYPE_DICTIONARY:
			return int(result.get("status", 1)) == 0
		return int(result) == 0
	if steam.has_method("steamInit"):
		var result = steam.call("steamInit")
		if typeof(result) == TYPE_DICTIONARY:
			return int(result.get("status", 1)) == 0
		if typeof(result) == TYPE_BOOL:
			return result
		return int(result) == 0
	return false

func _connect_event_bus() -> void:
	if event_bus_connected:
		return
	event_bus_connected = true
	EventBus.run_started.connect(_on_run_started)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.run_ended.connect(_on_run_ended)

func _on_run_started(_seed: int) -> void:
	set_rich_presence("status", "Wave 1 - Forging")

func _on_wave_started(wave: int) -> void:
	set_rich_presence("status", "Wave %d - Forging" % wave)

func _on_run_ended(victory: bool, stats: Dictionary) -> void:
	var wave := int(stats.get("wave", GameState.wave))
	if victory:
		set_rich_presence("status", "Forge Secured")
	else:
		set_rich_presence("status", "Forge Cold at Wave %d" % wave)
