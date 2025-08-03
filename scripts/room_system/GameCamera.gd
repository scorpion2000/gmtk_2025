extends Camera2D

@export var player_path: NodePath
@export var room_manager_path: NodePath
@export var cell_size: Vector2 = Vector2(352, 352)
@export var grid_origin: Vector2 = Vector2.ZERO
@export var margin: Vector2 = Vector2(24, 24)
@export var snap_to_room: bool = true   # true=center per room, false=lock to player

var player: Node2D = null
var _last_cx: int = -2147483648
var _last_cy: int = -2147483648

func _ready() -> void:
	enabled = true
	make_current()

	# If a RoomManagerTest is provided, pull its cell size (Vector2i -> Vector2).
	if room_manager_path != NodePath(""):
		var rm_node := get_node_or_null(room_manager_path)
		if rm_node != null:
			if rm_node is RoomManagerTest:
				var rm := rm_node as RoomManagerTest
				cell_size = Vector2(rm.cellSize)
			# optional origin node if you use one
			if rm_node.has_node("RoomContainer"):
				var cont := rm_node.get_node("RoomContainer") as Node2D
				if cont != null:
					grid_origin = cont.global_position

	# Find player
	if player_path != NodePath(""):
		player = get_node_or_null(player_path) as Node2D
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		push_warning("RoomSnapCamera: No player found. Set player_path or add player to 'player' group.")

	_fit_zoom_to_room()
	get_viewport().size_changed.connect(_fit_zoom_to_room)

func _process(_dt: float) -> void:
	if player == null:
		return

	if snap_to_room:
		var p: Vector2 = player.global_position - grid_origin
		var cx: int = floori(p.x / cell_size.x)
		var cy: int = floori(p.y / cell_size.y)
		if cx != _last_cx or cy != _last_cy:
			_last_cx = cx
			_last_cy = cy
			var target: Vector2 = grid_origin + Vector2(
				float(cx) * cell_size.x + cell_size.x * 0.5,
				float(cy) * cell_size.y + cell_size.y * 0.5
			)
			global_position = target
	else:
		global_position = player.global_position

func _fit_zoom_to_room() -> void:
	# Fit one room (+margin) fully in view with uniform zoom.
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var target_size: Vector2 = cell_size + margin * 2.0
	var zx: float = vp.x / target_size.x
	var zy: float = vp.y / target_size.y
	var z: float = zx
	if zy < zx:
		z = zy
	zoom = Vector2(z, z)
