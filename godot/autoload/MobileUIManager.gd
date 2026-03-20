extends Node
## MobileUIManager - Handles responsive UI scaling and mobile-specific features

signal device_orientation_changed(is_portrait: bool)
signal screen_size_changed(size: Vector2)
signal platform_detected(platform: String)

# Debug flag - set to true in editor to test mobile controls on desktop
var DEBUG_FORCE_MOBILE: bool = false

# Platform detection
enum Platform { DESKTOP, IOS, ANDROID, WEB }
var current_platform: Platform = Platform.DESKTOP

# Screen info
var screen_size: Vector2 = Vector2.ZERO
var is_portrait: bool = false
var is_mobile: bool = false
var is_tablet: bool = false
var safe_area: Rect2 = Rect2()

# UI scaling
var ui_scale: float = 1.0
var base_font_size: int = 16
var touch_target_min_size: int = 44  # Apple HIG minimum

# Touch controls
var virtual_joystick_enabled: bool = false
var haptic_feedback_enabled: bool = true

# Breakpoints (width in pixels)
const BREAKPOINT_PHONE: int = 480
const BREAKPOINT_TABLET: int = 768
const BREAKPOINT_DESKTOP: int = 1024

# Scale factors for different screen sizes
const SCALE_PHONE: float = 0.8
const SCALE_TABLET: float = 0.9
const SCALE_DESKTOP: float = 1.0

func _ready() -> void:
	_detect_platform()
	_update_screen_info()
	get_tree().root.size_changed.connect(_on_viewport_size_changed)

	# Enable touch controls on mobile
	if is_mobile:
		virtual_joystick_enabled = true


func _detect_platform() -> void:
	# Debug override for testing mobile controls on desktop
	if DEBUG_FORCE_MOBILE:
		current_platform = Platform.ANDROID  # Simulate Android
		is_mobile = true
		print("[MobileUIManager] DEBUG: Forcing mobile mode for testing")
		platform_detected.emit("android (debug)")
		return

	var os_name = OS.get_name()

	match os_name:
		"iOS":
			current_platform = Platform.IOS
			is_mobile = true
		"Android":
			current_platform = Platform.ANDROID
			is_mobile = true
		"Web":
			current_platform = Platform.WEB
			# Check if web is on mobile device
			is_mobile = _is_mobile_web()
		_:
			current_platform = Platform.DESKTOP
			is_mobile = false

	platform_detected.emit(_get_platform_string())


func _is_mobile_web() -> bool:
	# Check viewport size for web mobile detection
	var viewport_size = get_viewport().get_visible_rect().size
	return viewport_size.x < BREAKPOINT_TABLET


func _get_platform_string() -> String:
	match current_platform:
		Platform.IOS: return "ios"
		Platform.ANDROID: return "android"
		Platform.WEB: return "web"
		_: return "desktop"


func _update_screen_info() -> void:
	var old_portrait = is_portrait
	var old_size = screen_size

	screen_size = get_viewport().get_visible_rect().size
	is_portrait = screen_size.y > screen_size.x

	# Determine device type based on screen size
	var smaller_dimension = min(screen_size.x, screen_size.y)
	is_tablet = smaller_dimension >= BREAKPOINT_TABLET and is_mobile

	# Calculate UI scale
	_calculate_ui_scale()

	# Get safe area for notched devices (iOS)
	_update_safe_area()

	# Emit signals if changed
	if is_portrait != old_portrait:
		device_orientation_changed.emit(is_portrait)

	if screen_size != old_size:
		screen_size_changed.emit(screen_size)


func _calculate_ui_scale() -> void:
	var width = screen_size.x

	if width < BREAKPOINT_PHONE:
		ui_scale = SCALE_PHONE
	elif width < BREAKPOINT_TABLET:
		ui_scale = SCALE_PHONE + (SCALE_TABLET - SCALE_PHONE) * ((width - BREAKPOINT_PHONE) / float(BREAKPOINT_TABLET - BREAKPOINT_PHONE))
	elif width < BREAKPOINT_DESKTOP:
		ui_scale = SCALE_TABLET + (SCALE_DESKTOP - SCALE_TABLET) * ((width - BREAKPOINT_TABLET) / float(BREAKPOINT_DESKTOP - BREAKPOINT_TABLET))
	else:
		ui_scale = SCALE_DESKTOP


func _update_safe_area() -> void:
	if current_platform == Platform.IOS:
		safe_area = DisplayServer.get_display_safe_area()
	else:
		safe_area = Rect2(Vector2.ZERO, screen_size)


func _on_viewport_size_changed() -> void:
	_update_screen_info()


# ===== PUBLIC API =====

## Get scaled size for UI elements
func get_scaled_size(base_size: float) -> float:
	return base_size * ui_scale


## Get scaled font size
func get_scaled_font_size(base_size: int = 16) -> int:
	return int(base_size * ui_scale)


## Get minimum touch target size (for accessibility)
func get_min_touch_size() -> int:
	return touch_target_min_size


## Check if we should show virtual joystick
func should_show_joystick() -> bool:
	return is_mobile and virtual_joystick_enabled


## Get safe area margins (for notched devices)
func get_safe_margins() -> Dictionary:
	return {
		"top": safe_area.position.y,
		"bottom": screen_size.y - (safe_area.position.y + safe_area.size.y),
		"left": safe_area.position.x,
		"right": screen_size.x - (safe_area.position.x + safe_area.size.x)
	}


## Trigger haptic feedback (iOS/Android)
func haptic_light() -> void:
	if haptic_feedback_enabled and is_mobile:
		# Godot 4 doesn't have built-in haptics, but this is where it would go
		# For iOS, you'd use a native plugin
		pass


func haptic_medium() -> void:
	if haptic_feedback_enabled and is_mobile:
		pass


func haptic_heavy() -> void:
	if haptic_feedback_enabled and is_mobile:
		pass


## Apply responsive styling to a Control node
func make_responsive(control: Control) -> void:
	if control is Button:
		_make_button_responsive(control)
	elif control is Label:
		_make_label_responsive(control)
	elif control is Panel or control is PanelContainer:
		_make_panel_responsive(control)


func _make_button_responsive(button: Button) -> void:
	# Ensure minimum touch target size
	button.custom_minimum_size.x = max(button.custom_minimum_size.x, touch_target_min_size)
	button.custom_minimum_size.y = max(button.custom_minimum_size.y, touch_target_min_size)


func _make_label_responsive(label: Label) -> void:
	# Scale font if using theme override
	if label.has_theme_font_size_override("font_size"):
		var base_size = label.get_theme_font_size("font_size")
		label.add_theme_font_size_override("font_size", get_scaled_font_size(base_size))


func _make_panel_responsive(panel: Control) -> void:
	# Add safe area margins on mobile
	if is_mobile:
		var margins = get_safe_margins()
		if panel.has_method("add_theme_constant_override"):
			panel.add_theme_constant_override("margin_top", int(margins.top))
			panel.add_theme_constant_override("margin_bottom", int(margins.bottom))


## Create a virtual joystick for touch controls
func create_virtual_joystick(parent: Node) -> Control:
	var joystick_container = Control.new()
	joystick_container.name = "VirtualJoystick"
	joystick_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick_container.position = Vector2(50, -200)
	joystick_container.size = Vector2(150, 150)

	# Joystick base (outer circle)
	var base = _create_joystick_base()
	joystick_container.add_child(base)

	# Joystick knob (inner circle)
	var knob = _create_joystick_knob()
	joystick_container.add_child(knob)

	# Add touch handling
	var touch_area = TouchScreenButton.new()
	touch_area.name = "JoystickTouch"
	touch_area.position = Vector2.ZERO
	# We'll handle input manually
	joystick_container.add_child(touch_area)

	parent.add_child(joystick_container)

	return joystick_container


func _create_joystick_base() -> Polygon2D:
	var base = Polygon2D.new()
	base.name = "JoystickBase"
	base.color = Color(0.2, 0.2, 0.3, 0.5)
	base.polygon = _create_circle_polygon(75, 32)
	base.position = Vector2(75, 75)
	return base


func _create_joystick_knob() -> Polygon2D:
	var knob = Polygon2D.new()
	knob.name = "JoystickKnob"
	knob.color = Color(0.4, 0.5, 0.7, 0.8)
	knob.polygon = _create_circle_polygon(30, 24)
	knob.position = Vector2(75, 75)
	return knob


func _create_circle_polygon(radius: float, segments: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(segments):
		var angle = i * TAU / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


## Get device info for analytics/debugging
func get_device_info() -> Dictionary:
	return {
		"platform": _get_platform_string(),
		"is_mobile": is_mobile,
		"is_tablet": is_tablet,
		"is_portrait": is_portrait,
		"screen_size": screen_size,
		"ui_scale": ui_scale,
		"safe_area": safe_area
	}


## Toggle mobile mode at runtime (for debugging)
func toggle_mobile_mode() -> void:
	is_mobile = not is_mobile
	virtual_joystick_enabled = is_mobile
	print("[MobileUIManager] Mobile mode: ", is_mobile)
	platform_detected.emit(_get_platform_string() + (" (forced)" if is_mobile and current_platform == Platform.DESKTOP else ""))


## Set mobile mode explicitly (for debugging)
func set_mobile_mode(enabled: bool) -> void:
	is_mobile = enabled
	virtual_joystick_enabled = enabled
	print("[MobileUIManager] Mobile mode set to: ", enabled)
