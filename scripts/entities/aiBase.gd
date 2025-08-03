extends EntityBase

class_name AI_Base

@export var patrolTimer: Vector2i = Vector2i(2,6)

var speed: float = 100
var accel: float = 10
var navAgent: NavigationAgent2D = NavigationAgent2D.new()
var nextTargetPosition: Vector2 = global_position
var navigationArea: NavigationRegion2D
var doRandomPatrol: bool = false
var chasing: bool = false
var targetEntity: EntityBase = null
var randomPatrolTimer: Timer
var randomPatrolRegion: NavigationRegion2D

func _start():
	self.add_child(navAgent)

func _physics_process(delta):
	var dir = Vector2()
	navAgent.target_position = nextTargetPosition
	dir = navAgent.get_next_path_position() - global_position
	dir = dir.normalized()

	velocity = velocity.lerp(dir * speed, accel * delta)

	move_and_slide()
	if global_position.distance_squared_to(nextTargetPosition) < 10:
		if chasing: chasing = false
		set_physics_process(false)

func enableRandomPatrol(_region):
	randomPatrolRegion = _region
	if randomPatrolTimer != null:
		print("Random Patrol Timer already exists in " + self.name)
		return
	randomPatrolTimer = Timer.new()
	add_child(randomPatrolTimer)
	randomPatrolTimer.timeout.connect(moveToNextPatrolPoint)
	randomPatrolTimer.one_shot = true
	moveToNextPatrolPoint()

func AddNewNavigationTarget(navTarget: Vector2):
	nextTargetPosition = navTarget
	printt(nextTargetPosition, "is my destination")
	set_physics_process(true)

func moveToNextPatrolPoint():
	if chasing:
		return
	AddNewNavigationTarget(NavigationServer2D.region_get_random_point(randomPatrolRegion.get_rid(), 1, false))
	randomPatrolTimer.wait_time = randf_range(patrolTimer.x, patrolTimer.y)
	randomPatrolTimer.start()

func noiseAlert(_entity: EntityBase):
	print("I heard " + _entity.name + " make a noise!")
	AddNewNavigationTarget(_entity.global_position)
	chasing = true

func activateVision():
	var bodies: Array[Node2D] = vision.get_overlapping_bodies()
	for body in bodies:
		if body is Player:
			body.seenByEntity(self)
			spottedEntity(body)
			return
	spottedEntity(null)

func spottedEntity(_entity: EntityBase):
	if _entity == null:
		return
	print("Removing sanity from the player")
	_entity = _entity as Player
	var _stat: Stat = _entity.Stats.getStatRef("sanitydrain") as Stat
	var newModifyer: StatModifier = StatModifier.MultiplyValueModifier.new()
	newModifyer.factor = 0.02
	_stat.addModifier(newModifyer)
