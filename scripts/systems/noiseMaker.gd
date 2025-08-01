extends Area2D

class_name NoiseMaker

enum NoiseSize
{
    Small = 100,
    Medium = 200,
    Large = 300
}

var lifeTimer: Timer = Timer.new()
var collision: CollisionShape2D = CollisionShape2D.new()
var shape: CircleShape2D = CircleShape2D.new()

var noiseSize: NoiseSize = NoiseSize.Small
var parent: EntityBase

static func Create(_noiseSize: NoiseSize, _parent: EntityBase) -> NoiseMaker:
    var noiseMaker: NoiseMaker = NoiseMaker.new()
    noiseMaker.noiseSize = _noiseSize
    noiseMaker.parent = _parent
    return noiseMaker

func _ready():
    self.add_child(lifeTimer)
    self.add_child(collision)

    # Check for noise reduction buff
    var final_noise_size = noiseSize
    var game_manager = get_tree().get_first_node_in_group("game_manager")
    if game_manager and game_manager.noise_reduction_active:
        var reduced_size = int(noiseSize * game_manager.get_noise_reduction_multiplier())
        # Convert back to NoiseSize enum
        final_noise_size = reduced_size as NoiseSize
        print("Noise reduction active! Reduced size from ", noiseSize, " to ", final_noise_size)

    shape.radius = final_noise_size
    collision.shape = shape

    lifeTimer.wait_time = 1
    lifeTimer.start()
    lifeTimer.timeout.connect(queue_free)
    await get_tree().physics_frame
    await get_tree().physics_frame
    alertEntities()

func alertEntities():
    var bodies: Array[Node2D] = get_overlapping_bodies()
    for body in bodies:
        if body is EntityBase && body != parent:
            body.noiseAlert(parent)