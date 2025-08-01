@tool
extends EditorPlugin

func _enter_tree():
	call_deferred("_hide_3d_button")

func _exit_tree():
	var base = get_editor_interface().get_base_control()
	var button = _find_button_by_text(base, "3D")
	if button:
		button.show()

func _hide_3d_button():
	var base = get_editor_interface().get_base_control()
	var button = _find_button_by_text(base, "3D")
	if button:
		print("✔ Found and hiding '3D' button")
		button.hide()
	else:
		print("✘ Could not find '3D' button")

func _find_button_by_text(node: Node, label: String) -> Button:
	if node is Button and node.text.strip_edges() == label:
		return node
	for child in node.get_children():
		var found = _find_button_by_text(child, label)
		if found:
			return found
	return null
