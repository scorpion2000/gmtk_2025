extends Node2D

# Reference to the HUD
@onready var hud: GameHUD = $CanvasLayer/GameHUD
var room_manager: RoomManager

# Drain settings
var sanity_drain_rate: float = 5.0  # Points per second (when actively draining)
var hunger_drain_rate: float = 1.5  # Points per second
var hunger_drain_enabled: bool = true

# Sanity event-based drain
var sanity_is_draining: bool = false
var sanity_drain_timer: float = 0.0

# Player reference
var player: Node2D

func _ready() -> void:
	setup_hud_connections()
	setup_room_system()
	RenderingServer.set_default_clear_color(Color("#000000"))

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

func setup_room_system() -> void:
	# Find player in the scene
	player = get_node_or_null("Player")
	if not player:
		# Look for player in Player group
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	
	# Setup room manager
	room_manager = get_node_or_null("RoomManager") as RoomManager
	if not room_manager:
		room_manager = RoomManager.new()
		room_manager.name = "RoomManager"
		add_child(room_manager)
	
	if player and room_manager:
		room_manager.initialize_rooms(player)
		# Connect room events
		room_manager.room_changed.connect(_on_room_changed)
		room_manager.room_cleared.connect(_on_room_cleared)
		
		# Initialize mini-map after room manager is set up
		call_deferred("_setup_minimap")
		
		print("Room system initialized")
	else:
		print("Warning: Player or RoomManager not found!")

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

func _on_sanity_critical(_current_value: float) -> void:
	print("WARNING: Sanity critical!")
	# TODO: Trigger visual/audio warning effects

func _on_hunger_critical(_current_value: float) -> void:
	print("WARNING: Hunger critical!")
	# TODO: Trigger visual/audio warning effects

# Room system event handlers
func _on_room_changed(new_room: RoomData) -> void:
	print("Entered room: ", RoomData.RoomType.keys()[new_room.room_type])
	
	# Update mini-map
	if hud:
		hud.update_minimap_room(new_room)
	
	# Trigger sanity drain events based on room type
	match new_room.room_type:
		RoomData.RoomType.BEDROOM:
			TriggerSanityDrainEvent(1.5)  # Bedrooms are creepy
		RoomData.RoomType.LIVING_ROOM:
			if not new_room.is_cleared:
				TriggerSanityDrainEvent(1.0)  # Uncleared rooms cause mild stress

func _on_room_cleared(room: RoomData) -> void:
	print("Room cleared: ", RoomData.RoomType.keys()[room.room_type])
	
	# Restore some sanity for clearing rooms
	RestoreSanity(10.0)
	
	# Special rewards based on room type
	match room.room_type:
		RoomData.RoomType.KITCHEN:
			CollectLoop()
			RestoreHunger(25.0)  # Kitchen restores hunger
		RoomData.RoomType.SHRINE:
			# Shrine allows exchanging loops for buffs
			print("Shrine accessed - implement buff exchange system")
		RoomData.RoomType.BEDROOM:
			RestoreSanity(15.0)  # Bedroom restores sanity

func _setup_minimap():
	if hud and room_manager:
		hud.initialize_minimap(room_manager.get_level_generator())
