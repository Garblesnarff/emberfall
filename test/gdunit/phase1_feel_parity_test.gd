extends GdUnitTestSuite

const FeelParity := preload("res://data/feel_parity.tres")

func test_prototype_grid_and_shake_constants() -> void:
	assert_float(FeelParity.grid_cell_size).is_equal(80.0)
	assert_float(FeelParity.shake_decay).is_equal(0.85)

func test_prototype_dash_constants() -> void:
	assert_int(FeelParity.dash_duration_ticks).is_equal(9)
	assert_float(FeelParity.dash_speed_per_tick).is_equal(13.0)
	assert_int(FeelParity.dash_iframe_ticks).is_equal(14)

func test_prototype_combat_rhythm_constants() -> void:
	assert_int(FeelParity.fire_rate_ticks).is_equal(11)
	assert_float(FeelParity.projectile_speed).is_equal(9.5)
	assert_int(FeelParity.player_hurt_hitstop_ticks).is_equal(4)
	assert_int(FeelParity.boss_kill_hitstop_ticks).is_equal(8)
