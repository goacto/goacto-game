extends Control
## Stairs - Stairwell leading to Goacto's bedroom
## Part of intro flow: Kitchen -> Hallway -> Stairs -> Bedroom

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

# Player movement - stairs are more vertical
var player_speed: float = 200.0
var player_bounds: Rect2 = Rect2(-150, -300, 300, 500)

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

# Interactive objects on stairs
const INTERACTIVE_OBJECTS = {
	"HallwayDoor": {
		"name": "Hallway Door",
		"prompt": "Press SPACE to go back downstairs",
		"action": "go_hallway"
	},
	"BedroomDoor": {
		"name": "Your Room",
		"prompt": "Press SPACE to enter your room",
		"action": "go_bedroom"
	},
	"WindowSmall": {
		"name": "Stairwell Window",
		"prompt": "Press SPACE to look outside",
		"action": "look_window"
	}
}

# Object positions for proximity detection
var object_positions: Dictionary = {
	"HallwayDoor": Vector2(0, 150),
	"BedroomDoor": Vector2(0, -250),
	"WindowSmall": Vector2(-100, -50)
}


func _ready() -> void:
	# Connect dialogue button
	dialogue_button.pressed.connect(_close_dialogue)

	# Connect menu button
	menu_button.pressed.connect(_open_pause_menu)

	# Setup header controls (volume, save indicator)
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

	# Position player based on where they came from
	if GameManager.player_data.get("came_from_bedroom", false):
		# Coming from bedroom - spawn at top near bedroom door
		player.position = Vector2(0, -200)
		GameManager.player_data.erase("came_from_bedroom")
	else:
		# Coming from hallway - spawn at bottom near hallway door
		player.position = Vector2(0, 100)

	# Center the view
	_update_camera()

	print("[Stairs] Stairwell ready - your room awaits above")


func _process(delta: float) -> void:
	animation_time += delta

	# Animate stair lights
	_animate_stairs(delta)

	if in_dialogue:
		return

	# Check object proximity
	_check_object_proximity()

	# Handle movement
	_handle_movement(delta)

	# Update camera (follows player vertically)
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
		if pause_menu:
			_close_pause_menu()
			viewport.set_input_as_handled()
			return
		if space_view_panel and space_view_panel.visible:
			_close_space_view()
			viewport.set_input_as_handled()
			return
		if dialogue_panel.visible:
			_close_dialogue()
			viewport.set_input_as_handled()
			return
		# If nothing is open, open pause menu
		_open_pause_menu()
		viewport.set_input_as_handled()
		return

	# Block inputs when pause menu is open
	if pause_menu:
		return

	# Close space view with SPACE
	if space_view_panel and space_view_panel.visible:
		if event.is_action_pressed("ui_accept"):
			_close_space_view()
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

		# Stairs movement - vertical with slight horizontal
		var movement = Vector2(
			input_dir.x * 0.5,
			input_dir.y
		)

		var new_pos = player.position + movement * player_speed * delta

		# Clamp to stair bounds
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


func _play_sfx(sfx_path: String, volume_db: float = 0.0) -> void:
	if not ResourceLoader.exists(sfx_path):
		return
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		var stream = load(sfx_path)
		if stream:
			audio.play_sfx(stream, volume_db)
	else:
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.stream = load(sfx_path)
		sfx_player.volume_db = volume_db
		sfx_player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(sfx_player)
		sfx_player.play()
		sfx_player.finished.connect(func(): sfx_player.queue_free())


func _update_camera() -> void:
	if not game_world or not isometric_base or not player:
		return

	var screen_center = game_world.size / 2

	# Camera follows player vertically
	var target_x = screen_center.x
	var target_y = screen_center.y - (player.position.y * camera_zoom * 0.4)

	isometric_base.position = Vector2(round(target_x), round(target_y))
	isometric_base.scale = Vector2(camera_zoom, camera_zoom)


func _apply_zoom(amount: float) -> void:
	camera_zoom = clamp(camera_zoom + amount, min_zoom, max_zoom)
	_update_camera()


func _check_object_proximity() -> void:
	var closest_object: String = ""
	var closest_distance: float = 100.0  # Interaction radius

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
	if object_id == null or object_id == "":
		return
	var obj_data = INTERACTIVE_OBJECTS.get(object_id, null)
	if obj_data == null or (obj_data is Dictionary and obj_data.is_empty()):
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
		"go_hallway":
			GameManager.player_data["came_from_stairs"] = true
			GameManager.goto_scene("res://scenes/ship/hallway.tscn")
		"go_bedroom":
			_confirm_go_bedroom()
		"look_window":
			_show_space_view()


func _confirm_go_bedroom() -> void:
	_show_dialogue("Your Room", "This is your room! The Mindscape console is inside.\n\nEnter?", _go_to_bedroom)


func _go_to_bedroom() -> void:
	# Set flag that we came from the ship navigation
	GameManager.player_data["came_from_ship"] = true
	GameManager.goto_scene("res://scenes/bedroom/bedroom.tscn")


func _show_dialogue(title: String, text: String, callback: Callable = Callable(), voice_path: String = "") -> void:
	dialogue_title.text = title
	dialogue_text.text = text
	dialogue_panel.visible = true
	in_dialogue = true
	interaction_prompt.visible = false
	dialogue_callback = callback

	# Play voice if provided
	if voice_path != "":
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_voice_from_path"):
			audio.play_voice_from_path(voice_path)

	# Update button text based on whether there's a callback
	if callback.is_valid():
		dialogue_button.text = "Yes"
	else:
		dialogue_button.text = "Continue"


func _close_dialogue() -> void:
	dialogue_panel.visible = false
	in_dialogue = false

	if dialogue_callback.is_valid():
		dialogue_callback.call()
		dialogue_callback = Callable()


func _animate_stairs(delta: float) -> void:
	# Animate space view if visible
	if space_view_panel and space_view_panel.visible:
		_animate_space_view(delta)


# =============================================================================
# IMMERSIVE SPACE VIEW
# =============================================================================

var space_view_panel: Control = null
var space_view_time: float = 0.0
var space_stars: Array = []
var starship_node: Node2D = null
var nebula_node: Polygon2D = null
var earth_node: Node2D = null

func _show_space_view() -> void:
	if space_view_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false
	space_view_time = 0.0

	# Create fullscreen space view
	space_view_panel = Control.new()
	space_view_panel.name = "SpaceView"
	space_view_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	space_view_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(space_view_panel)

	# Deep space background
	var bg = ColorRect.new()
	bg.name = "SpaceBackground"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.06)
	space_view_panel.add_child(bg)

	# Stars container
	var stars_container = Node2D.new()
	stars_container.name = "Stars"
	space_view_panel.add_child(stars_container)
	_create_stars(stars_container)

	# Distant nebula glow
	_create_nebula()

	# Earth in the distance
	_create_earth()

	# SpaceX Starship
	_create_starship()

	# Viewport frame (window border)
	_create_window_frame()

	# Info text at bottom
	var info_label = Label.new()
	info_label.text = "The Stellar Wanderer passes by Earth on its 50-year voyage..."
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.9))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	info_label.offset_top = -80
	info_label.offset_bottom = -50
	space_view_panel.add_child(info_label)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Step Back"
	close_btn.custom_minimum_size = Vector2(150, 50)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	close_btn.offset_top = -50
	close_btn.offset_left = -75
	close_btn.offset_right = 75
	close_btn.offset_bottom = 0
	close_btn.pressed.connect(_close_space_view)
	space_view_panel.add_child(close_btn)

	# Fade in
	space_view_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(space_view_panel, "modulate:a", 1.0, 0.5)

	# Play voiceover
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_voice_from_path"):
		audio.play_voice_from_path("res://audio/voice/stairs/space_view.ogg")


func _create_stars(container: Node2D) -> void:
	var viewport_size = get_viewport_rect().size
	space_stars.clear()

	# Create ~150 stars at various depths
	for i in range(150):
		var star = Polygon2D.new()
		var size = randf_range(1.0, 3.0)

		# Diamond shape for stars
		star.polygon = PackedVector2Array([
			Vector2(0, -size),
			Vector2(size * 0.6, 0),
			Vector2(0, size),
			Vector2(-size * 0.6, 0)
		])

		# Vary colors - mostly white, some blue/yellow tints
		var color_rand = randf()
		if color_rand < 0.7:
			star.color = Color(1, 1, 1, randf_range(0.3, 1.0))
		elif color_rand < 0.85:
			star.color = Color(0.8, 0.9, 1.0, randf_range(0.4, 0.9))  # Blue-ish
		else:
			star.color = Color(1.0, 0.95, 0.8, randf_range(0.4, 0.9))  # Yellow-ish

		star.position = Vector2(
			randf_range(0, viewport_size.x),
			randf_range(0, viewport_size.y)
		)

		container.add_child(star)
		space_stars.append({
			"node": star,
			"twinkle_speed": randf_range(1.0, 4.0),
			"twinkle_offset": randf() * TAU,
			"base_alpha": star.color.a
		})


func _create_nebula() -> void:
	var viewport_size = get_viewport_rect().size

	# Large nebula glow in upper right
	nebula_node = Polygon2D.new()
	nebula_node.name = "Nebula"

	# Soft irregular blob shape
	var points = PackedVector2Array()
	var center = Vector2(viewport_size.x * 0.75, viewport_size.y * 0.25)
	var radius = 250.0
	for i in range(16):
		var angle = (i / 16.0) * TAU
		var r = radius * (0.7 + randf() * 0.6)
		points.append(center + Vector2(cos(angle), sin(angle)) * r)

	nebula_node.polygon = points
	nebula_node.color = Color(0.4, 0.15, 0.5, 0.15)  # Purple nebula
	space_view_panel.add_child(nebula_node)

	# Inner brighter core
	var core = Polygon2D.new()
	var core_points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		var r = radius * 0.4 * (0.8 + randf() * 0.4)
		core_points.append(center + Vector2(cos(angle), sin(angle)) * r)
	core.polygon = core_points
	core.color = Color(0.6, 0.3, 0.7, 0.1)
	space_view_panel.add_child(core)


func _create_earth() -> void:
	var viewport_size = get_viewport_rect().size

	earth_node = Node2D.new()
	earth_node.name = "Earth"
	earth_node.position = Vector2(viewport_size.x * 0.2, viewport_size.y * 0.6)
	space_view_panel.add_child(earth_node)

	var earth_radius = 80.0

	# Earth base (blue ocean)
	var earth_base = Polygon2D.new()
	var earth_points = PackedVector2Array()
	for i in range(32):
		var angle = (i / 32.0) * TAU
		earth_points.append(Vector2(cos(angle), sin(angle)) * earth_radius)
	earth_base.polygon = earth_points
	earth_base.color = Color(0.15, 0.35, 0.65)
	earth_node.add_child(earth_base)

	# Continents (green/brown patches)
	var continent1 = Polygon2D.new()
	continent1.polygon = PackedVector2Array([
		Vector2(-30, -40), Vector2(-10, -50), Vector2(20, -35),
		Vector2(25, -10), Vector2(10, 5), Vector2(-25, -5), Vector2(-35, -25)
	])
	continent1.color = Color(0.25, 0.45, 0.2)
	earth_node.add_child(continent1)

	var continent2 = Polygon2D.new()
	continent2.polygon = PackedVector2Array([
		Vector2(30, 10), Vector2(50, 0), Vector2(55, 25),
		Vector2(40, 45), Vector2(20, 35), Vector2(25, 15)
	])
	continent2.color = Color(0.3, 0.4, 0.2)
	earth_node.add_child(continent2)

	# Atmosphere glow
	var atmo = Polygon2D.new()
	var atmo_points = PackedVector2Array()
	for i in range(32):
		var angle = (i / 32.0) * TAU
		atmo_points.append(Vector2(cos(angle), sin(angle)) * (earth_radius + 8))
	atmo.polygon = atmo_points
	atmo.color = Color(0.4, 0.7, 1.0, 0.15)
	earth_node.add_child(atmo)

	# Cloud wisps
	var clouds = Polygon2D.new()
	clouds.polygon = PackedVector2Array([
		Vector2(-50, -20), Vector2(-30, -30), Vector2(0, -25),
		Vector2(20, -15), Vector2(10, -5), Vector2(-40, -10)
	])
	clouds.color = Color(1, 1, 1, 0.3)
	earth_node.add_child(clouds)


func _create_starship() -> void:
	var viewport_size = get_viewport_rect().size

	starship_node = Node2D.new()
	starship_node.name = "Starship"
	starship_node.position = Vector2(viewport_size.x * 0.65, viewport_size.y * 0.45)
	starship_node.rotation = -0.1  # Slight angle
	starship_node.scale = Vector2(1.3, 1.3)
	space_view_panel.add_child(starship_node)

	# Main cylindrical body (stainless steel)
	var body = Polygon2D.new()
	body.name = "Body"
	body.polygon = PackedVector2Array([
		# Nose cone - smooth curved profile
		Vector2(0, -140),       # Tip
		Vector2(4, -135),
		Vector2(8, -125),
		Vector2(12, -110),
		Vector2(15, -90),
		Vector2(17, -70),
		Vector2(18, -50),       # Where cone meets cylinder
		# Cylindrical body
		Vector2(18, 100),       # Bottom of cylinder
		Vector2(-18, 100),
		Vector2(-18, -50),
		# Left side of nose cone
		Vector2(-17, -70),
		Vector2(-15, -90),
		Vector2(-12, -110),
		Vector2(-8, -125),
		Vector2(-4, -135),
	])
	body.color = Color(0.78, 0.80, 0.84)  # Brushed stainless steel
	starship_node.add_child(body)

	# Panel seam lines (horizontal weld lines)
	for i in range(8):
		var seam = Polygon2D.new()
		var y_pos = -40 + i * 18
		seam.polygon = PackedVector2Array([
			Vector2(-18, y_pos), Vector2(18, y_pos),
			Vector2(18, y_pos + 1), Vector2(-18, y_pos + 1)
		])
		seam.color = Color(0.6, 0.62, 0.65, 0.5)
		starship_node.add_child(seam)

	# Vertical pipe/conduit running down center
	var pipe = Polygon2D.new()
	pipe.polygon = PackedVector2Array([
		Vector2(-2, -30), Vector2(2, -30), Vector2(2, 90), Vector2(-2, 90)
	])
	pipe.color = Color(0.55, 0.4, 0.35)  # Copper/brown pipe
	starship_node.add_child(pipe)

	# Forward flaps (positioned higher, swept back design)
	var flap_front_l = Polygon2D.new()
	flap_front_l.polygon = PackedVector2Array([
		Vector2(-18, -65),      # Attach point top
		Vector2(-45, -50),      # Tip outer
		Vector2(-48, -35),      # Tip bottom
		Vector2(-18, -25),      # Attach point bottom
	])
	flap_front_l.color = Color(0.7, 0.72, 0.76)
	starship_node.add_child(flap_front_l)

	var flap_front_r = Polygon2D.new()
	flap_front_r.polygon = PackedVector2Array([
		Vector2(18, -65),
		Vector2(45, -50),
		Vector2(48, -35),
		Vector2(18, -25),
	])
	flap_front_r.color = Color(0.82, 0.84, 0.88)
	starship_node.add_child(flap_front_r)

	# Rear flaps (larger, at bottom)
	var flap_rear_l = Polygon2D.new()
	flap_rear_l.polygon = PackedVector2Array([
		Vector2(-18, 55),       # Attach top
		Vector2(-50, 70),       # Outer top
		Vector2(-52, 105),      # Outer bottom
		Vector2(-18, 100),      # Attach bottom
	])
	flap_rear_l.color = Color(0.65, 0.67, 0.7)
	starship_node.add_child(flap_rear_l)

	var flap_rear_r = Polygon2D.new()
	flap_rear_r.polygon = PackedVector2Array([
		Vector2(18, 55),
		Vector2(50, 70),
		Vector2(52, 105),
		Vector2(18, 100),
	])
	flap_rear_r.color = Color(0.82, 0.84, 0.88)
	starship_node.add_child(flap_rear_r)

	# Flap hinges/attachments
	for flap_x in [-18, 18]:
		var hinge = Polygon2D.new()
		hinge.polygon = PackedVector2Array([
			Vector2(flap_x - 3, -50), Vector2(flap_x + 3, -50),
			Vector2(flap_x + 3, -40), Vector2(flap_x - 3, -40)
		])
		hinge.color = Color(0.4, 0.42, 0.45)
		starship_node.add_child(hinge)

	# Engine skirt section
	var skirt = Polygon2D.new()
	skirt.polygon = PackedVector2Array([
		Vector2(-18, 100), Vector2(-20, 115), Vector2(-18, 120),
		Vector2(18, 120), Vector2(20, 115), Vector2(18, 100)
	])
	skirt.color = Color(0.35, 0.37, 0.4)
	starship_node.add_child(skirt)

	# Engine nozzles (3 sea-level + 3 vacuum visible from angle)
	var nozzle_positions = [-10, 0, 10]
	for x_off in nozzle_positions:
		var nozzle = Polygon2D.new()
		nozzle.polygon = PackedVector2Array([
			Vector2(x_off - 4, 120),
			Vector2(x_off - 5, 135),
			Vector2(x_off + 5, 135),
			Vector2(x_off + 4, 120)
		])
		nozzle.color = Color(0.2, 0.22, 0.25)
		starship_node.add_child(nozzle)

		# Inner nozzle glow
		var inner = Polygon2D.new()
		inner.polygon = PackedVector2Array([
			Vector2(x_off - 2, 125),
			Vector2(x_off - 3, 133),
			Vector2(x_off + 3, 133),
			Vector2(x_off + 2, 125)
		])
		inner.color = Color(0.15, 0.15, 0.18)
		starship_node.add_child(inner)

	# Small circular details (ports/vents)
	var port_positions = [
		Vector2(10, -80), Vector2(-8, 20), Vector2(12, 50)
	]
	for pos in port_positions:
		var port = Polygon2D.new()
		var port_points = PackedVector2Array()
		for j in range(8):
			var angle = (j / 8.0) * TAU
			port_points.append(pos + Vector2(cos(angle), sin(angle)) * 3)
		port.polygon = port_points
		port.color = Color(0.25, 0.27, 0.3)
		starship_node.add_child(port)

	# Subtle engine glow
	var glow = Polygon2D.new()
	glow.name = "EngineGlow"
	glow.polygon = PackedVector2Array([
		Vector2(-12, 135), Vector2(0, 160), Vector2(12, 135)
	])
	glow.color = Color(0.4, 0.6, 1.0, 0.25)
	starship_node.add_child(glow)


func _create_window_frame() -> void:
	var viewport_size = get_viewport_rect().size

	# Circular window frame overlay
	var frame = Control.new()
	frame.name = "WindowFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	space_view_panel.add_child(frame)

	# Dark vignette corners (simulating round window)
	var vignette_tl = ColorRect.new()
	vignette_tl.color = Color(0.03, 0.03, 0.05, 0.9)
	vignette_tl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	vignette_tl.size = Vector2(150, 150)
	frame.add_child(vignette_tl)

	var vignette_tr = ColorRect.new()
	vignette_tr.color = Color(0.03, 0.03, 0.05, 0.9)
	vignette_tr.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	vignette_tr.size = Vector2(150, 150)
	vignette_tr.position.x = -150
	frame.add_child(vignette_tr)

	var vignette_bl = ColorRect.new()
	vignette_bl.color = Color(0.03, 0.03, 0.05, 0.9)
	vignette_bl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	vignette_bl.size = Vector2(150, 150)
	vignette_bl.position.y = -150
	frame.add_child(vignette_bl)

	var vignette_br = ColorRect.new()
	vignette_br.color = Color(0.03, 0.03, 0.05, 0.9)
	vignette_br.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	vignette_br.size = Vector2(150, 150)
	vignette_br.position = Vector2(-150, -150)
	frame.add_child(vignette_br)

	# Window rim
	var rim_label = Label.new()
	rim_label.text = "— STELLAR WANDERER • OBSERVATION DECK 7 —"
	rim_label.add_theme_font_size_override("font_size", 14)
	rim_label.add_theme_color_override("font_color", Color(0.4, 0.45, 0.5, 0.7))
	rim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rim_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	rim_label.offset_top = 20
	frame.add_child(rim_label)


func _animate_space_view(delta: float) -> void:
	space_view_time += delta

	# Twinkle stars
	for star_data in space_stars:
		var star = star_data["node"] as Polygon2D
		if star:
			var twinkle = sin(space_view_time * star_data["twinkle_speed"] + star_data["twinkle_offset"])
			star.color.a = star_data["base_alpha"] * (0.6 + twinkle * 0.4)

	# Subtle Starship drift
	if starship_node:
		starship_node.position.y += sin(space_view_time * 0.3) * 0.15
		starship_node.rotation = -0.15 + sin(space_view_time * 0.2) * 0.02

		# Pulse engine glow
		var glow = starship_node.get_node_or_null("EngineGlow")
		if glow:
			glow.color.a = 0.2 + sin(space_view_time * 3) * 0.1

	# Earth slow rotation illusion (move continents slightly)
	if earth_node:
		earth_node.rotation = sin(space_view_time * 0.05) * 0.03

	# Nebula subtle pulse
	if nebula_node:
		nebula_node.color.a = 0.12 + sin(space_view_time * 0.5) * 0.03


func _close_space_view() -> void:
	if not space_view_panel:
		return

	var tween = create_tween()
	tween.tween_property(space_view_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_cleanup_space_view)


func _cleanup_space_view() -> void:
	if space_view_panel:
		space_view_panel.queue_free()
		space_view_panel = null

	space_stars.clear()
	starship_node = null
	nebula_node = null
	earth_node = null
	in_dialogue = false


# =============================================================================
# HEADER CONTROLS (Volume, Save Indicator)
# =============================================================================

func _setup_header_controls() -> void:
	var header_hbox = menu_button.get_parent()
	if not header_hbox:
		return
	save_indicator = Label.new()
	save_indicator.add_theme_font_size_override("font_size", 14)
	save_indicator.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	save_indicator.tooltip_text = "Current save file"
	_update_save_indicator()
	header_hbox.add_child(save_indicator)
	header_hbox.move_child(save_indicator, menu_button.get_index())
	volume_button = Button.new()
	volume_button.custom_minimum_size = Vector2(45, 45)
	volume_button.add_theme_font_size_override("font_size", 20)
	volume_button.tooltip_text = "Volume (M to mute)"
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
		volume_button.text = "Mute"
		is_muted = true
	else:
		volume_button.text = "Vol"
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

	# Title
	var title = Label.new()
	title.text = "Menu"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Resume button
	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.custom_minimum_size = Vector2(0, 50)
	resume_btn.add_theme_font_size_override("font_size", 20)
	resume_btn.pressed.connect(_close_pause_menu)
	vbox.add_child(resume_btn)

	# Settings button
	var settings_btn = Button.new()
	settings_btn.text = "Settings"
	settings_btn.custom_minimum_size = Vector2(0, 50)
	settings_btn.add_theme_font_size_override("font_size", 20)
	settings_btn.pressed.connect(_go_to_settings)
	vbox.add_child(settings_btn)

	# Main Menu button
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
