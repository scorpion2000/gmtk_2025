extends Control
class_name GameHUD

# Node references (cached on ready)
@onready var LoopCounterLabel: Label = %LoopCounter
@onready var SanityBarFill: ColorRect = $TopLeftContainer/SanityBarContainer/SanityBarBackground/SanityBarFill
@onready var miniMap: MiniMap = $MiniMap
@onready var InteractionContainer: Control = $InteractionContainer
@onready var CircularProgressBar: Control = $InteractionContainer/CircularProgressBar
@onready var ProgressFill: ColorRect = $InteractionContainer/CircularProgressBar/ProgressFill
@onready var HoldELabel: Label = $InteractionContainer/HoldELabel
@onready var interactionLabel: Label = $InteractionContainer/InteractionLabel

# Buff icon references
@onready var BuffIconsContainer: VBoxContainer = $BuffIconsContainer
@onready var speedIcon: ColorRect = $BuffIconsContainer/SpeedIcon
@onready var noiseIcon: ColorRect = $BuffIconsContainer/NoiseIcon
@onready var loopIcon: ColorRect = $BuffIconsContainer/LoopIcon

# Signals for notifying game logic when thresholds are crossed
signal SanityDepleted

var statSanity : Stat

func _ready() -> void:
	add_to_group("hud")
	# Defer initial bar updates until all nodes are ready
	call_deferred("initialSetup")

# During initial setup, query the stats (if available)
func initialSetup() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var StatsListRef := player.Stats
	if !StatsListRef: return
	
	statSanity = StatsListRef.getStatRef("sanity")
	if statSanity:
		if !statSanity.statChanged.is_connected(onSanityUpdated):
			statSanity.statChanged.connect(onSanityUpdated)
		updateSanityBar()
		checkSanityThresholds()
		print("found sanity")

# --- Public API ---
func updateLoopDisplay(newValue: int) -> void:
	if !LoopCounterLabel: return
	LoopCounterLabel.text = "Loops: " + str(newValue)

# Initialize the mini‑map with level data
func initializeMinimap(levelGenerator: LevelGenerator) -> void:
	if !miniMap: return
	miniMap.initialize(levelGenerator)

func updateMinimapRoom(room: RoomData) -> void:
	if !miniMap: return
	miniMap.update_current_room(room)

# Display the interaction progress container with prompt text
func showInteractionProgress(promptText: String = "Search") -> void:
	if InteractionContainer and interactionLabel and HoldELabel:
		interactionLabel.text = promptText
		HoldELabel.text = "Hold E"
		InteractionContainer.visible = true
		if ProgressFill:
			ProgressFill.anchor_right = 0.0

func hideInteractionProgress() -> void:
	if !InteractionContainer: return
	InteractionContainer.visible = false

func updateInteractionProgress(progress: float) -> void:
	if !ProgressFill: return
	ProgressFill.anchor_right = clampf(progress, 0.0, 1.0)

# --- Internal methods ---
func updateSanityBar() -> void:
	if !SanityBarFill: return
	var percentage: float = statSanity.getPercentage()
	SanityBarFill.anchor_right = percentage
	# Colour the bar based on percentage
	if percentage > 0.5:
		SanityBarFill.color = Color(0.3, 0.7, 1.0)    # Blue – healthy
	elif percentage > 0.25:
		SanityBarFill.color = Color(1.0, 0.8, 0.2)    # Yellow – warning
	else:
		SanityBarFill.color = Color(1.0, 0.2, 0.2)    # Red – critical

func checkSanityThresholds() -> void:
	if statSanity.getValue() <= statSanity.getMinValue():
		SanityDepleted.emit()

func onSanityUpdated(_statName : String, _newValue: float):
	updateSanityBar()
	checkSanityThresholds()

# Buff icon management functions
func showSpeedBuff() -> void:
	if !speedIcon: return
	speedIcon.visible = true

func hideSpeedBuff() -> void:
	if !speedIcon: return
	speedIcon.visible = false

func showNoiseBuff() -> void:
	if !noiseIcon: return
	noiseIcon.visible = true

func hideNoiseBuff() -> void:
	if !noiseIcon: return
	noiseIcon.visible = false

func showLoopBuff() -> void:
	if !loopIcon: return
	loopIcon.visible = true

func hideLoopBuff() -> void:
	if !loopIcon: return
	loopIcon.visible = false
