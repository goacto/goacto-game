extends Control
## Cargo Hold - Storage corridor connecting hallway to mail room
## Contains storage crates and lore elements

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

# Fade transition
@onready var fade_overlay: ColorRect = $FadeOverlay

# Header controls
var volume_button: Button = null
var save_indicator: Label = null
var volume_popup: PanelContainer = null
var is_muted: bool = false

# Player movement
var player_speed: float = 250.0
var player_bounds: Rect2 = Rect2(-450, -150, 1400, 350)  # Extended to the right for old storage

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
var is_moving: bool = false

# Interactive objects
const INTERACTIVE_OBJECTS = {
	"HallwayDoor": {
		"name": "Hallway Door",
		"prompt": "Press SPACE to return to hallway",
		"action": "go_hallway"
	},
	"MailRoomDoor": {
		"name": "Mail Room Door",
		"prompt": "Press SPACE to enter mail room",
		"action": "go_mail_room"
	},
	"OldStorageDoor": {
		"name": "Old Storage Room",
		"prompt": "Press SPACE to enter",
		"action": "go_old_storage"
	},
	"StorageCrate1": {
		"name": "Supply Crate A-7",
		"prompt": "Press SPACE to examine",
		"action": "examine_crate1"
	},
	"StorageCrate2": {
		"name": "Equipment Container",
		"prompt": "Press SPACE to examine",
		"action": "examine_crate2"
	},
	"StorageCrate3": {
		"name": "Antique Cargo Box",
		"prompt": "Press SPACE to examine",
		"action": "examine_crate3"
	},
	"DataTerminal": {
		"name": "Cargo Manifest",
		"prompt": "Press SPACE to read",
		"action": "read_manifest"
	}
}

# Object positions
var object_positions: Dictionary = {
	"HallwayDoor": Vector2(-400, 0),
	"MailRoomDoor": Vector2(400, 0),
	"OldStorageDoor": Vector2(850, 0),
	"StorageCrate1": Vector2(-150, 80),
	"StorageCrate2": Vector2(100, 100),
	"StorageCrate3": Vector2(600, 80),
	"DataTerminal": Vector2(0, -80)
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

	# Set player spawn position based on where they came from
	if GameManager.player_data.get("came_from_old_storage", false):
		# Coming from old storage - spawn near old storage door
		player.position = Vector2(800, 0)
		GameManager.player_data.erase("came_from_old_storage")
	elif GameManager.player_data.get("came_from_mail_room", false):
		# Coming from mail room - spawn near mail room door
		player.position = Vector2(350, 0)
		GameManager.player_data.erase("came_from_mail_room")
	elif GameManager.player_data.get("came_from_hallway", false):
		# Coming from hallway - spawn by hallway door
		player.position = Vector2(-350, 0)
		GameManager.player_data.erase("came_from_hallway")
	else:
		# Default spawn near hallway door
		player.position = Vector2(-350, 0)

	# Center the view
	_update_camera()

	# Fade in
	_fade_in()

	print("[CargoHold] Storage corridor ready")


func _fade_in() -> void:
	if fade_overlay:
		var tween = create_tween()
		tween.tween_property(fade_overlay, "color:a", 0.0, 0.5).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	animation_time += delta

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

		# Cardinal movement (W=up, S=down, A=left, D=right) - matches top-down layout
		var new_pos = player.position + input_dir * player_speed * delta

		# Clamp to room bounds
		new_pos.x = clamp(new_pos.x, player_bounds.position.x, player_bounds.position.x + player_bounds.size.x)
		new_pos.y = clamp(new_pos.y, player_bounds.position.y, player_bounds.position.y + player_bounds.size.y)

		player.position = new_pos

		# Movement sound
		is_moving = true
		move_sound_timer += delta
		if move_sound_timer >= move_sound_interval:
			move_sound_timer = 0.0
			_play_sfx("res://audio/sfx/hover_move.wav", -12.0)
	else:
		is_moving = false
		move_sound_timer = 0.0


func _update_camera() -> void:
	if not game_world or not isometric_base or not player:
		return

	var screen_center = game_world.size / 2
	var target_pos = screen_center - (player.position * camera_zoom)
	isometric_base.position = target_pos.round()
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
			_play_sfx("res://audio/sfx/door_open.wav")
			GameManager.player_data["came_from_cargo_hold"] = true
			GameManager.goto_scene("res://scenes/ship/hallway.tscn")
		"go_mail_room":
			if _is_mail_room_unlocked():
				_play_sfx("res://audio/sfx/door_open.wav")
				GameManager.goto_scene("res://scenes/ship/mail_room.tscn")
			else:
				_show_dialogue("Mail Room Locked", "The package receiving area is sealed.\n\n*A delivery chime sounds faintly inside*\n\nOnce you've connected with your human and started your journey, deliveries will begin arriving.")
		"go_old_storage":
			_play_sfx("res://audio/sfx/door_open.wav")
			GameManager.player_data["came_from_cargo_hold"] = true
			GameManager.goto_scene("res://scenes/ship/old_storage.tscn")
		"examine_crate1":
			_show_dialogue("Supply Crate A-7", "Standard Goactorian supply crate.\n\nContents: Nutrient packs, water purification tablets, emergency beacon.\n\n*Everything seems properly secured for the journey*")
		"examine_crate2":
			_show_dialogue("Equipment Container", "Heavy-duty equipment storage.\n\nLabel reads: \"Mindscape Enhancement Tools - Handle With Care\"\n\n*Sealed until needed. Mom's research equipment perhaps?*")
		"examine_crate3":
			_show_dialogue("Antique Cargo Box", "An old wooden crate with faded Goactorian script.\n\n*This looks like it hasn't been opened in decades...*\n\nLabel reads: \"FAMILY HEIRLOOMS - HANDLE WITH EXTREME CARE\"")
		"read_manifest":
			_show_cargo_manifest()


func _show_cargo_manifest() -> void:
	var pending_count = MailManager.get_pending_orders().size() if MailManager else 0
	var available_count = MailManager.get_mail_count() if MailManager else 0

	var manifest_text = "=== STELLAR WANDERER CARGO MANIFEST ===\n\n"
	manifest_text += "Pending Deliveries: " + str(pending_count) + "\n"
	manifest_text += "Packages Ready: " + str(available_count) + "\n\n"

	if available_count > 0:
		manifest_text += "Note: Packages waiting in Mail Room!\n"
	elif pending_count > 0:
		manifest_text += "Note: Deliveries in transit...\n"
	else:
		manifest_text += "All cargo accounted for.\nNo pending orders."

	_show_dialogue("Cargo Manifest", manifest_text)


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


func _is_mail_room_unlocked() -> bool:
	# Master key unlocks everything
	if GameManager.has_method("has_master_key") and GameManager.has_master_key():
		return true
	# Mail room unlocks after first focus session (connected with human)
	if GameManager.player_data.get("total_focus_sessions", 0) >= 1:
		return true
	# Or if console is placed and intro completed
	if CampaignManager.has_seen_cutscene("intro_part2"):
		return true
	return false


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
