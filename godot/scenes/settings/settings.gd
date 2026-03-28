extends Control
## Settings - Audio, save/load, and game settings panel
## Can be opened from main menu or in-game

signal settings_closed

# Audio sliders
@onready var master_slider: HSlider = $Panel/Margin/ScrollContainer/VBox/AudioSection/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Panel/Margin/ScrollContainer/VBox/AudioSection/MusicRow/MusicSlider
@onready var voice_slider: HSlider = $Panel/Margin/ScrollContainer/VBox/AudioSection/VoiceRow/VoiceSlider
@onready var sfx_slider: HSlider = $Panel/Margin/ScrollContainer/VBox/AudioSection/SFXRow/SFXSlider
@onready var ambient_slider: HSlider = $Panel/Margin/ScrollContainer/VBox/AudioSection/AmbientRow/AmbientSlider

# Value labels
@onready var master_value: Label = $Panel/Margin/ScrollContainer/VBox/AudioSection/MasterRow/MasterValue
@onready var music_value: Label = $Panel/Margin/ScrollContainer/VBox/AudioSection/MusicRow/MusicValue
@onready var voice_value: Label = $Panel/Margin/ScrollContainer/VBox/AudioSection/VoiceRow/VoiceValue
@onready var sfx_value: Label = $Panel/Margin/ScrollContainer/VBox/AudioSection/SFXRow/SFXValue
@onready var ambient_value: Label = $Panel/Margin/ScrollContainer/VBox/AudioSection/AmbientRow/AmbientValue

# Buttons
@onready var back_button: Button = $Panel/Margin/ScrollContainer/VBox/ButtonRow/BackButton
@onready var test_voice_button: Button = $Panel/Margin/ScrollContainer/VBox/AudioSection/TestRow/TestVoiceButton

# Accessibility UI
@onready var font_size_option: OptionButton = $Panel/Margin/ScrollContainer/VBox/AccessibilitySection/FontSizeRow/FontSizeOption
@onready var high_contrast_toggle: CheckButton = $Panel/Margin/ScrollContainer/VBox/AccessibilitySection/HighContrastRow/HighContrastToggle
@onready var reduced_motion_toggle: CheckButton = $Panel/Margin/ScrollContainer/VBox/AccessibilitySection/ReducedMotionRow/ReducedMotionToggle
@onready var colorblind_option: OptionButton = $Panel/Margin/ScrollContainer/VBox/AccessibilitySection/ColorblindRow/ColorblindOption

# Save/Load UI
@onready var slot1_label: Label = $Panel/Margin/ScrollContainer/VBox/SaveLoadSection/SlotRow1/Slot1Label
@onready var slot2_label: Label = $Panel/Margin/ScrollContainer/VBox/SaveLoadSection/SlotRow2/Slot2Label
@onready var slot3_label: Label = $Panel/Margin/ScrollContainer/VBox/SaveLoadSection/SlotRow3/Slot3Label
@onready var save1_btn: Button = $Panel/Margin/ScrollContainer/VBox/SaveLoadSection/SlotRow1/Save1
@onready var save2_btn: Button = $Panel/Margin/ScrollContainer/VBox/SaveLoadSection/SlotRow2/Save2
@onready var save3_btn: Button = $Panel/Margin/ScrollContainer/VBox/SaveLoadSection/SlotRow3/Save3
@onready var load1_btn: Button = $Panel/Margin/ScrollContainer/VBox/SaveLoadSection/SlotRow1/Load1
@onready var load2_btn: Button = $Panel/Margin/ScrollContainer/VBox/SaveLoadSection/SlotRow2/Load2
@onready var load3_btn: Button = $Panel/Margin/ScrollContainer/VBox/SaveLoadSection/SlotRow3/Load3
@onready var export1_btn: Button = $Panel/Margin/ScrollContainer/VBox/SaveLoadSection/SlotRow1/Export1
@onready var export2_btn: Button = $Panel/Margin/ScrollContainer/VBox/SaveLoadSection/SlotRow2/Export2
@onready var export3_btn: Button = $Panel/Margin/ScrollContainer/VBox/SaveLoadSection/SlotRow3/Export3
@onready var import_btn: Button = $Panel/Margin/ScrollContainer/VBox/SaveLoadSection/ImportRow/ImportButton
@onready var file_dialog: FileDialog = $FileDialog

# Track where we came from
var return_scene: String = ""
var pending_import_slot: int = 0

# Cutscene viewer
var cutscene_section: VBoxContainer = null

# Cutscene display names (in order)
const CUTSCENE_INFO = {
	"intro_part1": {"name": "Prologue: The Stellar Wanderer", "chapter": "Chapter 1"},
	"intro_part2": {"name": "First Contact", "chapter": "Chapter 1"},
	"discipline_awakens": {"name": "Discipline Awakens", "chapter": "Chapter 2"},
	"growth_begins": {"name": "Growth Begins", "chapter": "Chapter 2"},
	"vitality_awakens": {"name": "Vitality Awakens", "chapter": "Chapter 3"},
	"family_dinner": {"name": "Family Dinner", "chapter": "Chapter 3"},
	"need_direction": {"name": "Need for Direction", "chapter": "Chapter 4"},
	"wisdom_awakens": {"name": "Wisdom Awakens", "chapter": "Chapter 4"},
	"arctis_navigation": {"name": "Arctis's Guidance", "chapter": "Chapter 4"},
	"darkness_stirs": {"name": "Darkness Stirs", "chapter": "Chapter 5"},
	"courage_awakens": {"name": "Courage Awakens", "chapter": "Chapter 5"},
	"creativity_awakens": {"name": "Creativity Awakens", "chapter": "Chapter 6"},
	"compassion_awakens": {"name": "Compassion Awakens", "chapter": "Chapter 7"},
	"certification_ceremony": {"name": "Certification Ceremony", "chapter": "Finale"}
}

const CUTSCENE_ORDER = [
	"intro_part1", "intro_part2", "discipline_awakens", "growth_begins",
	"vitality_awakens", "family_dinner", "need_direction", "wisdom_awakens",
	"arctis_navigation", "darkness_stirs", "courage_awakens", "creativity_awakens",
	"compassion_awakens", "certification_ceremony"
]


func _ready() -> void:
	# Connect audio signals
	back_button.pressed.connect(_on_back)
	test_voice_button.pressed.connect(_test_voice)

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	voice_slider.value_changed.connect(_on_voice_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	ambient_slider.value_changed.connect(_on_ambient_changed)

	# Connect save/load signals
	save1_btn.pressed.connect(_save_slot.bind(1))
	save2_btn.pressed.connect(_save_slot.bind(2))
	save3_btn.pressed.connect(_save_slot.bind(3))
	load1_btn.pressed.connect(_load_slot.bind(1))
	load2_btn.pressed.connect(_load_slot.bind(2))
	load3_btn.pressed.connect(_load_slot.bind(3))
	export1_btn.pressed.connect(_export_slot.bind(1))
	export2_btn.pressed.connect(_export_slot.bind(2))
	export3_btn.pressed.connect(_export_slot.bind(3))
	import_btn.pressed.connect(_show_import_dialog)
	file_dialog.file_selected.connect(_on_file_selected)

	# Connect accessibility signals
	font_size_option.item_selected.connect(_on_font_size_changed)
	high_contrast_toggle.toggled.connect(_on_high_contrast_toggled)
	reduced_motion_toggle.toggled.connect(_on_reduced_motion_toggled)
	colorblind_option.item_selected.connect(_on_colorblind_changed)

	# Load current values
	_load_settings()
	_load_accessibility_settings()
	_update_slot_labels()

	# Setup button sounds
	_setup_ui_sounds()

	# Build cutscene theater section
	_build_cutscene_theater()

	# Build feedback section
	_build_feedback_section()

	print("[Settings] Ready")


func _setup_ui_sounds() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		return

	var all_buttons = [
		back_button, test_voice_button,
		save1_btn, save2_btn, save3_btn,
		load1_btn, load2_btn, load3_btn,
		export1_btn, export2_btn, export3_btn,
		import_btn
	]
	for btn in all_buttons:
		if btn and not btn.pressed.is_connected(audio.play_ui_click):
			btn.pressed.connect(audio.play_ui_click)


func _load_settings() -> void:
	# Get AudioManager safely
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		return

	# Set slider values from AudioManager
	master_slider.value = audio.master_volume * 100
	music_slider.value = audio.music_volume * 100
	voice_slider.value = audio.voice_volume * 100
	sfx_slider.value = audio.sfx_volume * 100
	ambient_slider.value = audio.ambient_volume * 100

	# Update labels
	_update_labels()


func _update_labels() -> void:
	master_value.text = "%d%%" % int(master_slider.value)
	music_value.text = "%d%%" % int(music_slider.value)
	voice_value.text = "%d%%" % int(voice_slider.value)
	sfx_value.text = "%d%%" % int(sfx_slider.value)
	ambient_value.text = "%d%%" % int(ambient_slider.value)


func _on_master_changed(value: float) -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.set_master_volume(value / 100.0)
	_update_labels()


func _on_music_changed(value: float) -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.set_music_volume(value / 100.0)
	_update_labels()


func _on_voice_changed(value: float) -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.set_voice_volume(value / 100.0)
	_update_labels()


func _on_sfx_changed(value: float) -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.set_sfx_volume(value / 100.0)
	_update_labels()


func _on_ambient_changed(value: float) -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.set_ambient_volume(value / 100.0)
	_update_labels()


func _test_voice() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		print("[Settings] AudioManager not available")
		return

	# Play a test voice clip if available
	var test_path = "res://audio/voice/intro_part1/s0_d0.ogg"
	if ResourceLoader.exists(test_path):
		var stream = load(test_path)
		audio.play_voice(stream)
	else:
		print("[Settings] No test voice clip found at: ", test_path)


# =============================================================================
# ACCESSIBILITY
# =============================================================================

const FONT_SIZE_OPTIONS = ["small", "medium", "large"]
const COLORBLIND_OPTIONS = ["none", "deuteranopia", "protanopia", "tritanopia"]


func _load_accessibility_settings() -> void:
	if not GameManager:
		return

	# Font size
	var font_size = GameManager.get_font_size_multiplier()
	var font_idx = 1  # Default to medium
	if font_size < 0.9:
		font_idx = 0  # Small
	elif font_size > 1.1:
		font_idx = 2  # Large
	font_size_option.select(font_idx)

	# High contrast
	high_contrast_toggle.button_pressed = GameManager.is_high_contrast()

	# Reduced motion
	reduced_motion_toggle.button_pressed = GameManager.is_reduced_motion()

	# Colorblind mode
	var cb_mode = GameManager.get_colorblind_mode()
	var cb_idx = COLORBLIND_OPTIONS.find(cb_mode)
	if cb_idx >= 0:
		colorblind_option.select(cb_idx)
	else:
		colorblind_option.select(0)


func _on_font_size_changed(idx: int) -> void:
	if idx >= 0 and idx < FONT_SIZE_OPTIONS.size():
		GameManager.set_accessibility_setting("font_size", FONT_SIZE_OPTIONS[idx])
		print("[Settings] Font size set to: ", FONT_SIZE_OPTIONS[idx])


func _on_high_contrast_toggled(pressed: bool) -> void:
	GameManager.set_accessibility_setting("high_contrast", pressed)
	print("[Settings] High contrast: ", pressed)


func _on_reduced_motion_toggled(pressed: bool) -> void:
	GameManager.set_accessibility_setting("reduced_motion", pressed)
	print("[Settings] Reduced motion: ", pressed)


func _on_colorblind_changed(idx: int) -> void:
	if idx >= 0 and idx < COLORBLIND_OPTIONS.size():
		GameManager.set_accessibility_setting("colorblind_mode", COLORBLIND_OPTIONS[idx])
		print("[Settings] Colorblind mode: ", COLORBLIND_OPTIONS[idx])


func _on_back() -> void:
	# Save settings
	SaveManager.save_game()

	settings_closed.emit()

	# Return to the scene we came from
	var return_to = return_scene
	if return_to == "":
		return_to = GameManager.previous_scene_path

	# Only fallback to main menu if we have no valid return path
	if return_to == "":
		return_to = "res://scenes/main_menu/main_menu.tscn"

	GameManager.goto_scene(return_to)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()


# =============================================================================
# SAVE / LOAD
# =============================================================================

func _update_slot_labels() -> void:
	var slot_labels = [slot1_label, slot2_label, slot3_label]
	var load_btns = [load1_btn, load2_btn, load3_btn]
	var export_btns = [export1_btn, export2_btn, export3_btn]

	for i in range(3):
		var slot = i + 1
		var info = SaveManager.get_slot_info(slot)

		if info.exists:
			slot_labels[i].text = "%s\n%s • %d days • Evo %d" % [
				info.slot_name,
				info.date_string,
				int(info.days_completed),
				int(info.evolution_level)
			]
			load_btns[i].disabled = false
			export_btns[i].disabled = false
		else:
			slot_labels[i].text = "Slot %d: Empty\nNo saved data" % slot
			load_btns[i].disabled = true
			export_btns[i].disabled = true


func _save_slot(slot: int) -> void:
	if SaveManager.save_to_slot(slot):
		_show_message("Saved to Slot %d" % slot)
		_update_slot_labels()
	else:
		_show_message("Failed to save")


func _load_slot(slot: int) -> void:
	if SaveManager.load_from_slot(slot):
		_show_message("Loaded from Slot %d" % slot)
		# Reload current scene to apply loaded data
		await get_tree().process_frame
		get_tree().reload_current_scene()
	else:
		_show_message("Failed to load")


func _export_slot(slot: int) -> void:
	var json_data = SaveManager.export_slot(slot)
	if json_data == "":
		_show_message("No save in Slot %d" % slot)
		return

	# Copy to clipboard (most portable way to export)
	DisplayServer.clipboard_set(json_data)
	_show_message("Slot %d copied to clipboard!" % slot)


func _show_import_dialog() -> void:
	# First ask which slot to import to
	_show_slot_selection_for_import()


func _show_slot_selection_for_import() -> void:
	# Create a simple dialog to select slot
	var dialog = AcceptDialog.new()
	dialog.title = "Import to which slot?"
	dialog.dialog_text = "Paste your save JSON from clipboard:"

	var vbox = VBoxContainer.new()

	var text_edit = TextEdit.new()
	text_edit.custom_minimum_size = Vector2(400, 150)
	text_edit.placeholder_text = "Paste save data here..."
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	vbox.add_child(text_edit)

	var slot_row = HBoxContainer.new()
	slot_row.alignment = BoxContainer.ALIGNMENT_CENTER

	for i in range(1, 4):
		var btn = Button.new()
		btn.text = "Import to Slot %d" % i
		btn.pressed.connect(func():
			var json_text = text_edit.text.strip_edges()
			if json_text == "":
				_show_message("No data to import")
				dialog.queue_free()
				return

			if SaveManager.import_to_slot(i, json_text):
				_show_message("Imported to Slot %d" % i)
				_update_slot_labels()
			else:
				_show_message("Invalid save data")
			dialog.queue_free()
		)
		slot_row.add_child(btn)

	vbox.add_child(slot_row)
	dialog.add_child(vbox)
	dialog.get_ok_button().hide()

	add_child(dialog)
	dialog.popup_centered()


func _on_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		_show_message("Failed to open file")
		return

	var json_text = file.get_as_text()
	file.close()

	if pending_import_slot > 0:
		if SaveManager.import_to_slot(pending_import_slot, json_text):
			_show_message("Imported to Slot %d" % pending_import_slot)
			_update_slot_labels()
		else:
			_show_message("Invalid save file")
		pending_import_slot = 0


func _show_message(text: String) -> void:
	# Create a brief popup message
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_top = -80
	label.offset_bottom = -50

	add_child(label)

	# Fade out and remove
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)


# =============================================================================
# CUTSCENE THEATER
# =============================================================================

func _build_cutscene_theater() -> void:
	# Get the VBox container and find the separator before Back button
	var vbox = $Panel/Margin/ScrollContainer/VBox
	var separator3 = $Panel/Margin/ScrollContainer/VBox/Separator3
	if not vbox or not separator3:
		return

	# Get the index to insert before Separator3
	var insert_idx = separator3.get_index()

	# Section header row with label and Play All button
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	vbox.add_child(header_row)
	vbox.move_child(header_row, insert_idx)
	insert_idx += 1

	var section_label = Label.new()
	section_label.text = "Cutscene Theater"
	section_label.add_theme_font_size_override("font_size", 16)
	section_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.7, 1))
	section_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(section_label)

	# Check for master key and count unlocked cutscenes
	var has_master = GameManager.has_master_key()
	var unlocked_cutscenes = _get_unlocked_cutscenes(has_master)

	# Play All button (only if 2+ cutscenes unlocked)
	if unlocked_cutscenes.size() >= 2:
		var play_all_btn = Button.new()
		play_all_btn.text = "Play All (%d)" % unlocked_cutscenes.size()
		play_all_btn.custom_minimum_size = Vector2(80, 24)
		play_all_btn.add_theme_font_size_override("font_size", 11)
		play_all_btn.pressed.connect(_play_all_cutscenes.bind(unlocked_cutscenes))
		header_row.add_child(play_all_btn)

		var audio = get_node_or_null("/root/AudioManager")
		if audio:
			play_all_btn.pressed.connect(audio.play_ui_click)

	# Create scrollable container for cutscenes
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 120)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	vbox.move_child(scroll, insert_idx)
	insert_idx += 1

	cutscene_section = VBoxContainer.new()
	cutscene_section.add_theme_constant_override("separation", 3)
	cutscene_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(cutscene_section)

	# Build cutscene list
	var current_chapter = ""
	for cutscene_id in CUTSCENE_ORDER:
		var info = CUTSCENE_INFO.get(cutscene_id, {"name": cutscene_id, "chapter": ""})

		# Add chapter header if new chapter
		if info.chapter != current_chapter:
			current_chapter = info.chapter
			var chapter_label = Label.new()
			chapter_label.text = current_chapter
			chapter_label.add_theme_font_size_override("font_size", 12)
			chapter_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.6))
			cutscene_section.add_child(chapter_label)

		# Create cutscene row
		var row = _create_cutscene_row(cutscene_id, info.name, has_master)
		cutscene_section.add_child(row)

	# Master key hint (insert before Separator3, which moved down)
	if not has_master:
		var hint = Label.new()
		hint.text = "Find the Master Key to unlock all cutscenes"
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(hint)
		vbox.move_child(hint, insert_idx)


func _create_cutscene_row(cutscene_id: String, display_name: String, has_master: bool) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# Check if unlocked
	var is_unlocked = CampaignManager.has_seen_cutscene(cutscene_id) or has_master

	# Cutscene name label
	var name_label = Label.new()
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.custom_minimum_size = Vector2(280, 0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if is_unlocked:
		name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	else:
		name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))

	row.add_child(name_label)

	# Play button
	var play_btn = Button.new()
	play_btn.custom_minimum_size = Vector2(55, 24)
	play_btn.add_theme_font_size_override("font_size", 11)

	if is_unlocked:
		play_btn.text = "Play"
		play_btn.pressed.connect(_play_cutscene.bind(cutscene_id))
	else:
		play_btn.text = "Locked"
		play_btn.disabled = true

	row.add_child(play_btn)

	# Connect button sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio and is_unlocked:
		play_btn.pressed.connect(audio.play_ui_click)

	return row


func _get_unlocked_cutscenes(has_master: bool) -> Array:
	var unlocked = []
	for cutscene_id in CUTSCENE_ORDER:
		if CampaignManager.has_seen_cutscene(cutscene_id) or has_master:
			unlocked.append(cutscene_id)
	return unlocked


func _play_all_cutscenes(cutscene_list: Array) -> void:
	if cutscene_list.size() == 0:
		return

	print("[Settings] Playing all cutscenes: ", cutscene_list.size(), " total")

	# First cutscene plays immediately, rest go in playlist
	var first = cutscene_list[0]
	var playlist = cutscene_list.slice(1)

	GameManager.player_data["pending_cutscene"] = first
	GameManager.player_data["cutscene_replay_mode"] = true
	if playlist.size() > 0:
		GameManager.player_data["cutscene_playlist"] = playlist

	GameManager.goto_scene("res://scenes/cutscene/cutscene.tscn")


func _play_cutscene(cutscene_id: String) -> void:
	print("[Settings] Playing cutscene: ", cutscene_id)
	GameManager.player_data["pending_cutscene"] = cutscene_id
	GameManager.player_data["cutscene_replay_mode"] = true  # Return to previous scene after
	GameManager.goto_scene("res://scenes/cutscene/cutscene.tscn")


# =============================================================================
# FEEDBACK SYSTEM
# =============================================================================

# Google Form URL for feedback
const GOOGLE_FORM_URL = "https://docs.google.com/forms/d/e/1FAIpQLSdSNUA6MVx7aP-uOkIk-VHGYg6knh9GOow_lD5Pm9FzDryW7w/viewform"

# Entry IDs for pre-filling
const FORM_ENTRY_TYPE = "entry.571787797"      # Bug Report / Feature Request
const FORM_ENTRY_DESC = "entry.1442389502"     # Description
const FORM_ENTRY_DEVICE = "entry.2028626144"   # Platform/Browser

var feedback_panel: PanelContainer = null


func _build_feedback_section() -> void:
	var vbox = $Panel/Margin/ScrollContainer/VBox
	if not vbox:
		return

	# Create feedback section
	var section = VBoxContainer.new()
	section.name = "FeedbackSection"

	# Section title
	var title = Label.new()
	title.text = "Feedback & Support"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	section.add_child(title)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	section.add_child(spacer)

	# Buttons row
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)

	# Bug Report button
	var bug_btn = Button.new()
	bug_btn.text = "Report Bug"
	bug_btn.custom_minimum_size = Vector2(120, 40)
	bug_btn.pressed.connect(_show_feedback_form.bind("bug"))
	btn_row.add_child(bug_btn)

	# Feature Request button
	var feature_btn = Button.new()
	feature_btn.text = "Request Feature"
	feature_btn.custom_minimum_size = Vector2(140, 40)
	feature_btn.pressed.connect(_show_feedback_form.bind("feature"))
	btn_row.add_child(feature_btn)

	# Reset Game button (for stuck states)
	var reset_btn = Button.new()
	reset_btn.text = "Reset Game"
	reset_btn.custom_minimum_size = Vector2(120, 40)
	reset_btn.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	reset_btn.pressed.connect(_show_reset_confirm)
	btn_row.add_child(reset_btn)

	section.add_child(btn_row)

	# Info label
	var info = Label.new()
	info.text = "Stuck? Press Ctrl+Shift+R to force reload the game."
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	section.add_child(info)

	# Add to settings panel (before ButtonRow)
	var button_row = vbox.get_node_or_null("ButtonRow")
	if button_row:
		vbox.move_child(section, button_row.get_index())
	else:
		vbox.add_child(section)


func _show_feedback_form(feedback_type: String) -> void:
	# Collect device info
	var device_info = _get_device_info()
	var platform = OS.get_name()

	# Build Google Form URL with pre-filled data
	var url = GOOGLE_FORM_URL + "?usp=pp_url"
	url += "&" + FORM_ENTRY_TYPE + "=" + ("Bug Report" if feedback_type == "bug" else "Feature Request").uri_encode()
	url += "&" + FORM_ENTRY_DEVICE + "=" + (platform + " - " + device_info).uri_encode()

	# Open in browser
	OS.shell_open(url)

	print("[Settings] Opened feedback form: ", feedback_type)


func _get_device_info() -> String:
	var info = []
	info.append("Platform: " + OS.get_name())
	info.append("Version: 0.1.0")

	# Screen info
	var screen_size = DisplayServer.window_get_size()
	info.append("Screen: %dx%d" % [screen_size.x, screen_size.y])

	# Mobile detection
	if MobileUIManager and MobileUIManager.is_mobile:
		info.append("Device: Mobile")
	else:
		info.append("Device: Desktop")

	# Game progress
	if GameManager:
		var chapter = GameManager.player_data.get("current_chapter", 1)
		var total_focus = GameManager.player_data.get("total_focus_minutes", 0)
		info.append("Chapter: %d" % chapter)
		info.append("Focus Minutes: %d" % total_focus)

	return " | ".join(info)


func _show_reset_confirm() -> void:
	# Create confirmation dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Reset Game?"
	dialog.dialog_text = "This will reload the game. Unsaved progress will be lost.\n\nContinue?"
	dialog.ok_button_text = "Reset"
	dialog.add_cancel_button("Cancel")
	dialog.confirmed.connect(_do_game_reset)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()


func _do_game_reset() -> void:
	# For web: use JavaScript to reload
	if OS.get_name() == "Web":
		JavaScriptBridge.eval("location.reload();")
	else:
		# For native: restart the scene tree
		get_tree().reload_current_scene()
