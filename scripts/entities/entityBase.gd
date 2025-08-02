extends CharacterBody2D

class_name EntityBase

enum AnimationState
{
    Idle,
    Walk,
    Run,
    Attack
}

@export var animationStates: Dictionary[AnimationState, String]
@export var animationPlayer: AnimationPlayer

var nextAnimation: AnimationState

func _ready():
    animationPlayer.animation_finished.connect(playNextAnimation)
    if (animationStates.has(AnimationState.Idle)):
        animationPlayer.play(animationStates[AnimationState.Idle])
        nextAnimation = AnimationState.Idle

func ChangeAnimationState(_animation: AnimationState, _forced: bool):
    if (animationPlayer == null):
        print("Animation Player is missing, but animation state change was called!")
        return
    if (!animationStates.has(_animation)):
        print("Animation Player was forced to play an unset animation type!" + AnimationState.keys()[_animation] + " on " + self.name)
        return
    nextAnimation = _animation
    if (_forced):
        animationPlayer.play(animationStates[_animation])

func playNextAnimation():
    animationPlayer.play(animationStates[nextAnimation])

func noiseAlert(_entity: EntityBase):
    print("I heard " + _entity.name + " make a noise!")

func createNoise(_noiseSize: NoiseMaker.NoiseSize):
    var noise = NoiseMaker.Create(_noiseSize, self)
    add_child(noise)
