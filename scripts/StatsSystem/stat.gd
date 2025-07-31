extends Resource
class_name Stat

@export var currentValue: float = 0.0
@export var minValue: float = 0.0
@export var maxValue: float = 9999.0

signal statChanged(statName : String, newValue: float)

# Private list of active modifiers (buffs, equipment, etc.)
var _modifiers: Array[StatModifier] = []

func getValue() -> float:
	var value := currentValue
	# Sort modifiers by order using a comparator
	_modifiers.sort_custom(_compareModOrder)
	for mod in _modifiers:
		value = mod.modify(currentValue, value)
	
	return clamp(value, minValue, maxValue)

# Helper Functions
func addValue(newValue : float):
	currentValue = clampValue(currentValue + newValue)

func setValue(newValue : float):
	currentValue = clampValue(currentValue)

func subtractValue(newValue : float):
	currentValue = clampValue(currentValue - newValue)

func clampValue(value : float) -> float:
	return clamp(value, minValue, maxValue)

# Moifier Functions
#Allow external systems to add/remove modifiers
func addModifier(modifier: StatModifier) -> void:
	_modifiers.append(modifier)
	statChanged.emit(resource_name, getValue())

func removeModifier(modifier: StatModifier) -> void:
	_modifiers.erase(modifier)
	statChanged.emit(resource_name, getValue())

func _compareModOrder(a: StatModifier, b: StatModifier) -> bool:
	return a.order < b.order
