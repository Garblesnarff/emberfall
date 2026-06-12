extends Control

@onready var hp_bar: ProgressBar = %HPBar
@onready var dash_bar: ProgressBar = %DashBar
@onready var hp_label: Label = %HPLabel
@onready var wave_label: Label = %WaveLabel
@onready var remaining_label: Label = %RemainingLabel
@onready var score_label: Label = %ScoreLabel
@onready var combo_label: Label = %ComboLabel
@onready var minimap: Control = %Minimap
@onready var threat_chevrons: Control = %ThreatChevrons

func set_values(hp: float, max_hp: float, dash_ready: float, wave: int, remaining: int, score: int, kills: int, combo: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	dash_bar.value = clampf(dash_ready * 100.0, 0.0, 100.0)
	hp_label.text = "%d / %d" % [ceili(hp), ceili(max_hp)]
	wave_label.text = "WAVE %d" % wave
	remaining_label.text = "%d REMAIN" % remaining
	score_label.text = "SCORE %d\n%d PURGED" % [score, kills]
	combo_label.text = "%dx COMBO" % combo if combo > 5 else ""

func set_world_state(player_pos: Vector2, camera_pos: Vector2, enemies: Array, world_size: Vector2, boss_telegraph_pos := Vector2.INF, objective_markers: Array = []) -> void:
	minimap.set_world_state(player_pos, enemies, world_size, boss_telegraph_pos, objective_markers)
	threat_chevrons.set_world_state(player_pos, camera_pos, enemies, boss_telegraph_pos, objective_markers)
