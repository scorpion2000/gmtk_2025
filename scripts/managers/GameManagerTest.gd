
class_name GameManagerTest
extends Node

@export var roomManagerPath: NodePath
@export var playerPath: NodePath
@export var roomSize: Vector2i = Vector2i(352, 352)
@export var regionRadius: int = 2

var rm: RoomManagerTest
var player: Node2D
var currentGrid: Vector2i = Vector2i.ZERO

func _ready() -> void:
	randomize()
	var scene_root = get_tree().get_current_scene() as Node
	if roomManagerPath.is_empty():
		rm = scene_root.get_node("RoomManagerTest") as RoomManagerTest
	else:
		rm = get_node(roomManagerPath) as RoomManagerTest
	if playerPath.is_empty():
		player = get_tree().get_first_node_in_group("player") as Node2D
	else:
		player = get_node(playerPath) as Node2D
	assert(rm and player)
	rm.configure(roomSize)
	currentGrid = worldToGrid(player.global_position)
	rm.ensureRegion(currentGrid, regionRadius)
	rm.showOnlyWithin(currentGrid, regionRadius + 1)
	print("Initial region generated around ", currentGrid)

func _process(_dt: float) -> void:
	var g = worldToGrid(player.global_position)
	if g != currentGrid:
		currentGrid = g
		rm.ensureRegion(currentGrid, regionRadius)
		rm.showOnlyWithin(currentGrid, regionRadius + 1)
		print("Moved to cell ", g)

func worldToGrid(p: Vector2) -> Vector2i:
	var gx = int(floor(p.x / float(roomSize.x) + 0.5))
	var gy = int(floor(p.y / float(roomSize.y) + 0.5))
	return Vector2i(gx, gy)

func gridToWorld(g: Vector2i) -> Vector2:
	return Vector2(g.x * roomSize.x, g.y * roomSize.y)
