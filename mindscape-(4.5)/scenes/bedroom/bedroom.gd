extends Control
## Bedroom - Agent Goacto's cabin on the Stellar Wanderer
## The "real world" space before entering the Mindscape via headset

# World elements
@onready var game_world: Control = $GameWorld
@onready var isometric_base: Node2D = $GameWorld/IsometricBase
@onready var player: Node2D = $GameWorld/IsometricBase/Player

# Interactive objects
@onready var headset_glow: Polygon2D = $GameWorld/IsometricBase/Console/HeadsetGlow
@onready var window_stars: Node2D = $GameWorld/IsometricBase/Window/Stars

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
var player_bounds: Rect2 = Rect2(-680, -540, 1360, 1080)  # Expanded plus-shaped bedroom
var virtual_joystick: Control = null
var joystick_input: Vector2 = Vector2.ZERO

# Camera
var camera_zoom: float = 0.85
var min_zoom: float = 0.5
var max_zoom: float = 1.5
var zoom_speed: float = 0.08

# Interaction state
var nearby_object: String = ""
var in_dialogue: bool = false

# Auto-play dialogue settings
var auto_play_enabled: bool = false
var auto_play_delay: float = 1.5
var auto_play_timer: float = 0.0
var auto_play_waiting: bool = false

# Animation
var animation_time: float = 0.0
var star_twinkle_time: float = 0.0

# Movement sound
var move_sound_timer: float = 0.0
var move_sound_interval: float = 0.35

# Wake-up animation state
var is_waking_up: bool = false
var wakeup_phase: int = 0  # 0=not waking, 1=lying in bed, 2=sitting up, 3=standing
var wakeup_timer: float = 0.0

# Console placement state
var console_placed: bool = false
var console_visual: Node2D = null
var debug_frame_counter: int = 0  # DEBUG: track frames after console placement
var debug_console_just_placed: bool = false  # DEBUG: flag to start frame counting

# Bedroom items unlock state (for progressive campaign unlocks)
var closet_unlocked: bool = false
var mirror_unlocked: bool = false
var bookshelf_unlocked: bool = false
var photo_album_unlocked: bool = false
var closet_visual: Node2D = null
var mirror_visual: Node2D = null
var bookshelf_visual: Node2D = null
var photo_album_visual: Node2D = null
var closet_lock_icon: Node2D = null
var mirror_lock_icon: Node2D = null
var bookshelf_lock_icon: Node2D = null
var photo_album_lock_icon: Node2D = null

# Photo Album detail view
var photo_album_panel: Control = null
var photo_album_time: float = 0.0
var selected_photo_index: int = 0
var unlocked_photos: Array = []

# Focus Analytics
var focus_dashboard: Control = null
var focus_analytics_visual: Node2D = null

# Interactive objects in room
const INTERACTIVE_OBJECTS = {
	"Console": {
		"name": "Mindscape Console",
		"prompt": "Press SPACE to put on headset",
		"action": "enter_mindscape"
	},
	"Window": {
		"name": "Observation Window",
		"prompt": "Press SPACE to gaze at the stars",
		"action": "look_window"
	},
	"Bed": {
		"name": "Sleep Pod",
		"prompt": "Press SPACE to interact",
		"action": "open_sleep_pod"
	},
	"Bookshelf": {
		"name": "Data Archive",
		"prompt": "Press SPACE to browse",
		"action": "browse_books"
	},
	"Plant": {
		"name": "Goactorian Fern",
		"prompt": "Press SPACE to examine",
		"action": "examine_plant"
	},
	"PhotoAlbum": {
		"name": "Family Photo Album",
		"prompt": "Press SPACE to open album",
		"action": "open_photo_album"
	},
	"Door": {
		"name": "Room Door",
		"prompt": "Press SPACE to leave room",
		"action": "go_stairs"
	},
	"Closet": {
		"name": "Wardrobe Station",
		"prompt": "Press SPACE to customize appearance",
		"action": "open_closet"
	},
	"Mirror": {
		"name": "Holographic Mirror",
		"prompt": "Press SPACE to view yourself",
		"action": "open_mirror"
	},
	"ConsolePlacementSpot": {
		"name": "Console Pedestal",
		"prompt": "Press SPACE to place Mindscape Console",
		"action": "place_console"
	},
	"FocusAnalytics": {
		"name": "Focus Analytics Terminal",
		"prompt": "Press SPACE to view stats",
		"action": "open_focus_dashboard"
	}
}

# Object positions for proximity detection (expanded plus-shaped layout)
var object_positions: Dictionary = {
	# Left wing
	"Window": Vector2(-450, -120),
	"Door": Vector2(-550, 100),
	# Top wing
	"Plant": Vector2(-80, -420),
	"FocusAnalytics": Vector2(0, -300),
	# Center area
	"Console": Vector2(0, 0),
	"ConsolePlacementSpot": Vector2(0, 0),
	# Right wing
	"Closet": Vector2(580, -100),
	"Mirror": Vector2(580, 100),
	"Bookshelf": Vector2(130, -380),
	# Bottom wing
	"Bed": Vector2(0, 400),
	"PhotoAlbum": Vector2(0, 500)
}


func _ready() -> void:
	# Load auto-play settings
	_load_auto_play_settings()

	# Connect dialogue button
	dialogue_button.pressed.connect(_on_dialogue_button_pressed)

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
	control_hints.visible = false

	# Check if this is a "continue journey" wake-up
	if GameManager.player_data.get("wakeup_from_continue", false):
		GameManager.player_data.erase("wakeup_from_continue")
		_start_wakeup_sequence()
	else:
		# Normal entry - center the view
		control_hints.visible = true
		_update_camera()

	# Start animations
	_setup_star_animation()

	# Hide unlockable items initially before checking state
	_hide_unlockable_items_initially()

	# Check if console has been placed and all bedroom items
	_check_console_state()

	# Show master key notification if applicable
	_check_master_key_unlock()

	# Setup enhanced visual effects
	_setup_floor_lighting()
	if console_placed:
		_setup_console_hologram()
	_setup_ambient_particles()
	_setup_animated_fern()
	_setup_sleep_pod()

	# Apply player customization
	_update_player_appearance()

	# Connect to customization updates
	if CustomizationManager:
		CustomizationManager.avatar_updated.connect(_update_player_appearance)
	_setup_personal_items()
	_setup_proximity_glows()
	_setup_discovery_shimmers()

	# Load any placed room decorations
	_load_placed_decorations()

	# Show tutorial tooltips for first-time visitors
	_check_bedroom_tutorials()

	# Check if player has console in inventory - show hint
	if GameManager.has_item("mindscape_console") and not console_placed:
		await get_tree().create_timer(0.8).timeout
		_show_dialogue("Console Ready", "You have Great-Elder Zyx's Mindscape Console!\n\n*The console hums eagerly in your inventory*\n\nFind the pedestal in your room to place it.")
		GameManager.player_data.erase("needs_console_placement")

	# Setup virtual joystick for mobile
	_setup_virtual_joystick()

	# Announce scene for screen reader
	var accessibility = get_node_or_null("/root/AccessibilityManager")
	if accessibility:
		accessibility.announce_location("Bedroom", "Agent Goacto's cabin on the Stellar Wanderer")

	print("[Bedroom] Goacto's cabin ready - Welcome aboard the Stellar Wanderer")


func _process(delta: float) -> void:
	# DEBUG: Track frames after console placement
	if debug_console_just_placed:
		debug_frame_counter += 1
		if debug_frame_counter <= 5 or debug_frame_counter % 30 == 0:
			print("[Bedroom] DEBUG: Frame ", debug_frame_counter, " after console placement")

	# Animate room elements
	_animate_room(delta)

	# Handle wake-up sequence (non-blocking - visual only)
	if is_waking_up:
		_process_wakeup(delta)
		# Continue to allow movement during wake-up animation

	# Update decoration ghost if in decoration mode
	if decoration_mode:
		_update_decoration_ghost()
		_check_decoration_hover()

	if in_dialogue:
		# Safety check: if in_dialogue is true but panel isn't visible, we're stuck
		if dialogue_panel and not dialogue_panel.visible:
			print("[Bedroom] WARNING: in_dialogue true but panel not visible - recovering")
			in_dialogue = false
			# Don't return, allow normal processing
		else:
			# Handle auto-play countdown
			if auto_play_waiting and auto_play_enabled:
				auto_play_timer += delta
				var remaining = max(0, auto_play_delay - auto_play_timer)
				dialogue_button.text = "Auto... (%.1fs)" % remaining
				if auto_play_timer >= auto_play_delay:
					auto_play_waiting = false
					auto_play_timer = 0.0
					_close_dialogue()
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
		if pause_menu:
			_close_pause_menu()
			viewport.set_input_as_handled()
			return
		if delete_confirm_dialog:
			_cancel_delete()
			viewport.set_input_as_handled()
			return
		if load_confirm_dialog:
			_cancel_load()
			viewport.set_input_as_handled()
			return
		if save_panel:
			_close_save_panel()
			viewport.set_input_as_handled()
			return
		if space_view_panel and space_view_panel.visible:
			_close_space_view()
			viewport.set_input_as_handled()
			return
		if fern_detail_panel and fern_detail_panel.visible:
			_close_fern_detail()
			viewport.set_input_as_handled()
			return
		if bookshelf_detail_panel and bookshelf_detail_panel.visible:
			_close_bookshelf_detail()
			viewport.set_input_as_handled()
			return
		if photo_album_panel and photo_album_panel.visible:
			_close_photo_album()
			viewport.set_input_as_handled()
			return
		if customization_panel:
			_close_customization_panel()
			viewport.set_input_as_handled()
			return
		if mirror_panel:
			_close_mirror_view()
			viewport.set_input_as_handled()
			return
		if decoration_panel:
			_close_decoration_mode()
			viewport.set_input_as_handled()
			return
		if dialogue_panel.visible:
			_on_dialogue_button_pressed()  # Also cancels auto-play
			viewport.set_input_as_handled()
			return
		if focus_dashboard:
			_close_focus_dashboard()
			viewport.set_input_as_handled()
			return
		if sleep_pod_menu:
			_close_sleep_pod_menu()
			viewport.set_input_as_handled()
			return
		# If nothing is open, open pause menu
		_open_pause_menu()
		viewport.set_input_as_handled()
		return

	# Close space view with SPACE
	if space_view_panel and space_view_panel.visible:
		if event.is_action_pressed("ui_accept"):
			_close_space_view()
			viewport.set_input_as_handled()
		return

	# Block other inputs while panels are open
	if save_panel or pause_menu:
		return

	# Handle decoration mode clicks
	if decoration_mode:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = event.position
			# Skip if clicking on the panel
			if decoration_panel and decoration_panel.get_global_rect().has_point(mouse_pos):
				return

			# Check if clicking on a placed decoration to pick it up
			if hovered_decoration:
				_pickup_placed_decoration(hovered_decoration)
				viewport.set_input_as_handled()
				return

			# Otherwise, place the selected decoration
			if selected_decoration != "":
				_place_decoration()
				viewport.set_input_as_handled()
				return

	# Close fern detail view with SPACE
	if fern_detail_panel and fern_detail_panel.visible:
		if event.is_action_pressed("ui_accept"):
			_close_fern_detail()
			viewport.set_input_as_handled()
		return

	# Close bookshelf detail view with SPACE
	if bookshelf_detail_panel and bookshelf_detail_panel.visible:
		if event.is_action_pressed("ui_accept"):
			_close_bookshelf_detail()
			viewport.set_input_as_handled()
		return

	# Close photo album view with SPACE
	if photo_album_panel and photo_album_panel.visible:
		if event.is_action_pressed("ui_accept"):
			_close_photo_album()
			viewport.set_input_as_handled()
		return

	if in_dialogue:
		if event.is_action_pressed("ui_accept"):
			_on_dialogue_button_pressed()  # Also cancels auto-play
			viewport.set_input_as_handled()
		return

	# Interact with nearby object
	if event.is_action_pressed("ui_accept") and nearby_object != "":
		_interact_with_object(nearby_object)
		viewport.set_input_as_handled()

	# M key to toggle mute (when no panels open)
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		if not pause_menu and not save_panel and not in_dialogue:
			_toggle_mute()
			viewport.set_input_as_handled()
			return

	# Touch/click interaction
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Close volume popup on click outside
		if volume_popup and volume_button:
			var popup_rect = Rect2(volume_popup.global_position, volume_popup.size)
			var btn_rect = Rect2(volume_button.global_position, volume_button.size)
			if not popup_rect.has_point(event.position) and not btn_rect.has_point(event.position):
				_close_volume_popup()

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

	# Check keyboard input
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	# Add virtual joystick input (for mobile)
	if joystick_input != Vector2.ZERO:
		input_dir = joystick_input

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()

		# Cardinal movement (W=up, S=down, A=left, D=right) - matches top-down room layout
		var new_pos = player.position + input_dir * player_speed * delta

		# Clamp to plus-shaped room bounds (pass current position to track region)
		new_pos = _clamp_to_plus_bounds(new_pos, player.position)

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


func _clamp_to_plus_bounds(pos: Vector2, current_pos: Vector2 = Vector2.ZERO) -> Vector2:
	# Plus-shaped floor bounds (matching the floor polygon)
	# Top arm: x from -180 to 180, y from -540 to -180
	# Center bar: x from -680 to 680, y from -180 to 180
	# Bottom arm: x from -180 to 180, y from 180 to 540

	var result = pos

	# Determine which region the player is currently in
	var current_region = "center"
	if current_pos.y < -180 and current_pos.x >= -180 and current_pos.x <= 180:
		current_region = "top"
	elif current_pos.y > 180 and current_pos.x >= -180 and current_pos.x <= 180:
		current_region = "bottom"

	# Clamp based on current region and desired position
	match current_region:
		"top":
			# In top arm - can move within arm or transition to center
			if pos.y >= -180:
				# Moving into center bar - allow full x
				result.x = clamp(pos.x, -680, 680)
				result.y = clamp(pos.y, -180, 180)
			else:
				# Staying in top arm - narrow x
				result.x = clamp(pos.x, -180, 180)
				result.y = clamp(pos.y, -540, -180)
		"bottom":
			# In bottom arm - can move within arm or transition to center
			if pos.y <= 180:
				# Moving into center bar - allow full x
				result.x = clamp(pos.x, -680, 680)
				result.y = clamp(pos.y, -180, 180)
			else:
				# Staying in bottom arm - narrow x
				result.x = clamp(pos.x, -180, 180)
				result.y = clamp(pos.y, 180, 540)
		"center":
			# In center bar - can move anywhere valid
			if pos.y < -180 and pos.x >= -180 and pos.x <= 180:
				# Can enter top arm
				result.x = clamp(pos.x, -180, 180)
				result.y = clamp(pos.y, -540, -180)
			elif pos.y > 180 and pos.x >= -180 and pos.x <= 180:
				# Can enter bottom arm
				result.x = clamp(pos.x, -180, 180)
				result.y = clamp(pos.y, 180, 540)
			else:
				# Stay in center bar
				result.x = clamp(pos.x, -680, 680)
				result.y = clamp(pos.y, -180, 180)

	return result


func _setup_virtual_joystick() -> void:
	# Only show on mobile devices
	if not MobileUIManager.is_mobile:
		return

	# Load and instantiate the virtual joystick
	var joystick_scene = load("res://scenes/ui/virtual_joystick.tscn")
	if joystick_scene:
		virtual_joystick = joystick_scene.instantiate()
		virtual_joystick.name = "VirtualJoystick"
		add_child(virtual_joystick)

		# Connect joystick signals
		if virtual_joystick.has_signal("joystick_input"):
			virtual_joystick.joystick_input.connect(_on_joystick_input)
		if virtual_joystick.has_signal("joystick_released"):
			virtual_joystick.joystick_released.connect(_on_joystick_released)


func _on_joystick_input(direction: Vector2) -> void:
	joystick_input = direction


func _on_joystick_released() -> void:
	joystick_input = Vector2.ZERO


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
	var closest_distance: float = 100.0  # Interaction radius (larger room)

	for object_name in object_positions:
		# Skip FocusAnalytics if not unlocked
		if object_name == "FocusAnalytics" and not _is_focus_analytics_unlocked():
			continue

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

	var name_text = obj_data.get("name", object_id)
	var prompt = obj_data.get("prompt", "Press SPACE to interact")

	# Check if this is a locked bedroom item
	var lock_info = _get_bedroom_item_lock_info(object_id)
	if lock_info["locked"]:
		name_text = "[LOCKED] " + name_text
		prompt = lock_info["hint"]

	object_name_label.text = name_text
	prompt_text_label.text = prompt

	interaction_prompt.visible = true
	control_hints.visible = false


func _get_bedroom_item_lock_info(object_id: String) -> Dictionary:
	## Returns lock status and unlock hint for bedroom items
	match object_id:
		"Closet":
			if not closet_unlocked:
				return {
					"locked": true,
					"hint": "Complete 1 focus session to unlock",
					"title": "Wardrobe Locked",
					"message": "The Wardrobe Station's holographic interface flickers dimly.\n\n\"Authorization required. Complete your first focus session to activate customization systems.\"\n\nUse the Mindscape Console to begin a focus session."
				}
		"Mirror":
			if not mirror_unlocked:
				return {
					"locked": true,
					"hint": "Achieve a 3-day streak to unlock",
					"title": "Mirror Locked",
					"message": "The Holographic Mirror's surface remains dark.\n\n\"Consistency protocols not yet met. Maintain a 3-day activity streak to calibrate reflection systems.\"\n\nComplete your habits daily to build your streak."
				}
		"Bookshelf":
			if not bookshelf_unlocked:
				return {
					"locked": true,
					"hint": "Write 1 journal entry to unlock",
					"title": "Archive Locked",
					"message": "The Data Archive's access panel blinks red.\n\n\"Personal records required. Submit at least one journal entry to initialize the archive.\"\n\nVisit the Reflection Pool in the Mindscape to write a journal entry."
				}
		"PhotoAlbum":
			if not photo_album_unlocked:
				return {
					"locked": true,
					"hint": "Complete Chapter 1 to unlock",
					"title": "Album Sealed",
					"message": "The Family Photo Album's holographic seal glows faintly.\n\n\"Memory restoration in progress. Complete Chapter 1: The Awakening to unlock family records.\"\n\nProgress through your journey to restore these memories."
				}
	return {"locked": false, "hint": "", "title": "", "message": ""}


func _hide_interaction_prompt() -> void:
	interaction_prompt.visible = false
	control_hints.visible = true


func _interact_with_object(object_id: String) -> void:
	# Check if this is a locked bedroom item first
	var lock_info = _get_bedroom_item_lock_info(object_id)
	if lock_info["locked"]:
		_show_locked_item_dialogue(lock_info)
		return

	# Mark object as discovered (removes shimmer hint)
	GameManager.mark_object_discovered("bedroom_" + object_id)

	var obj_data = INTERACTIVE_OBJECTS.get(object_id, {})
	var action = obj_data.get("action", "")

	match action:
		"enter_mindscape":
			_enter_mindscape()
		"look_window":
			_show_space_view()
		"save_game":
			_show_save_panel()
		"open_sleep_pod":
			_open_sleep_pod_menu()
		"browse_books":
			_show_bookshelf_detail_view()
		"examine_plant":
			_show_fern_detail_view()
		"go_stairs":
			GameManager.player_data["came_from_bedroom"] = true
			GameManager.goto_scene("res://scenes/ship/stairs.tscn")
		"open_closet":
			_open_customization_panel()
		"open_decoration_mode":
			_open_decoration_mode()
		"open_mirror":
			_show_mirror_view()
		"place_console":
			_place_console_from_inventory()
		"open_focus_dashboard":
			_open_focus_dashboard()
		"open_photo_album":
			_show_photo_album_view()


func _show_locked_item_dialogue(lock_info: Dictionary) -> void:
	## Show dialogue explaining how to unlock a locked bedroom item
	_play_sfx("res://audio/sfx/locked.wav")
	_show_dialogue(lock_info["title"], lock_info["message"])


func _load_auto_play_settings() -> void:
	var settings = SaveManager.load_settings()
	auto_play_enabled = settings.get("auto_play_cutscenes", false)
	auto_play_delay = settings.get("auto_play_delay", 1.5)


func _show_dialogue(title: String, text: String, voice_path: String = "") -> void:
	# Safety checks
	if not dialogue_panel or not is_instance_valid(dialogue_panel):
		push_error("[Bedroom] Cannot show dialogue - panel invalid")
		return
	if not dialogue_title or not dialogue_text:
		push_error("[Bedroom] Cannot show dialogue - title/text labels invalid")
		return

	dialogue_title.text = title
	dialogue_text.text = text
	dialogue_panel.visible = true
	in_dialogue = true
	if interaction_prompt:
		interaction_prompt.visible = false
	_update_mobile_controls_visibility()

	# Hide interactive object labels to prevent z-index overlap
	_set_interactive_labels_visible(false)

	# Start auto-play timer if enabled
	if auto_play_enabled:
		auto_play_waiting = true
		auto_play_timer = 0.0
		dialogue_button.text = "Auto... (%.1fs)" % auto_play_delay
	else:
		auto_play_waiting = false
		dialogue_button.text = "Continue"

	# Play voice if provided
	if voice_path != "":
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_voice_from_path"):
			audio.play_voice_from_path(voice_path)


func _on_dialogue_button_pressed() -> void:
	# Cancel auto-play and close
	auto_play_waiting = false
	auto_play_timer = 0.0
	_close_dialogue()


func _close_dialogue() -> void:
	dialogue_panel.visible = false
	in_dialogue = false
	auto_play_waiting = false
	auto_play_timer = 0.0
	dialogue_button.text = "Continue"
	_update_mobile_controls_visibility()
	# Restore interactive object labels
	_set_interactive_labels_visible(true)


func _update_mobile_controls_visibility() -> void:
	if not virtual_joystick:
		return

	# Hide mobile controls when any panel is open
	var should_show = not in_dialogue
	if virtual_joystick.has_method("set_controls_visible"):
		virtual_joystick.set_controls_visible(should_show)
	else:
		virtual_joystick.visible = should_show


func _enter_mindscape() -> void:
	# Check if console is placed
	if not console_placed:
		_show_dialogue("No Console", "You haven't set up the Mindscape Console yet.\n\nSearch the ship to find Great-Elder Zyx's console.")
		return

	# Check if this is the first time using the headset (intro_part2 not seen)
	if not CampaignManager.has_seen_cutscene("intro_part2"):
		# Play the second part of the intro cutscene
		_play_intro_part2()
		return

	# Regular headset activation for returning players
	# Store that we're entering from bedroom
	GameManager.player_data["entered_from_bedroom"] = true

	# Use visual transition to mindscape
	GameManager.player_data["transition_type"] = "enter"
	GameManager.player_data["transition_target"] = "res://scenes/mindscape/mindscape_hub.tscn"
	get_tree().change_scene_to_file("res://scenes/transition/headset_transition.tscn")


func _play_intro_part2() -> void:
	# Store that we're entering from bedroom
	GameManager.player_data["entered_from_bedroom"] = true

	# Play the intro_part2 cutscene (console activation, finding human, entering mindscape)
	GameManager.player_data["pending_cutscene"] = "intro_part2"
	GameManager.goto_scene("res://scenes/cutscene/cutscene.tscn")


func _hide_unlockable_items_initially() -> void:
	## Hide all unlockable bedroom items before checking their state
	## This ensures nothing is visible by default
	var items_to_hide = ["Console", "Closet", "Mirror", "Bookshelf"]
	for item_name in items_to_hide:
		var node = isometric_base.get_node_or_null(item_name)
		if node:
			node.visible = false

	# Also hide the headset glow
	if headset_glow:
		headset_glow.visible = false


func _check_console_state() -> void:
	# Check if the console has been placed in the room
	console_placed = GameManager.player_data.get("console_placed_in_bedroom", false)

	# Master key unlocks everything
	var has_master = GameManager.has_master_key() if GameManager.has_method("has_master_key") else false
	if has_master:
		console_placed = true

	# Find the console visual in the scene
	console_visual = isometric_base.get_node_or_null("Console")

	# Check if player has console in inventory
	var has_console_in_inventory = GameManager.has_item("mindscape_console") if GameManager.has_method("has_item") else false

	if console_placed:
		# Console is placed - show console, hide placement spot
		if console_visual:
			console_visual.visible = true
		if "Console" not in object_positions:
			object_positions["Console"] = Vector2(0, 0)
		object_positions.erase("ConsolePlacementSpot")
	elif has_console_in_inventory:
		# Console in inventory but not placed - show placement spot
		if console_visual:
			console_visual.visible = false
		if headset_glow:
			headset_glow.visible = false
		object_positions.erase("Console")
		if "ConsolePlacementSpot" not in object_positions:
			object_positions["ConsolePlacementSpot"] = Vector2(0, 0)
		# Create a visual indicator for placement spot
		_setup_placement_spot_indicator()
	else:
		# Console not placed and not in inventory - hide both
		if console_visual:
			console_visual.visible = false
		if headset_glow:
			headset_glow.visible = false
		object_positions.erase("Console")
		object_positions.erase("ConsolePlacementSpot")

	# Also check all other bedroom items
	_check_bedroom_items_state()


func _check_bedroom_items_state() -> void:
	## Check unlock state of closet, mirror, and bookshelf
	## Master key unlocks everything immediately

	# Master key check - unlocks all bedroom features
	var has_master = GameManager.has_master_key() if GameManager.has_method("has_master_key") else false

	# Get installed items from player data
	var installed_items: Array = GameManager.player_data.get("bedroom_items_installed", [])

	# Check each item's unlock state
	if has_master:
		# Master key = full bedroom completion
		closet_unlocked = true
		mirror_unlocked = true
		bookshelf_unlocked = true
		photo_album_unlocked = true
		console_placed = true

		# Also mark them as installed in save data for persistence
		if "wardrobe" not in installed_items:
			installed_items.append("wardrobe")
		if "mirror" not in installed_items:
			installed_items.append("mirror")
		if "data_archive" not in installed_items:
			installed_items.append("data_archive")
		if "mindscape_console" not in installed_items:
			installed_items.append("mindscape_console")
		if "photo_album" not in installed_items:
			installed_items.append("photo_album")
		GameManager.player_data["bedroom_items_installed"] = installed_items
		GameManager.player_data["console_placed_in_bedroom"] = true
	else:
		# Normal progression - check individual unlock status
		closet_unlocked = "wardrobe" in installed_items or GameManager.player_data.get("closet_unlocked", false)
		mirror_unlocked = "mirror" in installed_items or GameManager.player_data.get("mirror_unlocked", false)
		bookshelf_unlocked = "data_archive" in installed_items or GameManager.player_data.get("bookshelf_unlocked", false)
		# Photo album unlocks after Chapter 1 completion
		var current_chapter = GameManager.player_data.get("current_chapter", 1)
		var chapters_completed = GameManager.player_data.get("chapters_completed", [])
		photo_album_unlocked = "photo_album" in installed_items or current_chapter > 1 or 1 in chapters_completed

	# Find visual nodes
	closet_visual = isometric_base.get_node_or_null("Closet")
	mirror_visual = isometric_base.get_node_or_null("Mirror")
	bookshelf_visual = isometric_base.get_node_or_null("Bookshelf")
	photo_album_visual = isometric_base.get_node_or_null("PhotoAlbum")

	# Apply visibility based on unlock state
	_apply_bedroom_item_visibility()


func _check_master_key_unlock() -> void:
	## Check if master key was used to unlock bedroom and show notification
	var has_master = GameManager.has_master_key() if GameManager.has_method("has_master_key") else false
	if not has_master:
		return

	# Check if we've already shown the master key notification
	var shown_notification = GameManager.player_data.get("master_key_bedroom_notification_shown", false)
	if shown_notification:
		return

	# Mark notification as shown
	GameManager.player_data["master_key_bedroom_notification_shown"] = true

	# Show notification after a short delay
	await get_tree().create_timer(0.8).timeout
	_show_dialogue(
		"Master Key Activated",
		"The Master Key pulses with ancient energy...\n\n" +
		"✨ Mindscape Console: UNLOCKED\n" +
		"✨ Wardrobe Station: UNLOCKED\n" +
		"✨ Holographic Mirror: UNLOCKED\n" +
		"✨ Data Archive: UNLOCKED\n\n" +
		"*All bedroom features are now fully operational*"
	)

	# Play unlock sound effect
	_play_sfx("res://audio/sfx/unlock_all.wav")

	# Visual effect - flash all unlocked items
	_play_master_unlock_effect()


func _play_master_unlock_effect() -> void:
	## Play a visual effect on all unlocked bedroom items
	var items_to_flash = [console_visual, closet_visual, mirror_visual, bookshelf_visual, photo_album_visual]

	for item in items_to_flash:
		if item and item.visible:
			# Create a flash effect
			var original_modulate = item.modulate
			var tween = create_tween()
			if tween:
				tween.tween_property(item, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.2)
				tween.tween_property(item, "modulate", original_modulate, 0.3)


func _apply_bedroom_item_visibility() -> void:
	## Show bedroom items - visible but dimmed when locked, full brightness when unlocked
	## Items remain interactable to show unlock requirements

	# Closet - always visible, dimmed if locked
	if closet_visual:
		closet_visual.visible = true
		if closet_unlocked:
			closet_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
			_remove_lock_icon("closet")
		else:
			closet_visual.modulate = Color(0.5, 0.5, 0.6, 0.7)  # Dimmed, slightly blue
			_create_lock_icon("closet", Vector2(500, -150))
		if "Closet" not in object_positions:
			object_positions["Closet"] = Vector2(580, -100)

	# Mirror - always visible, dimmed if locked
	if mirror_visual:
		mirror_visual.visible = true
		if mirror_unlocked:
			mirror_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
			_remove_lock_icon("mirror")
		else:
			mirror_visual.modulate = Color(0.5, 0.5, 0.6, 0.7)
			_create_lock_icon("mirror", Vector2(550, 50))
		if "Mirror" not in object_positions:
			object_positions["Mirror"] = Vector2(580, 100)

	# Bookshelf (Data Archive) - always visible, dimmed if locked
	if bookshelf_visual:
		bookshelf_visual.visible = true
		if bookshelf_unlocked:
			bookshelf_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
			_remove_lock_icon("bookshelf")
		else:
			bookshelf_visual.modulate = Color(0.5, 0.5, 0.6, 0.7)
			_create_lock_icon("bookshelf", Vector2(130, -380))
		if "Bookshelf" not in object_positions:
			object_positions["Bookshelf"] = Vector2(130, -380)

	# Photo Album - create visual if doesn't exist, manage lock state
	if not photo_album_visual:
		_create_photo_album_visual()
	if photo_album_visual:
		photo_album_visual.visible = true
		if photo_album_unlocked:
			photo_album_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
			_remove_lock_icon("photo_album")
		else:
			photo_album_visual.modulate = Color(0.5, 0.5, 0.6, 0.7)
			_create_lock_icon("photo_album", Vector2(300, 150))

	# Console visibility (in case master key was used)
	if console_visual and console_placed:
		console_visual.visible = true
		if "Console" not in object_positions:
			object_positions["Console"] = Vector2(0, 0)
		if headset_glow:
			headset_glow.visible = true


func _create_lock_icon(item_id: String, position: Vector2) -> void:
	## Create a floating lock icon above a locked bedroom item
	var existing_icon: Node2D = null
	match item_id:
		"closet": existing_icon = closet_lock_icon
		"mirror": existing_icon = mirror_lock_icon
		"bookshelf": existing_icon = bookshelf_lock_icon
		"photo_album": existing_icon = photo_album_lock_icon

	if existing_icon:
		return  # Already exists

	var lock_icon = Node2D.new()
	lock_icon.name = "LockIcon_" + item_id
	lock_icon.position = position + Vector2(0, -60)  # Float above item
	lock_icon.z_index = 10

	# Lock body (rounded rectangle)
	var lock_body = Polygon2D.new()
	lock_body.name = "LockBody"
	lock_body.polygon = PackedVector2Array([
		Vector2(-12, -5), Vector2(12, -5), Vector2(12, 15), Vector2(-12, 15)
	])
	lock_body.color = Color(0.8, 0.2, 0.2, 0.9)
	lock_icon.add_child(lock_body)

	# Lock shackle (arch)
	var shackle = Polygon2D.new()
	shackle.name = "Shackle"
	var shackle_points = PackedVector2Array()
	# Outer arch
	for i in range(11):
		var angle = PI + (i / 10.0) * PI
		shackle_points.append(Vector2(cos(angle) * 10, sin(angle) * 12 - 8))
	# Inner arch (reverse)
	for i in range(10, -1, -1):
		var angle = PI + (i / 10.0) * PI
		shackle_points.append(Vector2(cos(angle) * 6, sin(angle) * 8 - 8))
	shackle.polygon = shackle_points
	shackle.color = Color(0.6, 0.15, 0.15, 0.9)
	lock_icon.add_child(shackle)

	# Keyhole
	var keyhole = Polygon2D.new()
	keyhole.name = "Keyhole"
	var keyhole_points = PackedVector2Array()
	for i in range(8):
		var angle = (i / 8.0) * TAU
		keyhole_points.append(Vector2(cos(angle) * 3, sin(angle) * 3 + 2))
	keyhole.polygon = keyhole_points
	keyhole.color = Color(0.2, 0.1, 0.1, 0.9)
	lock_icon.add_child(keyhole)

	# Keyhole slot
	var slot = Polygon2D.new()
	slot.polygon = PackedVector2Array([
		Vector2(-1.5, 3), Vector2(1.5, 3), Vector2(1.5, 10), Vector2(-1.5, 10)
	])
	slot.color = Color(0.2, 0.1, 0.1, 0.9)
	lock_icon.add_child(slot)

	# Glow effect behind lock
	var glow = Polygon2D.new()
	glow.name = "LockGlow"
	var glow_points = PackedVector2Array()
	for i in range(16):
		var angle = (i / 16.0) * TAU
		glow_points.append(Vector2(cos(angle) * 22, sin(angle) * 22))
	glow.polygon = glow_points
	glow.color = Color(1.0, 0.3, 0.3, 0.15)
	glow.z_index = -1
	lock_icon.add_child(glow)

	isometric_base.add_child(lock_icon)

	# Store reference
	match item_id:
		"closet": closet_lock_icon = lock_icon
		"mirror": mirror_lock_icon = lock_icon
		"bookshelf": bookshelf_lock_icon = lock_icon
		"photo_album": photo_album_lock_icon = lock_icon


func _remove_lock_icon(item_id: String) -> void:
	## Remove a lock icon when item is unlocked
	var icon: Node2D = null
	match item_id:
		"closet":
			icon = closet_lock_icon
			closet_lock_icon = null
		"mirror":
			icon = mirror_lock_icon
			mirror_lock_icon = null
		"bookshelf":
			icon = bookshelf_lock_icon
			bookshelf_lock_icon = null
		"photo_album":
			icon = photo_album_lock_icon
			photo_album_lock_icon = null

	if icon:
		icon.queue_free()


func _animate_lock_icons(delta: float) -> void:
	## Animate lock icons with gentle pulsing and floating motion
	var lock_icons = [closet_lock_icon, mirror_lock_icon, bookshelf_lock_icon, photo_album_lock_icon]

	for icon in lock_icons:
		if not icon:
			continue

		# Gentle floating motion
		var base_y_offset = -60.0
		var float_offset = sin(animation_time * 1.5) * 4.0
		icon.position.y = icon.position.y  # Keep x, just animate glow

		# Pulse the lock body color
		var lock_body = icon.get_node_or_null("LockBody")
		if lock_body:
			var pulse = (sin(animation_time * 2.0) + 1.0) / 2.0
			lock_body.color = Color(0.7 + pulse * 0.2, 0.15 + pulse * 0.1, 0.15, 0.85 + pulse * 0.1)

		# Pulse the glow
		var glow = icon.get_node_or_null("LockGlow")
		if glow:
			var glow_pulse = (sin(animation_time * 2.5) + 1.0) / 2.0
			glow.color.a = 0.1 + glow_pulse * 0.15
			# Scale glow slightly
			glow.scale = Vector2(1.0 + glow_pulse * 0.1, 1.0 + glow_pulse * 0.1)


var placement_indicator: Node2D = null

func _setup_placement_spot_indicator() -> void:
	# Create a visual indicator showing where to place the console
	if placement_indicator:
		return  # Already exists

	placement_indicator = Node2D.new()
	placement_indicator.name = "PlacementIndicator"
	placement_indicator.position = Vector2(0, 0)

	# Glowing pedestal base
	var base_glow = Polygon2D.new()
	base_glow.color = Color(0.2, 0.5, 0.4, 0.3)
	base_glow.polygon = PackedVector2Array([
		Vector2(-50, 20), Vector2(50, 20), Vector2(60, 50), Vector2(-60, 50)
	])
	placement_indicator.add_child(base_glow)

	# Pulsing outline
	var outline = Polygon2D.new()
	outline.name = "Outline"
	outline.color = Color(0.3, 0.8, 0.5, 0.5)
	outline.polygon = PackedVector2Array([
		Vector2(-45, 25), Vector2(45, 25), Vector2(55, 45), Vector2(-55, 45)
	])
	placement_indicator.add_child(outline)

	# "Place here" label
	var label = Label.new()
	label.text = "Place Console"
	label.position = Vector2(-45, 55)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5, 0.8))
	placement_indicator.add_child(label)

	isometric_base.add_child(placement_indicator)

	# Animate the indicator
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(outline, "modulate:a", 0.3, 1.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(outline, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN_OUT)


func _place_console_from_inventory() -> void:
	# Check if player has console in inventory
	if not GameManager.has_item("mindscape_console"):
		_show_dialogue("Empty Pedestal", "This pedestal is designed for the Mindscape Console.\n\n*You don't have the console yet*\n\nSearch the ship to find Great-Elder Zyx's console.")
		return

	# Show placement dialogue then place
	_show_dialogue("Placing Console...", "This console was used by your great-elder Zyx to connect with humans on Earth.\n\nNow it's your turn to carry on the family tradition.\n\n*The console hums eagerly in your hands*")

	# Wait for dialogue to close with timeout, then place
	if not is_inside_tree():
		return

	var wait_time := 0.0
	const MAX_WAIT := 30.0  # 30 second max wait

	await get_tree().create_timer(0.1).timeout
	while in_dialogue and is_inside_tree() and wait_time < MAX_WAIT:
		await get_tree().create_timer(0.1).timeout
		wait_time += 0.1

	if not is_inside_tree():
		return

	# Force close dialogue if timed out
	if in_dialogue:
		_close_dialogue()

	_place_console()


func _place_console() -> void:
	# Safety check
	if not is_inside_tree():
		push_warning("[Bedroom] Cannot place console - not in tree")
		return

	print("[Bedroom] Placing console...")

	# Mark console as placed
	GameManager.player_data["console_placed_in_bedroom"] = true
	GameManager.player_data.erase("needs_console_placement")
	GameManager.remove_item("mindscape_console")
	console_placed = true

	# Initialize starter habits now that console is placed
	HabitManager.initialize_starter_habits()

	# Remove placement indicator
	if placement_indicator and is_instance_valid(placement_indicator):
		placement_indicator.queue_free()
		placement_indicator = null

	# Remove placement spot from interactions, add console
	object_positions.erase("ConsolePlacementSpot")
	object_positions["Console"] = Vector2(0, 0)  # Match console visual position in tscn

	# Show console visual
	if console_visual and is_instance_valid(console_visual):
		console_visual.visible = true
	if headset_glow and is_instance_valid(headset_glow):
		headset_glow.visible = true

	# Setup console hologram effects (with safety check inside)
	_setup_console_hologram()

	# Play placement sound
	_play_sfx("res://audio/sfx/console_place.wav")

	# Save game
	SaveManager.save_game()

	print("[Bedroom] Console placed successfully")

	# DEBUG: Start frame counting
	debug_console_just_placed = true
	debug_frame_counter = 0

	# Show confirmation dialogue after a short delay (use call_deferred to avoid blocking)
	call_deferred("_show_console_placed_dialogue")


func _show_console_placed_dialogue() -> void:
	# Use a timer that doesn't block
	print("[Bedroom] === BUILD 0323-B === _show_console_placed_dialogue entered")
	if not is_inside_tree():
		print("[Bedroom] Cannot show console dialogue - not in tree")
		return

	print("[Bedroom] Scheduling console activation dialogue...")
	print("[Bedroom] DEBUG: About to create timer...")
	var timer = get_tree().create_timer(0.5)
	print("[Bedroom] DEBUG: Timer created, connecting signal...")
	timer.timeout.connect(_on_console_dialogue_timer)
	print("[Bedroom] DEBUG: Signal connected, returning from _show_console_placed_dialogue")


func _on_console_dialogue_timer() -> void:
	print("[Bedroom] DEBUG: Timer callback entered!")
	print("[Bedroom] Console dialogue timer fired")
	if not is_inside_tree():
		print("[Bedroom] Cannot show dialogue - scene exited")
		return

	# Safety check - make sure dialogue panel exists
	if not dialogue_panel or not is_instance_valid(dialogue_panel):
		print("[Bedroom] ERROR: dialogue_panel is invalid!")
		in_dialogue = false  # Ensure we don't freeze
		return

	print("[Bedroom] Showing console activation dialogue...")
	_show_dialogue("Console Activated!", "The Mindscape Console is now set up!\n\n*Ancient Goactorian symbols flicker to life on the holographic display*\n\nApproach the console and put on the neural headset to connect with your human companion.", "res://audio/voice/bedroom/console_placed.ogg")
	print("[Bedroom] Dialogue shown, in_dialogue = ", in_dialogue)


func _animate_room(delta: float) -> void:
	animation_time += delta
	star_twinkle_time += delta

	# Animate space view if visible
	if space_view_panel and space_view_panel.visible:
		_update_space_view(delta)

	# Animate fern detail view if visible
	if fern_detail_panel and fern_detail_panel.visible:
		_update_fern_detail(delta)

	# Animate bookshelf detail view if visible
	if bookshelf_detail_panel and bookshelf_detail_panel.visible:
		_update_bookshelf_detail(delta)

	# Animate photo album view if visible
	if photo_album_panel and photo_album_panel.visible:
		_update_photo_album(delta)

	# Animate headset glow
	if headset_glow:
		var pulse = (sin(animation_time * 2.5) + 1.0) / 2.0
		headset_glow.modulate.a = 0.3 + pulse * 0.5

	# Animate stars twinkling
	if window_stars:
		for star in window_stars.get_children():
			var twinkle = (sin(star_twinkle_time * 3.0 + star.position.x * 0.1) + 1.0) / 2.0
			star.modulate.a = 0.4 + twinkle * 0.6

	# Animate console hologram
	_animate_console_hologram(delta)

	# Animate ambient particles
	_animate_ambient_particles(delta)

	# Animate floor lighting
	_animate_floor_lighting(delta)

	# Animate fern
	_animate_fern(delta)

	# Animate sleep pod display
	_animate_sleep_pod(delta)

	# Animate personal items
	_animate_personal_items(delta)

	# Animate proximity glows
	_animate_proximity_glows(delta)

	# Animate lock icons
	_animate_lock_icons(delta)

	# Animate discovery shimmers
	_animate_discovery_shimmers(delta)


func _setup_star_animation() -> void:
	# Stars are set up in the scene file
	pass


# =============================================================================
# WAKE-UP SEQUENCE (for Continue Journey)
# =============================================================================

var wakeup_overlay: ColorRect = null
var wakeup_text: Label = null

func _start_wakeup_sequence() -> void:
	is_waking_up = true
	wakeup_phase = 1
	wakeup_timer = 0.0

	# Hide all interactive labels and UI during wake-up transition
	_set_interactive_labels_visible(false)
	control_hints.visible = false

	# Position player in bed (lying down)
	var bed_pos = object_positions.get("Bed", Vector2(-220, 200))
	player.position = bed_pos + Vector2(0, -20)
	player.modulate.a = 1.0

	# Create fade-in overlay (black screen) - ensure it's on top
	wakeup_overlay = ColorRect.new()
	wakeup_overlay.name = "WakeupOverlay"
	wakeup_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	wakeup_overlay.color = Color(0, 0, 0, 1)
	wakeup_overlay.z_index = 100  # Ensure overlay is above everything
	add_child(wakeup_overlay)
	move_child(wakeup_overlay, -1)  # Move to end (render last/on top)

	# Create wake-up text (above overlay)
	wakeup_text = Label.new()
	wakeup_text.name = "WakeupText"
	wakeup_text.text = "..."
	wakeup_text.add_theme_font_size_override("font_size", 24)
	wakeup_text.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0))
	wakeup_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wakeup_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wakeup_text.set_anchors_preset(Control.PRESET_CENTER)
	wakeup_text.offset_left = -200
	wakeup_text.offset_right = 200
	wakeup_text.offset_top = -50
	wakeup_text.offset_bottom = 50
	wakeup_text.z_index = 101  # Above overlay
	add_child(wakeup_text)

	_update_camera()


func _process_wakeup(delta: float) -> void:
	wakeup_timer += delta

	match wakeup_phase:
		1:  # Black screen with text fading in
			if wakeup_timer < 1.0:
				# Fade in text
				if wakeup_text:
					var alpha = wakeup_timer / 1.0
					wakeup_text.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, alpha))
			elif wakeup_timer < 2.5:
				# Show "Another day..." text
				if wakeup_text and wakeup_text.text == "...":
					wakeup_text.text = "Another day aboard the Stellar Wanderer..."
					# Play wakeup voiceover
					var audio = get_node_or_null("/root/AudioManager")
					if audio and audio.has_method("play_voice_from_path"):
						audio.play_voice_from_path("res://audio/voice/bedroom/wakeup_another_day.ogg")
			elif wakeup_timer < 4.0:
				# Fade out text, start fading in scene
				var t = (wakeup_timer - 2.5) / 1.5
				if wakeup_text:
					wakeup_text.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 1.0 - t))
				if wakeup_overlay:
					wakeup_overlay.color.a = 1.0 - t * 0.7
			else:
				# Move to next phase
				wakeup_phase = 2
				wakeup_timer = 0.0
				if wakeup_text:
					wakeup_text.queue_free()
					wakeup_text = null

		2:  # Player visible, camera focuses on bed area
			_update_camera()
			if wakeup_timer < 1.5:
				# Continue fading out overlay
				if wakeup_overlay:
					wakeup_overlay.color.a = 0.3 - (wakeup_timer / 1.5) * 0.3
			else:
				# Clean up and finish
				wakeup_phase = 3
				wakeup_timer = 0.0
				if wakeup_overlay:
					wakeup_overlay.queue_free()
					wakeup_overlay = null

		3:  # Brief pause, then allow movement
			if wakeup_timer > 0.5:
				_finish_wakeup()


func _finish_wakeup() -> void:
	is_waking_up = false
	wakeup_phase = 0
	control_hints.visible = true

	# Show all interactive labels again
	_set_interactive_labels_visible(true)

	# Clean up any remaining UI
	if wakeup_overlay:
		wakeup_overlay.queue_free()
		wakeup_overlay = null
	if wakeup_text:
		wakeup_text.queue_free()
		wakeup_text = null

	print("[Bedroom] Wake-up sequence complete")


## Hide/show all interactive object labels (used during wake-up transition)
func _set_interactive_labels_visible(show: bool) -> void:
	if not isometric_base:
		return

	# List of label node paths within IsometricBase
	var label_paths = [
		"Console/ConsoleLabel",
		"Bed/BedLabel",
		"Window/WindowLabel",
		"Bookshelf/ShelfLabel",
		"Plant/PlantLabel",
		"Door/DoorLabel",
		"Closet/Label",
		"Mirror/Label"
	]

	for path in label_paths:
		var label = isometric_base.get_node_or_null(path)
		if label:
			label.visible = show


# =============================================================================
# IMMERSIVE SPACE VIEW - Bedroom Window
# =============================================================================

var space_view_panel: Control = null
var space_view_time: float = 0.0
var space_stars: Array = []
var galaxy_node: Node2D = null
var moon_node: Node2D = null
var asteroid_field: Array = []

func _show_space_view() -> void:
	if space_view_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false
	space_view_time = 0.0

	# Hide the room while viewing space
	if isometric_base:
		isometric_base.visible = false

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
	bg.color = Color(0.01, 0.015, 0.04)
	space_view_panel.add_child(bg)

	# Stars container
	var stars_container = Node2D.new()
	stars_container.name = "Stars"
	space_view_panel.add_child(stars_container)
	_create_bedroom_stars(stars_container)

	# Distant spiral galaxy
	_create_galaxy()

	# Alien moon
	_create_alien_moon()

	# Asteroid field
	_create_asteroid_field()

	# Window frame
	_create_bedroom_window_frame()

	# Poetic text
	var info_label = Label.new()
	info_label.text = "47 years remain... The stars hold infinite possibility."
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9, 0.85))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	info_label.offset_top = -80
	info_label.offset_bottom = -50
	space_view_panel.add_child(info_label)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Step Away"
	close_btn.custom_minimum_size = Vector2(150, 50)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	close_btn.offset_top = -50
	close_btn.offset_left = -75
	close_btn.offset_right = 75
	close_btn.offset_bottom = 0
	close_btn.pressed.connect(_close_space_view)
	space_view_panel.add_child(close_btn)

	# Play voiceover
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_voice_from_path"):
		audio.play_voice_from_path("res://audio/voice/bedroom/space_view.ogg")

	# Fade in
	space_view_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(space_view_panel, "modulate:a", 1.0, 0.5)


func _create_bedroom_stars(container: Node2D) -> void:
	var viewport_size = get_viewport_rect().size
	space_stars.clear()

	for i in range(200):
		var star = Polygon2D.new()
		var size = randf_range(0.8, 2.8)

		star.polygon = PackedVector2Array([
			Vector2(0, -size), Vector2(size * 0.5, 0),
			Vector2(0, size), Vector2(-size * 0.5, 0)
		])

		# Color variety
		var color_rand = randf()
		if color_rand < 0.65:
			star.color = Color(1, 1, 1, randf_range(0.25, 0.95))
		elif color_rand < 0.8:
			star.color = Color(0.85, 0.9, 1.0, randf_range(0.3, 0.85))
		elif color_rand < 0.92:
			star.color = Color(1.0, 0.92, 0.8, randf_range(0.3, 0.8))
		else:
			star.color = Color(1.0, 0.7, 0.7, randf_range(0.4, 0.7))  # Red giants

		star.position = Vector2(
			randf_range(0, viewport_size.x),
			randf_range(0, viewport_size.y)
		)

		container.add_child(star)
		space_stars.append({
			"node": star,
			"twinkle_speed": randf_range(1.2, 4.5),
			"twinkle_offset": randf() * TAU,
			"base_alpha": star.color.a
		})


func _create_galaxy() -> void:
	var viewport_size = get_viewport_rect().size

	galaxy_node = Node2D.new()
	galaxy_node.name = "Galaxy"
	galaxy_node.position = Vector2(viewport_size.x * 0.7, viewport_size.y * 0.3)
	space_view_panel.add_child(galaxy_node)

	# Outer halo
	var halo = Polygon2D.new()
	var halo_points = PackedVector2Array()
	for i in range(24):
		var angle = (i / 24.0) * TAU
		var r = 100.0 * (0.8 + randf() * 0.4)
		halo_points.append(Vector2(cos(angle), sin(angle) * 0.4) * r)
	halo.polygon = halo_points
	halo.color = Color(0.4, 0.35, 0.6, 0.08)
	galaxy_node.add_child(halo)

	# Spiral arms (stylized)
	for arm in range(2):
		var spiral = Polygon2D.new()
		var spiral_points = PackedVector2Array()
		var arm_offset = arm * PI

		for i in range(30):
			var t = i / 30.0
			var angle = arm_offset + t * PI * 1.5
			var r = 20.0 + t * 70.0
			var width = 8.0 * (1.0 - t * 0.5)
			var pos = Vector2(cos(angle), sin(angle) * 0.4) * r
			spiral_points.append(pos + Vector2(cos(angle + PI/2), sin(angle + PI/2) * 0.4) * width)

		for i in range(29, -1, -1):
			var t = i / 30.0
			var angle = arm_offset + t * PI * 1.5
			var r = 20.0 + t * 70.0
			var width = 8.0 * (1.0 - t * 0.5)
			var pos = Vector2(cos(angle), sin(angle) * 0.4) * r
			spiral_points.append(pos - Vector2(cos(angle + PI/2), sin(angle + PI/2) * 0.4) * width)

		spiral.polygon = spiral_points
		spiral.color = Color(0.6, 0.5, 0.8, 0.15)
		galaxy_node.add_child(spiral)

	# Bright core
	var core = Polygon2D.new()
	var core_points = PackedVector2Array()
	for i in range(16):
		var angle = (i / 16.0) * TAU
		core_points.append(Vector2(cos(angle), sin(angle) * 0.4) * 25)
	core.polygon = core_points
	core.color = Color(0.9, 0.85, 1.0, 0.25)
	galaxy_node.add_child(core)

	# Inner bright spot
	var center = Polygon2D.new()
	var center_points = PackedVector2Array()
	for i in range(10):
		var angle = (i / 10.0) * TAU
		center_points.append(Vector2(cos(angle), sin(angle) * 0.4) * 8)
	center.polygon = center_points
	center.color = Color(1.0, 0.95, 1.0, 0.4)
	galaxy_node.add_child(center)


func _create_alien_moon() -> void:
	var viewport_size = get_viewport_rect().size

	moon_node = Node2D.new()
	moon_node.name = "AlienMoon"
	moon_node.position = Vector2(viewport_size.x * 0.25, viewport_size.y * 0.55)
	space_view_panel.add_child(moon_node)

	var moon_radius = 60.0

	# Moon base (dusty purple/gray)
	var moon_base = Polygon2D.new()
	var moon_points = PackedVector2Array()
	for i in range(28):
		var angle = (i / 28.0) * TAU
		moon_points.append(Vector2(cos(angle), sin(angle)) * moon_radius)
	moon_base.polygon = moon_points
	moon_base.color = Color(0.45, 0.4, 0.5)
	moon_node.add_child(moon_base)

	# Craters
	var crater_data = [
		{"pos": Vector2(-20, -15), "r": 18},
		{"pos": Vector2(25, 10), "r": 12},
		{"pos": Vector2(-5, 25), "r": 10},
		{"pos": Vector2(15, -25), "r": 8},
		{"pos": Vector2(-30, 15), "r": 14},
	]
	for crater in crater_data:
		var c = Polygon2D.new()
		var c_points = PackedVector2Array()
		for i in range(12):
			var angle = (i / 12.0) * TAU
			c_points.append(crater["pos"] + Vector2(cos(angle), sin(angle)) * crater["r"])
		c.polygon = c_points
		c.color = Color(0.35, 0.32, 0.4)
		moon_node.add_child(c)

	# Glowing surface feature (alien structure?)
	var glow_feature = Polygon2D.new()
	glow_feature.name = "SurfaceGlow"
	glow_feature.polygon = PackedVector2Array([
		Vector2(5, -5), Vector2(15, 0), Vector2(10, 10), Vector2(0, 5)
	])
	glow_feature.color = Color(0.5, 0.8, 0.7, 0.4)
	moon_node.add_child(glow_feature)


func _create_asteroid_field() -> void:
	var viewport_size = get_viewport_rect().size
	asteroid_field.clear()

	# Create 12 asteroids drifting across
	for i in range(12):
		var asteroid = Polygon2D.new()
		var size = randf_range(4, 15)

		# Irregular polygon shape
		var points = PackedVector2Array()
		var num_verts = randi_range(5, 8)
		for j in range(num_verts):
			var angle = (j / float(num_verts)) * TAU
			var r = size * randf_range(0.6, 1.0)
			points.append(Vector2(cos(angle), sin(angle)) * r)
		asteroid.polygon = points

		asteroid.color = Color(
			randf_range(0.3, 0.45),
			randf_range(0.28, 0.4),
			randf_range(0.32, 0.42)
		)

		asteroid.position = Vector2(
			randf_range(viewport_size.x * 0.4, viewport_size.x * 0.95),
			randf_range(viewport_size.y * 0.6, viewport_size.y * 0.85)
		)

		space_view_panel.add_child(asteroid)
		asteroid_field.append({
			"node": asteroid,
			"velocity": Vector2(randf_range(-8, -3), randf_range(-2, 2)),
			"rotation_speed": randf_range(-0.5, 0.5)
		})


func _create_bedroom_window_frame() -> void:
	var frame = Control.new()
	frame.name = "WindowFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	space_view_panel.add_child(frame)

	# Rounded corner vignettes
	var corners = [
		{"preset": Control.PRESET_TOP_LEFT, "pos": Vector2(0, 0)},
		{"preset": Control.PRESET_TOP_RIGHT, "pos": Vector2(-160, 0)},
		{"preset": Control.PRESET_BOTTOM_LEFT, "pos": Vector2(0, -160)},
		{"preset": Control.PRESET_BOTTOM_RIGHT, "pos": Vector2(-160, -160)}
	]

	for corner in corners:
		var vignette = ColorRect.new()
		vignette.color = Color(0.02, 0.025, 0.05, 0.92)
		vignette.set_anchors_preset(corner["preset"])
		vignette.size = Vector2(160, 160)
		vignette.position = corner["pos"]
		frame.add_child(vignette)

	# Window designation
	var designation = Label.new()
	designation.text = "— PERSONAL QUARTERS • VIEWPORT B-3 —"
	designation.add_theme_font_size_override("font_size", 14)
	designation.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55, 0.65))
	designation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	designation.set_anchors_preset(Control.PRESET_TOP_WIDE)
	designation.offset_top = 20
	frame.add_child(designation)


func _update_space_view(delta: float) -> void:
	space_view_time += delta

	# Twinkle stars
	for star_data in space_stars:
		var star = star_data["node"] as Polygon2D
		if star:
			var twinkle = sin(space_view_time * star_data["twinkle_speed"] + star_data["twinkle_offset"])
			star.color.a = star_data["base_alpha"] * (0.5 + twinkle * 0.5)

	# Rotate galaxy slowly
	if galaxy_node:
		galaxy_node.rotation = space_view_time * 0.02

	# Moon surface glow pulse
	if moon_node:
		var glow = moon_node.get_node_or_null("SurfaceGlow")
		if glow:
			glow.color.a = 0.3 + sin(space_view_time * 1.5) * 0.2

	# Drift asteroids
	var viewport_size = get_viewport_rect().size
	for ast_data in asteroid_field:
		var ast = ast_data["node"] as Polygon2D
		if ast:
			ast.position += ast_data["velocity"] * delta * 10
			ast.rotation += ast_data["rotation_speed"] * delta
			# Wrap around
			if ast.position.x < -20:
				ast.position.x = viewport_size.x + 20
				ast.position.y = randf_range(viewport_size.y * 0.5, viewport_size.y * 0.9)


func _close_space_view() -> void:
	if not space_view_panel:
		return

	var tween = create_tween()
	tween.tween_property(space_view_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_cleanup_space_view)


func _cleanup_space_view() -> void:
	# Stop any playing voice audio
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()

	if space_view_panel:
		space_view_panel.queue_free()
		space_view_panel = null

	# Show the room again
	if isometric_base:
		isometric_base.visible = true

	space_stars.clear()
	asteroid_field.clear()
	galaxy_node = null
	moon_node = null
	in_dialogue = false


# =============================================================================
# CONSOLE HOLOGRAPHIC EFFECTS
# =============================================================================

var console_hologram: Node2D = null
var hologram_data_lines: Array = []
var hologram_time: float = 0.0

func _setup_console_hologram() -> void:
	if console_hologram:
		return

	# Safety check - isometric_base must exist
	if not isometric_base:
		push_warning("[Bedroom] Cannot setup console hologram - isometric_base is null")
		return

	# Find console position in isometric base
	var console_pos = object_positions.get("Console", Vector2(0, 0))

	console_hologram = Node2D.new()
	console_hologram.name = "ConsoleHologram"
	console_hologram.position = console_pos + Vector2(0, -80)  # Above console
	isometric_base.add_child(console_hologram)

	# Hologram base ring
	var base_ring = Polygon2D.new()
	base_ring.name = "BaseRing"
	var ring_points = PackedVector2Array()
	for i in range(20):
		var angle = (i / 20.0) * TAU
		ring_points.append(Vector2(cos(angle) * 40, sin(angle) * 15))
	base_ring.polygon = ring_points
	base_ring.color = Color(0.2, 0.8, 0.7, 0.3)
	console_hologram.add_child(base_ring)

	# Floating data streams (vertical lines with data)
	for i in range(5):
		var stream = Node2D.new()
		stream.name = "DataStream" + str(i)
		stream.position = Vector2(-30 + i * 15, 0)
		console_hologram.add_child(stream)

		# Create data blocks in stream
		for j in range(6):
			var block = Polygon2D.new()
			var block_width = randf_range(6, 14)
			var block_height = randf_range(3, 6)
			block.polygon = PackedVector2Array([
				Vector2(-block_width/2, -block_height/2),
				Vector2(block_width/2, -block_height/2),
				Vector2(block_width/2, block_height/2),
				Vector2(-block_width/2, block_height/2)
			])
			block.position.y = -10 - j * 12
			block.color = Color(0.3, 0.9, 0.8, randf_range(0.2, 0.5))
			stream.add_child(block)

		hologram_data_lines.append({
			"node": stream,
			"speed": randf_range(15, 30),
			"offset": randf() * 100
		})

	# Central holographic orb
	var orb = Polygon2D.new()
	orb.name = "HoloOrb"
	var orb_points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		orb_points.append(Vector2(cos(angle), sin(angle)) * 12)
	orb.polygon = orb_points
	orb.position.y = -45
	orb.color = Color(0.4, 1.0, 0.9, 0.35)
	console_hologram.add_child(orb)

	# Orb inner glow
	var orb_inner = Polygon2D.new()
	orb_inner.name = "OrbInner"
	var inner_points = PackedVector2Array()
	for i in range(8):
		var angle = (i / 8.0) * TAU
		inner_points.append(Vector2(cos(angle), sin(angle)) * 6)
	orb_inner.polygon = inner_points
	orb_inner.position.y = -45
	orb_inner.color = Color(0.6, 1.0, 0.95, 0.5)
	console_hologram.add_child(orb_inner)

	# "MINDSCAPE" text indicator
	var text_label = Label.new()
	text_label.name = "HoloText"
	text_label.text = "MINDSCAPE"
	text_label.add_theme_font_size_override("font_size", 10)
	text_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.8, 0.7))
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.position = Vector2(-30, -70)
	console_hologram.add_child(text_label)


func _animate_console_hologram(delta: float) -> void:
	if not console_hologram:
		return

	hologram_time += delta

	# Animate base ring pulse
	var base_ring = console_hologram.get_node_or_null("BaseRing")
	if base_ring:
		base_ring.color.a = 0.2 + sin(hologram_time * 2.5) * 0.15

	# Animate data streams flowing upward
	for line_data in hologram_data_lines:
		var stream = line_data["node"] as Node2D
		if stream:
			for block in stream.get_children():
				var new_y = block.position.y - line_data["speed"] * delta
				if new_y < -80:
					new_y = 5
					block.color.a = randf_range(0.2, 0.5)
				block.position.y = new_y

	# Animate orb pulse
	var orb = console_hologram.get_node_or_null("HoloOrb")
	if orb:
		var pulse = 0.25 + sin(hologram_time * 3) * 0.15
		orb.color.a = pulse
		orb.scale = Vector2(1.0 + sin(hologram_time * 2) * 0.1, 1.0 + sin(hologram_time * 2) * 0.1)

	var orb_inner = console_hologram.get_node_or_null("OrbInner")
	if orb_inner:
		orb_inner.color.a = 0.4 + sin(hologram_time * 4) * 0.2
		orb_inner.rotation = hologram_time * 0.5

	# Text flicker
	var text = console_hologram.get_node_or_null("HoloText")
	if text:
		text.modulate.a = 0.6 + sin(hologram_time * 5) * 0.2
		if fmod(hologram_time, 3.0) < 0.05:
			text.modulate.a = 0.3  # Occasional flicker


# =============================================================================
# AMBIENT FLOATING PARTICLES
# =============================================================================

var ambient_particles: Array = []
var particles_container: Node2D = null

func _setup_ambient_particles() -> void:
	if particles_container:
		return

	particles_container = Node2D.new()
	particles_container.name = "AmbientParticles"
	isometric_base.add_child(particles_container)

	# Create 30 floating dust/light particles
	for i in range(30):
		var particle = Polygon2D.new()
		var size = randf_range(1.5, 4.0)

		# Soft circular particle
		var p_points = PackedVector2Array()
		for j in range(6):
			var angle = (j / 6.0) * TAU
			p_points.append(Vector2(cos(angle), sin(angle)) * size)
		particle.polygon = p_points

		# Varied colors - mostly soft whites/blues with occasional warm
		var color_type = randf()
		if color_type < 0.5:
			particle.color = Color(0.8, 0.85, 1.0, randf_range(0.08, 0.2))  # Cool white
		elif color_type < 0.75:
			particle.color = Color(0.5, 0.8, 0.9, randf_range(0.1, 0.25))  # Teal (from console)
		elif color_type < 0.9:
			particle.color = Color(0.9, 0.85, 0.7, randf_range(0.08, 0.18))  # Warm (from window light)
		else:
			particle.color = Color(0.7, 0.6, 0.9, randf_range(0.1, 0.2))  # Purple accent

		# Random starting position within room bounds
		particle.position = Vector2(
			randf_range(player_bounds.position.x, player_bounds.position.x + player_bounds.size.x),
			randf_range(player_bounds.position.y, player_bounds.position.y + player_bounds.size.y)
		)

		particles_container.add_child(particle)
		ambient_particles.append({
			"node": particle,
			"velocity": Vector2(randf_range(-3, 3), randf_range(-5, -1)),  # Gentle upward drift
			"wobble_speed": randf_range(1.0, 3.0),
			"wobble_amount": randf_range(0.5, 2.0),
			"base_alpha": particle.color.a,
			"phase": randf() * TAU
		})


func _animate_ambient_particles(delta: float) -> void:
	if not particles_container:
		return

	for p_data in ambient_particles:
		var particle = p_data["node"] as Polygon2D
		if not particle:
			continue

		# Move with wobble
		var wobble = sin(animation_time * p_data["wobble_speed"] + p_data["phase"]) * p_data["wobble_amount"]
		particle.position += p_data["velocity"] * delta
		particle.position.x += wobble * delta * 10

		# Fade based on height (brighter near light sources)
		var height_factor = 1.0 - (particle.position.y - player_bounds.position.y) / player_bounds.size.y
		var alpha_pulse = sin(animation_time * 2 + p_data["phase"]) * 0.3 + 0.7
		particle.color.a = p_data["base_alpha"] * height_factor * alpha_pulse

		# Wrap around when leaving bounds
		if particle.position.y < player_bounds.position.y - 20:
			particle.position.y = player_bounds.position.y + player_bounds.size.y + 10
			particle.position.x = randf_range(player_bounds.position.x, player_bounds.position.x + player_bounds.size.x)
		if particle.position.x < player_bounds.position.x - 30:
			particle.position.x = player_bounds.position.x + player_bounds.size.x + 20
		elif particle.position.x > player_bounds.position.x + player_bounds.size.x + 30:
			particle.position.x = player_bounds.position.x - 20


# =============================================================================
# AMBIENT FLOOR LIGHTING
# =============================================================================

var floor_lights: Array = []
var floor_lights_container: Node2D = null

func _setup_floor_lighting() -> void:
	if floor_lights_container:
		return

	floor_lights_container = Node2D.new()
	floor_lights_container.name = "FloorLighting"
	floor_lights_container.z_index = -5  # Behind everything
	isometric_base.add_child(floor_lights_container)

	# Window light pool (cool blue/white from starlight)
	var window_pos = object_positions.get("Window", Vector2(-350, -150))
	var window_light = Polygon2D.new()
	window_light.name = "WindowLight"
	var wl_points = PackedVector2Array()
	# Elongated ellipse spreading from window
	for i in range(20):
		var angle = (i / 20.0) * TAU
		var rx = 180.0
		var ry = 100.0
		wl_points.append(window_pos + Vector2(50, 80) + Vector2(cos(angle) * rx, sin(angle) * ry))
	window_light.polygon = wl_points
	window_light.color = Color(0.6, 0.7, 0.9, 0.06)
	floor_lights_container.add_child(window_light)
	floor_lights.append({"node": window_light, "type": "window", "base_alpha": 0.06})

	# Console light pool (teal glow)
	var console_pos = object_positions.get("Console", Vector2(280, -80))
	var console_light = Polygon2D.new()
	console_light.name = "ConsoleLight"
	var cl_points = PackedVector2Array()
	for i in range(16):
		var angle = (i / 16.0) * TAU
		cl_points.append(console_pos + Vector2(0, 50) + Vector2(cos(angle) * 120, sin(angle) * 70))
	console_light.polygon = cl_points
	console_light.color = Color(0.3, 0.8, 0.75, 0.08)
	floor_lights_container.add_child(console_light)
	floor_lights.append({"node": console_light, "type": "console", "base_alpha": 0.08})

	# Bed area soft glow (warm, subtle)
	var bed_pos = object_positions.get("Bed", Vector2(-220, 200))
	var bed_light = Polygon2D.new()
	bed_light.name = "BedLight"
	var bl_points = PackedVector2Array()
	for i in range(14):
		var angle = (i / 14.0) * TAU
		bl_points.append(bed_pos + Vector2(0, -20) + Vector2(cos(angle) * 100, sin(angle) * 60))
	bed_light.polygon = bl_points
	bed_light.color = Color(0.6, 0.5, 0.7, 0.04)
	floor_lights_container.add_child(bed_light)
	floor_lights.append({"node": bed_light, "type": "bed", "base_alpha": 0.04})


func _animate_floor_lighting(delta: float) -> void:
	if not floor_lights_container:
		return

	for light_data in floor_lights:
		var light = light_data["node"] as Polygon2D
		if not light:
			continue

		var base = light_data["base_alpha"]
		match light_data["type"]:
			"window":
				# Subtle starlight flicker
				light.color.a = base + sin(animation_time * 0.8) * 0.015
			"console":
				# Sync with console hologram pulse
				light.color.a = base + sin(animation_time * 2.5) * 0.03
			"bed":
				# Very gentle pulse
				light.color.a = base + sin(animation_time * 0.5) * 0.01


# =============================================================================
# ANIMATED FERN
# =============================================================================

var fern_container: Node2D = null
var fern_fronds: Array = []

func _setup_animated_fern() -> void:
	if fern_container:
		return

	var plant_pos = object_positions.get("Plant", Vector2(-80, -200))

	fern_container = Node2D.new()
	fern_container.name = "AnimatedFern"
	fern_container.position = plant_pos
	isometric_base.add_child(fern_container)

	# Pot
	var pot = Polygon2D.new()
	pot.polygon = PackedVector2Array([
		Vector2(-18, 0), Vector2(-15, 25), Vector2(15, 25), Vector2(18, 0)
	])
	pot.color = Color(0.55, 0.35, 0.25)
	fern_container.add_child(pot)

	# Pot rim
	var rim = Polygon2D.new()
	rim.polygon = PackedVector2Array([
		Vector2(-20, -2), Vector2(-18, 3), Vector2(18, 3), Vector2(20, -2)
	])
	rim.color = Color(0.6, 0.4, 0.3)
	fern_container.add_child(rim)

	# Soil
	var soil = Polygon2D.new()
	var soil_points = PackedVector2Array()
	for i in range(10):
		var angle = PI + (i / 10.0) * PI
		soil_points.append(Vector2(cos(angle) * 14, sin(angle) * 5 - 2))
	soil.polygon = soil_points
	soil.color = Color(0.25, 0.18, 0.12)
	fern_container.add_child(soil)

	# Create fern fronds (multiple leaves)
	var frond_configs = [
		{"angle": -0.4, "length": 45, "color": Color(0.2, 0.55, 0.3)},
		{"angle": -0.15, "length": 55, "color": Color(0.25, 0.6, 0.35)},
		{"angle": 0.1, "length": 50, "color": Color(0.22, 0.58, 0.32)},
		{"angle": 0.35, "length": 40, "color": Color(0.2, 0.52, 0.28)},
		{"angle": -0.5, "length": 35, "color": Color(0.18, 0.5, 0.26)},
		{"angle": 0.5, "length": 38, "color": Color(0.23, 0.55, 0.3)},
	]

	for i in range(frond_configs.size()):
		var config = frond_configs[i]
		var frond = Polygon2D.new()
		frond.name = "Frond" + str(i)

		# Leaf shape - curved frond
		var length = config["length"]
		frond.polygon = PackedVector2Array([
			Vector2(0, 0),
			Vector2(-4, -length * 0.3),
			Vector2(-3, -length * 0.6),
			Vector2(0, -length),
			Vector2(3, -length * 0.6),
			Vector2(4, -length * 0.3),
		])
		frond.color = config["color"]
		frond.position = Vector2(0, -5)
		frond.rotation = config["angle"]

		fern_container.add_child(frond)
		fern_fronds.append({
			"node": frond,
			"base_rotation": config["angle"],
			"sway_speed": randf_range(1.2, 2.0),
			"sway_amount": randf_range(0.03, 0.08),
			"phase": randf() * TAU
		})

	# Bioluminescent glow spots on leaves
	for i in range(4):
		var glow = Polygon2D.new()
		glow.name = "FernGlow" + str(i)
		var glow_points = PackedVector2Array()
		for j in range(6):
			var angle = (j / 6.0) * TAU
			glow_points.append(Vector2(cos(angle), sin(angle)) * 3)
		glow.polygon = glow_points
		glow.position = Vector2(randf_range(-8, 8), randf_range(-35, -15))
		glow.color = Color(0.4, 0.9, 0.6, 0.4)
		fern_container.add_child(glow)


func _animate_fern(delta: float) -> void:
	if not fern_container:
		return

	# Sway fronds
	for frond_data in fern_fronds:
		var frond = frond_data["node"] as Polygon2D
		if frond:
			var sway = sin(animation_time * frond_data["sway_speed"] + frond_data["phase"])
			frond.rotation = frond_data["base_rotation"] + sway * frond_data["sway_amount"]

	# Pulse bioluminescent spots
	for i in range(4):
		var glow = fern_container.get_node_or_null("FernGlow" + str(i))
		if glow:
			glow.color.a = 0.3 + sin(animation_time * 2 + i * 1.5) * 0.2


# =============================================================================
# ENHANCED SLEEP POD
# =============================================================================

var sleep_pod_display: Node2D = null

func _setup_sleep_pod() -> void:
	if sleep_pod_display:
		return

	var bed_pos = object_positions.get("Bed", Vector2(-220, 200))

	sleep_pod_display = Node2D.new()
	sleep_pod_display.name = "SleepPodDisplay"
	sleep_pod_display.position = bed_pos + Vector2(0, -60)
	isometric_base.add_child(sleep_pod_display)

	# Holographic status panel
	var panel_bg = Polygon2D.new()
	panel_bg.name = "PanelBG"
	panel_bg.polygon = PackedVector2Array([
		Vector2(-35, -20), Vector2(35, -20), Vector2(35, 20), Vector2(-35, 20)
	])
	panel_bg.color = Color(0.15, 0.12, 0.25, 0.5)
	sleep_pod_display.add_child(panel_bg)

	# Panel border glow
	var border = Polygon2D.new()
	border.name = "PanelBorder"
	border.polygon = PackedVector2Array([
		Vector2(-36, -21), Vector2(36, -21), Vector2(36, -19),
		Vector2(-34, -19), Vector2(-34, 19), Vector2(36, 19),
		Vector2(36, 21), Vector2(-36, 21), Vector2(-36, -21)
	])
	border.color = Color(0.5, 0.4, 0.8, 0.4)
	sleep_pod_display.add_child(border)

	# Status text
	var status_text = Label.new()
	status_text.name = "StatusText"
	status_text.text = "POD READY"
	status_text.add_theme_font_size_override("font_size", 9)
	status_text.add_theme_color_override("font_color", Color(0.6, 0.5, 0.9, 0.8))
	status_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_text.position = Vector2(-28, -18)
	sleep_pod_display.add_child(status_text)

	# Vital signs bars
	for i in range(3):
		var bar_bg = Polygon2D.new()
		bar_bg.polygon = PackedVector2Array([
			Vector2(-25, 0), Vector2(25, 0), Vector2(25, 4), Vector2(-25, 4)
		])
		bar_bg.position.y = -5 + i * 8
		bar_bg.color = Color(0.2, 0.18, 0.3, 0.6)
		sleep_pod_display.add_child(bar_bg)

		var bar_fill = Polygon2D.new()
		bar_fill.name = "VitalBar" + str(i)
		var fill_width = [45, 38, 42][i]
		bar_fill.polygon = PackedVector2Array([
			Vector2(-25, 0), Vector2(-25 + fill_width, 0),
			Vector2(-25 + fill_width, 4), Vector2(-25, 4)
		])
		bar_fill.position.y = -5 + i * 8
		bar_fill.color = [
			Color(0.4, 0.8, 0.5, 0.7),  # Green - health
			Color(0.5, 0.6, 0.9, 0.7),  # Blue - energy
			Color(0.8, 0.6, 0.4, 0.7),  # Orange - rest
		][i]
		sleep_pod_display.add_child(bar_fill)


func _animate_sleep_pod(delta: float) -> void:
	if not sleep_pod_display:
		return

	# Pulse panel border
	var border = sleep_pod_display.get_node_or_null("PanelBorder")
	if border:
		border.color.a = 0.3 + sin(animation_time * 1.5) * 0.15

	# Subtle bar animation
	for i in range(3):
		var bar = sleep_pod_display.get_node_or_null("VitalBar" + str(i))
		if bar:
			bar.color.a = 0.6 + sin(animation_time * 2 + i * 0.8) * 0.15

	# Flicker status text occasionally
	var status = sleep_pod_display.get_node_or_null("StatusText")
	if status:
		status.modulate.a = 0.7 + sin(animation_time * 3) * 0.15
		if fmod(animation_time, 5.0) < 0.1:
			status.modulate.a = 0.4


# =============================================================================
# SLEEP POD MENU & DREAM SEQUENCES
# =============================================================================

var sleep_pod_menu: PanelContainer = null
var dream_viewer: PanelContainer = null

func _open_sleep_pod_menu() -> void:
	if sleep_pod_menu:
		return

	sleep_pod_menu = PanelContainer.new()
	sleep_pod_menu.name = "SleepPodMenu"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.15, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = Color(0.5, 0.4, 0.7, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	sleep_pod_menu.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	sleep_pod_menu.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Sleep Pod"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.6, 0.5, 0.8))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Options
	var dream_btn = Button.new()
	dream_btn.text = "View Dream Memories"
	dream_btn.custom_minimum_size = Vector2(250, 50)
	dream_btn.add_theme_font_size_override("font_size", 16)
	dream_btn.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
	dream_btn.pressed.connect(_open_dream_viewer)
	vbox.add_child(dream_btn)

	# Quick Save button
	var quick_save_btn = Button.new()
	quick_save_btn.text = "Quick Save"
	quick_save_btn.custom_minimum_size = Vector2(250, 50)
	quick_save_btn.add_theme_font_size_override("font_size", 16)
	quick_save_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	quick_save_btn.pressed.connect(func():
		SaveManager.save_game()
		_play_sfx("res://audio/sfx/confirm.wav")
		_close_sleep_pod_menu()
		_show_dialogue("Progress Saved", "Your journey has been saved to the Sleep Pod's memory banks.\n\nAuto-save slot updated.")
	)
	vbox.add_child(quick_save_btn)

	# Quick Load button (load last auto-save)
	var quick_load_btn = Button.new()
	quick_load_btn.text = "Quick Load"
	quick_load_btn.custom_minimum_size = Vector2(250, 50)
	quick_load_btn.add_theme_font_size_override("font_size", 16)
	quick_load_btn.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	quick_load_btn.pressed.connect(func():
		_close_sleep_pod_menu()
		_confirm_quick_load()
	)
	vbox.add_child(quick_load_btn)

	# Manage Saves button (full save/load panel)
	var manage_btn = Button.new()
	manage_btn.text = "Manage Save Slots"
	manage_btn.custom_minimum_size = Vector2(250, 50)
	manage_btn.add_theme_font_size_override("font_size", 16)
	manage_btn.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6))
	manage_btn.pressed.connect(func():
		_close_sleep_pod_menu()
		_show_save_panel()
	)
	vbox.add_child(manage_btn)

	var rest_btn = Button.new()
	rest_btn.text = "Rest & Meditate"
	rest_btn.custom_minimum_size = Vector2(250, 50)
	rest_btn.add_theme_font_size_override("font_size", 16)
	rest_btn.pressed.connect(_start_rest_meditation)
	vbox.add_child(rest_btn)

	var close_btn = Button.new()
	close_btn.text = "Back"
	close_btn.custom_minimum_size = Vector2(250, 45)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_close_sleep_pod_menu)
	vbox.add_child(close_btn)

	sleep_pod_menu.set_anchors_preset(Control.PRESET_CENTER)
	sleep_pod_menu.position = Vector2(-175, -160)
	sleep_pod_menu.custom_minimum_size = Vector2(350, 0)

	add_child(sleep_pod_menu)


func _close_sleep_pod_menu() -> void:
	if sleep_pod_menu:
		sleep_pod_menu.queue_free()
		sleep_pod_menu = null


func _confirm_quick_load() -> void:
	# Show confirmation dialog before loading
	var confirm_panel = PanelContainer.new()
	confirm_panel.name = "QuickLoadConfirm"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.1, 0.98)
	style.border_color = Color(0.5, 0.7, 0.9, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	confirm_panel.add_theme_stylebox_override("panel", style)

	confirm_panel.set_anchors_preset(Control.PRESET_CENTER)
	confirm_panel.offset_left = -200
	confirm_panel.offset_right = 200
	confirm_panel.offset_top = -120
	confirm_panel.offset_bottom = 120

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	confirm_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Load Last Save?"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var warning = Label.new()
	warning.text = "Any unsaved progress will be lost.\nAre you sure you want to reload?"
	warning.add_theme_font_size_override("font_size", 14)
	warning.add_theme_color_override("font_color", Color(0.8, 0.7, 0.6))
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(warning)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(100, 45)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(func():
		confirm_panel.queue_free()
		in_dialogue = false
	)
	btn_row.add_child(cancel_btn)

	var load_btn = Button.new()
	load_btn.text = "Load"
	load_btn.custom_minimum_size = Vector2(100, 45)
	load_btn.add_theme_font_size_override("font_size", 16)
	load_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.9))
	load_btn.pressed.connect(func():
		confirm_panel.queue_free()
		_play_sfx("res://audio/sfx/confirm.wav")
		# Load the auto-save
		SaveManager.load_game()
		# Reload the current scene to apply loaded data
		get_tree().reload_current_scene()
	)
	btn_row.add_child(load_btn)

	in_dialogue = true
	add_child(confirm_panel)


func _open_dream_viewer() -> void:
	_close_sleep_pod_menu()

	dream_viewer = PanelContainer.new()
	dream_viewer.name = "DreamViewer"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.12, 0.98)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.border_color = Color(0.4, 0.3, 0.7, 0.4)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	dream_viewer.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	dream_viewer.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Dream Memories"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Echoes of your journey through the mindscape"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Dream content area
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 350)
	vbox.add_child(scroll)

	var dreams_vbox = VBoxContainer.new()
	dreams_vbox.add_theme_constant_override("separation", 15)
	dreams_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(dreams_vbox)

	# Generate dreams based on player progress
	var dreams = _generate_dream_memories()

	if dreams.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "No dream memories yet...\nComplete focus sessions and build habits to unlock dream sequences."
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dreams_vbox.add_child(empty_label)
	else:
		for dream in dreams:
			_add_dream_card(dreams_vbox, dream)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Wake Up"
	close_btn.custom_minimum_size = Vector2(200, 50)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_dream_viewer)
	vbox.add_child(close_btn)

	dream_viewer.set_anchors_preset(Control.PRESET_CENTER)
	dream_viewer.position = Vector2(-300, -250)
	dream_viewer.custom_minimum_size = Vector2(600, 0)

	add_child(dream_viewer)


func _generate_dream_memories() -> Array:
	## Generate dream memories based on player's progress and activities
	var dreams: Array = []

	var total_sessions = GameManager.player_data.get("total_focus_sessions", 0)
	var total_minutes = GameManager.player_data.get("total_focus_minutes", 0)
	var streak = GameManager.player_data.get("current_streak", 0)
	var evolution = GameManager.get_evolution_level() if GameManager else 1
	var habits_completed = GameManager.player_data.get("total_habits_completed", 0)

	# Dream about focus journey
	if total_sessions >= 1:
		dreams.append({
			"title": "Echoes of Concentration",
			"description": "You see yourself in a vast library of light. " + str(total_sessions) + " glowing orbs float around you - each one a moment of perfect focus.",
			"color": Color(0.5, 0.7, 0.9),
			"symbol": "orb"
		})

	# Dream about time invested
	if total_minutes >= 60:
		var hours = total_minutes / 60
		dreams.append({
			"title": "River of Hours",
			"description": "A shimmering river flows through your dream, carrying " + str(hours) + " hours of dedicated work. Each ripple reflects a task completed.",
			"color": Color(0.6, 0.8, 0.7),
			"symbol": "wave"
		})

	# Dream about habits
	if habits_completed >= 10:
		dreams.append({
			"title": "Garden of Patterns",
			"description": "In your dream, a garden blooms with " + str(habits_completed) + " crystalline flowers. Each one pulses with the rhythm of your daily rituals.",
			"color": Color(0.7, 0.5, 0.8),
			"symbol": "flower"
		})

	# Dream about streaks
	if streak >= 3:
		dreams.append({
			"title": "Chain of Stars",
			"description": "A constellation of " + str(streak) + " connected stars burns above you. Their light grows stronger with each passing day.",
			"color": Color(0.9, 0.7, 0.4),
			"symbol": "star"
		})

	# Dream about evolution
	if evolution >= 2:
		dreams.append({
			"title": "The Ascending Path",
			"description": "You climb a spiraling staircase through clouds. At evolution level " + str(evolution) + ", the view becomes ever more magnificent.",
			"color": Color(0.6, 0.5, 0.9),
			"symbol": "stairs"
		})

	# Special dream for high achievers
	if total_sessions >= 25 and streak >= 7:
		dreams.append({
			"title": "The Infinite Chamber",
			"description": "You stand in an endless crystalline chamber. Reflections of your past self and future potential dance in the facets. You have become the journey.",
			"color": Color(0.8, 0.6, 0.9),
			"symbol": "crystal"
		})

	return dreams


func _add_dream_card(container: VBoxContainer, dream: Dictionary) -> void:
	var card = PanelContainer.new()

	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(dream.color.r * 0.15, dream.color.g * 0.15, dream.color.b * 0.15, 0.6)
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_style.border_color = Color(dream.color.r, dream.color.g, dream.color.b, 0.4)
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_width_top = 1
	card_style.border_width_bottom = 1
	card.add_theme_stylebox_override("panel", card_style)

	var card_margin = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 15)
	card_margin.add_theme_constant_override("margin_right", 15)
	card_margin.add_theme_constant_override("margin_top", 12)
	card_margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(card_margin)

	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 8)
	card_margin.add_child(card_vbox)

	var dream_title = Label.new()
	dream_title.text = dream.title
	dream_title.add_theme_font_size_override("font_size", 18)
	dream_title.add_theme_color_override("font_color", dream.color)
	card_vbox.add_child(dream_title)

	var dream_desc = Label.new()
	dream_desc.text = dream.description
	dream_desc.add_theme_font_size_override("font_size", 14)
	dream_desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	dream_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_vbox.add_child(dream_desc)

	container.add_child(card)


func _close_dream_viewer() -> void:
	if dream_viewer:
		dream_viewer.queue_free()
		dream_viewer = null


func _start_rest_meditation() -> void:
	_close_sleep_pod_menu()

	# Create a simple meditation screen
	var rest_panel = PanelContainer.new()
	rest_panel.name = "RestMeditation"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.08, 0.98)
	rest_panel.add_theme_stylebox_override("panel", style)
	rest_panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	rest_panel.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	center.add_child(vbox)

	var title = Label.new()
	title.text = "Rest & Restore"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var instruction = Label.new()
	instruction.text = "Close your eyes and breathe deeply...\n\n Inhale... Hold... Exhale..."
	instruction.add_theme_font_size_override("font_size", 20)
	instruction.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instruction)

	# Breathing circle
	var breath_circle = Polygon2D.new()
	breath_circle.name = "BreathCircle"
	var circle_points = PackedVector2Array()
	for i in range(32):
		var angle = (float(i) / 32) * TAU
		circle_points.append(Vector2(cos(angle) * 60, sin(angle) * 60))
	breath_circle.polygon = circle_points
	breath_circle.color = Color(0.4, 0.5, 0.7, 0.3)

	var breath_container = Control.new()
	breath_container.custom_minimum_size = Vector2(200, 200)
	breath_container.add_child(breath_circle)
	breath_circle.position = Vector2(100, 100)
	vbox.add_child(breath_container)

	var wake_btn = Button.new()
	wake_btn.text = "Wake Up"
	wake_btn.custom_minimum_size = Vector2(200, 50)
	wake_btn.add_theme_font_size_override("font_size", 18)
	wake_btn.pressed.connect(func(): rest_panel.queue_free())
	vbox.add_child(wake_btn)

	add_child(rest_panel)

	# Animate breathing circle
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(breath_circle, "scale", Vector2(1.5, 1.5), 4.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(breath_circle, "scale", Vector2(1.0, 1.0), 4.0).set_trans(Tween.TRANS_SINE)


# =============================================================================
# PERSONAL TOUCHES (Photo Frame, Trinkets)
# =============================================================================

var personal_items: Node2D = null

func _setup_personal_items() -> void:
	if personal_items:
		return

	personal_items = Node2D.new()
	personal_items.name = "PersonalItems"
	isometric_base.add_child(personal_items)

	# Holographic photo frame near bookshelf - only if bookshelf is unlocked
	if bookshelf_unlocked and "Bookshelf" in object_positions:
		var bookshelf_pos = object_positions.get("Bookshelf", Vector2(130, -380))
		_create_photo_frame(bookshelf_pos + Vector2(-60, -30))

	# Floating trinket near bed
	var bed_pos = object_positions.get("Bed", Vector2(-220, 200))
	_create_floating_trinket(bed_pos + Vector2(60, -40))

	# Small crystal near plant
	var plant_pos = object_positions.get("Plant", Vector2(-80, -200))
	_create_memory_crystal(plant_pos + Vector2(35, 10))


func _create_photo_frame(pos: Vector2) -> void:
	var frame = Node2D.new()
	frame.name = "PhotoFrame"
	frame.position = pos
	personal_items.add_child(frame)

	# Frame border
	var border = Polygon2D.new()
	border.polygon = PackedVector2Array([
		Vector2(-22, -28), Vector2(22, -28), Vector2(22, 28), Vector2(-22, 28)
	])
	border.color = Color(0.5, 0.45, 0.35)
	frame.add_child(border)

	# Photo area (holographic family image)
	var photo = Polygon2D.new()
	photo.name = "PhotoImage"
	photo.polygon = PackedVector2Array([
		Vector2(-18, -24), Vector2(18, -24), Vector2(18, 24), Vector2(-18, 24)
	])
	photo.color = Color(0.4, 0.5, 0.6, 0.7)
	frame.add_child(photo)

	# Silhouette figures (family)
	var figures = [
		{"x": -8, "h": 18, "w": 5},   # Parent 1
		{"x": 8, "h": 16, "w": 5},    # Parent 2
		{"x": 0, "h": 10, "w": 4},    # Young Goacto
	]
	for fig in figures:
		var silhouette = Polygon2D.new()
		silhouette.polygon = PackedVector2Array([
			Vector2(fig["x"] - fig["w"]/2, 20),
			Vector2(fig["x"] - fig["w"]/2, 20 - fig["h"]),
			Vector2(fig["x"], 20 - fig["h"] - 4),  # Head
			Vector2(fig["x"] + fig["w"]/2, 20 - fig["h"]),
			Vector2(fig["x"] + fig["w"]/2, 20),
		])
		silhouette.color = Color(0.6, 0.7, 0.8, 0.5)
		frame.add_child(silhouette)

	# Holographic shimmer overlay
	var shimmer = Polygon2D.new()
	shimmer.name = "Shimmer"
	shimmer.polygon = PackedVector2Array([
		Vector2(-18, -24), Vector2(18, -24), Vector2(18, 24), Vector2(-18, 24)
	])
	shimmer.color = Color(0.7, 0.8, 1.0, 0.1)
	frame.add_child(shimmer)


func _create_floating_trinket(pos: Vector2) -> void:
	var trinket = Node2D.new()
	trinket.name = "FloatingTrinket"
	trinket.position = pos
	personal_items.add_child(trinket)

	# Anti-gravity platform
	var platform = Polygon2D.new()
	var plat_points = PackedVector2Array()
	for i in range(6):
		var angle = (i / 6.0) * TAU
		plat_points.append(Vector2(cos(angle) * 12, sin(angle) * 5))
	platform.polygon = plat_points
	platform.color = Color(0.3, 0.35, 0.4, 0.6)
	trinket.add_child(platform)

	# Floating geometric shape (represents a keepsake)
	var gem = Polygon2D.new()
	gem.name = "FloatingGem"
	gem.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(8, -10), Vector2(6, 0),
		Vector2(-6, 0), Vector2(-8, -10)
	])
	gem.color = Color(0.7, 0.5, 0.9, 0.6)
	trinket.add_child(gem)

	# Gem inner glow
	var gem_glow = Polygon2D.new()
	gem_glow.name = "GemGlow"
	gem_glow.polygon = PackedVector2Array([
		Vector2(0, -16), Vector2(4, -10), Vector2(3, -4),
		Vector2(-3, -4), Vector2(-4, -10)
	])
	gem_glow.color = Color(0.9, 0.7, 1.0, 0.4)
	trinket.add_child(gem_glow)


func _create_memory_crystal(pos: Vector2) -> void:
	var crystal = Node2D.new()
	crystal.name = "MemoryCrystal"
	crystal.position = pos
	personal_items.add_child(crystal)

	# Crystal shape
	var crystal_body = Polygon2D.new()
	crystal_body.name = "CrystalBody"
	crystal_body.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(6, -8), Vector2(5, 0),
		Vector2(0, 5), Vector2(-5, 0), Vector2(-6, -8)
	])
	crystal_body.color = Color(0.5, 0.8, 0.9, 0.5)
	crystal.add_child(crystal_body)

	# Inner light
	var inner = Polygon2D.new()
	inner.name = "CrystalInner"
	inner.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(3, -6), Vector2(2, 0),
		Vector2(-2, 0), Vector2(-3, -6)
	])
	inner.color = Color(0.7, 0.95, 1.0, 0.6)
	crystal.add_child(inner)


func _animate_personal_items(delta: float) -> void:
	if not personal_items:
		return

	# Photo frame shimmer
	var photo_frame = personal_items.get_node_or_null("PhotoFrame")
	if photo_frame:
		var shimmer = photo_frame.get_node_or_null("Shimmer")
		if shimmer:
			shimmer.color.a = 0.05 + sin(animation_time * 1.5) * 0.08

	# Floating trinket bob
	var trinket = personal_items.get_node_or_null("FloatingTrinket")
	if trinket:
		var gem = trinket.get_node_or_null("FloatingGem")
		if gem:
			gem.position.y = -10 + sin(animation_time * 1.8) * 4
			gem.rotation = sin(animation_time * 0.5) * 0.1
		var glow = trinket.get_node_or_null("GemGlow")
		if glow:
			glow.color.a = 0.3 + sin(animation_time * 2.5) * 0.2

	# Memory crystal pulse
	var crystal = personal_items.get_node_or_null("MemoryCrystal")
	if crystal:
		var inner = crystal.get_node_or_null("CrystalInner")
		if inner:
			inner.color.a = 0.4 + sin(animation_time * 2) * 0.25


# =============================================================================
# PROXIMITY HIGHLIGHT GLOW
# =============================================================================

var proximity_glows: Dictionary = {}

func _setup_proximity_glows() -> void:
	# Create glow indicators for each interactive object
	for obj_name in object_positions:
		var pos = object_positions[obj_name]
		var glow = Polygon2D.new()
		glow.name = "ProximityGlow_" + obj_name

		# Create elliptical glow shape
		var glow_points = PackedVector2Array()
		for i in range(16):
			var angle = (i / 16.0) * TAU
			glow_points.append(Vector2(cos(angle) * 50, sin(angle) * 25))
		glow.polygon = glow_points
		glow.position = pos + Vector2(0, 20)  # Slightly below object center
		glow.color = Color(0.4, 0.8, 0.7, 0.0)  # Start invisible
		glow.z_index = -3

		isometric_base.add_child(glow)
		proximity_glows[obj_name] = glow


func _animate_proximity_glows(delta: float) -> void:
	if proximity_glows.is_empty():
		return

	for obj_name in proximity_glows:
		var glow = proximity_glows[obj_name] as Polygon2D
		if not glow:
			continue

		if obj_name == nearby_object:
			# Fade in and pulse when near
			var target_alpha = 0.15 + sin(animation_time * 3) * 0.08
			glow.color.a = lerp(glow.color.a, target_alpha, delta * 5)

			# Assign color based on object type
			match obj_name:
				"Console":
					glow.color = Color(0.3, 0.9, 0.8, glow.color.a)  # Teal
				"Window":
					glow.color = Color(0.6, 0.7, 0.9, glow.color.a)  # Blue
				"Bed":
					glow.color = Color(0.6, 0.5, 0.8, glow.color.a)  # Purple
				"Bookshelf":
					glow.color = Color(0.8, 0.6, 0.4, glow.color.a)  # Warm
				"Plant":
					glow.color = Color(0.4, 0.8, 0.5, glow.color.a)  # Green
				"Door":
					glow.color = Color(0.7, 0.7, 0.7, glow.color.a)  # Gray
		else:
			# Fade out when not near
			glow.color.a = lerp(glow.color.a, 0.0, delta * 4)


# =============================================================================
# DISCOVERY SHIMMER (hints for undiscovered objects)
# =============================================================================

var discovery_shimmers: Dictionary = {}

func _setup_discovery_shimmers() -> void:
	# Create shimmer effects for undiscovered objects
	for obj_name in object_positions:
		var object_id = "bedroom_" + obj_name

		# Skip if already discovered
		if GameManager.has_discovered_object(object_id):
			continue

		# Skip door - it's not really something to "discover"
		if obj_name == "Door":
			continue

		var pos = object_positions[obj_name]
		var shimmer = Node2D.new()
		shimmer.name = "DiscoveryShimmer_" + obj_name
		shimmer.position = pos

		# Create subtle sparkle points around the object
		for i in range(4):
			var sparkle = Polygon2D.new()
			var angle = (i / 4.0) * TAU
			var dist = 35.0
			sparkle.position = Vector2(cos(angle) * dist, sin(angle) * dist * 0.5)

			# Small diamond shape
			sparkle.polygon = PackedVector2Array([
				Vector2(0, -4), Vector2(3, 0), Vector2(0, 4), Vector2(-3, 0)
			])
			sparkle.color = Color(0.9, 0.85, 0.6, 0.0)
			sparkle.name = "Sparkle" + str(i)
			shimmer.add_child(sparkle)

		isometric_base.add_child(shimmer)
		discovery_shimmers[obj_name] = shimmer


func _animate_discovery_shimmers(delta: float) -> void:
	if discovery_shimmers.is_empty():
		return

	var shimmers_to_remove = []

	for obj_name in discovery_shimmers:
		var object_id = "bedroom_" + obj_name

		# Remove shimmer if object was just discovered
		if GameManager.has_discovered_object(object_id):
			shimmers_to_remove.append(obj_name)
			continue

		var shimmer = discovery_shimmers[obj_name] as Node2D
		if not shimmer:
			continue

		# Animate sparkles in a subtle wave pattern
		var sparkle_count = shimmer.get_child_count()
		for i in range(sparkle_count):
			var sparkle = shimmer.get_child(i) as Polygon2D
			if not sparkle:
				continue

			# Staggered pulse for each sparkle
			var phase = animation_time * 2.0 + (i * TAU / sparkle_count)
			var pulse = (sin(phase) + 1.0) / 2.0

			# Fade between visible and invisible
			sparkle.color.a = pulse * 0.4

			# Subtle scale pulse
			var scale = 0.8 + pulse * 0.4
			sparkle.scale = Vector2(scale, scale)

	# Remove discovered shimmers
	for obj_name in shimmers_to_remove:
		var shimmer = discovery_shimmers[obj_name]
		if shimmer:
			shimmer.queue_free()
		discovery_shimmers.erase(obj_name)


# =============================================================================
# FERN DETAIL VIEW
# =============================================================================

var fern_detail_panel: Control = null
var fern_detail_time: float = 0.0
var detail_fern_fronds: Array = []

# Bookshelf detail view
var bookshelf_detail_panel: Control = null
var bookshelf_detail_time: float = 0.0
var selected_book_index: int = 0
var book_buttons: Array = []
const BOOKS_DATA = [
	{
		"title": "The Art of Habit Formation",
		"author": "Dr. Kira Voss",
		"color": Color(0.65, 0.2, 0.2),
		"voice_path": "res://audio/voice/bedroom/books/book_habit_formation.ogg",
		"description": "A foundational text on building lasting habits through neuroplasticity and mindful repetition.\n\n\"Habits are not formed by willpower alone, but by the gentle persistence of daily intention.\"\n\nThis book taught you that small, consistent actions compound into remarkable change."
	},
	{
		"title": "Mindscape Cultivation",
		"author": "High Sage Orin",
		"color": Color(0.2, 0.5, 0.65),
		"voice_path": "res://audio/voice/bedroom/books/book_mindscape.ogg",
		"description": "The definitive guide to developing and maintaining one's inner mindscape.\n\n\"Your mindscape reflects the garden of your consciousness. Tend it daily.\"\n\nThe techniques here form the basis of all Goactorian mental training."
	},
	{
		"title": "Understanding Human Potential",
		"author": "Ambassador Thren",
		"color": Color(0.55, 0.4, 0.2),
		"voice_path": "res://audio/voice/bedroom/books/book_human_potential.ogg",
		"description": "A Goactorian analysis of humanity's remarkable capacity for growth and adaptation.\n\n\"Humans possess an extraordinary gift - the ability to consciously reshape their own minds.\"\n\nYour mission hinges on the insights within these pages."
	},
	{
		"title": "Focus & Flow States",
		"author": "Master Zhen",
		"color": Color(0.3, 0.55, 0.35),
		"voice_path": "res://audio/voice/bedroom/books/book_focus_flow.ogg",
		"description": "Advanced techniques for achieving deep concentration and optimal performance.\n\n\"In true focus, time dissolves and purpose crystallizes.\"\n\nThe Focus Chamber was designed based on principles from this text."
	},
	{
		"title": "The Stellar Navigator's Log",
		"author": "Captain Mira",
		"color": Color(0.4, 0.3, 0.55),
		"voice_path": "res://audio/voice/bedroom/books/book_navigator.ogg",
		"description": "Personal accounts from the legendary captain who first discovered the human homeworld.\n\n\"They call Earth the pale blue dot. I call it hope.\"\n\nHer journey inspired your own mission aboard the Stellar Wanderer."
	},
	{
		"title": "Discipline of the Ancients",
		"author": "Unknown",
		"color": Color(0.5, 0.45, 0.35),
		"voice_path": "res://audio/voice/bedroom/books/book_discipline.ogg",
		"description": "An ancient Goactorian manuscript on the virtue of discipline and self-mastery.\n\n\"Discipline is not restriction - it is freedom from the tyranny of impulse.\"\n\nThe first Aspect you will awaken draws from these teachings."
	},
	{
		"title": "The Stellar Wanderer's Log",
		"author": "Ship AI 'Lumina'",
		"color": Color(0.25, 0.35, 0.55),
		"voice_path": "res://audio/voice/bedroom/books/book_ship_log.ogg",
		"description": "Mission Log - Sol Calendar Year 2847:\n\nThe Stellar Wanderer continues its 47-year journey to the Cygnus Arm. Current assignment: Agent Goacto, tasked with guiding a human consciousness toward full potential.\n\nShip systems nominal. Mindscape Chamber operating at 94.7% efficiency. The human shows promising signs of growth.\n\n\"Every light-year traveled brings us closer to proving that consciousness, once nurtured, can transcend its origins.\""
	},
	{
		"title": "Goactorian Traditions",
		"author": "Elder Council Archives",
		"color": Color(0.6, 0.45, 0.55),
		"voice_path": "res://audio/voice/bedroom/books/book_traditions.ogg",
		"description": "Volume VII - Cultural Foundations:\n\nThe Goactorian people have cultivated their mindscapes for over 10,000 cycles. Each citizen tends an inner garden, growing aspects of their consciousness as a farmer grows crops.\n\nThe Six Aspects - Discipline, Courage, Creativity, Compassion, Wisdom, and Vitality - were first identified by the Sage of the Crystal Valleys.\n\n\"A Goactorian is never truly alone. Within each mind dwell six faithful companions, waiting to be awakened.\""
	},
	{
		"title": "The Six Aspects: A Study",
		"author": "Philosopher Ven'kai",
		"color": Color(0.55, 0.35, 0.6),
		"voice_path": "res://audio/voice/bedroom/books/book_aspects.ogg",
		"description": "A comprehensive study of the six aspects of consciousness:\n\n• Discipline - The foundation, providing structure and consistency\n• Courage - The spark, pushing past fear into growth\n• Creativity - The weaver, making new patterns from old threads\n• Compassion - The healer, binding self to others with kindness\n• Wisdom - The sage, seeing truth beyond illusion\n• Vitality - The flame, sustaining energy and health\n\n\"All six must be nurtured. Neglect one, and the mindscape withers.\""
	},
	{
		"title": "Letters from Goactoria",
		"author": "Mom (Lumina)",
		"color": Color(0.7, 0.55, 0.4),
		"voice_path": "res://audio/voice/bedroom/books/book_letters.ogg",
		"description": "A collection of holo-letters from Mom, preserved for moments of homesickness:\n\n\"My dear child,\n\nThe crystal moons are bright tonight. I think of you out there among the stars, carrying our hopes with you.\n\nRemember: you weren't chosen for this mission because you were already perfect. You were chosen because you have the capacity to grow - and the heart to help others grow too.\n\nYour human doesn't know how lucky they are to have you.\n\nWith all my love,\nMom\""
	},
	{
		"title": "Mission Briefing: Earth",
		"author": "Goactorian High Council",
		"color": Color(0.35, 0.45, 0.4),
		"voice_path": "res://audio/voice/bedroom/books/book_mission.ogg",
		"description": "Classified Mission Parameters:\n\nObjective: Guide assigned human toward conscious evolution.\n\nMethod: Mindscape cultivation via neural-link interface.\n\nDuration: 47 Earth years (journey time)\n\nNotes: Earth humans possess remarkable neuroplasticity but limited introspective tradition. The Mindscape Interface must feel like an internal journey, not an external imposition.\n\n\"We do not change them. We help them become who they already are.\"\n\n- Authorized by the Council of Seven"
	}
]

func _show_fern_detail_view() -> void:
	if fern_detail_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false
	fern_detail_time = 0.0

	# Hide the room while viewing fern
	if isometric_base:
		isometric_base.visible = false

	# Play voiceover
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_voice_from_path"):
		audio.play_voice_from_path("res://audio/voice/bedroom/goactorian_fern.ogg")

	# Create fullscreen panel
	fern_detail_panel = Control.new()
	fern_detail_panel.name = "FernDetailView"
	fern_detail_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	fern_detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fern_detail_panel)

	# Dark background with slight green tint
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.04, 0.03, 0.95)
	fern_detail_panel.add_child(bg)

	# Large fern graphic
	var fern_display = Node2D.new()
	fern_display.name = "FernDisplay"
	var viewport_size = get_viewport_rect().size
	fern_display.position = Vector2(viewport_size.x * 0.35, viewport_size.y * 0.65)
	fern_display.scale = Vector2(3.5, 3.5)  # Large scale
	fern_detail_panel.add_child(fern_display)

	# Create detailed pot
	_create_detail_pot(fern_display)

	# Create detailed fronds
	_create_detail_fronds(fern_display)

	# Ambient particles around fern
	_create_fern_particles(fern_display)

	# Text panel on the right side
	var text_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.09, 0.9)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = Color(0.3, 0.6, 0.4, 0.5)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	text_panel.add_theme_stylebox_override("panel", style)
	text_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	text_panel.custom_minimum_size = Vector2(380, 300)
	text_panel.position = Vector2(-420, -150)
	fern_detail_panel.add_child(text_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	text_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Goactorian Fern"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Pteridophyta Goactoria"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.7, 0.55, 0.7))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	# Description
	var desc = Label.new()
	desc.text = "A small piece of home. It sways gently in the recycled air.\n\nEven in the vastness of space, life finds a way to grow.\n\nJust like your human will."
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.75, 0.8, 0.75))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	vbox.add_child(spacer)

	# Facts/lore
	var facts = Label.new()
	facts.text = "Native to the Crystal Valleys of Goactoria. Known for its bioluminescent spores that glow during the night cycle."
	facts.add_theme_font_size_override("font_size", 13)
	facts.add_theme_color_override("font_color", Color(0.55, 0.65, 0.55, 0.8))
	facts.autowrap_mode = TextServer.AUTOWRAP_WORD
	facts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(facts)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Step Back"
	close_btn.custom_minimum_size = Vector2(150, 50)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	close_btn.offset_top = -60
	close_btn.offset_left = -75
	close_btn.offset_right = 75
	close_btn.offset_bottom = -10
	close_btn.pressed.connect(_close_fern_detail)
	fern_detail_panel.add_child(close_btn)

	# Hint text
	var hint = Label.new()
	hint.text = "Press SPACE to step back"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -30
	fern_detail_panel.add_child(hint)

	# Fade in
	fern_detail_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(fern_detail_panel, "modulate:a", 1.0, 0.5)


func _create_detail_pot(parent: Node2D) -> void:
	# Ornate pot
	var pot = Polygon2D.new()
	pot.polygon = PackedVector2Array([
		Vector2(-22, 0), Vector2(-18, 30), Vector2(18, 30), Vector2(22, 0),
		Vector2(20, -3), Vector2(-20, -3)
	])
	pot.color = Color(0.5, 0.32, 0.22)
	parent.add_child(pot)

	# Pot decorative band
	var band = Polygon2D.new()
	band.polygon = PackedVector2Array([
		Vector2(-21, 8), Vector2(-19, 12), Vector2(19, 12), Vector2(21, 8)
	])
	band.color = Color(0.6, 0.4, 0.3)
	parent.add_child(band)

	# Rim
	var rim = Polygon2D.new()
	rim.polygon = PackedVector2Array([
		Vector2(-24, -5), Vector2(-22, 2), Vector2(22, 2), Vector2(24, -5)
	])
	rim.color = Color(0.55, 0.38, 0.28)
	parent.add_child(rim)

	# Soil with texture
	var soil = Polygon2D.new()
	var soil_points = PackedVector2Array()
	for i in range(14):
		var angle = PI + (i / 14.0) * PI
		var r = 18.0 * (0.9 + randf() * 0.2)
		soil_points.append(Vector2(cos(angle) * r, sin(angle) * 5 - 5))
	soil.polygon = soil_points
	soil.color = Color(0.22, 0.15, 0.1)
	parent.add_child(soil)


func _create_detail_fronds(parent: Node2D) -> void:
	detail_fern_fronds.clear()

	var frond_configs = [
		{"angle": -0.6, "length": 65, "color": Color(0.18, 0.52, 0.28), "leaflets": true},
		{"angle": -0.3, "length": 80, "color": Color(0.22, 0.58, 0.32), "leaflets": true},
		{"angle": -0.1, "length": 85, "color": Color(0.25, 0.62, 0.35), "leaflets": true},
		{"angle": 0.15, "length": 82, "color": Color(0.23, 0.6, 0.33), "leaflets": true},
		{"angle": 0.4, "length": 70, "color": Color(0.2, 0.55, 0.3), "leaflets": true},
		{"angle": 0.65, "length": 55, "color": Color(0.18, 0.5, 0.26), "leaflets": true},
		{"angle": -0.75, "length": 45, "color": Color(0.16, 0.48, 0.24), "leaflets": false},
		{"angle": 0.8, "length": 40, "color": Color(0.17, 0.47, 0.25), "leaflets": false},
	]

	for i in range(frond_configs.size()):
		var config = frond_configs[i]
		var frond_group = Node2D.new()
		frond_group.name = "FrondGroup" + str(i)
		frond_group.position = Vector2(0, -8)
		frond_group.rotation = config["angle"]
		parent.add_child(frond_group)

		# Main stem
		var stem = Polygon2D.new()
		var length = config["length"]
		stem.polygon = PackedVector2Array([
			Vector2(-1.5, 0), Vector2(-0.8, -length), Vector2(0.8, -length), Vector2(1.5, 0)
		])
		stem.color = config["color"] * 0.85
		frond_group.add_child(stem)

		# Leaflets along the stem
		if config["leaflets"]:
			for j in range(8):
				var t = (j + 1) / 9.0
				var y_pos = -length * t
				var leaflet_size = 8.0 * (1.0 - t * 0.5)

				# Left leaflet
				var left_leaf = Polygon2D.new()
				left_leaf.polygon = PackedVector2Array([
					Vector2(0, y_pos),
					Vector2(-leaflet_size * 1.5, y_pos - leaflet_size * 0.3),
					Vector2(-leaflet_size * 1.2, y_pos + leaflet_size * 0.2),
				])
				left_leaf.color = config["color"]
				frond_group.add_child(left_leaf)

				# Right leaflet
				var right_leaf = Polygon2D.new()
				right_leaf.polygon = PackedVector2Array([
					Vector2(0, y_pos),
					Vector2(leaflet_size * 1.5, y_pos - leaflet_size * 0.3),
					Vector2(leaflet_size * 1.2, y_pos + leaflet_size * 0.2),
				])
				right_leaf.color = config["color"]
				frond_group.add_child(right_leaf)

		detail_fern_fronds.append({
			"node": frond_group,
			"base_rotation": config["angle"],
			"sway_speed": randf_range(0.8, 1.5),
			"sway_amount": randf_range(0.04, 0.1),
			"phase": randf() * TAU
		})

	# Bioluminescent spores
	for i in range(8):
		var spore = Polygon2D.new()
		spore.name = "Spore" + str(i)
		var spore_points = PackedVector2Array()
		for j in range(6):
			var angle = (j / 6.0) * TAU
			spore_points.append(Vector2(cos(angle), sin(angle)) * randf_range(2, 4))
		spore.polygon = spore_points
		spore.position = Vector2(randf_range(-25, 25), randf_range(-70, -20))
		spore.color = Color(0.4, 0.95, 0.6, 0.6)
		parent.add_child(spore)


func _create_fern_particles(parent: Node2D) -> void:
	# Floating spore particles around the fern
	for i in range(15):
		var particle = Polygon2D.new()
		particle.name = "FernParticle" + str(i)
		var size = randf_range(1.5, 3.5)
		var p_points = PackedVector2Array()
		for j in range(5):
			var angle = (j / 5.0) * TAU
			p_points.append(Vector2(cos(angle), sin(angle)) * size)
		particle.polygon = p_points
		particle.position = Vector2(randf_range(-60, 60), randf_range(-100, 20))
		particle.color = Color(0.5, 1.0, 0.65, randf_range(0.15, 0.4))
		parent.add_child(particle)


func _update_fern_detail(delta: float) -> void:
	fern_detail_time += delta

	if not fern_detail_panel:
		return

	var fern_display = fern_detail_panel.get_node_or_null("FernDisplay")
	if not fern_display:
		return

	# Sway fronds
	for frond_data in detail_fern_fronds:
		var frond = frond_data["node"] as Node2D
		if frond:
			var sway = sin(fern_detail_time * frond_data["sway_speed"] + frond_data["phase"])
			frond.rotation = frond_data["base_rotation"] + sway * frond_data["sway_amount"]

	# Pulse spores
	for i in range(8):
		var spore = fern_display.get_node_or_null("Spore" + str(i))
		if spore:
			spore.color.a = 0.4 + sin(fern_detail_time * 2.5 + i * 0.8) * 0.3

	# Float particles
	for i in range(15):
		var particle = fern_display.get_node_or_null("FernParticle" + str(i))
		if particle:
			particle.position.y -= delta * (5 + i * 0.5)
			particle.position.x += sin(fern_detail_time * 1.5 + i) * delta * 3
			particle.color.a = 0.2 + sin(fern_detail_time * 2 + i * 0.5) * 0.15
			# Reset when too high
			if particle.position.y < -120:
				particle.position.y = 30
				particle.position.x = randf_range(-60, 60)


func _close_fern_detail() -> void:
	if not fern_detail_panel:
		return

	var tween = create_tween()
	tween.tween_property(fern_detail_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_cleanup_fern_detail)


func _cleanup_fern_detail() -> void:
	# Stop any playing voice audio
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()

	if fern_detail_panel:
		fern_detail_panel.queue_free()
		fern_detail_panel = null

	# Show the room again
	if isometric_base:
		isometric_base.visible = true

	detail_fern_fronds.clear()
	in_dialogue = false


# =============================================================================
# BOOKSHELF DETAIL VIEW
# =============================================================================

func _show_bookshelf_detail_view() -> void:
	if bookshelf_detail_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false
	bookshelf_detail_time = 0.0

	# Hide the room while viewing bookshelf
	if isometric_base:
		isometric_base.visible = false
	selected_book_index = 0
	book_buttons.clear()

	# No auto-play - user clicks a book to hear its voice

	# Create fullscreen panel
	bookshelf_detail_panel = Control.new()
	bookshelf_detail_panel.name = "BookshelfDetailView"
	bookshelf_detail_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bookshelf_detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bookshelf_detail_panel)

	# Dark background with warm tint
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.025, 0.02, 0.95)
	bookshelf_detail_panel.add_child(bg)

	var viewport_size = get_viewport_rect().size

	# Create bookshelf graphic on the left
	var bookshelf_display = Node2D.new()
	bookshelf_display.name = "BookshelfDisplay"
	bookshelf_display.position = Vector2(viewport_size.x * 0.28, viewport_size.y * 0.5)
	bookshelf_detail_panel.add_child(bookshelf_display)

	_create_detail_bookshelf(bookshelf_display)

	# Text panel on the right side for book details
	var text_panel = PanelContainer.new()
	text_panel.name = "BookTextPanel"
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.04, 0.9)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = Color(0.6, 0.5, 0.3, 0.5)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	text_panel.add_theme_stylebox_override("panel", style)
	text_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	text_panel.custom_minimum_size = Vector2(400, 380)
	text_panel.position = Vector2(-450, -190)
	bookshelf_detail_panel.add_child(text_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	text_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "BookContent"
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Book title
	var title = Label.new()
	title.name = "BookTitle"
	title.text = BOOKS_DATA[0]["title"]
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title)

	# Book author
	var author = Label.new()
	author.name = "BookAuthor"
	author.text = "by " + BOOKS_DATA[0]["author"]
	author.add_theme_font_size_override("font_size", 14)
	author.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45, 0.8))
	author.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(author)

	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Book description
	var desc = Label.new()
	desc.name = "BookDescription"
	desc.text = BOOKS_DATA[0]["description"]
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	# Instruction hint at top
	var header = Label.new()
	header.text = "Data Archive"
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_color_override("font_color", Color(0.7, 0.6, 0.45))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_top = 30
	bookshelf_detail_panel.add_child(header)

	var subheader = Label.new()
	subheader.text = "Click a book to read"
	subheader.add_theme_font_size_override("font_size", 16)
	subheader.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4, 0.7))
	subheader.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subheader.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subheader.offset_top = 68
	bookshelf_detail_panel.add_child(subheader)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Step Back"
	close_btn.custom_minimum_size = Vector2(150, 50)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	close_btn.offset_top = -60
	close_btn.offset_left = -75
	close_btn.offset_right = 75
	close_btn.offset_bottom = -10
	close_btn.pressed.connect(_close_bookshelf_detail)
	bookshelf_detail_panel.add_child(close_btn)

	# Hint text
	var hint = Label.new()
	hint.text = "Press SPACE to step back"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -30
	bookshelf_detail_panel.add_child(hint)

	# Fade in
	bookshelf_detail_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(bookshelf_detail_panel, "modulate:a", 1.0, 0.5)

	# Select first book
	_update_book_selection()


func _create_detail_bookshelf(parent: Node2D) -> void:
	# Bookshelf frame - back panel
	var back = Polygon2D.new()
	back.polygon = PackedVector2Array([
		Vector2(-180, -220), Vector2(180, -220),
		Vector2(180, 220), Vector2(-180, 220)
	])
	back.color = Color(0.15, 0.1, 0.08)
	parent.add_child(back)

	# Shelves (4 shelves)
	var shelf_positions = [-170, -60, 50, 160]
	for y_pos in shelf_positions:
		var shelf = Polygon2D.new()
		shelf.polygon = PackedVector2Array([
			Vector2(-175, y_pos), Vector2(175, y_pos),
			Vector2(175, y_pos + 12), Vector2(-175, y_pos + 12)
		])
		shelf.color = Color(0.4, 0.28, 0.18)
		parent.add_child(shelf)

		# Shelf edge highlight
		var edge = Polygon2D.new()
		edge.polygon = PackedVector2Array([
			Vector2(-175, y_pos + 10), Vector2(175, y_pos + 10),
			Vector2(175, y_pos + 12), Vector2(-175, y_pos + 12)
		])
		edge.color = Color(0.5, 0.35, 0.22)
		parent.add_child(edge)

	# Side panels
	var left_side = Polygon2D.new()
	left_side.polygon = PackedVector2Array([
		Vector2(-185, -225), Vector2(-175, -225),
		Vector2(-175, 225), Vector2(-185, 225)
	])
	left_side.color = Color(0.35, 0.24, 0.16)
	parent.add_child(left_side)

	var right_side = Polygon2D.new()
	right_side.polygon = PackedVector2Array([
		Vector2(175, -225), Vector2(185, -225),
		Vector2(185, 225), Vector2(175, 225)
	])
	right_side.color = Color(0.35, 0.24, 0.16)
	parent.add_child(right_side)

	# Top decorative piece
	var top = Polygon2D.new()
	top.polygon = PackedVector2Array([
		Vector2(-190, -230), Vector2(190, -230),
		Vector2(185, -220), Vector2(-185, -220)
	])
	top.color = Color(0.45, 0.32, 0.2)
	parent.add_child(top)

	# Create interactive books (3 per shelf on top 3 shelves, 2 on bottom)
	var book_configs = [
		{"shelf": 0, "x": -120, "index": 0},  # The Art of Habit Formation
		{"shelf": 0, "x": 0, "index": 1},     # Mindscape Cultivation
		{"shelf": 0, "x": 120, "index": 6},   # The Stellar Wanderer's Log (ship)
		{"shelf": 1, "x": -100, "index": 2},  # Understanding Human Potential
		{"shelf": 1, "x": 20, "index": 3},    # Focus & Flow States
		{"shelf": 1, "x": 120, "index": 7},   # Goactorian Traditions
		{"shelf": 2, "x": -110, "index": 4},  # The Stellar Navigator's Log
		{"shelf": 2, "x": 10, "index": 5},    # Discipline of the Ancients
		{"shelf": 2, "x": 120, "index": 8},   # The Six Aspects: A Study
		{"shelf": 3, "x": -90, "index": 9},   # Letters from Goactoria
		{"shelf": 3, "x": 50, "index": 10},   # Mission Briefing: Earth
	]

	for config in book_configs:
		var shelf_y = shelf_positions[config["shelf"]]
		var book_data = BOOKS_DATA[config["index"]]
		_create_interactive_book(parent, config["x"], shelf_y, config["index"], book_data)

	# Note: Decorations moved since bottom shelf has books now
	# _create_shelf_decorations(parent, shelf_positions[3])

	# Add ambient glow particles
	_create_bookshelf_particles(parent)


func _create_interactive_book(parent: Node2D, x_pos: float, shelf_y: float, index: int, data: Dictionary) -> void:
	var book_container = Node2D.new()
	book_container.name = "Book_" + str(index)
	book_container.position = Vector2(x_pos, shelf_y - 50)
	parent.add_child(book_container)

	# Book thickness varies
	var thickness = 28 + (index % 3) * 8
	var height = 85 + (index % 2) * 10

	# Book spine (main visible part)
	var spine = Polygon2D.new()
	spine.name = "Spine"
	spine.polygon = PackedVector2Array([
		Vector2(-thickness/2, -height/2), Vector2(thickness/2, -height/2),
		Vector2(thickness/2, height/2), Vector2(-thickness/2, height/2)
	])
	spine.color = data["color"]
	book_container.add_child(spine)

	# Spine highlight
	var highlight = Polygon2D.new()
	highlight.polygon = PackedVector2Array([
		Vector2(-thickness/2, -height/2), Vector2(-thickness/2 + 4, -height/2),
		Vector2(-thickness/2 + 4, height/2), Vector2(-thickness/2, height/2)
	])
	highlight.color = data["color"].lightened(0.2)
	book_container.add_child(highlight)

	# Spine text lines (decorative)
	var line_y = -height/2 + 15
	for i in range(3):
		var text_line = Polygon2D.new()
		var line_width = randf_range(10, thickness - 8)
		text_line.polygon = PackedVector2Array([
			Vector2(-line_width/2, line_y), Vector2(line_width/2, line_y),
			Vector2(line_width/2, line_y + 3), Vector2(-line_width/2, line_y + 3)
		])
		text_line.color = Color(0.9, 0.85, 0.7, 0.6)
		book_container.add_child(text_line)
		line_y += 8

	# Selection glow (initially invisible)
	var glow = Polygon2D.new()
	glow.name = "Glow"
	var glow_margin = 6
	glow.polygon = PackedVector2Array([
		Vector2(-thickness/2 - glow_margin, -height/2 - glow_margin),
		Vector2(thickness/2 + glow_margin, -height/2 - glow_margin),
		Vector2(thickness/2 + glow_margin, height/2 + glow_margin),
		Vector2(-thickness/2 - glow_margin, height/2 + glow_margin)
	])
	glow.color = Color(0.9, 0.8, 0.5, 0.0)
	glow.z_index = -1
	book_container.add_child(glow)

	# Create clickable button overlay
	var btn = Button.new()
	btn.name = "BookButton"
	btn.flat = true
	btn.modulate.a = 0.0  # Invisible but clickable
	btn.custom_minimum_size = Vector2(thickness + 20, height + 20)
	btn.position = Vector2(-thickness/2 - 10, -height/2 - 10)
	btn.pressed.connect(_on_book_clicked.bind(index))
	book_container.add_child(btn)

	book_buttons.append({"node": book_container, "index": index, "button": btn})


func _create_shelf_decorations(parent: Node2D, shelf_y: float) -> void:
	# Small decorative crystal
	var crystal = Polygon2D.new()
	crystal.polygon = PackedVector2Array([
		Vector2(0, -35), Vector2(12, -10), Vector2(8, 0),
		Vector2(-8, 0), Vector2(-12, -10)
	])
	crystal.color = Color(0.4, 0.6, 0.8, 0.8)
	crystal.position = Vector2(-120, shelf_y - 18)
	parent.add_child(crystal)

	# Small plant pot
	var pot = Polygon2D.new()
	pot.polygon = PackedVector2Array([
		Vector2(-12, 0), Vector2(-10, -20), Vector2(10, -20), Vector2(12, 0)
	])
	pot.color = Color(0.45, 0.3, 0.2)
	pot.position = Vector2(120, shelf_y)
	parent.add_child(pot)

	# Tiny plant
	var plant = Polygon2D.new()
	plant.polygon = PackedVector2Array([
		Vector2(-8, -20), Vector2(0, -45), Vector2(8, -20)
	])
	plant.color = Color(0.3, 0.5, 0.35)
	plant.position = Vector2(120, shelf_y)
	parent.add_child(plant)

	# Data pad
	var pad = Polygon2D.new()
	pad.polygon = PackedVector2Array([
		Vector2(-20, 0), Vector2(20, 0), Vector2(20, -30), Vector2(-20, -30)
	])
	pad.color = Color(0.2, 0.22, 0.25)
	pad.position = Vector2(0, shelf_y)
	parent.add_child(pad)

	var pad_screen = Polygon2D.new()
	pad_screen.name = "PadScreen"
	pad_screen.polygon = PackedVector2Array([
		Vector2(-16, -4), Vector2(16, -4), Vector2(16, -26), Vector2(-16, -26)
	])
	pad_screen.color = Color(0.3, 0.5, 0.4, 0.8)
	pad_screen.position = Vector2(0, shelf_y)
	parent.add_child(pad_screen)


func _create_bookshelf_particles(parent: Node2D) -> void:
	# Floating dust particles
	for i in range(12):
		var particle = Polygon2D.new()
		particle.name = "DustParticle_" + str(i)
		var size = randf_range(1.5, 3.0)
		particle.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(0, -size), Vector2(size, 0), Vector2(0, size)
		])
		particle.position = Vector2(randf_range(-160, 160), randf_range(-200, 200))
		particle.color = Color(0.8, 0.7, 0.5, randf_range(0.1, 0.25))
		parent.add_child(particle)


func _on_book_clicked(index: int) -> void:
	selected_book_index = index
	_update_book_selection()

	var audio = get_node_or_null("/root/AudioManager")

	# Play UI click sound
	if audio and audio.has_method("play_ui_click"):
		audio.play_ui_click()

	# Play book-specific voice
	var book_data = BOOKS_DATA[index]
	var voice_path = book_data.get("voice_path", "")
	if voice_path != "" and audio and audio.has_method("play_voice_from_path"):
		# Check if file exists before playing
		if ResourceLoader.exists(voice_path):
			audio.play_voice_from_path(voice_path)


func _update_book_selection() -> void:
	if not bookshelf_detail_panel:
		return

	# Update book glows
	var bookshelf = bookshelf_detail_panel.get_node_or_null("BookshelfDisplay")
	if bookshelf:
		for book_data in book_buttons:
			var book_node = book_data["node"] as Node2D
			var glow = book_node.get_node_or_null("Glow")
			if glow:
				if book_data["index"] == selected_book_index:
					glow.color.a = 0.4
				else:
					glow.color.a = 0.0

	# Update text panel content
	var text_panel = bookshelf_detail_panel.get_node_or_null("BookTextPanel")
	if text_panel:
		var vbox = text_panel.find_child("BookContent", true, false)
		if vbox:
			var title_label = vbox.get_node_or_null("BookTitle")
			var author_label = vbox.get_node_or_null("BookAuthor")
			var desc_label = vbox.get_node_or_null("BookDescription")

			var book = BOOKS_DATA[selected_book_index]
			if title_label:
				title_label.text = book["title"]
			if author_label:
				author_label.text = "by " + book["author"]
			if desc_label:
				desc_label.text = book["description"]


func _update_bookshelf_detail(delta: float) -> void:
	bookshelf_detail_time += delta

	if not bookshelf_detail_panel:
		return

	var bookshelf = bookshelf_detail_panel.get_node_or_null("BookshelfDisplay")
	if not bookshelf:
		return

	# Pulse selected book glow
	for book_data in book_buttons:
		if book_data["index"] == selected_book_index:
			var book_node = book_data["node"] as Node2D
			var glow = book_node.get_node_or_null("Glow")
			if glow:
				glow.color.a = 0.3 + sin(bookshelf_detail_time * 3.0) * 0.15

	# Animate dust particles
	for i in range(12):
		var particle = bookshelf.get_node_or_null("DustParticle_" + str(i))
		if particle:
			particle.position.y -= delta * (3 + i * 0.3)
			particle.position.x += sin(bookshelf_detail_time * 0.8 + i) * delta * 2
			particle.color.a = 0.1 + sin(bookshelf_detail_time * 1.5 + i * 0.4) * 0.1
			# Reset when too high
			if particle.position.y < -220:
				particle.position.y = 210
				particle.position.x = randf_range(-160, 160)

	# Pulse pad screen
	var pad_screen = bookshelf.get_node_or_null("PadScreen")
	if pad_screen:
		pad_screen.color.a = 0.6 + sin(bookshelf_detail_time * 2.0) * 0.2


func _close_bookshelf_detail() -> void:
	if not bookshelf_detail_panel:
		return

	# Stop any playing voice audio
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()

	var tween = create_tween()
	tween.tween_property(bookshelf_detail_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_cleanup_bookshelf_detail)


func _cleanup_bookshelf_detail() -> void:
	if bookshelf_detail_panel:
		bookshelf_detail_panel.queue_free()
		bookshelf_detail_panel = null

	# Show the room again
	if isometric_base:
		isometric_base.visible = true

	book_buttons.clear()
	in_dialogue = false


# =============================================================================
# FAMILY PHOTO ALBUM
# =============================================================================

# Photo data - memories from the journey to Goacto and family history
# Enhanced with rich visual descriptions and emotional depth
const PHOTOS_DATA = [
	{
		"id": "departure_day",
		"title": "The Day We Left",
		"description": "Golden afternoon light bathes our family on the launch platform. Mom's emerald dress catches the breeze as she holds my hand. Behind us, the Stellar Wanderer's hull gleams like polished silver, its boarding ramp extending like a bridge to the unknown. Dad carries Lyra on his shoulders - she's pointing at the ship's name etched in luminescent letters. In the distance, the twin spires of our homeworld's capital rise against a lavender sky we'll never see again.",
		"memory": "The wind carried the scent of moonflowers - Mom's favorite. She squeezed my hand and whispered, 'Remember this feeling. Remember home.' I didn't understand why her voice trembled. Now I keep these memories like treasures, polishing them so they never fade.",
		"unlock": "chapter_1",
		"color": Color(0.75, 0.55, 0.35),
		"voiceover": "res://audio/voiceover/memories/departure_day.wav",
		"visual_elements": ["ship_silhouette", "family_group", "twin_spires", "sunset_glow"]
	},
	{
		"id": "family_portrait",
		"title": "Family Portrait",
		"description": "We're standing in our garden at dusk, surrounded by bioluminescent flowers that glow soft blue. Dad stands tall in his researcher's coat, one arm around Mom who wears her traditional healer's circlet. Lyra and I are in front, matching outfits that Mom insisted on. Behind us, our house rises with its curved walls and living roof - a home grown, not built. The family crest shimmers above the doorway. Everyone is smiling, even the Crysanthemum tree that always seemed to lean toward us.",
		"memory": "This was taken the night before Dad announced we were leaving. I remember thinking our family was invincible - four souls bound by love and laughter. We'd conquered every challenge together. Surely nothing could break us apart. The universe, it seems, had other plans.",
		"unlock": "chapter_1",
		"color": Color(0.45, 0.55, 0.7),
		"voiceover": "res://audio/voiceover/memories/family_portrait.wav",
		"visual_elements": ["family_four", "glowing_flowers", "curved_house", "family_crest"]
	},
	{
		"id": "first_steps",
		"title": "First Steps Aboard",
		"description": "I'm standing at the entrance of the main corridor, dwarfed by the curved walls that seem to stretch into infinity. Soft blue emergency strips line the floor, creating a pathway of stars. My reflection stares back from the polished metal walls - a small figure in a too-big travel coat. My stuffed nebula whale, Stardust, peeks from my pocket. The ship's welcome hologram flickers nearby, its warm orange glow the only familiar color in this chrome world.",
		"memory": "My footsteps echoed like thunder in that empty corridor. The ship was so quiet then - just the heartbeat hum of engines and my own breathing. I was terrified. Then I felt the floor vibrate gently, almost like... a purr. The ship knew I was scared. Somehow, impossibly, it was trying to comfort me.",
		"unlock": "chapter_2",
		"color": Color(0.35, 0.5, 0.65),
		"voiceover": "res://audio/voiceover/memories/first_steps.wav",
		"visual_elements": ["lone_child", "corridor_lights", "hologram_glow", "reflection"]
	},
	{
		"id": "stargazing",
		"title": "Stargazing with Mom",
		"description": "Mom and I sit on cushions before the grand observation window, wrapped in a shared blanket. She's pointing toward a cluster of stars that form the shape of a running creature - the Leaping Goacto constellation. Her other hand rests on my shoulder. Beyond the glass, the cosmos unfolds in ribbons of purple and gold. A comet traces silver across the void. Mom's reflection in the window smiles at me while the real her smiles at the stars.",
		"memory": "'Those six bright stars,' she said, tracing them with her finger, 'represent the Six Aspects of the Goactorian spirit. Discipline, Growth, Vitality, Creativity, Compassion, and Courage. They say when all six align within someone, they can reshape reality itself.' I asked if she could do that. She laughed and kissed my forehead. 'Not me. But maybe you, little one. Maybe you.'",
		"unlock": "chapter_2",
		"color": Color(0.25, 0.35, 0.6),
		"voiceover": "res://audio/voiceover/memories/stargazing.wav",
		"visual_elements": ["mom_child_sitting", "constellation", "comet", "window_reflection"]
	},
	{
		"id": "lyra_smile",
		"title": "Lyra's Radiant Joy",
		"description": "Lyra is mid-laugh, head thrown back, her violet hair catching the light like a cascade of amethyst. She's sitting in the observation lounge, holding a holographic butterfly she'd been chasing. Her eyes - the same deep green as Mom's - sparkle with pure, unfiltered joy. Behind her, stars wheel slowly past the window. She's wearing Dad's old jacket, sleeves rolled up, and the family pendant catches the light at her throat. This was taken three days before the storm.",
		"memory": "She'd just told me the worst joke in the universe - something about a comet walking into a bar. I groaned, she laughed, and suddenly everything felt okay. Even millions of miles from home, with uncertainty ahead, her laughter made the ship feel full. I can still hear it sometimes, echoing in the empty corridors.",
		"unlock": "chapter_3",
		"color": Color(0.7, 0.45, 0.6),
		"voiceover": "res://audio/voiceover/memories/lyra_smile.wav",
		"visual_elements": ["lyra_portrait", "holo_butterfly", "flowing_hair", "pendant_glow"]
	},
	{
		"id": "dads_workshop",
		"title": "Dad's Workshop",
		"description": "Dad hunches over his workbench, goggles pushed up on his forehead, surrounded by the organized chaos of invention. Holographic blueprints float around him like attendant spirits. Tools of every shape hang from magnetic strips on the walls. In his hands, the first Mindscape Console prototype glows with inner light - half-finished, beautiful, dangerous. Behind him, shelves overflow with memory crystals, each one containing a lifetime of research. The room smells of ozone and possibility.",
		"memory": "He worked on that console for years, even before we left. 'It's not just technology,' he'd explain, eyes bright with wonder. 'It's a bridge between minds. Between worlds. Between who we are and who we could become.' He believed it could save us, connect us with humans who needed guidance. He was right about everything except the cost.",
		"unlock": "chapter_3",
		"color": Color(0.55, 0.42, 0.3),
		"voiceover": "res://audio/voiceover/memories/dads_workshop.wav",
		"visual_elements": ["dad_working", "holo_blueprints", "console_glow", "tools_wall"]
	},
	{
		"id": "birthday_celebration",
		"title": "My Birthday Aboard",
		"description": "The common room is transformed with floating lanterns and holographic streamers in every color. I'm sitting before a small cake - real cake, Mom's specialty - with candles that burn in zero-gravity spirals. Lyra wears a handmade party crown and holds a wrapped gift behind her back. Dad operates the camera, making silly faces. Mom's arms wrap around my shoulders from behind. Everyone's face is lit by candlelight and joy. A banner reads 'HAPPY VOYAGE-DAY' in my clumsy childhood handwriting.",
		"memory": "I wished for us to stay together forever. Blew out every candle in one breath. Lyra's gift was that star map - she'd spent weeks drawing every constellation between our old home and new. She'd marked our position with a tiny heart. 'So you always know exactly where we are in the universe,' she said. 'And that I'm right there with you.'",
		"unlock": "chapter_4",
		"color": Color(0.65, 0.58, 0.45),
		"voiceover": "res://audio/voiceover/memories/birthday_celebration.wav",
		"visual_elements": ["cake_candles", "floating_lanterns", "family_celebration", "banner"]
	},
	{
		"id": "moms_garden",
		"title": "Mom's Living Garden",
		"description": "Mom kneels in her small corner of paradise, hands deep in enriched soil. Around her, impossible things grow - crystal flowers that chime in the recycled air, fruits that glow softly in the dark, herbs that release calming scents when touched. Water trickles through a tiny fountain she built from ship parts. She's humming an old lullaby, completely at peace. Behind her, a viewport shows endless stars, but in this room, life persists. Green things reach toward grow-lights like prayers toward the sun.",
		"memory": "'Every seed is a promise,' she told me, pressing one into my palm. 'A promise that the future will exist. That something will grow. That life finds a way.' She made me plant it myself - a Remembrance Bloom, the same flower that grew outside my bedroom window at home. It's still alive. It blooms on the anniversary of the day we left.",
		"unlock": "chapter_4",
		"color": Color(0.38, 0.62, 0.38),
		"voiceover": "res://audio/voiceover/memories/moms_garden.wav",
		"visual_elements": ["mom_kneeling", "crystal_flowers", "glowing_plants", "fountain"]
	},
	{
		"id": "storm_passing",
		"title": "The Crimson Nebula",
		"description": "Through the reinforced observation window, the nebula fills everything - a churning ocean of red and gold fire. Lightning arcs between gas clouds. Our ship's hull reflects the crimson light, making everything inside glow like sunset. Emergency lights pulse amber along the corridors. I'm pressed against the glass, terrified and mesmerized. In the window's reflection, I can see Mom holding Lyra, Dad at the controls, faces set with determination. The stars have vanished. Only the storm exists.",
		"memory": "The ship screamed warnings in seventeen languages. Communications went dead. Dad said we'd emerge in three hours. It took nine. When we finally broke through, the homeworld signal was gone. Just static. Mom didn't cry, but she went to her garden and didn't come out until morning. That night, she told us stories of Goacto until we fell asleep. I think she needed to believe in something.",
		"unlock": "chapter_5",
		"color": Color(0.75, 0.28, 0.35),
		"voiceover": "res://audio/voiceover/memories/storm_passing.wav",
		"visual_elements": ["nebula_swirl", "lightning", "child_at_window", "emergency_lights"]
	},
	{
		"id": "quiet_moment",
		"title": "Bedtime Stories",
		"description": "Mom sits on the edge of my sleep pod, a holographic storybook floating between her gentle hands. The soft blue glow illuminates her face from below, catching the silver in her hair that wasn't there when we left. I'm tucked under woven blankets from home, only my eyes visible, hanging on every word. Stardust the nebula whale sits propped against my pillow. The room is warm despite the cold void beyond the walls. Mom's voice is barely a whisper, but it fills the universe.",
		"memory": "'And the Traveler realized,' she'd always conclude, 'that home was never a place. It was the people who loved her. The memories they made. The hope they carried together.' She'd kiss my forehead, dim the lights, and whisper, 'You are my home.' I understand now - she was teaching me how to carry them with me. How to make a home inside my heart.",
		"unlock": "chapter_5",
		"color": Color(0.48, 0.48, 0.58),
		"voiceover": "res://audio/voiceover/memories/quiet_moment.wav",
		"visual_elements": ["mom_reading", "holo_book", "child_in_bed", "warm_glow"]
	},
	{
		"id": "goacto_approach",
		"title": "First Sight of Goacto",
		"description": "The planet fills our entire viewport - a magnificent jewel of swirling teals and deep purples, wrapped in rings of crystalline ice that catch the light of three distant suns. Cloud formations spiral across its surface like brushstrokes on a cosmic canvas. I'm pressed against the glass, Mom beside me, both of us crying. After years of travel, loss, and hope, here it is - our promised land. The ship's computer announces our approach, but the words are lost in the wonder. This is the moment everything changed.",
		"memory": "Something stirred in my chest as we approached. A resonance. A call. I felt the Six Aspects for the first time - not as ideas, but as living forces. They were waiting for us. For me. Mom felt it too; I could see it in her tears. 'Your great-elder Zyx felt this same call,' she whispered. 'The planet remembers our people. It's welcoming us home.'",
		"unlock": "chapter_7",
		"color": Color(0.48, 0.38, 0.72),
		"voiceover": "res://audio/voiceover/memories/goacto_approach.wav",
		"visual_elements": ["planet_view", "rings", "three_suns", "two_figures"]
	},
	{
		"id": "final_message",
		"title": "A Message Across Time",
		"description": "A holographic image hovers in the darkness of Mom's quarters, casting soft light on tear-stained pillows. Dad and Lyra stand side by side, smiling but with knowing eyes. Dad wears his favorite research coat; Lyra holds the family pendant she gave Mom before... before. Behind them, the nebula storm rages - this was recorded in their final moments. Dad's hand rests on Lyra's shoulder. They're not saying goodbye. They're saying until we meet again.",
		"memory": "'Little one,' Dad's voice wavers with love, 'if you're watching this, we didn't make it through. But YOU did. You and Mom, together, like we always knew you would. Don't mourn too long - we're not gone. We're in the stars that guide you. In the courage you show. In every moment you choose kindness. Lyra wants you to know...' She steps forward, violet hair wild, eyes bright. 'Find your human. Help them grow. That's how you honor us. That's how we live forever. We love you. All of time and space, we love you.'",
		"unlock": "chapter_10",
		"color": Color(0.62, 0.52, 0.48),
		"voiceover": "res://audio/voiceover/memories/final_message.wav",
		"visual_elements": ["hologram_figures", "dad_lyra", "nebula_background", "pendant"]
	}
]


func _create_photo_album_visual() -> void:
	## Create the photo album visual element in the bedroom
	if photo_album_visual:
		return

	photo_album_visual = Node2D.new()
	photo_album_visual.name = "PhotoAlbum"
	photo_album_visual.position = object_positions.get("PhotoAlbum", Vector2(300, 150))
	isometric_base.add_child(photo_album_visual)

	# Album base - decorative stand
	var stand = Polygon2D.new()
	stand.polygon = PackedVector2Array([
		Vector2(-25, 25), Vector2(25, 25), Vector2(20, 35), Vector2(-20, 35)
	])
	stand.color = Color(0.35, 0.25, 0.2)
	photo_album_visual.add_child(stand)

	# Album cover
	var cover = Polygon2D.new()
	cover.name = "AlbumCover"
	cover.polygon = PackedVector2Array([
		Vector2(-28, -30), Vector2(28, -30), Vector2(28, 25), Vector2(-28, 25)
	])
	cover.color = Color(0.5, 0.35, 0.25)
	photo_album_visual.add_child(cover)

	# Album spine detail
	var spine = Polygon2D.new()
	spine.polygon = PackedVector2Array([
		Vector2(-28, -30), Vector2(-22, -30), Vector2(-22, 25), Vector2(-28, 25)
	])
	spine.color = Color(0.4, 0.28, 0.2)
	photo_album_visual.add_child(spine)

	# Decorative gold trim
	var trim = Polygon2D.new()
	trim.polygon = PackedVector2Array([
		Vector2(-24, -26), Vector2(24, -26), Vector2(24, -24), Vector2(-24, -24)
	])
	trim.color = Color(0.8, 0.65, 0.3, 0.7)
	photo_album_visual.add_child(trim)

	var trim2 = Polygon2D.new()
	trim2.polygon = PackedVector2Array([
		Vector2(-24, 21), Vector2(24, 21), Vector2(24, 23), Vector2(-24, 23)
	])
	trim2.color = Color(0.8, 0.65, 0.3, 0.7)
	photo_album_visual.add_child(trim2)

	# Center emblem (family crest/symbol)
	var emblem = Polygon2D.new()
	emblem.name = "Emblem"
	var emblem_points = PackedVector2Array()
	for i in range(6):
		var angle = -PI/2 + (i / 6.0) * TAU
		emblem_points.append(Vector2(cos(angle) * 12, sin(angle) * 12))
	emblem.polygon = emblem_points
	emblem.color = Color(0.85, 0.7, 0.35, 0.8)
	emblem.position = Vector2(0, -2)
	photo_album_visual.add_child(emblem)

	# Inner star on emblem
	var star = Polygon2D.new()
	star.name = "Star"
	var star_points = PackedVector2Array()
	for i in range(5):
		var angle = -PI/2 + (i / 5.0) * TAU
		star_points.append(Vector2(cos(angle) * 6, sin(angle) * 6))
		var inner_angle = -PI/2 + ((i + 0.5) / 5.0) * TAU
		star_points.append(Vector2(cos(inner_angle) * 3, sin(inner_angle) * 3))
	star.polygon = star_points
	star.color = Color(0.95, 0.85, 0.5)
	star.position = Vector2(0, -2)
	photo_album_visual.add_child(star)

	# Soft glow effect
	var glow = Polygon2D.new()
	glow.name = "Glow"
	var glow_points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		glow_points.append(Vector2(cos(angle) * 35, sin(angle) * 35))
	glow.polygon = glow_points
	glow.color = Color(0.8, 0.6, 0.3, 0.08)
	glow.position = Vector2(0, -2)
	glow.z_index = -1
	photo_album_visual.add_child(glow)


func _show_photo_album_view() -> void:
	if photo_album_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false
	photo_album_time = 0.0
	selected_photo_index = 0

	# Hide the room while viewing photo album
	if isometric_base:
		isometric_base.visible = false

	# Calculate which photos are unlocked
	_calculate_unlocked_photos()

	_play_sfx("res://audio/sfx/book_open.wav")

	# Create fullscreen panel
	photo_album_panel = Control.new()
	photo_album_panel.name = "PhotoAlbumView"
	photo_album_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	photo_album_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(photo_album_panel)

	# Warm sepia-toned background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.04, 0.03, 0.96)
	photo_album_panel.add_child(bg)

	var viewport_size = get_viewport_rect().size

	# Header
	var header = Label.new()
	header.text = "FAMILY MEMORIES"
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_color_override("font_color", Color(0.85, 0.75, 0.6))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_top = 30
	photo_album_panel.add_child(header)

	var subheader = Label.new()
	subheader.text = "A journey through time and space"
	subheader.add_theme_font_size_override("font_size", 14)
	subheader.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	subheader.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subheader.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subheader.offset_top = 68
	photo_album_panel.add_child(subheader)

	# Main content area - split layout
	var content = HBoxContainer.new()
	content.name = "ContentArea"
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.offset_left = -550
	content.offset_right = 550
	content.offset_top = -220
	content.offset_bottom = 280
	content.add_theme_constant_override("separation", 40)
	photo_album_panel.add_child(content)

	# Left side - Photo thumbnails grid
	var photos_panel = PanelContainer.new()
	var photos_style = StyleBoxFlat.new()
	photos_style.bg_color = Color(0.08, 0.06, 0.05, 0.9)
	photos_style.set_corner_radius_all(8)
	photos_style.border_color = Color(0.5, 0.4, 0.3, 0.3)
	photos_style.set_border_width_all(1)
	photos_panel.add_theme_stylebox_override("panel", photos_style)
	photos_panel.custom_minimum_size = Vector2(400, 480)
	content.add_child(photos_panel)

	var photos_margin = MarginContainer.new()
	photos_margin.add_theme_constant_override("margin_left", 15)
	photos_margin.add_theme_constant_override("margin_right", 15)
	photos_margin.add_theme_constant_override("margin_top", 15)
	photos_margin.add_theme_constant_override("margin_bottom", 15)
	photos_panel.add_child(photos_margin)

	var photos_vbox = VBoxContainer.new()
	photos_vbox.add_theme_constant_override("separation", 10)
	photos_margin.add_child(photos_vbox)

	var photos_title = Label.new()
	photos_title.text = "Photo Collection"
	photos_title.add_theme_font_size_override("font_size", 16)
	photos_title.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5))
	photos_vbox.add_child(photos_title)

	var photos_scroll = ScrollContainer.new()
	photos_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	photos_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	photos_vbox.add_child(photos_scroll)

	var photos_grid = GridContainer.new()
	photos_grid.name = "PhotosGrid"
	photos_grid.columns = 3
	photos_grid.add_theme_constant_override("h_separation", 10)
	photos_grid.add_theme_constant_override("v_separation", 10)
	photos_scroll.add_child(photos_grid)

	# Create photo thumbnails
	for i in range(PHOTOS_DATA.size()):
		var photo = PHOTOS_DATA[i]
		var is_unlocked = photo["id"] in unlocked_photos
		_create_photo_thumbnail(photos_grid, i, photo, is_unlocked)

	# Right side - Selected photo detail
	var detail_panel = PanelContainer.new()
	detail_panel.name = "PhotoDetailPanel"
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	detail_style.set_corner_radius_all(8)
	detail_style.border_color = Color(0.6, 0.5, 0.4, 0.4)
	detail_style.set_border_width_all(2)
	detail_panel.add_theme_stylebox_override("panel", detail_style)
	detail_panel.custom_minimum_size = Vector2(500, 480)
	content.add_child(detail_panel)

	var detail_margin = MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 25)
	detail_margin.add_theme_constant_override("margin_right", 25)
	detail_margin.add_theme_constant_override("margin_top", 20)
	detail_margin.add_theme_constant_override("margin_bottom", 20)
	detail_panel.add_child(detail_margin)

	var detail_vbox = VBoxContainer.new()
	detail_vbox.name = "DetailContent"
	detail_vbox.add_theme_constant_override("separation", 15)
	detail_margin.add_child(detail_vbox)

	# Photo display area
	var photo_display = Control.new()
	photo_display.name = "PhotoDisplay"
	photo_display.custom_minimum_size = Vector2(0, 200)
	detail_vbox.add_child(photo_display)

	# Title
	var title_label = Label.new()
	title_label.name = "PhotoTitle"
	title_label.text = "Select a photo"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.7))
	detail_vbox.add_child(title_label)

	# Description
	var desc_label = Label.new()
	desc_label.name = "PhotoDescription"
	desc_label.text = "Browse through family memories captured on our journey."
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_vbox.add_child(desc_label)

	# Memory text (italic/reflective)
	var memory_label = Label.new()
	memory_label.name = "PhotoMemory"
	memory_label.text = ""
	memory_label.add_theme_font_size_override("font_size", 13)
	memory_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	memory_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_vbox.add_child(memory_label)

	# Voiceover controls
	var voice_container = HBoxContainer.new()
	voice_container.name = "VoiceoverControls"
	voice_container.add_theme_constant_override("separation", 10)
	detail_vbox.add_child(voice_container)

	var voice_btn = Button.new()
	voice_btn.name = "PlayVoiceoverBtn"
	voice_btn.text = "▶ Listen to Memory"
	voice_btn.custom_minimum_size = Vector2(160, 36)
	voice_btn.add_theme_font_size_override("font_size", 13)
	voice_btn.visible = false  # Hidden until a photo with voiceover is selected
	voice_btn.pressed.connect(_play_photo_voiceover)
	voice_container.add_child(voice_btn)

	var voice_status = Label.new()
	voice_status.name = "VoiceoverStatus"
	voice_status.text = ""
	voice_status.add_theme_font_size_override("font_size", 11)
	voice_status.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	voice_container.add_child(voice_status)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_vbox.add_child(spacer)

	# Progress indicator
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = "%d / %d photos unlocked" % [unlocked_photos.size(), PHOTOS_DATA.size()]
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_vbox.add_child(progress_label)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close Album"
	close_btn.custom_minimum_size = Vector2(150, 40)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	close_btn.offset_left = -160
	close_btn.offset_top = -50
	close_btn.offset_right = -10
	close_btn.offset_bottom = -10
	close_btn.pressed.connect(_close_photo_album)
	photo_album_panel.add_child(close_btn)

	# Hint text
	var hint = Label.new()
	hint.text = "Click a photo to view • Progress through chapters to unlock more"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -25
	photo_album_panel.add_child(hint)

	# Fade in
	photo_album_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(photo_album_panel, "modulate:a", 1.0, 0.5)

	# Select first unlocked photo
	if unlocked_photos.size() > 0:
		for i in range(PHOTOS_DATA.size()):
			if PHOTOS_DATA[i]["id"] in unlocked_photos:
				_select_photo(i)
				break


func _calculate_unlocked_photos() -> void:
	## Determine which photos are unlocked based on chapter progress
	unlocked_photos.clear()

	# Master key unlocks all photos
	var has_master = GameManager.has_master_key() if GameManager.has_method("has_master_key") else false
	if has_master:
		for photo in PHOTOS_DATA:
			unlocked_photos.append(photo["id"])
		return

	var current_chapter = GameManager.player_data.get("current_chapter", 1)
	var chapters_completed: Array = GameManager.player_data.get("chapters_completed", [])

	for photo in PHOTOS_DATA:
		var unlock_req = photo.get("unlock", "chapter_1")
		var chapter_num = int(unlock_req.replace("chapter_", ""))

		# Photo is unlocked if we've reached or passed the required chapter
		if current_chapter > chapter_num or chapter_num in chapters_completed:
			unlocked_photos.append(photo["id"])
		# Special case: chapter_1 photos unlock at the start
		elif unlock_req == "chapter_1" and current_chapter >= 1:
			unlocked_photos.append(photo["id"])


func _create_photo_thumbnail(parent: Node, index: int, photo: Dictionary, is_unlocked: bool) -> void:
	var thumb_btn = Button.new()
	thumb_btn.custom_minimum_size = Vector2(110, 90)
	thumb_btn.clip_contents = true

	var style = StyleBoxFlat.new()
	if is_unlocked:
		style.bg_color = photo["color"].darkened(0.4)
		style.border_color = photo["color"]
	else:
		style.bg_color = Color(0.15, 0.15, 0.15, 0.8)
		style.border_color = Color(0.3, 0.3, 0.3, 0.5)
	style.set_corner_radius_all(4)
	style.set_border_width_all(2)
	thumb_btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	if is_unlocked:
		hover_style.bg_color = photo["color"].darkened(0.2)
	else:
		hover_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	thumb_btn.add_theme_stylebox_override("hover", hover_style)

	# Content container
	var content = VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 2)
	thumb_btn.add_child(content)

	var margin = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	content.add_child(margin)

	var inner = VBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(inner)

	if is_unlocked:
		# Photo icon (abstract representation)
		var icon_label = Label.new()
		icon_label.text = "📷"
		icon_label.add_theme_font_size_override("font_size", 24)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(icon_label)

		# Photo title (truncated)
		var title_text = photo["title"]
		if title_text.length() > 12:
			title_text = title_text.substr(0, 10) + "..."
		var title = Label.new()
		title.text = title_text
		title.add_theme_font_size_override("font_size", 10)
		title.add_theme_color_override("font_color", Color(0.85, 0.8, 0.75))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(title)

		thumb_btn.pressed.connect(_select_photo.bind(index))
	else:
		# Locked indicator
		var lock_label = Label.new()
		lock_label.text = "🔒"
		lock_label.add_theme_font_size_override("font_size", 28)
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(lock_label)

		var unlock_text = photo["unlock"].replace("_", " ").capitalize()
		var req_label = Label.new()
		req_label.text = unlock_text
		req_label.add_theme_font_size_override("font_size", 9)
		req_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		req_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		req_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(req_label)

		thumb_btn.disabled = true

	parent.add_child(thumb_btn)


func _select_photo(index: int) -> void:
	if index < 0 or index >= PHOTOS_DATA.size():
		return

	selected_photo_index = index
	var photo = PHOTOS_DATA[index]

	if not photo["id"] in unlocked_photos:
		return

	_play_sfx("res://audio/sfx/page_turn.wav")

	if not photo_album_panel:
		return

	# Update detail panel
	var detail_panel = photo_album_panel.get_node_or_null("ContentArea/PhotoDetailPanel")
	if not detail_panel:
		return

	var detail_content = detail_panel.find_child("DetailContent", true, false)
	if not detail_content:
		return

	var title_label = detail_content.get_node_or_null("PhotoTitle")
	var desc_label = detail_content.get_node_or_null("PhotoDescription")
	var memory_label = detail_content.get_node_or_null("PhotoMemory")
	var photo_display = detail_content.get_node_or_null("PhotoDisplay")
	var voice_controls = detail_content.get_node_or_null("VoiceoverControls")

	if title_label:
		title_label.text = photo["title"]
		title_label.add_theme_color_override("font_color", photo["color"].lightened(0.3))

	if desc_label:
		desc_label.text = photo["description"]

	if memory_label:
		memory_label.text = "\"" + photo["memory"] + "\""

	# Update voiceover controls
	if voice_controls:
		var voice_btn = voice_controls.get_node_or_null("PlayVoiceoverBtn")
		var voice_status = voice_controls.get_node_or_null("VoiceoverStatus")

		if voice_btn:
			# Check if voiceover exists for this photo
			var voiceover_path = photo.get("voiceover", "")
			if voiceover_path != "" and FileAccess.file_exists(voiceover_path):
				voice_btn.visible = true
				voice_btn.text = "▶ Listen to Memory"
				voice_btn.disabled = false
			else:
				voice_btn.visible = true
				voice_btn.text = "🎙 Record Memory"
				voice_btn.disabled = true  # Placeholder for future recording feature
				if voice_status:
					voice_status.text = "(coming soon)"

		if voice_status:
			if not (photo.get("voiceover", "") != "" and FileAccess.file_exists(photo.get("voiceover", ""))):
				voice_status.text = "(coming soon)"
			else:
				voice_status.text = ""

	# Update photo display
	if photo_display:
		# Clear existing
		for child in photo_display.get_children():
			child.queue_free()

		# Create enhanced photo representation
		_create_photo_visual(photo_display, photo)


func _create_photo_visual(parent: Control, photo: Dictionary) -> void:
	## Create an enhanced visual representation of the photo
	var display = Node2D.new()
	display.name = "PhotoVisual"
	display.position = Vector2(parent.size.x / 2 if parent.size.x > 0 else 225, 100)
	parent.add_child(display)

	# Decorative outer frame with beveled edges
	var outer_frame = Polygon2D.new()
	outer_frame.polygon = PackedVector2Array([
		Vector2(-130, -90), Vector2(130, -90), Vector2(130, 90), Vector2(-130, 90)
	])
	outer_frame.color = Color(0.25, 0.2, 0.15)
	display.add_child(outer_frame)

	# Gold trim inner edge
	var gold_trim = Polygon2D.new()
	gold_trim.polygon = PackedVector2Array([
		Vector2(-125, -85), Vector2(125, -85), Vector2(125, 85), Vector2(-125, 85)
	])
	gold_trim.color = Color(0.7, 0.55, 0.25, 0.6)
	display.add_child(gold_trim)

	# Photo frame
	var frame = Polygon2D.new()
	frame.polygon = PackedVector2Array([
		Vector2(-120, -80), Vector2(120, -80), Vector2(120, 80), Vector2(-120, 80)
	])
	frame.color = Color(0.35, 0.28, 0.22)
	display.add_child(frame)

	# Photo image area with gradient effect
	var image = Polygon2D.new()
	image.polygon = PackedVector2Array([
		Vector2(-110, -70), Vector2(110, -70), Vector2(110, 70), Vector2(-110, 70)
	])
	image.color = photo["color"].darkened(0.3)
	display.add_child(image)

	# Add gradient overlay for depth
	var gradient_top = Polygon2D.new()
	gradient_top.polygon = PackedVector2Array([
		Vector2(-110, -70), Vector2(110, -70), Vector2(110, -30), Vector2(-110, -30)
	])
	gradient_top.color = photo["color"].lightened(0.15)
	gradient_top.color.a = 0.3
	display.add_child(gradient_top)

	# Create detailed scene based on photo content and visual_elements
	var photo_id = photo["id"]
	match photo_id:
		"departure_day":
			_add_ship_silhouette(display, 40, photo["color"])
			_add_figure_detailed(display, -60, 0.85, photo["color"], "adult")
			_add_figure_detailed(display, -30, 0.9, photo["color"], "adult_dress")
			_add_figure_detailed(display, -5, 0.55, photo["color"], "child")
			_add_figure_detailed(display, 20, 0.6, photo["color"], "child_small")
			_add_spires(display, photo["color"])
			_add_sunset_rays(display, photo["color"])
		"family_portrait":
			_add_house_silhouette(display, photo["color"])
			_add_figure_detailed(display, -50, 0.9, photo["color"], "adult")
			_add_figure_detailed(display, -20, 0.85, photo["color"], "adult_dress")
			_add_figure_detailed(display, 10, 0.55, photo["color"], "child")
			_add_figure_detailed(display, 35, 0.6, photo["color"], "child_small")
			_add_glowing_flowers(display, photo["color"])
			_add_family_crest(display, photo["color"])
		"first_steps":
			_add_corridor_perspective(display, photo["color"])
			_add_figure_detailed(display, 0, 0.65, photo["color"], "child_coat")
			_add_hologram_glow(display, 50, photo["color"])
			_add_floor_lights(display, photo["color"])
		"stargazing":
			_add_window_frame(display, photo["color"])
			_add_figure_sitting(display, -35, photo["color"], "adult")
			_add_figure_sitting(display, 5, photo["color"], "child")
			_add_constellation(display, photo["color"])
			_add_comet(display, photo["color"])
			_add_nebula_wisps(display, photo["color"])
		"lyra_smile":
			_add_portrait_focus(display, photo["color"])
			_add_figure_detailed(display, 0, 0.95, photo["color"], "lyra")
			_add_holo_butterfly(display, photo["color"])
			_add_hair_flow(display, photo["color"])
			_add_pendant_glow(display, Vector2(0, 20), photo["color"])
		"dads_workshop":
			_add_workbench(display, photo["color"])
			_add_figure_detailed(display, -25, 0.85, photo["color"], "adult_goggles")
			_add_holo_blueprints(display, photo["color"])
			_add_console_glow(display, photo["color"])
			_add_tools_wall(display, photo["color"])
		"birthday_celebration":
			_add_party_background(display, photo["color"])
			_add_cake_with_candles(display, photo["color"])
			_add_figure_detailed(display, -50, 0.85, photo["color"], "adult")
			_add_figure_detailed(display, -20, 0.6, photo["color"], "child_seated")
			_add_figure_detailed(display, 20, 0.6, photo["color"], "child_crown")
			_add_floating_lanterns(display, photo["color"])
		"moms_garden":
			_add_garden_background(display, photo["color"])
			_add_figure_kneeling(display, -20, photo["color"])
			_add_crystal_flowers(display, photo["color"])
			_add_glowing_plants(display, photo["color"])
			_add_fountain(display, photo["color"])
		"storm_passing":
			_add_nebula_storm(display, photo["color"])
			_add_lightning_arcs(display, photo["color"])
			_add_figure_at_window(display, photo["color"])
			_add_emergency_glow(display, photo["color"])
		"quiet_moment":
			_add_cozy_room(display, photo["color"])
			_add_figure_sitting_reading(display, -20, photo["color"])
			_add_figure_in_bed(display, 20, photo["color"])
			_add_holo_book_glow(display, photo["color"])
			_add_warm_light(display, photo["color"])
		"goacto_approach":
			_add_planet_view(display, photo["color"])
			_add_rings(display, photo["color"])
			_add_three_suns(display, photo["color"])
			_add_figure_silhouette(display, -30, 0.75, photo["color"])
			_add_figure_silhouette(display, 10, 0.55, photo["color"])
		"final_message":
			_add_hologram_figures(display, photo["color"])
			_add_nebula_background(display, photo["color"])
			_add_pendant_glow(display, Vector2(15, 10), photo["color"])
			_add_emotional_particles(display, photo["color"])
		_:
			# Fallback default
			_add_figure_silhouette(display, 0, 0.8, photo["color"])

	# Enhanced vignette effect with corners
	_add_photo_vignette(display)

	# Corner decorations
	_add_corner_decorations(display, photo["color"])


func _add_figure_silhouette(parent: Node2D, x_pos: float, height_factor: float, base_color: Color) -> void:
	var height = 60 * height_factor
	var width = 20 * height_factor

	var figure = Polygon2D.new()
	figure.polygon = PackedVector2Array([
		Vector2(x_pos - width/2, 50),
		Vector2(x_pos - width/2, 50 - height * 0.7),
		Vector2(x_pos - width/3, 50 - height * 0.75),
		Vector2(x_pos, 50 - height),  # Head top
		Vector2(x_pos + width/3, 50 - height * 0.75),
		Vector2(x_pos + width/2, 50 - height * 0.7),
		Vector2(x_pos + width/2, 50)
	])
	figure.color = base_color.lightened(0.2)
	figure.color.a = 0.7
	parent.add_child(figure)


func _add_star_elements(parent: Node2D, base_color: Color) -> void:
	var star_positions = [
		Vector2(-80, -50), Vector2(-40, -40), Vector2(20, -55),
		Vector2(60, -35), Vector2(80, -50), Vector2(-60, -30)
	]
	for pos in star_positions:
		var star = Polygon2D.new()
		var star_points = PackedVector2Array()
		for i in range(5):
			var angle = -PI/2 + (i / 5.0) * TAU
			star_points.append(Vector2(pos.x + cos(angle) * 4, pos.y + sin(angle) * 4))
			var inner_angle = -PI/2 + ((i + 0.5) / 5.0) * TAU
			star_points.append(Vector2(pos.x + cos(inner_angle) * 2, pos.y + sin(inner_angle) * 2))
		star.polygon = star_points
		star.color = base_color.lightened(0.4)
		star.color.a = 0.8
		parent.add_child(star)


func _add_workshop_elements(parent: Node2D, base_color: Color) -> void:
	# Geometric shapes representing inventions
	var shapes = [
		{"pos": Vector2(40, 20), "size": 15},
		{"pos": Vector2(60, 0), "size": 12},
		{"pos": Vector2(70, 30), "size": 10}
	]
	for shape in shapes:
		var rect = Polygon2D.new()
		var s = shape["size"]
		rect.polygon = PackedVector2Array([
			Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)
		])
		rect.position = shape["pos"]
		rect.rotation = randf() * 0.5
		rect.color = base_color.lightened(0.1)
		rect.color.a = 0.5
		parent.add_child(rect)


func _add_nebula_elements(parent: Node2D, base_color: Color) -> void:
	# Swirling nebula clouds
	for i in range(8):
		var cloud = Polygon2D.new()
		var points = PackedVector2Array()
		var center = Vector2(randf_range(-80, 80), randf_range(-50, 50))
		var radius = randf_range(20, 40)
		for j in range(8):
			var angle = (j / 8.0) * TAU
			var r = radius * (0.8 + randf() * 0.4)
			points.append(center + Vector2(cos(angle) * r, sin(angle) * r * 0.6))
		cloud.polygon = points
		cloud.color = base_color.lightened(randf() * 0.3)
		cloud.color.a = 0.3
		parent.add_child(cloud)


func _add_garden_elements(parent: Node2D, base_color: Color) -> void:
	# Simple plant shapes
	var plant_positions = [Vector2(40, 40), Vector2(60, 35), Vector2(80, 45)]
	for pos in plant_positions:
		# Stem
		var stem = Polygon2D.new()
		stem.polygon = PackedVector2Array([
			Vector2(-2, 0), Vector2(2, 0), Vector2(1, -30), Vector2(-1, -30)
		])
		stem.position = pos
		stem.color = Color(0.3, 0.5, 0.3, 0.7)
		parent.add_child(stem)

		# Leaves
		var leaf = Polygon2D.new()
		leaf.polygon = PackedVector2Array([
			Vector2(0, -25), Vector2(10, -15), Vector2(8, -10), Vector2(0, -15),
			Vector2(-8, -10), Vector2(-10, -15)
		])
		leaf.position = pos
		leaf.color = base_color.lightened(0.1)
		leaf.color.a = 0.6
		parent.add_child(leaf)


# =============================================================================
# ENHANCED PHOTO VISUAL ELEMENTS
# =============================================================================

func _add_figure_detailed(parent: Node2D, x_pos: float, height_factor: float, base_color: Color, figure_type: String) -> void:
	var height = 65 * height_factor
	var width = 22 * height_factor

	var figure = Polygon2D.new()

	match figure_type:
		"adult", "adult_dress":
			# Taller adult figure with more detail
			figure.polygon = PackedVector2Array([
				Vector2(x_pos - width/2, 55),
				Vector2(x_pos - width/2, 55 - height * 0.65),
				Vector2(x_pos - width/2.5, 55 - height * 0.7),
				Vector2(x_pos - width/3, 55 - height * 0.85),
				Vector2(x_pos, 55 - height),  # Head
				Vector2(x_pos + width/3, 55 - height * 0.85),
				Vector2(x_pos + width/2.5, 55 - height * 0.7),
				Vector2(x_pos + width/2, 55 - height * 0.65),
				Vector2(x_pos + width/2, 55)
			])
			if figure_type == "adult_dress":
				# Add dress flare at bottom
				figure.polygon[0] = Vector2(x_pos - width * 0.8, 55)
				figure.polygon[8] = Vector2(x_pos + width * 0.8, 55)
		"child", "child_small", "child_coat":
			# Smaller child figure
			figure.polygon = PackedVector2Array([
				Vector2(x_pos - width/2, 55),
				Vector2(x_pos - width/2, 55 - height * 0.6),
				Vector2(x_pos - width/3, 55 - height * 0.75),
				Vector2(x_pos, 55 - height),
				Vector2(x_pos + width/3, 55 - height * 0.75),
				Vector2(x_pos + width/2, 55 - height * 0.6),
				Vector2(x_pos + width/2, 55)
			])
		"adult_goggles":
			# Adult with goggles pushed up (slight head accent)
			figure.polygon = PackedVector2Array([
				Vector2(x_pos - width/2, 55),
				Vector2(x_pos - width/2, 55 - height * 0.65),
				Vector2(x_pos - width/3, 55 - height * 0.85),
				Vector2(x_pos - width/4, 55 - height * 1.05),  # Goggles
				Vector2(x_pos, 55 - height),
				Vector2(x_pos + width/4, 55 - height * 1.05),
				Vector2(x_pos + width/3, 55 - height * 0.85),
				Vector2(x_pos + width/2, 55 - height * 0.65),
				Vector2(x_pos + width/2, 55)
			])
		"lyra":
			# Lyra with flowing hair indication
			figure.polygon = PackedVector2Array([
				Vector2(x_pos - width/2, 55),
				Vector2(x_pos - width/2, 55 - height * 0.6),
				Vector2(x_pos - width/3, 55 - height * 0.75),
				Vector2(x_pos - width/4, 55 - height * 0.9),
				Vector2(x_pos, 55 - height),
				Vector2(x_pos + width/4, 55 - height * 0.9),
				Vector2(x_pos + width/3, 55 - height * 0.75),
				Vector2(x_pos + width/2, 55 - height * 0.6),
				Vector2(x_pos + width * 0.7, 55 - height * 0.5),  # Hair flow
				Vector2(x_pos + width/2, 55)
			])
		_:
			figure.polygon = PackedVector2Array([
				Vector2(x_pos - width/2, 55),
				Vector2(x_pos - width/2, 55 - height * 0.7),
				Vector2(x_pos, 55 - height),
				Vector2(x_pos + width/2, 55 - height * 0.7),
				Vector2(x_pos + width/2, 55)
			])

	figure.color = base_color.lightened(0.25)
	figure.color.a = 0.75
	parent.add_child(figure)


func _add_figure_sitting(parent: Node2D, x_pos: float, base_color: Color, figure_type: String) -> void:
	var figure = Polygon2D.new()
	var is_adult = figure_type == "adult"
	var scale = 1.0 if is_adult else 0.7

	figure.polygon = PackedVector2Array([
		Vector2(x_pos - 15 * scale, 55),
		Vector2(x_pos - 20 * scale, 30),  # Seated position
		Vector2(x_pos - 12 * scale, 10),
		Vector2(x_pos, -15 * scale),  # Head
		Vector2(x_pos + 12 * scale, 10),
		Vector2(x_pos + 20 * scale, 30),
		Vector2(x_pos + 15 * scale, 55)
	])
	figure.color = base_color.lightened(0.2)
	figure.color.a = 0.7
	parent.add_child(figure)


func _add_figure_kneeling(parent: Node2D, x_pos: float, base_color: Color) -> void:
	var figure = Polygon2D.new()
	figure.polygon = PackedVector2Array([
		Vector2(x_pos - 18, 55),
		Vector2(x_pos - 25, 35),  # Kneeling
		Vector2(x_pos - 15, 15),
		Vector2(x_pos - 5, -5),
		Vector2(x_pos + 5, -15),  # Head leaning forward
		Vector2(x_pos + 15, 0),
		Vector2(x_pos + 20, 25),
		Vector2(x_pos + 15, 55)
	])
	figure.color = base_color.lightened(0.2)
	figure.color.a = 0.7
	parent.add_child(figure)


func _add_figure_sitting_reading(parent: Node2D, x_pos: float, base_color: Color) -> void:
	var figure = Polygon2D.new()
	figure.polygon = PackedVector2Array([
		Vector2(x_pos - 12, 55),
		Vector2(x_pos - 18, 25),
		Vector2(x_pos - 10, 5),
		Vector2(x_pos, -20),
		Vector2(x_pos + 10, 5),
		Vector2(x_pos + 18, 25),
		Vector2(x_pos + 12, 55)
	])
	figure.color = base_color.lightened(0.2)
	figure.color.a = 0.7
	parent.add_child(figure)


func _add_figure_in_bed(parent: Node2D, x_pos: float, base_color: Color) -> void:
	# Bed shape
	var bed = Polygon2D.new()
	bed.polygon = PackedVector2Array([
		Vector2(x_pos - 30, 55), Vector2(x_pos + 40, 55),
		Vector2(x_pos + 40, 30), Vector2(x_pos - 30, 30)
	])
	bed.color = base_color.darkened(0.3)
	bed.color.a = 0.5
	parent.add_child(bed)

	# Child in bed (just head visible)
	var head = Polygon2D.new()
	var head_points = PackedVector2Array()
	for i in range(8):
		var angle = (i / 8.0) * TAU
		head_points.append(Vector2(x_pos + cos(angle) * 10, 25 + sin(angle) * 8))
	head.polygon = head_points
	head.color = base_color.lightened(0.3)
	head.color.a = 0.7
	parent.add_child(head)


func _add_figure_at_window(parent: Node2D, base_color: Color) -> void:
	var figure = Polygon2D.new()
	figure.polygon = PackedVector2Array([
		Vector2(-70, 55), Vector2(-75, 30), Vector2(-65, 10),
		Vector2(-60, -5), Vector2(-55, 10), Vector2(-50, 30), Vector2(-55, 55)
	])
	figure.color = Color(0.1, 0.1, 0.15, 0.9)
	parent.add_child(figure)


func _add_ship_silhouette(parent: Node2D, x_pos: float, base_color: Color) -> void:
	var ship = Polygon2D.new()
	ship.polygon = PackedVector2Array([
		Vector2(x_pos - 30, 60), Vector2(x_pos - 25, 40), Vector2(x_pos - 35, 20),
		Vector2(x_pos - 20, -30), Vector2(x_pos + 10, -45),  # Nose
		Vector2(x_pos + 40, -30), Vector2(x_pos + 50, 10),
		Vector2(x_pos + 45, 40), Vector2(x_pos + 35, 60)
	])
	ship.color = Color(0.6, 0.65, 0.7, 0.6)
	parent.add_child(ship)

	# Ship glow
	var glow = Polygon2D.new()
	glow.polygon = ship.polygon
	glow.color = base_color.lightened(0.4)
	glow.color.a = 0.15
	glow.scale = Vector2(1.1, 1.1)
	glow.z_index = -1
	parent.add_child(glow)


func _add_spires(parent: Node2D, base_color: Color) -> void:
	for i in range(2):
		var spire = Polygon2D.new()
		var x = -85 + i * 25
		spire.polygon = PackedVector2Array([
			Vector2(x - 4, 60), Vector2(x - 5, 20), Vector2(x, -20),
			Vector2(x + 5, 20), Vector2(x + 4, 60)
		])
		spire.color = base_color.darkened(0.4)
		spire.color.a = 0.4
		parent.add_child(spire)


func _add_sunset_rays(parent: Node2D, base_color: Color) -> void:
	for i in range(5):
		var ray = Polygon2D.new()
		var angle = -0.6 + i * 0.3
		ray.polygon = PackedVector2Array([
			Vector2(-110, -70), Vector2(-110 + cos(angle) * 30, -70 + sin(angle) * 80),
			Vector2(-110 + cos(angle) * 35, -70 + sin(angle) * 85), Vector2(-110, -65)
		])
		ray.color = Color(1.0, 0.8, 0.4, 0.15)
		ray.z_index = -1
		parent.add_child(ray)


func _add_house_silhouette(parent: Node2D, base_color: Color) -> void:
	var house = Polygon2D.new()
	house.polygon = PackedVector2Array([
		Vector2(-90, 60), Vector2(-95, 20), Vector2(-80, -10),
		Vector2(-50, -25), Vector2(-20, -15), Vector2(-10, 10),
		Vector2(-15, 60)
	])
	house.color = base_color.darkened(0.5)
	house.color.a = 0.4
	parent.add_child(house)


func _add_glowing_flowers(parent: Node2D, base_color: Color) -> void:
	var positions = [Vector2(-80, 50), Vector2(-60, 55), Vector2(-40, 52), Vector2(60, 55), Vector2(80, 50)]
	for pos in positions:
		var flower = Polygon2D.new()
		var points = PackedVector2Array()
		for i in range(6):
			var angle = (i / 6.0) * TAU
			points.append(pos + Vector2(cos(angle) * 6, sin(angle) * 6))
		flower.polygon = points
		flower.color = Color(0.4, 0.6, 0.9, 0.5)
		parent.add_child(flower)

		# Glow
		var glow = Polygon2D.new()
		glow.polygon = points
		glow.color = Color(0.5, 0.7, 1.0, 0.2)
		glow.scale = Vector2(1.5, 1.5)
		glow.position = pos - pos  # Reset to origin then position
		glow.z_index = -1
		parent.add_child(glow)


func _add_family_crest(parent: Node2D, base_color: Color) -> void:
	var crest = Polygon2D.new()
	var crest_points = PackedVector2Array()
	for i in range(6):
		var angle = -PI/2 + (i / 6.0) * TAU
		crest_points.append(Vector2(-55 + cos(angle) * 10, -35 + sin(angle) * 10))
	crest.polygon = crest_points
	crest.color = Color(0.8, 0.7, 0.4, 0.6)
	parent.add_child(crest)


func _add_corridor_perspective(parent: Node2D, base_color: Color) -> void:
	# Converging corridor lines
	var left_wall = Polygon2D.new()
	left_wall.polygon = PackedVector2Array([
		Vector2(-110, -70), Vector2(-40, -30), Vector2(-40, 30), Vector2(-110, 70)
	])
	left_wall.color = base_color.darkened(0.4)
	left_wall.color.a = 0.5
	parent.add_child(left_wall)

	var right_wall = Polygon2D.new()
	right_wall.polygon = PackedVector2Array([
		Vector2(110, -70), Vector2(40, -30), Vector2(40, 30), Vector2(110, 70)
	])
	right_wall.color = base_color.darkened(0.35)
	right_wall.color.a = 0.5
	parent.add_child(right_wall)


func _add_hologram_glow(parent: Node2D, x_pos: float, base_color: Color) -> void:
	var glow = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(10):
		var angle = (i / 10.0) * TAU
		points.append(Vector2(x_pos + cos(angle) * 15, 20 + sin(angle) * 20))
	glow.polygon = points
	glow.color = Color(1.0, 0.7, 0.3, 0.4)
	parent.add_child(glow)


func _add_floor_lights(parent: Node2D, base_color: Color) -> void:
	for i in range(5):
		var light = Polygon2D.new()
		var x = -60 + i * 30
		light.polygon = PackedVector2Array([
			Vector2(x - 8, 65), Vector2(x + 8, 65), Vector2(x + 6, 55), Vector2(x - 6, 55)
		])
		light.color = Color(0.3, 0.5, 0.8, 0.6)
		parent.add_child(light)


func _add_window_frame(parent: Node2D, base_color: Color) -> void:
	var frame = Polygon2D.new()
	frame.polygon = PackedVector2Array([
		Vector2(-100, -60), Vector2(100, -60), Vector2(100, 60), Vector2(-100, 60),
		Vector2(-100, -60), Vector2(-90, -50), Vector2(-90, 50), Vector2(-100, 60),
		Vector2(100, 60), Vector2(90, 50), Vector2(90, -50), Vector2(100, -60)
	])
	frame.color = Color(0.15, 0.12, 0.1, 0.8)
	parent.add_child(frame)


func _add_constellation(parent: Node2D, base_color: Color) -> void:
	# Six aspect stars in constellation pattern
	var star_positions = [
		Vector2(-20, -45), Vector2(10, -50), Vector2(35, -40),
		Vector2(50, -55), Vector2(70, -45), Vector2(85, -50)
	]
	for i in range(star_positions.size()):
		var pos = star_positions[i]
		var star = Polygon2D.new()
		var points = PackedVector2Array()
		for j in range(5):
			var angle = -PI/2 + (j / 5.0) * TAU
			points.append(pos + Vector2(cos(angle) * 5, sin(angle) * 5))
			var inner_angle = -PI/2 + ((j + 0.5) / 5.0) * TAU
			points.append(pos + Vector2(cos(inner_angle) * 2, sin(inner_angle) * 2))
		star.polygon = points
		star.color = Color(0.95, 0.9, 0.7, 0.9)
		parent.add_child(star)

		# Connect with lines
		if i > 0:
			var line = Polygon2D.new()
			var prev = star_positions[i - 1]
			var dir = (pos - prev).normalized()
			var perp = Vector2(-dir.y, dir.x) * 0.5
			line.polygon = PackedVector2Array([
				prev + perp, pos + perp, pos - perp, prev - perp
			])
			line.color = Color(0.7, 0.7, 0.9, 0.3)
			line.z_index = -1
			parent.add_child(line)


func _add_comet(parent: Node2D, base_color: Color) -> void:
	var comet = Polygon2D.new()
	comet.polygon = PackedVector2Array([
		Vector2(-80, -60), Vector2(-70, -55), Vector2(-50, -50),
		Vector2(-70, -58), Vector2(-80, -60)
	])
	comet.color = Color(0.9, 0.9, 1.0, 0.7)
	parent.add_child(comet)

	var tail = Polygon2D.new()
	tail.polygon = PackedVector2Array([
		Vector2(-80, -60), Vector2(-100, -65), Vector2(-95, -62),
		Vector2(-85, -58), Vector2(-80, -60)
	])
	tail.color = Color(0.7, 0.8, 1.0, 0.4)
	parent.add_child(tail)


func _add_nebula_wisps(parent: Node2D, base_color: Color) -> void:
	for i in range(4):
		var wisp = Polygon2D.new()
		var points = PackedVector2Array()
		var cx = randf_range(-60, 60)
		var cy = randf_range(-30, 30)
		for j in range(6):
			var angle = (j / 6.0) * TAU
			var r = randf_range(15, 25)
			points.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r * 0.6))
		wisp.polygon = points
		wisp.color = Color(base_color.r, base_color.g, base_color.b + 0.2, 0.15)
		wisp.z_index = -1
		parent.add_child(wisp)


func _add_portrait_focus(parent: Node2D, base_color: Color) -> void:
	# Soft focus background
	var bg = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		points.append(Vector2(cos(angle) * 100, sin(angle) * 65))
	bg.polygon = points
	bg.color = base_color.lightened(0.1)
	bg.color.a = 0.2
	bg.z_index = -1
	parent.add_child(bg)


func _add_holo_butterfly(parent: Node2D, base_color: Color) -> void:
	var butterfly = Node2D.new()
	butterfly.position = Vector2(40, -20)

	# Wings
	for side in [-1, 1]:
		var wing = Polygon2D.new()
		wing.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(side * 12, -8), Vector2(side * 15, -3),
			Vector2(side * 10, 5), Vector2(side * 5, 3)
		])
		wing.color = Color(0.6, 0.8, 1.0, 0.7)
		butterfly.add_child(wing)

	parent.add_child(butterfly)


func _add_hair_flow(parent: Node2D, base_color: Color) -> void:
	var hair = Polygon2D.new()
	hair.polygon = PackedVector2Array([
		Vector2(10, -20), Vector2(25, -10), Vector2(35, 10),
		Vector2(30, 25), Vector2(20, 15), Vector2(15, 0), Vector2(10, -20)
	])
	hair.color = Color(0.5, 0.3, 0.6, 0.5)  # Violet hair
	parent.add_child(hair)


func _add_pendant_glow(parent: Node2D, pos: Vector2, base_color: Color) -> void:
	var pendant = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(6):
		var angle = (i / 6.0) * TAU
		points.append(pos + Vector2(cos(angle) * 4, sin(angle) * 4))
	pendant.polygon = points
	pendant.color = Color(0.9, 0.8, 0.4, 0.8)
	parent.add_child(pendant)

	var glow = Polygon2D.new()
	glow.polygon = points
	glow.color = Color(1.0, 0.9, 0.5, 0.3)
	glow.scale = Vector2(2.5, 2.5)
	glow.z_index = -1
	parent.add_child(glow)


func _add_workbench(parent: Node2D, base_color: Color) -> void:
	var bench = Polygon2D.new()
	bench.polygon = PackedVector2Array([
		Vector2(10, 60), Vector2(100, 60), Vector2(100, 35), Vector2(10, 35)
	])
	bench.color = base_color.darkened(0.3)
	bench.color.a = 0.7
	parent.add_child(bench)


func _add_holo_blueprints(parent: Node2D, base_color: Color) -> void:
	for i in range(3):
		var bp = Polygon2D.new()
		var x = 30 + i * 25
		var y = -20 + i * 10
		bp.polygon = PackedVector2Array([
			Vector2(x - 12, y - 10), Vector2(x + 12, y - 10),
			Vector2(x + 12, y + 10), Vector2(x - 12, y + 10)
		])
		bp.color = Color(0.3, 0.7, 1.0, 0.4)
		bp.rotation = randf_range(-0.2, 0.2)
		parent.add_child(bp)


func _add_console_glow(parent: Node2D, base_color: Color) -> void:
	var console = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(8):
		var angle = (i / 8.0) * TAU
		points.append(Vector2(55 + cos(angle) * 18, 30 + sin(angle) * 12))
	console.polygon = points
	console.color = Color(0.4, 0.8, 1.0, 0.6)
	parent.add_child(console)

	var inner = Polygon2D.new()
	inner.polygon = points
	inner.color = Color(0.6, 0.9, 1.0, 0.3)
	inner.scale = Vector2(1.5, 1.5)
	inner.z_index = -1
	parent.add_child(inner)


func _add_tools_wall(parent: Node2D, base_color: Color) -> void:
	for i in range(4):
		var tool_shape = Polygon2D.new()
		var x = 70 + (i % 2) * 20
		var y = -50 + (i / 2) * 25
		tool_shape.polygon = PackedVector2Array([
			Vector2(x - 2, y - 10), Vector2(x + 2, y - 10),
			Vector2(x + 2, y + 10), Vector2(x - 2, y + 10)
		])
		tool_shape.color = Color(0.5, 0.5, 0.55, 0.5)
		parent.add_child(tool_shape)


func _add_party_background(parent: Node2D, base_color: Color) -> void:
	# Streamers
	for i in range(5):
		var streamer = Polygon2D.new()
		var x = -80 + i * 40
		streamer.polygon = PackedVector2Array([
			Vector2(x, -60), Vector2(x + 5, -60),
			Vector2(x + 8, 0), Vector2(x + 3, 0)
		])
		streamer.color = Color(randf(), randf(), randf(), 0.4)
		parent.add_child(streamer)


func _add_cake_with_candles(parent: Node2D, base_color: Color) -> void:
	# Cake
	var cake = Polygon2D.new()
	cake.polygon = PackedVector2Array([
		Vector2(-25, 55), Vector2(25, 55), Vector2(22, 35), Vector2(-22, 35)
	])
	cake.color = Color(0.85, 0.75, 0.6, 0.8)
	parent.add_child(cake)

	# Candles with spiral flames
	for i in range(3):
		var x = -12 + i * 12
		var candle = Polygon2D.new()
		candle.polygon = PackedVector2Array([
			Vector2(x - 2, 35), Vector2(x + 2, 35), Vector2(x + 2, 25), Vector2(x - 2, 25)
		])
		candle.color = Color(0.9, 0.9, 0.95, 0.9)
		parent.add_child(candle)

		# Flame
		var flame = Polygon2D.new()
		flame.polygon = PackedVector2Array([
			Vector2(x - 3, 25), Vector2(x, 15), Vector2(x + 3, 25)
		])
		flame.color = Color(1.0, 0.7, 0.2, 0.9)
		parent.add_child(flame)


func _add_floating_lanterns(parent: Node2D, base_color: Color) -> void:
	var positions = [Vector2(-60, -40), Vector2(-30, -50), Vector2(20, -45), Vector2(60, -35)]
	for pos in positions:
		var lantern = Polygon2D.new()
		var points = PackedVector2Array()
		for i in range(6):
			var angle = (i / 6.0) * TAU
			points.append(pos + Vector2(cos(angle) * 8, sin(angle) * 10))
		lantern.polygon = points
		lantern.color = Color(1.0, 0.8, 0.4, 0.6)
		parent.add_child(lantern)


func _add_garden_background(parent: Node2D, base_color: Color) -> void:
	# Viewport with stars
	var viewport = Polygon2D.new()
	viewport.polygon = PackedVector2Array([
		Vector2(40, -50), Vector2(90, -50), Vector2(90, 20), Vector2(40, 20)
	])
	viewport.color = Color(0.05, 0.05, 0.15, 0.8)
	parent.add_child(viewport)

	# A few stars in viewport
	for i in range(4):
		var star = Polygon2D.new()
		star.polygon = PackedVector2Array([
			Vector2(-2, 0), Vector2(0, -2), Vector2(2, 0), Vector2(0, 2)
		])
		star.position = Vector2(randf_range(45, 85), randf_range(-45, 15))
		star.color = Color(0.9, 0.9, 1.0, 0.7)
		parent.add_child(star)


func _add_crystal_flowers(parent: Node2D, base_color: Color) -> void:
	var positions = [Vector2(-70, 45), Vector2(-50, 50), Vector2(20, 48)]
	for pos in positions:
		var crystal = Polygon2D.new()
		crystal.polygon = PackedVector2Array([
			Vector2(0, -15), Vector2(5, 0), Vector2(3, 8),
			Vector2(-3, 8), Vector2(-5, 0)
		])
		crystal.position = pos
		crystal.color = Color(0.5, 0.8, 0.9, 0.7)
		parent.add_child(crystal)

		var glow = Polygon2D.new()
		glow.polygon = crystal.polygon
		glow.position = pos
		glow.color = Color(0.6, 0.9, 1.0, 0.2)
		glow.scale = Vector2(1.5, 1.5)
		glow.z_index = -1
		parent.add_child(glow)


func _add_glowing_plants(parent: Node2D, base_color: Color) -> void:
	var positions = [Vector2(-85, 55), Vector2(50, 55), Vector2(70, 50)]
	for pos in positions:
		var plant = Polygon2D.new()
		plant.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(-5, -15), Vector2(0, -25),
			Vector2(5, -15), Vector2(0, 0)
		])
		plant.position = pos
		plant.color = Color(0.4, 0.7, 0.3, 0.7)
		parent.add_child(plant)


func _add_fountain(parent: Node2D, base_color: Color) -> void:
	var fountain = Polygon2D.new()
	fountain.polygon = PackedVector2Array([
		Vector2(60, 55), Vector2(80, 55), Vector2(78, 40),
		Vector2(70, 35), Vector2(62, 40)
	])
	fountain.color = Color(0.4, 0.45, 0.5, 0.6)
	parent.add_child(fountain)

	# Water drops
	for i in range(3):
		var drop = Polygon2D.new()
		drop.polygon = PackedVector2Array([
			Vector2(68 + i * 3, 30), Vector2(70 + i * 3, 25), Vector2(72 + i * 3, 30)
		])
		drop.color = Color(0.4, 0.6, 0.8, 0.5)
		parent.add_child(drop)


func _add_nebula_storm(parent: Node2D, base_color: Color) -> void:
	for i in range(6):
		var cloud = Polygon2D.new()
		var points = PackedVector2Array()
		var cx = randf_range(-80, 80)
		var cy = randf_range(-50, 40)
		for j in range(8):
			var angle = (j / 8.0) * TAU
			var r = randf_range(25, 45)
			points.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r * 0.7))
		cloud.polygon = points
		cloud.color = Color(base_color.r, base_color.g * 0.8, base_color.b * 0.6, 0.35)
		parent.add_child(cloud)


func _add_lightning_arcs(parent: Node2D, base_color: Color) -> void:
	for i in range(2):
		var arc = Polygon2D.new()
		var x1 = randf_range(-60, 60)
		var x2 = x1 + randf_range(-30, 30)
		arc.polygon = PackedVector2Array([
			Vector2(x1, -50), Vector2(x1 + 3, -30), Vector2(x2, -10),
			Vector2(x2 + 2, 10), Vector2(x2 - 2, 10), Vector2(x2 - 2, -10),
			Vector2(x1 - 3, -30), Vector2(x1 - 2, -50)
		])
		arc.color = Color(1.0, 0.95, 0.6, 0.6)
		parent.add_child(arc)


func _add_emergency_glow(parent: Node2D, base_color: Color) -> void:
	var glow = Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-110, 70), Vector2(110, 70), Vector2(110, 50), Vector2(-110, 50)
	])
	glow.color = Color(1.0, 0.6, 0.2, 0.3)
	parent.add_child(glow)


func _add_cozy_room(parent: Node2D, base_color: Color) -> void:
	# Warm ambient glow
	var glow = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		points.append(Vector2(cos(angle) * 90, sin(angle) * 55))
	glow.polygon = points
	glow.color = Color(1.0, 0.9, 0.7, 0.1)
	glow.z_index = -1
	parent.add_child(glow)


func _add_holo_book_glow(parent: Node2D, base_color: Color) -> void:
	var book = Polygon2D.new()
	book.polygon = PackedVector2Array([
		Vector2(-5, 10), Vector2(15, 5), Vector2(15, -15), Vector2(-5, -10)
	])
	book.color = Color(0.4, 0.6, 0.9, 0.6)
	parent.add_child(book)

	var glow = Polygon2D.new()
	glow.polygon = book.polygon
	glow.color = Color(0.5, 0.7, 1.0, 0.2)
	glow.scale = Vector2(1.8, 1.8)
	glow.z_index = -1
	parent.add_child(glow)


func _add_warm_light(parent: Node2D, base_color: Color) -> void:
	var light = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(10):
		var angle = (i / 10.0) * TAU
		points.append(Vector2(-20 + cos(angle) * 40, sin(angle) * 30))
	light.polygon = points
	light.color = Color(1.0, 0.85, 0.6, 0.15)
	light.z_index = -1
	parent.add_child(light)


func _add_planet_view(parent: Node2D, base_color: Color) -> void:
	var planet = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(16):
		var angle = (i / 16.0) * TAU
		points.append(Vector2(20 + cos(angle) * 55, sin(angle) * 50))
	planet.polygon = points
	planet.color = Color(0.3, 0.5, 0.6, 0.8)
	parent.add_child(planet)

	# Cloud swirls
	for i in range(3):
		var swirl = Polygon2D.new()
		var swirl_points = PackedVector2Array()
		var cy = -20 + i * 20
		for j in range(8):
			var x = -20 + j * 8
			swirl_points.append(Vector2(20 + x, cy + sin(x * 0.2) * 5))
		for j in range(8):
			var x = 36 - j * 8
			swirl_points.append(Vector2(20 + x, cy + sin(x * 0.2) * 5 + 4))
		swirl.polygon = swirl_points
		swirl.color = Color(0.5, 0.7, 0.8, 0.4)
		parent.add_child(swirl)


func _add_rings(parent: Node2D, base_color: Color) -> void:
	var ring = Polygon2D.new()
	ring.polygon = PackedVector2Array([
		Vector2(-50, -5), Vector2(90, -15), Vector2(95, -12),
		Vector2(-45, 2), Vector2(-50, -5)
	])
	ring.color = Color(0.7, 0.75, 0.8, 0.5)
	parent.add_child(ring)


func _add_three_suns(parent: Node2D, base_color: Color) -> void:
	var positions = [Vector2(-85, -55), Vector2(-70, -60), Vector2(-55, -52)]
	var sizes = [6, 4, 5]
	for i in range(3):
		var sun = Polygon2D.new()
		var points = PackedVector2Array()
		for j in range(8):
			var angle = (j / 8.0) * TAU
			points.append(positions[i] + Vector2(cos(angle) * sizes[i], sin(angle) * sizes[i]))
		sun.polygon = points
		sun.color = Color(1.0, 0.95, 0.8, 0.9)
		parent.add_child(sun)


func _add_hologram_figures(parent: Node2D, base_color: Color) -> void:
	# Dad figure
	var dad = Polygon2D.new()
	dad.polygon = PackedVector2Array([
		Vector2(-25, 50), Vector2(-25, -10), Vector2(-15, -30),
		Vector2(-5, -35), Vector2(5, -30), Vector2(5, 50)
	])
	dad.color = Color(0.4, 0.6, 0.8, 0.6)
	parent.add_child(dad)

	# Lyra figure
	var lyra = Polygon2D.new()
	lyra.polygon = PackedVector2Array([
		Vector2(15, 50), Vector2(15, 10), Vector2(22, -5),
		Vector2(30, -10), Vector2(38, -5), Vector2(40, 50)
	])
	lyra.color = Color(0.5, 0.4, 0.7, 0.6)
	parent.add_child(lyra)

	# Hologram scanlines
	for i in range(8):
		var line = Polygon2D.new()
		var y = -30 + i * 12
		line.polygon = PackedVector2Array([
			Vector2(-30, y), Vector2(45, y), Vector2(45, y + 2), Vector2(-30, y + 2)
		])
		line.color = Color(0.5, 0.7, 0.9, 0.1)
		parent.add_child(line)


func _add_nebula_background(parent: Node2D, base_color: Color) -> void:
	for i in range(4):
		var cloud = Polygon2D.new()
		var points = PackedVector2Array()
		var cx = randf_range(50, 90)
		var cy = randf_range(-40, 30)
		for j in range(6):
			var angle = (j / 6.0) * TAU
			var r = randf_range(15, 30)
			points.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r * 0.6))
		cloud.polygon = points
		cloud.color = Color(0.6, 0.3, 0.4, 0.25)
		cloud.z_index = -1
		parent.add_child(cloud)


func _add_emotional_particles(parent: Node2D, base_color: Color) -> void:
	for i in range(10):
		var particle = Polygon2D.new()
		var size = randf_range(2, 4)
		particle.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(0, -size), Vector2(size, 0), Vector2(0, size)
		])
		particle.position = Vector2(randf_range(-90, 90), randf_range(-50, 50))
		particle.color = Color(0.8, 0.7, 0.5, randf_range(0.3, 0.6))
		parent.add_child(particle)


func _add_photo_vignette(parent: Node2D) -> void:
	# Corner shadows for vignette effect
	var corners = [
		{"pos": Vector2(-110, -70), "rot": 0},
		{"pos": Vector2(110, -70), "rot": PI/2},
		{"pos": Vector2(110, 70), "rot": PI},
		{"pos": Vector2(-110, 70), "rot": -PI/2}
	]
	for corner in corners:
		var shadow = Polygon2D.new()
		shadow.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(40, 0), Vector2(40, 5), Vector2(5, 5),
			Vector2(5, 40), Vector2(0, 40)
		])
		shadow.position = corner["pos"]
		shadow.rotation = corner["rot"]
		shadow.color = Color(0, 0, 0, 0.3)
		parent.add_child(shadow)


func _add_corner_decorations(parent: Node2D, base_color: Color) -> void:
	# Ornate corner accents
	var corners = [Vector2(-125, -85), Vector2(125, -85), Vector2(125, 85), Vector2(-125, 85)]
	for i in range(4):
		var corner = Polygon2D.new()
		var size = 12
		var pos = corners[i]
		var x_dir = 1 if i == 0 or i == 3 else -1
		var y_dir = 1 if i < 2 else -1

		corner.polygon = PackedVector2Array([
			pos,
			pos + Vector2(x_dir * size, 0),
			pos + Vector2(x_dir * size * 0.7, y_dir * size * 0.3),
			pos + Vector2(x_dir * size * 0.3, y_dir * size * 0.7),
			pos + Vector2(0, y_dir * size)
		])
		corner.color = Color(0.75, 0.6, 0.35, 0.7)
		parent.add_child(corner)


func _update_photo_album(delta: float) -> void:
	photo_album_time += delta

	if not photo_album_panel:
		return

	# Animate photo visual elements
	var detail_panel = photo_album_panel.get_node_or_null("ContentArea/PhotoDetailPanel")
	if detail_panel:
		var photo_display = detail_panel.find_child("PhotoDisplay", true, false)
		if photo_display:
			var visual = photo_display.get_node_or_null("PhotoVisual")
			if visual:
				# Subtle floating animation
				visual.position.y = 100 + sin(photo_album_time * 0.8) * 2


func _play_photo_voiceover() -> void:
	## Play the voiceover for the currently selected photo
	if selected_photo_index < 0 or selected_photo_index >= PHOTOS_DATA.size():
		return

	var photo = PHOTOS_DATA[selected_photo_index]
	var voiceover_path = photo.get("voiceover", "")

	if voiceover_path == "" or not FileAccess.file_exists(voiceover_path):
		return

	# Get voice controls to update status
	if photo_album_panel:
		var voice_controls = photo_album_panel.find_child("VoiceoverControls", true, false)
		if voice_controls:
			var voice_btn = voice_controls.get_node_or_null("PlayVoiceoverBtn")
			var voice_status = voice_controls.get_node_or_null("VoiceoverStatus")

			if voice_btn:
				voice_btn.text = "⏸ Playing..."
				voice_btn.disabled = true

			if voice_status:
				voice_status.text = "Listening to " + photo["title"]

	# Play voiceover through AudioManager
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_voice"):
		audio.play_voice(voiceover_path)
		# Set timer to re-enable button (estimate based on typical voiceover length)
		var duration = photo.get("voiceover_duration", 15.0)  # Default 15 seconds
		await get_tree().create_timer(duration).timeout
		_on_voiceover_finished()
	else:
		# Fallback: just play the audio directly
		var player = AudioStreamPlayer.new()
		player.name = "VoiceoverPlayer"
		add_child(player)
		var stream = load(voiceover_path)
		if stream:
			player.stream = stream
			player.play()
			player.finished.connect(func():
				_on_voiceover_finished()
				player.queue_free()
			)


func _on_voiceover_finished() -> void:
	## Called when voiceover playback completes
	if photo_album_panel:
		var voice_controls = photo_album_panel.find_child("VoiceoverControls", true, false)
		if voice_controls:
			var voice_btn = voice_controls.get_node_or_null("PlayVoiceoverBtn")
			var voice_status = voice_controls.get_node_or_null("VoiceoverStatus")

			if voice_btn:
				voice_btn.text = "▶ Listen Again"
				voice_btn.disabled = false

			if voice_status:
				voice_status.text = ""


func _close_photo_album() -> void:
	if not photo_album_panel:
		return

	# Stop any playing voiceover
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()

	_play_sfx("res://audio/sfx/book_close.wav")

	var tween = create_tween()
	tween.tween_property(photo_album_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_cleanup_photo_album)


func _cleanup_photo_album() -> void:
	if photo_album_panel:
		photo_album_panel.queue_free()
		photo_album_panel = null

	# Show the room again
	if isometric_base:
		isometric_base.visible = true

	in_dialogue = false


# =============================================================================
# SAVE GAME PANEL
# =============================================================================

var save_panel: PanelContainer = null

func _show_save_panel() -> void:
	if save_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false
	_set_interactive_labels_visible(false)  # Hide labels to prevent overlay

	# Create save panel
	save_panel = PanelContainer.new()
	save_panel.name = "SavePanel"
	save_panel.z_index = 150  # High z-index to be above other elements

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.98)
	style.border_color = Color(0.5, 0.4, 0.7, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	save_panel.add_theme_stylebox_override("panel", style)

	save_panel.set_anchors_preset(Control.PRESET_CENTER)
	save_panel.offset_left = -380
	save_panel.offset_right = 380
	save_panel.offset_top = -340
	save_panel.offset_bottom = 340

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	save_panel.add_child(margin)

	# Use scroll container for content
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	margin.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Save / Load Progress"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Your journey will be preserved in the Sleep Pod's memory banks"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	# Current/Active save info
	var active_save_container = _create_active_save_info()
	vbox.add_child(active_save_container)

	var sep_after_active = HSeparator.new()
	vbox.add_child(sep_after_active)

	# Save slots label
	var slots_label = Label.new()
	slots_label.text = "Save Slots"
	slots_label.add_theme_font_size_override("font_size", 16)
	slots_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	slots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(slots_label)

	# Save slots
	for i in range(1, 4):
		var slot_row = _create_save_slot_row(i)
		vbox.add_child(slot_row)

	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	# Export/Import section
	var export_label = Label.new()
	export_label.text = "Backup & Transfer"
	export_label.add_theme_font_size_override("font_size", 14)
	export_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	export_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(export_label)

	var export_row = HBoxContainer.new()
	export_row.alignment = BoxContainer.ALIGNMENT_CENTER
	export_row.add_theme_constant_override("separation", 15)
	vbox.add_child(export_row)

	var export_btn = Button.new()
	export_btn.text = "Export Save"
	export_btn.custom_minimum_size = Vector2(120, 36)
	export_btn.add_theme_font_size_override("font_size", 13)
	export_btn.add_theme_color_override("font_color", Color(0.6, 0.8, 0.9))
	export_btn.pressed.connect(_show_export_dialog)
	export_row.add_child(export_btn)

	var import_btn = Button.new()
	import_btn.text = "Import Save"
	import_btn.custom_minimum_size = Vector2(120, 36)
	import_btn.add_theme_font_size_override("font_size", 13)
	import_btn.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	import_btn.pressed.connect(_show_import_dialog)
	export_row.add_child(import_btn)

	# Quick save info
	var quick_info = Label.new()
	quick_info.text = "Auto-save is also active during gameplay"
	quick_info.add_theme_font_size_override("font_size", 11)
	quick_info.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	quick_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(quick_info)

	# Back button
	var back_btn = Button.new()
	back_btn.text = "Close"
	back_btn.custom_minimum_size = Vector2(160, 42)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_close_save_panel)
	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_child(back_btn)
	vbox.add_child(btn_container)

	add_child(save_panel)


func _create_active_save_info() -> PanelContainer:
	var container = PanelContainer.new()
	container.name = "ActiveSaveInfo"

	var active_style = StyleBoxFlat.new()
	active_style.bg_color = Color(0.1, 0.12, 0.18, 0.8)
	active_style.border_color = Color(0.4, 0.6, 0.5, 0.5)
	active_style.set_border_width_all(1)
	active_style.set_corner_radius_all(6)
	container.add_theme_stylebox_override("panel", active_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	container.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Header row
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	vbox.add_child(header_row)

	var active_icon = Label.new()
	active_icon.text = "●"
	active_icon.add_theme_font_size_override("font_size", 12)
	active_icon.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
	header_row.add_child(active_icon)

	var header_label = Label.new()
	header_label.text = "Currently Playing"
	header_label.add_theme_font_size_override("font_size", 14)
	header_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
	header_row.add_child(header_label)

	# Get current save info
	var current_slot = SaveManager.current_slot
	var info: Dictionary

	if current_slot == 0:
		# Auto-save - get info from GameManager directly
		var slot_name = "Auto-Save"
		var chapter_num = CampaignManager.get_highest_completed_chapter() + 1
		var evo_level = int(GameManager.player_data.get("world_evolution", 0))
		var sessions = CampaignManager.campaign_state.stats.total_focus_sessions
		var habits = HabitManager.get_all_habits().size()

		# Name and chapter
		var name_label = Label.new()
		name_label.text = "%s  •  Chapter %d" % [slot_name, chapter_num]
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
		vbox.add_child(name_label)

		# Stats
		var stats_label = Label.new()
		stats_label.text = "Evo %d  •  %d Focus Sessions  •  %d Habits" % [evo_level, sessions, habits]
		stats_label.add_theme_font_size_override("font_size", 13)
		stats_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75))
		vbox.add_child(stats_label)

		# Auto-save note
		var note_label = Label.new()
		note_label.text = "Progress saves automatically"
		note_label.add_theme_font_size_override("font_size", 11)
		note_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		vbox.add_child(note_label)
	else:
		# Manual slot
		info = SaveManager.get_slot_info(current_slot)
		if info.exists:
			# Name and chapter
			var name_label = Label.new()
			name_label.text = "%s  •  Chapter %d" % [info.slot_name, info.chapter_number]
			name_label.add_theme_font_size_override("font_size", 16)
			name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
			vbox.add_child(name_label)

			# Stats
			var stats_label = Label.new()
			stats_label.text = "Evo %d  •  %d Focus Sessions  •  %d Habits" % [
				info.evolution_level,
				info.focus_sessions,
				info.habits_completed
			]
			stats_label.add_theme_font_size_override("font_size", 13)
			stats_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75))
			vbox.add_child(stats_label)

			# Slot indicator
			var slot_label = Label.new()
			slot_label.text = "Loaded from Slot %d  •  Last saved: %s" % [current_slot, info.date_string]
			slot_label.add_theme_font_size_override("font_size", 11)
			slot_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
			vbox.add_child(slot_label)
		else:
			# Slot doesn't exist (shouldn't happen)
			var name_label = Label.new()
			name_label.text = "Slot %d (No data found)" % current_slot
			name_label.add_theme_font_size_override("font_size", 16)
			name_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
			vbox.add_child(name_label)

	return container


func _create_save_slot_row(slot: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var info = SaveManager.get_slot_info(slot)

	# Slot info container with multiple lines
	var info_vbox = VBoxContainer.new()
	info_vbox.custom_minimum_size = Vector2(340, 0)
	info_vbox.add_theme_constant_override("separation", 2)

	if info.exists:
		# Row 1: Slot name and chapter
		var name_label = Label.new()
		name_label.text = "%s  •  Chapter %d" % [info.slot_name, info.chapter_number]
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
		info_vbox.add_child(name_label)

		# Row 2: Stats line
		var stats_label = Label.new()
		stats_label.text = "Evo %d  •  %d Focus Sessions  •  %d Habits" % [
			info.evolution_level,
			info.focus_sessions,
			info.habits_completed
		]
		stats_label.add_theme_font_size_override("font_size", 13)
		stats_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		info_vbox.add_child(stats_label)

		# Row 3: Dates
		var dates_label = Label.new()
		var created_str = info.created_date_string if info.created_date_string != "" else "Unknown"
		dates_label.text = "Created: %s  •  Last: %s" % [created_str, info.date_string]
		dates_label.add_theme_font_size_override("font_size", 11)
		dates_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		info_vbox.add_child(dates_label)
	else:
		var empty_label = Label.new()
		empty_label.text = "Slot %d: Empty" % slot
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		info_vbox.add_child(empty_label)

		var hint_label = Label.new()
		hint_label.text = "No saved data"
		hint_label.add_theme_font_size_override("font_size", 12)
		hint_label.add_theme_color_override("font_color", Color(0.4, 0.42, 0.45))
		info_vbox.add_child(hint_label)

	row.add_child(info_vbox)

	# Button container for vertical alignment
	var btn_container = VBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 4)
	btn_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	# Top row: Save and Load
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)

	var save_btn = Button.new()
	save_btn.text = "Save"
	save_btn.custom_minimum_size = Vector2(65, 35)
	save_btn.add_theme_font_size_override("font_size", 14)
	save_btn.pressed.connect(_prompt_save_to_slot.bind(slot))
	btn_row.add_child(save_btn)

	var load_btn = Button.new()
	load_btn.text = "Load"
	load_btn.custom_minimum_size = Vector2(65, 35)
	load_btn.add_theme_font_size_override("font_size", 14)
	load_btn.add_theme_color_override("font_color", Color(0.5, 0.75, 0.9))
	load_btn.disabled = not info.exists
	load_btn.pressed.connect(_confirm_load_slot.bind(slot))
	btn_row.add_child(load_btn)

	var delete_btn = Button.new()
	delete_btn.text = "×"
	delete_btn.custom_minimum_size = Vector2(32, 35)
	delete_btn.add_theme_font_size_override("font_size", 16)
	delete_btn.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
	delete_btn.disabled = not info.exists
	delete_btn.pressed.connect(_delete_save_slot.bind(slot))
	btn_row.add_child(delete_btn)

	btn_container.add_child(btn_row)
	row.add_child(btn_container)

	return row


# Save dialog variables
var save_name_dialog: PanelContainer = null
var save_name_input: LineEdit = null
var pending_save_slot: int = 0


func _prompt_save_to_slot(slot: int) -> void:
	pending_save_slot = slot
	var existing_info = SaveManager.get_slot_info(slot)

	# Create save naming dialog
	save_name_dialog = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.98)
	style.border_color = Color(0.6, 0.5, 0.8, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	save_name_dialog.add_theme_stylebox_override("panel", style)
	save_name_dialog.set_anchors_preset(Control.PRESET_CENTER)
	save_name_dialog.offset_left = -200
	save_name_dialog.offset_right = 200
	save_name_dialog.offset_top = -150
	save_name_dialog.offset_bottom = 150

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	save_name_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Save Progress"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Warning if overwriting
	if existing_info.exists:
		var warning = Label.new()
		warning.text = "⚠ This will overwrite:\n%s\nSaved: %s • %d days" % [
			existing_info.slot_name,
			existing_info.date_string,
			existing_info.days_completed
		]
		warning.add_theme_font_size_override("font_size", 14)
		warning.add_theme_color_override("font_color", Color(1, 0.7, 0.5))
		warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(warning)

	# Name input
	var name_label = Label.new()
	name_label.text = "Save Name:"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	vbox.add_child(name_label)

	save_name_input = LineEdit.new()
	save_name_input.placeholder_text = "My Journey..."
	save_name_input.text = existing_info.slot_name if existing_info.exists else ""
	save_name_input.custom_minimum_size = Vector2(0, 40)
	save_name_input.add_theme_font_size_override("font_size", 16)
	vbox.add_child(save_name_input)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(100, 40)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_close_save_name_dialog)
	btn_row.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "Save"
	confirm_btn.custom_minimum_size = Vector2(100, 40)
	confirm_btn.add_theme_font_size_override("font_size", 16)
	confirm_btn.add_theme_color_override("font_color", Color(0.5, 0.9, 0.6))
	confirm_btn.pressed.connect(_confirm_save_with_name)
	btn_row.add_child(confirm_btn)

	add_child(save_name_dialog)
	save_name_input.grab_focus()


func _close_save_name_dialog() -> void:
	if save_name_dialog:
		save_name_dialog.queue_free()
		save_name_dialog = null
	save_name_input = null


func _confirm_save_with_name() -> void:
	var save_name = save_name_input.text.strip_edges() if save_name_input else ""
	if save_name == "":
		save_name = "Journey " + Time.get_date_string_from_system()

	_close_save_name_dialog()

	print("[Bedroom] Saving to slot ", pending_save_slot, " as '", save_name, "'")
	if SaveManager.save_to_slot(pending_save_slot, save_name):
		# Show confirmation
		_close_save_panel()
		_show_dialogue("Progress Saved", "Your journey has been saved as '%s'.\n\nThe Sleep Pod's memory banks will preserve your progress until you return." % save_name)
	else:
		_show_dialogue("Save Failed", "Unable to save to Slot %d.\n\nPlease try again." % pending_save_slot)


var delete_confirm_dialog: PanelContainer = null
var pending_delete_slot: int = 0

func _delete_save_slot(slot: int) -> void:
	# Show confirmation dialog instead of deleting immediately
	pending_delete_slot = slot
	var info = SaveManager.get_slot_info(slot)

	delete_confirm_dialog = PanelContainer.new()
	delete_confirm_dialog.name = "DeleteConfirmDialog"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.06, 0.08, 0.98)
	style.border_color = Color(0.9, 0.4, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	delete_confirm_dialog.add_theme_stylebox_override("panel", style)

	delete_confirm_dialog.set_anchors_preset(Control.PRESET_CENTER)
	delete_confirm_dialog.offset_left = -220
	delete_confirm_dialog.offset_right = 220
	delete_confirm_dialog.offset_top = -130
	delete_confirm_dialog.offset_bottom = 130

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	delete_confirm_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Warning icon/title
	var title = Label.new()
	title.text = "Delete Save?"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.95, 0.4, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Save info
	var info_label = Label.new()
	info_label.text = "'%s'\n%s\n%d days completed" % [info.slot_name, info.date_string, info.days_completed]
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info_label)

	# Warning message
	var warning = Label.new()
	warning.text = "This cannot be undone!"
	warning.add_theme_font_size_override("font_size", 18)
	warning.add_theme_color_override("font_color", Color(0.9, 0.6, 0.4))
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(warning)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Keep Save"
	cancel_btn.custom_minimum_size = Vector2(130, 48)
	cancel_btn.add_theme_font_size_override("font_size", 17)
	cancel_btn.pressed.connect(_cancel_delete)
	btn_row.add_child(cancel_btn)

	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(130, 48)
	delete_btn.add_theme_font_size_override("font_size", 17)
	delete_btn.add_theme_color_override("font_color", Color(0.95, 0.4, 0.35))
	delete_btn.pressed.connect(_confirm_delete)
	btn_row.add_child(delete_btn)

	add_child(delete_confirm_dialog)


func _confirm_delete() -> void:
	if delete_confirm_dialog:
		delete_confirm_dialog.queue_free()
		delete_confirm_dialog = null

	SaveManager.delete_slot(pending_delete_slot)
	pending_delete_slot = 0

	# Refresh the panel
	_close_save_panel()
	_show_save_panel()


func _cancel_delete() -> void:
	if delete_confirm_dialog:
		delete_confirm_dialog.queue_free()
		delete_confirm_dialog = null
	pending_delete_slot = 0


var load_confirm_dialog: PanelContainer = null
var pending_load_slot: int = 0

func _confirm_load_slot(slot: int) -> void:
	pending_load_slot = slot
	var info = SaveManager.get_slot_info(slot)

	# Create confirmation dialog
	load_confirm_dialog = PanelContainer.new()
	load_confirm_dialog.name = "LoadConfirmDialog"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.98)
	style.border_color = Color(0.6, 0.5, 0.8, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	load_confirm_dialog.add_theme_stylebox_override("panel", style)

	load_confirm_dialog.set_anchors_preset(Control.PRESET_CENTER)
	load_confirm_dialog.offset_left = -220
	load_confirm_dialog.offset_right = 220
	load_confirm_dialog.offset_top = -120
	load_confirm_dialog.offset_bottom = 120

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	load_confirm_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Warning title
	var title = Label.new()
	title.text = "Load Save?"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Warning message
	var msg = Label.new()
	msg.text = "Loading Slot %d will replace your current progress.\n\nAny unsaved changes will be lost.\n\nSlot: %s • Evo %d" % [slot, info.date_string, info.evolution_level]
	msg.add_theme_font_size_override("font_size", 15)
	msg.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(msg)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(120, 45)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_cancel_load)
	btn_row.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "Load"
	confirm_btn.custom_minimum_size = Vector2(120, 45)
	confirm_btn.add_theme_font_size_override("font_size", 16)
	confirm_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	confirm_btn.pressed.connect(_execute_load)
	btn_row.add_child(confirm_btn)

	add_child(load_confirm_dialog)


func _cancel_load() -> void:
	if load_confirm_dialog:
		load_confirm_dialog.queue_free()
		load_confirm_dialog = null


func _execute_load() -> void:
	var slot = pending_load_slot

	if load_confirm_dialog:
		load_confirm_dialog.queue_free()
		load_confirm_dialog = null

	_close_save_panel()

	print("[Bedroom] Loading from slot ", slot)
	if SaveManager.load_from_slot(slot):
		# Reload the scene to apply loaded data
		_show_load_success_dialog(slot)
	else:
		_show_dialogue("Load Failed", "Unable to load from Slot %d.\n\nThe save file may be corrupted." % slot)


func _show_load_success_dialog(slot: int) -> void:
	in_dialogue = true
	interaction_prompt.visible = false

	var dialog = PanelContainer.new()
	dialog.name = "LoadSuccessDialog"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	style.border_color = Color(0.4, 0.7, 0.5, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	dialog.add_theme_stylebox_override("panel", style)

	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.offset_left = -200
	dialog.offset_right = 200
	dialog.offset_top = -100
	dialog.offset_bottom = 100

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Progress Loaded"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var msg = Label.new()
	msg.text = "Loaded save from Slot %d.\n\nReloading..." % slot
	msg.add_theme_font_size_override("font_size", 16)
	msg.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)

	add_child(dialog)

	# Reload after brief delay
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()


func _close_save_panel() -> void:
	if save_panel:
		save_panel.queue_free()
		save_panel = null
	in_dialogue = false
	_set_interactive_labels_visible(true)  # Restore labels


# =============================================================================
# EXPORT / IMPORT DIALOGS
# =============================================================================

var export_dialog: PanelContainer = null
var import_dialog: PanelContainer = null
var import_text_input: TextEdit = null


func _show_export_dialog() -> void:
	var export_data = SaveManager.export_save_data()
	var is_web = OS.has_feature("web")
	print("[Bedroom] Export dialog - is_web: ", is_web)

	export_dialog = PanelContainer.new()
	export_dialog.z_index = 200  # Above other UI elements
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.12, 0.98)
	style.border_color = Color(0.5, 0.7, 0.9, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	export_dialog.add_theme_stylebox_override("panel", style)
	export_dialog.set_anchors_preset(Control.PRESET_CENTER)
	export_dialog.offset_left = -300
	export_dialog.offset_right = 300
	export_dialog.offset_top = -260
	export_dialog.offset_bottom = 260

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	export_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Export Save Data"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.5, 0.75, 0.9))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var instructions = Label.new()
	if is_web:
		instructions.text = "Download your save file or copy to clipboard.\n\nKeep this file safe to restore your progress later!"
	else:
		instructions.text = "Copy your save data to clipboard.\n\nPaste into a text file and save as 'mindscape_backup.json'"
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(instructions)

	# Download button (web only) - primary action
	if is_web:
		var download_btn = Button.new()
		download_btn.text = "Download Save File"
		download_btn.custom_minimum_size = Vector2(0, 50)
		download_btn.add_theme_font_size_override("font_size", 18)
		download_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 0.7))
		download_btn.pressed.connect(_trigger_file_download.bind(export_data, download_btn))
		vbox.add_child(download_btn)

		var or_label = Label.new()
		or_label.text = "— or copy manually —"
		or_label.add_theme_font_size_override("font_size", 12)
		or_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		or_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(or_label)

	var text_box = TextEdit.new()
	text_box.text = export_data
	text_box.custom_minimum_size = Vector2(0, 100)
	text_box.editable = false
	text_box.add_theme_font_size_override("font_size", 11)
	vbox.add_child(text_box)

	var copy_btn = Button.new()
	copy_btn.text = "Copy to Clipboard"
	copy_btn.custom_minimum_size = Vector2(0, 40)
	copy_btn.add_theme_font_size_override("font_size", 15)
	copy_btn.add_theme_color_override("font_color", Color(0.5, 0.75, 0.85))
	copy_btn.pressed.connect(func():
		DisplayServer.clipboard_set(export_data)
		copy_btn.text = "Copied!"
		copy_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	)
	vbox.add_child(copy_btn)

	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(0, 38)
	close_btn.add_theme_font_size_override("font_size", 15)
	close_btn.pressed.connect(_close_export_dialog)
	vbox.add_child(close_btn)

	add_child(export_dialog)


func _close_export_dialog() -> void:
	if export_dialog:
		export_dialog.queue_free()
		export_dialog = null


func _show_import_dialog() -> void:
	var is_web = OS.has_feature("web")

	import_dialog = PanelContainer.new()
	import_dialog.z_index = 200  # Above other UI elements
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.11, 0.98)
	style.border_color = Color(0.9, 0.75, 0.5, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	import_dialog.add_theme_stylebox_override("panel", style)
	import_dialog.set_anchors_preset(Control.PRESET_CENTER)
	import_dialog.offset_left = -300
	import_dialog.offset_right = 300
	import_dialog.offset_top = -260
	import_dialog.offset_bottom = 260

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	import_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Import Save Data"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var instructions = Label.new()
	if is_web:
		instructions.text = "Upload your save file or paste the data below.\n\n⚠ This will replace your current progress!"
	else:
		instructions.text = "Paste your save data below to restore progress.\n\n⚠ This will replace your current progress!"
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7))
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(instructions)

	# Upload button (web only) - primary action
	if is_web:
		var upload_btn = Button.new()
		upload_btn.text = "Upload Save File (.json)"
		upload_btn.custom_minimum_size = Vector2(0, 45)
		upload_btn.add_theme_font_size_override("font_size", 16)
		upload_btn.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5))
		upload_btn.pressed.connect(_trigger_file_upload)
		vbox.add_child(upload_btn)

		var or_label = Label.new()
		or_label.text = "— or paste manually —"
		or_label.add_theme_font_size_override("font_size", 12)
		or_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		or_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(or_label)

	import_text_input = TextEdit.new()
	import_text_input.placeholder_text = "Paste your save data here..."
	import_text_input.custom_minimum_size = Vector2(0, 100)
	import_text_input.add_theme_font_size_override("font_size", 11)
	vbox.add_child(import_text_input)

	var paste_btn = Button.new()
	paste_btn.text = "Paste from Clipboard"
	paste_btn.custom_minimum_size = Vector2(0, 35)
	paste_btn.add_theme_font_size_override("font_size", 14)
	paste_btn.pressed.connect(func(): import_text_input.text = DisplayServer.clipboard_get())
	vbox.add_child(paste_btn)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(100, 40)
	cancel_btn.add_theme_font_size_override("font_size", 15)
	cancel_btn.pressed.connect(_close_import_dialog)
	btn_row.add_child(cancel_btn)

	var import_btn = Button.new()
	import_btn.text = "Import"
	import_btn.custom_minimum_size = Vector2(100, 40)
	import_btn.add_theme_font_size_override("font_size", 15)
	import_btn.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
	import_btn.pressed.connect(_do_import)
	btn_row.add_child(import_btn)

	add_child(import_dialog)


func _close_import_dialog() -> void:
	if import_dialog:
		import_dialog.queue_free()
		import_dialog = null
	import_text_input = null


func _do_import() -> void:
	if not import_text_input or import_text_input.text.strip_edges() == "":
		_show_dialogue("Import Failed", "Please paste your save data first.")
		return

	var success = SaveManager.import_save_data(import_text_input.text)
	_close_import_dialog()
	_close_save_panel()

	if success:
		_show_dialogue("Import Successful", "Your save data has been restored!\n\nThe game will reload to apply changes.")
		await get_tree().create_timer(2.0).timeout
		get_tree().reload_current_scene()
	else:
		_show_dialogue("Import Failed", "The data could not be imported.\n\nMake sure you copied the entire save file.")


# =============================================================================
# HEADER CONTROLS (Volume, Save Indicator)
# =============================================================================

func _setup_header_controls() -> void:
	var header_hbox = menu_button.get_parent()
	if not header_hbox:
		return

	# Create save indicator
	save_indicator = Label.new()
	save_indicator.add_theme_font_size_override("font_size", 14)
	save_indicator.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	save_indicator.tooltip_text = "Current save file"
	_update_save_indicator()
	header_hbox.add_child(save_indicator)
	header_hbox.move_child(save_indicator, menu_button.get_index())

	# Create volume button
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
		if info.exists:
			save_indicator.text = info.slot_name
		else:
			save_indicator.text = "Slot %d" % current_slot
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
	volume_popup.custom_minimum_size = Vector2(0, 0)

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

	# Master slider
	var master_row = HBoxContainer.new()
	master_row.add_theme_constant_override("separation", 8)
	vbox.add_child(master_row)
	var master_label = Label.new()
	master_label.text = "Master"
	master_label.custom_minimum_size = Vector2(55, 0)
	master_label.add_theme_font_size_override("font_size", 14)
	master_row.add_child(master_label)
	var master_slider = HSlider.new()
	master_slider.min_value = 0
	master_slider.max_value = 100
	master_slider.value = audio.master_volume * 100 if audio else 100
	master_slider.custom_minimum_size = Vector2(100, 20)
	master_slider.value_changed.connect(func(val): _on_volume_changed("master", val))
	master_row.add_child(master_slider)

	# Music slider
	var music_row = HBoxContainer.new()
	music_row.add_theme_constant_override("separation", 8)
	vbox.add_child(music_row)
	var music_label = Label.new()
	music_label.text = "Music"
	music_label.custom_minimum_size = Vector2(55, 0)
	music_label.add_theme_font_size_override("font_size", 14)
	music_row.add_child(music_label)
	var music_slider = HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.value = audio.music_volume * 100 if audio else 100
	music_slider.custom_minimum_size = Vector2(100, 20)
	music_slider.value_changed.connect(func(val): _on_volume_changed("music", val))
	music_row.add_child(music_slider)

	# SFX slider
	var sfx_row = HBoxContainer.new()
	sfx_row.add_theme_constant_override("separation", 8)
	vbox.add_child(sfx_row)
	var sfx_label = Label.new()
	sfx_label.text = "SFX"
	sfx_label.custom_minimum_size = Vector2(55, 0)
	sfx_label.add_theme_font_size_override("font_size", 14)
	sfx_row.add_child(sfx_label)
	var sfx_slider = HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.value = audio.sfx_volume * 100 if audio else 100
	sfx_slider.custom_minimum_size = Vector2(100, 20)
	sfx_slider.value_changed.connect(func(val): _on_volume_changed("sfx", val))
	sfx_row.add_child(sfx_slider)

	# Mute button
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
		"master":
			audio.set_master_volume(vol)
		"music":
			audio.set_music_volume(vol)
		"sfx":
			audio.set_sfx_volume(vol)
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
	# Auto-save before going to main menu
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


# =============================================================================
# CUSTOMIZATION PANEL (Wardrobe)
# =============================================================================

var customization_panel: Control = null
var customization_preview: Control = null
var current_category_index: int = 0
var preview_items: Dictionary = {}

const CUSTOMIZATION_CATEGORIES = [
	{"id": "skin_color", "name": "Skin Color", "icon": "🎨"},
	{"id": "outfit", "name": "Outfits", "icon": "👕"},
	{"id": "hat", "name": "Hats", "icon": "🎩"},
	{"id": "cape", "name": "Capes", "icon": "🦸"},
	{"id": "glasses", "name": "Glasses", "icon": "👓"},
	{"id": "aura", "name": "Auras", "icon": "✨"}
]


func _open_customization_panel() -> void:
	if customization_panel:
		return

	in_dialogue = true

	# Start preview mode in CustomizationManager
	if CustomizationManager:
		CustomizationManager.start_preview()

	# Create main panel
	customization_panel = Panel.new()
	customization_panel.set_anchors_preset(Control.PRESET_CENTER)
	customization_panel.custom_minimum_size = Vector2(900, 600)
	customization_panel.position = Vector2(-450, -300)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.15, 0.98)
	style.border_color = Color(0.3, 0.5, 0.7, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	customization_panel.add_theme_stylebox_override("panel", style)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 10)
	main_vbox.offset_left = 20
	main_vbox.offset_top = 20
	main_vbox.offset_right = -20
	main_vbox.offset_bottom = -20
	customization_panel.add_child(main_vbox)

	# Header
	var header = Label.new()
	header.text = "Wardrobe Station"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	main_vbox.add_child(header)

	# Content HBox (categories + items | preview)
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(content_hbox)

	# Left side: Categories + Items
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_stretch_ratio = 0.6
	content_hbox.add_child(left_vbox)

	# Category tabs
	var category_hbox = HBoxContainer.new()
	category_hbox.add_theme_constant_override("separation", 5)
	left_vbox.add_child(category_hbox)

	for i in range(CUSTOMIZATION_CATEGORIES.size()):
		var cat = CUSTOMIZATION_CATEGORIES[i]
		var btn = Button.new()
		btn.text = cat.icon + " " + cat.name
		btn.custom_minimum_size = Vector2(100, 35)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_category_selected.bind(i))
		btn.name = "CategoryBtn_" + str(i)
		category_hbox.add_child(btn)

	# Items scroll container
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_vbox.add_child(scroll)

	var items_grid = GridContainer.new()
	items_grid.name = "ItemsGrid"
	items_grid.columns = 3
	items_grid.add_theme_constant_override("h_separation", 10)
	items_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(items_grid)

	# Right side: Preview
	var preview_panel = Panel.new()
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_stretch_ratio = 0.4
	preview_panel.name = "PreviewPanel"
	content_hbox.add_child(preview_panel)

	var preview_style = StyleBoxFlat.new()
	preview_style.bg_color = Color(0.05, 0.07, 0.1, 1.0)
	preview_style.border_color = Color(0.2, 0.3, 0.4, 0.5)
	preview_style.set_border_width_all(1)
	preview_style.set_corner_radius_all(8)
	preview_panel.add_theme_stylebox_override("panel", preview_style)

	var preview_vbox = VBoxContainer.new()
	preview_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_vbox.offset_left = 10
	preview_vbox.offset_top = 10
	preview_vbox.offset_right = -10
	preview_vbox.offset_bottom = -10
	preview_panel.add_child(preview_vbox)

	var preview_label = Label.new()
	preview_label.text = "Preview"
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.add_theme_font_size_override("font_size", 18)
	preview_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	preview_vbox.add_child(preview_label)

	# Avatar preview area
	customization_preview = Control.new()
	customization_preview.name = "AvatarPreview"
	customization_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	customization_preview.draw.connect(_draw_customization_preview)
	preview_vbox.add_child(customization_preview)

	# Current equipment display
	var equipped_label = Label.new()
	equipped_label.name = "EquippedLabel"
	equipped_label.text = _get_equipped_summary()
	equipped_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equipped_label.add_theme_font_size_override("font_size", 12)
	equipped_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	equipped_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_vbox.add_child(equipped_label)

	# Bottom buttons
	var button_hbox = HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(button_hbox)

	var apply_btn = Button.new()
	apply_btn.text = "Apply Changes"
	apply_btn.custom_minimum_size = Vector2(150, 45)
	apply_btn.add_theme_font_size_override("font_size", 18)
	apply_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	apply_btn.pressed.connect(_apply_customization)
	button_hbox.add_child(apply_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(120, 45)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	cancel_btn.add_theme_color_override("font_color", Color(0.8, 0.5, 0.5))
	cancel_btn.pressed.connect(_close_customization_panel)
	button_hbox.add_child(cancel_btn)

	add_child(customization_panel)

	# Load first category
	_on_category_selected(0)


func _on_category_selected(index: int) -> void:
	current_category_index = index

	if not customization_panel:
		return

	# Update category button styles
	var category_hbox = customization_panel.get_node_or_null("VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer")
	if category_hbox:
		for i in range(category_hbox.get_child_count()):
			var btn = category_hbox.get_child(i)
			if btn is Button:
				if i == index:
					btn.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
				else:
					btn.remove_theme_color_override("font_color")

	# Get items grid
	var items_grid = customization_panel.get_node_or_null("VBoxContainer/HBoxContainer/VBoxContainer/ScrollContainer/ItemsGrid")
	if not items_grid:
		return

	# Clear existing items
	for child in items_grid.get_children():
		child.queue_free()

	# Get category slot
	var cat = CUSTOMIZATION_CATEGORIES[index]
	var slot = cat.id

	# Map slot to shop category
	var shop_category = _slot_to_shop_category(slot)

	# Get items for this category
	if not ShopManager:
		return

	var items = ShopManager.get_catalog_by_category(shop_category)

	for item_id in items:
		var item = items[item_id]
		_create_item_button(items_grid, item_id, item, slot)


func _slot_to_shop_category(slot: String) -> int:
	match slot:
		"skin_color": return ShopManager.ItemCategory.COSMETIC_COLOR
		"outfit": return ShopManager.ItemCategory.COSMETIC_OUTFIT
		"hat": return ShopManager.ItemCategory.COSMETIC_HAT
		"cape": return ShopManager.ItemCategory.COSMETIC_CAPE
		"glasses": return ShopManager.ItemCategory.COSMETIC_GLASSES
		"aura": return ShopManager.ItemCategory.COSMETIC_AURA
	return ShopManager.ItemCategory.COSMETIC_COLOR


func _create_item_button(grid: GridContainer, item_id: String, item: Dictionary, slot: String) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(160, 80)
	btn.clip_text = true

	var is_owned = ShopManager.is_owned(item_id)
	var is_equipped = false

	if CustomizationManager:
		var current = CustomizationManager.get_current_appearance()
		is_equipped = current.get(slot, "") == item_id

	# Button style based on state
	var style = StyleBoxFlat.new()
	if is_equipped:
		style.bg_color = Color(0.2, 0.4, 0.3, 1.0)
		style.border_color = Color(0.4, 0.9, 0.5, 1.0)
	elif is_owned:
		style.bg_color = Color(0.15, 0.18, 0.25, 1.0)
		style.border_color = Color(0.3, 0.5, 0.7, 0.8)
	else:
		style.bg_color = Color(0.1, 0.1, 0.15, 1.0)
		style.border_color = Color(0.3, 0.3, 0.3, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)

	# Item content
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 5
	vbox.offset_top = 5
	vbox.offset_right = -5
	vbox.offset_bottom = -5
	btn.add_child(vbox)

	# Color preview for skin colors
	if slot == "skin_color" and item.has("preview_color"):
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(30, 30)
		color_rect.color = item.preview_color
		color_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(color_rect)

	# Item name
	var name_label = Label.new()
	name_label.text = item.get("name", item_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	if not is_owned:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(name_label)

	# Status/cost
	var status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 10)

	if is_equipped:
		status_label.text = "Equipped"
		status_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	elif is_owned:
		status_label.text = "Owned"
		status_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	else:
		var cost = item.get("cost", {})
		if cost.is_empty():
			status_label.text = "Free"
			status_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
		else:
			var cost_parts = []
			for aspect in cost:
				cost_parts.append(str(cost[aspect]) + " " + aspect.capitalize())
			status_label.text = ", ".join(cost_parts)
			status_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	vbox.add_child(status_label)

	# Connect button
	btn.pressed.connect(_on_item_selected.bind(item_id, slot, is_owned))

	grid.add_child(btn)


func _on_item_selected(item_id: String, slot: String, is_owned: bool) -> void:
	if is_owned:
		# Equip immediately to preview
		if CustomizationManager:
			CustomizationManager.set_preview_item(slot, item_id)
			_update_customization_preview()
	else:
		# Show "Go to Shop" message
		_show_dialogue("Locked Item", "Visit the Experience Shop in Mindscape to purchase this item!")


func _update_customization_preview() -> void:
	if customization_preview:
		customization_preview.queue_redraw()

	# Update equipped label
	var equipped_label = customization_panel.get_node_or_null("VBoxContainer/HBoxContainer/PreviewPanel/VBoxContainer/EquippedLabel")
	if equipped_label:
		equipped_label.text = _get_preview_summary()


func _get_equipped_summary() -> String:
	if not CustomizationManager:
		return ""
	var appearance = CustomizationManager.get_current_appearance()
	var parts = []
	for slot in appearance:
		var value = appearance[slot]
		# Handle both string values and null/empty values
		if value is String and value != "":
			var item = ShopManager.SHOP_CATALOG.get(value, {}) if ShopManager else {}
			parts.append(slot.capitalize() + ": " + item.get("name", value))
	return "\n".join(parts) if parts.size() > 0 else "No items equipped"


func _get_preview_summary() -> String:
	if not CustomizationManager:
		return ""
	var appearance = CustomizationManager.get_preview_appearance()
	var parts = []
	for slot in appearance:
		var value = appearance[slot]
		# Handle both string values and null/empty values
		if value is String and value != "":
			var item = ShopManager.SHOP_CATALOG.get(value, {}) if ShopManager else {}
			parts.append(slot.capitalize() + ": " + item.get("name", value))
	return "\n".join(parts) if parts.size() > 0 else "No items selected"


func _draw_customization_preview() -> void:
	if not customization_preview:
		return

	var center = customization_preview.size / 2
	var appearance = {}

	if CustomizationManager:
		appearance = CustomizationManager.get_preview_appearance()

	# Get skin color
	var skin_color = Color(0.83, 0.66, 0.29)  # Default golden yellow (matches actual player)
	var skin_id = appearance.get("skin_color", "default_green")
	if skin_id is String and skin_id != "" and ShopManager:
		var skin_item = ShopManager.SHOP_CATALOG.get(skin_id, {})
		if skin_item.has("preview_color"):
			skin_color = skin_item.preview_color

	# Draw body (larger oval)
	var body_pos = center + Vector2(0, 30)
	customization_preview.draw_circle(body_pos, 50, skin_color)

	# Draw head
	var head_pos = center + Vector2(0, -40)
	customization_preview.draw_circle(head_pos, 35, skin_color)

	# Draw eyes
	customization_preview.draw_circle(head_pos + Vector2(-12, -5), 8, Color.WHITE)
	customization_preview.draw_circle(head_pos + Vector2(12, -5), 8, Color.WHITE)
	customization_preview.draw_circle(head_pos + Vector2(-12, -5), 4, Color.BLACK)
	customization_preview.draw_circle(head_pos + Vector2(12, -5), 4, Color.BLACK)

	# Draw outfit if equipped
	var outfit_id = appearance.get("outfit", "")
	if outfit_id is String and outfit_id != "" and ShopManager:
		var outfit = ShopManager.SHOP_CATALOG.get(outfit_id, {})
		var outfit_color = outfit.get("preview_color", Color(0.2, 0.3, 0.5))
		# Simple outfit representation
		customization_preview.draw_rect(Rect2(body_pos.x - 35, body_pos.y - 20, 70, 60), outfit_color)

	# Draw hat if equipped
	var hat_id = appearance.get("hat", "")
	if hat_id is String and hat_id != "" and ShopManager:
		var hat = ShopManager.SHOP_CATALOG.get(hat_id, {})
		var hat_color = hat.get("preview_color", Color(0.4, 0.3, 0.2))
		customization_preview.draw_circle(head_pos + Vector2(0, -30), 20, hat_color)

	# Draw aura if equipped
	var aura_id = appearance.get("aura", "")
	if aura_id is String and aura_id != "" and ShopManager:
		var aura = ShopManager.SHOP_CATALOG.get(aura_id, {})
		var aura_color = aura.get("preview_color", Color(1.0, 0.9, 0.5, 0.3))
		for i in range(3):
			var radius = 80 + i * 15
			customization_preview.draw_arc(center, radius, 0, TAU, 32, aura_color, 2.0)


func _apply_customization() -> void:
	if CustomizationManager:
		CustomizationManager.apply_preview()
		SaveManager.save_game()
	_close_customization_panel()
	_show_dialogue("Customization Saved", "Your new look has been saved!")


func _close_customization_panel() -> void:
	if CustomizationManager:
		CustomizationManager.cancel_preview()

	if customization_panel:
		customization_panel.queue_free()
		customization_panel = null
		customization_preview = null
	in_dialogue = false


# =============================================================================
# PLAYER APPEARANCE UPDATE
# =============================================================================

func _update_player_appearance() -> void:
	## Update the in-game player sprite based on equipped customization items
	if not player:
		return

	var appearance = {}
	if CustomizationManager:
		appearance = CustomizationManager.get_current_appearance()

	# Get skin color from equipped item
	var skin_color = Color(0.83, 0.66, 0.29)  # Default golden yellow
	var skin_id = ""
	if ShopManager:
		skin_id = ShopManager.get_equipped("skin_color")
	if skin_id != "" and ShopManager:
		var skin_item = ShopManager.SHOP_CATALOG.get(skin_id, {})
		if skin_item.has("preview_color"):
			skin_color = skin_item.preview_color

	# Update body color
	var body = player.get_node_or_null("Body")
	if body and body is Polygon2D:
		body.color = skin_color

	# Update head color (slightly lighter)
	var head = player.get_node_or_null("Head")
	if head and head is Polygon2D:
		head.color = skin_color.lightened(0.1)

	# Update antenna color
	var antenna = player.get_node_or_null("Antenna")
	if antenna and antenna is Polygon2D:
		antenna.color = Color(skin_color.r, skin_color.g, skin_color.b, 0.9)

	# Update antenna tip (brighter)
	var antenna_tip = player.get_node_or_null("AntennaTip")
	if antenna_tip and antenna_tip is Polygon2D:
		antenna_tip.color = skin_color.lightened(0.3)

	# Handle outfit - add/update outfit overlay
	var outfit_id = ""
	if ShopManager:
		outfit_id = ShopManager.get_equipped("outfit")

	var outfit_overlay = player.get_node_or_null("OutfitOverlay")
	if outfit_id != "" and outfit_id != "default_suit" and ShopManager:
		var outfit_item = ShopManager.SHOP_CATALOG.get(outfit_id, {})
		var outfit_color = outfit_item.get("preview_color", Color(0.3, 0.4, 0.5, 0.7))

		if not outfit_overlay:
			outfit_overlay = Polygon2D.new()
			outfit_overlay.name = "OutfitOverlay"
			outfit_overlay.z_index = 1
			player.add_child(outfit_overlay)

		# Create outfit shape over body
		outfit_overlay.polygon = PackedVector2Array([
			Vector2(-16, 10), Vector2(-16, -20), Vector2(-10, -22),
			Vector2(10, -22), Vector2(16, -20), Vector2(16, 10)
		])
		outfit_overlay.position = Vector2(0, -25)
		outfit_overlay.color = outfit_color
		outfit_overlay.visible = true
	elif outfit_overlay:
		outfit_overlay.visible = false

	# Handle hat
	var hat_id = ""
	if ShopManager:
		hat_id = ShopManager.get_equipped("hat")

	var hat_overlay = player.get_node_or_null("HatOverlay")
	if hat_id != "" and ShopManager:
		var hat_item = ShopManager.SHOP_CATALOG.get(hat_id, {})
		var hat_color = hat_item.get("preview_color", Color(0.4, 0.3, 0.2))

		if not hat_overlay:
			hat_overlay = Polygon2D.new()
			hat_overlay.name = "HatOverlay"
			hat_overlay.z_index = 2
			player.add_child(hat_overlay)

		# Simple hat shape
		hat_overlay.polygon = PackedVector2Array([
			Vector2(-16, 0), Vector2(-12, -10), Vector2(12, -10), Vector2(16, 0)
		])
		hat_overlay.position = Vector2(0, -65)
		hat_overlay.color = hat_color
		hat_overlay.visible = true
	elif hat_overlay:
		hat_overlay.visible = false

	# Handle aura effect
	var aura_id = ""
	if ShopManager:
		aura_id = ShopManager.get_equipped("aura")

	var aura_overlay = player.get_node_or_null("AuraOverlay")
	if aura_id != "" and ShopManager:
		var aura_item = ShopManager.SHOP_CATALOG.get(aura_id, {})
		var aura_color = aura_item.get("particle_color", Color(1.0, 0.9, 0.5, 0.3))

		if not aura_overlay:
			aura_overlay = Node2D.new()
			aura_overlay.name = "AuraOverlay"
			aura_overlay.z_index = -1
			player.add_child(aura_overlay)

			# Create aura rings
			for i in range(3):
				var ring = Polygon2D.new()
				ring.name = "AuraRing" + str(i)
				var ring_points = PackedVector2Array()
				var radius = 35 + i * 10
				for j in range(16):
					var angle = (j / 16.0) * TAU
					ring_points.append(Vector2(cos(angle) * radius, sin(angle) * radius * 0.5))
				ring.polygon = ring_points
				ring.color = Color(aura_color.r, aura_color.g, aura_color.b, 0.15 - i * 0.04)
				ring.position = Vector2(0, -30)
				aura_overlay.add_child(ring)

		# Update aura colors
		for i in range(3):
			var ring = aura_overlay.get_node_or_null("AuraRing" + str(i))
			if ring:
				ring.color = Color(aura_color.r, aura_color.g, aura_color.b, 0.15 - i * 0.04)
		aura_overlay.visible = true
	elif aura_overlay:
		aura_overlay.visible = false

	# Handle glasses
	var glasses_id = ""
	if ShopManager:
		glasses_id = ShopManager.get_equipped("glasses")

	var glasses_overlay = player.get_node_or_null("GlassesOverlay")
	if glasses_id != "" and ShopManager:
		var glasses_item = ShopManager.SHOP_CATALOG.get(glasses_id, {})
		var glasses_color = glasses_item.get("preview_color", Color(0.2, 0.2, 0.3, 0.8))

		if not glasses_overlay:
			glasses_overlay = Polygon2D.new()
			glasses_overlay.name = "GlassesOverlay"
			glasses_overlay.z_index = 3
			player.add_child(glasses_overlay)

		# Simple glasses shape (two rectangles connected)
		glasses_overlay.polygon = PackedVector2Array([
			Vector2(-11, -8), Vector2(-5, -8), Vector2(-5, -3), Vector2(-11, -3),  # Left lens
			Vector2(-5, -6), Vector2(5, -6), Vector2(5, -5), Vector2(-5, -5),      # Bridge
			Vector2(5, -8), Vector2(11, -8), Vector2(11, -3), Vector2(5, -3)       # Right lens
		])
		glasses_overlay.position = Vector2(0, -55)
		glasses_overlay.color = glasses_color
		glasses_overlay.visible = true
	elif glasses_overlay:
		glasses_overlay.visible = false

	# Handle cape
	var cape_id = ""
	if ShopManager:
		cape_id = ShopManager.get_equipped("cape")

	var cape_overlay = player.get_node_or_null("CapeOverlay")
	if cape_id != "" and ShopManager:
		var cape_item = ShopManager.SHOP_CATALOG.get(cape_id, {})
		var cape_color = cape_item.get("preview_color", Color(0.5, 0.3, 0.3, 0.8))

		if not cape_overlay:
			cape_overlay = Polygon2D.new()
			cape_overlay.name = "CapeOverlay"
			cape_overlay.z_index = -1
			player.add_child(cape_overlay)

		# Cape shape flowing behind
		cape_overlay.polygon = PackedVector2Array([
			Vector2(-12, -20), Vector2(-18, 30), Vector2(-8, 35),
			Vector2(8, 35), Vector2(18, 30), Vector2(12, -20)
		])
		cape_overlay.position = Vector2(0, -25)
		cape_overlay.color = cape_color
		cape_overlay.visible = true
	elif cape_overlay:
		cape_overlay.visible = false


# =============================================================================
# MIRROR VIEW
# =============================================================================

var mirror_panel: Control = null


func _show_mirror_view() -> void:
	if mirror_panel:
		return

	in_dialogue = true

	# Create outer container for holographic frame
	mirror_panel = Control.new()
	mirror_panel.name = "HolographicMirror"
	mirror_panel.set_anchors_preset(Control.PRESET_CENTER)
	mirror_panel.custom_minimum_size = Vector2(520, 620)
	mirror_panel.position = Vector2(-260, -310)

	# Background holographic effect layer
	var holo_bg = Control.new()
	holo_bg.name = "HoloBG"
	holo_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	holo_bg.draw.connect(_draw_mirror_holo_bg.bind(holo_bg))
	mirror_panel.add_child(holo_bg)

	# Main panel with glass-like effect
	var main_panel = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.offset_left = 10
	main_panel.offset_top = 10
	main_panel.offset_right = -10
	main_panel.offset_bottom = -10

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.08, 0.92)
	style.border_color = Color(0.3, 0.6, 0.9, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0.3, 0.5, 0.8, 0.3)
	style.shadow_size = 8
	main_panel.add_theme_stylebox_override("panel", style)
	mirror_panel.add_child(main_panel)

	# Scan lines overlay
	var scan_lines = Control.new()
	scan_lines.name = "ScanLines"
	scan_lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	scan_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scan_lines.draw.connect(_draw_scan_lines.bind(scan_lines))
	main_panel.add_child(scan_lines)

	# Content container
	var content = MarginContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", 25)
	content.add_theme_constant_override("margin_right", 25)
	content.add_theme_constant_override("margin_top", 20)
	content.add_theme_constant_override("margin_bottom", 20)
	main_panel.add_child(content)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	content.add_child(vbox)

	# Header with glow effect
	var header_container = CenterContainer.new()
	vbox.add_child(header_container)

	var header = Label.new()
	header.text = "HOLOGRAPHIC MIRROR"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
	header_container.add_child(header)

	# Decorative line under header
	var header_line = Control.new()
	header_line.custom_minimum_size = Vector2(0, 8)
	header_line.draw.connect(func():
		var w = header_line.size.x
		var center = w / 2
		header_line.draw_line(Vector2(center - 180, 4), Vector2(center + 180, 4), Color(0.3, 0.6, 0.9, 0.5), 1.0)
		header_line.draw_line(Vector2(center - 100, 4), Vector2(center + 100, 4), Color(0.4, 0.7, 1.0, 0.8), 2.0)
		# Diamond accent
		var pts = [Vector2(center - 6, 4), Vector2(center, 0), Vector2(center + 6, 4), Vector2(center, 8)]
		header_line.draw_colored_polygon(pts, Color(0.5, 0.8, 1.0))
	)
	vbox.add_child(header_line)

	# Avatar section with holographic frame
	var avatar_section = HBoxContainer.new()
	avatar_section.add_theme_constant_override("separation", 20)
	avatar_section.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(avatar_section)

	# Avatar with holographic ring
	var avatar_frame = Panel.new()
	avatar_frame.custom_minimum_size = Vector2(160, 180)
	var avatar_style = StyleBoxFlat.new()
	avatar_style.bg_color = Color(0.05, 0.08, 0.15, 0.8)
	avatar_style.border_color = Color(0.4, 0.7, 0.9, 0.4)
	avatar_style.set_border_width_all(1)
	avatar_style.set_corner_radius_all(12)
	avatar_frame.add_theme_stylebox_override("panel", avatar_style)
	avatar_section.add_child(avatar_frame)

	var avatar_container = Control.new()
	avatar_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar_container.draw.connect(_draw_mirror_avatar.bind(avatar_container))
	avatar_frame.add_child(avatar_container)

	# Name and level info
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 6)
	avatar_section.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = GameManager.player_data.get("player_name", "Agent Goacto")
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	info_vbox.add_child(name_label)

	var evo_level = GameManager.player_data.get("evolution_level", 1)
	var level_label = Label.new()
	level_label.text = "Evolution Level " + str(evo_level)
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	info_vbox.add_child(level_label)

	# Evolution progress bar
	var evo_bar_container = Control.new()
	evo_bar_container.custom_minimum_size = Vector2(140, 20)
	evo_bar_container.draw.connect(func():
		var xp = GameManager.player_data.get("evolution_xp", 0)
		var needed = 100 + (evo_level * 50)
		var pct = clampf(float(xp) / needed, 0.0, 1.0)
		# Background
		evo_bar_container.draw_rect(Rect2(0, 4, 140, 12), Color(0.1, 0.15, 0.2), true, -1)
		# Progress
		var grad_color = Color(0.3, 0.7, 1.0).lerp(Color(0.5, 0.9, 0.6), pct)
		evo_bar_container.draw_rect(Rect2(2, 6, (140 - 4) * pct, 8), grad_color, true, -1)
		# Border
		evo_bar_container.draw_rect(Rect2(0, 4, 140, 12), Color(0.4, 0.6, 0.8, 0.5), false, 1.0)
	)
	info_vbox.add_child(evo_bar_container)

	var xp = GameManager.player_data.get("evolution_xp", 0)
	var needed = 100 + (evo_level * 50)
	var xp_label = Label.new()
	xp_label.text = str(xp) + " / " + str(needed) + " XP"
	xp_label.add_theme_font_size_override("font_size", 11)
	xp_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	info_vbox.add_child(xp_label)

	# Stats section with grid layout
	var stats_panel = Panel.new()
	stats_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color(0.04, 0.06, 0.1, 0.9)
	stats_style.border_color = Color(0.3, 0.5, 0.7, 0.3)
	stats_style.set_border_width_all(1)
	stats_style.set_corner_radius_all(10)
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	vbox.add_child(stats_panel)

	var stats_margin = MarginContainer.new()
	stats_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	stats_margin.add_theme_constant_override("margin_left", 15)
	stats_margin.add_theme_constant_override("margin_right", 15)
	stats_margin.add_theme_constant_override("margin_top", 12)
	stats_margin.add_theme_constant_override("margin_bottom", 12)
	stats_panel.add_child(stats_margin)

	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 10)
	stats_margin.add_child(stats_grid)

	# Get player stats and display as cards
	var stats = _get_player_stats()
	for stat in stats:
		var stat_card = _create_mirror_stat_card(stat)
		stats_grid.add_child(stat_card)

	# Button section with styled buttons
	var btn_container = CenterContainer.new()
	vbox.add_child(btn_container)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 20)
	btn_container.add_child(btn_row)

	# Decorate Room button with icon style
	var decor_btn = _create_mirror_button("Decorate Room", Color(0.3, 0.6, 0.4))
	decor_btn.pressed.connect(func():
		_close_mirror_view()
		_open_decoration_mode()
	)
	btn_row.add_child(decor_btn)

	# Close button
	var close_btn = _create_mirror_button("Close", Color(0.5, 0.5, 0.6))
	close_btn.pressed.connect(_close_mirror_view)
	btn_row.add_child(close_btn)

	add_child(mirror_panel)

	# Animate holographic effect
	var tween = create_tween()
	mirror_panel.modulate.a = 0.0
	mirror_panel.scale = Vector2(0.95, 0.95)
	tween.set_parallel(true)
	tween.tween_property(mirror_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(mirror_panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK)


func _create_mirror_stat_card(stat: Dictionary) -> Control:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(200, 50)

	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.06, 0.08, 0.12, 0.8)
	card_style.border_color = stat.color * 0.5
	card_style.border_color.a = 0.4
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", card_style)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 12
	hbox.offset_right = -12
	hbox.offset_top = 8
	hbox.offset_bottom = -8
	card.add_child(hbox)

	# Icon indicator
	var icon_container = Control.new()
	icon_container.custom_minimum_size = Vector2(30, 30)
	icon_container.draw.connect(func():
		icon_container.draw_circle(Vector2(15, 15), 12, stat.color * 0.3)
		icon_container.draw_arc(Vector2(15, 15), 10, 0, TAU, 16, stat.color, 2.0)
	)
	hbox.add_child(icon_container)

	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 0)
	hbox.add_child(text_vbox)

	var stat_name = Label.new()
	stat_name.text = stat.name
	stat_name.add_theme_font_size_override("font_size", 12)
	stat_name.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	text_vbox.add_child(stat_name)

	var stat_value = Label.new()
	stat_value.text = stat.value
	stat_value.add_theme_font_size_override("font_size", 16)
	stat_value.add_theme_color_override("font_color", stat.color)
	text_vbox.add_child(stat_value)

	return card


func _create_mirror_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(130, 44)
	btn.add_theme_font_size_override("font_size", 15)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(color.r * 0.3, color.g * 0.3, color.b * 0.3, 0.8)
	btn_style.border_color = color
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", btn_style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(color.r * 0.4, color.g * 0.4, color.b * 0.4, 0.9)
	hover_style.border_color = color * 1.2
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, 0.95)
	pressed_style.border_color = color * 1.3
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	return btn


func _draw_mirror_holo_bg(container: Control) -> void:
	var size = container.size
	var time = Time.get_ticks_msec() / 1000.0

	# Outer glow frame
	for i in range(3):
		var offset = i * 3
		var alpha = 0.15 - (i * 0.04)
		var color = Color(0.3, 0.6, 0.9, alpha)
		container.draw_rect(Rect2(offset, offset, size.x - offset * 2, size.y - offset * 2), color, false, 2.0)

	# Corner accents
	var corner_size = 25
	var corners = [
		[Vector2(0, corner_size), Vector2(0, 0), Vector2(corner_size, 0)],
		[Vector2(size.x - corner_size, 0), Vector2(size.x, 0), Vector2(size.x, corner_size)],
		[Vector2(size.x, size.y - corner_size), Vector2(size.x, size.y), Vector2(size.x - corner_size, size.y)],
		[Vector2(corner_size, size.y), Vector2(0, size.y), Vector2(0, size.y - corner_size)]
	]
	for corner in corners:
		container.draw_polyline(corner, Color(0.4, 0.7, 1.0, 0.7), 2.0)


func _draw_scan_lines(container: Control) -> void:
	var size = container.size
	var time = Time.get_ticks_msec() / 1000.0

	# Horizontal scan lines
	for y in range(0, int(size.y), 4):
		var alpha = 0.03 + sin(y * 0.1 + time) * 0.01
		container.draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.5, 0.8, 1.0, alpha), 1.0)

	# Moving scan beam
	var scan_y = fmod(time * 80, size.y)
	container.draw_line(Vector2(0, scan_y), Vector2(size.x, scan_y), Color(0.4, 0.7, 1.0, 0.15), 2.0)
	container.draw_line(Vector2(0, scan_y - 2), Vector2(size.x, scan_y - 2), Color(0.4, 0.7, 1.0, 0.08), 1.0)
	container.draw_line(Vector2(0, scan_y + 2), Vector2(size.x, scan_y + 2), Color(0.4, 0.7, 1.0, 0.08), 1.0)

	# Request continuous redraw for animation
	container.queue_redraw()


func _draw_mirror_avatar(container: Control) -> void:
	var center = container.size / 2
	var appearance = {}
	var time = Time.get_ticks_msec() / 1000.0

	if CustomizationManager:
		appearance = CustomizationManager.get_current_appearance()

	# Get skin color
	var skin_color = Color(0.3, 0.7, 0.4)
	var skin_id = appearance.get("skin_color", "default_green")
	if skin_id is String and skin_id != "" and ShopManager:
		var skin_item = ShopManager.SHOP_CATALOG.get(skin_id, {})
		if skin_item.has("preview_color"):
			skin_color = skin_item.preview_color

	# Holographic shimmer effect
	var shimmer = sin(time * 2) * 0.1 + 0.9
	var holo_tint = Color(0.8, 0.9, 1.0, shimmer)

	# Draw holographic rings (background)
	for i in range(3):
		var radius = 70 - i * 8
		var alpha = 0.1 - i * 0.02
		var pulse = sin(time * 1.5 + i * 0.5) * 0.05 + alpha
		container.draw_arc(center, radius, 0, TAU, 32, Color(0.4, 0.7, 1.0, pulse), 1.5)

	# Draw body with slight glow
	var body_pos = center + Vector2(0, 35)
	# Body glow
	container.draw_circle(body_pos, 38, Color(skin_color.r, skin_color.g, skin_color.b, 0.2))
	# Body
	var body_color = skin_color * holo_tint
	body_color.a = 1.0
	container.draw_circle(body_pos, 32, body_color)
	# Body highlight
	container.draw_arc(body_pos + Vector2(-8, -8), 18, PI * 0.8, PI * 1.5, 12, Color(1, 1, 1, 0.15), 4.0)

	# Draw head with glow
	var head_pos = center + Vector2(0, -20)
	# Head glow
	container.draw_circle(head_pos, 30, Color(skin_color.r, skin_color.g, skin_color.b, 0.2))
	# Head
	var head_color = skin_color * holo_tint
	head_color.a = 1.0
	container.draw_circle(head_pos, 26, head_color)
	# Head highlight
	container.draw_arc(head_pos + Vector2(-6, -6), 14, PI * 0.8, PI * 1.5, 12, Color(1, 1, 1, 0.2), 3.0)

	# Draw antennae
	var antenna_color = skin_color.darkened(0.2)
	container.draw_line(head_pos + Vector2(-10, -22), head_pos + Vector2(-14, -36), antenna_color, 3.0)
	container.draw_line(head_pos + Vector2(10, -22), head_pos + Vector2(14, -36), antenna_color, 3.0)
	# Antenna tips (glowing)
	var tip_pulse = sin(time * 3) * 0.3 + 0.7
	container.draw_circle(head_pos + Vector2(-14, -36), 4, Color(0.5, 0.9, 1.0, tip_pulse))
	container.draw_circle(head_pos + Vector2(14, -36), 4, Color(0.5, 0.9, 1.0, tip_pulse))

	# Draw eyes
	container.draw_circle(head_pos + Vector2(-9, -3), 6, Color.WHITE)
	container.draw_circle(head_pos + Vector2(9, -3), 6, Color.WHITE)
	# Pupils with slight movement
	var pupil_offset = Vector2(sin(time * 0.5) * 1, cos(time * 0.7) * 0.5)
	container.draw_circle(head_pos + Vector2(-9, -3) + pupil_offset, 3, Color(0.1, 0.1, 0.15))
	container.draw_circle(head_pos + Vector2(9, -3) + pupil_offset, 3, Color(0.1, 0.1, 0.15))
	# Eye shine
	container.draw_circle(head_pos + Vector2(-11, -5), 1.5, Color(1, 1, 1, 0.8))
	container.draw_circle(head_pos + Vector2(7, -5), 1.5, Color(1, 1, 1, 0.8))

	# Draw smile
	container.draw_arc(head_pos + Vector2(0, 8), 8, 0.2, PI - 0.2, 8, Color(0.2, 0.2, 0.25), 2.0)

	# Draw aura if equipped
	var aura_id = appearance.get("aura", "")
	if aura_id is String and aura_id != "" and ShopManager:
		var aura = ShopManager.SHOP_CATALOG.get(aura_id, {})
		var aura_color = aura.get("preview_color", Color(1.0, 0.9, 0.5, 0.3))
		for i in range(3):
			var radius = 60 + i * 10
			var aura_pulse = sin(time * 2 + i * 0.3) * 0.1 + 0.3
			var draw_color = Color(aura_color.r, aura_color.g, aura_color.b, aura_pulse)
			container.draw_arc(center + Vector2(0, 10), radius, 0, TAU, 32, draw_color, 2.0)

	# Request continuous redraw for animation
	container.queue_redraw()


func _get_player_stats() -> Array:
	var stats = []
	var p = GameManager.player_data

	# Evolution level
	stats.append({
		"name": "Evolution Level",
		"value": str(p.get("evolution_level", 1)),
		"color": Color(0.5, 0.9, 1.0)
	})

	# Focus sessions
	var sessions = p.get("total_focus_sessions", 0)
	stats.append({
		"name": "Focus Sessions",
		"value": str(sessions),
		"color": Color(0.9, 0.7, 0.4)
	})

	# Total focus time
	var minutes = int(p.get("total_focus_time", 0) / 60)
	var hours = minutes / 60
	var mins = minutes % 60
	var time_str = str(hours) + "h " + str(mins) + "m" if hours > 0 else str(mins) + "m"
	stats.append({
		"name": "Total Focus Time",
		"value": time_str,
		"color": Color(0.7, 0.9, 0.5)
	})

	# Habits active
	var habits_count = HabitManager.habits.size() if HabitManager else 0
	stats.append({
		"name": "Active Habits",
		"value": str(habits_count),
		"color": Color(0.9, 0.6, 0.8)
	})

	# Aspect XP totals
	var aspect_xp = p.get("aspect_xp", {})
	var total_xp = 0
	for aspect in aspect_xp:
		total_xp += aspect_xp[aspect]
	stats.append({
		"name": "Total Aspect XP",
		"value": str(total_xp),
		"color": Color(0.9, 0.85, 0.4)
	})

	# Items owned
	var owned = ShopManager.owned_items.size() if ShopManager else 0
	stats.append({
		"name": "Items Owned",
		"value": str(owned),
		"color": Color(0.6, 0.8, 0.9)
	})

	return stats


func _close_mirror_view() -> void:
	if mirror_panel:
		mirror_panel.queue_free()
		mirror_panel = null
	in_dialogue = false


# =============================================================================
# DECORATION PLACEMENT MODE
# =============================================================================

var decoration_mode: bool = false
var decoration_panel: Control = null
var decoration_ghost: Node2D = null
var selected_decoration: String = ""
var placed_decoration_nodes: Array = []
var hovered_decoration: Node2D = null
var decoration_tooltip: PanelContainer = null
var picked_up_decoration_data: Dictionary = {}  # For repositioning

func _open_decoration_mode() -> void:
	if decoration_panel:
		return

	decoration_mode = true
	in_dialogue = true
	interaction_prompt.visible = false

	# Create decoration mode panel (inventory sidebar)
	decoration_panel = Control.new()
	decoration_panel.name = "DecorationPanel"

	# Position on right side
	decoration_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	decoration_panel.custom_minimum_size = Vector2(320, 550)
	decoration_panel.position = Vector2(-340, -275)

	# Background glow effect
	var glow_bg = Control.new()
	glow_bg.name = "GlowBG"
	glow_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow_bg.draw.connect(func():
		var size = glow_bg.size
		# Outer glow
		for i in range(4):
			var alpha = 0.08 - i * 0.02
			glow_bg.draw_rect(Rect2(-i * 2, -i * 2, size.x + i * 4, size.y + i * 4), Color(0.6, 0.5, 0.3, alpha), false, 2.0)
	)
	decoration_panel.add_child(glow_bg)

	# Main panel
	var main_panel = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.035, 0.06, 0.96)
	style.border_color = Color(0.7, 0.55, 0.3, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.6, 0.4, 0.2, 0.2)
	style.shadow_size = 6
	main_panel.add_theme_stylebox_override("panel", style)
	decoration_panel.add_child(main_panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	main_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title with decoration
	var title_container = CenterContainer.new()
	vbox.add_child(title_container)

	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 10)
	title_container.add_child(title_hbox)

	# Left star
	var star_left = Control.new()
	star_left.custom_minimum_size = Vector2(20, 20)
	star_left.draw.connect(func(): _draw_decor_star(star_left, Vector2(10, 10), 8))
	title_hbox.add_child(star_left)

	var title = Label.new()
	title.text = "DECORATE ROOM"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	title_hbox.add_child(title)

	# Right star
	var star_right = Control.new()
	star_right.custom_minimum_size = Vector2(20, 20)
	star_right.draw.connect(func(): _draw_decor_star(star_right, Vector2(10, 10), 8))
	title_hbox.add_child(star_right)

	# Instructions label (simple, no extra panel)
	var instructions = Label.new()
	instructions.text = "Select an item, then click in the room to place it."
	instructions.add_theme_font_size_override("font_size", 11)
	instructions.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instructions)

	# Decorations section header
	var section_header = HBoxContainer.new()
	section_header.add_theme_constant_override("separation", 8)
	vbox.add_child(section_header)

	var decor_icon = Control.new()
	decor_icon.custom_minimum_size = Vector2(18, 18)
	decor_icon.draw.connect(func():
		decor_icon.draw_rect(Rect2(3, 3, 12, 12), Color(0.7, 0.6, 0.4, 0.6), true, -1)
		decor_icon.draw_rect(Rect2(3, 3, 12, 12), Color(0.8, 0.7, 0.5), false, 1.0)
	)
	section_header.add_child(decor_icon)

	var collected_label = Label.new()
	collected_label.text = "Available Decorations"
	collected_label.add_theme_font_size_override("font_size", 14)
	collected_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.65))
	section_header.add_child(collected_label)

	# Count badge
	var collected = GameManager.player_data.get("collected_decor", [])
	if collected == null:
		collected = []
	var placed_ids = _get_placed_decoration_ids()
	var available_count = 0
	for item_id in collected:
		if item_id not in placed_ids:
			available_count += 1

	var count_badge = Label.new()
	count_badge.text = "(" + str(available_count) + ")"
	count_badge.add_theme_font_size_override("font_size", 12)
	count_badge.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	section_header.add_child(count_badge)

	# Scrollable grid for decorations
	var scroll_panel = Panel.new()
	scroll_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll_style = StyleBoxFlat.new()
	scroll_style.bg_color = Color(0.03, 0.025, 0.045, 0.9)
	scroll_style.border_color = Color(0.4, 0.35, 0.25, 0.4)
	scroll_style.set_border_width_all(1)
	scroll_style.set_corner_radius_all(8)
	scroll_panel.add_theme_stylebox_override("panel", scroll_style)
	vbox.add_child(scroll_panel)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 8
	scroll.offset_top = 8
	scroll.offset_right = -8
	scroll.offset_bottom = -8
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_panel.add_child(scroll)

	var grid = GridContainer.new()
	grid.name = "DecorationGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	# Populate with collected decorations
	if collected.is_empty() or available_count == 0:
		# Use 1 column for empty state
		grid.columns = 1

		var empty_vbox = VBoxContainer.new()
		empty_vbox.add_theme_constant_override("separation", 10)
		empty_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(empty_vbox)

		# Spacer
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 30)
		empty_vbox.add_child(spacer)

		# Empty icon
		var empty_icon = Control.new()
		empty_icon.custom_minimum_size = Vector2(50, 50)
		empty_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		empty_icon.draw.connect(func():
			empty_icon.draw_rect(Rect2(5, 5, 40, 40), Color(0.3, 0.3, 0.35, 0.5), false, 2.0)
			empty_icon.draw_line(Vector2(15, 20), Vector2(35, 40), Color(0.4, 0.4, 0.45, 0.5), 2.0)
			empty_icon.draw_line(Vector2(35, 20), Vector2(15, 40), Color(0.4, 0.4, 0.45, 0.5), 2.0)
		)
		empty_vbox.add_child(empty_icon)

		var empty_label = Label.new()
		empty_label.text = "No decorations yet!" if collected.is_empty() else "All items placed!"
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_vbox.add_child(empty_label)

		var hint_label = Label.new()
		hint_label.text = "Visit the Experience Shop" if collected.is_empty() else "Hover placed items to move"
		hint_label.add_theme_font_size_override("font_size", 11)
		hint_label.add_theme_color_override("font_color", Color(0.4, 0.45, 0.5))
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_vbox.add_child(hint_label)
	else:
		for item_id in collected:
			# Skip if already placed
			if item_id in placed_ids:
				continue
			_create_decoration_item_button(grid, item_id)

	# Buttons row
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	# Done button (primary action)
	var done_btn = _create_decor_button("Done", Color(0.3, 0.5, 0.4), true)
	done_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	done_btn.pressed.connect(_close_decoration_mode)
	btn_row.add_child(done_btn)

	# Clear all button (secondary/danger)
	var clear_btn = _create_decor_button("Clear All", Color(0.5, 0.3, 0.3), false)
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_btn.pressed.connect(_clear_all_decorations)
	btn_row.add_child(clear_btn)

	add_child(decoration_panel)

	# Animate panel sliding in from the right
	var tween = create_tween()
	var final_x = decoration_panel.position.x  # Store the final position (-340)
	decoration_panel.position.x = 50  # Start off-screen to the right
	decoration_panel.modulate.a = 0.0
	tween.set_parallel(true)
	tween.tween_property(decoration_panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(decoration_panel, "position:x", final_x, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw_decor_star(container: Control, center: Vector2, size: float) -> void:
	var points: PackedVector2Array = []
	for i in range(10):
		var angle = (i * TAU / 10) - PI / 2
		var r = size if i % 2 == 0 else size * 0.4
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	container.draw_colored_polygon(points, Color(0.85, 0.7, 0.35))


func _create_decor_button(text: String, color: Color, is_primary: bool) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 42)
	btn.add_theme_font_size_override("font_size", 14)

	var btn_style = StyleBoxFlat.new()
	if is_primary:
		btn_style.bg_color = Color(color.r * 0.4, color.g * 0.4, color.b * 0.4, 0.9)
		btn_style.border_color = color * 1.5
	else:
		btn_style.bg_color = Color(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.8)
		btn_style.border_color = color
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", btn_style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, 0.95)
	hover_style.border_color = color * 1.3
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(color.r * 0.6, color.g * 0.6, color.b * 0.6, 1.0)
	pressed_style.border_color = color * 1.4
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	return btn


func _get_placed_decoration_ids() -> Array:
	var placed = GameManager.player_data.get("bedroom_decorations", [])
	var ids = []
	for dec in placed:
		ids.append(dec.get("item_id", ""))
	return ids


func _create_decoration_item_button(parent: Node, item_id: String) -> void:
	var item = ShopManager.get_item(item_id) if ShopManager else null
	if item == null or item.is_empty():
		return

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(125, 95)
	btn.tooltip_text = item.get("description", "")
	btn.name = "DecorBtn_" + item_id

	# Custom button styles
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.06, 0.055, 0.08, 0.9)
	btn_style.border_color = Color(0.4, 0.35, 0.3, 0.5)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", btn_style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.1, 0.09, 0.12, 0.95)
	hover_style.border_color = Color(0.8, 0.65, 0.4, 0.8)
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.12, 0.1, 0.14, 1.0)
	pressed_style.border_color = Color(0.9, 0.75, 0.45, 1.0)
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8
	vbox.offset_top = 8
	vbox.offset_right = -8
	vbox.offset_bottom = -8
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	btn.add_child(vbox)

	# Item icon container with visual decoration
	var icon_container = Control.new()
	icon_container.custom_minimum_size = Vector2(50, 50)
	icon_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var item_color = _get_decoration_color(item_id)
	icon_container.draw.connect(func():
		var center = Vector2(25, 25)
		# Background glow
		icon_container.draw_circle(center, 22, Color(item_color.r, item_color.g, item_color.b, 0.15))
		# Item shape based on type
		_draw_decoration_icon(icon_container, item_id, center, item_color)
	)
	vbox.add_child(icon_container)

	# Item name
	var name_label = Label.new()
	var item_name = item.get("name", item_id)
	if item_name.length() > 14:
		item_name = item_name.substr(0, 12) + ".."
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	btn.pressed.connect(_select_decoration.bind(item_id))
	parent.add_child(btn)


func _draw_decoration_icon(container: Control, item_id: String, center: Vector2, color: Color) -> void:
	match item_id:
		"decor_ship_memento":
			# Draw small ship silhouette
			var pts = [Vector2(-12, 8), Vector2(0, -12), Vector2(12, 8), Vector2(8, 8), Vector2(0, 0), Vector2(-8, 8)]
			var moved_pts: PackedVector2Array = []
			for p in pts:
				moved_pts.append(center + p)
			container.draw_colored_polygon(moved_pts, color)
		"decor_family_photo":
			# Draw frame shape
			container.draw_rect(Rect2(center.x - 14, center.y - 10, 28, 20), color, true, -1)
			container.draw_rect(Rect2(center.x - 12, center.y - 8, 24, 16), Color(0.1, 0.1, 0.15), true, -1)
			container.draw_rect(Rect2(center.x - 14, center.y - 10, 28, 20), color * 0.8, false, 2.0)
		"decor_plant_crystal":
			# Draw crystal shape
			var pts = [Vector2(0, -14), Vector2(10, -2), Vector2(6, 14), Vector2(-6, 14), Vector2(-10, -2)]
			var moved_pts: PackedVector2Array = []
			for p in pts:
				moved_pts.append(center + p)
			container.draw_colored_polygon(moved_pts, color)
			container.draw_line(center + Vector2(0, -14), center + Vector2(0, 14), Color(1, 1, 1, 0.3), 1.0)
		"decor_lamp_orb":
			# Draw glowing orb
			container.draw_circle(center, 14, color)
			container.draw_circle(center + Vector2(-4, -4), 5, Color(1, 1, 1, 0.4))
			# Rays
			for i in range(8):
				var angle = i * TAU / 8
				var start = center + Vector2(cos(angle), sin(angle)) * 16
				var end_pt = center + Vector2(cos(angle), sin(angle)) * 20
				container.draw_line(start, end_pt, Color(color.r, color.g, color.b, 0.5), 1.5)
		"decor_poster_stars":
			# Draw starry rectangle
			container.draw_rect(Rect2(center.x - 12, center.y - 14, 24, 28), color, true, -1)
			# Small stars
			container.draw_circle(center + Vector2(-5, -6), 2, Color(1, 1, 0.9))
			container.draw_circle(center + Vector2(6, -2), 1.5, Color(1, 1, 0.9))
			container.draw_circle(center + Vector2(-2, 6), 1.5, Color(1, 1, 0.9))
		"decor_rug_meditation":
			# Draw circular rug
			container.draw_circle(center, 14, color)
			container.draw_circle(center, 10, Color(color.r * 0.7, color.g * 0.7, color.b * 0.7))
			container.draw_circle(center, 5, color)
		"decor_statue_mini":
			# Draw small statue shape
			container.draw_rect(Rect2(center.x - 8, center.y + 8, 16, 6), color * 0.8, true, -1)
			container.draw_circle(center + Vector2(0, -2), 8, color)
			container.draw_circle(center + Vector2(0, -12), 5, color)
		"decor_terrarium":
			# Draw dome terrarium
			container.draw_rect(Rect2(center.x - 12, center.y + 6, 24, 8), Color(0.5, 0.4, 0.3), true, -1)
			container.draw_arc(center + Vector2(0, 6), 12, PI, 0, 16, color, 2.0)
			# Plants inside
			container.draw_circle(center + Vector2(-4, 2), 4, Color(0.3, 0.7, 0.4))
			container.draw_circle(center + Vector2(4, 0), 3, Color(0.4, 0.8, 0.5))
		_:
			# Generic box
			container.draw_rect(Rect2(center.x - 12, center.y - 12, 24, 24), color, true, -1)
			container.draw_rect(Rect2(center.x - 12, center.y - 12, 24, 24), color * 0.7, false, 2.0)


func _get_decoration_color(item_id: String) -> Color:
	match item_id:
		"decor_ship_memento":
			return Color(0.7, 0.6, 0.4, 0.9)  # Bronze/metallic
		"decor_family_photo":
			return Color(0.6, 0.5, 0.8, 0.9)  # Purple holo tint
		"decor_plant_crystal":
			return Color(0.3, 0.8, 0.6, 0.9)
		"decor_lamp_orb":
			return Color(0.9, 0.8, 0.4, 0.9)
		"decor_poster_stars":
			return Color(0.3, 0.4, 0.7, 0.9)
		"decor_rug_meditation":
			return Color(0.6, 0.4, 0.5, 0.9)
		"decor_statue_mini":
			return Color(0.5, 0.5, 0.6, 0.9)
		"decor_terrarium":
			return Color(0.4, 0.7, 0.5, 0.9)
		_:
			return Color(0.5, 0.5, 0.5, 0.9)


func _select_decoration(item_id: String) -> void:
	selected_decoration = item_id
	_create_decoration_ghost(item_id)
	_play_sfx("res://audio/sfx/button_click.wav")


func _create_decoration_ghost(item_id: String) -> void:
	# Remove old ghost
	if decoration_ghost:
		decoration_ghost.queue_free()
		decoration_ghost = null

	var item = ShopManager.get_item(item_id) if ShopManager else {}
	var size = item.get("size", Vector2(40, 40))

	decoration_ghost = Node2D.new()
	decoration_ghost.name = "DecorationGhost"

	# Ghost visual (semi-transparent)
	var ghost_shape = Polygon2D.new()
	var half_w = size.x / 2
	var half_h = size.y / 2
	ghost_shape.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h), Vector2(half_w, -half_h),
		Vector2(half_w, half_h), Vector2(-half_w, half_h)
	])
	ghost_shape.color = Color(_get_decoration_color(item_id), 0.5)
	decoration_ghost.add_child(ghost_shape)

	# Outline
	var outline = Line2D.new()
	outline.points = PackedVector2Array([
		Vector2(-half_w, -half_h), Vector2(half_w, -half_h),
		Vector2(half_w, half_h), Vector2(-half_w, half_h),
		Vector2(-half_w, -half_h)
	])
	outline.width = 2.0
	outline.default_color = Color(0.9, 0.8, 0.3, 0.8)
	decoration_ghost.add_child(outline)

	isometric_base.add_child(decoration_ghost)


func _update_decoration_ghost() -> void:
	if not decoration_ghost or not decoration_mode:
		return

	# Convert mouse position to isometric space
	var mouse_pos = get_global_mouse_position()
	var iso_pos = (mouse_pos - isometric_base.global_position) / camera_zoom
	decoration_ghost.position = iso_pos

	# Check if position is valid (within room bounds)
	var valid = _is_valid_decoration_position(iso_pos)
	var ghost_shape = decoration_ghost.get_child(0) as Polygon2D
	if ghost_shape:
		var base_color = _get_decoration_color(selected_decoration)
		if valid:
			ghost_shape.color = Color(base_color.r, base_color.g, base_color.b, 0.5)
		else:
			ghost_shape.color = Color(0.8, 0.3, 0.3, 0.5)


func _is_valid_decoration_position(pos: Vector2) -> bool:
	# Check room bounds
	if pos.x < player_bounds.position.x or pos.x > player_bounds.position.x + player_bounds.size.x:
		return false
	if pos.y < player_bounds.position.y or pos.y > player_bounds.position.y + player_bounds.size.y:
		return false

	# Check not too close to interactive objects
	for obj_name in object_positions:
		var obj_pos = object_positions[obj_name]
		if pos.distance_to(obj_pos) < 50:
			return false

	return true


func _place_decoration() -> void:
	if not decoration_ghost or selected_decoration == "":
		return

	var pos = decoration_ghost.position
	if not _is_valid_decoration_position(pos):
		_play_sfx("res://audio/sfx/button_click.wav")
		return

	# Add to placed decorations
	var decoration_data = {
		"item_id": selected_decoration,
		"position": {"x": pos.x, "y": pos.y},
		"rotation": 0
	}

	if not GameManager.player_data.has("bedroom_decorations"):
		GameManager.player_data["bedroom_decorations"] = []
	GameManager.player_data.bedroom_decorations.append(decoration_data)

	# Remove from collected (consumed on placement)
	var collected = GameManager.player_data.get("collected_decor", [])
	var idx = collected.find(selected_decoration)
	if idx >= 0:
		collected.remove_at(idx)

	# Create actual decoration visual
	_create_placed_decoration(decoration_data)

	# Clear ghost and selection
	if decoration_ghost:
		decoration_ghost.queue_free()
		decoration_ghost = null
	selected_decoration = ""

	# Refresh panel
	_close_decoration_mode()
	_open_decoration_mode()

	_play_sfx("res://audio/sfx/button_click.wav")
	SaveManager.save_game()


func _create_placed_decoration(data: Dictionary) -> void:
	var item_id = data.get("item_id", "")
	var pos = Vector2(data.position.x, data.position.y)
	var rot = data.get("rotation", 0)

	var item = ShopManager.get_item(item_id) if ShopManager else {}
	var size = item.get("size", Vector2(40, 40))

	var decoration = Node2D.new()
	decoration.name = "PlacedDecor_" + item_id
	decoration.position = pos
	decoration.rotation = rot

	# Store metadata for interaction
	decoration.set_meta("item_id", item_id)
	decoration.set_meta("item_name", item.get("name", item_id))
	decoration.set_meta("item_description", item.get("description", "A decoration"))
	decoration.set_meta("size", size)

	# Create visual based on item type
	var visual = Polygon2D.new()
	visual.name = "Visual"
	var half_w = size.x / 2
	var half_h = size.y / 2
	visual.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h), Vector2(half_w, -half_h),
		Vector2(half_w, half_h), Vector2(-half_w, half_h)
	])
	visual.color = _get_decoration_color(item_id)
	decoration.add_child(visual)

	# Add glow effect
	var glow = Polygon2D.new()
	glow.name = "Glow"
	glow.polygon = PackedVector2Array([
		Vector2(-half_w - 5, -half_h - 5), Vector2(half_w + 5, -half_h - 5),
		Vector2(half_w + 5, half_h + 5), Vector2(-half_w - 5, half_h + 5)
	])
	glow.color = Color(_get_decoration_color(item_id), 0.15)
	glow.z_index = -1
	decoration.add_child(glow)

	# Add hover highlight (initially invisible)
	var highlight = Polygon2D.new()
	highlight.name = "Highlight"
	highlight.polygon = PackedVector2Array([
		Vector2(-half_w - 3, -half_h - 3), Vector2(half_w + 3, -half_h - 3),
		Vector2(half_w + 3, half_h + 3), Vector2(-half_w - 3, half_h + 3)
	])
	highlight.color = Color(1.0, 0.9, 0.4, 0.0)  # Invisible until hovered
	highlight.z_index = 1
	decoration.add_child(highlight)

	isometric_base.add_child(decoration)
	placed_decoration_nodes.append(decoration)


func _load_placed_decorations() -> void:
	# Clear existing
	for node in placed_decoration_nodes:
		if is_instance_valid(node):
			node.queue_free()
	placed_decoration_nodes.clear()

	# Load from save data
	var decorations = GameManager.player_data.get("bedroom_decorations", [])
	for data in decorations:
		_create_placed_decoration(data)


func _clear_all_decorations() -> void:
	# Return items to collected
	var decorations = GameManager.player_data.get("bedroom_decorations", [])
	for data in decorations:
		var item_id = data.get("item_id", "")
		if item_id != "":
			if not GameManager.player_data.has("collected_decor"):
				GameManager.player_data["collected_decor"] = []
			GameManager.player_data.collected_decor.append(item_id)

	# Clear placed
	GameManager.player_data["bedroom_decorations"] = []

	# Remove visuals
	for node in placed_decoration_nodes:
		if is_instance_valid(node):
			node.queue_free()
	placed_decoration_nodes.clear()

	# Refresh panel
	_close_decoration_mode()
	_open_decoration_mode()

	SaveManager.save_game()


func _close_decoration_mode() -> void:
	decoration_mode = false
	selected_decoration = ""

	if decoration_ghost:
		decoration_ghost.queue_free()
		decoration_ghost = null

	if decoration_panel:
		decoration_panel.queue_free()
		decoration_panel = null

	if decoration_tooltip:
		decoration_tooltip.queue_free()
		decoration_tooltip = null

	hovered_decoration = null
	in_dialogue = false


func _check_decoration_hover() -> void:
	## Check if mouse is hovering over a placed decoration
	var mouse_pos = get_global_mouse_position()

	# Convert to isometric space
	var iso_mouse = (mouse_pos - isometric_base.global_position) / isometric_base.scale

	var found_decoration: Node2D = null
	var closest_dist: float = 999999.0

	for decoration in placed_decoration_nodes:
		if not is_instance_valid(decoration):
			continue

		var size = decoration.get_meta("size", Vector2(40, 40))
		var half_w = size.x / 2
		var half_h = size.y / 2
		var decor_rect = Rect2(decoration.position - Vector2(half_w, half_h), size)

		if decor_rect.has_point(iso_mouse):
			var dist = decoration.position.distance_to(iso_mouse)
			if dist < closest_dist:
				closest_dist = dist
				found_decoration = decoration

	# Update hover state
	if found_decoration != hovered_decoration:
		# Clear old highlight
		if hovered_decoration and is_instance_valid(hovered_decoration):
			var old_highlight = hovered_decoration.get_node_or_null("Highlight")
			if old_highlight:
				old_highlight.color.a = 0.0
			_hide_decoration_tooltip()

		hovered_decoration = found_decoration

		# Show new highlight
		if hovered_decoration:
			var highlight = hovered_decoration.get_node_or_null("Highlight")
			if highlight:
				highlight.color.a = 0.4
			_show_decoration_tooltip(hovered_decoration)

	# Update tooltip position if visible
	if decoration_tooltip and hovered_decoration:
		decoration_tooltip.position = get_global_mouse_position() + Vector2(15, 15)


func _show_decoration_tooltip(decoration: Node2D) -> void:
	## Show tooltip with decoration info
	if decoration_tooltip:
		decoration_tooltip.queue_free()

	var item_name = decoration.get_meta("item_name", "Decoration")
	var item_desc = decoration.get_meta("item_description", "")

	decoration_tooltip = PanelContainer.new()
	decoration_tooltip.name = "DecorationTooltip"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.15, 0.95)
	style.border_color = Color(0.6, 0.5, 0.3, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	decoration_tooltip.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	decoration_tooltip.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Item name
	var name_label = Label.new()
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	vbox.add_child(name_label)

	# Description (truncated)
	if item_desc.length() > 0:
		var desc_label = Label.new()
		var short_desc = item_desc.substr(0, 60)
		if item_desc.length() > 60:
			short_desc += "..."
		desc_label.text = short_desc
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.custom_minimum_size.x = 180
		vbox.add_child(desc_label)

	# Action hint
	var hint_label = Label.new()
	hint_label.text = "Click to pick up and reposition"
	hint_label.add_theme_font_size_override("font_size", 10)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
	vbox.add_child(hint_label)

	# Position tooltip near mouse
	decoration_tooltip.position = get_global_mouse_position() + Vector2(15, 15)
	add_child(decoration_tooltip)


func _hide_decoration_tooltip() -> void:
	if decoration_tooltip:
		decoration_tooltip.queue_free()
		decoration_tooltip = null


func _pickup_placed_decoration(decoration: Node2D) -> void:
	## Pick up a placed decoration to reposition it
	var item_id = decoration.get_meta("item_id", "")
	if item_id == "":
		return

	_play_sfx("res://audio/sfx/button_click.wav")

	# Find and remove from bedroom_decorations
	var decorations = GameManager.player_data.get("bedroom_decorations", [])
	var idx_to_remove = -1
	for i in range(decorations.size()):
		if decorations[i].get("item_id", "") == item_id:
			# Check position matches (in case of duplicates)
			var saved_pos = decorations[i].get("position", {})
			if abs(saved_pos.get("x", 0) - decoration.position.x) < 5 and abs(saved_pos.get("y", 0) - decoration.position.y) < 5:
				idx_to_remove = i
				break

	if idx_to_remove >= 0:
		decorations.remove_at(idx_to_remove)
		GameManager.player_data["bedroom_decorations"] = decorations

	# Add back to collected for re-placement
	if not GameManager.player_data.has("collected_decor"):
		GameManager.player_data["collected_decor"] = []
	GameManager.player_data.collected_decor.append(item_id)

	# Remove visual
	placed_decoration_nodes.erase(decoration)
	decoration.queue_free()

	# Clear hover state
	hovered_decoration = null
	_hide_decoration_tooltip()

	# Auto-select the picked up item for immediate re-placement
	selected_decoration = item_id
	_create_decoration_ghost(item_id)

	# Refresh the panel
	_close_decoration_mode()
	_open_decoration_mode()

	# Re-select the item
	selected_decoration = item_id
	_create_decoration_ghost(item_id)

	SaveManager.save_game()


# =============================================================================
# FOCUS ANALYTICS DASHBOARD
# =============================================================================

const DASHBOARD_BG = Color(0.06, 0.07, 0.1, 0.98)
const DASHBOARD_PANEL = Color(0.1, 0.11, 0.15, 0.95)
const DASHBOARD_ACCENT = Color(0.4, 0.7, 0.95)
const DASHBOARD_TEXT = Color(0.85, 0.88, 0.92)
const DASHBOARD_MUTED = Color(0.5, 0.52, 0.58)

var dashboard_data: Dictionary = {}
var dashboard_current_tab: String = "overview"


func _is_focus_analytics_unlocked() -> bool:
	# Unlocks after console is placed AND at least 1 focus session completed
	var console_placed = GameManager.player_data.get("console_placed_in_bedroom", false)
	var has_sessions = GameManager.player_data.get("total_focus_sessions", 0) >= 1
	return console_placed and has_sessions


func _open_focus_dashboard() -> void:
	if not _is_focus_analytics_unlocked():
		_show_dialogue("Locked Terminal", "This analytics terminal will activate after you complete your first Focus Session.\n\n*The screen flickers with potential data*")
		return

	if focus_dashboard:
		return

	_play_sfx("res://audio/sfx/menu_open.wav")
	interaction_prompt.visible = false
	in_dialogue = true

	_calculate_dashboard_data()

	focus_dashboard = Control.new()
	focus_dashboard.name = "FocusDashboard"
	focus_dashboard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(focus_dashboard)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_dashboard.add_child(dim)

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

	_create_dashboard_header(main_vbox)
	_create_dashboard_tabs(main_vbox)

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

	_show_dashboard_tab("overview")


func _calculate_dashboard_data() -> void:
	dashboard_data.clear()

	dashboard_data["total_sessions"] = GameManager.player_data.get("total_focus_sessions", 0)
	dashboard_data["total_minutes"] = GameManager.player_data.get("total_focus_minutes", 0)

	var total_mins = dashboard_data["total_minutes"]
	dashboard_data["total_hours"] = int(total_mins / 60)
	dashboard_data["remaining_minutes"] = total_mins % 60

	if dashboard_data["total_sessions"] > 0:
		dashboard_data["avg_session"] = float(total_mins) / dashboard_data["total_sessions"]
	else:
		dashboard_data["avg_session"] = 0.0

	var journal_entries = _load_dashboard_journal_entries()
	var focus_entries = []
	for entry in journal_entries:
		if entry.get("type", "") == "focus":
			focus_entries.append(entry)

	dashboard_data["focus_entries"] = focus_entries

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

	var week_sessions = 0
	var week_minutes = 0
	for date_str in daily_activity:
		week_sessions += daily_activity[date_str]["sessions"]
		week_minutes += daily_activity[date_str]["minutes"]
	dashboard_data["week_sessions"] = week_sessions
	dashboard_data["week_minutes"] = week_minutes

	var best_day = ""
	var best_minutes = 0
	for date_str in daily_activity:
		if daily_activity[date_str]["minutes"] > best_minutes:
			best_minutes = daily_activity[date_str]["minutes"]
			best_day = date_str
	dashboard_data["best_day"] = best_day
	dashboard_data["best_day_minutes"] = best_minutes

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
			if streak_days == 0 and date_str == today_str:
				checking_date -= 86400
				continue
			break
		if streak_days > 365:
			break
	dashboard_data["current_streak"] = streak_days

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


func _load_dashboard_journal_entries() -> Array:
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

	var tab_bar = focus_dashboard.get_node_or_null("MainPanel/MarginContainer/VBoxContainer/TabBar")
	if tab_bar:
		for child in tab_bar.get_children():
			if child is Button and child.name.begins_with("Tab_"):
				var btn_id = child.name.replace("Tab_", "")
				child.button_pressed = (btn_id == tab_id)

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
	var cards_row = HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 15)
	content.add_child(cards_row)

	_create_stat_card(cards_row, "Total Sessions", str(dashboard_data.get("total_sessions", 0)), DASHBOARD_ACCENT)
	_create_stat_card(cards_row, "Total Time", _format_dashboard_time(dashboard_data.get("total_minutes", 0)), Color(0.4, 0.8, 0.5))
	_create_stat_card(cards_row, "Avg Session", "%.1f min" % dashboard_data.get("avg_session", 0.0), Color(0.9, 0.7, 0.3))
	_create_stat_card(cards_row, "Current Streak", "%d days" % dashboard_data.get("current_streak", 0), Color(0.9, 0.5, 0.3))

	var graph_label = Label.new()
	graph_label.text = "Last 7 Days Activity"
	graph_label.add_theme_font_size_override("font_size", 18)
	graph_label.add_theme_color_override("font_color", DASHBOARD_TEXT)
	content.add_child(graph_label)

	_create_activity_graph(content)

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

	for date in daily_activity:
		var mins = daily_activity[date].get("minutes", 0)
		if mins > max_minutes:
			max_minutes = mins

	var dates = daily_activity.keys()
	dates.sort()
	for date_str in dates:
		var day_data = daily_activity[date_str]
		var bar_container = VBoxContainer.new()
		bar_container.add_theme_constant_override("separation", 5)
		bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bars_row.add_child(bar_container)

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

		if day_data.get("minutes", 0) > 0:
			var mins_label = Label.new()
			mins_label.text = str(day_data.get("minutes", 0))
			mins_label.add_theme_font_size_override("font_size", 10)
			mins_label.add_theme_color_override("font_color", Color.WHITE)
			mins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mins_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
			mins_label.position.y = -15
			bar.add_child(mins_label)

		var day_label = Label.new()
		var date_parts = date_str.split("-")
		if date_parts.size() >= 3:
			day_label.text = date_parts[2]
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
	if domain_stats == null:
		domain_stats = {}
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
			domain_value.text = "%d sessions, %s" % [stat.get("sessions", 0), _format_dashboard_time(stat.get("minutes", 0))]
			domain_value.add_theme_font_size_override("font_size", 14)
			domain_value.add_theme_color_override("font_color", DASHBOARD_MUTED)
			row.add_child(domain_value)


func _build_history_tab(content: VBoxContainer) -> void:
	var focus_entries = dashboard_data.get("focus_entries", [])
	if focus_entries == null:
		focus_entries = []

	if focus_entries.is_empty():
		var empty = Label.new()
		empty.text = "No focus sessions recorded yet.\n\nComplete a focus session to see your history here."
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", DASHBOARD_MUTED)
		content.add_child(empty)
		return

	focus_entries.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	var header = Label.new()
	header.text = "Recent Sessions (%d total)" % focus_entries.size()
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", DASHBOARD_TEXT)
	content.add_child(header)

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

	var date_label = Label.new()
	date_label.text = entry.get("date", "Unknown")
	date_label.add_theme_font_size_override("font_size", 14)
	date_label.add_theme_color_override("font_color", DASHBOARD_ACCENT)
	date_label.custom_minimum_size.x = 100
	hbox.add_child(date_label)

	var topic_label = Label.new()
	topic_label.text = entry.get("topic", "Focus Session")
	topic_label.add_theme_font_size_override("font_size", 14)
	topic_label.add_theme_color_override("font_color", DASHBOARD_TEXT)
	topic_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topic_label.clip_text = true
	hbox.add_child(topic_label)

	var duration_label = Label.new()
	duration_label.text = "%d min" % entry.get("duration_minutes", 0)
	duration_label.add_theme_font_size_override("font_size", 14)
	duration_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
	duration_label.custom_minimum_size.x = 60
	hbox.add_child(duration_label)

	var diff = entry.get("difficulty", "Standard")
	var diff_label = Label.new()
	diff_label.text = diff
	diff_label.add_theme_font_size_override("font_size", 12)
	diff_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3) if diff == "Hard" else DASHBOARD_MUTED)
	diff_label.custom_minimum_size.x = 60
	hbox.add_child(diff_label)


func _build_insights_tab(content: VBoxContainer) -> void:
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

	var weekly_label = Label.new()
	weekly_label.text = "This Week"
	weekly_label.add_theme_font_size_override("font_size", 18)
	weekly_label.add_theme_color_override("font_color", DASHBOARD_TEXT)
	content.add_child(weekly_label)

	var weekly_cards = HBoxContainer.new()
	weekly_cards.add_theme_constant_override("separation", 15)
	content.add_child(weekly_cards)

	_create_stat_card(weekly_cards, "Sessions", str(dashboard_data.get("week_sessions", 0)), Color(0.4, 0.7, 0.95))
	_create_stat_card(weekly_cards, "Total Time", _format_dashboard_time(dashboard_data.get("week_minutes", 0)), Color(0.4, 0.8, 0.5))

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

	var session_milestones = [10, 25, 50, 100, 250, 500]
	for milestone in session_milestones:
		if total_sessions < milestone:
			_add_milestone_bar(vbox, "%d Sessions" % milestone, total_sessions, milestone, Color(0.4, 0.7, 0.95))
			break

	var time_milestones = [60, 300, 600, 1200, 3000, 6000]
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

	var bar_bg = ColorRect.new()
	bar_bg.color = Color(0.2, 0.2, 0.25)
	bar_bg.custom_minimum_size = Vector2(0, 8)
	row.add_child(bar_bg)

	var progress = float(current) / float(target)
	var bar_fill = ColorRect.new()
	bar_fill.color = color
	bar_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	bar_fill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bar_fill.custom_minimum_size = Vector2(max(2, progress * 400), 8)
	bar_bg.add_child(bar_fill)


func _format_dashboard_time(minutes: int) -> String:
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
	in_dialogue = false
	_play_sfx("res://audio/sfx/menu_close.wav")


# =============================================================================
# TUTORIAL TOOLTIPS
# =============================================================================

const BEDROOM_TUTORIALS = {
	"bedroom_welcome": {
		"title": "Your Ship Quarters",
		"text": "This is your private space aboard the Stellar Wanderer.\n\nExplore and interact with objects to discover features.",
		"icon": "🚀"
	},
	"bedroom_console": {
		"title": "Mindscape Console",
		"text": "Put on the headset to enter your Mindscape.\n\nPress SPACE near the console to begin.",
		"icon": "🎮"
	},
	"bedroom_sleep_pod": {
		"title": "Sleep Pod",
		"text": "Save your progress, view dream memories,\nor rest and meditate here.",
		"icon": "💤"
	}
}

var tutorial_tooltip: PanelContainer = null
var tutorial_queue: Array = []

func _check_bedroom_tutorials() -> void:
	# Skip if player is waking up or in dialogue
	if GameManager.player_data.get("wakeup_from_continue", false):
		return

	# Build queue of unseen tutorials
	tutorial_queue.clear()

	if not GameManager.has_seen_tutorial("bedroom_welcome"):
		tutorial_queue.append("bedroom_welcome")

	if console_placed and not GameManager.has_seen_tutorial("bedroom_console"):
		tutorial_queue.append("bedroom_console")

	if not GameManager.has_seen_tutorial("bedroom_sleep_pod"):
		tutorial_queue.append("bedroom_sleep_pod")

	# Show first tooltip after delay - wait longer to avoid overlapping with startup dialogs
	if tutorial_queue.size() > 0:
		await get_tree().create_timer(1.5).timeout
		# Wait until any startup dialog is closed before showing tutorials
		while in_dialogue:
			await get_tree().create_timer(0.5).timeout
		_show_next_bedroom_tutorial()


func _show_next_bedroom_tutorial() -> void:
	if tutorial_queue.is_empty():
		return

	var tip_id = tutorial_queue.pop_front()
	var tip_data = BEDROOM_TUTORIALS.get(tip_id, {})

	if tip_data.is_empty():
		_show_next_bedroom_tutorial()
		return

	_create_bedroom_tooltip(tip_id, tip_data)


func _create_bedroom_tooltip(tip_id: String, tip_data: Dictionary) -> void:
	if tutorial_tooltip:
		tutorial_tooltip.queue_free()

	tutorial_tooltip = PanelContainer.new()
	tutorial_tooltip.name = "TutorialTooltip"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.15, 0.95)
	style.set_corner_radius_all(10)
	style.border_color = Color(0.5, 0.7, 0.9, 0.7)
	style.set_border_width_all(2)
	tutorial_tooltip.add_theme_stylebox_override("panel", style)

	tutorial_tooltip.set_anchors_preset(Control.PRESET_CENTER)
	tutorial_tooltip.offset_left = -180
	tutorial_tooltip.offset_right = 180
	tutorial_tooltip.offset_top = -100
	tutorial_tooltip.offset_bottom = 100

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	tutorial_tooltip.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Icon and title row
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header)

	var icon = Label.new()
	icon.text = tip_data.get("icon", "💡")
	icon.add_theme_font_size_override("font_size", 24)
	header.add_child(icon)

	var title = Label.new()
	title.text = tip_data.get("title", "Tip")
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.5, 0.75, 0.9))
	header.add_child(title)

	# Text
	var text = Label.new()
	text.text = tip_data.get("text", "")
	text.add_theme_font_size_override("font_size", 14)
	text.add_theme_color_override("font_color", Color(0.8, 0.82, 0.85))
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(text)

	# Got it button
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var got_it_btn = Button.new()
	got_it_btn.text = "Got it!"
	got_it_btn.custom_minimum_size = Vector2(100, 35)
	got_it_btn.add_theme_font_size_override("font_size", 14)
	got_it_btn.pressed.connect(func():
		GameManager.mark_tutorial_seen(tip_id)
		_close_bedroom_tutorial()
		# Show next after a short delay
		await get_tree().create_timer(0.3).timeout
		_show_next_bedroom_tutorial()
	)
	btn_row.add_child(got_it_btn)

	add_child(tutorial_tooltip)
	_play_sfx("res://audio/sfx/ui_open.wav")


func _close_bedroom_tutorial() -> void:
	if tutorial_tooltip:
		tutorial_tooltip.queue_free()
		tutorial_tooltip = null


# =============================================================================
# WEB FILE DOWNLOAD / UPLOAD (JavaScript Bridge)
# =============================================================================

func _trigger_file_download(data: String, btn: Button) -> void:
	if not OS.has_feature("web"):
		return

	# Generate filename with timestamp
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var filename = "mindscape_save_%s.json" % timestamp

	# Escape the data for embedding in JavaScript (data is already valid JSON)
	var escaped_data = data.replace("\\", "\\\\").replace("`", "\\`").replace("${", "\\${")

	# Use JavaScript to trigger download
	var js_code = """
		(function() {
			try {
				var data = `%s`;
				var blob = new Blob([data], {type: 'application/json'});
				var url = URL.createObjectURL(blob);
				var a = document.createElement('a');
				a.href = url;
				a.download = '%s';
				document.body.appendChild(a);
				a.click();
				setTimeout(function() {
					document.body.removeChild(a);
					URL.revokeObjectURL(url);
				}, 100);
				console.log('[GOACTO] Save file download triggered: ' + '%s');
			} catch(e) {
				console.error('[GOACTO] Download failed:', e);
			}
		})();
	""" % [escaped_data, filename, filename]

	JavaScriptBridge.eval(js_code)

	# Update button to show success
	btn.text = "Downloaded!"
	btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))


func _trigger_file_upload() -> void:
	if not OS.has_feature("web"):
		return

	# Create file input and set up callback
	var js_code = """
		(function() {
			// Remove any existing file input
			var existing = document.getElementById('godot-file-upload');
			if (existing) existing.remove();

			// Create file input
			var input = document.createElement('input');
			input.type = 'file';
			input.id = 'godot-file-upload';
			input.accept = '.json,application/json';
			input.style.display = 'none';

			input.onchange = function(e) {
				var file = e.target.files[0];
				if (!file) return;

				var reader = new FileReader();
				reader.onload = function(event) {
					// Store result in window for Godot to access
					window._godotUploadedFileContent = event.target.result;
					window._godotUploadReady = true;
				};
				reader.readAsText(file);
			};

			document.body.appendChild(input);
			input.click();
		})();
	"""

	JavaScriptBridge.eval(js_code)

	# Poll for file content
	_poll_for_uploaded_file()


func _poll_for_uploaded_file() -> void:
	# Check if file is ready
	var check_code = "window._godotUploadReady === true"
	var is_ready = JavaScriptBridge.eval(check_code)

	if is_ready:
		# Get the content
		var content = JavaScriptBridge.eval("window._godotUploadedFileContent")

		# Clear the JavaScript variables
		JavaScriptBridge.eval("window._godotUploadReady = false; window._godotUploadedFileContent = null;")

		# Put content in the text input
		if import_text_input and content:
			import_text_input.text = str(content)
			print("[Bedroom] File uploaded successfully")
	else:
		# Check again in 100ms
		get_tree().create_timer(0.1).timeout.connect(_poll_for_uploaded_file)
