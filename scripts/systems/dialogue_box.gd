extends Control

class_name DialogueBox

enum TextSpeed
{
	Fast = 5,
	Normal = 10,
	Slow = 20
}

var textTimer: Timer = Timer.new()
var text: String
var displayedTextLength: int = 0
var textSpeed: float = TextSpeed.Normal
var panelComponent: Panel
var textComponent: RichTextLabel
var originPoint: Vector2
var mouseOverPanel: bool = false

func _ready():
	panelComponent = self.get_node("Panel")
	textComponent = self.get_node("Panel").get_node("RichTextLabel")
	originPoint = global_position

	add_child(textTimer)
	textTimer.one_shot = true
	textTimer.timeout.connect(displayNextChar)

	mouse_entered.connect(toggleMouseOver.bind(true))
	mouse_exited.connect(toggleMouseOver.bind(false))

func _input(event):
	if event is InputEventMouseButton:
		if displayedTextLength >= text.length() && mouseOverPanel:
			popupToggle()

func setText(_text: String, _speed: TextSpeed):
	text = _text
	textSpeed = _speed
	textTimer.wait_time = textSpeed/100
	displayedTextLength = 0
	start()

func toggleMouseOver(_toggle: bool):
	print("Mouse hovering over? " + "yup" if _toggle else "nope")
	mouseOverPanel = _toggle

func start():
	popupToggle()

func popupToggle():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", Vector2(originPoint.x, originPoint.y - 160 if global_position.y == originPoint.y else originPoint.y), 0.5)
	tween.finished.connect(displayNextChar)

func displayNextChar():
	displayedTextLength += 1
	if displayedTextLength+1 < text.length() && text[displayedTextLength+1] == " ":
		displayedTextLength += 1

	textComponent.text = text.left(displayedTextLength)

	if displayedTextLength < text.length():
		textTimer.start()
