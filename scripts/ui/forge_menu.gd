extends Control

signal start_run_requested
signal settings_requested

@onready var bank_label: Label = %BankLabel
@onready var unlock_label: Label = %UnlockLabel
@onready var start_button: Button = %StartButton
@onready var purchase_button: Button = %PurchaseButton
@onready var settings_button: Button = %SettingsButton
@onready var background: TextureRect = %Background
@onready var word_mark: TextureRect = %WordMark

func _ready() -> void:
	_fit_to_viewport()
	get_viewport().size_changed.connect(_fit_to_viewport)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	word_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	word_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	start_button.pressed.connect(func() -> void: start_run_requested.emit())
	purchase_button.pressed.connect(purchase_first_available)
	settings_button.pressed.connect(func() -> void: settings_requested.emit())
	refresh()

func _fit_to_viewport() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

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
