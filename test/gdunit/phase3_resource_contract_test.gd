extends GdUnitTestSuite

const WEAPONS := [
	preload("res://data/weapons/forgehammer.tres"),
	preload("res://data/weapons/slag_lance.tres"),
	preload("res://data/weapons/ember_maw.tres"),
	preload("res://data/weapons/meteor_volley.tres"),
	preload("res://data/weapons/railspike.tres"),
	preload("res://data/weapons/crucible_breath.tres"),
]
const SYNERGIES := [
	preload("res://data/synergies/detonating_brand.tres"),
	preload("res://data/synergies/arc_steel.tres"),
	preload("res://data/synergies/bulwark_orbit.tres"),
	preload("res://data/synergies/blast_furnace.tres"),
	preload("res://data/synergies/overclocked_bellows.tres"),
]
const EVOLUTIONS := [
	preload("res://data/evolutions/meteor_volley.tres"),
	preload("res://data/evolutions/railspike.tres"),
	preload("res://data/evolutions/crucible_breath.tres"),
]
const OBJECTIVES := [
	preload("res://data/objectives/ember_vein.tres"),
	preload("res://data/objectives/braziers.tres"),
	preload("res://data/objectives/elite_bounty.tres"),
	preload("res://data/objectives/anvil_defense.tres"),
]
const TEMPERINGS := [
	preload("res://data/temperings/hotter_steel.tres"),
	preload("res://data/temperings/twin_hammers.tres"),
	preload("res://data/temperings/bellows.tres"),
	preload("res://data/temperings/quenched_legs.tres"),
	preload("res://data/temperings/reforged_heart.tres"),
	preload("res://data/temperings/piercing_slag.tres"),
	preload("res://data/temperings/coiled_spring.tres"),
	preload("res://data/temperings/ember_leech.tres"),
	preload("res://data/temperings/nova_dash.tres"),
	preload("res://data/temperings/slow_burn.tres"),
	preload("res://data/temperings/killing_edge.tres"),
	preload("res://data/temperings/branding_iron.tres"),
	preload("res://data/temperings/chain_spark.tres"),
	preload("res://data/temperings/orbiting_anvil.tres"),
	preload("res://data/temperings/forgehammer_sharpen.tres"),
	preload("res://data/temperings/slag_lance_sharpen.tres"),
	preload("res://data/temperings/ember_maw_sharpen.tres"),
	preload("res://data/temperings/thorns.tres"),
	preload("res://data/temperings/magnet_coil.tres"),
	preload("res://data/temperings/second_wind.tres"),
]

func test_phase3_weapon_contracts() -> void:
	assert_int(WEAPONS.size()).is_equal(6)
	for weapon in WEAPONS:
		assert_that(weapon.id).is_not_null()
		assert_str(weapon.display_name).is_not_empty()
		assert_int(weapon.fire_rate_ticks).is_greater(0)

func test_phase3_synergy_and_evolution_contracts() -> void:
	assert_int(SYNERGIES.size()).is_equal(5)
	for synergy in SYNERGIES:
		assert_int(synergy.requirements.size()).is_greater(0)
	assert_int(EVOLUTIONS.size()).is_equal(3)
	for evolution in EVOLUTIONS:
		assert_that(evolution.evolved_weapon).is_not_null()
		assert_int(evolution.requirements.size()).is_greater(0)

func test_phase3_objective_contracts() -> void:
	var types := []
	for objective in OBJECTIVES:
		types.append(objective.objective_type)
	assert_bool(types.has("ember_vein")).is_true()
	assert_bool(types.has("braziers")).is_true()
	assert_bool(types.has("elite_bounty")).is_true()
	assert_bool(types.has("anvil_defense")).is_true()

func test_phase3_tempering_pool_contracts() -> void:
	assert_int(TEMPERINGS.size()).is_equal(20)
	var sharpen_count := 0
	var locked_count := 0
	for tempering in TEMPERINGS:
		if tempering.tags.has(&"sharpen"):
			sharpen_count += 1
		if not tempering.unlocked:
			locked_count += 1
	assert_int(sharpen_count).is_equal(3)
	assert_int(locked_count).is_equal(3)
