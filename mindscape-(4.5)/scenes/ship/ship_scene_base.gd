class_name ShipSceneBase extends Control
## Base class for ship scenes
## Contains shared functionality for dialogue, interaction, movement, and UI

# =============================================================================
# CORE UI REFERENCES
# =============================================================================

# These should be set by derived classes via @onready or in _setup_references()
var game_world: Control = null
var isometric_base: Node2D = null
var player: Node2D = null

# Interaction UI
var interaction_prompt: PanelContainer = null
var object_name_label: Label = null
var prompt_text_label: Label = null
var control_hints: HBoxContainer = null

# Dialogue UI
var dialogue_panel: PanelContainer = null
var dialogue_title: Label = null
var dialogue_text: Label = null
var dialogue_button: Button = null

# Menu
var menu_button: Button = null

# =============================================================================
# HEADER CONTROLS
# =============================================================================

var volume_button: Button = null
var save_indicator: Label = null
var volume_popup: PanelContainer = null
var is_muted: bool = false

# =============================================================================
# PLAYER & CAMERA
# =============================================================================

var player_speed: float = 250.0
var player_bounds: Rect2 = Rect2(-400, -100, 800, 200)

var camera_zoom: float = 1.0
var min_zoom: float = 0.6
var max_zoom: float = 1.5
var zoom_speed: float = 0.08

# =============================================================================
# INTERACTION STATE
# =============================================================================

var nearby_object: String = ""
var in_dialogue: bool = false
var dialogue_callback: Callable = Callable()

# Typing effect
var typing_tween: Tween = null
var dialogue_full_text: String = ""

# Auto-play dialogue settings
var auto_play_enabled: bool = false
var auto_play_delay: float = 1.5
var auto_play_timer: float = 0.0
var auto_play_waiting: bool = false

# Animation
var animation_time: float = 0.0

# Movement sound
var move_sound_timer: float = 0.0
var move_sound_interval: float = 0.35

# =============================================================================
# PAUSE MENU
# =============================================================================

var pause_menu: PanelContainer = null

# =============================================================================
# VIRTUAL METHODS (Override in derived classes)
# =============================================================================

## Return dictionary of interactive objects
func _get_interactive_objects() -> Dictionary:
	return {}

## Return dictionary of object positions
func _get_object_positions() -> Dictionary:
	return {}

## Handle interaction with specific object - override in derived class
func _interact_with_object(object_id: String) -> void:
	push_warning("[ShipSceneBase] Unhandled interaction: " + object_id)

## Scene-specific setup - called after common setup
func _setup_scene_specific() -> void:
	pass

## Scene-specific process - called each frame
func _process_scene_specific(_delta: float) -> void:
	pass

## Get isometric movement factor (some scenes use different values)
func _get_iso_movement_factor() -> float:
	return 0.5

# =============================================================================
# COMMON SETUP
# =============================================================================

func _setup_common() -> void:
	# Connect dialogue button
	if dialogue_button:
		dialogue_button.pressed.connect(_close_dialogue)

	# Connect menu button
	if menu_button:
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
	if interaction_prompt:
		interaction_prompt.visible = false
	if dialogue_panel:
		dialogue_panel.visible = false

	# Update camera
	_update_camera()


# =============================================================================
# MOVEMENT & CAMERA
# =============================================================================

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
	if not isometric_base or not player:
		return

	var screen_center = get_viewport_rect().size / 2
	var target_pos = screen_center - (player.position * camera_zoom)

	isometric_base.position = target_pos.round()
	isometric_base.scale = Vector2(camera_zoom, camera_zoom)


func _apply_zoom(amount: float) -> void:
	camera_zoom = clamp(camera_zoom + amount, min_zoom, max_zoom)
	_update_camera()


# =============================================================================
# INTERACTION
# =============================================================================

func _check_object_proximity() -> void:
	var closest_object: String = ""
	var closest_distance: float = 100.0  # Interaction radius

	var positions = _get_object_positions()
	for object_name in positions:
		var obj_pos = positions[object_name]
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
	var objects = _get_interactive_objects()
	if not objects:
		return
	var obj_data = objects.get(object_id, {})
	if not obj_data:
		return

	if object_name_label:
		object_name_label.text = obj_data.get("name", object_id)
	if prompt_text_label:
		prompt_text_label.text = obj_data.get("prompt", "Press SPACE to interact")

	if interaction_prompt:
		interaction_prompt.visible = true
	if control_hints:
		control_hints.visible = false

	# Announce to screen reader
	var accessibility = get_node_or_null("/root/AccessibilityManager")
	if accessibility:
		accessibility.announce_nearby_object(obj_data.get("name", object_id), obj_data)


func _hide_interaction_prompt() -> void:
	if interaction_prompt:
		interaction_prompt.visible = false
	if control_hints:
		control_hints.visible = true


# =============================================================================
# DIALOGUE
# =============================================================================

func _load_auto_play_settings() -> void:
	var settings = SaveManager.load_settings()
	auto_play_enabled = settings.get("auto_play_cutscenes", false)
	auto_play_delay = settings.get("auto_play_delay", 1.5)


func _show_dialogue(title: String, text: String, callback: Callable = Callable(), voice_path: String = "") -> void:
	# Load auto-play settings
	_load_auto_play_settings()

	if dialogue_title:
		dialogue_title.text = title
	dialogue_full_text = text

	if dialogue_text:
		dialogue_text.text = ""
		dialogue_text.visible_ratio = 0.0

	if dialogue_panel:
		dialogue_panel.visible = true

	in_dialogue = true
	auto_play_waiting = false
	auto_play_timer = 0.0

	if interaction_prompt:
		interaction_prompt.visible = false

	dialogue_callback = callback

	# Update button text
	if dialogue_button:
		if callback.is_valid():
			dialogue_button.text = "Yes"
		else:
			dialogue_button.text = "Continue"

	# Play voice if provided
	if voice_path != "":
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_voice_from_path"):
			audio.play_voice_from_path(voice_path)

	# Announce to screen reader (if no voice, speak the dialogue)
	if voice_path == "":
		var accessibility = get_node_or_null("/root/AccessibilityManager")
		if accessibility:
			accessibility.announce_dialog(title, text)

	# Start typing effect
	_start_typing_effect(dialogue_full_text)


func _start_typing_effect(text: String) -> void:
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()

	if not dialogue_text:
		return

	dialogue_text.text = text
	dialogue_text.visible_ratio = 0.0

	var duration = text.length() * 0.025
	duration = clamp(duration, 0.5, 6.0)

	typing_tween = create_tween()
	if typing_tween:
		typing_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)
		typing_tween.tween_callback(_on_typing_finished)


func _on_typing_finished() -> void:
	# Start auto-play countdown if enabled and no callback (simple dialogue)
	if auto_play_enabled and not dialogue_callback.is_valid():
		auto_play_waiting = true
		auto_play_timer = 0.0
		if dialogue_button:
			dialogue_button.text = "Auto... (%.1fs)" % auto_play_delay


func _skip_typing() -> void:
	var was_typing = typing_tween and typing_tween.is_valid()
	if was_typing:
		typing_tween.kill()
	if dialogue_text:
		dialogue_text.visible_ratio = 1.0
	# Trigger auto-play after skipping (only if we actually skipped)
	if was_typing:
		_on_typing_finished()


func _process_auto_play(delta: float) -> void:
	if in_dialogue and auto_play_waiting and auto_play_enabled:
		auto_play_timer += delta
		var remaining = max(0, auto_play_delay - auto_play_timer)
		if dialogue_button:
			dialogue_button.text = "Auto... (%.1fs)" % remaining
		if auto_play_timer >= auto_play_delay:
			auto_play_waiting = false
			auto_play_timer = 0.0
			_close_dialogue()


func _on_dialogue_button_pressed() -> void:
	# Cancel auto-play and close
	auto_play_waiting = false
	auto_play_timer = 0.0
	_close_dialogue()


func _close_dialogue() -> void:
	_skip_typing()
	auto_play_waiting = false
	auto_play_timer = 0.0

	if dialogue_panel:
		dialogue_panel.visible = false
	in_dialogue = false

	if dialogue_button:
		dialogue_button.text = "Continue"

	if dialogue_callback.is_valid():
		var callback = dialogue_callback
		dialogue_callback = Callable()
		callback.call()


# =============================================================================
# AUDIO
# =============================================================================

func _play_sfx(sfx_path: String, _volume_db: float = 0.0) -> void:
	if not ResourceLoader.exists(sfx_path):
		return

	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx_from_path"):
		audio.play_sfx_from_path(sfx_path)
	else:
		# Fallback
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.stream = load(sfx_path)
		sfx_player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(sfx_player)
		sfx_player.play()
		sfx_player.finished.connect(func(): sfx_player.queue_free())


# =============================================================================
# HEADER CONTROLS
# =============================================================================

func _setup_header_controls() -> void:
	if not menu_button:
		return

	var header_hbox = menu_button.get_parent()
	if not header_hbox:
		return

	# Save indicator
	save_indicator = Label.new()
	save_indicator.add_theme_font_size_override("font_size", 14)
	save_indicator.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	save_indicator.tooltip_text = "Current save file"
	_update_save_indicator()
	header_hbox.add_child(save_indicator)
	header_hbox.move_child(save_indicator, menu_button.get_index())

	# Volume button
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

func _open_pause_menu() -> void:
	if pause_menu:
		return

	in_dialogue = true
	if interaction_prompt:
		interaction_prompt.visible = false

	# Announce to screen reader
	var accessibility = get_node_or_null("/root/AccessibilityManager")
	if accessibility:
		accessibility.announce("Pause menu opened. Resume, Settings, or Main Menu.")

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
# ACCESSIBILITY
# =============================================================================

## Call this from derived class _ready() to announce the scene
func _announce_scene_entry(scene_name: String, context: String = "") -> void:
	var accessibility = get_node_or_null("/root/AccessibilityManager")
	if accessibility:
		accessibility.announce_location(scene_name, context)


# =============================================================================
# COMMON INPUT HANDLING
# =============================================================================

func _handle_common_input(event: InputEvent) -> bool:
	var viewport = get_viewport()
	if viewport == null:
		return false

	# ESC handling
	if event.is_action_pressed("ui_cancel"):
		if volume_popup:
			_close_volume_popup()
			viewport.set_input_as_handled()
			return true
		if pause_menu:
			_close_pause_menu()
			viewport.set_input_as_handled()
			return true
		if dialogue_panel and dialogue_panel.visible:
			_close_dialogue()
			viewport.set_input_as_handled()
			return true
		# Open pause menu
		_open_pause_menu()
		viewport.set_input_as_handled()
		return true

	# Block inputs when pause menu is open
	if pause_menu:
		return true

	# Dialogue interaction
	if in_dialogue:
		if event.is_action_pressed("ui_accept"):
			if dialogue_text and dialogue_text.visible_ratio < 1.0:
				_skip_typing()
			else:
				_close_dialogue()
			viewport.set_input_as_handled()
		return true

	# Object interaction
	if event.is_action_pressed("ui_accept") and nearby_object != "":
		_interact_with_object(nearby_object)
		viewport.set_input_as_handled()
		return true

	# Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(zoom_speed)
			viewport.set_input_as_handled()
			return true
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(-zoom_speed)
			viewport.set_input_as_handled()
			return true

	return false
