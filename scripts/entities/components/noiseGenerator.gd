extends Timer

class_name NoiseGenerator

@export var parent: EntityBase

func _ready():
	timeout.connect(randomWaitTime)

func randomWaitTime():
	parent.createNoise(
		[NoiseMaker.NoiseSize.Small, NoiseMaker.NoiseSize.Medium, NoiseMaker.NoiseSize.Large].pick_random()
	)
	wait_time = randf_range(1,5)
	start()
