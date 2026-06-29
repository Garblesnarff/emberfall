extends Node2D
class_name BulletManager

@export var capacity := Config.PLAYER_BULLET_CAP
@export var is_player_owned := true
@export var bullet_color := Color(1.0, 0.682, 0.259)

var positions := PackedVector2Array()
var velocities := PackedVector2Array()
var life_ticks := PackedInt32Array()
var damage := PackedFloat32Array()
var radius := PackedFloat32Array()
var pierce := PackedInt32Array()
var rendered_origins := PackedVector2Array()
var homing_strength := PackedFloat32Array()
var active_count := 0

var _multimesh_instance: MultiMeshInstance2D
var _multimesh: MultiMesh

func _ready() -> void:
	_build_multimesh()

func reset() -> void:
	positions.clear()
	velocities.clear()
	life_ticks.clear()
	damage.clear()
	radius.clear()
	pierce.clear()
	rendered_origins.clear()
	homing_strength.clear()
	active_count = 0
	if _multimesh:
		_multimesh.visible_instance_count = 0

func spawn(pos: Vector2, vel: Vector2, dmg: float, life: int, p_radius := 4.0, p_pierce := 0, p_homing_strength := 0.0) -> bool:
	if active_count >= capacity:
		return false
	positions.append(pos)
	velocities.append(vel)
	life_ticks.append(life)
	damage.append(dmg)
	radius.append(p_radius)
	pierce.append(p_pierce)
	rendered_origins.append(pos)
	homing_strength.append(p_homing_strength)
	active_count += 1
	return true

func physics_tick(bounds: Rect2, grid: RefCounted, enemies: Array, player: Node = null, terrain: Node = null) -> Dictionary:
	var hits := []
	var player_hits := 0
	var i := active_count - 1
	while i >= 0:
		if not is_player_owned and is_instance_valid(player) and homing_strength[i] > 0.0:
			var to_player: Vector2 = player.position - positions[i]
			if to_player.length_squared() > 0.001:
				var speed := velocities[i].length()
				var steered := velocities[i].normalized().lerp(to_player.normalized(), homing_strength[i]).normalized()
				velocities[i] = steered * speed
		positions[i] += velocities[i]
		life_ticks[i] -= 1
		var dead := life_ticks[i] <= 0 or not bounds.grow(32.0).has_point(positions[i])
		if not dead and is_instance_valid(terrain) and terrain.has_method("projectile_blocked"):
			dead = terrain.projectile_blocked(positions[i])
		if not dead:
			if is_player_owned:
				var near: Array = grid.nearby(positions[i], 46.0)
				for enemy in near:
					if not is_instance_valid(enemy) or enemy.dead or enemy.dying:
						continue
					var rr: float = enemy.radius + radius[i]
					if positions[i].distance_squared_to(enemy.position) < rr * rr:
						hits.append({"enemy": enemy, "damage": damage[i], "velocity": velocities[i]})
						if pierce[i] > 0:
							pierce[i] -= 1
						else:
							dead = true
						break
			elif is_instance_valid(player) and player.invulnerable_ticks <= 0 and player.dashing_ticks <= 0:
				var rr2: float = player.radius + radius[i]
				if positions[i].distance_squared_to(player.position) < rr2 * rr2:
					player.apply_damage(damage[i], self, Config.PLAYER_BULLET_HURT_IFRAME_TICKS)
					player_hits += 1
					dead = true
		if dead:
			_remove_at(i)
		i -= 1
	_update_multimesh()
	return {"enemy_hits": hits, "player_hits": player_hits}

func _remove_at(index: int) -> void:
	var last := active_count - 1
	if index != last:
		positions[index] = positions[last]
		velocities[index] = velocities[last]
		life_ticks[index] = life_ticks[last]
		damage[index] = damage[last]
		radius[index] = radius[last]
		pierce[index] = pierce[last]
		rendered_origins[index] = rendered_origins[last]
		homing_strength[index] = homing_strength[last]
	positions.resize(last)
	velocities.resize(last)
	life_ticks.resize(last)
	damage.resize(last)
	radius.resize(last)
	pierce.resize(last)
	rendered_origins.resize(last)
	homing_strength.resize(last)
	active_count -= 1

func _build_multimesh() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_colors = true
	_multimesh.instance_count = capacity
	_multimesh.visible_instance_count = 0
	var mesh := QuadMesh.new()
	mesh.size = Vector2(8, 8)
	_multimesh.mesh = mesh
	_multimesh_instance = MultiMeshInstance2D.new()
	_multimesh_instance.multimesh = _multimesh
	add_child(_multimesh_instance)

func _update_multimesh() -> void:
	if not _multimesh:
		return
	_multimesh.visible_instance_count = active_count
	for i in range(active_count):
		var scale: float = max(0.75, radius[i] / 4.0)
		var xform := Transform2D(Vector2(scale, 0.0), Vector2(0.0, scale), positions[i])
		rendered_origins[i] = xform.origin
		_multimesh.set_instance_transform_2d(i, xform)
		_multimesh.set_instance_color(i, bullet_color)

func rendered_position(index: int) -> Vector2:
	if index < 0 or index >= active_count:
		return Vector2.INF
	return rendered_origins[index]
