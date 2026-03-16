extends Control
class_name MindscapeRegionBase
## Base class for mindscape region scenes
## Provides common functionality for zones, player movement, and portal back to hub

# Game world - must be set by subclass
var game_world: Control
var isometric_base: Node2D
var player: Node2D
var zones_node: Node2D
var hub_portal: Node2D

# UI references
var interaction_prompt: PanelContainer
var zone_name_label: Label
var prompt_text_label: Label
var control_hints: HBoxContainer

# Zone panel
var zone_panel: PanelContainer
var zone_title: Label
var zone_body: VBoxContainer
var back_button: Button

# Dialogue
var dialogue_panel: PanelContainer
var speaker_name: Label
var dialogue_text: Label
var dialogue_continue: Button

# Header
var evolution_label: Label
var evolution_bar: ProgressBar
var date_label: Label
var menu_button: Button

# Header controls
var volume_button: Button = null
var save_indicator: Label = null
var volume_popup: PanelContainer = null
var is_muted: bool = false

# Pause Menu
var pause_menu: PanelContainer = null

# Region info (set by subclass)
var region_id: String = ""
var region_name: String = ""
var theme_color: Color = Color(0.5, 0.5, 0.8)

# Player movement
var player_speed: float = 300.0
var player_bounds: Rect2 = Rect2(-800, -600, 1600, 1200)

# Camera
var camera_zoom: float = 0.9
var min_zoom: float = 0.5
var max_zoom: float = 1.5
var zoom_speed: float = 0.08

# Interaction state
var nearby_zone: String = ""
var near_hub_portal: bool = false
var in_zone_panel: bool = false

# Zone data (set by subclass)
var zone_names: Dictionary = {}

# Proximity detection
var zone_positions: Dictionary = {}  # zone_id -> Vector2
var hub_portal_position: Vector2 = Vector2.ZERO
const INTERACTION_RADIUS: float = 120.0


func setup_region(config: Dictionary) -> void:
	region_id = config.get("region_id", "")
	region_name = config.get("region_name", "Region")
	theme_color = config.get("theme_color", Color(0.5, 0.5, 0.8))
	zone_names = config.get("zone_names", {})
	player_bounds = config.get("player_bounds", Rect2(-800, -600, 1600, 1200))


func initialize_region() -> void:
	# Connect UI
	if back_button:
		back_button.pressed.connect(_close_zone)
	if dialogue_continue:
		dialogue_continue.pressed.connect(_close_dialogue)
	if menu_button:
		menu_button.pressed.connect(_open_pause_menu)

	# Setup header controls (volume, save indicator)
	_setup_header_controls()

	# Setup zone interactions
	_setup_zone_interactions()
	_setup_hub_portal_interaction()

	# Position player
	_position_player_from_transition()

	# Initialize
	_update_header()
	_center_base()

	# Re-center on resize
	get_tree().root.size_changed.connect(_center_base)

	GameManager.change_state(GameManager.GameState.MINDSCAPE)

	print("[", region_name, "] Region ready")


func _setup_header_controls() -> void:
	if not menu_button:
		return

	var header_hbox = menu_button.get_parent()
	if not header_hbox:
		return

	# Create save indicator (shows current save slot name)
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

	# Check if currently muted
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

	# Position below the volume button
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

	# Title
	var title = Label.new()
	title.text = "Volume"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var audio = get_node_or_null("/root/AudioManager")

	# Master volume slider
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

	# Music volume slider
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

	# SFX volume slider
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
		# Restore to default
		audio.set_master_volume(1.0)
		is_muted = false
	else:
		# Mute
		audio.set_master_volume(0.0)
		is_muted = true

	_update_volume_button_icon()
	_close_volume_popup()


func _position_player_from_transition() -> void:
	# Check for custom spawn position override (e.g., from Focus Chamber going to Script Lab)
	if GameManager.player_data.has("custom_spawn_position"):
		var custom_pos = GameManager.player_data["custom_spawn_position"]
		GameManager.player_data.erase("custom_spawn_position")
		if player:
			player.position = custom_pos
		return

	var from_region = MindscapeRegionManager.last_portal_used
	var spawn_pos = MindscapeRegionManager.get_spawn_position(region_id, from_region)
	if player:
		player.position = spawn_pos


func _setup_zone_interactions() -> void:
	if not zones_node:
		return

	# Collect zone positions for proximity detection
	for zone in zones_node.get_children():
		zone_positions[zone.name] = zone.position


func _setup_hub_portal_interaction() -> void:
	if hub_portal:
		hub_portal_position = hub_portal.position


func _check_proximity() -> void:
	if not player:
		return

	var closest_zone: String = ""
	var closest_distance: float = INTERACTION_RADIUS
	var was_near_hub_portal = near_hub_portal
	var old_nearby_zone = nearby_zone

	# Check hub portal proximity first (takes priority)
	var portal_distance = player.position.distance_to(hub_portal_position)
	if portal_distance < INTERACTION_RADIUS:
		near_hub_portal = true
		nearby_zone = ""
		if not was_near_hub_portal:
			_show_hub_portal_prompt()
		return
	else:
		near_hub_portal = false
		if was_near_hub_portal:
			_hide_interaction_prompt()

	# Check zone proximities
	for zone_id in zone_positions:
		var zone_pos = zone_positions[zone_id]
		var distance = player.position.distance_to(zone_pos)
		if distance < closest_distance:
			closest_distance = distance
			closest_zone = zone_id

	nearby_zone = closest_zone

	# Update prompt if zone changed
	if nearby_zone != old_nearby_zone:
		if nearby_zone != "":
			_show_zone_prompt(nearby_zone)
		else:
			_hide_interaction_prompt()


func _show_zone_prompt(zone_id: String) -> void:
	if not zone_name_label or not prompt_text_label or not interaction_prompt:
		return

	zone_name_label.text = zone_names.get(zone_id, zone_id)

	var is_locked = not GameManager.is_zone_unlocked(zone_id)
	if is_locked:
		prompt_text_label.text = "LOCKED - " + GameManager.get_zone_requirement(zone_id)
		zone_name_label.modulate = Color(0.6, 0.6, 0.7)
	else:
		prompt_text_label.text = "Press SPACE to enter"
		zone_name_label.modulate = Color(1, 1, 1)

	interaction_prompt.visible = true


func _show_hub_portal_prompt() -> void:
	if not zone_name_label or not prompt_text_label or not interaction_prompt:
		return

	zone_name_label.text = "Return to Hub"
	prompt_text_label.text = "Press SPACE to travel"
	zone_name_label.modulate = Color(0.83, 0.66, 0.29)  # Gold

	interaction_prompt.visible = true


func _hide_interaction_prompt() -> void:
	if interaction_prompt:
		interaction_prompt.visible = false


func process_region(delta: float) -> void:
	# Skip if in UI
	if (zone_panel and zone_panel.visible) or (dialogue_panel and dialogue_panel.visible) or (pause_menu and pause_menu.visible):
		return

	# Check proximity to zones and portal
	_check_proximity()

	# WASD movement
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	if input_dir != Vector2.ZERO and player:
		input_dir = input_dir.normalized()

		# Isometric movement
		var iso_movement = Vector2(
			input_dir.x - input_dir.y,
			(input_dir.x + input_dir.y) * 0.5
		)

		var new_pos = player.position + iso_movement * player_speed * delta
		new_pos.x = clamp(new_pos.x, player_bounds.position.x, player_bounds.position.x + player_bounds.size.x)
		new_pos.y = clamp(new_pos.y, player_bounds.position.y, player_bounds.position.y + player_bounds.size.y)
		player.position = new_pos

	_update_camera()


func handle_input(event: InputEvent) -> void:
	var viewport = get_viewport()
	if viewport == null:
		return

	# ESC key
	if event.is_action_pressed("ui_cancel"):
		if volume_popup:
			_close_volume_popup()
		elif pause_menu and pause_menu.visible:
			_close_pause_menu()
		elif zone_panel and zone_panel.visible:
			_close_zone()
		elif dialogue_panel and dialogue_panel.visible:
			_close_dialogue()
		else:
			_open_pause_menu()
		viewport.set_input_as_handled()
		return

	# Handle interaction with SPACE/Enter
	if event.is_action_pressed("ui_accept"):
		# Skip if in UI
		if (zone_panel and zone_panel.visible) or (dialogue_panel and dialogue_panel.visible) or (pause_menu and pause_menu.visible):
			return

		if near_hub_portal:
			_travel_to_hub()
			viewport.set_input_as_handled()
			return
		elif nearby_zone != "":
			_interact_with_zone(nearby_zone)
			viewport.set_input_as_handled()
			return

	# Quick action shortcuts (only when no panels are open)
	if event is InputEventKey and event.pressed:
		var panels_closed = not (zone_panel and zone_panel.visible) and not (dialogue_panel and dialogue_panel.visible) and not (pause_menu and pause_menu.visible)
		if panels_closed:
			if event.keycode == KEY_M:
				# M - Return to hub
				_travel_to_hub()
				viewport.set_input_as_handled()
				return
			elif event.keycode == KEY_H:
				# H - Go to Daily Rituals
				GameManager.goto_scene("res://scenes/daily_rituals/daily_rituals.tscn")
				viewport.set_input_as_handled()
				return

	# Zoom with mouse wheel (only when not in a UI panel)
	if event is InputEventMouseButton:
		# Close volume popup on click outside
		if volume_popup and volume_button and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var popup_rect = Rect2(volume_popup.global_position, volume_popup.size)
			var btn_rect = Rect2(volume_button.global_position, volume_button.size)
			if not popup_rect.has_point(event.position) and not btn_rect.has_point(event.position):
				_close_volume_popup()

		# Don't zoom when zone panel or other UI is open - let scroll containers handle it
		if (zone_panel and zone_panel.visible) or (dialogue_panel and dialogue_panel.visible) or (pause_menu and pause_menu.visible):
			return

		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(zoom_speed)
			viewport.set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(-zoom_speed)
			viewport.set_input_as_handled()
			return


func _interact_with_zone(zone_id: String) -> void:
	if not GameManager.is_zone_unlocked(zone_id):
		var zone_name = zone_names.get(zone_id, zone_id)
		var requirement = GameManager.get_zone_requirement(zone_id)
		_show_dialogue("Locked", zone_name + " is not yet accessible.\n\n" + requirement)
		return

	# Override in subclass to handle specific zones
	_open_zone(zone_id)


func _open_zone(zone_id: String) -> void:
	# Default implementation - override in subclass
	_show_dialogue(zone_names.get(zone_id, zone_id), "This zone is available but not yet implemented.")


func _travel_to_hub() -> void:
	# Save current position
	if player:
		MindscapeRegionManager.save_player_position(region_id, player.position)

	# Travel to hub
	MindscapeRegionManager.travel_to_region("hub", region_id)


func _show_dialogue(title: String, text: String, callback: Callable = Callable(), voice_path: String = "") -> void:
	if not speaker_name or not dialogue_text or not dialogue_panel or not dialogue_continue:
		return

	speaker_name.text = title
	dialogue_text.text = text
	dialogue_panel.visible = true

	# Play voice if provided
	if voice_path != "":
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_voice_from_path"):
			audio.play_voice_from_path(voice_path)

	# Disconnect any previous connections
	var connections = dialogue_continue.pressed.get_connections()
	for conn in connections:
		dialogue_continue.pressed.disconnect(conn.callable)

	if callback.is_valid():
		# Close dialogue first, then call the callback
		dialogue_continue.pressed.connect(_close_dialogue_and_call.bind(callback), CONNECT_ONE_SHOT)
	else:
		dialogue_continue.pressed.connect(_close_dialogue, CONNECT_ONE_SHOT)


func _close_dialogue_and_call(callback: Callable) -> void:
	_close_dialogue()
	if callback.is_valid():
		callback.call()


func _close_dialogue() -> void:
	if dialogue_panel:
		dialogue_panel.visible = false


func _clear_zone_body() -> void:
	if not zone_body:
		return
	for child in zone_body.get_children():
		child.queue_free()


func _close_zone() -> void:
	if zone_panel:
		zone_panel.visible = false
	in_zone_panel = false


func _open_pause_menu() -> void:
	if pause_menu:
		pause_menu.visible = true


func _close_pause_menu() -> void:
	if pause_menu:
		pause_menu.visible = false


func _update_header() -> void:
	if evolution_label and evolution_bar:
		var level = GameManager.get_evolution_level()
		var progress = GameManager.get_evolution_progress()
		evolution_label.text = "Evolution " + str(level)
		evolution_bar.value = progress * 100

	if date_label:
		var date = Time.get_date_dict_from_system()
		var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
		date_label.text = months[date.month - 1] + " " + str(date.day)


func _center_base() -> void:
	await get_tree().process_frame
	_update_camera()


func _update_camera() -> void:
	if not game_world or not isometric_base or not player:
		return

	var screen_center = game_world.size / 2
	var target = screen_center - player.position * camera_zoom
	isometric_base.position = target
	isometric_base.scale = Vector2(camera_zoom, camera_zoom)


func _apply_zoom(amount: float) -> void:
	camera_zoom = clamp(camera_zoom + amount, min_zoom, max_zoom)
	_update_camera()
