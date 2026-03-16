class_name UISounds
extends Node
## UISounds - Utility to add audio feedback to UI elements
## Add as child of any Control to automatically add sounds to its buttons

## Connect sounds to all buttons in the parent
static func setup_button_sounds(parent: Node) -> void:
	_connect_buttons_recursive(parent)


static func _connect_buttons_recursive(node: Node) -> void:
	if node is Button:
		_connect_button(node)

	for child in node.get_children():
		_connect_buttons_recursive(child)


static func _connect_button(button: Button) -> void:
	# Only connect if not already connected
	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed)

	if not button.mouse_entered.is_connected(_on_button_hover):
		button.mouse_entered.connect(_on_button_hover)


static func _on_button_pressed() -> void:
	var audio = Engine.get_singleton("AudioManager") if Engine.has_singleton("AudioManager") else null
	if not audio:
		audio = _get_audio_manager()
	if audio:
		audio.play_ui_click()


static func _on_button_hover() -> void:
	var audio = Engine.get_singleton("AudioManager") if Engine.has_singleton("AudioManager") else null
	if not audio:
		audio = _get_audio_manager()
	if audio:
		audio.play_ui_hover()


static func _get_audio_manager() -> Node:
	var tree = Engine.get_main_loop()
	if tree and tree is SceneTree:
		return tree.root.get_node_or_null("/root/AudioManager")
	return null
