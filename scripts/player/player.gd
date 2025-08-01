extends EntityBase

@export var walk_speed: float = 100.0
@export var sprint_speed: float = 180.0
@export var acceleration: float = 12.0
@export var friction: float = 15.0

var current_speed: float

func _ready() -> void:
	add_to_group("player")

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
