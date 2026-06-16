extends Control

@onready var title_label: Label = %TitleLabel
@onready var stats_label: Label = %StatsLabel

func set_recap(recap: Dictionary) -> void:
	title_label.text = "FORGE SECURED" if recap.get("victory", false) else "RUN ENDED"
	stats_label.text = "WAVE %d\nSCORE %d\nKILLS %d\nBEST COMBO %d\nEMBERS BANKED %d\n%s" % [
		int(recap.get("wave", 0)),
		int(recap.get("score", 0)),
		int(recap.get("kills", 0)),
		int(recap.get("best_combo", 0)),
		int(recap.get("embers_banked", 0)),
		String(recap.get("weapon", "")),
	]
