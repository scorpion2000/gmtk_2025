# WallsManager.gd — uses RoomManagerTest cells, draws bright-red doors
class_name WallsManager
extends Node2D

@export var room_manager_path: $RoomManagerTest
@export var cell_size: Vector2i = Vector2i(352, 352)

# Gap and visuals
@export var wall_thickness: float = 36.0         # thickness of the border line between rooms (in px)
@export var door_width: float = 96.0              # opening width along the wall (in px)
@export_range(0.0, 1.0, 0.01) var door_chance: float = 0.5
@export var show_debug_walls: bool = true
@export var wall_color: Color = Color(0.15, 0.15, 0.18, 0.45)
@export var door_color: Color = Color(1.0, 0.0, 0.0, 0.95) # BRIGHT RED

# build timing
@export var refresh_seconds: float = 0.25

# internal
var rm: Node = null
var timer: Timer
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Per-cell door spec:
# { "mask":int, "n_t":float, "e_t":float, "s_t":float, "w_t":float, "centers":Dictionary }
# where t is 0..1 along that edge (0=left/top, 1=right/bottom)
var door_specs: Dictionary = {}             # Vector2i -> Dictionary

func _ready() -> void:
	rng.randomize()

	if room_manager_path != NodePath(""):
		rm = get_node_or_null(room_manager_path)

	# Read cell size from manager if available
	if rm != null:
		var cs = rm.get("cellSize")
		if typeof(cs) == TYPE_VECTOR2I:
			cell_size = cs
		elif typeof(cs) == TYPE_VECTOR2:
			var v: Vector2 = cs
			cell_size = Vector2i(int(v.x), int(v.y))

	timer = Timer.new()
	timer.wait_time = refresh_seconds
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_rebuild)

	_rebuild()

# ---------------- public ----------------
func get_door_centers_world(g: Vector2i) -> Dictionary:
	if door_specs.has(g):
		var spec: Dictionary = door_specs[g]
		if spec.has("centers"):
			return spec["centers"]
	return {}

# ---------------- rebuild ----------------
func _rebuild() -> void:
	if rm == null:
		return

	# Gather present rooms (assumes colored room Node2D are direct children of RoomManagerTest)
	var present: Array[Vector2i] = []
	var center_by_grid: Dictionary = {}  # Vector2i -> Vector2
	for child in rm.get_children():
		if child is Node2D and child.get_parent() == rm:
			var n := child as Node2D
			var g := _world_to_grid(n.global_position)
			present.append(g)
			center_by_grid[g] = n.global_position

	# Prune specs for missing cells
	var to_erase: Array[Vector2i] = []
	for k in door_specs.keys():
		var key: Vector2i = k
		if not present.has(key):
			to_erase.append(key)
	for k2 in to_erase:
		door_specs.erase(k2)

	# Clear previous geometry
	_clear_children()

	# Ensure specs first (so neighbors align)
	for g in present:
		_ensure_spec(g)

	# Build borders (avoid duplicates: each cell owns EAST and SOUTH; NORTH/WEST only if border)
	for g2 in present:
		_build_for_cell(g2, center_by_grid[g2], present)

# ---------------- spec ----------------
func _ensure_spec(g: Vector2i) -> Dictionary:
	if door_specs.has(g):
		return door_specs[g] as Dictionary

	var mask: int = 0
	var n_t: float = -1.0
	var e_t: float = -1.0
	var s_t: float = -1.0
	var w_t: float = -1.0

	var nkey := Vector2i(g.x, g.y - 1)
	var skey := Vector2i(g.x, g.y + 1)
	var ekey := Vector2i(g.x + 1, g.y)
	var wkey := Vector2i(g.x - 1, g.y)

	# Pull door from neighbor if it already exists, otherwise random chance
	if door_specs.has(nkey) and (int(door_specs[nkey]["mask"]) & (1 << 2)) != 0:
		mask |= 1 << 0; n_t = float(door_specs[nkey]["s_t"])
	elif rng.randf() < door_chance:
		mask |= 1 << 0; n_t = rng.randf_range(0.25, 0.75)

	if door_specs.has(skey) and (int(door_specs[skey]["mask"]) & (1 << 0)) != 0:
		mask |= 1 << 2; s_t = float(door_specs[skey]["n_t"])
	elif rng.randf() < door_chance:
		mask |= 1 << 2; s_t = rng.randf_range(0.25, 0.75)

	if door_specs.has(ekey) and (int(door_specs[ekey]["mask"]) & (1 << 3)) != 0:
		mask |= 1 << 1; e_t = float(door_specs[ekey]["w_t"])
	elif rng.randf() < door_chance:
		mask |= 1 << 1; e_t = rng.randf_range(0.25, 0.75)

	if door_specs.has(wkey) and (int(door_specs[wkey]["mask"]) & (1 << 1)) != 0:
		mask |= 1 << 3; w_t = float(door_specs[wkey]["e_t"])
	elif rng.randf() < door_chance:
		mask |= 1 << 3; w_t = rng.randf_range(0.25, 0.75)

	var spec: Dictionary = {"mask":mask, "n_t":n_t, "e_t":e_t, "s_t":s_t, "w_t":w_t, "centers": {}}
	door_specs[g] = spec
	return spec

# ---------------- geometry ----------------
func _build_for_cell(g: Vector2i, center: Vector2, present: Array[Vector2i]) -> void:
	var spec: Dictionary = door_specs[g]
	var centers: Dictionary = spec["centers"] as Dictionary

	var halfx: float = float(cell_size.x) * 0.5
	var halfy: float = float(cell_size.y) * 0.5
	var t: float = wall_thickness
	var dw: float = clampf(door_width, 0.0, float(cell_size.x))

	# Precompute door centers if there is a door on that side
	if ((int(spec["mask"]) & (1 << 0)) != 0) and float(spec["n_t"]) >= 0.0:
		var cx_n := center.x + (float(spec["n_t"]) - 0.5) * float(cell_size.x)
		centers["N"] = Vector2(cx_n, center.y - halfy)
	if ((int(spec["mask"]) & (1 << 2)) != 0) and float(spec["s_t"]) >= 0.0:
		var cx_s := center.x + (float(spec["s_t"]) - 0.5) * float(cell_size.x)
		centers["S"] = Vector2(cx_s, center.y + halfy)
	if ((int(spec["mask"]) & (1 << 1)) != 0) and float(spec["e_t"]) >= 0.0:
		var cy_e := center.y + (float(spec["e_t"]) - 0.5) * float(cell_size.y)
		centers["E"] = Vector2(center.x + halfx, cy_e)
	if ((int(spec["mask"]) & (1 << 3)) != 0) and float(spec["w_t"]) >= 0.0:
		var cy_w := center.y + (float(spec["w_t"]) - 0.5) * float(cell_size.y)
		centers["W"] = Vector2(center.x - halfx, cy_w)

	# NORTH (only if border)
	if not present.has(Vector2i(g.x, g.y - 1)):
		if centers.has("N"):
			_build_hline_with_door(center, -halfy, float(centers["N"].x), t, dw, true)
			_draw_door_visual(Vector2(float(centers["N"].x), center.y - halfy), Vector2(dw, t))
		else:
			_add_wall_rect(Vector2(center.x, center.y - halfy), Vector2(float(cell_size.x), t))

	# SOUTH (owned by this cell)
	if centers.has("S"):
		_build_hline_with_door(center, +halfy, float(centers["S"].x), t, dw, true)
		_draw_door_visual(Vector2(float(centers["S"].x), center.y + halfy), Vector2(dw, t))
	else:
		_add_wall_rect(Vector2(center.x, center.y + halfy), Vector2(float(cell_size.x), t))

	# WEST (only if border)
	if not present.has(Vector2i(g.x - 1, g.y)):
		if centers.has("W"):
			_build_vline_with_door(center, -halfx, float(centers["W"].y), t, dw, true)
			_draw_door_visual(Vector2(center.x - halfx, float(centers["W"].y)), Vector2(t, dw))
		else:
			_add_wall_rect(Vector2(center.x - halfx, center.y), Vector2(t, float(cell_size.y)))

	# EAST (owned by this cell)
	if centers.has("E"):
		_build_vline_with_door(center, +halfx, float(centers["E"].y), t, dw, true)
		_draw_door_visual(Vector2(center.x + halfx, float(centers["E"].y)), Vector2(t, dw))
	else:
		_add_wall_rect(Vector2(center.x + halfx, center.y), Vector2(t, float(cell_size.y)))

	door_specs[g] = spec

# Horizontal line at y-offset (+/-halfy). Cuts an opening centered at cx.
func _build_hline_with_door(center: Vector2, y_off: float, cx: float, thick: float, door_w: float, own_edge: bool) -> void:
	var x0 := center.x - float(cell_size.x) * 0.5
	var x1 := center.x + float(cell_size.x) * 0.5
	var left_len := (cx - door_w * 0.5) - x0
	var right_len := x1 - (cx + door_w * 0.5)
	if left_len > 0.0:
		_add_wall_rect(Vector2(x0 + left_len * 0.5, center.y + y_off), Vector2(left_len, thick))
	if right_len > 0.0:
		_add_wall_rect(Vector2(cx + door_w * 0.5 + right_len * 0.5, center.y + y_off), Vector2(right_len, thick))

# Vertical line at x-offset (+/-halfx). Cuts an opening centered at cy.
func _build_vline_with_door(center: Vector2, x_off: float, cy: float, thick: float, door_w: float, own_edge: bool) -> void:
	var y0 := center.y - float(cell_size.y) * 0.5
	var y1 := center.y + float(cell_size.y) * 0.5
	var top_len := (cy - door_w * 0.5) - y0
	var bot_len := y1 - (cy + door_w * 0.5)
	if top_len > 0.0:
		_add_wall_rect(Vector2(center.x + x_off, y0 + top_len * 0.5), Vector2(thick, top_len))
	if bot_len > 0.0:
		_add_wall_rect(Vector2(center.x + x_off, cy + door_w * 0.5 + bot_len * 0.5), Vector2(thick, bot_len))

# ---------------- spawning helpers ----------------
func _add_wall_rect(center: Vector2, size: Vector2) -> void:
	# collider
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
	add_child(body)

	# optional visual
	if show_debug_walls:
		var r := ColorRect.new()
		r.size = size
		r.position = -size * 0.5
		r.color = wall_color
		r.z_index = 101
		body.add_child(r)

func _draw_door_visual(center: Vector2, size: Vector2) -> void:
	var node := Node2D.new()
	node.global_position = center
	node.z_index = 200
	add_child(node)

	var rect := ColorRect.new()
	rect.size = size
	rect.position = -size * 0.5
	rect.color = door_color     # bright red door slab (visual only)
	rect.z_index = 201
	node.add_child(rect)

# ---------------- utils ----------------
func _world_to_grid(p: Vector2) -> Vector2i:
	var gx := int(floor(p.x / float(cell_size.x) + 0.5))
	var gy := int(floor(p.y / float(cell_size.y) + 0.5))
	return Vector2i(gx, gy)

func _clear_children() -> void:
	var to_free: Array[Node] = []
	for c in get_children():
		if c != timer:
			to_free.append(c)
	for n in to_free:
		n.queue_free()
