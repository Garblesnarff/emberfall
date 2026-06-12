extends Resource
class_name EnemyData

@export var id: StringName
@export var display_name := ""
@export var ai_profile: StringName = &"chase"
@export var radius := 10.0
@export var hp := 10.0
@export var speed_min := 1.0
@export var speed_max := 1.0
@export var damage := 5.0
@export var points := 10
@export var color := Color.WHITE
@export var sprite_frames: SpriteFrames
@export var projectile_speed := 0.0
@export var projectile_radius := 0.0
@export var projectile_life_ticks := 0
@export var fire_cooldown_min_ticks := 0
@export var fire_cooldown_max_ticks := 0
@export var preferred_range := 0.0
@export var retreat_range := 0.0
@export var placeholder_sides := 3
@export var split_child_id: StringName
@export var split_child_count := 0
@export var split_child_hp_mult := 0.45
@export var split_child_radius_mult := 0.8
@export var boss := false
@export var boss_fixed_spawn := Vector2.ZERO
@export var boss_patterns: Array[StringName] = []
@export var boss_pattern_cooldown_min_ticks := 50
@export var boss_pattern_cooldown_max_ticks := 105
