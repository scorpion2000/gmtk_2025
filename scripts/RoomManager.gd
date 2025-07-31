class_name RoomManager
extends Node

signal room_changed(new_room: RoomData)
signal room_cleared(room: RoomData)

# Current room state
var current_room: RoomData
var current_room_scene: Node
var level_generator: LevelGenerator
var last_door_direction: RoomData.DoorDirection = RoomData.DoorDirection.NORTH  # Track which door player came from
var is_first_room_load: bool = true  # Track if this is the very first room load

# Room transition
var is_transitioning: bool = false
var transition_duration: float = 0.3  # Shorter transition for quicker response
var door_cooldown_timer: float = 0.0
var door_cooldown_duration: float = 0.3  # Much shorter cooldown

# Transition state
var transition_tween: Tween
var transition_start_position: Vector2
var transition_target_position: Vector2
var player_can_move: bool = true  # Track if player input is allowed

# Player reference
var player: Node2D

# Fog of war - track loaded room scenes
var loaded_room_scenes: Dictionary = {}  # RoomData -> Node
var visible_rooms: Array[RoomData] = []  # Currently visible rooms

# Room scene container
@onready var room_container: Node = $RoomContainer

func _ready():
	level_generator = LevelGenerator.new()
	add_child(level_generator)

func _process(delta):
	# Update door cooldown timer
	if door_cooldown_timer > 0:
		door_cooldown_timer -= delta

# Initialize the room system
func initialize_rooms(player_node: Node2D):
	player = player_node
	
	# Generate level
	var rooms = level_generator.generate_level()
	print("Generated ", rooms.size(), " rooms")
	
	# Start in the starting room
	var starting_room = level_generator.get_starting_room()
	if starting_room:
		_load_room(starting_room)

# Load and display a room
func _load_room(room_data: RoomData):
	if is_transitioning:
		return
		
	is_transitioning = true
	
	# Set current room and mark as visited
	current_room = room_data
	current_room.is_visited = true
	
	print("Visiting room: ", RoomData.RoomType.keys()[room_data.room_type], " at (", room_data.grid_x, ",", room_data.grid_y, ")")
	
	# Load room scene if not already loaded
	if not loaded_room_scenes.has(room_data):
		_load_room_scene(room_data)
	
	# Preload adjacent rooms for smoother experience
	_preload_adjacent_rooms(room_data)
	
	# Update fog of war - show only visited rooms
	_update_fog_of_war()
	
	# Position player in the new room
	current_room_scene = loaded_room_scenes[room_data]
	
	# Start smooth transition
	_start_room_transition()

# Start smooth room transition
func _start_room_transition():
	if not player or not current_room_scene:
		_finish_room_transition()
		return
	
	# Store player's current position as start
	transition_start_position = player.global_position
	
	# Calculate target position for player
	var target_spawn_position = Vector2.ZERO
	if is_first_room_load:
		# First room load - use PlayerSpawn marker if available
		var spawn_point = current_room_scene.find_child("PlayerSpawn")
		if spawn_point:
			target_spawn_position = spawn_point.global_position
		else:
			target_spawn_position = current_room_scene.global_position  # Center as fallback
		is_first_room_load = false
	else:
		# Room transition - spawn at the door they came from
		var opposite_direction = _get_opposite_door(last_door_direction)
		target_spawn_position = _get_door_spawn_position(opposite_direction)
	
	transition_target_position = target_spawn_position
	
	# Create and configure tween
	if transition_tween:
		transition_tween.kill()
	
	transition_tween = create_tween()
	transition_tween.set_ease(Tween.EASE_OUT)
	transition_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animate player position
	transition_tween.tween_method(_update_player_transition, 0.0, 1.0, transition_duration)
	transition_tween.tween_callback(_finish_room_transition)

# Update player position during transition
func _update_player_transition(progress: float):
	if not player:
		return
	
	var current_pos = transition_start_position.lerp(transition_target_position, progress)
	player.global_position = current_pos

# Finish room transition
func _finish_room_transition():
	if player:
		player.global_position = transition_target_position
		player.z_index = 10
	
	# Emit room changed signal
	room_changed.emit(current_room)
	
	is_transitioning = false
	print("Room loading complete. Visited rooms: ", _count_visited_rooms())

# Count how many rooms have been visited (for debugging)
func _count_visited_rooms() -> int:
	var count = 0
	for room in level_generator.all_rooms:
		if room.is_visited:
			count += 1
	return count

# Load a single room scene into memory
func _load_room_scene(room_data: RoomData):
	var room_scene_node: Node
	
	if room_data.scene_path != "" and ResourceLoader.exists(room_data.scene_path):
		var room_scene = load(room_data.scene_path)
		room_scene_node = room_scene.instantiate()
		room_container.add_child(room_scene_node)

		call_deferred("_setup_room_doors", room_scene_node, room_data)
	else:
		room_scene_node = _create_placeholder_room(room_data)
		room_container.add_child(room_scene_node)
	
	# Position room scene based on grid coordinates
	var room_offset = Vector2(
		room_data.grid_x * 700,  # Rooms are 600x600, so 700 spacing (100px gap)
		room_data.grid_y * 700   # Square spacing for square rooms
	)
	room_scene_node.position = room_offset
	
	# Initially hide the room (fog of war)
	room_scene_node.visible = false
	
	# Store the loaded scene
	loaded_room_scenes[room_data] = room_scene_node

# Update fog of war visibility
func _update_fog_of_war():
	# Clear current visible rooms
	visible_rooms.clear()
	
	# Only show visited rooms (including current room)
	for room in level_generator.all_rooms:
		if room.is_visited:
			visible_rooms.append(room)
	
	# Update visibility of all loaded rooms
	for room_data in loaded_room_scenes.keys():
		var room_scene = loaded_room_scenes[room_data]
		room_scene.visible = visible_rooms.has(room_data)

# Setup doors in the room scene
func _setup_room_doors(room_scene: Node, room_data: RoomData):
	# Look for door nodes in the room scene
	var doors = _find_doors_in_scene(room_scene)
	
	for direction in RoomData.DoorDirection.values():
		var door = doors.get(direction)
		if door:
			if room_data.has_door(direction):
				door.visible = true
				door.set_deferred("monitoring", true)
				# Disconnect any existing connections first
				if door.body_entered.is_connected(_on_door_entered):
					door.body_entered.disconnect(_on_door_entered)
				# Connect door interaction with proper lambda
				door.body_entered.connect(func(body): _on_door_entered(direction, body))
			else:
				door.visible = false
				door.set_deferred("monitoring", false)

# Find door nodes in room scene
func _find_doors_in_scene(room_scene: Node) -> Dictionary:
	var doors = {}
	
	# Look for specifically named door nodes
	var north_door = room_scene.find_child("NorthDoor")
	var east_door = room_scene.find_child("EastDoor")
	var south_door = room_scene.find_child("SouthDoor")
	var west_door = room_scene.find_child("WestDoor")
	
	if north_door:
		doors[RoomData.DoorDirection.NORTH] = north_door
	if east_door:
		doors[RoomData.DoorDirection.EAST] = east_door
	if south_door:
		doors[RoomData.DoorDirection.SOUTH] = south_door
	if west_door:
		doors[RoomData.DoorDirection.WEST] = west_door
	
	return doors

# Handle player entering a door
func _on_door_entered(direction: RoomData.DoorDirection, body):
	if body != player or is_transitioning or door_cooldown_timer > 0:
		return
	
	# Start door cooldown
	door_cooldown_timer = door_cooldown_duration
	
	# Track which door the player used
	last_door_direction = direction
	
	# Calculate target room position
	var offset = RoomData.get_direction_offset(direction)
	var target_x = current_room.grid_x + offset.x
	var target_y = current_room.grid_y + offset.y
	
	# Get target room
	var target_room = level_generator.get_room_at(target_x, target_y)
	if target_room:
		call_deferred("_load_room", target_room)

# Preload adjacent rooms for smoother transitions
func _preload_adjacent_rooms(room: RoomData):
	for direction in RoomData.DoorDirection.values():
		if room.has_door(direction):
			var offset = RoomData.get_direction_offset(direction)
			var adj_x = room.grid_x + offset.x
			var adj_y = room.grid_y + offset.y
			
			var adjacent_room = level_generator.get_room_at(adj_x, adj_y)
			if adjacent_room and not loaded_room_scenes.has(adjacent_room):
				_load_room_scene(adjacent_room)

# Get the opposite door direction
func _get_opposite_door(direction: RoomData.DoorDirection) -> RoomData.DoorDirection:
	match direction:
		RoomData.DoorDirection.NORTH:
			return RoomData.DoorDirection.SOUTH
		RoomData.DoorDirection.SOUTH:
			return RoomData.DoorDirection.NORTH
		RoomData.DoorDirection.EAST:
			return RoomData.DoorDirection.WEST
		RoomData.DoorDirection.WEST:
			return RoomData.DoorDirection.EAST
		_:
			return RoomData.DoorDirection.NORTH

# Get spawn position near a specific door
func _get_door_spawn_position(door_direction: RoomData.DoorDirection) -> Vector2:
	if not current_room_scene:
		return Vector2.ZERO
	
	# Get the room's position offset
	var room_pos = current_room_scene.global_position
	
		# Position player near the door (inside the room, not on the door)
	match door_direction:
		RoomData.DoorDirection.NORTH:
			return room_pos + Vector2(0, -200)  # Well inside room from top door
		RoomData.DoorDirection.SOUTH:
			return room_pos + Vector2(0, 200)   # Well inside room from bottom door
		RoomData.DoorDirection.EAST:
			return room_pos + Vector2(200, 0)   # Well inside room from right door
		RoomData.DoorDirection.WEST:
			return room_pos + Vector2(-200, 0)  # Well inside room from left door
		_:
			return room_pos  # Center as fallback

# Create placeholder room for testing
func _create_placeholder_room(room_data: RoomData) -> Node2D:
	var placeholder = Node2D.new()
	placeholder.name = "PlaceholderRoom"
	
	# Create visual background
	var bg = ColorRect.new()
	bg.size = Vector2(600, 600)  # Square rooms instead of rectangles
	bg.position = Vector2(-300, -300)  # Centered at origin
	
	# Color based on room type
	match room_data.room_type:
		RoomData.RoomType.STARTING:
			bg.color = Color.GREEN * 0.3
		RoomData.RoomType.KITCHEN:
			bg.color = Color.YELLOW * 0.3
		RoomData.RoomType.SHRINE:
			bg.color = Color.BLUE * 0.3
		RoomData.RoomType.BEDROOM:
			bg.color = Color.PURPLE * 0.3
		RoomData.RoomType.LIVING_ROOM:
			bg.color = Color.GRAY * 0.3
	
	placeholder.add_child(bg)
	
	# Create door areas
	_create_placeholder_doors(placeholder, room_data)
	
	# Add room type label
	var label = Label.new()
	label.text = RoomData.RoomType.keys()[room_data.room_type] + " ROOM"
	label.position = Vector2(-50, -10)
	placeholder.add_child(label)
	
	return placeholder

# Create placeholder doors for testing
func _create_placeholder_doors(room: Node2D, room_data: RoomData):
	var door_positions = {
		RoomData.DoorDirection.NORTH: Vector2(0, -300),  # Top edge of 600x600 room
		RoomData.DoorDirection.EAST: Vector2(300, 0),    # Right edge of 600x600 room
		RoomData.DoorDirection.SOUTH: Vector2(0, 300),   # Bottom edge of 600x600 room
		RoomData.DoorDirection.WEST: Vector2(-300, 0)    # Left edge of 600x600 room
	}
	
	var door_names = ["NorthDoor", "EastDoor", "SouthDoor", "WestDoor"]
	
	for direction in RoomData.DoorDirection.values():
		if room_data.has_door(direction):
			var door = Area2D.new()
			door.name = door_names[direction]
			door.position = door_positions[direction]
			
			var collision = CollisionShape2D.new()
			var shape = RectangleShape2D.new()
			shape.size = Vector2(60, 60)
			collision.shape = shape
			door.add_child(collision)
			
			var visual = ColorRect.new()
			visual.size = Vector2(60, 60)
			visual.position = Vector2(-30, -30)
			visual.color = Color.WHITE
			door.add_child(visual)
			
			room.add_child(door)

# Get current room data
func get_current_room() -> RoomData:
	return current_room

# Mark current room as cleared
func mark_room_cleared():
	if current_room:
		current_room.is_cleared = true
		room_cleared.emit(current_room)
