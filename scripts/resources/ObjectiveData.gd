extends Resource
class_name ObjectiveData

@export var id: StringName
@export var display_name := ""
@export_enum("ember_vein", "braziers", "elite_bounty", "anvil_defense", "none") var objective_type := "ember_vein"
@export var channel_ticks := 0
@export var marker_count := 1
@export var score_reward := 0
@export var ember_reward := 0
@export var heart_reward := 0.0
@export var duration_ticks := 0
