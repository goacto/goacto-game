extends CanvasLayer
## HudOverlay - shared HUD for every room scene:
##  - Phone/touch: resizes the virtual canvas so the game fills the screen (no letterbox void),
##    text is readable and buttons are finger-sized.
##  - On-screen touch controls: D-pad (move_* actions) + Interact (ui_accept).
##  - One-line objective tracker (top-left).
##  - Interact hint: "SPACE" with E / click (or Tap on touch) as alternates. E is added to ui_accept.

## Shortest side of the virtual canvas on phones. 600 keeps 1366x768-era panels on screen while
## scaling UI ~2.3x larger than the old fixed 1366-wide canvas on a 390px-wide phone.
const PHONE_SHORT_SIDE := 600
const PHONE_MAX_WINDOW_SHORT_SIDE := 900
const NON_ROOM_SCENES = ["main_menu", "settings", "cutscene", "transition"]
const SPACE_PROMPT := "Press SPACE"

var is_touch_layout := false
var _objective_label: Label
var _touch_root: Control
var _dpad: Control

func _ready() -> void:
	layer = 90
	_add_interact_key_alternate()
	_build_objective_tracker()
	_build_touch_controls()
	get_tree().root.size_changed.connect(_apply_canvas_scaling)
	_apply_canvas_scaling()


func _add_interact_key_alternate() -> void:
	var e_key := InputEventKey.new()
	e_key.physical_keycode = KEY_E
	if not InputMap.action_has_event("ui_accept", e_key):
		InputMap.action_add_event("ui_accept", e_key)


## Window size in CSS/logical pixels (web canvas size is in device pixels, so divide out DPR).
func _window_size() -> Vector2:
	var size := Vector2(DisplayServer.window_get_size())
	if OS.has_feature("web"):
		var dpr = JavaScriptBridge.eval("window.devicePixelRatio || 1")
		if dpr != null and float(dpr) > 0.0:
			size /= float(dpr)
	return size


func _is_phone_sized(window_size: Vector2) -> bool:
	if minf(window_size.x, window_size.y) > PHONE_MAX_WINDOW_SHORT_SIDE:
		return false
	if OS.has_feature("web"):
		# A finger is the primary pointer (phones/tablets), not a desktop with a touch-capable browser.
		return bool(JavaScriptBridge.eval("window.matchMedia('(pointer: coarse)').matches"))
	return OS.has_feature("mobile")


func _apply_canvas_scaling() -> void:
	var window_size := _window_size()
	if window_size.x <= 0 or window_size.y <= 0:
		return
	is_touch_layout = _is_phone_sized(window_size)
	var root := get_tree().root
	if is_touch_layout:
		var scale: float = PHONE_SHORT_SIDE / minf(window_size.x, window_size.y)
		root.content_scale_size = Vector2i(roundi(window_size.x * scale), roundi(window_size.y * scale))
	else:
		root.content_scale_size = Vector2i(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"))
	if MobileUIManager:
		MobileUIManager.is_mobile = MobileUIManager.is_mobile or is_touch_layout
		MobileUIManager.virtual_joystick_enabled = MobileUIManager.virtual_joystick_enabled or is_touch_layout


# ---------------------------------------------------------------- objective tracker

func _build_objective_tracker() -> void:
	_objective_label = Label.new()
	_objective_label.name = "ObjectiveTracker"
	_objective_label.position = Vector2(16, 62)
	_objective_label.add_theme_font_size_override("font_size", 15)
	_objective_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5, 0.95))
	_objective_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_objective_label.add_theme_constant_override("outline_size", 4)
	_objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_objective_label)


## One line, derived from story progress.
func current_objective() -> String:
	var pd: Dictionary = GameManager.player_data
	if not GameManager.has_item("mindscape_console"):
		return "Objective: Find Zyx's Mindscape Console somewhere on the ship"
	if pd.get("needs_console_placement", false):
		return "Objective: Set up the Mindscape Console in your room"
	return "Objective: Use the Mindscape Console to help your human focus"


# ---------------------------------------------------------------- touch controls

func _build_touch_controls() -> void:
	_touch_root = Control.new()
	_touch_root.name = "TouchControls"
	_touch_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_touch_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_touch_root)

	_dpad = Control.new()
	_dpad.name = "DPad"
	_dpad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_dpad.position = Vector2(20, -340)
	_dpad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch_root.add_child(_dpad)
	_add_dpad_button("Up", "^", Vector2(76, 0), "move_up")
	_add_dpad_button("Left", "<", Vector2(0, 76), "move_left")
	_add_dpad_button("Right", ">", Vector2(152, 76), "move_right")
	_add_dpad_button("Down", "v", Vector2(76, 152), "move_down")

	var interact := Button.new()
	interact.name = "InteractButton"
	interact.text = "Tap\nInteract"
	interact.add_theme_font_size_override("font_size", 20)
	interact.custom_minimum_size = Vector2(130, 130)
	interact.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	interact.position = Vector2(-150, -280)
	interact.modulate = Color(1, 1, 1, 0.8)
	interact.focus_mode = Control.FOCUS_NONE
	interact.button_down.connect(_press_interact)
	_touch_root.add_child(interact)


func _add_dpad_button(node_name: String, glyph: String, offset: Vector2, action: String) -> void:
	var b := Button.new()
	b.name = node_name
	b.text = glyph
	b.add_theme_font_size_override("font_size", 28)
	b.custom_minimum_size = Vector2(72, 72)
	b.position = offset
	b.modulate = Color(1, 1, 1, 0.7)
	b.focus_mode = Control.FOCUS_NONE
	b.button_down.connect(func(): Input.action_press(action))
	b.button_up.connect(func(): Input.action_release(action))
	_dpad.add_child(b)


func _press_interact() -> void:
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = "ui_accept"
		ev.pressed = pressed
		Input.parse_input_event(ev)


# ---------------------------------------------------------------- per-frame HUD state

func _is_room_scene(scene: Node) -> bool:
	if scene == null:
		return false
	for marker in NON_ROOM_SCENES:
		if scene.scene_file_path.contains(marker):
			return false
	return true


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var in_room := _is_room_scene(scene)
	_objective_label.visible = in_room
	if in_room:
		_objective_label.text = current_objective()
	_touch_root.visible = in_room and is_touch_layout
	# bedroom / hub ship their own joystick; don't stack a second movement control
	var in_dialogue: bool = scene != null and bool(scene.get("in_dialogue"))
	_dpad.visible = not in_dialogue and scene != null and scene.find_child("VirtualJoystick", true, false) == null
	if in_room:
		_update_interact_hint(scene)


func _update_interact_hint(scene: Node) -> void:
	var prompt := scene.get_node_or_null("InteractionPrompt")
	if prompt == null or not prompt.visible:
		return
	var label := prompt.find_child("PromptText", true, false) as Label
	if label == null or not label.text.begins_with(SPACE_PROMPT) or label.text.contains("(or "):
		return
	var alt := "Tap Interact" if is_touch_layout else "E / click"
	label.text = label.text.replace(SPACE_PROMPT, "Press SPACE (or %s)" % alt)
