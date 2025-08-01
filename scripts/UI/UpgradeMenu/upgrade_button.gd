##Dependent on class Stat and GlobalLoops
@tool
class_name UpgradeButton
extends Panel

# The stat resource this button will upgrade.
@export var UpgradeStat: Stat:
	set(value):
		UpgradeStat = value
		# Reflect the stat name in the UI when assigned.
		%StatNameLabel.text = UpgradeStat.resource_name.capitalize()
		if Engine.is_editor_hint() and UpgradeStat:
			name = UpgradeStat.resource_name.capitalize() + "Stat"

# How the upgrade is applied: flat add or percent (multiplicative).
enum modType { Flat, Percent }
@export var ModifierType: modType = modType.Flat

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

# Current upgrade level shown on the button.
var level: int = 0:
	set(value):
		level = value
		%LvlLabel.text = str(level)

# displayed current cost for the next upgrade.
var statCost: float:
	set(newValue):
		statCost = newValue
		%CostLabel.text = str(statCost)

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

# ---------- Helpers ----------
# Exponential cost curve: base * multiplier^level.
func getCurrentCost() -> float:
	return BaseCost * pow(CostMultiplier, level)

# Exponential effect curve: value * multiplier^level.
func getCurrentIncrease() -> float:
	return ModifierValue * pow(ModifierMultiplier, level)

# Can the player afford the next upgrade right now.
func canUpgrade() -> bool:
	return GlobalLoops.LoopsCurrency >= statCost

# Update currency label when the global currency changes.
func loopsUpdated(_newLoops : float):
	%Button.disabled = !canUpgrade()

# ---------- Interaction ----------
func onButtonClick() -> void:
	# Guard: Export variable UpgradeStat must be set, must not be in editor and be affordable.
	if !UpgradeStat or !canUpgrade() and !Engine.is_editor_hint(): 
		return
	
	# Spend the currency for this upgrade.
	GlobalLoops.subtractLoops(statCost)
	var inc := getCurrentIncrease()
	
	# Apply the upgrade according to its type.
	match ModifierType:
		modType.Flat:
			# Flat: add the increase directly to the stat.
			UpgradeStat.addValue(inc) 
		modType.Percent:
			# Percent: create a multiplicative modifier.
			var mod := StatModifier.MultiplyValueModifier.new()
			mod.factor = 1.0 + inc    # e.g. inc=0.05 → factor 1.05
			UpgradeStat.addModifier(mod)
	
	# Level up and recompute the next cost.
	level += 1 
	statCost = getCurrentCost()
