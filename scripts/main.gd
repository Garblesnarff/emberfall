extends Node

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameState.state == GameState.RunState.PLAY:
			GameState.state = GameState.RunState.PAUSE
			get_tree().paused = true
		elif GameState.state == GameState.RunState.PAUSE:
			get_tree().paused = false
			GameState.state = GameState.RunState.PLAY
