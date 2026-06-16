extends CharacterBody2D
class_name Player

const BASE_FEEL := preload("res://data/player_feel.tres")

@export var feel: Resource

var radius := Config.PLAYER_RADIUS
var hp := Config.PLAYER_HP
var max_hp := Config.PLAYER_HP
var damage := Config.PLAYER_DAMAGE
var fire_ticks := 0
var dash_cooldown_ticks := 0
var dashing_ticks := 0
var invulnerable_ticks := 0
var dash_direction := Vector2.RIGHT
var aim_world := Vector2.RIGHT
var move_input := Vector2.ZERO
var damage_mult := 1.0
var fire_rate_mult := 1.0
var weapon_shots_bonus := 0
var pierce_bonus := 0
var ricochet_bonus := 0
var lifesteal := 0.0
var regen := 0.0
var crit := 0.0
var burn := false
var nova := false
var orbs := 0
var orb_angle := 0.0
var thorns := 0.0
var magnet_mult := 1.0
var second_wind_ready := false

func _ready() -> void:
	if feel == null:
		feel = load("res://data/player_feel.tres")
	feel = feel.duplicate(true)
	reset(Vector2(Config.WORLD_SIZE.x * 0.5, Config.WORLD_SIZE.y * 0.5))

func reset(pos: Vector2) -> void:
	feel = BASE_FEEL.duplicate(true)
	position = pos
	radius = feel.radius
	hp = feel.hp
	max_hp = feel.hp
	damage = feel.damage
	damage_mult = 1.0
	fire_rate_mult = 1.0
	weapon_shots_bonus = 0
	pierce_bonus = 0
	ricochet_bonus = 0
	lifesteal = 0.0
	regen = 0.0
	crit = 0.0
	burn = false
	nova = false
	orbs = 0
	orb_angle = 0.0
	thorns = 0.0
	magnet_mult = 1.0
	second_wind_ready = false
	fire_ticks = 0
	dash_cooldown_ticks = 0
	dashing_ticks = 0
	invulnerable_ticks = 0
	dash_direction = Vector2.RIGHT
	queue_redraw()

func physics_tick(input_vector: Vector2, aim_pos: Vector2, bullet_manager: Node, dash_pressed := false, suppress_auto_fire := false) -> void:
	move_input = input_vector
	aim_world = aim_pos
	if dashing_ticks > 0:
		dashing_ticks -= 1
		velocity = dash_direction * feel.dash_speed_per_tick * Config.PHYSICS_TICKS_PER_SECOND
	else:
		velocity = input_vector * feel.speed * Config.PHYSICS_TICKS_PER_SECOND
	move_and_slide()
	position.x = clampf(position.x, radius, Config.WORLD_SIZE.x - radius)
	position.y = clampf(position.y, radius, Config.WORLD_SIZE.y - radius)
	if dash_cooldown_ticks > 0:
		dash_cooldown_ticks -= 1
	if (Input.is_action_pressed("dash") or dash_pressed) and dash_cooldown_ticks <= 0 and input_vector.length_squared() > 0.0:
		dash_direction = input_vector.normalized()
		dashing_ticks = feel.dash_duration_ticks
		invulnerable_ticks = feel.dash_iframe_ticks
		dash_cooldown_ticks = feel.dash_cooldown_ticks
	if invulnerable_ticks > 0:
		invulnerable_ticks -= 1
	fire_ticks -= 1
	if fire_ticks <= 0 and not suppress_auto_fire:
		fire_ticks = feel.fire_rate_ticks
		var dir := (aim_world - position).normalized()
		if dir.length_squared() <= 0.001:
			dir = Vector2.RIGHT
		bullet_manager.spawn(position + dir * 14.0, dir * feel.projectile_speed, damage, feel.projectile_life_ticks)
		EventBus.shake_requested.emit(Config.SHAKE_SHOT)
	queue_redraw()

func apply_damage(amount: float, source: Variant, iframe_ticks := Config.PLAYER_HURT_IFRAME_TICKS) -> void:
	if invulnerable_ticks > 0 or dashing_ticks > 0:
		return
	hp = max(0.0, hp - amount)
	if hp <= 0.0 and second_wind_ready:
		second_wind_ready = false
		hp = max_hp * 0.45
	invulnerable_ticks = iframe_ticks
	GameState.set_combo(0)
	EventBus.player_hurt.emit(amount, source)
	EventBus.shake_requested.emit(Config.SHAKE_PLAYER_HURT)
	EventBus.hitstop_requested.emit(Config.HITSTOP_PLAYER_HURT_TICKS)
	queue_redraw()

func dash_ready_ratio() -> float:
	return 1.0 - float(dash_cooldown_ticks) / float(feel.dash_cooldown_ticks)

func _draw() -> void:
	var blink := invulnerable_ticks > 0 and int(Engine.get_physics_frames() / 4) % 2 == 0
	if blink:
		return
	draw_circle(Vector2.ZERO, radius + (8.0 if dashing_ticks > 0 else 3.0), Color(1.0, 0.682, 0.259, 0.22))
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.91, 0.77))
	var dir := (aim_world - position).normalized()
	if dir.length_squared() > 0.0:
		draw_line(Vector2.ZERO, dir * (radius + 11.0), Color(0.08, 0.067, 0.047), 3.0)
