extends Node

enum RunState { MENU, PLAY, UPGRADE, PAUSE, OVER, VICTORY }

var state: RunState = RunState.MENU
var wave := 0
var score := 0
var kills := 0
var combo := 0
var best_combo := 0

func start_run(seed_value: int = 0xE4BEF411) -> void:
	Config.set_run_seed(seed_value)
	state = RunState.PLAY
	wave = 0
	score = 0
	kills = 0
	combo = 0
	best_combo = 0

func set_combo(value: int) -> void:
	combo = value
	best_combo = max(best_combo, combo)
	EventBus.combo_changed.emit(combo)

func add_score(base_points: int) -> void:
	var mult := 1 + int(floor(combo / 8.0))
	score += base_points * mult
	EventBus.score_changed.emit(score)

func end_run(victory: bool) -> void:
	state = RunState.VICTORY if victory else RunState.OVER
	EventBus.run_ended.emit(victory, {
		"wave": wave,
		"score": score,
		"kills": kills,
		"best_combo": best_combo,
		"seed": Config.run_seed,
	})
