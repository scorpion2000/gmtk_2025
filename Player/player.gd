extends CharacterBody2D

@export var speed:int
func _physics_process(delta): 
	var direction = Input.get_vector("left","right", "up", "down")
	velocity = velocity.lerp(direction*speed, 0.10)
	move_and_slide()
