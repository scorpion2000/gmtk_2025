##Dependent on classes StatsList
class_name UpgradeMenu
extends Panel

@export var StatList : StatsList

var upgrade_buttons : Array[UpgradeButton]

func _ready():
	loadButtons()
	%RetryBtn.pressed.connect(onRetryPressed)
	%BackBtn.pressed.connect(onBackPressed)

func _exit_tree() -> void:
	saveButtons()

func onRetryPressed() -> void:
	Utilities.switch_scene("Game", self)

func onBackPressed() -> void:
	if Utilities.lastScenePressed == "End":
		Utilities.backShowEnd()
	else:
		Utilities.go_back()

func saveButtons():
	var buttonList : Array[UpgradeButton]
	for item in %StatsContainer.get_children():
		if item is UpgradeButton:
			buttonList.append(item)
	Utilities.save_stat_upgrades(buttonList)

func loadButtons():
	var buttonList : Array[UpgradeButton]
	for item in %StatsContainer.get_children():
		if item is UpgradeButton:
			buttonList.append(item)
	var upgrade_data := Utilities.upgrade_save_data
	
	for btn in buttonList:
		var key := btn.UpgradeStat.resource_name
		if upgrade_data.has(key):
			var saved: Dictionary = upgrade_data[key]
			var target_level := int(saved.get("level", 0))
			btn.level = 0
			btn.statCost = btn.getCurrentCost()
			btn.UpgradeStat.setValue(btn.UpgradeStat.currentValue)
			for i in range(target_level):
				var inc := btn.getCurrentIncrease()
				match saved.get("modifier_type", btn.modType.Flat):
					btn.modType.Flat:
						btn.UpgradeStat.addValue(inc)
					btn.modType.Percent:
						var mod := StatModifier.MultiplyValueModifier.new()
						mod.factor = 1.0 + inc
						btn.UpgradeStat.addModifier(mod)
				btn.level += 1
				btn.statCost = btn.getCurrentCost()
