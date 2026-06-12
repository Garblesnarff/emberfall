extends Camera2D

@export var target_path: NodePath
@export var world_size := Config.WORLD_SIZE

var target: Node2D
var aim_world := Vector2.ZERO

func _ready() -> void:
	if target_path != NodePath():
		target = get_node(target_path)
	position_smoothing_enabled = false

func physics_tick() -> void:
	if not is_instance_valid(target):
		return
	var desired := target.global_position
	var aim_delta := aim_world - target.global_position
	if aim_delta.length_squared() > 0.01:
		desired += aim_delta.normalized() * Config.CAMERA_LOOKAHEAD
	var viewport_size := get_viewport_rect().size
	var half := viewport_size * 0.5 / zoom
	desired.x = clampf(desired.x, half.x, world_size.x - half.x)
	desired.y = clampf(desired.y, half.y, world_size.y - half.y)
	global_position = global_position.lerp(desired, Config.CAMERA_LERP)
