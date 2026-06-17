extends Node

const PHYSICS_TICKS_PER_SECOND := 60
const WORLD_SIZE := Vector2(3200.0, 2400.0)
const CAMERA_LOOKAHEAD := 80.0
const CAMERA_LERP := 0.08
const CAMERA_BOSS_TELEGRAPH_TICKS := 90

const GRID_CELL_SIZE := 80.0
const ACTIVE_ENEMY_CAP := 80
const PLAYER_BULLET_CAP := 300
const ENEMY_BULLET_CAP := 500
const DAMAGE_NUMBER_CAP := 70

const PLAYER_HP := 100.0
const PLAYER_RADIUS := 11.0
const PLAYER_SPEED := 3.3
const PLAYER_DAMAGE := 10.0
const PLAYER_FIRE_RATE_TICKS := 11
const PLAYER_PROJECTILE_SPEED := 9.5
const PLAYER_PROJECTILE_LIFE_TICKS := 80
const PLAYER_DASH_COOLDOWN_TICKS := 90
const PLAYER_DASH_DURATION_TICKS := 9
const PLAYER_DASH_SPEED_PER_TICK := 13.0
const PLAYER_DASH_IFRAME_TICKS := 14
const PLAYER_HURT_IFRAME_TICKS := 40
const PLAYER_BULLET_HURT_IFRAME_TICKS := 35
const PLAYER_KNOCKBACK := 22.0
const LAVA_DAMAGE := 4.0
const LAVA_DAMAGE_INTERVAL_TICKS := 30

const SHAKE_DECAY := 0.85
const SHAKE_SHOT := 1.0
const SHAKE_KILL := 3.5
const SHAKE_ELITE_KILL := 7.0
const SHAKE_PLAYER_HURT := 10.0
const SHAKE_ENEMY_BULLET_HURT := 8.0
const HITSTOP_PLAYER_HURT_TICKS := 4
const HITSTOP_BOSS_KILL_TICKS := 8

const SPAWN_INITIAL_DELAY_TICKS := 30
const BOSS_TELEGRAPH_TICKS := 90
const SPAWN_OFFSCREEN_MIN := 60.0
const SPAWN_OFFSCREEN_MAX := 140.0
const SPAWN_INTERVAL_MIN_TICKS := 6
const SPAWN_INTERVAL_BASE_TICKS := 40
const SPAWN_INTERVAL_WAVE_REDUCTION := 2

const ENEMY_HP_SCALE_LINEAR := 0.32
const ENEMY_HP_SCALE_EXP := 1.6
const ENEMY_HP_SCALE_EXP_FACTOR := 0.02
const ELITE_BASE_CHANCE := 0.03
const ELITE_WAVE_CHANCE := 0.006
const ELITE_MAX_CHANCE := 0.22
const ELITE_HP_MULT := 2.6
const ELITE_SPEED_MULT := 1.12
const ELITE_DAMAGE_MULT := 1.3
const ELITE_RADIUS_MULT := 1.18

const WAVE_BASE_COUNT := 8
const WAVE_COUNT_PER_WAVE := 2.6
const WAVE_COUNT_CAP := 110
const WAVE_SPITTER_ROLL := 0.20
const WAVE_BRUTE_ROLL := 0.34
const WAVE_SPLITTER_ROLL := 0.46
const WAVE_HOUND_ROLL := 0.58
const COMBO_DECAY_TICKS := 180
const LOD_SEPARATION_VIEWPORT_MULT := 1.5
const THREAT_CHEVRON_MAX := 12

const SPLITTER_CHILD_SPACING := 18.0
const HOUND_TRIGGER_RANGE := 340.0
const HOUND_WINDUP_TICKS := 26
const HOUND_CHARGE_TICKS := 22
const HOUND_CHARGE_SPEED := 9.0
const HOUND_RESET_MIN_TICKS := 70
const HOUND_RESET_MAX_TICKS := 110

const BOSS_RING_BULLET_SPEED := 3.0
const BOSS_FAN_BULLET_SPEED := 4.6
const BOSS_FAN_SPREAD_RADIANS := 0.16
const BOSS_BULLET_RADIUS := 6.0
const BOSS_BULLET_DAMAGE := 14.0
const BOSS_RING_BULLET_LIFE_TICKS := 240
const BOSS_FAN_BULLET_LIFE_TICKS := 220
const BOSS_CHARGE_WINDUP_TICKS := 34
const BOSS_CHARGE_TICKS := 30
const BOSS_CHARGE_SPEED := 7.0

const DROP_HEART_HEAL := 12.0
const DROP_EMBER_SCORE := 60
const DROP_PICKUP_RADIUS := 20.0
const DROP_MAGNET_RADIUS := 110.0
const DROP_MAGNET_PULL := 7.0
const HEART_DROP_CHANCE := 0.045
const EMBER_DROP_CHANCE := 0.22
const ELITE_HEART_DROP_CHANCE := 0.45
const CHEST_RADIUS := 16.0
const CHEST_REVEAL_SLOWMO_SCALE := 0.3
const CHEST_REVEAL_TICKS := 72
const UPGRADE_PICK_COUNT := 3

const OBJECTIVE_MARKER_RADIUS := 42.0
const OBJECTIVE_PATTERN := [&"ember_vein", &"braziers", &"none", &"elite_bounty", &"ember_vein", &"none"]
const OBJECTIVE_VEIN_ERUPT_COUNT := 6
const OBJECTIVE_BRAZIER_BONUS_CHOICES := 1
const OBJECTIVE_BOUNTY_DESPAWN_TICKS := 2700
const ANVIL_DEFENSE_START_HP := 300.0
const ANVIL_DEFENSE_HP_PER_WAVE := 40.0
const ANVIL_DEFENSE_BLESSING_HP := 30.0
const ANVIL_THREAT_RADIUS := 520.0

const BURN_TICK_INTERVAL := 20
const BURN_DAMAGE_FACTOR := 0.18
const DETONATING_BRAND_RADIUS := 130.0
const DETONATING_BRAND_DAMAGE_FACTOR := 1.35
const BLAST_FURNACE_RADIUS := 170.0
const BLAST_FURNACE_DAMAGE_FACTOR := 2.2
const BLAST_FURNACE_DASH_REFUND := 0.30
const OVERCLOCK_STILL_TICKS := 60
const OVERCLOCK_FIRE_RATE_MULT := 0.60
const METEOR_RADIUS := 115.0
const RAILSPIKE_WIDTH := 34.0
const VICTORY_EMBER_MULT := 1.5

var rng := RandomNumberGenerator.new()
var run_seed := 0
var screen_shake_scale := 1.0
var damage_numbers_enabled := true
var minimap_enabled := true
var fps_overlay_enabled := false

func _ready() -> void:
	Engine.physics_ticks_per_second = PHYSICS_TICKS_PER_SECOND
	_ensure_controller_defaults()
	set_run_seed(0xE4BEF411)

func apply_settings(settings: Dictionary) -> void:
	screen_shake_scale = clampf(float(settings.get("shake", 1.0)), 0.0, 1.0)
	damage_numbers_enabled = bool(settings.get("dnums", true))
	minimap_enabled = bool(settings.get("minimap", true))
	fps_overlay_enabled = bool(settings.get("fps", false))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(settings.get("vsync", true)) else DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if bool(settings.get("fullscreen", false)) else DisplayServer.WINDOW_MODE_WINDOWED)

func set_run_seed(seed_value: int) -> void:
	run_seed = seed_value
	rng.seed = seed_value

func randf_range(min_value: float, max_value: float) -> float:
	return rng.randf_range(min_value, max_value)

func randi_range(min_value: int, max_value: int) -> int:
	return rng.randi_range(min_value, max_value)

func enemy_hp_scale(wave: int) -> float:
	return 1.0 + wave * ENEMY_HP_SCALE_LINEAR + pow(float(wave), ENEMY_HP_SCALE_EXP) * ENEMY_HP_SCALE_EXP_FACTOR

func elite_chance(wave: int) -> float:
	return min(ELITE_BASE_CHANCE + wave * ELITE_WAVE_CHANCE, ELITE_MAX_CHANCE)

func spawn_interval(wave: int) -> int:
	return max(SPAWN_INTERVAL_MIN_TICKS, SPAWN_INTERVAL_BASE_TICKS - wave * SPAWN_INTERVAL_WAVE_REDUCTION)

func _ensure_controller_defaults() -> void:
	_add_axis_event("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis_event("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_axis_event("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis_event("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_button_event("dash", JOY_BUTTON_A)
	_add_button_event("dash", JOY_BUTTON_RIGHT_SHOULDER)
	_add_button_event("pause", JOY_BUTTON_START)

func _add_axis_event(action: StringName, axis: JoyAxis, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, axis_value):
			return
	var joy_event := InputEventJoypadMotion.new()
	joy_event.axis = axis
	joy_event.axis_value = axis_value
	InputMap.action_add_event(action, joy_event)

func _add_button_event(action: StringName, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return
	var joy_event := InputEventJoypadButton.new()
	joy_event.button_index = button
	InputMap.action_add_event(action, joy_event)
