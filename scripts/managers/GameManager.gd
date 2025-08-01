# The GameManager is responsible for all core game logic.
class_name GameManager
extends Node

signal loopsUpdated(newValue: int)

# --- Public References ---
@export var HudReference: GameHUD
@export var UiManager: UIManager

# --- Settings & timers ---
var player: Player
var roomManager: RoomManager
var isHungerDraining: bool = true
var isSanityDraining: bool = false
var hungerDrainRate: float = 2.0    # Hunger points per second
var sanityDrainRate: float = 5.0    # Sanity points per second
var sanityRecoveryRate: float = 1.0 # Sanity points per second in safe areas
var sanityDrainTimer: float = 0.0   # Remaining time for an active drain event

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
var hungerStat: Stat
var sanityStat: Stat

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
	# If stats are not set up or game is paused, skip processing
	if !hungerStat or !sanityStat: return
	
	# Drain hunger every frame if enabled.
	if isHungerDraining:
		processHungerDrain(delta)
	
	# Drain sanity during an active drain event.
	if isSanityDraining:
		processSanityDrain(delta)
	elif isPlayerInSafeArea():
		processSanityRecovery(delta)

# Apply hunger drain through the stat system.
func processHungerDrain(delta: float) -> void:
	if !hungerStat: return
	DamageHunger(hungerDrainRate * delta)

# Apply sanity drain through the stat system and decrease the timer.
func processSanityDrain(delta: float) -> void:
	if sanityStat:
		DamageSanity(sanityDrainRate * delta)
	sanityDrainTimer -= delta
	if sanityDrainTimer <= 0.0:
		isSanityDraining = false

# Recover sanity in safe areas by adding to the stat.
func processSanityRecovery(delta: float) -> void:
	if !sanityStat: return
	RestoreSanity(sanityRecoveryRate * delta)

# Begin a temporary sanity drain event for the specified duration.
func TriggerSanityDrainEvent(duration: float) -> void:
	isSanityDraining = true
	sanityDrainTimer = max(duration, 0.0)

# Utility for directly reducing sanity
func DamageSanity(amount: float) -> void:
	if !sanityStat: return
	sanityStat.subtractValue(amount)

# Utility for directly reducing hunger
func DamageHunger(amount: float) -> void:
	if !hungerStat: return
	hungerStat.subtractValue(amount)

# Utility for directly restoring sanity
func RestoreSanity(amount: float) -> void:
	if !sanityStat: return
	sanityStat.addValue(amount)

# Utility for directly restoring hunger via stat
func RestoreHunger(amount: float) -> void:
	if !hungerStat: return
	hungerStat.addValue(amount)

func isPlayerInSafeArea() -> bool:
	# TODO: Replace this placeholder with the actual logic that determines
	# whether the player is currently in a safe area
	return false

func setupRoomSystem() -> void:
	# Create or retrieve the RoomManager.
	roomManager = get_node_or_null("RoomManager") as RoomManager

	# Initialize rooms only if both player and roomManager exist.
	if player and roomManager:
		roomManager.initialize_rooms(player)
		roomManager.room_changed.connect(onRoomChanged)
		roomManager.room_cleared.connect(onRoomCleared)
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
	# Trigger sanity drain based on room properties
	match newRoom.room_type:
		RoomData.RoomType.BEDROOM:
			TriggerSanityDrainEvent(1.5)
		RoomData.RoomType.LIVING_ROOM:
			if not newRoom.is_cleared:
				TriggerSanityDrainEvent(1.0)

func onRoomCleared(room: RoomData) -> void:
	# Reward the player for clearing rooms
	RestoreSanity(10.0)
	match room.room_type:
		RoomData.RoomType.KITCHEN:
			CollectLoop(5)
			RestoreHunger(25.0)
		RoomData.RoomType.SHRINE:
			pass
		RoomData.RoomType.BEDROOM:
			RestoreSanity(15.0)

# --- HUD and end‑game ---
func setupHudConnections() -> void:
	if !HudReference:
		print("Warning: GameHUD not found in scene!")
		return
	loopsUpdated.connect(HudReference.updateLoopDisplay)
	HudReference.updateLoopDisplay(LoopCount)
	HudReference.SanityDepleted.connect(onSanityDepleted)
	HudReference.HungerDepleted.connect(onHungerDepleted)
	HudReference.SanityCritical.connect(onSanityCritical)
	HudReference.HungerCritical.connect(onHungerCritical)

# Assign references to individual stats from the StatsList.
func setupStatsReferences() -> void:
	var statsListRef := player.Stats
	hungerStat = statsListRef.getStatRef("hunger") as Stat
	sanityStat = statsListRef.getStatRef("sanity") as Stat
	if !hungerStat:
		print("Warning: Hunger stat not found in StatsList")
	if !sanityStat:
		print("Warning: Sanity stat not found in StatsList")

# Trigger game over via the StateManager and show the end screen on the UI
func onSanityDepleted() -> void:
	StateManager.SetGameOverState()
	var reason = "Sanity depleted!"
	var loopsCollected = LoopCount
	var secondsSurvived = getActiveSeconds()
	if !UiManager: return
	UiManager.showEnd(reason, loopsCollected, secondsSurvived)

func onHungerDepleted() -> void:
	StateManager.SetGameOverState()
	var reason = "Hunger depleted!"
	var loopsCollected = LoopCount
	var secondsSurvived = getActiveSeconds()
	if !UiManager: return
	UiManager.showEnd(reason, loopsCollected, secondsSurvived)

func onSanityCritical(_currentValue: float) -> void:
	pass

func onHungerCritical(_currentValue: float) -> void:
	pass

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
