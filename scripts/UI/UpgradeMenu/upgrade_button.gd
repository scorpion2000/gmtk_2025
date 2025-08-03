##Dependent on class Stat and GlobalLoops
@tool
class_name UpgradeButton
extends Panel

# The stat resource this button will upgrade.
@export var UpgradeStat: Stat:
	set(value):
		UpgradeStat = value
		# Reflect the stat name in the UI when assigned.
		setStatName()

@export var upgradeName : String = "empty":
	set(value):
		upgradeName = value
		setStatName()

# How the upgrade is applied: flat add or percent (multiplicative).
enum modType { FlatPositive, FlatNegative, PercentPositive, PercentNegative }
@export var ModifierType: modType = modType.FlatPositive

# ---------- Cost scaling settings ----------
# Starting cost of the first upgrade.
@export var BaseCost: float = 10.0
# Exponential multiplier per level for cost growth.
@export var CostMultiplier: float = 1.5

# ---------- Upgrade scaling settings ----------
# Base effect per level. Use 5.0 for +5 flat, or 0.05 for +5%.
@export var ModifierValue: float = 5.0
# Exponential multiplier per level for effect growth.
@export var ModifierMultiplier: float = 1.2

@export var maxLevel : int = 10
# Current upgrade level shown on the button.
var level: int = 0:
	set(value):
		level = value
		%LvlLabel.text = str(level)

# displayed current cost for the next upgrade.
var statCost: float:
	set(newValue):
		statCost = newValue
		setCostText()

# ---------- Lifecycle ----------
func _ready() -> void:
	# Do not do runtime hookups while editing in the editor.
	if Engine.is_editor_hint(): return
	
	# calculate the initial cost.
	statCost = getCurrentCost()
	# Listen for currency updates and refresh the label.
	GlobalLoops.updateLoops.connect(loopsUpdated)
	# Make sure level label matches the starting value.
	%LvlLabel.text = str(level)
	setCostText()

# ---------- Helpers ----------
func setCostText():
	if level >= maxLevel:
		%CostLabel.text = "MAX"
		GlobalLoops.updateLoops.disconnect(loopsUpdated)
		return
	%CostLabel.text = str(int(statCost))

func setStatName():
	%StatNameLabel.text = upgradeName
	if !Engine.is_editor_hint() or !UpgradeStat: return
	name = UpgradeStat.resource_name.capitalize()

# Exponential cost curve: base * multiplier^level.
func getCurrentCost() -> float:
	return BaseCost * pow(CostMultiplier, level)

# Exponential effect curve: value * multiplier^level.
func getCurrentIncrease() -> float:
	return ModifierValue * pow(ModifierMultiplier, level)

# Can the player afford the next upgrade right now.
func canUpgrade() -> bool:
	return GlobalLoops.LoopsCurrency >= statCost and level <= maxLevel

# Update currency label when the global currency changes.
func loopsUpdated(_newLoops : float):
	%Button.disabled = !canUpgrade()

# ---------- Interaction ----------
func onButtonClick() -> void:
	# Guard: Export variable UpgradeStat must be set, must not be in editor and be affordable.
	if !UpgradeStat or !canUpgrade() and !Engine.is_editor_hint(): return
	
	# Spend the currency for this upgrade.
	GlobalLoops.subtractLoops(statCost)
	upgradeButton()

func upgradeButton():
	var inc := getCurrentIncrease()
	match ModifierType:
		modType.FlatPositive:
			UpgradeStat.addValue(inc) 
		modType.FlatNegative:
			# Flat: add the increase directly to the stat.
			UpgradeStat.subtractValue(inc)
		modType.PercentPositive:
			var mod := StatModifier.MultiplyValueModifier.new()
			mod.factor = 1.0 + inc
			UpgradeStat.addModifier(mod)
		modType.PercentNegative:
			var mod := StatModifier.MultiplyValueModifier.new()
			mod.factor = 1.0 - inc
			UpgradeStat.addModifier(mod)
	level += 1 
	statCost = getCurrentCost()
