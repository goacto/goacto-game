extends Control
## RegionTransition - Quick portal warp effect when traveling between mindscape regions
## Faster than headset transition with region-themed colors

@onready var background: ColorRect = $Background
@onready var vignette: ColorRect = $Vignette
@onready var center_ring: Polygon2D = $CenterEffects/Ring
@onready var center_glow: Polygon2D = $CenterEffects/Glow
@onready var inner_ring: Polygon2D = $CenterEffects/InnerRing
@onready var particles_container: Node2D = $Particles
@onready var region_label: Label = $RegionLabel

# Transition settings
var target_scene: String = ""
var theme_color: Color = Color(0.5, 0.5, 0.8)

# Animation state
var animation_time: float = 0.0
var phase: int = 0  # 0=expand, 1=hold, 2=contract
var phase_duration: float = 0.0

# Phase timings (faster than headset transition)
const EXPAND_TIME = 0.6
const HOLD_TIME = 0.8
const CONTRACT_TIME = 0.5

# Visual settings
var ring_rotation: float = 0.0


@onready var center_effects: Node2D = $CenterEffects

func _ready() -> void:
	# Get transition parameters from GameManager
	target_scene = GameManager.player_data.get("transition_target", "res://scenes/mindscape/mindscape_hub.tscn")
	theme_color = GameManager.player_data.get("transition_color", Color(0.5, 0.5, 0.8))
	var region_name = _get_region_name_from_scene(target_scene)

	# Clear the transition data
	GameManager.player_data.erase("transition_type")
	GameManager.player_data.erase("transition_target")
	GameManager.player_data.erase("transition_color")

	# Center the effects based on actual viewport size
	_center_effects()

	# Set up visuals
	_setup_transition(region_name)

	# Create particles
	_create_portal_particles()

	# Start animation
	phase = 0
	phase_duration = 0.0

	# Initial state
	modulate.a = 0.0
	center_ring.scale = Vector2(0.1, 0.1)
	inner_ring.scale = Vector2(0.1, 0.1)

	# Connect to viewport size changes
	get_viewport().size_changed.connect(_center_effects)


func _center_effects() -> void:
	var viewport_size = get_viewport_rect().size
	var center = viewport_size / 2

	# Center the effects containers
	if center_effects:
		center_effects.position = center
	if particles_container:
		particles_container.position = center

	# Center and reposition the label
	if region_label:
		region_label.offset_top = viewport_size.y * 0.65
		region_label.offset_bottom = viewport_size.y * 0.65 + 50


func _process(delta: float) -> void:
	animation_time += delta
	phase_duration += delta
	ring_rotation += delta * 2.0

	# Animate based on current phase
	match phase:
		0:  # Expand - portal opens
			var progress = phase_duration / EXPAND_TIME
			var eased = ease(progress, 0.5)
			modulate.a = eased
			center_ring.scale = Vector2(eased, eased)
			inner_ring.scale = Vector2(eased * 0.7, eased * 0.7)
			_animate_effects(delta, eased)

			if phase_duration >= EXPAND_TIME:
				phase = 1
				phase_duration = 0.0

		1:  # Hold - full portal effect
			modulate.a = 1.0
			center_ring.scale = Vector2(1.0, 1.0)
			inner_ring.scale = Vector2(0.7, 0.7)
			_animate_effects(delta, 1.0)

			if phase_duration >= HOLD_TIME:
				phase = 2
				phase_duration = 0.0

		2:  # Contract - portal closes and transitions
			var progress = phase_duration / CONTRACT_TIME
			var inv_progress = 1.0 - ease(progress, 2.0)
			modulate.a = inv_progress
			var scale_val = max(0.1, inv_progress)
			center_ring.scale = Vector2(scale_val, scale_val)
			inner_ring.scale = Vector2(scale_val * 0.7, scale_val * 0.7)
			_animate_effects(delta, inv_progress)

			if phase_duration >= CONTRACT_TIME:
				_complete_transition()


func _setup_transition(region_name: String) -> void:
	# Set background to darkened theme color
	background.color = Color(theme_color.r * 0.1, theme_color.g * 0.1, theme_color.b * 0.1, 1)

	# Set ring colors based on theme
	center_glow.color = Color(theme_color.r, theme_color.g, theme_color.b, 0.5)
	center_ring.color = Color(theme_color.r * 1.2, theme_color.g * 1.2, theme_color.b * 1.2, 0.9)
	inner_ring.color = Color(theme_color.r * 0.8, theme_color.g * 0.8, theme_color.b * 0.8, 0.7)

	# Set region label
	region_label.text = region_name
	region_label.add_theme_color_override("font_color", Color(theme_color.r * 1.3, theme_color.g * 1.3, theme_color.b * 1.3))


func _get_region_name_from_scene(scene_path: String) -> String:
	# Check for custom label first
	var custom_label = GameManager.player_data.get("transition_label", "")
	if custom_label != "":
		GameManager.player_data.erase("transition_label")
		return custom_label

	if "hub" in scene_path:
		return "Central Hub"
	elif "north" in scene_path:
		return "Northern Gardens"
	elif "east" in scene_path:
		return "Eastern Observatory"
	elif "west" in scene_path:
		return "Western Depths"
	elif "south" in scene_path:
		return "Southern Peaks"
	elif "focus_mode" in scene_path:
		return "Focus Session"
	elif "bedroom" in scene_path:
		return "Your Room"
	return "Mindscape"


func _create_portal_particles() -> void:
	# Create swirling portal particles
	for i in range(24):
		var particle = Polygon2D.new()
		var size = randf_range(4, 10)
		particle.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(0, -size * 0.5),
			Vector2(size, 0), Vector2(0, size * 0.5)
		])
		particle.color = Color(theme_color.r, theme_color.g, theme_color.b, randf_range(0.4, 0.9))

		# Circular pattern
		var angle = (float(i) / 24.0) * TAU
		var distance = randf_range(80, 200)
		particle.position = Vector2(cos(angle), sin(angle)) * distance
		particle.set_meta("base_angle", angle)
		particle.set_meta("distance", distance)
		particle.set_meta("speed", randf_range(1.5, 3.0))
		particle.set_meta("orbit_offset", randf() * TAU)

		particles_container.add_child(particle)


func _animate_effects(delta: float, intensity: float) -> void:
	# Rotate rings in opposite directions
	if center_ring:
		center_ring.rotation = ring_rotation
	if inner_ring:
		inner_ring.rotation = -ring_rotation * 1.5

	# Pulse the glow
	if center_glow:
		var pulse = (sin(animation_time * 6.0) + 1.0) / 2.0
		center_glow.modulate.a = (0.5 + pulse * 0.5) * intensity
		var glow_scale = 1.0 + pulse * 0.2
		center_glow.scale = Vector2(glow_scale, glow_scale)

	# Animate particles in spiral pattern
	for particle in particles_container.get_children():
		var base_angle = particle.get_meta("base_angle", 0.0)
		var base_distance = particle.get_meta("distance", 150.0)
		var speed = particle.get_meta("speed", 2.0)
		var orbit_offset = particle.get_meta("orbit_offset", 0.0)

		# Spiral inward motion
		var current_angle = base_angle + animation_time * speed + orbit_offset
		var distance_pulse = sin(animation_time * 4.0 + orbit_offset) * 20
		var current_distance = (base_distance + distance_pulse) * intensity

		particle.position = Vector2(cos(current_angle), sin(current_angle)) * current_distance
		particle.modulate.a = intensity
		particle.rotation = current_angle + PI / 2

	# Animate label
	if region_label:
		var label_pulse = (sin(animation_time * 5.0) + 1.0) / 2.0
		region_label.modulate.a = (0.8 + label_pulse * 0.2) * intensity


func _complete_transition() -> void:
	# Stop any playing voice audio when transitioning
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()

	if target_scene != "":
		get_tree().change_scene_to_file(target_scene)
	else:
		# Fallback to hub
		get_tree().change_scene_to_file("res://scenes/mindscape/mindscape_hub.tscn")
