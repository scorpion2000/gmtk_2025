##Dependent on classes StatsList
class_name UpgradeMenu
extends Panel

signal retryPressed()
signal backPressed()

@export var StatList : StatsList

func _ready():
	%RetryBtn.pressed.connect(onRetryPressed)
	%BackBtn.pressed.connect(onBackPressed)
	## Example of how to get and add stats
	#print("Health: ", StatList.getStatValue("health"))
	#var health : Stat = StatList.getStatRef("health")
	#health.addValue(10)
	#print("Health: ", StatList.getStatValue("health"))
	pass

func onRetryPressed() -> void:
	retryPressed.emit()

func onBackPressed() -> void:
	backPressed.emit()
