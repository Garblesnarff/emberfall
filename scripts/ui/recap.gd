extends Control

const VICTORY_BACKGROUND := preload("res://assets/sprites/ui/victory_screen.png")
const DEFEAT_BACKGROUND := preload("res://assets/sprites/ui/defeat_screen.png")

signal restart_requested
signal forge_requested
signal endless_requested
signal end_run_requested

@onready var title_label: Label = %TitleLabel
@onready var stats_label: Label = %StatsLabel
@onready var background: TextureRect = %Background
@onready var restart_button: Button = %RestartButton
@onready var forge_button: Button = %ForgeButton
@onready var endless_button: Button = %EndlessButton
@onready var end_run_button: Button = %EndRunButton

func _ready() -> void:
	_fit_to_viewport()
	get_viewport().size_changed.connect(_fit_to_viewport)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	forge_button.pressed.connect(func() -> void: forge_requested.emit())
	endless_button.pressed.connect(func() -> void: endless_requested.emit())
	end_run_button.pressed.connect(func() -> void: end_run_requested.emit())

func _fit_to_viewport() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_recap(recap: Dictionary) -> void:
	var victory: bool = recap.get("victory", false)
	background.texture = VICTORY_BACKGROUND if victory else DEFEAT_BACKGROUND
	title_label.text = "FORGE SECURED" if victory else "RUN ENDED"
	stats_label.text = "WAVE %d\nSCORE %d\nKILLS %d\nBEST COMBO %d\nEMBERS BANKED %d\n%s" % [
		int(recap.get("wave", 0)),
		int(recap.get("score", 0)),
		int(recap.get("kills", 0)),
		int(recap.get("best_combo", 0)),
		int(recap.get("embers_banked", 0)),
		String(recap.get("weapon", "")),
	]
	endless_button.visible = victory
	end_run_button.visible = victory
