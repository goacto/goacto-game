class_name ShipUtils
## Static utilities for ship scenes
## Provides reusable functions without requiring inheritance changes

# =============================================================================
# HEADER CONTROLS
# =============================================================================

## Create and setup header controls (volume button, save indicator)
## Returns dictionary with references to created controls
static func create_header_controls(scene: Control, menu_button: Button) -> Dictionary:
	if not menu_button:
		return {}

	var header_hbox = menu_button.get_parent()
	if not header_hbox:
		return {}

	var result = {}

	# Save indicator
	var save_indicator = Label.new()
	save_indicator.add_theme_font_size_override("font_size", 14)
	save_indicator.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	save_indicator.tooltip_text = "Current save file"
	header_hbox.add_child(save_indicator)
	header_hbox.move_child(save_indicator, menu_button.get_index())
	result["save_indicator"] = save_indicator

	# Update save indicator text
	update_save_indicator(save_indicator)

	# Volume button
	var volume_button = Button.new()
	volume_button.custom_minimum_size = Vector2(45, 45)
	volume_button.add_theme_font_size_override("font_size", 20)
	volume_button.tooltip_text = "Volume (M to mute)"
	header_hbox.add_child(volume_button)
	header_hbox.move_child(volume_button, menu_button.get_index())
	result["volume_button"] = volume_button

	# Set initial icon
	update_volume_button_icon(volume_button)

	return result


## Update save indicator label
static func update_save_indicator(save_indicator: Label) -> void:
	if not save_indicator:
		return
	var current_slot = SaveManager.current_slot
	if current_slot > 0:
		var info = SaveManager.get_slot_info(current_slot)
		save_indicator.text = info.slot_name if info.exists else "Slot %d" % current_slot
	else:
		save_indicator.text = "Auto-save"


## Update volume button icon based on mute state
static func update_volume_button_icon(volume_button: Button) -> void:
	if not volume_button:
		return
	var audio = volume_button.get_node_or_null("/root/AudioManager")
	if audio and audio.master_volume <= 0.01:
		volume_button.text = "Mute"
	else:
		volume_button.text = "Vol"


# =============================================================================
# VOLUME POPUP
# =============================================================================

## Create volume popup panel
static func create_volume_popup(scene: Control, volume_button: Button) -> PanelContainer:
	var popup = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.98)
	style.border_color = Color(0.4, 0.35, 0.6, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	popup.add_theme_stylebox_override("panel", style)
	popup.position = volume_button.global_position + Vector2(-80, volume_button.size.y + 5)
	popup.custom_minimum_size = Vector2(200, 0)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	popup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Volume"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var audio = scene.get_node_or_null("/root/AudioManager")
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
		slider.value_changed.connect(func(val): _on_volume_changed(scene, channel.to_lower(), val, volume_button))
		row.add_child(slider)

	scene.add_child(popup)
	return popup


static func _on_volume_changed(scene: Control, channel: String, value: float, volume_button: Button) -> void:
	var audio = scene.get_node_or_null("/root/AudioManager")
	if not audio:
		return
	var vol = value / 100.0
	match channel:
		"master": audio.set_master_volume(vol)
		"music": audio.set_music_volume(vol)
		"sfx": audio.set_sfx_volume(vol)
	update_volume_button_icon(volume_button)


# =============================================================================
# PAUSE MENU
# =============================================================================

## Create pause menu and return the panel reference
static func create_pause_menu(scene: Control, on_resume: Callable, on_settings: Callable, on_main_menu: Callable) -> PanelContainer:
	var pause_menu = PanelContainer.new()
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
	resume_btn.pressed.connect(on_resume)
	vbox.add_child(resume_btn)

	# Settings button
	var settings_btn = Button.new()
	settings_btn.text = "Settings"
	settings_btn.custom_minimum_size = Vector2(0, 50)
	settings_btn.add_theme_font_size_override("font_size", 20)
	settings_btn.pressed.connect(on_settings)
	vbox.add_child(settings_btn)

	# Main Menu button
	var main_menu_btn = Button.new()
	main_menu_btn.text = "Main Menu"
	main_menu_btn.custom_minimum_size = Vector2(0, 50)
	main_menu_btn.add_theme_font_size_override("font_size", 20)
	main_menu_btn.add_theme_color_override("font_color", Color(0.8, 0.6, 0.6))
	main_menu_btn.pressed.connect(on_main_menu)
	vbox.add_child(main_menu_btn)

	# Announce to screen reader
	var accessibility = scene.get_node_or_null("/root/AccessibilityManager")
	if accessibility:
		accessibility.announce("Pause menu opened. Resume, Settings, or Main Menu.")

	scene.add_child(pause_menu)
	return pause_menu


# =============================================================================
# DIALOGUE HELPERS
# =============================================================================

## Create a standard dialogue panel structure
static func create_dialogue_panel(scene: Control) -> Dictionary:
	var panel = PanelContainer.new()
	panel.name = "DialoguePanel"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.15, 0.95)
	style.border_color = Color(0.4, 0.35, 0.6, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)

	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_top = -180
	panel.offset_bottom = -30
	panel.offset_left = -350
	panel.offset_right = 350

	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.name = "DialogueTitle"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	vbox.add_child(title)

	var text = Label.new()
	text.name = "DialogueText"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 16)
	text.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	vbox.add_child(text)

	var button = Button.new()
	button.name = "DialogueButton"
	button.text = "Continue"
	button.custom_minimum_size = Vector2(120, 40)
	button.add_theme_font_size_override("font_size", 16)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	vbox.add_child(button)

	panel.visible = false
	scene.add_child(panel)

	return {
		"panel": panel,
		"title": title,
		"text": text,
		"button": button
	}


# =============================================================================
# AUDIO HELPERS
# =============================================================================

## Play ship ambient and music
static func play_ship_audio(scene: Control) -> void:
	var audio = scene.get_node_or_null("/root/AudioManager")
	if audio:
		if audio.has_method("play_music_ship"):
			audio.play_music_ship()
		if audio.has_method("play_ambient_ship"):
			audio.play_ambient_ship()


## Play a sound effect
static func play_sfx(scene: Control, sfx_path: String) -> void:
	if not ResourceLoader.exists(sfx_path):
		return

	var audio = scene.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx_from_path"):
		audio.play_sfx_from_path(sfx_path)


# =============================================================================
# ACCESSIBILITY HELPERS
# =============================================================================

## Announce scene entry for screen reader
static func announce_scene(scene: Control, scene_name: String, context: String = "") -> void:
	var accessibility = scene.get_node_or_null("/root/AccessibilityManager")
	if accessibility:
		accessibility.announce_location(scene_name, context)


## Announce nearby object for screen reader
static func announce_object(scene: Control, object_name: String, object_data: Dictionary = {}) -> void:
	var accessibility = scene.get_node_or_null("/root/AccessibilityManager")
	if accessibility:
		accessibility.announce_nearby_object(object_name, object_data)
