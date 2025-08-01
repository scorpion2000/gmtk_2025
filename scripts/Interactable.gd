extends Area2D
class_name Interactable

# Configuration
@export var interaction_time: float = 3.0
@export var interaction_prompt: String = "Search"

# State
var is_player_nearby: bool = false
var is_interacting: bool = false
var interaction_progress: float = 0.0
var hud: GameHUD

# Signals
signal interaction_completed
signal interaction_started
signal interaction_cancelled

func _ready() -> void:
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Find the HUD
	call_deferred("find_hud")

func find_hud() -> void:
	# Look for GameHUD in the scene tree
	var hud_node = get_tree().get_first_node_in_group("hud")
	if hud_node:
		hud = hud_node as GameHUD
		print("Found HUD via group: ", hud)
	else:
		# Fallback: search by type
		var root = get_tree().current_scene
		hud = _find_node_by_class(root, "GameHUD") as GameHUD
		print("Found HUD via search: ", hud)

func _find_node_by_class(node: Node, target_class: String) -> Node:
	if node.get_script() and node.get_script().get_global_name() == target_class:
		return node
	for child in node.get_children():
		var result = _find_node_by_class(child, target_class)
		if result:
			return result
	return null

func _physics_process(delta: float) -> void:
	if not is_player_nearby:
		return
	
	# Check for E key input
	if Input.is_action_pressed("interact"):
		if not is_interacting:
			start_interaction()
		else:
			update_interaction(delta)
	else:
		if is_interacting:
			cancel_interaction()

func start_interaction() -> void:
	is_interacting = true
	interaction_progress = 0.0
	# Don't call show_interaction_progress here since it's already shown when entering area
	# Just reset the progress bar to 0
	if hud:
		hud.update_interaction_progress(0.0)
	interaction_started.emit()
	print("Starting interaction with: ", get_parent().name)

func update_interaction(delta: float) -> void:
	interaction_progress += delta / interaction_time
	
	if hud:
		hud.update_interaction_progress(interaction_progress)
	
	if interaction_progress >= 1.0:
		complete_interaction()

func complete_interaction() -> void:
	is_interacting = false
	interaction_progress = 1.0
	if hud:
		hud.hide_interaction_progress()
	interaction_completed.emit()
	print("Interaction completed with: ", get_parent().name)

func cancel_interaction() -> void:
	is_interacting = false
	interaction_progress = 0.0
	# Reset progress bar to 0 but keep the "Hold E" prompt visible
	if hud:
		hud.update_interaction_progress(0.0)
	interaction_cancelled.emit()
	print("Cancelling interaction with: ", get_parent().name)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = true
		print("Player entered interaction area for: ", get_parent().name)
		# Show the prompt immediately when player enters area
		if hud:
			hud.show_interaction_progress(interaction_prompt)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false
		print("Player exited interaction area for: ", get_parent().name)
		if is_interacting:
			cancel_interaction()
		else:
			# Hide the prompt when player leaves area
			if hud:
				hud.hide_interaction_progress()
