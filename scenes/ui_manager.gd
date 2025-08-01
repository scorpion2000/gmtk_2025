# UIManager.gd
class_name UIManager
extends Node

@export var hud           : GameHUD
@export var endScreen     : EndScreen
@export var upgradeMenu   : UpgradeMenu

@export var mainMenuScene : PackedScene

func _ready() -> void:
	endScreen.retryPressed.connect(onRetryRequested)
	endScreen.upgradePressed.connect(onUpgradeRequested)
	endScreen.menuPressed.connect(onMenuRequested)
	endScreen.exitPressed.connect(onExitRequested)
	
	upgradeMenu.retryPressed.connect(onRetryRequested)
	upgradeMenu.backPressed.connect(onUpgradeBack)
	
	# On start we want only the HUD visible
	hud.visible = true
	endScreen.visible = false
	upgradeMenu.visible = false

func showEnd(reason: String, loops: int, time: float) -> void:
	# Pause game and show the end screen
	get_tree().paused = true
	hud.visible = false
	upgradeMenu.visible = false
	endScreen.visible = true
	endScreen.showEnd(reason, loops, time)

func onRetryRequested() -> void:
	print("is retry")
	# Hide the end screen, unpause and reload the current level
	endScreen.visible = false
	upgradeMenu.visible = false
	get_tree().paused = false
	
	get_tree().reload_current_scene()

func onUpgradeRequested() -> void:
	# Hide end screen and show upgrade menu
	endScreen.visible = false
	upgradeMenu.visible = true

func onUpgradeBack() -> void:
	# Hide upgrade menu and return to HUD/game
	upgradeMenu.visible = false
	endScreen.visible = true

func onMenuRequested() -> void:
	# Hide end screen, unpause and load the main menu scene
	endScreen.visible = false
	get_tree().paused = false
	if mainMenuScene:
		get_tree().change_scene_to_packed(mainMenuScene)

func onExitRequested() -> void:
	# Exit the application
	get_tree().quit()
