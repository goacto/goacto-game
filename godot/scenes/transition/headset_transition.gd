extends Control
## HeadsetTransition - Visual transition when putting on/removing the neural headset
## Creates an immersive effect when traveling between bedroom and mindscape

@onready var background: ColorRect = $Background
@onready var vignette: ColorRect = $Vignette
@onready var center_ring: Polygon2D = $CenterEffects/Ring
@onready var center_glow: Polygon2D = $CenterEffects/Glow
@onready var particles_container: Node2D = $Particles
@onready var status_label: Label = $StatusLabel
@onready var subtitle_label: Label = $SubtitleLabel

# Transition settings
var transition_type: String = "enter"  # "enter" (to mindscape) or "exit" (to bedroom)
var target_scene: String = ""

# Animation state
var animation_time: float = 0.0
var phase: int = 0  # 0=fade_in, 1=hold, 2=fade_out
var phase_duration: float = 0.0

# Phase timings
const FADE_IN_TIME = 1.2
const HOLD_TIME = 2.0
const FADE_OUT_TIME = 0.8

# Visual settings
var ring_rotation: float = 0.0
var pulse_time: float = 0.0


func _ready() -> void:
	# Get transition parameters
	transition_type = GameManager.player_data.get("transition_type", "enter")
	target_scene = GameManager.player_data.get("transition_target", "res://scenes/mindscape/mindscape_hub.tscn")

	# Clear the transition data
	GameManager.player_data.erase("transition_type")
	GameManager.player_data.erase("transition_target")

	# Set up visuals based on transition type
	_setup_transition()

	# Start animation
	phase = 0
	phase_duration = 0.0

	# Initial state - invisible
	modulate.a = 0.0


func _process(delta: float) -> void:
	animation_time += delta
	phase_duration += delta

	# Animate based on current phase
	match phase:
		0:  # Fade in
			var progress = phase_duration / FADE_IN_TIME
			modulate.a = ease(progress, 0.3)
			_animate_effects(delta, progress)

			if phase_duration >= FADE_IN_TIME:
				phase = 1
				phase_duration = 0.0

		1:  # Hold - show the full effect
			modulate.a = 1.0
			_animate_effects(delta, 1.0)

			if phase_duration >= HOLD_TIME:
				phase = 2
				phase_duration = 0.0

		2:  # Fade out
			var progress = phase_duration / FADE_OUT_TIME
			modulate.a = 1.0 - ease(progress, 0.3)
			_animate_effects(delta, 1.0 - progress)

			if phase_duration >= FADE_OUT_TIME:
				_complete_transition()


func _setup_transition() -> void:
	if transition_type == "enter":
		# Entering mindscape - blue/cyan theme
		background.color = Color(0.02, 0.04, 0.08, 1)
		center_glow.color = Color(0.3, 0.6, 0.9, 0.6)
		center_ring.color = Color(0.4, 0.7, 1.0, 0.8)
		status_label.text = "NEURAL LINK ACTIVATING"
		subtitle_label.text = "Connecting to mindscape..."
		status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		subtitle_label.add_theme_color_override("font_color", Color(0.4, 0.6, 0.8))
		_create_particles(Color(0.4, 0.7, 1.0, 0.8))
	else:
		# Exiting to bedroom - gold/warm theme
		background.color = Color(0.06, 0.04, 0.02, 1)
		center_glow.color = Color(0.9, 0.7, 0.3, 0.6)
		center_ring.color = Color(1.0, 0.8, 0.4, 0.8)
		status_label.text = "NEURAL LINK DISCONNECTING"
		subtitle_label.text = "Returning to reality..."
		status_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
		subtitle_label.add_theme_color_override("font_color", Color(0.8, 0.65, 0.35))
		_create_particles(Color(1.0, 0.8, 0.4, 0.8))


func _create_particles(color: Color) -> void:
	# Create floating particles
	for i in range(20):
		var particle = Polygon2D.new()
		var size = randf_range(3, 8)
		particle.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(0, -size),
			Vector2(size, 0), Vector2(0, size)
		])
		particle.color = Color(color.r, color.g, color.b, randf_range(0.3, 0.7))

		# Random position in a ring pattern
		var angle = randf() * TAU
		var distance = randf_range(100, 400)
		particle.position = Vector2(cos(angle), sin(angle)) * distance
		particle.set_meta("base_angle", angle)
		particle.set_meta("distance", distance)
		particle.set_meta("speed", randf_range(0.3, 0.8))

		particles_container.add_child(particle)


func _animate_effects(delta: float, intensity: float) -> void:
	pulse_time += delta
	ring_rotation += delta * 0.5

	# Rotate and pulse the ring
	if center_ring:
		center_ring.rotation = ring_rotation
		var pulse = (sin(pulse_time * 3.0) + 1.0) / 2.0
		var scale_val = 0.8 + pulse * 0.4 * intensity
		center_ring.scale = Vector2(scale_val, scale_val)

	# Pulse the glow
	if center_glow:
		var glow_pulse = (sin(pulse_time * 2.0) + 1.0) / 2.0
		center_glow.modulate.a = (0.4 + glow_pulse * 0.6) * intensity
		var glow_scale = 1.0 + glow_pulse * 0.3 * intensity
		center_glow.scale = Vector2(glow_scale, glow_scale)

	# Animate particles - spiral inward or outward
	for particle in particles_container.get_children():
		var base_angle = particle.get_meta("base_angle", 0.0)
		var base_distance = particle.get_meta("distance", 200.0)
		var speed = particle.get_meta("speed", 0.5)

		# Spiral motion
		var current_angle = base_angle + animation_time * speed
		var distance_modifier = 1.0

		if transition_type == "enter":
			# Particles spiral inward when entering mindscape
			distance_modifier = 1.0 - (intensity * 0.5)
		else:
			# Particles spiral outward when exiting
			distance_modifier = 1.0 + (intensity * 0.3)

		var current_distance = base_distance * distance_modifier
		particle.position = Vector2(cos(current_angle), sin(current_angle)) * current_distance
		particle.modulate.a = intensity
		particle.rotation = current_angle

	# Animate labels
	if status_label:
		var label_pulse = (sin(pulse_time * 4.0) + 1.0) / 2.0
		status_label.modulate.a = (0.7 + label_pulse * 0.3) * intensity

	if subtitle_label:
		subtitle_label.modulate.a = intensity * 0.8


func _complete_transition() -> void:
	# Stop any playing voice audio when transitioning
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()

	# Transition to target scene
	if target_scene != "":
		if "mindscape" in target_scene:
			GameManager.change_state(GameManager.GameState.MINDSCAPE)
		get_tree().change_scene_to_file(target_scene)
	else:
		# Fallback to mindscape hub
		GameManager.change_state(GameManager.GameState.MINDSCAPE)
		get_tree().change_scene_to_file("res://scenes/mindscape/mindscape_hub.tscn")
