extends Node2D

const EnemyScene := preload("res://scenes/enemies/enemy.tscn")
const CRAWLER := preload("res://data/enemies/crawler.tres")
const BRUTE := preload("res://data/enemies/brute.tres")
const SPITTER := preload("res://data/enemies/spitter.tres")
const SPLITTER := preload("res://data/enemies/splitter.tres")
const HOUND := preload("res://data/enemies/hound.tres")
const KILNMAW := preload("res://data/enemies/kilnmaw.tres")
const CHOIR := preload("res://data/enemies/choir.tres")
const AURUM := preload("res://data/enemies/aurum.tres")
const AURUM_REKINDLED := preload("res://data/enemies/aurum_rekindled.tres")
const ARENA_LAYOUT := preload("res://data/arena_layout.tres")
const FORGEHAMMER := preload("res://data/weapons/forgehammer.tres")
const SLAG_LANCE := preload("res://data/weapons/slag_lance.tres")
const EMBER_MAW := preload("res://data/weapons/ember_maw.tres")
const TEMPERINGS := [
	preload("res://data/temperings/hotter_steel.tres"),
	preload("res://data/temperings/twin_hammers.tres"),
	preload("res://data/temperings/bellows.tres"),
	preload("res://data/temperings/quenched_legs.tres"),
	preload("res://data/temperings/reforged_heart.tres"),
	preload("res://data/temperings/piercing_slag.tres"),
	preload("res://data/temperings/coiled_spring.tres"),
	preload("res://data/temperings/ember_leech.tres"),
	preload("res://data/temperings/nova_dash.tres"),
	preload("res://data/temperings/slow_burn.tres"),
	preload("res://data/temperings/killing_edge.tres"),
	preload("res://data/temperings/branding_iron.tres"),
	preload("res://data/temperings/chain_spark.tres"),
	preload("res://data/temperings/orbiting_anvil.tres"),
	preload("res://data/temperings/forgehammer_sharpen.tres"),
	preload("res://data/temperings/slag_lance_sharpen.tres"),
	preload("res://data/temperings/ember_maw_sharpen.tres"),
	preload("res://data/temperings/thorns.tres"),
	preload("res://data/temperings/magnet_coil.tres"),
	preload("res://data/temperings/second_wind.tres"),
]
const SYNERGIES := [
	preload("res://data/synergies/detonating_brand.tres"),
	preload("res://data/synergies/arc_steel.tres"),
	preload("res://data/synergies/bulwark_orbit.tres"),
	preload("res://data/synergies/blast_furnace.tres"),
	preload("res://data/synergies/overclocked_bellows.tres"),
]
const EVOLUTIONS := [
	preload("res://data/evolutions/meteor_volley.tres"),
	preload("res://data/evolutions/railspike.tres"),
	preload("res://data/evolutions/crucible_breath.tres"),
]
const OBJ_EMBER_VEIN := preload("res://data/objectives/ember_vein.tres")
const OBJ_BRAZIERS := preload("res://data/objectives/braziers.tres")
const OBJ_ELITE_BOUNTY := preload("res://data/objectives/elite_bounty.tres")
const OBJ_ANVIL_DEFENSE := preload("res://data/objectives/anvil_defense.tres")

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
var current_weapon: Resource = FORGEHAMMER
var weapon_fire_ticks := 0
var tempering_levels: Dictionary = {}
var active_synergies: Dictionary = {}
var active_evolutions: Dictionary = {}
var drops: Array = []
var chests: Array = []
var current_objective: Dictionary = {}
var objective_failure_log: Array[StringName] = []
var ember_count := 0
var offered_cards: Array = []
var upgrade_panel_visible := false
var pending_next_wave := false
var pending_upgrade_reason: StringName = &""
var chest_reveal_ticks := 0
var chest_reveal_contents: Array = []
var standing_still_ticks := 0
var anvil_hp := 0.0
var anvil_bonus_choices := 0
var anvil_target: Node2D
var nova_dash_armed := false
var endless_mode := false
var run_finalized := false
var debug_stats := {
	"waves_cleared": [],
	"spawned": {},
	"boss_patterns": {},
	"boss_spawned": false,
	"projectiles_blocked": 0,
	"lava_ticks": 0,
	"separation_skips": 0,
	"objectives_completed": [],
	"objectives_failed": [],
	"chests_opened": 0,
	"evolutions": {},
	"synergies": {},
	"weapons_tested": {},
	"embers": 0,
	"hearts_collected": 0,
	"boss_phases": {},
	"victory": false,
	"recap": {},
	"endless_entered": false,
}

func _ready() -> void:
	Engine.time_scale = 1.0
	input_router = InputRouterScript.new()
	grid = SpatialGridScript.new()
	add_child(input_router)
	EventBus.shake_requested.connect(_on_shake_requested)
	EventBus.hitstop_requested.connect(_on_hitstop_requested)
	EventBus.boss_phase.connect(_on_boss_phase)
	_build_terrain()
	anvil_target = Node2D.new()
	anvil_target.position = ARENA_LAYOUT.central_anvil_position
	add_child(anvil_target)
	GameState.start_run(Config.run_seed)
	player.reset(Config.WORLD_SIZE * 0.5)
	select_weapon(&"forgehammer")
	camera.global_position = player.global_position
	_next_wave()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _physics_process(_delta: float) -> void:
	tick += 1
	if hitstop_ticks > 0:
		hitstop_ticks -= 1
		_update_camera_shake_only()
		return
	if GameState.state != GameState.RunState.PLAY:
		if GameState.state == GameState.RunState.UPGRADE:
			_tick_chest_reveal()
			_update_hud()
		return
	var input_vector: Vector2 = scripted_move if scripted_input_enabled else input_router.movement_vector()
	var aim_world: Vector2 = scripted_aim if scripted_input_enabled else input_router.aim_world_position(self, player.global_position, tick)
	player.physics_tick(input_vector, aim_world, player_bullets, scripted_dash, true)
	scripted_dash = false
	if player.dashing_ticks > 0 and player.nova:
		nova_dash_armed = true
	if nova_dash_armed and player.dashing_ticks <= 0:
		nova_dash_armed = false
		_explode_enemy(player.position, player.damage * player.damage_mult * Config.BLAST_FURNACE_DAMAGE_FACTOR, Config.BLAST_FURNACE_RADIUS)
		if active_synergies.has(&"blast_furnace"):
			for enemy in enemies:
				if enemy.position.distance_to(player.position) <= Config.BLAST_FURNACE_RADIUS + enemy.radius:
					enemy.apply_burn(120, player.damage * Config.BURN_DAMAGE_FACTOR)
	_tick_player_weapon(input_vector, aim_world)
	grid.rebuild(enemies)
	_tick_spawning()
	_tick_boss_telegraph()
	_tick_bullets()
	_tick_enemies()
	_tick_lava()
	_tick_orbits()
	_tick_drops()
	_tick_chests()
	_tick_chest_reveal()
	_tick_objective()
	_tick_player_touch_damage()
	_tick_regen()
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
	if anvil_hp > 0.0:
		draw_arc(ARENA_LAYOUT.central_anvil_position, 72.0, 0.0, TAU, 48, Color(0.48, 0.88, 0.52, 0.55), 4.0)
	draw_rect(Rect2(Vector2.ZERO, Config.WORLD_SIZE), Color(1.0, 0.682, 0.259, 0.28), false, 10.0)
	if boss_telegraph_ticks > 0:
		draw_arc(pending_boss_pos, 72.0 + sin(tick * 0.16) * 9.0, 0.0, TAU, 64, Color(1.0, 0.91, 0.77, 0.8), 4.0)
	for marker in objective_markers:
		draw_arc(marker, Config.OBJECTIVE_MARKER_RADIUS, 0.0, TAU, 48, Color(0.48, 0.88, 0.52, 0.65), 3.0)
	for drop in drops:
		var col := Color(0.49, 0.88, 0.52) if drop.type == &"heart" else Color(1.0, 0.682, 0.259)
		draw_circle(drop.position, 8.0, col)
	for chest in chests:
		draw_rect(Rect2(chest.position - Vector2(12, 9), Vector2(24, 18)), Color(1.0, 0.682, 0.259, 0.9))

func _next_wave() -> void:
	GameState.wave += 1
	spawn_queue.clear()
	_start_objective_for_wave(GameState.wave)
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
	var boss_data := _boss_for_wave(GameState.wave)
	if boss_data:
		pending_boss_data = boss_data
		pending_boss_pos = boss_data.boss_fixed_spawn
		boss_telegraph_ticks = Config.BOSS_TELEGRAPH_TICKS
	spawn_ticks = Config.SPAWN_INITIAL_DELAY_TICKS
	wave_active = true

func _boss_for_wave(wave: int) -> Resource:
	if wave == 5:
		return KILNMAW
	if wave == 10:
		return CHOIR
	if wave == 15:
		return AURUM
	if wave == 20:
		return AURUM_REKINDLED
	if endless_mode and wave > 20 and wave % 5 == 0:
		var cycle := [KILNMAW, CHOIR, AURUM, AURUM_REKINDLED]
		return cycle[(wave / 5) % cycle.size()]
	return null

func _tick_player_weapon(input_vector: Vector2, aim_world: Vector2) -> void:
	if input_vector.length_squared() < 0.01:
		standing_still_ticks += 1
	else:
		standing_still_ticks = 0
	weapon_fire_ticks -= 1
	var effective_rate: int = _effective_weapon_rate()
	if weapon_fire_ticks > 0:
		return
	weapon_fire_ticks = effective_rate
	var dir: Vector2 = (aim_world - player.position).normalized()
	if dir.length_squared() <= 0.001:
		dir = Vector2.RIGHT
	var weapon_id: StringName = current_weapon.id
	debug_stats.weapons_tested[weapon_id] = debug_stats.weapons_tested.get(weapon_id, 0) + 1
	if current_weapon.pattern == "projectile":
		_fire_projectile_weapon(dir)
	elif current_weapon.pattern == "cone":
		_fire_cone_weapon(dir)
	elif current_weapon.pattern == "beam":
		_fire_beam_weapon(dir)
	elif current_weapon.pattern == "meteor":
		_fire_meteor_weapon(aim_world)
	EventBus.shake_requested.emit(Config.SHAKE_SHOT)

func _effective_weapon_rate() -> int:
	var mult: float = player.fire_rate_mult
	if active_synergies.has(&"overclocked_bellows") and standing_still_ticks >= Config.OVERCLOCK_STILL_TICKS:
		mult *= Config.OVERCLOCK_FIRE_RATE_MULT
	var rate := int(round(float(current_weapon.fire_rate_ticks) * mult))
	return max(3, rate)

func _weapon_damage() -> float:
	return current_weapon.damage * player.damage_mult

func _fire_projectile_weapon(dir: Vector2) -> void:
	var shots: int = current_weapon.shots + player.weapon_shots_bonus
	var spread: float = current_weapon.spread_radians
	var base_damage: float = _weapon_damage()
	var total_pierce: int = current_weapon.pierce + player.pierce_bonus + (1 if active_synergies.has(&"arc_steel") else 0)
	for i in range(max(1, shots)):
		var off: float = (float(i) - (float(max(1, shots)) - 1.0) * 0.5) * spread
		var d: Vector2 = dir.rotated(off)
		player_bullets.spawn(player.position + d * 14.0, d * current_weapon.projectile_speed, base_damage, current_weapon.projectile_life_ticks, current_weapon.projectile_radius, total_pierce)

func _fire_cone_weapon(dir: Vector2) -> void:
	for enemy in enemies:
		var to_enemy: Vector2 = enemy.position - player.position
		if to_enemy.length() > current_weapon.cone_range + enemy.radius:
			continue
		if abs(dir.angle_to(to_enemy.normalized())) <= current_weapon.cone_angle_radians * 0.5:
			enemy.apply_damage(_weapon_damage(), dir * 3.0)
			if current_weapon.burn_ticks > 0 or player.burn:
				enemy.apply_burn(max(current_weapon.burn_ticks, 120), _weapon_damage() * Config.BURN_DAMAGE_FACTOR)

func _fire_beam_weapon(dir: Vector2) -> void:
	for enemy in enemies:
		var rel: Vector2 = enemy.position - player.position
		if rel.dot(dir) < 0:
			continue
		var side_dist: float = abs(rel.cross(dir))
		if side_dist <= Config.RAILSPIKE_WIDTH + enemy.radius:
			enemy.apply_damage(_weapon_damage(), dir * 6.0)

func _fire_meteor_weapon(target_pos: Vector2) -> void:
	for enemy in enemies:
		if enemy.position.distance_to(target_pos) <= Config.METEOR_RADIUS + enemy.radius:
			enemy.apply_damage(_weapon_damage(), Vector2.ZERO)

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
			var hit_damage: float = hit.damage
			if Config.rng.randf() < player.crit:
				hit_damage *= 2.5
			enemy.apply_damage(hit_damage, hit.velocity)
			if player.burn:
				enemy.apply_burn(120, hit_damage * Config.BURN_DAMAGE_FACTOR)
			if player.ricochet_bonus > 0 or active_synergies.has(&"arc_steel"):
				_arc_to_nearby_enemy(enemy, hit_damage * 0.65)
	enemy_bullets.physics_tick(bounds, grid, enemies, player, self)
	if active_synergies.has(&"bulwark_orbit") and player.orbs > 0:
		_eat_enemy_projectiles()
	debug_stats.projectiles_blocked += max(0, before_player - player_bullets.active_count - result.enemy_hits.size())
	debug_stats.projectiles_blocked += max(0, before_enemy - enemy_bullets.active_count)

func _arc_to_nearby_enemy(source: Node, amount: float) -> void:
	var best: Node = null
	var best_dist := 300.0 * 300.0
	for enemy in enemies:
		if enemy == source or enemy.dead:
			continue
		var dist: float = source.position.distance_squared_to(enemy.position)
		if dist < best_dist:
			best_dist = dist
			best = enemy
	if best:
		best.apply_damage(amount, Vector2.ZERO)

func _eat_enemy_projectiles() -> void:
	var i: int = enemy_bullets.active_count - 1
	while i >= 0:
		var eaten := false
		for k in range(player.orbs):
			var angle: float = player.orb_angle + TAU * float(k) / float(max(1, player.orbs))
			var orb_pos: Vector2 = player.position + Vector2(cos(angle), sin(angle)) * 58.0
			if enemy_bullets.positions[i].distance_to(orb_pos) < 24.0:
				eaten = true
				break
		if eaten:
			enemy_bullets._remove_at(i)
		i -= 1

func _tick_enemies() -> void:
	for enemy in enemies:
		var before_pattern: int = enemy.boss_pattern_index
		var target: Node2D = player
		if _objective_type() == "anvil_defense" and enemy.position.distance_to(ARENA_LAYOUT.central_anvil_position) < Config.ANVIL_THREAT_RADIUS:
			target = anvil_target
		enemy.physics_tick(target, enemy_bullets)
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
			if player.thorns > 0.0:
				enemy.apply_damage(enemy.damage * player.thorns, Vector2.ZERO)
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
	if player.lifesteal > 0.0:
		player.hp = min(player.max_hp, player.hp + player.lifesteal)
	if active_synergies.has(&"blast_furnace"):
		player.dash_cooldown_ticks = max(0, player.dash_cooldown_ticks - int(round(float(player.feel.dash_cooldown_ticks) * Config.BLAST_FURNACE_DASH_REFUND)))
	if active_synergies.has(&"detonating_brand") and enemy.burn_ticks > 0:
		_explode_enemy(enemy.position, player.damage * Config.DETONATING_BRAND_DAMAGE_FACTOR, Config.DETONATING_BRAND_RADIUS)
	_roll_drop(enemy)
	if enemy.data.split_child_count > 0 and not enemy.child:
		for i in range(enemy.data.split_child_count):
			var angle := TAU * float(i) / float(enemy.data.split_child_count)
			_spawn_enemy(CRAWLER, enemy.position + Vector2(cos(angle), sin(angle)) * Config.SPLITTER_CHILD_SPACING, true)
	if enemy.data.boss:
		EventBus.hitstop_requested.emit(Config.HITSTOP_BOSS_KILL_TICKS)
		_spawn_chest(enemy.position, true)
		if enemy.data.boss_reward_embers > 0:
			ember_count += int(enemy.data.boss_reward_embers)
			debug_stats.embers = ember_count
		if enemy.data.victory_boss and not endless_mode:
			_finalize_run(true)
		elif enemy.data.victory_boss and endless_mode:
			debug_stats.endless_entered = true
	if _objective_type() == "elite_bounty" and current_objective.get("target", null) == enemy:
		GameState.add_score(current_objective.data.score_reward)
		_spawn_chest(enemy.position, true)
		_complete_objective()
	enemies.remove_at(index)
	enemy.queue_free()

func _roll_drop(enemy: Node) -> void:
	var heart_chance := Config.HEART_DROP_CHANCE
	if enemy.elite:
		heart_chance = Config.ELITE_HEART_DROP_CHANCE
	if Config.rng.randf() < heart_chance:
		drops.append({"type": &"heart", "position": enemy.position, "value": Config.DROP_HEART_HEAL})
	elif Config.rng.randf() < Config.EMBER_DROP_CHANCE:
		drops.append({"type": &"ember", "position": enemy.position, "value": 1})

func _spawn_chest(pos: Vector2, guaranteed_evolution := false) -> void:
	chests.append({"position": pos, "guaranteed_evolution": guaranteed_evolution})

func _tick_drops() -> void:
	var i := drops.size() - 1
	while i >= 0:
		var drop: Dictionary = drops[i]
		var pos: Vector2 = drop.position
		var dist := pos.distance_to(player.position)
		if dist < Config.DROP_MAGNET_RADIUS * player.magnet_mult:
			pos = pos.move_toward(player.position, Config.DROP_MAGNET_PULL * player.magnet_mult)
			drop.position = pos
			drops[i] = drop
		if dist < Config.DROP_PICKUP_RADIUS:
			if drop.type == &"heart":
				player.hp = min(player.max_hp, player.hp + float(drop.value))
				debug_stats.hearts_collected += 1
			else:
				ember_count += int(drop.value)
				debug_stats.embers = ember_count
				GameState.add_score(Config.DROP_EMBER_SCORE)
			drops.remove_at(i)
		i -= 1

func _tick_chests() -> void:
	var i := chests.size() - 1
	while i >= 0:
		var chest: Dictionary = chests[i]
		if chest.position.distance_to(player.position) <= Config.CHEST_RADIUS + player.radius:
			_open_chest(chest)
			chests.remove_at(i)
		i -= 1

func _open_chest(_chest: Dictionary) -> void:
	debug_stats.chests_opened += 1
	var evolved := false
	chest_reveal_ticks = Config.CHEST_REVEAL_TICKS
	Engine.time_scale = Config.CHEST_REVEAL_SLOWMO_SCALE
	chest_reveal_contents.clear()
	for evolution in EVOLUTIONS:
		if _can_evolve(evolution):
			current_weapon = evolution.evolved_weapon
			active_evolutions[evolution.id] = true
			debug_stats.evolutions[evolution.id] = debug_stats.evolutions.get(evolution.id, 0) + 1
			EventBus.chest_opened.emit([evolution.id])
			chest_reveal_contents = [evolution.display_name]
			evolved = true
			break
	if not evolved:
		offer_upgrades(Config.UPGRADE_PICK_COUNT, &"chest")

func _tick_chest_reveal() -> void:
	if chest_reveal_ticks <= 0:
		return
	chest_reveal_ticks -= 1
	if chest_reveal_ticks <= 0:
		chest_reveal_contents.clear()
		Engine.time_scale = 1.0

func _can_evolve(evolution: Resource) -> bool:
	if current_weapon.id != evolution.base_weapon:
		return false
	for req_id in evolution.requirements.keys():
		if get_tempering_level(req_id) < int(evolution.requirements[req_id]):
			return false
	return true

func _explode_enemy(pos: Vector2, amount: float, radius_value: float) -> void:
	for enemy in enemies:
		if enemy.position.distance_to(pos) <= radius_value + enemy.radius:
			enemy.apply_damage(amount, Vector2.ZERO)

func _tick_orbits() -> void:
	if player.orbs <= 0:
		return
	player.orb_angle += 0.055
	for k in range(player.orbs):
		var angle: float = player.orb_angle + TAU * float(k) / float(player.orbs)
		var orb_pos: Vector2 = player.position + Vector2(cos(angle), sin(angle)) * 58.0
		for enemy in enemies:
			if enemy.position.distance_to(orb_pos) <= enemy.radius + 10.0:
				enemy.apply_damage(player.damage * player.damage_mult * 0.9, Vector2(cos(angle), sin(angle)) * 6.0)

func _tick_regen() -> void:
	if player.regen > 0.0 and tick % 120 == 0:
		player.hp = min(player.max_hp, player.hp + player.regen)

func _start_objective_for_wave(wave: int) -> void:
	objective_markers.clear()
	current_objective.clear()
	anvil_hp = 0.0
	anvil_bonus_choices = 0
	if wave in [7, 13, 19]:
		_start_objective(OBJ_ANVIL_DEFENSE)
	else:
		var slot: StringName = Config.OBJECTIVE_PATTERN[(wave - 1) % Config.OBJECTIVE_PATTERN.size()]
		if slot == &"none":
			current_objective = {"data": null, "done": true, "failed": false, "progress": 0, "markers": [], "lit": {}, "touched": false, "timer": 0, "none": true}
		elif slot == &"ember_vein":
			_start_objective(OBJ_EMBER_VEIN)
		elif slot == &"braziers":
			_start_objective(OBJ_BRAZIERS)
		elif slot == &"elite_bounty":
			_start_objective(OBJ_ELITE_BOUNTY)

func _start_objective(data: Resource) -> void:
	current_objective = {"data": data, "done": false, "failed": false, "progress": 0, "markers": [], "lit": {}, "touched": false, "timer": data.duration_ticks}
	if data.objective_type == "ember_vein":
		var marker := _far_objective_position()
		current_objective.markers = [marker]
		objective_markers = [marker]
	elif data.objective_type == "braziers":
		var markers: Array[Vector2] = []
		for i in range(data.marker_count):
			markers.append(ARENA_LAYOUT.central_anvil_position + Vector2(cos(TAU * float(i) / float(data.marker_count)), sin(TAU * float(i) / float(data.marker_count))) * 520.0)
		current_objective.markers = markers
		objective_markers = markers
	elif data.objective_type == "elite_bounty":
		var target := _spawn_enemy(BRUTE, _far_objective_position())
		target.elite = true
		target.hp *= Config.ELITE_HP_MULT
		target.max_hp = target.hp
		current_objective.target = target
		objective_markers = [target.position]
	elif data.objective_type == "anvil_defense":
		anvil_hp = Config.ANVIL_DEFENSE_START_HP + Config.ANVIL_DEFENSE_HP_PER_WAVE * GameState.wave
		objective_markers = [ARENA_LAYOUT.central_anvil_position]

func _tick_objective() -> void:
	if current_objective.is_empty() or current_objective.get("done", false) or current_objective.get("failed", false):
		return
	var data: Resource = current_objective.data
	if data.objective_type == "ember_vein":
		_tick_ember_vein_objective(data)
	elif data.objective_type == "braziers":
		_tick_braziers_objective(data)
	elif data.objective_type == "elite_bounty":
		_tick_bounty_objective(data)
	elif data.objective_type == "anvil_defense":
		_tick_anvil_objective()

func _tick_ember_vein_objective(data: Resource) -> void:
	var marker: Vector2 = current_objective.markers[0]
	if player.position.distance_to(marker) <= Config.OBJECTIVE_MARKER_RADIUS:
		if not current_objective.touched:
			current_objective.touched = true
			for i in range(Config.OBJECTIVE_VEIN_ERUPT_COUNT):
				_spawn_enemy(CRAWLER, marker + Vector2(cos(TAU * float(i) / Config.OBJECTIVE_VEIN_ERUPT_COUNT), sin(TAU * float(i) / Config.OBJECTIVE_VEIN_ERUPT_COUNT)) * 50.0)
		current_objective.progress += 1
	if int(current_objective.progress) >= data.channel_ticks:
		player.hp = min(player.max_hp, player.hp + data.heart_reward)
		ember_count += data.ember_reward
		debug_stats.embers = ember_count
		GameState.add_score(data.score_reward)
		_complete_objective()

func _tick_braziers_objective(data: Resource) -> void:
	var markers: Array = current_objective.markers
	for i in range(markers.size()):
		if current_objective.lit.has(i):
			continue
		if player.position.distance_to(markers[i]) <= Config.OBJECTIVE_MARKER_RADIUS:
			current_objective.progress = int(current_objective.get("progress", 0)) + 1
			if int(current_objective.progress) >= data.channel_ticks:
				current_objective.lit[i] = true
				current_objective.progress = 0
	if current_objective.lit.size() >= markers.size():
		current_objective.bonus_tempering = Config.OBJECTIVE_BRAZIER_BONUS_CHOICES
		_complete_objective()

func _tick_bounty_objective(_data: Resource) -> void:
	current_objective.timer = int(current_objective.timer) - 1
	if not is_instance_valid(current_objective.get("target", null)):
		_complete_objective()
	elif int(current_objective.timer) <= 0:
		_fail_objective()

func _tick_anvil_objective() -> void:
	for enemy in enemies:
		if enemy.position.distance_to(ARENA_LAYOUT.central_anvil_position) <= enemy.radius + 56.0:
			anvil_hp -= enemy.damage * 0.025
	if anvil_hp <= 0.0:
		_fail_objective()

func _complete_objective() -> void:
	current_objective.done = true
	var id: StringName = current_objective.data.id
	debug_stats.objectives_completed.append(id)
	EventBus.objective_done.emit(id)
	if id == &"anvil_defense":
		anvil_bonus_choices = 1
	objective_markers.clear()

func _fail_objective() -> void:
	current_objective.failed = true
	var id: StringName = current_objective.data.id
	objective_failure_log.append(id)
	debug_stats.objectives_failed.append(id)
	objective_markers.clear()

func _objective_type() -> String:
	if current_objective.is_empty() or current_objective.get("none", false):
		return ""
	return String(current_objective.data.objective_type)

func _objective_status_text() -> String:
	if current_objective.is_empty() or current_objective.get("none", false):
		return "NO OBJECTIVE"
	if current_objective.get("done", false):
		return "OBJECTIVE DONE"
	if current_objective.get("failed", false):
		return "OBJECTIVE FAILED"
	return current_objective.data.display_name

func _far_objective_position() -> Vector2:
	var angle := Config.randf_range(0.0, TAU)
	var pos := ARENA_LAYOUT.central_anvil_position + Vector2(cos(angle), sin(angle)) * 820.0
	return pos.clamp(Vector2(120, 120), ARENA_LAYOUT.world_size - Vector2(120, 120))

func get_tempering_level(id: StringName) -> int:
	return int(tempering_levels.get(id, 0))

func apply_tempering(id: StringName) -> void:
	var data := _tempering_by_id(id)
	if data == null:
		return
	var next_level := get_tempering_level(id) + 1
	tempering_levels[id] = min(next_level, data.max_level)
	_apply_tempering_effect(id)
	_update_synergies()

func _apply_tempering_effect(id: StringName) -> void:
	match id:
		&"hotter_steel":
			player.damage_mult *= 1.30
		&"twin_hammers":
			player.weapon_shots_bonus += 1
			player.damage_mult *= 0.92
		&"bellows":
			player.fire_rate_mult *= 0.78
		&"quenched_legs":
			player.feel.speed *= 1.15
		&"reforged_heart":
			player.max_hp += 30.0
			player.hp = player.max_hp
		&"piercing_slag":
			player.pierce_bonus += 1
		&"coiled_spring":
			player.feel.dash_cooldown_ticks = max(28, int(round(float(player.feel.dash_cooldown_ticks) * 0.65)))
		&"ember_leech":
			player.lifesteal += 1.0
		&"nova_dash":
			player.nova = true
		&"slow_burn":
			player.regen += 1.0
		&"killing_edge":
			player.crit += 0.15
		&"branding_iron":
			player.burn = true
		&"chain_spark":
			player.ricochet_bonus += 1
		&"orbiting_anvil":
			player.orbs += 1
		&"thorns":
			player.thorns += 0.2
		&"magnet_coil":
			player.magnet_mult *= 1.35
		&"second_wind":
			player.second_wind_ready = true

func _update_synergies() -> void:
	for synergy in SYNERGIES:
		if active_synergies.has(synergy.id):
			continue
		var ok := true
		for req_id in synergy.requirements.keys():
			if get_tempering_level(req_id) < int(synergy.requirements[req_id]):
				ok = false
				break
		if ok:
			active_synergies[synergy.id] = true
			debug_stats.synergies[synergy.id] = debug_stats.synergies.get(synergy.id, 0) + 1

func offer_upgrades(count := Config.UPGRADE_PICK_COUNT, reason: StringName = &"wave") -> Array:
	offered_cards.clear()
	for tempering in TEMPERINGS:
		if tempering.unlocked and get_tempering_level(tempering.id) < tempering.max_level:
			offered_cards.append(tempering)
	for i in range(offered_cards.size() - 1, 0, -1):
		var j := Config.rng.randi_range(0, i)
		var temp: Resource = offered_cards[i]
		offered_cards[i] = offered_cards[j]
		offered_cards[j] = temp
	offered_cards = offered_cards.slice(0, min(count, offered_cards.size()))
	upgrade_panel_visible = true
	pending_upgrade_reason = reason
	GameState.state = GameState.RunState.UPGRADE
	return offered_cards

func choose_upgrade(index := 0) -> void:
	if index >= 0 and index < offered_cards.size():
		apply_tempering(offered_cards[index].id)
	upgrade_panel_visible = false
	offered_cards.clear()
	GameState.state = GameState.RunState.PLAY
	if pending_next_wave:
		pending_next_wave = false
		_next_wave()

func select_weapon(id: StringName) -> void:
	if id == &"slag_lance":
		current_weapon = SLAG_LANCE
	elif id == &"ember_maw":
		current_weapon = EMBER_MAW
	else:
		current_weapon = FORGEHAMMER
	weapon_fire_ticks = 0

func force_open_chest() -> void:
	_open_chest({"position": player.position, "guaranteed_evolution": true})

func _tempering_by_id(id: StringName) -> Resource:
	for tempering in TEMPERINGS:
		if tempering.id == id:
			return tempering
	return null

func _tick_combo() -> void:
	if combo_ticks > 0:
		combo_ticks -= 1
		if combo_ticks == 0:
			GameState.set_combo(0)

func _check_wave_clear_or_death() -> void:
	if player.hp <= 0.0 and not run_finalized:
		_finalize_run(false)
	if wave_active and spawn_queue.is_empty() and enemies.is_empty():
		if GameState.state == GameState.RunState.VICTORY or GameState.state == GameState.RunState.OVER:
			return
		wave_active = false
		if not current_objective.is_empty() and not current_objective.get("done", false) and not current_objective.get("failed", false):
			if _objective_type() == "anvil_defense":
				player.max_hp += Config.ANVIL_DEFENSE_BLESSING_HP
				player.hp = player.max_hp
				_complete_objective()
			else:
				_fail_objective()
		GameState.add_score(100 + GameState.wave * 20)
		EventBus.wave_cleared.emit(GameState.wave)
		debug_stats.waves_cleared.append(GameState.wave)
		pending_next_wave = true
		var offer_count := Config.UPGRADE_PICK_COUNT + anvil_bonus_choices
		if offer_upgrades(offer_count, &"wave").is_empty():
			choose_upgrade(-1)

func _finalize_run(victory: bool) -> void:
	if run_finalized:
		return
	run_finalized = true
	if victory:
		ember_count = int(round(float(ember_count) * Config.VICTORY_EMBER_MULT))
	debug_stats.embers = ember_count
	debug_stats.victory = victory
	var recap := {
		"victory": victory,
		"wave": GameState.wave,
		"score": GameState.score,
		"kills": GameState.kills,
		"best_combo": GameState.best_combo,
		"embers_banked": ember_count,
		"weapon": current_weapon.display_name,
		"evolutions": active_evolutions.keys(),
		"synergies": active_synergies.keys(),
	}
	debug_stats.recap = recap
	GameState.end_run(victory)
	GameState.last_recap = recap
	SaveManager.record_run(victory, GameState.wave, GameState.score, GameState.best_combo, GameState.kills, ember_count)

func enter_endless() -> void:
	if GameState.state != GameState.RunState.VICTORY:
		return
	endless_mode = true
	run_finalized = false
	debug_stats.endless_entered = true
	GameState.state = GameState.RunState.PLAY
	_next_wave()

func end_after_victory() -> void:
	if GameState.state == GameState.RunState.VICTORY:
		GameState.state = GameState.RunState.OVER

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
	if hud.has_method("set_phase3_state"):
		var cards := offered_cards if upgrade_panel_visible else []
		var chest_text := ""
		if chest_reveal_ticks > 0:
			var content_text := ""
			for content in chest_reveal_contents:
				if content_text != "":
					content_text += ", "
				content_text += str(content)
			chest_text = "CHEST: %s" % (content_text if content_text != "" else "TEMPERING")
		hud.set_phase3_state(current_weapon.display_name, ember_count, _objective_status_text(), anvil_hp, cards, chest_text)

func _unhandled_input(event: InputEvent) -> void:
	if GameState.state != GameState.RunState.UPGRADE or not event.is_pressed():
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.keycode >= KEY_1 and key.keycode <= KEY_4:
			choose_upgrade(key.keycode - KEY_1)

func _on_shake_requested(strength: float) -> void:
	shake = max(shake, strength * Config.screen_shake_scale)

func _on_hitstop_requested(ticks_count: int) -> void:
	hitstop_ticks = max(hitstop_ticks, ticks_count)

func _on_boss_phase(boss: Node, phase: int) -> void:
	if not boss or not boss.data:
		return
	var phases: Dictionary = debug_stats.boss_phases
	var key: StringName = boss.data.id
	var list: Array = phases.get(key, [])
	list.append(phase)
	phases[key] = list

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
