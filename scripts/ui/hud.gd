extends Control

@onready var hp_bar: ProgressBar = %HPBar
@onready var dash_bar: ProgressBar = %DashBar
@onready var hp_label: Label = %HPLabel
@onready var wave_label: Label = %WaveLabel
@onready var remaining_label: Label = %RemainingLabel
@onready var score_label: Label = %ScoreLabel
@onready var combo_label: Label = %ComboLabel
@onready var phase3_label: Label = %Phase3Label
@onready var upgrade_label: Label = %UpgradeLabel
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

func set_phase3_state(weapon_name: String, embers: int, objective_text: String, anvil_hp: float, cards: Array, chest_text: String, selected_card := -1) -> void:
	var objective_line := objective_text
	if anvil_hp > 0.0:
		objective_line = "%s %.0f HP" % [objective_text, anvil_hp]
	phase3_label.text = "%s\nEMBERS %d\n%s" % [weapon_name, embers, objective_line]
	if chest_text != "":
		upgrade_label.text = chest_text
		upgrade_label.visible = true
	elif cards.is_empty():
		upgrade_label.text = ""
		upgrade_label.visible = false
	else:
		var lines: Array[String] = ["CHOOSE TEMPERING"]
		for i in range(cards.size()):
			var marker := ">" if i == selected_card else " "
			lines.append("%s %d  %s" % [marker, i + 1, cards[i].display_name])
		upgrade_label.text = "\n".join(lines)
		upgrade_label.visible = true
