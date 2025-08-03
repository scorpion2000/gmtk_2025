# RoomManagerTest.gd (Godot 4.x) — Rooms + Walls in one script
class_name RoomManagerTest
extends Node

# ---------------- Room visuals ----------------
@export var cellSize: Vector2i = Vector2i(352, 352)

var rooms: Dictionary = {}                           # key: Vector2i -> Node2D
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

const ROOM_TYPES := [
	{"name":"LIVING",  "color": Color(0.6, 0.6, 0.6)},
	{"name":"KITCHEN", "color": Color(0.9, 0.9, 0.3)},
	{"name":"SHRINE",  "color": Color(0.3, 0.5, 0.9)},
	{"name":"BEDROOM", "color": Color(0.6, 0.3, 0.8)},
]

# ---------------- Walls / Doors ----------------
@export var wall_thickness: float = 36.0            # thickness of the divider bars (px)
@export var door_width: float = 96.0                # width of the opening (px)
@export_range(0.0, 1.0, 0.01) var door_chance: float = 0.55
@export var door_clearance: float = 2.0  # tiny gap to guarantee passage

@export var show_wall_debug: bool = true
@export var wall_color: Color = Color(0.15, 0.15, 0.18, 0.55)
@export var door_color: Color = Color(1.0, 0.0, 0.0, 0.95) # BRIGHT RED

var _walls_root: Node2D = null
var _edge_nodes := {}       # String -> Array[Node]   (spawned nodes for that edge)
var _door_centers := {}     # Vector2i -> Dictionary("N"/"E"/"S"/"W" -> Vector2 world pos)

func _ready() -> void:
	rng.randomize()
	_ensure_walls_root()

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
	var toRemove: Array = []
	for k in rooms.keys():
		var key: Vector2i = k
		var dx := absi(key.x - center.x)
		var dy := absi(key.y - center.y)
		var d := dx
		if dy > dx:
			d = dy
		(rooms[key] as Node2D).visible = d <= radius
		if d > radius + 1:
			toRemove.append(key)
	for r in toRemove:
		if is_instance_valid(rooms[r]):
			rooms[r].queue_free()
		rooms.erase(r)
		_rebuild_around(r)

func ensureRoom(g: Vector2i) -> void:
	_ensure_walls_root()
	if rooms.has(g):
		return
	var idx := rng.randi_range(0, ROOM_TYPES.size() - 1)
	var t: Dictionary = ROOM_TYPES[idx]
	var node := makeRoom(String(t["name"]), t["color"] as Color)
	node.position = Vector2(g.x * cellSize.x, g.y * cellSize.y)  # center of cell
	add_child(node)
	rooms[g] = node
	_rebuild_around(g)

# AI helper: returns "N","E","S","W" -> world Vector2 for any door on that side
func get_door_centers_world(g: Vector2i) -> Dictionary:
	if _door_centers.has(g):
		return _door_centers[g]
	return {}

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
	label.position = Vector2(-40, -10)
	n.add_child(label)

	return n

# ================= Walls/Doors implementation =================

func _ensure_walls_root() -> void:
	if _walls_root == null:
		_walls_root = Node2D.new()
		_walls_root.name = "Walls"
		add_child(_walls_root)

func _world_center(g: Vector2i) -> Vector2:
	return Vector2(g.x * cellSize.x, g.y * cellSize.y)

func _has_room(g: Vector2i) -> bool:
	return rooms.has(g)

func _ordered_pair_key(a: Vector2i, b: Vector2i, orient: String) -> String:
	var ax := a.x
	var ay := a.y
	var bx := b.x
	var by := b.y
	var swap := false
	if bx < ax:
		swap = true
	elif bx == ax and by < ay:
		swap = true
	if swap:
		return str(bx, ",", by, "|", ax, ",", ay, "|", orient)
	return str(ax, ",", ay, "|", bx, ",", by, "|", orient)

func _border_key(g: Vector2i, side: String) -> String:
	return str("B|", g.x, ",", g.y, "|", side)

func _randf_for_key(key: String) -> float:
	var h := hash(key)
	var v := float(h & 0xffffffff) / float(0xffffffff)
	if v < 0.0:
		v = -v
	return fmod(v, 1.0)

func _rebuild_around(center_g: Vector2i) -> void:
	_ensure_walls_root()
	_clear_door_entry(center_g)
	_clear_door_entry(Vector2i(center_g.x + 1, center_g.y))
	_clear_door_entry(Vector2i(center_g.x - 1, center_g.y))
	_clear_door_entry(Vector2i(center_g.x, center_g.y + 1))
	_clear_door_entry(Vector2i(center_g.x, center_g.y - 1))

	_build_internal_edge(center_g, Vector2i(center_g.x + 1, center_g.y), true)   # vertical divider
	_build_internal_edge(center_g, Vector2i(center_g.x, center_g.y + 1), false)  # horizontal divider
	_build_internal_edge(Vector2i(center_g.x - 1, center_g.y), center_g, true)
	_build_internal_edge(Vector2i(center_g.x, center_g.y - 1), center_g, false)

	_build_border_if_needed(center_g, "N")
	_build_border_if_needed(center_g, "W")
	_build_border_if_needed(center_g, "E")
	_build_border_if_needed(center_g, "S")

func _clear_door_entry(g: Vector2i) -> void:
	if _door_centers.has(g):
		_door_centers.erase(g)

func _clear_edge_nodes(edge_key: String) -> void:
	if _edge_nodes.has(edge_key):
		var arr = _edge_nodes[edge_key]
		for n in arr:
			if is_instance_valid(n):
				n.queue_free()
		_edge_nodes.erase(edge_key)

func _store_edge_nodes(edge_key: String, arr) -> void:
	_edge_nodes[edge_key] = arr

func _build_internal_edge(a: Vector2i, b: Vector2i, vertical: bool) -> void:
	if not _has_room(a) or not _has_room(b):
		return

	var orient := "V" if vertical else "H"
	var key := _ordered_pair_key(a, b, orient)
	_clear_edge_nodes(key)

	var nodes := []
	var cA := _world_center(a)
	var halfx := float(cellSize.x) * 0.5
	var halfy := float(cellSize.y) * 0.5
	var t := wall_thickness
	var dw := clampf(door_width, 0.0, float(cellSize.x))
	var eps := door_clearance

	# deterministic door on this edge
	var r := _randf_for_key(key)
	var has_door := r < door_chance
	var tpos := 0.5
	if has_door:
		var r2 := _randf_for_key(key + "_t")
		tpos = 0.3 + 0.4 * r2

	if vertical:
		var xline := cA.x + halfx
		if has_door:
			var cy := cA.y + (tpos - 0.5) * float(cellSize.y)

			# TOP piece (stop a bit before the door)
			var top_len := (cy - dw * 0.5) - (cA.y - halfy) - eps
			if top_len > 0.0:
				nodes.append(_add_wall_rect(
					Vector2(xline, cA.y - halfy + top_len * 0.5),
					Vector2(t, top_len)
				))

			# BOTTOM piece (start a bit after the door)
			var bot_len := (cA.y + halfy) - (cy + dw * 0.5) - eps
			if bot_len > 0.0:
				nodes.append(_add_wall_rect(
					Vector2(xline, cy + dw * 0.5 + eps + bot_len * 0.5),
					Vector2(t, bot_len)
				))

			nodes.append(_draw_door_visual(Vector2(xline, cy), Vector2(t, dw)))
			_set_door_center(a, "E", Vector2(xline, cy))
			_set_door_center(b, "W", Vector2(xline, cy))
		else:
			nodes.append(_add_wall_rect(Vector2(xline, cA.y), Vector2(t, float(cellSize.y))))
	else:
		var yline := cA.y + halfy
		if has_door:
			var cx := cA.x + (tpos - 0.5) * float(cellSize.x)

			# LEFT piece
			var left_len := (cx - dw * 0.5) - (cA.x - halfx) - eps
			if left_len > 0.0:
				nodes.append(_add_wall_rect(
					Vector2(cA.x - halfx + left_len * 0.5, yline),
					Vector2(left_len, t)
				))

			# RIGHT piece
			var right_len := (cA.x + halfx) - (cx + dw * 0.5) - eps
			if right_len > 0.0:
				nodes.append(_add_wall_rect(
					Vector2(cx + dw * 0.5 + eps + right_len * 0.5, yline),
					Vector2(right_len, t)
				))

			nodes.append(_draw_door_visual(Vector2(cx, yline), Vector2(dw, t)))
			_set_door_center(a, "S", Vector2(cx, yline))
			_set_door_center(b, "N", Vector2(cx, yline))
		else:
			nodes.append(_add_wall_rect(Vector2(cA.x, yline), Vector2(float(cellSize.x), t)))

	_store_edge_nodes(key, nodes)


func _build_border_if_needed(g: Vector2i, side: String) -> void:
	var neighbor := g
	if side == "N":
		neighbor = Vector2i(g.x, g.y - 1)
	elif side == "S":
		neighbor = Vector2i(g.x, g.y + 1)
	elif side == "E":
		neighbor = Vector2i(g.x + 1, g.y)
	else:
		neighbor = Vector2i(g.x - 1, g.y)

	if _has_room(neighbor):
		return

	var key := _border_key(g, side)
	_clear_edge_nodes(key)

	var nodes := []
	var c := _world_center(g)
	var halfx := float(cellSize.x) * 0.5
	var halfy := float(cellSize.y) * 0.5
	var t := wall_thickness

	if side == "N":
		nodes.append(_add_wall_rect(Vector2(c.x, c.y - halfy), Vector2(float(cellSize.x), t)))
	elif side == "S":
		nodes.append(_add_wall_rect(Vector2(c.x, c.y + halfy), Vector2(float(cellSize.x), t)))
	elif side == "E":
		nodes.append(_add_wall_rect(Vector2(c.x + halfx, c.y), Vector2(t, float(cellSize.y))))
	else: # "W"
		nodes.append(_add_wall_rect(Vector2(c.x - halfx, c.y), Vector2(t, float(cellSize.y))))

	_store_edge_nodes(key, nodes)

# ---------------- spawn helpers ----------------
func _add_wall_rect(center: Vector2, size: Vector2) -> Node:
	_ensure_walls_root()
	var body := StaticBody2D.new()
	body.global_position = center
	body.z_index = 100
	body.collision_layer = 1
	body.collision_mask = 1

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	_walls_root.add_child(body)

	if show_wall_debug:
		var r := ColorRect.new()
		r.size = size
		r.position = -size * 0.5
		r.color = wall_color
		r.z_index = 101
		body.add_child(r)

	return body

func _draw_door_visual(center: Vector2, size: Vector2) -> Node:
	_ensure_walls_root()
	var n := Node2D.new()
	n.global_position = center
	n.z_index = 200
	_walls_root.add_child(n)

	var rect := ColorRect.new()
	rect.size = size
	rect.position = -size * 0.5
	rect.color = door_color
	rect.z_index = 201
	n.add_child(rect)
	return n

func _set_door_center(g: Vector2i, side: String, pos: Vector2) -> void:
	if not _door_centers.has(g):
		_door_centers[g] = {}
	var d: Dictionary = _door_centers[g]
	d[side] = pos
	_door_centers[g] = d
