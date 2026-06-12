extends Resource
class_name WeaponData

@export var id: StringName
@export var display_name := ""
@export_enum("projectile", "cone", "beam", "meteor") var pattern := "projectile"
@export var fire_rate_ticks := 11
@export var damage := 10.0
@export var projectile_speed := 9.5
@export var projectile_life_ticks := 80
@export var projectile_radius := 4.0
@export var shots := 1
@export var spread_radians := 0.13
@export var pierce := 0
@export var cone_range := 130.0
@export var cone_angle_radians := 1.4
@export var burn_ticks := 0
@export var linked_tempering: StringName
@export var evolution_id: StringName
