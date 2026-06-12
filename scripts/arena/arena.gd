extends Node2D

const EnemyScene := preload("res://scenes/enemies/enemy.tscn")
const CRAWLER := preload("res://data/enemies/crawler.tres")
const BRUTE := preload("res://data/enemies/brute.tres")
const SPITTER := preload("res://data/enemies/spitter.tres")
const SPLITTER := preload("res://data/enemies/splitter.tres")
const HOUND := preload("res://data/enemies/hound.tres")
const KILNMAW := preload("res://data/enemies/kilnmaw.tres")
const ARENA_LAYOUT := preload("res://data/arena_layout.tres")

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
var boss_telegraph_ticks := 0
var pending_boss_data: Resource
var pending_boss_pos := Vector2.ZERO
var wave_active := false
var combo_ticks := 0
var hitstop_ticks := 0
var shake := 0.0
var tick := 0
var scripted_input_enabled := false
var scripted_move := Vector2.ZERO
var scripted_aim := Vector2.ZERO
var scripted_dash := false
var objective_markers: Array[Vector2] = []
var debug_stats := {
	"waves_cleared": [],
	"spawned": {},
	"boss_patterns": {},
	"boss_spawned": false,
	"projectiles_blocked": 0,
	"lava_ticks": 0,
	"separation_skips": 0,
}

func _ready() -> void:
	input_router = InputRouterScript.new()
	grid = SpatialGridScript.new()
	add_child(input_router)
	EventBus.shake_requested.connect(_on_shake_requested)
	EventBus.hitstop_requested.connect(_on_hitstop_requested)
	_build_terrain()
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
	var input_vector: Vector2 = scripted_move if scripted_input_enabled else input_router.movement_vector()
	var aim_world: Vector2 = scripted_aim if scripted_input_enabled else input_router.aim_world_position(self, player.global_position, tick)
	player.physics_tick(input_vector, aim_world, player_bullets, scripted_dash)
	scripted_dash = false
	grid.rebuild(enemies)
	_tick_spawning()
	_tick_boss_telegraph()
	_tick_bullets()
	_tick_enemies()
	_tick_lava()
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
	for lava in ARENA_LAYOUT.lava_strips:
		draw_rect(lava, Color(1.0, 0.18, 0.06, 0.28))
		draw_rect(lava.grow(-8.0), Color(1.0, 0.55, 0.10, 0.18))
	for pillar in ARENA_LAYOUT.pillars:
		draw_circle(Vector2(pillar.x, pillar.y), pillar.z, Color(0.12, 0.095, 0.071))
		draw_arc(Vector2(pillar.x, pillar.y), pillar.z, 0.0, TAU, 48, Color(1.0, 0.682, 0.259, 0.22), 3.0)
	draw_circle(ARENA_LAYOUT.central_anvil_position, 48.0, Color(1.0, 0.368, 0.169, 0.22))
	draw_arc(ARENA_LAYOUT.central_anvil_position, 54.0, 0.0, TAU, 48, Color(1.0, 0.682, 0.259, 0.45), 3.0)
	draw_rect(Rect2(Vector2.ZERO, Config.WORLD_SIZE), Color(1.0, 0.682, 0.259, 0.28), false, 10.0)
	if boss_telegraph_ticks > 0:
		draw_arc(pending_boss_pos, 72.0 + sin(tick * 0.16) * 9.0, 0.0, TAU, 64, Color(1.0, 0.91, 0.77, 0.8), 4.0)

func _next_wave() -> void:
	GameState.wave += 1
	spawn_queue.clear()
	var count: int = min(Config.WAVE_BASE_COUNT + floori(GameState.wave * Config.WAVE_COUNT_PER_WAVE), Config.WAVE_COUNT_CAP)
	for i in range(count):
		var roll := Config.rng.randf()
		if GameState.wave >= 2 and roll < Config.WAVE_SPITTER_ROLL:
			spawn_queue.append(SPITTER)
		elif GameState.wave >= 3 and roll < Config.WAVE_BRUTE_ROLL:
			spawn_queue.append(BRUTE)
		elif GameState.wave >= 4 and roll < Config.WAVE_SPLITTER_ROLL:
			spawn_queue.append(SPLITTER)
		elif GameState.wave >= 6 and roll < Config.WAVE_HOUND_ROLL:
			spawn_queue.append(HOUND)
		else:
			spawn_queue.append(CRAWLER)
	if GameState.wave == 5:
		pending_boss_data = KILNMAW
		pending_boss_pos = KILNMAW.boss_fixed_spawn
		boss_telegraph_ticks = Config.BOSS_TELEGRAPH_TICKS
	spawn_ticks = Config.SPAWN_INITIAL_DELAY_TICKS
	wave_active = true

func _tick_spawning() -> void:
	if spawn_queue.is_empty() or enemies.size() >= Config.ACTIVE_ENEMY_CAP:
		return
	spawn_ticks -= 1
	if spawn_ticks > 0:
		return
	var data: Resource = spawn_queue.pop_front()
	_spawn_enemy(data)
	spawn_ticks = Config.spawn_interval(GameState.wave)

func _spawn_enemy(data: Resource, forced_pos := Vector2.INF, make_child := false) -> Node:
	var enemy: Node = EnemyScene.instantiate()
	add_child(enemy)
	var pos := forced_pos if forced_pos != Vector2.INF else _offscreen_spawn_position()
	var make_elite: bool = (Config.rng.randf() < Config.elite_chance(GameState.wave)) and not data.boss and not make_child
	enemy.setup(data, GameState.wave, pos, make_elite, make_child)
	if data.boss:
		debug_stats.boss_spawned = true
	var spawned: Dictionary = debug_stats.spawned
	spawned[data.id] = spawned.get(data.id, 0) + 1
	enemies.append(enemy)
	return enemy

func _tick_boss_telegraph() -> void:
	if boss_telegraph_ticks <= 0:
		return
	boss_telegraph_ticks -= 1
	queue_redraw()
	if boss_telegraph_ticks == 0 and pending_boss_data:
		_spawn_enemy(pending_boss_data, pending_boss_pos)
		pending_boss_data = null

func _offscreen_spawn_position() -> Vector2:
	var view_rect := _camera_rect()
	var margin := Config.randf_range(Config.SPAWN_OFFSCREEN_MIN, Config.SPAWN_OFFSCREEN_MAX)
	var world_rect := Rect2(Vector2.ZERO, ARENA_LAYOUT.world_size)
	var candidates: Array[Vector2] = [
		Vector2(view_rect.position.x - margin, Config.randf_range(view_rect.position.y, view_rect.end.y)),
		Vector2(view_rect.end.x + margin, Config.randf_range(view_rect.position.y, view_rect.end.y)),
		Vector2(Config.randf_range(view_rect.position.x, view_rect.end.x), view_rect.position.y - margin),
		Vector2(Config.randf_range(view_rect.position.x, view_rect.end.x), view_rect.end.y + margin),
	]
	var valid: Array[Vector2] = []
	for candidate in candidates:
		if world_rect.has_point(candidate) and not view_rect.has_point(candidate):
			valid.append(candidate)
	if valid.is_empty():
		var fallback := ARENA_LAYOUT.central_anvil_position
		var away := (fallback - camera.global_position).normalized()
		return (camera.global_position + away * (max(get_viewport_rect().size.x, get_viewport_rect().size.y) * 0.65)).clamp(Vector2(24, 24), ARENA_LAYOUT.world_size - Vector2(24, 24))
	return valid[Config.randi_range(0, valid.size() - 1)]

func _tick_bullets() -> void:
	var bounds := Rect2(Vector2.ZERO, Config.WORLD_SIZE)
	var before_player: int = player_bullets.active_count
	var before_enemy: int = enemy_bullets.active_count
	var result: Dictionary = player_bullets.physics_tick(bounds, grid, enemies, null, self)
	for hit in result.enemy_hits:
		var enemy: Node = hit.enemy
		if is_instance_valid(enemy):
			enemy.apply_damage(hit.damage, hit.velocity)
	enemy_bullets.physics_tick(bounds, grid, enemies, player, self)
	debug_stats.projectiles_blocked += max(0, before_player - player_bullets.active_count - result.enemy_hits.size())
	debug_stats.projectiles_blocked += max(0, before_enemy - enemy_bullets.active_count)

func _tick_enemies() -> void:
	for enemy in enemies:
		var before_pattern: int = enemy.boss_pattern_index
		enemy.physics_tick(player, enemy_bullets)
		if enemy.data and enemy.data.boss and enemy.boss_pattern_index != before_pattern:
			var patterns: Dictionary = debug_stats.boss_patterns
			var pattern_index: int = (enemy.boss_pattern_index - 1) % enemy.data.boss_patterns.size()
			var pattern: StringName = enemy.data.boss_patterns[pattern_index]
			patterns[pattern] = patterns.get(pattern, 0) + 1
		_resolve_enemy_terrain(enemy)
	grid.rebuild(enemies)
	var view_radius: float = max(get_viewport_rect().size.x, get_viewport_rect().size.y) * Config.LOD_SEPARATION_VIEWPORT_MULT
	for enemy in enemies:
		if enemy.position.distance_to(camera.global_position) > view_radius:
			enemy.skipped_separation = true
			debug_stats.separation_skips += 1
			continue
		enemy.skipped_separation = false
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

func _tick_lava() -> void:
	var player_in_lava := false
	for lava in ARENA_LAYOUT.lava_strips:
		if lava.has_point(player.position):
			player_in_lava = true
			break
	if player_in_lava and player.dashing_ticks <= 0:
		if tick % Config.LAVA_DAMAGE_INTERVAL_TICKS == 0:
			player.apply_damage(Config.LAVA_DAMAGE, "lava", Config.LAVA_DAMAGE_INTERVAL_TICKS)
			debug_stats.lava_ticks += 1
	for enemy in enemies:
		for lava in ARENA_LAYOUT.lava_strips:
			if lava.has_point(enemy.position):
				enemy.apply_lava_damage()
				debug_stats.lava_ticks += 1
				break

func _kill_enemy(index: int) -> void:
	var enemy: Node = enemies[index]
	GameState.kills += 1
	GameState.set_combo(GameState.combo + 1)
	combo_ticks = Config.COMBO_DECAY_TICKS
	GameState.add_score(enemy.points)
	EventBus.enemy_killed.emit(enemy.data)
	EventBus.shake_requested.emit(Config.SHAKE_ELITE_KILL if enemy.elite else Config.SHAKE_KILL)
	if enemy.data.split_child_count > 0 and not enemy.child:
		for i in range(enemy.data.split_child_count):
			var angle := TAU * float(i) / float(enemy.data.split_child_count)
			_spawn_enemy(CRAWLER, enemy.position + Vector2(cos(angle), sin(angle)) * Config.SPLITTER_CHILD_SPACING, true)
	if enemy.data.boss:
		EventBus.hitstop_requested.emit(Config.HITSTOP_BOSS_KILL_TICKS)
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
		debug_stats.waves_cleared.append(GameState.wave)
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
	if hud.has_method("set_world_state"):
		hud.set_world_state(player.position, camera.global_position, enemies, ARENA_LAYOUT.world_size, pending_boss_pos if boss_telegraph_ticks > 0 else Vector2.INF, objective_markers)

func _on_shake_requested(strength: float) -> void:
	shake = max(shake, strength * Config.screen_shake_scale)

func _on_hitstop_requested(ticks_count: int) -> void:
	hitstop_ticks = max(hitstop_ticks, ticks_count)

func set_scripted_input(move_vector: Vector2, aim_position: Vector2, dash_pressed := false) -> void:
	scripted_input_enabled = true
	scripted_move = move_vector
	scripted_aim = aim_position
	scripted_dash = dash_pressed

func clear_scripted_input() -> void:
	scripted_input_enabled = false
	scripted_move = Vector2.ZERO
	scripted_dash = false

func projectile_blocked(pos: Vector2) -> bool:
	for pillar in ARENA_LAYOUT.pillars:
		if pos.distance_squared_to(Vector2(pillar.x, pillar.y)) <= pillar.z * pillar.z:
			return true
	return false

func _resolve_enemy_terrain(enemy: Node) -> void:
	for pillar in ARENA_LAYOUT.pillars:
		var center := Vector2(pillar.x, pillar.y)
		var min_dist: float = pillar.z + enemy.radius
		var delta: Vector2 = enemy.position - center
		var dist: float = delta.length()
		if dist < min_dist:
			enemy.position = center + (delta.normalized() if dist > 0.001 else Vector2.RIGHT) * min_dist
	enemy.position.x = clampf(enemy.position.x, enemy.radius, ARENA_LAYOUT.world_size.x - enemy.radius)
	enemy.position.y = clampf(enemy.position.y, enemy.radius, ARENA_LAYOUT.world_size.y - enemy.radius)

func _build_terrain() -> void:
	var terrain_root := Node2D.new()
	terrain_root.name = "Terrain"
	add_child(terrain_root)
	for pillar in ARENA_LAYOUT.pillars:
		var body := StaticBody2D.new()
		body.position = Vector2(pillar.x, pillar.y)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = pillar.z
		shape.shape = circle
		body.add_child(shape)
		terrain_root.add_child(body)
	var t := ARENA_LAYOUT.boundary_thickness
	var world := ARENA_LAYOUT.world_size
	_add_wall(terrain_root, Vector2(world.x * 0.5, -t * 0.5), Vector2(world.x + t * 2.0, t))
	_add_wall(terrain_root, Vector2(world.x * 0.5, world.y + t * 0.5), Vector2(world.x + t * 2.0, t))
	_add_wall(terrain_root, Vector2(-t * 0.5, world.y * 0.5), Vector2(t, world.y + t * 2.0))
	_add_wall(terrain_root, Vector2(world.x + t * 0.5, world.y * 0.5), Vector2(t, world.y + t * 2.0))

func _add_wall(parent: Node, pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	parent.add_child(body)

func _camera_rect() -> Rect2:
	var viewport_size := get_viewport_rect().size / camera.zoom
	return Rect2(camera.global_position - viewport_size * 0.5, viewport_size)
