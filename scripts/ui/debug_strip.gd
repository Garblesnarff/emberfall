extends Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_left = 16.0
	offset_top = 34.0
	offset_right = -16.0
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	visible = Config.fps_overlay_enabled
	if not visible:
		return
	text = "FPS %d  STATE %s  WAVE %d  STEAM %s" % [
		Engine.get_frames_per_second(),
		GameState.RunState.keys()[GameState.state],
		GameState.wave,
		"ON" if SteamManager.is_available() else "OFF",
	]
