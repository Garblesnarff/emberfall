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

func setup(enemy_data: Resource, wave: int, spawn_position: Vector2, make_elite := false) -> void:
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
	if elite:
		hp *= Config.ELITE_HP_MULT
		speed *= Config.ELITE_SPEED_MULT
		damage *= Config.ELITE_DAMAGE_MULT
		radius *= Config.ELITE_RADIUS_MULT
		points *= 4
	max_hp = hp
	dead = false
	fire_ticks = Config.randi_range(enemy_data.fire_cooldown_min_ticks, enemy_data.fire_cooldown_max_ticks) if enemy_data.fire_cooldown_max_ticks > 0 else 0
	_apply_sprite_frames()
	queue_redraw()

func physics_tick(player: Node2D, enemy_bullets: Node) -> void:
	if dead:
		return
	if hit_flash_ticks > 0:
		hit_flash_ticks -= 1
	var to_player: Vector2 = player.position - position
	var dist: float = max(0.001, to_player.length())
	var dir: Vector2 = to_player / dist
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
	queue_redraw()

func _draw() -> void:
	if not data:
		return
	animated_sprite.modulate = Color.WHITE if hit_flash_ticks > 0 else Color.WHITE
	if elite:
		draw_arc(Vector2.ZERO, radius + 5.0, 0, TAU, 32, Color(1.0, 0.91, 0.77), 2.0)
	if max_hp > 40.0:
		var width := radius * 2.2
		draw_rect(Rect2(Vector2(-width * 0.5, -radius - 10.0), Vector2(width, 4)), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(Vector2(-width * 0.5, -radius - 10.0), Vector2(width * max(0.0, hp / max_hp), 4)), color.lightened(0.25))

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
