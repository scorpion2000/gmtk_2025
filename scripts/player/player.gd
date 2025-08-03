class_name Player
extends EntityBase

@export var Stats : StatsList
var walk_speed: float = 100.0
var sprint_speed: float = 180.0
@export var acceleration: float = 12.0
@export var friction: float = 15.0

var is_rummaging: bool = false
var current_speed: float
# Base speeds for buff calculations
var base_walk_speed: float
var base_sprint_speed: float
var speed_modifiers: Array[float] = []
var face_dir: Vector2 = Vector2.DOWN

func _ready() -> void:
	add_to_group("player")
	# Store base speeds
	base_walk_speed = Stats.getStatRef("speed").getValue()
	base_sprint_speed = Stats.getStatRef("speed").getMaxValue()

func apply_speed_modifier(multiplier: float) -> void:
	speed_modifiers.append(multiplier)
	update_speeds()

func remove_speed_modifier(multiplier: float) -> void:
	speed_modifiers.erase(multiplier)
	update_speeds()

func update_speeds() -> void:
	# Calculate total multiplier
	var total_multiplier = 1.0
	for modifier in speed_modifiers:
		total_multiplier *= modifier
	
	# Apply to base speeds
	walk_speed = base_walk_speed * total_multiplier
	sprint_speed = base_sprint_speed * total_multiplier

func _physics_process(delta: float): 
	var direction = Input.get_vector("left", "right", "up", "down").normalized()
	var is_sprinting = Input.is_action_pressed("sprint")
	var target_speed = sprint_speed if is_sprinting else walk_speed
	current_speed = lerp(current_speed, target_speed, acceleration * delta)
	if direction != Vector2.ZERO:
		face_dir = direction
		velocity = velocity.move_toward(direction * current_speed, acceleration * current_speed * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * current_speed * delta)
		
	
	move_and_slide()
	_update_anim(direction)

func loadStats():
	pass

func _update_anim(move_dir: Vector2) -> void:
	if animationPlayer == null:
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
	var frames: SpriteFrames = animationPlayer.sprite_frames

	if frames.has_animation(base + "sideleft"):
		chosen = base + "sideleft"
		animationPlayer.flip_h = dx > 0.0            # moving right? flip the left-facing clip
	elif frames.has_animation(base + "sideright"):
		chosen = base + "sideright"
		animationPlayer.flip_h = dx < 0.0            # moving left? flip the right-facing clip
	elif frames.has_animation(base + "side"):
		chosen = base + "side"
		# With a neutral side clip, flip when moving left.
		animationPlayer.flip_h = dx < 0.0
	else:
		# Fallbacks: left/right, then down/up, then base
		if dx < 0.0 and frames.has_animation(base + "left"):
			chosen = base + "left"; animationPlayer.flip_h = false
		elif dx >= 0.0 and frames.has_animation(base + "right"):
			chosen = base + "right"; animationPlayer.flip_h = false
		elif frames.has_animation(base + "down"):
			chosen = base + "down"; animationPlayer.flip_h = false
		elif frames.has_animation(base + "up"):
			chosen = base + "up"; animationPlayer.flip_h = false
		else:
			chosen = base; animationPlayer.flip_h = false

	if animationPlayer.animation != chosen:
		animationPlayer.play(chosen)

func _play_updown(base: String, orient: String) -> void:
	var frames: SpriteFrames = animationPlayer.sprite_frames
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
	animationPlayer.flip_h = false
	if animationPlayer.animation != name:
		animationPlayer.play(name)