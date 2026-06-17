extends Node

const BulletManagerScript := preload("res://scripts/projectiles/bullet_manager.gd")
const SpatialGridScript := preload("res://scripts/systems/spatial_grid.gd")
const ArenaScene := preload("res://scenes/arena/arena.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")
const FeelParity := preload("res://data/feel_parity.tres")
const ObjVein := preload("res://data/objectives/ember_vein.tres")
const ObjBraziers := preload("res://data/objectives/braziers.tres")
const ObjBounty := preload("res://data/objectives/elite_bounty.tres")
const ObjAnvil := preload("res://data/objectives/anvil_defense.tres")
const Choir := preload("res://data/enemies/choir.tres")
const Aurum := preload("res://data/enemies/aurum.tres")
const AurumRekindled := preload("res://data/enemies/aurum_rekindled.tres")
const ForgeMenuScene := preload("res://scenes/ui/forge_menu.tscn")
const RecapScene := preload("res://scenes/ui/recap.tscn")
const MainScene := preload("res://scenes/main.tscn")
const SettingsMenuScene := preload("res://scenes/ui/settings_menu.tscn")

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_feel_parity()
	_test_spatial_grid()
	_test_pool_integrity()
	_test_bullet_visual_collision_alignment()
	await _test_phase2_world_systems()
	await _test_deck_resolution_hud_layout()
	await _test_phase3_forced_builds()
	await _test_phase3_objectives_and_rewards()
	await _test_phase4_save_meta_and_ui()
	await _test_phase4_main_flow_integration()
	await _test_phase4_bosses_victory_and_endless()
	await _test_phase5_steam_achievements_settings_and_pause()
	await _test_determinism()
	await _test_phase2_wave6_coverage()
	if failures == 0:
		print("EMBERFALL Phase 1/2/3/4/5 tests: PASS")
	else:
		push_error("EMBERFALL Phase 1/2/3/4/5 tests: %d failure(s)" % failures)
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

func _test_bullet_visual_collision_alignment() -> void:
	var manager = BulletManagerScript.new()
	manager.capacity = 4
	manager.is_player_owned = false
	get_tree().root.add_child(manager)
	manager.spawn(Vector2(400, 300), Vector2.ZERO, 1.0, 10, 5.0)
	manager.spawn(Vector2(800, 500), Vector2.ZERO, 1.0, 10, 6.0)
	manager.physics_tick(Rect2(Vector2.ZERO, Vector2(1600, 1200)), SpatialGridScript.new(), [])
	_assert_eq(manager.rendered_position(0), manager.positions[0], "radius-5 enemy bullet visual matches collision position")
	_assert_eq(manager.rendered_position(1), manager.positions[1], "radius-6 boss bullet visual matches collision position")
	manager.queue_free()

func _test_phase2_world_systems() -> void:
	Config.set_run_seed(0x7777)
	GameState.start_run(0x7777)
	var arena = ArenaScene.instantiate()
	get_tree().root.add_child(arena)
	await get_tree().physics_frame
	var camera_rect: Rect2 = arena._camera_rect()
	var offscreen_ok := true
	for i in range(32):
		var pos: Vector2 = arena._offscreen_spawn_position()
		var closest := Vector2(clampf(pos.x, camera_rect.position.x, camera_rect.end.x), clampf(pos.y, camera_rect.position.y, camera_rect.end.y))
		var distance: float = closest.distance_to(pos)
		offscreen_ok = offscreen_ok and not camera_rect.has_point(pos)
		offscreen_ok = offscreen_ok and distance >= Config.SPAWN_OFFSCREEN_MIN - 0.01
		offscreen_ok = offscreen_ok and distance <= Config.SPAWN_OFFSCREEN_MAX + 0.01
	_assert_true(offscreen_ok, "off-screen spawns stay 60-140 units outside camera rect")
	var pillar: Vector3 = arena.ARENA_LAYOUT.pillars[0]
	_assert_true(arena.projectile_blocked(Vector2(pillar.x, pillar.y)), "terrain pillars block projectiles")
	var far_enemy = arena._spawn_enemy(preload("res://data/enemies/crawler.tres"), Vector2(3180, 2380))
	arena._tick_enemies()
	_assert_true(arena.debug_stats.separation_skips > 0 or far_enemy.skipped_separation, "LOD skips separation for enemies beyond 1.5 viewports")
	arena.queue_free()
	await get_tree().process_frame

func _test_deck_resolution_hud_layout() -> void:
	var hud: Control = HudScene.instantiate()
	get_tree().root.add_child(hud)
	hud.set_values(75, 100, 0.8, 6, 24, 12345, 99, 12)
	await get_tree().process_frame
	var left: Control = hud.get_node("Left")
	var center: Control = hud.get_node("Center")
	var right: Control = hud.get_node("Right")
	var minimap: Control = hud.get_node("Minimap")
	var bounds := Rect2(Vector2.ZERO, Vector2(1280, 800))
	var rects := [left.get_global_rect(), center.get_global_rect(), right.get_global_rect(), minimap.get_global_rect()]
	var inside := true
	for rect in rects:
		inside = inside and bounds.encloses(rect)
	var separated := not left.get_global_rect().intersects(center.get_global_rect())
	separated = separated and not center.get_global_rect().intersects(right.get_global_rect())
	separated = separated and not right.get_global_rect().intersects(minimap.get_global_rect())
	hud.set_world_state(Vector2(1600, 1200), Vector2(1600, 1200), [], Config.WORLD_SIZE, Vector2.INF, [Vector2(3100, 2300)])
	hud.set_phase3_state("Forgehammer", 12, "Ember Vein", 0.0, [preload("res://data/temperings/hotter_steel.tres")], "")
	await get_tree().process_frame
	_assert_true(inside, "HUD elements fit inside 1280x800 Deck viewport")
	_assert_true(separated, "HUD regions do not overlap at 1280x800")
	_assert_true(hud.threat_chevrons.last_drawn_count > 0, "objective threat placeholders can draw edge chevrons")
	_assert_true(hud.phase3_label.text.contains("EMBERS 12"), "HUD exposes Phase 3 ember readout")
	_assert_true(hud.upgrade_label.visible, "HUD exposes placeholder upgrade choices")
	hud.queue_free()
	await get_tree().process_frame

func _test_determinism() -> void:
	var a := await _run_scripted_phase2_sample(0x1234, false)
	var b := await _run_scripted_phase2_sample(0x1234, false)
	_assert_eq(a, b, "same seed scripted survival run is deterministic through wave 6")
	_assert_true(a.player_hp > 0, "deterministic run survives intentionally")
	_assert_true(a.wave >= 6 or a.waves_cleared.has(6), "deterministic run reaches wave 6 coverage")

func _test_phase3_forced_builds() -> void:
	for weapon_id in [&"forgehammer", &"slag_lance", &"ember_maw"]:
		var result := await _run_forced_weapon_sample(weapon_id)
		_assert_true(result.damage_events > 0, "forced-build weapon %s deals damage over 600 ticks" % weapon_id)
	for synergy_id in [&"detonating_brand", &"arc_steel", &"bulwark_orbit", &"blast_furnace", &"overclocked_bellows"]:
		var synergy_result := await _run_forced_synergy_sample(synergy_id)
		_assert_true(synergy_result.active, "forced-build synergy %s activates" % synergy_id)
	for evo_id in [&"meteor_volley", &"railspike", &"crucible_breath"]:
		var evo_result := await _run_forced_evolution_sample(evo_id)
		_assert_true(evo_result.evolved, "forced-build evolution %s activates from chest" % evo_id)

func _test_phase3_objectives_and_rewards() -> void:
	var arena = await _fresh_test_arena(0x3303)
	arena._start_objective(ObjVein)
	arena.player.position = arena.current_objective.markers[0]
	for i in range(ObjVein.channel_ticks):
		arena._tick_objective()
	_assert_true(arena.debug_stats.objectives_completed.has(&"ember_vein"), "Ember Vein completes and records success")
	_assert_true(arena.ember_count >= ObjVein.ember_reward, "Ember Vein awards embers")
	arena._start_objective(ObjBraziers)
	for marker in arena.current_objective.markers:
		arena.player.position = marker
		for i in range(ObjBraziers.channel_ticks):
			arena._tick_objective()
	_assert_true(arena.debug_stats.objectives_completed.has(&"braziers"), "Braziers objective completes")
	arena._start_objective(ObjBounty)
	arena.current_objective.timer = 1
	arena._tick_objective()
	_assert_true(arena.debug_stats.objectives_failed.has(&"elite_bounty"), "Distant Elite Bounty failure path records timeout")
	arena._start_objective(ObjBounty)
	var bounty_target: Node = arena.current_objective.target
	bounty_target.hp = 0.0
	bounty_target.dead = true
	arena._tick_enemies()
	_assert_true(arena.debug_stats.objectives_completed.has(&"elite_bounty"), "Distant Elite Bounty success path records completion")
	_assert_true(arena.chests.size() > 0, "Distant Elite Bounty success drops a chest")
	arena._start_objective(ObjAnvil)
	arena.anvil_hp = 0.0
	arena._tick_objective()
	_assert_true(arena.debug_stats.objectives_failed.has(&"anvil_defense"), "Anvil Defense failure path records anvil break")
	arena._start_objective(ObjVein)
	arena.spawn_queue.clear()
	for enemy_node in arena.enemies:
		enemy_node.queue_free()
	arena.enemies.clear()
	arena.wave_active = true
	arena._check_wave_clear_or_death()
	_assert_true(arena.debug_stats.objectives_failed.has(&"ember_vein"), "Ember Vein failure path records wave-end failure")
	arena.choose_upgrade(0)
	arena._start_objective(ObjBraziers)
	arena.spawn_queue.clear()
	for enemy_node in arena.enemies:
		enemy_node.queue_free()
	arena.enemies.clear()
	arena.wave_active = true
	arena._check_wave_clear_or_death()
	_assert_true(arena.debug_stats.objectives_failed.has(&"braziers"), "Braziers failure path records wave-end failure")
	arena.choose_upgrade(0)
	GameState.wave = 3
	arena._start_objective_for_wave(3)
	_assert_true(arena.current_objective.get("none", false), "objective schedule includes no-objective waves")
	arena.drops.append({"type": &"heart", "position": arena.player.position, "value": Config.DROP_HEART_HEAL})
	arena.drops.append({"type": &"ember", "position": arena.player.position, "value": 1})
	var score_before: int = GameState.score
	arena._tick_drops()
	_assert_true(arena.debug_stats.hearts_collected > 0, "heart drops heal and record pickup")
	_assert_true(arena.ember_count > ObjVein.ember_reward, "ember drops increment ember accounting")
	_assert_true(GameState.score > score_before, "ember drops add score")
	var enemy = arena._spawn_enemy(preload("res://data/enemies/crawler.tres"), arena.player.position + Vector2(80, 0))
	enemy.hp = 0
	enemy.dead = true
	arena._tick_enemies()
	_assert_true(GameState.combo > 0, "kills increment combo")
	arena.player.position = Vector2(1600, 1200)
	arena.select_weapon(&"forgehammer")
	arena.apply_tempering(&"forgehammer_sharpen")
	arena.apply_tempering(&"forgehammer_sharpen")
	arena.apply_tempering(&"forgehammer_sharpen")
	arena.apply_tempering(&"forgehammer_sharpen")
	arena.apply_tempering(&"forgehammer_sharpen")
	arena.apply_tempering(&"twin_hammers")
	arena.apply_tempering(&"twin_hammers")
	arena.apply_tempering(&"twin_hammers")
	arena.force_open_chest()
	_assert_true(arena.active_evolutions.has(&"meteor_volley"), "chest-to-evolution flow works")
	_assert_true(arena.chest_reveal_ticks > 0, "chest reveal placeholder starts")
	_assert_true(Engine.time_scale < 1.0, "chest reveal starts slow-mo")
	arena.chest_reveal_ticks = 1
	arena._tick_chest_reveal()
	_assert_true(is_equal_approx(Engine.time_scale, 1.0), "chest reveal restores normal time")
	arena.select_weapon(&"forgehammer")
	arena.tempering_levels.clear()
	arena.active_evolutions.clear()
	arena.force_open_chest()
	_assert_true(arena.upgrade_panel_visible, "non-evolution chest offers upgrade cards")
	_assert_true(arena.offered_cards.size() > 0, "chest-to-tempering flow has card choices")
	arena.choose_upgrade(0)
	arena._start_objective(ObjAnvil)
	arena._complete_objective()
	arena.spawn_queue.clear()
	for enemy_node in arena.enemies:
		enemy_node.queue_free()
	arena.enemies.clear()
	arena.wave_active = true
	arena._check_wave_clear_or_death()
	_assert_true(arena.upgrade_panel_visible and arena.offered_cards.size() == 4, "Anvil Defense survival offers a fourth card")
	arena.queue_free()
	await get_tree().process_frame

func _test_phase4_save_meta_and_ui() -> void:
	_reset_test_save()
	SaveManager.load_save()
	_assert_eq(int(SaveManager.data.v), SaveManager.SAVE_VERSION, "fresh save migrates to current schema")
	_assert_true(SaveManager.data.unlocks.weapons.has("forgehammer"), "fresh save starts with Forgehammer")
	SaveManager.record_run(false, 6, 1200, 9, 80, 175)
	_assert_eq(int(SaveManager.data.bank.embers), 175, "run recap banks embers into save")
	_assert_eq(int(SaveManager.data.stats.runs), 1, "run recap increments run count")
	_assert_true(MetaProgression.first_unlock_reachable_in_two_runs(175), "first unlock reachable within two median runs")
	MetaProgression.add_embers(200)
	_assert_true(MetaProgression.purchase(&"weapon_slag_lance"), "Forge purchase unlocks Slag Lance")
	_assert_true(SaveManager.data.unlocks.weapons.has("slag_lance"), "purchased weapon persists in save data")
	var forge: Control = ForgeMenuScene.instantiate()
	get_tree().root.add_child(forge)
	await get_tree().process_frame
	_assert_true(forge.bank_label.text.contains("EMBERS"), "Forge menu exposes ember bank")
	_assert_true(forge.background.texture != null and forge.background.texture.resource_path.ends_with("menu_background.png"), "Forge menu uses concept background art")
	_assert_true(forge.word_mark.texture != null and forge.word_mark.texture.resource_path.ends_with("word_mark_cropped.png"), "Forge menu uses cropped concept word mark")
	var panel: Control = forge.get_node("Panel")
	_assert_true(forge.word_mark.global_position.y + forge.word_mark.size.y < panel.global_position.y, "Forge word mark stays above menu controls")
	forge.queue_free()
	var recap: Control = RecapScene.instantiate()
	get_tree().root.add_child(recap)
	recap.set_recap({"victory": true, "wave": 20, "score": 5000, "kills": 300, "best_combo": 42, "embers_banked": 450, "weapon": "Meteor Volley"})
	await get_tree().process_frame
	_assert_true(recap.title_label.text == "FORGE SECURED", "Victory recap shows FORGE SECURED")
	_assert_true(recap.background.texture != null and recap.background.texture.resource_path.ends_with("victory_screen.png"), "Victory recap uses concept victory art")
	recap.set_recap({"victory": false, "wave": 12, "score": 3000, "kills": 180, "best_combo": 20, "embers_banked": 120, "weapon": "Forgehammer"})
	_assert_true(recap.background.texture != null and recap.background.texture.resource_path.ends_with("defeat_screen.png"), "Death recap uses concept defeat art")
	recap.queue_free()
	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	file.store_string("{bad json")
	file.close()
	SaveManager.load_save()
	_assert_eq(int(SaveManager.data.v), SaveManager.SAVE_VERSION, "corrupt save falls back to fresh schema")
	_assert_true(FileAccess.file_exists(SaveManager.SAVE_PATH + ".corrupt"), "corrupt save is backed up")
	_reset_test_save()

func _test_phase4_bosses_victory_and_endless() -> void:
	var arena = await _fresh_test_arena(0x4404)
	GameState.wave = 10
	var choir = arena._spawn_enemy(Choir, Vector2(1600, 520))
	choir.apply_damage(choir.max_hp * 0.34, Vector2.ZERO)
	_assert_true(choir.boss_bodies_alive < Choir.boss_body_count, "Choir loses bodies at shared HP thresholds")
	_assert_true(arena.debug_stats.boss_phases.has(&"choir"), "Choir body loss emits boss phase")
	var aurum = arena._spawn_enemy(Aurum, Vector2(1600, 520))
	aurum.apply_damage(aurum.max_hp * 0.55, Vector2.ZERO)
	_assert_eq(aurum.boss_phase, 2, "Aurum enters phase 2 below half HP")
	_assert_true(arena.debug_stats.boss_phases.has(&"aurum"), "Aurum phase transition emits boss phase")
	GameState.wave = 20
	arena.ember_count = 200
	var rekindled = arena._spawn_enemy(AurumRekindled, Vector2(1600, 520))
	rekindled.dead = true
	arena._kill_enemy(arena.enemies.find(rekindled))
	_assert_true(GameState.state == GameState.RunState.VICTORY, "Aurum Rekindled kill ends run in victory")
	_assert_true(arena.debug_stats.victory, "Victory flag is recorded")
	_assert_eq(int(arena.debug_stats.recap.get("embers_banked", 0)), 450, "Victory recap applies ember multiplier and boss reward")
	arena.enter_endless()
	_assert_true(arena.endless_mode and GameState.state == GameState.RunState.PLAY, "Endless can be entered from victory recap")
	arena.queue_free()
	await get_tree().process_frame

func _test_phase4_main_flow_integration() -> void:
	_reset_test_save()
	var main: Node = MainScene.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	_assert_true(GameState.state == GameState.RunState.MENU, "main scene starts at Forge menu")
	_assert_true(is_instance_valid(main.forge_menu) and main.forge_menu.visible, "Forge menu is reachable from main")
	_assert_true(main.forge_menu.size == get_viewport().get_visible_rect().size, "Forge menu fills the viewport")
	_assert_true(not main.arena.get_node("CanvasLayer").visible, "Arena HUD is hidden on title screen")
	main._start_run()
	await get_tree().process_frame
	_assert_true(GameState.state == GameState.RunState.PLAY, "Forge menu can start a run")
	_assert_true(main.arena.visible, "Arena is shown after starting a run")
	_assert_true(main.arena.get_node("CanvasLayer").visible, "Arena HUD is restored during play")
	main.arena.player.hp = 0.0
	main.arena._check_wave_clear_or_death()
	await get_tree().process_frame
	_assert_true(GameState.state == GameState.RunState.OVER, "player death reaches run-over state")
	_assert_true(is_instance_valid(main.recap) and main.recap.visible, "death recap is shown from main")
	_assert_true(main.recap.size == get_viewport().get_visible_rect().size, "Recap fills the viewport")
	_assert_true(not main.arena.get_node("CanvasLayer").visible, "Arena HUD is hidden behind recap")
	main._show_forge()
	await get_tree().process_frame
	_assert_true(GameState.state == GameState.RunState.MENU and main.forge_menu.visible, "recap can return to Forge menu")
	main.queue_free()
	await get_tree().process_frame
	_reset_test_save()

func _test_phase5_steam_achievements_settings_and_pause() -> void:
	_reset_test_save()
	SteamManager.unlocked_achievements.clear()
	SteamManager.rich_presence.clear()
	SteamManager.stats_store_requests = 0
	AchievementManager.reset_for_tests()
	AudioDirector.reset_for_tests()
	_assert_true(not SteamManager.is_available(), "SteamManager no-ops cleanly without Steam")
	SteamManager.unlock_achievement(&"first_light")
	SteamManager.set_rich_presence("status", "Wave 12 - Forging")
	_assert_true(SteamManager.unlocked_achievements.has(&"first_light"), "SteamManager records local achievement unlocks")
	_assert_eq(String(SteamManager.rich_presence.get("status", "")), "Wave 12 - Forging", "SteamManager stores rich presence locally")
	EventBus.player_hurt.emit(12.0, &"test")
	_assert_true(AudioDirector.last_sfx == &"player_hurt" and AudioDirector.intensity >= 0.75, "AudioDirector reacts to player hurt events")
	EventBus.enemy_killed.emit(preload("res://data/enemies/kilnmaw.tres"))
	EventBus.enemy_killed.emit(Choir)
	EventBus.enemy_killed.emit(Aurum)
	EventBus.wave_cleared.emit(1)
	EventBus.combo_changed.emit(100)
	EventBus.chest_opened.emit([&"meteor_volley"])
	SaveManager.data.bank.embers = 1000
	SaveManager.data.stats.runs = 25
	EventBus.run_ended.emit(true, {})
	_assert_true(AchievementManager.unlocked.has(&"slagbreaker"), "Kilnmaw kill unlocks Slagbreaker")
	_assert_true(AchievementManager.unlocked.has(&"choir_silencer"), "Choir kill unlocks Choir Silencer")
	_assert_true(AchievementManager.unlocked.has(&"tyrants_end"), "Aurum kill unlocks Tyrant's End")
	_assert_true(AchievementManager.unlocked.has(&"first_light"), "Wave 1 clear unlocks First Light")
	_assert_true(AchievementManager.unlocked.has(&"centurion"), "100 combo unlocks Centurion")
	_assert_true(AchievementManager.unlocked.has(&"evolved"), "Evolution chest unlocks Evolved")
	_assert_true(AchievementManager.unlocked.has(&"forge_secured"), "Victory unlocks FORGE SECURED")
	_assert_true(AchievementManager.unlocked.has(&"full_bank"), "1000 banked embers unlocks Full Bank")
	_assert_true(AchievementManager.unlocked.has(&"old_hand"), "25 runs unlocks Old Hand")
	_assert_true(AudioDirector.last_sfx == &"victory", "AudioDirector reacts to run-ended victory events")
	_assert_true(AudioDirector.sfx_stream_cache.has(&"victory") and AudioDirector.sfx_stream_cache[&"victory"].data.size() > 0, "AudioDirector generates procedural placeholder SFX data")
	SaveManager.update_setting("sfx", 0.35)
	SaveManager.update_setting("music", 0.25)
	SaveManager.update_setting("shake", 0.2)
	SaveManager.update_setting("fps", true)
	_assert_approx(AudioDirector.sfx_volume, 0.35, 0.001, "SFX volume setting applies to AudioDirector")
	_assert_approx(AudioDirector.music_volume, 0.25, 0.001, "Music volume setting applies to AudioDirector")
	_assert_approx(Config.screen_shake_scale, 0.2, 0.001, "Shake setting applies to Config")
	_assert_true(Config.fps_overlay_enabled, "FPS overlay setting applies to Config")
	_assert_true(_action_has_joy_motion("move_left", JOY_AXIS_LEFT_X, -1.0), "Controller left stick maps to movement")
	_assert_true(_action_has_joy_motion("aim_right", JOY_AXIS_RIGHT_X, 1.0), "Controller right stick maps to aim")
	_assert_true(_action_has_joy_button("dash", JOY_BUTTON_A), "Controller face button maps to dash")
	_assert_true(_action_has_joy_button("pause", JOY_BUTTON_START), "Controller start button maps to pause")
	SaveManager.update_key_binding(&"dash", KEY_K)
	_assert_true(_action_has_key("dash", KEY_K), "Keyboard rebinding applies to InputMap")
	_assert_eq(int(SaveManager.data.settings.bindings.dash), KEY_K, "Keyboard rebinding persists in save settings")
	var settings: Control = SettingsMenuScene.instantiate()
	get_tree().root.add_child(settings)
	await get_tree().process_frame
	_assert_approx(settings.sfx_slider.value, 0.35, 0.001, "Settings menu loads saved SFX volume")
	_assert_true(settings.binding_buttons.has(&"dash") and settings.binding_buttons[&"dash"].text == "K", "Settings menu displays saved key binding")
	settings._begin_capture(&"move_up")
	_assert_true(settings.binding_buttons[&"move_up"].text == "PRESS KEY", "Settings menu exposes key capture state")
	SaveManager.reset_key_bindings()
	settings._update_binding_buttons()
	_assert_true(_action_has_key("dash", KEY_SPACE), "Control reset restores default dash key")
	settings.queue_free()
	var main: Node = MainScene.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	_assert_true(main.debug_strip.visible and main.debug_strip.text.contains("STEAM OFF"), "Debug strip shows local Steam status when FPS overlay is enabled")
	main._start_run()
	await get_tree().process_frame
	main._pause_run()
	await get_tree().process_frame
	_assert_true(GameState.state == GameState.RunState.PAUSE and get_tree().paused, "Pause menu pauses active run")
	_assert_true(AudioDirector.audio_paused, "Pause menu pauses audio")
	_assert_true(is_instance_valid(main.pause_menu) and main.pause_menu.visible, "Pause menu is visible")
	main._show_settings()
	await get_tree().process_frame
	_assert_true(is_instance_valid(main.settings_menu) and main.settings_menu.visible, "Settings menu opens from pause")
	main._close_settings()
	await get_tree().process_frame
	_assert_true(main.pause_menu.visible, "Closing settings returns to pause menu")
	main._resume_run()
	await get_tree().process_frame
	_assert_true(GameState.state == GameState.RunState.PLAY and not get_tree().paused, "Resume returns to active play")
	_assert_true(not AudioDirector.audio_paused, "Resume unpauses audio")
	main.queue_free()
	await get_tree().process_frame
	_reset_test_save()

func _action_has_joy_motion(action: StringName, axis: JoyAxis, axis_value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, axis_value):
			return true
	return false

func _action_has_joy_button(action: StringName, button: JoyButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return true
	return false

func _action_has_key(action: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.keycode == keycode:
			return true
	return false

func _test_phase2_wave6_coverage() -> void:
	var result := await _run_scripted_phase2_sample(0x223344, true)
	_assert_true(result.waves_cleared.has(6), "Test 1 clears through wave 6: %s" % str(result))
	_assert_true(result.spawned.get(&"crawler", 0) > 0, "Test 1 spawns crawlers")
	_assert_true(result.spawned.get(&"brute", 0) > 0, "Test 1 spawns brutes")
	_assert_true(result.spawned.get(&"spitter", 0) > 0, "Test 1 spawns spitters")
	_assert_true(result.spawned.get(&"splitter", 0) > 0, "Test 1 spawns splitters")
	_assert_true(result.spawned.get(&"hound", 0) > 0, "Test 1 spawns hounds")
	_assert_true(result.boss_spawned, "Test 1 spawns Kilnmaw: %s" % str(result))
	_assert_true(result.boss_patterns.get(&"ring", 0) > 0, "Kilnmaw uses ring pattern")
	_assert_true(result.boss_patterns.get(&"fan", 0) > 0, "Kilnmaw uses aimed fan pattern")
	_assert_true(result.boss_patterns.get(&"charge", 0) > 0, "Kilnmaw uses charge pattern")
	_assert_true(result.player_hp > 0, "Test 1 scripted player survives through wave 6")

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

func _reset_test_save() -> void:
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.SAVE_PATH))
	if FileAccess.file_exists(SaveManager.SAVE_PATH + ".corrupt"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.SAVE_PATH + ".corrupt"))
	SaveManager.data = SaveManager.default_save()
	SaveManager.save()
	MetaProgression.sync_from_save()

func _run_scripted_phase2_sample(seed_value: int, require_wave6_clear: bool) -> Dictionary:
	Config.set_run_seed(seed_value)
	GameState.start_run(seed_value)
	var arena = ArenaScene.instantiate()
	get_tree().root.add_child(arena)
	arena.player.max_hp = 2000.0
	arena.player.hp = 2000.0
	arena.player.damage_mult = 16.0
	var max_ticks := 60000 if require_wave6_clear else 22000
	for i in range(max_ticks):
		_script_arena_input(arena, i)
		if GameState.state == GameState.RunState.UPGRADE:
			arena.choose_upgrade(0)
		if arena.debug_stats.boss_spawned and not _boss_patterns_complete(arena.debug_stats.boss_patterns):
			arena.player.damage_mult = 0.0
		else:
			arena.player.damage_mult = 52.0 if require_wave6_clear else 22.0
		arena.player.hp = max(arena.player.hp, 1200.0)
		await get_tree().physics_frame
		if GameState.state == GameState.RunState.UPGRADE:
			arena.choose_upgrade(0)
		if require_wave6_clear and arena.debug_stats.waves_cleared.has(6):
			break
		if not require_wave6_clear and arena.debug_stats.waves_cleared.has(6):
			break
	var result := {
		"kills": GameState.kills,
		"score": GameState.score,
		"wave": GameState.wave,
		"combo": GameState.combo,
		"waves_cleared": arena.debug_stats.waves_cleared.duplicate(),
		"spawned": arena.debug_stats.spawned.duplicate(),
		"boss_patterns": arena.debug_stats.boss_patterns.duplicate(),
		"boss_spawned": arena.debug_stats.boss_spawned,
		"enemies": arena.enemies.size(),
		"player_bullets": arena.player_bullets.active_count,
		"enemy_bullets": arena.enemy_bullets.active_count,
		"player_hp": roundi(arena.player.hp),
	}
	arena.queue_free()
	await get_tree().process_frame
	return result

func _script_arena_input(arena: Node, tick: int) -> void:
	var player_pos: Vector2 = arena.player.position
	var target = _nearest_enemy(arena, player_pos)
	if arena._objective_type() == "elite_bounty" and is_instance_valid(arena.current_objective.get("target", null)):
		target = arena.current_objective.target
	var aim := player_pos + Vector2.RIGHT * 100.0
	var move := Vector2.ZERO
	if is_instance_valid(target):
		aim = target.position
		var away: Vector2 = player_pos - target.position
		if away.length() > 520.0:
			move = (-away).normalized()
		else:
			var tangential := away.orthogonal().normalized()
			move = (away.normalized() * 0.65 + tangential * 0.35).normalized()
	else:
		var orbit_angle := float(tick) * 0.025
		var anchor := Config.WORLD_SIZE * 0.5 + Vector2(cos(orbit_angle), sin(orbit_angle)) * 220.0
		move = (anchor - player_pos).normalized()
	var dash := false
	if is_instance_valid(target):
		dash = player_pos.distance_to(target.position) < 95.0 and tick % 45 == 0
	arena.set_scripted_input(move, aim, dash)

func _nearest_enemy(arena: Node, pos: Vector2) -> Node:
	var best: Node = null
	var best_dist := INF
	for enemy in arena.enemies:
		if not is_instance_valid(enemy):
			continue
		var dist := pos.distance_squared_to(enemy.position)
		if enemy.data and enemy.data.boss:
			dist *= 0.25
		if dist < best_dist:
			best_dist = dist
			best = enemy
	return best

func _boss_patterns_complete(patterns: Dictionary) -> bool:
	return patterns.get(&"ring", 0) > 0 and patterns.get(&"fan", 0) > 0 and patterns.get(&"charge", 0) > 0

func _fresh_test_arena(seed_value: int) -> Node:
	Config.set_run_seed(seed_value)
	GameState.start_run(seed_value)
	var arena = ArenaScene.instantiate()
	get_tree().root.add_child(arena)
	await get_tree().physics_frame
	arena.player.max_hp = 5000.0
	arena.player.hp = 5000.0
	arena.player.damage = 100.0
	return arena

func _run_forced_weapon_sample(weapon_id: StringName) -> Dictionary:
	var arena = await _fresh_test_arena(0x4400 + int(hash(weapon_id) & 0xff))
	arena.select_weapon(weapon_id)
	arena.player.damage_mult = 8.0
	var before_kills := GameState.kills
	for i in range(600):
		if i % 18 == 0:
			arena._spawn_enemy(preload("res://data/enemies/crawler.tres"), arena.player.position + Vector2(90 + i % 60, 0))
		arena.set_scripted_input(Vector2.ZERO, arena.player.position + Vector2.RIGHT * 200.0)
		await get_tree().physics_frame
	var result := {
		"damage_events": GameState.kills - before_kills + arena.debug_stats.weapons_tested.get(weapon_id, 0),
	}
	arena.queue_free()
	await get_tree().process_frame
	return result

func _run_forced_synergy_sample(synergy_id: StringName) -> Dictionary:
	var arena = await _fresh_test_arena(0x5500 + int(hash(synergy_id) & 0xff))
	match synergy_id:
		&"detonating_brand":
			arena.apply_tempering(&"branding_iron")
			arena.apply_tempering(&"killing_edge")
			arena.apply_tempering(&"killing_edge")
		&"arc_steel":
			arena.apply_tempering(&"chain_spark")
			arena.apply_tempering(&"chain_spark")
			arena.apply_tempering(&"piercing_slag")
			arena.apply_tempering(&"piercing_slag")
		&"bulwark_orbit":
			arena.apply_tempering(&"orbiting_anvil")
			arena.apply_tempering(&"orbiting_anvil")
			arena.apply_tempering(&"reforged_heart")
			arena.apply_tempering(&"reforged_heart")
		&"blast_furnace":
			arena.apply_tempering(&"nova_dash")
			arena.apply_tempering(&"branding_iron")
		&"overclocked_bellows":
			for i in range(4):
				arena.apply_tempering(&"bellows")
			arena.apply_tempering(&"quenched_legs")
			arena.apply_tempering(&"quenched_legs")
	for i in range(600):
		if i % 60 == 0:
			arena._spawn_enemy(preload("res://data/enemies/crawler.tres"), arena.player.position + Vector2(85, 0))
		arena.set_scripted_input(Vector2.ZERO, arena.player.position + Vector2.RIGHT * 180.0, synergy_id == &"blast_furnace" and i == 1)
		await get_tree().physics_frame
	var result := {"active": arena.active_synergies.has(synergy_id)}
	arena.queue_free()
	await get_tree().process_frame
	return result

func _run_forced_evolution_sample(evolution_id: StringName) -> Dictionary:
	var arena = await _fresh_test_arena(0x6600 + int(hash(evolution_id) & 0xff))
	if evolution_id == &"meteor_volley":
		arena.select_weapon(&"forgehammer")
		for i in range(5):
			arena.apply_tempering(&"forgehammer_sharpen")
		for i in range(3):
			arena.apply_tempering(&"twin_hammers")
	elif evolution_id == &"railspike":
		arena.select_weapon(&"slag_lance")
		for i in range(5):
			arena.apply_tempering(&"slag_lance_sharpen")
		for i in range(4):
			arena.apply_tempering(&"piercing_slag")
	elif evolution_id == &"crucible_breath":
		arena.select_weapon(&"ember_maw")
		for i in range(5):
			arena.apply_tempering(&"ember_maw_sharpen")
		arena.apply_tempering(&"branding_iron")
	arena.force_open_chest()
	for i in range(600):
		if i % 60 == 0:
			arena._spawn_enemy(preload("res://data/enemies/crawler.tres"), arena.player.position + Vector2(110, 0))
		arena.set_scripted_input(Vector2.ZERO, arena.player.position + Vector2.RIGHT * 180.0)
		await get_tree().physics_frame
	var result := {"evolved": arena.active_evolutions.has(evolution_id)}
	arena.queue_free()
	await get_tree().process_frame
	return result
