extends GdUnitTestSuite

const CHOIR := preload("res://data/enemies/choir.tres")
const AURUM := preload("res://data/enemies/aurum.tres")
const AURUM_REKINDLED := preload("res://data/enemies/aurum_rekindled.tres")

func test_phase4_boss_contracts() -> void:
	assert_bool(CHOIR.boss).is_true()
	assert_int(CHOIR.boss_body_count).is_equal(3)
	assert_float(CHOIR.hp).is_equal(720.0)
	assert_bool(CHOIR.boss_patterns.has(&"mourn")).is_true()
	assert_bool(CHOIR.boss_patterns.has(&"vesper")).is_true()
	assert_bool(CHOIR.boss_patterns.has(&"harrow")).is_true()
	assert_float(AURUM.hp).is_equal(520.0)
	assert_bool(AURUM.boss_patterns.has(&"siphon")).is_true()
	assert_bool(AURUM.boss_patterns.has(&"tax")).is_true()
	assert_float(AURUM_REKINDLED.hp).is_equal(900.0)
	assert_bool(AURUM_REKINDLED.boss_patterns.has(&"geyser")).is_true()
	assert_bool(AURUM_REKINDLED.boss_patterns.has(&"barrage")).is_true()
	assert_bool(AURUM_REKINDLED.victory_boss).is_true()
	assert_int(AURUM_REKINDLED.boss_reward_embers).is_equal(100)

func test_phase4_unlock_cost_contracts() -> void:
	assert_bool(MetaProgression.UNLOCK_COSTS.has(&"weapon_slag_lance")).is_true()
	assert_bool(MetaProgression.UNLOCK_COSTS.has(&"weapon_ember_maw")).is_true()
	assert_bool(MetaProgression.UNLOCK_COSTS.has(&"card_thorns")).is_true()
	assert_bool(MetaProgression.first_unlock_reachable_in_two_runs(175)).is_true()
