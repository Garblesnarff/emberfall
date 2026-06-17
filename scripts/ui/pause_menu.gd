extends Control

signal resume_requested
signal settings_requested
signal forge_requested

@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var forge_button: Button = %ForgeButton

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	settings_button.pressed.connect(func() -> void: settings_requested.emit())
	forge_button.pressed.connect(func() -> void: forge_requested.emit())

