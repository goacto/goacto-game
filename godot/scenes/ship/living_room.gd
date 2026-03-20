extends Control
## Living Room - Family gathering space on the Stellar Wanderer
## Cozy area with entertainment system, snacks, and family memories

# World elements
@onready var game_world: Control = $GameWorld
@onready var isometric_base: Node2D = $GameWorld/IsometricBase
@onready var player: Node2D = $GameWorld/IsometricBase/Player

# Decorative lights
@onready var lights_container: Node2D = $GameWorld/IsometricBase/Lights

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
var player_speed: float = 280.0
var player_bounds: Rect2 = Rect2(-400, -80, 800, 160)

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
var tv_flicker_time: float = 0.0

# Movement sound
var move_sound_timer: float = 0.0
var move_sound_interval: float = 0.35

# Interactive objects in living room
const INTERACTIVE_OBJECTS = {
	"HallwayDoor": {
		"name": "Hallway Door",
		"prompt": "Press SPACE to return to hallway",
		"action": "go_hallway"
	},
	"Couch": {
		"name": "Family Couch",
		"prompt": "Press SPACE to sit",
		"action": "examine_couch"
	},
	"TV": {
		"name": "Holo-Display",
		"prompt": "Press SPACE to play Stellar Pong",
		"action": "play_pong"
	},
	"SnackTable": {
		"name": "Snack Station",
		"prompt": "Press SPACE to grab a snack",
		"action": "examine_snacks"
	},
	"Bookshelf": {
		"name": "Memory Archive",
		"prompt": "Press SPACE to browse",
		"action": "examine_bookshelf"
	},
	"FamilyPhoto": {
		"name": "Holographic Frame",
		"prompt": "Press SPACE to view",
		"action": "examine_photo"
	},
	"WindowView": {
		"name": "Observation Window",
		"prompt": "Press SPACE to look outside",
		"action": "examine_window"
	},
	"GameConsole": {
		"name": "RetroStation 3000",
		"prompt": "Press SPACE to play",
		"action": "examine_console"
	},
}

# Object positions for proximity detection
var object_positions: Dictionary = {
	"HallwayDoor": Vector2(-350, 0),
	"Couch": Vector2(0, 30),
	"TV": Vector2(0, -70),
	"SnackTable": Vector2(-150, 50),
	"Bookshelf": Vector2(350, 0),
	"FamilyPhoto": Vector2(200, -60),
	"WindowView": Vector2(-250, -60),
	"GameConsole": Vector2(180, 40),
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
	if GameManager.player_data.get("came_from_hallway", false):
		player.position = Vector2(-280, 0)
		GameManager.player_data.erase("came_from_hallway")
	else:
		player.position = Vector2(-280, 0)

	# Center the view
	_update_camera()

	print("[LivingRoom] Family living room ready")


func _process(delta: float) -> void:
	animation_time += delta
	tv_flicker_time += delta

	# Animate lights and TV
	_animate_lights(delta)
	_animate_tv(delta)

	# Update Pong game if playing
	if pong_playing:
		_pong_update(delta)
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
		if pong_panel:
			_close_pong_game()
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
		# If nothing is open, open pause menu
		_open_pause_menu()
		viewport.set_input_as_handled()
		return

	# Block inputs when pause menu or pong is open
	if pause_menu:
		return

	# Pong handles its own input
	if pong_panel:
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

		# Isometric movement (W=up-left, S=down-right, A=down-left, D=up-right)
		var iso_movement = Vector2(
			input_dir.x + input_dir.y * 0.3,
			(input_dir.y - input_dir.x) * 0.3
		)

		var new_pos = player.position + iso_movement * player_speed * delta

		# Clamp to room bounds
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

	var target_x = screen_center.x - (player.position.x * camera_zoom * 0.4)
	var target_y = screen_center.y

	isometric_base.position = Vector2(target_x, target_y)
	isometric_base.scale = Vector2(camera_zoom, camera_zoom)


func _apply_zoom(amount: float) -> void:
	camera_zoom = clamp(camera_zoom + amount, min_zoom, max_zoom)
	_update_camera()


func _check_object_proximity() -> void:
	var closest_object: String = ""
	var closest_distance: float = 80.0  # Interaction radius

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
		"go_hallway":
			GameManager.player_data["came_from_living_room"] = true
			GameManager.goto_scene("res://scenes/ship/hallway.tscn")
		"examine_couch":
			_show_dialogue("Family Couch", "The softest couch in the entire Goactorian fleet.\n\nCountless movie nights and family game sessions happened here.\n\nYou can still see the indent where Dad always sits.", Callable(), "res://audio/voice/living_room/couch.ogg")
		"play_pong":
			_start_pong_game()
		"examine_snacks":
			_show_dialogue("Snack Station", "A bowl of crystallized Nebula Puffs - your favorite!\n\nNext to it: Plasma Jerky strips and fizzy Comet Cola.\n\nMom always keeps this stocked for family time.", Callable(), "res://audio/voice/living_room/snacks.ogg")
		"examine_bookshelf":
			_show_dialogue("Memory Archive", "Generations of Goactorian knowledge stored in data crystals.\n\nYour favorite: \"Tales of the First Explorers\" - stories of your ancestors who charted the stars.\n\nOne day, your story will be here too.", Callable(), "res://audio/voice/living_room/bookshelf.ogg")
		"examine_photo":
			_show_dialogue("Holographic Frame", "A rotating display of family memories...\n\nYour hatching day celebration. The trip to the Prismatic Nebula. Elder Zyx's 500th birthday.\n\nEvery image a treasure from home.", Callable(), "res://audio/voice/living_room/photo.ogg")
		"examine_window":
			_show_dialogue("Observation Window", "The vast expanse of space stretches endlessly before you.\n\nDistant stars twinkle like the eyes of ancient guardians.\n\nSomewhere out there... your new home waits.", Callable(), "res://audio/voice/living_room/window.ogg")
		"examine_console":
			_show_dialogue("RetroStation 3000", "An ancient gaming console your grandparents played on!\n\nStill works perfectly - Goactorian engineering at its finest.\n\nMaybe later you can convince Dad to play Star Raiders...", Callable(), "res://audio/voice/living_room/console.ogg")


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


func _animate_lights(delta: float) -> void:
	if not lights_container:
		return

	# Gentle ambient lighting
	for i in range(lights_container.get_child_count()):
		var light = lights_container.get_child(i)
		var phase_offset = float(i) * 0.7
		var pulse = (sin(animation_time * 1.5 + phase_offset) + 1.0) / 2.0
		light.modulate.a = 0.5 + pulse * 0.3


func _animate_tv(delta: float) -> void:
	var tv_glow = isometric_base.get_node_or_null("TV/Glow")
	if tv_glow:
		# Subtle TV flicker effect
		var flicker = randf_range(0.8, 1.0)
		tv_glow.modulate.a = 0.6 * flicker


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


# =============================================================================
# PONG MINI-GAME
# =============================================================================

var pong_panel: PanelContainer = null
var pong_game_area: Control = null
var pong_ball: ColorRect = null
var pong_paddle_player: ColorRect = null
var pong_paddle_ai: ColorRect = null
var pong_score_label: Label = null

var pong_playing: bool = false
var pong_ball_velocity: Vector2 = Vector2.ZERO
var pong_ball_speed: float = 300.0
var pong_paddle_speed: float = 350.0
var pong_ai_speed: float = 220.0
var pong_player_score: int = 0
var pong_ai_score: int = 0
var pong_max_score: int = 5

# Game area bounds
var pong_area_width: float = 500.0
var pong_area_height: float = 300.0
var pong_paddle_height: float = 60.0
var pong_paddle_width: float = 12.0
var pong_ball_size: float = 12.0


func _start_pong_game() -> void:
	if pong_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false
	pong_playing = true
	pong_player_score = 0
	pong_ai_score = 0

	# Create pong panel
	pong_panel = PanelContainer.new()
	pong_panel.name = "PongPanel"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.05, 0.98)
	style.border_color = Color(0.4, 0.6, 0.9, 0.8)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	pong_panel.add_theme_stylebox_override("panel", style)

	pong_panel.set_anchors_preset(Control.PRESET_CENTER)
	pong_panel.offset_left = -280
	pong_panel.offset_right = 280
	pong_panel.offset_top = -220
	pong_panel.offset_bottom = 220

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	pong_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title bar
	var title_bar = HBoxContainer.new()
	vbox.add_child(title_bar)

	var title = Label.new()
	title.text = "STELLAR PONG"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(title)

	pong_score_label = Label.new()
	pong_score_label.text = "0 - 0"
	pong_score_label.add_theme_font_size_override("font_size", 24)
	pong_score_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
	title_bar.add_child(pong_score_label)

	# Game area container
	var game_container = PanelContainer.new()
	var game_style = StyleBoxFlat.new()
	game_style.bg_color = Color(0.0, 0.0, 0.0, 1.0)
	game_style.border_color = Color(0.3, 0.3, 0.5, 1.0)
	game_style.set_border_width_all(2)
	game_container.add_theme_stylebox_override("panel", game_style)
	game_container.custom_minimum_size = Vector2(pong_area_width, pong_area_height)
	vbox.add_child(game_container)

	pong_game_area = Control.new()
	pong_game_area.custom_minimum_size = Vector2(pong_area_width, pong_area_height)
	game_container.add_child(pong_game_area)

	# Center line
	var center_line = ColorRect.new()
	center_line.color = Color(0.3, 0.3, 0.4, 0.5)
	center_line.position = Vector2(pong_area_width / 2 - 1, 0)
	center_line.size = Vector2(2, pong_area_height)
	pong_game_area.add_child(center_line)

	# Player paddle (left)
	pong_paddle_player = ColorRect.new()
	pong_paddle_player.color = Color(0.3, 0.9, 0.5, 1.0)
	pong_paddle_player.size = Vector2(pong_paddle_width, pong_paddle_height)
	pong_paddle_player.position = Vector2(15, pong_area_height / 2 - pong_paddle_height / 2)
	pong_game_area.add_child(pong_paddle_player)

	# AI paddle (right)
	pong_paddle_ai = ColorRect.new()
	pong_paddle_ai.color = Color(0.9, 0.4, 0.4, 1.0)
	pong_paddle_ai.size = Vector2(pong_paddle_width, pong_paddle_height)
	pong_paddle_ai.position = Vector2(pong_area_width - 15 - pong_paddle_width, pong_area_height / 2 - pong_paddle_height / 2)
	pong_game_area.add_child(pong_paddle_ai)

	# Ball
	pong_ball = ColorRect.new()
	pong_ball.color = Color(1.0, 1.0, 1.0, 1.0)
	pong_ball.size = Vector2(pong_ball_size, pong_ball_size)
	pong_game_area.add_child(pong_ball)

	# Instructions
	var instructions = Label.new()
	instructions.text = "W/S or Up/Down to move  |  ESC to exit  |  First to 5 wins!"
	instructions.add_theme_font_size_override("font_size", 12)
	instructions.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instructions)

	add_child(pong_panel)

	# Start ball
	_pong_reset_ball()


func _pong_reset_ball() -> void:
	if not pong_ball:
		return

	pong_ball.position = Vector2(
		pong_area_width / 2 - pong_ball_size / 2,
		pong_area_height / 2 - pong_ball_size / 2
	)

	# Random direction
	var angle = randf_range(-PI / 4, PI / 4)
	if randi() % 2 == 0:
		angle += PI
	pong_ball_velocity = Vector2(cos(angle), sin(angle)) * pong_ball_speed


func _pong_update(delta: float) -> void:
	if not pong_playing or not pong_ball or not pong_paddle_player or not pong_paddle_ai:
		return

	# Player paddle movement
	var player_input = 0.0
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("ui_up"):
		player_input -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down"):
		player_input += 1.0

	pong_paddle_player.position.y += player_input * pong_paddle_speed * delta
	pong_paddle_player.position.y = clamp(
		pong_paddle_player.position.y,
		0,
		pong_area_height - pong_paddle_height
	)

	# AI paddle movement (follows ball with some lag)
	var ai_target = pong_ball.position.y + pong_ball_size / 2 - pong_paddle_height / 2
	var ai_diff = ai_target - pong_paddle_ai.position.y
	var ai_move = sign(ai_diff) * min(abs(ai_diff), pong_ai_speed * delta)
	pong_paddle_ai.position.y += ai_move
	pong_paddle_ai.position.y = clamp(
		pong_paddle_ai.position.y,
		0,
		pong_area_height - pong_paddle_height
	)

	# Ball movement
	pong_ball.position += pong_ball_velocity * delta

	# Ball collision with top/bottom
	if pong_ball.position.y <= 0:
		pong_ball.position.y = 0
		pong_ball_velocity.y = abs(pong_ball_velocity.y)
		_play_sfx("res://audio/sfx/hover_move.wav", -8.0)
	elif pong_ball.position.y >= pong_area_height - pong_ball_size:
		pong_ball.position.y = pong_area_height - pong_ball_size
		pong_ball_velocity.y = -abs(pong_ball_velocity.y)
		_play_sfx("res://audio/sfx/hover_move.wav", -8.0)

	# Ball collision with player paddle
	var ball_rect = Rect2(pong_ball.position, pong_ball.size)
	var player_rect = Rect2(pong_paddle_player.position, pong_paddle_player.size)
	var ai_rect = Rect2(pong_paddle_ai.position, pong_paddle_ai.size)

	if ball_rect.intersects(player_rect) and pong_ball_velocity.x < 0:
		pong_ball.position.x = pong_paddle_player.position.x + pong_paddle_width
		var hit_pos = (pong_ball.position.y + pong_ball_size / 2 - pong_paddle_player.position.y) / pong_paddle_height
		var angle = lerp(-PI / 4, PI / 4, hit_pos)
		pong_ball_velocity = Vector2(cos(angle), sin(angle)) * pong_ball_speed * 1.05
		pong_ball_speed = min(pong_ball_speed * 1.02, 500.0)
		_play_sfx("res://audio/sfx/hover_move.wav", -5.0)

	if ball_rect.intersects(ai_rect) and pong_ball_velocity.x > 0:
		pong_ball.position.x = pong_paddle_ai.position.x - pong_ball_size
		var hit_pos = (pong_ball.position.y + pong_ball_size / 2 - pong_paddle_ai.position.y) / pong_paddle_height
		var angle = lerp(PI - PI / 4, PI + PI / 4, hit_pos)
		pong_ball_velocity = Vector2(cos(angle), sin(angle)) * pong_ball_speed * 1.05
		pong_ball_speed = min(pong_ball_speed * 1.02, 500.0)
		_play_sfx("res://audio/sfx/hover_move.wav", -5.0)

	# Scoring
	if pong_ball.position.x < -pong_ball_size:
		pong_ai_score += 1
		_pong_update_score()
		pong_ball_speed = 300.0
		if pong_ai_score >= pong_max_score:
			_pong_game_over(false)
		else:
			_pong_reset_ball()

	if pong_ball.position.x > pong_area_width:
		pong_player_score += 1
		_pong_update_score()
		pong_ball_speed = 300.0
		if pong_player_score >= pong_max_score:
			_pong_game_over(true)
		else:
			_pong_reset_ball()


func _pong_update_score() -> void:
	if pong_score_label:
		pong_score_label.text = "%d - %d" % [pong_player_score, pong_ai_score]


func _pong_game_over(player_won: bool) -> void:
	pong_playing = false
	if pong_score_label:
		if player_won:
			pong_score_label.text = "YOU WIN!"
			pong_score_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		else:
			pong_score_label.text = "AI WINS!"
			pong_score_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

	# Auto-close after delay
	get_tree().create_timer(2.0).timeout.connect(_close_pong_game)


func _close_pong_game() -> void:
	if pong_panel:
		pong_panel.queue_free()
		pong_panel = null
		pong_game_area = null
		pong_ball = null
		pong_paddle_player = null
		pong_paddle_ai = null
		pong_score_label = null
	pong_playing = false
	pong_ball_speed = 300.0
	in_dialogue = false
