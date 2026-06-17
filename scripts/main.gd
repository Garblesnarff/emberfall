extends Node

const ForgeMenuScene := preload("res://scenes/ui/forge_menu.tscn")
const RecapScene := preload("res://scenes/ui/recap.tscn")
const PauseMenuScene := preload("res://scenes/ui/pause_menu.tscn")
const SettingsMenuScene := preload("res://scenes/ui/settings_menu.tscn")

@onready var arena: Node = %Arena

var forge_menu: Control
var recap: Control
var pause_menu: Control
var settings_menu: Control
var ui_layer: CanvasLayer
var state_before_settings := GameState.RunState.MENU

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 50
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_layer)
	EventBus.run_ended.connect(_on_run_ended)
	_set_arena_visible(false)
	_show_forge()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameState.state == GameState.RunState.PLAY:
			_pause_run()
		elif GameState.state == GameState.RunState.PAUSE:
			_resume_run()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and GameState.state == GameState.RunState.PLAY:
		_pause_run()

func _show_forge() -> void:
	get_tree().paused = false
	AudioDirector.set_audio_paused(false)
	GameState.state = GameState.RunState.MENU
	_set_arena_visible(false)
	_clear_recap()
	_clear_pause()
	_clear_settings()
	if not is_instance_valid(forge_menu):
		forge_menu = ForgeMenuScene.instantiate()
		ui_layer.add_child(forge_menu)
		forge_menu.start_run_requested.connect(_start_run)
		forge_menu.settings_requested.connect(_show_settings)
	forge_menu.visible = true
	if forge_menu.has_method("refresh"):
		forge_menu.refresh()

func _start_run() -> void:
	get_tree().paused = false
	AudioDirector.set_audio_paused(false)
	_clear_recap()
	_clear_pause()
	_clear_settings()
	if is_instance_valid(forge_menu):
		forge_menu.visible = false
	_set_arena_visible(true)
	var run_index := int(SaveManager.data.stats.runs) + 1
	arena.begin_run(0xE4BEF411 + run_index)

func _on_run_ended(_victory: bool, _stats: Dictionary) -> void:
	_show_recap(GameState.last_recap)

func _show_recap(stats: Dictionary) -> void:
	get_tree().paused = false
	AudioDirector.set_audio_paused(false)
	_set_arena_visible(false)
	_clear_pause()
	_clear_settings()
	if not is_instance_valid(recap):
		recap = RecapScene.instantiate()
		ui_layer.add_child(recap)
		recap.restart_requested.connect(_start_run)
		recap.forge_requested.connect(_show_forge)
		recap.endless_requested.connect(_enter_endless)
		recap.end_run_requested.connect(_show_forge)
	recap.visible = true
	recap.set_recap(stats)

func _enter_endless() -> void:
	if is_instance_valid(recap):
		recap.visible = false
	_set_arena_visible(true)
	AudioDirector.set_audio_paused(false)
	if arena.has_method("enter_endless"):
		arena.enter_endless()

func _clear_recap() -> void:
	if is_instance_valid(recap):
		recap.visible = false

func _pause_run() -> void:
	GameState.state = GameState.RunState.PAUSE
	get_tree().paused = true
	AudioDirector.set_audio_paused(true)
	if not is_instance_valid(pause_menu):
		pause_menu = PauseMenuScene.instantiate()
		pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		ui_layer.add_child(pause_menu)
		pause_menu.resume_requested.connect(_resume_run)
		pause_menu.settings_requested.connect(_show_settings)
		pause_menu.forge_requested.connect(_show_forge)
	pause_menu.visible = true

func _resume_run() -> void:
	get_tree().paused = false
	AudioDirector.set_audio_paused(false)
	GameState.state = GameState.RunState.PLAY
	_clear_pause()
	_clear_settings()

func _show_settings() -> void:
	state_before_settings = GameState.state
	if not is_instance_valid(settings_menu):
		settings_menu = SettingsMenuScene.instantiate()
		settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		ui_layer.add_child(settings_menu)
		settings_menu.closed.connect(_close_settings)
	if is_instance_valid(pause_menu):
		pause_menu.visible = false
	settings_menu.visible = true

func _close_settings() -> void:
	_clear_settings()
	if state_before_settings == GameState.RunState.PAUSE and is_instance_valid(pause_menu):
		pause_menu.visible = true

func _clear_pause() -> void:
	if is_instance_valid(pause_menu):
		pause_menu.visible = false

func _clear_settings() -> void:
	if is_instance_valid(settings_menu):
		settings_menu.visible = false

func _set_arena_visible(value: bool) -> void:
	arena.visible = value
	var arena_canvas := arena.get_node_or_null("CanvasLayer")
	if arena_canvas:
		arena_canvas.visible = value
