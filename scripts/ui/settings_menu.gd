extends Control

signal closed

@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var shake_slider: HSlider = %ShakeSlider
@onready var damage_numbers_check: CheckBox = %DamageNumbersCheck
@onready var minimap_check: CheckBox = %MinimapCheck
@onready var fps_check: CheckBox = %FpsCheck
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var vsync_check: CheckBox = %VsyncCheck
@onready var close_button: Button = %CloseButton

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	close_button.pressed.connect(func() -> void: closed.emit())
	_load_values()
	_connect_controls()
	close_button.grab_focus()

func _load_values() -> void:
	var settings: Dictionary = SaveManager.data.get("settings", {})
	sfx_slider.value = float(settings.get("sfx", 1.0))
	music_slider.value = float(settings.get("music", 1.0))
	shake_slider.value = float(settings.get("shake", 1.0))
	damage_numbers_check.button_pressed = bool(settings.get("dnums", true))
	minimap_check.button_pressed = bool(settings.get("minimap", true))
	fps_check.button_pressed = bool(settings.get("fps", false))
	fullscreen_check.button_pressed = bool(settings.get("fullscreen", false))
	vsync_check.button_pressed = bool(settings.get("vsync", true))

func _connect_controls() -> void:
	sfx_slider.value_changed.connect(func(value: float) -> void: SaveManager.update_setting("sfx", value))
	music_slider.value_changed.connect(func(value: float) -> void: SaveManager.update_setting("music", value))
	shake_slider.value_changed.connect(func(value: float) -> void: SaveManager.update_setting("shake", value))
	damage_numbers_check.toggled.connect(func(value: bool) -> void: SaveManager.update_setting("dnums", value))
	minimap_check.toggled.connect(func(value: bool) -> void: SaveManager.update_setting("minimap", value))
	fps_check.toggled.connect(func(value: bool) -> void: SaveManager.update_setting("fps", value))
	fullscreen_check.toggled.connect(func(value: bool) -> void: SaveManager.update_setting("fullscreen", value))
	vsync_check.toggled.connect(func(value: bool) -> void: SaveManager.update_setting("vsync", value))
