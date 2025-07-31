@tool
extends Panel

signal UpgradeClicked(statName : Stat, cost : float)

@export var UpgradeStat : Stat:
	set(value):
		UpgradeStat = value
		%StatNameLabel.text = UpgradeStat.resource_name.capitalize()
		if Engine.is_editor_hint() and UpgradeStat:
			name = UpgradeStat.resource_name.capitalize() + "Stat"

var StatCost : float:
	set(newValue):
		StatCost = newValue
		%CostLabel.text = StatCost

func onButtonClick():
	if UpgradeStat:
		UpgradeClicked.emit(UpgradeStat, StatCost)

func updateCost(newCost):
	StatCost = newCost
