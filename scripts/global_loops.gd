extends Node

signal updateLoops(newLoops : float)

var LoopsCurrency : float = 100:
	set(value):
		LoopsCurrency = value
		updateLoops.emit(LoopsCurrency)

func addLoops(value : float):
	LoopsCurrency += value

func subtractLoops(value : float):
	LoopsCurrency -= value
