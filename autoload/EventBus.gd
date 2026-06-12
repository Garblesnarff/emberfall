extends Node

signal enemy_killed(data: Resource)
signal player_hurt(amount: float, source: Variant)
signal boss_phase(boss: Node, phase: int)
signal chest_opened(contents: Array)
signal wave_cleared(wave: int)
signal objective_done(id: StringName)
signal combo_changed(n: int)
signal run_ended(victory: bool, stats: Dictionary)
signal score_changed(score: int)
signal shake_requested(strength: float)
signal hitstop_requested(ticks: int)
