class_name FocusDashboardComponent
extends Node
## FocusDashboardComponent - Focus analytics dashboard UI
## Extracted from bedroom.gd for modularity and reduced token usage

# =============================================================================
# CONSTANTS
# =============================================================================

const DASHBOARD_BG = Color(0.06, 0.07, 0.1, 0.98)
const DASHBOARD_PANEL = Color(0.1, 0.11, 0.15, 0.95)
const DASHBOARD_ACCENT = Color(0.4, 0.7, 0.95)
const DASHBOARD_TEXT = Color(0.85, 0.88, 0.92)
const DASHBOARD_MUTED = Color(0.5, 0.52, 0.58)

# =============================================================================
# STATE
# =============================================================================

var dashboard_panel: Control = null
var dashboard_data: Dictionary = {}
var dashboard_current_tab: String = "overview"
var parent_scene: Control = null
var close_callback: Callable = Callable()

# =============================================================================
# SIGNALS
# =============================================================================

signal dashboard_opened
signal dashboard_closed

# =============================================================================
# PUBLIC API
# =============================================================================

func is_unlocked() -> bool:
	var console_placed = GameManager.player_data.get("console_placed_in_bedroom", false)
	var has_sessions = GameManager.player_data.get("total_focus_sessions", 0) >= 1
	return console_placed and has_sessions


func show(scene: Control, on_close: Callable = Callable()) -> bool:
	if not is_unlocked():
		return false

	if dashboard_panel:
		return false

	parent_scene = scene
	close_callback = on_close

	_calculate_dashboard_data()
	_create_dashboard()
	dashboard_opened.emit()
	return true


func close() -> void:
	if not dashboard_panel:
		return

	var tween = parent_scene.create_tween()
	tween.tween_property(dashboard_panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		dashboard_panel.queue_free()
		dashboard_panel = null
		dashboard_closed.emit()
		if close_callback.is_valid():
			close_callback.call()
	)


func is_open() -> bool:
	return dashboard_panel != null

# =============================================================================
# DASHBOARD CREATION
# =============================================================================

func _create_dashboard() -> void:
	dashboard_panel = Control.new()
	dashboard_panel.name = "FocusDashboard"
	dashboard_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dashboard_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	parent_scene.add_child(dashboard_panel)

	# Dim background
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dashboard_panel.add_child(dim)

	# Main panel
	var panel = PanelContainer.new()
	panel.name = "MainPanel"
	var style = StyleBoxFlat.new()
	style.bg_color = DASHBOARD_BG
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = DASHBOARD_ACCENT.darkened(0.3)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(900, 600)
	panel.offset_left = -450
	panel.offset_right = 450
	panel.offset_top = -300
	panel.offset_bottom = 300
	dashboard_panel.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	_create_header(vbox)
	_create_tabs(vbox)

	var scroll = ScrollContainer.new()
	scroll.name = "ContentScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content = VBoxContainer.new()
	content.name = "ContentContainer"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 15)
	scroll.add_child(content)

	_show_tab("overview")

	# Fade in
	dashboard_panel.modulate.a = 0.0
	var tween = parent_scene.create_tween()
	tween.tween_property(dashboard_panel, "modulate:a", 1.0, 0.3)


func _create_header(parent: VBoxContainer) -> void:
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
	close_btn.pressed.connect(close)
	header.add_child(close_btn)


func _create_tabs(parent: VBoxContainer) -> void:
	var tab_bar = HBoxContainer.new()
	tab_bar.name = "TabBar"
	tab_bar.add_theme_constant_override("separation", 10)
	parent.add_child(tab_bar)

	var tabs = [
		{"id": "overview", "label": "Overview"},
		{"id": "history", "label": "History"},
		{"id": "insights", "label": "Insights"}
	]

	for tab in tabs:
		var btn = Button.new()
		btn.name = "Tab_" + tab.id
		btn.text = tab.label
		btn.toggle_mode = true
		btn.button_pressed = (tab.id == dashboard_current_tab)
		btn.custom_minimum_size = Vector2(100, 35)
		btn.pressed.connect(_show_tab.bind(tab.id))
		tab_bar.add_child(btn)

	var sep = HSeparator.new()
	parent.add_child(sep)


func _show_tab(tab_id: String) -> void:
	dashboard_current_tab = tab_id

	# Update tab buttons
	var tab_bar = dashboard_panel.get_node_or_null("MainPanel/MarginContainer/VBoxContainer/TabBar")
	if tab_bar:
		for child in tab_bar.get_children():
			if child is Button and child.name.begins_with("Tab_"):
				child.button_pressed = (child.name == "Tab_" + tab_id)

	# Clear and rebuild content
	var content = dashboard_panel.get_node_or_null("MainPanel/MarginContainer/VBoxContainer/ContentScroll/ContentContainer")
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

# =============================================================================
# TAB BUILDERS
# =============================================================================

func _build_overview_tab(content: VBoxContainer) -> void:
	# Stats cards row
	var cards = HBoxContainer.new()
	cards.add_theme_constant_override("separation", 15)
	content.add_child(cards)

	_create_stat_card(cards, "Total Sessions", str(dashboard_data.get("total_sessions", 0)), DASHBOARD_ACCENT)
	_create_stat_card(cards, "Total Time", _format_time(dashboard_data.get("total_minutes", 0)), Color(0.4, 0.8, 0.5))
	_create_stat_card(cards, "Avg Session", "%.1f min" % dashboard_data.get("avg_session", 0.0), Color(0.9, 0.7, 0.3))
	_create_stat_card(cards, "Current Streak", "%d days" % dashboard_data.get("current_streak", 0), Color(0.9, 0.5, 0.3))

	# Activity graph
	_add_section_label(content, "Last 7 Days Activity")
	_create_activity_graph(content)

	# Domain breakdown
	_add_section_label(content, "Focus by Domain")
	_create_domain_breakdown(content)


func _build_history_tab(content: VBoxContainer) -> void:
	var entries = dashboard_data.get("focus_entries", [])
	entries.reverse()  # Most recent first

	if entries.is_empty():
		var empty = Label.new()
		empty.text = "No focus sessions recorded yet."
		empty.add_theme_color_override("font_color", DASHBOARD_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(empty)
		return

	var count = 0
	for entry in entries:
		if count >= 20:
			break
		_create_history_entry(content, entry)
		count += 1


func _build_insights_tab(content: VBoxContainer) -> void:
	# Records section
	_add_section_label(content, "Personal Records")

	var records_grid = GridContainer.new()
	records_grid.columns = 2
	records_grid.add_theme_constant_override("h_separation", 20)
	records_grid.add_theme_constant_override("v_separation", 10)
	content.add_child(records_grid)

	_add_record_row(records_grid, "Longest Session", "%d min" % dashboard_data.get("longest_session", 0))
	_add_record_row(records_grid, "Most Sessions (Day)", str(dashboard_data.get("most_sessions_day", 0)))
	_add_record_row(records_grid, "Best Day Focus", _format_time(dashboard_data.get("best_day_minutes", 0)))
	_add_record_row(records_grid, "Total Hours", str(dashboard_data.get("total_hours", 0)))

	# Milestones
	_add_section_label(content, "Milestones")
	_create_milestones(content)

# =============================================================================
# UI HELPERS
# =============================================================================

func _add_section_label(parent: VBoxContainer, text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", DASHBOARD_TEXT)
	parent.add_child(label)


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
	var container = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = DASHBOARD_PANEL
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	container.add_theme_stylebox_override("panel", style)
	container.custom_minimum_size.y = 150
	content.add_child(container)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	container.add_child(margin)

	var bars = HBoxContainer.new()
	bars.add_theme_constant_override("separation", 10)
	bars.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(bars)

	var daily = dashboard_data.get("daily_activity", {})
	var max_mins = 1
	for date in daily:
		var mins = daily[date].get("minutes", 0)
		if mins > max_mins:
			max_mins = mins

	var dates = daily.keys()
	dates.sort()

	for date in dates:
		var day_data = daily[date]
		var mins = day_data.get("minutes", 0)
		var height = max(10, (float(mins) / max_mins) * 100)

		var bar_container = VBoxContainer.new()
		bar_container.add_theme_constant_override("separation", 5)
		bars.add_child(bar_container)

		var bar = ColorRect.new()
		bar.custom_minimum_size = Vector2(40, height)
		bar.color = DASHBOARD_ACCENT if mins > 0 else DASHBOARD_PANEL.lightened(0.1)
		bar_container.add_child(bar)

		var day_label = Label.new()
		var parts = date.split("-")
		day_label.text = parts[2] if parts.size() >= 3 else date
		day_label.add_theme_font_size_override("font_size", 10)
		day_label.add_theme_color_override("font_color", DASHBOARD_MUTED)
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bar_container.add_child(day_label)


func _create_domain_breakdown(content: VBoxContainer) -> void:
	var domain_stats = dashboard_data.get("domain_stats", {})

	var container = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = DASHBOARD_PANEL
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	container.add_theme_stylebox_override("panel", style)
	content.add_child(container)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	container.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var total_mins = 0
	for domain in domain_stats:
		total_mins += domain_stats[domain].get("minutes", 0)

	if total_mins == 0:
		var empty = Label.new()
		empty.text = "No domain data yet"
		empty.add_theme_color_override("font_color", DASHBOARD_MUTED)
		vbox.add_child(empty)
		return

	var colors = {
		"health": Color(0.3, 0.8, 0.4),
		"learning": Color(0.4, 0.6, 0.9),
		"mindfulness": Color(0.7, 0.5, 0.9),
		"social": Color(0.9, 0.6, 0.4),
		"productivity": Color(0.9, 0.8, 0.3),
		"general": Color(0.6, 0.6, 0.7)
	}

	for domain in domain_stats:
		var stats = domain_stats[domain]
		var percent = (float(stats.minutes) / total_mins) * 100

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		vbox.add_child(row)

		var name_label = Label.new()
		name_label.text = domain.capitalize()
		name_label.custom_minimum_size.x = 100
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", colors.get(domain, DASHBOARD_TEXT))
		row.add_child(name_label)

		var bar_bg = ColorRect.new()
		bar_bg.custom_minimum_size = Vector2(200, 16)
		bar_bg.color = Color(0.15, 0.15, 0.2)
		bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bar_bg)

		var bar_fill = ColorRect.new()
		bar_fill.custom_minimum_size = Vector2(percent * 2, 16)
		bar_fill.color = colors.get(domain, DASHBOARD_ACCENT)
		bar_bg.add_child(bar_fill)

		var pct_label = Label.new()
		pct_label.text = "%.0f%%" % percent
		pct_label.add_theme_font_size_override("font_size", 12)
		pct_label.add_theme_color_override("font_color", DASHBOARD_MUTED)
		row.add_child(pct_label)


func _create_history_entry(content: VBoxContainer, entry: Dictionary) -> void:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = DASHBOARD_PANEL
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	card.add_theme_stylebox_override("panel", style)
	content.add_child(card)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)

	# Date
	var date_label = Label.new()
	date_label.text = entry.get("date", "Unknown")
	date_label.custom_minimum_size.x = 100
	date_label.add_theme_font_size_override("font_size", 12)
	date_label.add_theme_color_override("font_color", DASHBOARD_MUTED)
	hbox.add_child(date_label)

	# Topic
	var topic_label = Label.new()
	topic_label.text = entry.get("topic", "Focus Session")
	topic_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topic_label.add_theme_font_size_override("font_size", 14)
	topic_label.add_theme_color_override("font_color", DASHBOARD_TEXT)
	hbox.add_child(topic_label)

	# Duration
	var dur_label = Label.new()
	dur_label.text = "%d min" % entry.get("duration_minutes", 0)
	dur_label.add_theme_font_size_override("font_size", 14)
	dur_label.add_theme_color_override("font_color", DASHBOARD_ACCENT)
	hbox.add_child(dur_label)


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


func _create_milestones(content: VBoxContainer) -> void:
	var container = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = DASHBOARD_PANEL
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	container.add_theme_stylebox_override("panel", style)
	content.add_child(container)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	container.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var total = dashboard_data.get("total_sessions", 0)
	var milestones = [
		{"label": "First Steps", "target": 10, "color": Color(0.5, 0.7, 0.9)},
		{"label": "Building Momentum", "target": 25, "color": Color(0.4, 0.8, 0.5)},
		{"label": "Dedicated", "target": 50, "color": Color(0.9, 0.7, 0.3)},
		{"label": "Master", "target": 100, "color": Color(0.9, 0.5, 0.3)}
	]

	for m in milestones:
		_add_milestone_bar(vbox, m.label, total, m.target, m.color)


func _add_milestone_bar(parent: VBoxContainer, label_text: String, current: int, target: int, color: Color) -> void:
	var row = VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)

	var header = HBoxContainer.new()
	row.add_child(header)

	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color if current >= target else DASHBOARD_MUTED)
	header.add_child(label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var progress_text = Label.new()
	progress_text.text = "%d / %d" % [min(current, target), target]
	progress_text.add_theme_font_size_override("font_size", 12)
	progress_text.add_theme_color_override("font_color", DASHBOARD_MUTED)
	header.add_child(progress_text)

	var bar_bg = ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(0, 8)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_bg.color = Color(0.15, 0.15, 0.2)
	row.add_child(bar_bg)

	var progress = min(float(current) / target, 1.0)
	var bar_fill = ColorRect.new()
	bar_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_fill.custom_minimum_size = Vector2(progress * 300, 8)
	bar_fill.color = color
	bar_bg.add_child(bar_fill)

# =============================================================================
# DATA CALCULATION
# =============================================================================

func _calculate_dashboard_data() -> void:
	dashboard_data.clear()

	dashboard_data["total_sessions"] = GameManager.player_data.get("total_focus_sessions", 0)
	dashboard_data["total_minutes"] = GameManager.player_data.get("total_focus_minutes", 0)

	var total_mins = dashboard_data["total_minutes"]
	dashboard_data["total_hours"] = int(total_mins / 60)

	if dashboard_data["total_sessions"] > 0:
		dashboard_data["avg_session"] = float(total_mins) / dashboard_data["total_sessions"]
	else:
		dashboard_data["avg_session"] = 0.0

	# Load journal entries
	var entries = _load_journal_entries()
	var focus_entries = []
	for entry in entries:
		if entry.get("type", "") == "focus":
			focus_entries.append(entry)
	dashboard_data["focus_entries"] = focus_entries

	# Calculate daily activity for last 7 days
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

	# Calculate weekly totals
	var week_mins = 0
	for date_str in daily_activity:
		week_mins += daily_activity[date_str]["minutes"]
	dashboard_data["week_minutes"] = week_mins

	# Find best day
	var best_mins = 0
	for date_str in daily_activity:
		if daily_activity[date_str]["minutes"] > best_mins:
			best_mins = daily_activity[date_str]["minutes"]
	dashboard_data["best_day_minutes"] = best_mins

	# Domain stats
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

	# Calculate current streak
	var streak = 0
	var checking = Time.get_unix_time_from_system()
	while streak < 365:
		var date_dict = Time.get_date_dict_from_unix_time(checking)
		var date_str = "%04d-%02d-%02d" % [date_dict.year, date_dict.month, date_dict.day]
		var had_focus = false
		for entry in focus_entries:
			if entry.get("date", "") == date_str:
				had_focus = true
				break
		if had_focus:
			streak += 1
			checking -= 86400
		elif streak == 0 and date_str == today_str:
			checking -= 86400
		else:
			break
	dashboard_data["current_streak"] = streak

	# Records
	var longest = 0
	for entry in focus_entries:
		var dur = entry.get("duration_minutes", 0)
		if dur > longest:
			longest = dur
	dashboard_data["longest_session"] = longest

	var sessions_by_day = {}
	for entry in focus_entries:
		var date = entry.get("date", "")
		if not sessions_by_day.has(date):
			sessions_by_day[date] = 0
		sessions_by_day[date] += 1
	var most = 0
	for date in sessions_by_day:
		if sessions_by_day[date] > most:
			most = sessions_by_day[date]
	dashboard_data["most_sessions_day"] = most


func _load_journal_entries() -> Array:
	var path = SaveManager.get_journal_path()
	if not FileAccess.file_exists(path):
		return []

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return []

	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return []

	var data = json.get_data()
	return data if data is Array else []


func _format_time(minutes: int) -> String:
	if minutes < 60:
		return "%d min" % minutes
	var hours = minutes / 60
	var mins = minutes % 60
	if mins == 0:
		return "%d hr" % hours
	return "%d hr %d min" % [hours, mins]
