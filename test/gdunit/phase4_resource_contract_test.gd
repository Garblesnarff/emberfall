extends GdUnitTestSuite

const CHOIR := preload("res://data/enemies/choir.tres")
const AURUM := preload("res://data/enemies/aurum.tres")
const AURUM_REKINDLED := preload("res://data/enemies/aurum_rekindled.tres")

func test_phase4_boss_contracts() -> void:
	assert_bool(CHOIR.boss).is_true()
	assert_int(CHOIR.boss_body_count).is_equal(3)
	assert_bool(CHOIR.boss_patterns.has(&"sync_rotate")).is_true()
	assert_bool(AURUM.boss_phase2_patterns.has(&"sweep_beam")).is_true()
	assert_bool(AURUM_REKINDLED.victory_boss).is_true()
	assert_int(AURUM_REKINDLED.boss_reward_embers).is_equal(100)

func test_phase4_unlock_cost_contracts() -> void:
	assert_bool(MetaProgression.UNLOCK_COSTS.has(&"weapon_slag_lance")).is_true()
	assert_bool(MetaProgression.UNLOCK_COSTS.has(&"weapon_ember_maw")).is_true()
	assert_bool(MetaProgression.UNLOCK_COSTS.has(&"card_thorns")).is_true()
	assert_bool(MetaProgression.first_unlock_reachable_in_two_runs(175)).is_true()
