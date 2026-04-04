extends MindscapeRegionBase
## Southern Peaks - Training Arena, Script Lab, Goal Compass, Summit
## An achievement-focused area for training, goals, and reaching your peak
## EXPANDED VERSION with dramatic mountain landscape

# Enhanced visual elements
var environment_container: Node2D = null
var atmosphere_container: Node2D = null
var particles_container: Node2D = null
var detail_container: Node2D = null

# Animation state
var env_time: float = 0.0
var cloud_data: Array = []
var snow_particles: Array = []
var torch_data: Array = []
var flag_data: Array = []

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

	# Play mindscape music
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_music_mindscape"):
		audio.play_music_mindscape()

	setup_region({
		"region_id": "south",
		"region_name": "Southern Peaks",
		"theme_color": Color(0.7, 0.55, 0.35),
		"zone_names": {
			"TrainingArena": "Training Arena",
			"ScriptLab": "Script Lab",
			"GoalCompass": "Goal Compass",
			"Summit": "The Summit"
		},
		"player_bounds": Rect2(-900, -700, 1800, 1400)  # Expanded bounds
	})

	# Create enhanced environment BEFORE initialize_region
	_create_enhanced_environment()

	initialize_region()


func _process(delta: float) -> void:
	env_time += delta
	_animate_environment(delta)
	process_region(delta)


# =============================================================================
# ENHANCED ENVIRONMENT CREATION
# =============================================================================

func _create_enhanced_environment() -> void:
	# Create containers - add environment FIRST so it renders behind (like Northern Gardens)
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

	# Build the environment
	_create_sky_gradient()
	_create_distant_mountains()
	_create_mid_mountains()
	_create_main_terrain()
	_create_paths_and_bridges()
	_create_rocks_and_boulders()
	_create_pine_trees()
	_create_snow_patches()
	_create_clouds()
	_create_snow_particles()
	_create_ambient_glow()
	_enhance_zones()


func _create_sky_gradient() -> void:
	# Dawn/dusk sky effect at the edges
	var sky_colors = [
		{"y": -600, "color": Color(0.15, 0.12, 0.2, 0.4)},
		{"y": -400, "color": Color(0.2, 0.15, 0.25, 0.3)},
		{"y": -200, "color": Color(0.25, 0.18, 0.3, 0.2)},
	]

	for sky in sky_colors:
		var band = Polygon2D.new()
		band.polygon = PackedVector2Array([
			Vector2(-1200, sky["y"]), Vector2(1200, sky["y"]),
			Vector2(1200, sky["y"] + 200), Vector2(-1200, sky["y"] + 200)
		])
		band.color = sky["color"]
		environment_container.add_child(band)


func _create_distant_mountains() -> void:
	# Far background mountain range (silhouettes)
	var distant_peaks = [
		{"x": -800, "height": 280, "width": 400},
		{"x": -500, "height": 350, "width": 500},
		{"x": -200, "height": 420, "width": 550},
		{"x": 150, "height": 380, "width": 480},
		{"x": 500, "height": 320, "width": 450},
		{"x": 800, "height": 260, "width": 380},
	]

	for peak in distant_peaks:
		var mountain = Polygon2D.new()
		var w = peak["width"]
		var h = peak["height"]
		var x = peak["x"]
		var base_y = -200

		# Jagged mountain silhouette
		var points = PackedVector2Array()
		points.append(Vector2(x - w/2, base_y))
		points.append(Vector2(x - w/2.5, base_y - h * 0.3))
		points.append(Vector2(x - w/4, base_y - h * 0.5))
		points.append(Vector2(x - w/6, base_y - h * 0.7))
		points.append(Vector2(x, base_y - h))
		points.append(Vector2(x + w/8, base_y - h * 0.8))
		points.append(Vector2(x + w/4, base_y - h * 0.6))
		points.append(Vector2(x + w/3, base_y - h * 0.4))
		points.append(Vector2(x + w/2, base_y))

		mountain.polygon = points
		mountain.color = Color(0.12, 0.1, 0.15, 0.7)
		environment_container.add_child(mountain)

		# Snow caps on distant peaks
		if h > 300:
			var snow = Polygon2D.new()
			snow.polygon = PackedVector2Array([
				Vector2(x - w/8, base_y - h * 0.75),
				Vector2(x, base_y - h),
				Vector2(x + w/10, base_y - h * 0.85),
			])
			snow.color = Color(0.85, 0.88, 0.95, 0.5)
			environment_container.add_child(snow)


func _create_mid_mountains() -> void:
	# Mid-ground mountains with more detail
	var mid_peaks = [
		{"x": -600, "height": 200, "width": 350, "snow": true},
		{"x": -300, "height": 250, "width": 400, "snow": true},
		{"x": 0, "height": 300, "width": 500, "snow": true},
		{"x": 350, "height": 230, "width": 380, "snow": true},
		{"x": 650, "height": 180, "width": 320, "snow": false},
	]

	for peak in mid_peaks:
		var x = peak["x"]
		var h = peak["height"]
		var w = peak["width"]
		var base_y = -100

		# Main mountain body
		var mountain = Polygon2D.new()
		mountain.polygon = PackedVector2Array([
			Vector2(x - w/2, base_y),
			Vector2(x - w/3, base_y - h * 0.4),
			Vector2(x - w/5, base_y - h * 0.7),
			Vector2(x, base_y - h),
			Vector2(x + w/6, base_y - h * 0.75),
			Vector2(x + w/3, base_y - h * 0.45),
			Vector2(x + w/2, base_y),
		])
		mountain.color = Color(0.2, 0.17, 0.22)
		environment_container.add_child(mountain)

		# Rocky face (darker side)
		var shadow_face = Polygon2D.new()
		shadow_face.polygon = PackedVector2Array([
			Vector2(x - w/2, base_y),
			Vector2(x - w/3, base_y - h * 0.4),
			Vector2(x - w/5, base_y - h * 0.7),
			Vector2(x - w/8, base_y - h * 0.5),
			Vector2(x - w/4, base_y),
		])
		shadow_face.color = Color(0.15, 0.12, 0.18)
		environment_container.add_child(shadow_face)

		# Snow cap
		if peak["snow"]:
			var snow = Polygon2D.new()
			snow.polygon = PackedVector2Array([
				Vector2(x - w/6, base_y - h * 0.7),
				Vector2(x - w/10, base_y - h * 0.85),
				Vector2(x, base_y - h),
				Vector2(x + w/8, base_y - h * 0.8),
				Vector2(x + w/5, base_y - h * 0.65),
				Vector2(x, base_y - h * 0.6),
			])
			snow.color = Color(0.9, 0.92, 0.98, 0.9)
			environment_container.add_child(snow)

			# Snow highlights
			var highlight = Polygon2D.new()
			highlight.polygon = PackedVector2Array([
				Vector2(x - w/12, base_y - h * 0.88),
				Vector2(x, base_y - h),
				Vector2(x + w/15, base_y - h * 0.9),
			])
			highlight.color = Color(1, 1, 1, 0.6)
			environment_container.add_child(highlight)


func _create_main_terrain() -> void:
	# Expanded isometric base terrain with elevation levels
	# Level 1: Outer ring (lowest) - darker edge
	var outer_terrain = Polygon2D.new()
	outer_terrain.polygon = PackedVector2Array([
		Vector2(-900, 180), Vector2(0, -600), Vector2(900, 180), Vector2(0, 700)
	])
	outer_terrain.color = Color(0.12, 0.1, 0.09)
	environment_container.add_child(outer_terrain)

	# Level 2: Middle plateau - rocky mountainside
	var mid_terrain = Polygon2D.new()
	mid_terrain.polygon = PackedVector2Array([
		Vector2(-750, 130), Vector2(0, -500), Vector2(750, 130), Vector2(0, 550)
	])
	mid_terrain.color = Color(0.18, 0.15, 0.13)
	environment_container.add_child(mid_terrain)

	# Level 3: Inner plateau (main play area) - warmer rocky ground
	var inner_terrain = Polygon2D.new()
	inner_terrain.polygon = PackedVector2Array([
		Vector2(-600, 100), Vector2(0, -400), Vector2(600, 100), Vector2(0, 450)
	])
	inner_terrain.color = Color(0.22, 0.18, 0.15)
	environment_container.add_child(inner_terrain)

	# Central walkable area - lighter and warmer
	var walkable_area = Polygon2D.new()
	walkable_area.polygon = PackedVector2Array([
		Vector2(-500, 80), Vector2(0, -320), Vector2(500, 80), Vector2(0, 380)
	])
	walkable_area.color = Color(0.26, 0.22, 0.18)
	environment_container.add_child(walkable_area)

	# Warm glow on walkable area
	var terrain_glow = Polygon2D.new()
	terrain_glow.polygon = PackedVector2Array([
		Vector2(-450, 60), Vector2(0, -280), Vector2(450, 60), Vector2(0, 340)
	])
	terrain_glow.color = Color(0.4, 0.32, 0.25, 0.15)
	environment_container.add_child(terrain_glow)

	# Terrain edge highlights - top edge glow
	var edge_highlight = Polygon2D.new()
	edge_highlight.polygon = PackedVector2Array([
		Vector2(-500, 80), Vector2(0, -320), Vector2(500, 80),
		Vector2(490, 85), Vector2(0, -310), Vector2(-490, 85)
	])
	edge_highlight.color = Color(0.35, 0.28, 0.22, 0.4)
	environment_container.add_child(edge_highlight)

	# Outer edge definition
	var outer_edge = Polygon2D.new()
	outer_edge.polygon = PackedVector2Array([
		Vector2(-600, 100), Vector2(0, -400), Vector2(600, 100),
		Vector2(590, 105), Vector2(0, -390), Vector2(-590, 105)
	])
	outer_edge.color = Color(0.3, 0.25, 0.2, 0.3)
	environment_container.add_child(outer_edge)

	# Grid pattern on terrain
	_create_terrain_grid()


func _create_terrain_grid() -> void:
	var grid_color = Color(0.28, 0.23, 0.18, 0.2)

	# Diagonal grid lines
	for i in range(-5, 6):
		var offset = i * 100

		# NE-SW lines
		var line1 = Polygon2D.new()
		line1.polygon = PackedVector2Array([
			Vector2(offset - 550, 80 + offset * 0.5),
			Vector2(offset, -350 + offset * 0.5),
			Vector2(offset + 2, -350 + offset * 0.5),
			Vector2(offset - 548, 80 + offset * 0.5),
		])
		line1.color = grid_color
		detail_container.add_child(line1)


func _create_paths_and_bridges() -> void:
	# Stone paths connecting zones - more visible
	var path_color = Color(0.3, 0.25, 0.2, 0.9)
	var path_edge_color = Color(0.35, 0.3, 0.25, 0.6)

	# Main central path
	var central_path = Polygon2D.new()
	central_path.polygon = PackedVector2Array([
		Vector2(-20, -200), Vector2(20, -200),
		Vector2(25, 250), Vector2(-25, 250)
	])
	central_path.color = path_color
	detail_container.add_child(central_path)

	# Path to Training Arena
	var arena_path = Polygon2D.new()
	arena_path.polygon = PackedVector2Array([
		Vector2(-50, 0), Vector2(-50, -15),
		Vector2(-380, -15), Vector2(-380, 0)
	])
	arena_path.color = path_color
	detail_container.add_child(arena_path)

	# Path to Script Lab
	var lab_path = Polygon2D.new()
	lab_path.polygon = PackedVector2Array([
		Vector2(50, 0), Vector2(50, -15),
		Vector2(380, -15), Vector2(380, 0)
	])
	lab_path.color = path_color
	detail_container.add_child(lab_path)

	# Stone path texture (scattered stones)
	for i in range(30):
		var stone = Polygon2D.new()
		var size = randf_range(3, 8)
		var points = PackedVector2Array()
		for j in range(5):
			var angle = (j / 5.0) * TAU
			var r = size * randf_range(0.7, 1.0)
			points.append(Vector2(cos(angle), sin(angle)) * r)
		stone.polygon = points
		stone.position = Vector2(
			randf_range(-400, 400),
			randf_range(-150, 200)
		)
		stone.color = Color(
			randf_range(0.18, 0.25),
			randf_range(0.15, 0.2),
			randf_range(0.12, 0.17),
			0.6
		)
		detail_container.add_child(stone)


func _create_rocks_and_boulders() -> void:
	# Scattered boulders around the terrain
	var boulder_configs = [
		{"pos": Vector2(-500, 50), "size": 35, "color": Color(0.28, 0.24, 0.2)},
		{"pos": Vector2(-450, 120), "size": 25, "color": Color(0.25, 0.22, 0.18)},
		{"pos": Vector2(480, 80), "size": 30, "color": Color(0.26, 0.23, 0.19)},
		{"pos": Vector2(520, 150), "size": 22, "color": Color(0.24, 0.21, 0.17)},
		{"pos": Vector2(-200, 280), "size": 28, "color": Color(0.27, 0.23, 0.19)},
		{"pos": Vector2(180, 300), "size": 32, "color": Color(0.25, 0.22, 0.18)},
		{"pos": Vector2(-350, -180), "size": 20, "color": Color(0.23, 0.2, 0.17)},
		{"pos": Vector2(320, -150), "size": 24, "color": Color(0.26, 0.22, 0.18)},
	]

	for config in boulder_configs:
		_create_boulder(config["pos"], config["size"], config["color"])


func _create_boulder(pos: Vector2, size: float, color: Color) -> void:
	var boulder = Node2D.new()
	boulder.position = pos
	detail_container.add_child(boulder)

	# Main boulder body
	var body = Polygon2D.new()
	var points = PackedVector2Array()
	var num_verts = randi_range(6, 9)
	for i in range(num_verts):
		var angle = (i / float(num_verts)) * TAU
		var r = size * randf_range(0.7, 1.0)
		points.append(Vector2(cos(angle), sin(angle) * 0.6) * r)
	body.polygon = points
	body.color = color
	boulder.add_child(body)

	# Highlight
	var highlight = Polygon2D.new()
	highlight.polygon = PackedVector2Array([
		Vector2(-size * 0.3, -size * 0.2),
		Vector2(size * 0.2, -size * 0.35),
		Vector2(size * 0.1, -size * 0.15),
		Vector2(-size * 0.2, -size * 0.1),
	])
	highlight.color = Color(color.r + 0.1, color.g + 0.08, color.b + 0.06, 0.5)
	boulder.add_child(highlight)

	# Shadow
	var shadow = Polygon2D.new()
	var shadow_points = PackedVector2Array()
	for i in range(8):
		var angle = (i / 8.0) * TAU
		shadow_points.append(Vector2(cos(angle) * size * 1.1, sin(angle) * size * 0.3 + size * 0.4))
	shadow.polygon = shadow_points
	shadow.color = Color(0, 0, 0, 0.25)
	shadow.z_index = -1
	boulder.add_child(shadow)


func _create_pine_trees() -> void:
	# Scattered pine trees for atmosphere
	var tree_positions = [
		Vector2(-600, -50), Vector2(-550, 20), Vector2(-620, 100),
		Vector2(580, -30), Vector2(620, 60), Vector2(550, 130),
		Vector2(-480, 200), Vector2(500, 220),
		Vector2(-650, -120), Vector2(670, -100),
	]

	for pos in tree_positions:
		_create_pine_tree(pos, randf_range(40, 70))


func _create_pine_tree(pos: Vector2, height: float) -> void:
	var tree = Node2D.new()
	tree.position = pos
	detail_container.add_child(tree)

	# Trunk
	var trunk = Polygon2D.new()
	trunk.polygon = PackedVector2Array([
		Vector2(-4, 0), Vector2(-3, -height * 0.3),
		Vector2(3, -height * 0.3), Vector2(4, 0)
	])
	trunk.color = Color(0.35, 0.25, 0.18)
	tree.add_child(trunk)

	# Tree layers (3 triangular sections)
	var layer_colors = [
		Color(0.12, 0.25, 0.15),
		Color(0.1, 0.22, 0.13),
		Color(0.08, 0.2, 0.11),
	]

	for i in range(3):
		var layer = Polygon2D.new()
		var layer_y = -height * 0.25 - i * height * 0.22
		var layer_width = (30 - i * 8) * (height / 55.0)
		var layer_height = height * 0.35

		layer.polygon = PackedVector2Array([
			Vector2(-layer_width, layer_y),
			Vector2(0, layer_y - layer_height),
			Vector2(layer_width, layer_y),
		])
		layer.color = layer_colors[i]
		tree.add_child(layer)

	# Snow on top
	var snow = Polygon2D.new()
	var top_y = -height * 0.25 - 2 * height * 0.22
	snow.polygon = PackedVector2Array([
		Vector2(-8, top_y + 5),
		Vector2(0, top_y - height * 0.2),
		Vector2(8, top_y + 5),
	])
	snow.color = Color(0.9, 0.92, 0.95, 0.7)
	tree.add_child(snow)


func _create_snow_patches() -> void:
	# Snow accumulation on terrain
	var snow_areas = [
		{"pos": Vector2(-300, -250), "size": 80},
		{"pos": Vector2(250, -200), "size": 70},
		{"pos": Vector2(0, -320), "size": 100},
		{"pos": Vector2(-150, -280), "size": 60},
		{"pos": Vector2(180, -260), "size": 55},
	]

	for area in snow_areas:
		var snow = Polygon2D.new()
		var points = PackedVector2Array()
		var size = area["size"]
		for i in range(10):
			var angle = (i / 10.0) * TAU
			var r = size * randf_range(0.6, 1.0)
			points.append(area["pos"] + Vector2(cos(angle), sin(angle) * 0.4) * r)
		snow.polygon = points
		snow.color = Color(0.85, 0.88, 0.95, 0.3)
		detail_container.add_child(snow)


func _create_clouds() -> void:
	cloud_data.clear()

	# Create drifting clouds
	for i in range(8):
		var cloud = Node2D.new()
		cloud.name = "Cloud" + str(i)
		cloud.position = Vector2(
			randf_range(-1000, 1000),
			randf_range(-550, -350)
		)
		atmosphere_container.add_child(cloud)

		# Cloud puffs
		var num_puffs = randi_range(3, 6)
		for j in range(num_puffs):
			var puff = Polygon2D.new()
			var puff_size = randf_range(30, 60)
			var puff_points = PackedVector2Array()
			for k in range(10):
				var angle = (k / 10.0) * TAU
				var r = puff_size * randf_range(0.7, 1.0)
				puff_points.append(Vector2(cos(angle), sin(angle) * 0.5) * r)
			puff.polygon = puff_points
			puff.position = Vector2(j * 35 - num_puffs * 15, randf_range(-10, 10))
			puff.color = Color(0.8, 0.82, 0.9, randf_range(0.15, 0.3))
			cloud.add_child(puff)

		cloud_data.append({
			"node": cloud,
			"speed": randf_range(8, 20),
			"start_x": cloud.position.x
		})


func _create_snow_particles() -> void:
	snow_particles.clear()

	# Gentle snowfall
	for i in range(60):
		var flake = Polygon2D.new()
		var size = randf_range(1.5, 4)
		var points = PackedVector2Array()
		for j in range(6):
			var angle = (j / 6.0) * TAU
			points.append(Vector2(cos(angle), sin(angle)) * size)
		flake.polygon = points
		flake.position = Vector2(
			randf_range(-800, 800),
			randf_range(-500, 400)
		)
		flake.color = Color(1, 1, 1, randf_range(0.2, 0.5))
		particles_container.add_child(flake)

		snow_particles.append({
			"node": flake,
			"fall_speed": randf_range(15, 40),
			"drift_speed": randf_range(0.5, 2),
			"drift_phase": randf() * TAU
		})


func _create_ambient_glow() -> void:
	# Warm glow from zones
	var zone_glows = [
		{"pos": Vector2(-400, 50), "color": Color(0.8, 0.5, 0.3, 0.1), "size": 120},  # Training
		{"pos": Vector2(400, 50), "color": Color(0.5, 0.7, 0.9, 0.1), "size": 100},  # Script
		{"pos": Vector2(-200, 250), "color": Color(0.9, 0.4, 0.3, 0.1), "size": 90},  # Compass
		{"pos": Vector2(200, 250), "color": Color(0.9, 0.7, 0.3, 0.12), "size": 110},  # Summit
		{"pos": Vector2(0, -200), "color": Color(0.9, 0.75, 0.4, 0.15), "size": 100},  # Portal
	]

	for glow_config in zone_glows:
		var glow = Polygon2D.new()
		var points = PackedVector2Array()
		var size = glow_config["size"]
		for i in range(16):
			var angle = (i / 16.0) * TAU
			points.append(glow_config["pos"] + Vector2(cos(angle), sin(angle) * 0.5) * size)
		glow.polygon = points
		glow.color = glow_config["color"]
		glow.z_index = -8
		environment_container.add_child(glow)


func _enhance_zones() -> void:
	# Add torches and details to existing zones
	_add_zone_torches()
	_add_zone_decorations()


func _add_zone_torches() -> void:
	torch_data.clear()

	var torch_positions = [
		Vector2(-440, 20), Vector2(-360, 80),  # Training Arena
		Vector2(360, 20), Vector2(440, 80),    # Script Lab
		Vector2(-240, 220), Vector2(-160, 280),  # Goal Compass
		Vector2(160, 220), Vector2(240, 280),  # Summit
	]

	for pos in torch_positions:
		var torch = Node2D.new()
		torch.name = "Torch"
		torch.position = pos
		detail_container.add_child(torch)

		# Torch post
		var post = Polygon2D.new()
		post.polygon = PackedVector2Array([
			Vector2(-3, 0), Vector2(-2, -25), Vector2(2, -25), Vector2(3, 0)
		])
		post.color = Color(0.35, 0.28, 0.2)
		torch.add_child(post)

		# Torch bowl
		var bowl = Polygon2D.new()
		bowl.polygon = PackedVector2Array([
			Vector2(-8, -25), Vector2(-6, -32), Vector2(6, -32), Vector2(8, -25)
		])
		bowl.color = Color(0.4, 0.32, 0.25)
		torch.add_child(bowl)

		# Flame
		var flame = Polygon2D.new()
		flame.name = "Flame"
		flame.polygon = PackedVector2Array([
			Vector2(-5, -32), Vector2(0, -50), Vector2(5, -32)
		])
		flame.color = Color(1.0, 0.6, 0.2, 0.9)
		torch.add_child(flame)

		# Flame glow
		var glow = Polygon2D.new()
		glow.name = "FlameGlow"
		var glow_points = PackedVector2Array()
		for i in range(10):
			var angle = (i / 10.0) * TAU
			glow_points.append(Vector2(cos(angle) * 20, sin(angle) * 20 - 40))
		glow.polygon = glow_points
		glow.color = Color(1.0, 0.5, 0.1, 0.2)
		torch.add_child(glow)

		torch_data.append({
			"node": torch,
			"phase": randf() * TAU
		})


func _add_zone_decorations() -> void:
	# Add flags to Summit zone
	flag_data.clear()
	var summit_pos = Vector2(200, 250)

	for i in range(3):
		var flag = Node2D.new()
		flag.name = "Flag" + str(i)
		flag.position = summit_pos + Vector2(-30 + i * 30, -60 - i * 10)
		detail_container.add_child(flag)

		# Pole
		var pole = Polygon2D.new()
		pole.polygon = PackedVector2Array([
			Vector2(-1.5, 0), Vector2(-1.5, -50), Vector2(1.5, -50), Vector2(1.5, 0)
		])
		pole.color = Color(0.5, 0.4, 0.3)
		flag.add_child(pole)

		# Flag cloth
		var cloth = Polygon2D.new()
		cloth.name = "Cloth"
		cloth.polygon = PackedVector2Array([
			Vector2(2, -50), Vector2(25, -45), Vector2(25, -35), Vector2(2, -30)
		])
		cloth.color = [
			Color(0.9, 0.3, 0.2),
			Color(0.9, 0.7, 0.2),
			Color(0.3, 0.7, 0.4),
		][i]
		flag.add_child(cloth)

		flag_data.append({
			"node": flag,
			"phase": randf() * TAU
		})


# =============================================================================
# ENVIRONMENT ANIMATION
# =============================================================================

func _animate_environment(delta: float) -> void:
	_animate_clouds(delta)
	_animate_snow(delta)
	_animate_torches(delta)
	_animate_flags(delta)


func _animate_clouds(delta: float) -> void:
	for cloud_info in cloud_data:
		var cloud = cloud_info["node"] as Node2D
		if cloud:
			cloud.position.x += cloud_info["speed"] * delta
			# Wrap around
			if cloud.position.x > 1200:
				cloud.position.x = -1000


func _animate_snow(delta: float) -> void:
	for snow_info in snow_particles:
		var flake = snow_info["node"] as Polygon2D
		if flake:
			flake.position.y += snow_info["fall_speed"] * delta
			flake.position.x += sin(env_time * snow_info["drift_speed"] + snow_info["drift_phase"]) * 0.5

			# Reset when below terrain
			if flake.position.y > 450:
				flake.position.y = -500
				flake.position.x = randf_range(-800, 800)


func _animate_torches(delta: float) -> void:
	for torch_info in torch_data:
		var torch = torch_info["node"] as Node2D
		if torch:
			var flame = torch.get_node_or_null("Flame")
			var glow = torch.get_node_or_null("FlameGlow")
			var phase = torch_info["phase"]

			if flame:
				# Flicker effect
				var flicker = sin(env_time * 8 + phase) * 0.2 + sin(env_time * 12 + phase * 2) * 0.1
				flame.scale = Vector2(1.0 + flicker * 0.3, 1.0 + flicker * 0.2)
				flame.color.a = 0.8 + flicker * 0.2

			if glow:
				var pulse = sin(env_time * 4 + phase) * 0.1
				glow.color.a = 0.15 + pulse


func _animate_flags(delta: float) -> void:
	for flag_info in flag_data:
		var flag = flag_info["node"] as Node2D
		if flag:
			var cloth = flag.get_node_or_null("Cloth")
			if cloth:
				var wave = sin(env_time * 3 + flag_info["phase"])
				cloth.polygon = PackedVector2Array([
					Vector2(2, -50),
					Vector2(25 + wave * 3, -45 + wave * 2),
					Vector2(25 + wave * 4, -35 + wave * 2),
					Vector2(2, -30)
				])


func _input(event: InputEvent) -> void:
	handle_input(event)


func _open_zone(zone_id: String) -> void:
	match zone_id:
		"TrainingArena":
			_open_training_arena()
		"ScriptLab":
			_open_script_lab()
		"GoalCompass":
			_open_goal_compass()
		"Summit":
			_open_summit()
		_:
			super._open_zone(zone_id)


func _open_training_arena() -> void:
	zone_title.text = "Training Arena"
	_clear_zone_body()

	var intro = Label.new()
	intro.text = "Face challenges and adversaries to build mental strength. Each victory over doubt makes you stronger."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(intro)

	var train_button = Button.new()
	train_button.text = "Begin Training"
	train_button.pressed.connect(_begin_training)
	zone_body.add_child(train_button)

	zone_panel.visible = true
	in_zone_panel = true


func _open_script_lab() -> void:
	# Transition to the full Script Lab scene
	GameManager.goto_scene("res://scenes/mindscape/script_lab.tscn")


func _show_all_scripts() -> void:
	var all_scripts = ScriptManager.get_all_scripts()
	if all_scripts.is_empty():
		var empty = Label.new()
		empty.text = "No scripts created yet.\n\nScripts are 25-minute focused sessions with specific actions for each minute."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		zone_body.add_child(empty)
	else:
		var header = Label.new()
		header.text = "Your Scripts:"
		header.add_theme_font_size_override("font_size", 20)
		header.add_theme_color_override("font_color", Color(0.7, 0.55, 0.35))
		zone_body.add_child(header)

		_add_spacer(8)

		for script in all_scripts:
			_add_script_row(script)


func _show_favorite_scripts() -> void:
	var favorites = ScriptManager.get_favorite_scripts()
	if favorites.is_empty():
		var empty = Label.new()
		empty.text = "No favorite scripts yet.\n\nMark scripts as favorites to access them quickly here."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		zone_body.add_child(empty)
	else:
		var header = Label.new()
		header.text = "★ Your Best Scripts:"
		header.add_theme_font_size_override("font_size", 20)
		header.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
		zone_body.add_child(header)

		_add_spacer(8)

		for script in favorites:
			_add_script_row(script)


func _show_run_history() -> void:
	# Get all completed run records
	var all_runs = []
	for record in ScriptManager.run_records.values():
		if record.get("status", "") == "completed":
			all_runs.append(record)

	all_runs.sort_custom(func(a, b): return a.get("completed_at", 0) > b.get("completed_at", 0))

	if all_runs.is_empty():
		var empty = Label.new()
		empty.text = "No completed script runs yet.\n\nRun a script and complete the review to see your history here."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		zone_body.add_child(empty)
	else:
		var header = Label.new()
		header.text = "Recent Runs:"
		header.add_theme_font_size_override("font_size", 20)
		header.add_theme_color_override("font_color", Color(0.7, 0.55, 0.35))
		zone_body.add_child(header)

		_add_spacer(8)

		# Show last 10 runs
		for i in range(mini(all_runs.size(), 10)):
			_add_run_record_row(all_runs[i])


func _add_run_record_row(record: Dictionary) -> void:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	# Completion rate indicator
	var rate_indicator = ColorRect.new()
	rate_indicator.custom_minimum_size = Vector2(6, 45)
	var rate = record.get("completion_rate", 0.0)
	if rate >= 0.8:
		rate_indicator.color = Color(0.3, 0.7, 0.3)  # Green
	elif rate >= 0.5:
		rate_indicator.color = Color(0.8, 0.7, 0.2)  # Yellow
	else:
		rate_indicator.color = Color(0.7, 0.3, 0.3)  # Red
	container.add_child(rate_indicator)

	# Run info
	var info_col = VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label = Label.new()
	name_label.text = record.get("script_name", "Unknown") + ".psa"
	name_label.add_theme_font_size_override("font_size", 18)
	info_col.add_child(name_label)

	var meta_label = Label.new()
	var date_str = Time.get_datetime_string_from_unix_time(record.get("completed_at", 0)).substr(0, 10)
	meta_label.text = date_str + " • " + str(int(rate * 100)) + "% completed"
	meta_label.add_theme_font_size_override("font_size", 14)
	meta_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	info_col.add_child(meta_label)

	container.add_child(info_col)

	# View button
	var view_btn = Button.new()
	view_btn.text = "Review"
	view_btn.custom_minimum_size = Vector2(80, 0)
	view_btn.add_theme_font_size_override("font_size", 16)
	view_btn.pressed.connect(_view_run_record.bind(record.get("id", "")))
	container.add_child(view_btn)

	zone_body.add_child(container)
	_add_spacer(6)


func _add_script_row(script: Dictionary) -> void:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	# Favorite star button
	var fav_btn = Button.new()
	var is_fav = ScriptManager.is_favorite(script.get("id", ""))
	fav_btn.text = "★" if is_fav else "☆"
	fav_btn.custom_minimum_size = Vector2(35, 45)
	fav_btn.add_theme_font_size_override("font_size", 20)
	if is_fav:
		fav_btn.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
	else:
		fav_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	fav_btn.pressed.connect(_toggle_script_favorite.bind(script.get("id", "")))
	container.add_child(fav_btn)

	# Type indicator
	var type_indicator = ColorRect.new()
	type_indicator.custom_minimum_size = Vector2(6, 45)
	type_indicator.color = ScriptManager.get_type_color(script.get("type", 0))
	container.add_child(type_indicator)

	# Script info
	var info_col = VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label = Label.new()
	name_label.text = script.get("name", "Untitled") + ".psa"
	name_label.add_theme_font_size_override("font_size", 18)
	info_col.add_child(name_label)

	var meta_label = Label.new()
	var runs = script.get("times_executed", 0)
	var avg_rate = script.get("avg_completion_rate", 0.0)
	var meta_text = ScriptManager.get_type_name(script.get("type", 0)).capitalize() + " • " + str(runs) + " runs"
	if runs > 0 and avg_rate > 0:
		meta_text += " • " + str(int(avg_rate * 100)) + "% avg"
	meta_label.text = meta_text
	meta_label.add_theme_font_size_override("font_size", 14)
	meta_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	info_col.add_child(meta_label)

	container.add_child(info_col)

	# Run button
	var run_btn = Button.new()
	run_btn.text = "Run"
	run_btn.custom_minimum_size = Vector2(70, 0)
	run_btn.add_theme_font_size_override("font_size", 16)
	run_btn.pressed.connect(_run_script.bind(script.get("id", "")))
	container.add_child(run_btn)

	# View button
	var view_btn = Button.new()
	view_btn.text = "View"
	view_btn.custom_minimum_size = Vector2(70, 0)
	view_btn.add_theme_font_size_override("font_size", 16)
	view_btn.pressed.connect(_view_script.bind(script.get("id", "")))
	container.add_child(view_btn)

	zone_body.add_child(container)
	_add_spacer(6)


func _toggle_script_favorite(script_id: String) -> void:
	ScriptManager.toggle_favorite(script_id)
	_open_script_lab()  # Refresh


func _open_goal_compass() -> void:
	zone_title.text = "Goal Compass"
	_clear_zone_body()

	var intro = Label.new()
	intro.text = "Set your direction with meaningful goals. The compass always points toward your true north."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(intro)

	_add_spacer(8)

	# Show active goals
	var active_goals = GoalManager.get_active_goals() if GoalManager else []
	if active_goals.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No active goals. Set one below!"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		zone_body.add_child(empty_label)
	else:
		var goals_header = Label.new()
		goals_header.text = "Active Goals:"
		goals_header.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
		zone_body.add_child(goals_header)

		for goal in active_goals:
			var goal_row = HBoxContainer.new()
			goal_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var timeframe_text = GoalManager.get_timeframe_name(goal.get("timeframe", 0))
			var goal_label = Label.new()
			goal_label.text = "[" + timeframe_text + "] " + goal.get("title", "Goal")
			goal_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			goal_row.add_child(goal_label)

			var complete_btn = Button.new()
			complete_btn.text = "✓"
			complete_btn.tooltip_text = "Mark as complete"
			complete_btn.custom_minimum_size = Vector2(32, 0)
			complete_btn.pressed.connect(_complete_goal.bind(goal.id))
			goal_row.add_child(complete_btn)

			zone_body.add_child(goal_row)

	_add_spacer(16)

	var add_button = Button.new()
	add_button.text = "+ Set New Goal"
	add_button.pressed.connect(_show_goal_creation_form)
	zone_body.add_child(add_button)

	_add_spacer(20)

	# Values Compass section
	var values_header = Label.new()
	values_header.text = "Core Values"
	values_header.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	values_header.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(values_header)

	var values_desc = Label.new()
	values_desc.text = "Define your guiding principles to keep goals aligned with what matters most."
	values_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	values_desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	zone_body.add_child(values_desc)

	_add_spacer(8)

	var values_button = Button.new()
	values_button.text = "Open Values Compass"
	values_button.pressed.connect(_open_values_compass)
	zone_body.add_child(values_button)

	zone_panel.visible = true
	in_zone_panel = true


func _show_goal_creation_form() -> void:
	zone_title.text = "Create Goal"
	_clear_zone_body()

	# Title input
	var title_label = Label.new()
	title_label.text = "What do you want to achieve?"
	zone_body.add_child(title_label)

	var title_input = LineEdit.new()
	title_input.name = "GoalTitleInput"
	title_input.placeholder_text = "Enter your goal..."
	title_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_body.add_child(title_input)

	_add_spacer(12)

	# Timeframe selection
	var timeframe_label = Label.new()
	timeframe_label.text = "Timeframe:"
	zone_body.add_child(timeframe_label)

	var timeframe_container = HBoxContainer.new()
	timeframe_container.name = "TimeframeContainer"

	var daily_btn = Button.new()
	daily_btn.name = "DailyBtn"
	daily_btn.text = "Daily"
	daily_btn.toggle_mode = true
	daily_btn.button_pressed = true
	daily_btn.pressed.connect(_select_timeframe.bind(0))
	timeframe_container.add_child(daily_btn)

	var weekly_btn = Button.new()
	weekly_btn.name = "WeeklyBtn"
	weekly_btn.text = "Weekly"
	weekly_btn.toggle_mode = true
	weekly_btn.pressed.connect(_select_timeframe.bind(1))
	timeframe_container.add_child(weekly_btn)

	var milestone_btn = Button.new()
	milestone_btn.name = "MilestoneBtn"
	milestone_btn.text = "Milestone"
	milestone_btn.toggle_mode = true
	milestone_btn.pressed.connect(_select_timeframe.bind(2))
	timeframe_container.add_child(milestone_btn)

	zone_body.add_child(timeframe_container)

	_add_spacer(12)

	# Aspect selection
	var aspect_label = Label.new()
	aspect_label.text = "Powers which aspect?"
	zone_body.add_child(aspect_label)

	var aspect_grid = GridContainer.new()
	aspect_grid.name = "AspectGrid"
	aspect_grid.columns = 3

	var aspects = [
		{"id": "discipline", "name": "Discipline"},
		{"id": "courage", "name": "Courage"},
		{"id": "creativity", "name": "Creativity"},
		{"id": "compassion", "name": "Compassion"},
		{"id": "wisdom", "name": "Wisdom"},
		{"id": "vitality", "name": "Vitality"}
	]

	for i in range(aspects.size()):
		var aspect = aspects[i]
		var btn = Button.new()
		btn.name = aspect.id + "Btn"
		btn.text = aspect.name
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)  # Default to Discipline
		btn.pressed.connect(_select_aspect.bind(aspect.id))
		aspect_grid.add_child(btn)

	zone_body.add_child(aspect_grid)

	_add_spacer(16)

	# Action buttons
	var button_row = HBoxContainer.new()

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(_open_goal_compass)
	button_row.add_child(cancel_btn)

	var create_btn = Button.new()
	create_btn.text = "Create Goal"
	create_btn.pressed.connect(_create_goal_from_form)
	button_row.add_child(create_btn)

	zone_body.add_child(button_row)

# Form state
var _selected_timeframe: int = 0  # GoalManager.GoalTimeframe.DAILY
var _selected_aspect: String = "discipline"


func _select_timeframe(timeframe: int) -> void:
	_selected_timeframe = timeframe

	# Update button states
	var container = zone_body.find_child("TimeframeContainer", true, false)
	if container:
		for child in container.get_children():
			if child is Button:
				child.button_pressed = false

		var btn_name = ["DailyBtn", "WeeklyBtn", "MilestoneBtn"][timeframe] if timeframe < 3 else "DailyBtn"
		var btn = container.get_node_or_null(btn_name)
		if btn:
			btn.button_pressed = true


func _select_aspect(aspect_id: String) -> void:
	_selected_aspect = aspect_id

	# Update button states
	var grid = zone_body.find_child("AspectGrid", true, false)
	if grid:
		for child in grid.get_children():
			if child is Button:
				child.button_pressed = (child.name == aspect_id + "Btn")


func _create_goal_from_form() -> void:
	var title_input = zone_body.find_child("GoalTitleInput", true, false) as LineEdit
	if not title_input or title_input.text.strip_edges() == "":
		_show_dialogue("Error", "Please enter a goal title.")
		return

	var goal_data = {
		"title": title_input.text.strip_edges(),
		"timeframe": _selected_timeframe,
		"aspect": _selected_aspect
	}

	GoalManager.create_goal(goal_data)

	# Show confirmation and return to compass
	_close_zone()
	var timeframe_name = GoalManager.get_timeframe_name(_selected_timeframe)
	_show_dialogue("Goal Created", "'" + goal_data.title + "' has been set as a " + timeframe_name + " goal!\n\nComplete it to earn XP and evolve your mindscape.", _open_goal_compass)


func _complete_goal(goal_id: String) -> void:
	var goal = GoalManager.goals.get(goal_id, {})
	var title = goal.get("title", "Goal")

	GoalManager.complete_goal(goal_id)

	_close_zone()
	_show_dialogue("Goal Complete!", "'" + title + "' achieved!\n\n+" + str(goal.get("exp_reward", 15)) + " XP earned.", _open_goal_compass)


func _add_spacer(height: int) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	zone_body.add_child(spacer)


func _open_summit() -> void:
	zone_title.text = "The Summit"
	_clear_zone_body()

	var intro = Label.new()
	intro.text = "The pinnacle of achievement. Those who reach the summit have proven their dedication to growth."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(intro)

	var evolution = GameManager.get_evolution_level()
	var status = Label.new()
	status.text = "\nYour Evolution Level: " + str(evolution)
	zone_body.add_child(status)

	zone_panel.visible = true
	in_zone_panel = true


func _begin_training() -> void:
	_close_zone()
	_show_dialogue("Training", "Prepare yourself for mental combat!\n\n(Combat system coming soon)")


# ============ SCRIPT LAB SYSTEM ============

var _script_name: String = ""
var _script_layer: String = "mind"
var _script_type: int = 0
var _script_lines: Array = []

func _create_script() -> void:
	zone_title.text = "Create Script"
	_clear_zone_body()

	# Reset state
	_script_lines.clear()
	for i in range(25):
		_script_lines.append("")

	# Name input
	var name_label = Label.new()
	name_label.text = "Script Name:"
	name_label.add_theme_font_size_override("font_size", 20)
	zone_body.add_child(name_label)

	var name_input = LineEdit.new()
	name_input.name = "ScriptNameInput"
	name_input.placeholder_text = "e.g., morning_routine, deep_work, exercise..."
	name_input.custom_minimum_size = Vector2(0, 45)
	name_input.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(name_input)

	_add_spacer(12)

	# Layer selection
	var layer_label = Label.new()
	layer_label.text = "Life Domain:"
	layer_label.add_theme_font_size_override("font_size", 20)
	zone_body.add_child(layer_label)

	var layer_grid = GridContainer.new()
	layer_grid.name = "LayerGrid"
	layer_grid.columns = 3
	layer_grid.add_theme_constant_override("h_separation", 8)
	layer_grid.add_theme_constant_override("v_separation", 8)

	var layers = [
		{"id": "mind", "name": "Mind"},
		{"id": "body", "name": "Body"},
		{"id": "soul", "name": "Soul"},
		{"id": "social", "name": "Social"},
		{"id": "career", "name": "Career"},
		{"id": "wealth", "name": "Wealth"}
	]

	for i in range(layers.size()):
		var layer = layers[i]
		var btn = Button.new()
		btn.name = "Layer_" + layer.id
		btn.text = layer.name
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_select_script_layer.bind(layer.id))
		layer_grid.add_child(btn)

	zone_body.add_child(layer_grid)

	_add_spacer(12)

	# Type selection
	var type_label = Label.new()
	type_label.text = "Script Type:"
	type_label.add_theme_font_size_override("font_size", 20)
	zone_body.add_child(type_label)

	var type_container = HBoxContainer.new()
	type_container.name = "TypeContainer"
	type_container.add_theme_constant_override("separation", 8)

	var types = [
		{"id": 0, "name": "Update", "desc": "Learning & growth"},
		{"id": 1, "name": "Upgrade", "desc": "Paradigm shift"},
	]

	for i in range(types.size()):
		var type_data = types[i]
		var btn = Button.new()
		btn.name = "Type_" + str(type_data.id)
		btn.text = type_data.name
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_select_script_type.bind(type_data.id))
		type_container.add_child(btn)

	zone_body.add_child(type_container)

	_add_spacer(15)

	# Buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 15)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 50)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.add_theme_font_size_override("font_size", 18)
	cancel_btn.pressed.connect(_open_script_lab)
	button_row.add_child(cancel_btn)

	var next_btn = Button.new()
	next_btn.text = "Write Lines →"
	next_btn.custom_minimum_size = Vector2(0, 50)
	next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_btn.add_theme_font_size_override("font_size", 18)
	next_btn.pressed.connect(_show_script_lines_editor)
	button_row.add_child(next_btn)

	zone_body.add_child(button_row)


func _select_script_layer(layer_id: String) -> void:
	_script_layer = layer_id
	var grid = zone_body.find_child("LayerGrid", true, false)
	if grid:
		for child in grid.get_children():
			if child is Button:
				child.button_pressed = (child.name == "Layer_" + layer_id)


func _select_script_type(type_id: int) -> void:
	_script_type = type_id
	var container = zone_body.find_child("TypeContainer", true, false)
	if container:
		for child in container.get_children():
			if child is Button:
				child.button_pressed = (child.name == "Type_" + str(type_id))


func _show_script_lines_editor() -> void:
	var name_input = zone_body.find_child("ScriptNameInput", true, false) as LineEdit
	if not name_input or name_input.text.strip_edges() == "":
		_show_dialogue("Missing Name", "Please enter a name for your script.")
		return

	_script_name = name_input.text.strip_edges()

	zone_title.text = "Write Script Lines"
	_clear_zone_body()

	var intro = Label.new()
	intro.text = "Write 5 action lines (each = 5 minutes of focus):"
	intro.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(intro)

	var hint = Label.new()
	hint.text = "Be specific: 'Review notes for 5 min' not 'Study'"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	zone_body.add_child(hint)

	_add_spacer(10)

	# Show 5 main lines (each represents 5 minutes)
	for i in range(5):
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var num = Label.new()
		num.text = str((i * 5) + 1).pad_zeros(2) + "-" + str((i + 1) * 5).pad_zeros(2)
		num.custom_minimum_size = Vector2(55, 0)
		num.add_theme_font_size_override("font_size", 14)
		num.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		row.add_child(num)

		var input = LineEdit.new()
		input.name = "Line_" + str(i)
		input.placeholder_text = "Action for minutes " + str((i * 5) + 1) + "-" + str((i + 1) * 5) + "..."
		input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		input.custom_minimum_size = Vector2(0, 40)
		input.add_theme_font_size_override("font_size", 16)
		row.add_child(input)

		zone_body.add_child(row)

	_add_spacer(15)

	# Buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 15)

	var back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.custom_minimum_size = Vector2(0, 50)
	back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_create_script)
	button_row.add_child(back_btn)

	var save_btn = Button.new()
	save_btn.text = "Create Script"
	save_btn.custom_minimum_size = Vector2(0, 50)
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.add_theme_font_size_override("font_size", 18)
	save_btn.pressed.connect(_save_new_script)
	button_row.add_child(save_btn)

	zone_body.add_child(button_row)


func _save_new_script() -> void:
	# Collect lines (expand 5 inputs into 25 lines)
	_script_lines.clear()
	for i in range(5):
		var input = zone_body.find_child("Line_" + str(i), true, false) as LineEdit
		var line_text = input.text.strip_edges() if input else ""
		# Each input covers 5 minutes, so add it 5 times
		for j in range(5):
			_script_lines.append(line_text)

	# Check if at least one line has content
	var has_content = false
	for line in _script_lines:
		if line != "":
			has_content = true
			break

	if not has_content:
		_show_dialogue("Empty Script", "Please write at least one action line.")
		return

	# Create the script
	var script_id = ScriptManager.create_script({
		"name": _script_name,
		"layer_id": _script_layer,
		"type": _script_type,
		"lines": _script_lines
	})

	_close_zone()
	_show_dialogue("Script Created!", _script_name + ".psa has been created!\n\nRun this script to start a 25-minute focus session with your defined actions.", _open_script_lab)


func _run_script(script_id: String) -> void:
	if not ScriptManager.scripts.has(script_id):
		_show_dialogue("Error", "Script not found.")
		return

	var script = ScriptManager.execute_script(script_id)

	_close_zone()

	# Launch focus mode with the script
	GameManager.player_data["pending_focus"] = {
		"topic": script.name + ".psa",
		"script_id": script_id,
		"lines": script.lines,
		"aspect": script.aspect,
		"duration": 25,
		"difficulty": 0  # Default to easy
	}
	GameManager.goto_scene("res://scenes/focus_mode/focus_mode.tscn")


func _view_script(script_id: String) -> void:
	if not ScriptManager.scripts.has(script_id):
		_show_dialogue("Error", "Script not found.")
		return

	var script = ScriptManager.scripts[script_id]

	zone_title.text = script.name + ".psa"
	_clear_zone_body()

	# Script info
	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 15)

	# Favorite star
	var is_fav = ScriptManager.is_favorite(script_id)
	var fav_label = Label.new()
	fav_label.text = "★" if is_fav else ""
	fav_label.add_theme_font_size_override("font_size", 20)
	fav_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
	if is_fav:
		info_row.add_child(fav_label)

	var type_label = Label.new()
	type_label.text = ScriptManager.get_type_name(script.get("type", 0)).capitalize()
	type_label.add_theme_font_size_override("font_size", 18)
	type_label.add_theme_color_override("font_color", ScriptManager.get_type_color(script.get("type", 0)))
	info_row.add_child(type_label)

	var layer_label = Label.new()
	layer_label.text = "• " + script.get("layer_id", "mind").capitalize() + " layer"
	layer_label.add_theme_font_size_override("font_size", 18)
	layer_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	info_row.add_child(layer_label)

	var runs_label = Label.new()
	var runs = script.get("times_executed", 0)
	var avg_rate = script.get("avg_completion_rate", 0.0)
	var runs_text = "• " + str(runs) + " runs"
	if runs > 0 and avg_rate > 0:
		runs_text += " (" + str(int(avg_rate * 100)) + "% avg)"
	runs_label.text = runs_text
	runs_label.add_theme_font_size_override("font_size", 18)
	runs_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	info_row.add_child(runs_label)

	zone_body.add_child(info_row)

	# Version info if applicable
	if script.has("version") and script.version > 1:
		var version_label = Label.new()
		version_label.text = "Version " + str(script.version)
		if script.has("parent_script_id"):
			version_label.text += " (iteration of previous)"
		version_label.add_theme_font_size_override("font_size", 14)
		version_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		zone_body.add_child(version_label)

	_add_spacer(15)

	# Show lines (condensed - show unique lines only)
	var header = Label.new()
	header.text = "Script Actions:"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.7, 0.55, 0.35))
	zone_body.add_child(header)

	_add_spacer(8)

	var lines = script.get("lines", [])
	var effectiveness = ScriptManager.get_line_effectiveness(script_id)
	var shown_lines = []

	for i in range(0, min(lines.size(), 25), 5):
		var line = lines[i]
		if line != "" and not shown_lines.has(line):
			shown_lines.append(line)

			var line_row = HBoxContainer.new()
			line_row.add_theme_constant_override("separation", 10)

			# Effectiveness indicator
			if i < effectiveness.size() and effectiveness[i].status != "no_data":
				var eff_icon = Label.new()
				var eff = effectiveness[i]
				if eff.status == "good":
					eff_icon.text = "✓"
					eff_icon.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))
				elif eff.status == "needs_work":
					eff_icon.text = "~"
					eff_icon.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
				else:
					eff_icon.text = "!"
					eff_icon.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
				eff_icon.custom_minimum_size = Vector2(20, 0)
				eff_icon.add_theme_font_size_override("font_size", 14)
				line_row.add_child(eff_icon)

			var num = Label.new()
			num.text = str(i + 1).pad_zeros(2)
			num.custom_minimum_size = Vector2(30, 0)
			num.add_theme_font_size_override("font_size", 14)
			num.add_theme_color_override("font_color", Color(0.4, 0.45, 0.5))
			line_row.add_child(num)

			var text = Label.new()
			text.text = line
			text.add_theme_font_size_override("font_size", 16)
			text.autowrap_mode = TextServer.AUTOWRAP_WORD
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_row.add_child(text)

			zone_body.add_child(line_row)

	if shown_lines.is_empty():
		var empty = Label.new()
		empty.text = "(No actions defined)"
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		zone_body.add_child(empty)

	_add_spacer(20)

	# First row of buttons
	var button_row1 = HBoxContainer.new()
	button_row1.add_theme_constant_override("separation", 15)

	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 50)
	back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_open_script_lab)
	button_row1.add_child(back_btn)

	var run_btn = Button.new()
	run_btn.text = "Run Script"
	run_btn.custom_minimum_size = Vector2(0, 50)
	run_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_btn.add_theme_font_size_override("font_size", 18)
	run_btn.pressed.connect(_run_script.bind(script_id))
	button_row1.add_child(run_btn)

	zone_body.add_child(button_row1)

	_add_spacer(8)

	# Second row of buttons
	var button_row2 = HBoxContainer.new()
	button_row2.add_theme_constant_override("separation", 15)

	var history_btn = Button.new()
	history_btn.text = "Run History"
	history_btn.custom_minimum_size = Vector2(0, 45)
	history_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_btn.add_theme_font_size_override("font_size", 16)
	history_btn.pressed.connect(_view_script_runs.bind(script_id))
	button_row2.add_child(history_btn)

	var fav_btn = Button.new()
	fav_btn.text = "★ Unfavorite" if is_fav else "☆ Favorite"
	fav_btn.custom_minimum_size = Vector2(0, 45)
	fav_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fav_btn.add_theme_font_size_override("font_size", 16)
	fav_btn.pressed.connect(_toggle_and_refresh_script.bind(script_id))
	button_row2.add_child(fav_btn)

	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(0, 45)
	delete_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_btn.add_theme_font_size_override("font_size", 16)
	delete_btn.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
	delete_btn.pressed.connect(_confirm_delete_script.bind(script_id))
	button_row2.add_child(delete_btn)

	zone_body.add_child(button_row2)


func _toggle_and_refresh_script(script_id: String) -> void:
	ScriptManager.toggle_favorite(script_id)
	_view_script(script_id)  # Refresh view


func _confirm_delete_script(script_id: String) -> void:
	var script = ScriptManager.scripts.get(script_id, {})
	var name = script.get("name", "this script")

	_close_zone()
	_show_dialogue("Delete Script?", "Are you sure you want to delete " + name + ".psa?\n\nThis cannot be undone.", _delete_script.bind(script_id))


func _delete_script(script_id: String) -> void:
	ScriptManager.delete_script(script_id)
	_close_dialogue()
	_show_dialogue("Deleted", "Script has been removed.", _open_script_lab)


# ============ RUN RECORD VIEWING ============

func _view_run_record(run_id: String) -> void:
	if not ScriptManager.run_records.has(run_id):
		_show_dialogue("Error", "Run record not found.")
		return

	var record = ScriptManager.run_records[run_id]

	zone_title.text = "Run Review: " + record.get("script_name", "Script") + ".psa"
	_clear_zone_body()

	# Header info
	var date_str = Time.get_datetime_string_from_unix_time(record.get("completed_at", 0)).substr(0, 10)
	var rate = record.get("completion_rate", 0.0)

	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 15)

	var date_label = Label.new()
	date_label.text = "Date: " + date_str
	date_label.add_theme_font_size_override("font_size", 16)
	info_row.add_child(date_label)

	var rate_label = Label.new()
	rate_label.text = "Completion: " + str(int(rate * 100)) + "%"
	rate_label.add_theme_font_size_override("font_size", 16)
	if rate >= 0.8:
		rate_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	elif rate >= 0.5:
		rate_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
	else:
		rate_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
	info_row.add_child(rate_label)

	if record.get("overall_rating", 0) > 0:
		var rating_label = Label.new()
		rating_label.text = "★".repeat(record.get("overall_rating", 0))
		rating_label.add_theme_font_size_override("font_size", 16)
		rating_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
		info_row.add_child(rating_label)

	zone_body.add_child(info_row)

	_add_spacer(10)

	# Reflection
	var reflection = record.get("reflection", "")
	if reflection != "":
		var ref_label = Label.new()
		ref_label.text = "Reflection: " + reflection
		ref_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		ref_label.add_theme_font_size_override("font_size", 14)
		ref_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
		zone_body.add_child(ref_label)
		_add_spacer(10)

	# Line-by-line results header
	var header = Label.new()
	header.text = "Line-by-Line Results:"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.7, 0.55, 0.35))
	zone_body.add_child(header)

	_add_spacer(8)

	# Scrollable line results
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	zone_body.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	var lines_planned = record.get("lines_planned", [])
	var line_results = record.get("line_results", [])

	# Show condensed view (every 5 minutes)
	for i in range(0, 25, 5):
		var line_text = lines_planned[i] if i < lines_planned.size() else ""
		var result = line_results[i] if i < line_results.size() else {"status": "pending", "note": ""}

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		# Status icon
		var status_icon = Label.new()
		var status = result.get("status", "pending")
		match status:
			"completed":
				status_icon.text = "✓"
				status_icon.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
			"partial":
				status_icon.text = "~"
				status_icon.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
			"skipped":
				status_icon.text = "✗"
				status_icon.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
			_:
				status_icon.text = "○"
				status_icon.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		status_icon.custom_minimum_size = Vector2(25, 0)
		status_icon.add_theme_font_size_override("font_size", 18)
		row.add_child(status_icon)

		# Time range
		var time_label = Label.new()
		time_label.text = str(i + 1).pad_zeros(2) + "-" + str(i + 5).pad_zeros(2)
		time_label.custom_minimum_size = Vector2(50, 0)
		time_label.add_theme_font_size_override("font_size", 14)
		time_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		row.add_child(time_label)

		# Line text
		var text_label = Label.new()
		text_label.text = line_text if line_text != "" else "(empty)"
		text_label.add_theme_font_size_override("font_size", 16)
		text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if line_text == "":
			text_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		row.add_child(text_label)

		vbox.add_child(row)

		# Show note if any
		var note = result.get("note", "")
		if note != "":
			var note_row = HBoxContainer.new()
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(75, 0)
			note_row.add_child(spacer)
			var note_label = Label.new()
			note_label.text = "→ " + note
			note_label.add_theme_font_size_override("font_size", 13)
			note_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
			note_row.add_child(note_label)
			vbox.add_child(note_row)

	_add_spacer(15)

	# Action buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 15)

	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 50)
	back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_open_script_lab)
	button_row.add_child(back_btn)

	var iterate_btn = Button.new()
	iterate_btn.text = "Create Improved Version"
	iterate_btn.custom_minimum_size = Vector2(0, 50)
	iterate_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	iterate_btn.add_theme_font_size_override("font_size", 18)
	iterate_btn.pressed.connect(_create_iteration_from_run.bind(run_id))
	button_row.add_child(iterate_btn)

	zone_body.add_child(button_row)


func _create_iteration_from_run(run_id: String) -> void:
	if not ScriptManager.run_records.has(run_id):
		return

	var record = ScriptManager.run_records[run_id]
	var script_id = record.get("script_id", "")

	if not ScriptManager.scripts.has(script_id):
		_show_dialogue("Error", "Original script not found.")
		return

	var script = ScriptManager.scripts[script_id]

	zone_title.text = "Improve: " + script.get("name", "Script") + ".psa"
	_clear_zone_body()

	var intro = Label.new()
	intro.text = "Edit lines based on your run experience. Lines that were often skipped or partial are highlighted."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_font_size_override("font_size", 16)
	zone_body.add_child(intro)

	_add_spacer(10)

	# Get line effectiveness
	var effectiveness = ScriptManager.get_line_effectiveness(script_id)

	# Show 5 editable lines
	var lines_planned = record.get("lines_planned", script.get("lines", []))
	var line_results = record.get("line_results", [])

	for i in range(5):
		var line_idx = i * 5
		var line_text = lines_planned[line_idx] if line_idx < lines_planned.size() else ""
		var result = line_results[line_idx] if line_idx < line_results.size() else {}

		var row = VBoxContainer.new()
		row.add_theme_constant_override("separation", 4)

		# Label with status indicator
		var label_row = HBoxContainer.new()

		var num_label = Label.new()
		num_label.text = str((i * 5) + 1).pad_zeros(2) + "-" + str((i + 1) * 5).pad_zeros(2)
		num_label.custom_minimum_size = Vector2(55, 0)
		num_label.add_theme_font_size_override("font_size", 14)
		label_row.add_child(num_label)

		# Show effectiveness if available
		if line_idx < effectiveness.size():
			var eff = effectiveness[line_idx]
			var eff_label = Label.new()
			if eff.status == "good":
				eff_label.text = "✓ works well"
				eff_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))
			elif eff.status == "needs_work":
				eff_label.text = "~ needs adjustment"
				eff_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
			elif eff.status == "problematic":
				eff_label.text = "✗ often skipped"
				eff_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
			eff_label.add_theme_font_size_override("font_size", 12)
			label_row.add_child(eff_label)

		row.add_child(label_row)

		var input = LineEdit.new()
		input.name = "IterLine_" + str(i)
		input.text = line_text
		input.placeholder_text = "Action for minutes " + str((i * 5) + 1) + "-" + str((i + 1) * 5) + "..."
		input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		input.custom_minimum_size = Vector2(0, 40)
		input.add_theme_font_size_override("font_size", 16)
		row.add_child(input)

		zone_body.add_child(row)

	_add_spacer(15)

	# Notes input
	var notes_label = Label.new()
	notes_label.text = "What are you changing and why?"
	notes_label.add_theme_font_size_override("font_size", 16)
	zone_body.add_child(notes_label)

	var notes_input = LineEdit.new()
	notes_input.name = "IterNotes"
	notes_input.placeholder_text = "e.g., Made line 3 more specific, reduced time on prep..."
	notes_input.custom_minimum_size = Vector2(0, 40)
	notes_input.add_theme_font_size_override("font_size", 16)
	zone_body.add_child(notes_input)

	_add_spacer(15)

	# Buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 15)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 50)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.add_theme_font_size_override("font_size", 18)
	cancel_btn.pressed.connect(_view_run_record.bind(run_id))
	button_row.add_child(cancel_btn)

	var save_btn = Button.new()
	save_btn.text = "Create New Version"
	save_btn.custom_minimum_size = Vector2(0, 50)
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.add_theme_font_size_override("font_size", 18)
	save_btn.pressed.connect(_save_script_iteration.bind(script_id))
	button_row.add_child(save_btn)

	zone_body.add_child(button_row)


func _save_script_iteration(original_script_id: String) -> void:
	# Collect new lines
	var new_lines = []
	for i in range(5):
		var input = zone_body.find_child("IterLine_" + str(i), true, false) as LineEdit
		var line_text = input.text.strip_edges() if input else ""
		# Expand to 5 copies
		for j in range(5):
			new_lines.append(line_text)

	var notes_input = zone_body.find_child("IterNotes", true, false) as LineEdit
	var notes = notes_input.text.strip_edges() if notes_input else ""

	var new_script_id = ScriptManager.create_script_iteration(original_script_id, new_lines, notes)

	if new_script_id != "":
		_close_zone()
		_show_dialogue("Version Created!", "A new version of your script has been created.\n\nRun it and see if the changes improve your completion rate!", _open_script_lab)
	else:
		_show_dialogue("Error", "Could not create script iteration.")


# ============ SCRIPT VIEW ENHANCEMENTS ============

func _view_script_runs(script_id: String) -> void:
	var records = ScriptManager.get_script_run_records(script_id)
	var script = ScriptManager.scripts.get(script_id, {})

	zone_title.text = "Run History: " + script.get("name", "Script") + ".psa"
	_clear_zone_body()

	if records.is_empty():
		var empty = Label.new()
		empty.text = "No completed runs for this script yet.\n\nRun the script and complete a review to see your history."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		zone_body.add_child(empty)
	else:
		# Show line effectiveness summary
		var effectiveness = ScriptManager.get_line_effectiveness(script_id)
		if not effectiveness.is_empty():
			var eff_header = Label.new()
			eff_header.text = "Line Effectiveness (based on " + str(records.size()) + " runs):"
			eff_header.add_theme_font_size_override("font_size", 16)
			eff_header.add_theme_color_override("font_color", Color(0.7, 0.55, 0.35))
			zone_body.add_child(eff_header)

			_add_spacer(8)

			for i in range(0, mini(effectiveness.size(), 25), 5):
				var eff = effectiveness[i]
				var row = HBoxContainer.new()

				var time_label = Label.new()
				time_label.text = str(i + 1).pad_zeros(2) + "-" + str(i + 5).pad_zeros(2) + ":"
				time_label.custom_minimum_size = Vector2(60, 0)
				time_label.add_theme_font_size_override("font_size", 14)
				row.add_child(time_label)

				var bar = ProgressBar.new()
				bar.custom_minimum_size = Vector2(150, 20)
				bar.value = eff.rate * 100
				bar.show_percentage = false
				row.add_child(bar)

				var pct_label = Label.new()
				pct_label.text = str(int(eff.rate * 100)) + "%"
				pct_label.custom_minimum_size = Vector2(45, 0)
				pct_label.add_theme_font_size_override("font_size", 14)
				if eff.status == "good":
					pct_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
				elif eff.status == "needs_work":
					pct_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
				else:
					pct_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
				row.add_child(pct_label)

				zone_body.add_child(row)

			_add_spacer(15)

		# Run records list
		var header = Label.new()
		header.text = "Recent Runs:"
		header.add_theme_font_size_override("font_size", 18)
		header.add_theme_color_override("font_color", Color(0.7, 0.55, 0.35))
		zone_body.add_child(header)

		_add_spacer(8)

		for record in records.slice(0, 5):
			_add_run_record_row(record)

	_add_spacer(15)

	var back_btn = Button.new()
	back_btn.text = "Back to Script"
	back_btn.custom_minimum_size = Vector2(0, 50)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_view_script.bind(script_id))
	zone_body.add_child(back_btn)


# ============ VALUES COMPASS SYSTEM ============

const VALUE_SUGGESTIONS = [
	"Growth", "Family", "Health", "Integrity", "Creativity", "Freedom",
	"Adventure", "Connection", "Wisdom", "Courage", "Compassion", "Discipline",
	"Joy", "Service", "Authenticity", "Balance", "Peace", "Excellence",
	"Faith", "Gratitude", "Humor", "Learning", "Loyalty", "Mindfulness",
	"Nature", "Responsibility", "Simplicity", "Teamwork", "Trust", "Vision"
]

var _editing_value_index: int = -1


func _open_values_compass() -> void:
	zone_title.text = "Values Compass"
	_clear_zone_body()

	var intro = Label.new()
	intro.text = "Your core values are the compass that guides all decisions. Define 3-5 values that matter most to you."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(intro)

	_add_spacer(12)

	# Load existing values
	var values = _load_core_values()

	if values.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No core values defined yet. Start by defining what matters most to you."
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		zone_body.add_child(empty_label)
	else:
		var values_header = Label.new()
		values_header.text = "Your Core Values:"
		values_header.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
		values_header.add_theme_font_size_override("font_size", 18)
		zone_body.add_child(values_header)

		_add_spacer(8)

		for i in range(values.size()):
			var value_data = values[i]
			_add_value_display(value_data, i)

	_add_spacer(16)

	# Action buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)

	if values.size() < 5:
		var add_btn = Button.new()
		add_btn.text = "+ Add Value"
		add_btn.pressed.connect(_show_values_editor.bind(-1))
		button_row.add_child(add_btn)

	if values.size() > 0:
		var check_btn = Button.new()
		check_btn.text = "Weekly Alignment Check"
		check_btn.pressed.connect(_show_values_alignment)
		button_row.add_child(check_btn)

	zone_body.add_child(button_row)

	_add_spacer(12)

	var back_btn = Button.new()
	back_btn.text = "← Back to Goal Compass"
	back_btn.pressed.connect(_open_goal_compass)
	zone_body.add_child(back_btn)

	zone_panel.visible = true
	in_zone_panel = true


func _add_value_display(value_data: Dictionary, index: int) -> void:
	var container = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.18, 0.25, 0.8)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	# Value name row
	var name_row = HBoxContainer.new()
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var value_icon = Label.new()
	value_icon.text = "◆"
	value_icon.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	name_row.add_child(value_icon)

	var value_name = Label.new()
	value_name.text = value_data.get("name", "Value")
	value_name.add_theme_font_size_override("font_size", 18)
	value_name.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	value_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(value_name)

	var edit_btn = Button.new()
	edit_btn.text = "✎"
	edit_btn.tooltip_text = "Edit"
	edit_btn.custom_minimum_size = Vector2(30, 0)
	edit_btn.pressed.connect(_show_values_editor.bind(index))
	name_row.add_child(edit_btn)

	var delete_btn = Button.new()
	delete_btn.text = "✕"
	delete_btn.tooltip_text = "Remove"
	delete_btn.custom_minimum_size = Vector2(30, 0)
	delete_btn.pressed.connect(_delete_value.bind(index))
	name_row.add_child(delete_btn)

	vbox.add_child(name_row)

	# Why text
	var why_label = Label.new()
	why_label.text = "\"" + value_data.get("why", "") + "\""
	why_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	why_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	why_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(why_label)

	container.add_child(vbox)
	zone_body.add_child(container)
	_add_spacer(6)


func _show_values_editor(edit_index: int) -> void:
	_editing_value_index = edit_index
	var is_edit = edit_index >= 0

	zone_title.text = "Edit Value" if is_edit else "Add Core Value"
	_clear_zone_body()

	var existing_data = {}
	if is_edit:
		var values = _load_core_values()
		if edit_index < values.size():
			existing_data = values[edit_index]

	# Value name input
	var name_label = Label.new()
	name_label.text = "Value Name:"
	zone_body.add_child(name_label)

	var name_input = LineEdit.new()
	name_input.name = "ValueNameInput"
	name_input.placeholder_text = "e.g., Growth, Integrity, Family..."
	name_input.text = existing_data.get("name", "")
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_body.add_child(name_input)

	_add_spacer(8)

	# Suggestions
	var suggest_label = Label.new()
	suggest_label.text = "Suggestions:"
	suggest_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	zone_body.add_child(suggest_label)

	var suggest_flow = HFlowContainer.new()
	suggest_flow.add_theme_constant_override("h_separation", 6)
	suggest_flow.add_theme_constant_override("v_separation", 4)

	# Show 8 random suggestions
	var shuffled = VALUE_SUGGESTIONS.duplicate()
	shuffled.shuffle()
	for i in range(min(8, shuffled.size())):
		var chip = Button.new()
		chip.text = shuffled[i]
		chip.add_theme_font_size_override("font_size", 14)
		chip.pressed.connect(func(): name_input.text = shuffled[i])
		suggest_flow.add_child(chip)

	zone_body.add_child(suggest_flow)

	_add_spacer(16)

	# Why input
	var why_label = Label.new()
	why_label.text = "Why is this important to you?"
	zone_body.add_child(why_label)

	var why_input = TextEdit.new()
	why_input.name = "ValueWhyInput"
	why_input.placeholder_text = "Describe why this value matters to you..."
	why_input.text = existing_data.get("why", "")
	why_input.custom_minimum_size = Vector2(0, 80)
	why_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_body.add_child(why_input)

	_add_spacer(16)

	# Action buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(_open_values_compass)
	button_row.add_child(cancel_btn)

	var save_btn = Button.new()
	save_btn.text = "Update Value" if is_edit else "Add Value"
	save_btn.pressed.connect(_save_core_value)
	button_row.add_child(save_btn)

	zone_body.add_child(button_row)


func _save_core_value() -> void:
	var name_input = zone_body.find_child("ValueNameInput", true, false) as LineEdit
	var why_input = zone_body.find_child("ValueWhyInput", true, false) as TextEdit

	if not name_input or name_input.text.strip_edges() == "":
		_show_dialogue("Error", "Please enter a value name.")
		return

	var values = _load_core_values()

	var value_data = {
		"name": name_input.text.strip_edges(),
		"why": why_input.text.strip_edges() if why_input else "",
		"created": Time.get_datetime_string_from_system()
	}

	if _editing_value_index >= 0 and _editing_value_index < values.size():
		# Update existing
		values[_editing_value_index] = value_data
	else:
		# Add new
		if values.size() >= 5:
			_show_dialogue("Limit Reached", "You can define up to 5 core values. Edit or remove existing ones first.")
			return
		values.append(value_data)

	_save_core_values(values)
	_editing_value_index = -1

	_close_zone()
	var action = "updated" if _editing_value_index >= 0 else "added"
	_show_dialogue("Value Saved", "'" + value_data.name + "' has been " + action + " as a core value.\n\nRemember to check in weekly to stay aligned!", _open_values_compass)


func _delete_value(index: int) -> void:
	var values = _load_core_values()
	if index >= 0 and index < values.size():
		var removed_name = values[index].get("name", "Value")
		values.remove_at(index)
		_save_core_values(values)
		_close_zone()
		_show_dialogue("Value Removed", "'" + removed_name + "' has been removed from your core values.", _open_values_compass)


func _load_core_values() -> Array:
	var path = "user://core_values.json"
	if not FileAccess.file_exists(path):
		return []

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return []

	var json = JSON.new()
	var result = json.parse(file.get_as_text())
	file.close()

	if result == OK and json.data is Array:
		return json.data
	return []


func _save_core_values(values: Array) -> void:
	var file = FileAccess.open("user://core_values.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(values, "\t"))
		file.close()
		if SaveManager: SaveManager.sync_web_filesystem()


func _show_values_alignment() -> void:
	zone_title.text = "Weekly Alignment Check"
	_clear_zone_body()

	var values = _load_core_values()
	if values.is_empty():
		_show_dialogue("No Values", "Define your core values first before checking alignment.", _open_values_compass)
		return

	var intro = Label.new()
	intro.text = "Reflect on how well you lived your values this week. Rate each from 1 (not at all) to 5 (fully aligned)."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(intro)

	_add_spacer(16)

	# Create rating sliders for each value
	for i in range(values.size()):
		var value_data = values[i]
		var container = VBoxContainer.new()
		container.add_theme_constant_override("separation", 4)

		var name_label = Label.new()
		name_label.text = value_data.get("name", "Value " + str(i + 1))
		name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
		name_label.add_theme_font_size_override("font_size", 16)
		container.add_child(name_label)

		var rating_row = HBoxContainer.new()
		rating_row.add_theme_constant_override("separation", 8)

		for j in range(1, 6):
			var rating_btn = Button.new()
			rating_btn.name = "Rating_" + str(i) + "_" + str(j)
			rating_btn.text = str(j)
			rating_btn.toggle_mode = true
			rating_btn.button_pressed = (j == 3)  # Default to middle
			rating_btn.custom_minimum_size = Vector2(40, 40)
			rating_btn.pressed.connect(_select_alignment_rating.bind(i, j))
			rating_row.add_child(rating_btn)

		var rating_label = Label.new()
		rating_label.name = "RatingLabel_" + str(i)
		rating_label.text = "Neutral"
		rating_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		rating_row.add_child(rating_label)

		container.add_child(rating_row)
		zone_body.add_child(container)
		_add_spacer(12)

	# Notes
	var notes_label = Label.new()
	notes_label.text = "Reflections (optional):"
	zone_body.add_child(notes_label)

	var notes_input = TextEdit.new()
	notes_input.name = "AlignmentNotesInput"
	notes_input.placeholder_text = "What helped or hindered your alignment this week?"
	notes_input.custom_minimum_size = Vector2(0, 60)
	zone_body.add_child(notes_input)

	_add_spacer(16)

	# Action buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(_open_values_compass)
	button_row.add_child(cancel_btn)

	var save_btn = Button.new()
	save_btn.text = "Save Alignment Check"
	save_btn.pressed.connect(_save_alignment_check)
	button_row.add_child(save_btn)

	zone_body.add_child(button_row)


var _alignment_ratings: Dictionary = {}

func _select_alignment_rating(value_index: int, rating: int) -> void:
	_alignment_ratings[value_index] = rating

	# Update button states
	for j in range(1, 6):
		var btn_name = "Rating_" + str(value_index) + "_" + str(j)
		var btn = zone_body.find_child(btn_name, true, false)
		if btn and btn is Button:
			btn.button_pressed = (j == rating)

	# Update rating label
	var label = zone_body.find_child("RatingLabel_" + str(value_index), true, false)
	if label:
		var labels = ["Very Low", "Low", "Neutral", "Good", "Excellent"]
		label.text = labels[rating - 1]
		var colors = [Color(0.8, 0.3, 0.3), Color(0.8, 0.5, 0.3), Color(0.7, 0.7, 0.5), Color(0.5, 0.7, 0.4), Color(0.3, 0.8, 0.4)]
		label.add_theme_color_override("font_color", colors[rating - 1])


func _save_alignment_check() -> void:
	var values = _load_core_values()
	var notes_input = zone_body.find_child("AlignmentNotesInput", true, false) as TextEdit

	# Build alignment data
	var alignment_data = {
		"date": Time.get_datetime_string_from_system(),
		"week": _get_week_number(),
		"ratings": {},
		"notes": notes_input.text.strip_edges() if notes_input else "",
		"average": 0.0
	}

	var total = 0.0
	for i in range(values.size()):
		var rating = _alignment_ratings.get(i, 3)
		alignment_data.ratings[values[i].get("name", "Value " + str(i))] = rating
		total += rating

	alignment_data.average = total / max(1, values.size())

	# Save to alignment history
	var history = _load_alignment_history()
	history.append(alignment_data)
	_save_alignment_history(history)

	# Award XP
	var xp_amount = 30
	if GameManager and GameManager.has_method("add_aspect_experience"):
		GameManager.add_aspect_experience("wisdom", xp_amount)

	# Track for aspect quests
	if GameManager:
		GameManager.check_quests_for_trigger("values_check", {})

	_alignment_ratings.clear()
	_close_zone()
	_show_dialogue("Alignment Saved", "Weekly alignment check recorded!\n\nAverage alignment: " + str(snappedf(alignment_data.average, 0.1)) + "/5\n\n+" + str(xp_amount) + " Wisdom XP", _open_values_compass)


func _get_week_number() -> int:
	var date = Time.get_datetime_dict_from_system()
	var day_of_year = Time.get_datetime_dict_from_system()["day"]
	for m in range(1, date["month"]):
		var days_in_month = 31
		if m in [4, 6, 9, 11]:
			days_in_month = 30
		elif m == 2:
			days_in_month = 29 if date["year"] % 4 == 0 else 28
		day_of_year += days_in_month
	return (day_of_year / 7) + 1


func _load_alignment_history() -> Array:
	var path = "user://values_alignment.json"
	if not FileAccess.file_exists(path):
		return []

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return []

	var json = JSON.new()
	var result = json.parse(file.get_as_text())
	file.close()

	if result == OK and json.data is Array:
		return json.data
	return []


func _save_alignment_history(history: Array) -> void:
	var file = FileAccess.open("user://values_alignment.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(history, "\t"))
		if SaveManager: SaveManager.sync_web_filesystem()
		file.close()
