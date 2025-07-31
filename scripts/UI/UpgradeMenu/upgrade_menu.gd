class_name UpgradeMenu
extends Panel

@export var StatList : StatsList

func _ready():
	print("Health: ", StatList.getStatValue("health"))
	var health : Stat = StatList.getStatRef("health")
	health.addValue(10)
	print("Health: ", StatList.getStatValue("health"))
