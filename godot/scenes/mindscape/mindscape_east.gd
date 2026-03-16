extends MindscapeRegionBase
## Eastern Observatory - Star Observatory and Reflection Pool
## A celestial area focused on cosmic insight, stargazing, and self-reflection
## EXPANDED VERSION with observatory dome, constellations, and cosmic atmosphere

# Enhanced visual elements
var environment_container: Node2D = null
var atmosphere_container: Node2D = null
var particles_container: Node2D = null
var detail_container: Node2D = null

# Animation state
var env_time: float = 0.0
var star_data: Array = []
var shooting_star_data: Array = []
var nebula_data: Array = []
var cosmic_dust_data: Array = []
var ripple_time: float = 0.0

# Zone panel graphic
var zone_graphic_container: Control = null

func _ready() -> void:
	# Get node references
	game_world = $GameWorld
	isometric_base = $GameWorld/IsometricBase
	player = $GameWorld/IsometricBase/Player
	zones_node = $GameWorld/IsometricBase/Zones
	hub_portal = $GameWorld/IsometricBase/HubPortal

	interaction_prompt = $InteractionPrompt
	zone_name_label = $InteractionPrompt/Margin/VBox/ZoneName
	prompt_text_label = $InteractionPrompt/Margin/VBox/PromptText
	control_hints = $ControlHints

	zone_panel = $ZonePanel
	zone_title = $ZonePanel/HBoxLayout/MenuSection/Margin/ZoneContent/ZoneHeader/ZoneTitle
	zone_body = $ZonePanel/HBoxLayout/MenuSection/Margin/ZoneContent/ZoneBody/ZoneBodyContent
	back_button = $ZonePanel/HBoxLayout/MenuSection/Margin/ZoneContent/ZoneHeader/BackButton
	zone_graphic_container = $ZonePanel/HBoxLayout/GraphicSection/GraphicContainer

	dialogue_panel = $DialoguePanel
	speaker_name = $DialoguePanel/Margin/VBox/SpeakerName
	dialogue_text = $DialoguePanel/Margin/VBox/DialogueText
	dialogue_continue = $DialoguePanel/Margin/VBox/ContinueButton

	evolution_label = $Header/Margin/HBox/EvolutionContainer/EvolutionLabel
	evolution_bar = $Header/Margin/HBox/EvolutionContainer/EvolutionBar
	date_label = $Header/Margin/HBox/DateLabel
	menu_button = $Header/Margin/HBox/MenuButton

	pause_menu = $PauseMenu
	var close_menu_button = $PauseMenu/Margin/VBox/MenuHeader/CloseMenuButton
	var resume_button = $PauseMenu/Margin/VBox/MenuContent/MenuBody/ResumeButton
	var exit_button = $PauseMenu/Margin/VBox/MenuContent/MenuBody/ReturnToHubButton

	close_menu_button.pressed.connect(_close_pause_menu)
	resume_button.pressed.connect(_close_pause_menu)
	exit_button.pressed.connect(_travel_to_hub)

	# Setup region config
	setup_region({
		"region_id": "east",
		"region_name": "Eastern Observatory",
		"theme_color": Color(0.5, 0.5, 0.8),
		"zone_names": {
			"Observatory": "Star Observatory",
			"ReflectionPool": "Reflection Pool"
		},
		"player_bounds": Rect2(-900, -700, 1800, 1400)  # Expanded bounds
	})

	# Create enhanced environment BEFORE initialize_region
	_create_enhanced_environment()

	initialize_region()


func _process(delta: float) -> void:
	env_time += delta
	ripple_time += delta
	_animate_environment(delta)
	process_region(delta)


func _input(event: InputEvent) -> void:
	handle_input(event)


# =============================================================================
# ENHANCED ENVIRONMENT CREATION
# =============================================================================

func _create_enhanced_environment() -> void:
	# Create containers - add environment FIRST so it renders behind
	environment_container = Node2D.new()
	environment_container.name = "Environment"
	isometric_base.add_child(environment_container)
	isometric_base.move_child(environment_container, 0)

	detail_container = Node2D.new()
	detail_container.name = "Details"
	isometric_base.add_child(detail_container)
	isometric_base.move_child(detail_container, 1)

	particles_container = Node2D.new()
	particles_container.name = "Particles"
	particles_container.z_index = 10
	isometric_base.add_child(particles_container)

	atmosphere_container = Node2D.new()
	atmosphere_container.name = "Atmosphere"
	atmosphere_container.z_index = 15
	isometric_base.add_child(atmosphere_container)

	# Build the celestial observatory environment
	_create_cosmic_backdrop()
	_create_observatory_platform()
	_create_stone_pathways()
	_create_reflection_pool_area()
	_create_observatory_dome()
	_create_constellation_markers()
	_create_ancient_pillars()
	_create_stargazing_platforms()

	# Create atmospheric particles
	_create_twinkling_stars()
	_create_shooting_stars()
	_create_nebula_wisps()
	_create_cosmic_dust()


func _create_cosmic_backdrop() -> void:
	# Deep space gradient floor - more visible
	var space_floor = Polygon2D.new()
	space_floor.polygon = PackedVector2Array([
		Vector2(-1000, 0),
		Vector2(0, -550),
		Vector2(1000, 0),
		Vector2(0, 700)
	])
	space_floor.color = Color(0.08, 0.1, 0.18, 1.0)
	environment_container.add_child(space_floor)

	# Lighter inner region for contrast
	var inner_space = Polygon2D.new()
	inner_space.polygon = PackedVector2Array([
		Vector2(-800, 0),
		Vector2(0, -450),
		Vector2(800, 0),
		Vector2(0, 550)
	])
	inner_space.color = Color(0.1, 0.12, 0.22, 1.0)
	environment_container.add_child(inner_space)

	# More visible nebula glow areas
	var nebula_colors = [
		Color(0.3, 0.15, 0.5, 0.3),
		Color(0.15, 0.3, 0.5, 0.25),
		Color(0.4, 0.15, 0.4, 0.22)
	]
	var nebula_positions = [
		Vector2(-400, -200),
		Vector2(350, -100),
		Vector2(-100, 300)
	]

	for i in range(nebula_positions.size()):
		var nebula = Polygon2D.new()
		var size = randf_range(150, 250)
		nebula.polygon = _create_soft_blob(size)
		nebula.position = nebula_positions[i]
		nebula.color = nebula_colors[i]
		environment_container.add_child(nebula)


func _create_soft_blob(size: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	var segments = 12
	for i in range(segments):
		var angle = (float(i) / segments) * TAU
		var radius = size * (0.8 + randf() * 0.4)
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius * 0.5))
	return points


func _create_observatory_platform() -> void:
	# Main elevated platform for the observatory - more visible
	var main_platform = Polygon2D.new()
	main_platform.polygon = PackedVector2Array([
		Vector2(-450, -50),
		Vector2(-200, -200),
		Vector2(200, -200),
		Vector2(450, -50),
		Vector2(450, 100),
		Vector2(200, 250),
		Vector2(-200, 250),
		Vector2(-450, 100)
	])
	main_platform.color = Color(0.14, 0.16, 0.26, 1.0)
	environment_container.add_child(main_platform)

	# Platform edge highlight
	var platform_edge = Polygon2D.new()
	platform_edge.polygon = PackedVector2Array([
		Vector2(-450, 100),
		Vector2(450, 100),
		Vector2(200, 250),
		Vector2(-200, 250)
	])
	platform_edge.color = Color(0.18, 0.2, 0.32, 1.0)
	environment_container.add_child(platform_edge)

	# Glowing runes on platform - brighter
	var rune_positions = [
		Vector2(-300, 50), Vector2(-150, -50), Vector2(0, 0),
		Vector2(150, -50), Vector2(300, 50)
	]
	for pos in rune_positions:
		var rune = Polygon2D.new()
		rune.polygon = PackedVector2Array([
			Vector2(-10, 0), Vector2(0, -10), Vector2(10, 0), Vector2(0, 10)
		])
		rune.position = pos
		rune.color = Color(0.5, 0.6, 1.0, 0.7)
		detail_container.add_child(rune)


func _create_stone_pathways() -> void:
	# Path from hub portal to center - visible stones
	var path_stones_1 = [
		Vector2(-450, 150), Vector2(-350, 100), Vector2(-250, 50)
	]
	_create_stone_path(path_stones_1)

	# Path to reflection pool
	var path_stones_2 = [
		Vector2(150, 100), Vector2(230, 140), Vector2(300, 175)
	]
	_create_stone_path(path_stones_2)

	# Circular path around observatory - reduced count
	for i in range(8):
		var angle = (float(i) / 8) * TAU
		var radius = 180
		var stone = Polygon2D.new()
		var size = randf_range(18, 28)
		stone.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(0, -size * 0.5),
			Vector2(size, 0), Vector2(0, size * 0.5)
		])
		stone.position = Vector2(cos(angle) * radius, sin(angle) * radius * 0.5)
		stone.color = Color(0.18, 0.2, 0.32, 0.95)
		detail_container.add_child(stone)


func _create_stone_path(positions: Array) -> void:
	for pos in positions:
		var stone = Polygon2D.new()
		var size = randf_range(25, 40)
		stone.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(-size * 0.3, -size * 0.4),
			Vector2(size * 0.3, -size * 0.4), Vector2(size, 0),
			Vector2(size * 0.3, size * 0.4), Vector2(-size * 0.3, size * 0.4)
		])
		stone.position = pos
		stone.color = Color(0.18, 0.2, 0.3, 0.95)
		detail_container.add_child(stone)


func _create_reflection_pool_area() -> void:
	# Pool platform - positioned closer to center, more visible
	var pool_platform = Polygon2D.new()
	pool_platform.polygon = PackedVector2Array([
		Vector2(-140, 0),
		Vector2(0, -80),
		Vector2(140, 0),
		Vector2(0, 80)
	])
	pool_platform.position = Vector2(350, 200)
	pool_platform.color = Color(0.12, 0.14, 0.22, 1.0)
	environment_container.add_child(pool_platform)

	# Pool water (cosmic reflection) - brighter blue
	var pool_water = Polygon2D.new()
	pool_water.polygon = PackedVector2Array([
		Vector2(-110, 0),
		Vector2(0, -60),
		Vector2(110, 0),
		Vector2(0, 60)
	])
	pool_water.position = Vector2(350, 200)
	pool_water.color = Color(0.2, 0.35, 0.6, 0.95)
	detail_container.add_child(pool_water)

	# Star reflections in pool - brighter
	for i in range(5):
		var star_reflect = Polygon2D.new()
		star_reflect.polygon = PackedVector2Array([
			Vector2(-4, 0), Vector2(0, -4), Vector2(4, 0), Vector2(0, 4)
		])
		star_reflect.position = Vector2(
			350 + randf_range(-70, 70),
			200 + randf_range(-35, 35)
		)
		star_reflect.color = Color(0.9, 0.92, 1.0, 0.7)
		detail_container.add_child(star_reflect)

	# Pool border stones
	for i in range(8):
		var angle = (float(i) / 8) * TAU
		var border_stone = Polygon2D.new()
		border_stone.polygon = PackedVector2Array([
			Vector2(-15, 0), Vector2(0, -10), Vector2(15, 0), Vector2(0, 10)
		])
		border_stone.position = Vector2(
			350 + cos(angle) * 120,
			200 + sin(angle) * 65
		)
		border_stone.color = Color(0.2, 0.24, 0.36, 1.0)
		detail_container.add_child(border_stone)


func _create_observatory_dome() -> void:
	# NOTE: The main observatory dome is already in the .tscn file at the Observatory zone
	# This creates an additional smaller dome structure in the environment

	# Secondary observatory structure - moved to not overlap with zone
	var secondary_dome_pos = Vector2(-150, -280)

	# Small dome base
	var dome_base = Polygon2D.new()
	dome_base.polygon = PackedVector2Array([
		Vector2(-50, 0),
		Vector2(-40, -15),
		Vector2(40, -15),
		Vector2(50, 0),
		Vector2(40, 15),
		Vector2(-40, 15)
	])
	dome_base.position = secondary_dome_pos
	dome_base.color = Color(0.18, 0.2, 0.32, 1.0)
	detail_container.add_child(dome_base)

	# Small dome
	var dome = Polygon2D.new()
	dome.polygon = PackedVector2Array([
		Vector2(-35, 0),
		Vector2(-30, -20),
		Vector2(-15, -35),
		Vector2(15, -35),
		Vector2(30, -20),
		Vector2(35, 0)
	])
	dome.position = secondary_dome_pos + Vector2(0, -15)
	dome.color = Color(0.24, 0.28, 0.44, 1.0)
	detail_container.add_child(dome)

	# Small scope
	var scope = Polygon2D.new()
	scope.polygon = PackedVector2Array([
		Vector2(-3, 0), Vector2(-5, -25), Vector2(-2, -40),
		Vector2(2, -40), Vector2(5, -25), Vector2(3, 0)
	])
	scope.position = secondary_dome_pos + Vector2(0, -45)
	scope.color = Color(0.32, 0.36, 0.52, 1.0)
	detail_container.add_child(scope)

	# Scope glow
	var lens_glow = Polygon2D.new()
	lens_glow.polygon = PackedVector2Array([
		Vector2(-6, 0), Vector2(0, -6), Vector2(6, 0), Vector2(0, 6)
	])
	lens_glow.position = secondary_dome_pos + Vector2(0, -88)
	lens_glow.color = Color(0.6, 0.7, 1.0, 0.9)
	detail_container.add_child(lens_glow)


func _create_constellation_markers() -> void:
	# Create simple constellation patterns on the ground - reduced complexity
	# Simple triangle constellation
	var triangle_points = [
		Vector2(0, -40), Vector2(-35, 20), Vector2(35, 20)
	]
	_create_constellation("Triangle", triangle_points, Vector2(200, -100))

	# Simple big dipper shape
	var dipper_points = [
		Vector2(0, 0), Vector2(25, -8), Vector2(50, 0), Vector2(65, 15)
	]
	_create_constellation("Dipper", dipper_points, Vector2(-200, 100))


func _create_constellation(constellation_name: String, points: Array, offset: Vector2) -> void:
	# Draw connecting lines first (behind stars)
	for i in range(points.size() - 1):
		var line_start = points[i] + offset
		var line_end = points[i + 1] + offset
		var line = _create_line_polygon(line_start, line_end, 2.0)
		line.color = Color(0.5, 0.6, 0.9, 0.5)
		detail_container.add_child(line)

	# Draw constellation star points - brighter
	for i in range(points.size()):
		var star_marker = Polygon2D.new()
		star_marker.polygon = PackedVector2Array([
			Vector2(-6, 0), Vector2(0, -6), Vector2(6, 0), Vector2(0, 6)
		])
		star_marker.position = points[i] + offset
		star_marker.color = Color(0.7, 0.8, 1.0, 0.8)
		detail_container.add_child(star_marker)


func _create_line_polygon(start: Vector2, end: Vector2, width: float) -> Polygon2D:
	var line = Polygon2D.new()
	var direction = (end - start).normalized()
	var perpendicular = Vector2(-direction.y, direction.x) * width
	line.polygon = PackedVector2Array([
		start + perpendicular,
		start - perpendicular,
		end - perpendicular,
		end + perpendicular
	])
	return line


func _create_ancient_pillars() -> void:
	# Stone pillars - reduced count, more visible colors
	var pillar_positions = [
		Vector2(-550, 0), Vector2(550, 50),
		Vector2(-100, -300), Vector2(100, -300)
	]

	for pos in pillar_positions:
		# Pillar base
		var base = Polygon2D.new()
		base.polygon = PackedVector2Array([
			Vector2(-25, 0), Vector2(0, -15), Vector2(25, 0), Vector2(0, 15)
		])
		base.position = pos
		base.color = Color(0.18, 0.2, 0.3, 1.0)
		detail_container.add_child(base)

		# Pillar column
		var column = Polygon2D.new()
		column.polygon = PackedVector2Array([
			Vector2(-15, 0), Vector2(-15, -80), Vector2(15, -80), Vector2(15, 0)
		])
		column.position = pos
		column.color = Color(0.22, 0.24, 0.36, 1.0)
		detail_container.add_child(column)

		# Crystal glow (behind crystal)
		var glow = Polygon2D.new()
		glow.polygon = PackedVector2Array([
			Vector2(-18, 5), Vector2(-20, -20), Vector2(0, -40),
			Vector2(20, -20), Vector2(18, 5)
		])
		glow.position = pos + Vector2(0, -80)
		glow.color = Color(0.6, 0.7, 1.0, 0.4)
		detail_container.add_child(glow)

		# Pillar top crystal - brighter
		var crystal = Polygon2D.new()
		crystal.polygon = PackedVector2Array([
			Vector2(-10, 0), Vector2(-12, -15), Vector2(0, -30),
			Vector2(12, -15), Vector2(10, 0)
		])
		crystal.position = pos + Vector2(0, -80)
		crystal.color = Color(0.5, 0.6, 1.0, 0.9)
		detail_container.add_child(crystal)


func _create_stargazing_platforms() -> void:
	# Small meditation platforms for stargazing - fewer, more visible
	var platform_positions = [
		Vector2(-550, 350), Vector2(600, -150)
	]

	for pos in platform_positions:
		# Platform
		var platform = Polygon2D.new()
		platform.polygon = PackedVector2Array([
			Vector2(-55, 0), Vector2(0, -32), Vector2(55, 0), Vector2(0, 32)
		])
		platform.position = pos
		platform.color = Color(0.14, 0.16, 0.26, 1.0)
		environment_container.add_child(platform)

		# Cushion/mat - brighter purple
		var cushion = Polygon2D.new()
		cushion.polygon = PackedVector2Array([
			Vector2(-22, 0), Vector2(0, -13), Vector2(22, 0), Vector2(0, 13)
		])
		cushion.position = pos + Vector2(0, -5)
		cushion.color = Color(0.45, 0.35, 0.65, 0.95)
		detail_container.add_child(cushion)


# =============================================================================
# ATMOSPHERIC PARTICLE CREATION
# =============================================================================

func _create_twinkling_stars() -> void:
	# Create background stars that twinkle (reduced count for performance)
	for i in range(25):
		var star = Polygon2D.new()
		var size = randf_range(3, 7)
		star.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(0, -size),
			Vector2(size, 0), Vector2(0, size)
		])
		star.position = Vector2(
			randf_range(-700, 700),
			randf_range(-450, 350)
		)
		var brightness = randf_range(0.6, 1.0)
		star.color = Color(0.95, 0.95, 1.0, brightness)
		atmosphere_container.add_child(star)

		star_data.append({
			"polygon": star,
			"base_alpha": brightness,
			"twinkle_speed": randf_range(1.5, 3.5),
			"twinkle_offset": randf() * TAU
		})


func _create_shooting_stars() -> void:
	# Create occasional shooting stars (reduced for performance)
	for i in range(2):
		var shooting_star = Node2D.new()
		shooting_star.position = Vector2(
			randf_range(-600, 600),
			randf_range(-400, -150)
		)
		shooting_star.visible = false

		# Star head
		var head = Polygon2D.new()
		head.polygon = PackedVector2Array([
			Vector2(-5, 0), Vector2(0, -5), Vector2(5, 0), Vector2(0, 5)
		])
		head.color = Color(1.0, 1.0, 0.95, 1.0)
		shooting_star.add_child(head)

		# Trail
		var trail = Polygon2D.new()
		trail.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(-50, -25), Vector2(-45, -22), Vector2(0, 2)
		])
		trail.color = Color(0.85, 0.9, 1.0, 0.5)
		shooting_star.add_child(trail)

		atmosphere_container.add_child(shooting_star)

		shooting_star_data.append({
			"node": shooting_star,
			"active": false,
			"timer": randf_range(3.0, 10.0),
			"velocity": Vector2(randf_range(200, 400), randf_range(100, 200)),
			"lifetime": 0.0
		})


func _create_nebula_wisps() -> void:
	# Floating nebula wisps (reduced for performance)
	for i in range(6):
		var wisp = Polygon2D.new()
		var size = randf_range(50, 100)
		wisp.polygon = _create_soft_blob(size)
		wisp.position = Vector2(
			randf_range(-500, 500),
			randf_range(-350, 250)
		)
		var hue = randf_range(0.6, 0.8)  # Blue to purple range
		wisp.color = Color.from_hsv(hue, 0.5, 0.6, 0.2)
		particles_container.add_child(wisp)

		nebula_data.append({
			"polygon": wisp,
			"base_pos": wisp.position,
			"drift_speed": randf_range(0.05, 0.12),
			"drift_range": randf_range(25, 50),
			"phase": randf() * TAU
		})


func _create_cosmic_dust() -> void:
	# Tiny floating cosmic dust particles (reduced for performance)
	for i in range(15):
		var dust = Polygon2D.new()
		dust.polygon = PackedVector2Array([
			Vector2(-2.5, 0), Vector2(0, -2.5), Vector2(2.5, 0), Vector2(0, 2.5)
		])
		dust.position = Vector2(
			randf_range(-600, 600),
			randf_range(-350, 350)
		)
		dust.color = Color(0.85, 0.88, 1.0, randf_range(0.5, 0.8))
		particles_container.add_child(dust)

		cosmic_dust_data.append({
			"polygon": dust,
			"velocity": Vector2(randf_range(-8, 8), randf_range(-4, 4)),
			"drift_phase": randf() * TAU
		})


# =============================================================================
# ANIMATION
# =============================================================================

func _animate_environment(delta: float) -> void:
	_animate_stars(delta)
	_animate_shooting_stars(delta)
	_animate_nebula(delta)
	_animate_cosmic_dust(delta)


func _animate_stars(delta: float) -> void:
	for data in star_data:
		var twinkle = sin(env_time * data.twinkle_speed + data.twinkle_offset)
		var alpha = data.base_alpha * (0.7 + twinkle * 0.3)
		data.polygon.color.a = alpha


func _animate_shooting_stars(delta: float) -> void:
	for data in shooting_star_data:
		if data.active:
			data.lifetime += delta
			data.node.position += data.velocity * delta

			# Fade out over time
			var alpha = 1.0 - (data.lifetime / 1.5)
			if alpha <= 0:
				data.active = false
				data.node.visible = false
				data.timer = randf_range(5.0, 15.0)
			else:
				data.node.modulate.a = alpha
		else:
			data.timer -= delta
			if data.timer <= 0:
				# Reset and activate shooting star
				data.active = true
				data.lifetime = 0.0
				data.node.visible = true
				data.node.modulate.a = 1.0
				data.node.position = Vector2(
					randf_range(-600, 200),
					randf_range(-500, -300)
				)
				data.velocity = Vector2(
					randf_range(250, 450),
					randf_range(100, 200)
				)


func _animate_nebula(delta: float) -> void:
	for data in nebula_data:
		if not data.has("phase"):
			continue
		var offset_x = sin(env_time * data.drift_speed + data.phase) * data.drift_range
		var offset_y = cos(env_time * data.drift_speed * 0.7 + data.phase) * data.drift_range * 0.5
		data.polygon.position = data.base_pos + Vector2(offset_x, offset_y)

		# Subtle alpha pulse - brighter
		var alpha_pulse = 0.1 + sin(env_time * 0.5 + data.phase) * 0.04
		data.polygon.color.a = alpha_pulse


func _animate_cosmic_dust(delta: float) -> void:
	for data in cosmic_dust_data:
		# Gentle drift
		data.drift_phase += delta * 0.5
		var drift = Vector2(
			sin(data.drift_phase) * 0.5,
			cos(data.drift_phase * 0.7) * 0.3
		)
		data.polygon.position += (data.velocity * 0.1 + drift) * delta

		# Wrap around
		if data.polygon.position.x < -850:
			data.polygon.position.x = 850
		elif data.polygon.position.x > 850:
			data.polygon.position.x = -850
		if data.polygon.position.y < -550:
			data.polygon.position.y = 550
		elif data.polygon.position.y > 550:
			data.polygon.position.y = -550


# =============================================================================
# ZONE INTERACTIONS
# =============================================================================

func _open_zone(zone_id: String) -> void:
	# Hide interaction prompt when opening any zone panel
	_hide_interaction_prompt()

	match zone_id:
		"Observatory":
			_open_observatory()
		"ReflectionPool":
			_open_reflection_pool()
		_:
			super._open_zone(zone_id)


func _open_observatory() -> void:
	zone_title.text = "Star Observatory"
	_clear_zone_body()
	_create_observatory_graphic()

	var intro = Label.new()
	intro.text = "Gaze upon the stars and contemplate your place in the cosmos. Track celestial events and find cosmic inspiration."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(intro)

	var stargaze_button = Button.new()
	stargaze_button.text = "Stargaze"
	stargaze_button.pressed.connect(_stargaze)
	zone_body.add_child(stargaze_button)

	var constellation_button = Button.new()
	constellation_button.text = "Study Constellations"
	constellation_button.pressed.connect(_study_constellations)
	zone_body.add_child(constellation_button)

	zone_panel.visible = true
	in_zone_panel = true


func _open_reflection_pool() -> void:
	zone_title.text = "Reflection Pool"
	_clear_zone_body()
	_create_reflection_pool_graphic()

	var intro = Label.new()
	intro.text = "A tranquil pool that reflects not just light, but truth. Journal your thoughts and gain clarity through cosmic reflection."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(intro)

	# Quick insights summary
	_add_pool_spacer(10)
	_add_insights_summary()

	_add_pool_spacer(15)

	var journal_button = Button.new()
	journal_button.text = "Write Reflection"
	journal_button.custom_minimum_size = Vector2(0, 45)
	journal_button.add_theme_font_size_override("font_size", 18)
	journal_button.pressed.connect(_open_write_journal)
	zone_body.add_child(journal_button)

	_add_pool_spacer(8)

	var view_journal_button = Button.new()
	view_journal_button.text = "View Journal"
	view_journal_button.custom_minimum_size = Vector2(0, 45)
	view_journal_button.add_theme_font_size_override("font_size", 18)
	view_journal_button.pressed.connect(_open_journal_viewer)
	zone_body.add_child(view_journal_button)

	_add_pool_spacer(8)

	var insights_button = Button.new()
	insights_button.text = "View Insights & Stats"
	insights_button.custom_minimum_size = Vector2(0, 45)
	insights_button.add_theme_font_size_override("font_size", 18)
	insights_button.pressed.connect(_open_insights_panel)
	zone_body.add_child(insights_button)

	_add_pool_spacer(8)

	var meditate_button = Button.new()
	meditate_button.text = "Meditate"
	meditate_button.custom_minimum_size = Vector2(0, 45)
	meditate_button.add_theme_font_size_override("font_size", 18)
	meditate_button.pressed.connect(_meditate)
	zone_body.add_child(meditate_button)

	zone_panel.visible = true
	in_zone_panel = true


func _add_pool_spacer(height: int) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	zone_body.add_child(spacer)


func _add_insights_summary() -> void:
	var journal = _load_focus_journal()

	# Count different entry types
	var focus_count = 0
	var reflection_count = 0
	var total_focus_minutes = 0

	for entry in journal:
		var entry_type = entry.get("type", "")
		if entry_type == "focus":
			focus_count += 1
			total_focus_minutes += int(entry.get("duration_minutes", 0))
		elif entry_type == "reflection":
			reflection_count += 1

	# Get habit stats
	var habit_completions = 0
	var current_streaks = 0
	for habit_id in HabitManager.habits:
		var habit = HabitManager.habits[habit_id]
		habit_completions += habit.get("completion_history", []).size()
		if habit.get("streak", 0) > 0:
			current_streaks += 1

	# Display summary
	var summary = Label.new()
	var hours = total_focus_minutes / 60
	var mins = total_focus_minutes % 60
	var time_str = str(hours) + "h " + str(mins) + "m" if hours > 0 else str(mins) + " min"
	summary.text = str(focus_count) + " sessions • " + time_str + " focused • " + str(reflection_count) + " reflections"
	summary.add_theme_font_size_override("font_size", 14)
	summary.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	zone_body.add_child(summary)

	if current_streaks > 0:
		var streaks_label = Label.new()
		streaks_label.text = "🔥 " + str(current_streaks) + " active habit streak(s)"
		streaks_label.add_theme_font_size_override("font_size", 14)
		streaks_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
		zone_body.add_child(streaks_label)


# =============================================================================
# ZONE PANEL GRAPHICS
# =============================================================================

func _create_observatory_graphic() -> void:
	# Clear existing graphics
	for child in zone_graphic_container.get_children():
		child.queue_free()

	var graphic = Control.new()
	graphic.set_anchors_preset(Control.PRESET_FULL_RECT)
	zone_graphic_container.add_child(graphic)

	var canvas = Node2D.new()
	graphic.add_child(canvas)
	graphic.resized.connect(func(): canvas.position = graphic.size / 2)
	canvas.position = Vector2(200, 300)

	# Night sky background
	var sky = Polygon2D.new()
	sky.polygon = PackedVector2Array([
		Vector2(-80, -150), Vector2(80, -150),
		Vector2(80, 80), Vector2(-80, 80)
	])
	sky.color = Color(0.02, 0.03, 0.08, 1.0)
	canvas.add_child(sky)

	# Stars in sky
	for i in range(15):
		var star = Polygon2D.new()
		var size = randf_range(2, 4)
		star.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(0, -size),
			Vector2(size, 0), Vector2(0, size)
		])
		star.position = Vector2(
			randf_range(-70, 70),
			randf_range(-140, -20)
		)
		star.color = Color(0.9, 0.92, 1.0, randf_range(0.5, 1.0))
		canvas.add_child(star)

	# Observatory dome
	var dome_base = Polygon2D.new()
	dome_base.polygon = PackedVector2Array([
		Vector2(-50, 0), Vector2(-45, -20), Vector2(45, -20), Vector2(50, 0),
		Vector2(50, 30), Vector2(-50, 30)
	])
	dome_base.position = Vector2(0, 50)
	dome_base.color = Color(0.12, 0.14, 0.22, 1.0)
	canvas.add_child(dome_base)

	# Dome
	var dome = Polygon2D.new()
	dome.polygon = PackedVector2Array([
		Vector2(-40, 0), Vector2(-35, -25), Vector2(-15, -40),
		Vector2(15, -40), Vector2(35, -25), Vector2(40, 0)
	])
	dome.position = Vector2(0, 30)
	dome.color = Color(0.18, 0.22, 0.35, 1.0)
	canvas.add_child(dome)

	# Dome slit
	var slit = Polygon2D.new()
	slit.polygon = PackedVector2Array([
		Vector2(-5, 0), Vector2(-5, -35), Vector2(5, -35), Vector2(5, 0)
	])
	slit.position = Vector2(0, 25)
	slit.color = Color(0.05, 0.08, 0.15, 1.0)
	canvas.add_child(slit)

	# Telescope
	var telescope = Polygon2D.new()
	telescope.polygon = PackedVector2Array([
		Vector2(-4, 0), Vector2(-6, -35), Vector2(-3, -50),
		Vector2(3, -50), Vector2(6, -35), Vector2(4, 0)
	])
	telescope.position = Vector2(0, 0)
	telescope.color = Color(0.3, 0.35, 0.5, 1.0)
	canvas.add_child(telescope)

	# Lens glow
	var lens = Polygon2D.new()
	lens.polygon = PackedVector2Array([
		Vector2(-6, 0), Vector2(0, -8), Vector2(6, 0), Vector2(0, 6)
	])
	lens.position = Vector2(0, -55)
	lens.color = Color(0.5, 0.6, 1.0, 0.8)
	canvas.add_child(lens)


func _create_reflection_pool_graphic() -> void:
	# Clear existing graphics
	for child in zone_graphic_container.get_children():
		child.queue_free()

	var graphic = Control.new()
	graphic.set_anchors_preset(Control.PRESET_FULL_RECT)
	zone_graphic_container.add_child(graphic)

	# Center the canvas in the graphic container
	var canvas = Node2D.new()
	graphic.add_child(canvas)

	# Use a deferred call to center after the container has its size
	canvas.set_meta("parent", graphic)
	graphic.resized.connect(func(): canvas.position = graphic.size / 2)
	# Initial centering (fallback position)
	canvas.position = Vector2(200, 300)

	# Pool border
	var border = Polygon2D.new()
	border.polygon = PackedVector2Array([
		Vector2(-75, 0), Vector2(0, -50), Vector2(75, 0), Vector2(0, 50)
	])
	border.color = Color(0.1, 0.12, 0.18, 1.0)
	canvas.add_child(border)

	# Pool water
	var water = Polygon2D.new()
	water.polygon = PackedVector2Array([
		Vector2(-60, 0), Vector2(0, -40), Vector2(60, 0), Vector2(0, 40)
	])
	water.color = Color(0.12, 0.2, 0.4, 0.95)
	canvas.add_child(water)

	# Reflected stars
	for i in range(8):
		var star = Polygon2D.new()
		var size = randf_range(2, 4)
		star.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(0, -size),
			Vector2(size, 0), Vector2(0, size)
		])
		star.position = Vector2(
			randf_range(-45, 45),
			randf_range(-25, 25)
		)
		star.color = Color(0.7, 0.75, 1.0, randf_range(0.3, 0.7))
		canvas.add_child(star)

	# Moon reflection
	var moon = Polygon2D.new()
	moon.polygon = _create_circle_polygon(15, 12)
	moon.position = Vector2(-15, -10)
	moon.color = Color(0.85, 0.88, 0.95, 0.6)
	canvas.add_child(moon)

	# Ripple rings
	for i in range(3):
		var ripple = Polygon2D.new()
		var radius = 25 + i * 15
		ripple.polygon = _create_ring_polygon(radius, radius + 2, 16)
		ripple.color = Color(0.5, 0.6, 0.9, 0.2 - i * 0.05)
		canvas.add_child(ripple)


func _create_circle_polygon(radius: float, segments: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(segments):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	return points


func _create_ring_polygon(inner_radius: float, outer_radius: float, segments: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	# Outer circle
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle) * outer_radius, sin(angle) * outer_radius))
	# Inner circle (reversed)
	for i in range(segments, -1, -1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle) * inner_radius, sin(angle) * inner_radius))
	return points


# =============================================================================
# ZONE ACTIONS
# =============================================================================

func _stargaze() -> void:
	_close_zone()
	_show_dialogue("Stargazing", "You gaze up at the infinite expanse of stars...\n\nThe cosmos stretches endlessly above, each star a distant sun with its own stories.\n\nYou feel a profound sense of peace and perspective.", Callable(), "res://audio/voice/mindscape/east/stargazing.ogg")


func _study_constellations() -> void:
	_close_zone()
	_show_dialogue("Constellations", "You trace the ancient patterns in the sky...\n\nOrion the Hunter watches over the eastern horizon, while the Great Bear circles the pole star.\n\nEach constellation holds millennia of human wisdom and wonder.", Callable(), "res://audio/voice/mindscape/east/constellations.ogg")


func _meditate() -> void:
	_close_zone()
	_show_dialogue("Cosmic Meditation", "You sit beside the pool and close your eyes...\n\nThe boundary between self and cosmos dissolves. You are stardust, briefly aware.\n\nTime flows differently here, measured in heartbeats and breaths.", Callable(), "res://audio/voice/mindscape/east/cosmic_meditation.ogg")


# =============================================================================
# JOURNAL SYSTEM
# =============================================================================

var current_journal_tab: String = "focus"  # "focus", "habits", "reflections", "all"
var journal_input: TextEdit = null
var journal_search_text: String = ""
var journal_filter_aspect: String = ""  # Filter by aspect


func _open_write_journal() -> void:
	zone_title.text = "Write Reflection"
	_clear_zone_body()
	_create_reflection_pool_graphic()

	var intro = Label.new()
	intro.text = "Take a moment to reflect on your thoughts, feelings, and insights."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	zone_body.add_child(intro)

	# Journal input
	journal_input = TextEdit.new()
	journal_input.custom_minimum_size = Vector2(0, 200)
	journal_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_input.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_input.placeholder_text = "What's on your mind? What insights have you gained? What are you grateful for?"
	journal_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	journal_input.add_theme_font_size_override("font_size", 16)
	zone_body.add_child(journal_input)

	# Button row
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	zone_body.add_child(btn_row)

	var save_btn = Button.new()
	save_btn.text = "Save Reflection"
	save_btn.pressed.connect(_save_reflection)
	btn_row.add_child(save_btn)

	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(_open_reflection_pool)
	btn_row.add_child(back_btn)


func _save_reflection() -> void:
	if journal_input == null or journal_input.text.strip_edges() == "":
		return

	var entry = {
		"type": "reflection",
		"timestamp": Time.get_unix_time_from_system(),
		"date": Time.get_date_string_from_system(),
		"content": journal_input.text.strip_edges()
	}

	_save_journal_entry(entry)
	journal_input = null
	_open_reflection_pool()
	_show_dialogue("Reflection Saved", "Your thoughts have been captured in the pool's memory.\n\nReturn anytime to review your reflections.")


func _save_journal_entry(entry: Dictionary) -> void:
	var journal = _load_focus_journal()
	journal.append(entry)

	var json_string = JSON.stringify(journal, "\t")
	var journal_path = SaveManager.get_journal_path()
	var file = FileAccess.open(journal_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()


func _open_journal_viewer() -> void:
	zone_title.text = "Journal"
	_clear_zone_body()
	_create_reflection_pool_graphic()

	# Search bar
	var search_row = HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 8)
	zone_body.add_child(search_row)

	var search_input = LineEdit.new()
	search_input.name = "JournalSearch"
	search_input.placeholder_text = "Search entries..."
	search_input.text = journal_search_text
	search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_input.custom_minimum_size = Vector2(0, 35)
	search_input.text_changed.connect(_on_journal_search_changed)
	search_row.add_child(search_input)

	var clear_btn = Button.new()
	clear_btn.text = "Clear"
	clear_btn.custom_minimum_size = Vector2(60, 35)
	clear_btn.pressed.connect(_clear_journal_search)
	search_row.add_child(clear_btn)

	_add_pool_spacer(8)

	# Tab buttons
	var tab_row = HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 8)
	zone_body.add_child(tab_row)

	var focus_tab = Button.new()
	focus_tab.text = "Focus Sessions"
	focus_tab.toggle_mode = true
	focus_tab.button_pressed = (current_journal_tab == "focus")
	focus_tab.add_theme_font_size_override("font_size", 14)
	focus_tab.pressed.connect(_show_journal_tab.bind("focus"))
	tab_row.add_child(focus_tab)

	var habits_tab = Button.new()
	habits_tab.text = "Habit Log"
	habits_tab.toggle_mode = true
	habits_tab.button_pressed = (current_journal_tab == "habits")
	habits_tab.add_theme_font_size_override("font_size", 14)
	habits_tab.pressed.connect(_show_journal_tab.bind("habits"))
	tab_row.add_child(habits_tab)

	var all_tab = Button.new()
	all_tab.text = "All Entries"
	all_tab.toggle_mode = true
	all_tab.button_pressed = (current_journal_tab == "all")
	all_tab.add_theme_font_size_override("font_size", 14)
	all_tab.pressed.connect(_show_journal_tab.bind("all"))
	tab_row.add_child(all_tab)

	# Separator
	var sep = HSeparator.new()
	zone_body.add_child(sep)

	# Content based on tab
	match current_journal_tab:
		"focus":
			_build_focus_tab()
		"habits":
			_build_habits_tab()
		"reflections":
			_build_reflections_tab()
		"all":
			_build_all_entries_tab()

	# Back button at bottom
	var back_btn = Button.new()
	back_btn.text = "Back to Reflection Pool"
	back_btn.custom_minimum_size = Vector2(0, 40)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_open_reflection_pool)
	zone_body.add_child(back_btn)


func _on_journal_search_changed(new_text: String) -> void:
	journal_search_text = new_text
	# Refresh the current tab with new search
	_open_journal_viewer()


func _clear_journal_search() -> void:
	journal_search_text = ""
	_open_journal_viewer()


func _build_all_entries_tab() -> void:
	var all_entries = []

	# Get all entries from journal (includes focus, habit, and reflection entries)
	var journal = _load_focus_journal()
	for entry in journal:
		all_entries.append(entry)

	# Apply search filter
	if journal_search_text != "":
		var filtered = []
		var search_lower = journal_search_text.to_lower()
		for entry in all_entries:
			var searchable = ""
			if entry.has("topic"):
				searchable += entry.topic.to_lower()
			if entry.has("content"):
				searchable += entry.content.to_lower()
			if entry.has("learned"):
				searchable += entry.learned.to_lower()
			if entry.has("accomplished"):
				searchable += entry.accomplished.to_lower()
			if entry.has("habit_name"):
				searchable += entry.habit_name.to_lower()
			if entry.has("note"):
				searchable += entry.note.to_lower()
			if entry.has("text"):
				searchable += entry.text.to_lower()
			if entry.has("journal_entry"):
				searchable += entry.journal_entry.to_lower()
			if entry.has("date"):
				searchable += entry.date

			if searchable.contains(search_lower):
				filtered.append(entry)
		all_entries = filtered

	# Sort by timestamp (newest first)
	all_entries.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	if all_entries.is_empty():
		var empty = Label.new()
		if journal_search_text != "":
			empty.text = "No entries match '" + journal_search_text + "'"
		else:
			empty.text = "No entries yet.\n\nComplete focus sessions, habits, or write reflections to see them here."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		zone_body.add_child(empty)
		return

	var count_label = Label.new()
	count_label.text = str(all_entries.size()) + " total entries"
	if journal_search_text != "":
		count_label.text += " matching '" + journal_search_text + "'"
	count_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	zone_body.add_child(count_label)

	# Build scrollable list
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	zone_body.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	var display_count = mini(all_entries.size(), 30)
	for i in range(display_count):
		var entry = all_entries[i]
		var entry_type = entry.get("type", "")
		var panel: PanelContainer
		match entry_type:
			"focus":
				panel = _create_session_entry_panel(entry)
			"habit":
				panel = _create_habit_entry_panel(entry)
			"reflection":
				panel = _create_reflection_entry_panel(entry)
			_:
				continue
		vbox.add_child(panel)


func _show_journal_tab(tab: String) -> void:
	current_journal_tab = tab
	_open_journal_viewer()


func _build_focus_tab() -> void:
	var sessions = _load_focus_journal()
	var focus_sessions = []
	for entry in sessions:
		if entry.get("type", "") == "focus":
			focus_sessions.append(entry)

	focus_sessions.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	if focus_sessions.is_empty():
		var empty = Label.new()
		empty.text = "No focus sessions recorded yet.\n\nComplete a focus session to see entries here."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		zone_body.add_child(empty)
		return

	var count_label = Label.new()
	count_label.text = "%d focus sessions" % focus_sessions.size()
	count_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	zone_body.add_child(count_label)

	_build_entries_scroll(focus_sessions, "focus")


func _build_habits_tab() -> void:
	# Get habit entries from the journal file (contains actual text)
	var journal = _load_focus_journal()
	var habit_entries = []

	for entry in journal:
		if entry.get("type", "") == "habit":
			habit_entries.append(entry)

	habit_entries.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	if habit_entries.is_empty():
		var empty = Label.new()
		empty.text = "No habits completed yet.\n\nComplete your daily habits to build your log."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		zone_body.add_child(empty)
		return

	var count_label = Label.new()
	count_label.text = "%d habit completions" % habit_entries.size()
	count_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	zone_body.add_child(count_label)

	_build_entries_scroll(habit_entries, "habit")


func _build_reflections_tab() -> void:
	var sessions = _load_focus_journal()
	var reflections = []
	for entry in sessions:
		if entry.get("type", "") == "reflection":
			reflections.append(entry)

	reflections.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	if reflections.is_empty():
		var empty = Label.new()
		empty.text = "No reflections written yet.\n\nUse 'Write Reflection' to capture your thoughts."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		zone_body.add_child(empty)
		return

	var count_label = Label.new()
	count_label.text = "%d reflections" % reflections.size()
	count_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	zone_body.add_child(count_label)

	_build_entries_scroll(reflections, "reflection")


func _build_entries_scroll(entries: Array, entry_type: String) -> void:
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 350)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	zone_body.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	var display_count = mini(entries.size(), 30)
	for i in range(display_count):
		var entry = entries[i]
		var panel: PanelContainer
		match entry_type:
			"focus":
				panel = _create_session_entry_panel(entry)
			"habit":
				panel = _create_habit_entry_panel(entry)
			"reflection":
				panel = _create_reflection_entry_panel(entry)
		vbox.add_child(panel)


func _create_habit_entry_panel(entry: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.12, 0.8)
	style.border_color = Color(0.3, 0.5, 0.35, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Header row with icon and habit name
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var icon = Label.new()
	icon.text = "✓"
	icon.add_theme_font_size_override("font_size", 20)
	icon.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
	header.add_child(icon)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(10, 0)
	header.add_child(spacer1)

	var name_label = Label.new()
	name_label.text = entry.get("habit_name", "Habit")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.85))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var date_label = Label.new()
	date_label.text = entry.get("date", "")
	date_label.add_theme_font_size_override("font_size", 12)
	date_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.6))
	header.add_child(date_label)

	# Show journal entry text if present (check multiple field names for compatibility)
	var journal_text = entry.get("note", "")
	if journal_text == "":
		journal_text = entry.get("text", "")
	if journal_text == "":
		journal_text = entry.get("journal_entry", "")
	if journal_text != "":
		var text_label = Label.new()
		text_label.text = journal_text
		text_label.add_theme_font_size_override("font_size", 14)
		text_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.7))
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(text_label)

	return panel


func _create_reflection_entry_panel(entry: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.18, 0.8)
	style.border_color = Color(0.4, 0.35, 0.6, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var date_label = Label.new()
	date_label.text = entry.get("date", "Unknown date")
	date_label.add_theme_font_size_override("font_size", 12)
	date_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.7))
	vbox.add_child(date_label)

	var content_label = Label.new()
	content_label.text = entry.get("content", "")
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	content_label.add_theme_font_size_override("font_size", 14)
	content_label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.9))
	vbox.add_child(content_label)

	return panel


func _date_to_timestamp(date_str: String) -> int:
	# Convert YYYY-MM-DD to approximate timestamp
	var parts = date_str.split("-")
	if parts.size() >= 3:
		var year = int(parts[0])
		var month = int(parts[1])
		var day = int(parts[2])
		# Approximate calculation
		return (year - 1970) * 31536000 + month * 2592000 + day * 86400
	return 0


func _create_session_entry_panel(entry: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.8)
	style.border_color = Color(0.3, 0.35, 0.5, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	# Store hover style
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.15, 0.18, 0.25, 0.9)
	hover_style.border_color = Color(0.5, 0.6, 0.8, 0.7)
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(4)
	hover_style.set_content_margin_all(10)

	# Make clickable - use a Button overlay for better interaction
	var click_button = Button.new()
	click_button.flat = true
	click_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	click_button.pressed.connect(_open_session_detail_view.bind(entry))
	click_button.mouse_entered.connect(func(): panel.add_theme_stylebox_override("panel", hover_style))
	click_button.mouse_exited.connect(func(): panel.add_theme_stylebox_override("panel", style))

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)

	# Add button after content so it's on top
	panel.add_child(click_button)

	# Header: Date and Topic with click hint
	var header = HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header)

	var topic_icon = Label.new()
	topic_icon.text = "🎯"
	topic_icon.add_theme_font_size_override("font_size", 16)
	topic_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(topic_icon)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(8, 0)
	spacer1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(spacer1)

	# Topic
	var topic = entry.get("topic", "Focus Session")
	var topic_label = Label.new()
	topic_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topic_label.text = topic if topic != "" else "Focus Session"
	topic_label.add_theme_font_size_override("font_size", 16)
	topic_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.6))
	topic_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(topic_label)

	var date_label = Label.new()
	date_label.text = entry.get("date", "").right(5)  # Show MM-DD
	date_label.add_theme_font_size_override("font_size", 14)
	date_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	date_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(date_label)

	# Subtext row
	var subtext = HBoxContainer.new()
	subtext.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(subtext)

	var duration_label = Label.new()
	duration_label.text = "⏱ " + str(entry.get("duration_minutes", 0)) + " min"
	duration_label.add_theme_font_size_override("font_size", 13)
	duration_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.55))
	duration_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtext.add_child(duration_label)

	# Show preview of learned/accomplished
	var learned = entry.get("learned", "").strip_edges()
	var accomplished = entry.get("accomplished", "").strip_edges()
	if learned != "" or accomplished != "":
		var spacer2 = Control.new()
		spacer2.custom_minimum_size = Vector2(15, 0)
		spacer2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		subtext.add_child(spacer2)

		var preview = Label.new()
		var preview_text = learned if learned != "" else accomplished
		if preview_text.length() > 50:
			preview_text = preview_text.substr(0, 47) + "..."
		preview.text = "✓ " + preview_text
		preview.add_theme_font_size_override("font_size", 13)
		preview.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		subtext.add_child(preview)

	# Click hint with arrow
	var hint = Label.new()
	hint.text = "→"
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hint)

	return panel


func _open_session_detail_view(entry: Dictionary) -> void:
	zone_title.text = "Focus Session Details"
	_clear_zone_body()

	# Create animated session visualization
	_create_session_detail_graphic(entry)

	# Session header
	var header_container = VBoxContainer.new()
	header_container.add_theme_constant_override("separation", 8)
	zone_body.add_child(header_container)

	# Topic
	var topic = entry.get("topic", "Focus Session")
	var topic_label = Label.new()
	topic_label.text = "🎯 " + topic
	topic_label.add_theme_font_size_override("font_size", 22)
	topic_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	header_container.add_child(topic_label)

	# Date and duration
	var meta_row = HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 20)
	header_container.add_child(meta_row)

	var date_label = Label.new()
	date_label.text = "📅 " + entry.get("date", "Unknown")
	date_label.add_theme_font_size_override("font_size", 16)
	date_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	meta_row.add_child(date_label)

	var duration_label = Label.new()
	duration_label.text = "⏱ " + str(entry.get("duration_minutes", 0)) + " minutes"
	duration_label.add_theme_font_size_override("font_size", 16)
	duration_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.6))
	meta_row.add_child(duration_label)

	# Aspect if available
	var aspect = entry.get("aspect", "")
	if aspect != "":
		var aspect_label = Label.new()
		aspect_label.text = "✧ " + aspect.capitalize()
		aspect_label.add_theme_font_size_override("font_size", 16)
		aspect_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.8))
		meta_row.add_child(aspect_label)

	_add_pool_spacer(15)

	# Scrollable content
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 280)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	zone_body.add_child(scroll)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 15)
	scroll.add_child(content)

	# What I learned
	var learned = entry.get("learned", "").strip_edges()
	if learned != "":
		var learned_section = _create_detail_section("💡 What I Learned", learned, Color(0.9, 0.85, 0.5))
		content.add_child(learned_section)

	# What I accomplished
	var accomplished = entry.get("accomplished", "").strip_edges()
	if accomplished != "":
		var acc_section = _create_detail_section("✓ What I Accomplished", accomplished, Color(0.5, 0.85, 0.6))
		content.add_child(acc_section)

	# Session notes
	var notes = entry.get("session_notes", "").strip_edges()
	if notes != "" and notes != accomplished and notes != learned:
		var notes_section = _create_detail_section("📝 Session Notes", notes, Color(0.6, 0.7, 0.85))
		content.add_child(notes_section)

	# Next goals
	var next_goals = entry.get("next_goals", "").strip_edges()
	if next_goals != "":
		var goals_section = _create_detail_section("🎯 Goals for Next Time", next_goals, Color(0.85, 0.6, 0.7))
		content.add_child(goals_section)

	# If no content sections, show placeholder
	if learned == "" and accomplished == "" and notes == "" and next_goals == "":
		var empty = Label.new()
		empty.text = "No reflection notes were recorded for this session."
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		content.add_child(empty)

	_add_pool_spacer(15)

	# Back button
	var back_btn = Button.new()
	back_btn.text = "← Back to Journal"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_open_journal_viewer)
	zone_body.add_child(back_btn)


func _create_detail_section(title: String, content_text: String, title_color: Color) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 6)

	# Section panel
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.15, 0.9)
	style.border_color = title_color * 0.5
	style.border_color.a = 0.4
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	section.add_child(panel)

	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)

	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", title_color)
	inner.add_child(title_label)

	var content_label = Label.new()
	content_label.text = content_text
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	content_label.add_theme_font_size_override("font_size", 15)
	content_label.add_theme_color_override("font_color", Color(0.85, 0.87, 0.9))
	inner.add_child(content_label)

	return section


func _create_session_detail_graphic(entry: Dictionary) -> void:
	# Clear existing graphics
	for child in zone_graphic_container.get_children():
		child.queue_free()

	var graphic = Control.new()
	graphic.set_anchors_preset(Control.PRESET_FULL_RECT)
	zone_graphic_container.add_child(graphic)

	var canvas = Node2D.new()
	graphic.add_child(canvas)
	graphic.resized.connect(func(): canvas.position = graphic.size / 2)
	canvas.position = Vector2(200, 300)

	# Session completion visualization
	var duration = entry.get("duration_minutes", 25)

	# Central focus orb
	var orb_glow = Polygon2D.new()
	var glow_points = PackedVector2Array()
	for i in range(16):
		var angle = (float(i) / 16) * TAU
		glow_points.append(Vector2(cos(angle) * 80, sin(angle) * 80))
	orb_glow.polygon = glow_points
	orb_glow.color = Color(0.3, 0.5, 0.8, 0.2)
	canvas.add_child(orb_glow)

	var orb = Polygon2D.new()
	var orb_points = PackedVector2Array()
	for i in range(12):
		var angle = (float(i) / 12) * TAU
		orb_points.append(Vector2(cos(angle) * 50, sin(angle) * 50))
	orb.polygon = orb_points
	orb.color = Color(0.4, 0.6, 0.9, 0.8)
	canvas.add_child(orb)

	# Duration ring segments
	var segments = mini(duration / 5, 12)  # One segment per 5 minutes
	for i in range(segments):
		var segment = Polygon2D.new()
		var start_angle = (float(i) / segments) * TAU - PI/2
		var end_angle = (float(i + 1) / segments) * TAU - PI/2
		var inner_r = 60
		var outer_r = 70

		var seg_points = PackedVector2Array()
		for j in range(5):
			var angle = start_angle + (end_angle - start_angle) * (float(j) / 4)
			seg_points.append(Vector2(cos(angle) * inner_r, sin(angle) * inner_r))
		for j in range(4, -1, -1):
			var angle = start_angle + (end_angle - start_angle) * (float(j) / 4)
			seg_points.append(Vector2(cos(angle) * outer_r, sin(angle) * outer_r))

		segment.polygon = seg_points
		segment.color = Color(0.5, 0.7, 0.9, 0.6)
		canvas.add_child(segment)

	# Duration text
	var duration_text = Label.new()
	duration_text.text = str(duration) + " min"
	duration_text.add_theme_font_size_override("font_size", 18)
	duration_text.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	duration_text.position = Vector2(-25, -12)
	canvas.add_child(duration_text)

	# Topic label below
	var topic = entry.get("topic", "Focus Session")
	var topic_text = Label.new()
	topic_text.text = topic
	topic_text.add_theme_font_size_override("font_size", 14)
	topic_text.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	topic_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topic_text.position = Vector2(-80, 90)
	topic_text.custom_minimum_size = Vector2(160, 0)
	canvas.add_child(topic_text)


func _create_entry_section(title: String, content: String) -> VBoxContainer:
	var section = VBoxContainer.new()

	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	section.add_child(title_label)

	var content_label = Label.new()
	content_label.text = content
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	content_label.add_theme_font_size_override("font_size", 14)
	content_label.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88))
	section.add_child(content_label)

	return section


func _load_focus_journal() -> Array:
	var journal_path = SaveManager.get_journal_path()
	if not FileAccess.file_exists(journal_path):
		return []

	var file = FileAccess.open(journal_path, FileAccess.READ)
	if not file:
		return []

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return []

	var data = json.get_data()
	if data is Array:
		return data
	return []


# =============================================================================
# INSIGHTS PANEL
# =============================================================================

func _open_insights_panel() -> void:
	zone_title.text = "Growth Insights"
	_clear_zone_body()
	_create_reflection_pool_graphic()

	var intro = Label.new()
	intro.text = "Patterns and statistics from your growth journey."
	intro.add_theme_font_size_override("font_size", 16)
	intro.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	zone_body.add_child(intro)

	_add_pool_spacer(15)

	# Calculate all stats
	var journal = _load_focus_journal()
	var stats = _calculate_insights(journal)

	# Focus Session Stats
	var focus_header = Label.new()
	focus_header.text = "Focus Sessions"
	focus_header.add_theme_font_size_override("font_size", 18)
	focus_header.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	zone_body.add_child(focus_header)

	_add_pool_spacer(6)

	var focus_stats = GridContainer.new()
	focus_stats.columns = 2
	focus_stats.add_theme_constant_override("h_separation", 20)
	focus_stats.add_theme_constant_override("v_separation", 6)
	zone_body.add_child(focus_stats)

	_add_stat_row(focus_stats, "Total Sessions:", str(stats.focus_count))
	_add_stat_row(focus_stats, "Total Focus Time:", _format_duration(stats.total_focus_minutes))
	_add_stat_row(focus_stats, "Average Session:", _format_duration(stats.avg_session_minutes) if stats.focus_count > 0 else "N/A")
	_add_stat_row(focus_stats, "Most Productive Day:", stats.best_day if stats.best_day != "" else "N/A")
	_add_stat_row(focus_stats, "Current Week:", str(stats.sessions_this_week) + " sessions")

	_add_pool_spacer(15)

	# Habit Stats
	var habit_header = Label.new()
	habit_header.text = "Habits"
	habit_header.add_theme_font_size_override("font_size", 18)
	habit_header.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	zone_body.add_child(habit_header)

	_add_pool_spacer(6)

	var habit_stats = GridContainer.new()
	habit_stats.columns = 2
	habit_stats.add_theme_constant_override("h_separation", 20)
	habit_stats.add_theme_constant_override("v_separation", 6)
	zone_body.add_child(habit_stats)

	_add_stat_row(habit_stats, "Total Completions:", str(stats.habit_completions))
	_add_stat_row(habit_stats, "Active Streaks:", str(stats.active_streaks))
	_add_stat_row(habit_stats, "Longest Streak:", str(stats.longest_streak) + " days" if stats.longest_streak > 0 else "N/A")
	_add_stat_row(habit_stats, "Best Habit:", stats.best_habit if stats.best_habit != "" else "N/A")

	_add_pool_spacer(15)

	# Reflection Stats
	var ref_header = Label.new()
	ref_header.text = "Reflections"
	ref_header.add_theme_font_size_override("font_size", 18)
	ref_header.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
	zone_body.add_child(ref_header)

	_add_pool_spacer(6)

	var ref_stats = GridContainer.new()
	ref_stats.columns = 2
	ref_stats.add_theme_constant_override("h_separation", 20)
	ref_stats.add_theme_constant_override("v_separation", 6)
	zone_body.add_child(ref_stats)

	_add_stat_row(ref_stats, "Total Reflections:", str(stats.reflection_count))
	_add_stat_row(ref_stats, "This Week:", str(stats.reflections_this_week))
	_add_stat_row(ref_stats, "Avg. Length:", str(stats.avg_reflection_words) + " words" if stats.reflection_count > 0 else "N/A")

	_add_pool_spacer(15)

	# Growth Timeline
	if stats.focus_count > 0 or stats.habit_completions > 0:
		var timeline_header = Label.new()
		timeline_header.text = "Last 7 Days Activity"
		timeline_header.add_theme_font_size_override("font_size", 18)
		timeline_header.add_theme_color_override("font_color", Color(0.7, 0.55, 0.35))
		zone_body.add_child(timeline_header)

		_add_pool_spacer(6)

		_build_activity_bars(stats.daily_activity)

	_add_pool_spacer(15)

	# Back button
	var back_btn = Button.new()
	back_btn.text = "Back to Reflection Pool"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_open_reflection_pool)
	zone_body.add_child(back_btn)


func _add_stat_row(container: GridContainer, label_text: String, value_text: String) -> void:
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	container.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 14)
	value.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	container.add_child(value)


func _format_duration(minutes: int) -> String:
	if minutes >= 60:
		var hours = minutes / 60
		var mins = minutes % 60
		return str(hours) + "h " + str(mins) + "m"
	return str(minutes) + " min"


func _calculate_insights(journal: Array) -> Dictionary:
	var stats = {
		"focus_count": 0,
		"total_focus_minutes": 0,
		"avg_session_minutes": 0,
		"best_day": "",
		"sessions_this_week": 0,
		"habit_completions": 0,
		"active_streaks": 0,
		"longest_streak": 0,
		"best_habit": "",
		"reflection_count": 0,
		"reflections_this_week": 0,
		"avg_reflection_words": 0,
		"daily_activity": {}  # date -> {focus: int, habits: int}
	}

	var today = Time.get_date_string_from_system()
	var today_dict = Time.get_date_dict_from_system()

	# Calculate week start (last 7 days)
	var week_dates = []
	for i in range(7):
		var day_dict = today_dict.duplicate()
		day_dict.day -= i
		# Simple date normalization (won't handle month boundaries perfectly but good enough)
		while day_dict.day < 1:
			day_dict.month -= 1
			if day_dict.month < 1:
				day_dict.month = 12
				day_dict.year -= 1
			day_dict.day += 30
		var date_str = "%04d-%02d-%02d" % [day_dict.year, day_dict.month, day_dict.day]
		week_dates.append(date_str)
		stats.daily_activity[date_str] = {"focus": 0, "habits": 0, "reflections": 0}

	# Process journal entries
	var day_session_counts = {}
	var total_reflection_words = 0

	for entry in journal:
		var entry_type = entry.get("type", "")
		var entry_date = entry.get("date", "")

		if entry_type == "focus":
			stats.focus_count += 1
			stats.total_focus_minutes += entry.get("duration_minutes", 0)

			# Count by day of week
			if not day_session_counts.has(entry_date):
				day_session_counts[entry_date] = 0
			day_session_counts[entry_date] += 1

			# This week
			if entry_date in week_dates:
				stats.sessions_this_week += 1
				stats.daily_activity[entry_date]["focus"] += entry.get("duration_minutes", 25)

		elif entry_type == "reflection":
			stats.reflection_count += 1
			var content = entry.get("content", "")
			total_reflection_words += content.split(" ").size()

			if entry_date in week_dates:
				stats.reflections_this_week += 1
				stats.daily_activity[entry_date]["reflections"] += 1

	# Calculate averages
	if stats.focus_count > 0:
		stats.avg_session_minutes = stats.total_focus_minutes / stats.focus_count

	if stats.reflection_count > 0:
		stats.avg_reflection_words = total_reflection_words / stats.reflection_count

	# Find best day (most sessions)
	var best_day_count = 0
	for date_str in day_session_counts:
		if day_session_counts[date_str] > best_day_count:
			best_day_count = day_session_counts[date_str]
			stats.best_day = date_str

	# Habit stats
	var habit_completion_counts = {}
	for habit_id in HabitManager.habits:
		var habit = HabitManager.habits[habit_id]
		var history = habit.get("completion_history", [])
		stats.habit_completions += history.size()
		habit_completion_counts[habit.name] = history.size()

		var streak = habit.get("streak", 0)
		if streak > 0:
			stats.active_streaks += 1
		if streak > stats.longest_streak:
			stats.longest_streak = streak

		# Count in daily activity
		for date in history:
			if date in week_dates:
				stats.daily_activity[date]["habits"] += 1

	# Find best habit
	var best_count = 0
	for habit_name in habit_completion_counts:
		if habit_completion_counts[habit_name] > best_count:
			best_count = habit_completion_counts[habit_name]
			stats.best_habit = habit_name

	return stats


func _build_activity_bars(daily_activity: Dictionary) -> void:
	var bar_container = HBoxContainer.new()
	bar_container.add_theme_constant_override("separation", 8)
	bar_container.alignment = BoxContainer.ALIGNMENT_CENTER
	zone_body.add_child(bar_container)

	# Get sorted dates (oldest to newest for display)
	var dates = daily_activity.keys()
	dates.sort()

	# Find max for scaling
	var max_val = 1
	for date in dates:
		var total = daily_activity[date].focus + daily_activity[date].habits * 5
		if total > max_val:
			max_val = total

	for date in dates:
		var day_col = VBoxContainer.new()
		day_col.add_theme_constant_override("separation", 2)
		bar_container.add_child(day_col)

		var data = daily_activity[date]
		var total = data.focus + data.habits * 5

		# Bar
		var bar = ColorRect.new()
		var bar_height = max(5, int((float(total) / max_val) * 60))
		bar.custom_minimum_size = Vector2(30, bar_height)
		if total > 30:
			bar.color = Color(0.4, 0.8, 0.4, 0.8)  # Green for active days
		elif total > 0:
			bar.color = Color(0.6, 0.7, 0.3, 0.6)  # Yellow-green for some activity
		else:
			bar.color = Color(0.3, 0.3, 0.35, 0.4)  # Gray for no activity
		day_col.add_child(bar)

		# Day label
		var day_label = Label.new()
		var parts = date.split("-")
		day_label.text = parts[2] if parts.size() >= 3 else date.right(2)
		day_label.add_theme_font_size_override("font_size", 11)
		day_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_col.add_child(day_label)
