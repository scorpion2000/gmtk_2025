class_name MiniMap
extends Control

# Mini-map settings
@export var room_size: Vector2 = Vector2(20, 20)
@export var room_spacing: Vector2 = Vector2(4, 4)

# Room colors
var room_colors = {
	RoomData.RoomType.LIVING_ROOM: Color.GRAY,
	RoomData.RoomType.STARTING: Color.GREEN,
	RoomData.RoomType.KITCHEN: Color.YELLOW,
	RoomData.RoomType.SHRINE: Color.BLUE,
	RoomData.RoomType.BEDROOM: Color.PURPLE
}

# Current state
var level_generator: LevelGenerator
var current_room: RoomData
var room_sprites: Dictionary = {}

# UI elements
@onready var room_container: Control = $RoomContainer

func _ready():
	# Set up the mini-map container
	if not room_container:
		room_container = Control.new()
		room_container.name = "RoomContainer"
		add_child(room_container)

# Initialize mini-map with level data
func initialize(generator: LevelGenerator):
	level_generator = generator
	_clear_map()
	_create_room_sprites()
	_center_minimap()

# Clear existing mini-map
func _clear_map():
	for child in room_container.get_children():
		child.queue_free()
	room_sprites.clear()

# Create sprites for all rooms
func _create_room_sprites():
	if not level_generator:
		return
	
	for room in level_generator.all_rooms:
		_create_room_sprite(room)

# Create a sprite for a single room
func _create_room_sprite(room: RoomData):
	var room_rect = ColorRect.new()
	room_rect.name = "Room_" + str(room.grid_x) + "_" + str(room.grid_y)
	room_rect.size = room_size
	
	# Position based on grid coordinates
	var pos = Vector2(
		room.grid_x * (room_size.x + room_spacing.x),
		room.grid_y * (room_size.y + room_spacing.y)
	)
	room_rect.position = pos
	
	# Set color based on room type
	var color = room_colors.get(room.room_type, Color.GRAY)
	room_rect.color = color
	
	# Fog of war: Initially hidden until visited
	if room.is_visited:
		room_rect.modulate = Color.WHITE
	else:
		room_rect.modulate = Color.TRANSPARENT
	
	room_container.add_child(room_rect)
	room_sprites[room] = room_rect

# Center the minimap in the available space
func _center_minimap():
	if level_generator == null or level_generator.all_rooms.is_empty():
		return
	
	# Find bounds of all rooms
	var min_x = level_generator.all_rooms[0].grid_x
	var max_x = level_generator.all_rooms[0].grid_x
	var min_y = level_generator.all_rooms[0].grid_y
	var max_y = level_generator.all_rooms[0].grid_y
	
	for room in level_generator.all_rooms:
		min_x = min(min_x, room.grid_x)
		max_x = max(max_x, room.grid_x)
		min_y = min(min_y, room.grid_y)
		max_y = max(max_y, room.grid_y)
	
	# Calculate total size needed
	var total_width = (max_x - min_x + 1) * (room_size.x + room_spacing.x) - room_spacing.x
	var total_height = (max_y - min_y + 1) * (room_size.y + room_spacing.y) - room_spacing.y
	
	# Calculate offset to center in container
	var container_size = room_container.size
	var offset_x = (container_size.x - total_width) / 2 - min_x * (room_size.x + room_spacing.x)
	var offset_y = (container_size.y - total_height) / 2 - min_y * (room_size.y + room_spacing.y)
	
	# Apply offset to all room sprites
	for room_sprite in room_sprites.values():
		room_sprite.position += Vector2(offset_x, offset_y)

# Update mini-map when room changes
func update_current_room(room: RoomData):
	# Remove highlight from previous room
	if current_room and room_sprites.has(current_room):
		var prev_sprite = room_sprites[current_room]
		# Return to normal visited color (not highlighted)
		prev_sprite.modulate = Color.WHITE
	
	# Set new current room
	current_room = room
	
	# Reveal and highlight current room
	if room_sprites.has(room):
		var room_sprite = room_sprites[room]
		# Mark as visited and make visible
		room.is_visited = true
		room_sprite.modulate = Color.WHITE
		
		# Highlight current room (make it brighter)
		room_sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)
	
	# Update all room sprites based on visited status
	_update_room_visibility()

# Update visibility of all room sprites based on visited status
func _update_room_visibility():
	for room in level_generator.all_rooms:
		if room_sprites.has(room):
			var room_sprite = room_sprites[room]
			if room.is_visited:
				# Show visited rooms
				if room == current_room:
					room_sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)  # Highlighted current room
				else:
					room_sprite.modulate = Color.WHITE  # Normal visited room
			else:
				# Hide unvisited rooms
				room_sprite.modulate = Color.TRANSPARENT
