extends Node2D

const EnemyScene := preload("res://scenes/enemies/enemy.tscn")
const CRAWLER := preload("res://data/enemies/crawler.tres")
const BRUTE := preload("res://data/enemies/brute.tres")
const SPITTER := preload("res://data/enemies/spitter.tres")

@onready var player: Node = %Player
@onready var player_bullets: Node = %PlayerBullets
@onready var enemy_bullets: Node = %EnemyBullets
@onready var camera: Camera2D = %Camera2D
@onready var hud: Control = %HUD

const InputRouterScript := preload("res://scripts/systems/input_router.gd")
const SpatialGridScript := preload("res://scripts/systems/spatial_grid.gd")

var input_router: Node
var grid: RefCounted
var enemies: Array = []
var spawn_queue: Array = []
var spawn_ticks := 0
var wave_active := false
var combo_ticks := 0
var hitstop_ticks := 0
var shake := 0.0
var tick := 0

func _ready() -> void:
	input_router = InputRouterScript.new()
	grid = SpatialGridScript.new()
	add_child(input_router)
	EventBus.shake_requested.connect(_on_shake_requested)
	EventBus.hitstop_requested.connect(_on_hitstop_requested)
	GameState.start_run(Config.run_seed)
	player.reset(Config.WORLD_SIZE * 0.5)
	camera.global_position = player.global_position
	_next_wave()

func _physics_process(_delta: float) -> void:
	tick += 1
	if hitstop_ticks > 0:
		hitstop_ticks -= 1
		_update_camera_shake_only()
		return
	if GameState.state != GameState.RunState.PLAY:
		return
	var input_vector: Vector2 = input_router.movement_vector()
	var aim_world: Vector2 = input_router.aim_world_position(self, player.global_position, tick)
	player.physics_tick(input_vector, aim_world, player_bullets)
	grid.rebuild(enemies)
	_tick_spawning()
	_tick_bullets()
	_tick_enemies()
	_tick_player_touch_damage()
	_tick_combo()
	_check_wave_clear_or_death()
	_update_camera(aim_world)
	_update_hud()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Config.WORLD_SIZE), Color(0.082, 0.067, 0.047))
	var grid_step := 128.0
	var line_color := Color(1.0, 0.682, 0.259, 0.045)
	for x in range(0, int(Config.WORLD_SIZE.x) + 1, int(grid_step)):
		draw_line(Vector2(x, 0), Vector2(x, Config.WORLD_SIZE.y), line_color)
	for y in range(0, int(Config.WORLD_SIZE.y) + 1, int(grid_step)):
		draw_line(Vector2(0, y), Vector2(Config.WORLD_SIZE.x, y), line_color)
	draw_circle(Config.WORLD_SIZE * 0.5, 48.0, Color(1.0, 0.368, 0.169, 0.22))
	draw_arc(Config.WORLD_SIZE * 0.5, 54.0, 0.0, TAU, 48, Color(1.0, 0.682, 0.259, 0.45), 3.0)

func _next_wave() -> void:
	GameState.wave += 1
	spawn_queue.clear()
	var count: int = min(Config.WAVE_BASE_COUNT + floori(GameState.wave * Config.WAVE_COUNT_PER_WAVE), Config.WAVE_COUNT_CAP)
	for i in range(count):
		var roll := Config.rng.randf()
		if GameState.wave >= 2 and roll < 0.20:
			spawn_queue.append(SPITTER)
		elif GameState.wave >= 3 and roll < 0.34:
			spawn_queue.append(BRUTE)
		else:
			spawn_queue.append(CRAWLER)
	spawn_ticks = Config.SPAWN_INITIAL_DELAY_TICKS
	wave_active = true

func _tick_spawning() -> void:
	if spawn_queue.is_empty() or enemies.size() >= Config.PHASE1_ACTIVE_SPAWN_CAP or enemies.size() >= Config.ACTIVE_ENEMY_CAP:
		return
	spawn_ticks -= 1
	if spawn_ticks > 0:
		return
	var data: Resource = spawn_queue.pop_front()
	_spawn_enemy(data)
	spawn_ticks = Config.spawn_interval(GameState.wave)

func _spawn_enemy(data: Resource) -> void:
	var enemy: Node = EnemyScene.instantiate()
	add_child(enemy)
	var pos := _offscreen_spawn_position()
	var make_elite := Config.rng.randf() < Config.elite_chance(GameState.wave)
	enemy.setup(data, GameState.wave, pos, make_elite)
	enemies.append(enemy)

func _offscreen_spawn_position() -> Vector2:
	var view_rect := Rect2(camera.global_position - get_viewport_rect().size * 0.5, get_viewport_rect().size)
	var side := Config.randi_range(0, 3)
	var margin := Config.randf_range(60.0, 140.0)
	var pos := Vector2.ZERO
	if side == 0:
		pos = Vector2(view_rect.position.x - margin, Config.randf_range(view_rect.position.y, view_rect.end.y))
	elif side == 1:
		pos = Vector2(view_rect.end.x + margin, Config.randf_range(view_rect.position.y, view_rect.end.y))
	elif side == 2:
		pos = Vector2(Config.randf_range(view_rect.position.x, view_rect.end.x), view_rect.position.y - margin)
	else:
		pos = Vector2(Config.randf_range(view_rect.position.x, view_rect.end.x), view_rect.end.y + margin)
	pos.x = clampf(pos.x, 24.0, Config.WORLD_SIZE.x - 24.0)
	pos.y = clampf(pos.y, 24.0, Config.WORLD_SIZE.y - 24.0)
	return pos

func _tick_bullets() -> void:
	var bounds := Rect2(Vector2.ZERO, Config.WORLD_SIZE)
	var result: Dictionary = player_bullets.physics_tick(bounds, grid, enemies)
	for hit in result.enemy_hits:
		var enemy: Node = hit.enemy
		if is_instance_valid(enemy):
			enemy.apply_damage(hit.damage, hit.velocity)
	enemy_bullets.physics_tick(bounds, grid, enemies, player)

func _tick_enemies() -> void:
	for enemy in enemies:
		enemy.physics_tick(player, enemy_bullets)
	grid.rebuild(enemies)
	for enemy in enemies:
		var near: Array = grid.nearby(enemy.position, enemy.radius + 24.0)
		for other in near:
			if other == enemy:
				continue
			var rr: float = (enemy.radius + other.radius) * 0.8
			if enemy.position.distance_squared_to(other.position) < rr * rr:
				var away: Vector2 = (enemy.position - other.position).normalized()
				enemy.position += away * 0.5
	var i := enemies.size() - 1
	while i >= 0:
		var enemy: Node = enemies[i]
		if enemy.dead:
			_kill_enemy(i)
		i -= 1

func _tick_player_touch_damage() -> void:
	for enemy in enemies:
		if player.invulnerable_ticks > 0 or player.dashing_ticks > 0:
			return
		var rr: float = enemy.radius + player.radius
		if enemy.position.distance_squared_to(player.position) < rr * rr:
			player.apply_damage(enemy.damage, enemy, Config.PLAYER_HURT_IFRAME_TICKS)
			var away: Vector2 = (player.position - enemy.position).normalized()
			player.position += away * Config.PLAYER_KNOCKBACK
			return

func _kill_enemy(index: int) -> void:
	var enemy: Node = enemies[index]
	GameState.kills += 1
	GameState.set_combo(GameState.combo + 1)
	combo_ticks = Config.COMBO_DECAY_TICKS
	GameState.add_score(enemy.points)
	EventBus.enemy_killed.emit(enemy.data)
	EventBus.shake_requested.emit(Config.SHAKE_ELITE_KILL if enemy.elite else Config.SHAKE_KILL)
	enemies.remove_at(index)
	enemy.queue_free()

func _tick_combo() -> void:
	if combo_ticks > 0:
		combo_ticks -= 1
		if combo_ticks == 0:
			GameState.set_combo(0)

func _check_wave_clear_or_death() -> void:
	if player.hp <= 0.0:
		GameState.end_run(false)
	if wave_active and spawn_queue.is_empty() and enemies.is_empty():
		wave_active = false
		GameState.add_score(100 + GameState.wave * 20)
		EventBus.wave_cleared.emit(GameState.wave)
		_next_wave()

func _update_camera(aim_world: Vector2) -> void:
	if camera.has_method("physics_tick"):
		camera.aim_world = aim_world
		camera.physics_tick()
	_update_camera_shake_only()

func _update_camera_shake_only() -> void:
	if shake > 0.0:
		camera.offset = Vector2(Config.randf_range(-shake, shake), Config.randf_range(-shake, shake))
		shake *= Config.SHAKE_DECAY
		if shake < 0.3:
			shake = 0.0
	else:
		camera.offset = Vector2.ZERO

func _update_hud() -> void:
	if hud.has_method("set_values"):
		hud.set_values(player.hp, player.max_hp, player.dash_ready_ratio(), GameState.wave, spawn_queue.size() + enemies.size(), GameState.score, GameState.kills, GameState.combo)

func _on_shake_requested(strength: float) -> void:
	shake = max(shake, strength * Config.screen_shake_scale)

func _on_hitstop_requested(ticks_count: int) -> void:
	hitstop_ticks = max(hitstop_ticks, ticks_count)
