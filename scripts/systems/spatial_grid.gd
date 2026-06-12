extends RefCounted
class_name SpatialGrid

var cell_size := Config.GRID_CELL_SIZE
var cells: Dictionary = {}
var _nearby: Array = []

func _init(p_cell_size := Config.GRID_CELL_SIZE) -> void:
	cell_size = p_cell_size

func clear() -> void:
	cells.clear()

func rebuild(items: Array) -> void:
	cells.clear()
	for item in items:
		add(item)

func add(item: Variant) -> void:
	var pos: Vector2 = item.position
	var key := _cell_key(pos)
	if not cells.has(key):
		cells[key] = []
	cells[key].append(item)

func nearby(pos: Vector2, radius: float) -> Array:
	_nearby.clear()
	var x0 := floori((pos.x - radius) / cell_size)
	var x1 := floori((pos.x + radius) / cell_size)
	var y0 := floori((pos.y - radius) / cell_size)
	var y1 := floori((pos.y + radius) / cell_size)
	for cx in range(x0, x1 + 1):
		for cy in range(y0, y1 + 1):
			var key := Vector2i(cx, cy)
			if cells.has(key):
				_nearby.append_array(cells[key])
	return _nearby

func cell_count() -> int:
	return cells.size()

func _cell_key(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / cell_size), floori(pos.y / cell_size))
