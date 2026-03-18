extends Control
class_name VirtualJoystick
## Touch-based virtual joystick for mobile controls

signal joystick_input(direction: Vector2)
signal joystick_released

@export var joystick_radius: float = 75.0
@export var knob_radius: float = 30.0
@export var dead_zone: float = 0.1
@export var clamp_zone: float = 1.0

var _is_pressed: bool = false
var _touch_index: int = -1
var _joystick_center: Vector2 = Vector2.ZERO
var _current_output: Vector2 = Vector2.ZERO

@onready var base: Polygon2D = $Base
@onready var knob: Polygon2D = $Knob


func _ready() -> void:
	_joystick_center = size / 2
	_create_joystick_graphics()
	_reset_knob_position()

	# Hide on desktop
	if not MobileUIManager.is_mobile:
		visible = false


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
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Check if touch is within joystick area
		var local_pos = event.position - global_position
		if local_pos.distance_to(_joystick_center) <= joystick_radius * 1.5:
			_is_pressed = true
			_touch_index = event.index
			_update_knob_position(local_pos)
	else:
		if event.index == _touch_index:
			_is_pressed = false
			_touch_index = -1
			_reset_knob_position()
			joystick_released.emit()


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


func _reset_knob_position() -> void:
	if knob:
		var tween = create_tween()
		tween.tween_property(knob, "position", _joystick_center, 0.1).set_ease(Tween.EASE_OUT)
	_current_output = Vector2.ZERO


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
