extends CanvasLayer
## TransitionManager - Handles smooth scene transitions with fade effects
## Autoload singleton for global transition control

# Transition overlay
var overlay: ColorRect = null
var is_transitioning: bool = false

# Transition settings
var fade_color: Color = Color(0, 0, 0, 1)
var default_duration: float = 0.3

# Signals
signal transition_started
signal transition_midpoint  # When fully faded (good time to change scene)
signal transition_finished


func _ready() -> void:
	# Set layer to be on top of everything
	layer = 100

	# Create full-screen overlay
	overlay = ColorRect.new()
	overlay.name = "TransitionOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0)  # Start transparent
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	print("[TransitionManager] Initialized")


## Fade out, call callback, fade in
func transition_to_scene(scene_path: String, duration: float = -1.0) -> void:
	if is_transitioning:
		return

	# Stop any playing voice audio when transitioning
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()

	if duration < 0:
		duration = default_duration

	is_transitioning = true
	transition_started.emit()

	# Fade out
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, duration).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		transition_midpoint.emit()
		# Change scene
		get_tree().change_scene_to_file(scene_path)
	)
	# Small delay for scene to load
	tween.tween_interval(0.1)
	# Fade in
	tween.tween_property(overlay, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		is_transitioning = false
		transition_finished.emit()
	)


## Just fade out (for custom handling)
func fade_out(duration: float = -1.0) -> void:
	if duration < 0:
		duration = default_duration

	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, duration).set_ease(Tween.EASE_IN)
	await tween.finished


## Just fade in (for custom handling)
func fade_in(duration: float = -1.0) -> void:
	if duration < 0:
		duration = default_duration

	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)
	await tween.finished


## Flash effect (quick white flash for impacts/achievements)
func flash(flash_color: Color = Color.WHITE, duration: float = 0.2) -> void:
	overlay.color = flash_color
	overlay.color.a = 0.8

	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)


## Set the fade color (default is black)
func set_fade_color(color: Color) -> void:
	fade_color = color
	overlay.color = Color(color.r, color.g, color.b, overlay.color.a)


## Ensure overlay is transparent (call after manual scene changes)
func ensure_visible() -> void:
	if overlay.color.a > 0 and not is_transitioning:
		fade_in(0.3)
