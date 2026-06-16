extends Node2D
class_name Enemy

const PlaceholderSpriteFactoryScript := preload("res://scripts/systems/placeholder_sprite_factory.gd")

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D

var data: Resource
var radius := 10.0
var hp := 1.0
var max_hp := 1.0
var speed := 1.0
var damage := 1.0
var points := 0
var color := Color.WHITE
var elite := false
var dead := false
var fire_ticks := 0
var hit_flash_ticks := 0
var child := false
var hound_state := 0
var hound_ticks := 0
var charge_angle := 0.0
var boss_pattern_index := 0
var telegraph_ticks := 0
var lava_ticks := 0
var skipped_separation := false
var burn_ticks := 0
var burn_damage := 0.0
var boss_phase := 1
var boss_bodies_alive := 1
var last_body_threshold := 1.0

func setup(enemy_data: Resource, wave: int, spawn_position: Vector2, make_elite := false, child_enemy := false) -> void:
	data = enemy_data
	position = spawn_position
	var scale := Config.enemy_hp_scale(wave)
	radius = enemy_data.radius
	hp = enemy_data.hp * scale
	speed = Config.randf_range(enemy_data.speed_min, enemy_data.speed_max) + _wave_speed_bonus(enemy_data, wave)
	damage = enemy_data.damage
	points = enemy_data.points
	color = enemy_data.color
	elite = make_elite
	child = child_enemy
	if elite:
		hp *= Config.ELITE_HP_MULT
		speed *= Config.ELITE_SPEED_MULT
		damage *= Config.ELITE_DAMAGE_MULT
		radius *= Config.ELITE_RADIUS_MULT
		points *= 4
	if child:
		hp *= enemy_data.split_child_hp_mult if enemy_data.split_child_hp_mult > 0.0 else 0.45
		radius *= enemy_data.split_child_radius_mult if enemy_data.split_child_radius_mult > 0.0 else 0.8
		points = 5
	max_hp = hp
	dead = false
	fire_ticks = Config.randi_range(enemy_data.fire_cooldown_min_ticks, enemy_data.fire_cooldown_max_ticks) if enemy_data.fire_cooldown_max_ticks > 0 else 0
	if data.boss:
		fire_ticks = data.boss_pattern_cooldown_max_ticks
	boss_phase = 1
	boss_bodies_alive = max(1, data.boss_body_count)
	last_body_threshold = 1.0
	hound_state = 0
	hound_ticks = Config.randi_range(50, 90)
	telegraph_ticks = 0
	burn_ticks = 0
	burn_damage = 0.0
	_apply_sprite_frames()
	queue_redraw()

func physics_tick(player: Node2D, enemy_bullets: Node) -> void:
	if dead:
		return
	if hit_flash_ticks > 0:
		hit_flash_ticks -= 1
	if burn_ticks > 0:
		burn_ticks -= 1
		if burn_ticks % Config.BURN_TICK_INTERVAL == 0:
			apply_damage(burn_damage, Vector2.ZERO)
	var to_player: Vector2 = player.position - position
	var dist: float = max(0.001, to_player.length())
	var dir: Vector2 = to_player / dist
	if telegraph_ticks > 0:
		telegraph_ticks -= 1
		return
	if data.ai_profile == &"kite":
		var want := 0.0
		if dist > data.preferred_range:
			want = 1.0
		elif dist < data.retreat_range:
			want = -1.0
		position += dir * speed * want
		fire_ticks -= 1
		if fire_ticks <= 0:
			fire_ticks = Config.randi_range(data.fire_cooldown_min_ticks, data.fire_cooldown_max_ticks)
			enemy_bullets.spawn(position, dir * data.projectile_speed, damage, data.projectile_life_ticks, data.projectile_radius, 0)
	elif data.ai_profile == &"hound":
		_tick_hound(dir, dist)
	elif data.ai_profile == &"boss_kilnmaw":
		_tick_kilnmaw(dir, enemy_bullets)
	elif data.ai_profile == &"boss_choir":
		_tick_choir(dir, enemy_bullets)
	elif data.ai_profile == &"boss_aurum":
		_tick_aurum(dir, enemy_bullets)
	else:
		position += dir * speed
	position.x = clampf(position.x, 0.0, Config.WORLD_SIZE.x)
	position.y = clampf(position.y, 0.0, Config.WORLD_SIZE.y)

func apply_damage(amount: float, impulse: Vector2) -> void:
	hp -= amount
	hit_flash_ticks = 5
	if impulse.length_squared() > 0.001:
		var kb := 0.35
		position += impulse.normalized() * impulse.length() * kb
	if hp <= 0.0:
		dead = true
	_update_boss_phase_state()
	queue_redraw()

func _update_boss_phase_state() -> void:
	if not data or not data.boss:
		return
	if data.boss_body_count > 1:
		var third := max_hp / float(data.boss_body_count)
		var expected_alive := ceili(max(0.0, hp) / third)
		expected_alive = clampi(expected_alive, 0, data.boss_body_count)
		if expected_alive < boss_bodies_alive:
			boss_bodies_alive = expected_alive
			speed *= 1.12
			EventBus.boss_phase.emit(self, data.boss_body_count - boss_bodies_alive)
	if boss_phase == 1 and hp <= max_hp * 0.5 and not data.boss_phase2_patterns.is_empty():
		boss_phase = 2
		EventBus.boss_phase.emit(self, 2)

func apply_burn(ticks_count: int, per_tick_damage: float) -> void:
	burn_ticks = max(burn_ticks, ticks_count)
	burn_damage = max(burn_damage, per_tick_damage)

func apply_lava_damage() -> void:
	lava_ticks += 1
	if lava_ticks >= Config.LAVA_DAMAGE_INTERVAL_TICKS:
		lava_ticks = 0
		apply_damage(Config.LAVA_DAMAGE, Vector2.ZERO)

func _draw() -> void:
	if not data:
		return
	animated_sprite.modulate = Color.WHITE if hit_flash_ticks > 0 else Color.WHITE
	if elite:
		draw_arc(Vector2.ZERO, radius + 5.0, 0, TAU, 32, Color(1.0, 0.91, 0.77), 2.0)
	if telegraph_ticks > 0:
		draw_arc(Vector2.ZERO, radius + 12.0, 0, TAU, 48, Color(1.0, 0.682, 0.259, 0.8), 3.0)
	if hound_state == 1 or (data and data.ai_profile == &"boss_kilnmaw" and hound_state == 1):
		draw_line(Vector2.ZERO, Vector2(cos(charge_angle), sin(charge_angle)) * (radius + 38.0), Color(1.0, 0.91, 0.77, 0.8), 3.0)
	if max_hp > 40.0:
		var width := radius * 2.2
		draw_rect(Rect2(Vector2(-width * 0.5, -radius - 10.0), Vector2(width, 4)), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(Vector2(-width * 0.5, -radius - 10.0), Vector2(width * max(0.0, hp / max_hp), 4)), color.lightened(0.25))
	if data and data.boss_body_count > 1:
		for i in range(boss_bodies_alive):
			var angle := TAU * float(i) / float(max(1, boss_bodies_alive)) + float(Engine.get_physics_frames()) * 0.025
			draw_circle(Vector2(cos(angle), sin(angle)) * (radius + 16.0), 7.0, color.lightened(0.45))

func _apply_sprite_frames() -> void:
	if data.sprite_frames:
		animated_sprite.sprite_frames = data.sprite_frames
	else:
		animated_sprite.sprite_frames = PlaceholderSpriteFactoryScript.enemy_frames(color, radius, data.placeholder_sides)
	animated_sprite.animation = &"idle"
	animated_sprite.play()

func _wave_speed_bonus(enemy_data: Resource, wave: int) -> float:
	if enemy_data.id == &"crawler":
		return min(wave * 0.05, 1.4)
	if enemy_data.id == &"brute":
		return min(wave * 0.025, 0.8)
	return 0.0

func _tick_hound(dir: Vector2, dist: float) -> void:
	if hound_state == 0:
		position += dir * speed
		hound_ticks -= 1
		if hound_ticks <= 0 and dist < Config.HOUND_TRIGGER_RANGE:
			hound_state = 1
			hound_ticks = Config.HOUND_WINDUP_TICKS
			charge_angle = dir.angle()
	elif hound_state == 1:
		hound_ticks -= 1
		charge_angle = dir.angle()
		if hound_ticks <= 0:
			hound_state = 2
			hound_ticks = Config.HOUND_CHARGE_TICKS
	else:
		position += Vector2(cos(charge_angle), sin(charge_angle)) * Config.HOUND_CHARGE_SPEED
		hound_ticks -= 1
		if hound_ticks <= 0:
			hound_state = 0
			hound_ticks = Config.randi_range(Config.HOUND_RESET_MIN_TICKS, Config.HOUND_RESET_MAX_TICKS)

func _tick_kilnmaw(dir: Vector2, enemy_bullets: Node) -> void:
	if hound_state == 1:
		hound_ticks -= 1
		charge_angle = dir.angle()
		if hound_ticks <= 0:
			hound_state = 2
			hound_ticks = Config.BOSS_CHARGE_TICKS
	elif hound_state == 2:
		position += Vector2(cos(charge_angle), sin(charge_angle)) * Config.BOSS_CHARGE_SPEED
		hound_ticks -= 1
		if hound_ticks <= 0:
			hound_state = 0
	else:
		position += dir * speed
		fire_ticks -= 1
		if fire_ticks <= 0:
			fire_ticks = clampi(data.boss_pattern_cooldown_max_ticks - GameState.wave * 2, data.boss_pattern_cooldown_min_ticks, data.boss_pattern_cooldown_max_ticks)
			var pattern: StringName = data.boss_patterns[boss_pattern_index % data.boss_patterns.size()]
			boss_pattern_index += 1
			if pattern == &"ring":
				_fire_ring(enemy_bullets)
			elif pattern == &"fan":
				_fire_fan(dir, enemy_bullets)
			elif pattern == &"charge":
				hound_state = 1
				hound_ticks = Config.BOSS_CHARGE_WINDUP_TICKS
				charge_angle = dir.angle()

func _tick_choir(dir: Vector2, enemy_bullets: Node) -> void:
	position += dir * speed * 0.35
	fire_ticks -= 1
	if fire_ticks > 0:
		return
	fire_ticks = clampi(data.boss_pattern_cooldown_max_ticks - max(0, data.boss_body_count - boss_bodies_alive) * 8, data.boss_pattern_cooldown_min_ticks, data.boss_pattern_cooldown_max_ticks)
	var pattern: StringName = data.boss_patterns[boss_pattern_index % data.boss_patterns.size()]
	boss_pattern_index += 1
	if pattern == &"sync_rotate":
		_fire_sync_rotate(enemy_bullets)
	elif pattern == &"fan":
		_fire_fan(dir, enemy_bullets)
	elif pattern == &"ring":
		_fire_ring(enemy_bullets)

func _tick_aurum(dir: Vector2, enemy_bullets: Node) -> void:
	position += dir * speed * (0.32 if boss_phase == 1 else 0.45)
	fire_ticks -= 1
	if fire_ticks > 0:
		return
	fire_ticks = clampi(data.boss_pattern_cooldown_max_ticks - GameState.wave * 2, data.boss_pattern_cooldown_min_ticks, data.boss_pattern_cooldown_max_ticks)
	var patterns: Array[StringName] = data.boss_patterns if boss_phase == 1 or data.boss_phase2_patterns.is_empty() else data.boss_phase2_patterns
	var pattern: StringName = patterns[boss_pattern_index % patterns.size()]
	boss_pattern_index += 1
	if pattern == &"summon":
		_fire_ring(enemy_bullets)
	elif pattern == &"sweep_beam":
		_fire_sweep_beam(dir, enemy_bullets)
	elif pattern == &"ring":
		_fire_ring(enemy_bullets)
	elif pattern == &"fan":
		_fire_fan(dir, enemy_bullets)
	elif pattern == &"charge":
		hound_state = 1
		hound_ticks = Config.BOSS_CHARGE_WINDUP_TICKS
		charge_angle = dir.angle()

func _fire_ring(enemy_bullets: Node) -> void:
	var count := 10 + floori(GameState.wave / 5.0) * 2
	var base := Config.randf_range(0.0, TAU)
	for i in range(count):
		var angle := base + TAU * float(i) / float(count)
		enemy_bullets.spawn(position, Vector2(cos(angle), sin(angle)) * Config.BOSS_RING_BULLET_SPEED, Config.BOSS_BULLET_DAMAGE, Config.BOSS_RING_BULLET_LIFE_TICKS, Config.BOSS_BULLET_RADIUS, 0)
	EventBus.shake_requested.emit(5.0)

func _fire_fan(dir: Vector2, enemy_bullets: Node) -> void:
	var base := dir.angle()
	for i in range(-2, 3):
		var angle := base + float(i) * Config.BOSS_FAN_SPREAD_RADIANS
		enemy_bullets.spawn(position, Vector2(cos(angle), sin(angle)) * Config.BOSS_FAN_BULLET_SPEED, Config.BOSS_BULLET_DAMAGE, Config.BOSS_FAN_BULLET_LIFE_TICKS, Config.BOSS_BULLET_RADIUS, 0)

func _fire_sync_rotate(enemy_bullets: Node) -> void:
	var bodies: int = max(1, boss_bodies_alive)
	var base := float(Engine.get_physics_frames()) * 0.035
	for body in range(bodies):
		var origin := position + Vector2(cos(TAU * float(body) / bodies), sin(TAU * float(body) / bodies)) * (radius + 14.0)
		for i in range(4):
			var angle: float = base + TAU * float(i) / 4.0 + TAU * float(body) / bodies
			enemy_bullets.spawn(origin, Vector2(cos(angle), sin(angle)) * Config.BOSS_FAN_BULLET_SPEED, Config.BOSS_BULLET_DAMAGE, Config.BOSS_FAN_BULLET_LIFE_TICKS, Config.BOSS_BULLET_RADIUS, 0)

func _fire_sweep_beam(dir: Vector2, enemy_bullets: Node) -> void:
	var base := dir.angle() - PI * 0.75
	for i in range(9):
		var angle := base + PI * 1.5 * float(i) / 8.0
		enemy_bullets.spawn(position, Vector2(cos(angle), sin(angle)) * (Config.BOSS_FAN_BULLET_SPEED * 1.2), Config.BOSS_BULLET_DAMAGE * 1.25, Config.BOSS_FAN_BULLET_LIFE_TICKS, Config.BOSS_BULLET_RADIUS, 0)
