extends CharacterBody2D

class_name EntityBase

enum AnimationState
{
	IdleDown,
	IdleLeft,
	IdleRight,
	IdleUp,
	WalkDown,
	WalkLeft,
	WalkRight,
	WalkUp,
	RunDown,
	RunLeft,
	RunRight,
	RunUp,
	Attack,
	RummageDown,
	RummageLeft,
	RummageRight,
	RummageUp,
}

@export var animationStates: Dictionary[AnimationState, String]
@export var animationPlayer: AnimatedSprite2D
@export var enableVision: bool = true
@export var visionSize: float = 150
@export var visionCycle: float = 0.25

var nextAnimation: AnimationState
#Vision stuff
var vision: Area2D = Area2D.new()
var visionShape: CircleShape2D = CircleShape2D.new()
var visionCollision: CollisionShape2D = CollisionShape2D.new()
var visionTimer: Timer = Timer.new()
var flipped: bool = false

func _ready():
	set_physics_process(false)
	if animationPlayer != null:
		animationPlayer.animation_finished.connect(playNextAnimation)
		if (animationStates.has(AnimationState.IdleDown)):
			animationPlayer.play(animationStates[AnimationState.IdleDown])
			nextAnimation = AnimationState.IdleDown
	createVision()
	_start()

func _start():
	pass

func ChangeAnimationState(_animation: AnimationState, _forced: bool, _flipped: bool = false):
	if (animationPlayer == null):
		print("Animation Player is missing, but animation state change was called!")
		return
	if (!animationStates.has(_animation)):
		print("Animation Player was forced to play an unset animation type!" + AnimationState.keys()[_animation] + " on " + self.name)
		return
	nextAnimation = _animation
	flipped = _flipped
	if (_forced):
		if _flipped:
			animationPlayer.sprite_frames
		animationPlayer.play(animationStates[_animation])

func playNextAnimation():
	animationPlayer.play(animationStates[nextAnimation])

func noiseAlert(_entity: EntityBase):
	print("I heard " + _entity.name + " make a noise!")

func createNoise(_noiseSize: NoiseMaker.NoiseSize):
	var noise = NoiseMaker.Create(_noiseSize, self)
	add_child(noise)

func createVision():
	if !enableVision: return
	add_child(vision)
	vision.add_child(visionCollision)
	add_child(visionTimer)

	visionShape.radius = visionSize
	visionCollision.shape = visionShape
	visionTimer.wait_time = visionCycle
	visionTimer.start()
	visionTimer.timeout.connect(activateVision)

func activateVision():
	var bodies: Array[Node2D] = vision.get_overlapping_bodies()
	for body in bodies:
		if body is EntityBase && body != self:
			body.seenByEntity()
			spottedEntity(body)

func spottedEntity(_entity: EntityBase):
	pass
		
func seenByEntity(_entity: EntityBase):
	pass
