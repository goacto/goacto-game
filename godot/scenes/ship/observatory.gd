extends Control
## Observatory - Star-gazing room with a large telescope
## Connect with the cosmos and view constellations

# World elements
@onready var game_world: Control = $GameWorld
@onready var isometric_base: Node2D = $GameWorld/IsometricBase
@onready var player: Node2D = $GameWorld/IsometricBase/Player

# UI
@onready var interaction_prompt: PanelContainer = $InteractionPrompt
@onready var object_name_label: Label = $InteractionPrompt/Margin/VBox/ObjectName
@onready var prompt_text_label: Label = $InteractionPrompt/Margin/VBox/PromptText
@onready var control_hints: HBoxContainer = $ControlHints

# Dialogue
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var dialogue_title: Label = $DialoguePanel/Margin/VBox/DialogueTitle
@onready var dialogue_text: Label = $DialoguePanel/Margin/VBox/DialogueText
@onready var dialogue_button: Button = $DialoguePanel/Margin/VBox/DialogueButton

# Menu
@onready var menu_button: Button = $Header/Margin/HBox/MenuButton

# Fade
@onready var fade_overlay: ColorRect = $FadeOverlay

# Header controls
var volume_button: Button = null
var save_indicator: Label = null
var volume_popup: PanelContainer = null
var is_muted: bool = false

# Player movement
var player_speed: float = 250.0
var player_bounds: Rect2 = Rect2(-400, -200, 800, 450)

# Camera
var camera_zoom: float = 1.0
var min_zoom: float = 0.6
var max_zoom: float = 1.5
var zoom_speed: float = 0.08

# Interaction state
var nearby_object: String = ""
var in_dialogue: bool = false
var dialogue_callback: Callable

# Typing effect
var typing_tween: Tween = null
var dialogue_full_text: String = ""

# Animation
var animation_time: float = 0.0

# Movement sound
var move_sound_timer: float = 0.0
var move_sound_interval: float = 0.35

# Starfield
var stars: Array = []
var constellation_lines: Array = []

# Constellation Mini-game
var constellation_game: Control = null
var constellation_stars: Array = []  # {node, position, id, connected}
var selected_star: int = -1
var drawn_lines: Array = []  # Lines player has drawn
var current_constellation: Dictionary = {}
var completed_constellations: Array = []

# Constellation definitions
const CONSTELLATIONS = [
	{
		"id": "the_grower",
		"name": "The Grower",
		"description": "Ancient Goactorians saw this as a symbol of nurturing potential.",
		"aspect": "discipline",
		"stars": [
			Vector2(0.5, 0.2),    # Head
			Vector2(0.35, 0.4),   # Left shoulder
			Vector2(0.65, 0.4),   # Right shoulder
			Vector2(0.3, 0.7),    # Left hand (holding plant)
			Vector2(0.7, 0.65),   # Right hand
			Vector2(0.5, 0.85)    # Plant/growth
		],
		"connections": [[0, 1], [0, 2], [1, 3], [2, 4], [3, 5], [4, 5]],
		"reward_xp": 30
	},
	{
		"id": "the_disciplined_one",
		"name": "The Disciplined One",
		"description": "Its steady light represents unwavering commitment.",
		"aspect": "discipline",
		"stars": [
			Vector2(0.5, 0.15),   # Crown
			Vector2(0.5, 0.3),    # Head
			Vector2(0.35, 0.45),  # Left arm
			Vector2(0.65, 0.45),  # Right arm
			Vector2(0.5, 0.6),    # Core
			Vector2(0.4, 0.85),   # Left foot
			Vector2(0.6, 0.85)    # Right foot
		],
		"connections": [[0, 1], [1, 2], [1, 3], [1, 4], [4, 5], [4, 6]],
		"reward_xp": 35
	},
	{
		"id": "the_courage_bearer",
		"name": "The Courage Bearer",
		"description": "A warrior constellation facing the void. Facing fear makes us shine brighter.",
		"aspect": "courage",
		"stars": [
			Vector2(0.5, 0.2),    # Head
			Vector2(0.5, 0.4),    # Chest
			Vector2(0.25, 0.35),  # Shield left
			Vector2(0.3, 0.5),    # Shield bottom
			Vector2(0.75, 0.3),   # Sword tip
			Vector2(0.65, 0.45),  # Sword mid
			Vector2(0.5, 0.7),    # Waist
			Vector2(0.4, 0.9),    # Left leg
			Vector2(0.6, 0.9)     # Right leg
		],
		"connections": [[0, 1], [1, 2], [2, 3], [1, 3], [1, 5], [5, 4], [1, 6], [6, 7], [6, 8]],
		"reward_xp": 45
	},
	{
		"id": "the_wise_seeker",
		"name": "The Wise Seeker",
		"description": "Forever searching for truth among the stars.",
		"aspect": "wisdom",
		"stars": [
			Vector2(0.5, 0.15),   # Third eye
			Vector2(0.4, 0.3),    # Left eye
			Vector2(0.6, 0.3),    # Right eye
			Vector2(0.5, 0.45),   # Nose/center
			Vector2(0.3, 0.6),    # Left scroll
			Vector2(0.7, 0.6),    # Right scroll
			Vector2(0.5, 0.8)     # Wisdom light
		],
		"connections": [[0, 1], [0, 2], [1, 3], [2, 3], [3, 4], [3, 5], [4, 6], [5, 6]],
		"reward_xp": 40
	},
	{
		"id": "the_compassionate_heart",
		"name": "The Compassionate Heart",
		"description": "Love radiates outward, touching all who see it.",
		"aspect": "compassion",
		"stars": [
			Vector2(0.5, 0.25),   # Top of heart
			Vector2(0.3, 0.35),   # Left lobe
			Vector2(0.7, 0.35),   # Right lobe
			Vector2(0.2, 0.5),    # Left ray
			Vector2(0.8, 0.5),    # Right ray
			Vector2(0.5, 0.7),    # Heart bottom
			Vector2(0.35, 0.85),  # Left glow
			Vector2(0.65, 0.85)   # Right glow
		],
		"connections": [[0, 1], [0, 2], [1, 3], [2, 4], [1, 5], [2, 5], [5, 6], [5, 7]],
		"reward_xp": 40
	}
]

# Interactive objects
const INTERACTIVE_OBJECTS = {
	"HallwayDoor": {
		"name": "Hallway Door",
		"prompt": "Press SPACE to return to hallway",
		"action": "go_hallway"
	},
	"MainTelescope": {
		"name": "Stellar Telescope",
		"prompt": "Press SPACE to observe the cosmos",
		"action": "use_telescope"
	},
	"ConstellationMap": {
		"name": "Constellation Display",
		"prompt": "Press SPACE to study constellations",
		"action": "view_constellations"
	},
	"StarChart": {
		"name": "Navigation Star Chart",
		"prompt": "Press SPACE to examine",
		"action": "examine_chart"
	},
	"ObservationSeat": {
		"name": "Observation Chair",
		"prompt": "Press SPACE to sit and reflect",
		"action": "sit_reflect"
	}
}

# Object positions
var object_positions: Dictionary = {
	"HallwayDoor": Vector2(-350, 0),
	"MainTelescope": Vector2(100, -80),
	"ConstellationMap": Vector2(-150, -120),
	"StarChart": Vector2(250, 50),
	"ObservationSeat": Vector2(-50, 100)
}

# Focus Dashboard
var focus_dashboard: Control = null
var dashboard_current_tab: String = "overview"


func _ready() -> void:
	# Connect dialogue button
	dialogue_button.pressed.connect(_close_dialogue)

	# Connect menu button
	menu_button.pressed.connect(_open_pause_menu)

	# Setup header controls
	_setup_header_controls()

	# Play ship music and ambient sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		if audio.has_method("play_music_ship"):
			audio.play_music_ship()
		if audio.has_method("play_ambient_ship"):
			audio.play_ambient_ship()

	# Hide UI initially
	interaction_prompt.visible = false
	dialogue_panel.visible = false

	# Position player near door
	if GameManager.player_data.get("came_from_hallway", false):
		player.position = Vector2(-280, 0)
		GameManager.player_data.erase("came_from_hallway")
	else:
		player.position = Vector2(-280, 0)

	# Setup starfield and constellations
	_create_starfield()
	_create_constellation_display()
	_create_focus_analytics_terminal()

	# Load telescope discoveries
	telescope_discovered = GameManager.player_data.get("telescope_discoveries", [])

	# Center the view
	_update_camera()

	# Fade in
	_fade_in()

	# Show first-time dialogue
	if not CampaignManager.has_seen_cutscene("observatory_first_visit"):
		CampaignManager.mark_cutscene_seen("observatory_first_visit")
		await get_tree().create_timer(0.8).timeout
		_show_dialogue("Observatory", "The ship's observation dome...\n\n*Thousands of stars twinkle through the transparent ceiling*\n\nFrom here, you can see the vastness of the galaxy stretching in every direction.")

	print("[Observatory] Observation dome ready")


func _fade_in() -> void:
	if fade_overlay:
		var tween = create_tween()
		tween.tween_property(fade_overlay, "color:a", 0.0, 0.5).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	animation_time += delta

	# Animate starfield
	_animate_stars(delta)

	# Handle telescope panning when open
	if telescope_panel:
		_handle_telescope_pan(delta)
		return

	if in_dialogue:
		return

	# Check object proximity
	_check_object_proximity()

	# Handle movement
	_handle_movement(delta)

	# Update camera
	_update_camera()


func _handle_telescope_pan(delta: float) -> void:
	var pan_speed = 300.0
	var pan_dir = Vector2.ZERO

	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"):
		pan_dir.x += 1  # Move view right to see left objects
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"):
		pan_dir.x -= 1
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("ui_up"):
		pan_dir.y += 1
	if Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down"):
		pan_dir.y -= 1

	if pan_dir != Vector2.ZERO:
		telescope_view_offset += pan_dir * pan_speed * delta
		# Clamp to reasonable bounds (allows reaching all celestial objects)
		telescope_view_offset.x = clamp(telescope_view_offset.x, -500, 500)
		telescope_view_offset.y = clamp(telescope_view_offset.y, -450, 450)

		# Update star container position
		var star_container = telescope_panel.find_child("StarContainer", true, false)
		if star_container:
			star_container.position = Vector2(200, 175) + telescope_view_offset


func _input(event: InputEvent) -> void:
	var viewport = get_viewport()
	if viewport == null:
		return

	# ESC to close panels or open pause menu
	if event.is_action_pressed("ui_cancel"):
		if telescope_panel:
			_close_telescope_viewer()
			viewport.set_input_as_handled()
			return
		if meditation_panel:
			_close_meditation_panel()
			viewport.set_input_as_handled()
			return
		if volume_popup:
			_close_volume_popup()
			viewport.set_input_as_handled()
			return
		if pause_menu:
			_close_pause_menu()
			viewport.set_input_as_handled()
			return
		if dialogue_panel.visible:
			_close_dialogue()
			viewport.set_input_as_handled()
			return
		_open_pause_menu()
		viewport.set_input_as_handled()
		return

	if in_dialogue:
		if event.is_action_pressed("ui_accept"):
			_close_dialogue()
			viewport.set_input_as_handled()
		return

	# Interact with nearby object
	if event.is_action_pressed("ui_accept") and nearby_object != "":
		_interact_with_object(nearby_object)
		viewport.set_input_as_handled()

	# M key to toggle mute
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		if not pause_menu and not in_dialogue:
			_toggle_mute()
			viewport.set_input_as_handled()
			return

	# Touch/click interaction
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if nearby_object != "" and interaction_prompt.visible:
			_interact_with_object(nearby_object)

	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(zoom_speed)
			viewport.set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(-zoom_speed)
			viewport.set_input_as_handled()


func _apply_zoom(delta_zoom: float) -> void:
	camera_zoom = clamp(camera_zoom + delta_zoom, min_zoom, max_zoom)
	_update_camera()


func _handle_movement(delta: float) -> void:
	var input_dir = Vector2.ZERO

	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		var iso_movement = Vector2(input_dir.x - input_dir.y * 0.5, input_dir.y * 0.5 + input_dir.x * 0.3)
		var new_pos = player.position + iso_movement * player_speed * delta
		new_pos.x = clamp(new_pos.x, player_bounds.position.x, player_bounds.position.x + player_bounds.size.x)
		new_pos.y = clamp(new_pos.y, player_bounds.position.y, player_bounds.position.y + player_bounds.size.y)
		player.position = new_pos

		# Movement sound
		move_sound_timer += delta
		if move_sound_timer >= move_sound_interval:
			move_sound_timer = 0.0
			_play_sfx("res://audio/sfx/footstep_ship.wav", -12.0)


func _update_camera() -> void:
	var screen_center = get_viewport_rect().size / 2
	var target_pos = screen_center - (player.position * camera_zoom)
	isometric_base.position = target_pos
	isometric_base.scale = Vector2(camera_zoom, camera_zoom)


func _check_object_proximity() -> void:
	var closest_object = ""
	var closest_distance = 120.0

	for obj_name in object_positions:
		var obj_pos = object_positions[obj_name]
		var distance = player.position.distance_to(obj_pos)

		if distance < closest_distance:
			closest_distance = distance
			closest_object = obj_name

	if closest_object != nearby_object:
		nearby_object = closest_object
		if nearby_object != "":
			_show_interaction_prompt(nearby_object)
		else:
			_hide_interaction_prompt()


func _show_interaction_prompt(obj_name: String) -> void:
	if INTERACTIVE_OBJECTS.has(obj_name):
		var obj = INTERACTIVE_OBJECTS[obj_name]
		object_name_label.text = obj.name
		prompt_text_label.text = obj.prompt
		interaction_prompt.visible = true


func _hide_interaction_prompt() -> void:
	interaction_prompt.visible = false


func _interact_with_object(obj_name: String) -> void:
	if not INTERACTIVE_OBJECTS.has(obj_name):
		return

	var obj = INTERACTIVE_OBJECTS[obj_name]
	var action = obj.action

	match action:
		"go_hallway":
			_play_sfx("res://audio/sfx/door_open.wav")
			GameManager.player_data["came_from_observatory"] = true
			GameManager.goto_scene("res://scenes/ship/hallway.tscn")
		"use_telescope":
			_use_telescope()
		"view_constellations":
			_view_constellations()
		"examine_chart":
			_examine_chart()
		"sit_reflect":
			_sit_and_reflect()


var telescope_panel: PanelContainer = null
var telescope_view_offset: Vector2 = Vector2.ZERO
var telescope_zoom: float = 1.0
var telescope_discovered: Array = []  # Track discovered objects

const CELESTIAL_OBJECTS = [
	{"name": "Nebula Primordis", "type": "nebula", "pos": Vector2(380, 280), "color": Color(0.6, 0.3, 0.8), "desc": "A swirling cloud of cosmic dust where new stars are born."},
	{"name": "Binary Suns of Korrath", "type": "binary", "pos": Vector2(-420, -320), "color": Color(1.0, 0.8, 0.4), "desc": "Two ancient suns locked in an eternal dance."},
	{"name": "The Wandering Comet", "type": "comet", "pos": Vector2(450, -380), "color": Color(0.7, 0.9, 1.0), "desc": "A lonely traveler crossing the void every 500 years."},
	{"name": "Planet Serenix", "type": "planet", "pos": Vector2(-380, 350), "color": Color(0.3, 0.6, 0.9), "desc": "A peaceful water world, home to bioluminescent creatures."},
	{"name": "The Dark Veil", "type": "anomaly", "pos": Vector2(50, -420), "color": Color(0.2, 0.1, 0.3), "desc": "A mysterious region where light itself seems to rest."},
	{"name": "Stellar Nursery Zyx-7", "type": "nebula", "pos": Vector2(-480, -50), "color": Color(0.9, 0.5, 0.6), "desc": "Named after your great-elder who discovered it."},
]

func _use_telescope() -> void:
	if telescope_panel:
		return
	_open_telescope_viewer()


func _open_telescope_viewer() -> void:
	_play_sfx("res://audio/sfx/ui_open.wav")
	interaction_prompt.visible = false
	in_dialogue = true

	telescope_panel = PanelContainer.new()
	telescope_panel.name = "TelescopePanel"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.05, 0.98)
	style.border_color = Color(0.3, 0.4, 0.6, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	telescope_panel.add_theme_stylebox_override("panel", style)

	telescope_panel.set_anchors_preset(Control.PRESET_CENTER)
	telescope_panel.offset_left = -350
	telescope_panel.offset_right = 350
	telescope_panel.offset_top = -280
	telescope_panel.offset_bottom = 280

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	telescope_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var title = Label.new()
	title.text = "Stellar Telescope"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.pressed.connect(_close_telescope_viewer)
	header.add_child(close_btn)

	# Telescope viewport
	var view_container = PanelContainer.new()
	var view_style = StyleBoxFlat.new()
	view_style.bg_color = Color(0.01, 0.01, 0.02, 1.0)
	view_style.border_color = Color(0.2, 0.25, 0.35, 0.8)
	view_style.set_border_width_all(2)
	view_style.set_corner_radius_all(100)  # Circular view
	view_container.add_theme_stylebox_override("panel", view_style)
	view_container.custom_minimum_size = Vector2(400, 350)
	vbox.add_child(view_container)

	var telescope_view = Control.new()
	telescope_view.name = "TelescopeView"
	telescope_view.custom_minimum_size = Vector2(400, 350)
	telescope_view.clip_contents = true
	view_container.add_child(telescope_view)

	# Create starfield and celestial objects
	_populate_telescope_view(telescope_view)

	# Controls hint
	var hint = Label.new()
	hint.text = "Arrow keys to pan | +/- to zoom | Click objects to discover"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	# Discovery counter
	var discovered_label = Label.new()
	discovered_label.name = "DiscoveredLabel"
	discovered_label.text = "Discovered: %d / %d" % [telescope_discovered.size(), CELESTIAL_OBJECTS.size()]
	discovered_label.add_theme_font_size_override("font_size", 14)
	discovered_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.5))
	discovered_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(discovered_label)

	add_child(telescope_panel)


func _populate_telescope_view(view: Control) -> void:
	var star_container = Node2D.new()
	star_container.name = "StarContainer"
	star_container.position = Vector2(200, 175)  # Center of view
	view.add_child(star_container)

	# Random background stars
	for i in range(80):
		var star = Polygon2D.new()
		var size = randf_range(1, 3)
		star.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(0, -size), Vector2(size, 0), Vector2(0, size)
		])
		star.position = Vector2(randf_range(-300, 300), randf_range(-250, 250))
		star.color = Color(1.0, 1.0, 1.0, randf_range(0.3, 0.8))
		star_container.add_child(star)

	# Add celestial objects
	for obj in CELESTIAL_OBJECTS:
		var celestial = _create_celestial_object(obj)
		star_container.add_child(celestial)


func _create_celestial_object(data: Dictionary) -> Node2D:
	var obj = Node2D.new()
	obj.name = data.name.replace(" ", "_")
	obj.position = data.pos
	obj.set_meta("celestial_data", data)

	var is_discovered = data.name in telescope_discovered

	match data.type:
		"nebula":
			# Glowing cloud
			for i in range(5):
				var cloud = Polygon2D.new()
				var s = 20 + i * 8
				cloud.polygon = PackedVector2Array([
					Vector2(-s, -s/2), Vector2(0, -s), Vector2(s, -s/2),
					Vector2(s, s/2), Vector2(0, s), Vector2(-s, s/2)
				])
				cloud.color = Color(data.color.r, data.color.g, data.color.b, 0.15 - i * 0.02)
				obj.add_child(cloud)
		"binary":
			# Two orbiting stars
			for i in range(2):
				var star = Polygon2D.new()
				star.polygon = PackedVector2Array([
					Vector2(-8, 0), Vector2(0, -8), Vector2(8, 0), Vector2(0, 8)
				])
				star.position = Vector2(-12 if i == 0 else 12, 0)
				star.color = data.color
				obj.add_child(star)
		"comet":
			# Head and tail
			var head = Polygon2D.new()
			head.polygon = PackedVector2Array([
				Vector2(-6, 0), Vector2(0, -6), Vector2(6, 0), Vector2(0, 6)
			])
			head.color = data.color
			obj.add_child(head)
			var tail = Polygon2D.new()
			tail.polygon = PackedVector2Array([
				Vector2(6, -2), Vector2(40, 0), Vector2(6, 2)
			])
			tail.color = Color(data.color.r, data.color.g, data.color.b, 0.4)
			obj.add_child(tail)
		"planet":
			var planet = Polygon2D.new()
			var pts = PackedVector2Array()
			for i in range(16):
				var angle = i * TAU / 16
				pts.append(Vector2(cos(angle) * 15, sin(angle) * 15))
			planet.polygon = pts
			planet.color = data.color
			obj.add_child(planet)
		"anomaly":
			# Dark swirling void
			for i in range(3):
				var ring = Polygon2D.new()
				var pts = PackedVector2Array()
				var r = 12 + i * 6
				for j in range(12):
					var angle = j * TAU / 12
					pts.append(Vector2(cos(angle) * r, sin(angle) * r))
				ring.polygon = pts
				ring.color = Color(data.color.r, data.color.g, data.color.b, 0.3 - i * 0.08)
				obj.add_child(ring)

	# Add interaction area
	var btn = Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(50, 50)
	btn.position = Vector2(-25, -25)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func(): _discover_celestial(data))
	obj.add_child(btn)

	# Label if discovered
	if is_discovered:
		var lbl = Label.new()
		lbl.text = data.name
		lbl.position = Vector2(-40, 20)
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6, 0.8))
		obj.add_child(lbl)

	return obj


func _discover_celestial(data: Dictionary) -> void:
	if data.name in telescope_discovered:
		# Already discovered - show info
		_show_dialogue(data.name, data.desc + "\n\n*Already logged in your star journal*")
	else:
		# New discovery!
		telescope_discovered.append(data.name)
		GameManager.player_data["telescope_discoveries"] = telescope_discovered
		SaveManager.save_game()

		_play_sfx("res://audio/sfx/select_confirm.wav")

		# Update counter immediately
		if telescope_panel:
			var label = telescope_panel.find_child("DiscoveredLabel", true, false)
			if label:
				label.text = "Discovered: %d / %d" % [telescope_discovered.size(), CELESTIAL_OBJECTS.size()]

		# Close telescope first, then show dialogue
		_close_telescope_viewer()
		await get_tree().create_timer(0.1).timeout
		_show_dialogue("New Discovery!", "You've discovered: " + data.name + "\n\n" + data.desc + "\n\n*Logged in your star journal*")


func _close_telescope_viewer() -> void:
	if telescope_panel:
		telescope_panel.queue_free()
		telescope_panel = null
	telescope_view_offset = Vector2.ZERO
	in_dialogue = false


func _view_constellations() -> void:
	_open_constellation_game()


func _examine_chart() -> void:
	_show_dialogue("Navigation Star Chart", "This chart shows our voyage across the galaxy.\n\n*You trace the winding path with your finger*\n\nWe've traveled through 47 star systems so far. The journey continues for another 23 years before we reach our destination.\n\nPlenty of time to help many humans grow.")


var meditation_panel: PanelContainer = null
var breathing_circle: Control = null
var breath_phase: String = "inhale"
var breath_timer: float = 0.0
var breath_cycle_time: float = 4.0
var meditation_active: bool = false

const AFFIRMATIONS = [
	"Growth happens one breath at a time.",
	"You are exactly where you need to be.",
	"Every small step creates lasting change.",
	"Your potential is limitless.",
	"Today's effort shapes tomorrow's strength.",
	"Connection begins within.",
	"The universe supports your journey.",
	"Peace flows through you like starlight.",
]

func _sit_and_reflect() -> void:
	if meditation_panel:
		return
	_open_meditation_panel()


func _open_meditation_panel() -> void:
	_play_sfx("res://audio/sfx/ui_open.wav")
	interaction_prompt.visible = false
	meditation_active = true
	in_dialogue = true

	meditation_panel = PanelContainer.new()
	meditation_panel.name = "MeditationPanel"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.95)
	style.border_color = Color(0.4, 0.3, 0.6, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	meditation_panel.add_theme_stylebox_override("panel", style)

	meditation_panel.set_anchors_preset(Control.PRESET_CENTER)
	meditation_panel.offset_left = -280
	meditation_panel.offset_right = 280
	meditation_panel.offset_top = -250
	meditation_panel.offset_bottom = 250

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	meditation_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var title = Label.new()
	title.text = "Quiet Reflection"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.pressed.connect(_close_meditation_panel)
	header.add_child(close_btn)

	# Stats summary
	var sessions = GameManager.player_data.get("total_focus_sessions", 0)
	var aspects = CampaignManager.campaign_state.aspects_awakened.size()
	var stats_label = Label.new()
	stats_label.text = "%d focus sessions | %d aspects awakened" % [sessions, aspects]
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)

	# Breathing circle container
	var circle_container = CenterContainer.new()
	circle_container.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(circle_container)

	breathing_circle = Control.new()
	breathing_circle.name = "BreathingCircle"
	breathing_circle.custom_minimum_size = Vector2(150, 150)
	circle_container.add_child(breathing_circle)

	# Draw the breathing circle
	var circle_visual = _create_breathing_circle_visual()
	breathing_circle.add_child(circle_visual)

	# Breath instruction
	var breath_label = Label.new()
	breath_label.name = "BreathLabel"
	breath_label.text = "Breathe in..."
	breath_label.add_theme_font_size_override("font_size", 22)
	breath_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.9))
	breath_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(breath_label)

	# Affirmation
	var affirmation = Label.new()
	affirmation.name = "Affirmation"
	affirmation.text = AFFIRMATIONS[randi() % AFFIRMATIONS.size()]
	affirmation.add_theme_font_size_override("font_size", 16)
	affirmation.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
	affirmation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	affirmation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(affirmation)

	# Session buttons
	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)

	var quick_btn = Button.new()
	quick_btn.text = "1 Min Calm"
	quick_btn.custom_minimum_size = Vector2(120, 45)
	quick_btn.pressed.connect(func(): _start_timed_meditation(60))
	btn_container.add_child(quick_btn)

	var medium_btn = Button.new()
	medium_btn.text = "3 Min Peace"
	medium_btn.custom_minimum_size = Vector2(120, 45)
	medium_btn.pressed.connect(func(): _start_timed_meditation(180))
	btn_container.add_child(medium_btn)

	add_child(meditation_panel)

	# Start breathing animation
	_start_breathing_cycle()


func _create_breathing_circle_visual() -> Node2D:
	var visual = Node2D.new()
	visual.name = "CircleVisual"
	visual.position = Vector2(75, 75)

	# Outer glow rings
	for i in range(3):
		var ring = Polygon2D.new()
		ring.name = "Ring%d" % i
		var pts = PackedVector2Array()
		var r = 50 + i * 15
		for j in range(32):
			var angle = j * TAU / 32
			pts.append(Vector2(cos(angle) * r, sin(angle) * r))
		ring.polygon = pts
		ring.color = Color(0.4, 0.5, 0.8, 0.15 - i * 0.04)
		visual.add_child(ring)

	# Main circle
	var main_circle = Polygon2D.new()
	main_circle.name = "MainCircle"
	var pts = PackedVector2Array()
	for i in range(32):
		var angle = i * TAU / 32
		pts.append(Vector2(cos(angle) * 40, sin(angle) * 40))
	main_circle.polygon = pts
	main_circle.color = Color(0.5, 0.6, 0.9, 0.6)
	visual.add_child(main_circle)

	# Inner glow
	var inner = Polygon2D.new()
	inner.name = "InnerGlow"
	pts = PackedVector2Array()
	for i in range(32):
		var angle = i * TAU / 32
		pts.append(Vector2(cos(angle) * 25, sin(angle) * 25))
	inner.polygon = pts
	inner.color = Color(0.7, 0.8, 1.0, 0.4)
	visual.add_child(inner)

	return visual


func _start_breathing_cycle() -> void:
	if not meditation_panel or not breathing_circle:
		return

	var visual = breathing_circle.get_node_or_null("CircleVisual")
	var breath_label = meditation_panel.find_child("BreathLabel", true, false)
	if not visual:
		return

	# Create breathing animation tween
	var tween = create_tween()
	tween.set_loops()

	# Inhale - expand
	tween.tween_property(visual, "scale", Vector2(1.3, 1.3), breath_cycle_time).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		if breath_label:
			breath_label.text = "Hold..."
	)
	tween.tween_interval(1.5)

	# Exhale - contract
	tween.tween_callback(func():
		if breath_label:
			breath_label.text = "Breathe out..."
	)
	tween.tween_property(visual, "scale", Vector2(0.8, 0.8), breath_cycle_time).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		if breath_label:
			breath_label.text = "Breathe in..."
		# Change affirmation
		var affirmation = meditation_panel.find_child("Affirmation", true, false) if meditation_panel else null
		if affirmation:
			affirmation.text = AFFIRMATIONS[randi() % AFFIRMATIONS.size()]
	)
	tween.tween_interval(1.0)


func _start_timed_meditation(seconds: int) -> void:
	# Enter meditation audio state
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("enter_meditation_mode"):
		audio.enter_meditation_mode()

	# Show countdown timer
	var timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.add_theme_font_size_override("font_size", 18)
	timer_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.5))
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if meditation_panel:
		var existing = meditation_panel.find_child("TimerLabel", true, false)
		if existing:
			existing.queue_free()

		var margin = meditation_panel.get_child(0)
		if margin:
			var vbox = margin.get_child(0)
			if vbox:
				vbox.add_child(timer_label)

	# Start countdown
	var remaining = seconds
	while remaining > 0 and meditation_panel:
		timer_label.text = "Time remaining: %d:%02d" % [remaining / 60, remaining % 60]
		await get_tree().create_timer(1.0).timeout
		remaining -= 1

	if meditation_panel:
		timer_label.text = "Session complete!"
		_play_sfx("res://audio/sfx/select_confirm.wav")

		# Award small XP bonus
		if GameManager.has_method("add_aspect_experience"):
			GameManager.add_aspect_experience("wisdom", 5)

		await get_tree().create_timer(2.0).timeout
		_close_meditation_panel()


func _close_meditation_panel() -> void:
	meditation_active = false
	in_dialogue = false

	# Exit meditation audio state
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("exit_meditation_mode"):
		audio.exit_meditation_mode()

	if meditation_panel:
		meditation_panel.queue_free()
		meditation_panel = null
	breathing_circle = null


func _show_dialogue(title: String, text: String, callback: Callable = Callable()) -> void:
	dialogue_title.text = title
	dialogue_full_text = text
	dialogue_text.text = ""
	dialogue_panel.visible = true
	in_dialogue = true
	dialogue_callback = callback
	interaction_prompt.visible = false

	# Start typing effect
	if typing_tween and typing_tween.is_running():
		typing_tween.kill()

	typing_tween = create_tween()
	if typing_tween:
		typing_tween.tween_method(_update_dialogue_text, 0, dialogue_full_text.length(), dialogue_full_text.length() * 0.03)


func _update_dialogue_text(char_count: int) -> void:
	dialogue_text.text = dialogue_full_text.substr(0, char_count)


func _close_dialogue() -> void:
	if typing_tween and typing_tween.is_running():
		typing_tween.kill()
		dialogue_text.text = dialogue_full_text
		return

	dialogue_panel.visible = false
	in_dialogue = false

	if dialogue_callback.is_valid():
		dialogue_callback.call()
		dialogue_callback = Callable()


func _play_sfx(sfx_path: String, _volume_db: float = 0.0) -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx_from_path"):
		audio.play_sfx_from_path(sfx_path)

# ============ STARFIELD ============

func _create_starfield() -> void:
	var star_container = isometric_base.get_node_or_null("Stars")
	if not star_container:
		star_container = Node2D.new()
		star_container.name = "Stars"
		star_container.z_index = -10
		isometric_base.add_child(star_container)

	# Create many twinkling stars
	for i in range(80):
		var star = Polygon2D.new()
		var size = randf_range(1.5, 4.0)
		star.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(0, -size), Vector2(size, 0), Vector2(0, size)
		])
		star.position = Vector2(randf_range(-500, 500), randf_range(-350, 200))
		star.color = Color(1.0, 1.0, randf_range(0.8, 1.0), randf_range(0.3, 0.9))
		star_container.add_child(star)
		stars.append({
			"node": star,
			"base_alpha": star.color.a,
			"phase": randf() * TAU,
			"speed": randf_range(1.5, 3.0)
		})


func _create_constellation_display() -> void:
	# The constellation display is a holographic element
	var display = isometric_base.get_node_or_null("ConstellationDisplay")
	if display:
		return

	display = Node2D.new()
	display.name = "ConstellationDisplay"
	display.position = object_positions["ConstellationMap"]
	isometric_base.add_child(display)

	# Create a few constellation stars connected by lines
	var const_stars = [
		Vector2(0, -30), Vector2(-20, -10), Vector2(20, -10),
		Vector2(-15, 20), Vector2(15, 20)
	]

	for pos in const_stars:
		var star = Polygon2D.new()
		star.polygon = PackedVector2Array([
			Vector2(-3, 0), Vector2(0, -3), Vector2(3, 0), Vector2(0, 3)
		])
		star.position = pos
		star.color = Color(0.6, 0.8, 1.0, 0.8)
		display.add_child(star)


func _create_focus_analytics_terminal() -> void:
	# Create the Focus Analytics terminal visual
	var terminal = Node2D.new()
	terminal.name = "FocusAnalyticsTerminal"
	terminal.position = object_positions["FocusAnalytics"]
	isometric_base.add_child(terminal)

	# Terminal base/stand
	var stand = Polygon2D.new()
	stand.name = "Stand"
	stand.polygon = PackedVector2Array([
		Vector2(-25, 0), Vector2(25, 0),
		Vector2(20, 30), Vector2(-20, 30)
	])
	stand.color = Color(0.15, 0.18, 0.25, 0.9)
	terminal.add_child(stand)

	# Screen frame
	var frame = Polygon2D.new()
	frame.name = "Frame"
	frame.polygon = PackedVector2Array([
		Vector2(-35, -60), Vector2(35, -60),
		Vector2(35, 0), Vector2(-35, 0)
	])
	frame.color = Color(0.2, 0.22, 0.3, 0.95)
	terminal.add_child(frame)

	# Screen
	var screen = Polygon2D.new()
	screen.name = "Screen"
	screen.polygon = PackedVector2Array([
		Vector2(-30, -55), Vector2(30, -55),
		Vector2(30, -5), Vector2(-30, -5)
	])
	screen.color = Color(0.08, 0.12, 0.18, 0.95)
	terminal.add_child(screen)

	# Screen glow
	var screen_glow = Polygon2D.new()
	screen_glow.name = "ScreenGlow"
	screen_glow.polygon = PackedVector2Array([
		Vector2(-28, -53), Vector2(28, -53),
		Vector2(28, -7), Vector2(-28, -7)
	])
	screen_glow.color = Color(0.3, 0.6, 0.9, 0.15)
	terminal.add_child(screen_glow)

	# Graph bars on screen (visualization preview)
	var bar_heights = [15, 25, 20, 35, 18, 28]
	for i in range(6):
		var bar = Polygon2D.new()
		bar.name = "Bar%d" % i
		var x = -22 + i * 9
		var h = bar_heights[i]
		bar.polygon = PackedVector2Array([
			Vector2(x, -10), Vector2(x + 6, -10),
			Vector2(x + 6, -10 - h), Vector2(x, -10 - h)
		])
		bar.color = Color(0.4, 0.7, 0.95, 0.7)
		terminal.add_child(bar)

	# Analytics icon (small chart symbol)
	var icon = Polygon2D.new()
	icon.name = "Icon"
	icon.polygon = PackedVector2Array([
		Vector2(-8, -70), Vector2(8, -70),
		Vector2(8, -62), Vector2(-8, -62)
	])
	icon.color = Color(0.4, 0.7, 0.95, 0.8)
	terminal.add_child(icon)


func _animate_stars(delta: float) -> void:
	for star_data in stars:
		var star = star_data.node as Polygon2D
		if star:
			star_data.phase += delta * star_data.speed
			var twinkle = (sin(star_data.phase) + 1.0) / 2.0
			star.color.a = star_data.base_alpha * (0.5 + twinkle * 0.5)


# ============ HEADER CONTROLS ============

func _setup_header_controls() -> void:
	var header_hbox = get_node_or_null("Header/Margin/HBox")
	if not header_hbox:
		return

	# Volume button
	volume_button = Button.new()
	volume_button.text = "Vol"
	volume_button.custom_minimum_size = Vector2(50, 35)
	volume_button.add_theme_font_size_override("font_size", 14)
	volume_button.pressed.connect(_toggle_volume_popup)
	header_hbox.add_child(volume_button)

	# Save indicator
	save_indicator = Label.new()
	save_indicator.text = ""
	save_indicator.add_theme_font_size_override("font_size", 12)
	save_indicator.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	header_hbox.add_child(save_indicator)


func _toggle_volume_popup() -> void:
	if volume_popup:
		_close_volume_popup()
	else:
		_open_volume_popup()


func _open_volume_popup() -> void:
	if volume_popup:
		return

	volume_popup = PanelContainer.new()
	volume_popup.name = "VolumePopup"
	volume_popup.position = Vector2(volume_button.global_position.x, volume_button.global_position.y + 40)
	volume_popup.custom_minimum_size = Vector2(150, 80)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.set_corner_radius_all(8)
	volume_popup.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_child(vbox)
	volume_popup.add_child(margin)

	var mute_btn = Button.new()
	mute_btn.text = "Unmute" if is_muted else "Mute"
	mute_btn.pressed.connect(_toggle_mute)
	vbox.add_child(mute_btn)

	add_child(volume_popup)


func _close_volume_popup() -> void:
	if volume_popup:
		volume_popup.queue_free()
		volume_popup = null


func _toggle_mute() -> void:
	is_muted = not is_muted
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("set_muted"):
		audio.set_muted(is_muted)

	if volume_popup:
		var mute_btn = volume_popup.get_node_or_null("MarginContainer/VBoxContainer/Button")
		if mute_btn:
			mute_btn.text = "Unmute" if is_muted else "Mute"


# ============ PAUSE MENU ============

var pause_menu: PanelContainer = null

func _open_pause_menu() -> void:
	if pause_menu:
		return

	pause_menu = PanelContainer.new()
	pause_menu.name = "PauseMenu"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.98)
	style.border_color = Color(0.4, 0.35, 0.5, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	pause_menu.add_theme_stylebox_override("panel", style)

	pause_menu.set_anchors_preset(Control.PRESET_CENTER)
	pause_menu.offset_left = -150
	pause_menu.offset_right = 150
	pause_menu.offset_top = -120
	pause_menu.offset_bottom = 120

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	pause_menu.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Paused"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.custom_minimum_size = Vector2(200, 45)
	resume_btn.pressed.connect(_close_pause_menu)
	vbox.add_child(resume_btn)

	var settings_btn = Button.new()
	settings_btn.text = "Settings"
	settings_btn.custom_minimum_size = Vector2(200, 45)
	settings_btn.pressed.connect(_go_to_settings)
	vbox.add_child(settings_btn)

	add_child(pause_menu)


func _close_pause_menu() -> void:
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null


func _go_to_settings() -> void:
	_close_pause_menu()
	GameManager.goto_scene("res://scenes/settings/settings.tscn")


# =============================================================================
# FOCUS ANALYTICS DASHBOARD
# =============================================================================

const DASHBOARD_BG = Color(0.06, 0.07, 0.1, 0.98)
const DASHBOARD_PANEL = Color(0.1, 0.11, 0.15, 0.95)
const DASHBOARD_ACCENT = Color(0.4, 0.7, 0.95)
const DASHBOARD_TEXT = Color(0.85, 0.88, 0.92)
const DASHBOARD_MUTED = Color(0.5, 0.52, 0.58)

var dashboard_data: Dictionary = {}


func _open_focus_dashboard() -> void:
	if focus_dashboard:
		return

	_play_sfx("res://audio/sfx/ui_open.wav")
	interaction_prompt.visible = false

	# Calculate all stats first
	_calculate_dashboard_data()

	# Create dashboard panel
	focus_dashboard = Control.new()
	focus_dashboard.name = "FocusDashboard"
	focus_dashboard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(focus_dashboard)

	# Dim background
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_dashboard.add_child(dim)

	# Main panel
	var panel = PanelContainer.new()
	panel.name = "MainPanel"
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = DASHBOARD_BG
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.border_color = DASHBOARD_ACCENT.darkened(0.3)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(900, 600)
	panel.offset_left = -450
	panel.offset_right = 450
	panel.offset_top = -300
	panel.offset_bottom = 300
	focus_dashboard.add_child(panel)

	var main_margin = MarginContainer.new()
	main_margin.add_theme_constant_override("margin_left", 20)
	main_margin.add_theme_constant_override("margin_right", 20)
	main_margin.add_theme_constant_override("margin_top", 15)
	main_margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(main_margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	main_margin.add_child(main_vbox)

	# Header
	_create_dashboard_header(main_vbox)

	# Tab bar
	_create_dashboard_tabs(main_vbox)

	# Content area
	var content_scroll = ScrollContainer.new()
	content_scroll.name = "ContentScroll"
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(content_scroll)

	var content_container = VBoxContainer.new()
	content_container.name = "ContentContainer"
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 15)
	content_scroll.add_child(content_container)

	# Show default tab
	_show_dashboard_tab("overview")


func _calculate_dashboard_data() -> void:
	dashboard_data.clear()

	# Basic stats from GameManager
	dashboard_data["total_sessions"] = GameManager.player_data.get("total_focus_sessions", 0)
	dashboard_data["total_minutes"] = GameManager.player_data.get("total_focus_minutes", 0)

	# Calculate hours and remaining minutes
	var total_mins = dashboard_data["total_minutes"]
	dashboard_data["total_hours"] = int(total_mins / 60)
	dashboard_data["remaining_minutes"] = total_mins % 60

	# Average session length
	if dashboard_data["total_sessions"] > 0:
		dashboard_data["avg_session"] = float(total_mins) / dashboard_data["total_sessions"]
	else:
		dashboard_data["avg_session"] = 0.0

	# Load journal entries for detailed stats
	var journal_entries = _load_journal_entries()
	var focus_entries = []
	for entry in journal_entries:
		if entry.get("type", "") == "focus":
			focus_entries.append(entry)

	dashboard_data["focus_entries"] = focus_entries

	# Daily activity (last 7 days)
	var daily_activity = {}
	var today = Time.get_date_dict_from_system()
	var today_str = "%04d-%02d-%02d" % [today.year, today.month, today.day]

	for i in range(7):
		var date_unix = Time.get_unix_time_from_system() - (i * 86400)
		var date_dict = Time.get_date_dict_from_unix_time(date_unix)
		var date_str = "%04d-%02d-%02d" % [date_dict.year, date_dict.month, date_dict.day]
		daily_activity[date_str] = {"minutes": 0, "sessions": 0}

	for entry in focus_entries:
		var entry_date = entry.get("date", "")
		if entry_date in daily_activity:
			daily_activity[entry_date]["minutes"] += entry.get("duration_minutes", 0)
			daily_activity[entry_date]["sessions"] += 1

	dashboard_data["daily_activity"] = daily_activity
	dashboard_data["today"] = today_str

	# Sessions this week
	var week_sessions = 0
	var week_minutes = 0
	for date_str in daily_activity:
		week_sessions += daily_activity[date_str]["sessions"]
		week_minutes += daily_activity[date_str]["minutes"]
	dashboard_data["week_sessions"] = week_sessions
	dashboard_data["week_minutes"] = week_minutes

	# Best day (most minutes)
	var best_day = ""
	var best_minutes = 0
	for date_str in daily_activity:
		if daily_activity[date_str]["minutes"] > best_minutes:
			best_minutes = daily_activity[date_str]["minutes"]
			best_day = date_str
	dashboard_data["best_day"] = best_day
	dashboard_data["best_day_minutes"] = best_minutes

	# Domain breakdown
	var domain_stats = {}
	for entry in focus_entries:
		var domain = entry.get("habit_domain", entry.get("domain", "general"))
		if domain == "":
			domain = "general"
		if not domain_stats.has(domain):
			domain_stats[domain] = {"sessions": 0, "minutes": 0}
		domain_stats[domain]["sessions"] += 1
		domain_stats[domain]["minutes"] += entry.get("duration_minutes", 0)
	dashboard_data["domain_stats"] = domain_stats

	# Streak calculation
	var streak_days = 0
	var checking_date = Time.get_unix_time_from_system()
	while true:
		var date_dict = Time.get_date_dict_from_unix_time(checking_date)
		var date_str = "%04d-%02d-%02d" % [date_dict.year, date_dict.month, date_dict.day]
		var had_focus = false
		for entry in focus_entries:
			if entry.get("date", "") == date_str:
				had_focus = true
				break
		if had_focus:
			streak_days += 1
			checking_date -= 86400
		else:
			# Allow today to not have focus yet
			if streak_days == 0 and date_str == today_str:
				checking_date -= 86400
				continue
			break
		if streak_days > 365:
			break
	dashboard_data["current_streak"] = streak_days

	# Personal records
	var longest_session = 0
	var most_sessions_day = 0
	var session_counts_by_day = {}
	for entry in focus_entries:
		var duration = entry.get("duration_minutes", 0)
		if duration > longest_session:
			longest_session = duration
		var date = entry.get("date", "")
		if not session_counts_by_day.has(date):
			session_counts_by_day[date] = 0
		session_counts_by_day[date] += 1
	for date in session_counts_by_day:
		if session_counts_by_day[date] > most_sessions_day:
			most_sessions_day = session_counts_by_day[date]
	dashboard_data["longest_session"] = longest_session
	dashboard_data["most_sessions_day"] = most_sessions_day


func _load_journal_entries() -> Array:
	var journal_path = SaveManager.get_journal_path()
	if not FileAccess.file_exists(journal_path):
		return []

	var file = FileAccess.open(journal_path, FileAccess.READ)
	if not file:
		return []

	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return []

	var data = json.get_data()
	if data is Array:
		return data
	return []


func _create_dashboard_header(parent: VBoxContainer) -> void:
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 15)
	parent.add_child(header)

	var title = Label.new()
	title.text = "Focus Analytics"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", DASHBOARD_ACCENT)
	header.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Your journey in focus"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", DASHBOARD_MUTED)
	subtitle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(subtitle)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(35, 35)
	close_btn.pressed.connect(_close_focus_dashboard)
	header.add_child(close_btn)


func _create_dashboard_tabs(parent: VBoxContainer) -> void:
	var tab_bar = HBoxContainer.new()
	tab_bar.name = "TabBar"
	tab_bar.add_theme_constant_override("separation", 10)
	parent.add_child(tab_bar)

	var tabs = ["Overview", "History", "Insights"]
	var tab_ids = ["overview", "history", "insights"]

	for i in range(tabs.size()):
		var tab_btn = Button.new()
		tab_btn.name = "Tab_" + tab_ids[i]
		tab_btn.text = tabs[i]
		tab_btn.toggle_mode = true
		tab_btn.button_pressed = (tab_ids[i] == dashboard_current_tab)
		tab_btn.custom_minimum_size = Vector2(100, 35)
		tab_btn.pressed.connect(_show_dashboard_tab.bind(tab_ids[i]))
		tab_bar.add_child(tab_btn)

	var sep = HSeparator.new()
	parent.add_child(sep)


func _show_dashboard_tab(tab_id: String) -> void:
	dashboard_current_tab = tab_id

	# Update tab buttons
	var tab_bar = focus_dashboard.get_node_or_null("MainPanel/MarginContainer/VBoxContainer/TabBar")
	if tab_bar:
		for child in tab_bar.get_children():
			if child is Button and child.name.begins_with("Tab_"):
				var btn_id = child.name.replace("Tab_", "")
				child.button_pressed = (btn_id == tab_id)

	# Clear and rebuild content
	var content = focus_dashboard.get_node_or_null("MainPanel/MarginContainer/VBoxContainer/ContentScroll/ContentContainer")
	if not content:
		return

	for child in content.get_children():
		child.queue_free()

	match tab_id:
		"overview":
			_build_overview_tab(content)
		"history":
			_build_history_tab(content)
		"insights":
			_build_insights_tab(content)


func _build_overview_tab(content: VBoxContainer) -> void:
	# Summary cards row
	var cards_row = HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 15)
	content.add_child(cards_row)

	_create_stat_card(cards_row, "Total Sessions", str(dashboard_data.get("total_sessions", 0)), DASHBOARD_ACCENT)
	_create_stat_card(cards_row, "Total Time", _format_time(dashboard_data.get("total_minutes", 0)), Color(0.4, 0.8, 0.5))
	_create_stat_card(cards_row, "Avg Session", "%.1f min" % dashboard_data.get("avg_session", 0.0), Color(0.9, 0.7, 0.3))
	_create_stat_card(cards_row, "Current Streak", "%d days" % dashboard_data.get("current_streak", 0), Color(0.9, 0.5, 0.3))

	# Activity graph section
	var graph_label = Label.new()
	graph_label.text = "Last 7 Days Activity"
	graph_label.add_theme_font_size_override("font_size", 18)
	graph_label.add_theme_color_override("font_color", DASHBOARD_TEXT)
	content.add_child(graph_label)

	_create_activity_graph(content)

	# Domain breakdown
	var domain_label = Label.new()
	domain_label.text = "Focus by Domain"
	domain_label.add_theme_font_size_override("font_size", 18)
	domain_label.add_theme_color_override("font_color", DASHBOARD_TEXT)
	content.add_child(domain_label)

	_create_domain_breakdown(content)


func _create_stat_card(parent: HBoxContainer, title: String, value: String, color: Color) -> void:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = DASHBOARD_PANEL
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_color = color.darkened(0.3)
	style.border_width_left = 3
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", DASHBOARD_MUTED)
	vbox.add_child(title_label)

	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 24)
	value_label.add_theme_color_override("font_color", color)
	vbox.add_child(value_label)


func _create_activity_graph(content: VBoxContainer) -> void:
	var graph_container = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = DASHBOARD_PANEL
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	graph_container.add_theme_stylebox_override("panel", style)
	graph_container.custom_minimum_size.y = 150
	content.add_child(graph_container)

	var graph_margin = MarginContainer.new()
	graph_margin.add_theme_constant_override("margin_left", 15)
	graph_margin.add_theme_constant_override("margin_right", 15)
	graph_margin.add_theme_constant_override("margin_top", 15)
	graph_margin.add_theme_constant_override("margin_bottom", 15)
	graph_container.add_child(graph_margin)

	var bars_row = HBoxContainer.new()
	bars_row.add_theme_constant_override("separation", 10)
	bars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	graph_margin.add_child(bars_row)

	var daily_activity = dashboard_data.get("daily_activity", {})
	var max_minutes = 1

	# Find max for scaling
	for date in daily_activity:
		var mins = daily_activity[date].get("minutes", 0)
		if mins > max_minutes:
			max_minutes = mins

	# Create bars for each day (reverse order so oldest is left)
	var dates = daily_activity.keys()
	dates.sort()
	for date_str in dates:
		var day_data = daily_activity[date_str]
		var bar_container = VBoxContainer.new()
		bar_container.add_theme_constant_override("separation", 5)
		bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bars_row.add_child(bar_container)

		# Bar
		var bar_height = 0
		if max_minutes > 0:
			bar_height = int((float(day_data.get("minutes", 0)) / max_minutes) * 100)

		var bar_wrapper = Control.new()
		bar_wrapper.custom_minimum_size = Vector2(0, 100)
		bar_container.add_child(bar_wrapper)

		var bar = ColorRect.new()
		bar.color = DASHBOARD_ACCENT if date_str == dashboard_data.get("today", "") else Color(0.3, 0.5, 0.7)
		bar.custom_minimum_size = Vector2(30, max(5, bar_height))
		bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		bar.offset_top = -max(5, bar_height)
		bar_wrapper.add_child(bar)

		# Minutes label on bar
		if day_data.get("minutes", 0) > 0:
			var mins_label = Label.new()
			mins_label.text = str(day_data.get("minutes", 0))
			mins_label.add_theme_font_size_override("font_size", 10)
			mins_label.add_theme_color_override("font_color", Color.WHITE)
			mins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mins_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
			mins_label.position.y = -15
			bar.add_child(mins_label)

		# Day label
		var day_label = Label.new()
		var date_parts = date_str.split("-")
		if date_parts.size() >= 3:
			day_label.text = date_parts[2]  # Just the day number
		else:
			day_label.text = "?"
		day_label.add_theme_font_size_override("font_size", 11)
		day_label.add_theme_color_override("font_color", DASHBOARD_MUTED)
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bar_container.add_child(day_label)


func _create_domain_breakdown(content: VBoxContainer) -> void:
	var domain_container = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = DASHBOARD_PANEL
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	domain_container.add_theme_stylebox_override("panel", style)
	content.add_child(domain_container)

	var domain_margin = MarginContainer.new()
	domain_margin.add_theme_constant_override("margin_left", 15)
	domain_margin.add_theme_constant_override("margin_right", 15)
	domain_margin.add_theme_constant_override("margin_top", 15)
	domain_margin.add_theme_constant_override("margin_bottom", 15)
	domain_container.add_child(domain_margin)

	var domain_grid = GridContainer.new()
	domain_grid.columns = 3
	domain_grid.add_theme_constant_override("h_separation", 20)
	domain_grid.add_theme_constant_override("v_separation", 10)
	domain_margin.add_child(domain_grid)

	var domain_stats = dashboard_data.get("domain_stats", {})
	var domain_colors = {
		"mind": Color(0.4, 0.5, 0.9),
		"body": Color(0.3, 0.8, 0.4),
		"soul": Color(0.7, 0.5, 0.9),
		"social": Color(0.9, 0.6, 0.4),
		"career": Color(0.9, 0.8, 0.3),
		"wealth": Color(0.3, 0.7, 0.7),
		"general": Color(0.5, 0.5, 0.5)
	}

	if domain_stats.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No focus sessions recorded yet"
		empty_label.add_theme_color_override("font_color", DASHBOARD_MUTED)
		domain_grid.add_child(empty_label)
	else:
		for domain in domain_stats:
			var stat = domain_stats[domain]
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			domain_grid.add_child(row)

			var color_dot = ColorRect.new()
			color_dot.color = domain_colors.get(domain, Color(0.5, 0.5, 0.5))
			color_dot.custom_minimum_size = Vector2(12, 12)
			row.add_child(color_dot)

			var domain_name = Label.new()
			domain_name.text = domain.capitalize()
			domain_name.add_theme_font_size_override("font_size", 14)
			domain_name.add_theme_color_override("font_color", DASHBOARD_TEXT)
			domain_name.custom_minimum_size.x = 80
			row.add_child(domain_name)

			var domain_value = Label.new()
			domain_value.text = "%d sessions, %s" % [stat.get("sessions", 0), _format_time(stat.get("minutes", 0))]
			domain_value.add_theme_font_size_override("font_size", 14)
			domain_value.add_theme_color_override("font_color", DASHBOARD_MUTED)
			row.add_child(domain_value)


func _build_history_tab(content: VBoxContainer) -> void:
	var focus_entries = dashboard_data.get("focus_entries", [])

	if focus_entries.is_empty():
		var empty = Label.new()
		empty.text = "No focus sessions recorded yet.\n\nComplete a focus session to see your history here."
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", DASHBOARD_MUTED)
		content.add_child(empty)
		return

	# Sort by date (newest first)
	focus_entries.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	var header = Label.new()
	header.text = "Recent Sessions (%d total)" % focus_entries.size()
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", DASHBOARD_TEXT)
	content.add_child(header)

	# Show last 20 entries
	var count = 0
	for entry in focus_entries:
		if count >= 20:
			break
		_create_history_entry(content, entry)
		count += 1


func _create_history_entry(content: VBoxContainer, entry: Dictionary) -> void:
	var entry_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = DASHBOARD_PANEL
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	entry_panel.add_theme_stylebox_override("panel", style)
	content.add_child(entry_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	entry_panel.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)

	# Date
	var date_label = Label.new()
	date_label.text = entry.get("date", "Unknown")
	date_label.add_theme_font_size_override("font_size", 14)
	date_label.add_theme_color_override("font_color", DASHBOARD_ACCENT)
	date_label.custom_minimum_size.x = 100
	hbox.add_child(date_label)

	# Topic
	var topic_label = Label.new()
	topic_label.text = entry.get("topic", "Focus Session")
	topic_label.add_theme_font_size_override("font_size", 14)
	topic_label.add_theme_color_override("font_color", DASHBOARD_TEXT)
	topic_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topic_label.clip_text = true
	hbox.add_child(topic_label)

	# Duration
	var duration_label = Label.new()
	duration_label.text = "%d min" % entry.get("duration_minutes", 0)
	duration_label.add_theme_font_size_override("font_size", 14)
	duration_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
	duration_label.custom_minimum_size.x = 60
	hbox.add_child(duration_label)

	# Difficulty
	var diff = entry.get("difficulty", "Standard")
	var diff_label = Label.new()
	diff_label.text = diff
	diff_label.add_theme_font_size_override("font_size", 12)
	diff_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3) if diff == "Hard" else DASHBOARD_MUTED)
	diff_label.custom_minimum_size.x = 60
	hbox.add_child(diff_label)


func _build_insights_tab(content: VBoxContainer) -> void:
	# Personal Records section
	var records_label = Label.new()
	records_label.text = "Personal Records"
	records_label.add_theme_font_size_override("font_size", 18)
	records_label.add_theme_color_override("font_color", DASHBOARD_TEXT)
	content.add_child(records_label)

	var records_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = DASHBOARD_PANEL
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	records_panel.add_theme_stylebox_override("panel", style)
	content.add_child(records_panel)

	var records_margin = MarginContainer.new()
	records_margin.add_theme_constant_override("margin_left", 15)
	records_margin.add_theme_constant_override("margin_right", 15)
	records_margin.add_theme_constant_override("margin_top", 15)
	records_margin.add_theme_constant_override("margin_bottom", 15)
	records_panel.add_child(records_margin)

	var records_grid = GridContainer.new()
	records_grid.columns = 2
	records_grid.add_theme_constant_override("h_separation", 40)
	records_grid.add_theme_constant_override("v_separation", 12)
	records_margin.add_child(records_grid)

	_add_record_row(records_grid, "Longest Session", "%d min" % dashboard_data.get("longest_session", 0))
	_add_record_row(records_grid, "Most Sessions (Day)", str(dashboard_data.get("most_sessions_day", 0)))
	_add_record_row(records_grid, "Best Day", dashboard_data.get("best_day", "N/A"))
	_add_record_row(records_grid, "Best Day Minutes", "%d min" % dashboard_data.get("best_day_minutes", 0))
	_add_record_row(records_grid, "Current Streak", "%d days" % dashboard_data.get("current_streak", 0))

	# Weekly comparison
	var weekly_label = Label.new()
	weekly_label.text = "This Week"
	weekly_label.add_theme_font_size_override("font_size", 18)
	weekly_label.add_theme_color_override("font_color", DASHBOARD_TEXT)
	content.add_child(weekly_label)

	var weekly_cards = HBoxContainer.new()
	weekly_cards.add_theme_constant_override("separation", 15)
	content.add_child(weekly_cards)

	_create_stat_card(weekly_cards, "Sessions", str(dashboard_data.get("week_sessions", 0)), Color(0.4, 0.7, 0.95))
	_create_stat_card(weekly_cards, "Total Time", _format_time(dashboard_data.get("week_minutes", 0)), Color(0.4, 0.8, 0.5))

	# Milestones
	var milestones_label = Label.new()
	milestones_label.text = "Milestones"
	milestones_label.add_theme_font_size_override("font_size", 18)
	milestones_label.add_theme_color_override("font_color", DASHBOARD_TEXT)
	content.add_child(milestones_label)

	_create_milestones_panel(content)


func _add_record_row(grid: GridContainer, label_text: String, value_text: String) -> void:
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", DASHBOARD_MUTED)
	grid.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 14)
	value.add_theme_color_override("font_color", DASHBOARD_TEXT)
	grid.add_child(value)


func _create_milestones_panel(content: VBoxContainer) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = DASHBOARD_PANEL
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	content.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var total_sessions = dashboard_data.get("total_sessions", 0)
	var total_minutes = dashboard_data.get("total_minutes", 0)

	# Session milestones
	var session_milestones = [10, 25, 50, 100, 250, 500]
	for milestone in session_milestones:
		if total_sessions < milestone:
			_add_milestone_bar(vbox, "%d Sessions" % milestone, total_sessions, milestone, Color(0.4, 0.7, 0.95))
			break

	# Time milestones (in minutes)
	var time_milestones = [60, 300, 600, 1200, 3000, 6000]  # 1hr, 5hr, 10hr, 20hr, 50hr, 100hr
	var time_labels = ["1 Hour", "5 Hours", "10 Hours", "20 Hours", "50 Hours", "100 Hours"]
	for i in range(time_milestones.size()):
		if total_minutes < time_milestones[i]:
			_add_milestone_bar(vbox, time_labels[i], total_minutes, time_milestones[i], Color(0.4, 0.8, 0.5))
			break


func _add_milestone_bar(parent: VBoxContainer, label_text: String, current: int, target: int, color: Color) -> void:
	var row = VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)

	var label_row = HBoxContainer.new()
	row.add_child(label_row)

	var label = Label.new()
	label.text = "Next: " + label_text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", DASHBOARD_TEXT)
	label_row.add_child(label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_row.add_child(spacer)

	var progress_text = Label.new()
	progress_text.text = "%d / %d" % [current, target]
	progress_text.add_theme_font_size_override("font_size", 13)
	progress_text.add_theme_color_override("font_color", DASHBOARD_MUTED)
	label_row.add_child(progress_text)

	# Progress bar
	var bar_bg = ColorRect.new()
	bar_bg.color = Color(0.2, 0.2, 0.25)
	bar_bg.custom_minimum_size = Vector2(0, 8)
	row.add_child(bar_bg)

	var progress = float(current) / float(target)
	var bar_fill = ColorRect.new()
	bar_fill.color = color
	bar_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	bar_fill.offset_right = progress * bar_bg.size.x if bar_bg.size.x > 0 else 0
	bar_fill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bar_fill.custom_minimum_size = Vector2(max(2, progress * 400), 8)
	bar_bg.add_child(bar_fill)


func _format_time(minutes: int) -> String:
	if minutes < 60:
		return "%d min" % minutes
	var hours = minutes / 60
	var mins = minutes % 60
	if mins == 0:
		return "%d hr" % hours
	return "%d hr %d min" % [hours, mins]


func _close_focus_dashboard() -> void:
	if focus_dashboard:
		focus_dashboard.queue_free()
		focus_dashboard = null
	_play_sfx("res://audio/sfx/ui_close.wav")


# =============================================================================
# CONSTELLATION MINI-GAME
# =============================================================================

func _open_constellation_game() -> void:
	if constellation_game:
		return

	# Load completed constellations from player data
	completed_constellations = GameManager.player_data.get("completed_constellations", [])

	in_dialogue = true
	interaction_prompt.visible = false

	# Create fullscreen game panel
	constellation_game = Control.new()
	constellation_game.name = "ConstellationGame"
	constellation_game.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(constellation_game)

	# Dark space background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.06, 0.98)
	constellation_game.add_child(bg)

	# Create ambient stars
	_create_ambient_stars()

	# Header
	var header = HBoxContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_top = 20
	header.offset_bottom = 70
	header.offset_left = 40
	header.offset_right = -40
	constellation_game.add_child(header)

	var title = Label.new()
	title.text = "Constellation Charting"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(50, 50)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(_close_constellation_game)
	header.add_child(close_btn)

	# Main content: left sidebar + right play area
	var main_content = HBoxContainer.new()
	main_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_content.offset_top = 80
	main_content.offset_bottom = -40
	main_content.offset_left = 30
	main_content.offset_right = -30
	main_content.add_theme_constant_override("separation", 20)
	constellation_game.add_child(main_content)

	# Left sidebar: constellation list
	var sidebar = PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(280, 0)
	var sidebar_style = StyleBoxFlat.new()
	sidebar_style.bg_color = Color(0.06, 0.07, 0.12, 0.9)
	sidebar_style.set_corner_radius_all(10)
	sidebar.add_theme_stylebox_override("panel", sidebar_style)
	main_content.add_child(sidebar)

	var sidebar_margin = MarginContainer.new()
	sidebar_margin.add_theme_constant_override("margin_left", 15)
	sidebar_margin.add_theme_constant_override("margin_right", 15)
	sidebar_margin.add_theme_constant_override("margin_top", 15)
	sidebar_margin.add_theme_constant_override("margin_bottom", 15)
	sidebar.add_child(sidebar_margin)

	var sidebar_vbox = VBoxContainer.new()
	sidebar_vbox.add_theme_constant_override("separation", 10)
	sidebar_margin.add_child(sidebar_vbox)

	var sidebar_title = Label.new()
	sidebar_title.text = "Constellations"
	sidebar_title.add_theme_font_size_override("font_size", 20)
	sidebar_title.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	sidebar_vbox.add_child(sidebar_title)

	# Progress
	var progress_label = Label.new()
	progress_label.text = "%d / %d discovered" % [completed_constellations.size(), CONSTELLATIONS.size()]
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	sidebar_vbox.add_child(progress_label)

	var sep = HSeparator.new()
	sidebar_vbox.add_child(sep)

	# Constellation buttons
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar_vbox.add_child(scroll)

	var button_list = VBoxContainer.new()
	button_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_list.add_theme_constant_override("separation", 8)
	scroll.add_child(button_list)

	for i in range(CONSTELLATIONS.size()):
		var const_data = CONSTELLATIONS[i]
		var is_completed = const_data.id in completed_constellations

		var btn = Button.new()
		var btn_text = const_data.name
		if is_completed:
			btn_text = "★ " + btn_text
		btn.text = btn_text
		btn.custom_minimum_size = Vector2(0, 45)
		btn.add_theme_font_size_override("font_size", 16)
		if is_completed:
			btn.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
		btn.pressed.connect(_start_constellation.bind(i))
		button_list.add_child(btn)

	# Right: play area
	var play_area = PanelContainer.new()
	play_area.name = "PlayArea"
	play_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var play_style = StyleBoxFlat.new()
	play_style.bg_color = Color(0.03, 0.04, 0.08, 0.95)
	play_style.set_corner_radius_all(10)
	play_style.border_color = Color(0.2, 0.3, 0.5, 0.5)
	play_style.set_border_width_all(2)
	play_area.add_theme_stylebox_override("panel", play_style)
	main_content.add_child(play_area)

	# Play area content
	var play_content = MarginContainer.new()
	play_content.name = "PlayContent"
	play_content.add_theme_constant_override("margin_left", 20)
	play_content.add_theme_constant_override("margin_right", 20)
	play_content.add_theme_constant_override("margin_top", 20)
	play_content.add_theme_constant_override("margin_bottom", 20)
	play_area.add_child(play_content)

	# Initial message
	var welcome = VBoxContainer.new()
	welcome.name = "WelcomeMessage"
	welcome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	welcome.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_content.add_child(welcome)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	welcome.add_child(spacer)

	var welcome_title = Label.new()
	welcome_title.text = "Chart the Constellations"
	welcome_title.add_theme_font_size_override("font_size", 24)
	welcome_title.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	welcome_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome.add_child(welcome_title)

	var welcome_text = Label.new()
	welcome_text.text = "Select a constellation from the list to begin tracing.\n\nClick stars in order to draw the constellation lines.\nComplete the pattern to discover the constellation."
	welcome_text.add_theme_font_size_override("font_size", 16)
	welcome_text.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	welcome_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	welcome.add_child(welcome_text)

	var spacer2 = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	welcome.add_child(spacer2)

	_play_sfx("res://audio/sfx/ui_open.wav")


func _create_ambient_stars() -> void:
	var stars_container = Control.new()
	stars_container.name = "AmbientStars"
	stars_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	stars_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	constellation_game.add_child(stars_container)
	constellation_game.move_child(stars_container, 1)  # After bg

	var viewport_size = get_viewport_rect().size
	for i in range(100):
		var star = ColorRect.new()
		var size = randf_range(1, 2.5)
		star.custom_minimum_size = Vector2(size, size)
		star.size = Vector2(size, size)
		star.position = Vector2(randf() * viewport_size.x, randf() * viewport_size.y)
		star.color = Color(1, 1, randf_range(0.85, 1), randf_range(0.2, 0.6))
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stars_container.add_child(star)


func _start_constellation(index: int) -> void:
	if index < 0 or index >= CONSTELLATIONS.size():
		return

	current_constellation = CONSTELLATIONS[index]
	selected_star = -1
	drawn_lines.clear()
	constellation_stars.clear()

	var play_area = constellation_game.get_node_or_null("Control/HBoxContainer/PlayArea")
	if not play_area:
		# Find play area through the hierarchy
		for child in constellation_game.get_children():
			if child is HBoxContainer:
				for subchild in child.get_children():
					if subchild.name == "PlayArea" or subchild is PanelContainer:
						if subchild.size_flags_horizontal == Control.SIZE_EXPAND_FILL:
							play_area = subchild
							break

	if not play_area:
		# Search through main content
		for child in constellation_game.get_children():
			if child is HBoxContainer:
				play_area = child.get_child(1) if child.get_child_count() > 1 else null
				break

	if not play_area:
		push_error("[Observatory] Could not find play area")
		return

	var play_content = play_area.get_node_or_null("PlayContent")
	if not play_content:
		play_content = play_area.get_child(0) if play_area.get_child_count() > 0 else null

	if not play_content:
		return

	# Clear existing content
	for child in play_content.get_children():
		child.queue_free()

	await get_tree().process_frame

	# Create constellation view
	var const_view = Control.new()
	const_view.name = "ConstellationView"
	const_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	const_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_content.add_child(const_view)

	# Header with name
	var header = VBoxContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 80
	const_view.add_child(header)

	var name_label = Label.new()
	name_label.text = current_constellation.name
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = current_constellation.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	header.add_child(desc_label)

	# Star field area
	var star_field = Control.new()
	star_field.name = "StarField"
	star_field.set_anchors_preset(Control.PRESET_FULL_RECT)
	star_field.offset_top = 90
	star_field.offset_bottom = -60
	const_view.add_child(star_field)

	# Lines container (drawn under stars)
	var lines_container = Control.new()
	lines_container.name = "LinesContainer"
	lines_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_field.add_child(lines_container)

	# Create stars
	await get_tree().process_frame
	var field_size = star_field.size
	if field_size.x < 100:
		field_size = Vector2(600, 400)  # Default size

	for i in range(current_constellation.stars.size()):
		var star_pos_norm = current_constellation.stars[i]
		var star_pos = Vector2(
			star_pos_norm.x * field_size.x,
			star_pos_norm.y * field_size.y
		)

		var star_btn = Button.new()
		star_btn.name = "Star%d" % i
		star_btn.custom_minimum_size = Vector2(30, 30)
		star_btn.position = star_pos - Vector2(15, 15)
		star_btn.flat = true
		star_btn.pressed.connect(_on_star_clicked.bind(i))
		star_field.add_child(star_btn)

		# Visual star
		var star_visual = ColorRect.new()
		star_visual.custom_minimum_size = Vector2(12, 12)
		star_visual.size = Vector2(12, 12)
		star_visual.position = Vector2(9, 9)
		star_visual.color = Color(0.9, 0.95, 1.0, 0.9)
		star_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star_btn.add_child(star_visual)

		# Glow
		var glow = ColorRect.new()
		glow.custom_minimum_size = Vector2(20, 20)
		glow.size = Vector2(20, 20)
		glow.position = Vector2(5, 5)
		glow.color = Color(0.6, 0.8, 1.0, 0.2)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star_btn.add_child(glow)
		star_btn.move_child(glow, 0)

		constellation_stars.append({
			"node": star_btn,
			"position": star_pos,
			"id": i,
			"visual": star_visual
		})

	# Instructions footer
	var footer = Label.new()
	footer.name = "Footer"
	footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -50
	footer.text = "Click stars in sequence to draw constellation lines"
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	const_view.add_child(footer)

	_play_sfx("res://audio/sfx/hover_move.wav")


func _on_star_clicked(star_index: int) -> void:
	if current_constellation.is_empty():
		return

	_play_sfx("res://audio/sfx/click.wav")

	if selected_star == -1:
		# First star selected
		selected_star = star_index
		_highlight_star(star_index, true)
	else:
		# Second star - try to draw line
		if selected_star != star_index:
			var connection = [mini(selected_star, star_index), maxi(selected_star, star_index)]

			# Check if this is a valid connection
			var is_valid = false
			for conn in current_constellation.connections:
				var sorted_conn = [mini(conn[0], conn[1]), maxi(conn[0], conn[1])]
				if sorted_conn[0] == connection[0] and sorted_conn[1] == connection[1]:
					is_valid = true
					break

			if is_valid and connection not in drawn_lines:
				drawn_lines.append(connection)
				_draw_constellation_line(selected_star, star_index)
				_play_sfx("res://audio/sfx/select.wav")

				# Check if constellation is complete
				if drawn_lines.size() >= current_constellation.connections.size():
					_complete_constellation()
			else:
				# Invalid connection
				_play_sfx("res://audio/sfx/ui_close.wav")

		# Deselect
		_highlight_star(selected_star, false)
		selected_star = -1


func _highlight_star(star_index: int, highlight: bool) -> void:
	if star_index < 0 or star_index >= constellation_stars.size():
		return

	var star_data = constellation_stars[star_index]
	var visual = star_data.get("visual") as ColorRect
	if visual:
		if highlight:
			visual.color = Color(1.0, 0.9, 0.4, 1.0)  # Golden highlight
		else:
			visual.color = Color(0.9, 0.95, 1.0, 0.9)  # Normal white


func _draw_constellation_line(from_idx: int, to_idx: int) -> void:
	if from_idx < 0 or from_idx >= constellation_stars.size():
		return
	if to_idx < 0 or to_idx >= constellation_stars.size():
		return

	var from_pos = constellation_stars[from_idx].position
	var to_pos = constellation_stars[to_idx].position

	# Find lines container
	var star_field = constellation_game.find_child("StarField", true, false)
	if not star_field:
		return
	var lines_container = star_field.get_node_or_null("LinesContainer")
	if not lines_container:
		return

	# Create line using Line2D
	var line = Line2D.new()
	line.add_point(from_pos)
	line.add_point(to_pos)
	line.width = 2.0
	line.default_color = Color(0.5, 0.7, 1.0, 0.7)
	line.antialiased = true
	lines_container.add_child(line)


func _complete_constellation() -> void:
	var const_id = current_constellation.get("id", "")
	var is_new = const_id not in completed_constellations

	if is_new:
		completed_constellations.append(const_id)
		GameManager.player_data["completed_constellations"] = completed_constellations

		# Award XP
		var xp = current_constellation.get("reward_xp", 20)
		var aspect = current_constellation.get("aspect", "wisdom")
		GameManager.add_aspect_experience(aspect, xp)

		# Add evolution
		GameManager.player_data["world_evolution"] = GameManager.player_data.get("world_evolution", 0.0) + 0.5

		SaveManager.save_game()

	# Show completion
	await get_tree().create_timer(0.5).timeout

	_play_sfx("res://audio/sfx/achievement.wav")

	# Create completion overlay
	var overlay = PanelContainer.new()
	overlay.name = "CompletionOverlay"
	overlay.set_anchors_preset(Control.PRESET_CENTER)
	overlay.offset_left = -200
	overlay.offset_right = 200
	overlay.offset_top = -150
	overlay.offset_bottom = 150
	var overlay_style = StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.05, 0.08, 0.15, 0.98)
	overlay_style.set_corner_radius_all(15)
	overlay_style.border_color = Color(0.4, 0.6, 0.9, 0.8)
	overlay_style.set_border_width_all(3)
	overlay.add_theme_stylebox_override("panel", overlay_style)
	constellation_game.add_child(overlay)

	var overlay_margin = MarginContainer.new()
	overlay_margin.add_theme_constant_override("margin_left", 25)
	overlay_margin.add_theme_constant_override("margin_right", 25)
	overlay_margin.add_theme_constant_override("margin_top", 25)
	overlay_margin.add_theme_constant_override("margin_bottom", 25)
	overlay.add_child(overlay_margin)

	var overlay_vbox = VBoxContainer.new()
	overlay_vbox.add_theme_constant_override("separation", 15)
	overlay_margin.add_child(overlay_vbox)

	var complete_title = Label.new()
	complete_title.text = "Constellation Discovered!"
	complete_title.add_theme_font_size_override("font_size", 24)
	complete_title.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
	complete_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_vbox.add_child(complete_title)

	var const_name = Label.new()
	const_name.text = current_constellation.name
	const_name.add_theme_font_size_override("font_size", 20)
	const_name.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95))
	const_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_vbox.add_child(const_name)

	if is_new:
		var rewards_label = Label.new()
		rewards_label.text = "+%d %s XP\n+0.5%% World Evolution" % [
			current_constellation.get("reward_xp", 20),
			current_constellation.get("aspect", "Wisdom").capitalize()
		]
		rewards_label.add_theme_font_size_override("font_size", 16)
		rewards_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
		rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		overlay_vbox.add_child(rewards_label)
	else:
		var already_label = Label.new()
		already_label.text = "(Already discovered)"
		already_label.add_theme_font_size_override("font_size", 14)
		already_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		already_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		overlay_vbox.add_child(already_label)

	var continue_btn = Button.new()
	continue_btn.text = "Continue"
	continue_btn.custom_minimum_size = Vector2(150, 45)
	continue_btn.add_theme_font_size_override("font_size", 18)
	continue_btn.pressed.connect(func():
		overlay.queue_free()
		_close_constellation_game()
		_open_constellation_game()  # Reopen to refresh list
	)
	overlay_vbox.add_child(continue_btn)


func _close_constellation_game() -> void:
	if constellation_game:
		constellation_game.queue_free()
		constellation_game = null

	current_constellation = {}
	selected_star = -1
	drawn_lines.clear()
	constellation_stars.clear()
	in_dialogue = false

	_play_sfx("res://audio/sfx/ui_close.wav")
