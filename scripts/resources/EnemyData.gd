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
