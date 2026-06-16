extends Node

const UNLOCK_COSTS := {
	&"weapon_slag_lance": 300,
	&"weapon_ember_maw": 300,
	&"tempered_skin_1": 150,
	&"tempered_skin_2": 300,
	&"tempered_skin_3": 600,
	&"deep_pockets_1": 200,
	&"deep_pockets_2": 400,
	&"old_flame": 250,
	&"card_thorns": 200,
	&"card_magnet_coil": 200,
	&"card_second_wind": 200,
}

var ember_bank := 0

func _ready() -> void:
	sync_from_save()

func sync_from_save() -> void:
	SaveManager.data = SaveManager._migrate(SaveManager.data)
	ember_bank = int(SaveManager.data.bank.embers)

func add_embers(amount: int) -> void:
	sync_from_save()
	ember_bank += amount
	SaveManager.data.bank.embers = ember_bank
	SaveManager.save()

func can_purchase(id: StringName) -> bool:
	sync_from_save()
	return UNLOCK_COSTS.has(id) and ember_bank >= int(UNLOCK_COSTS[id]) and not is_unlocked(id)

func purchase(id: StringName) -> bool:
	if not can_purchase(id):
		return false
	ember_bank -= int(UNLOCK_COSTS[id])
	SaveManager.data.bank.embers = ember_bank
	if id == &"weapon_slag_lance":
		SaveManager.data.unlocks.weapons.append("slag_lance")
	elif id == &"weapon_ember_maw":
		SaveManager.data.unlocks.weapons.append("ember_maw")
	elif String(id).begins_with("card_"):
		SaveManager.data.unlocks.cards.append(String(id).trim_prefix("card_"))
	else:
		SaveManager.data.unlocks.perks.append(String(id))
	SaveManager.save()
	return true

func is_unlocked(id: StringName) -> bool:
	SaveManager.data = SaveManager._migrate(SaveManager.data)
	if id == &"weapon_slag_lance":
		return SaveManager.data.unlocks.weapons.has("slag_lance")
	if id == &"weapon_ember_maw":
		return SaveManager.data.unlocks.weapons.has("ember_maw")
	if String(id).begins_with("card_"):
		return SaveManager.data.unlocks.cards.has(String(id).trim_prefix("card_"))
	return SaveManager.data.unlocks.perks.has(String(id))

func first_unlock_reachable_in_two_runs(median_embers: int = 175) -> bool:
	var cheapest := 999999
	for cost in UNLOCK_COSTS.values():
		cheapest = min(cheapest, int(cost))
	return median_embers * 2 >= cheapest
