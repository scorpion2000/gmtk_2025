extends Node

# Scene manager

var scenes: Dictionary = {
	Menu = "res://addons/simple_menu/scenes/main_menu.tscn",
	Game = "res://scenes/game.tscn",
	Shop = "res://scenes/UI/UpgradeMenu/upgrade_menu.tscn",
	End = "res://scenes/UI/EndScreen/end_screen.tscn"
}
@export var is_persistence: bool = false

const PATH = "user://settings.cfg"
var config: ConfigFile

var endReason
var endLoops
var endTime

func _ready():
	config = ConfigFile.new()
	for action in InputMap.get_actions():
		if InputMap.action_get_events(action).size() != 0:
			config.set_value("Controls", action, InputMap.action_get_events(action)[0])

	config.set_value("Video", "fullscreen", DisplayServer.WINDOW_MODE_WINDOWED)
	config.set_value("Video", "borderless", false)
	config.set_value("Video", "vsync", DisplayServer.VSYNC_ENABLED)

	for i in range(3):
		config.set_value("Audio", str(i), 0.5)

	if is_persistence:
		load_data()

# Persistence
func save_data():
	if is_persistence:
		config.save(PATH)

func load_data():
	if config.load("user://settings.cfg") != OK:
		save_data()
		return
	load_control_settings()
	load_video_settings()

func load_control_settings():
	var keys = config.get_section_keys("Controls")
	for action in InputMap.get_actions():
		if keys.has(action):
			var value = config.get_value("Controls", action)
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, value)

func load_video_settings():
	var screen_type = config.get_value("Video","fullscreen")
	DisplayServer.window_set_mode(screen_type)
	var borderless = config.get_value("Video","borderless")
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, borderless)
	var vsync_index = config.get_value("Video", "vsync")
	DisplayServer.window_set_vsync_mode(vsync_index)

# Scene manager
func switch_scene(scene_name: StringName, curScene : Node):
	if not scenes.has(scene_name):
		print("ERROR: Scene '", scene_name, "' not found in scene_map")
		return
	#
	#call_deferred("curScene.queue_free()")
	get_tree().change_scene_to_file(scenes[scene_name])

func showEnd(reason : String, loops : int, time : float):
	endReason = reason
	endLoops = loops
	endTime = time
	get_tree().change_scene_to_file(scenes["End"])
	await get_tree().process_frame

	var end_node  := get_tree().current_scene

	# Now call the method
	end_node.showEnd(endReason, endLoops, endTime)

func backShowEnd():
	get_tree().change_scene_to_packed(load(scenes["End"]))
	await get_tree().process_frame
	await get_tree().process_frame

	var end_node  := get_tree().current_scene

	# Now call the method
	end_node.showEnd(endReason, endLoops, endTime)
