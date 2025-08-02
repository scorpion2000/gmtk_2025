extends Interactable
class_name Altar

# Altar configuration
@export var base_loop_cost: int = 10  # Base cost in loops
@export var buff_duration: float = 60.0  # Duration in seconds

# State
var times_used: int = 0  # Track how many times altar has been used
var game_manager: GameManager

enum BuffType {
	SPEED_BOOST,      # +10% speed
	NOISE_REDUCTION,  # -10% noise level 
	LOOP_BOOST        # +100% loop chance and amount
}

# Buff tracking
var active_buffs: Array[BuffType] = []
var buff_timers: Dictionary = {}

func _ready() -> void:
	super._ready()
	var parent_name = "no parent"
	if get_parent():
		parent_name = get_parent().name
	print("Altar _ready called for: ", parent_name)
	
	# Find the GameManager
	call_deferred("find_game_manager")
	
	# Connect to our own completion signal
	interaction_completed.connect(_on_altar_used)
	print("Connected interaction_completed signal for altar: ", parent_name)
	
	# Set altar-specific interaction prompt
	update_interaction_prompt()

func get_current_cost() -> int:
	# Escalating cost: 10, 50, 100
	match times_used:
		0: return base_loop_cost  # 10 loops
		1: return base_loop_cost * 5  # 50 loops
		2: return base_loop_cost * 10  # 100 loops
		_: return base_loop_cost * 10  # Cap at 100 loops

func update_interaction_prompt() -> void:
	var current_cost = get_current_cost()
	interaction_prompt = "Use Altar (" + str(current_cost) + " loops)"
	
	# Update the visual cost label on the altar
	var parent_object = get_parent()
	if parent_object.has_node("CostLabel"):
		var cost_label = parent_object.get_node("CostLabel") as Label
		if cost_label:
			cost_label.text = str(current_cost) + " loops"

func find_game_manager() -> void:
	# Look for GameManager in the scene tree
	game_manager = get_tree().get_first_node_in_group("GameManager") as GameManager
	if game_manager:
		print("Altar found GameManager: ", game_manager)
	else:
		# Fallback: search by type
		var root = get_tree().current_scene
		game_manager = _find_node_by_class(root, "GameManager") as GameManager
		if game_manager:
			print("Altar found GameManager via search: ", game_manager)
		else:
			print("WARNING: Altar could not find GameManager!")

func _on_altar_used() -> void:
	var parent_name = "no parent"
	if get_parent():
		parent_name = get_parent().name
	print("_on_altar_used called for: ", parent_name)
	
	var current_cost = get_current_cost()
	
	# Check current run loops via HUD, not global bank
	var current_run_loops = 0
	if hud:
		current_run_loops = game_manager.LoopCount
	
	# Check if player has enough loops in current run
	if current_run_loops < current_cost:
		print("Not enough loops! Need ", current_cost, " but have ", current_run_loops, " (current run)")
		if hud:
			# Show feedback - reusing the interaction label for feedback
			hud.showInteractionProgress("Not enough loops!")
			await get_tree().create_timer(2.0).timeout
			hud.hideInteractionProgress()
		return
	
	# Check if all buffs are already active
	if active_buffs.size() >= 3:
		print("All buffs already active!")
		if hud:
			hud.showInteractionProgress("All buffs active!")
			await get_tree().create_timer(2.0).timeout
			hud.hideInteractionProgress()
		return
	
	# Spend the loops from current run
	if game_manager:
		game_manager.LoopCount -= current_cost
	
	print("Spent ", current_cost, " loops from current run at altar!")
	
	# Increment usage count
	times_used += 1
	
	# Update the prompt for next use
	update_interaction_prompt()
	
	# Give a random buff that's not already active
	give_random_available_buff()

func give_random_available_buff() -> void:
	# Get all buff types that are not currently active
	var available_buffs: Array[BuffType] = []
	
	var all_buff_types = [BuffType.SPEED_BOOST, BuffType.NOISE_REDUCTION, BuffType.LOOP_BOOST]
	for buff_type in all_buff_types:
		if not active_buffs.has(buff_type):
			available_buffs.append(buff_type)
	
	if available_buffs.is_empty():
		print("No available buffs!")
		return
	
	# Choose a random available buff
	var random_buff = available_buffs[randi() % available_buffs.size()]
	apply_buff(random_buff)

func apply_buff(buff_type: BuffType) -> void:
	var buff_name = ""
	
	match buff_type:
		BuffType.SPEED_BOOST:
			buff_name = "Speed Boost"
			apply_speed_buff()
		BuffType.NOISE_REDUCTION:
			buff_name = "Noise Reduction"
			apply_noise_buff()
		BuffType.LOOP_BOOST:
			buff_name = "Loop Boost"
			apply_loop_buff()
	
	print("Applied buff: ", buff_name, " for ", buff_duration, " seconds")
	print("Active buffs: ", active_buffs.size(), "/3")
	print("Times used: ", times_used, " | Next cost: ", get_current_cost())
	
	# Show feedback to player
	if hud:
		hud.showInteractionProgress(buff_name + " Active!")
		await get_tree().create_timer(2.0).timeout
		hud.hideInteractionProgress()
	
	# Track the buff
	active_buffs.append(buff_type)
	
	# Create timer for buff duration
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = buff_duration
	timer.one_shot = true
	timer.timeout.connect(_on_buff_expired.bind(buff_type, timer))
	timer.start()
	
	buff_timers[buff_type] = timer

func apply_speed_buff() -> void:
	# Get the player and apply speed boost
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("apply_speed_modifier"):
			player.apply_speed_modifier(1.1)  # +10% speed
		else:
			# Fallback: directly modify speed values if no modifier system
			if player.has_property("walk_speed"):
				player.walk_speed *= 1.1
			if player.has_property("sprint_speed"):
				player.sprint_speed *= 1.1
		print("Applied +10% speed boost to player")
	
	# Show speed icon on HUD
	if hud:
		hud.showSpeedBuff()

func apply_noise_buff() -> void:
	# Find all NoiseMaker instances and reduce their noise level
	# This is more complex - we'll need to modify the NoiseMaker system
	# For now, we'll add this to the GameManager for global tracking
	if game_manager:
		if game_manager.has_method("applyNoiseReduction"):
			game_manager.applyNoiseReduction(0.9)  # -10% noise
		else:
			# Add the buff tracking to GameManager
			game_manager.noiseReductionActive = true
		print("Applied -10% noise reduction")
	
	# Show noise icon on HUD
	if hud:
		hud.showNoiseBuff()

func apply_loop_buff() -> void:
	# Modify all SearchableObject instances to have better rewards
	# This will affect new searches during the buff duration
	if game_manager:
		if game_manager.has_method("applyLoopBoost"):
			game_manager.applyLoopBoost(2.0, 2.0)  # +100% chance and amount
		else:
			# Add the buff tracking to GameManager
			game_manager.loopBoostActive = true
			game_manager.loopBoostMultiplier = 2.0
		print("Applied +100% loop boost")
	
	# Show loop icon on HUD
	if hud:
		hud.showLoopBuff()

func _on_buff_expired(buff_type: BuffType, timer: Timer) -> void:
	print("Buff expired: ", BuffType.keys()[buff_type])
	
	# Remove the buff
	active_buffs.erase(buff_type)
	buff_timers.erase(buff_type)
	
	# Remove the timer
	timer.queue_free()
	
	# Decrease usage count when a buff expires
	times_used = max(0, times_used - 1)
	
	# Update the prompt for next use
	update_interaction_prompt()
	
	# Reverse the buff effects
	match buff_type:
		BuffType.SPEED_BOOST:
			remove_speed_buff()
		BuffType.NOISE_REDUCTION:
			remove_noise_buff()
		BuffType.LOOP_BOOST:
			remove_loop_buff()

func remove_speed_buff() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("remove_speed_modifier"):
			player.remove_speed_modifier(1.1)
		else:
			# Fallback: restore original speed
			if player.has_property("walk_speed"):
				player.walk_speed /= 1.1
			if player.has_property("sprint_speed"):
				player.sprint_speed /= 1.1
		print("Removed speed boost from player")
	
	# Hide speed icon on HUD
	if hud:
		hud.hideSpeedBuff()

func remove_noise_buff() -> void:
	if game_manager:
		if game_manager.has_method("removeNoiseReduction"):
			game_manager.removeNoiseReduction()
		else:
			game_manager.noiseReductionActive = false
		print("Removed noise reduction")
	
	# Hide noise icon on HUD
	if hud:
		hud.hideNoiseBuff()

func remove_loop_buff() -> void:
	if game_manager:
		if game_manager.has_method("removeLoopBoost"):
			game_manager.removeLoopBoost()
		else:
			game_manager.loopBoostActive = false
			game_manager.loopBoostMultiplier = 1.0
		print("Removed loop boost")
	
	# Hide loop icon on HUD
	if hud:
		hud.hideLoopBuff()
