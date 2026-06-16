extends Node

const ForgeMenuScene := preload("res://scenes/ui/forge_menu.tscn")
const RecapScene := preload("res://scenes/ui/recap.tscn")

@onready var arena: Node = %Arena

var forge_menu: Control
var recap: Control
var ui_layer: CanvasLayer

func _ready() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 50
	add_child(ui_layer)
	EventBus.run_ended.connect(_on_run_ended)
	_set_arena_visible(false)
	_show_forge()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameState.state == GameState.RunState.PLAY:
			GameState.state = GameState.RunState.PAUSE
			get_tree().paused = true
		elif GameState.state == GameState.RunState.PAUSE:
			get_tree().paused = false
			GameState.state = GameState.RunState.PLAY

func _show_forge() -> void:
	get_tree().paused = false
	GameState.state = GameState.RunState.MENU
	_set_arena_visible(false)
	_clear_recap()
	if not is_instance_valid(forge_menu):
		forge_menu = ForgeMenuScene.instantiate()
		ui_layer.add_child(forge_menu)
		forge_menu.start_run_requested.connect(_start_run)
	forge_menu.visible = true
	if forge_menu.has_method("refresh"):
		forge_menu.refresh()

func _start_run() -> void:
	get_tree().paused = false
	_clear_recap()
	if is_instance_valid(forge_menu):
		forge_menu.visible = false
	_set_arena_visible(true)
	var run_index := int(SaveManager.data.stats.runs) + 1
	arena.begin_run(0xE4BEF411 + run_index)

func _on_run_ended(_victory: bool, _stats: Dictionary) -> void:
	_show_recap(GameState.last_recap)

func _show_recap(stats: Dictionary) -> void:
	_set_arena_visible(false)
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
	if arena.has_method("enter_endless"):
		arena.enter_endless()

func _clear_recap() -> void:
	if is_instance_valid(recap):
		recap.visible = false

func _set_arena_visible(value: bool) -> void:
	arena.visible = value
	var arena_canvas := arena.get_node_or_null("CanvasLayer")
	if arena_canvas:
		arena_canvas.visible = value
