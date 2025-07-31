extends Node2D

# Reference to the HUD
@onready var hud: GameHUD = $GameHUD

# Drain settings
var sanity_drain_rate: float = 5.0  # Points per second (when actively draining)
var hunger_drain_rate: float = 1.5  # Points per second
var hunger_drain_enabled: bool = true

# Sanity event-based drain
var sanity_is_draining: bool = false
var sanity_drain_timer: float = 0.0

func _ready() -> void:
	setup_hud_connections()

func setup_hud_connections() -> void:
	# Find the HUD in the scene
	if not hud:
		hud = get_node_or_null("GameHUD") as GameHUD
	
	if hud:
		# Connect to HUD signals for game events
		hud.SanityDepleted.connect(_on_sanity_depleted)
		hud.HungerDepleted.connect(_on_hunger_depleted)
		hud.SanityCritical.connect(_on_sanity_critical)
		hud.HungerCritical.connect(_on_hunger_critical)
		print("HUD connected successfully")
	else:
		print("Warning: GameHUD not found in scene!")

func _process(delta: float) -> void:
	if not hud:
		return
		
	# Handle sanity drain timer
	if sanity_is_draining:
		var new_sanity = hud.GetSanity() - (sanity_drain_rate * delta)
		hud.SetSanity(new_sanity)
		
		# Decrease timer
		sanity_drain_timer -= delta
		if sanity_drain_timer <= 0.0:
			sanity_is_draining = false
	
	# Gradually drain hunger over time (always active)
	if hunger_drain_enabled:
		var new_hunger = hud.GetHunger() - (hunger_drain_rate * delta)
		hud.SetHunger(new_hunger)

# Public function to trigger sanity drain events
func TriggerSanityDrainEvent(duration: float) -> void:
	sanity_is_draining = true
	sanity_drain_timer = duration

# Public functions for game events
func CollectLoop() -> void:
	if hud:
		hud.AddLoops(1)

func RestoreSanity(amount: float) -> void:
	if hud:
		var new_sanity = hud.GetSanity() + amount
		hud.SetSanity(new_sanity)

func RestoreHunger(amount: float) -> void:
	if hud:
		var new_hunger = hud.GetHunger() + amount
		hud.SetHunger(new_hunger)

# Signal handlers for critical HUD events
func _on_sanity_depleted() -> void:
	print("GAME OVER: Sanity depleted!")
	# TODO: Trigger game over sequence

func _on_hunger_depleted() -> void:
	print("GAME OVER: Hunger depleted!")
	# TODO: Trigger game over sequence

func _on_sanity_critical(current_value: float) -> void:
	print("WARNING: Sanity critical!")
	# TODO: Trigger visual/audio warning effects

func _on_hunger_critical(current_value: float) -> void:
	print("WARNING: Hunger critical!")
	# TODO: Trigger visual/audio warning effects
