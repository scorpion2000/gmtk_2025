extends CharacterBody2D

class_name EntityBase

func noiseAlert(_entity: EntityBase):
    print("I heard " + _entity.name + " make a noise!")

func createNoise(_noiseSize: NoiseMaker.NoiseSize):
    var noise = NoiseMaker.Create(_noiseSize, self)
    add_child(noise)
