extends CharacterBody2D
class_name Player

const BASE_FEEL := preload("res://data/player_feel.tres")

@export var feel: Resource

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D

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
var forge_heat := 0.0
var attack_animation_ticks := 0
var last_facing_direction := Vector2.DOWN

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
	forge_heat = 0.0
	fire_ticks = 0
	dash_cooldown_ticks = 0
	dashing_ticks = 0
	invulnerable_ticks = 0
	dash_direction = Vector2.RIGHT
	attack_animation_ticks = 0
	last_facing_direction = Vector2.DOWN
	_update_directional_animation(last_facing_direction)
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
	if attack_animation_ticks > 0:
		attack_animation_ticks -= 1
	forge_heat = max(0.0, forge_heat - Config.HEAT_DECAY_PER_TICK)
	fire_ticks -= 1
	if fire_ticks <= 0 and not suppress_auto_fire:
		fire_ticks = feel.fire_rate_ticks
		var dir := (aim_world - position).normalized()
		if dir.length_squared() <= 0.001:
			dir = Vector2.RIGHT
		bullet_manager.spawn(position + dir * 14.0, dir * feel.projectile_speed, damage, feel.projectile_life_ticks)
		add_forge_heat(Config.HEAT_SHOT_GAIN)
		EventBus.shake_requested.emit(Config.SHAKE_SHOT)
	_update_directional_animation(input_vector)
	queue_redraw()

func play_attack_animation(direction: Vector2) -> void:
	if animated_sprite.sprite_frames == null or not animated_sprite.sprite_frames.has_animation(&"attack_00"):
		return
	attack_animation_ticks = _animation_duration_ticks(&"attack_00")
	_update_directional_animation(direction)

func _update_directional_animation(direction: Vector2) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if direction.length_squared() > 0.001:
		last_facing_direction = direction.normalized()
	var angle := wrapf(last_facing_direction.angle() + PI * 0.5, 0.0, TAU)
	var index := int(round(angle / TAU * 8.0)) % 8
	var prefix := "walk"
	if dashing_ticks > 0:
		prefix = "dash"
	elif attack_animation_ticks > 0:
		prefix = "attack"
	var animation := StringName("%s_%02d" % [prefix, index])
	if not animated_sprite.sprite_frames.has_animation(animation):
		animation = StringName("walk_%02d" % index)
	if not animated_sprite.sprite_frames.has_animation(animation):
		return
	if animated_sprite.animation != animation:
		animated_sprite.animation = animation
		animated_sprite.play()
	if prefix == "walk" and move_input.length_squared() <= 0.001:
		animated_sprite.pause()
		animated_sprite.frame = 0
	elif not animated_sprite.is_playing():
		animated_sprite.play()

func _animation_duration_ticks(animation: StringName) -> int:
	var frame_count := animated_sprite.sprite_frames.get_frame_count(animation)
	var fps := animated_sprite.sprite_frames.get_animation_speed(animation)
	return max(1, ceili(float(frame_count * Config.PHYSICS_TICKS_PER_SECOND) / maxf(fps, 0.001)))

func add_forge_heat(amount: float) -> void:
	forge_heat = clampf(forge_heat + amount, 0.0, Config.HEAT_MAX)

func heat_fraction() -> float:
	return clampf(forge_heat / Config.HEAT_MAX, 0.0, 1.0)

func swelter_radius() -> float:
	var heat_frac := heat_fraction()
	if heat_frac <= 0.0:
		return 0.0
	return Config.SWELTER_RADIUS_BASE + heat_frac * Config.SWELTER_RADIUS_SCALE

func swelter_slow() -> float:
	return Config.SWELTER_SLOW_BASE + heat_fraction() * Config.SWELTER_SLOW_SCALE

func swelter_scorch_damage(shot_damage: float) -> float:
	if forge_heat < Config.HEAT_SWEET_LO:
		return 0.0
	return shot_damage * Config.SWELTER_SCORCH_DAMAGE_FACTOR

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
	if animated_sprite:
		animated_sprite.visible = not blink
	if blink:
		return
	var heat_frac := heat_fraction()
	var aura_radius := swelter_radius()
	if aura_radius > 0.0:
		draw_circle(Vector2.ZERO, aura_radius, Color(1.0, 0.30 + heat_frac * 0.42, 0.08, 0.035 + heat_frac * 0.055))
		draw_arc(Vector2.ZERO, aura_radius, 0.0, TAU, 80, Color(1.0, 0.70 + heat_frac * 0.21, 0.25, 0.16 + heat_frac * 0.20), 2.0)
	draw_circle(Vector2.ZERO, radius + (8.0 if dashing_ticks > 0 else 3.0), Color(1.0, 0.682, 0.259, 0.22))
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.91, 0.77))
		var crown_height := 10.0 + heat_frac * 18.0
		var crown_color := Color(1.0, 0.84 + heat_frac * 0.16, 0.34 + heat_frac * 0.36, 0.58 + heat_frac * 0.35)
		draw_polygon([
			Vector2(-radius * 0.55, -radius * 0.8),
			Vector2(0.0, -radius - crown_height),
			Vector2(radius * 0.55, -radius * 0.8),
			Vector2(0.0, -radius * 0.35),
		], [crown_color])
	var dir := (aim_world - position).normalized()
	if dir.length_squared() > 0.0:
		draw_line(Vector2.ZERO, dir * (radius + 11.0), Color(0.08, 0.067, 0.047), 3.0)
