class_name RoomData
extends Resource

# Room types for Loop Cat game
enum RoomType {
	LIVING_ROOM,
	STARTING,
	KITCHEN,
	SHRINE,
	BEDROOM
}

# Door directions
enum DoorDirection {
	NORTH = 0,
	EAST = 1,
	SOUTH = 2,
	WEST = 3
}

# Room data
@export var room_type: RoomType = RoomType.LIVING_ROOM
@export var scene_path: String = ""
@export var has_doors: Array[bool] = [false, false, false, false] # N, E, S, W
@export var is_visited: bool = false
@export var is_cleared: bool = false

# Grid position
var grid_x: int = 0
var grid_y: int = 0

func _init(type: RoomType = RoomType.LIVING_ROOM, scene: String = ""):
	room_type = type
	scene_path = scene
	has_doors = [false, false, false, false]
	is_visited = false
	is_cleared = false

# Helper functions for door management
func has_door(direction: DoorDirection) -> bool:
	return has_doors[direction]

func set_door(direction: DoorDirection, enabled: bool) -> void:
	has_doors[direction] = enabled

func get_door_count() -> int:
	var count = 0
	for door in has_doors:
		if door:
			count += 1
	return count

# Get opposite door direction
static func get_opposite_direction(direction: DoorDirection) -> DoorDirection:
	match direction:
		DoorDirection.NORTH:
			return DoorDirection.SOUTH
		DoorDirection.SOUTH:
			return DoorDirection.NORTH
		DoorDirection.EAST:
			return DoorDirection.WEST
		DoorDirection.WEST:
			return DoorDirection.EAST
		_:
			return DoorDirection.NORTH

# Get direction offset for grid movement
static func get_direction_offset(direction: DoorDirection) -> Vector2i:
	match direction:
		DoorDirection.NORTH:
			return Vector2i(0, -1)
		DoorDirection.SOUTH:
			return Vector2i(0, 1)
		DoorDirection.EAST:
			return Vector2i(1, 0)
		DoorDirection.WEST:
			return Vector2i(-1, 0)
		_:
			return Vector2i.ZERO
