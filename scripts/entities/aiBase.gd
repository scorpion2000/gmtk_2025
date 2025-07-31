extends EntityBase

class_name AI_Base

var speed: float = 100
var accel: float = 10
var navAgent: NavigationAgent2D = NavigationAgent2D.new()
var nextTargetPosition: Vector2 = global_position

func _ready():
    self.add_child(navAgent)

func _physics_process(delta):
    var dir = Vector2()
    navAgent.target_position = nextTargetPosition
    dir = navAgent.get_next_path_position() - global_position
    dir = dir.normalized()

    velocity = velocity.lerp(dir * speed, accel * delta)

    move_and_slide()
    if global_position.distance_squared_to(nextTargetPosition) < 10:
        set_physics_process(false)

func AddNewNavigationTarget(navTarget: Vector2):
    nextTargetPosition = navTarget
    set_physics_process(true)