extends Control

@onready var option_menu: TabContainer = $"../Settings"

var gameScene := "res://scenes/game.tscn"

func _ready():
	$VBoxContainer/Start.grab_focus()
	if option_menu:
		option_menu.pre_scene = self

func _input(event):
	if event.is_action_pressed("ui_cancel") and option_menu and option_menu.visible:
		option_menu.hide()
		reset_focus()

func reset_focus():
	$VBoxContainer/Start.grab_focus()

func _on_start_pressed():
	Utilities.switch_scene("Game", get_parent().get_parent())
	AudioManager.play_music_sound()

func _on_option_pressed():
	if option_menu:
		option_menu.show()
		if option_menu.has_method("reset_focus"):
			option_menu.reset_focus()
		AudioManager.play_button_sound()
	else:
		print("Error: Settings menu not found!")

func _on_quit_pressed():
	get_tree().quit()
