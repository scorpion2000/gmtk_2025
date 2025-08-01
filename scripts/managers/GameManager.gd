extends Node
class_name GameManager

# --- Public References ---
@export var HudReference : GameHUD
@export var uiManager : UIManager

# --- Settings ---
var hunger_drain_rate: float = 2.0        # Hunger points per second
var sanity_recovery_rate: float = 1.0     # Sanity points per second in safe areas

# --- Time Tracking ---
var timeStart: int                        # Set at scene start
var timePaused: int = 0                   # Accumulated pause time
var timePausedStart: int = -1             # Timestamp when pause begins

func _ready() -> void:
	timeStart = Time.get_ticks_msec()
	setup_hud_connections()

func _process(delta: float) -> void:
	if not HudReference:
		return

	process_hunger_drain(delta)

	if is_player_in_safe_area():
		process_sanity_recovery(delta)

# --- Pause Tracking ---
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		timePausedStart = Time.get_ticks_msec()
	elif what == NOTIFICATION_UNPAUSED and timePausedStart >= 0:
		timePaused += Time.get_ticks_msec() - timePausedStart
		timePausedStart = -1

func getActiveSeconds() -> float:
	var currentTime := Time.get_ticks_msec()
	var pausedTotal := timePaused
	if get_tree().paused and timePausedStart >= 0:
		pausedTotal += currentTime - timePausedStart
	return float(currentTime - timeStart - pausedTotal) / 1000.0

# --- Game Logic ---
func CollectLoop() -> void:
	if HudReference:
		HudReference.AddLoops(1)

func DamageSanity(amount: float) -> void:
	if HudReference:
		var new_sanity = HudReference.GetSanity() - amount
		HudReference.SetSanity(new_sanity)

func RestoreHunger(amount: float) -> void:
	if HudReference:
		var new_hunger = HudReference.GetHunger() + amount
		HudReference.SetHunger(new_hunger)

# --- Internal Tick ---
func process_hunger_drain(delta: float) -> void:
	var new_hunger = HudReference.GetHunger() - (hunger_drain_rate * delta)
	HudReference.SetHunger(new_hunger)

func process_sanity_recovery(delta: float) -> void:
	var new_sanity = HudReference.GetSanity() + (sanity_recovery_rate * delta)
	HudReference.SetSanity(new_sanity)

func is_player_in_safe_area() -> bool:
	# TODO: Implement actual detection logic
	return false

# --- HUD Signals ---
func setup_hud_connections() -> void:
	if not HudReference:
		print("Warning: GameHUD not found in scene!")
		return

	HudReference.SanityDepleted.connect(_on_sanity_depleted)
	HudReference.HungerDepleted.connect(_on_hunger_depleted)
	HudReference.SanityCritical.connect(_on_sanity_critical)
	HudReference.HungerCritical.connect(_on_hunger_critical)

func _on_sanity_depleted() -> void:
	var reason = "Sanity depleted!"
	var loopsCollected = 0 # Will be connected to loop collection system later
	var secondsSurvived = getActiveSeconds()
	uiManager.showEnd(reason, loopsCollected, secondsSurvived)

func _on_hunger_depleted() -> void:
	var reason = "Hunger depleted!"
	var loopsCollected = 0 # Will be connected to loop collection system later
	var secondsSurvived = getActiveSeconds()
	uiManager.showEnd(reason, loopsCollected, secondsSurvived)

func _on_sanity_critical(current_value: float) -> void:
	print("Warning: Sanity critical! Current:", current_value)

func _on_hunger_critical(current_value: float) -> void:
	print("Warning: Hunger critical! Current:", current_value)
