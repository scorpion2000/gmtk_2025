# PlayerTest.gd
class_name PlayerTest
extends CharacterBody2D

@export var walk_speed: float = 100.0
@export var sprint_speed: float = 180.0
@export var acceleration: float = 12.0
@export var friction: float = 15.0

@export var anim_path: NodePath
var anim: AnimatedSprite2D = null

var is_rummaging: bool = false
var current_speed: float = 0.0
var base_walk_speed: float
var base_sprint_speed: float
var speed_modifiers: Array[float] = []
var face_dir: Vector2 = Vector2.DOWN

func _ready() -> void:
	add_to_group("player")
	base_walk_speed = walk_speed
	base_sprint_speed = sprint_speed
	_ensure_default_input()

	if anim_path == NodePath(""):
		if has_node("AnimatedSprite2D"):
			anim = get_node("AnimatedSprite2D")
	else:
		anim = get_node_or_null(anim_path)

func _physics_process(delta: float) -> void:
	var dir: Vector2 = Input.get_vector("left", "right", "up", "down").normalized()
	var sprinting: bool = Input.is_action_pressed("sprint")
	is_rummaging = Input.is_action_pressed("interact")

	var target_speed: float = walk_speed
	if sprinting:
		target_speed = sprint_speed

	var lerp_factor: float = acceleration * delta
	if lerp_factor > 1.0:
		lerp_factor = 1.0
	current_speed = lerp(current_speed, target_speed, lerp_factor)

	if dir != Vector2.ZERO:
		face_dir = dir
		velocity = velocity.move_toward(dir * current_speed, acceleration * current_speed * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * current_speed * delta)

	move_and_slide()
	_update_anim(dir)

# ---------------- speed modifiers ----------------
func apply_speed_modifier(multiplier: float) -> void:
	speed_modifiers.append(multiplier)
	_update_speeds()

func remove_speed_modifier(multiplier: float) -> void:
	var idx: int = speed_modifiers.find(multiplier)
	if idx != -1:
		speed_modifiers.remove_at(idx)
	_update_speeds()

func _update_speeds() -> void:
	var total: float = 1.0
	for m in speed_modifiers:
		total *= m
	walk_speed = base_walk_speed * total
	sprint_speed = base_sprint_speed * total

# ---------------- animation ----------------
func _update_anim(move_dir: Vector2) -> void:
	if anim == null:
		return

	var base: String = "idle"
	if is_rummaging:
		base = "rummage"
	elif move_dir != Vector2.ZERO:
		base = "walk"

	var orient: String = _dir_to_orient(face_dir)  # "up","down","side"
	if orient == "side":
		_play_side(base, face_dir.x)
	else:
		_play_updown(base, orient)

func _dir_to_orient(d: Vector2) -> String:
	var ax: float = absf(d.x)
	var ay: float = absf(d.y)
	if ax > ay:
		return "side"
	if d.y < 0.0:
		return "up"
	return "down"

func _play_side(base: String, dx: float) -> void:
	# Priority: *sideleft / *sideright / *side then fallbacks.
	var chosen: String = ""
	var frames: SpriteFrames = anim.sprite_frames

	if frames.has_animation(base + "sideleft"):
		chosen = base + "sideleft"
		anim.flip_h = dx > 0.0            # moving right? flip the left-facing clip
	elif frames.has_animation(base + "sideright"):
		chosen = base + "sideright"
		anim.flip_h = dx < 0.0            # moving left? flip the right-facing clip
	elif frames.has_animation(base + "side"):
		chosen = base + "side"
		# With a neutral side clip, flip when moving left.
		anim.flip_h = dx < 0.0
	else:
		# Fallbacks: left/right, then down/up, then base
		if dx < 0.0 and frames.has_animation(base + "left"):
			chosen = base + "left"; anim.flip_h = false
		elif dx >= 0.0 and frames.has_animation(base + "right"):
			chosen = base + "right"; anim.flip_h = false
		elif frames.has_animation(base + "down"):
			chosen = base + "down"; anim.flip_h = false
		elif frames.has_animation(base + "up"):
			chosen = base + "up"; anim.flip_h = false
		else:
			chosen = base; anim.flip_h = false

	if anim.animation != chosen:
		anim.play(chosen)

func _play_updown(base: String, orient: String) -> void:
	var frames: SpriteFrames = anim.sprite_frames
	var name: String = ""
	if frames.has_animation(base + orient):
		name = base + orient
	elif frames.has_animation(base):
		name = base
	else:
		# Try a sensible other direction as last resort
		if orient == "up" and frames.has_animation(base + "down"):
			name = base + "down"
		elif orient == "down" and frames.has_animation(base + "up"):
			name = base + "up"
		else:
			name = base
	anim.flip_h = false
	if anim.animation != name:
		anim.play(name)

# ---------------- inputs ----------------
func _ensure_default_input() -> void:
	_add_key("left", KEY_A);   _add_key("left", KEY_LEFT)
	_add_key("right", KEY_D);  _add_key("right", KEY_RIGHT)
	_add_key("up", KEY_W);     _add_key("up", KEY_UP)
	_add_key("down", KEY_S);   _add_key("down", KEY_DOWN)
	_add_key("sprint", KEY_SHIFT)
	_add_key("interact", KEY_E)

func _add_key(action: String, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)
