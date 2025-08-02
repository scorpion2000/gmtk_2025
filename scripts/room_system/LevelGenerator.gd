class_name LevelGenerator
extends Node

# Fixed class declaration
@export var grid_width: int = 13
@export var grid_height: int = 13
@export var min_rooms: int = 7
@export var max_rooms: int = 10
@export var special_room_chance: float = 0.4

var room_grid: Array[Array] = []
var all_rooms: Array[RoomData] = []
var start_x: int
var start_y: int

func _ready():
	start_x = int(float(grid_width) / 2.0)
	start_y = int(float(grid_height) / 2.0)

func generate_level() -> Array[RoomData]:
	_initialize_grid()
	_generate_branching_layout()
	_add_special_rooms()
	_finalize_doors()
	return all_rooms

func _initialize_grid():
	room_grid.clear()
	all_rooms.clear()
	for x in grid_width:
		room_grid.append([])
		for y in grid_height:
			room_grid[x].append(null)

# Generate branching layout with controlled room count
func _generate_branching_layout():
	# Create starting room
	var start_room = RoomData.new(RoomData.RoomType.STARTING, "res://scenes/rooms/StartRoom.tscn")
	start_room.grid_x = start_x
	start_room.grid_y = start_y
	_place_room(start_room, start_x, start_y)
	
	# Keep track of rooms that can be expanded from
	var expansion_candidates: Array[RoomData] = [start_room]
	var rooms_created = 1
	var target_rooms = randi_range(min_rooms, max_rooms)
	
	#print("Generating level with ", target_rooms, " rooms...")
	
	# Create rooms until we reach target count
	while rooms_created < target_rooms and not expansion_candidates.is_empty():
		# Pick a random room to expand from
		var base_room_index = randi() % expansion_candidates.size()
		var base_room = expansion_candidates[base_room_index]
		
		# Get valid directions for this room
		var directions = _get_valid_directions(base_room.grid_x, base_room.grid_y)
		
		if directions.is_empty():
			# This room can't expand further, remove it from candidates
			expansion_candidates.erase(base_room)
			continue
		
		# Choose a random direction
		var direction = directions[randi() % directions.size()]
		var offset = RoomData.get_direction_offset(direction)
		var new_x = base_room.grid_x + offset.x
		var new_y = base_room.grid_y + offset.y
		
		# Create a living room (we'll convert some to special rooms later)
		var new_room = RoomData.new(RoomData.RoomType.LIVING_ROOM, "res://scenes/rooms/LivingRoom.tscn")
		new_room.grid_x = new_x
		new_room.grid_y = new_y
		_place_room(new_room, new_x, new_y)
		
		rooms_created += 1
		#print("Created room ", rooms_created, "/", target_rooms, " at (", new_x, ",", new_y, ")")
		
		# Always add new room to expansion candidates if we're under minimum
		if rooms_created < min_rooms:
			expansion_candidates.append(new_room)
		else:
			# After minimum, use probability to create some dead ends
			if randf() > 0.4:  # 60% chance to add to expansion candidates
				expansion_candidates.append(new_room)
		
		# Only remove base room from candidates after we have enough rooms and with low probability
		if rooms_created >= min_rooms and randf() < 0.15:  # 15% chance to stop expanding from this room
			expansion_candidates.erase(base_room)
	
	#print("Level generation complete: ", rooms_created, " rooms created")

# Add special rooms (kitchen, shrine, bedroom, bathroom)
func _add_special_rooms():
	for room in all_rooms:
		if room.room_type != RoomData.RoomType.LIVING_ROOM:
			continue
			
		# Chance to convert living room to special room
		if randf() < special_room_chance:
			var special_types = [
				RoomData.RoomType.KITCHEN,
				RoomData.RoomType.SHRINE,
				RoomData.RoomType.BEDROOM
			]
			
			var new_type = special_types[randi() % special_types.size()]
			room.room_type = new_type
			
			# Update scene path based on type
			match new_type:
				RoomData.RoomType.KITCHEN:
					room.scene_path = "res://scenes/rooms/KitchenRoom.tscn"
				RoomData.RoomType.SHRINE:
					room.scene_path = "res://scenes/rooms/ShrineRoom.tscn"
				RoomData.RoomType.BEDROOM:
					room.scene_path = "res://scenes/rooms/BedroomRoom.tscn"

# Finalize door connections between rooms
func _finalize_doors():
	for room in all_rooms:
		for direction in RoomData.DoorDirection.values():
			var offset = RoomData.get_direction_offset(direction)
			var neighbor_x = room.grid_x + offset.x
			var neighbor_y = room.grid_y + offset.y
			
			if _is_valid_position(neighbor_x, neighbor_y) and room_grid[neighbor_x][neighbor_y] != null:
				room.set_door(direction, true)

# Helper functions
func _place_room(room: RoomData, x: int, y: int):
	room_grid[x][y] = room
	all_rooms.append(room)

func _is_valid_position(x: int, y: int) -> bool:
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height

func _get_valid_directions(x: int, y: int) -> Array[RoomData.DoorDirection]:
	var valid_directions: Array[RoomData.DoorDirection] = []
	
	for direction in RoomData.DoorDirection.values():
		var offset = RoomData.get_direction_offset(direction)
		var new_x = x + offset.x
		var new_y = y + offset.y
		
		if _is_valid_position(new_x, new_y) and room_grid[new_x][new_y] == null:
			valid_directions.append(direction)
	
	return valid_directions

# Get room at grid position
func get_room_at(x: int, y: int) -> RoomData:
	if _is_valid_position(x, y):
		return room_grid[x][y]
	return null

# Get starting room
func get_starting_room() -> RoomData:
	return get_room_at(start_x, start_y)
