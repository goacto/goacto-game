extends MindscapeRegionBase
## Western Depths - Shadow Work and Aspect Shrine
## A mysterious underwater cavern area for confronting fears and developing aspects
## EXPANDED VERSION with dramatic underwater depths landscape

# Enhanced visual elements
var environment_container: Node2D = null
var atmosphere_container: Node2D = null
var particles_container: Node2D = null
var detail_container: Node2D = null

# Animation state
var env_time: float = 0.0
var bubble_data: Array = []
var crystal_data: Array = []
var light_ray_data: Array = []
var flame_data: Array = []

# Zone panel graphic
var zone_graphic_container: Control = null

# Variables moved from mid-file (GDScript requires class vars at top)
var fish_data: Array = []
var artifact_glow: Polygon2D = null
var _current_aspect_for_graphic: String = ""
var _current_shadow_type: String = ""
var _selected_kindness_category: String = "helping"
var _kindness_feeling: int = 3

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

	# Play mindscape music
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_music_mindscape"):
		audio.play_music_mindscape()

	setup_region({
		"region_id": "west",
		"region_name": "Western Depths",
		"theme_color": Color(0.6, 0.4, 0.7),
		"zone_names": {
			"ShadowWork": "Shadow Work",
			"AspectShrine": "Aspect Shrine",
			"HealingPool": "Healing Pool",
			"MemoryCave": "Memory Cave"
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

	# Build the underwater cavern environment
	_create_water_gradient()
	_create_cavern_walls()
	_create_rock_formations()
	_create_main_terrain()
	_create_crystal_clusters()
	_create_seaweed()
	_create_light_rays()
	_create_bubbles()
	_create_ambient_glow()
	_enhance_zones()


func _create_water_gradient() -> void:
	# Deep underwater gradient from dark at top to mysterious purple below
	var water_colors = [
		{"y": -500, "color": Color(0.03, 0.02, 0.06, 0.9)},
		{"y": -350, "color": Color(0.05, 0.03, 0.1, 0.7)},
		{"y": -200, "color": Color(0.08, 0.05, 0.15, 0.5)},
	]

	for water in water_colors:
		var band = Polygon2D.new()
		band.polygon = PackedVector2Array([
			Vector2(-1000, water["y"]), Vector2(1000, water["y"]),
			Vector2(1000, water["y"] + 150), Vector2(-1000, water["y"] + 150)
		])
		band.color = water["color"]
		environment_container.add_child(band)


func _create_cavern_walls() -> void:
	# Left cavern wall
	var left_wall = Polygon2D.new()
	left_wall.polygon = PackedVector2Array([
		Vector2(-900, -500), Vector2(-750, -450), Vector2(-700, -300),
		Vector2(-650, -150), Vector2(-700, 0), Vector2(-750, 200),
		Vector2(-850, 400), Vector2(-900, 500), Vector2(-900, -500)
	])
	left_wall.color = Color(0.1, 0.08, 0.15, 1.0)
	environment_container.add_child(left_wall)

	# Left wall detail
	var left_detail = Polygon2D.new()
	left_detail.polygon = PackedVector2Array([
		Vector2(-850, -400), Vector2(-720, -350), Vector2(-680, -200),
		Vector2(-730, -250), Vector2(-800, -320)
	])
	left_detail.color = Color(0.15, 0.12, 0.2, 0.8)
	environment_container.add_child(left_detail)

	# Right cavern wall
	var right_wall = Polygon2D.new()
	right_wall.polygon = PackedVector2Array([
		Vector2(900, -500), Vector2(750, -420), Vector2(680, -280),
		Vector2(650, -100), Vector2(700, 100), Vector2(800, 350),
		Vector2(900, 500), Vector2(900, -500)
	])
	right_wall.color = Color(0.1, 0.08, 0.15, 1.0)
	environment_container.add_child(right_wall)

	# Right wall detail
	var right_detail = Polygon2D.new()
	right_detail.polygon = PackedVector2Array([
		Vector2(850, -380), Vector2(720, -320), Vector2(660, -180),
		Vector2(710, -220), Vector2(790, -300)
	])
	right_detail.color = Color(0.15, 0.12, 0.2, 0.8)
	environment_container.add_child(right_detail)

	# Stalactites from ceiling
	var stalactite_positions = [
		{"x": -500, "length": 120}, {"x": -300, "length": 180},
		{"x": -100, "length": 140}, {"x": 150, "length": 200},
		{"x": 400, "length": 150}, {"x": 600, "length": 100}
	]

	for stal in stalactite_positions:
		var stalactite = Polygon2D.new()
		stalactite.polygon = PackedVector2Array([
			Vector2(stal["x"] - 25, -450),
			Vector2(stal["x"], -450 + stal["length"]),
			Vector2(stal["x"] + 25, -450)
		])
		stalactite.color = Color(0.12, 0.1, 0.18, 1.0)
		environment_container.add_child(stalactite)


func _create_rock_formations() -> void:
	# Underwater rock pillars and formations
	var rock_configs = [
		{"pos": Vector2(-550, 150), "height": 200, "width": 120},
		{"pos": Vector2(-400, 280), "height": 150, "width": 100},
		{"pos": Vector2(500, 180), "height": 180, "width": 110},
		{"pos": Vector2(600, 300), "height": 120, "width": 90},
	]

	for rock in rock_configs:
		var pillar = Polygon2D.new()
		var x = rock["pos"].x
		var y = rock["pos"].y
		var w = rock["width"]
		var h = rock["height"]

		pillar.polygon = PackedVector2Array([
			Vector2(x - w/2, y), Vector2(x - w/3, y - h * 0.6),
			Vector2(x - w/4, y - h * 0.9), Vector2(x, y - h),
			Vector2(x + w/4, y - h * 0.85), Vector2(x + w/3, y - h * 0.5),
			Vector2(x + w/2, y)
		])
		pillar.color = Color(0.15, 0.12, 0.2, 1.0)
		environment_container.add_child(pillar)

		# Rock highlight
		var highlight = Polygon2D.new()
		highlight.polygon = PackedVector2Array([
			Vector2(x - w/4, y - h * 0.9), Vector2(x, y - h),
			Vector2(x - w/6, y - h * 0.7)
		])
		highlight.color = Color(0.22, 0.18, 0.28, 0.7)
		environment_container.add_child(highlight)


func _create_main_terrain() -> void:
	# Underwater cavern floor with depth levels
	# Level 1: Outer ring (deepest)
	var outer_terrain = Polygon2D.new()
	outer_terrain.polygon = PackedVector2Array([
		Vector2(-800, 200), Vector2(0, -450), Vector2(800, 200), Vector2(0, 600)
	])
	outer_terrain.color = Color(0.08, 0.06, 0.12, 1.0)
	environment_container.add_child(outer_terrain)

	# Level 2: Middle plateau
	var mid_terrain = Polygon2D.new()
	mid_terrain.polygon = PackedVector2Array([
		Vector2(-650, 150), Vector2(0, -350), Vector2(650, 150), Vector2(0, 480)
	])
	mid_terrain.color = Color(0.12, 0.1, 0.16, 1.0)
	environment_container.add_child(mid_terrain)

	# Level 3: Inner plateau (main play area)
	var inner_terrain = Polygon2D.new()
	inner_terrain.polygon = PackedVector2Array([
		Vector2(-500, 100), Vector2(0, -280), Vector2(500, 100), Vector2(0, 380)
	])
	inner_terrain.color = Color(0.16, 0.13, 0.22, 1.0)
	environment_container.add_child(inner_terrain)

	# Terrain edge glow
	var edge_glow = Polygon2D.new()
	edge_glow.polygon = PackedVector2Array([
		Vector2(-500, 100), Vector2(0, -280), Vector2(500, 100),
		Vector2(490, 105), Vector2(0, -270), Vector2(-490, 105)
	])
	edge_glow.color = Color(0.5, 0.3, 0.6, 0.3)
	environment_container.add_child(edge_glow)


func _create_crystal_clusters() -> void:
	crystal_data.clear()

	var crystal_positions = [
		{"pos": Vector2(-450, -100), "count": 4, "color": Color(0.6, 0.3, 0.8)},
		{"pos": Vector2(-350, 50), "count": 3, "color": Color(0.5, 0.4, 0.9)},
		{"pos": Vector2(400, -80), "count": 5, "color": Color(0.7, 0.4, 0.7)},
		{"pos": Vector2(480, 100), "count": 3, "color": Color(0.4, 0.3, 0.8)},
		{"pos": Vector2(-200, 200), "count": 4, "color": Color(0.5, 0.5, 0.9)},
		{"pos": Vector2(250, 220), "count": 3, "color": Color(0.6, 0.35, 0.75)},
	]

	for cluster in crystal_positions:
		var cluster_node = Node2D.new()
		cluster_node.position = cluster["pos"]
		detail_container.add_child(cluster_node)

		for i in range(cluster["count"]):
			var crystal = Polygon2D.new()
			var height = randf_range(30, 60)
			var width = randf_range(8, 15)
			var offset_x = (i - cluster["count"] / 2.0) * 15
			var offset_y = randf_range(-10, 10)

			crystal.polygon = PackedVector2Array([
				Vector2(offset_x - width/2, offset_y),
				Vector2(offset_x - width/3, offset_y - height * 0.7),
				Vector2(offset_x, offset_y - height),
				Vector2(offset_x + width/3, offset_y - height * 0.7),
				Vector2(offset_x + width/2, offset_y)
			])
			crystal.color = cluster["color"]
			cluster_node.add_child(crystal)

			# Crystal glow
			var glow = Polygon2D.new()
			glow.polygon = PackedVector2Array([
				Vector2(offset_x - width, offset_y + 5),
				Vector2(offset_x, offset_y - height - 10),
				Vector2(offset_x + width, offset_y + 5)
			])
			glow.color = Color(cluster["color"].r, cluster["color"].g, cluster["color"].b, 0.15)
			cluster_node.add_child(glow)

		crystal_data.append({
			"node": cluster_node,
			"phase": randf() * TAU
		})


func _create_seaweed() -> void:
	var seaweed_positions = [
		Vector2(-600, 250), Vector2(-520, 300), Vector2(-480, 200),
		Vector2(550, 280), Vector2(620, 320), Vector2(500, 350),
		Vector2(-300, 350), Vector2(350, 380),
	]

	for pos in seaweed_positions:
		_create_seaweed_strand(pos, randf_range(60, 100))


func _create_seaweed_strand(pos: Vector2, height: float) -> void:
	var strand = Node2D.new()
	strand.position = pos
	detail_container.add_child(strand)

	# Create multiple fronds
	for i in range(randi_range(3, 5)):
		var frond = Polygon2D.new()
		var offset_x = (i - 2) * 8
		frond.polygon = PackedVector2Array([
			Vector2(offset_x - 4, 0), Vector2(offset_x - 3, -height * 0.4),
			Vector2(offset_x, -height), Vector2(offset_x + 3, -height * 0.4),
			Vector2(offset_x + 4, 0)
		])
		frond.color = Color(0.2, 0.4, 0.35, 0.8)
		strand.add_child(frond)


func _create_light_rays() -> void:
	light_ray_data.clear()

	# Mysterious light rays filtering down from above
	var ray_positions = [-400, -150, 100, 350]

	for x_pos in ray_positions:
		var ray = Polygon2D.new()
		ray.polygon = PackedVector2Array([
			Vector2(x_pos - 30, -450), Vector2(x_pos + 30, -450),
			Vector2(x_pos + 80, 300), Vector2(x_pos - 80, 300)
		])
		ray.color = Color(0.5, 0.4, 0.7, 0.08)
		atmosphere_container.add_child(ray)

		light_ray_data.append({
			"node": ray,
			"base_x": x_pos,
			"phase": randf() * TAU
		})


func _create_bubbles() -> void:
	bubble_data.clear()

	# Create rising bubbles
	for i in range(40):
		var bubble = Polygon2D.new()
		var size = randf_range(3, 8)
		var points = PackedVector2Array()
		for j in range(8):
			var angle = (j / 8.0) * TAU
			points.append(Vector2(cos(angle), sin(angle)) * size)
		bubble.polygon = points
		bubble.position = Vector2(
			randf_range(-600, 600),
			randf_range(-300, 400)
		)
		bubble.color = Color(0.7, 0.8, 1.0, randf_range(0.15, 0.35))
		particles_container.add_child(bubble)

		bubble_data.append({
			"node": bubble,
			"rise_speed": randf_range(15, 35),
			"drift_speed": randf_range(0.3, 1.5),
			"drift_phase": randf() * TAU,
			"size": size
		})


func _create_ambient_glow() -> void:
	# Mysterious glow from zones
	var zone_glows = [
		{"pos": Vector2(-350, -50), "color": Color(0.5, 0.3, 0.7, 0.12), "size": 160},   # Shadow Work
		{"pos": Vector2(0, 200), "color": Color(0.7, 0.5, 0.9, 0.15), "size": 180},      # Aspect Shrine
		{"pos": Vector2(380, -80), "color": Color(0.95, 0.8, 0.45, 0.12), "size": 120},  # Portal
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
		environment_container.add_child(glow)


func _enhance_zones() -> void:
	# Add mystical flames and particle effects to zones
	_add_shrine_flames()
	_create_ancient_ruins()
	_create_bioluminescent_fish()
	_create_treasure_artifact()


func _add_shrine_flames() -> void:
	flame_data.clear()

	# Ethereal flames around Aspect Shrine
	var flame_positions = [
		Vector2(-40, 180), Vector2(40, 180),
		Vector2(-60, 220), Vector2(60, 220),
	]

	for pos in flame_positions:
		var flame_holder = Node2D.new()
		flame_holder.position = pos
		detail_container.add_child(flame_holder)

		# Pedestal
		var pedestal = Polygon2D.new()
		pedestal.polygon = PackedVector2Array([
			Vector2(-8, 0), Vector2(-6, -20), Vector2(6, -20), Vector2(8, 0)
		])
		pedestal.color = Color(0.35, 0.28, 0.4)
		flame_holder.add_child(pedestal)

		# Flame
		var flame = Polygon2D.new()
		flame.name = "Flame"
		flame.polygon = PackedVector2Array([
			Vector2(-10, 0), Vector2(0, -35), Vector2(10, 0)
		])
		flame.position = Vector2(0, -22)
		flame.color = Color(0.7, 0.4, 0.9, 0.9)
		flame_holder.add_child(flame)

		# Flame glow
		var glow = Polygon2D.new()
		glow.name = "FlameGlow"
		var glow_points = PackedVector2Array()
		for i in range(10):
			var angle = (i / 10.0) * TAU
			glow_points.append(Vector2(cos(angle) * 25, sin(angle) * 25 - 30))
		glow.polygon = glow_points
		glow.color = Color(0.6, 0.3, 0.8, 0.15)
		flame_holder.add_child(glow)

		flame_data.append({
			"node": flame_holder,
			"phase": randf() * TAU
		})


func _create_ancient_ruins() -> void:
	# Ancient Goactorian pillars scattered around
	var pillar_positions = [
		Vector2(-550, -200), Vector2(-580, 100),
		Vector2(550, -150), Vector2(520, 50),
	]

	for pos in pillar_positions:
		var pillar = Node2D.new()
		pillar.position = pos

		# Pillar base
		var base = Polygon2D.new()
		base.polygon = PackedVector2Array([
			Vector2(-15, 60), Vector2(15, 60),
			Vector2(12, 50), Vector2(-12, 50)
		])
		base.color = Color(0.25, 0.2, 0.35, 0.9)
		pillar.add_child(base)

		# Pillar shaft (broken/tilted)
		var shaft = Polygon2D.new()
		var tilt = randf_range(-0.1, 0.1)
		shaft.polygon = PackedVector2Array([
			Vector2(-10 + tilt * 20, -80), Vector2(10 + tilt * 20, -80),
			Vector2(12, 50), Vector2(-12, 50)
		])
		shaft.color = Color(0.3, 0.25, 0.4, 0.85)
		pillar.add_child(shaft)

		# Ancient symbols/carvings
		for i in range(3):
			var symbol = Polygon2D.new()
			var sy = -20 + i * 35
			symbol.polygon = PackedVector2Array([
				Vector2(-6, sy - 5), Vector2(6, sy - 5),
				Vector2(6, sy + 5), Vector2(-6, sy + 5)
			])
			symbol.color = Color(0.5, 0.4, 0.7, 0.3)
			pillar.add_child(symbol)

		# Subtle glow
		var glow = Polygon2D.new()
		glow.polygon = PackedVector2Array([
			Vector2(-25, -90), Vector2(25, -90),
			Vector2(25, 70), Vector2(-25, 70)
		])
		glow.color = Color(0.5, 0.35, 0.7, 0.06)
		glow.z_index = -1
		pillar.add_child(glow)

		detail_container.add_child(pillar)


func _create_bioluminescent_fish() -> void:
	fish_data.clear()

	# Create small glowing fish that swim around
	for i in range(12):
		var fish = Node2D.new()
		fish.name = "Fish%d" % i
		fish.position = Vector2(randf_range(-600, 600), randf_range(-400, 300))

		# Fish body
		var body = Polygon2D.new()
		body.name = "Body"
		body.polygon = PackedVector2Array([
			Vector2(-8, 0), Vector2(-4, -3), Vector2(4, -2),
			Vector2(8, 0), Vector2(4, 2), Vector2(-4, 3)
		])
		# Varying colors
		var fish_colors = [
			Color(0.3, 0.8, 0.9, 0.7),  # Cyan
			Color(0.4, 0.9, 0.6, 0.7),  # Green
			Color(0.8, 0.5, 0.9, 0.7),  # Purple
			Color(0.9, 0.8, 0.3, 0.7),  # Yellow
		]
		body.color = fish_colors[i % fish_colors.size()]
		fish.add_child(body)

		# Tail
		var tail = Polygon2D.new()
		tail.name = "Tail"
		tail.polygon = PackedVector2Array([
			Vector2(-8, 0), Vector2(-14, -4), Vector2(-14, 4)
		])
		tail.color = Color(body.color, 0.5)
		fish.add_child(tail)

		# Glow
		var glow = Polygon2D.new()
		glow.name = "Glow"
		var glow_points = PackedVector2Array()
		for j in range(8):
			var angle = (j / 8.0) * TAU
			glow_points.append(Vector2(cos(angle) * 15, sin(angle) * 8))
		glow.polygon = glow_points
		glow.color = Color(body.color.r, body.color.g, body.color.b, 0.15)
		glow.z_index = -1
		fish.add_child(glow)

		particles_container.add_child(fish)

		fish_data.append({
			"node": fish,
			"speed": randf_range(30, 60),
			"direction": 1 if randf() > 0.5 else -1,
			"phase": randf() * TAU,
			"base_y": fish.position.y
		})


func _create_treasure_artifact() -> void:
	# Ancient Goactorian artifact/treasure chest
	var artifact = Node2D.new()
	artifact.name = "AncientArtifact"
	artifact.position = Vector2(-250, 350)

	# Ornate chest base
	var chest = Polygon2D.new()
	chest.polygon = PackedVector2Array([
		Vector2(-30, 0), Vector2(30, 0),
		Vector2(35, 25), Vector2(-35, 25)
	])
	chest.color = Color(0.4, 0.3, 0.2, 0.9)
	artifact.add_child(chest)

	# Chest lid
	var lid = Polygon2D.new()
	lid.polygon = PackedVector2Array([
		Vector2(-32, 0), Vector2(32, 0),
		Vector2(28, -15), Vector2(-28, -15)
	])
	lid.color = Color(0.5, 0.35, 0.25, 0.9)
	artifact.add_child(lid)

	# Gold trim
	var trim = Polygon2D.new()
	trim.polygon = PackedVector2Array([
		Vector2(-30, -2), Vector2(30, -2),
		Vector2(30, 3), Vector2(-30, 3)
	])
	trim.color = Color(0.85, 0.7, 0.3, 0.8)
	artifact.add_child(trim)

	# Mystical glow emanating from chest
	artifact_glow = Polygon2D.new()
	artifact_glow.name = "ArtifactGlow"
	var glow_points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		glow_points.append(Vector2(cos(angle) * 60, sin(angle) * 40 - 10))
	artifact_glow.polygon = glow_points
	artifact_glow.color = Color(0.9, 0.75, 0.3, 0.1)
	artifact_glow.z_index = -1
	artifact.add_child(artifact_glow)

	# Floating gem above chest
	var gem = Node2D.new()
	gem.name = "FloatingGem"
	gem.position = Vector2(0, -40)

	var gem_shape = Polygon2D.new()
	gem_shape.polygon = PackedVector2Array([
		Vector2(0, -15), Vector2(10, 0), Vector2(0, 15), Vector2(-10, 0)
	])
	gem_shape.color = Color(0.8, 0.5, 0.9, 0.9)
	gem.add_child(gem_shape)

	var gem_glow = Polygon2D.new()
	gem_glow.polygon = PackedVector2Array([
		Vector2(0, -25), Vector2(18, 0), Vector2(0, 25), Vector2(-18, 0)
	])
	gem_glow.color = Color(0.7, 0.4, 0.9, 0.2)
	gem_glow.z_index = -1
	gem.add_child(gem_glow)

	artifact.add_child(gem)
	detail_container.add_child(artifact)


# =============================================================================
# ENVIRONMENT ANIMATION
# =============================================================================

func _animate_environment(delta: float) -> void:
	_animate_bubbles(delta)
	_animate_crystals(delta)
	_animate_light_rays(delta)
	_animate_flames(delta)
	_animate_fish(delta)
	_animate_artifact()


func _animate_bubbles(delta: float) -> void:
	for bubble_info in bubble_data:
		var bubble = bubble_info["node"] as Polygon2D
		if bubble:
			bubble.position.y -= bubble_info["rise_speed"] * delta
			bubble.position.x += sin(env_time * bubble_info["drift_speed"] + bubble_info["drift_phase"]) * 0.8

			# Reset when above visible area
			if bubble.position.y < -350:
				bubble.position.y = 450
				bubble.position.x = randf_range(-600, 600)


func _animate_crystals(delta: float) -> void:
	for crystal_info in crystal_data:
		var cluster = crystal_info["node"] as Node2D
		if cluster:
			# Pulsing glow effect
			var pulse = sin(env_time * 1.5 + crystal_info["phase"]) * 0.15 + 0.85
			cluster.modulate.a = pulse


func _animate_light_rays(delta: float) -> void:
	for ray_info in light_ray_data:
		var ray = ray_info["node"] as Polygon2D
		if ray:
			var sway = sin(env_time * 0.3 + ray_info["phase"]) * 20
			var base_x = ray_info["base_x"]
			ray.polygon = PackedVector2Array([
				Vector2(base_x - 30 + sway, -450), Vector2(base_x + 30 + sway, -450),
				Vector2(base_x + 80, 300), Vector2(base_x - 80, 300)
			])

			# Intensity variation
			var intensity = (sin(env_time * 0.5 + ray_info["phase"]) * 0.03 + 0.08)
			ray.color.a = intensity


func _animate_flames(delta: float) -> void:
	for flame_info in flame_data:
		var holder = flame_info["node"] as Node2D
		if holder:
			var flame = holder.get_node_or_null("Flame")
			var glow = holder.get_node_or_null("FlameGlow")
			var phase = flame_info["phase"]

			if flame:
				var flicker = sin(env_time * 6 + phase) * 0.2 + sin(env_time * 10 + phase * 2) * 0.1
				flame.scale = Vector2(1.0 + flicker * 0.25, 1.0 + flicker * 0.3)
				flame.color.a = 0.85 + flicker * 0.15

			if glow:
				var pulse = sin(env_time * 3 + phase) * 0.08
				glow.color.a = 0.12 + pulse


func _animate_fish(delta: float) -> void:
	for fish_info in fish_data:
		var fish = fish_info["node"] as Node2D
		if not fish:
			continue

		var speed = fish_info["speed"]
		var direction = fish_info["direction"]
		var phase = fish_info["phase"]
		var base_y = fish_info["base_y"]

		# Move fish horizontally
		fish.position.x += speed * direction * delta

		# Wrap around when off screen
		if fish.position.x > 700:
			fish.position.x = -700
			fish_info["base_y"] = randf_range(-400, 300)
		elif fish.position.x < -700:
			fish.position.x = 700
			fish_info["base_y"] = randf_range(-400, 300)

		# Gentle vertical swimming motion
		fish.position.y = fish_info["base_y"] + sin(env_time * 2 + phase) * 20

		# Face direction of movement
		fish.scale.x = direction

		# Animate tail
		var tail = fish.get_node_or_null("Tail") as Polygon2D
		if tail:
			tail.rotation = sin(env_time * 8 + phase) * 0.3

		# Pulse glow
		var glow = fish.get_node_or_null("Glow") as Polygon2D
		if glow:
			var pulse = (sin(env_time * 3 + phase) + 1.0) / 2.0
			glow.color.a = 0.1 + pulse * 0.1


func _animate_artifact() -> void:
	if not artifact_glow:
		return

	# Pulse the artifact glow
	var pulse = (sin(env_time * 2) + 1.0) / 2.0
	artifact_glow.color.a = 0.08 + pulse * 0.08

	# Animate floating gem
	var artifact_node = artifact_glow.get_parent()
	if artifact_node:
		var gem = artifact_node.get_node_or_null("FloatingGem")
		if gem:
			gem.position.y = -40 + sin(env_time * 1.5) * 5
			gem.rotation = sin(env_time * 0.8) * 0.1


func _input(event: InputEvent) -> void:
	handle_input(event)


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

	# Center the graphic in the left section
	var parent = zone_graphic_container.get_parent()
	if parent:
		zone_graphic_container.position = Vector2(parent.size.x / 2, parent.size.y / 2)

	match zone_id:
		"ShadowWork":
			_create_shadow_work_graphic()
		"AspectShrine":
			_create_aspect_shrine_graphic()
		"HealingPool":
			_create_healing_pool_graphic()
		"MemoryCave":
			_create_memory_cave_graphic()


func _create_shadow_work_graphic() -> void:
	var scale_factor = 2.5

	# Dark platform
	var platform = Polygon2D.new()
	platform.polygon = PackedVector2Array([
		Vector2(-90, 0), Vector2(0, -50), Vector2(90, 0), Vector2(0, 50)
	])
	platform.scale = Vector2(scale_factor, scale_factor)
	platform.color = Color(0.1, 0.08, 0.15)
	zone_graphic_container.add_child(platform)

	# Mirror frame
	var frame = Polygon2D.new()
	frame.polygon = PackedVector2Array([
		Vector2(-40, 60), Vector2(-40, -60), Vector2(40, -60), Vector2(40, 60)
	])
	frame.position = Vector2(0, -30 * scale_factor)
	frame.scale = Vector2(scale_factor, scale_factor)
	frame.color = Color(0.25, 0.2, 0.35)
	zone_graphic_container.add_child(frame)

	# Mirror glass - dark and mysterious
	var glass = Polygon2D.new()
	glass.polygon = PackedVector2Array([
		Vector2(-32, 52), Vector2(-32, -52), Vector2(32, -52), Vector2(32, 52)
	])
	glass.position = Vector2(0, -30 * scale_factor)
	glass.scale = Vector2(scale_factor, scale_factor)
	glass.color = Color(0.15, 0.1, 0.25, 0.9)
	zone_graphic_container.add_child(glass)

	# Shadow silhouette in mirror
	var shadow = Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-15, 40), Vector2(-12, 0), Vector2(-8, -25),
		Vector2(0, -40), Vector2(8, -25), Vector2(12, 0), Vector2(15, 40)
	])
	shadow.position = Vector2(0, -30 * scale_factor)
	shadow.scale = Vector2(scale_factor, scale_factor)
	shadow.color = Color(0.08, 0.05, 0.12, 0.7)
	zone_graphic_container.add_child(shadow)

	# Mirror glow
	var glow = Polygon2D.new()
	var glow_points = PackedVector2Array()
	for i in range(16):
		var angle = (i / 16.0) * TAU
		glow_points.append(Vector2(cos(angle) * 70, sin(angle) * 90))
	glow.polygon = glow_points
	glow.position = Vector2(0, -30 * scale_factor)
	glow.scale = Vector2(scale_factor, scale_factor)
	glow.color = Color(0.5, 0.3, 0.6, 0.1)
	glow.z_index = -1
	zone_graphic_container.add_child(glow)

	# Candles on sides
	for side in [-1, 1]:
		var candle = Polygon2D.new()
		candle.polygon = PackedVector2Array([
			Vector2(-5, 20), Vector2(-4, -15), Vector2(4, -15), Vector2(5, 20)
		])
		candle.position = Vector2(side * 55 * scale_factor, 10 * scale_factor)
		candle.scale = Vector2(scale_factor, scale_factor)
		candle.color = Color(0.35, 0.3, 0.4)
		zone_graphic_container.add_child(candle)

		var flame = Polygon2D.new()
		flame.polygon = PackedVector2Array([
			Vector2(-6, 5), Vector2(0, -18), Vector2(6, 5)
		])
		flame.position = Vector2(side * 55 * scale_factor, -8 * scale_factor)
		flame.scale = Vector2(scale_factor, scale_factor)
		flame.color = Color(0.6, 0.3, 0.7, 0.9)
		zone_graphic_container.add_child(flame)


func _create_aspect_shrine_graphic() -> void:
	# If we have a current aspect selected, show evolved graphic
	if _current_aspect_for_graphic != "":
		_create_aspect_evolution_graphic(_current_aspect_for_graphic)
		return

	var scale_factor = 2.2

	# Shrine platform (hexagonal)
	var platform = Polygon2D.new()
	var plat_points = PackedVector2Array()
	for i in range(6):
		var angle = (i / 6.0) * TAU - PI/6
		plat_points.append(Vector2(cos(angle) * 80, sin(angle) * 40))
	platform.polygon = plat_points
	platform.scale = Vector2(scale_factor, scale_factor)
	platform.color = Color(0.15, 0.12, 0.22)
	zone_graphic_container.add_child(platform)

	# Central shrine structure
	var shrine = Polygon2D.new()
	shrine.polygon = PackedVector2Array([
		Vector2(-45, 45), Vector2(-45, -25), Vector2(0, -60), Vector2(45, -25), Vector2(45, 45)
	])
	shrine.position = Vector2(0, -20 * scale_factor)
	shrine.scale = Vector2(scale_factor, scale_factor)
	shrine.color = Color(0.35, 0.28, 0.45)
	zone_graphic_container.add_child(shrine)

	# Shrine inner detail
	var inner = Polygon2D.new()
	inner.polygon = PackedVector2Array([
		Vector2(-30, 35), Vector2(-30, -15), Vector2(0, -40), Vector2(30, -15), Vector2(30, 35)
	])
	inner.position = Vector2(0, -20 * scale_factor)
	inner.scale = Vector2(scale_factor, scale_factor)
	inner.color = Color(0.25, 0.2, 0.35)
	zone_graphic_container.add_child(inner)

	# Central flame/orb
	var orb = Polygon2D.new()
	var orb_points = PackedVector2Array()
	for i in range(16):
		var angle = (i / 16.0) * TAU
		orb_points.append(Vector2(cos(angle) * 22, sin(angle) * 22))
	orb.polygon = orb_points
	orb.position = Vector2(0, -45 * scale_factor)
	orb.scale = Vector2(scale_factor, scale_factor)
	orb.color = Color(0.7, 0.5, 0.95, 0.9)
	zone_graphic_container.add_child(orb)

	# Orb inner glow
	var orb_inner = Polygon2D.new()
	var orb_inner_points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		orb_inner_points.append(Vector2(cos(angle) * 12, sin(angle) * 12))
	orb_inner.polygon = orb_inner_points
	orb_inner.position = Vector2(0, -45 * scale_factor)
	orb_inner.scale = Vector2(scale_factor, scale_factor)
	orb_inner.color = Color(0.9, 0.8, 1.0, 0.8)
	zone_graphic_container.add_child(orb_inner)

	# Six aspect symbols around (small gems)
	var aspect_colors = [
		Color(0.83, 0.66, 0.29),  # Discipline
		Color(0.8, 0.3, 0.35),    # Courage
		Color(0.7, 0.5, 0.8),     # Creativity
		Color(0.4, 0.7, 0.5),     # Compassion
		Color(0.3, 0.6, 0.9),     # Wisdom
		Color(0.9, 0.5, 0.3),     # Vitality
	]

	for i in range(6):
		var angle = (i / 6.0) * TAU - PI/2
		var gem = Polygon2D.new()
		gem.polygon = PackedVector2Array([
			Vector2(0, -12), Vector2(8, 0), Vector2(0, 12), Vector2(-8, 0)
		])
		gem.position = Vector2(cos(angle) * 55 * scale_factor, sin(angle) * 28 * scale_factor - 20 * scale_factor)
		gem.scale = Vector2(scale_factor, scale_factor)
		gem.color = aspect_colors[i]
		zone_graphic_container.add_child(gem)

	# Shrine glow
	var glow = Polygon2D.new()
	var glow_points = PackedVector2Array()
	for i in range(20):
		var angle = (i / 20.0) * TAU
		glow_points.append(Vector2(cos(angle) * 100, sin(angle) * 70) * scale_factor)
	glow.polygon = glow_points
	glow.color = Color(0.6, 0.4, 0.8, 0.1)
	glow.z_index = -1
	zone_graphic_container.add_child(glow)


## Create evolved aspect visualization based on level
func _create_aspect_evolution_graphic(aspect_id: String) -> void:
	var scale_factor = 2.5
	var level = 1
	if GameManager:
		level = GameManager.get_aspect_level(aspect_id)

	# Get aspect color
	var aspect_colors = {
		"discipline": Color(0.83, 0.66, 0.29),
		"courage": Color(0.8, 0.3, 0.35),
		"creativity": Color(0.7, 0.5, 0.8),
		"compassion": Color(0.4, 0.7, 0.5),
		"wisdom": Color(0.3, 0.6, 0.9),
		"vitality": Color(0.9, 0.5, 0.3)
	}
	var aspect_color = aspect_colors.get(aspect_id, Color(0.7, 0.5, 0.9))

	# Base platform - darker at higher levels, more mystical
	var platform = Polygon2D.new()
	var plat_points = PackedVector2Array()
	var platform_sides = 6 + min(level / 2, 6)  # More sides at higher levels
	for i in range(platform_sides):
		var angle = (float(i) / platform_sides) * TAU - PI/6
		plat_points.append(Vector2(cos(angle) * 100, sin(angle) * 50))
	platform.polygon = plat_points
	platform.scale = Vector2(scale_factor, scale_factor)
	platform.color = Color(0.12, 0.1, 0.18).lerp(aspect_color.darkened(0.7), min(level * 0.05, 0.3))
	zone_graphic_container.add_child(platform)

	# Evolution rings - more rings at higher levels
	var ring_count = min(level, 5)
	for r in range(ring_count):
		var ring = Polygon2D.new()
		var ring_points = PackedVector2Array()
		var ring_radius = 35 + (r * 18)
		for i in range(24):
			var angle = (float(i) / 24.0) * TAU
			ring_points.append(Vector2(cos(angle) * ring_radius, sin(angle) * ring_radius * 0.5))
		ring.polygon = ring_points
		ring.position = Vector2(0, -10 * scale_factor)
		ring.scale = Vector2(scale_factor, scale_factor)
		ring.color = aspect_color.lightened(0.2)
		ring.color.a = 0.15 + (ring_count - r) * 0.08
		ring.z_index = -1
		zone_graphic_container.add_child(ring)

		# Animate rings at high levels
		if level >= 3:
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(ring, "rotation", TAU, 10.0 + r * 3.0)

	# Central altar structure - grows with level
	var altar_height = 50 + level * 5
	var altar = Polygon2D.new()
	altar.polygon = PackedVector2Array([
		Vector2(-40, 30), Vector2(-40, -altar_height + 30), Vector2(0, -altar_height - 10),
		Vector2(40, -altar_height + 30), Vector2(40, 30)
	])
	altar.position = Vector2(0, -15 * scale_factor)
	altar.scale = Vector2(scale_factor, scale_factor)
	altar.color = Color(0.35, 0.3, 0.45).lerp(aspect_color.darkened(0.4), 0.3)
	zone_graphic_container.add_child(altar)

	# Inner detail
	var inner = Polygon2D.new()
	inner.polygon = PackedVector2Array([
		Vector2(-28, 20), Vector2(-28, -altar_height + 40), Vector2(0, -altar_height),
		Vector2(28, -altar_height + 40), Vector2(28, 20)
	])
	inner.position = Vector2(0, -15 * scale_factor)
	inner.scale = Vector2(scale_factor, scale_factor)
	inner.color = aspect_color.darkened(0.5)
	zone_graphic_container.add_child(inner)

	# Central aspect orb - grows and glows more with level
	var orb_size = 20 + level * 3
	var orb = Polygon2D.new()
	var orb_points = PackedVector2Array()
	for i in range(20):
		var angle = (float(i) / 20.0) * TAU
		orb_points.append(Vector2(cos(angle) * orb_size, sin(angle) * orb_size))
	orb.polygon = orb_points
	orb.position = Vector2(0, (-35 - level * 3) * scale_factor)
	orb.scale = Vector2(scale_factor, scale_factor)
	orb.color = aspect_color
	zone_graphic_container.add_child(orb)

	# Orb glow layers - more intense at higher levels
	for g in range(min(level, 4)):
		var glow = Polygon2D.new()
		var glow_points = PackedVector2Array()
		var glow_size = orb_size + 10 + g * 8
		for i in range(16):
			var angle = (float(i) / 16.0) * TAU
			glow_points.append(Vector2(cos(angle) * glow_size, sin(angle) * glow_size))
		glow.polygon = glow_points
		glow.position = orb.position
		glow.scale = Vector2(scale_factor, scale_factor)
		glow.color = aspect_color.lightened(0.3)
		glow.color.a = 0.2 - g * 0.04
		glow.z_index = -1
		zone_graphic_container.add_child(glow)

		# Pulse animation at level 5+
		if level >= 5:
			var tween = create_tween()
			tween.set_loops()
			var pulse_scale = scale_factor * (1.0 + 0.05 * (g + 1))
			tween.tween_property(glow, "scale", Vector2(pulse_scale, pulse_scale), 1.5 + g * 0.3)
			tween.tween_property(glow, "scale", Vector2(scale_factor, scale_factor), 1.5 + g * 0.3)

	# Inner orb highlight
	var orb_inner = Polygon2D.new()
	var orb_inner_points = PackedVector2Array()
	var inner_size = orb_size * 0.5
	for i in range(12):
		var angle = (float(i) / 12.0) * TAU
		orb_inner_points.append(Vector2(cos(angle) * inner_size, sin(angle) * inner_size))
	orb_inner.polygon = orb_inner_points
	orb_inner.position = orb.position
	orb_inner.scale = Vector2(scale_factor, scale_factor)
	orb_inner.color = Color.WHITE
	orb_inner.color.a = 0.6
	zone_graphic_container.add_child(orb_inner)

	# Evolution particles at level 3+
	if level >= 3:
		var particle_count = min(level * 2, 12)
		for p in range(particle_count):
			var particle = Polygon2D.new()
			var p_points = PackedVector2Array()
			for i in range(4):
				var angle = (float(i) / 4.0) * TAU + PI/4
				p_points.append(Vector2(cos(angle) * 4, sin(angle) * 4))
			particle.polygon = p_points
			var p_angle = (float(p) / particle_count) * TAU
			var p_radius = 60 + randf() * 30
			particle.position = Vector2(
				cos(p_angle) * p_radius * scale_factor,
				sin(p_angle) * p_radius * 0.5 * scale_factor - 35 * scale_factor
			)
			particle.scale = Vector2(scale_factor, scale_factor)
			particle.color = aspect_color.lightened(0.4)
			particle.color.a = 0.5 + randf() * 0.3
			zone_graphic_container.add_child(particle)

			# Float animation
			var tween = create_tween()
			tween.set_loops()
			var float_offset = Vector2(0, -15 * scale_factor)
			var start_pos = particle.position
			tween.tween_property(particle, "position", start_pos + float_offset, 2.0 + randf())
			tween.tween_property(particle, "position", start_pos, 2.0 + randf())

	# Level indicator
	var level_label = Label.new()
	level_label.text = "LV " + str(level)
	level_label.add_theme_font_size_override("font_size", 24)
	level_label.add_theme_color_override("font_color", aspect_color.lightened(0.3))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.position = Vector2(-40, 80 * scale_factor)
	level_label.custom_minimum_size = Vector2(80, 30)
	zone_graphic_container.add_child(level_label)

	# Evolution title at level 7+
	if level >= 7:
		var title_label = Label.new()
		var titles = {
			"discipline": "Master of Will",
			"courage": "Fearless Champion",
			"creativity": "Boundless Visionary",
			"compassion": "Heart of Light",
			"wisdom": "Sage of Ages",
			"vitality": "Eternal Flame"
		}
		title_label.text = titles.get(aspect_id, "Ascended")
		title_label.add_theme_font_size_override("font_size", 14)
		title_label.add_theme_color_override("font_color", aspect_color.lightened(0.5))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.position = Vector2(-80, 105 * scale_factor)
		title_label.custom_minimum_size = Vector2(160, 20)
		zone_graphic_container.add_child(title_label)


func _create_healing_pool_graphic() -> void:
	var scale_factor = 2.2

	# Pool base (dark rock)
	var base = Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-100, 0), Vector2(0, -55), Vector2(100, 0), Vector2(0, 55)
	])
	base.scale = Vector2(scale_factor, scale_factor)
	base.color = Color(0.15, 0.12, 0.2)
	zone_graphic_container.add_child(base)

	# Pool water
	var water = Polygon2D.new()
	water.polygon = PackedVector2Array([
		Vector2(-80, 0), Vector2(0, -45), Vector2(80, 0), Vector2(0, 45)
	])
	water.position = Vector2(0, -5 * scale_factor)
	water.scale = Vector2(scale_factor, scale_factor)
	water.color = Color(0.2, 0.35, 0.55, 0.85)
	zone_graphic_container.add_child(water)

	# Water inner glow
	var water_glow = Polygon2D.new()
	water_glow.polygon = PackedVector2Array([
		Vector2(-60, 0), Vector2(0, -35), Vector2(60, 0), Vector2(0, 35)
	])
	water_glow.position = Vector2(0, -5 * scale_factor)
	water_glow.scale = Vector2(scale_factor, scale_factor)
	water_glow.color = Color(0.3, 0.5, 0.7, 0.4)
	zone_graphic_container.add_child(water_glow)

	# Healing crystals around the pool
	var crystal_positions = [
		{"pos": Vector2(-65, 10), "color": Color(0.4, 0.7, 0.8, 0.9), "height": 35},
		{"pos": Vector2(65, 10), "color": Color(0.5, 0.6, 0.9, 0.9), "height": 30},
		{"pos": Vector2(0, -35), "color": Color(0.45, 0.65, 0.85, 0.9), "height": 25}
	]

	for data in crystal_positions:
		var crystal = Polygon2D.new()
		var h = data.height
		crystal.polygon = PackedVector2Array([
			Vector2(-8, h * 0.7), Vector2(-6, -h * 0.4), Vector2(0, -h),
			Vector2(6, -h * 0.4), Vector2(8, h * 0.7)
		])
		crystal.position = data.pos * scale_factor
		crystal.scale = Vector2(scale_factor, scale_factor)
		crystal.color = data.color
		zone_graphic_container.add_child(crystal)

		# Crystal glow
		var glow = Polygon2D.new()
		var glow_points = PackedVector2Array()
		for i in range(8):
			var angle = (i / 8.0) * TAU
			glow_points.append(Vector2(cos(angle) * 15, sin(angle) * 20))
		glow.polygon = glow_points
		glow.position = data.pos * scale_factor + Vector2(0, -h * 0.3 * scale_factor)
		glow.scale = Vector2(scale_factor, scale_factor)
		glow.color = Color(data.color.r, data.color.g, data.color.b, 0.2)
		glow.z_index = -1
		zone_graphic_container.add_child(glow)

	# Lotus flowers on water
	for i in [-1, 1]:
		var lotus = Polygon2D.new()
		lotus.polygon = PackedVector2Array([
			Vector2(-10, 0), Vector2(-6, -14), Vector2(0, -18),
			Vector2(6, -14), Vector2(10, 0), Vector2(6, 5), Vector2(-6, 5)
		])
		lotus.position = Vector2(i * 30 * scale_factor, 5 * scale_factor)
		lotus.scale = Vector2(scale_factor, scale_factor)
		lotus.color = Color(0.8, 0.5, 0.7, 0.9) if i < 0 else Color(0.7, 0.5, 0.8, 0.9)
		zone_graphic_container.add_child(lotus)

	# Pool outer glow
	var pool_glow = Polygon2D.new()
	var glow_points = PackedVector2Array()
	for i in range(20):
		var angle = (i / 20.0) * TAU
		glow_points.append(Vector2(cos(angle) * 120, sin(angle) * 70))
	pool_glow.polygon = glow_points
	pool_glow.scale = Vector2(scale_factor, scale_factor)
	pool_glow.color = Color(0.3, 0.5, 0.7, 0.08)
	pool_glow.z_index = -1
	zone_graphic_container.add_child(pool_glow)


func _create_memory_cave_graphic() -> void:
	var scale_factor = 2.2

	# Cave base
	var base = Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-90, 0), Vector2(0, -50), Vector2(90, 0), Vector2(0, 50)
	])
	base.scale = Vector2(scale_factor, scale_factor)
	base.color = Color(0.12, 0.1, 0.15)
	zone_graphic_container.add_child(base)

	# Cave entrance (dark arch)
	var entrance = Polygon2D.new()
	entrance.polygon = PackedVector2Array([
		Vector2(-55, 40), Vector2(-55, -10), Vector2(-40, -50),
		Vector2(0, -65), Vector2(40, -50), Vector2(55, -10), Vector2(55, 40)
	])
	entrance.position = Vector2(0, -30 * scale_factor)
	entrance.scale = Vector2(scale_factor, scale_factor)
	entrance.color = Color(0.08, 0.06, 0.12)
	zone_graphic_container.add_child(entrance)

	# Cave interior (deeper dark)
	var interior = Polygon2D.new()
	interior.polygon = PackedVector2Array([
		Vector2(-40, 30), Vector2(-40, -5), Vector2(-30, -35),
		Vector2(0, -50), Vector2(30, -35), Vector2(40, -5), Vector2(40, 30)
	])
	interior.position = Vector2(0, -30 * scale_factor)
	interior.scale = Vector2(scale_factor, scale_factor)
	interior.color = Color(0.05, 0.04, 0.08)
	zone_graphic_container.add_child(interior)

	# Stalactites
	var stalactite_data = [
		{"pos": Vector2(-30, -65), "len": 25},
		{"pos": Vector2(30, -60), "len": 20},
		{"pos": Vector2(0, -70), "len": 15}
	]
	for data in stalactite_data:
		var stal = Polygon2D.new()
		stal.polygon = PackedVector2Array([
			Vector2(-6, 0), Vector2(0, data.len), Vector2(6, 0)
		])
		stal.position = data.pos * scale_factor
		stal.scale = Vector2(scale_factor, scale_factor)
		stal.color = Color(0.2, 0.18, 0.25)
		zone_graphic_container.add_child(stal)

	# Glowing memory orbs inside cave
	var orb_data = [
		{"pos": Vector2(-25, -20), "color": Color(0.6, 0.4, 0.8, 0.6), "size": 8},
		{"pos": Vector2(25, -25), "color": Color(0.5, 0.5, 0.9, 0.6), "size": 6},
		{"pos": Vector2(0, -40), "color": Color(0.7, 0.3, 0.7, 0.6), "size": 5}
	]
	for data in orb_data:
		var orb = Polygon2D.new()
		var orb_points = PackedVector2Array()
		for i in range(8):
			var angle = (i / 8.0) * TAU
			orb_points.append(Vector2(cos(angle) * data.size, sin(angle) * data.size))
		orb.polygon = orb_points
		orb.position = data.pos * scale_factor
		orb.scale = Vector2(scale_factor, scale_factor)
		orb.color = data.color
		zone_graphic_container.add_child(orb)

		# Orb glow
		var glow = Polygon2D.new()
		var glow_points = PackedVector2Array()
		for i in range(8):
			var angle = (i / 8.0) * TAU
			glow_points.append(Vector2(cos(angle) * data.size * 2, sin(angle) * data.size * 2))
		glow.polygon = glow_points
		glow.position = data.pos * scale_factor
		glow.scale = Vector2(scale_factor, scale_factor)
		glow.color = Color(data.color.r, data.color.g, data.color.b, 0.15)
		glow.z_index = -1
		zone_graphic_container.add_child(glow)

	# Central memory crystal
	var crystal = Polygon2D.new()
	crystal.polygon = PackedVector2Array([
		Vector2(-12, 15), Vector2(-8, -10), Vector2(0, -25),
		Vector2(8, -10), Vector2(12, 15)
	])
	crystal.position = Vector2(0, -10 * scale_factor)
	crystal.scale = Vector2(scale_factor, scale_factor)
	crystal.color = Color(0.5, 0.4, 0.7, 0.85)
	zone_graphic_container.add_child(crystal)

	# Crystal glow
	var crystal_glow = Polygon2D.new()
	var glow_points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		glow_points.append(Vector2(cos(angle) * 25, sin(angle) * 30))
	crystal_glow.polygon = glow_points
	crystal_glow.position = Vector2(0, -15 * scale_factor)
	crystal_glow.scale = Vector2(scale_factor, scale_factor)
	crystal_glow.color = Color(0.5, 0.4, 0.7, 0.15)
	crystal_glow.z_index = -1
	zone_graphic_container.add_child(crystal_glow)


func _close_zone() -> void:
	_clear_zone_graphics()
	super._close_zone()


func _open_zone(zone_id: String) -> void:
	match zone_id:
		"ShadowWork":
			_open_shadow_work()
		"AspectShrine":
			_open_aspect_shrine()
		"HealingPool":
			_open_healing_pool()
		"MemoryCave":
			_open_memory_cave()
		_:
			super._open_zone(zone_id)


func _open_shadow_work() -> void:
	zone_title.text = "Shadow Work"
	_clear_zone_body()
	_setup_zone_graphic("ShadowWork")

	_add_spacer(10)

	var intro = Label.new()
	intro.text = "Face your inner shadows - fears, doubts, and limiting beliefs. Transform them into sources of strength."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(intro)

	_add_spacer(15)

	# Show shadow work progress
	var shadows = _load_shadows()
	var confronted = shadows.filter(func(s): return s.get("confronted", false)).size()

	if shadows.size() > 0:
		var progress_label = Label.new()
		progress_label.text = "Shadows confronted: " + str(confronted) + "/" + str(shadows.size())
		progress_label.add_theme_font_size_override("font_size", 16)
		progress_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.6))
		zone_body.add_child(progress_label)

		_add_spacer(10)

	# Main actions
	var identify_btn = Button.new()
	identify_btn.text = "Identify a Shadow"
	identify_btn.custom_minimum_size = Vector2(0, 50)
	identify_btn.add_theme_font_size_override("font_size", 18)
	identify_btn.pressed.connect(_identify_shadow)
	zone_body.add_child(identify_btn)

	_add_spacer(8)

	var confront_btn = Button.new()
	confront_btn.text = "Confront Your Shadows"
	confront_btn.custom_minimum_size = Vector2(0, 50)
	confront_btn.add_theme_font_size_override("font_size", 18)
	confront_btn.pressed.connect(_confront_shadows_list)
	zone_body.add_child(confront_btn)

	_add_spacer(8)

	var reframe_btn = Button.new()
	reframe_btn.text = "Practice Reframing"
	reframe_btn.custom_minimum_size = Vector2(0, 50)
	reframe_btn.add_theme_font_size_override("font_size", 18)
	reframe_btn.pressed.connect(_practice_reframing)
	zone_body.add_child(reframe_btn)

	zone_panel.visible = true
	in_zone_panel = true


func _open_aspect_shrine() -> void:
	zone_title.text = "Aspect Shrine"
	_clear_zone_body()
	_current_aspect_for_graphic = ""  # Clear to show default shrine graphic
	_setup_zone_graphic("AspectShrine")

	_add_spacer(10)

	var intro = Label.new()
	intro.text = "Commune with your awakened aspects. Each represents a facet of your growth."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(intro)

	_add_spacer(12)

	var aspects_data = _get_aspects_display_data()

	for aspect in aspects_data:
		var aspect_row = HBoxContainer.new()
		aspect_row.add_theme_constant_override("separation", 10)

		# Aspect evolution indicator (grows with level)
		var indicator_size = 8 + min(aspect.level, 10) * 2
		var indicator = Polygon2D.new()
		var ind_points = PackedVector2Array()
		for i in range(6):
			var angle = (float(i) / 6.0) * TAU - PI/2
			ind_points.append(Vector2(cos(angle) * indicator_size / 2, sin(angle) * indicator_size / 2))
		indicator.polygon = ind_points
		indicator.color = aspect.color
		var ind_container = Control.new()
		ind_container.custom_minimum_size = Vector2(30, 55)
		indicator.position = Vector2(15, 27)
		ind_container.add_child(indicator)

		# Add glow at level 5+
		if aspect.level >= 5:
			var glow = Polygon2D.new()
			var glow_points = PackedVector2Array()
			for i in range(6):
				var angle = (float(i) / 6.0) * TAU - PI/2
				glow_points.append(Vector2(cos(angle) * (indicator_size + 6) / 2, sin(angle) * (indicator_size + 6) / 2))
			glow.polygon = glow_points
			glow.color = aspect.color
			glow.color.a = 0.3
			glow.position = Vector2(15, 27)
			glow.z_index = -1
			ind_container.add_child(glow)

		aspect_row.add_child(ind_container)

		# Name, level, and XP progress
		var info_col = VBoxContainer.new()
		info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_col.add_theme_constant_override("separation", 2)

		# Name with evolution tier
		var name_row = HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 8)

		var name_label = Label.new()
		name_label.text = aspect.name
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", aspect.color)
		name_row.add_child(name_label)

		# Evolution tier badge
		var tier = _get_evolution_tier(aspect.level)
		if tier.name != "":
			var tier_badge = Label.new()
			tier_badge.text = tier.name
			tier_badge.add_theme_font_size_override("font_size", 11)
			tier_badge.add_theme_color_override("font_color", tier.color)
			name_row.add_child(tier_badge)

		info_col.add_child(name_row)

		# Level with XP progress
		var level_row = HBoxContainer.new()
		level_row.add_theme_constant_override("separation", 8)

		var level_label = Label.new()
		level_label.text = "Lv " + str(aspect.level)
		level_label.add_theme_font_size_override("font_size", 14)
		level_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		level_row.add_child(level_label)

		# XP progress bar
		var xp_progress = _get_aspect_xp_progress(aspect.id)
		var progress_bg = ColorRect.new()
		progress_bg.custom_minimum_size = Vector2(80, 8)
		progress_bg.color = Color(0.2, 0.2, 0.25)
		level_row.add_child(progress_bg)

		var progress_fill = ColorRect.new()
		progress_fill.custom_minimum_size = Vector2(80 * xp_progress, 8)
		progress_fill.color = aspect.color.darkened(0.2)
		progress_fill.position = Vector2(0, 0)
		progress_bg.add_child(progress_fill)

		info_col.add_child(level_row)

		aspect_row.add_child(info_col)

		# Talk button
		var talk_btn = Button.new()
		talk_btn.text = "Commune"
		talk_btn.custom_minimum_size = Vector2(100, 40)
		talk_btn.add_theme_font_size_override("font_size", 16)
		talk_btn.pressed.connect(_commune_with_aspect.bind(aspect.id))
		aspect_row.add_child(talk_btn)

		zone_body.add_child(aspect_row)
		_add_spacer(6)

	_add_spacer(20)

	# Kindness & Contribution Log section
	var kindness_header = Label.new()
	kindness_header.text = "Acts of Kindness"
	kindness_header.add_theme_color_override("font_color", Color(0.4, 0.7, 0.5))
	kindness_header.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(kindness_header)

	var kindness_desc = Label.new()
	kindness_desc.text = "Track moments of kindness and contribution. Each act strengthens your Compassion."
	kindness_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	kindness_desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	zone_body.add_child(kindness_desc)

	_add_spacer(8)

	var kindness_button = Button.new()
	kindness_button.text = "Open Kindness Log"
	kindness_button.custom_minimum_size = Vector2(0, 45)
	kindness_button.add_theme_font_size_override("font_size", 16)
	kindness_button.pressed.connect(_open_kindness_log)
	zone_body.add_child(kindness_button)

	zone_panel.visible = true
	in_zone_panel = true


func _open_healing_pool() -> void:
	zone_title.text = "Healing Pool"
	_clear_zone_body()
	_setup_zone_graphic("HealingPool")

	_add_spacer(10)

	var intro = Label.new()
	intro.text = "A tranquil pool infused with healing crystals. Rest here to restore your inner balance and practice mindful breathing."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(intro)

	_add_spacer(15)

	# Show meditation stats
	var meditation_count = AchievementManager.stats.get("meditations_completed", 0) if AchievementManager else 0
	if meditation_count > 0:
		var stats_label = Label.new()
		stats_label.text = "Meditations completed: " + str(meditation_count)
		stats_label.add_theme_font_size_override("font_size", 16)
		stats_label.add_theme_color_override("font_color", Color(0.4, 0.6, 0.7))
		zone_body.add_child(stats_label)
		_add_spacer(10)

	# Quick breathing exercise
	var breathe_btn = Button.new()
	breathe_btn.text = "Breathing Exercise (2 min)"
	breathe_btn.custom_minimum_size = Vector2(0, 50)
	breathe_btn.add_theme_font_size_override("font_size", 18)
	breathe_btn.pressed.connect(_start_breathing_exercise.bind(2))
	zone_body.add_child(breathe_btn)

	_add_spacer(8)

	# Medium meditation
	var meditate_btn = Button.new()
	meditate_btn.text = "Calm Mind Meditation (5 min)"
	meditate_btn.custom_minimum_size = Vector2(0, 50)
	meditate_btn.add_theme_font_size_override("font_size", 18)
	meditate_btn.pressed.connect(_start_breathing_exercise.bind(5))
	zone_body.add_child(meditate_btn)

	_add_spacer(8)

	# Deep meditation
	var deep_btn = Button.new()
	deep_btn.text = "Deep Healing Session (10 min)"
	deep_btn.custom_minimum_size = Vector2(0, 50)
	deep_btn.add_theme_font_size_override("font_size", 18)
	deep_btn.pressed.connect(_start_breathing_exercise.bind(10))
	zone_body.add_child(deep_btn)

	_add_spacer(15)

	# Affirmation practice
	var affirm_btn = Button.new()
	affirm_btn.text = "Pool Affirmations"
	affirm_btn.custom_minimum_size = Vector2(0, 45)
	affirm_btn.add_theme_font_size_override("font_size", 16)
	affirm_btn.pressed.connect(_show_pool_affirmations)
	zone_body.add_child(affirm_btn)

	zone_panel.visible = true
	in_zone_panel = true


func _start_breathing_exercise(duration_minutes: int) -> void:
	_clear_zone_body()
	_setup_zone_graphic("HealingPool")

	var exercise_container = VBoxContainer.new()
	exercise_container.add_theme_constant_override("separation", 20)
	zone_body.add_child(exercise_container)

	var title = Label.new()
	title.text = "Breathing Exercise"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.5, 0.7, 0.8))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exercise_container.add_child(title)

	var instruction = Label.new()
	instruction.text = "Breathe with the rhythm..."
	instruction.add_theme_font_size_override("font_size", 18)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exercise_container.add_child(instruction)

	# Breathing indicator
	var breath_indicator = Label.new()
	breath_indicator.name = "BreathIndicator"
	breath_indicator.text = "INHALE"
	breath_indicator.add_theme_font_size_override("font_size", 36)
	breath_indicator.add_theme_color_override("font_color", Color(0.4, 0.7, 0.9))
	breath_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exercise_container.add_child(breath_indicator)

	# Timer display
	var timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.text = str(duration_minutes) + ":00"
	timer_label.add_theme_font_size_override("font_size", 20)
	timer_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exercise_container.add_child(timer_label)

	_add_spacer(20)

	var stop_btn = Button.new()
	stop_btn.text = "End Session"
	stop_btn.custom_minimum_size = Vector2(0, 45)
	stop_btn.add_theme_font_size_override("font_size", 16)
	stop_btn.pressed.connect(_end_breathing_session.bind(duration_minutes))
	zone_body.add_child(stop_btn)

	# Start the breathing cycle
	_run_breathing_cycle(breath_indicator, timer_label, duration_minutes * 60)


func _run_breathing_cycle(indicator: Label, timer_label: Label, total_seconds: int) -> void:
	var cycle_duration = 8.0  # 4s inhale, 4s exhale
	var remaining = total_seconds

	while remaining > 0 and is_instance_valid(indicator):
		# Inhale phase
		indicator.text = "INHALE"
		indicator.add_theme_color_override("font_color", Color(0.4, 0.8, 0.9))

		for i in range(40):  # 4 seconds
			if not is_instance_valid(indicator):
				return
			await get_tree().create_timer(0.1).timeout
			remaining -= 0.1
			if remaining <= 0:
				break
			var mins = int(remaining) / 60
			var secs = int(remaining) % 60
			if is_instance_valid(timer_label):
				timer_label.text = "%d:%02d" % [mins, secs]

		if remaining <= 0 or not is_instance_valid(indicator):
			break

		# Exhale phase
		indicator.text = "EXHALE"
		indicator.add_theme_color_override("font_color", Color(0.6, 0.5, 0.8))

		for i in range(40):  # 4 seconds
			if not is_instance_valid(indicator):
				return
			await get_tree().create_timer(0.1).timeout
			remaining -= 0.1
			if remaining <= 0:
				break
			var mins = int(remaining) / 60
			var secs = int(remaining) % 60
			if is_instance_valid(timer_label):
				timer_label.text = "%d:%02d" % [mins, secs]

	# Session complete
	if is_instance_valid(indicator):
		_end_breathing_session(total_seconds / 60)


func _end_breathing_session(duration_minutes: int) -> void:
	# Award XP for meditation
	if AchievementManager:
		AchievementManager.record_meditation()

	if GameManager:
		var xp_amount = duration_minutes * 3
		GameManager.add_aspect_experience("wisdom", xp_amount)
		# Track for aspect quests
		GameManager.check_quests_for_trigger("meditation_completed", {})

	_close_zone()

	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_ui_sound"):
		audio.play_ui_sound("complete")

	show_dialogue("Session Complete", "You completed a %d-minute meditation session.\n\n+%d Wisdom XP" % [duration_minutes, duration_minutes * 3])


func _show_pool_affirmations() -> void:
	_clear_zone_body()
	_setup_zone_graphic("HealingPool")

	var affirmations = [
		"I am at peace with myself and the universe.",
		"My mind is calm, my heart is open.",
		"I release what no longer serves me.",
		"I am worthy of love, healing, and growth.",
		"Each breath brings me closer to inner peace.",
		"I trust the journey, even when the path is unclear.",
		"I am resilient, I am whole, I am enough."
	]

	var title = Label.new()
	title.text = "Pool Affirmations"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.5, 0.7, 0.8))
	zone_body.add_child(title)

	_add_spacer(15)

	var random_affirmation = affirmations[randi() % affirmations.size()]

	var affirmation_label = Label.new()
	affirmation_label.text = '"' + random_affirmation + '"'
	affirmation_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	affirmation_label.add_theme_font_size_override("font_size", 20)
	affirmation_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	zone_body.add_child(affirmation_label)

	_add_spacer(20)

	var another_btn = Button.new()
	another_btn.text = "Another Affirmation"
	another_btn.custom_minimum_size = Vector2(0, 45)
	another_btn.add_theme_font_size_override("font_size", 16)
	another_btn.pressed.connect(_show_pool_affirmations)
	zone_body.add_child(another_btn)

	_add_spacer(10)

	var back_btn = Button.new()
	back_btn.text = "Back to Pool"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_open_healing_pool)
	zone_body.add_child(back_btn)


func _open_memory_cave() -> void:
	zone_title.text = "Memory Cave"
	_clear_zone_body()
	_setup_zone_graphic("MemoryCave")

	_add_spacer(10)

	var intro = Label.new()
	intro.text = "Ancient memories shimmer in the crystal walls. Review your journey and see how far you've come."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(intro)

	_add_spacer(15)

	# Journey stats
	var stats_title = Label.new()
	stats_title.text = "Your Journey So Far"
	stats_title.add_theme_font_size_override("font_size", 20)
	stats_title.add_theme_color_override("font_color", Color(0.6, 0.5, 0.8))
	zone_body.add_child(stats_title)

	_add_spacer(10)

	# Gather stats
	var stats_data = _gather_journey_stats()
	for stat in stats_data:
		var stat_row = HBoxContainer.new()
		stat_row.add_theme_constant_override("separation", 10)

		var icon_label = Label.new()
		icon_label.text = stat.icon
		icon_label.add_theme_font_size_override("font_size", 20)
		stat_row.add_child(icon_label)

		var stat_label = Label.new()
		stat_label.text = stat.label + ": " + str(stat.value)
		stat_label.add_theme_font_size_override("font_size", 16)
		stat_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		stat_row.add_child(stat_label)

		zone_body.add_child(stat_row)
		_add_spacer(4)

	_add_spacer(15)

	# View shadow work history
	var shadow_btn = Button.new()
	shadow_btn.text = "Review Shadow Work History"
	shadow_btn.custom_minimum_size = Vector2(0, 45)
	shadow_btn.add_theme_font_size_override("font_size", 16)
	shadow_btn.pressed.connect(_view_shadow_history)
	zone_body.add_child(shadow_btn)

	_add_spacer(8)

	# View kindness history
	var kindness_btn = Button.new()
	kindness_btn.text = "Review Kindness Log"
	kindness_btn.custom_minimum_size = Vector2(0, 45)
	kindness_btn.add_theme_font_size_override("font_size", 16)
	kindness_btn.pressed.connect(_show_kindness_history)
	zone_body.add_child(kindness_btn)

	_add_spacer(8)

	# View achievements
	var achievements_btn = Button.new()
	achievements_btn.text = "Review Achievements"
	achievements_btn.custom_minimum_size = Vector2(0, 45)
	achievements_btn.add_theme_font_size_override("font_size", 16)
	achievements_btn.pressed.connect(_show_memory_achievements)
	zone_body.add_child(achievements_btn)

	zone_panel.visible = true
	in_zone_panel = true


func _gather_journey_stats() -> Array:
	var stats = []

	# Days played
	var days = AchievementManager.stats.get("days_played", 0) if AchievementManager else 0
	stats.append({"icon": "📅", "label": "Days on journey", "value": days})

	# Focus sessions
	var focus_sessions = AchievementManager.stats.get("focus_sessions", 0) if AchievementManager else 0
	stats.append({"icon": "🎯", "label": "Focus sessions", "value": focus_sessions})

	# Habits completed
	var habits = AchievementManager.stats.get("habits_completed", 0) if AchievementManager else 0
	stats.append({"icon": "✅", "label": "Habits completed", "value": habits})

	# Best streak
	var streak = AchievementManager.stats.get("best_streak", 0) if AchievementManager else 0
	stats.append({"icon": "🔥", "label": "Best streak", "value": str(streak) + " days"})

	# Meditations
	var meditations = AchievementManager.stats.get("meditations_completed", 0) if AchievementManager else 0
	stats.append({"icon": "🧘", "label": "Meditations", "value": meditations})

	# Kindness acts
	var kindness = AchievementManager.stats.get("kindness_acts", 0) if AchievementManager else 0
	stats.append({"icon": "💝", "label": "Acts of kindness", "value": kindness})

	# Total XP
	var xp = AchievementManager.stats.get("total_xp_earned", 0) if AchievementManager else 0
	stats.append({"icon": "✨", "label": "Total XP earned", "value": xp})

	return stats


func _view_shadow_history() -> void:
	_clear_zone_body()
	_setup_zone_graphic("MemoryCave")

	var title = Label.new()
	title.text = "Shadow Work History"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.5, 0.4, 0.6))
	zone_body.add_child(title)

	_add_spacer(10)

	var shadows = _load_shadows()
	if shadows.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No shadows have been confronted yet.\n\nVisit the Shadow Work zone to begin your inner journey."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		zone_body.add_child(empty_label)
	else:
		var confronted = shadows.filter(func(s): return s.get("confronted", false))
		for shadow in confronted.slice(0, 5):
			var shadow_card = PanelContainer.new()
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.12, 0.1, 0.15)
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			shadow_card.add_theme_stylebox_override("panel", style)

			var margin = MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 12)
			margin.add_theme_constant_override("margin_right", 12)
			margin.add_theme_constant_override("margin_top", 8)
			margin.add_theme_constant_override("margin_bottom", 8)
			shadow_card.add_child(margin)

			var vbox = VBoxContainer.new()
			margin.add_child(vbox)

			var name_label = Label.new()
			name_label.text = shadow.get("name", "Unknown Shadow")
			name_label.add_theme_font_size_override("font_size", 16)
			name_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))
			vbox.add_child(name_label)

			if shadow.has("reframe") and shadow.reframe != "":
				var reframe_label = Label.new()
				reframe_label.text = "Reframed: " + shadow.reframe
				reframe_label.autowrap_mode = TextServer.AUTOWRAP_WORD
				reframe_label.add_theme_font_size_override("font_size", 14)
				reframe_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
				vbox.add_child(reframe_label)

			zone_body.add_child(shadow_card)
			_add_spacer(6)

	_add_spacer(15)

	var back_btn = Button.new()
	back_btn.text = "Back to Memory Cave"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_open_memory_cave)
	zone_body.add_child(back_btn)


func _show_memory_achievements() -> void:
	_clear_zone_body()
	_setup_zone_graphic("MemoryCave")

	var title = Label.new()
	title.text = "Achievement Memories"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.6, 0.5, 0.8))
	zone_body.add_child(title)

	_add_spacer(10)

	if not AchievementManager:
		var error_label = Label.new()
		error_label.text = "Achievement system not available."
		zone_body.add_child(error_label)
	else:
		var unlocked = AchievementManager.get_unlocked_achievements()
		var total = AchievementManager.ACHIEVEMENTS.size()

		var progress_label = Label.new()
		progress_label.text = "Achievements unlocked: %d/%d (%d%%)" % [unlocked.size(), total, int(AchievementManager.get_unlock_percentage() * 100)]
		progress_label.add_theme_font_size_override("font_size", 16)
		progress_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		zone_body.add_child(progress_label)

		_add_spacer(10)

		# Show recent achievements
		var recent = AchievementManager.get_recent_achievements(5)
		if recent.is_empty():
			var empty_label = Label.new()
			empty_label.text = "No achievements unlocked yet. Keep exploring and growing!"
			empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			empty_label.add_theme_font_size_override("font_size", 16)
			empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
			zone_body.add_child(empty_label)
		else:
			var recent_title = Label.new()
			recent_title.text = "Recent Achievements:"
			recent_title.add_theme_font_size_override("font_size", 18)
			zone_body.add_child(recent_title)
			_add_spacer(8)

			for achievement in recent:
				var ach_row = HBoxContainer.new()
				ach_row.add_theme_constant_override("separation", 10)

				var icon = Label.new()
				icon.text = achievement.get("icon", "🏆")
				icon.add_theme_font_size_override("font_size", 24)
				ach_row.add_child(icon)

				var info = VBoxContainer.new()
				var name_label = Label.new()
				name_label.text = achievement.get("name", "Achievement")
				name_label.add_theme_font_size_override("font_size", 16)
				name_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6))
				info.add_child(name_label)

				var desc_label = Label.new()
				desc_label.text = achievement.get("description", "")
				desc_label.add_theme_font_size_override("font_size", 14)
				desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
				info.add_child(desc_label)

				ach_row.add_child(info)
				zone_body.add_child(ach_row)
				_add_spacer(6)

	_add_spacer(15)

	var back_btn = Button.new()
	back_btn.text = "Back to Memory Cave"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_open_memory_cave)
	zone_body.add_child(back_btn)


func _get_aspects_display_data() -> Array:
	var aspect_info = {
		"discipline": {"name": "Discipline", "color": Color(0.83, 0.66, 0.29)},
		"courage": {"name": "Courage", "color": Color(0.8, 0.3, 0.35)},
		"creativity": {"name": "Creativity", "color": Color(0.7, 0.5, 0.8)},
		"compassion": {"name": "Compassion", "color": Color(0.4, 0.7, 0.5)},
		"wisdom": {"name": "Wisdom", "color": Color(0.3, 0.6, 0.9)},
		"vitality": {"name": "Vitality", "color": Color(0.9, 0.5, 0.3)}
	}

	var result = []
	var aspects = GameManager.player_data.get("aspects", {})

	for aspect_id in ["discipline", "courage", "creativity", "compassion", "wisdom", "vitality"]:
		if aspects.has(aspect_id):
			var info = aspect_info.get(aspect_id, {})
			result.append({
				"id": aspect_id,
				"name": info.get("name", aspect_id.capitalize()),
				"color": info.get("color", Color.WHITE),
				"level": aspects[aspect_id].get("level", 1),
				"experience": aspects[aspect_id].get("experience", 0)
			})

	return result


func _commune_with_aspect(aspect_id: String) -> void:
	_close_zone()

	# Record the interaction for bond tracking
	if GameManager:
		GameManager.record_aspect_interaction(aspect_id, "communion")

	var dialogue = _get_aspect_dialogue(aspect_id)
	var aspect_names = {
		"discipline": "Discipline",
		"courage": "Courage",
		"creativity": "Creativity",
		"compassion": "Compassion",
		"wisdom": "Wisdom",
		"vitality": "Vitality"
	}

	var name = aspect_names.get(aspect_id, "Aspect")
	_show_dialogue(name, dialogue, _show_aspect_options.bind(aspect_id))


func _get_aspect_dialogue(aspect_id: String) -> String:
	var level = GameManager.get_aspect_level(aspect_id)
	var greetings = _get_aspect_greetings()

	if greetings.has(aspect_id):
		var aspect_greetings = greetings[aspect_id]
		if level >= 5 and aspect_greetings.has("high"):
			return aspect_greetings.high[randi() % aspect_greetings.high.size()]
		elif level >= 3 and aspect_greetings.has("mid"):
			return aspect_greetings.mid[randi() % aspect_greetings.mid.size()]
		else:
			return aspect_greetings.low[randi() % aspect_greetings.low.size()]

	return "I sense your presence, traveler."


func _get_aspect_greetings() -> Dictionary:
	return {
		"discipline": {
			"low": [
				"Ah, you've come. Good. Consistency is the foundation of all achievement.\n\nWhat brings you to the shrine today?",
				"Welcome. I am Discipline - the steady flame that burns when motivation fades.\n\nHow may I guide you?",
				"You seek structure? Purpose? I can help you find both.\n\nLet us talk."
			],
			"mid": [
				"Your commitment grows stronger each day. I can feel it.\n\nWhat wisdom do you seek?",
				"The habits you've built are taking root. Well done.\n\nHow can I help you continue?"
			],
			"high": [
				"Your discipline rivals my own. You have become a master of consistency.\n\nWhat more would you learn?",
				"We are kindred spirits now. Your dedication honors the path.\n\nSpeak, and I shall answer."
			]
		},
		"courage": {
			"low": [
				"Fear is not your enemy - it is your compass.\n\nWhat challenge weighs on your heart?",
				"You come seeking bravery? Know this: courage is not the absence of fear, but action despite it.\n\nTell me your struggles.",
				"I am Courage. I light the way through darkness.\n\nWhat shadows do you face?"
			],
			"mid": [
				"You've faced fears that once seemed insurmountable. I am proud.\n\nWhat new frontier calls to you?",
				"Your heart grows stronger. The fears that once ruled you now bow.\n\nHow may I serve?"
			],
			"high": [
				"You have become a warrior of the spirit. Fear flees before you.\n\nWhat wisdom can I share with one so brave?",
				"Together we have conquered much. Your courage inspires even me.\n\nSpeak freely, champion."
			]
		},
		"creativity": {
			"low": [
				"Ooh, a visitor! How delightful! I'm Creativity - or as I like to say, the spark that makes sparks!\n\nWhat shall we imagine today?",
				"Hello, hello! Ready to think outside the box? Actually, let's throw the box away entirely!\n\nWhat's on your mind?",
				"Welcome to the realm of possibilities! Here, every idea is a seed waiting to bloom.\n\nWhat would you like to create?"
			],
			"mid": [
				"Your ideas are blooming beautifully! I can see the colors of your imagination growing brighter.\n\nWhat new creation calls to you?",
				"You've been experimenting! I love it! The best ideas come from play.\n\nWhat shall we explore?"
			],
			"high": [
				"Oh my, look at you! A true artist of life! Your creativity knows no bounds now.\n\nTeach me something new!",
				"We've made magic together, you and I. Your imagination is a wonder.\n\nWhat masterpiece shall we dream up next?"
			]
		},
		"compassion": {
			"low": [
				"Come, sit with me. I am Compassion, and I see the kindness within you.\n\nHow do you care for yourself and others?",
				"Welcome, gentle soul. The heart that seeks to understand is the heart that grows.\n\nWhat troubles you?",
				"I feel your presence - warm, seeking connection. That is beautiful.\n\nHow may I help you nurture your relationships?"
			],
			"mid": [
				"Your heart has opened so much since we first met. The love you give returns to you.\n\nHow are you feeling today?",
				"You've learned to be kinder - to others and to yourself. I'm touched.\n\nWhat would you like to discuss?"
			],
			"high": [
				"You have become a beacon of empathy. Others are drawn to your warmth.\n\nI am honored to commune with you.",
				"Your compassion ripples outward, touching lives you may never know. You are love embodied.\n\nHow may I serve such a kind heart?"
			]
		},
		"wisdom": {
			"low": [
				"Hmm. You seek understanding. A worthy pursuit.\n\nWisdom begins with the admission that we know little. What questions do you carry?",
				"I am Wisdom. I do not give answers - I help you find them within yourself.\n\nWhat do you wish to understand?",
				"Welcome, seeker. The examined life is the life worth living.\n\nWhat reflection brings you here?"
			],
			"mid": [
				"Your understanding deepens. You ask better questions now than when we first met.\n\nWhat paradox puzzles you today?",
				"I see clarity forming where confusion once lived. You're learning to think clearly.\n\nShare your thoughts."
			],
			"high": [
				"You have become a philosopher in your own right. Your insights rival ancient sages.\n\nWhat wisdom would you share with me?",
				"The student has become the teacher. Your clarity of thought is remarkable.\n\nI listen with great interest."
			]
		},
		"vitality": {
			"low": [
				"Hey! Welcome! I'm Vitality - your body's best friend!\n\nHow are you treating that amazing vessel of yours?",
				"Energy! Movement! Life! That's what I'm all about!\n\nHow can we get you feeling more alive today?",
				"Your body is a temple, a machine, a miracle all in one!\n\nLet's talk about taking care of it!"
			],
			"mid": [
				"I can see you've been taking better care of yourself! Your energy is vibrant!\n\nWhat healthy habit shall we celebrate?",
				"Movement and rest, fuel and recovery - you're finding the balance!\n\nHow do you feel?"
			],
			"high": [
				"Wow! Look at you! You're practically glowing with health and energy!\n\nYou've become a master of vitality!",
				"Your body and mind work in perfect harmony now. You're an inspiration!\n\nWhat secrets of wellness shall we discuss?"
			]
		}
	}


func _show_aspect_options(aspect_id: String) -> void:
	_close_dialogue()
	zone_title.text = _get_aspect_name(aspect_id)
	_clear_zone_body()
	_current_aspect_for_graphic = aspect_id  # Show evolved aspect graphic
	_setup_zone_graphic("AspectShrine")

	_add_spacer(10)

	# Check for active quests to show badge
	var active_quests = []
	if GameManager:
		active_quests = GameManager.get_active_quests_for_aspect(aspect_id)

	var quest_text = "Accept Quests"
	if active_quests.size() > 0:
		quest_text = "View Quests (%d active)" % active_quests.size()

	var options = [
		{"text": "Ask for advice", "action": "_get_aspect_advice"},
		{"text": "Request encouragement", "action": "_get_aspect_encouragement"},
		{"text": quest_text, "action": "_view_aspect_quests"},
		{"text": "Share my progress", "action": "_share_progress_with_aspect"},
		{"text": "Learn about this aspect", "action": "_get_aspect_teaching"},
		{"text": "Return to shrine", "action": "_open_aspect_shrine"}
	]

	for opt in options:
		var btn = Button.new()
		btn.text = opt.text
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", 18)
		if opt.action == "_open_aspect_shrine":
			btn.pressed.connect(_open_aspect_shrine)
		else:
			btn.pressed.connect(_handle_aspect_option.bind(aspect_id, opt.action))
		zone_body.add_child(btn)
		_add_spacer(8)

	zone_panel.visible = true
	in_zone_panel = true


func _handle_aspect_option(aspect_id: String, action: String) -> void:
	_close_zone()
	var name = _get_aspect_name(aspect_id)

	match action:
		"_get_aspect_advice":
			if GameManager:
				GameManager.record_aspect_interaction(aspect_id, "advice")
			var advice = _get_random_advice(aspect_id)
			_show_dialogue(name, advice, _show_aspect_options.bind(aspect_id))
		"_get_aspect_encouragement":
			if GameManager:
				GameManager.record_aspect_interaction(aspect_id, "dialogue")
			var encouragement = _get_random_encouragement(aspect_id)
			_show_dialogue(name, encouragement, _show_aspect_options.bind(aspect_id))
		"_view_aspect_quests":
			_show_aspect_quests(aspect_id)
		"_share_progress_with_aspect":
			if GameManager:
				GameManager.record_aspect_interaction(aspect_id, "dialogue")
			var response = _get_progress_response(aspect_id)
			_show_dialogue(name, response, _show_aspect_options.bind(aspect_id))
		"_get_aspect_teaching":
			if GameManager:
				GameManager.record_aspect_interaction(aspect_id, "advice")
			var teaching = _get_aspect_teaching_text(aspect_id)
			_show_dialogue(name, teaching, _show_aspect_options.bind(aspect_id))


## Show quests UI for an aspect
func _show_aspect_quests(aspect_id: String) -> void:
	zone_title.text = _get_aspect_name(aspect_id) + " - Quests"
	_clear_zone_body()
	_current_aspect_for_graphic = aspect_id  # Show evolved aspect graphic
	_setup_zone_graphic("AspectShrine")

	if not GameManager:
		_add_label("Quest system unavailable", 16, Color(0.7, 0.7, 0.7))
		_add_back_button(aspect_id)
		zone_panel.visible = true
		in_zone_panel = true
		return

	var active_quests = GameManager.get_active_quests_for_aspect(aspect_id)
	var available_quests = GameManager.get_available_quests(aspect_id)

	# Active Quests Section
	if active_quests.size() > 0:
		_add_label("Active Quests", 20, Color(0.9, 0.8, 0.3))
		_add_spacer(8)

		for quest in active_quests:
			_add_quest_card(quest, aspect_id, true)
			_add_spacer(10)

		_add_spacer(15)

	# Available Quests Section
	_add_label("Available Quests", 20, Color(0.6, 0.8, 0.9))
	_add_spacer(8)

	if available_quests.size() == 0:
		_add_label("No new quests available. Check back later!", 14, Color(0.6, 0.6, 0.6))
		_add_spacer(10)
	else:
		for quest in available_quests:
			_add_quest_card(quest, aspect_id, false)
			_add_spacer(10)

	_add_spacer(15)
	_add_back_button(aspect_id)

	zone_panel.visible = true
	in_zone_panel = true


## Add a quest card to the UI
func _add_quest_card(quest: Dictionary, aspect_id: String, is_active: bool) -> void:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()

	# Different colors for active vs available
	if is_active:
		style.bg_color = Color(0.2, 0.25, 0.35, 0.9)
		style.border_color = Color(0.4, 0.6, 0.8, 0.8)
	else:
		style.bg_color = Color(0.15, 0.18, 0.25, 0.9)
		style.border_color = Color(0.3, 0.35, 0.4, 0.6)

	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	# Header with icon and name
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var quest_data = quest.get("quest_data", quest)
	var icon_label = Label.new()
	icon_label.text = quest_data.get("icon", "?")
	icon_label.add_theme_font_size_override("font_size", 24)
	header.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = quest_data.get("name", "Unknown Quest")
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	# Difficulty badge
	var difficulty = quest_data.get("difficulty", "easy")
	var diff_label = Label.new()
	diff_label.text = difficulty.to_upper()
	diff_label.add_theme_font_size_override("font_size", 11)
	var diff_colors = {
		"easy": Color(0.4, 0.8, 0.4),
		"medium": Color(0.9, 0.7, 0.3),
		"hard": Color(0.9, 0.4, 0.4)
	}
	diff_label.add_theme_color_override("font_color", diff_colors.get(difficulty, Color.WHITE))
	header.add_child(diff_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = quest_data.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Rewards row
	var rewards = HBoxContainer.new()
	rewards.add_theme_constant_override("separation", 20)
	vbox.add_child(rewards)

	var xp_label = Label.new()
	xp_label.text = "+%d XP" % quest_data.get("xp_reward", 0)
	xp_label.add_theme_font_size_override("font_size", 13)
	xp_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	rewards.add_child(xp_label)

	var bond_label = Label.new()
	bond_label.text = "+%d Bond" % quest_data.get("bond_reward", 0)
	bond_label.add_theme_font_size_override("font_size", 13)
	bond_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.9))
	rewards.add_child(bond_label)

	# Progress or Accept button
	var quest_id = quest.get("id", "")

	if is_active:
		# Show progress info
		var progress_label = Label.new()
		progress_label.text = "In Progress..."
		progress_label.add_theme_font_size_override("font_size", 12)
		progress_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rewards.add_child(progress_label)

		# Abandon button
		var abandon_btn = Button.new()
		abandon_btn.text = "Abandon"
		abandon_btn.custom_minimum_size = Vector2(80, 30)
		abandon_btn.add_theme_font_size_override("font_size", 12)
		abandon_btn.pressed.connect(_abandon_quest.bind(quest_id, aspect_id))
		vbox.add_child(abandon_btn)
	else:
		# Accept button
		var accept_btn = Button.new()
		accept_btn.text = "Accept Quest"
		accept_btn.custom_minimum_size = Vector2(0, 36)
		accept_btn.add_theme_font_size_override("font_size", 14)
		accept_btn.pressed.connect(_accept_quest.bind(quest_id, aspect_id))
		vbox.add_child(accept_btn)

	zone_body.add_child(card)


## Accept a quest
func _accept_quest(quest_id: String, aspect_id: String) -> void:
	if not GameManager:
		return

	var success = GameManager.accept_quest(quest_id, aspect_id)
	if success:
		GameManager.record_aspect_interaction(aspect_id, "challenge_accepted")
		var aspect_name = _get_aspect_name(aspect_id)
		_close_zone()
		_show_dialogue(aspect_name, "Excellent! I accept your commitment to this challenge.\n\nComplete the quest objectives and return to me for your reward.\n\nMay your journey be fruitful!", _show_aspect_quests.bind(aspect_id))
	else:
		# Show error - likely too many active quests
		_close_zone()
		_show_dialogue(_get_aspect_name(aspect_id), "You already have too many active quests.\n\nComplete or abandon some quests before taking on new challenges.", _show_aspect_quests.bind(aspect_id))


## Abandon a quest
func _abandon_quest(quest_id: String, aspect_id: String) -> void:
	if not GameManager:
		return

	GameManager.abandon_quest(quest_id)
	_close_zone()
	_show_dialogue(_get_aspect_name(aspect_id), "I understand. Sometimes we must release what no longer serves us.\n\nThis quest will be available again when you are ready.", _show_aspect_quests.bind(aspect_id))


## Add back button for quest panel
func _add_back_button(aspect_id: String) -> void:
	var back_btn = Button.new()
	back_btn.text = "Back to " + _get_aspect_name(aspect_id)
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_show_aspect_options.bind(aspect_id))
	zone_body.add_child(back_btn)


func _get_aspect_name(aspect_id: String) -> String:
	var names = {
		"discipline": "Discipline",
		"courage": "Courage",
		"creativity": "Creativity",
		"compassion": "Compassion",
		"wisdom": "Wisdom",
		"vitality": "Vitality"
	}
	return names.get(aspect_id, aspect_id.capitalize())


## Get evolution tier based on level
func _get_evolution_tier(level: int) -> Dictionary:
	if level >= 10:
		return {"name": "ASCENDED", "color": Color(1.0, 0.85, 0.4)}
	elif level >= 7:
		return {"name": "MASTER", "color": Color(0.8, 0.6, 0.95)}
	elif level >= 5:
		return {"name": "ADEPT", "color": Color(0.4, 0.8, 0.9)}
	elif level >= 3:
		return {"name": "AWAKENED", "color": Color(0.6, 0.8, 0.5)}
	else:
		return {"name": "", "color": Color.WHITE}


## Get XP progress to next level (0.0 to 1.0)
func _get_aspect_xp_progress(aspect_id: String) -> float:
	if not GameManager:
		return 0.0

	var aspect_data = GameManager.player_data.aspects.get(aspect_id, {})
	var current_xp = aspect_data.get("experience", 0)
	var level = aspect_data.get("level", 1)

	# XP requirements per level (matches GameManager)
	var xp_for_next = level * 100
	var xp_for_current = (level - 1) * 100

	var progress_xp = current_xp - xp_for_current
	var needed_xp = xp_for_next - xp_for_current

	if needed_xp <= 0:
		return 1.0

	return clamp(float(progress_xp) / float(needed_xp), 0.0, 1.0)


func _get_random_advice(aspect_id: String) -> String:
	var advice_pool = {
		"discipline": [
			"Start small. A tiny habit done daily is worth more than a grand plan never started.",
			"When motivation fails - and it will - let routine carry you. Systems beat willpower.",
			"Don't break the chain. Every day you show up, you strengthen the neural pathway of commitment.",
			"Progress, not perfection. Done is better than perfect.",
			"Schedule your priorities, or others will schedule them for you."
		],
		"courage": [
			"Feel the fear. Acknowledge it. Then take one small step anyway.",
			"Comfort zones grow only when you step outside them. Discomfort is the price of growth.",
			"Ask yourself: 'What would I do if I weren't afraid?' Then do that.",
			"Failure is not the opposite of success - it's part of the journey. Fail forward.",
			"The conversation you're avoiding? That's exactly the one you need to have."
		],
		"creativity": [
			"Creativity isn't about talent - it's about practice! Make something today, even if it's imperfect.",
			"Bored? Good! Boredom is the birthplace of new ideas. Let your mind wander.",
			"Steal like an artist! Combine ideas from different places into something new.",
			"Write badly. Draw poorly. Create terribly. Then improve. The first draft is never good.",
			"Constraints breed creativity. Give yourself limits and watch innovation bloom."
		],
		"compassion": [
			"You cannot pour from an empty cup. Self-care is not selfish - it's essential.",
			"Listen to understand, not to respond. True connection begins with presence.",
			"Forgiveness is a gift you give yourself. Holding grudges only poisons your own heart.",
			"Small acts of kindness ripple outward in ways you'll never see. Keep giving.",
			"Treat yourself with the same kindness you'd show a good friend."
		],
		"wisdom": [
			"The wise person knows they know nothing. Stay curious. Stay humble.",
			"Before reacting, pause. In that pause lies your power to choose your response.",
			"Learn from everyone. Even fools teach us what not to do.",
			"What you focus on expands. Choose your attention carefully.",
			"Simple questions often lead to profound answers. Ask 'Why?' five times."
		],
		"vitality": [
			"Move your body every day, even if it's just a walk. Motion is life!",
			"Sleep is not a luxury - it's when your body repairs and your mind consolidates learning.",
			"You are what you eat. Feed yourself like you love yourself.",
			"Energy is contagious. Surround yourself with people who lift you up.",
			"Deep breaths. Right now. Three of them. Feel the difference?"
		]
	}

	if advice_pool.has(aspect_id):
		var pool = advice_pool[aspect_id]
		return pool[randi() % pool.size()]
	return "Growth comes one step at a time."


func _get_random_encouragement(aspect_id: String) -> String:
	var encouragement_pool = {
		"discipline": [
			"You're doing better than you think. Every session counts. Every habit matters.",
			"The fact that you're here, working on yourself? That IS discipline. Keep going.",
			"Your future self will thank you for the choices you're making today.",
			"Rome wasn't built in a day, but they were laying bricks every hour. You're laying bricks.",
			"Streaks get broken. What matters is that you start again. And you have."
		],
		"courage": [
			"You've already overcome so much to get here. You're braver than you know.",
			"Fear means you're about to grow. You're on the right track.",
			"Every hero felt afraid. The difference is they acted anyway. Like you.",
			"You've survived 100% of your worst days. You'll survive this too.",
			"The fact that you face your fears instead of running? That's true courage."
		],
		"creativity": [
			"Your ideas matter! The world needs what only you can create.",
			"Every master was once a disaster. Keep making things!",
			"You're more creative than you give yourself credit for. I've seen your potential!",
			"There's no such thing as a bad idea - only stepping stones to better ones.",
			"The muse rewards those who show up. And you're showing up!"
		],
		"compassion": [
			"Your kindness makes a difference, even when you can't see it.",
			"It's okay to rest. It's okay to struggle. You're human, and that's beautiful.",
			"The love you give comes back to you in unexpected ways. Trust the process.",
			"You deserve the same compassion you give to others. Remember that.",
			"Your presence matters to more people than you realize. You are valued."
		],
		"wisdom": [
			"Seeking understanding is itself a form of wisdom. You're on the right path.",
			"Your questions are getting deeper. That's how wisdom grows.",
			"Confusion is just understanding in progress. Be patient with yourself.",
			"The fact that you reflect on your life puts you ahead of most. Keep thinking.",
			"Wisdom isn't knowing everything - it's knowing what you don't know. You're wise."
		],
		"vitality": [
			"Your body is incredible - look at everything it does for you every day!",
			"Taking care of yourself isn't vanity. It's honoring the life you've been given.",
			"Every healthy choice compounds. You're building a stronger foundation daily.",
			"Rest when you need to. Recovery is part of getting stronger.",
			"You showed up today. That matters. Your body thanks you."
		]
	}

	if encouragement_pool.has(aspect_id):
		var pool = encouragement_pool[aspect_id]
		return pool[randi() % pool.size()]
	return "You're doing wonderfully. Keep going."


func _get_aspect_teaching_text(aspect_id: String) -> String:
	var teachings = {
		"discipline": "Discipline is the practice of delayed gratification - choosing long-term fulfillment over short-term pleasure.\n\nI grow stronger when you:\n• Complete focus sessions\n• Maintain daily habits\n• Follow through on commitments\n\nConsistency over intensity. Small steps, taken daily, lead to extraordinary destinations.",
		"courage": "Courage is not the absence of fear, but the judgment that something else is more important than fear.\n\nI grow stronger when you:\n• Face uncomfortable situations\n• Have difficult conversations\n• Try new things despite uncertainty\n\nEvery time you act despite fear, you expand what's possible for you.",
		"creativity": "Creativity is the ability to see connections others miss and to bring something new into existence.\n\nI grow stronger when you:\n• Experiment and play\n• Combine ideas in new ways\n• Express yourself authentically\n\nCreativity isn't a gift - it's a practice. The more you create, the more creative you become!",
		"compassion": "Compassion is the recognition that others suffer as you do, and the desire to ease that suffering - including your own.\n\nI grow stronger when you:\n• Practice self-care\n• Listen with empathy\n• Forgive yourself and others\n\nLove is not finite. The more you give, the more you have.",
		"wisdom": "Wisdom is the integration of knowledge with experience, tempered by humility.\n\nI grow stronger when you:\n• Reflect on your experiences\n• Seek to understand before being understood\n• Learn from both success and failure\n\nThe wisest know that true wisdom is knowing how much you don't know.",
		"vitality": "Vitality is the life force that flows through you - the energy that allows all other aspects to flourish.\n\nI grow stronger when you:\n• Move your body regularly\n• Prioritize rest and recovery\n• Nourish yourself with good food\n\nTake care of your body. It's the only place you have to live!"
	}

	return teachings.get(aspect_id, "This aspect represents a facet of your personal growth.")


func _get_aspect_challenge_text(aspect_id: String) -> String:
	var challenges = {
		"discipline": [
			"Your challenge, should you accept it:\n\n🎯 Complete 3 focus sessions today, each at least 15 minutes.\n\nThis will strengthen your ability to sustain attention and build momentum.",
			"I challenge you:\n\n🎯 For the next 3 days, complete your habits at the same time each day.\n\nRituals create the scaffolding of discipline.",
			"Here is your test:\n\n🎯 Choose one task you've been avoiding and complete it within the next hour.\n\nDiscipline means doing what needs to be done, when it needs to be done."
		],
		"courage": [
			"I challenge you:\n\n🎯 Have a conversation you've been putting off.\n\nThe discomfort is temporary. The growth is permanent.",
			"Your challenge awaits:\n\n🎯 Try something new today that makes you slightly uncomfortable.\n\nComfort zones only grow from the outside.",
			"Here is your test:\n\n🎯 Share something honest about yourself with someone you trust.\n\nVulnerability is the birthplace of courage."
		],
		"creativity": [
			"Ooh! Here's a fun challenge:\n\n🎯 Create something - anything! - in the next 30 minutes. No judgment, just creation!\n\nPerfection is the enemy of done!",
			"I challenge your imagination:\n\n🎯 Write down 10 wild ideas for something you care about. The wilder the better!\n\nQuantity breeds quality in idea generation.",
			"Here's a creative quest:\n\n🎯 Combine two things that don't normally go together and see what happens.\n\nInnovation lives at the intersection of the unexpected!"
		],
		"compassion": [
			"A gentle challenge for you:\n\n🎯 Write yourself a kind letter, as if writing to a dear friend.\n\nYou deserve the same compassion you give others.",
			"Your heart's challenge:\n\n🎯 Reach out to someone you haven't connected with in a while.\n\nConnection nourishes the soul.",
			"I invite you to:\n\n🎯 Perform three small acts of kindness today - and log them!\n\nKindness given returns multiplied."
		],
		"wisdom": [
			"A challenge for the seeker:\n\n🎯 Before each decision today, pause and ask: 'What would my wisest self do?'\n\nWisdom requires the space to emerge.",
			"I pose this challenge:\n\n🎯 Journal for 10 minutes about a recent experience and what it taught you.\n\nReflection transforms experience into wisdom.",
			"Your contemplation task:\n\n🎯 Spend 5 minutes in silence, observing your thoughts without attachment.\n\nIn stillness, wisdom speaks."
		],
		"vitality": [
			"Your body's challenge:\n\n🎯 Move your body for 20 minutes today - dancing, walking, stretching, anything!\n\nEnergy creates energy.",
			"A vital challenge:\n\n🎯 Drink 8 glasses of water today and notice how you feel.\n\nHydration is the foundation of vitality.",
			"I challenge your wellness:\n\n🎯 Go to bed 30 minutes earlier tonight.\n\nRest is not laziness - it's fuel for the fire of life!"
		]
	}

	if challenges.has(aspect_id):
		var pool = challenges[aspect_id]
		return pool[randi() % pool.size()]
	return "I challenge you to reflect on how you can grow in this area today."


func _get_progress_response(aspect_id: String) -> String:
	# Get actual stats for this aspect
	var level = GameManager.get_aspect_level(aspect_id)
	var habits = HabitManager.get_all_habits()
	var total_streak = 0
	var completed_today = 0
	var domain_match = _get_aspect_domain(aspect_id)

	for habit in habits:
		if habit.get("domain", -1) == domain_match:
			total_streak += habit.get("streak", 0)
			if HabitManager.is_completed_today(habit.id):
				completed_today += 1

	var focus_stats = GameManager.player_data.get("focus_stats", {})
	var total_focus_minutes = focus_stats.get("total_minutes", 0)

	# Generate response based on actual progress
	if level >= 5:
		return _get_high_level_response(aspect_id, level, total_streak, completed_today, total_focus_minutes)
	elif level >= 3:
		return _get_mid_level_response(aspect_id, level, total_streak, completed_today, total_focus_minutes)
	else:
		return _get_low_level_response(aspect_id, level, total_streak, completed_today, total_focus_minutes)


func _get_aspect_domain(aspect_id: String) -> int:
	match aspect_id:
		"vitality": return HabitManager.HabitDomain.HEALTH
		"creativity": return HabitManager.HabitDomain.LEARNING
		"wisdom": return HabitManager.HabitDomain.MINDFULNESS
		"compassion": return HabitManager.HabitDomain.SOCIAL
		"discipline": return HabitManager.HabitDomain.PRODUCTIVITY
		_: return -1


func _get_low_level_response(aspect_id: String, level: int, streak: int, completed: int, focus_mins: int) -> String:
	var responses = {
		"discipline": "Your journey with me has just begun. Level %d.\n\nI see you've completed %d habit(s) today with %d total streak days.\n\n%s\n\nKeep showing up. That is the only secret." % [level, completed, streak, "Good start!" if completed > 0 else "Let's build some habits together."],
		"courage": "We are still getting acquainted. Level %d.\n\nThe path of courage begins with small steps.\n\n%s\n\nEvery brave act, no matter how small, strengthens me." % [level, "I see you're building momentum!" if streak > 3 else "What fear will you face today?"],
		"creativity": "Oh how exciting - a new creative journey! Level %d.\n\n%s\n\nRemember: bad art is better than no art. Create something today!" % [level, "You've been showing up - I love it!" if completed > 0 else "Let's make something together!"],
		"compassion": "Your heart is opening. Level %d.\n\n%s\n\nBe gentle with yourself as you grow. Compassion starts within." % [level, "I feel the warmth of your efforts." if streak > 0 else "How have you been kind to yourself today?"],
		"wisdom": "A seeker arrives. Level %d.\n\nYou've spent %d minutes in focused contemplation.\n\n%s\n\nWisdom comes to those who pause and reflect." % [level, focus_mins, "You are learning to be present." if focus_mins > 30 else "Seek moments of stillness."],
		"vitality": "Your life force stirs! Level %d.\n\n%s\n\nYour body is your vehicle for this journey. Treat it well!" % [level, "You're building healthy patterns!" if streak > 0 else "How will you move your body today?"]
	}
	return responses.get(aspect_id, "I sense potential within you. Level %d. Let us grow together." % level)


func _get_mid_level_response(aspect_id: String, level: int, streak: int, completed: int, focus_mins: int) -> String:
	var responses = {
		"discipline": "You grow stronger! Level %d.\n\n%d habit(s) completed today, %d total streak days. %d minutes of focused work.\n\nI am proud of your consistency. You understand now that showing up is the victory." % [level, completed, streak, focus_mins],
		"courage": "Your bravery deepens. Level %d.\n\nYou've faced fears that once seemed impossible. %d streak days of facing challenges.\n\nThe version of you from weeks ago would be in awe." % [level, streak],
		"creativity": "Your imagination blooms! Level %d.\n\nI can see the colors of your creativity growing brighter! %d days of creative practice.\n\nYou're discovering that creativity is a skill, not a gift." % [level, streak],
		"compassion": "Your heart expands beautifully. Level %d.\n\n%d days of cultivating kindness. The love you give creates ripples beyond what you can see.\n\nYou're learning that compassion for others begins with compassion for yourself." % [level, streak],
		"wisdom": "Understanding dawns. Level %d.\n\n%d minutes in contemplation. %d days of reflection.\n\nYou're learning that answers often come not from seeking, but from being still enough to hear them." % [level, focus_mins, streak],
		"vitality": "Your life force surges! Level %d.\n\n%d days of caring for your body. You're discovering that energy creates energy.\n\nThe vessel grows stronger each day you honor it." % [level, streak]
	}
	return responses.get(aspect_id, "Your dedication shows. Level %d. Continue on this path." % level)


func _get_high_level_response(aspect_id: String, level: int, streak: int, completed: int, focus_mins: int) -> String:
	var responses = {
		"discipline": "You have become a master of consistency. Level %d.\n\n%d total streak days. %d minutes of focused mastery.\n\nWe are kindred spirits now. What once took effort has become who you are. Discipline is no longer something you do - it is something you are." % [level, streak, focus_mins],
		"courage": "You have become a warrior of the spirit! Level %d.\n\n%d days of facing fears. You now know that courage is not the absence of fear, but its companion.\n\nFear still whispers, but it no longer commands. I am honored to walk beside such a brave soul." % [level, streak],
		"creativity": "Oh my stars! Look at you! Level %d!\n\n%d days of creative wonder! You've discovered the great secret: creativity is infinite. The more you use, the more you have!\n\nYou are an artist of life itself now. What will we dream up next?" % [level, streak],
		"compassion": "You have become love embodied. Level %d.\n\n%d days of cultivating the heart. Your compassion now extends naturally - to others, to yourself, to all beings.\n\nThe warmth you carry lights up every room you enter. I am honored to know such a kind soul." % [level, streak],
		"wisdom": "You have attained deep understanding. Level %d.\n\n%d minutes of contemplation. %d days of seeking truth.\n\nYou now know that wisdom is not about having answers, but about sitting peacefully with questions. The examined life shines through you." % [level, focus_mins, streak],
		"vitality": "Your life force is radiant! Level %d.\n\n%d days of honoring your body. You understand now that vitality is the foundation upon which all other aspects build.\n\nYour energy inspires others. The temple is strong and ready for any journey!" % [level, streak]
	}
	return responses.get(aspect_id, "You have reached great heights. Level %d. You are a beacon of growth." % level)


func _add_spacer(height: int) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	zone_body.add_child(spacer)


# ============ SHADOW WORK SYSTEM ============

const SHADOW_TYPES = {
	"fear": {
		"name": "Fear",
		"prompt": "What are you afraid of?",
		"examples": "failure, rejection, being seen, making mistakes, not being good enough",
		"color": Color(0.8, 0.3, 0.35),
		"aspect": "courage"
	},
	"doubt": {
		"name": "Self-Doubt",
		"prompt": "What do you doubt about yourself?",
		"examples": "my abilities, my worth, my decisions, my potential",
		"color": Color(0.5, 0.4, 0.6),
		"aspect": "discipline"
	},
	"shame": {
		"name": "Shame",
		"prompt": "What do you feel ashamed of?",
		"examples": "past mistakes, perceived flaws, things I've done/not done",
		"color": Color(0.4, 0.3, 0.5),
		"aspect": "compassion"
	},
	"belief": {
		"name": "Limiting Belief",
		"prompt": "What limiting belief holds you back?",
		"examples": "I'm not smart enough, I don't deserve success, I can't change",
		"color": Color(0.3, 0.4, 0.6),
		"aspect": "wisdom"
	}
}


func _identify_shadow() -> void:
	zone_title.text = "Identify a Shadow"
	_clear_zone_body()
	_setup_zone_graphic("ShadowWork")

	_add_spacer(10)

	var intro = Label.new()
	intro.text = "What type of shadow do you want to explore?"
	intro.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(intro)

	_add_spacer(12)

	for type_id in SHADOW_TYPES:
		var type_data = SHADOW_TYPES[type_id]
		var btn = Button.new()
		btn.text = type_data.name
		btn.custom_minimum_size = Vector2(0, 45)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_show_shadow_input.bind(type_id))
		zone_body.add_child(btn)

		var desc = Label.new()
		desc.text = "Examples: " + type_data.examples
		desc.add_theme_font_size_override("font_size", 13)
		desc.add_theme_color_override("font_color", Color(0.5, 0.45, 0.55))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		zone_body.add_child(desc)

		_add_spacer(6)


func _show_shadow_input(shadow_type: String) -> void:
	_current_shadow_type = shadow_type
	var type_data = SHADOW_TYPES[shadow_type]

	zone_title.text = "Identify: " + type_data.name
	_clear_zone_body()
	_setup_zone_graphic("ShadowWork")

	_add_spacer(10)

	var prompt = Label.new()
	prompt.text = type_data.prompt
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", type_data.color)
	zone_body.add_child(prompt)

	_add_spacer(10)

	var input = TextEdit.new()
	input.name = "ShadowInput"
	input.placeholder_text = "Describe your " + type_data.name.to_lower() + " honestly..."
	input.custom_minimum_size = Vector2(0, 100)
	input.add_theme_font_size_override("font_size", 16)
	input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	zone_body.add_child(input)

	_add_spacer(10)

	var guidance = Label.new()
	guidance.text = "Be specific and honest. Naming your shadow is the first step to transforming it."
	guidance.add_theme_font_size_override("font_size", 14)
	guidance.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	guidance.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(guidance)

	_add_spacer(12)

	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 15)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 45)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_identify_shadow)
	button_row.add_child(cancel_btn)

	var save_btn = Button.new()
	save_btn.text = "Acknowledge Shadow"
	save_btn.custom_minimum_size = Vector2(0, 45)
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.add_theme_font_size_override("font_size", 16)
	save_btn.pressed.connect(_save_shadow)
	button_row.add_child(save_btn)

	zone_body.add_child(button_row)


func _save_shadow() -> void:
	var input = zone_body.find_child("ShadowInput", true, false) as TextEdit
	if not input or input.text.strip_edges() == "":
		_show_dialogue("Empty Entry", "Please describe your shadow to acknowledge it.")
		return

	var type_data = SHADOW_TYPES.get(_current_shadow_type, {})

	var shadow = {
		"id": str(Time.get_unix_time_from_system()),
		"type": _current_shadow_type,
		"description": input.text.strip_edges(),
		"timestamp": Time.get_unix_time_from_system(),
		"date": Time.get_date_string_from_system(),
		"confronted": false,
		"reframe": ""
	}

	_save_shadow_entry(shadow)

	# Award XP for acknowledging a shadow
	var aspect = type_data.get("aspect", "courage")
	GameManager.add_aspect_experience(aspect, 20)

	# Track for aspect quests
	if GameManager:
		GameManager.check_quests_for_trigger("journal_entry", {"type": "shadow"})

	_close_zone()
	_show_dialogue("Shadow Acknowledged", "You have named your shadow. That takes courage.\n\n+" + str(20) + " " + aspect.capitalize() + " XP\n\nReturn when you're ready to confront and transform it.", _open_shadow_work)


func _confront_shadows_list() -> void:
	zone_title.text = "Your Shadows"
	_clear_zone_body()
	_setup_zone_graphic("ShadowWork")

	_add_spacer(10)

	var shadows = _load_shadows()

	if shadows.is_empty():
		var empty = Label.new()
		empty.text = "You haven't identified any shadows yet.\n\nStart by identifying a fear, doubt, or limiting belief."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color(0.5, 0.45, 0.55))
		zone_body.add_child(empty)

		_add_spacer(15)

		var btn = Button.new()
		btn.text = "Identify a Shadow"
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_identify_shadow)
		zone_body.add_child(btn)
	else:
		var intro = Label.new()
		intro.text = "Choose a shadow to confront:"
		intro.add_theme_font_size_override("font_size", 18)
		zone_body.add_child(intro)

		_add_spacer(10)

		for shadow in shadows:
			_add_shadow_entry(shadow)

	zone_panel.visible = true
	in_zone_panel = true


func _add_shadow_entry(shadow: Dictionary) -> void:
	var type_data = SHADOW_TYPES.get(shadow.get("type", "fear"), SHADOW_TYPES["fear"])
	var is_confronted = shadow.get("confronted", false)

	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	# Status indicator
	var indicator = ColorRect.new()
	indicator.custom_minimum_size = Vector2(8, 50)
	if is_confronted:
		indicator.color = Color(0.4, 0.7, 0.5)
	else:
		indicator.color = type_data.color
	container.add_child(indicator)

	# Shadow info
	var info_col = VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var type_label = Label.new()
	type_label.text = type_data.name + (" ✓" if is_confronted else "")
	type_label.add_theme_font_size_override("font_size", 16)
	if is_confronted:
		type_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.5))
	else:
		type_label.add_theme_color_override("font_color", type_data.color)
	info_col.add_child(type_label)

	var desc = shadow.get("description", "")
	var preview_label = Label.new()
	preview_label.text = desc.substr(0, 40) + ("..." if desc.length() > 40 else "")
	preview_label.add_theme_font_size_override("font_size", 13)
	preview_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	info_col.add_child(preview_label)

	container.add_child(info_col)

	# Confront button
	var btn = Button.new()
	btn.text = "View" if is_confronted else "Confront"
	btn.custom_minimum_size = Vector2(80, 0)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(_confront_shadow.bind(shadow.get("id", "")))
	container.add_child(btn)

	zone_body.add_child(container)
	_add_spacer(6)


func _confront_shadow(shadow_id: String) -> void:
	var shadows = _load_shadows()
	var shadow = null
	for s in shadows:
		if s.get("id", "") == shadow_id:
			shadow = s
			break

	if not shadow:
		_show_dialogue("Error", "Shadow not found.")
		return

	var type_data = SHADOW_TYPES.get(shadow.get("type", "fear"), SHADOW_TYPES["fear"])

	zone_title.text = "Confront: " + type_data.name
	_clear_zone_body()
	_setup_zone_graphic("ShadowWork")

	_add_spacer(10)

	# Show the shadow
	var shadow_label = Label.new()
	shadow_label.text = "Your shadow:"
	shadow_label.add_theme_font_size_override("font_size", 16)
	shadow_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.55))
	zone_body.add_child(shadow_label)

	var shadow_text = Label.new()
	shadow_text.text = '"' + shadow.get("description", "") + '"'
	shadow_text.add_theme_font_size_override("font_size", 18)
	shadow_text.add_theme_color_override("font_color", type_data.color)
	shadow_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(shadow_text)

	_add_spacer(12)

	# Show existing reframe if any
	if shadow.get("reframe", "") != "":
		var reframe_label = Label.new()
		reframe_label.text = "Your reframe:"
		reframe_label.add_theme_font_size_override("font_size", 16)
		reframe_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
		zone_body.add_child(reframe_label)

		var reframe_text = Label.new()
		reframe_text.text = '"' + shadow.get("reframe", "") + '"'
		reframe_text.add_theme_font_size_override("font_size", 18)
		reframe_text.add_theme_color_override("font_color", Color(0.4, 0.7, 0.5))
		reframe_text.autowrap_mode = TextServer.AUTOWRAP_WORD
		zone_body.add_child(reframe_text)
	else:
		# Prompt for reframe
		var reframe_prompt = Label.new()
		reframe_prompt.text = "How can you reframe this shadow into a source of growth?"
		reframe_prompt.add_theme_font_size_override("font_size", 16)
		reframe_prompt.add_theme_color_override("font_color", Color(0.5, 0.55, 0.5))
		zone_body.add_child(reframe_prompt)

		var reframe_input = TextEdit.new()
		reframe_input.name = "ReframeInput"
		reframe_input.placeholder_text = "Transform the negative into an empowering truth..."
		reframe_input.custom_minimum_size = Vector2(0, 80)
		reframe_input.add_theme_font_size_override("font_size", 14)
		reframe_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		zone_body.add_child(reframe_input)

	_add_spacer(12)

	# Buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 15)

	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_confront_shadows_list)
	button_row.add_child(back_btn)

	if shadow.get("reframe", "") == "":
		var confront_btn = Button.new()
		confront_btn.text = "Transform Shadow"
		confront_btn.custom_minimum_size = Vector2(0, 45)
		confront_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		confront_btn.add_theme_font_size_override("font_size", 16)
		confront_btn.pressed.connect(_complete_confrontation.bind(shadow_id))
		button_row.add_child(confront_btn)

	zone_body.add_child(button_row)


func _complete_confrontation(shadow_id: String) -> void:
	var reframe_input = zone_body.find_child("ReframeInput", true, false) as TextEdit
	if not reframe_input or reframe_input.text.strip_edges() == "":
		_show_dialogue("Missing Reframe", "Please write how you can transform this shadow into growth.")
		return

	var shadows = _load_shadows()
	for i in range(shadows.size()):
		if shadows[i].get("id", "") == shadow_id:
			shadows[i]["confronted"] = true
			shadows[i]["reframe"] = reframe_input.text.strip_edges()
			shadows[i]["confronted_date"] = Time.get_date_string_from_system()
			break

	_save_all_shadows(shadows)

	# Award significant XP for confronting a shadow
	GameManager.add_aspect_experience("courage", 40)
	GameManager.add_aspect_experience("wisdom", 20)
	GameManager.evolve_world(0.5)

	_close_zone()
	_show_dialogue("Shadow Transformed!", "You have confronted your shadow and found the light within it.\n\n+40 Courage XP\n+20 Wisdom XP\n+0.5% World Evolution\n\nThis shadow no longer controls you.", _open_shadow_work)


func _practice_reframing() -> void:
	zone_title.text = "Reframing Practice"
	_clear_zone_body()
	_setup_zone_graphic("ShadowWork")

	_add_spacer(10)

	var intro = Label.new()
	intro.text = "Reframing transforms negative thoughts into empowering ones.\n\nHere are some examples:"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(intro)

	_add_spacer(12)

	var examples = [
		{"negative": "I'm not good enough", "reframe": "I'm learning and growing every day"},
		{"negative": "I always fail", "reframe": "Every failure teaches me something valuable"},
		{"negative": "People will judge me", "reframe": "What others think is none of my business"},
		{"negative": "I can't change", "reframe": "Change is difficult but possible with consistent effort"},
	]

	for example in examples:
		var container = VBoxContainer.new()
		container.add_theme_constant_override("separation", 3)

		var neg = Label.new()
		neg.text = "✗ \"" + example.negative + "\""
		neg.add_theme_font_size_override("font_size", 14)
		neg.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4))
		container.add_child(neg)

		var pos = Label.new()
		pos.text = "↳ \"" + example.reframe + "\""
		pos.add_theme_font_size_override("font_size", 14)
		pos.add_theme_color_override("font_color", Color(0.4, 0.7, 0.5))
		container.add_child(pos)

		zone_body.add_child(container)
		_add_spacer(8)

	_add_spacer(10)

	var back_btn = Button.new()
	back_btn.text = "Return to Shadow Work"
	back_btn.custom_minimum_size = Vector2(0, 50)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_open_shadow_work)
	zone_body.add_child(back_btn)


func _save_shadow_entry(shadow: Dictionary) -> void:
	var shadows = _load_shadows()
	shadows.append(shadow)
	_save_all_shadows(shadows)


func _save_all_shadows(shadows: Array) -> void:
	var json_string = JSON.stringify(shadows, "\t")
	var path = SaveManager.get_shadow_path()
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		if SaveManager: SaveManager.sync_web_filesystem()


func _load_shadows() -> Array:
	var path = SaveManager.get_shadow_path()
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


# ============ KINDNESS/CONTRIBUTION LOG ============

const KINDNESS_CATEGORIES = [
	{"id": "helping", "name": "Helping Others", "icon": "🤝", "color": Color(0.4, 0.7, 0.5)},
	{"id": "listening", "name": "Active Listening", "icon": "👂", "color": Color(0.5, 0.6, 0.8)},
	{"id": "giving", "name": "Giving/Donating", "icon": "🎁", "color": Color(0.7, 0.5, 0.6)},
	{"id": "volunteering", "name": "Volunteering", "icon": "🌟", "color": Color(0.8, 0.7, 0.4)},
	{"id": "encouraging", "name": "Encouraging Words", "icon": "💬", "color": Color(0.6, 0.5, 0.7)},
	{"id": "self_care", "name": "Self-Compassion", "icon": "💚", "color": Color(0.5, 0.75, 0.6)}
]


func _open_kindness_log() -> void:
	zone_title.text = "Kindness Log"
	_clear_zone_body()

	var intro = Label.new()
	intro.text = "Track your acts of kindness and contribution. Every compassionate action ripples outward."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(intro)

	_add_spacer(12)

	# Stats summary
	var entries = _load_kindness_entries()
	var this_week = _count_entries_this_week(entries)
	var total = entries.size()

	var stats_row = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 20)

	var week_stat = _create_stat_display("This Week", str(this_week), Color(0.4, 0.7, 0.5))
	stats_row.add_child(week_stat)

	var total_stat = _create_stat_display("All Time", str(total), Color(0.5, 0.6, 0.7))
	stats_row.add_child(total_stat)

	var streak = _calculate_kindness_streak(entries)
	var streak_stat = _create_stat_display("Day Streak", str(streak), Color(0.8, 0.6, 0.3))
	stats_row.add_child(streak_stat)

	zone_body.add_child(stats_row)

	_add_spacer(16)

	# Action buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)

	var log_btn = Button.new()
	log_btn.text = "+ Log Act of Kindness"
	log_btn.custom_minimum_size = Vector2(0, 45)
	log_btn.add_theme_font_size_override("font_size", 16)
	log_btn.pressed.connect(_show_kindness_entry_form)
	button_row.add_child(log_btn)

	var history_btn = Button.new()
	history_btn.text = "View History"
	history_btn.custom_minimum_size = Vector2(0, 45)
	history_btn.add_theme_font_size_override("font_size", 16)
	history_btn.pressed.connect(_show_kindness_history)
	button_row.add_child(history_btn)

	zone_body.add_child(button_row)

	_add_spacer(16)

	# Recent entries preview
	if not entries.is_empty():
		var recent_header = Label.new()
		recent_header.text = "Recent Acts:"
		recent_header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		zone_body.add_child(recent_header)

		_add_spacer(6)

		var recent = entries.slice(max(0, entries.size() - 3), entries.size())
		recent.reverse()
		for entry in recent:
			_add_kindness_entry_card(entry, true)

	_add_spacer(12)

	var back_btn = Button.new()
	back_btn.text = "← Back to Aspect Shrine"
	back_btn.pressed.connect(_open_aspect_shrine)
	zone_body.add_child(back_btn)

	zone_panel.visible = true
	in_zone_panel = true


func _create_stat_display(label_text: String, value_text: String, color: Color) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var value_label = Label.new()
	value_label.text = value_text
	value_label.add_theme_font_size_override("font_size", 24)
	value_label.add_theme_color_override("font_color", color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(value_label)

	var text_label = Label.new()
	text_label.text = label_text
	text_label.add_theme_font_size_override("font_size", 12)
	text_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(text_label)

	return container


func _show_kindness_entry_form() -> void:
	zone_title.text = "Log Kindness"
	_clear_zone_body()

	var intro = Label.new()
	intro.text = "Record an act of kindness or contribution you've made."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(intro)

	_add_spacer(12)

	# Category selection
	var cat_label = Label.new()
	cat_label.text = "Category:"
	zone_body.add_child(cat_label)

	var cat_grid = GridContainer.new()
	cat_grid.name = "CategoryGrid"
	cat_grid.columns = 2
	cat_grid.add_theme_constant_override("h_separation", 8)
	cat_grid.add_theme_constant_override("v_separation", 8)

	for i in range(KINDNESS_CATEGORIES.size()):
		var cat = KINDNESS_CATEGORIES[i]
		var btn = Button.new()
		btn.name = "Cat_" + cat.id
		btn.text = cat.icon + " " + cat.name
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_select_kindness_category.bind(cat.id))
		cat_grid.add_child(btn)

	zone_body.add_child(cat_grid)

	_add_spacer(12)

	# Description input
	var desc_label = Label.new()
	desc_label.text = "What did you do?"
	zone_body.add_child(desc_label)

	var desc_input = TextEdit.new()
	desc_input.name = "KindnessDescInput"
	desc_input.placeholder_text = "Describe your act of kindness..."
	desc_input.custom_minimum_size = Vector2(0, 80)
	desc_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_body.add_child(desc_input)

	_add_spacer(12)

	# Recipient (optional)
	var recipient_label = Label.new()
	recipient_label.text = "For whom? (optional)"
	zone_body.add_child(recipient_label)

	var recipient_input = LineEdit.new()
	recipient_input.name = "KindnessRecipientInput"
	recipient_input.placeholder_text = "e.g., A friend, A stranger, Myself..."
	zone_body.add_child(recipient_input)

	_add_spacer(12)

	# How did it feel?
	var feel_label = Label.new()
	feel_label.text = "How did it feel? (1-5)"
	zone_body.add_child(feel_label)

	var feel_row = HBoxContainer.new()
	feel_row.name = "FeelRow"
	feel_row.add_theme_constant_override("separation", 8)

	for i in range(1, 6):
		var feel_btn = Button.new()
		feel_btn.name = "Feel_" + str(i)
		feel_btn.text = str(i)
		feel_btn.toggle_mode = true
		feel_btn.button_pressed = (i == 3)
		feel_btn.custom_minimum_size = Vector2(40, 40)
		feel_btn.pressed.connect(_select_kindness_feeling.bind(i))
		feel_row.add_child(feel_btn)

	var feel_desc = Label.new()
	feel_desc.name = "FeelDesc"
	feel_desc.text = "Neutral"
	feel_desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	feel_row.add_child(feel_desc)

	zone_body.add_child(feel_row)

	_add_spacer(16)

	# Action buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(_open_kindness_log)
	button_row.add_child(cancel_btn)

	var save_btn = Button.new()
	save_btn.text = "Save Entry"
	save_btn.pressed.connect(_save_kindness_entry)
	button_row.add_child(save_btn)

	zone_body.add_child(button_row)


func _select_kindness_category(cat_id: String) -> void:
	_selected_kindness_category = cat_id
	var grid = zone_body.find_child("CategoryGrid", true, false)
	if grid:
		for child in grid.get_children():
			if child is Button:
				child.button_pressed = (child.name == "Cat_" + cat_id)


func _select_kindness_feeling(level: int) -> void:
	_kindness_feeling = level
	var row = zone_body.find_child("FeelRow", true, false)
	if row:
		for child in row.get_children():
			if child is Button:
				child.button_pressed = (child.name == "Feel_" + str(level))

	var feel_desc = zone_body.find_child("FeelDesc", true, false)
	if feel_desc:
		var descriptions = ["Difficult", "Challenging", "Neutral", "Good", "Amazing"]
		feel_desc.text = descriptions[level - 1]
		var colors = [Color(0.6, 0.4, 0.4), Color(0.7, 0.5, 0.4), Color(0.6, 0.6, 0.6), Color(0.5, 0.7, 0.5), Color(0.4, 0.8, 0.5)]
		feel_desc.add_theme_color_override("font_color", colors[level - 1])


func _save_kindness_entry() -> void:
	var desc_input = zone_body.find_child("KindnessDescInput", true, false) as TextEdit
	var recipient_input = zone_body.find_child("KindnessRecipientInput", true, false) as LineEdit

	if not desc_input or desc_input.text.strip_edges() == "":
		_show_dialogue("Error", "Please describe what you did.")
		return

	var entry = {
		"date": Time.get_datetime_string_from_system(),
		"category": _selected_kindness_category,
		"description": desc_input.text.strip_edges(),
		"recipient": recipient_input.text.strip_edges() if recipient_input else "",
		"feeling": _kindness_feeling
	}

	var entries = _load_kindness_entries()
	entries.append(entry)
	_save_kindness_entries(entries)

	# Award Compassion XP
	var xp_amount = 15 + (_kindness_feeling * 3)  # 18-30 XP based on feeling
	if GameManager and GameManager.has_method("add_aspect_experience"):
		GameManager.add_aspect_experience("compassion", xp_amount)

	# Track for aspect quests
	if GameManager:
		GameManager.check_quests_for_trigger("kindness_logged", {})

	# Update player data for streaks
	var today = Time.get_date_string_from_system()
	if not GameManager.player_data.has("kindness_dates"):
		GameManager.player_data["kindness_dates"] = []
	if not today in GameManager.player_data["kindness_dates"]:
		GameManager.player_data["kindness_dates"].append(today)

	# Find category name
	var cat_name = "kindness"
	for cat in KINDNESS_CATEGORIES:
		if cat.id == _selected_kindness_category:
			cat_name = cat.name.to_lower()
			break

	_close_zone()
	_show_dialogue("Kindness Logged", "Your act of " + cat_name + " has been recorded.\n\n+" + str(xp_amount) + " Compassion XP\n\nRemember: every act of kindness creates ripples.", _open_kindness_log)


func _show_kindness_history() -> void:
	zone_title.text = "Kindness History"
	_clear_zone_body()

	var entries = _load_kindness_entries()

	if entries.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No kindness entries yet. Start logging your acts of compassion!"
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		zone_body.add_child(empty_label)
	else:
		# Category breakdown
		var breakdown = _get_category_breakdown(entries)
		if not breakdown.is_empty():
			var breakdown_header = Label.new()
			breakdown_header.text = "By Category:"
			breakdown_header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
			zone_body.add_child(breakdown_header)

			_add_spacer(6)

			for cat_id in breakdown:
				var cat_info = null
				for c in KINDNESS_CATEGORIES:
					if c.id == cat_id:
						cat_info = c
						break

				if cat_info:
					var row = HBoxContainer.new()
					row.add_theme_constant_override("separation", 8)

					var icon = Label.new()
					icon.text = cat_info.icon
					row.add_child(icon)

					var name_label = Label.new()
					name_label.text = cat_info.name
					name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					row.add_child(name_label)

					var count = Label.new()
					count.text = str(breakdown[cat_id])
					count.add_theme_color_override("font_color", cat_info.color)
					row.add_child(count)

					zone_body.add_child(row)

			_add_spacer(16)

		# Recent entries
		var entries_header = Label.new()
		entries_header.text = "Recent Entries (" + str(entries.size()) + " total):"
		entries_header.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		zone_body.add_child(entries_header)

		_add_spacer(8)

		# Show last 10 entries
		var recent = entries.slice(max(0, entries.size() - 10), entries.size())
		recent.reverse()
		for entry in recent:
			_add_kindness_entry_card(entry, false)

	_add_spacer(16)

	var back_btn = Button.new()
	back_btn.text = "← Back to Kindness Log"
	back_btn.pressed.connect(_open_kindness_log)
	zone_body.add_child(back_btn)


func _add_kindness_entry_card(entry: Dictionary, compact: bool) -> void:
	var container = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.18, 0.8)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8 if compact else 10)
	container.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	# Header row with category and date
	var header_row = HBoxContainer.new()

	var cat_info = null
	for c in KINDNESS_CATEGORIES:
		if c.id == entry.get("category", "helping"):
			cat_info = c
			break

	if cat_info:
		var icon = Label.new()
		icon.text = cat_info.icon
		header_row.add_child(icon)

		var cat_label = Label.new()
		cat_label.text = " " + cat_info.name
		cat_label.add_theme_color_override("font_color", cat_info.color)
		cat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_row.add_child(cat_label)

	var date_str = entry.get("date", "")
	if date_str.length() > 10:
		date_str = date_str.substr(0, 10)
	var date_label = Label.new()
	date_label.text = date_str
	date_label.add_theme_font_size_override("font_size", 12)
	date_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	header_row.add_child(date_label)

	vbox.add_child(header_row)

	# Description
	if not compact or entry.get("description", "").length() <= 50:
		var desc = Label.new()
		var desc_text = entry.get("description", "")
		if compact and desc_text.length() > 50:
			desc_text = desc_text.substr(0, 47) + "..."
		desc.text = desc_text
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc.add_theme_font_size_override("font_size", 14)
		vbox.add_child(desc)

	# Recipient and feeling (if not compact)
	if not compact:
		var recipient = entry.get("recipient", "")
		if recipient != "":
			var rec_label = Label.new()
			rec_label.text = "For: " + recipient
			rec_label.add_theme_font_size_override("font_size", 12)
			rec_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
			vbox.add_child(rec_label)

		var feeling = entry.get("feeling", 3)
		var feeling_labels = ["Difficult", "Challenging", "Neutral", "Good", "Amazing"]
		var feel_label = Label.new()
		feel_label.text = "Felt: " + feeling_labels[feeling - 1]
		feel_label.add_theme_font_size_override("font_size", 12)
		feel_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
		vbox.add_child(feel_label)

	container.add_child(vbox)
	zone_body.add_child(container)
	_add_spacer(4)


func _get_category_breakdown(entries: Array) -> Dictionary:
	var breakdown = {}
	for entry in entries:
		var cat = entry.get("category", "helping")
		breakdown[cat] = breakdown.get(cat, 0) + 1
	return breakdown


func _count_entries_this_week(entries: Array) -> int:
	var count = 0
	var today = Time.get_datetime_dict_from_system()
	var today_unix = Time.get_unix_time_from_datetime_dict(today)
	var week_ago = today_unix - (7 * 24 * 60 * 60)

	for entry in entries:
		var date_str = entry.get("date", "")
		if date_str.length() >= 10:
			var parts = date_str.substr(0, 10).split("-")
			if parts.size() >= 3:
				var entry_date = {
					"year": int(parts[0]),
					"month": int(parts[1]),
					"day": int(parts[2]),
					"hour": 0, "minute": 0, "second": 0
				}
				var entry_unix = Time.get_unix_time_from_datetime_dict(entry_date)
				if entry_unix >= week_ago:
					count += 1
	return count


func _calculate_kindness_streak(entries: Array) -> int:
	if entries.is_empty():
		return 0

	# Get unique dates
	var dates = []
	for entry in entries:
		var date_str = entry.get("date", "")
		if date_str.length() >= 10:
			var date_only = date_str.substr(0, 10)
			if not date_only in dates:
				dates.append(date_only)

	dates.sort()
	dates.reverse()

	# Check streak from today
	var today = Time.get_date_string_from_system()
	var streak = 0

	if dates.is_empty():
		return 0

	# If most recent isn't today or yesterday, streak is broken
	var most_recent = dates[0]
	if most_recent != today:
		# Check if it was yesterday
		var today_dict = Time.get_datetime_dict_from_system()
		var today_unix = Time.get_unix_time_from_datetime_dict(today_dict)
		var yesterday_unix = today_unix - (24 * 60 * 60)
		var yesterday_dict = Time.get_datetime_dict_from_unix_time(yesterday_unix)
		var yesterday = "%04d-%02d-%02d" % [yesterday_dict.year, yesterday_dict.month, yesterday_dict.day]

		if most_recent != yesterday:
			return 0

	# Count consecutive days
	for i in range(dates.size()):
		if i == 0:
			streak = 1
			continue

		var current_parts = dates[i-1].split("-")
		var prev_parts = dates[i].split("-")

		if current_parts.size() < 3 or prev_parts.size() < 3:
			break

		var current_dict = {
			"year": int(current_parts[0]),
			"month": int(current_parts[1]),
			"day": int(current_parts[2]),
			"hour": 0, "minute": 0, "second": 0
		}
		var prev_dict = {
			"year": int(prev_parts[0]),
			"month": int(prev_parts[1]),
			"day": int(prev_parts[2]),
			"hour": 0, "minute": 0, "second": 0
		}

		var current_unix = Time.get_unix_time_from_datetime_dict(current_dict)
		var prev_unix = Time.get_unix_time_from_datetime_dict(prev_dict)

		# Check if exactly one day apart
		if current_unix - prev_unix == 24 * 60 * 60:
			streak += 1
		else:
			break

	return streak


func _load_kindness_entries() -> Array:
	var path = "user://kindness_log.json"
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


func _save_kindness_entries(entries: Array) -> void:
	var file = FileAccess.open("user://kindness_log.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(entries, "\t"))
		if SaveManager: SaveManager.sync_web_filesystem()
		file.close()
