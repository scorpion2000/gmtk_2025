class_name Player
extends EntityBase

@export var Stats : StatsList
@export var walk_speed: float = 100.0
@export var sprint_speed: float = 180.0
@export var acceleration: float = 12.0
@export var friction: float = 15.0

var current_speed: float
# Base speeds for buff calculations
var base_walk_speed: float
var base_sprint_speed: float
var speed_modifiers: Array[float] = []

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
	var direction = Input.get_vector("left", "right", "up", "down")
	var is_sprinting = Input.is_action_pressed("sprint")
	var target_speed = sprint_speed if is_sprinting else walk_speed
	current_speed = lerp(current_speed, target_speed, acceleration * delta)
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * current_speed, acceleration * current_speed * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * current_speed * delta)
	
	move_and_slide()
