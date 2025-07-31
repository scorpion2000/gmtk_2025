##Dependent on class Stat
# Resource that holds a list of Stat resources and exposes:
# - A fast lookup dictionary (by stat resource_name, case-insensitive).
# - A unified signal that forwards each Stat's change events.
class_name StatsList
extends Resource

# ---------- Data ----------
# Whenever this array is reassigned, we rebuild connections and the lookup map.
@export var statsList: Array[Stat]:
	set(value):
		statsList = value
		_rebuild()

# Emitted whenever any child Stat fires its own statChanged.
signal statUpdated(stat_name: String, new_value: float)
func _on_stat_changed(stat_name: String, new_value: float) -> void:
	statUpdated.emit(stat_name, new_value)

# Lookup table: "resource_name".to_lower() -> Stat
var statsDict: Dictionary = {}

# ---------- Lifecycle ----------
# After init, ensure our dictionary and connections are correct.
func _notification(what):
	if what == NOTIFICATION_POSTINITIALIZE:
		_rebuild()

# Rebuilds the lookup dictionary and connects signals from each Stat.
func _rebuild() -> void:
	statsDict.clear()
	for stat : Stat in statsList:
		if stat:
			if !stat.statChanged.is_connected(_on_stat_changed):
				stat.statChanged.connect(_on_stat_changed)
			statsDict[stat.resource_name.to_lower()] = stat

# ---------- Queries ----------
# Returns the effective stat value.
# Accepts either a stat name (String) or a Stat reference.
func getStatValue(statRef : Variant):
	var stat : Stat
	if typeof(statRef) == TYPE_STRING:
		stat = statsDict[statRef.to_lower()]
		return stat.getValue()
	
	if statRef is Stat:
		return statRef.getValue()
	
	return -1

# Returns the Stat reference by name (case-insensitive).
func getStatRef(statName : String) -> Stat:
	return statsDict[statName.to_lower()]
