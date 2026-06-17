extends Node

var unlocked: Dictionary = {}
var wave_damage_taken := false

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_hurt.connect(_on_player_hurt)
	EventBus.wave_cleared.connect(_on_wave_cleared)
	EventBus.combo_changed.connect(_on_combo_changed)
	EventBus.chest_opened.connect(_on_chest_opened)
	EventBus.run_ended.connect(_on_run_ended)

func reset_for_tests() -> void:
	unlocked.clear()
	wave_damage_taken = false
	SteamManager.unlocked_achievements.clear()
	SteamManager.stats_store_requests = 0

func _unlock(id: StringName) -> void:
	if unlocked.has(id):
		return
	unlocked[id] = true
	SteamManager.unlock_achievement(id)

func _on_enemy_killed(data: Resource) -> void:
	if not data:
		return
	match data.id:
		&"kilnmaw":
			_unlock(&"slagbreaker")
		&"choir":
			_unlock(&"choir_silencer")
		&"aurum", &"aurum_rekindled":
			_unlock(&"tyrants_end")

func _on_player_hurt(_amount: float, _source: Variant) -> void:
	wave_damage_taken = true

func _on_wave_cleared(wave: int) -> void:
	if wave == 1:
		_unlock(&"first_light")
	if wave >= 10 and not wave_damage_taken:
		_unlock(&"untouchable")
	wave_damage_taken = false

func _on_combo_changed(combo: int) -> void:
	if combo >= 100:
		_unlock(&"centurion")

func _on_chest_opened(contents: Array) -> void:
	for item in contents:
		if item in [&"meteor_volley", &"railspike", &"crucible_breath"]:
			_unlock(&"evolved")
			return

func _on_run_ended(victory: bool, _stats: Dictionary) -> void:
	if victory:
		_unlock(&"forge_secured")
	if int(SaveManager.data.get("bank", {}).get("embers", 0)) >= 1000:
		_unlock(&"full_bank")
	if int(SaveManager.data.get("stats", {}).get("runs", 0)) >= 25:
		_unlock(&"old_hand")
