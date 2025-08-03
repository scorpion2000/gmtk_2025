# The GameManager is responsible for all core game logic.
class_name GameManager
extends Node

signal loopsUpdated(newValue: int)

# --- Public References ---
@export var HudReference: GameHUD

# --- Settings & timers ---
var player: Player
var roomManager: RoomManager
var isSanityDraining: bool = true

# --- Buff System ---
var noiseReductionActive: bool = false
var loopBoostActive: bool = false
var loopBoostMultiplier: float = 1.0

# --- Time tracking ---
var timeStart: int                    # Set at scene start
var timePaused: int = 0               # Accumulated pause time
var timePausedStart: int = -1         # Timestamp when pause begins

# --- Loop tracking ---
var LoopCount: int = 0:
	set(value):
		LoopCount = value
		loopsUpdated.emit(LoopCount)

# References to individual stats for fast access.
var sanityStat: Stat
var sanityDrain: Stat
var sanityRecovery: Stat

func CollectLoop(amount: int) -> void:
	LoopCount += amount

func _ready() -> void:
	add_to_group("GameManager")
	# Locate the player either by direct node name or group.
	player = get_tree().get_first_node_in_group("player") as Player
	timeStart = Time.get_ticks_msec()
	setupRoomSystem()
	setupHudConnections()
	setupStatsReferences()

# Track pause time so getActiveSeconds() excludes paused duration.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		timePausedStart = Time.get_ticks_msec()
	elif what == NOTIFICATION_UNPAUSED and timePausedStart >= 0:
		timePaused += Time.get_ticks_msec() - timePausedStart
		timePausedStart = -1

func _process(delta: float) -> void:
	if !sanityStat: return
	
	if isSanityDraining:
		processSanityDrain(delta)
	elif isPlayerInSafeArea():
		processSanityRecovery(delta)

# Apply sanity drain through the stat system.
func processSanityDrain(delta: float) -> void:
	DamageSanity(sanityDrain.getValue() * delta)

# Recover sanity in safe areas by adding to the stat.
func processSanityRecovery(delta: float) -> void:
	if !sanityRecovery: return
	RestoreSanity(sanityRecovery.getValue() * delta)

# Utility for directly reducing sanity
func DamageSanity(amount: float) -> void:
	sanityStat.subtractValue(amount)

# Utility for directly restoring sanity via stat
func RestoreSanity(amount: float) -> void:
	sanityStat.addValue(amount)

func isPlayerInSafeArea() -> bool:
	return false

func setupRoomSystem() -> void:
	# Create or retrieve the RoomManager.
	roomManager = get_node_or_null("RoomManager") as RoomManager

	# Initialize rooms only if both player and roomManager exist.
	if player and roomManager:
		roomManager.initialize_rooms(player)
		roomManager.room_changed.connect(onRoomChanged)
		# Defer minimap setup until the RoomManager has generated level data
		call_deferred("setupMinimap")
	else:
		print("Warning: Player or RoomManager not found!")

func setupMinimap() -> void:
	if HudReference and roomManager:
		HudReference.initializeMinimap(roomManager.get_level_generator())

# --- Room system event handlers ---
func onRoomChanged(newRoom: RoomData) -> void:
	# Update the minimap on the HUD
	if HudReference:
		HudReference.updateMinimapRoom(newRoom)

# --- HUD and end‑game ---
func setupHudConnections() -> void:
	if !HudReference:
		print("Warning: GameHUD not found in scene!")
		return
	loopsUpdated.connect(HudReference.updateLoopDisplay)
	HudReference.updateLoopDisplay(LoopCount)
	HudReference.SanityDepleted.connect(onSanityDepleted)

# Assign references to individual stats from the StatsList.
func setupStatsReferences() -> void:
	var statsListRef := player.Stats
	sanityStat = statsListRef.getStatRef("sanity") as Stat
	sanityDrain = statsListRef.getStatRef("sanitydrain") as Stat
	sanityRecovery = statsListRef.getStatRef("sanityrecovery") as Stat

func onSanityDepleted() -> void:
	StateManager.SetGameOverState()
	var reason = "Sanity depleted!"
	var loopsCollected = LoopCount
	var secondsSurvived = getActiveSeconds()
	Utilities.showEnd(reason, loopsCollected, secondsSurvived)

## Compute the total time the player has been active, subtracting pause time
func getActiveSeconds() -> float:
	var currentTime: int = Time.get_ticks_msec()
	var pausedTotal: int = timePaused
	if get_tree().paused and timePausedStart >= 0:
		pausedTotal += currentTime - timePausedStart
	return float(currentTime - timeStart - pausedTotal) / 1000.0

func applyNoiseReduction(_multiplier: float) -> void:
	noiseReductionActive = true

func removeNoiseReduction() -> void:
	noiseReductionActive = false

func applyLoopBoost(_chanceMultiplier: float, amountMultiplier: float) -> void:
	loopBoostActive = true
	loopBoostMultiplier = amountMultiplier

func removeLoopBoost() -> void:
	loopBoostActive = false
	loopBoostMultiplier = 1.0

func getNoiseReductionMultiplier() -> float:
	return 0.9 if noiseReductionActive else 1.0

func getLoopBoostMultiplier() -> float:
	return loopBoostMultiplier if loopBoostActive else 1.0

func isLoopBoostActive() -> bool:
	return loopBoostActive
