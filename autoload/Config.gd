extends Node

const PHYSICS_TICKS_PER_SECOND := 60
const WORLD_SIZE := Vector2(3200.0, 2400.0)
const CAMERA_LOOKAHEAD := 80.0
const CAMERA_LERP := 0.08

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

const SHAKE_DECAY := 0.85
const SHAKE_SHOT := 1.0
const SHAKE_KILL := 3.5
const SHAKE_ELITE_KILL := 7.0
const SHAKE_PLAYER_HURT := 10.0
const SHAKE_ENEMY_BULLET_HURT := 8.0
const HITSTOP_PLAYER_HURT_TICKS := 4
const HITSTOP_BOSS_KILL_TICKS := 8

const SPAWN_INITIAL_DELAY_TICKS := 30
const SPAWN_INTERVAL_MIN_TICKS := 6
const SPAWN_INTERVAL_BASE_TICKS := 40
const SPAWN_INTERVAL_WAVE_REDUCTION := 2
const PHASE1_ACTIVE_SPAWN_CAP := 52

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
const COMBO_DECAY_TICKS := 180

var rng := RandomNumberGenerator.new()
var run_seed := 0
var screen_shake_scale := 1.0

func _ready() -> void:
	Engine.physics_ticks_per_second = PHYSICS_TICKS_PER_SECOND
	set_run_seed(0xE4BEF411)

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
