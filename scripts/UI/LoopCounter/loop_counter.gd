@tool
class_name LoopCounter
extends HBoxContainer

func _ready():
	if Engine.is_editor_hint(): return
	
	GlobalLoops.updateLoops.connect(loopsUpdated)
	loopsUpdated(GlobalLoops.LoopsCurrency)

func loopsUpdated(newLoops : float):
	%CurrencyLabel.text = str(int(newLoops))
