##Dependent on classes StatsList, Stat, UpgradeButton
class_name UpgradeMenu
extends Panel

@export var StatList : StatsList

func _ready():
	## Example of how to get and add stats
	#print("Health: ", StatList.getStatValue("health"))
	#var health : Stat = StatList.getStatRef("health")
	#health.addValue(10)
	#print("Health: ", StatList.getStatValue("health"))
	pass
