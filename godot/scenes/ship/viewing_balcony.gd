extends Control
## Viewing Balcony - Observation deck off the kitchen
## A peaceful spot to gaze at the stars and reflect

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

# Header controls
var volume_button: Button = null
var save_indicator: Label = null
var volume_popup: PanelContainer = null
var is_muted: bool = false

# Player movement
var player_speed: float = 250.0
var player_bounds: Rect2 = Rect2(-400, -200, 800, 400)

# Camera
var camera_zoom: float = 1.0
var min_zoom: float = 0.6
var max_zoom: float = 1.5
var zoom_speed: float = 0.08

# Interaction state
var nearby_object: String = ""
var in_dialogue: bool = false
var dialogue_callback: Callable

# Animation
var animation_time: float = 0.0

# Movement sound
var move_sound_timer: float = 0.0
var move_sound_interval: float = 0.35

# Starfield animation
var stars: Array = []
var shooting_star_timer: float = 0.0

# Interactive panels
var telescope_viewer: PanelContainer = null
var meditation_panel: PanelContainer = null
var meditation_timer: float = 0.0
var meditation_duration: float = 0.0
var is_meditating: bool = false
var breath_phase: String = "inhale"  # inhale, hold, exhale
var breath_timer: float = 0.0

# Telescope view state
var telescope_view_offset: Vector2 = Vector2.ZERO
var telescope_dragging: bool = false
var telescope_drag_start: Vector2 = Vector2.ZERO

# Celestial objects for telescope (different from observatory)
const BALCONY_CELESTIAL_OBJECTS = [
	{"name": "Earth", "type": "planet", "pos": Vector2(350, 300), "description": "A pale blue dot in the distance.\nYour ancestral home, billions of miles away.", "xp": 15},
	{"name": "Comet Zephyrus", "type": "comet", "pos": Vector2(-400, -280), "description": "A wanderer between worlds, trailing stardust.\nIt won't pass this way again for 200 years.", "xp": 20},
	{"name": "The Void Gate", "type": "anomaly", "pos": Vector2(280, -350), "description": "A shimmering tear in spacetime.\nSome say voices whisper from the other side.", "xp": 30},
	{"name": "Pulsar X-7", "type": "pulsar", "pos": Vector2(-320, 380), "description": "A spinning neutron star, flashing like a lighthouse.\nIts rhythmic pulse has guided travelers for millennia.", "xp": 25},
	{"name": "The Nursery Nebula", "type": "nebula", "pos": Vector2(-50, -400), "description": "Where new stars are born from cosmic dust.\nEach spark could one day host life.", "xp": 20}
]

# Interactive objects
const INTERACTIVE_OBJECTS = {
	"KitchenDoor": {
		"name": "Kitchen Door",
		"prompt": "Press SPACE to return to kitchen",
		"action": "go_kitchen"
	},
	"Telescope": {
		"name": "Observation Telescope",
		"prompt": "Press SPACE to look through",
		"action": "use_telescope"
	},
	"Railing": {
		"name": "Safety Railing",
		"prompt": "Press SPACE to lean on railing",
		"action": "lean_railing"
	},
	"Bench": {
		"name": "Meditation Bench",
		"prompt": "Press SPACE to sit",
		"action": "sit_bench"
	}
}

# Object positions
var object_positions: Dictionary = {
	"KitchenDoor": Vector2(350, 0),
	"Telescope": Vector2(-200, -100),
	"Railing": Vector2(0, 150),
	"Bench": Vector2(150, -50)
}


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
	if GameManager.player_data.get("came_from_kitchen", false):
		player.position = Vector2(280, 0)
		GameManager.player_data.erase("came_from_kitchen")
	else:
		player.position = Vector2(280, 0)

	# Setup starfield
	_create_starfield()

	# Center the view
	_update_camera()

	print("[ViewingBalcony] Observation deck ready")


func _process(delta: float) -> void:
	animation_time += delta

	# Animate starfield
	_animate_stars(delta)

	# Update meditation if active
	if is_meditating:
		_update_meditation(delta)

	# Handle telescope panning when open
	if telescope_viewer:
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


func _input(event: InputEvent) -> void:
	var viewport = get_viewport()
	if viewport == null:
		return

	# ESC to close panels or open pause menu
	if event.is_action_pressed("ui_cancel"):
		if volume_popup:
			_close_volume_popup()
			viewport.set_input_as_handled()
			return
		if telescope_viewer:
			_close_telescope_viewer()
			viewport.set_input_as_handled()
			return
		if meditation_panel:
			_close_meditation_panel()
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

	# Block inputs when pause menu is open
	if pause_menu:
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


func _handle_movement(delta: float) -> void:
	var input_dir = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()

		var iso_movement = Vector2(
			input_dir.x - input_dir.y,
			(input_dir.x + input_dir.y) * 0.5
		)

		var new_pos = player.position + iso_movement * player_speed * delta

		# Clamp to bounds
		new_pos.x = clamp(new_pos.x, player_bounds.position.x, player_bounds.position.x + player_bounds.size.x)
		new_pos.y = clamp(new_pos.y, player_bounds.position.y, player_bounds.position.y + player_bounds.size.y)

		player.position = new_pos

		# Play movement sound
		move_sound_timer += delta
		if move_sound_timer >= move_sound_interval:
			move_sound_timer = 0.0
			_play_sfx("res://audio/sfx/hover_move.wav", -12.0)
	else:
		move_sound_timer = 0.0


func _update_camera() -> void:
	if not game_world or not isometric_base or not player:
		return

	var screen_center = game_world.size / 2
	var target_pos = screen_center - (player.position * camera_zoom)
	isometric_base.position = target_pos
	isometric_base.scale = Vector2(camera_zoom, camera_zoom)


func _apply_zoom(amount: float) -> void:
	camera_zoom = clamp(camera_zoom + amount, min_zoom, max_zoom)
	_update_camera()


func _check_object_proximity() -> void:
	var closest_object: String = ""
	var closest_distance: float = 100.0

	for object_name in object_positions:
		var obj_pos = object_positions[object_name]
		var distance = player.position.distance_to(obj_pos)

		if distance < closest_distance:
			closest_distance = distance
			closest_object = object_name

	if closest_object != nearby_object:
		nearby_object = closest_object
		if nearby_object != "":
			_show_interaction_prompt(nearby_object)
		else:
			_hide_interaction_prompt()


func _show_interaction_prompt(object_id: String) -> void:
	var obj_data = INTERACTIVE_OBJECTS.get(object_id, {})
	if obj_data.is_empty():
		return

	object_name_label.text = obj_data.get("name", object_id)
	prompt_text_label.text = obj_data.get("prompt", "Press SPACE to interact")

	interaction_prompt.visible = true
	control_hints.visible = false


func _hide_interaction_prompt() -> void:
	interaction_prompt.visible = false
	control_hints.visible = true


func _interact_with_object(object_id: String) -> void:
	var obj_data = INTERACTIVE_OBJECTS.get(object_id, {})
	var action = obj_data.get("action", "")

	match action:
		"go_kitchen":
			_go_to_kitchen()
		"use_telescope":
			_open_telescope_viewer()
		"lean_railing":
			_show_dialogue("The View", "You lean against the safety rail and gaze into the void.\n\nStars stretch endlessly in every direction. The ship hums quietly beneath your feet.\n\nIt's moments like these that remind you how small you are... and how vast your potential.")
		"sit_bench":
			_open_meditation_panel()


func _go_to_kitchen() -> void:
	_play_sfx("res://audio/sfx/door_open.wav")
	GameManager.goto_scene("res://scenes/ship/kitchen.tscn")


func _show_dialogue(title: String, text: String, callback: Callable = Callable(), voice_path: String = "") -> void:
	dialogue_title.text = title
	dialogue_text.text = text
	dialogue_panel.visible = true
	in_dialogue = true
	interaction_prompt.visible = false
	dialogue_callback = callback

	if callback.is_valid():
		dialogue_button.text = "Yes"
	else:
		dialogue_button.text = "Continue"

	# Play voice line if provided
	if voice_path != "" and ResourceLoader.exists(voice_path):
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_voice"):
			var stream = load(voice_path)
			if stream:
				audio.play_voice(stream)


func _close_dialogue() -> void:
	dialogue_panel.visible = false
	in_dialogue = false

	if dialogue_callback.is_valid():
		dialogue_callback.call()
		dialogue_callback = Callable()


func _play_sfx(sfx_path: String, volume_db: float = 0.0) -> void:
	if not ResourceLoader.exists(sfx_path):
		return

	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		var stream = load(sfx_path)
		if stream:
			audio.play_sfx(stream, volume_db)


# =============================================================================
# STARFIELD ANIMATION
# =============================================================================

func _create_starfield() -> void:
	stars.clear()

	var stars_container = isometric_base.get_node_or_null("Stars")
	if not stars_container:
		return

	# Stars are already in the tscn, just track them for animation
	for child in stars_container.get_children():
		if child is Polygon2D:
			stars.append({
				"node": child,
				"twinkle_speed": randf_range(1.5, 4.0),
				"twinkle_offset": randf() * TAU,
				"base_alpha": child.color.a
			})


func _animate_stars(delta: float) -> void:
	# Twinkle stars
	for star_data in stars:
		var star = star_data["node"] as Polygon2D
		if star:
			var twinkle = sin(animation_time * star_data["twinkle_speed"] + star_data["twinkle_offset"])
			star.color.a = star_data["base_alpha"] * (0.5 + twinkle * 0.5)

	# Occasional shooting star
	shooting_star_timer += delta
	if shooting_star_timer > randf_range(3.0, 8.0):
		shooting_star_timer = 0.0
		# Could spawn a shooting star effect here


# =============================================================================
# TELESCOPE VIEWER
# =============================================================================

func _open_telescope_viewer() -> void:
	if telescope_viewer:
		return

	in_dialogue = true
	interaction_prompt.visible = false
	_play_sfx("res://audio/sfx/menu_open.wav")

	# Create main panel
	telescope_viewer = PanelContainer.new()
	telescope_viewer.name = "TelescopeViewer"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.06, 0.98)
	style.border_color = Color(0.3, 0.4, 0.6, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	telescope_viewer.add_theme_stylebox_override("panel", style)

	telescope_viewer.set_anchors_preset(Control.PRESET_CENTER)
	telescope_viewer.offset_left = -350
	telescope_viewer.offset_right = 350
	telescope_viewer.offset_top = -280
	telescope_viewer.offset_bottom = 280

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	telescope_viewer.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var title = Label.new()
	title.text = "Balcony Telescope"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var discoveries_label = Label.new()
	var discovered_count = _get_balcony_discovery_count()
	discoveries_label.text = "%d/%d discovered" % [discovered_count, BALCONY_CELESTIAL_OBJECTS.size()]
	discoveries_label.add_theme_font_size_override("font_size", 14)
	discoveries_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.5))
	header.add_child(discoveries_label)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_telescope_viewer)
	header.add_child(close_btn)

	# Instructions
	var instructions = Label.new()
	instructions.text = "Arrow keys to pan | Click glowing objects to discover"
	instructions.add_theme_font_size_override("font_size", 12)
	instructions.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instructions)

	# Viewport container with starfield
	var view_container = PanelContainer.new()
	view_container.custom_minimum_size = Vector2(660, 400)
	view_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var view_style = StyleBoxFlat.new()
	view_style.bg_color = Color(0.01, 0.01, 0.03)
	view_style.border_color = Color(0.2, 0.25, 0.4)
	view_style.set_border_width_all(1)
	view_style.set_corner_radius_all(8)
	view_container.add_theme_stylebox_override("panel", view_style)
	vbox.add_child(view_container)

	# Starfield canvas
	var starfield = Control.new()
	starfield.name = "Starfield"
	starfield.set_anchors_preset(Control.PRESET_FULL_RECT)
	starfield.clip_contents = true
	view_container.add_child(starfield)

	# Create random background stars
	for i in range(80):
		var star = Polygon2D.new()
		var star_size = randf_range(1.0, 3.0)
		star.polygon = PackedVector2Array([
			Vector2(-star_size, 0), Vector2(0, -star_size),
			Vector2(star_size, 0), Vector2(0, star_size)
		])
		var brightness = randf_range(0.3, 0.9)
		star.color = Color(brightness, brightness * 1.1, brightness * 1.2, randf_range(0.4, 0.9))
		star.position = Vector2(randf_range(20, 640), randf_range(20, 380))
		starfield.add_child(star)

	# Create celestial objects
	var objects_container = Control.new()
	objects_container.name = "CelestialObjects"
	objects_container.position = Vector2(330, 200) + telescope_view_offset
	starfield.add_child(objects_container)

	for obj_data in BALCONY_CELESTIAL_OBJECTS:
		var obj_button = _create_celestial_button(obj_data)
		obj_button.position = obj_data.pos
		objects_container.add_child(obj_button)

	# Connect starfield for dragging
	starfield.gui_input.connect(_on_telescope_input)

	add_child(telescope_viewer)


func _create_celestial_button(data: Dictionary) -> Control:
	var container = Control.new()
	container.name = data.name.replace(" ", "")

	var is_discovered = _is_balcony_object_discovered(data.name)

	# Visual representation based on type
	var visual = Polygon2D.new()
	var size = 12.0
	var color: Color

	match data.type:
		"planet":
			visual.polygon = _create_circle_polygon(size)
			color = Color(0.3, 0.5, 0.9) if is_discovered else Color(0.4, 0.6, 1.0, 0.7)
		"comet":
			visual.polygon = PackedVector2Array([
				Vector2(-size, 0), Vector2(0, -size * 0.5),
				Vector2(size * 2, 0), Vector2(0, size * 0.5)
			])
			color = Color(0.6, 0.8, 0.9) if is_discovered else Color(0.7, 0.9, 1.0, 0.7)
		"anomaly":
			visual.polygon = _create_circle_polygon(size * 1.5)
			color = Color(0.7, 0.3, 0.8) if is_discovered else Color(0.8, 0.4, 0.9, 0.7)
		"pulsar":
			visual.polygon = _create_star_polygon(size, 6)
			color = Color(1.0, 0.9, 0.5) if is_discovered else Color(1.0, 0.95, 0.6, 0.7)
		"nebula":
			visual.polygon = _create_circle_polygon(size * 2)
			color = Color(0.5, 0.3, 0.7, 0.6) if is_discovered else Color(0.6, 0.4, 0.8, 0.5)
		_:
			visual.polygon = _create_circle_polygon(size)
			color = Color(0.8, 0.8, 0.8, 0.7)

	visual.color = color
	container.add_child(visual)

	# Glow effect for undiscovered
	if not is_discovered:
		var glow = Polygon2D.new()
		glow.polygon = _create_circle_polygon(size * 2.5)
		glow.color = Color(color.r, color.g, color.b, 0.15)
		glow.z_index = -1
		container.add_child(glow)

		# Pulse animation
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(glow, "scale", Vector2(1.3, 1.3), 1.0)
		tween.tween_property(glow, "scale", Vector2(1.0, 1.0), 1.0)

	# Clickable button
	var btn = Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(40, 40)
	btn.position = Vector2(-20, -20)
	btn.pressed.connect(func(): _discover_balcony_celestial(data))
	container.add_child(btn)

	# Label for discovered objects
	if is_discovered:
		var lbl = Label.new()
		lbl.text = data.name
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 0.8))
		lbl.position = Vector2(size + 5, -8)
		container.add_child(lbl)

	return container


func _create_circle_polygon(radius: float, segments: int = 16) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(segments):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	return points


func _create_star_polygon(radius: float, points_count: int = 5) -> PackedVector2Array:
	var points = PackedVector2Array()
	var inner_radius = radius * 0.4
	for i in range(points_count * 2):
		var angle = (float(i) / (points_count * 2)) * TAU - PI / 2
		var r = radius if i % 2 == 0 else inner_radius
		points.append(Vector2(cos(angle) * r, sin(angle) * r))
	return points


func _on_telescope_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				telescope_dragging = true
				telescope_drag_start = event.position
			else:
				telescope_dragging = false
	elif event is InputEventMouseMotion and telescope_dragging:
		var delta = event.position - telescope_drag_start
		telescope_drag_start = event.position
		telescope_view_offset += delta
		telescope_view_offset = telescope_view_offset.clamp(Vector2(-200, -150), Vector2(200, 150))

		# Update objects container position
		if telescope_viewer:
			var objects = telescope_viewer.get_node_or_null("MarginContainer/VBoxContainer/PanelContainer/Starfield/CelestialObjects")
			if objects:
				objects.position = Vector2(330, 200) + telescope_view_offset


func _discover_balcony_celestial(data: Dictionary) -> void:
	var discoveries = GameManager.player_data.get("balcony_telescope_discoveries", [])

	if data.name in discoveries:
		# Already discovered - show info
		_show_telescope_info(data, true)
	else:
		# New discovery!
		discoveries.append(data.name)
		GameManager.player_data["balcony_telescope_discoveries"] = discoveries

		# Award XP
		if GameManager.has_method("add_aspect_experience"):
			GameManager.add_aspect_experience("wisdom", data.xp)

		_play_sfx("res://audio/sfx/success.wav")
		_show_telescope_info(data, false)


func _show_telescope_info(data: Dictionary, already_known: bool) -> void:
	# Close viewer and show dialogue
	_close_telescope_viewer()

	var title = "Discovery: " + data.name if not already_known else data.name
	var text = data.description
	if not already_known:
		text += "\n\n+%d Wisdom XP" % data.xp

	_show_dialogue(title, text)


func _is_balcony_object_discovered(obj_name: String) -> bool:
	var discoveries = GameManager.player_data.get("balcony_telescope_discoveries", [])
	return obj_name in discoveries


func _get_balcony_discovery_count() -> int:
	var discoveries = GameManager.player_data.get("balcony_telescope_discoveries", [])
	return discoveries.size()


func _close_telescope_viewer() -> void:
	if telescope_viewer:
		telescope_viewer.queue_free()
		telescope_viewer = null
	in_dialogue = false
	telescope_view_offset = Vector2.ZERO


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
		# Clamp to reasonable bounds
		telescope_view_offset.x = clamp(telescope_view_offset.x, -450, 450)
		telescope_view_offset.y = clamp(telescope_view_offset.y, -450, 450)

		# Update objects container position
		if telescope_viewer:
			var objects = telescope_viewer.get_node_or_null("MarginContainer/VBoxContainer/PanelContainer/Starfield/CelestialObjects")
			if objects:
				objects.position = Vector2(330, 200) + telescope_view_offset


# =============================================================================
# MEDITATION PANEL
# =============================================================================

func _open_meditation_panel() -> void:
	if meditation_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false
	_play_sfx("res://audio/sfx/menu_open.wav")

	meditation_panel = PanelContainer.new()
	meditation_panel.name = "MeditationPanel"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.08, 0.98)
	style.border_color = Color(0.4, 0.3, 0.6, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	meditation_panel.add_theme_stylebox_override("panel", style)

	meditation_panel.set_anchors_preset(Control.PRESET_CENTER)
	meditation_panel.offset_left = -280
	meditation_panel.offset_right = 280
	meditation_panel.offset_top = -250
	meditation_panel.offset_bottom = 250

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	meditation_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "MeditationVBox"
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var title = Label.new()
	title.text = "Starlight Meditation"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_meditation_panel)
	header.add_child(close_btn)

	# Lore text
	var lore = Label.new()
	lore.text = "Elder Zyx's favorite spot for contemplation.\nLet the starlight guide your breath."
	lore.add_theme_font_size_override("font_size", 13)
	lore.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	lore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(lore)

	# Breathing circle container
	var circle_container = CenterContainer.new()
	circle_container.custom_minimum_size = Vector2(0, 180)
	vbox.add_child(circle_container)

	var breathing_circle = Control.new()
	breathing_circle.name = "BreathingCircle"
	breathing_circle.custom_minimum_size = Vector2(120, 120)
	circle_container.add_child(breathing_circle)

	# Draw breathing circle
	var circle = Polygon2D.new()
	circle.name = "Circle"
	circle.polygon = _create_circle_polygon(50.0, 32)
	circle.color = Color(0.5, 0.4, 0.8, 0.6)
	circle.position = Vector2(60, 60)
	breathing_circle.add_child(circle)

	# Inner glow
	var inner_glow = Polygon2D.new()
	inner_glow.name = "InnerGlow"
	inner_glow.polygon = _create_circle_polygon(35.0, 24)
	inner_glow.color = Color(0.7, 0.6, 1.0, 0.3)
	inner_glow.position = Vector2(60, 60)
	breathing_circle.add_child(inner_glow)

	# Breath instruction
	var breath_label = Label.new()
	breath_label.name = "BreathLabel"
	breath_label.text = "Tap to begin"
	breath_label.add_theme_font_size_override("font_size", 16)
	breath_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	breath_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	breath_label.position = Vector2(0, 130)
	breath_label.custom_minimum_size = Vector2(120, 30)
	breathing_circle.add_child(breath_label)

	# Timer display
	var timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.text = ""
	timer_label.add_theme_font_size_override("font_size", 14)
	timer_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(timer_label)

	# Duration buttons
	var duration_label = Label.new()
	duration_label.text = "Choose duration:"
	duration_label.add_theme_font_size_override("font_size", 14)
	duration_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(duration_label)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 15)
	vbox.add_child(btn_row)

	for duration in [60, 180, 300]:
		var btn = Button.new()
		btn.text = "%d min" % (duration / 60)
		btn.custom_minimum_size = Vector2(80, 45)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(func(): _start_meditation(duration))
		btn_row.add_child(btn)

	# Stats
	var total_sessions = GameManager.player_data.get("balcony_meditation_sessions", 0)
	var total_minutes = GameManager.player_data.get("balcony_meditation_minutes", 0)

	var stats_label = Label.new()
	stats_label.text = "Sessions: %d | Total: %d min" % [total_sessions, total_minutes]
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)

	add_child(meditation_panel)


func _start_meditation(duration: float) -> void:
	meditation_duration = duration
	meditation_timer = duration
	is_meditating = true
	breath_phase = "inhale"
	breath_timer = 0.0

	_play_sfx("res://audio/sfx/confirm.wav")

	# Update UI
	if meditation_panel:
		var breath_label = meditation_panel.get_node_or_null("MarginContainer/MeditationVBox/CenterContainer/BreathingCircle/BreathLabel")
		if breath_label:
			breath_label.text = "Breathe in..."


func _update_meditation(delta: float) -> void:
	if not is_meditating or not meditation_panel:
		return

	meditation_timer -= delta
	breath_timer += delta

	# Breathing cycle: 4s inhale, 4s hold, 6s exhale
	var cycle_time = fmod(breath_timer, 14.0)
	var old_phase = breath_phase

	if cycle_time < 4.0:
		breath_phase = "inhale"
	elif cycle_time < 8.0:
		breath_phase = "hold"
	else:
		breath_phase = "exhale"

	# Update breath label
	var breath_label = meditation_panel.get_node_or_null("MarginContainer/MeditationVBox/CenterContainer/BreathingCircle/BreathLabel")
	if breath_label and old_phase != breath_phase:
		match breath_phase:
			"inhale": breath_label.text = "Breathe in..."
			"hold": breath_label.text = "Hold..."
			"exhale": breath_label.text = "Breathe out..."

	# Animate breathing circle
	var circle = meditation_panel.get_node_or_null("MarginContainer/MeditationVBox/CenterContainer/BreathingCircle/Circle")
	var inner_glow = meditation_panel.get_node_or_null("MarginContainer/MeditationVBox/CenterContainer/BreathingCircle/InnerGlow")

	if circle:
		var target_scale: float
		match breath_phase:
			"inhale":
				target_scale = lerp(1.0, 1.5, cycle_time / 4.0)
			"hold":
				target_scale = 1.5
			"exhale":
				target_scale = lerp(1.5, 1.0, (cycle_time - 8.0) / 6.0)
			_:
				target_scale = 1.0

		circle.scale = Vector2(target_scale, target_scale)
		if inner_glow:
			inner_glow.scale = Vector2(target_scale, target_scale)

	# Update timer display
	var timer_label = meditation_panel.get_node_or_null("MarginContainer/MeditationVBox/Label2")
	if not timer_label:
		# Try alternate path
		for child in meditation_panel.get_node("MarginContainer/MeditationVBox").get_children():
			if child is Label and child.name == "TimerLabel":
				timer_label = child
				break

	if timer_label:
		var mins = int(meditation_timer) / 60
		var secs = int(meditation_timer) % 60
		timer_label.text = "%d:%02d remaining" % [mins, secs]

	# Check if complete
	if meditation_timer <= 0:
		_complete_meditation()


func _complete_meditation() -> void:
	is_meditating = false

	# Record stats
	var sessions = GameManager.player_data.get("balcony_meditation_sessions", 0) + 1
	var minutes = GameManager.player_data.get("balcony_meditation_minutes", 0) + int(meditation_duration / 60)
	GameManager.player_data["balcony_meditation_sessions"] = sessions
	GameManager.player_data["balcony_meditation_minutes"] = minutes

	# Award XP based on duration
	var xp_reward = int(meditation_duration / 60) * 10
	if GameManager.has_method("add_aspect_experience"):
		GameManager.add_aspect_experience("spirit", xp_reward)

	_play_sfx("res://audio/sfx/success.wav")

	_close_meditation_panel()
	_show_dialogue("Meditation Complete", "You feel centered and at peace.\n\nThe starlight has filled you with calm clarity.\n\n+%d Spirit XP" % xp_reward)


func _close_meditation_panel() -> void:
	is_meditating = false
	if meditation_panel:
		meditation_panel.queue_free()
		meditation_panel = null
	in_dialogue = false


# =============================================================================
# HEADER CONTROLS
# =============================================================================

func _setup_header_controls() -> void:
	var header_hbox = menu_button.get_parent()
	if not header_hbox:
		return

	save_indicator = Label.new()
	save_indicator.add_theme_font_size_override("font_size", 14)
	save_indicator.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	_update_save_indicator()
	header_hbox.add_child(save_indicator)
	header_hbox.move_child(save_indicator, menu_button.get_index())

	volume_button = Button.new()
	volume_button.custom_minimum_size = Vector2(45, 45)
	volume_button.add_theme_font_size_override("font_size", 20)
	volume_button.pressed.connect(_toggle_volume_popup)
	_update_volume_button_icon()
	header_hbox.add_child(volume_button)
	header_hbox.move_child(volume_button, menu_button.get_index())

	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		is_muted = audio.master_volume <= 0.01


func _update_save_indicator() -> void:
	if not save_indicator:
		return
	var current_slot = SaveManager.current_slot
	if current_slot > 0:
		var info = SaveManager.get_slot_info(current_slot)
		save_indicator.text = info.slot_name if info.exists else "Slot %d" % current_slot
	else:
		save_indicator.text = "Auto-save"


func _update_volume_button_icon() -> void:
	if not volume_button:
		return
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.master_volume <= 0.01:
		volume_button.text = "🔇"
		is_muted = true
	else:
		volume_button.text = "🔊"
		is_muted = false


func _toggle_volume_popup() -> void:
	if volume_popup:
		_close_volume_popup()
		return

	volume_popup = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.98)
	style.border_color = Color(0.4, 0.35, 0.6, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	volume_popup.add_theme_stylebox_override("panel", style)
	volume_popup.position = volume_button.global_position + Vector2(-80, volume_button.size.y + 5)
	volume_popup.custom_minimum_size = Vector2(200, 0)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	volume_popup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Volume"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var audio = get_node_or_null("/root/AudioManager")
	for channel in ["Master", "Music", "SFX"]:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var lbl = Label.new()
		lbl.text = channel
		lbl.custom_minimum_size = Vector2(55, 0)
		lbl.add_theme_font_size_override("font_size", 14)
		row.add_child(lbl)

		var slider = HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		match channel:
			"Master": slider.value = audio.master_volume * 100 if audio else 100
			"Music": slider.value = audio.music_volume * 100 if audio else 100
			"SFX": slider.value = audio.sfx_volume * 100 if audio else 100
		slider.custom_minimum_size = Vector2(100, 20)
		slider.value_changed.connect(func(val): _on_volume_changed(channel.to_lower(), val))
		row.add_child(slider)

	var mute_btn = Button.new()
	mute_btn.text = "Unmute All" if is_muted else "Mute All"
	mute_btn.custom_minimum_size = Vector2(0, 35)
	mute_btn.add_theme_font_size_override("font_size", 14)
	mute_btn.pressed.connect(_toggle_mute)
	vbox.add_child(mute_btn)

	add_child(volume_popup)


func _close_volume_popup() -> void:
	if volume_popup:
		volume_popup.queue_free()
		volume_popup = null


func _on_volume_changed(channel: String, value: float) -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		return
	var vol = value / 100.0
	match channel:
		"master": audio.set_master_volume(vol)
		"music": audio.set_music_volume(vol)
		"sfx": audio.set_sfx_volume(vol)
	_update_volume_button_icon()


func _toggle_mute() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		return
	if is_muted:
		audio.set_master_volume(1.0)
		is_muted = false
	else:
		audio.set_master_volume(0.0)
		is_muted = true
	_update_volume_button_icon()
	_close_volume_popup()


# =============================================================================
# PAUSE MENU
# =============================================================================

var pause_menu: PanelContainer = null

func _open_pause_menu() -> void:
	if pause_menu:
		return

	in_dialogue = true
	interaction_prompt.visible = false

	pause_menu = PanelContainer.new()
	pause_menu.name = "PauseMenu"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.98)
	style.border_color = Color(0.5, 0.4, 0.7, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	pause_menu.add_theme_stylebox_override("panel", style)

	pause_menu.set_anchors_preset(Control.PRESET_CENTER)
	pause_menu.offset_left = -200
	pause_menu.offset_right = 200
	pause_menu.offset_top = -200
	pause_menu.offset_bottom = 200

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	pause_menu.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Menu"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.custom_minimum_size = Vector2(0, 50)
	resume_btn.add_theme_font_size_override("font_size", 20)
	resume_btn.pressed.connect(_close_pause_menu)
	vbox.add_child(resume_btn)

	var settings_btn = Button.new()
	settings_btn.text = "Settings"
	settings_btn.custom_minimum_size = Vector2(0, 50)
	settings_btn.add_theme_font_size_override("font_size", 20)
	settings_btn.pressed.connect(_go_to_settings)
	vbox.add_child(settings_btn)

	var main_menu_btn = Button.new()
	main_menu_btn.text = "Main Menu"
	main_menu_btn.custom_minimum_size = Vector2(0, 50)
	main_menu_btn.add_theme_font_size_override("font_size", 20)
	main_menu_btn.add_theme_color_override("font_color", Color(0.8, 0.6, 0.6))
	main_menu_btn.pressed.connect(_go_to_main_menu)
	vbox.add_child(main_menu_btn)

	add_child(pause_menu)


func _close_pause_menu() -> void:
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null
	in_dialogue = false


func _go_to_settings() -> void:
	_close_pause_menu()
	GameManager.goto_scene("res://scenes/settings/settings.tscn")


func _go_to_main_menu() -> void:
	_close_pause_menu()
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
