extends Timer

class_name PathGenerator

@export var parent: Basic_AI
@export var navMesh: NavigationRegion2D

func _ready():
    self.timeout.connect(getRandomPoint)

func getRandomPoint():
    var pos = parent.global_position + Vector2(randf_range(-300, 300), randf_range(-300, 300))
    parent.AddNewNavigationTarget(pos)