extends Control

var player_pos := Vector2.ZERO
var world_size := Config.WORLD_SIZE
var enemies: Array = []
var boss_telegraph_pos := Vector2.INF
var objective_markers: Array = []

func set_world_state(p_player_pos: Vector2, p_enemies: Array, p_world_size: Vector2, p_boss_telegraph_pos := Vector2.INF, p_objective_markers: Array = []) -> void:
	player_pos = p_player_pos
	enemies = p_enemies
	world_size = p_world_size
	boss_telegraph_pos = p_boss_telegraph_pos
	objective_markers = p_objective_markers
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.017, 0.012, 0.72))
	draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.682, 0.259, 0.35), false, 1.0)
	_draw_point(player_pos, Color(1.0, 0.91, 0.77), 3.5)
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var col: Color = Color(1.0, 0.91, 0.77) if enemy.elite else enemy.color
		var radius := 2.8 if enemy.elite or enemy.data.boss else 1.8
		_draw_point(enemy.position, col, radius)
	if boss_telegraph_pos != Vector2.INF:
		_draw_point(boss_telegraph_pos, Color(1.0, 0.682, 0.259), 4.0)
	for marker in objective_markers:
		_draw_point(marker, Color(0.48, 0.88, 0.52), 3.2)

func _draw_point(world_pos: Vector2, color: Color, radius: float) -> void:
	var p := Vector2(world_pos.x / world_size.x * size.x, world_pos.y / world_size.y * size.y)
	draw_circle(p, radius, color)
