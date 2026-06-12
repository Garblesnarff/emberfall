extends Resource
class_name ArenaLayoutData

@export var world_size := Config.WORLD_SIZE
@export var pillars: Array[Vector3] = []
@export var lava_strips: Array[Rect2] = []
@export var central_anvil_position := Config.WORLD_SIZE * 0.5
@export var boundary_thickness := 32.0
