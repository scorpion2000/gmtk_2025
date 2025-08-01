class_name EndScreen
extends Control

signal upgradePressed()
signal menuPressed()
signal exitPressed()
signal retryPressed()

@onready var reasonLabel: Label  = %EndReason
@onready var summaryLabel: Label = %SummaryResults

func _ready() -> void:
	%RetryBtn.pressed.connect(onRetryPressed)
	%UpgradeBtn.pressed.connect(onUpgradePressed)
	%MenuBtn.pressed.connect(onMenuPressed)
	%ExitBtn.pressed.connect(onExitPressed)

# Called from GameManager when run ends
func showEnd(reason: String, loopsCollected: int, secondsSurvived: float) -> void:
	reasonLabel.text = reason
	summaryLabel.text = "Loops: %d  |  Time: %s" % [loopsCollected, fmtTime(secondsSurvived)]
	%RetryBtn.grab_focus()

# Buttons are wired in the editor
func onRetryPressed() -> void:
	retryPressed.emit()

func onUpgradePressed() -> void:
	upgradePressed.emit()

func onMenuPressed() -> void:
	menuPressed.emit()

func onExitPressed() -> void:
	exitPressed.emit()

func fmtTime(t: float) -> String:
	var s := int(t)
	var m := float(s) / 60
	var r := s % 60
	return "%02d:%02d" % [m, r]
