extends Node

# Scene manager

var scenes: Dictionary = {
	Menu = "res://addons/simple_menu/scenes/main_menu.tscn",
	Game = "res://scenes/game.tscn",
	Shop = "res://scenes/UI/UpgradeMenu/upgrade_menu.tscn",
	End = "res://scenes/UI/EndScreen/end_screen.tscn"
}

const PATH = "user://settings.cfg"
var lastScenePressed : String = "Menu"
var upgrade_save_data: Dictionary = {}
var config: ConfigFile
var history: Array = []

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

	load_data()

# Persistence
func save_data():
	config.set_value("Upgrades", "data", upgrade_save_data)
	config.set_value("Loop", "Loop", GlobalLoops.LoopsCurrency)
	config.save(PATH)

func load_data():
	if config.load("user://settings.cfg") != OK:
		save_data()
		return
	load_control_settings()
	load_video_settings()
	if config.has_section_key("Upgrades", "data"):
		upgrade_save_data = config.get_value("Upgrades", "data", {})
	
	if config.has_section_key("Loop", "Loop"):
		GlobalLoops.LoopsCurrency = float(config.get_value("Loop", "Loop"))

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
	if not scenes.has(scene_name): return
	lastScenePressed = scene_name
	var current = get_tree().current_scene
	if current != null and !current.scene_file_path.is_empty():
		history.push_back(current.scene_file_path)
	get_tree().change_scene_to_file(scenes[scene_name])

func go_back() -> void:
	if history.size() > 0:
		var last_path: String = history.pop_back()
		get_tree().change_scene_to_file(last_path)

func showEnd(reason : String, loops : int, time : float):
	endReason = reason
	endLoops = loops
	endTime = time
	
	GlobalLoops.addLoops(endLoops)
	
	get_tree().change_scene_to_file(scenes["End"])
	await get_tree().create_timer(0.01).timeout
	var end_node := get_tree().get_first_node_in_group("End") as EndScreen
	end_node.showEnd(endReason, endLoops, endTime)

func backShowEnd():
	get_tree().change_scene_to_file(scenes["End"])
	await get_tree().create_timer(0.01).timeout
	var end_node := get_tree().get_first_node_in_group("End") as EndScreen
	end_node.showEnd(endReason, endLoops, endTime)

func save_stat_upgrades(buttons: Array[UpgradeButton]) -> void:
	upgrade_save_data.clear()
	for btn in buttons:
		var key := btn.UpgradeStat.resource_name
		upgrade_save_data[key] = {
			"level": btn.level,
			"modifier_type": btn.ModifierType,
		}
	save_data()
