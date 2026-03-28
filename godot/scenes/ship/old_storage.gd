extends Control
## Old Storage Room - Ancient storage area with family heirlooms
## Contains the Mindscape Console that Goacto needs to find

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
var player_bounds: Rect2 = Rect2(-350, -150, 700, 350)

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

# Mindscape console reference
var mindscape_console_visual: Node2D = null

# Interactive objects
const INTERACTIVE_OBJECTS = {
	"CargoHoldDoor": {
		"name": "Cargo Hold Door",
		"prompt": "Press SPACE to return",
		"action": "go_cargo_hold"
	},
	"MindscapeConsole": {
		"name": "Mindscape Console",
		"prompt": "Press SPACE to pick up",
		"action": "pickup_console"
	},
	"OldChest": {
		"name": "Great-Elder's Chest",
		"prompt": "Press SPACE to examine",
		"action": "examine_chest"
	},
	"DustyShelf": {
		"name": "Dusty Shelf",
		"prompt": "Press SPACE to examine",
		"action": "examine_shelf"
	},
	"FamilyPortrait": {
		"name": "Old Family Portrait",
		"prompt": "Press SPACE to examine",
		"action": "examine_portrait"
	}
}

# Object positions
var object_positions: Dictionary = {
	"CargoHoldDoor": Vector2(-300, 0),
	"MindscapeConsole": Vector2(150, 0),
	"OldChest": Vector2(-100, 100),
	"DustyShelf": Vector2(250, -80),
	"FamilyPortrait": Vector2(0, -100)
}


func _ready() -> void:
	# Connect dialogue button
	dialogue_button.pressed.connect(_close_dialogue)

	# Connect menu button
	menu_button.pressed.connect(_open_pause_menu)

	# Setup header controls
	_setup_header_controls()

	# Play ship music and ambient
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		if audio.has_method("play_music_ship"):
			audio.play_music_ship()
		if audio.has_method("play_ambient_ship"):
			audio.play_ambient_ship()

	# Hide UI initially
	interaction_prompt.visible = false
	dialogue_panel.visible = false

	# Setup Mindscape console visual
	mindscape_console_visual = isometric_base.get_node_or_null("MindscapeConsole")
	if mindscape_console_visual:
		# Check if console has already been picked up or placed in bedroom
		var console_picked_up = GameManager.has_item("mindscape_console")
		var console_in_bedroom = GameManager.player_data.get("console_placed_in_bedroom", false)
		print("[OldStorage] Console state - picked_up: ", console_picked_up, " in_bedroom: ", console_in_bedroom)

		if console_picked_up or console_in_bedroom:
			# Console already collected - hide it
			mindscape_console_visual.visible = false
			object_positions.erase("MindscapeConsole")
			print("[OldStorage] Console hidden - already collected/placed")
		else:
			# Console should be visible - ensure it's shown
			mindscape_console_visual.visible = true
			if "MindscapeConsole" not in object_positions:
				object_positions["MindscapeConsole"] = Vector2(150, 0)
			print("[OldStorage] Console VISIBLE - waiting to be discovered!")

	# Position player near door
	if GameManager.player_data.get("came_from_cargo_hold", false):
		player.position = Vector2(-220, 0)
		GameManager.player_data.erase("came_from_cargo_hold")
	else:
		player.position = Vector2(-220, 0)

	# Center the view
	_update_camera()

	# Fade in
	_fade_in()

	# First time entering - show discovery dialogue
	if not CampaignManager.has_seen_cutscene("old_storage_entered"):
		await get_tree().create_timer(0.8).timeout
		_show_dialogue("Old Storage Room", "*Dust particles float in the dim light...*\n\nThis room hasn't been opened in years. Ancient boxes and covered furniture fill the space.\n\n*Something glows faintly in the corner...*")
		_play_voice("res://audio/voice/old_storage/room_enter.ogg")
		CampaignManager.mark_cutscene_seen("old_storage_entered")

	print("[OldStorage] Ancient storage room ready")


func _fade_in() -> void:
	if fade_overlay:
		var tween = create_tween()
		tween.tween_property(fade_overlay, "color:a", 0.0, 0.5).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	animation_time += delta

	# Animate console glow if visible
	_animate_console()

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

	# ESC handling
	if event.is_action_pressed("ui_cancel"):
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

	# Block inputs when pause menu is open
	if pause_menu:
		return

	if in_dialogue:
		if event.is_action_pressed("ui_accept"):
			if dialogue_text.visible_ratio < 1.0:
				_skip_typing()
			else:
				_close_dialogue()
			viewport.set_input_as_handled()
		return

	# Interact with nearby object
	if event.is_action_pressed("ui_accept") and nearby_object != "":
		_interact_with_object(nearby_object)
		viewport.set_input_as_handled()

	# Touch interaction
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if nearby_object != "" and interaction_prompt.visible:
			_interact_with_object(nearby_object)

	# Zoom
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

		# Cardinal movement (W=up, S=down, A=left, D=right)
		var new_pos = player.position + input_dir * player_speed * delta

		# Clamp to bounds
		new_pos.x = clamp(new_pos.x, player_bounds.position.x, player_bounds.position.x + player_bounds.size.x)
		new_pos.y = clamp(new_pos.y, player_bounds.position.y, player_bounds.position.y + player_bounds.size.y)

		player.position = new_pos

		# Movement sound
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
		"go_cargo_hold":
			_play_sfx("res://audio/sfx/door_open.wav")
			GameManager.player_data["came_from_old_storage"] = true
			GameManager.goto_scene("res://scenes/ship/cargo_hold.tscn")
		"pickup_console":
			_pickup_mindscape_console()
		"examine_chest":
			_show_dialogue("Great-Elder's Chest", "A beautifully carved chest with Goactorian symbols.\n\nIt belonged to Great-Elder Zyx before they passed.\n\n*You run your fingers over the intricate patterns, feeling a connection to your ancestors.*")
			_play_voice("res://audio/voice/old_storage/examine_chest.ogg")
		"examine_shelf":
			_show_dialogue("Dusty Shelf", "Old data crystals and memory cubes line the shelves.\n\nLabels have faded beyond reading.\n\n*These contain knowledge from generations past, waiting to be rediscovered.*")
			_play_voice("res://audio/voice/old_storage/examine_shelf.ogg")
		"examine_portrait":
			_show_dialogue("Old Family Portrait", "A holographic family portrait from three generations ago.\n\nYou recognize Great-Elder Zyx as a young Goactorian.\n\n*They're holding a small device that looks familiar... is that the Mindscape Console?*")
			_play_voice("res://audio/voice/old_storage/examine_portrait.ogg")


func _pickup_mindscape_console() -> void:
	# Play pickup sound
	_play_sfx("res://audio/sfx/key_pickup.wav")

	# Add to inventory
	GameManager.add_item("mindscape_console")

	# Mark as needing placement
	GameManager.player_data["needs_console_placement"] = true

	# Hide the visual
	if mindscape_console_visual:
		mindscape_console_visual.visible = false

	# Remove from interactive objects
	object_positions.erase("MindscapeConsole")
	nearby_object = ""
	_hide_interaction_prompt()

	# Show pickup message
	_show_dialogue("Mindscape Console Found!", "You found Great-Elder Zyx's Mindscape Console!\n\n*The ancient device hums warmly in your hands, as if recognizing its new owner.*\n\nThis is how Goactorians connect with their human companions. Take it back to your room and set it up!\n\n*The console has been added to your inventory.*")
	_play_voice("res://audio/voice/old_storage/console_found.ogg")


func _animate_console() -> void:
	if not mindscape_console_visual or not mindscape_console_visual.visible:
		return

	# Pulse the console glow
	var glow = mindscape_console_visual.get_node_or_null("Glow")
	if glow:
		var pulse = 0.3 + sin(animation_time * 2.5) * 0.15
		glow.modulate.a = pulse

	# Subtle float animation
	var console_body = mindscape_console_visual.get_node_or_null("ConsoleBody")
	if console_body:
		console_body.position.y = sin(animation_time * 1.5) * 2


# =============================================================================
# DIALOGUE SYSTEM
# =============================================================================

func _show_dialogue(title: String, text: String, callback: Callable = Callable()) -> void:
	dialogue_title.text = title
	dialogue_full_text = text
	dialogue_panel.visible = true
	in_dialogue = true
	interaction_prompt.visible = false
	dialogue_callback = callback

	if callback.is_valid():
		dialogue_button.text = "Yes"
	else:
		dialogue_button.text = "Continue"

	_start_typing_effect(text)


func _start_typing_effect(text: String) -> void:
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()

	dialogue_text.text = text
	dialogue_text.visible_ratio = 0.0

	var duration = text.length() * 0.025
	duration = clamp(duration, 0.5, 6.0)

	typing_tween = create_tween()
	if typing_tween:
		typing_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)


func _skip_typing() -> void:
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
	dialogue_text.visible_ratio = 1.0


func _close_dialogue() -> void:
	dialogue_panel.visible = false
	in_dialogue = false

	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()

	if dialogue_callback.is_valid():
		dialogue_callback.call()
		dialogue_callback = Callable()


func _play_voice(voice_path: String) -> void:
	if not ResourceLoader.exists(voice_path):
		return
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_voice_from_path"):
		audio.play_voice_from_path(voice_path)


func _play_sfx(sfx_path: String, volume_db: float = 0.0) -> void:
	if not ResourceLoader.exists(sfx_path):
		return

	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		var stream = load(sfx_path)
		if stream:
			audio.play_sfx(stream, volume_db)


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
	else:
		audio.set_master_volume(0.0)
	is_muted = not is_muted
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
