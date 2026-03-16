extends Control
## Daily Rituals - Dedicated scene for habit tracking and management
## A sacred space for maintaining daily practices

# UI References
@onready var background: ColorRect = $Background
@onready var panel_section: PanelContainer = $HBoxLayout/PanelSection
@onready var graphic_section: Control = $HBoxLayout/GraphicSection
@onready var shrine_visuals: Node2D = $HBoxLayout/GraphicSection/ShrineVisuals
@onready var title_label: Label = $HBoxLayout/PanelSection/MainPanel/VBox/TitleLabel
@onready var subtitle_label: Label = $HBoxLayout/PanelSection/MainPanel/VBox/SubtitleLabel
@onready var habits_scroll: ScrollContainer = $HBoxLayout/PanelSection/MainPanel/VBox/HabitsScroll
@onready var habits_container: VBoxContainer = $HBoxLayout/PanelSection/MainPanel/VBox/HabitsScroll/HabitsContainer
@onready var back_button: Button = $HBoxLayout/PanelSection/MainPanel/VBox/BackButton

# Animation
var animation_time: float = 0.0

# Drag and drop state
var is_dragging: bool = false
var drag_habit_id: String = ""
var drag_preview: Control = null
var drag_start_index: int = -1
var habit_row_nodes: Dictionary = {}  # habit_id -> row node

# Statistics panel
var stats_panel: Control = null
var stats_period: int = 7  # 7 = weekly, 30 = monthly

# Journal prompt
var journal_dialog: PanelContainer = null
var journal_input: TextEdit = null
var pending_habit_id: String = ""
var pending_habit_name: String = ""

# Bulk completion queue
var bulk_complete_queue: Array = []
var bulk_complete_total: int = 0
var is_bulk_completing: bool = false


func _ready() -> void:
	back_button.pressed.connect(_return_to_hub)
	back_button.tooltip_text = "Return to Hub (ESC or M)"

	_create_shrine_visuals()
	_load_habits()

	print("[DailyRituals] Ready")


func _process(delta: float) -> void:
	animation_time += delta
	_animate_shrine()
	_animate_celebration_particles(delta)


func _animate_celebration_particles(delta: float) -> void:
	if celebration_particles.is_empty():
		return

	for particle in celebration_particles:
		if not is_instance_valid(particle):
			continue

		var vel_x = particle.get_meta("vel_x")
		var vel_y = particle.get_meta("vel_y")
		var rot_speed = particle.get_meta("rot_speed")
		var wobble = particle.get_meta("wobble")

		# Wobble effect
		var wobble_x = sin(animation_time * 3 + wobble) * 40

		particle.position.x += (vel_x + wobble_x) * delta
		particle.position.y += vel_y * delta
		particle.rotation += rot_speed * delta

		# Fade out as it falls
		if particle.position.y > 500:
			particle.modulate.a = max(0, 1.0 - (particle.position.y - 500) / 200)


func _load_habits() -> void:
	# Clear existing
	for child in habits_container.get_children():
		child.queue_free()
	habit_row_nodes.clear()

	# Grace days info
	var grace_row = HBoxContainer.new()
	grace_row.add_theme_constant_override("separation", 12)

	var grace_count = HabitManager.get_grace_days()
	var grace_label = Label.new()
	grace_label.text = "Grace Days: " + str(grace_count) + "/" + str(HabitManager.MAX_GRACE_DAYS)
	grace_label.add_theme_font_size_override("font_size", 14)
	grace_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.5) if grace_count > 0 else Color(0.5, 0.5, 0.55))
	grace_row.add_child(grace_label)
	habits_container.add_child(grace_row)

	_add_spacer(10)

	# Check for habits needing recovery
	var at_risk = HabitManager.get_habits_needing_recovery()
	if at_risk.size() > 0:
		_show_streak_recovery(at_risk)
		_add_spacer(12)

	# Get habits
	var habits = HabitManager.get_all_habits()

	if habits.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No habits tracked yet.\nCreate your first daily ritual!"
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		habits_container.add_child(empty_label)
	else:
		# Count incomplete
		var incomplete_count = 0
		for habit in habits:
			if not HabitManager.is_completed_today(habit.id):
				incomplete_count += 1

		# Bulk complete button
		if incomplete_count > 1:
			var bulk_btn = Button.new()
			bulk_btn.text = "Complete All (%d remaining)" % incomplete_count
			bulk_btn.custom_minimum_size = Vector2(0, 42)
			bulk_btn.add_theme_font_size_override("font_size", 16)
			bulk_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
			bulk_btn.pressed.connect(_bulk_complete_habits)
			habits_container.add_child(bulk_btn)
			_add_spacer(8)

		# Habit list
		for habit in habits:
			_add_habit_row(habit)

	_add_spacer(12)

	# Button row for actions
	var action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	habits_container.add_child(action_row)

	# Add new habit button
	var add_btn = Button.new()
	add_btn.text = "+ New Habit"
	add_btn.custom_minimum_size = Vector2(0, 45)
	add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_btn.add_theme_font_size_override("font_size", 16)
	add_btn.pressed.connect(_show_create_habit_form)
	action_row.add_child(add_btn)

	# Stats button
	var stats_btn = Button.new()
	stats_btn.text = "Stats"
	stats_btn.custom_minimum_size = Vector2(80, 45)
	stats_btn.add_theme_font_size_override("font_size", 16)
	stats_btn.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	stats_btn.pressed.connect(_show_stats_panel)
	action_row.add_child(stats_btn)

	# Archived habits
	var archived = HabitManager.get_archived_habits()
	if archived.size() > 0:
		_add_spacer(16)
		var archived_label = Label.new()
		archived_label.text = "Archived (" + str(archived.size()) + ")"
		archived_label.add_theme_font_size_override("font_size", 14)
		archived_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		habits_container.add_child(archived_label)

		for habit in archived:
			_add_archived_habit_row(habit)


func _add_habit_row(habit: Dictionary) -> void:
	var is_completed = HabitManager.is_completed_today(habit.id)

	var row = HBoxContainer.new()
	row.name = "HabitRow_" + habit.id
	row.add_theme_constant_override("separation", 8)
	row.set_meta("habit_id", habit.id)

	# Drag handle
	var drag_handle = Button.new()
	drag_handle.text = ":::"
	drag_handle.flat = true
	drag_handle.custom_minimum_size = Vector2(30, 30)
	drag_handle.add_theme_font_size_override("font_size", 14)
	drag_handle.add_theme_color_override("font_color", Color(0.4, 0.45, 0.5))
	drag_handle.tooltip_text = "Drag to reorder"
	drag_handle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	drag_handle.button_down.connect(_on_drag_start.bind(habit.id, row))
	drag_handle.button_up.connect(_on_drag_end)
	row.add_child(drag_handle)

	var checkbox = CheckBox.new()
	checkbox.text = habit.get("name", "Habit")
	checkbox.button_pressed = is_completed
	checkbox.add_theme_font_size_override("font_size", 18)
	checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	checkbox.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5) if is_completed else Color(1, 1, 1))
	checkbox.toggled.connect(_on_habit_toggled.bind(habit.id))
	row.add_child(checkbox)

	# Streak
	var streak = int(habit.get("streak", 0))
	if streak > 0:
		var streak_label = Label.new()
		streak_label.text = _get_streak_icon(streak) + " " + str(streak)
		streak_label.add_theme_font_size_override("font_size", 16)
		streak_label.add_theme_color_override("font_color", _get_streak_color(streak))
		streak_label.tooltip_text = "Best: %d days" % int(habit.get("best_streak", 0))
		row.add_child(streak_label)

	habits_container.add_child(row)
	habit_row_nodes[habit.id] = row


func _add_archived_habit_row(habit: Dictionary) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label = Label.new()
	name_label.text = habit.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var restore_btn = Button.new()
	restore_btn.text = "Restore"
	restore_btn.custom_minimum_size = Vector2(70, 30)
	restore_btn.add_theme_font_size_override("font_size", 12)
	restore_btn.pressed.connect(_unarchive_habit.bind(habit.id))
	row.add_child(restore_btn)

	habits_container.add_child(row)


func _show_streak_recovery(at_risk: Array) -> void:
	var recovery_panel = PanelContainer.new()
	var recovery_vbox = VBoxContainer.new()
	recovery_vbox.add_theme_constant_override("separation", 8)

	var warning_label = Label.new()
	warning_label.text = "Streaks at Risk!"
	warning_label.add_theme_font_size_override("font_size", 16)
	warning_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
	recovery_vbox.add_child(warning_label)

	for habit in at_risk:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var name_label = Label.new()
		name_label.text = habit.name + " (" + str(habit.streak) + " day streak)"
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var recover_btn = Button.new()
		recover_btn.text = "Use Grace Day"
		recover_btn.custom_minimum_size = Vector2(100, 30)
		recover_btn.add_theme_font_size_override("font_size", 12)
		recover_btn.pressed.connect(_use_grace_day.bind(habit.id))
		row.add_child(recover_btn)

		recovery_vbox.add_child(row)

	recovery_panel.add_child(recovery_vbox)
	habits_container.add_child(recovery_panel)


func _on_habit_toggled(toggled: bool, habit_id: String) -> void:
	if toggled:
		# Show journal prompt before completing
		var habit = HabitManager.habits.get(habit_id, {})
		if habit:
			pending_habit_id = habit_id
			pending_habit_name = habit.get("name", "Habit")
			_show_journal_prompt()
		return  # Don't reload until journal is submitted
	_load_habits()


func _show_journal_prompt() -> void:
	if journal_dialog:
		journal_dialog.queue_free()

	journal_dialog = PanelContainer.new()
	journal_dialog.name = "JournalPrompt"
	journal_dialog.set_anchors_preset(Control.PRESET_CENTER)
	journal_dialog.custom_minimum_size = Vector2(420, 320)
	journal_dialog.position = Vector2(-210, -160)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.98)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_color = Color(0.4, 0.5, 0.3)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	journal_dialog.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_bottom", 20)
	journal_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	if is_bulk_completing and bulk_complete_total > 0:
		var current_num = bulk_complete_total - bulk_complete_queue.size() + 1
		title.text = "Reflect on: " + pending_habit_name + " (%d/%d)" % [current_num, bulk_complete_total]
	else:
		title.text = "Reflect on: " + pending_habit_name
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Prompt text
	var prompt = Label.new()
	prompt.text = "Take a moment to journal about completing this habit.\nHow did it go? What did you learn?"
	prompt.add_theme_font_size_override("font_size", 14)
	prompt.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(prompt)

	# Text input
	journal_input = TextEdit.new()
	journal_input.placeholder_text = "Write a brief reflection... (required)"
	journal_input.custom_minimum_size = Vector2(0, 120)
	journal_input.add_theme_font_size_override("font_size", 16)
	journal_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	vbox.add_child(journal_input)

	# Character count / hint
	var hint = Label.new()
	hint.name = "CharHint"
	hint.text = "Minimum 10 characters"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(hint)

	# Button row
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	# Cancel button
	var cancel_btn = Button.new()
	cancel_btn.name = "CancelBtn"
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 45)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.add_theme_color_override("font_color", Color(0.6, 0.5, 0.5))
	cancel_btn.pressed.connect(_cancel_journal_entry)
	btn_row.add_child(cancel_btn)

	# Submit button
	var submit_btn = Button.new()
	submit_btn.name = "SubmitBtn"
	submit_btn.text = "Complete Habit"
	submit_btn.custom_minimum_size = Vector2(0, 45)
	submit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	submit_btn.add_theme_font_size_override("font_size", 18)
	submit_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	submit_btn.disabled = true  # Start disabled
	submit_btn.pressed.connect(_submit_journal_entry)
	btn_row.add_child(submit_btn)

	add_child(journal_dialog)
	journal_input.grab_focus()

	# Connect text changed to validate
	journal_input.text_changed.connect(_on_journal_text_changed)

	# Fade in
	journal_dialog.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(journal_dialog, "modulate:a", 1.0, 0.2)


func _on_journal_text_changed() -> void:
	if not journal_dialog:
		return

	var text = journal_input.text.strip_edges()
	var char_count = text.length()
	var min_chars = 10

	# Find hint and submit button using recursive search
	var hint = journal_dialog.find_child("CharHint", true, false)
	var submit_btn = journal_dialog.find_child("SubmitBtn", true, false)

	if hint:
		if char_count >= min_chars:
			hint.text = "%d characters" % char_count
			hint.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
		else:
			hint.text = "%d / %d characters needed" % [char_count, min_chars]
			hint.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5))

	if submit_btn:
		submit_btn.disabled = char_count < min_chars


func _submit_journal_entry() -> void:
	if not journal_input or pending_habit_id == "":
		return

	var entry_text = journal_input.text.strip_edges()
	if entry_text.length() < 10:
		return  # Safety check

	# Save journal entry
	_save_habit_journal_entry(pending_habit_id, pending_habit_name, entry_text)

	# Now complete the habit
	var habit = HabitManager.complete_habit(pending_habit_id)
	if habit:
		var streak = habit.get("streak", 1)
		var exp = habit.get("exp_reward", 25)
		var streak_bonus = int(exp * streak * 0.1)

		# Only show feedback if not bulk completing (avoid spam)
		if not is_bulk_completing:
			_show_completion_feedback(habit.name, exp + streak_bonus, streak)

		# Check for streak milestones
		if streak in [7, 14, 30, 50, 100, 365]:
			_show_streak_celebration(habit.name, streak)

	# Close dialog
	_close_journal_dialog()

	# If bulk completing, show next journal prompt
	if is_bulk_completing:
		# Remove the completed habit from queue
		if not bulk_complete_queue.is_empty():
			bulk_complete_queue.pop_front()
		# Small delay before next prompt
		await get_tree().create_timer(0.3).timeout
		_show_next_bulk_journal()
	else:
		_load_habits()


func _save_habit_journal_entry(habit_id: String, habit_name: String, entry_text: String) -> void:
	# Get or create habit journal entries in player data
	if not GameManager.player_data.has("habit_journal"):
		GameManager.player_data["habit_journal"] = []

	# Get habit info for additional fields
	var habit = HabitManager.habits.get(habit_id, {})

	var entry = {
		"type": "habit",
		"habit_id": habit_id,
		"habit_name": habit_name,
		"note": entry_text,
		"date": Time.get_date_string_from_system(),
		"timestamp": Time.get_unix_time_from_system(),
		"streak": habit.get("streak", 1),
		"domain": HabitManager._domain_to_string(habit.get("domain", 0))
	}

	GameManager.player_data["habit_journal"].append(entry)

	# Keep only last 100 entries to prevent bloat
	if GameManager.player_data["habit_journal"].size() > 100:
		GameManager.player_data["habit_journal"] = GameManager.player_data["habit_journal"].slice(-100)

	# Also save to the main journal JSON file (used by Reflection Pool)
	_append_to_journal_file(entry)

	SaveManager.save_game()
	print("[DailyRituals] Journal entry saved for: ", habit_name)


func _append_to_journal_file(entry: Dictionary) -> void:
	var journal_path = SaveManager.get_journal_path()
	var journal: Array = []

	# Load existing entries
	if FileAccess.file_exists(journal_path):
		var file = FileAccess.open(journal_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data = json.get_data()
				if data is Array:
					journal = data
			file.close()

	# Append new entry
	journal.append(entry)

	# Save back
	var json_string = JSON.stringify(journal, "\t")
	var file = FileAccess.open(journal_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()


func _cancel_journal_entry() -> void:
	# User cancelled - clear bulk queue and close dialog
	bulk_complete_queue.clear()
	bulk_complete_total = 0
	is_bulk_completing = false
	_close_journal_dialog()
	_load_habits()  # Reload to uncheck the checkbox


func _show_next_bulk_journal() -> void:
	if bulk_complete_queue.is_empty():
		# All done
		is_bulk_completing = false
		_load_habits()

		subtitle_label.text = "All habits complete!"
		subtitle_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))

		# Play completion sound
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_focus_complete"):
			audio.play_focus_complete()
		return

	# Show journal prompt for next habit in queue
	var next_habit = bulk_complete_queue[0]
	pending_habit_id = next_habit.id
	pending_habit_name = next_habit.name
	_show_journal_prompt()


func _close_journal_dialog() -> void:
	if journal_dialog:
		var tween = create_tween()
		tween.tween_property(journal_dialog, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func():
			if journal_dialog:
				journal_dialog.queue_free()
				journal_dialog = null
		)
	pending_habit_id = ""
	pending_habit_name = ""
	journal_input = null


func _show_completion_feedback(habit_name: String, xp: int, streak: int) -> void:
	# Play completion sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		if streak > 1 and audio.has_method("play_streak_increase"):
			audio.play_streak_increase()
		elif audio.has_method("play_habit_complete"):
			audio.play_habit_complete()

	# Flash the shrine
	var glow = shrine_visuals.get_node_or_null("AltarGlow")
	if glow:
		glow.modulate.a = 1.0

	# Update subtitle briefly
	subtitle_label.text = habit_name + " complete! +" + str(xp) + " XP"
	subtitle_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))

	await get_tree().create_timer(2.0).timeout

	subtitle_label.text = "Complete your daily rituals to grow"
	subtitle_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))


func _bulk_complete_habits() -> void:
	# Queue all incomplete habits for journal prompts
	var habits = HabitManager.get_all_habits()
	bulk_complete_queue.clear()

	for habit in habits:
		if not HabitManager.is_completed_today(habit.id):
			bulk_complete_queue.append({
				"id": habit.id,
				"name": habit.get("name", "Habit")
			})

	if bulk_complete_queue.is_empty():
		return

	# Start bulk completion mode
	is_bulk_completing = true
	bulk_complete_total = bulk_complete_queue.size()
	_show_next_bulk_journal()


func _move_habit_up(habit_id: String) -> void:
	HabitManager.move_habit_up(habit_id)
	_load_habits()


func _move_habit_down(habit_id: String) -> void:
	HabitManager.move_habit_down(habit_id)
	_load_habits()


func _unarchive_habit(habit_id: String) -> void:
	HabitManager.unarchive_habit(habit_id)
	_load_habits()


func _use_grace_day(habit_id: String) -> void:
	if HabitManager.use_grace_day(habit_id):
		subtitle_label.text = "Streak saved with grace day!"
		subtitle_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.5))
	_load_habits()


func _show_create_habit_form() -> void:
	# Create modal dialog for habit creation
	var dialog = PanelContainer.new()
	dialog.name = "CreateHabitDialog"
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.custom_minimum_size = Vector2(350, 280)
	dialog.position = Vector2(-175, -140)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Create New Habit"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var name_label = Label.new()
	name_label.text = "Habit Name"
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)

	var name_input = LineEdit.new()
	name_input.name = "NameInput"
	name_input.placeholder_text = "e.g., Morning meditation"
	name_input.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(name_input)

	var desc_label = Label.new()
	desc_label.text = "Description (optional)"
	desc_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(desc_label)

	var desc_input = LineEdit.new()
	desc_input.name = "DescInput"
	desc_input.placeholder_text = "Brief description..."
	desc_input.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(desc_input)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 40)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(func(): dialog.queue_free())
	btn_row.add_child(cancel_btn)

	var create_btn = Button.new()
	create_btn.text = "Create"
	create_btn.custom_minimum_size = Vector2(0, 40)
	create_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	create_btn.pressed.connect(func():
		var habit_name = name_input.text.strip_edges()
		var habit_desc = desc_input.text.strip_edges()
		if habit_name != "":
			HabitManager.create_custom_habit(habit_name, habit_desc, HabitManager.HabitDomain.PRODUCTIVITY)
			dialog.queue_free()
			_load_habits()
	)
	btn_row.add_child(create_btn)

	add_child(dialog)
	name_input.grab_focus()


func _show_stats_panel() -> void:
	if stats_panel:
		stats_panel.queue_free()
		stats_panel = null
		return

	var stats = HabitManager.get_period_stats(stats_period)

	stats_panel = PanelContainer.new()
	stats_panel.name = "StatsPanel"
	stats_panel.set_anchors_preset(Control.PRESET_CENTER)
	stats_panel.custom_minimum_size = Vector2(450, 520)
	stats_panel.position = Vector2(-225, -260)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.98)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_color = Color(0.3, 0.35, 0.45)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	stats_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_bottom", 20)
	stats_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# Header with title and close
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	var title = Label.new()
	title.text = "Habit Statistics"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.flat = true
	close_btn.custom_minimum_size = Vector2(35, 35)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_stats_panel)
	header.add_child(close_btn)

	# Period toggle buttons
	var period_row = HBoxContainer.new()
	period_row.add_theme_constant_override("separation", 8)
	vbox.add_child(period_row)

	var week_btn = Button.new()
	week_btn.text = "Weekly"
	week_btn.custom_minimum_size = Vector2(100, 38)
	week_btn.add_theme_font_size_override("font_size", 16)
	if stats_period == 7:
		week_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	week_btn.pressed.connect(func():
		stats_period = 7
		_refresh_stats_panel()
	)
	period_row.add_child(week_btn)

	var month_btn = Button.new()
	month_btn.text = "Monthly"
	month_btn.custom_minimum_size = Vector2(100, 38)
	month_btn.add_theme_font_size_override("font_size", 16)
	if stats_period == 30:
		month_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	month_btn.pressed.connect(func():
		stats_period = 30
		_refresh_stats_panel()
	)
	period_row.add_child(month_btn)

	# Overall stats summary
	var summary_panel = PanelContainer.new()
	var summary_style = StyleBoxFlat.new()
	summary_style.bg_color = Color(0.1, 0.12, 0.18, 0.8)
	summary_style.corner_radius_top_left = 10
	summary_style.corner_radius_top_right = 10
	summary_style.corner_radius_bottom_left = 10
	summary_style.corner_radius_bottom_right = 10
	summary_panel.add_theme_stylebox_override("panel", summary_style)
	vbox.add_child(summary_panel)

	var summary_margin = MarginContainer.new()
	summary_margin.add_theme_constant_override("margin_left", 15)
	summary_margin.add_theme_constant_override("margin_top", 12)
	summary_margin.add_theme_constant_override("margin_right", 15)
	summary_margin.add_theme_constant_override("margin_bottom", 12)
	summary_panel.add_child(summary_margin)

	var summary_grid = GridContainer.new()
	summary_grid.columns = 2
	summary_grid.add_theme_constant_override("h_separation", 30)
	summary_grid.add_theme_constant_override("v_separation", 10)
	summary_margin.add_child(summary_grid)

	# Completion rate
	_add_stat_item(summary_grid, "Completion Rate", "%d%%" % int(stats.completion_rate * 100), _get_rate_color(stats.completion_rate))

	# Perfect days
	var period_name = "week" if stats_period == 7 else "month"
	_add_stat_item(summary_grid, "Perfect Days", "%d / %d" % [int(stats.perfect_days), int(stats.period_days)], Color(0.9, 0.8, 0.4))

	# Total completed
	_add_stat_item(summary_grid, "Total Completed", "%d / %d" % [int(stats.total_completed), int(stats.total_possible)], Color(0.7, 0.8, 0.9))

	# Best day
	var habit_count = HabitManager.get_all_habits().size()
	_add_stat_item(summary_grid, "Best Day", "%d / %d habits" % [int(stats.best_day_count), int(habit_count)], Color(0.6, 0.9, 0.7))

	# Daily chart
	var chart_label = Label.new()
	chart_label.text = "Daily Completions"
	chart_label.add_theme_font_size_override("font_size", 16)
	chart_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	vbox.add_child(chart_label)

	var chart_container = _create_daily_chart(stats.daily_counts, habit_count)
	vbox.add_child(chart_container)

	# Per-habit breakdown
	var habits_label = Label.new()
	habits_label.text = "Per-Habit Breakdown"
	habits_label.add_theme_font_size_override("font_size", 16)
	habits_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	vbox.add_child(habits_label)

	var habits_scroll = ScrollContainer.new()
	habits_scroll.custom_minimum_size = Vector2(0, 140)
	habits_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(habits_scroll)

	var habits_vbox = VBoxContainer.new()
	habits_vbox.add_theme_constant_override("separation", 8)
	habits_scroll.add_child(habits_vbox)

	for habit_stat in stats.per_habit_stats:
		_add_habit_stat_row(habits_vbox, habit_stat, stats.period_days)

	add_child(stats_panel)

	# Fade in
	stats_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(stats_panel, "modulate:a", 1.0, 0.2)


func _close_stats_panel() -> void:
	if not stats_panel:
		return

	var tween = create_tween()
	tween.tween_property(stats_panel, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		if stats_panel:
			stats_panel.queue_free()
			stats_panel = null
	)


func _refresh_stats_panel() -> void:
	_close_stats_panel()
	await get_tree().create_timer(0.2).timeout
	_show_stats_panel()


func _add_stat_item(container: Control, label_text: String, value_text: String, value_color: Color) -> void:
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
	container.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", value_color)
	container.add_child(value)


func _get_rate_color(rate: float) -> Color:
	if rate >= 0.9:
		return Color(0.5, 0.9, 0.5)  # Green
	elif rate >= 0.7:
		return Color(0.7, 0.85, 0.5)  # Yellow-green
	elif rate >= 0.5:
		return Color(0.9, 0.8, 0.4)  # Yellow
	elif rate >= 0.3:
		return Color(0.9, 0.6, 0.3)  # Orange
	else:
		return Color(0.9, 0.4, 0.4)  # Red


func _create_daily_chart(daily_counts: Array, max_habits: int) -> Control:
	var chart = Control.new()
	chart.custom_minimum_size = Vector2(400, 60)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 3)
	chart.add_child(hbox)

	# Show last 7 or 14 days (limit for readability)
	var show_days = mini(daily_counts.size(), 14)
	var bar_width = 380.0 / show_days - 3

	for i in range(show_days):
		if i >= daily_counts.size():
			break

		var day_data = daily_counts[show_days - 1 - i]  # Reverse order (oldest first)
		var count = day_data.count
		var total = day_data.total
		var rate = 0.0
		if total > 0:
			rate = float(count) / float(total)

		var bar_container = VBoxContainer.new()
		bar_container.add_theme_constant_override("separation", 2)
		hbox.add_child(bar_container)

		# Bar
		var bar = ColorRect.new()
		bar.custom_minimum_size = Vector2(bar_width, max(5, rate * 40))
		bar.color = _get_rate_color(rate)
		bar_container.add_child(bar)

		# Day label (show day of week for last 7)
		if show_days <= 7:
			var date_str = day_data.date
			var day_label = Label.new()
			day_label.text = _get_short_day_name(date_str)
			day_label.add_theme_font_size_override("font_size", 10)
			day_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
			day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bar_container.add_child(day_label)

	return chart


func _get_short_day_name(date_str: String) -> String:
	# Parse date and get day of week
	var dict = Time.get_datetime_dict_from_datetime_string(date_str + "T00:00:00", false)
	var weekday = Time.get_datetime_dict_from_unix_time(
		Time.get_unix_time_from_datetime_dict(dict)
	).weekday
	var days = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
	if weekday >= 0 and weekday < days.size():
		return days[weekday]
	return "?"


func _add_habit_stat_row(container: VBoxContainer, habit_stat: Dictionary, period_days: int) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	container.add_child(row)

	# Habit name
	var name_label = Label.new()
	name_label.text = habit_stat.name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.custom_minimum_size = Vector2(120, 0)
	name_label.clip_text = true
	row.add_child(name_label)

	# Progress bar
	var bar_bg = ColorRect.new()
	bar_bg.color = Color(0.15, 0.17, 0.22)
	bar_bg.custom_minimum_size = Vector2(120, 16)
	row.add_child(bar_bg)

	var bar_fill = ColorRect.new()
	bar_fill.color = _get_rate_color(habit_stat.rate)
	bar_fill.custom_minimum_size = Vector2(max(2, habit_stat.rate * 120), 16)
	bar_fill.position = Vector2(0, 0)
	bar_bg.add_child(bar_fill)

	# Rate percentage
	var rate_label = Label.new()
	rate_label.text = "%d%%" % int(habit_stat.rate * 100)
	rate_label.add_theme_font_size_override("font_size", 14)
	rate_label.add_theme_color_override("font_color", _get_rate_color(habit_stat.rate))
	rate_label.custom_minimum_size = Vector2(45, 0)
	rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(rate_label)

	# Streak info
	var streak_label = Label.new()
	if int(habit_stat.streak) > 0:
		streak_label.text = "%d streak" % int(habit_stat.streak)
		streak_label.add_theme_color_override("font_color", _get_streak_color(habit_stat.streak))
	else:
		streak_label.text = "no streak"
		streak_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
	streak_label.add_theme_font_size_override("font_size", 12)
	streak_label.custom_minimum_size = Vector2(70, 0)
	streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(streak_label)


func _add_spacer(height: int) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	habits_container.add_child(spacer)


func _get_streak_icon(streak: int) -> String:
	if streak >= 30:
		return "***"
	elif streak >= 14:
		return "**"
	elif streak >= 7:
		return "*"
	else:
		return "~"


func _get_streak_color(streak: int) -> Color:
	if streak >= 30:
		return Color(1.0, 0.85, 0.3)  # Gold
	elif streak >= 14:
		return Color(0.95, 0.6, 0.2)  # Orange
	elif streak >= 7:
		return Color(0.9, 0.5, 0.4)   # Red-orange
	else:
		return Color(0.8, 0.7, 0.4)   # Yellow


func _return_to_hub() -> void:
	GameManager.goto_scene("res://scenes/mindscape/mindscape_hub.tscn")


func _create_shrine_visuals() -> void:
	# Clear existing
	for child in shrine_visuals.get_children():
		child.queue_free()

	# Center position relative to graphic section (scaled for 1/3 width)
	var center = Vector2(0, 50)
	var scale = 0.65  # Scale down for smaller space

	# Outer mystical circle - ambient glow
	var outer_glow = Polygon2D.new()
	outer_glow.color = Color(0.15, 0.1, 0.25, 0.15)
	outer_glow.polygon = PackedVector2Array([
		Vector2(-220, 65) * scale, Vector2(0, -100) * scale,
		Vector2(220, 65) * scale, Vector2(0, 190) * scale
	])
	outer_glow.position = center
	shrine_visuals.add_child(outer_glow)

	# Floor - ritual circle
	var floor_poly = Polygon2D.new()
	floor_poly.color = Color(0.08, 0.1, 0.14, 1)
	floor_poly.polygon = PackedVector2Array([
		Vector2(-180, 50) * scale, Vector2(0, -70) * scale,
		Vector2(180, 50) * scale, Vector2(0, 140) * scale
	])
	floor_poly.position = center
	shrine_visuals.add_child(floor_poly)

	# Ritual circle edge glow
	var circle_edge = Polygon2D.new()
	circle_edge.color = Color(0.25, 0.2, 0.35, 0.5)
	circle_edge.polygon = PackedVector2Array([
		Vector2(-165, 45) * scale, Vector2(0, -60) * scale,
		Vector2(165, 45) * scale, Vector2(0, 125) * scale
	])
	circle_edge.position = center
	shrine_visuals.add_child(circle_edge)

	# Inner ritual platform
	var inner_ring = Polygon2D.new()
	inner_ring.color = Color(0.12, 0.14, 0.2, 0.95)
	inner_ring.polygon = PackedVector2Array([
		Vector2(-130, 35) * scale, Vector2(0, -45) * scale,
		Vector2(130, 35) * scale, Vector2(0, 95) * scale
	])
	inner_ring.position = center
	shrine_visuals.add_child(inner_ring)

	# Decorative rune patterns on floor (4 instead of 6)
	for i in range(4):
		var rune = Polygon2D.new()
		rune.name = "Rune" + str(i)
		var angle = i * PI / 2.0 + PI / 4.0
		var dist = 90 * scale
		rune.position = center + Vector2(cos(angle) * dist, sin(angle) * dist * 0.5 + 30 * scale)
		rune.color = Color(0.4, 0.3, 0.5, 0.3)
		rune.polygon = PackedVector2Array([
			Vector2(-6, 0), Vector2(0, -10), Vector2(6, 0), Vector2(0, 10)
		])
		shrine_visuals.add_child(rune)

	# Altar base
	var altar_base = Polygon2D.new()
	altar_base.color = Color(0.18, 0.15, 0.25, 0.95)
	altar_base.polygon = PackedVector2Array([
		Vector2(-50, 32) * scale, Vector2(-58, 0) * scale, Vector2(-45, -20) * scale,
		Vector2(45, -20) * scale, Vector2(58, 0) * scale, Vector2(50, 32) * scale, Vector2(0, 42) * scale
	])
	altar_base.position = center + Vector2(0, -15) * scale
	shrine_visuals.add_child(altar_base)

	# Altar middle tier
	var altar_mid = Polygon2D.new()
	altar_mid.name = "Altar"
	altar_mid.color = Color(0.25, 0.2, 0.35, 0.95)
	altar_mid.polygon = PackedVector2Array([
		Vector2(-35, 22) * scale, Vector2(-42, -3) * scale, Vector2(-30, -22) * scale,
		Vector2(30, -22) * scale, Vector2(42, -3) * scale, Vector2(35, 22) * scale, Vector2(0, 32) * scale
	])
	altar_mid.position = center + Vector2(0, -35) * scale
	shrine_visuals.add_child(altar_mid)

	# Altar top
	var altar_top = Polygon2D.new()
	altar_top.color = Color(0.3, 0.25, 0.4, 0.95)
	altar_top.polygon = PackedVector2Array([
		Vector2(-22, 13) * scale, Vector2(-26, -6) * scale, Vector2(-16, -20) * scale,
		Vector2(16, -20) * scale, Vector2(26, -6) * scale, Vector2(22, 13) * scale, Vector2(0, 18) * scale
	])
	altar_top.position = center + Vector2(0, -60) * scale
	shrine_visuals.add_child(altar_top)

	# Brazier bowl
	var brazier = Polygon2D.new()
	brazier.color = Color(0.5, 0.4, 0.3, 1)
	brazier.polygon = PackedVector2Array([
		Vector2(-14, 8) * scale, Vector2(-17, -3) * scale, Vector2(-12, -10) * scale,
		Vector2(12, -10) * scale, Vector2(17, -3) * scale, Vector2(14, 8) * scale, Vector2(0, 11) * scale
	])
	brazier.position = center + Vector2(0, -78) * scale
	shrine_visuals.add_child(brazier)

	# Altar glow
	var glow = Polygon2D.new()
	glow.name = "AltarGlow"
	glow.color = Color(0.8, 0.5, 0.2, 0.2)
	glow.polygon = PackedVector2Array([
		Vector2(-55, 48) * scale, Vector2(-62, -14) * scale, Vector2(-42, -55) * scale,
		Vector2(42, -55) * scale, Vector2(62, -14) * scale, Vector2(55, 48) * scale, Vector2(0, 62) * scale
	])
	glow.position = center + Vector2(0, -55) * scale
	shrine_visuals.add_child(glow)

	# Main flame
	var flame = Polygon2D.new()
	flame.name = "Flame"
	flame.color = Color(1.0, 0.7, 0.2, 0.95)
	flame.polygon = PackedVector2Array([
		Vector2(-12, 10) * scale, Vector2(-8, 0) * scale, Vector2(-14, -24) * scale,
		Vector2(-5, -38) * scale, Vector2(0, -55) * scale, Vector2(5, -38) * scale,
		Vector2(14, -24) * scale, Vector2(8, 0) * scale, Vector2(12, 10) * scale, Vector2(0, 15) * scale
	])
	flame.position = center + Vector2(0, -90) * scale
	shrine_visuals.add_child(flame)

	# Flame inner core
	var flame_inner = Polygon2D.new()
	flame_inner.name = "FlameInner"
	flame_inner.color = Color(1.0, 0.9, 0.5, 0.9)
	flame_inner.polygon = PackedVector2Array([
		Vector2(-7, 7) * scale, Vector2(-4, 0) * scale, Vector2(-7, -17) * scale,
		Vector2(0, -35) * scale, Vector2(7, -17) * scale, Vector2(4, 0) * scale,
		Vector2(7, 7) * scale, Vector2(0, 10) * scale
	])
	flame_inner.position = center + Vector2(0, -93) * scale
	shrine_visuals.add_child(flame_inner)

	# Flame outer glow
	var flame_glow = Polygon2D.new()
	flame_glow.name = "FlameGlow"
	flame_glow.color = Color(1.0, 0.5, 0.1, 0.15)
	flame_glow.polygon = PackedVector2Array([
		Vector2(-24, 20) * scale, Vector2(-17, 0) * scale, Vector2(-24, -35) * scale,
		Vector2(0, -70) * scale, Vector2(24, -35) * scale, Vector2(17, 0) * scale,
		Vector2(24, 20) * scale, Vector2(0, 28) * scale
	])
	flame_glow.position = center + Vector2(0, -90) * scale
	shrine_visuals.add_child(flame_glow)

	# Candle stands (4 around the altar, scaled down)
	for i in range(4):
		var angle = i * PI / 2.0 + PI / 4.0
		var dist = 120 * scale
		var candle_x = cos(angle) * dist
		var candle_y = sin(angle) * dist * 0.5 + 25 * scale

		# Candle stand
		var stand = Polygon2D.new()
		stand.name = "Stand" + str(i)
		stand.color = Color(0.4, 0.35, 0.3, 0.9)
		stand.polygon = PackedVector2Array([
			Vector2(-5, 14) * scale, Vector2(-4, -28) * scale,
			Vector2(4, -28) * scale, Vector2(5, 14) * scale
		])
		stand.position = center + Vector2(candle_x, candle_y)
		shrine_visuals.add_child(stand)

		# Candle
		var candle = Polygon2D.new()
		candle.name = "Candle" + str(i)
		candle.color = Color(0.8, 0.7, 0.5, 0.9)
		candle.polygon = PackedVector2Array([
			Vector2(-4, 6) * scale, Vector2(-4, -20) * scale,
			Vector2(4, -20) * scale, Vector2(4, 6) * scale
		])
		candle.position = center + Vector2(candle_x, candle_y - 30 * scale)
		shrine_visuals.add_child(candle)

		# Candle flame
		var candle_flame = Polygon2D.new()
		candle_flame.name = "CandleFlame" + str(i)
		candle_flame.color = Color(1.0, 0.8, 0.3, 0.85)
		candle_flame.polygon = PackedVector2Array([
			Vector2(-3, 4) * scale, Vector2(0, -12) * scale,
			Vector2(3, 4) * scale, Vector2(0, 6) * scale
		])
		candle_flame.position = center + Vector2(candle_x, candle_y - 52 * scale)
		shrine_visuals.add_child(candle_flame)

	# Floating ember particles (fewer for smaller space)
	for i in range(8):
		var ember = Polygon2D.new()
		ember.name = "Ember" + str(i)
		var angle = randf() * TAU
		var dist = randf_range(30, 150) * scale
		var height = randf_range(-100, 60) * scale
		ember.position = center + Vector2(cos(angle) * dist, sin(angle) * dist * 0.4 + height)
		ember.color = Color(1.0, 0.6, 0.2, randf_range(0.2, 0.5))
		ember.polygon = PackedVector2Array([
			Vector2(-2, 0), Vector2(0, -3), Vector2(2, 0), Vector2(0, 3)
		])
		shrine_visuals.add_child(ember)


var celebration_panel: Control = null
var celebration_particles: Array = []

func _show_streak_celebration(habit_name: String, streak: int) -> void:
	# Create celebration overlay
	if celebration_panel:
		celebration_panel.queue_free()

	celebration_panel = Control.new()
	celebration_panel.name = "StreakCelebration"
	celebration_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	celebration_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(celebration_panel)

	# Spawn confetti particles
	_spawn_celebration_confetti()

	# Create milestone banner
	var banner = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.15, 0.95)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_color = _get_milestone_color(streak)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	banner.add_theme_stylebox_override("panel", style)
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.custom_minimum_size = Vector2(400, 200)
	banner.position = Vector2(-200, -100)
	celebration_panel.add_child(banner)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	banner.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Milestone icon
	var icon_label = Label.new()
	icon_label.text = _get_milestone_icon(streak)
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)

	# Title
	var title = Label.new()
	title.text = _get_milestone_title(streak)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", _get_milestone_color(streak))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Streak count
	var streak_label = Label.new()
	streak_label.text = str(streak) + " Day Streak!"
	streak_label.add_theme_font_size_override("font_size", 22)
	streak_label.add_theme_color_override("font_color", Color(1, 1, 1))
	streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(streak_label)

	# Habit name
	var habit_label = Label.new()
	habit_label.text = habit_name
	habit_label.add_theme_font_size_override("font_size", 16)
	habit_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	habit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(habit_label)

	# Play celebration sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_focus_complete"):
		audio.play_focus_complete()

	# Fade in
	celebration_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(celebration_panel, "modulate:a", 1.0, 0.3)

	# Auto dismiss after delay
	await get_tree().create_timer(3.5).timeout
	_dismiss_celebration()


func _spawn_celebration_confetti() -> void:
	if not celebration_panel:
		return

	celebration_particles.clear()
	var colors = [
		Color(1.0, 0.85, 0.3),   # Gold
		Color(0.95, 0.6, 0.2),   # Orange
		Color(0.9, 0.4, 0.4),    # Red
		Color(0.5, 0.8, 0.5),    # Green
		Color(0.5, 0.6, 0.9),    # Blue
		Color(0.8, 0.5, 0.8),    # Purple
	]

	var screen_size = get_viewport_rect().size

	for i in range(50):
		var particle = Polygon2D.new()

		# Random shape
		if randi() % 2 == 0:
			particle.polygon = PackedVector2Array([
				Vector2(-4, -6), Vector2(4, -6), Vector2(4, 6), Vector2(-4, 6)
			])
		else:
			particle.polygon = PackedVector2Array([
				Vector2(-5, 0), Vector2(0, -7), Vector2(5, 0), Vector2(0, 7)
			])

		particle.color = colors[randi() % colors.size()]
		particle.position = Vector2(
			randf_range(50, screen_size.x - 50),
			randf_range(-50, -150)
		)
		particle.rotation = randf_range(0, TAU)

		# Store animation data
		particle.set_meta("vel_x", randf_range(-80, 80))
		particle.set_meta("vel_y", randf_range(150, 350))
		particle.set_meta("rot_speed", randf_range(-4, 4))
		particle.set_meta("wobble", randf_range(0, TAU))

		celebration_panel.add_child(particle)
		celebration_particles.append(particle)


func _dismiss_celebration() -> void:
	if not celebration_panel:
		return

	var tween = create_tween()
	tween.tween_property(celebration_panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func():
		if celebration_panel:
			celebration_panel.queue_free()
			celebration_panel = null
		celebration_particles.clear()
	)


func _get_milestone_icon(streak: int) -> String:
	match streak:
		7: return "***"
		14: return "****"
		30: return "*****"
		50: return "******"
		100: return "*******"
		365: return "********"
		_: return "**"


func _get_milestone_title(streak: int) -> String:
	match streak:
		7: return "One Week Strong!"
		14: return "Two Weeks of Dedication!"
		30: return "Monthly Master!"
		50: return "Habit Champion!"
		100: return "Century Achiever!"
		365: return "Year of Mastery!"
		_: return "Milestone Reached!"


func _get_milestone_color(streak: int) -> Color:
	match streak:
		7: return Color(0.8, 0.6, 0.3)      # Bronze
		14: return Color(0.75, 0.75, 0.8)   # Silver
		30: return Color(1.0, 0.85, 0.3)    # Gold
		50: return Color(0.5, 0.9, 0.9)     # Diamond
		100: return Color(0.9, 0.5, 0.9)    # Pink/Legendary
		365: return Color(1.0, 1.0, 1.0)    # White/Transcendent
		_: return Color(0.8, 0.8, 0.4)


# =============================================================================
# DRAG AND DROP REORDERING
# =============================================================================

func _on_drag_start(habit_id: String, row: Control) -> void:
	is_dragging = true
	drag_habit_id = habit_id
	drag_start_index = HabitManager.get_habit_index(habit_id)

	# Create drag preview
	_create_drag_preview(row)

	# Dim the original row
	row.modulate.a = 0.4


func _on_drag_end() -> void:
	if not is_dragging:
		return

	is_dragging = false

	# Restore original row opacity
	if habit_row_nodes.has(drag_habit_id):
		var row = habit_row_nodes[drag_habit_id]
		if is_instance_valid(row):
			row.modulate.a = 1.0

	# Remove drag preview
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null

	drag_habit_id = ""
	drag_start_index = -1


func _create_drag_preview(source_row: Control) -> void:
	if drag_preview:
		drag_preview.queue_free()

	drag_preview = PanelContainer.new()
	drag_preview.name = "DragPreview"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.18, 0.25, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_color = Color(0.5, 0.7, 0.9, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	drag_preview.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	drag_preview.add_child(margin)

	# Get habit name
	var habit = HabitManager.habits.get(drag_habit_id, {})
	var label = Label.new()
	label.text = habit.get("name", "Habit")
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	margin.add_child(label)

	drag_preview.custom_minimum_size = Vector2(250, 45)
	drag_preview.z_index = 100

	add_child(drag_preview)


func _input(event: InputEvent) -> void:
	# Check if a text input is focused - don't process shortcuts while typing
	var focused = get_viewport().gui_get_focus_owner()
	var is_typing = focused is LineEdit or focused is TextEdit

	# ESC - Close panels or return to hub (always works, even when typing)
	if event.is_action_pressed("ui_cancel"):
		if journal_dialog:
			_cancel_journal_entry()
			get_viewport().set_input_as_handled()
			return
		if stats_panel:
			_close_stats_panel()
			get_viewport().set_input_as_handled()
			return
		if is_dragging:
			_cancel_drag()
			get_viewport().set_input_as_handled()
			return
		_return_to_hub()
		get_viewport().set_input_as_handled()
		return

	# Don't process other shortcuts while typing in text fields
	if is_typing:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			_return_to_hub()
			get_viewport().set_input_as_handled()
			return

	# Handle drag movement
	if is_dragging and event is InputEventMouseMotion:
		_update_drag_position(event.position)
		_check_drop_position(event.position)

	# Handle drag release on mouse up
	if is_dragging and event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_finalize_drag()


func _update_drag_position(mouse_pos: Vector2) -> void:
	if drag_preview:
		drag_preview.global_position = mouse_pos - Vector2(125, 22)


func _check_drop_position(mouse_pos: Vector2) -> void:
	# Highlight the drop target row
	var habits = HabitManager.get_all_habits()

	for i in range(habits.size()):
		var habit = habits[i]
		if not habit_row_nodes.has(habit.id):
			continue

		var row = habit_row_nodes[habit.id]
		if not is_instance_valid(row):
			continue

		var row_rect = row.get_global_rect()

		# Check if mouse is over this row
		if row_rect.has_point(mouse_pos):
			# Highlight potential drop position
			if habit.id != drag_habit_id:
				row.modulate = Color(1.2, 1.2, 1.4)  # Slight blue highlight
		else:
			# Reset non-dragged rows
			if habit.id != drag_habit_id:
				row.modulate = Color(1, 1, 1)


func _finalize_drag() -> void:
	if not is_dragging or drag_habit_id == "":
		_on_drag_end()
		return

	# Find which row we're dropping onto
	var mouse_pos = get_global_mouse_position()
	var habits = HabitManager.get_all_habits()
	var target_index = -1

	for i in range(habits.size()):
		var habit = habits[i]
		if not habit_row_nodes.has(habit.id):
			continue

		var row = habit_row_nodes[habit.id]
		if not is_instance_valid(row):
			continue

		var row_rect = row.get_global_rect()

		if row_rect.has_point(mouse_pos):
			target_index = i
			break

	# If we found a valid drop target, reorder
	if target_index >= 0 and target_index != drag_start_index:
		HabitManager.move_habit_to_position(drag_habit_id, target_index)

		# Play feedback sound
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_ui_click"):
			audio.play_ui_click()

		# Reload the habit list
		_on_drag_end()
		_load_habits()
	else:
		_on_drag_end()


func _cancel_drag() -> void:
	# Reset all row modulates
	for habit_id in habit_row_nodes:
		var row = habit_row_nodes[habit_id]
		if is_instance_valid(row):
			row.modulate = Color(1, 1, 1)

	_on_drag_end()


func _animate_shrine() -> void:
	# Animate altar glow
	var glow = shrine_visuals.get_node_or_null("AltarGlow")
	if glow:
		var pulse = sin(animation_time * 1.5) * 0.1 + 0.9
		glow.modulate.a = 0.15 + pulse * 0.1

	# Animate main flame
	var flame = shrine_visuals.get_node_or_null("Flame")
	if flame:
		var flicker = sin(animation_time * 8.0) * 0.1 + sin(animation_time * 5.0) * 0.08 + 0.9
		flame.modulate.a = flicker
		flame.scale.y = 0.95 + sin(animation_time * 6.0) * 0.08

	# Animate flame inner
	var flame_inner = shrine_visuals.get_node_or_null("FlameInner")
	if flame_inner:
		var flicker = sin(animation_time * 10.0) * 0.12 + 0.85
		flame_inner.modulate.a = flicker
		flame_inner.scale.y = 0.9 + sin(animation_time * 7.0) * 0.1

	# Animate flame glow
	var flame_glow = shrine_visuals.get_node_or_null("FlameGlow")
	if flame_glow:
		flame_glow.modulate.a = 0.12 + sin(animation_time * 4.0) * 0.05

	# Animate candle flames (6 candles now)
	for i in range(6):
		var candle_flame = shrine_visuals.get_node_or_null("CandleFlame" + str(i))
		if candle_flame:
			var offset = i * 1.2
			var flicker = sin(animation_time * 7.0 + offset) * 0.2 + 0.8
			candle_flame.modulate.a = flicker
			candle_flame.scale.y = 0.85 + sin(animation_time * 5.5 + offset) * 0.15

	# Animate rune patterns
	for i in range(6):
		var rune = shrine_visuals.get_node_or_null("Rune" + str(i))
		if rune:
			var pulse = sin(animation_time * 2.0 + i * 1.0) * 0.15 + 0.3
			rune.modulate.a = pulse

	# Animate floating embers
	for i in range(12):
		var ember = shrine_visuals.get_node_or_null("Ember" + str(i))
		if ember:
			if not ember.has_meta("base_pos"):
				ember.set_meta("base_pos", ember.position)
			var base_pos = ember.get_meta("base_pos")
			var float_offset = sin(animation_time * 1.5 + i * 0.5) * 10
			var drift = cos(animation_time * 0.8 + i * 0.7) * 5
			ember.position = base_pos + Vector2(drift, float_offset)
			ember.modulate.a = 0.3 + sin(animation_time * 3.0 + i * 0.4) * 0.2
