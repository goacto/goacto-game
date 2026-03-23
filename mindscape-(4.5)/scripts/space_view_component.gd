class_name SpaceViewComponent extends Node
## Reusable space view component for ship scenes
## Creates a fullscreen space window view with stars, nebula, and ambient effects

# =============================================================================
# CONFIGURATION
# =============================================================================

## Configuration for the space view appearance
var config = {
	"nebula_colors": [Color(0.2, 0.05, 0.3, 0.3), Color(0.1, 0.2, 0.4, 0.2)],
	"info_text": "Gazing out at the infinite cosmos...",
	"close_button_text": "Return",
	"show_comet": false,
	"show_space_station": false,
	"show_stellar_wanderer": false,
	"voice_path": "",
	"num_stars": 400
}

# =============================================================================
# STATE
# =============================================================================

var space_view_panel: Control = null
var animation_time: float = 0.0
var is_active: bool = false
var parent_scene: Control = null
var close_callback: Callable = Callable()

# Star animation
var star_nodes: Array = []
var shooting_stars: Array = []

# =============================================================================
# SIGNALS
# =============================================================================

signal space_view_opened
signal space_view_closed


# =============================================================================
# PUBLIC API
# =============================================================================

## Open the space view with optional configuration
func show(scene: Control, custom_config: Dictionary = {}, on_close: Callable = Callable()) -> void:
	if is_active:
		return

	parent_scene = scene
	close_callback = on_close

	# Merge custom config
	for key in custom_config:
		config[key] = custom_config[key]

	is_active = true
	animation_time = 0.0
	_create_space_view()
	space_view_opened.emit()


## Close the space view
func close() -> void:
	if not is_active:
		return

	_cleanup_space_view()


## Update animation (call from parent _process)
func update(delta: float) -> void:
	if not is_active:
		return

	animation_time += delta
	_animate_stars()
	_animate_shooting_stars(delta)


# =============================================================================
# SPACE VIEW CREATION
# =============================================================================

func _create_space_view() -> void:
	# Create fullscreen space view
	space_view_panel = Control.new()
	space_view_panel.name = "SpaceView"
	space_view_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	space_view_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	parent_scene.add_child(space_view_panel)

	# Deep space background
	var bg = ColorRect.new()
	bg.name = "SpaceBackground"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.015, 0.02, 0.05)
	space_view_panel.add_child(bg)

	# Stars container
	var stars_container = Node2D.new()
	stars_container.name = "Stars"
	space_view_panel.add_child(stars_container)
	_create_stars(stars_container)

	# Nebula
	_create_nebula()

	# Optional space objects
	if config.show_comet:
		_create_comet()
	if config.show_space_station:
		_create_space_station()
	if config.show_stellar_wanderer:
		_create_stellar_wanderer()

	# Window frame
	_create_window_frame()

	# Info text
	var info_label = Label.new()
	info_label.text = config.info_text
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9, 0.9))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	info_label.offset_top = -80
	info_label.offset_bottom = -50
	space_view_panel.add_child(info_label)

	# Close button
	var close_btn = Button.new()
	close_btn.text = config.close_button_text
	close_btn.custom_minimum_size = Vector2(180, 50)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	close_btn.offset_top = -50
	close_btn.offset_left = -90
	close_btn.offset_right = 90
	close_btn.offset_bottom = 0
	close_btn.pressed.connect(close)
	space_view_panel.add_child(close_btn)

	# Fade in
	space_view_panel.modulate.a = 0.0
	var tween = parent_scene.create_tween()
	tween.tween_property(space_view_panel, "modulate:a", 1.0, 0.5)

	# Play voiceover
	if config.voice_path != "":
		var audio = parent_scene.get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_voice_from_path"):
			audio.play_voice_from_path(config.voice_path)


func _cleanup_space_view() -> void:
	is_active = false

	# Stop audio
	var audio = parent_scene.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()

	if space_view_panel:
		var tween = parent_scene.create_tween()
		tween.tween_property(space_view_panel, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func():
			space_view_panel.queue_free()
			space_view_panel = null
			star_nodes.clear()
			shooting_stars.clear()
			space_view_closed.emit()
			if close_callback.is_valid():
				close_callback.call()
		)


# =============================================================================
# SPACE ELEMENTS
# =============================================================================

func _get_viewport_size() -> Vector2:
	if parent_scene and is_instance_valid(parent_scene):
		return parent_scene.get_viewport_rect().size
	return Vector2(1366, 768)  # Default fallback


func _create_stars(container: Node2D) -> void:
	star_nodes.clear()
	var viewport_size = _get_viewport_size()

	for i in range(config.num_stars):
		var star = _create_star()
		star.position = Vector2(
			randf_range(0, viewport_size.x),
			randf_range(0, viewport_size.y)
		)
		container.add_child(star)
		star_nodes.append(star)


func _create_star() -> Node2D:
	var star = Node2D.new()

	var polygon = Polygon2D.new()
	var size = randf_range(0.5, 2.5)

	# Star shape (4 points)
	var points = PackedVector2Array()
	points.append(Vector2(0, -size))
	points.append(Vector2(size * 0.3, 0))
	points.append(Vector2(0, size))
	points.append(Vector2(-size * 0.3, 0))
	polygon.polygon = points

	# Random warm/cool star color
	var brightness = randf_range(0.6, 1.0)
	if randf() < 0.3:
		polygon.color = Color(brightness, brightness * 0.9, brightness * 0.7)  # Warm
	else:
		polygon.color = Color(brightness * 0.8, brightness * 0.9, brightness)  # Cool

	star.add_child(polygon)

	# Store twinkle data
	star.set_meta("twinkle_speed", randf_range(1.5, 4.0))
	star.set_meta("twinkle_phase", randf() * TAU)
	star.set_meta("base_brightness", brightness)

	return star


func _create_nebula() -> void:
	var viewport_size = _get_viewport_size()
	var nebula_container = Node2D.new()
	nebula_container.name = "Nebula"
	space_view_panel.add_child(nebula_container)

	for i in range(config.nebula_colors.size()):
		var nebula_cloud = Polygon2D.new()
		var center = Vector2(
			randf_range(viewport_size.x * 0.2, viewport_size.x * 0.8),
			randf_range(viewport_size.y * 0.2, viewport_size.y * 0.8)
		)

		# Create cloud shape
		var points = PackedVector2Array()
		var num_points = 8
		for j in range(num_points):
			var angle = j * TAU / num_points
			var radius = randf_range(150, 300)
			points.append(center + Vector2(cos(angle) * radius, sin(angle) * radius))

		nebula_cloud.polygon = points
		nebula_cloud.color = config.nebula_colors[i]
		nebula_container.add_child(nebula_cloud)


func _create_window_frame() -> void:
	var viewport_size = _get_viewport_size()

	# Frame borders
	var frame_color = Color(0.12, 0.1, 0.15)
	var border_width = 60

	for side in ["top", "bottom", "left", "right"]:
		var border = ColorRect.new()
		border.color = frame_color

		match side:
			"top":
				border.size = Vector2(viewport_size.x, border_width)
			"bottom":
				border.position = Vector2(0, viewport_size.y - border_width)
				border.size = Vector2(viewport_size.x, border_width)
			"left":
				border.size = Vector2(border_width, viewport_size.y)
			"right":
				border.position = Vector2(viewport_size.x - border_width, 0)
				border.size = Vector2(border_width, viewport_size.y)

		space_view_panel.add_child(border)


func _create_comet() -> void:
	var viewport_size = _get_viewport_size()
	var comet = Node2D.new()
	comet.name = "Comet"
	comet.position = Vector2(viewport_size.x * 0.7, viewport_size.y * 0.25)

	# Comet head
	var head = Polygon2D.new()
	var points = PackedVector2Array([
		Vector2(10, 0), Vector2(3, 5), Vector2(-5, 3),
		Vector2(-5, -3), Vector2(3, -5)
	])
	head.polygon = points
	head.color = Color(0.9, 0.95, 1.0)
	comet.add_child(head)

	# Tail
	var tail = Polygon2D.new()
	tail.polygon = PackedVector2Array([
		Vector2(-5, 0), Vector2(-80, 8), Vector2(-120, 12),
		Vector2(-120, -12), Vector2(-80, -8)
	])
	tail.color = Color(0.4, 0.6, 0.9, 0.4)
	comet.add_child(tail)

	space_view_panel.add_child(comet)


func _create_space_station() -> void:
	var viewport_size = _get_viewport_size()
	var station = Node2D.new()
	station.name = "SpaceStation"
	station.position = Vector2(viewport_size.x * 0.2, viewport_size.y * 0.3)
	station.scale = Vector2(0.5, 0.5)

	# Simple station shape
	var core = Polygon2D.new()
	core.polygon = PackedVector2Array([
		Vector2(-20, -15), Vector2(20, -15), Vector2(25, -10),
		Vector2(25, 10), Vector2(20, 15), Vector2(-20, 15),
		Vector2(-25, 10), Vector2(-25, -10)
	])
	core.color = Color(0.5, 0.5, 0.55)
	station.add_child(core)

	# Solar panels
	for side in [-1, 1]:
		var panel = Polygon2D.new()
		panel.polygon = PackedVector2Array([
			Vector2(35 * side, -25), Vector2(80 * side, -25),
			Vector2(80 * side, 25), Vector2(35 * side, 25)
		])
		panel.color = Color(0.2, 0.25, 0.4, 0.8)
		station.add_child(panel)

	space_view_panel.add_child(station)


func _create_stellar_wanderer() -> void:
	var viewport_size = _get_viewport_size()
	var ship = Node2D.new()
	ship.name = "StellarWanderer"
	ship.position = Vector2(viewport_size.x * 0.75, viewport_size.y * 0.6)
	ship.scale = Vector2(0.3, 0.3)

	# Ship hull
	var hull = Polygon2D.new()
	hull.polygon = PackedVector2Array([
		Vector2(50, 0), Vector2(30, 15), Vector2(-30, 20),
		Vector2(-50, 10), Vector2(-50, -10), Vector2(-30, -20),
		Vector2(30, -15)
	])
	hull.color = Color(0.4, 0.35, 0.5)
	ship.add_child(hull)

	# Engine glow
	var glow = Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-50, 8), Vector2(-80, 4), Vector2(-80, -4), Vector2(-50, -8)
	])
	glow.color = Color(0.3, 0.5, 0.9, 0.6)
	ship.add_child(glow)

	space_view_panel.add_child(ship)


# =============================================================================
# ANIMATION
# =============================================================================

func _animate_stars() -> void:
	for star in star_nodes:
		var twinkle_speed = star.get_meta("twinkle_speed")
		var twinkle_phase = star.get_meta("twinkle_phase")
		var base_brightness = star.get_meta("base_brightness")

		var twinkle = (sin(animation_time * twinkle_speed + twinkle_phase) + 1) * 0.5
		var brightness = base_brightness * (0.5 + twinkle * 0.5)
		star.modulate.a = brightness


func _animate_shooting_stars(delta: float) -> void:
	# Occasionally spawn shooting star
	if randf() < 0.003 and shooting_stars.size() < 2:
		_spawn_shooting_star()

	# Update existing shooting stars
	for i in range(shooting_stars.size() - 1, -1, -1):
		var star = shooting_stars[i]
		if is_instance_valid(star):
			star.position += star.get_meta("velocity") * delta
			star.modulate.a -= delta * 0.8
			if star.modulate.a <= 0:
				star.queue_free()
				shooting_stars.remove_at(i)


func _spawn_shooting_star() -> void:
	if not space_view_panel:
		return

	var viewport_size = _get_viewport_size()
	var shooting_star = Node2D.new()

	# Random start position at top/right of screen
	if randf() < 0.5:
		shooting_star.position = Vector2(randf_range(0, viewport_size.x), 0)
	else:
		shooting_star.position = Vector2(viewport_size.x, randf_range(0, viewport_size.y * 0.5))

	# Velocity moving down-left
	var velocity = Vector2(randf_range(-300, -150), randf_range(150, 300))
	shooting_star.set_meta("velocity", velocity)

	# Create line shape
	var line = Line2D.new()
	line.points = PackedVector2Array([Vector2.ZERO, -velocity.normalized() * 30])
	line.width = 2
	line.default_color = Color(1, 1, 1, 0.8)
	shooting_star.add_child(line)

	var stars_node = space_view_panel.get_node_or_null("Stars")
	if stars_node:
		stars_node.add_child(shooting_star)
		shooting_stars.append(shooting_star)
