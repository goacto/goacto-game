extends Control
## Focus Chamber - Dedicated scene for setting up focus sessions
## Uses 1/3 graphic, 2/3 menu layout

# UI References - New layout
@onready var background: ColorRect = $Background
@onready var main_panel: PanelContainer = $MainPanel
@onready var graphic_container: Control = $MainPanel/HBoxLayout/GraphicSection/GraphicContainer
@onready var chamber_visuals: Node2D = $MainPanel/HBoxLayout/GraphicSection/GraphicContainer/ChamberVisuals
@onready var title_label: Label = $MainPanel/HBoxLayout/MenuSection/Margin/VBox/HeaderRow/TitleLabel
@onready var back_button: Button = $MainPanel/HBoxLayout/MenuSection/Margin/VBox/HeaderRow/BackButton
@onready var subtitle_label: Label = $MainPanel/HBoxLayout/MenuSection/Margin/VBox/SubtitleLabel
@onready var content_scroll: ScrollContainer = $MainPanel/HBoxLayout/MenuSection/Margin/VBox/ContentScroll
@onready var content_vbox: VBoxContainer = $MainPanel/HBoxLayout/MenuSection/Margin/VBox/ContentScroll/ContentVBox

# Animation
var animation_time: float = 0.0

# Session settings
const FOCUS_DURATIONS = [15, 25, 45, 60]
var selected_duration: int = 25
var selected_difficulty: int = 0  # 0 = Standard, 1 = Hard
var selected_topic: String = ""
var selected_topic_id: String = ""
var selected_script_id: String = ""
var selected_script_lines: Array = []
var selected_script_aspect: String = ""

# Multi-step flow
enum Step { DURATION_DIFFICULTY, FOCUS_SELECTION }
enum SelectionTab { TOPICS, SCRIPTS, BLOCKS }
var current_step: Step = Step.DURATION_DIFFICULTY
var current_tab: SelectionTab = SelectionTab.TOPICS

# Dynamic UI containers
var duration_container: HBoxContainer = null
var difficulty_container: VBoxContainer = null
var tab_container: HBoxContainer = null

# Focus Block builder
var block_slots: Array = []  # Array of 4 slot dictionaries
var block_content_container: VBoxContainer = null
const MAX_BLOCK_SLOTS = 4


func _ready() -> void:
	# Load last used settings
	selected_duration = GameManager.player_data.get("last_focus_duration", 25)
	selected_difficulty = GameManager.player_data.get("last_focus_difficulty", 0)

	# Connect back button
	back_button.pressed.connect(_handle_back)

	# Create chamber visuals in graphic section
	_create_chamber_visuals()

	# Show first step
	_show_step(Step.DURATION_DIFFICULTY)

	print("[FocusChamber] Ready - 1/3, 2/3 layout")


func _process(delta: float) -> void:
	animation_time += delta
	_animate_chamber()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_handle_back()
		get_viewport().set_input_as_handled()


func _handle_back() -> void:
	# Navigate back based on current step
	match current_step:
		Step.FOCUS_SELECTION:
			# Go back to duration/difficulty selection
			_show_step(Step.DURATION_DIFFICULTY)
		Step.DURATION_DIFFICULTY:
			# Exit to hub
			_return_to_hub()


func _clear_dynamic_content() -> void:
	# Remove all children from content_vbox
	for child in content_vbox.get_children():
		child.queue_free()

	duration_container = null
	difficulty_container = null
	tab_container = null


func _show_step(step: Step) -> void:
	current_step = step
	_clear_dynamic_content()

	# Need to wait a frame for queue_free to complete
	await get_tree().process_frame

	match step:
		Step.DURATION_DIFFICULTY:
			_build_duration_difficulty_step()
		Step.FOCUS_SELECTION:
			_build_focus_selection_step()


func _build_duration_difficulty_step() -> void:
	title_label.text = "Focus Chamber"
	subtitle_label.text = "Configure your focus session"

	# Duration section
	var dur_section = _create_section_header("Duration")
	content_vbox.add_child(dur_section)

	duration_container = HBoxContainer.new()
	duration_container.add_theme_constant_override("separation", 10)
	content_vbox.add_child(duration_container)

	for dur in FOCUS_DURATIONS:
		var btn = Button.new()
		btn.name = "Dur" + str(dur)
		btn.text = str(dur) + " min"
		btn.toggle_mode = true
		btn.button_pressed = (dur == selected_duration)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_select_duration.bind(dur))
		duration_container.add_child(btn)

	_add_spacer(20)

	# Difficulty section
	var diff_section = _create_section_header("Difficulty")
	content_vbox.add_child(diff_section)

	difficulty_container = VBoxContainer.new()
	difficulty_container.add_theme_constant_override("separation", 10)
	content_vbox.add_child(difficulty_container)

	# Standard mode button with description
	var standard_row = _create_difficulty_option(
		"STANDARD",
		"Complete anytime for 0.7x XP",
		selected_difficulty == 0,
		0
	)
	difficulty_container.add_child(standard_row)

	# Hard mode button with description
	var hard_row = _create_difficulty_option(
		"HARD",
		"Complete 90%+ session for 1.5x XP",
		selected_difficulty == 1,
		1
	)
	difficulty_container.add_child(hard_row)

	_add_spacer(25)

	# Action button - prominent
	var next_btn = Button.new()
	next_btn.text = "Select Focus Topic"
	next_btn.custom_minimum_size = Vector2(0, 55)
	next_btn.add_theme_font_size_override("font_size", 20)
	next_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 0.65))
	next_btn.pressed.connect(func(): _show_step(Step.FOCUS_SELECTION))
	content_vbox.add_child(next_btn)


func _create_section_header(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	return label


func _create_difficulty_option(title: String, desc: String, is_selected: bool, diff_value: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = title + "Panel"

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)

	var radio = CheckBox.new()
	radio.name = title + "Radio"
	radio.button_pressed = is_selected
	radio.toggled.connect(func(pressed):
		_select_difficulty(diff_value)
		radio.button_pressed = true
	)
	hbox.add_child(radio)

	var text_vbox = VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 3)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 18)
	if is_selected:
		title_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		title_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	text_vbox.add_child(title_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	text_vbox.add_child(desc_lbl)

	return panel


func _build_focus_selection_step() -> void:
	title_label.text = "Select Focus"
	var diff_text = "Standard" if selected_difficulty == 0 else "Hard"
	subtitle_label.text = str(selected_duration) + " minutes  |  " + diff_text + " mode"

	# Tab buttons
	tab_container = HBoxContainer.new()
	tab_container.add_theme_constant_override("separation", 10)
	content_vbox.add_child(tab_container)

	var topics_tab = Button.new()
	topics_tab.name = "TopicsTab"
	topics_tab.text = "Topics"
	topics_tab.toggle_mode = true
	topics_tab.button_pressed = (current_tab == SelectionTab.TOPICS)
	topics_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topics_tab.custom_minimum_size = Vector2(0, 45)
	topics_tab.add_theme_font_size_override("font_size", 17)
	topics_tab.pressed.connect(func(): _switch_tab(SelectionTab.TOPICS))
	tab_container.add_child(topics_tab)

	var scripts_tab = Button.new()
	scripts_tab.name = "ScriptsTab"
	scripts_tab.text = "Scripts"
	scripts_tab.toggle_mode = true
	scripts_tab.button_pressed = (current_tab == SelectionTab.SCRIPTS)
	scripts_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scripts_tab.custom_minimum_size = Vector2(0, 45)
	scripts_tab.add_theme_font_size_override("font_size", 17)
	scripts_tab.pressed.connect(func(): _switch_tab(SelectionTab.SCRIPTS))
	tab_container.add_child(scripts_tab)

	var blocks_tab = Button.new()
	blocks_tab.name = "BlocksTab"
	blocks_tab.text = "Blocks"
	blocks_tab.toggle_mode = true
	blocks_tab.button_pressed = (current_tab == SelectionTab.BLOCKS)
	blocks_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	blocks_tab.custom_minimum_size = Vector2(0, 45)
	blocks_tab.add_theme_font_size_override("font_size", 17)
	blocks_tab.pressed.connect(func(): _switch_tab(SelectionTab.BLOCKS))
	tab_container.add_child(blocks_tab)

	_add_spacer(15)

	# Content area
	var content_area = VBoxContainer.new()
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.add_theme_constant_override("separation", 8)
	content_vbox.add_child(content_area)

	# Build content based on tab
	match current_tab:
		SelectionTab.TOPICS:
			_build_topics_content(content_area)
		SelectionTab.SCRIPTS:
			_build_scripts_content(content_area)
		SelectionTab.BLOCKS:
			_build_blocks_content(content_area)

	_add_spacer(20)

	# Back button
	var back_btn = Button.new()
	back_btn.text = "< Change Duration/Difficulty"
	back_btn.custom_minimum_size = Vector2(0, 42)
	back_btn.add_theme_font_size_override("font_size", 15)
	back_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	back_btn.pressed.connect(func(): _show_step(Step.DURATION_DIFFICULTY))
	content_vbox.add_child(back_btn)


func _switch_tab(tab: SelectionTab) -> void:
	current_tab = tab
	_show_step(Step.FOCUS_SELECTION)


func _build_topics_content(container: VBoxContainer) -> void:
	# General Focus option (no specific topic)
	var general_btn = Button.new()
	general_btn.text = "General Focus"
	general_btn.custom_minimum_size = Vector2(0, 50)
	general_btn.add_theme_font_size_override("font_size", 17)
	general_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 0.65))
	general_btn.pressed.connect(func():
		selected_topic = ""
		selected_topic_id = ""
		selected_script_id = ""
		_start_focus_session()
	)
	container.add_child(general_btn)

	# Topics from HabitManager
	if HabitManager:
		var topics = HabitManager.get_all_topics()
		if topics.size() > 0:
			_add_spacer_to(container, 10)

			var topics_header = Label.new()
			topics_header.text = "Your Topics"
			topics_header.add_theme_font_size_override("font_size", 14)
			topics_header.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
			container.add_child(topics_header)

			for topic in topics:
				var topic_row = HBoxContainer.new()
				topic_row.add_theme_constant_override("separation", 8)
				container.add_child(topic_row)

				# Topic button with session count in the label
				var sessions = topic.get("total_sessions", 0)
				var topic_btn = Button.new()
				topic_btn.text = "%s (%d)" % [topic.name, sessions]
				topic_btn.custom_minimum_size = Vector2(0, 45)
				topic_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				topic_btn.add_theme_font_size_override("font_size", 16)
				topic_btn.pressed.connect(_start_with_topic.bind(topic.id, topic.name))
				topic_row.add_child(topic_btn)

				# Delete button
				var delete_btn = Button.new()
				delete_btn.text = "x"
				delete_btn.custom_minimum_size = Vector2(35, 35)
				delete_btn.add_theme_font_size_override("font_size", 14)
				delete_btn.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
				delete_btn.add_theme_color_override("font_hover_color", Color(0.9, 0.4, 0.4))
				delete_btn.tooltip_text = "Delete topic"
				delete_btn.pressed.connect(_confirm_delete_topic_from_chamber.bind(topic.id, topic.name))
				topic_row.add_child(delete_btn)

	_add_spacer_to(container, 15)

	# Create new topic button
	var new_topic_btn = Button.new()
	new_topic_btn.text = "+ Add New Topic"
	new_topic_btn.custom_minimum_size = Vector2(0, 42)
	new_topic_btn.add_theme_font_size_override("font_size", 15)
	new_topic_btn.add_theme_color_override("font_color", Color(0.5, 0.6, 0.75))
	new_topic_btn.pressed.connect(_show_create_topic)
	container.add_child(new_topic_btn)


func _build_scripts_content(container: VBoxContainer) -> void:
	# Get all user scripts
	var all_scripts = ScriptManager.get_all_scripts() if ScriptManager else []

	if all_scripts.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "No scripts created yet.\n\nVisit the Script Lab to create\ncustom focus scripts."
		empty_label.add_theme_font_size_override("font_size", 15)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(empty_label)

		_add_spacer_to(container, 15)

		var goto_lab_btn = Button.new()
		goto_lab_btn.text = "Go to Script Lab"
		goto_lab_btn.custom_minimum_size = Vector2(0, 48)
		goto_lab_btn.add_theme_font_size_override("font_size", 16)
		goto_lab_btn.add_theme_color_override("font_color", Color(0.65, 0.5, 0.85))
		goto_lab_btn.pressed.connect(_goto_script_lab)
		container.add_child(goto_lab_btn)
	else:
		var scripts_header = Label.new()
		scripts_header.text = "Your Scripts"
		scripts_header.add_theme_font_size_override("font_size", 14)
		scripts_header.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		container.add_child(scripts_header)

		for script in all_scripts:
			var script_row = HBoxContainer.new()
			script_row.add_theme_constant_override("separation", 10)
			container.add_child(script_row)

			var script_btn = Button.new()
			script_btn.text = script.name + ".psa"
			script_btn.custom_minimum_size = Vector2(0, 45)
			script_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			script_btn.add_theme_font_size_override("font_size", 16)
			script_btn.pressed.connect(_start_with_script.bind(script))
			script_row.add_child(script_btn)

			# Execution count
			var exec_count = script.get("times_executed", 0)
			var count_label = Label.new()
			count_label.text = str(exec_count) + "x"
			count_label.add_theme_font_size_override("font_size", 14)
			count_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6) if exec_count > 0 else Color(0.4, 0.4, 0.45))
			count_label.custom_minimum_size = Vector2(40, 0)
			count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			count_label.tooltip_text = str(exec_count) + " times executed"
			script_row.add_child(count_label)


func _build_blocks_content(container: VBoxContainer) -> void:
	block_content_container = container

	# Initialize empty block slots if needed
	if block_slots.size() == 0:
		block_slots = []
		for i in range(MAX_BLOCK_SLOTS):
			block_slots.append({"type": "empty", "id": "", "name": ""})

	# Header with info
	var info_label = Label.new()
	info_label.text = "Build a block of " + str(MAX_BLOCK_SLOTS) + " focus sessions"
	info_label.add_theme_font_size_override("font_size", 13)
	info_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	container.add_child(info_label)

	_add_spacer_to(container, 10)

	# Block slots
	var slots_container = VBoxContainer.new()
	slots_container.add_theme_constant_override("separation", 8)
	container.add_child(slots_container)

	for i in range(MAX_BLOCK_SLOTS):
		var slot_row = _create_block_slot_row(i)
		slots_container.add_child(slot_row)

	_add_spacer_to(container, 15)

	# Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	container.add_child(btn_row)

	# Run block button
	var run_btn = Button.new()
	run_btn.text = "Run Block"
	run_btn.custom_minimum_size = Vector2(0, 45)
	run_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_btn.add_theme_font_size_override("font_size", 16)
	run_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 0.65))
	run_btn.pressed.connect(_run_focus_block)
	# Disable if no slots filled
	var filled_count = _count_filled_slots()
	run_btn.disabled = (filled_count == 0)
	if filled_count > 0:
		run_btn.text = "Run Block (" + str(filled_count) + " sessions)"
	btn_row.add_child(run_btn)

	_add_spacer_to(container, 10)

	# Saved blocks section
	var saved_label = Label.new()
	saved_label.text = "Saved Blocks"
	saved_label.add_theme_font_size_override("font_size", 14)
	saved_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	container.add_child(saved_label)

	var saved_blocks = _get_saved_blocks()
	if saved_blocks.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "No saved blocks yet"
		empty_label.add_theme_font_size_override("font_size", 13)
		empty_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		container.add_child(empty_label)
	else:
		for block in saved_blocks:
			var block_row = _create_saved_block_row(block)
			container.add_child(block_row)

	_add_spacer_to(container, 10)

	# Save current block button
	var save_btn = Button.new()
	save_btn.text = "+ Save Current Block"
	save_btn.custom_minimum_size = Vector2(0, 40)
	save_btn.add_theme_font_size_override("font_size", 14)
	save_btn.add_theme_color_override("font_color", Color(0.5, 0.6, 0.75))
	save_btn.pressed.connect(_show_save_block_dialog)
	save_btn.disabled = (filled_count == 0)
	container.add_child(save_btn)


func _create_block_slot_row(index: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.name = "Slot" + str(index)
	row.add_theme_constant_override("separation", 8)

	# Slot number
	var num_label = Label.new()
	num_label.text = str(index + 1) + "."
	num_label.add_theme_font_size_override("font_size", 16)
	num_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	num_label.custom_minimum_size = Vector2(25, 0)
	row.add_child(num_label)

	var slot = block_slots[index]

	# Slot button (shows current selection or "Empty")
	var slot_btn = Button.new()
	slot_btn.name = "SlotBtn"
	slot_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_btn.custom_minimum_size = Vector2(0, 40)
	slot_btn.add_theme_font_size_override("font_size", 14)

	if slot.type == "empty":
		slot_btn.text = "[ Empty - tap to add ]"
		slot_btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	else:
		var prefix = "T: " if slot.type == "topic" else "S: "
		slot_btn.text = prefix + slot.name
		slot_btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))

	slot_btn.pressed.connect(_show_slot_picker.bind(index))
	row.add_child(slot_btn)

	# Clear button (only if filled)
	if slot.type != "empty":
		var clear_btn = Button.new()
		clear_btn.text = "X"
		clear_btn.custom_minimum_size = Vector2(35, 35)
		clear_btn.add_theme_font_size_override("font_size", 14)
		clear_btn.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4))
		clear_btn.pressed.connect(_clear_block_slot.bind(index))
		row.add_child(clear_btn)

	return row


func _show_slot_picker(slot_index: int) -> void:
	# Create picker dialog
	var dialog = PanelContainer.new()
	dialog.name = "SlotPickerDialog"
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.custom_minimum_size = Vector2(340, 380)
	dialog.position = Vector2(-170, -190)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Select for Slot " + str(slot_index + 1)
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Scroll container for options
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var options_vbox = VBoxContainer.new()
	options_vbox.add_theme_constant_override("separation", 6)
	options_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(options_vbox)

	# Topics section
	var topics_header = Label.new()
	topics_header.text = "Topics"
	topics_header.add_theme_font_size_override("font_size", 14)
	topics_header.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	options_vbox.add_child(topics_header)

	# General focus
	var general_btn = Button.new()
	general_btn.text = "General Focus"
	general_btn.custom_minimum_size = Vector2(0, 38)
	general_btn.add_theme_font_size_override("font_size", 14)
	general_btn.pressed.connect(func():
		_set_block_slot(slot_index, "topic", "", "General Focus")
		dialog.queue_free()
	)
	options_vbox.add_child(general_btn)

	# User topics
	if HabitManager:
		var topics = HabitManager.get_all_topics()
		for topic in topics:
			var topic_btn = Button.new()
			topic_btn.text = topic.name
			topic_btn.custom_minimum_size = Vector2(0, 38)
			topic_btn.add_theme_font_size_override("font_size", 14)
			topic_btn.pressed.connect(func():
				_set_block_slot(slot_index, "topic", topic.id, topic.name)
				dialog.queue_free()
			)
			options_vbox.add_child(topic_btn)

	# Scripts section
	var scripts = ScriptManager.get_all_scripts() if ScriptManager else []
	if scripts.size() > 0:
		var scripts_header = Label.new()
		scripts_header.text = "Scripts"
		scripts_header.add_theme_font_size_override("font_size", 14)
		scripts_header.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		options_vbox.add_child(scripts_header)

		for script in scripts:
			var script_btn = Button.new()
			script_btn.text = script.name + ".psa"
			script_btn.custom_minimum_size = Vector2(0, 38)
			script_btn.add_theme_font_size_override("font_size", 14)
			script_btn.pressed.connect(func():
				_set_block_slot(slot_index, "script", script.id, script.name)
				dialog.queue_free()
			)
			options_vbox.add_child(script_btn)

	# Cancel button
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 40)
	cancel_btn.add_theme_font_size_override("font_size", 15)
	cancel_btn.pressed.connect(func(): dialog.queue_free())
	vbox.add_child(cancel_btn)

	add_child(dialog)


func _set_block_slot(index: int, type: String, id: String, name: String) -> void:
	block_slots[index] = {"type": type, "id": id, "name": name}
	# Refresh the blocks tab
	_show_step(Step.FOCUS_SELECTION)


func _clear_block_slot(index: int) -> void:
	block_slots[index] = {"type": "empty", "id": "", "name": ""}
	_show_step(Step.FOCUS_SELECTION)


func _count_filled_slots() -> int:
	var count = 0
	for slot in block_slots:
		if slot.type != "empty":
			count += 1
	return count


func _run_focus_block() -> void:
	# Build batch data from filled slots
	var sessions = []
	for slot in block_slots:
		if slot.type == "empty":
			continue

		var session_data = {
			"duration": selected_duration,
			"difficulty": selected_difficulty
		}

		if slot.type == "topic":
			session_data["topic"] = slot.name if slot.name != "" else "Focus Session"
			session_data["topic_id"] = slot.id
		elif slot.type == "script":
			var script = ScriptManager.scripts.get(slot.id) if ScriptManager else null
			if script:
				session_data["topic"] = script.name
				session_data["script_id"] = script.id
				session_data["lines"] = script.lines.duplicate() if script.has("lines") else []
				session_data["aspect"] = script.get("aspect", "productivity")

		sessions.append(session_data)

	if sessions.size() == 0:
		return

	# If only one session, run it directly
	if sessions.size() == 1:
		GameManager.player_data["pending_focus"] = sessions[0]
		GameManager.goto_scene("res://scenes/focus_mode/focus_mode.tscn")
		return

	# Multiple sessions - use batch mode
	# First session starts immediately, rest go in a queue
	GameManager.player_data["pending_focus"] = sessions[0]
	GameManager.player_data["focus_block_queue"] = sessions.slice(1)
	GameManager.goto_scene("res://scenes/focus_mode/focus_mode.tscn")


func _get_saved_blocks() -> Array:
	return GameManager.player_data.get("saved_focus_blocks", [])


func _save_block(name: String) -> void:
	var filled_slots = []
	for slot in block_slots:
		if slot.type != "empty":
			filled_slots.append(slot.duplicate())

	if filled_slots.size() == 0:
		return

	var block = {
		"id": str(Time.get_unix_time_from_system()),
		"name": name,
		"slots": filled_slots,
		"created": Time.get_datetime_string_from_system()
	}

	var saved = _get_saved_blocks()
	saved.append(block)
	GameManager.player_data["saved_focus_blocks"] = saved
	SaveManager.save_game()

	# Refresh
	_show_step(Step.FOCUS_SELECTION)


func _show_save_block_dialog() -> void:
	var dialog = PanelContainer.new()
	dialog.name = "SaveBlockDialog"
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.custom_minimum_size = Vector2(320, 180)
	dialog.position = Vector2(-160, -90)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Save Block"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var name_input = LineEdit.new()
	name_input.placeholder_text = "Block name..."
	name_input.custom_minimum_size = Vector2(0, 42)
	name_input.add_theme_font_size_override("font_size", 15)
	vbox.add_child(name_input)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 40)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.add_theme_font_size_override("font_size", 14)
	cancel_btn.pressed.connect(func(): dialog.queue_free())
	btn_row.add_child(cancel_btn)

	var save_btn = Button.new()
	save_btn.text = "Save"
	save_btn.custom_minimum_size = Vector2(0, 40)
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.add_theme_font_size_override("font_size", 14)
	save_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 0.65))
	save_btn.pressed.connect(func():
		var block_name = name_input.text.strip_edges()
		if block_name == "":
			block_name = "Block " + str(_get_saved_blocks().size() + 1)
		_save_block(block_name)
		dialog.queue_free()
	)
	btn_row.add_child(save_btn)

	add_child(dialog)
	name_input.grab_focus()


func _create_saved_block_row(block: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# Block name button (loads this block)
	var load_btn = Button.new()
	load_btn.text = block.name + " (" + str(block.slots.size()) + ")"
	load_btn.custom_minimum_size = Vector2(0, 38)
	load_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_btn.add_theme_font_size_override("font_size", 14)
	load_btn.pressed.connect(_load_saved_block.bind(block))
	row.add_child(load_btn)

	# Run button
	var run_btn = Button.new()
	run_btn.text = "Run"
	run_btn.custom_minimum_size = Vector2(50, 38)
	run_btn.add_theme_font_size_override("font_size", 13)
	run_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 0.65))
	run_btn.pressed.connect(_run_saved_block.bind(block))
	row.add_child(run_btn)

	# Delete button
	var del_btn = Button.new()
	del_btn.text = "X"
	del_btn.custom_minimum_size = Vector2(35, 38)
	del_btn.add_theme_font_size_override("font_size", 13)
	del_btn.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4))
	del_btn.pressed.connect(_delete_saved_block.bind(block.id))
	row.add_child(del_btn)

	return row


func _load_saved_block(block: Dictionary) -> void:
	# Load block slots into current editor
	block_slots = []
	for i in range(MAX_BLOCK_SLOTS):
		if i < block.slots.size():
			block_slots.append(block.slots[i].duplicate())
		else:
			block_slots.append({"type": "empty", "id": "", "name": ""})

	_show_step(Step.FOCUS_SELECTION)


func _run_saved_block(block: Dictionary) -> void:
	# Load and immediately run
	block_slots = []
	for slot in block.slots:
		block_slots.append(slot.duplicate())
	# Pad to MAX_BLOCK_SLOTS
	while block_slots.size() < MAX_BLOCK_SLOTS:
		block_slots.append({"type": "empty", "id": "", "name": ""})

	_run_focus_block()


func _delete_saved_block(block_id: String) -> void:
	var saved = _get_saved_blocks()
	saved = saved.filter(func(b): return b.id != block_id)
	GameManager.player_data["saved_focus_blocks"] = saved
	SaveManager.save_game()
	_show_step(Step.FOCUS_SELECTION)


func _start_with_topic(topic_id: String, topic_name: String) -> void:
	selected_topic_id = topic_id
	selected_topic = topic_name
	selected_script_id = ""
	selected_script_lines = []
	_start_focus_session()


func _start_with_script(script: Dictionary) -> void:
	selected_script_id = script.id
	selected_script_lines = script.lines.duplicate() if script.has("lines") else []
	selected_script_aspect = script.get("aspect", "productivity")
	selected_topic = script.name
	selected_topic_id = ""
	_start_focus_session()


func _select_duration(dur: int) -> void:
	selected_duration = dur
	GameManager.player_data["last_focus_duration"] = dur
	_update_duration_buttons()


func _select_difficulty(diff: int) -> void:
	selected_difficulty = diff
	GameManager.player_data["last_focus_difficulty"] = diff
	_update_difficulty_buttons()


func _update_duration_buttons() -> void:
	if not duration_container:
		return
	for btn in duration_container.get_children():
		if btn is Button:
			var dur = int(btn.text.replace(" min", ""))
			btn.button_pressed = (dur == selected_duration)


func _update_difficulty_buttons() -> void:
	if not difficulty_container:
		return

	var standard_panel = difficulty_container.get_node_or_null("STANDARDPanel")
	var hard_panel = difficulty_container.get_node_or_null("HARDPanel")

	if standard_panel:
		var radio = standard_panel.find_child("STANDARDRadio", true, false)
		if radio:
			radio.set_pressed_no_signal(selected_difficulty == 0)

	if hard_panel:
		var radio = hard_panel.find_child("HARDRadio", true, false)
		if radio:
			radio.set_pressed_no_signal(selected_difficulty == 1)


func _confirm_delete_topic_from_chamber(topic_id: String, topic_name: String) -> void:
	var dialog = PanelContainer.new()
	dialog.name = "DeleteTopicDialog"
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.offset_left = -200
	dialog.offset_right = 200
	dialog.offset_top = -120
	dialog.offset_bottom = 120

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.1, 0.98)
	style.border_color = Color(0.8, 0.4, 0.4, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	dialog.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Delete Topic?"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.5, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Remove \"%s\" and all its session history?\nThis cannot be undone." % topic_name
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.65, 0.68, 0.75))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var keep_btn = Button.new()
	keep_btn.text = "Keep"
	keep_btn.custom_minimum_size = Vector2(100, 40)
	keep_btn.add_theme_font_size_override("font_size", 16)
	keep_btn.pressed.connect(func(): dialog.queue_free())
	btn_row.add_child(keep_btn)

	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(100, 40)
	delete_btn.add_theme_font_size_override("font_size", 16)
	delete_btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	delete_btn.pressed.connect(func():
		if HabitManager and HabitManager.has_method("delete_topic"):
			HabitManager.delete_topic(topic_id)
			SaveManager.save_game()
		dialog.queue_free()
		# Refresh the topic list
		_show_step(Step.FOCUS_SELECTION)
	)
	btn_row.add_child(delete_btn)

	add_child(dialog)


func _show_create_topic() -> void:
	# Create modal dialog for topic creation
	var dialog = PanelContainer.new()
	dialog.name = "CreateTopicDialog"
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.custom_minimum_size = Vector2(360, 200)
	dialog.position = Vector2(-180, -100)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Add Topic"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var name_input = LineEdit.new()
	name_input.name = "NameInput"
	name_input.placeholder_text = "Topic name..."
	name_input.custom_minimum_size = Vector2(0, 45)
	name_input.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_input)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 42)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.add_theme_font_size_override("font_size", 15)
	cancel_btn.pressed.connect(func(): dialog.queue_free())
	btn_row.add_child(cancel_btn)

	var create_btn = Button.new()
	create_btn.text = "Add"
	create_btn.custom_minimum_size = Vector2(0, 42)
	create_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_btn.add_theme_font_size_override("font_size", 15)
	create_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 0.65))
	create_btn.pressed.connect(func():
		var topic_name = name_input.text.strip_edges()
		if topic_name != "":
			HabitManager.create_topic(topic_name)
			dialog.queue_free()
			# Refresh the topics list
			_show_step(Step.FOCUS_SELECTION)
	)
	btn_row.add_child(create_btn)

	add_child(dialog)
	name_input.grab_focus()


func _start_focus_session() -> void:
	# Set up pending focus data
	var focus_data = {
		"duration": selected_duration,
		"difficulty": selected_difficulty,
		"topic": selected_topic if selected_topic != "" else "Focus Session",
		"topic_id": selected_topic_id
	}

	# Add script data if using a script
	if selected_script_id != "":
		focus_data["script_id"] = selected_script_id
		focus_data["lines"] = selected_script_lines
		focus_data["aspect"] = selected_script_aspect

	GameManager.player_data["pending_focus"] = focus_data

	# Transition to focus mode
	GameManager.goto_scene("res://scenes/focus_mode/focus_mode.tscn")


func _return_to_hub() -> void:
	GameManager.goto_scene("res://scenes/mindscape/mindscape_hub.tscn")


func _goto_script_lab() -> void:
	# Check if Script Lab is unlocked
	if not CampaignManager.is_room_unlocked("script_lab"):
		_show_script_lab_locked_notice()
		return

	# Navigate to Southern Peaks with spawn position near Script Lab
	# Script Lab is at position (420, 20), spawn slightly below/left of it
	GameManager.player_data["custom_spawn_position"] = Vector2(350, 80)
	MindscapeRegionManager.travel_to_region("south", "focus_chamber")


func _show_script_lab_locked_notice() -> void:
	var dialog = PanelContainer.new()
	dialog.name = "ScriptLabLockedDialog"
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.custom_minimum_size = Vector2(340, 180)
	dialog.position = Vector2(-170, -90)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Script Lab Locked"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var info = Label.new()
	info.text = "The Script Lab unlocks in Chapter 8.\n\nKeep building habits and completing\nfocus sessions to progress!"
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)

	var ok_btn = Button.new()
	ok_btn.text = "OK"
	ok_btn.custom_minimum_size = Vector2(0, 42)
	ok_btn.add_theme_font_size_override("font_size", 16)
	ok_btn.pressed.connect(func(): dialog.queue_free())
	vbox.add_child(ok_btn)

	add_child(dialog)


func _add_spacer(height: int) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	content_vbox.add_child(spacer)


func _add_spacer_to(container: Control, height: int) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	container.add_child(spacer)


func _create_chamber_visuals() -> void:
	# Clear existing
	for child in chamber_visuals.get_children():
		child.queue_free()

	# Wait for layout
	await get_tree().process_frame

	# Get the center of the graphic container
	var center_x = graphic_container.size.x / 2
	var center_y = graphic_container.size.y / 2

	# Adjust if container not ready yet
	if center_x < 50:
		center_x = 200
		center_y = 300

	# Floor - isometric diamond (scaled to fit)
	var floor_poly = Polygon2D.new()
	floor_poly.color = Color(0.08, 0.1, 0.15, 1)
	floor_poly.polygon = PackedVector2Array([
		Vector2(-150, 60), Vector2(0, -30), Vector2(150, 60), Vector2(0, 140)
	])
	floor_poly.position = Vector2(center_x, center_y + 100)
	chamber_visuals.add_child(floor_poly)

	# Floor inner ring
	var inner_ring = Polygon2D.new()
	inner_ring.color = Color(0.12, 0.15, 0.22, 0.8)
	inner_ring.polygon = PackedVector2Array([
		Vector2(-80, 30), Vector2(0, -15), Vector2(80, 30), Vector2(0, 60)
	])
	inner_ring.position = Vector2(center_x, center_y + 100)
	chamber_visuals.add_child(inner_ring)

	# Central crystal (focus amplifier)
	var crystal = Polygon2D.new()
	crystal.name = "Crystal"
	crystal.color = Color(0.3, 0.6, 0.85, 0.95)
	crystal.polygon = PackedVector2Array([
		Vector2(-25, 45), Vector2(-35, -30), Vector2(0, -90),
		Vector2(35, -30), Vector2(25, 45), Vector2(0, 65)
	])
	crystal.position = Vector2(center_x, center_y + 50)
	chamber_visuals.add_child(crystal)

	# Crystal inner highlight
	var highlight = Polygon2D.new()
	highlight.name = "CrystalHighlight"
	highlight.color = Color(0.5, 0.8, 1.0, 0.4)
	highlight.polygon = PackedVector2Array([
		Vector2(-12, 24), Vector2(-16, -16), Vector2(0, -55),
		Vector2(16, -16), Vector2(12, 24), Vector2(0, 36)
	])
	highlight.position = Vector2(center_x, center_y + 50)
	chamber_visuals.add_child(highlight)

	# Crystal glow
	var glow = Polygon2D.new()
	glow.name = "CrystalGlow"
	glow.color = Color(0.4, 0.7, 1.0, 0.15)
	glow.polygon = PackedVector2Array([
		Vector2(-45, 70), Vector2(-55, -45), Vector2(0, -120),
		Vector2(55, -45), Vector2(45, 70), Vector2(0, 95)
	])
	glow.position = Vector2(center_x, center_y + 50)
	chamber_visuals.add_child(glow)

	# Floating orbs around crystal
	for i in range(5):
		var orb = Polygon2D.new()
		orb.name = "Orb" + str(i)
		orb.color = Color(0.5, 0.75, 0.95, 0.6)
		orb.polygon = PackedVector2Array([
			Vector2(-5, 0), Vector2(0, -5), Vector2(5, 0), Vector2(0, 5)
		])
		var angle = (i / 5.0) * TAU
		orb.position = Vector2(center_x + cos(angle) * 100, center_y + 20 + sin(angle) * 45)
		orb.set_meta("base_angle", angle)
		orb.set_meta("center_x", center_x)
		orb.set_meta("center_y", center_y + 20)
		chamber_visuals.add_child(orb)

	# Add ambient particles
	for i in range(8):
		var particle = Polygon2D.new()
		particle.name = "Particle" + str(i)
		var size = randf_range(2, 4)
		particle.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(0, -size),
			Vector2(size, 0), Vector2(0, size)
		])
		particle.position = Vector2(
			center_x + randf_range(-120, 120),
			center_y + randf_range(-80, 150)
		)
		particle.color = Color(0.6, 0.7, 0.95, randf_range(0.2, 0.5))
		particle.set_meta("base_pos", particle.position)
		particle.set_meta("phase", randf() * TAU)
		chamber_visuals.add_child(particle)


func _animate_chamber() -> void:
	# Get center for orb calculations
	var center_x = graphic_container.size.x / 2 if graphic_container.size.x > 50 else 200
	var center_y = graphic_container.size.y / 2 if graphic_container.size.y > 50 else 300

	# Animate crystal glow
	var glow = chamber_visuals.get_node_or_null("CrystalGlow")
	if glow:
		var pulse = sin(animation_time * 2.0) * 0.15 + 0.85
		glow.modulate.a = 0.6 * pulse

	# Animate crystal highlight
	var highlight = chamber_visuals.get_node_or_null("CrystalHighlight")
	if highlight:
		var shimmer = sin(animation_time * 3.0) * 0.1 + 0.9
		highlight.modulate.a = shimmer

	# Animate orbs
	for i in range(5):
		var orb = chamber_visuals.get_node_or_null("Orb" + str(i))
		if orb:
			var base_angle = orb.get_meta("base_angle", 0.0)
			var orb_center_x = orb.get_meta("center_x", center_x)
			var orb_center_y = orb.get_meta("center_y", center_y + 20)
			var current_angle = base_angle + animation_time * 0.4
			var float_y = sin(animation_time * 1.8 + i * 0.5) * 10
			orb.position = Vector2(
				orb_center_x + cos(current_angle) * 100,
				orb_center_y + sin(current_angle) * 45 + float_y
			)
			orb.modulate.a = 0.5 + sin(animation_time * 2.5 + i) * 0.2

	# Animate particles
	for i in range(8):
		var particle = chamber_visuals.get_node_or_null("Particle" + str(i))
		if particle:
			var base_pos = particle.get_meta("base_pos", Vector2.ZERO)
			var phase = particle.get_meta("phase", 0.0)
			var drift_x = sin(animation_time * 0.5 + phase) * 8
			var drift_y = cos(animation_time * 0.3 + phase) * 6
			particle.position = base_pos + Vector2(drift_x, drift_y)
			particle.modulate.a = 0.3 + sin(animation_time * 2.0 + phase) * 0.2
