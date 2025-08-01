# Simple stat container with min, max, current value and a stack of modifiers.
# Modifiers can change the effective value (buffs, debuffs, gear, etc.).
extends Resource
class_name Stat

# Base numbers stored on the resource.
@export var currentValue: float = 0.0
@export var minValue: float = 0.0
@export var maxValue: float = 9999.0

# Fired whenever modifiers change or you explicitly emit after a change.
signal statChanged(statName : String, newValue: float)

# Private list of active modifiers (buffs, equipment, etc.).
var _modifiers: Array[StatModifier] = []

# Returns the effective value after applying all modifiers in order.
func getValue() -> float:
	var value := currentValue
	# Sort modifiers by order using a comparator.
	_modifiers.sort_custom(_compareModOrder)
	for mod in _modifiers:
		# Each modifier gets the base (currentValue) and the running value.
		value = mod.modify(currentValue, value)
	
	# Clamp to enforce min and max bounds.
	return clamp(value, minValue, maxValue)

# ---------- Helper Functions ----------
# Add to currentValue, then clamp within bounds.
func addValue(newValue : float):
	currentValue = clampValue(currentValue + newValue)
	statChanged.emit(resource_name, getValue())

# Set currentValue directly, clamped.
func setValue(newValue : float):
	currentValue = clampValue(newValue)
	statChanged.emit(resource_name, getValue())

# Subtract from currentValue, then clamp within bounds.
func subtractValue(newValue : float):
	currentValue = clampValue(currentValue - newValue)
	statChanged.emit(resource_name, getValue())

# Central clamp helper so clamping rules live in one place.
func clampValue(value : float) -> float:
	return clamp(value, minValue, maxValue)

func getPercentage() -> float:
	return clampValue(currentValue / maxValue)

# ---------- Modifier Functions ----------
# Allow external systems to add/remove modifiers.
func addModifier(modifier: StatModifier) -> void:
	_modifiers.append(modifier)
	statChanged.emit(resource_name, getValue())

func removeModifier(modifier: StatModifier) -> void:
	_modifiers.erase(modifier)
	statChanged.emit(resource_name, getValue())

# Comparator for sort_custom. Lower order applies first.
func _compareModOrder(a: StatModifier, b: StatModifier) -> bool:
	return a.order < b.order
