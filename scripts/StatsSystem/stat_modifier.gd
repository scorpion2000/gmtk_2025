# Base type for all stat modifiers. A modifier transforms a running value.
# The Stat resource collects these and applies them in sorted order.
class_name StatModifier
extends Resource

# Lower numbers are applied earlier than higher numbers.
@export var order: int = 0 

# Subclasses override this to implement their own transformation.
func modify(_fromValue: float, currentValue: float) -> float:
	return currentValue 

# ---------- Modifiers ----------
## You can initialize modifiers by doing "StatModifier.AddValueModifier.new()" or "StatModifier.MultiplyValueModifier.new()"
# Additive modifier: adds a fixed amount to the running value.
# Example: amount = 5 makes currentValue become currentValue + 5.
class AddValueModifier extends StatModifier:
	@export var amount: float = 0.0
	func modify(_fromValue: float, currentValue: float) -> float:
		return currentValue + amount

# Multiplicative modifier: multiplies the running value by a factor.
# Example: factor = 1.05 gives a +5% increase.
class MultiplyValueModifier extends StatModifier:
	@export var factor: float = 1.0
	func modify(_fromValue: float, currentValue: float) -> float:
		return currentValue * factor
