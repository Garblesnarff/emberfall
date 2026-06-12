extends Node

const BulletManagerScript := preload("res://scripts/projectiles/bullet_manager.gd")
const SpatialGridScript := preload("res://scripts/systems/spatial_grid.gd")
const ArenaScene := preload("res://scenes/arena/arena.tscn")
const FeelParity := preload("res://data/feel_parity.tres")

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_feel_parity()
	_test_spatial_grid()
	_test_pool_integrity()
	await _test_determinism()
	if failures == 0:
		print("EMBERFALL Phase 1 tests: PASS")
	else:
		push_error("EMBERFALL Phase 1 tests: %d failure(s)" % failures)
	get_tree().quit(failures)

func _assert_true(value: bool, message: String) -> void:
	if value:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	_assert_true(actual == expected, "%s (expected %s, got %s)" % [message, str(expected), str(actual)])

func _assert_approx(actual: float, expected: float, tolerance: float, message: String) -> void:
	_assert_true(abs(actual - expected) <= tolerance, "%s (expected %.4f, got %.4f)" % [message, expected, actual])

func _test_feel_parity() -> void:
	_assert_approx(FeelParity.grid_cell_size, 80.0, 0.0, "prototype grid cell is 80")
	_assert_approx(FeelParity.shake_decay, 0.85, 0.0, "prototype shake decay is 0.85")
	_assert_eq(FeelParity.dash_duration_ticks, 9, "prototype dash lasts 9 ticks")
	_assert_approx(FeelParity.dash_speed_per_tick, 13.0, 0.0, "prototype dash speed is 13 units/tick")
	_assert_eq(FeelParity.dash_iframe_ticks, 14, "prototype dash grants 14 i-frame ticks")
	_assert_eq(FeelParity.fire_rate_ticks, 11, "prototype fire cadence is 11 ticks")
	_assert_approx(FeelParity.projectile_speed, 9.5, 0.0, "prototype projectile speed is 9.5 units/tick")
	_assert_eq(FeelParity.player_hurt_hitstop_ticks, 4, "prototype player hurt hitstop is 4 ticks")
	_assert_eq(FeelParity.boss_kill_hitstop_ticks, 8, "prototype boss hitstop is 8 ticks")

func _test_spatial_grid() -> void:
	var grid = SpatialGridScript.new()
	var a := Node2D.new()
	var b := Node2D.new()
	a.position = Vector2(10, 10)
	b.position = Vector2(170, 10)
	grid.rebuild([a, b])
	var near: Array = grid.nearby(Vector2(0, 0), 90)
	_assert_true(near.has(a), "spatial grid finds nearby item")
	_assert_true(not near.has(b), "spatial grid excludes distant item")
	_assert_eq(grid.cell_count(), 2, "spatial grid tracks occupied cells")
	a.free()
	b.free()

func _test_pool_integrity() -> void:
	var manager = BulletManagerScript.new()
	manager.capacity = 3
	get_tree().root.add_child(manager)
	for i in range(5):
		manager.spawn(Vector2(i, 0), Vector2.RIGHT, 1.0, 10)
	_assert_eq(manager.active_count, 3, "bullet pool refuses spawns above capacity")
	manager.reset()
	_assert_eq(manager.active_count, 0, "bullet pool reset clears active count")
	_assert_eq(manager.positions.size(), 0, "bullet pool reset clears position storage")
	manager.queue_free()

func _test_determinism() -> void:
	var a := await _run_arena_sample(0x1234, 5000)
	var b := await _run_arena_sample(0x1234, 5000)
	_assert_eq(a, b, "same seed scripted run is deterministic at tick 5000")

func _run_arena_sample(seed_value: int, ticks: int) -> Dictionary:
	Config.set_run_seed(seed_value)
	GameState.start_run(seed_value)
	var arena = ArenaScene.instantiate()
	get_tree().root.add_child(arena)
	for i in range(ticks):
		await get_tree().physics_frame
	var result := {
		"kills": GameState.kills,
		"score": GameState.score,
		"wave": GameState.wave,
		"combo": GameState.combo,
		"enemies": arena.enemies.size(),
		"player_bullets": arena.player_bullets.active_count,
		"enemy_bullets": arena.enemy_bullets.active_count,
		"player_hp": roundi(arena.player.hp),
	}
	arena.queue_free()
	await get_tree().process_frame
	return result
