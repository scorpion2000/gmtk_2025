# resource that groups several Stats together
class_name StatsList
extends Resource

# define the stats
@export var statsList: Array[Stat]:
	set(value):
		statsList = value
		_rebuild()

signal statUpdated(stat_name: String, new_value: float)
func _on_stat_changed(stat_name: String, new_value: float) -> void:
	statUpdated.emit(stat_name, new_value)

var statsDict: Dictionary = {}

func _notification(what):
	if what == NOTIFICATION_POSTINITIALIZE:
		_rebuild()

func _rebuild() -> void:
	statsDict.clear()
	for stat : Stat in statsList:
		if stat:
			if !stat.statChanged.is_connected(_on_stat_changed):
				stat.statChanged.connect(_on_stat_changed)
			statsDict[stat.resource_name.to_lower()] = stat

func getStatValue(statRef : Variant):
	var stat : Stat
	if typeof(statRef) == TYPE_STRING:
		stat = statsDict[statRef.to_lower()]
		return stat.getValue()
	
	if statRef is Stat:
		return statRef.getValue()

func getStatRef(statName : String) -> Stat:
	return statsDict[statName.to_lower()]
