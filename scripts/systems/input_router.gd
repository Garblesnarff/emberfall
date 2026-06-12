extends Node
class_name InputRouter

const STICK_DEADZONE := 0.18
const CONTROLLER_RETICLE_DISTANCE := 120.0

var last_aim_vector := Vector2.RIGHT
var last_controller_aim_tick := -999999

func movement_vector() -> Vector2:
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return v.normalized() if v.length_squared() > 1.0 else v

func aim_world_position(owner_node: CanvasItem, player_pos: Vector2, tick: int) -> Vector2:
	var stick := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if stick.length() >= STICK_DEADZONE:
		last_aim_vector = stick.normalized()
		last_controller_aim_tick = tick
		return player_pos + last_aim_vector * CONTROLLER_RETICLE_DISTANCE
	var mouse_world := owner_node.get_global_mouse_position()
	var mouse_dir := mouse_world - player_pos
	if mouse_dir.length_squared() > 0.01:
		last_aim_vector = mouse_dir.normalized()
	return mouse_world
