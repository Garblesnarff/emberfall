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

const STATS := {
	&"runs": "STAT_RUNS",
	&"kills": "STAT_KILLS",
	&"deaths": "STAT_DEATHS",
	&"play_ms": "STAT_PLAY_MS",
	&"victories": "STAT_VICTORIES",
	&"best_wave": "STAT_BEST_WAVE",
	&"best_score": "STAT_BEST_SCORE",
	&"best_combo": "STAT_BEST_COMBO",
	&"embers": "STAT_EMBERS",
}

const INPUT_ACTIONS := {
	&"move": "Move",
	&"aim": "Aim",
	&"dash": "Dash",
	&"pause": "Pause",
	&"ui_accept": "MenuAccept",
	&"ui_cancel": "MenuBack",
	&"ui_navigate": "MenuNavigate",
}

const INPUT_GLYPH_FALLBACKS := {
	&"move": "LEFT STICK",
	&"aim": "RIGHT STICK",
	&"dash": "A / RB",
	&"pause": "START",
	&"ui_accept": "A",
	&"ui_cancel": "B",
	&"ui_navigate": "D-PAD",
}

var available := false
var initialized := false
var steam: Object
var unlocked_achievements: Dictionary = {}
var rich_presence: Dictionary = {}
var stats: Dictionary = {}
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

func stat_api_name(id: StringName) -> String:
	return String(STATS.get(id, ""))

func steam_input_action_name(id: StringName) -> String:
	return String(INPUT_ACTIONS.get(id, ""))

func input_glyph_text(id: StringName) -> String:
	return String(INPUT_GLYPH_FALLBACKS.get(id, ""))

func set_stat(id: StringName, value: Variant, flush := true) -> void:
	var api_name := stat_api_name(id)
	if api_name == "":
		return
	stats[id] = value
	if available and steam:
		if typeof(value) == TYPE_FLOAT and steam.has_method("setStatFloat"):
			steam.call("setStatFloat", api_name, float(value))
		elif steam.has_method("setStatInt"):
			steam.call("setStatInt", api_name, int(value))
	if flush:
		store_stats()

func sync_save_stats(save_data: Dictionary) -> void:
	var best: Dictionary = save_data.get("best", {})
	var bank: Dictionary = save_data.get("bank", {})
	var save_stats: Dictionary = save_data.get("stats", {})
	set_stat(&"runs", int(save_stats.get("runs", 0)), false)
	set_stat(&"kills", int(save_stats.get("kills", 0)), false)
	set_stat(&"deaths", int(save_stats.get("deaths", 0)), false)
	set_stat(&"play_ms", int(save_stats.get("playMs", 0)), false)
	set_stat(&"victories", int(save_stats.get("victories", 0)), false)
	set_stat(&"best_wave", int(best.get("wave", 0)), false)
	set_stat(&"best_score", int(best.get("score", 0)), false)
	set_stat(&"best_combo", int(best.get("combo", 0)), false)
	set_stat(&"embers", int(bank.get("embers", 0)), false)
	store_stats()

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
	stats.clear()
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
	if bool(stats.get("demo_complete", false)):
		set_rich_presence("status", "Demo Complete")
	elif victory:
		set_rich_presence("status", "Forge Secured")
	else:
		set_rich_presence("status", "Forge Cold at Wave %d" % wave)
