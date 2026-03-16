extends Control
## FocusMode - Focus session with journaling
## Now supports script execution with 25 lines of code

@onready var topic_label: Label = $CenterContainer/ScrollContainer/ContentCenter/VBox/TopSection/TopicLabel
@onready var timer_label: Label = $CenterContainer/ScrollContainer/ContentCenter/VBox/TopSection/TimerContainer/TimerRing/TimerLabel
@onready var status_label: Label = $CenterContainer/ScrollContainer/ContentCenter/VBox/TopSection/StatusLabel
@onready var timer_ring: Control = $CenterContainer/ScrollContainer/ContentCenter/VBox/TopSection/TimerContainer/TimerRing
@onready var ring_bg: ColorRect = $CenterContainer/ScrollContainer/ContentCenter/VBox/TopSection/TimerContainer/TimerRing/RingBG

@onready var session_panel: Control = $CenterContainer/ScrollContainer/ContentCenter/VBox/SessionPanel
@onready var journal_panel: Control = $CenterContainer/ScrollContainer/ContentCenter/VBox/JournalPanel
@onready var progress_section: Control = $CenterContainer/ScrollContainer/ContentCenter/VBox/ProgressSection
@onready var progress_bar: ProgressBar = $CenterContainer/ScrollContainer/ContentCenter/VBox/ProgressSection/ProgressBar
@onready var progress_label: Label = $CenterContainer/ScrollContainer/ContentCenter/VBox/ProgressSection/ProgressLabel

@onready var start_button: Button = $CenterContainer/ScrollContainer/ContentCenter/VBox/SessionPanel/ButtonContainer/StartButton
@onready var complete_button: Button = $CenterContainer/ScrollContainer/ContentCenter/VBox/SessionPanel/ButtonContainer/CompleteButton
@onready var cancel_button: Button = $CenterContainer/ScrollContainer/ContentCenter/VBox/SessionPanel/ButtonContainer/CancelButton
@onready var instructions_label: Label = $CenterContainer/ScrollContainer/ContentCenter/VBox/SessionPanel/Instructions

@onready var submit_button: Button = $CenterContainer/ScrollContainer/ContentCenter/VBox/JournalPanel/SubmitButton

@onready var timer: Timer = $Timer

# Session state
var session_duration_minutes: int = 25
var elapsed_seconds: int = 0
var is_running: bool = false
var current_topic: String = "Focus Session"
var current_habit_id: String = ""
var current_topic_id: String = ""

# Difficulty mode
enum DifficultyMode { EASY, HARD }
var difficulty: DifficultyMode = DifficultyMode.EASY
const EASY_XP_MULTIPLIER: float = 0.7
const HARD_XP_MULTIPLIER: float = 1.5
const HARD_MIN_COMPLETION_RATIO: float = 1.0  # Must complete entire session for hard mode

# Script mode
var script_id: String = ""
var script_lines: Array = []
var script_aspect: String = ""
var is_script_session: bool = false
var current_line_index: int = -1

# Batch mode
var is_batch_session: bool = false
var batch_script_ids: Array = []
var batch_current_index: int = 0
var batch_package_name: String = ""

# UI for script lines
var lines_container: VBoxContainer = null

# Completion state
var session_auto_completed: bool = false
var confetti_particles: Array = []

# Pomodoro break reminders
const POMODORO_INTERVAL_MINUTES: int = 25
var pomodoro_reminders_shown: Array = []  # Track which intervals we've shown reminders for
var break_reminder_panel: PanelContainer = null

# Session summary data
var summary_xp_earned: int = 0
var summary_minutes: int = 0
var summary_domain: String = ""
var summary_panel: PanelContainer = null

# Session notes (taken during active timer)
var session_notes_text: String = ""
var notes_panel: PanelContainer = null
var notes_input: TextEdit = null
var notes_collapsed: bool = true

# Journal entry mode
enum JournalMode { OPEN_ENTRY, LAG_JOURNAL }
var journal_mode: JournalMode = JournalMode.OPEN_ENTRY
var open_entry_input: TextEdit = null
var lag_container: VBoxContainer = null
var lag_learned_input: TextEdit = null
var lag_accomplished_input: TextEdit = null
var lag_goals_input: TextEdit = null
var journal_error_label: Label = null
var open_entry_btn: Button = null
var lag_journal_btn: Button = null

# Focus ambient sound options
enum AmbientOption { SILENCE, SPACE, SHIP, MINDSCAPE, RAIN, FOREST }
var selected_ambient: AmbientOption = AmbientOption.SPACE
var ambient_option_buttons: Array = []
const AMBIENT_OPTIONS = {
	AmbientOption.SILENCE: {"name": "Silence", "path": ""},
	AmbientOption.SPACE: {"name": "Deep Space", "path": "res://audio/sfx/ambient_focus_space.wav"},
	AmbientOption.SHIP: {"name": "Ship Hum", "path": "res://audio/sfx/ambient_ship_hum.wav"},
	AmbientOption.MINDSCAPE: {"name": "Mindscape", "path": "res://audio/sfx/ambient_mindscape.wav"},
	AmbientOption.RAIN: {"name": "Rain", "path": "res://audio/sfx/ambient_rain.wav"},
	AmbientOption.FOREST: {"name": "Forest", "path": "res://audio/sfx/ambient_forest.wav"}
}


func _ready() -> void:
	# Connect buttons
	start_button.pressed.connect(_on_start)
	complete_button.pressed.connect(_on_complete)
	cancel_button.pressed.connect(_on_cancel)
	submit_button.pressed.connect(_on_submit_journal)
	timer.timeout.connect(_on_timer_tick)

	# Setup ambient selector
	_setup_ambient_selector()

	# Load saved ambient preference (cast to int - JSON parsing returns floats)
	selected_ambient = int(GameManager.player_data.get("focus_ambient", AmbientOption.SPACE))
	_update_ambient_buttons()

	# Initial state
	_show_session_panel()
	complete_button.visible = false
	progress_bar.value = 0.0
	progress_label.text = "0% complete"

	# Check for batch run first
	if GameManager.player_data.has("pending_batch"):
		var batch = GameManager.player_data.pending_batch
		is_batch_session = true
		batch_script_ids = batch.script_ids
		batch_package_name = batch.package_name
		batch_current_index = 0
		if batch.has("difficulty"):
			difficulty = batch.difficulty
		GameManager.player_data.erase("pending_batch")
		_load_batch_script(0)
	# Check for single script
	elif GameManager.player_data.has("pending_focus"):
		var pending = GameManager.player_data.pending_focus
		if pending.has("topic"):
			current_topic = pending.topic
		if pending.has("habit_id"):
			current_habit_id = pending.habit_id
		if pending.has("topic_id"):
			current_topic_id = pending.topic_id
		if pending.has("duration"):
			session_duration_minutes = pending.duration
		if pending.has("script_id"):
			script_id = pending.script_id
			is_script_session = true
		if pending.has("lines"):
			script_lines = pending.lines
		if pending.has("aspect"):
			script_aspect = pending.aspect
		if pending.has("difficulty"):
			difficulty = pending.difficulty
		GameManager.player_data.erase("pending_focus")

	# Show topic with difficulty indicator
	var diff_text = "[STANDARD]" if difficulty == DifficultyMode.EASY else "[HARD]"
	topic_label.text = current_topic + " " + diff_text
	_update_timer_display()

	# Update status label with difficulty info
	var min_required = int(session_duration_minutes * HARD_MIN_COMPLETION_RATIO)
	if difficulty == DifficultyMode.EASY:
		status_label.text = "Standard Mode - Complete anytime"
		status_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
	else:
		status_label.text = "Hard Mode - Full %d minutes required" % session_duration_minutes
		status_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.4))

	# Setup script lines display if we have them
	if script_lines.size() > 0:
		_setup_script_lines_display()

	GameManager.change_state(GameManager.GameState.FOCUS_MODE)
	print("[FocusMode] Ready - ", current_topic)


func _load_batch_script(index: int) -> void:
	if index >= batch_script_ids.size():
		return

	var script = ScriptManager.scripts[batch_script_ids[index]]
	script_id = script.id
	script_lines = script.lines.duplicate()
	script_aspect = script.aspect
	current_topic = batch_package_name + " [" + str(index + 1) + "/" + str(batch_script_ids.size()) + "]\n" + script.name + ".psa"
	is_script_session = true
	session_duration_minutes = 25


func _setup_script_lines_display() -> void:
	# Create a scrollable container for script lines
	lines_container = VBoxContainer.new()
	lines_container.name = "ScriptLines"

	var header = Label.new()
	header.text = "Your script code:"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	lines_container.add_child(header)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var lines_vbox = VBoxContainer.new()
	lines_vbox.name = "LinesVBox"

	for i in range(script_lines.size()):
		if script_lines[i] == "":
			continue  # Skip empty lines

		var line_hbox = HBoxContainer.new()
		line_hbox.add_theme_constant_override("separation", 10)
		line_hbox.name = "Line_" + str(i)

		var line_num = Label.new()
		line_num.text = str(i + 1).pad_zeros(2)
		line_num.add_theme_font_size_override("font_size", 12)
		line_num.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		line_num.custom_minimum_size = Vector2(25, 0)
		line_hbox.add_child(line_num)

		var line_text = Label.new()
		line_text.text = script_lines[i]
		line_text.add_theme_font_size_override("font_size", 14)
		line_text.autowrap_mode = TextServer.AUTOWRAP_WORD
		line_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line_text.name = "LineText"
		line_hbox.add_child(line_text)

		lines_vbox.add_child(line_hbox)

	scroll.add_child(lines_vbox)
	lines_container.add_child(scroll)

	# Insert after instructions
	var instructions = session_panel.get_node_or_null("Instructions")
	if instructions:
		session_panel.add_child(lines_container)
		session_panel.move_child(lines_container, instructions.get_index() + 1)
	else:
		session_panel.add_child(lines_container)


func _show_session_panel() -> void:
	session_panel.visible = true
	progress_section.visible = true
	journal_panel.visible = false


func _show_journal_panel() -> void:
	session_panel.visible = false
	progress_section.visible = false
	journal_panel.visible = true

	# Clear old static inputs and build dynamic journal UI
	_build_journal_ui()

	# Pre-fill with session notes if any
	if session_notes_text.strip_edges() != "":
		var notes_content = "Session Notes:\n" + session_notes_text.strip_edges()
		if journal_mode == JournalMode.OPEN_ENTRY and open_entry_input:
			open_entry_input.text = notes_content
		elif lag_accomplished_input:
			lag_accomplished_input.text = notes_content


func _build_journal_ui() -> void:
	# Clear existing dynamic content (but keep title, subtitle, submit button)
	var to_remove = []
	for child in journal_panel.get_children():
		var name = child.name
		if name != "JournalTitle" and name != "JournalSubtitle" and name != "SubmitButton" and name != "Spacer1":
			to_remove.append(child)
	for child in to_remove:
		child.queue_free()

	# Mode toggle row
	var toggle_row = HBoxContainer.new()
	toggle_row.name = "ModeToggle"
	toggle_row.alignment = BoxContainer.ALIGNMENT_CENTER
	toggle_row.add_theme_constant_override("separation", 12)
	journal_panel.add_child(toggle_row)
	journal_panel.move_child(toggle_row, 3)  # After Spacer1

	open_entry_btn = Button.new()
	open_entry_btn.text = "Open Entry"
	open_entry_btn.custom_minimum_size = Vector2(140, 45)
	open_entry_btn.add_theme_font_size_override("font_size", 16)
	open_entry_btn.pressed.connect(_switch_to_open_entry)
	toggle_row.add_child(open_entry_btn)

	lag_journal_btn = Button.new()
	lag_journal_btn.text = "LAG Journal"
	lag_journal_btn.custom_minimum_size = Vector2(140, 45)
	lag_journal_btn.add_theme_font_size_override("font_size", 16)
	lag_journal_btn.pressed.connect(_switch_to_lag_journal)
	toggle_row.add_child(lag_journal_btn)

	_update_toggle_buttons()

	# Content container
	var content = VBoxContainer.new()
	content.name = "JournalContent"
	content.add_theme_constant_override("separation", 12)
	journal_panel.add_child(content)
	journal_panel.move_child(content, 4)

	# Error label (initially hidden)
	journal_error_label = Label.new()
	journal_error_label.name = "ErrorLabel"
	journal_error_label.add_theme_font_size_override("font_size", 14)
	journal_error_label.add_theme_color_override("font_color", Color(0.95, 0.4, 0.4))
	journal_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	journal_error_label.visible = false
	content.add_child(journal_error_label)

	if journal_mode == JournalMode.OPEN_ENTRY:
		_build_open_entry_ui(content)
	else:
		_build_lag_journal_ui(content)


func _build_open_entry_ui(parent: VBoxContainer) -> void:
	var hint = Label.new()
	hint.text = "Write freely about your session - what you learned, accomplished, or want to do next."
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	parent.add_child(hint)

	open_entry_input = TextEdit.new()
	open_entry_input.custom_minimum_size = Vector2(500, 200)
	open_entry_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open_entry_input.add_theme_font_size_override("font_size", 16)
	open_entry_input.placeholder_text = "Reflect on your focus session..."
	open_entry_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	parent.add_child(open_entry_input)
	open_entry_input.grab_focus()


func _build_lag_journal_ui(parent: VBoxContainer) -> void:
	lag_container = VBoxContainer.new()
	lag_container.add_theme_constant_override("separation", 15)
	parent.add_child(lag_container)

	# Lesson (L)
	var l_label = Label.new()
	l_label.text = "Lesson - What did you learn?"
	l_label.add_theme_font_size_override("font_size", 16)
	l_label.add_theme_color_override("font_color", Color(0.55, 0.7, 0.8))
	lag_container.add_child(l_label)

	lag_learned_input = TextEdit.new()
	lag_learned_input.custom_minimum_size = Vector2(500, 70)
	lag_learned_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lag_learned_input.add_theme_font_size_override("font_size", 15)
	lag_learned_input.placeholder_text = "Key insights..."
	lag_learned_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	lag_container.add_child(lag_learned_input)

	# Accomplishment (A)
	var a_label = Label.new()
	a_label.text = "Accomplishment - What did you achieve?"
	a_label.add_theme_font_size_override("font_size", 16)
	a_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.55))
	lag_container.add_child(a_label)

	lag_accomplished_input = TextEdit.new()
	lag_accomplished_input.custom_minimum_size = Vector2(500, 70)
	lag_accomplished_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lag_accomplished_input.add_theme_font_size_override("font_size", 15)
	lag_accomplished_input.placeholder_text = "Progress made..."
	lag_accomplished_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	lag_container.add_child(lag_accomplished_input)

	# Goals (G)
	var g_label = Label.new()
	g_label.text = "Goals - What's next?"
	g_label.add_theme_font_size_override("font_size", 16)
	g_label.add_theme_color_override("font_color", Color(0.8, 0.65, 0.5))
	lag_container.add_child(g_label)

	lag_goals_input = TextEdit.new()
	lag_goals_input.custom_minimum_size = Vector2(500, 70)
	lag_goals_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lag_goals_input.add_theme_font_size_override("font_size", 15)
	lag_goals_input.placeholder_text = "Next steps..."
	lag_goals_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	lag_container.add_child(lag_goals_input)

	lag_learned_input.grab_focus()


func _switch_to_open_entry() -> void:
	journal_mode = JournalMode.OPEN_ENTRY
	_build_journal_ui()


func _switch_to_lag_journal() -> void:
	journal_mode = JournalMode.LAG_JOURNAL
	_build_journal_ui()


func _update_toggle_buttons() -> void:
	if not open_entry_btn or not lag_journal_btn:
		return

	var active_color = Color(0.83, 0.66, 0.29)
	var inactive_color = Color(0.5, 0.55, 0.6)

	if journal_mode == JournalMode.OPEN_ENTRY:
		open_entry_btn.add_theme_color_override("font_color", active_color)
		lag_journal_btn.add_theme_color_override("font_color", inactive_color)
	else:
		open_entry_btn.add_theme_color_override("font_color", inactive_color)
		lag_journal_btn.add_theme_color_override("font_color", active_color)


func _create_session_notes_panel() -> void:
	# Remove existing notes panel if any
	if notes_panel:
		notes_panel.queue_free()
		notes_panel = null

	notes_panel = PanelContainer.new()
	notes_panel.name = "SessionNotesPanel"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_color = Color(0.3, 0.5, 0.4, 0.5)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	notes_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	notes_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Header row with toggle
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	vbox.add_child(header_row)

	var toggle_btn = Button.new()
	toggle_btn.name = "NotesToggle"
	toggle_btn.text = "v Session Notes"
	toggle_btn.flat = true
	toggle_btn.add_theme_font_size_override("font_size", 16)
	toggle_btn.add_theme_color_override("font_color", Color(0.5, 0.75, 0.6))
	toggle_btn.pressed.connect(_toggle_notes_panel)
	toggle_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(toggle_btn)

	var note_count = Label.new()
	note_count.name = "NoteCount"
	note_count.text = ""
	note_count.add_theme_font_size_override("font_size", 14)
	note_count.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	header_row.add_child(note_count)

	# Notes content (hidden by default)
	var notes_content = VBoxContainer.new()
	notes_content.name = "NotesContent"
	notes_content.visible = false
	notes_content.add_theme_constant_override("separation", 8)
	vbox.add_child(notes_content)

	var hint_label = Label.new()
	hint_label.text = "Capture thoughts during your session:"
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	notes_content.add_child(hint_label)

	notes_input = TextEdit.new()
	notes_input.name = "NotesInput"
	notes_input.custom_minimum_size = Vector2(350, 120)
	notes_input.add_theme_font_size_override("font_size", 15)
	notes_input.placeholder_text = "Ideas, insights, progress notes..."
	notes_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	notes_input.text_changed.connect(_on_notes_changed)
	notes_content.add_child(notes_input)

	# Position at bottom right of screen
	notes_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	notes_panel.offset_left = -400
	notes_panel.offset_top = -180
	notes_panel.offset_right = -20
	notes_panel.offset_bottom = -20

	add_child(notes_panel)

	# Start collapsed
	notes_collapsed = true
	_update_notes_toggle_text()


func _toggle_notes_panel() -> void:
	notes_collapsed = not notes_collapsed

	if notes_panel:
		var content = notes_panel.find_child("NotesContent", true, false)
		if content:
			content.visible = not notes_collapsed

	_update_notes_toggle_text()

	# Adjust panel size
	if notes_panel:
		if notes_collapsed:
			notes_panel.offset_top = -60
		else:
			notes_panel.offset_top = -220


func _update_notes_toggle_text() -> void:
	if not notes_panel:
		return

	var toggle = notes_panel.find_child("NotesToggle", true, false)
	var count_label = notes_panel.find_child("NoteCount", true, false)

	if toggle:
		if notes_collapsed:
			toggle.text = "> Session Notes"
		else:
			toggle.text = "v Session Notes"

	if count_label:
		var char_count = session_notes_text.length()
		if char_count > 0:
			count_label.text = "(%d chars)" % char_count
		else:
			count_label.text = ""


func _on_notes_changed() -> void:
	if notes_input:
		session_notes_text = notes_input.text
		_update_notes_toggle_text()


# =============================================================================
# AMBIENT SOUND SELECTION
# =============================================================================

func _setup_ambient_selector() -> void:
	# Create ambient selector container and insert into session panel
	var ambient_container = VBoxContainer.new()
	ambient_container.name = "AmbientSelector"
	ambient_container.add_theme_constant_override("separation", 8)

	# Label
	var label = Label.new()
	label.text = "Background Sound"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ambient_container.add_child(label)

	# Button row
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 8)
	ambient_container.add_child(btn_row)

	ambient_option_buttons.clear()

	# Only show available options (check if files exist)
	var available_options = [AmbientOption.SILENCE, AmbientOption.SHIP, AmbientOption.MINDSCAPE]

	# Check for additional ambient files
	if ResourceLoader.exists("res://audio/sfx/ambient_focus_space.wav"):
		available_options.insert(1, AmbientOption.SPACE)
	if ResourceLoader.exists("res://audio/sfx/ambient_rain.wav"):
		available_options.append(AmbientOption.RAIN)
	if ResourceLoader.exists("res://audio/sfx/ambient_forest.wav"):
		available_options.append(AmbientOption.FOREST)

	for option in available_options:
		var btn = Button.new()
		btn.text = AMBIENT_OPTIONS[option]["name"]
		btn.custom_minimum_size = Vector2(85, 36)
		btn.add_theme_font_size_override("font_size", 13)
		# Don't use toggle_mode - manage appearance manually for radio-button behavior
		btn.pressed.connect(_on_ambient_selected.bind(option))
		btn_row.add_child(btn)
		ambient_option_buttons.append({"button": btn, "option": option})

	# Insert into session panel before the button container
	var button_container = session_panel.get_node_or_null("ButtonContainer")
	if button_container:
		session_panel.add_child(ambient_container)
		session_panel.move_child(ambient_container, button_container.get_index())

	# Update button appearance to show current selection
	_update_ambient_buttons()


func _update_ambient_buttons() -> void:
	var current_ambient = int(selected_ambient)
	for item in ambient_option_buttons:
		var btn = item["button"] as Button
		var option = int(item["option"])
		var is_selected = (option == current_ambient)

		if is_selected:
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
			# Add a highlighted style for selected button
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.2, 0.15, 1.0)
			style.border_color = Color(0.4, 0.8, 0.5, 0.8)
			style.set_border_width_all(2)
			style.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)
		else:
			btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_stylebox_override("hover")
			btn.remove_theme_stylebox_override("pressed")


func _on_ambient_selected(option: AmbientOption) -> void:
	selected_ambient = option
	GameManager.player_data["focus_ambient"] = option
	_update_ambient_buttons()

	# If session is running, switch to the new ambient immediately
	if is_running:
		_play_focus_ambient()


func _play_focus_ambient() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		return

	# Ensure selected_ambient is an int for proper comparison
	var ambient_key = int(selected_ambient)

	# Always stop current ambient first when switching
	if audio.has_method("stop_ambient"):
		audio.stop_ambient()

	if ambient_key == AmbientOption.SILENCE:
		# Already stopped above
		return

	# Try to play the selected ambient
	var ambient_data = AMBIENT_OPTIONS.get(ambient_key, {})
	var path = ambient_data.get("path", "")

	if path == "":
		return

	# Check if file exists
	if not ResourceLoader.exists(path):
		# Fall back to existing ambients
		match ambient_key:
			AmbientOption.SHIP:
				if audio.has_method("play_ambient_ship"):
					audio.play_ambient_ship()
			AmbientOption.MINDSCAPE:
				if audio.has_method("play_ambient_mindscape"):
					audio.play_ambient_mindscape()
		return

	# Play the ambient
	if audio.has_method("play_ambient_from_path"):
		audio.play_ambient_from_path(path)
	elif audio.has_method("play_ambient"):
		var stream = load(path)
		if stream:
			audio.play_ambient(stream)


func _stop_focus_ambient() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_ambient"):
		audio.stop_ambient()


func _on_start() -> void:
	is_running = true
	elapsed_seconds = 0
	current_line_index = 0
	timer.start()

	# Play focus start sound and focus music
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		if audio.has_method("play_focus_start"):
			audio.play_focus_start()
		if audio.has_method("play_music_focus"):
			audio.play_music_focus()

		# Play selected ambient sound
		_play_focus_ambient()

	start_button.visible = false
	complete_button.visible = true
	instructions_label.text = "Focus on your task. Return when complete."
	status_label.text = "Session in progress..."
	status_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))

	# Update visual feedback
	ring_bg.color = Color(0.15, 0.2, 0.18, 1)

	_update_current_line_highlight()

	# Create session notes panel
	_create_session_notes_panel()

	print("[FocusMode] Session started")


func _on_timer_tick() -> void:
	# Handle break timer
	if break_timer_active:
		break_seconds_remaining -= 1
		_update_break_timer_display()

		if break_seconds_remaining <= 0:
			break_timer_active = false
			timer.stop()

			var btn_center = get_node_or_null("BreakButtonCenter")
			if btn_center:
				btn_center.queue_free()

			# Show break complete message then return
			status_label.text = "Break complete!"
			timer_label.text = "00:00"
			await get_tree().create_timer(1.5).timeout
			_return_to_base()
		return

	if not is_running:
		return

	elapsed_seconds += 1
	_update_timer_display()
	_update_progress()

	# Check for Pomodoro break reminder (every 25 minutes)
	_check_pomodoro_reminder()

	# Check if timer just hit zero
	var target_seconds = session_duration_minutes * 60
	if elapsed_seconds >= target_seconds and not session_auto_completed:
		session_auto_completed = true
		_trigger_completion_celebration()
		return

	# Update current line index based on elapsed time (1 line per minute)
	var new_line_index = elapsed_seconds / 60
	if new_line_index != current_line_index and new_line_index < 25:
		current_line_index = new_line_index
		_update_current_line_highlight()


func _update_progress() -> void:
	var total_seconds = session_duration_minutes * 60
	var progress = float(elapsed_seconds) / float(total_seconds)
	progress = clampf(progress, 0.0, 1.0)
	progress_bar.value = progress
	progress_label.text = "%d%% complete" % int(progress * 100)


func _check_pomodoro_reminder() -> void:
	# Check if we've hit a Pomodoro interval (25 minutes)
	var elapsed_minutes = elapsed_seconds / 60
	var pomodoro_count = elapsed_minutes / POMODORO_INTERVAL_MINUTES

	# Only show reminder at exact interval marks (25, 50, 75 min, etc.)
	if pomodoro_count > 0 and elapsed_seconds == pomodoro_count * POMODORO_INTERVAL_MINUTES * 60:
		if pomodoro_count not in pomodoro_reminders_shown:
			pomodoro_reminders_shown.append(pomodoro_count)
			_show_pomodoro_reminder(pomodoro_count)


func _show_pomodoro_reminder(pomodoro_count: int) -> void:
	# Don't show if already showing a reminder or other panel
	if break_reminder_panel or summary_panel or break_panel:
		return

	# Play notification sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_notification"):
		audio.play_notification()

	break_reminder_panel = PanelContainer.new()
	break_reminder_panel.name = "PomodoroReminder"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_color = Color(0.5, 0.7, 0.9, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	break_reminder_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	break_reminder_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title with pomodoro count
	var title = Label.new()
	if pomodoro_count >= 4:
		title.text = "Long Break Time?"
	else:
		title.text = "Pomodoro #" + str(pomodoro_count) + " Complete!"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.5, 0.75, 0.9))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Message
	var msg = Label.new()
	if pomodoro_count >= 4:
		msg.text = "You've completed " + str(pomodoro_count) + " pomodoros!\nConsider a longer 15-20 min break."
	else:
		msg.text = str(pomodoro_count * 25) + " minutes of focus achieved.\nTake a short break?"
	msg.add_theme_font_size_override("font_size", 14)
	msg.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var continue_btn = Button.new()
	continue_btn.text = "Keep Going"
	continue_btn.custom_minimum_size = Vector2(110, 40)
	continue_btn.add_theme_font_size_override("font_size", 14)
	continue_btn.pressed.connect(_dismiss_pomodoro_reminder)
	btn_row.add_child(continue_btn)

	var break_btn = Button.new()
	break_btn.text = "Take Break"
	break_btn.custom_minimum_size = Vector2(110, 40)
	break_btn.add_theme_font_size_override("font_size", 14)
	break_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	break_btn.pressed.connect(_take_pomodoro_break)
	btn_row.add_child(break_btn)

	# Position at top of screen
	break_reminder_panel.position = Vector2(
		(get_viewport_rect().size.x - 300) / 2,
		50
	)
	break_reminder_panel.custom_minimum_size = Vector2(300, 0)

	add_child(break_reminder_panel)

	# Auto-dismiss after 10 seconds if no action
	await get_tree().create_timer(10.0).timeout
	_dismiss_pomodoro_reminder()


func _dismiss_pomodoro_reminder() -> void:
	if break_reminder_panel and is_instance_valid(break_reminder_panel):
		break_reminder_panel.queue_free()
		break_reminder_panel = null


func _take_pomodoro_break() -> void:
	_dismiss_pomodoro_reminder()

	# Pause the session timer temporarily
	is_running = false

	# Show a mini-break timer (5 minutes)
	_show_mini_break()


func _show_mini_break() -> void:
	var mini_break = PanelContainer.new()
	mini_break.name = "MiniBreak"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.1, 0.98)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = Color(0.4, 0.7, 0.5, 0.5)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	mini_break.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	mini_break.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Break Time"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var timer_lbl = Label.new()
	timer_lbl.name = "MiniBreakTimer"
	timer_lbl.text = "5:00"
	timer_lbl.add_theme_font_size_override("font_size", 48)
	timer_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(timer_lbl)

	var tip = Label.new()
	tip.text = "Stretch, hydrate, rest your eyes"
	tip.add_theme_font_size_override("font_size", 16)
	tip.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tip)

	var resume_btn = Button.new()
	resume_btn.text = "Resume Session"
	resume_btn.custom_minimum_size = Vector2(200, 50)
	resume_btn.add_theme_font_size_override("font_size", 18)
	resume_btn.pressed.connect(func():
		mini_break.queue_free()
		is_running = true
		status_label.text = "Focus Session Active"
	)
	vbox.add_child(resume_btn)

	mini_break.position = Vector2(
		(get_viewport_rect().size.x - 350) / 2,
		(get_viewport_rect().size.y - 280) / 2
	)
	mini_break.custom_minimum_size = Vector2(350, 0)

	add_child(mini_break)

	# Run mini break countdown
	var break_secs = 300  # 5 minutes
	while break_secs > 0 and is_instance_valid(mini_break):
		var mins = break_secs / 60
		var secs = break_secs % 60
		var timer_node = mini_break.find_child("MiniBreakTimer", true, false)
		if timer_node:
			timer_node.text = "%d:%02d" % [mins, secs]
		await get_tree().create_timer(1.0).timeout
		break_secs -= 1

	# Auto-resume after break
	if is_instance_valid(mini_break):
		mini_break.queue_free()
		is_running = true
		status_label.text = "Focus Session Active"


func _update_current_line_highlight() -> void:
	if not lines_container:
		return

	var lines_vbox = lines_container.find_child("LinesVBox", true, false)
	if not lines_vbox:
		return

	# Highlight current line, dim completed lines
	for i in range(lines_vbox.get_child_count()):
		var line_hbox = lines_vbox.get_child(i)
		var line_text = line_hbox.find_child("LineText", false, false)
		if line_text:
			if i < current_line_index:
				# Completed
				line_text.add_theme_color_override("font_color", Color(0.4, 0.6, 0.4))
			elif i == current_line_index:
				# Current
				line_text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
				line_text.add_theme_font_size_override("font_size", 16)
			else:
				# Upcoming
				line_text.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))


func _update_timer_display() -> void:
	var target_seconds = session_duration_minutes * 60
	var remaining = max(0, target_seconds - elapsed_seconds)

	if elapsed_seconds >= target_seconds:
		var overtime = elapsed_seconds - target_seconds
		timer_label.text = "+" + _format_time(overtime)
		timer_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		status_label.text = "Time Complete"
	else:
		timer_label.text = _format_time(remaining)


func _format_time(seconds: int) -> String:
	var mins = seconds / 60
	var secs = seconds % 60
	return "%02d:%02d" % [mins, secs]


func _on_complete() -> void:
	# In hard mode, check if minimum time has been reached
	if difficulty == DifficultyMode.HARD:
		var target_seconds = session_duration_minutes * 60
		var min_seconds_required = int(target_seconds * HARD_MIN_COMPLETION_RATIO)
		if elapsed_seconds < min_seconds_required:
			var remaining_seconds = min_seconds_required - elapsed_seconds
			var remaining_mins = remaining_seconds / 60
			var remaining_secs = remaining_seconds % 60
			if remaining_mins > 0:
				status_label.text = "Hard Mode: %d:%02d more required" % [remaining_mins, remaining_secs]
			else:
				status_label.text = "Hard Mode: %d sec more required" % remaining_secs
			status_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
			return

	is_running = false
	timer.stop()

	# Show session summary before journal
	_show_session_summary()


var cancel_dialog: PanelContainer = null

func _on_cancel() -> void:
	# Show confirmation if session has been running for more than 1 minute
	if elapsed_seconds > 60:
		_show_cancel_confirmation()
	else:
		_return_to_base()


func _show_cancel_confirmation() -> void:
	if cancel_dialog:
		return  # Already showing

	cancel_dialog = PanelContainer.new()
	cancel_dialog.name = "CancelConfirmation"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.15, 0.98)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = Color(0.8, 0.4, 0.3, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	cancel_dialog.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	cancel_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Cancel Session?"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.6, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Message
	var minutes_elapsed = elapsed_seconds / 60
	var msg = Label.new()
	msg.text = "You've been focused for %d minute%s.\nAre you sure you want to cancel?" % [minutes_elapsed, "s" if minutes_elapsed != 1 else ""]
	msg.add_theme_font_size_override("font_size", 18)
	msg.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var continue_btn = Button.new()
	continue_btn.text = "Keep Going"
	continue_btn.custom_minimum_size = Vector2(150, 50)
	continue_btn.add_theme_font_size_override("font_size", 18)
	continue_btn.pressed.connect(_dismiss_cancel_dialog)
	btn_row.add_child(continue_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel Session"
	cancel_btn.custom_minimum_size = Vector2(150, 50)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	cancel_btn.add_theme_color_override("font_color", Color(0.9, 0.5, 0.4))
	cancel_btn.pressed.connect(_confirm_cancel)
	btn_row.add_child(cancel_btn)

	# Center the dialog
	cancel_dialog.position = Vector2(
		(get_viewport_rect().size.x - 400) / 2,
		(get_viewport_rect().size.y - 220) / 2
	)
	cancel_dialog.custom_minimum_size = Vector2(400, 0)

	add_child(cancel_dialog)

	# Pause timer while dialog is showing
	if is_running:
		timer.stop()


func _dismiss_cancel_dialog() -> void:
	if cancel_dialog:
		cancel_dialog.queue_free()
		cancel_dialog = null
	# Resume timer
	if is_running:
		timer.start()


func _confirm_cancel() -> void:
	if cancel_dialog:
		cancel_dialog.queue_free()
		cancel_dialog = null
	_return_to_base()


func _on_submit_journal() -> void:
	# Validate that at least one entry has content
	var has_content = false
	var learned_text = ""
	var accomplished_text = ""
	var goals_text = ""
	var open_text = ""

	if journal_mode == JournalMode.OPEN_ENTRY:
		if open_entry_input:
			open_text = open_entry_input.text.strip_edges()
			has_content = open_text != ""
	else:
		# LAG Journal mode
		if lag_learned_input:
			learned_text = lag_learned_input.text.strip_edges()
		if lag_accomplished_input:
			accomplished_text = lag_accomplished_input.text.strip_edges()
		if lag_goals_input:
			goals_text = lag_goals_input.text.strip_edges()
		has_content = learned_text != "" or accomplished_text != "" or goals_text != ""

	if not has_content:
		# Show error message
		if journal_error_label:
			journal_error_label.text = "Please write at least one reflection before saving."
			journal_error_label.visible = true
			# Shake animation
			var tween = create_tween()
			tween.tween_property(journal_error_label, "position:x", journal_error_label.position.x + 10, 0.05)
			tween.tween_property(journal_error_label, "position:x", journal_error_label.position.x - 10, 0.05)
			tween.tween_property(journal_error_label, "position:x", journal_error_label.position.x, 0.05)
		return

	var minutes_focused = max(1, elapsed_seconds / 60)

	# Calculate XP multiplier based on difficulty
	var xp_multiplier = EASY_XP_MULTIPLIER if difficulty == DifficultyMode.EASY else HARD_XP_MULTIPLIER
	var diff_name = "Standard" if difficulty == DifficultyMode.EASY else "Hard"

	# Create journal entry based on mode
	var entry = {
		"type": "focus",
		"timestamp": Time.get_unix_time_from_system(),
		"date": Time.get_date_string_from_system(),
		"topic": current_topic,
		"duration_minutes": minutes_focused,
		"session_notes": session_notes_text.strip_edges(),
		"habit_id": current_habit_id,
		"script_id": script_id,
		"difficulty": diff_name,
		"journal_mode": "open" if journal_mode == JournalMode.OPEN_ENTRY else "lag"
	}

	if journal_mode == JournalMode.OPEN_ENTRY:
		entry["open_entry"] = open_text
		# Also populate legacy fields for compatibility
		entry["learned"] = ""
		entry["accomplished"] = open_text
		entry["next_goals"] = ""
	else:
		entry["learned"] = learned_text
		entry["accomplished"] = accomplished_text
		entry["next_goals"] = goals_text

	_save_journal_entry(entry)

	# Award progress
	var domain = script_aspect if script_aspect != "" else "productivity"
	if current_habit_id != "" and HabitManager.habits.has(current_habit_id):
		var habit = HabitManager.habits[current_habit_id]
		domain = HabitManager._domain_to_string(habit.domain)
		# Only complete habit if not already completed today
		if not HabitManager.is_completed_today(current_habit_id):
			HabitManager.complete_habit(current_habit_id)

	# Complete topic if applicable
	if current_topic_id != "" and HabitManager.topics.has(current_topic_id):
		HabitManager.complete_topic(current_topic_id, minutes_focused)

	# Apply difficulty multiplier to focus session rewards
	GameManager.complete_focus_session_with_multiplier(minutes_focused, domain, xp_multiplier)

	# Track for campaign progress
	CampaignManager.record_focus_session()

	# Track for daily challenges
	if ChallengeManager:
		ChallengeManager.record_focus_session(minutes_focused)

	# Track for achievements
	if AchievementManager:
		AchievementManager.record_focus_session(minutes_focused)

	print("[FocusMode] Journal saved - ", minutes_focused, " minutes on ", current_topic, " (", diff_name, " mode, ", xp_multiplier, "x XP)")

	# Check if batch has more scripts
	if is_batch_session:
		batch_current_index += 1
		if batch_current_index < batch_script_ids.size():
			_start_next_batch_script()
			return

	# Check if focus block has more sessions queued
	var block_queue = GameManager.player_data.get("focus_block_queue", [])
	if block_queue.size() > 0:
		_show_block_continue_option(block_queue)
		return

	# Offer break for sessions 15+ minutes
	if minutes_focused >= 15:
		_show_break_option()
	else:
		_return_to_base()


func _start_next_batch_script() -> void:
	# Reset state for next script
	elapsed_seconds = 0
	is_running = false
	current_line_index = -1

	# Load next script
	_load_batch_script(batch_current_index)

	# Clear journal inputs (will be rebuilt when journal panel shows)
	open_entry_input = null
	lag_learned_input = null
	lag_accomplished_input = null
	lag_goals_input = null

	# Update UI
	topic_label.text = current_topic
	_update_timer_display()
	start_button.visible = true
	complete_button.visible = false
	status_label.text = "Ready for next script"

	# Remove old lines container and add new one
	if lines_container:
		lines_container.queue_free()
		lines_container = null

	_setup_script_lines_display()
	_show_session_panel()


func _save_journal_entry(entry: Dictionary) -> void:
	var journal = _load_journal()
	journal.append(entry)

	var json_string = JSON.stringify(journal, "\t")
	var journal_path = SaveManager.get_journal_path()
	var file = FileAccess.open(journal_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

	# Check for bedroom unlocks (Data Archive unlocks after first journal)
	if CampaignManager.has_method("check_bedroom_unlocks"):
		CampaignManager.check_bedroom_unlocks()


func _load_journal() -> Array:
	var journal_path = SaveManager.get_journal_path()
	if not FileAccess.file_exists(journal_path):
		return []

	var file = FileAccess.open(journal_path, FileAccess.READ)
	if not file:
		return []

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return []

	var data = json.get_data()
	if data is Array:
		return data
	return []


var block_continue_panel: PanelContainer = null

func _show_block_continue_option(block_queue: Array) -> void:
	if block_continue_panel:
		return

	block_continue_panel = PanelContainer.new()
	block_continue_panel.name = "BlockContinuePanel"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.98)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_bottom = 3
	style.border_color = Color(0.4, 0.65, 0.5)
	block_continue_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 25)
	block_continue_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Focus Block"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.5, 0.85, 0.65))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var remaining = block_queue.size()
	var next_name = block_queue[0].get("topic", "Focus Session")
	var info_text = str(remaining) + " session" + ("s" if remaining > 1 else "") + " remaining"
	info_text += "\nNext: " + next_name

	var info = Label.new()
	info.text = info_text
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	vbox.add_child(btn_row)

	# Continue button
	var continue_btn = Button.new()
	continue_btn.text = "Continue Block"
	continue_btn.custom_minimum_size = Vector2(0, 50)
	continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_btn.add_theme_font_size_override("font_size", 17)
	continue_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 0.65))
	continue_btn.pressed.connect(_continue_block.bind(block_queue))
	btn_row.add_child(continue_btn)

	# Finish button
	var finish_btn = Button.new()
	finish_btn.text = "Finish"
	finish_btn.custom_minimum_size = Vector2(0, 50)
	finish_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finish_btn.add_theme_font_size_override("font_size", 17)
	finish_btn.pressed.connect(_finish_block)
	btn_row.add_child(finish_btn)

	block_continue_panel.set_anchors_preset(Control.PRESET_CENTER)
	block_continue_panel.custom_minimum_size = Vector2(340, 220)
	block_continue_panel.position = Vector2(-170, -110)

	add_child(block_continue_panel)


func _continue_block(block_queue: Array) -> void:
	if block_continue_panel:
		block_continue_panel.queue_free()
		block_continue_panel = null

	# Get next session
	var next_session = block_queue[0]
	var remaining = block_queue.slice(1)

	# Update queue
	if remaining.size() > 0:
		GameManager.player_data["focus_block_queue"] = remaining
	else:
		GameManager.player_data.erase("focus_block_queue")

	# Set pending focus and reload scene
	GameManager.player_data["pending_focus"] = next_session
	get_tree().reload_current_scene()


func _finish_block() -> void:
	if block_continue_panel:
		block_continue_panel.queue_free()
		block_continue_panel = null

	# Clear the queue
	GameManager.player_data.erase("focus_block_queue")

	_return_to_base()


func _return_to_base() -> void:
	# Stop focus ambient sound
	_stop_focus_ambient()

	GameManager.change_state(GameManager.GameState.MINDSCAPE)

	# Set spawn position near Focus Chamber (-320, -130)
	# Spawn slightly to the right of it so player faces the chamber
	GameManager.player_data["custom_spawn_position"] = Vector2(-250, -80)

	# Use the portal transition for a nicer effect
	GameManager.player_data["transition_type"] = "region"
	GameManager.player_data["transition_target"] = "res://scenes/mindscape/mindscape_hub.tscn"
	GameManager.player_data["transition_color"] = Color(0.83, 0.66, 0.29)  # Hub gold color
	get_tree().change_scene_to_file("res://scenes/transition/region_transition.tscn")


func _trigger_completion_celebration() -> void:
	is_running = false
	timer.stop()

	# Update UI to show completion
	timer_label.text = "00:00"
	timer_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	status_label.text = "Session Complete!"
	status_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	ring_bg.color = Color(0.15, 0.25, 0.15, 1)

	# Spawn confetti
	_spawn_confetti()

	# Wait for confetti animation, then show journal
	var celebration_timer = get_tree().create_timer(2.5)
	celebration_timer.timeout.connect(_show_journal_after_celebration)


func _spawn_confetti() -> void:
	var colors = [
		Color(0.9, 0.3, 0.3),   # Red
		Color(0.3, 0.9, 0.3),   # Green
		Color(0.3, 0.5, 0.9),   # Blue
		Color(0.9, 0.9, 0.3),   # Yellow
		Color(0.9, 0.5, 0.9),   # Pink
		Color(0.3, 0.9, 0.9),   # Cyan
		Color(0.9, 0.6, 0.2),   # Orange
	]

	var screen_size = get_viewport_rect().size

	# Create confetti particles
	for i in range(60):
		var confetti = Polygon2D.new()
		confetti.name = "Confetti_" + str(i)

		# Random shape (rectangle or diamond)
		if randi() % 2 == 0:
			confetti.polygon = PackedVector2Array([
				Vector2(-4, -6), Vector2(4, -6), Vector2(4, 6), Vector2(-4, 6)
			])
		else:
			confetti.polygon = PackedVector2Array([
				Vector2(-5, 0), Vector2(0, -8), Vector2(5, 0), Vector2(0, 8)
			])

		confetti.color = colors[randi() % colors.size()]
		confetti.position = Vector2(
			randf_range(100, screen_size.x - 100),
			-20 - randf_range(0, 100)
		)
		confetti.rotation = randf_range(0, TAU)

		# Store animation data
		confetti.set_meta("velocity_x", randf_range(-100, 100))
		confetti.set_meta("velocity_y", randf_range(200, 500))
		confetti.set_meta("rotation_speed", randf_range(-5, 5))
		confetti.set_meta("wobble_offset", randf_range(0, TAU))

		add_child(confetti)
		confetti_particles.append(confetti)


func _process(delta: float) -> void:
	# Animate confetti
	for confetti in confetti_particles:
		if is_instance_valid(confetti):
			var vel_x = confetti.get_meta("velocity_x")
			var vel_y = confetti.get_meta("velocity_y")
			var rot_speed = confetti.get_meta("rotation_speed")
			var wobble = confetti.get_meta("wobble_offset")

			# Add wobble to horizontal movement
			var wobble_x = sin(Time.get_ticks_msec() * 0.003 + wobble) * 50

			confetti.position.x += (vel_x + wobble_x) * delta
			confetti.position.y += vel_y * delta
			confetti.rotation += rot_speed * delta

			# Fade out as it falls
			if confetti.position.y > 600:
				confetti.modulate.a = max(0, 1.0 - (confetti.position.y - 600) / 200)


func _show_journal_after_celebration() -> void:
	# Clean up confetti
	for confetti in confetti_particles:
		if is_instance_valid(confetti):
			confetti.queue_free()
	confetti_particles.clear()

	# Show session summary first
	_show_session_summary()


func _show_session_summary() -> void:
	# Hide/remove notes panel
	if notes_panel:
		# Save the notes text before removing
		if notes_input:
			session_notes_text = notes_input.text
		notes_panel.queue_free()
		notes_panel = null

	# Play focus complete sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_focus_complete"):
		audio.play_focus_complete()

	# Calculate session stats
	summary_minutes = max(1, elapsed_seconds / 60)
	var xp_multiplier = EASY_XP_MULTIPLIER if difficulty == DifficultyMode.EASY else HARD_XP_MULTIPLIER
	summary_domain = script_aspect if script_aspect != "" else "productivity"

	# Base XP is 2 per minute
	var base_xp = summary_minutes * 2
	summary_xp_earned = int(base_xp * xp_multiplier)

	# Update timer display to show elapsed time (not remaining)
	timer_label.text = _format_time(elapsed_seconds)
	timer_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	status_label.text = "Reflect on your session"
	status_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))

	# Create summary panel
	summary_panel = PanelContainer.new()
	summary_panel.name = "SessionSummary"

	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = Color(0.83, 0.66, 0.29, 0.5)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	summary_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	summary_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Session Complete!"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Stats grid
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 12)
	vbox.add_child(grid)

	_add_summary_stat(grid, "Time Focused", "%d min" % summary_minutes)
	_add_summary_stat(grid, "Mode", "Standard" if difficulty == DifficultyMode.EASY else "Hard")
	_add_summary_stat(grid, "Aspect", summary_domain.capitalize())
	_add_summary_stat(grid, "XP Multiplier", "%.1fx" % (EASY_XP_MULTIPLIER if difficulty == DifficultyMode.EASY else HARD_XP_MULTIPLIER))

	# XP earned (big and golden)
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var xp_row = HBoxContainer.new()
	xp_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(xp_row)

	var xp_label = Label.new()
	xp_label.text = "+" + str(summary_xp_earned) + " XP"
	xp_label.add_theme_font_size_override("font_size", 48)
	xp_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	xp_row.add_child(xp_label)

	# Continue button
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer2)

	var continue_btn = Button.new()
	continue_btn.text = "Continue to Journal"
	continue_btn.custom_minimum_size = Vector2(300, 60)
	continue_btn.add_theme_font_size_override("font_size", 22)
	continue_btn.pressed.connect(_close_summary_show_journal)
	vbox.add_child(continue_btn)

	# Center the panel on screen
	summary_panel.position = Vector2(
		(get_viewport_rect().size.x - 450) / 2,
		(get_viewport_rect().size.y - 380) / 2
	)
	summary_panel.custom_minimum_size = Vector2(450, 0)

	add_child(summary_panel)

	# Hide session panel
	session_panel.visible = false
	progress_section.visible = false

	status_label.text = "Great work!"


func _add_summary_stat(grid: GridContainer, label_text: String, value_text: String) -> void:
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	grid.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 20)
	value.add_theme_color_override("font_color", Color(1, 1, 1))
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(value)


func _close_summary_show_journal() -> void:
	if summary_panel:
		summary_panel.queue_free()
		summary_panel = null

	status_label.text = "Reflect on your session"
	_show_journal_panel()


# ============ BREAK TIMER ============

var break_panel: PanelContainer = null
var break_seconds_remaining: int = 0
var break_timer_active: bool = false
const BREAK_DURATION_SECONDS: int = 300  # 5 minutes

func _show_break_option() -> void:
	# Create break option panel
	break_panel = PanelContainer.new()
	break_panel.name = "BreakPanel"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.98)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = Color(0.4, 0.7, 0.5, 0.5)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	break_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	break_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Take a Break?"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Rest your mind for 5 minutes before\nreturning to your mindscape."
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var skip_btn = Button.new()
	skip_btn.text = "Skip Break"
	skip_btn.custom_minimum_size = Vector2(150, 50)
	skip_btn.add_theme_font_size_override("font_size", 18)
	skip_btn.pressed.connect(_skip_break)
	btn_row.add_child(skip_btn)

	var start_btn = Button.new()
	start_btn.text = "Start 5min Break"
	start_btn.custom_minimum_size = Vector2(180, 50)
	start_btn.add_theme_font_size_override("font_size", 18)
	start_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	start_btn.pressed.connect(_start_break_timer)
	btn_row.add_child(start_btn)

	# Center on screen
	break_panel.position = Vector2(
		(get_viewport_rect().size.x - 420) / 2,
		(get_viewport_rect().size.y - 240) / 2
	)
	break_panel.custom_minimum_size = Vector2(420, 0)

	add_child(break_panel)


func _skip_break() -> void:
	if break_panel:
		break_panel.queue_free()
		break_panel = null
	_return_to_base()


func _start_break_timer() -> void:
	if break_panel:
		break_panel.queue_free()
		break_panel = null

	break_seconds_remaining = BREAK_DURATION_SECONDS
	break_timer_active = true

	# Show break timer UI
	_show_break_timer_ui()


func _show_break_timer_ui() -> void:
	# Reuse existing timer display
	session_panel.visible = false
	journal_panel.visible = false
	progress_section.visible = false

	topic_label.text = "Break Time"
	topic_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	status_label.text = "Relax and recharge"
	status_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.55))
	ring_bg.color = Color(0.1, 0.18, 0.14, 1)

	_update_break_timer_display()

	# Create end break button
	var end_btn = Button.new()
	end_btn.name = "EndBreakBtn"
	end_btn.text = "End Break Early"
	end_btn.custom_minimum_size = Vector2(250, 55)
	end_btn.add_theme_font_size_override("font_size", 20)
	end_btn.pressed.connect(_end_break_early)

	# Center it below the timer
	var center = CenterContainer.new()
	center.name = "BreakButtonCenter"
	center.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	center.offset_top = -120
	center.offset_bottom = -60
	center.add_child(end_btn)
	add_child(center)

	# Start timer ticking
	timer.start()


func _update_break_timer_display() -> void:
	var mins = break_seconds_remaining / 60
	var secs = break_seconds_remaining % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	timer_label.add_theme_color_override("font_color", Color(0.5, 0.85, 0.6))


func _end_break_early() -> void:
	break_timer_active = false
	timer.stop()

	var btn_center = get_node_or_null("BreakButtonCenter")
	if btn_center:
		btn_center.queue_free()

	_return_to_base()
