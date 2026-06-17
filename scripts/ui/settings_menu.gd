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
@onready var binding_list: VBoxContainer = %BindingList
@onready var reset_controls_button: Button = %ResetControlsButton
@onready var close_button: Button = %CloseButton

var binding_buttons: Dictionary = {}
var capture_action: StringName = &""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	close_button.pressed.connect(func() -> void: closed.emit())
	reset_controls_button.pressed.connect(_reset_controls)
	_build_binding_rows()
	_load_values()
	_connect_controls()
	close_button.grab_focus()

func _input(event: InputEvent) -> void:
	if capture_action == &"":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.keycode == KEY_ESCAPE:
			_cancel_capture()
			return
		SaveManager.update_key_binding(capture_action, event.keycode)
		_update_binding_buttons()
		capture_action = &""

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
	_update_binding_buttons()

func _connect_controls() -> void:
	sfx_slider.value_changed.connect(func(value: float) -> void: SaveManager.update_setting("sfx", value))
	music_slider.value_changed.connect(func(value: float) -> void: SaveManager.update_setting("music", value))
	shake_slider.value_changed.connect(func(value: float) -> void: SaveManager.update_setting("shake", value))
	damage_numbers_check.toggled.connect(func(value: bool) -> void: SaveManager.update_setting("dnums", value))
	minimap_check.toggled.connect(func(value: bool) -> void: SaveManager.update_setting("minimap", value))
	fps_check.toggled.connect(func(value: bool) -> void: SaveManager.update_setting("fps", value))
	fullscreen_check.toggled.connect(func(value: bool) -> void: SaveManager.update_setting("fullscreen", value))
	vsync_check.toggled.connect(func(value: bool) -> void: SaveManager.update_setting("vsync", value))

func _build_binding_rows() -> void:
	for child in binding_list.get_children():
		child.queue_free()
	binding_buttons.clear()
	for action in Config.REBINDABLE_ACTIONS:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 34)
		var label := Label.new()
		label.text = Config.action_label(action)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 30)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_begin_capture.bind(action))
		row.add_child(label)
		row.add_child(button)
		binding_list.add_child(row)
		binding_buttons[action] = button

func _begin_capture(action: StringName) -> void:
	capture_action = action
	_update_binding_buttons()

func _cancel_capture() -> void:
	capture_action = &""
	_update_binding_buttons()

func _update_binding_buttons() -> void:
	for action in Config.REBINDABLE_ACTIONS:
		var button: Button = binding_buttons.get(action)
		if not button:
			continue
		button.text = "PRESS KEY" if action == capture_action else Config.keyboard_binding_text(action).to_upper()

func _reset_controls() -> void:
	SaveManager.reset_key_bindings()
	capture_action = &""
	_update_binding_buttons()
