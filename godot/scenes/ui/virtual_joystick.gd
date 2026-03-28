extends Control
class_name VirtualJoystick
## Touch-based virtual joystick + interaction button for mobile controls

signal joystick_input(direction: Vector2)
signal joystick_released
signal interact_pressed

@export var joystick_radius: float = 75.0
@export var knob_radius: float = 30.0
@export var dead_zone: float = 0.1
@export var clamp_zone: float = 1.0

var _is_pressed: bool = false
var _touch_index: int = -1
var _joystick_center: Vector2 = Vector2.ZERO
var _current_output: Vector2 = Vector2.ZERO

# Interaction button
var interact_button: Control = null
var _interact_touch_index: int = -1

@onready var base: Polygon2D = $Base
@onready var knob: Polygon2D = $Knob


func _ready() -> void:
	_joystick_center = size / 2
	_create_joystick_graphics()
	_reset_knob_position()

	# Store default position for returning after dynamic repositioning
	call_deferred("_store_default_position")

	# Hide on desktop, create interact button only on mobile
	if not MobileUIManager.is_mobile:
		visible = false
	else:
		# Defer button creation to ensure parent is ready
		call_deferred("_create_interact_button")


func _store_default_position() -> void:
	_default_position = global_position


func _create_joystick_graphics() -> void:
	if not base:
		base = Polygon2D.new()
		base.name = "Base"
		add_child(base)

	if not knob:
		knob = Polygon2D.new()
		knob.name = "Knob"
		add_child(knob)

	# Create base circle
	base.polygon = _create_circle(joystick_radius, 32)
	base.color = Color(0.15, 0.18, 0.25, 0.6)
	base.position = _joystick_center

	# Create knob circle
	knob.polygon = _create_circle(knob_radius, 24)
	knob.color = Color(0.3, 0.4, 0.6, 0.85)
	knob.position = _joystick_center

	# Add subtle glow to knob
	var glow = Polygon2D.new()
	glow.name = "KnobGlow"
	glow.polygon = _create_circle(knob_radius + 5, 24)
	glow.color = Color(0.4, 0.5, 0.7, 0.3)
	glow.z_index = -1
	knob.add_child(glow)


func _create_circle(radius: float, segments: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(segments):
		var angle = i * TAU / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		_handle_interact_touch(event)
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Dynamic joystick: any touch on the left half of the screen activates it
		var viewport_size = get_viewport_rect().size
		var is_left_half = event.position.x < viewport_size.x * 0.5
		var local_pos = event.position - global_position
		var is_in_joystick = local_pos.distance_to(_joystick_center) <= joystick_radius * 2.0

		if is_in_joystick or (is_left_half and not _is_pressed):
			_is_pressed = true
			_touch_index = event.index

			if is_left_half and not is_in_joystick:
				# Reposition joystick to touch point for dynamic feel
				global_position = event.position - _joystick_center
				local_pos = _joystick_center

			_update_knob_position(local_pos)
	else:
		if event.index == _touch_index:
			_is_pressed = false
			_touch_index = -1
			_reset_knob_position()
			joystick_released.emit()
			# Return joystick to default position
			_return_to_default_position()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if _is_pressed and event.index == _touch_index:
		var local_pos = event.position - global_position
		_update_knob_position(local_pos)


func _update_knob_position(touch_pos: Vector2) -> void:
	var delta = touch_pos - _joystick_center
	var distance = delta.length()

	# Clamp to joystick radius
	if distance > joystick_radius * clamp_zone:
		delta = delta.normalized() * joystick_radius * clamp_zone

	# Update knob visual position
	knob.position = _joystick_center + delta

	# Calculate output (-1 to 1 range)
	var output = delta / joystick_radius

	# Apply dead zone
	if output.length() < dead_zone:
		output = Vector2.ZERO
	else:
		# Remap to full range outside dead zone
		var adjusted_length = (output.length() - dead_zone) / (1.0 - dead_zone)
		output = output.normalized() * adjusted_length

	_current_output = output.clampf(-1.0, 1.0)
	joystick_input.emit(_current_output)


var _default_position: Vector2 = Vector2.ZERO

func _reset_knob_position() -> void:
	if knob:
		var tween = create_tween()
		tween.tween_property(knob, "position", _joystick_center, 0.1).set_ease(Tween.EASE_OUT)
	_current_output = Vector2.ZERO


func _return_to_default_position() -> void:
	if _default_position != Vector2.ZERO and global_position != _default_position:
		var tween = create_tween()
		tween.tween_property(self, "global_position", _default_position, 0.2).set_ease(Tween.EASE_OUT)


func get_output() -> Vector2:
	return _current_output


func is_active() -> bool:
	return _is_pressed


## Show/hide with animation
func show_joystick() -> void:
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)


func hide_joystick() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)


func _create_interact_button() -> void:
	# Only create on mobile
	if not MobileUIManager.is_mobile:
		return

	# Create interact button on the right side of the screen (large touch target)
	interact_button = Control.new()
	interact_button.name = "InteractButton"
	interact_button.custom_minimum_size = Vector2(100, 100)
	interact_button.size = Vector2(100, 100)

	# Position in bottom-right corner with comfortable margin
	var viewport_size = get_viewport_rect().size
	interact_button.position = Vector2(viewport_size.x - 140, viewport_size.y - 150)

	# Create button background (larger)
	var bg = Polygon2D.new()
	bg.name = "ButtonBg"
	bg.polygon = _create_circle(48, 24)
	bg.position = Vector2(50, 50)
	bg.color = Color(0.25, 0.35, 0.5, 0.7)
	interact_button.add_child(bg)

	# Create button glow
	var glow = Polygon2D.new()
	glow.name = "ButtonGlow"
	glow.polygon = _create_circle(54, 24)
	glow.position = Vector2(50, 50)
	glow.color = Color(0.4, 0.5, 0.7, 0.3)
	glow.z_index = -1
	interact_button.add_child(glow)

	# Create interact label
	var label = Label.new()
	label.name = "ButtonLabel"
	label.text = "TAP"
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(0, 18)
	label.size = Vector2(100, 60)
	interact_button.add_child(label)

	# Add to parent (the scene containing the joystick)
	var parent = get_parent()
	if parent:
		parent.add_child(interact_button)


func _handle_interact_touch(event: InputEventScreenTouch) -> void:
	if not interact_button or not interact_button.visible:
		return

	var button_rect = Rect2(interact_button.global_position, interact_button.size)

	if event.pressed:
		if button_rect.has_point(event.position):
			_interact_touch_index = event.index
			# Visual feedback
			var bg = interact_button.get_node_or_null("ButtonBg") as Polygon2D
			if bg:
				bg.color = Color(0.4, 0.5, 0.7, 0.9)
			interact_pressed.emit()
			# Simulate keyboard interact
			var input_event = InputEventAction.new()
			input_event.action = "ui_accept"
			input_event.pressed = true
			Input.parse_input_event(input_event)
	else:
		if event.index == _interact_touch_index:
			_interact_touch_index = -1
			# Reset visual
			var bg = interact_button.get_node_or_null("ButtonBg") as Polygon2D
			if bg:
				bg.color = Color(0.25, 0.35, 0.5, 0.7)


## Call this when UI panels open to hide mobile controls
func set_controls_visible(show: bool) -> void:
	if show:
		show_joystick()
		if interact_button:
			interact_button.visible = true
	else:
		hide_joystick()
		if interact_button:
			interact_button.visible = false


## Update interact button position when viewport changes
func update_button_position() -> void:
	if interact_button:
		var viewport_size = get_viewport_rect().size
		interact_button.position = Vector2(viewport_size.x - 130, viewport_size.y - 130)
