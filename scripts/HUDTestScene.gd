extends Node2D

# Reference to the HUD
@onready var hud: GameHUD = $GameHUD
@onready var current_values_label: Label = $TestControls/CurrentValues

# Drain settings
var sanity_drain_rate: float = 5.0  # Points per second (when actively draining)
var hunger_drain_rate: float = 1.5  # Points per second
var hunger_drain_enabled: bool = true

# Sanity event-based drain
var sanity_is_draining: bool = false
var sanity_drain_timer: float = 0.0

func _ready() -> void:
	print("HUD Test Scene loaded!")
	
	# Connect to HUD signals to demonstrate functionality
	if hud:
		hud.SanityDepleted.connect(_on_sanity_depleted)
		hud.HungerDepleted.connect(_on_hunger_depleted)
		hud.SanityCritical.connect(_on_sanity_critical)
		hud.HungerCritical.connect(_on_hunger_critical)
		
		update_values_display()
	else:
		print("ERROR: Could not find GameHUD!")

func _process(delta: float) -> void:
	if hud:
		# Handle sanity drain timer
		if sanity_is_draining:
			var new_sanity = hud.GetSanity() - (sanity_drain_rate * delta)
			hud.SetSanity(new_sanity)
			
			# Decrease timer
			sanity_drain_timer -= delta
			if sanity_drain_timer <= 0.0:
				sanity_is_draining = false
				print("Sanity drain stopped")
		
		# Gradually drain hunger over time (always active)
		if hunger_drain_enabled:
			var new_hunger = hud.GetHunger() - (hunger_drain_rate * delta)
			hud.SetHunger(new_hunger)
		
		update_values_display()

func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	
	# Only handle keyboard events
	if not event is InputEventKey:
		return
		
	# Test controls for HUD functionality
	match event.keycode:
		KEY_1:  # Add Loop
			hud.AddLoops(1)
			update_values_display()
			print("Added 1 loop! Total: ", hud.LoopCount)
			
		KEY_2:  # Damage Sanity
			var new_sanity = hud.GetSanity() - 10.0
			hud.SetSanity(new_sanity)
			update_values_display()
			print("Damaged sanity! Current: ", hud.GetSanity())
			
		KEY_3:  # Restore Sanity
			var new_sanity = hud.GetSanity() + 10.0
			hud.SetSanity(new_sanity)
			update_values_display()
			print("Restored sanity! Current: ", hud.GetSanity())
			
		KEY_4:  # Damage Hunger
			var new_hunger = hud.GetHunger() - 10.0
			hud.SetHunger(new_hunger)
			update_values_display()
			print("Damaged hunger! Current: ", hud.GetHunger())
			
		KEY_5:  # Restore Hunger
			var new_hunger = hud.GetHunger() + 10.0
			hud.SetHunger(new_hunger)
			update_values_display()
			print("Restored hunger! Current: ", hud.GetHunger())
			
		KEY_6:  # Trigger sanity drain event (3 seconds)
			trigger_sanity_drain_event(3.0)
			
		KEY_7:  # Toggle hunger drain
			hunger_drain_enabled = !hunger_drain_enabled
			print("Hunger drain ", "enabled" if hunger_drain_enabled else "disabled")
			
		KEY_8:  # Trigger short sanity drain (1 second)
			trigger_sanity_drain_event(1.0)
			
		KEY_9:  # Trigger long sanity drain (5 seconds) 
			trigger_sanity_drain_event(5.0)
			
		KEY_0:  # Reset all values
			hud.LoopCount = 0
			hud.SetSanity(100.0)
			hud.SetHunger(100.0)
			hud.UpdateLoopDisplay()
			sanity_is_draining = false
			update_values_display()
			print("Reset all values!")

func update_values_display() -> void:
	if current_values_label and hud:
		var sanity_status = "DRAINING" if sanity_is_draining else "stable"
		current_values_label.text = "Current Values:\nLoops: %d\nSanity: %.1f%% (%s)\nHunger: %.1f%%" % [
			hud.LoopCount,
			hud.GetSanityPercentage() * 100,
			sanity_status,
			hud.GetHungerPercentage() * 100
		]

# Public function to trigger sanity drain events
func trigger_sanity_drain_event(duration: float) -> void:
	sanity_is_draining = true
	sanity_drain_timer = duration
	print("Sanity drain triggered for ", duration, " seconds!")

# Signal handlers for HUD events
func _on_sanity_depleted() -> void:
	print("🚨 GAME OVER: Sanity completely depleted!")
	# You could trigger a game over screen here

func _on_hunger_depleted() -> void:
	print("🚨 GAME OVER: Hunger completely depleted!")
	# You could trigger a game over screen here

func _on_sanity_critical(current_value: float) -> void:
	print("⚠️  WARNING: Sanity critical! Value: ", current_value)
	# You could add screen shake, color effects, audio warnings here

func _on_hunger_critical(current_value: float) -> void:
	print("⚠️  WARNING: Hunger critical! Value: ", current_value)
	# You could add stomach growling sounds, visual effects here
