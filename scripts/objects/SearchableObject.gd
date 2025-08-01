extends Interactable
class_name SearchableObject

# Reward configuration
@export var min_loops: int = 1
@export var max_loops: int = 5
@export var min_food: float = 10.0
@export var max_food: float = 25.0
@export var loop_chance: float = 0.6  # 60% chance for loops
@export var food_chance: float = 0.4  # 40% chance for food

# State
var has_been_searched: bool = false
var game_manager: GameManager

func _ready() -> void:
	super._ready()
	var parent_name = "no parent"
	if get_parent():
		parent_name = get_parent().name
	print("SearchableObject _ready called for: ", parent_name)
	# Find the GameManager
	call_deferred("find_game_manager")
	
	# Connect to our own completion signal
	interaction_completed.connect(_on_search_completed)
	print("Connected interaction_completed signal for: ", parent_name)

func find_game_manager() -> void:
	# Look for GameManager in the scene tree
	var gm_node = get_tree().get_first_node_in_group("game_manager")
	if gm_node:
		game_manager = gm_node as GameManager
		print("SearchableObject found GameManager: ", game_manager)
	else:
		# Fallback: search by type
		var root = get_tree().current_scene
		game_manager = _find_node_by_class(root, "GameManager") as GameManager
		if game_manager:
			print("SearchableObject found GameManager via search: ", game_manager)
		else:
			print("WARNING: SearchableObject could not find GameManager!")

func _on_search_completed() -> void:
	var parent_name = "no parent"
	if get_parent():
		parent_name = get_parent().name
	print("_on_search_completed called for: ", parent_name)
	if has_been_searched:
		print("Object already searched: ", parent_name)
		return
	
	has_been_searched = true
	give_random_reward()
	
	# Visual feedback - change appearance to show it's been searched
	update_searched_appearance()

func give_random_reward() -> void:
	var random_value = randf()
	
	if random_value <= loop_chance:
		# Give loops
		var loops_amount = randi_range(min_loops, max_loops)
		GlobalLoops.addLoops(loops_amount)
		print("Found ", loops_amount, " loops in ", get_parent().name, "!")
		
		# Update the HUD loop display if available
		if game_manager and game_manager.HudReference:
			game_manager.HudReference.AddLoops(loops_amount)
			
	else:
		# Give food
		var food_amount = randf_range(min_food, max_food)
		if game_manager:
			game_manager.RestoreHunger(food_amount)
			print("Found food worth ", food_amount, " hunger in ", get_parent().name, "!")
		else:
			print("No GameManager found - can't give food reward")

func update_searched_appearance() -> void:
	# Change the visual to show this object has been searched
	var parent_object = get_parent()
	if parent_object.has_node("Visual"):
		var visual = parent_object.get_node("Visual") as ColorRect
		if visual:
			# Make it darker/grayed out
			visual.color = visual.color * 0.5
	
	if parent_object.has_node("Label"):
		var label = parent_object.get_node("Label") as Label
		if label:
			label.text = label.text + " (Searched)"
	
	# Disable further interactions
	interaction_prompt = "Already Searched"
	interaction_time = 0.5  # Very quick interaction time for already searched objects
