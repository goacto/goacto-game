extends MindscapeRegionBase
## Northern Gardens - Dream Garden and Memory Archive
## A lush, magical area focused on dreams, memories, and personal history
## EXPANDED VERSION with enchanted garden landscape

# Enhanced visual elements
var environment_container: Node2D = null
var atmosphere_container: Node2D = null
var particles_container: Node2D = null
var detail_container: Node2D = null

# Animation state
var env_time: float = 0.0
var petal_data: Array = []
var firefly_data: Array = []
var butterfly_data: Array = []
var flower_data: Array = []
var pond_ripple_time: float = 0.0

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
		"region_id": "north",
		"region_name": "Northern Gardens",
		"theme_color": Color(0.4, 0.7, 0.5),
		"zone_names": {
			"DreamGarden": "Dream Garden",
			"MemoryArchive": "Memory Archive"
		},
		"player_bounds": Rect2(-900, -700, 1800, 1400)  # Expanded bounds
	})

	# Create enhanced environment BEFORE initialize_region
	_create_enhanced_environment()

	initialize_region()


func _process(delta: float) -> void:
	env_time += delta
	pond_ripple_time += delta
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

	# Build the enchanted garden environment
	_create_sky_gradient()
	_create_rolling_hills()
	_create_garden_paths()
	_create_main_terrain()
	_create_pond()
	_create_flower_beds()
	_create_trees()
	_create_gazebo()
	_create_floating_petals()
	_create_fireflies()
	_create_butterflies()
	_create_ambient_glow()
	_enhance_zones()


func _create_sky_gradient() -> void:
	# Soft gradient suggesting dawn/dusk garden atmosphere
	var sky_colors = [
		{"y": -600, "color": Color(0.15, 0.2, 0.25, 0.4)},
		{"y": -450, "color": Color(0.2, 0.3, 0.25, 0.3)},
		{"y": -300, "color": Color(0.15, 0.25, 0.2, 0.2)},
	]

	for sky in sky_colors:
		var band = Polygon2D.new()
		band.polygon = PackedVector2Array([
			Vector2(-1100, sky["y"]), Vector2(1100, sky["y"]),
			Vector2(1100, sky["y"] + 150), Vector2(-1100, sky["y"] + 150)
		])
		band.color = sky["color"]
		environment_container.add_child(band)


func _create_rolling_hills() -> void:
	# Background hills with soft green tones
	var hills = [
		{"pos": Vector2(-600, -400), "scale": 1.4, "color": Color(0.15, 0.28, 0.18, 0.7)},
		{"pos": Vector2(0, -450), "scale": 1.6, "color": Color(0.12, 0.25, 0.15, 0.6)},
		{"pos": Vector2(500, -380), "scale": 1.3, "color": Color(0.18, 0.3, 0.2, 0.7)},
		{"pos": Vector2(-400, -320), "scale": 1.2, "color": Color(0.2, 0.32, 0.22, 0.8)},
		{"pos": Vector2(300, -300), "scale": 1.1, "color": Color(0.22, 0.35, 0.24, 0.8)},
	]

	for hill in hills:
		var h = Polygon2D.new()
		h.position = hill["pos"]
		var s = hill["scale"]
		h.polygon = PackedVector2Array([
			Vector2(-200 * s, 80), Vector2(-180 * s, 20), Vector2(-120 * s, -40),
			Vector2(-40 * s, -70), Vector2(40 * s, -60), Vector2(120 * s, -30),
			Vector2(180 * s, 30), Vector2(200 * s, 80)
		])
		h.color = hill["color"]
		environment_container.add_child(h)


func _create_garden_paths() -> void:
	# Winding stone paths through the garden
	var path_color = Color(0.35, 0.3, 0.25, 0.8)
	var path_border = Color(0.25, 0.22, 0.18, 0.9)

	# Main path from portal to zones
	var main_path = Polygon2D.new()
	main_path.polygon = PackedVector2Array([
		Vector2(-30, 350), Vector2(30, 350),
		Vector2(40, 200), Vector2(50, 100),
		Vector2(40, 0), Vector2(30, -80),
		Vector2(-30, -80), Vector2(-40, 0),
		Vector2(-50, 100), Vector2(-40, 200)
	])
	main_path.color = path_color
	detail_container.add_child(main_path)

	# Branch to Dream Garden
	var left_path = Polygon2D.new()
	left_path.polygon = PackedVector2Array([
		Vector2(-30, -80), Vector2(-50, -100),
		Vector2(-150, -150), Vector2(-280, -180),
		Vector2(-320, -200), Vector2(-300, -220),
		Vector2(-280, -200), Vector2(-150, -170),
		Vector2(-50, -120), Vector2(-20, -100)
	])
	left_path.color = path_color
	detail_container.add_child(left_path)

	# Branch to Memory Archive
	var right_path = Polygon2D.new()
	right_path.polygon = PackedVector2Array([
		Vector2(30, -80), Vector2(50, -100),
		Vector2(150, -130), Vector2(250, -160),
		Vector2(300, -180), Vector2(320, -160),
		Vector2(300, -160), Vector2(250, -140),
		Vector2(150, -110), Vector2(50, -80)
	])
	right_path.color = path_color
	detail_container.add_child(right_path)

	# Stepping stones along paths
	var stone_positions = [
		Vector2(0, 250), Vector2(10, 150), Vector2(-5, 50),
		Vector2(-80, -100), Vector2(-180, -160),
		Vector2(80, -90), Vector2(180, -140)
	]
	for pos in stone_positions:
		var stone = Polygon2D.new()
		stone.position = pos
		stone.polygon = PackedVector2Array([
			Vector2(-12, 0), Vector2(0, -8), Vector2(12, 0), Vector2(0, 8)
		])
		stone.color = Color(0.4, 0.38, 0.35, 0.9)
		detail_container.add_child(stone)


func _create_main_terrain() -> void:
	# Three-level terrain for depth
	var terrain_back = Polygon2D.new()
	terrain_back.polygon = PackedVector2Array([
		Vector2(-950, 0), Vector2(0, -480), Vector2(950, 0), Vector2(0, 480)
	])
	terrain_back.color = Color(0.12, 0.22, 0.14, 1.0)
	environment_container.add_child(terrain_back)

	var terrain_mid = Polygon2D.new()
	terrain_mid.polygon = PackedVector2Array([
		Vector2(-850, 0), Vector2(0, -430), Vector2(850, 0), Vector2(0, 430)
	])
	terrain_mid.color = Color(0.15, 0.28, 0.18, 1.0)
	environment_container.add_child(terrain_mid)

	var terrain_front = Polygon2D.new()
	terrain_front.polygon = PackedVector2Array([
		Vector2(-750, 0), Vector2(0, -380), Vector2(750, 0), Vector2(0, 380)
	])
	terrain_front.color = Color(0.18, 0.32, 0.2, 1.0)
	environment_container.add_child(terrain_front)


func _create_pond() -> void:
	# Serene pond with lily pads
	var pond_pos = Vector2(200, 150)

	# Pond base
	var pond = Polygon2D.new()
	pond.position = pond_pos
	pond.polygon = PackedVector2Array([
		Vector2(-100, 0), Vector2(-70, -50), Vector2(0, -70),
		Vector2(70, -50), Vector2(100, 0), Vector2(70, 50),
		Vector2(0, 70), Vector2(-70, 50)
	])
	pond.color = Color(0.2, 0.35, 0.45, 0.9)
	detail_container.add_child(pond)

	# Pond reflection/shimmer
	var shimmer = Polygon2D.new()
	shimmer.name = "PondShimmer"
	shimmer.position = pond_pos + Vector2(0, -10)
	shimmer.polygon = PackedVector2Array([
		Vector2(-60, 0), Vector2(-40, -30), Vector2(0, -45),
		Vector2(40, -30), Vector2(60, 0), Vector2(40, 30),
		Vector2(0, 45), Vector2(-40, 30)
	])
	shimmer.color = Color(0.4, 0.55, 0.65, 0.4)
	detail_container.add_child(shimmer)

	# Lily pads
	var lily_positions = [
		Vector2(-50, -20), Vector2(30, -35), Vector2(-20, 25),
		Vector2(50, 15), Vector2(-40, 40)
	]
	for i in range(lily_positions.size()):
		var lily = Polygon2D.new()
		lily.position = pond_pos + lily_positions[i]
		lily.polygon = PackedVector2Array([
			Vector2(-15, 0), Vector2(-10, -10), Vector2(0, -15),
			Vector2(10, -10), Vector2(15, 0), Vector2(10, 10),
			Vector2(0, 15), Vector2(-10, 10)
		])
		lily.color = Color(0.3, 0.55, 0.35, 0.9)
		detail_container.add_child(lily)

		# Lily flower on some
		if i < 2:
			var flower = Polygon2D.new()
			flower.position = pond_pos + lily_positions[i] + Vector2(0, -5)
			flower.polygon = PackedVector2Array([
				Vector2(-6, 0), Vector2(0, -8), Vector2(6, 0), Vector2(0, 6)
			])
			flower.color = Color(0.95, 0.85, 0.9, 1.0) if i == 0 else Color(0.9, 0.75, 0.85, 1.0)
			detail_container.add_child(flower)

	# Pond border
	var border = Polygon2D.new()
	border.position = pond_pos
	border.polygon = PackedVector2Array([
		Vector2(-110, 0), Vector2(-75, -55), Vector2(0, -78),
		Vector2(75, -55), Vector2(110, 0), Vector2(75, 55),
		Vector2(0, 78), Vector2(-75, 55)
	])
	border.color = Color(0.25, 0.22, 0.18, 0.6)
	# Draw behind pond
	detail_container.move_child(border, detail_container.get_child_count() - 6)


func _create_flower_beds() -> void:
	# Multiple flower beds with different colored flowers
	var bed_positions = [
		{"pos": Vector2(-450, 50), "colors": [Color(0.9, 0.4, 0.5), Color(0.95, 0.5, 0.55), Color(0.85, 0.35, 0.45)]},
		{"pos": Vector2(-350, -50), "colors": [Color(0.9, 0.75, 0.3), Color(0.95, 0.8, 0.4), Color(0.85, 0.7, 0.25)]},
		{"pos": Vector2(450, -50), "colors": [Color(0.6, 0.4, 0.8), Color(0.7, 0.5, 0.85), Color(0.55, 0.35, 0.75)]},
		{"pos": Vector2(350, 100), "colors": [Color(0.4, 0.7, 0.9), Color(0.5, 0.75, 0.95), Color(0.35, 0.65, 0.85)]},
		{"pos": Vector2(-200, 200), "colors": [Color(0.95, 0.6, 0.7), Color(0.9, 0.55, 0.65), Color(1.0, 0.65, 0.75)]},
	]

	for bed in bed_positions:
		# Soil bed
		var soil = Polygon2D.new()
		soil.position = bed["pos"]
		soil.polygon = PackedVector2Array([
			Vector2(-60, 0), Vector2(0, -30), Vector2(60, 0), Vector2(0, 30)
		])
		soil.color = Color(0.22, 0.18, 0.12, 0.9)
		detail_container.add_child(soil)

		# Flowers in bed
		var flower_offsets = [
			Vector2(-25, -8), Vector2(0, -15), Vector2(25, -8),
			Vector2(-15, 5), Vector2(15, 5), Vector2(0, 10)
		]
		for i in range(flower_offsets.size()):
			var flower = Polygon2D.new()
			flower.position = bed["pos"] + flower_offsets[i]
			var size = randf_range(5, 9)
			flower.polygon = PackedVector2Array([
				Vector2(-size, 0), Vector2(0, -size * 1.2),
				Vector2(size, 0), Vector2(0, size * 0.8)
			])
			flower.color = bed["colors"][i % bed["colors"].size()]
			detail_container.add_child(flower)

			# Store for animation
			flower_data.append({"node": flower, "base_pos": flower.position, "phase": randf() * TAU})


func _create_trees() -> void:
	# Various trees around the garden
	var tree_configs = [
		{"pos": Vector2(-550, -200), "trunk_h": 80, "foliage_r": 70, "color": Color(0.25, 0.5, 0.35)},
		{"pos": Vector2(550, -150), "trunk_h": 90, "foliage_r": 80, "color": Color(0.3, 0.55, 0.4)},
		{"pos": Vector2(-450, 180), "trunk_h": 70, "foliage_r": 60, "color": Color(0.22, 0.48, 0.32)},
		{"pos": Vector2(500, 200), "trunk_h": 75, "foliage_r": 65, "color": Color(0.28, 0.52, 0.38)},
		{"pos": Vector2(-650, 0), "trunk_h": 85, "foliage_r": 75, "color": Color(0.2, 0.45, 0.3)},
		{"pos": Vector2(650, 50), "trunk_h": 80, "foliage_r": 70, "color": Color(0.26, 0.5, 0.36)},
	]

	for tree in tree_configs:
		var tree_node = Node2D.new()
		tree_node.position = tree["pos"]
		detail_container.add_child(tree_node)

		# Trunk
		var trunk = Polygon2D.new()
		trunk.polygon = PackedVector2Array([
			Vector2(-12, 50), Vector2(-10, -tree["trunk_h"] + 30),
			Vector2(10, -tree["trunk_h"] + 30), Vector2(12, 50)
		])
		trunk.color = Color(0.35, 0.28, 0.18)
		tree_node.add_child(trunk)

		# Foliage layers
		var r = tree["foliage_r"]
		var base_color = tree["color"]

		for layer in range(3):
			var foliage = Polygon2D.new()
			var offset_y = -tree["trunk_h"] - (layer * 20)
			var layer_r = r - (layer * 10)
			foliage.position = Vector2(0, offset_y)
			foliage.polygon = PackedVector2Array([
				Vector2(-layer_r, 25), Vector2(-layer_r * 0.8, -10),
				Vector2(-layer_r * 0.4, -layer_r * 0.6), Vector2(0, -layer_r * 0.7),
				Vector2(layer_r * 0.4, -layer_r * 0.6), Vector2(layer_r * 0.8, -10),
				Vector2(layer_r, 25), Vector2(0, 35)
			])
			var layer_color = base_color
			layer_color = layer_color.lightened(layer * 0.08)
			foliage.color = layer_color
			tree_node.add_child(foliage)


func _create_gazebo() -> void:
	# Garden gazebo near the center
	var gazebo_pos = Vector2(-100, -250)
	var gazebo = Node2D.new()
	gazebo.position = gazebo_pos
	detail_container.add_child(gazebo)

	# Base platform
	var base = Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-70, 0), Vector2(0, -35), Vector2(70, 0), Vector2(0, 35)
	])
	base.color = Color(0.4, 0.35, 0.28)
	gazebo.add_child(base)

	# Pillars
	var pillar_positions = [Vector2(-50, -10), Vector2(50, -10), Vector2(-50, 20), Vector2(50, 20)]
	for pos in pillar_positions:
		var pillar = Polygon2D.new()
		pillar.position = pos
		pillar.polygon = PackedVector2Array([
			Vector2(-5, 25), Vector2(-5, -60), Vector2(5, -60), Vector2(5, 25)
		])
		pillar.color = Color(0.9, 0.88, 0.85)
		gazebo.add_child(pillar)

	# Roof
	var roof = Polygon2D.new()
	roof.position = Vector2(0, -70)
	roof.polygon = PackedVector2Array([
		Vector2(-80, 15), Vector2(0, -25), Vector2(80, 15),
		Vector2(60, 20), Vector2(0, -15), Vector2(-60, 20)
	])
	roof.color = Color(0.5, 0.35, 0.3)
	gazebo.add_child(roof)

	# Roof peak
	var peak = Polygon2D.new()
	peak.position = Vector2(0, -90)
	peak.polygon = PackedVector2Array([
		Vector2(-8, 10), Vector2(0, -10), Vector2(8, 10)
	])
	peak.color = Color(0.45, 0.3, 0.25)
	gazebo.add_child(peak)


func _create_floating_petals() -> void:
	# Cherry blossom-like petals floating in the air
	var petal_colors = [
		Color(0.95, 0.8, 0.85, 0.8),
		Color(0.9, 0.75, 0.8, 0.7),
		Color(1.0, 0.85, 0.9, 0.75),
		Color(0.85, 0.7, 0.75, 0.7)
	]

	for i in range(25):
		var petal = Polygon2D.new()
		petal.polygon = PackedVector2Array([
			Vector2(-4, 0), Vector2(0, -6), Vector2(4, 0), Vector2(0, 4)
		])
		petal.color = petal_colors[i % petal_colors.size()]
		particles_container.add_child(petal)

		petal_data.append({
			"node": petal,
			"x": randf_range(-800, 800),
			"y": randf_range(-500, 400),
			"speed_x": randf_range(-20, 20),
			"speed_y": randf_range(15, 40),
			"rotation_speed": randf_range(-2, 2),
			"sway_phase": randf() * TAU,
			"sway_amplitude": randf_range(30, 60)
		})


func _create_fireflies() -> void:
	# Magical fireflies with glowing effect
	for i in range(18):
		var firefly = Node2D.new()
		particles_container.add_child(firefly)

		# Glow
		var glow = Polygon2D.new()
		glow.polygon = PackedVector2Array([
			Vector2(-8, 0), Vector2(0, -8), Vector2(8, 0), Vector2(0, 8)
		])
		glow.color = Color(0.9, 0.95, 0.5, 0.3)
		firefly.add_child(glow)

		# Core
		var core = Polygon2D.new()
		core.polygon = PackedVector2Array([
			Vector2(-3, 0), Vector2(0, -3), Vector2(3, 0), Vector2(0, 3)
		])
		core.color = Color(1.0, 1.0, 0.7, 0.9)
		firefly.add_child(core)

		firefly_data.append({
			"node": firefly,
			"glow": glow,
			"x": randf_range(-700, 700),
			"y": randf_range(-400, 300),
			"base_x": randf_range(-700, 700),
			"base_y": randf_range(-400, 300),
			"phase": randf() * TAU,
			"speed": randf_range(0.3, 0.8),
			"radius": randf_range(50, 150),
			"glow_phase": randf() * TAU
		})


func _create_butterflies() -> void:
	# Colorful butterflies fluttering around
	var butterfly_colors = [
		Color(0.3, 0.6, 0.9, 0.9),
		Color(0.9, 0.6, 0.3, 0.9),
		Color(0.7, 0.4, 0.8, 0.9),
		Color(0.4, 0.8, 0.6, 0.9)
	]

	for i in range(8):
		var butterfly = Node2D.new()
		particles_container.add_child(butterfly)

		var color = butterfly_colors[i % butterfly_colors.size()]

		# Left wing
		var left_wing = Polygon2D.new()
		left_wing.name = "LeftWing"
		left_wing.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(-12, -8), Vector2(-15, 0), Vector2(-10, 8)
		])
		left_wing.color = color
		butterfly.add_child(left_wing)

		# Right wing
		var right_wing = Polygon2D.new()
		right_wing.name = "RightWing"
		right_wing.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(12, -8), Vector2(15, 0), Vector2(10, 8)
		])
		right_wing.color = color
		butterfly.add_child(right_wing)

		# Body
		var body = Polygon2D.new()
		body.polygon = PackedVector2Array([
			Vector2(-2, -6), Vector2(2, -6), Vector2(2, 6), Vector2(-2, 6)
		])
		body.color = Color(0.2, 0.15, 0.1)
		butterfly.add_child(body)

		butterfly_data.append({
			"node": butterfly,
			"left_wing": left_wing,
			"right_wing": right_wing,
			"x": randf_range(-600, 600),
			"y": randf_range(-350, 250),
			"target_x": randf_range(-600, 600),
			"target_y": randf_range(-350, 250),
			"phase": randf() * TAU,
			"wing_phase": randf() * TAU
		})


func _create_ambient_glow() -> void:
	# Soft ambient lighting effects
	var glow_positions = [
		Vector2(-300, -150), Vector2(300, -120), Vector2(0, 50),
		Vector2(-450, 100), Vector2(450, 150)
	]

	for pos in glow_positions:
		var glow = Polygon2D.new()
		glow.position = pos
		glow.polygon = PackedVector2Array([
			Vector2(-80, 0), Vector2(-55, -55), Vector2(0, -80),
			Vector2(55, -55), Vector2(80, 0), Vector2(55, 55),
			Vector2(0, 80), Vector2(-55, 55)
		])
		glow.color = Color(0.5, 0.7, 0.4, 0.08)
		atmosphere_container.add_child(glow)


func _enhance_zones() -> void:
	# Add extra visual polish to zone platforms
	var zones = zones_node.get_children()
	for zone in zones:
		if zone.has_node("Glow"):
			var glow = zone.get_node("Glow")
			glow.modulate.a = 0.6


# =============================================================================
# ANIMATION
# =============================================================================

func _animate_environment(delta: float) -> void:
	_animate_petals(delta)
	_animate_fireflies(delta)
	_animate_butterflies(delta)
	_animate_flowers(delta)
	_animate_pond(delta)


func _animate_petals(delta: float) -> void:
	for petal in petal_data:
		var node = petal["node"] as Polygon2D
		if not node:
			continue

		# Update position with falling and swaying
		petal["y"] += petal["speed_y"] * delta
		petal["x"] += petal["speed_x"] * delta
		petal["x"] += sin(env_time * 0.5 + petal["sway_phase"]) * petal["sway_amplitude"] * delta

		# Reset when off screen
		if petal["y"] > 500:
			petal["y"] = -500
			petal["x"] = randf_range(-800, 800)

		node.position = Vector2(petal["x"], petal["y"])
		node.rotation += petal["rotation_speed"] * delta


func _animate_fireflies(delta: float) -> void:
	for firefly in firefly_data:
		var node = firefly["node"] as Node2D
		var glow = firefly["glow"] as Polygon2D
		if not node or not glow:
			continue

		# Circular wandering motion
		firefly["phase"] += firefly["speed"] * delta
		var new_x = firefly["base_x"] + cos(firefly["phase"]) * firefly["radius"]
		var new_y = firefly["base_y"] + sin(firefly["phase"] * 0.7) * firefly["radius"] * 0.6

		node.position = Vector2(new_x, new_y)

		# Pulsing glow
		firefly["glow_phase"] += delta * 3
		var glow_alpha = 0.2 + sin(firefly["glow_phase"]) * 0.15
		glow.modulate.a = glow_alpha


func _animate_butterflies(delta: float) -> void:
	for butterfly in butterfly_data:
		var node = butterfly["node"] as Node2D
		var left_wing = butterfly["left_wing"] as Polygon2D
		var right_wing = butterfly["right_wing"] as Polygon2D
		if not node:
			continue

		# Move toward target
		var dx = butterfly["target_x"] - butterfly["x"]
		var dy = butterfly["target_y"] - butterfly["y"]
		var dist = sqrt(dx * dx + dy * dy)

		if dist < 20:
			# Pick new target
			butterfly["target_x"] = randf_range(-600, 600)
			butterfly["target_y"] = randf_range(-350, 250)
		else:
			butterfly["x"] += (dx / dist) * 60 * delta
			butterfly["y"] += (dy / dist) * 60 * delta
			# Add some waviness
			butterfly["y"] += sin(env_time * 3 + butterfly["phase"]) * 30 * delta

		node.position = Vector2(butterfly["x"], butterfly["y"])

		# Wing flapping
		butterfly["wing_phase"] += delta * 15
		var wing_scale = 0.7 + sin(butterfly["wing_phase"]) * 0.3
		if left_wing:
			left_wing.scale.x = wing_scale
		if right_wing:
			right_wing.scale.x = wing_scale


func _animate_flowers(delta: float) -> void:
	for flower in flower_data:
		var node = flower["node"] as Polygon2D
		if not node:
			continue

		# Gentle swaying
		var sway = sin(env_time * 1.5 + flower["phase"]) * 2
		node.position = flower["base_pos"] + Vector2(sway, 0)


func _animate_pond(delta: float) -> void:
	# Animate pond shimmer
	var shimmer = detail_container.find_child("PondShimmer", false, false) as Polygon2D
	if shimmer:
		var alpha = 0.3 + sin(pond_ripple_time * 0.8) * 0.1
		shimmer.modulate.a = alpha


# =============================================================================
# ZONE PANEL GRAPHICS
# =============================================================================

func _clear_zone_graphics() -> void:
	if zone_graphic_container:
		for child in zone_graphic_container.get_children():
			child.queue_free()


func _setup_zone_graphic(zone_id: String) -> void:
	_clear_zone_graphics()
	if not zone_graphic_container:
		return

	var parent = zone_graphic_container.get_parent()
	if parent:
		zone_graphic_container.position = Vector2(parent.size.x / 2, parent.size.y / 2)

	match zone_id:
		"DreamGarden":
			_create_dream_garden_graphic()
		"MemoryArchive":
			_create_memory_archive_graphic()


func _create_dream_garden_graphic() -> void:
	var scale_factor = 2.5

	# Garden bed platform
	var platform = Polygon2D.new()
	platform.polygon = PackedVector2Array([
		Vector2(-80, 0), Vector2(0, -45), Vector2(80, 0), Vector2(0, 45)
	])
	platform.scale = Vector2(scale_factor, scale_factor)
	platform.color = Color(0.18, 0.3, 0.2)
	zone_graphic_container.add_child(platform)

	# Rich soil
	var soil = Polygon2D.new()
	soil.position = Vector2(0, -15 * scale_factor)
	soil.polygon = PackedVector2Array([
		Vector2(-55, 0), Vector2(0, -30), Vector2(55, 0), Vector2(0, 30)
	])
	soil.scale = Vector2(scale_factor, scale_factor)
	soil.color = Color(0.25, 0.18, 0.12)
	zone_graphic_container.add_child(soil)

	# Central dream flower (lotus-like)
	var flower_colors = [
		Color(0.85, 0.6, 0.95), Color(0.75, 0.5, 0.9),
		Color(0.9, 0.7, 0.95), Color(0.7, 0.45, 0.85)
	]
	for i in range(4):
		var petal = Polygon2D.new()
		var angle = i * PI / 2
		petal.position = Vector2(cos(angle) * 20, sin(angle) * 15 - 60) * scale_factor
		petal.polygon = PackedVector2Array([
			Vector2(-15, 15), Vector2(-18, -8), Vector2(0, -25),
			Vector2(18, -8), Vector2(15, 15)
		])
		petal.rotation = angle
		petal.scale = Vector2(scale_factor, scale_factor)
		petal.color = flower_colors[i]
		zone_graphic_container.add_child(petal)

	# Flower center
	var center = Polygon2D.new()
	center.position = Vector2(0, -60 * scale_factor)
	center.polygon = PackedVector2Array([
		Vector2(-12, 0), Vector2(-8, -8), Vector2(0, -12),
		Vector2(8, -8), Vector2(12, 0), Vector2(8, 8),
		Vector2(0, 12), Vector2(-8, 8)
	])
	center.scale = Vector2(scale_factor, scale_factor)
	center.color = Color(1.0, 0.9, 0.5)
	zone_graphic_container.add_child(center)

	# Glow effect
	var glow = Polygon2D.new()
	glow.position = Vector2(0, -50 * scale_factor)
	glow.polygon = PackedVector2Array([
		Vector2(-50, 0), Vector2(-35, -35), Vector2(0, -50),
		Vector2(35, -35), Vector2(50, 0), Vector2(35, 35),
		Vector2(0, 50), Vector2(-35, 35)
	])
	glow.scale = Vector2(scale_factor, scale_factor)
	glow.color = Color(0.7, 0.5, 0.9, 0.25)
	zone_graphic_container.add_child(glow)

	# Small surrounding flowers
	var small_positions = [
		Vector2(-45, -20), Vector2(45, -20), Vector2(-30, 15), Vector2(30, 15)
	]
	var small_colors = [
		Color(0.9, 0.7, 0.3), Color(0.9, 0.5, 0.6),
		Color(0.5, 0.8, 0.6), Color(0.7, 0.6, 0.9)
	]
	for i in range(small_positions.size()):
		var small_flower = Polygon2D.new()
		small_flower.position = small_positions[i] * scale_factor
		small_flower.polygon = PackedVector2Array([
			Vector2(-8, 0), Vector2(0, -10), Vector2(8, 0), Vector2(0, 8)
		])
		small_flower.scale = Vector2(scale_factor, scale_factor)
		small_flower.color = small_colors[i]
		zone_graphic_container.add_child(small_flower)


func _create_memory_archive_graphic() -> void:
	var scale_factor = 2.5

	# Stone platform
	var platform = Polygon2D.new()
	platform.polygon = PackedVector2Array([
		Vector2(-80, 0), Vector2(0, -45), Vector2(80, 0), Vector2(0, 45)
	])
	platform.scale = Vector2(scale_factor, scale_factor)
	platform.color = Color(0.18, 0.2, 0.25)
	zone_graphic_container.add_child(platform)

	# Archive pedestal
	var pedestal = Polygon2D.new()
	pedestal.position = Vector2(0, -20 * scale_factor)
	pedestal.polygon = PackedVector2Array([
		Vector2(-35, 30), Vector2(-35, -20), Vector2(35, -20), Vector2(35, 30)
	])
	pedestal.scale = Vector2(scale_factor, scale_factor)
	pedestal.color = Color(0.35, 0.38, 0.45)
	zone_graphic_container.add_child(pedestal)

	# Crystal formation
	var crystal_colors = [
		Color(0.6, 0.8, 0.95, 0.9),
		Color(0.5, 0.75, 0.9, 0.85),
		Color(0.7, 0.85, 1.0, 0.9)
	]
	var crystal_positions = [
		{"pos": Vector2(0, -70), "height": 50, "width": 18},
		{"pos": Vector2(-25, -55), "height": 35, "width": 14},
		{"pos": Vector2(25, -55), "height": 40, "width": 15},
	]
	for i in range(crystal_positions.size()):
		var crystal = Polygon2D.new()
		var c = crystal_positions[i]
		crystal.position = c["pos"] * scale_factor
		crystal.polygon = PackedVector2Array([
			Vector2(-c["width"], c["height"]), Vector2(-c["width"] * 0.6, 0),
			Vector2(0, -c["height"]), Vector2(c["width"] * 0.6, 0),
			Vector2(c["width"], c["height"])
		])
		crystal.scale = Vector2(scale_factor, scale_factor)
		crystal.color = crystal_colors[i]
		zone_graphic_container.add_child(crystal)

	# Crystal glow
	var glow = Polygon2D.new()
	glow.position = Vector2(0, -60 * scale_factor)
	glow.polygon = PackedVector2Array([
		Vector2(-55, 0), Vector2(-40, -40), Vector2(0, -55),
		Vector2(40, -40), Vector2(55, 0), Vector2(40, 40),
		Vector2(0, 55), Vector2(-40, 40)
	])
	glow.scale = Vector2(scale_factor, scale_factor)
	glow.color = Color(0.5, 0.7, 0.9, 0.2)
	zone_graphic_container.add_child(glow)

	# Memory orbs floating around
	var orb_data = [
		{"pos": Vector2(-40, -90), "color": Color(0.95, 0.85, 0.5, 0.8)},
		{"pos": Vector2(40, -85), "color": Color(0.5, 0.9, 0.7, 0.8)},
		{"pos": Vector2(0, -100), "color": Color(0.9, 0.6, 0.8, 0.8)},
	]
	for orb in orb_data:
		var o = Polygon2D.new()
		o.position = orb["pos"] * scale_factor
		o.polygon = PackedVector2Array([
			Vector2(-8, 0), Vector2(-5, -5), Vector2(0, -8),
			Vector2(5, -5), Vector2(8, 0), Vector2(5, 5),
			Vector2(0, 8), Vector2(-5, 5)
		])
		o.scale = Vector2(scale_factor, scale_factor)
		o.color = orb["color"]
		zone_graphic_container.add_child(o)


func _close_zone() -> void:
	_clear_zone_graphics()
	super._close_zone()


# =============================================================================
# ZONE INTERACTIONS
# =============================================================================

func _open_zone(zone_id: String) -> void:
	match zone_id:
		"DreamGarden":
			_open_dream_garden()
		"MemoryArchive":
			_open_memory_archive()
		_:
			super._open_zone(zone_id)


func _open_dream_garden() -> void:
	zone_title.text = "Dream Garden"
	_clear_zone_body()
	_setup_zone_graphic("DreamGarden")

	_add_spacer(10)

	var intro = Label.new()
	intro.text = "A serene garden where dreams and aspirations take form. Plant seeds of intention and watch them grow."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_font_size_override("font_size", 18)
	intro.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	zone_body.add_child(intro)

	_add_spacer(15)

	var meditate_button = Button.new()
	meditate_button.text = "Guided Visualization"
	meditate_button.custom_minimum_size = Vector2(0, 50)
	meditate_button.add_theme_font_size_override("font_size", 18)
	meditate_button.pressed.connect(_start_visualization)
	zone_body.add_child(meditate_button)

	_add_spacer(8)

	var dream_button = Button.new()
	dream_button.text = "Record a Dream"
	dream_button.custom_minimum_size = Vector2(0, 50)
	dream_button.add_theme_font_size_override("font_size", 18)
	dream_button.pressed.connect(_record_dream)
	zone_body.add_child(dream_button)

	_add_spacer(8)

	var past_btn = Button.new()
	past_btn.text = "View Dream Archive"
	past_btn.custom_minimum_size = Vector2(0, 50)
	past_btn.add_theme_font_size_override("font_size", 18)
	past_btn.pressed.connect(_view_past_dreams)
	zone_body.add_child(past_btn)

	zone_panel.visible = true
	in_zone_panel = true


func _open_memory_archive() -> void:
	zone_title.text = "Memory Archive"
	_clear_zone_body()
	_setup_zone_graphic("MemoryArchive")

	_add_spacer(10)

	var intro = Label.new()
	intro.text = "A crystalline archive where meaningful memories are stored. Revisit past experiences to find wisdom."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_font_size_override("font_size", 18)
	intro.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	zone_body.add_child(intro)

	_add_spacer(15)

	var reflect_button = Button.new()
	reflect_button.text = "Gratitude Reflection"
	reflect_button.custom_minimum_size = Vector2(0, 50)
	reflect_button.add_theme_font_size_override("font_size", 18)
	reflect_button.pressed.connect(_gratitude_reflection)
	zone_body.add_child(reflect_button)

	_add_spacer(8)

	var milestone_button = Button.new()
	milestone_button.text = "View Milestones"
	milestone_button.custom_minimum_size = Vector2(0, 50)
	milestone_button.add_theme_font_size_override("font_size", 18)
	milestone_button.pressed.connect(_view_milestones)
	zone_body.add_child(milestone_button)

	_add_spacer(8)

	var history_btn = Button.new()
	history_btn.text = "Gratitude History"
	history_btn.custom_minimum_size = Vector2(0, 50)
	history_btn.add_theme_font_size_override("font_size", 18)
	history_btn.pressed.connect(_view_gratitude_history)
	zone_body.add_child(history_btn)

	zone_panel.visible = true
	in_zone_panel = true


# ============ DREAM GARDEN FEATURES ============

func _start_visualization() -> void:
	zone_title.text = "Guided Visualization"
	_clear_zone_body()
	_setup_zone_graphic("DreamGarden")

	_add_spacer(10)

	var intro = Label.new()
	intro.text = "Choose a visualization to guide your meditation:"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(intro)

	_add_spacer(12)

	var visualizations = [
		{"name": "Peaceful Garden", "desc": "Walk through a serene garden, feeling calm wash over you.", "aspect": "compassion", "duration": 5},
		{"name": "Mountain Summit", "desc": "Climb to a peak and see your path clearly laid out before you.", "aspect": "courage", "duration": 5},
		{"name": "Inner Sanctuary", "desc": "Build a safe space within yourself where wisdom resides.", "aspect": "wisdom", "duration": 5},
		{"name": "Creative Flow", "desc": "Let ideas flow like a river, uninhibited and free.", "aspect": "creativity", "duration": 5},
	]

	for viz in visualizations:
		var btn = Button.new()
		btn.text = viz.name + " (" + str(viz.duration) + " min)"
		btn.custom_minimum_size = Vector2(0, 45)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_launch_visualization.bind(viz))
		zone_body.add_child(btn)

		var desc = Label.new()
		desc.text = viz.desc
		desc.add_theme_font_size_override("font_size", 14)
		desc.add_theme_color_override("font_color", Color(0.5, 0.6, 0.55))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		zone_body.add_child(desc)

		_add_spacer(8)

	_add_spacer(10)

	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_open_dream_garden)
	zone_body.add_child(back_btn)


func _launch_visualization(viz: Dictionary) -> void:
	_close_zone()
	# Launch a short focus session with the visualization theme
	GameManager.player_data["pending_focus"] = {
		"topic": "Visualization: " + viz.name,
		"duration": viz.duration,
		"difficulty": 0  # Always easy for meditations
	}
	GameManager.goto_scene("res://scenes/focus_mode/focus_mode.tscn")


func _record_dream() -> void:
	zone_title.text = "Dream Journal"
	_clear_zone_body()
	_setup_zone_graphic("DreamGarden")

	_add_spacer(10)

	var intro = Label.new()
	intro.text = "Record your dream while it's fresh in your memory:"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(intro)

	_add_spacer(10)

	# Dream title
	var title_label = Label.new()
	title_label.text = "Dream Title:"
	title_label.add_theme_font_size_override("font_size", 16)
	zone_body.add_child(title_label)

	var title_input = LineEdit.new()
	title_input.name = "DreamTitleInput"
	title_input.placeholder_text = "Give your dream a name..."
	title_input.custom_minimum_size = Vector2(0, 42)
	title_input.add_theme_font_size_override("font_size", 16)
	zone_body.add_child(title_input)

	_add_spacer(8)

	# Dream content
	var content_label = Label.new()
	content_label.text = "What happened in your dream?"
	content_label.add_theme_font_size_override("font_size", 16)
	zone_body.add_child(content_label)

	var content_input = TextEdit.new()
	content_input.name = "DreamContentInput"
	content_input.placeholder_text = "Describe the events, feelings, people, places..."
	content_input.custom_minimum_size = Vector2(0, 100)
	content_input.add_theme_font_size_override("font_size", 15)
	content_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	zone_body.add_child(content_input)

	_add_spacer(8)

	# Dream mood
	var mood_label = Label.new()
	mood_label.text = "How did you feel?"
	mood_label.add_theme_font_size_override("font_size", 16)
	zone_body.add_child(mood_label)

	var mood_container = HBoxContainer.new()
	mood_container.name = "MoodContainer"
	mood_container.add_theme_constant_override("separation", 6)

	var moods = ["Peaceful", "Anxious", "Excited", "Confused", "Happy", "Scared"]
	for mood in moods:
		var btn = Button.new()
		btn.name = "Mood_" + mood
		btn.text = mood
		btn.toggle_mode = true
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_select_dream_mood.bind(mood))
		mood_container.add_child(btn)

	zone_body.add_child(mood_container)

	_add_spacer(12)

	# Buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)

	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_open_dream_garden)
	button_row.add_child(back_btn)

	var save_btn = Button.new()
	save_btn.text = "Save Dream"
	save_btn.custom_minimum_size = Vector2(0, 45)
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.add_theme_font_size_override("font_size", 16)
	save_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	save_btn.pressed.connect(_save_dream)
	button_row.add_child(save_btn)

	zone_body.add_child(button_row)


var _selected_dream_mood: String = ""

func _select_dream_mood(mood: String) -> void:
	_selected_dream_mood = mood
	var container = zone_body.find_child("MoodContainer", true, false)
	if container:
		for child in container.get_children():
			if child is Button:
				child.button_pressed = (child.name == "Mood_" + mood)


func _save_dream() -> void:
	var title_input = zone_body.find_child("DreamTitleInput", true, false) as LineEdit
	var content_input = zone_body.find_child("DreamContentInput", true, false) as TextEdit

	if not title_input or title_input.text.strip_edges() == "":
		_show_dialogue("Missing Title", "Please give your dream a title.")
		return

	if not content_input or content_input.text.strip_edges() == "":
		_show_dialogue("Missing Content", "Please describe what happened in your dream.")
		return

	var dream = {
		"id": str(Time.get_unix_time_from_system()),
		"timestamp": Time.get_unix_time_from_system(),
		"date": Time.get_date_string_from_system(),
		"title": title_input.text.strip_edges(),
		"content": content_input.text.strip_edges(),
		"mood": _selected_dream_mood if _selected_dream_mood != "" else "Neutral"
	}

	_save_dream_entry(dream)

	# Award XP for recording a dream
	GameManager.add_aspect_experience("wisdom", 15)

	_close_zone()
	_show_dialogue("Dream Recorded", "Your dream has been saved to the archive.\n\n+15 Wisdom XP\n\nRecording dreams helps you understand your subconscious mind.", _open_dream_garden)

	_selected_dream_mood = ""


func _save_dream_entry(dream: Dictionary) -> void:
	var dreams = _load_dreams()
	dreams.append(dream)

	var json_string = JSON.stringify(dreams, "\t")
	var path = SaveManager.get_dream_path()
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()


func _load_dreams() -> Array:
	var path = SaveManager.get_dream_path()
	if not FileAccess.file_exists(path):
		return []

	var file = FileAccess.open(path, FileAccess.READ)
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


func _view_past_dreams() -> void:
	zone_title.text = "Dream Archive"
	_clear_zone_body()
	_setup_zone_graphic("DreamGarden")

	_add_spacer(10)

	var dreams = _load_dreams()

	if dreams.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No dreams recorded yet.\n\nStart recording your dreams to discover patterns and insights."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.55))
		zone_body.add_child(empty_label)
	else:
		var header = Label.new()
		header.text = "Your recorded dreams (" + str(dreams.size()) + "):"
		header.add_theme_font_size_override("font_size", 18)
		zone_body.add_child(header)

		_add_spacer(10)

		# Show dreams in reverse chronological order
		dreams.reverse()
		for i in range(min(dreams.size(), 10)):  # Show last 10
			var dream = dreams[i]
			_add_dream_entry(dream)

	_add_spacer(12)

	var back_btn = Button.new()
	back_btn.text = "Record New Dream"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_record_dream)
	zone_body.add_child(back_btn)


func _add_dream_entry(dream: Dictionary) -> void:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)

	var title_row = HBoxContainer.new()

	var title = Label.new()
	title.text = dream.get("title", "Untitled Dream")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.4, 0.7, 0.5))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var date = Label.new()
	date.text = dream.get("date", "")
	date.add_theme_font_size_override("font_size", 14)
	date.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	title_row.add_child(date)

	container.add_child(title_row)

	var content = Label.new()
	var full_content = dream.get("content", "")
	content.text = full_content.substr(0, 80) + ("..." if full_content.length() > 80 else "")
	content.add_theme_font_size_override("font_size", 14)
	content.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	content.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(content)

	var mood = Label.new()
	mood.text = "Mood: " + dream.get("mood", "Neutral")
	mood.add_theme_font_size_override("font_size", 13)
	mood.add_theme_color_override("font_color", Color(0.5, 0.55, 0.5))
	container.add_child(mood)

	zone_body.add_child(container)
	_add_spacer(8)


# ============ MEMORY ARCHIVE FEATURES ============

func _gratitude_reflection() -> void:
	zone_title.text = "Gratitude Reflection"
	_clear_zone_body()
	_setup_zone_graphic("MemoryArchive")

	_add_spacer(10)

	var intro = Label.new()
	intro.text = "Take a moment to reflect on what you're grateful for today:"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(intro)

	_add_spacer(12)

	# Three gratitude inputs
	for i in range(3):
		var label = Label.new()
		label.text = "I am grateful for #" + str(i + 1) + ":"
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.55))
		zone_body.add_child(label)

		var input = LineEdit.new()
		input.name = "GratitudeInput" + str(i)
		input.placeholder_text = "Something you appreciate..."
		input.custom_minimum_size = Vector2(0, 40)
		input.add_theme_font_size_override("font_size", 16)
		zone_body.add_child(input)

		_add_spacer(6)

	_add_spacer(10)

	# Buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)

	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_open_memory_archive)
	button_row.add_child(back_btn)

	var save_btn = Button.new()
	save_btn.text = "Save Gratitude"
	save_btn.custom_minimum_size = Vector2(0, 45)
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.add_theme_font_size_override("font_size", 16)
	save_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	save_btn.pressed.connect(_save_gratitude)
	button_row.add_child(save_btn)

	zone_body.add_child(button_row)


func _save_gratitude() -> void:
	var items = []
	for i in range(3):
		var input = zone_body.find_child("GratitudeInput" + str(i), true, false) as LineEdit
		if input and input.text.strip_edges() != "":
			items.append(input.text.strip_edges())

	if items.is_empty():
		_show_dialogue("Nothing Entered", "Please enter at least one thing you're grateful for.")
		return

	var entry = {
		"timestamp": Time.get_unix_time_from_system(),
		"date": Time.get_date_string_from_system(),
		"items": items
	}

	_save_gratitude_entry(entry)

	# Award XP based on number of items
	var xp = items.size() * 10
	GameManager.add_aspect_experience("compassion", xp)

	# Small world evolution boost
	GameManager.evolve_world(0.1 * items.size())

	_close_zone()
	_show_dialogue("Gratitude Saved", "Your gratitude has been recorded.\n\n+" + str(xp) + " Compassion XP\n+0." + str(items.size()) + "% World Evolution\n\nGratitude practice strengthens your connection to the world.", _open_memory_archive)


func _save_gratitude_entry(entry: Dictionary) -> void:
	var entries = _load_gratitude()
	entries.append(entry)

	var json_string = JSON.stringify(entries, "\t")
	var path = SaveManager.get_gratitude_path()
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()


func _load_gratitude() -> Array:
	var path = SaveManager.get_gratitude_path()
	if not FileAccess.file_exists(path):
		return []

	var file = FileAccess.open(path, FileAccess.READ)
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


func _view_gratitude_history() -> void:
	zone_title.text = "Gratitude History"
	_clear_zone_body()
	_setup_zone_graphic("MemoryArchive")

	_add_spacer(10)

	var entries = _load_gratitude()

	if entries.is_empty():
		var empty = Label.new()
		empty.text = "No gratitude entries yet.\n\nStart practicing gratitude daily to see patterns in what brings you joy."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color(0.5, 0.6, 0.55))
		zone_body.add_child(empty)
	else:
		var header = Label.new()
		header.text = "Recent gratitude entries (" + str(entries.size()) + " total):"
		header.add_theme_font_size_override("font_size", 18)
		zone_body.add_child(header)

		_add_spacer(10)

		entries.reverse()
		for i in range(min(entries.size(), 7)):
			var entry = entries[i]
			_add_gratitude_entry(entry)

	_add_spacer(12)

	var back_btn = Button.new()
	back_btn.text = "New Entry"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_gratitude_reflection)
	zone_body.add_child(back_btn)


func _add_gratitude_entry(entry: Dictionary) -> void:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var date_label = Label.new()
	date_label.text = entry.get("date", "")
	date_label.add_theme_font_size_override("font_size", 14)
	date_label.add_theme_color_override("font_color", Color(0.4, 0.6, 0.5))
	container.add_child(date_label)

	var items = entry.get("items", [])
	for item in items:
		var item_label = Label.new()
		item_label.text = "• " + item
		item_label.add_theme_font_size_override("font_size", 16)
		item_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		container.add_child(item_label)

	zone_body.add_child(container)
	_add_spacer(8)


func _view_milestones() -> void:
	zone_title.text = "Journey Milestones"
	_clear_zone_body()
	_setup_zone_graphic("MemoryArchive")

	_add_spacer(10)

	var intro = Label.new()
	intro.text = "Your growth journey so far:"
	intro.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(intro)

	_add_spacer(12)

	# Calculate milestones from player data
	var focus_minutes = int(GameManager.player_data.get("total_focus_minutes", 0))
	var habits_completed = int(GameManager.player_data.get("total_habits_completed", 0))
	var dreams_count = _load_dreams().size()
	var gratitude_count = _load_gratitude().size()
	var evolution = GameManager.player_data.get("world_evolution_level", 0.0)

	var milestones = []

	# Always-achieved milestones
	milestones.append({"name": "Awakening", "desc": "Began your mindscape journey", "achieved": true})

	# Focus milestones
	if focus_minutes >= 25:
		milestones.append({"name": "First Focus", "desc": "Completed your first 25-minute session", "achieved": true})
	if focus_minutes >= 100:
		milestones.append({"name": "Century Focus", "desc": "100 minutes of focused work", "achieved": true})
	if focus_minutes >= 500:
		milestones.append({"name": "Deep Worker", "desc": "500 minutes of focused work", "achieved": true})

	# Habit milestones
	if habits_completed >= 1:
		milestones.append({"name": "Habit Former", "desc": "Completed your first daily habit", "achieved": true})
	if habits_completed >= 10:
		milestones.append({"name": "Building Momentum", "desc": "Completed 10 habits", "achieved": true})
	if habits_completed >= 50:
		milestones.append({"name": "Habit Master", "desc": "Completed 50 habits", "achieved": true})

	# Dream milestones
	if dreams_count >= 1:
		milestones.append({"name": "Dream Catcher", "desc": "Recorded your first dream", "achieved": true})
	if dreams_count >= 10:
		milestones.append({"name": "Dream Keeper", "desc": "Recorded 10 dreams", "achieved": true})

	# Gratitude milestones
	if gratitude_count >= 1:
		milestones.append({"name": "Grateful Heart", "desc": "First gratitude reflection", "achieved": true})
	if gratitude_count >= 7:
		milestones.append({"name": "Week of Thanks", "desc": "7 days of gratitude", "achieved": true})

	# Evolution milestones
	if evolution >= 10:
		milestones.append({"name": "World Shaper", "desc": "10% world evolution", "achieved": true})
	if evolution >= 50:
		milestones.append({"name": "Reality Bender", "desc": "50% world evolution", "achieved": true})

	for milestone in milestones:
		_add_milestone_entry(milestone)

	# Show locked milestones hints
	_add_spacer(12)
	var hint = Label.new()
	hint.text = "Keep growing to unlock more milestones..."
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.4, 0.45, 0.5))
	zone_body.add_child(hint)

	_add_spacer(10)

	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_open_memory_archive)
	zone_body.add_child(back_btn)


func _add_milestone_entry(milestone: Dictionary) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var icon = Label.new()
	icon.text = "✓" if milestone.achieved else "○"
	icon.add_theme_font_size_override("font_size", 18)
	if milestone.achieved:
		icon.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
	else:
		icon.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	row.add_child(icon)

	var text_container = VBoxContainer.new()
	text_container.add_theme_constant_override("separation", 1)

	var name_label = Label.new()
	name_label.text = milestone.name
	name_label.add_theme_font_size_override("font_size", 17)
	if milestone.achieved:
		name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
	else:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	text_container.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = milestone.desc
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.5))
	text_container.add_child(desc_label)

	row.add_child(text_container)
	zone_body.add_child(row)

	_add_spacer(6)


func _add_spacer(height: int) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	zone_body.add_child(spacer)
