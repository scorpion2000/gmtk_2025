@tool
class_name LoopCounter
extends HBoxContainer

@export var LoopsTexture : Texture2D:
	set(value):
		LoopsTexture = value
		setTexture(LoopsTexture)

func _ready():
	if Engine.is_editor_hint(): return
	
	GlobalLoops.updateLoops.connect(loopsUpdated)
	# Initialize the currency.
	loopsUpdated(GlobalLoops.LoopsCurrency)

func loopsUpdated(newLoops : float):
	%CurrencyLabel.text = str(newLoops)

func setTexture(newTexture : Texture2D):
	%CurrencyImage.texture = newTexture
