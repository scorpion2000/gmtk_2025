# RoomManagerTest.gd (Godot 4.x)
class_name RoomManagerTest
extends Node

@export var cellSize: Vector2i = Vector2i(352, 352)

var rooms: Dictionary[Vector2i, Node2D] = {}                           # key: Vector2i -> Node2D
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

const ROOM_TYPES := [
	{"name":"LIVING",  "color": Color(0.6, 0.6, 0.6)},
	{"name":"KITCHEN", "color": Color(0.9, 0.9, 0.3)},
	{"name":"SHRINE",  "color": Color(0.3, 0.5, 0.9)},
	{"name":"BEDROOM", "color": Color(0.6, 0.3, 0.8)},
]

func _ready() -> void:
	rng.randomize()

# --- API ---
func configure(size: Vector2i) -> void:
	cellSize = size

func ensureRegion(center: Vector2i, radius: int) -> void:
	var x := center.x - radius
	while x <= center.x + radius:
		var y := center.y - radius
		while y <= center.y + radius:
			ensureRoom(Vector2i(x, y))
			y += 1
		x += 1

func showOnlyWithin(center: Vector2i, radius: int) -> void:
	var toRemove: Array[Vector2i] = []
	for k in rooms.keys():
		var key: Vector2i = k
		var dx := absi(key.x - center.x)
		var dy := absi(key.y - center.y)
		var d := dx if dx >= dy else dy
		(rooms[key] as Node2D).visible = d <= radius
		if d > radius + 1:
			toRemove.append(key)
	for r in toRemove:
		if is_instance_valid(rooms[r]):
			rooms[r].queue_free()
		rooms.erase(r)

func ensureRoom(g: Vector2i) -> void:
	if rooms.has(g):
		return
	var idx := rng.randi_range(0, ROOM_TYPES.size() - 1)
	var t: Dictionary = ROOM_TYPES[idx]
	var node := makeRoom(String(t["name"]), t["color"] as Color)
	node.position = Vector2(g.x * cellSize.x, g.y * cellSize.y)  # center of cell
	add_child(node)
	rooms[g] = node

# --- visuals ---
func makeRoom(labelText: String, c: Color) -> Node2D:
	var n := Node2D.new()

	var bg := ColorRect.new()
	bg.size = Vector2(cellSize) * 0.9
	bg.position = -bg.size * 0.5
	bg.color = c
	n.add_child(bg)

	var border := ColorRect.new()
	border.size = bg.size + Vector2(4, 4)
	border.position = bg.position - Vector2(2, 2)
	border.color = Color(0, 0, 0, 0.6)
	n.add_child(border)
	border.move_to_front()

	var label := Label.new()
	label.text = labelText
	label.position = Vector2(-40, -10)  # simple nudge; tweak as you like
	n.add_child(label)

	createWalls()

	return n

func createWalls():
	pass