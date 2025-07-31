class_name StatModifier
extends Resource

 # lower values apply earlier
@export var order: int = 0 

 # base class does nothing
func modify(_from_value: float, current_value: float) -> float:
	return current_value 

# Additive modifier – adds a fixed value
class AddValueModifier extends StatModifier:
	@export var amount: float = 0.0
	func modify(_from_value: float, current_value: float) -> float:
		return current_value + amount

# Multiplicative modifier – multiplies current value
class MultiplyValueModifier extends StatModifier:
	@export var factor: float = 1.0
	func modify(_from_value: float, current_value: float) -> float:
		return current_value * factor
