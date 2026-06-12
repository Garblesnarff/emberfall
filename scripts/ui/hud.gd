extends Control

@onready var hp_bar: ProgressBar = %HPBar
@onready var dash_bar: ProgressBar = %DashBar
@onready var hp_label: Label = %HPLabel
@onready var wave_label: Label = %WaveLabel
@onready var remaining_label: Label = %RemainingLabel
@onready var score_label: Label = %ScoreLabel
@onready var combo_label: Label = %ComboLabel

func set_values(hp: float, max_hp: float, dash_ready: float, wave: int, remaining: int, score: int, kills: int, combo: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	dash_bar.value = clampf(dash_ready * 100.0, 0.0, 100.0)
	hp_label.text = "%d / %d" % [ceili(hp), ceili(max_hp)]
	wave_label.text = "WAVE %d" % wave
	remaining_label.text = "%d REMAIN" % remaining
	score_label.text = "SCORE %d\n%d PURGED" % [score, kills]
	combo_label.text = "%dx COMBO" % combo if combo > 5 else ""
