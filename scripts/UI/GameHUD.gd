extends Control
class_name GameHUD

# Public variables (accessible by other classes)
var LoopCount: int = 0
var MaxSanity: float = 100.0
var MaxHunger: float = 100.0

# Private variables (internal use only)
var current_sanity: float = 100.0
var current_hunger: float = 100.0
var bar_width: float = 200.0

# Node references
@onready var loop_counter_label: Label = $TopLeftContainer/LoopCounter
@onready var sanity_bar_fill: ColorRect = $TopLeftContainer/SanityBarContainer/SanityBarBackground/SanityBarFill
@onready var hunger_bar_fill: ColorRect = $TopLeftContainer/HungerBarContainer/HungerBarBackground/HungerBarFill
@onready var mini_map: MiniMap = $MiniMap
@onready var interaction_container: Control = $InteractionContainer
@onready var circular_progress_bar: Control = $InteractionContainer/CircularProgressBar
@onready var progress_fill: ColorRect = $InteractionContainer/CircularProgressBar/ProgressFill
@onready var hold_e_label: Label = $InteractionContainer/HoldELabel
@onready var interaction_label: Label = $InteractionContainer/InteractionLabel

# Signals for when bars reach critical levels
signal SanityDepleted
signal HungerDepleted
signal SanityCritical(current_value: float)
signal HungerCritical(current_value: float)

func _ready() -> void:
	# Add to hud group for easy access
	add_to_group("hud")
	
	# Force initial update after nodes are ready
	call_deferred("initial_setup")

func initial_setup() -> void:
	update_loop_display()
	update_sanity_bar()
	update_hunger_bar()
	print("HUD initialized - Sanity: ", GetSanityPercentage() * 100, "%, Hunger: ", GetHungerPercentage() * 100, "%")

# Public methods - accessible by other classes
func AddLoops(amount: int) -> void:
	LoopCount += amount
	UpdateLoopDisplay()

func SetSanity(value: float) -> void:
	current_sanity = clampf(value, 0.0, MaxSanity)
	update_sanity_bar()
	check_sanity_thresholds()

func SetHunger(value: float) -> void:
	current_hunger = clampf(value, 0.0, MaxHunger)
	update_hunger_bar()
	check_hunger_thresholds()

func GetSanity() -> float:
	return current_sanity

func GetHunger() -> float:
	return current_hunger

func GetSanityPercentage() -> float:
	return current_sanity / MaxSanity

func GetHungerPercentage() -> float:
	return current_hunger / MaxHunger

func UpdateLoopDisplay() -> void:
	update_loop_display()

# Private methods - internal functionality
func update_loop_display() -> void:
	if loop_counter_label:
		loop_counter_label.text = "Loops: " + str(LoopCount)

func update_sanity_bar() -> void:
	if sanity_bar_fill:
		var percentage = GetSanityPercentage()
		# Use anchor_right to scale the bar as a percentage of its parent
		sanity_bar_fill.anchor_right = percentage
		
		# Change color based on sanity level
		if percentage > 0.5:
			sanity_bar_fill.color = Color(0.3, 0.7, 1.0)  # Blue - healthy
		elif percentage > 0.25:
			sanity_bar_fill.color = Color(1.0, 0.8, 0.2)  # Yellow - warning
		else:
			sanity_bar_fill.color = Color(1.0, 0.2, 0.2)  # Red - critical

func update_hunger_bar() -> void:
	if hunger_bar_fill:
		var percentage = GetHungerPercentage()
		# Use anchor_right to scale the bar as a percentage of its parent
		hunger_bar_fill.anchor_right = percentage
		
		# Change color based on hunger level
		if percentage > 0.5:
			hunger_bar_fill.color = Color(1.0, 0.5, 0.2)  # Orange - satisfied
		elif percentage > 0.25:
			hunger_bar_fill.color = Color(1.0, 0.8, 0.2)  # Yellow - getting hungry
		else:
			hunger_bar_fill.color = Color(1.0, 0.2, 0.2)  # Red - starving

func check_sanity_thresholds() -> void:
	if current_sanity <= 0.0:
		SanityDepleted.emit()
	elif current_sanity <= MaxSanity * 0.25:
		SanityCritical.emit(current_sanity)

func check_hunger_thresholds() -> void:
	if current_hunger <= 0.0:
		HungerDepleted.emit()
	elif current_hunger <= MaxHunger * 0.25:
		HungerCritical.emit(current_hunger)

# Mini-map management functions
func initialize_minimap(level_generator: LevelGenerator) -> void:
	if mini_map:
		mini_map.initialize(level_generator)

func update_minimap_room(room: RoomData) -> void:
	if mini_map:
		mini_map.update_current_room(room)

# Interaction progress bar functions
func show_interaction_progress(prompt_text: String = "Search") -> void:
	if interaction_container and interaction_label and hold_e_label:
		interaction_label.text = prompt_text
		hold_e_label.text = "Hold E"
		interaction_container.visible = true
		if progress_fill:
			progress_fill.anchor_right = 0.0

func hide_interaction_progress() -> void:
	if interaction_container:
		interaction_container.visible = false

func update_interaction_progress(progress: float) -> void:
	if progress_fill:
		progress_fill.anchor_right = clampf(progress, 0.0, 1.0)
