extends Node

var ember_bank := 0

func add_embers(amount: int) -> void:
	ember_bank += amount
	SaveManager.data.get_or_add("bank", {})["embers"] = ember_bank
	SaveManager.save()
