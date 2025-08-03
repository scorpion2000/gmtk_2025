extends Node

class_name EnemySpawner

@export var startingEnemies: int = 0
@export var spawnArea: NavigationRegion2D
@export var enemyPrefabs: Array[PackedScene]

var spawnTimer: Timer = Timer.new()

func _ready():
	add_child(spawnTimer)
	spawnTimer.timeout.connect(createEnemy)
	await get_tree().physics_frame
	for x in range(startingEnemies):
		createEnemy()

func createEnemy():
	var newEnemy = enemyPrefabs.pick_random().instantiate()
	get_tree().root.add_child(newEnemy)
	await get_tree().physics_frame
	var randomPos: Vector2 = NavigationServer2D.region_get_random_point(spawnArea.get_rid(), 1, false)
	print(randomPos)
	newEnemy.global_position = randomPos
	print(newEnemy.global_position)
	newEnemy.enableRandomPatrol(spawnArea)
