extends Control

@onready var bank_label: Label = %BankLabel
@onready var unlock_label: Label = %UnlockLabel

func _ready() -> void:
	refresh()

func refresh() -> void:
	MetaProgression.sync_from_save()
	bank_label.text = "FORGE BANK: %d EMBERS" % MetaProgression.ember_bank
	var lines: Array[String] = []
	for id in MetaProgression.UNLOCK_COSTS.keys():
		var state := "OWNED" if MetaProgression.is_unlocked(id) else "%d" % int(MetaProgression.UNLOCK_COSTS[id])
		lines.append("%s  %s" % [String(id).to_upper(), state])
	unlock_label.text = "\n".join(lines)

func purchase_first_available() -> bool:
	for id in MetaProgression.UNLOCK_COSTS.keys():
		if MetaProgression.purchase(id):
			refresh()
			return true
	return false
