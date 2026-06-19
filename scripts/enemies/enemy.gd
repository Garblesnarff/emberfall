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
var movement_scale := 1.0
var choir_body_alive: Array[bool] = []
var choir_body_voices: Array[Array] = []
var choir_recent_damage: Array[float] = []
var choir_body_positions: Array[Vector2] = []
var choir_fallen_voices: Array[StringName] = []
var choir_reprise_ticks := -1
var choir_final_chord_fired := false
var tether_state := 0
var tether_ticks := 0
var tether_damage_events := 0
var aurum_attack_log: Array[StringName] = []
var aurum_siphon_ticks := 0
var aurum_siphon_dir := Vector2.RIGHT
var aurum_siphon_locked := false
var aurum_retreat_triggered := false
var aurum_fervor_triggered := false
var aurum_geysers: Array[Dictionary] = []
var aurum_geyser_hits := 0

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
	movement_scale = 1.0
	_setup_v42_boss_state()
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
		position += dir * speed * movement_scale * want
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
		_tick_aurum(dir, enemy_bullets, player)
	else:
		position += dir * speed * movement_scale
	position.x = clampf(position.x, 0.0, Config.WORLD_SIZE.x)
	position.y = clampf(position.y, 0.0, Config.WORLD_SIZE.y)

func apply_damage(amount: float, impulse: Vector2) -> void:
	if data and data.id == &"choir" and boss_bodies_alive > 0:
		_apply_choir_damage(_focused_choir_body_index(), amount)
		return
	hp -= amount
	hit_flash_ticks = 5
	if impulse.length_squared() > 0.001:
		var kb := 0.35
		position += impulse.normalized() * impulse.length() * kb
	if hp <= 0.0:
		dead = true
	_update_boss_phase_state()
	queue_redraw()

func apply_damage_from_player(amount: float, impulse: Vector2, player_heat: float) -> void:
	var final_amount := amount
	if data and data.id == &"aurum":
		final_amount *= Config.AURUM_WHITE_HEAT_DAMAGE_MULT if player_heat >= Config.HEAT_SWEET_LO else Config.AURUM_COLD_DAMAGE_MULT
	apply_damage(final_amount, impulse)

func apply_choir_body_damage(body_index: int, amount: float) -> void:
	if not data or data.id != &"choir":
		apply_damage(amount, Vector2.ZERO)
		return
	_apply_choir_damage(body_index, amount)

func _update_boss_phase_state() -> void:
	if not data or not data.boss:
		return
	if data.id == &"choir":
		return
	if data.id == &"aurum" and hp <= 0.0 and not aurum_retreat_triggered:
		aurum_retreat_triggered = true
		boss_phase = 99
		EventBus.boss_phase.emit(self, 99)
		return
	if data.id == &"aurum_rekindled" and not aurum_fervor_triggered and hp <= max_hp * Config.AURUM_FERVOR_HP_FRAC:
		aurum_fervor_triggered = true
		EventBus.boss_phase.emit(self, 25)
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
		_update_choir_body_positions()
		var living_positions := _living_choir_positions()
		for body_pos in living_positions:
			draw_circle(body_pos - position, 7.0, color.lightened(0.45))
		if living_positions.size() > 1:
			var tether_color := Color(1.0, 0.36, 0.18, 0.65 if tether_state == 2 else 0.24)
			for i in range(living_positions.size()):
				draw_line(living_positions[i] - position, living_positions[(i + 1) % living_positions.size()] - position, tether_color, 3.0 if tether_state == 2 else 1.5)

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
		position += dir * speed * movement_scale
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
		position += Vector2(cos(charge_angle), sin(charge_angle)) * Config.HOUND_CHARGE_SPEED * movement_scale
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
	if choir_reprise_ticks >= 0:
		_tick_choir_reprise(enemy_bullets)
		return
	position += dir * speed * 0.18 * _choir_speed_scale()
	_update_choir_body_positions()
	_tick_choir_tether()
	fire_ticks -= 1
	if fire_ticks > 0:
		return
	fire_ticks = _choir_beat_interval()
	var living := _living_choir_indices()
	if living.is_empty():
		return
	var body_index: int = living[boss_pattern_index % living.size()]
	var pattern: StringName = _choir_primary_voice(body_index)
	boss_pattern_index += 1
	_fire_choir_voice(pattern, enemy_bullets, body_index, dir)
	if boss_bodies_alive < data.boss_body_count and living.size() > 1 and Config.rng.randf() < 0.5:
		var off_body: int = living[(boss_pattern_index + 1) % living.size()]
		_fire_choir_voice(_choir_primary_voice(off_body), enemy_bullets, off_body, dir)

func _tick_aurum(dir: Vector2, enemy_bullets: Node, player: Node2D) -> void:
	position += dir * speed * (0.20 if data.id == &"aurum" else 0.42)
	_tick_aurum_siphon(player)
	_tick_aurum_geysers(player)
	if data.id == &"aurum_rekindled" and not aurum_fervor_triggered and hp <= max_hp * Config.AURUM_FERVOR_HP_FRAC:
		aurum_fervor_triggered = true
		fire_ticks = min(fire_ticks, 10)
		EventBus.boss_phase.emit(self, 25)
	fire_ticks -= 1
	if fire_ticks > 0:
		return
	fire_ticks = Config.randi_range(data.boss_pattern_cooldown_min_ticks, data.boss_pattern_cooldown_max_ticks)
	if data.id == &"aurum_rekindled" and aurum_fervor_triggered:
		fire_ticks = max(20, int(round(float(fire_ticks) * 0.65)))
	var patterns: Array[StringName] = data.boss_patterns
	var pattern: StringName = patterns[boss_pattern_index % patterns.size()]
	boss_pattern_index += 1
	aurum_attack_log.append(pattern)
	if pattern == &"siphon":
		_start_aurum_siphon(dir)
	elif pattern == &"tax":
		_fire_ring(enemy_bullets)
	elif pattern == &"sweep" or pattern == &"barrage":
		_fire_sweep_beam(dir, enemy_bullets)
	elif pattern == &"slam":
		_fire_ring(enemy_bullets)
	elif pattern == &"geyser":
		_start_aurum_geysers(player.position)

func _fire_choir_voice(pattern: StringName, enemy_bullets: Node, body_index: int, dir: Vector2) -> void:
	if pattern == &"mourn":
		_fire_mourn(enemy_bullets, _choir_body_position(body_index))
	elif pattern == &"vesper":
		_fire_fan_from(_choir_body_position(body_index), dir, enemy_bullets, Config.CHOIR_VESPER_SPEED, 5)
	elif pattern == &"harrow":
		_fire_harrow(enemy_bullets, _choir_body_position(body_index))

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

func _fire_fan_from(origin: Vector2, dir: Vector2, enemy_bullets: Node, bullet_speed: float, count: int) -> void:
	var base := dir.angle()
	var half := float(count - 1) * 0.5
	for i in range(count):
		var angle := base + (float(i) - half) * Config.BOSS_FAN_SPREAD_RADIANS
		enemy_bullets.spawn(origin, Vector2(cos(angle), sin(angle)) * bullet_speed, Config.BOSS_BULLET_DAMAGE, Config.BOSS_FAN_BULLET_LIFE_TICKS, Config.BOSS_BULLET_RADIUS, 0)

func _fire_sync_rotate(enemy_bullets: Node) -> void:
	var bodies: int = max(1, boss_bodies_alive)
	var base := float(Engine.get_physics_frames()) * 0.035
	for body in range(bodies):
		var origin := position + Vector2(cos(TAU * float(body) / bodies), sin(TAU * float(body) / bodies)) * (radius + 14.0)
		for i in range(4):
			var angle: float = base + TAU * float(i) / 4.0 + TAU * float(body) / bodies
			enemy_bullets.spawn(origin, Vector2(cos(angle), sin(angle)) * Config.BOSS_FAN_BULLET_SPEED, Config.BOSS_BULLET_DAMAGE, Config.BOSS_FAN_BULLET_LIFE_TICKS, Config.BOSS_BULLET_RADIUS, 0)

func _fire_mourn(enemy_bullets: Node, origin := Vector2.INF) -> void:
	if origin == Vector2.INF:
		origin = position
	var count := 2 + (1 if Config.rng.randf() > 0.5 else 0)
	var base := Config.randf_range(0.0, TAU)
	for i in range(count):
		var angle := base + TAU * float(i) / float(count)
		enemy_bullets.spawn(origin, Vector2(cos(angle), sin(angle)) * Config.CHOIR_MOURN_SPEED, Config.BOSS_BULLET_DAMAGE, Config.BOSS_FAN_BULLET_LIFE_TICKS, Config.BOSS_BULLET_RADIUS, 0, Config.CHOIR_MOURN_HOMING)

func _fire_harrow(enemy_bullets: Node, origin: Vector2) -> void:
	var count := Config.randi_range(6, 10)
	var base := Config.randf_range(0.0, TAU)
	for i in range(count):
		var angle := base + TAU * float(i) / float(count)
		enemy_bullets.spawn(origin, Vector2(cos(angle), sin(angle)) * Config.BOSS_RING_BULLET_SPEED, Config.BOSS_BULLET_DAMAGE, Config.BOSS_RING_BULLET_LIFE_TICKS, Config.BOSS_BULLET_RADIUS, 0)

func _fire_sweep_beam(dir: Vector2, enemy_bullets: Node) -> void:
	var base := dir.angle() - PI * 0.75
	for i in range(9):
		var angle := base + PI * 1.5 * float(i) / 8.0
		enemy_bullets.spawn(position, Vector2(cos(angle), sin(angle)) * (Config.BOSS_FAN_BULLET_SPEED * 1.2), Config.BOSS_BULLET_DAMAGE * 1.25, Config.BOSS_FAN_BULLET_LIFE_TICKS, Config.BOSS_BULLET_RADIUS, 0)

func _setup_v42_boss_state() -> void:
	choir_body_alive.clear()
	choir_body_voices.clear()
	choir_recent_damage.clear()
	choir_body_positions.clear()
	choir_fallen_voices.clear()
	choir_reprise_ticks = -1
	choir_final_chord_fired = false
	tether_state = 0
	tether_ticks = Config.randi_range(Config.CHOIR_TETHER_IDLE_MIN_TICKS, Config.CHOIR_TETHER_IDLE_MAX_TICKS)
	tether_damage_events = 0
	aurum_attack_log.clear()
	aurum_siphon_ticks = 0
	aurum_siphon_dir = Vector2.RIGHT
	aurum_siphon_locked = false
	aurum_retreat_triggered = false
	aurum_fervor_triggered = false
	aurum_geysers.clear()
	aurum_geyser_hits = 0
	if data and data.id == &"choir":
		var voices: Array[StringName] = [&"mourn", &"vesper", &"harrow"]
		for i in range(data.boss_body_count):
			choir_body_alive.append(true)
			choir_body_voices.append([voices[i]])
			choir_recent_damage.append(0.0)
			choir_body_positions.append(position)

func _focused_choir_body_index() -> int:
	var living := _living_choir_indices()
	if living.is_empty():
		return 0
	var best := living[0]
	var best_damage := choir_recent_damage[best]
	for index in living:
		if choir_recent_damage[index] > best_damage:
			best = index
			best_damage = choir_recent_damage[index]
	return best

func _apply_choir_damage(body_index: int, amount: float) -> void:
	if choir_body_alive.is_empty():
		hp -= amount
		if hp <= 0.0:
			dead = true
		return
	body_index = clampi(body_index, 0, choir_body_alive.size() - 1)
	if not choir_body_alive[body_index]:
		body_index = _focused_choir_body_index()
	hp = max(0.0, hp - amount)
	choir_recent_damage[body_index] += amount
	hit_flash_ticks = 5
	_check_choir_thresholds()
	if hp <= 0.0 and choir_reprise_ticks < 0:
		_start_choir_reprise()
	queue_redraw()

func _check_choir_thresholds() -> void:
	var alive := _living_choir_indices().size()
	if alive <= 1:
		return
	var hp_frac := hp / max_hp
	var should_alive := 3
	if hp_frac <= 0.34:
		should_alive = 1
	elif hp_frac <= 0.67:
		should_alive = 2
	while _living_choir_indices().size() > should_alive:
		_drop_focused_choir_body()

func _drop_focused_choir_body() -> void:
	var fallen := _focused_choir_body_index()
	choir_body_alive[fallen] = false
	boss_bodies_alive = _living_choir_indices().size()
	var inherited: Array = choir_body_voices[fallen]
	for voice in inherited:
		choir_fallen_voices.append(voice)
	for index in _living_choir_indices():
		for voice in inherited:
			if not choir_body_voices[index].has(voice):
				choir_body_voices[index].append(voice)
	for i in range(choir_recent_damage.size()):
		choir_recent_damage[i] = 0.0
	EventBus.boss_phase.emit(self, data.boss_body_count - boss_bodies_alive)

func _living_choir_indices() -> Array[int]:
	var living: Array[int] = []
	for i in range(choir_body_alive.size()):
		if choir_body_alive[i]:
			living.append(i)
	return living

func _living_choir_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for index in _living_choir_indices():
		positions.append(_choir_body_position(index))
	return positions

func _choir_body_position(index: int) -> Vector2:
	_update_choir_body_positions()
	if index >= 0 and index < choir_body_positions.size():
		return choir_body_positions[index]
	return position

func _update_choir_body_positions() -> void:
	if not data or data.id != &"choir" or choir_body_alive.is_empty():
		return
	var base := float(Engine.get_physics_frames()) * 0.018
	for i in range(choir_body_positions.size()):
		var angle := base + TAU * float(i) / float(max(1, data.boss_body_count))
		choir_body_positions[i] = position + Vector2(cos(angle), sin(angle)) * Config.CHOIR_ORBIT_RADIUS

func _choir_speed_scale() -> float:
	return 1.0 + float(data.boss_body_count - boss_bodies_alive) * 0.5

func _choir_beat_interval() -> int:
	if boss_bodies_alive <= 1:
		return Config.CHOIR_BEAT_ONE
	if boss_bodies_alive == 2:
		return Config.CHOIR_BEAT_TWO
	return Config.CHOIR_BEAT_THREE

func _choir_primary_voice(body_index: int) -> StringName:
	var voices: Array = choir_body_voices[body_index]
	return voices[boss_pattern_index % voices.size()]

func _tick_choir_tether() -> void:
	if boss_bodies_alive < 2:
		return
	tether_ticks -= 1
	if tether_ticks > 0:
		return
	if tether_state == 0:
		tether_state = 1
		tether_ticks = Config.CHOIR_TETHER_TELEGRAPH_TICKS
	elif tether_state == 1:
		tether_state = 2
		tether_ticks = Config.CHOIR_TETHER_SNAP_TICKS
	else:
		tether_state = 0
		tether_ticks = Config.randi_range(Config.CHOIR_TETHER_IDLE_MIN_TICKS, Config.CHOIR_TETHER_IDLE_MAX_TICKS)

func apply_choir_tether_damage_if_player_on_segment(player: Node2D) -> bool:
	if tether_state != 2:
		return false
	var living_positions := _living_choir_positions()
	if living_positions.size() < 2:
		return false
	for i in range(living_positions.size()):
		var a := living_positions[i]
		var b := living_positions[(i + 1) % living_positions.size()]
		if _point_segment_distance(player.position, a, b) <= Config.CHOIR_TETHER_WIDTH:
			player.apply_damage(Config.CHOIR_TETHER_DAMAGE, self, Config.PLAYER_HURT_IFRAME_TICKS)
			tether_damage_events += 1
			return true
	return false

func _point_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var length_sq := ab.length_squared()
	if length_sq <= 0.001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / length_sq, 0.0, 1.0)
	return point.distance_to(a + ab * t)

func _start_choir_reprise() -> void:
	choir_reprise_ticks = Config.CHOIR_REPRISE_TICKS
	choir_final_chord_fired = false
	boss_bodies_alive = data.boss_body_count
	for i in range(choir_body_alive.size()):
		choir_body_alive[i] = true
	EventBus.boss_phase.emit(self, 70)

func _tick_choir_reprise(enemy_bullets: Node) -> void:
	choir_reprise_ticks -= 1
	if not choir_final_chord_fired and choir_reprise_ticks <= Config.CHOIR_REPRISE_TICKS - Config.CHOIR_REPRISE_CHORD_TICK:
		choir_final_chord_fired = true
		for voice in [&"mourn", &"vesper", &"harrow"]:
			_fire_choir_voice(voice, enemy_bullets, 0, Vector2.RIGHT)
	if choir_reprise_ticks <= 0:
		dead = true
		EventBus.boss_phase.emit(self, 71)

func _start_aurum_siphon(dir: Vector2) -> void:
	aurum_siphon_ticks = Config.AURUM_SIPHON_LOCK_TICKS + Config.AURUM_SIPHON_ACTIVE_TICKS
	aurum_siphon_dir = dir.normalized() if dir.length_squared() > 0.001 else Vector2.RIGHT
	aurum_siphon_locked = false

func _tick_aurum_siphon(player: Node2D) -> void:
	if aurum_siphon_ticks <= 0:
		return
	aurum_siphon_ticks -= 1
	if aurum_siphon_ticks > Config.AURUM_SIPHON_ACTIVE_TICKS:
		var to_player := (player.position - position).normalized()
		if to_player.length_squared() > 0.001:
			aurum_siphon_dir = to_player
		return
	aurum_siphon_locked = true
	var rel := player.position - position
	if rel.dot(aurum_siphon_dir) >= 0.0 and abs(rel.cross(aurum_siphon_dir)) <= Config.AURUM_SIPHON_WIDTH:
		if player.has_method("add_forge_heat"):
			player.add_forge_heat(-Config.AURUM_SIPHON_DRAIN_PER_TICK)

func _start_aurum_geysers(player_pos: Vector2) -> void:
	aurum_geysers.clear()
	for i in range(5):
		var angle := TAU * float(i) / 5.0 + Config.randf_range(-0.2, 0.2)
		var offset := Vector2(cos(angle), sin(angle)) * Config.randf_range(32.0, 120.0)
		aurum_geysers.append({"position": player_pos + offset, "ticks": Config.AURUM_GEYSER_ERUPT_TICK, "erupted": false})

func _tick_aurum_geysers(player: Node2D) -> void:
	for i in range(aurum_geysers.size() - 1, -1, -1):
		var geyser: Dictionary = aurum_geysers[i]
		geyser.ticks = int(geyser.ticks) - 1
		if int(geyser.ticks) <= 0 and not bool(geyser.erupted):
			geyser.erupted = true
			if player.position.distance_to(geyser.position) <= Config.AURUM_GEYSER_RADIUS:
				player.apply_damage(Config.AURUM_GEYSER_DAMAGE, self, Config.PLAYER_HURT_IFRAME_TICKS)
				aurum_geyser_hits += 1
		if int(geyser.ticks) <= -8:
			aurum_geysers.remove_at(i)
		else:
			aurum_geysers[i] = geyser
