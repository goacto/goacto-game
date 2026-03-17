extends Control
## Script Lab - Personal Operating System Editor
## "Our lives are the outcome of the scripts we allow ourselves to run."
##
## Features:
## - Welcome cards explaining PSA (PowerSelfAction) philosophy
## - Two-dimensional layer system: Domain + Operational
## - 25-line script editor (1 line = 1 minute)
## - Audit mode for Bloatware/Virus scripts

# Main containers
var background: ColorRect = null
var main_container: VBoxContainer = null
var header: PanelContainer = null
var content_area: HSplitContainer = null

# Welcome overlay
var welcome_overlay: Control = null
var current_welcome_card: int = 0
var has_seen_intro: bool = false

# Script list panel
var script_list_panel: PanelContainer = null
var script_list_container: VBoxContainer = null
var domain_filter: OptionButton = null
var operational_filter: OptionButton = null
var script_items: Array = []

# Script editor panel
var editor_panel: PanelContainer = null
var editor_header: HBoxContainer = null
var script_name_label: Label = null
var script_domain_label: Label = null
var script_layer_label: Label = null
var line_editors: Array = []  # 25 LineEdit nodes
var selected_script_id: String = ""

# Bottom toolbar
var toolbar: HBoxContainer = null
var new_script_button: Button = null
var audit_mode_button: Button = null
var packages_button: Button = null
var back_button: Button = null

# Audit mode
var is_audit_mode: bool = false

# Colors
const BG_COLOR = Color(0.06, 0.07, 0.1)
const PANEL_COLOR = Color(0.1, 0.11, 0.15, 0.95)
const ACCENT_COLOR = Color(0.2, 0.8, 0.5)
const TEXT_COLOR = Color(0.85, 0.88, 0.92)
const MUTED_COLOR = Color(0.5, 0.52, 0.58)

# Welcome card content
const WELCOME_CARDS = [
	{
		"title": "Your Personal Operating System",
		"content": [
			"Your life runs on scripts - patterns of thought and action.",
			"",
			"PSA (PowerSelfAction) files are 25-minute focus sessions.",
			"Each line represents 1 minute of intentional action.",
			"",
			"Together, these scripts form your Personal Operating System.",
			"Design it consciously. Run it intentionally."
		],
		"icon": "terminal"
	},
	{
		"title": "Domain Layers",
		"content": [
			"Scripts belong to one of six life domains:",
			"",
			"Mind - Mental growth, learning, focus",
			"Body - Physical health, movement, energy",
			"Soul - Purpose, meaning, spirituality",
			"Social - Relationships, community, connection",
			"Career - Work, craft, contribution",
			"Wealth - Financial growth, resources"
		],
		"icon": "layers"
	},
	{
		"title": "Operational Layers",
		"content": [
			"Each script has an operational classification:",
			"",
			"Baseline - Daily essentials that keep you running",
			"Update - Learning new skills and improving",
			"Upgrade - Major paradigm shifts that level you up",
			"Bloatware - Routines slowing your system down",
			"Virus - Limiting beliefs to debug and transform"
		],
		"icon": "code"
	},
	{
		"title": "Auditing & Redesigning",
		"content": [
			"Empowerment through honest auditing:",
			"",
			"Review your scripts regularly",
			"Identify what's working vs. what's not",
			"Transform Bloatware into Updates",
			"Debug Viruses into Upgrades",
			"",
			"Design intentionally. Run consciously."
		],
		"icon": "refresh"
	}
]


func _ready() -> void:
	# Check if user has seen intro
	has_seen_intro = GameManager.player_data.get("has_seen_script_lab_intro", false)

	# Build the UI
	_create_background()
	_create_main_layout()

	# Show welcome cards if first time
	if not has_seen_intro:
		_show_welcome_overlay()
	else:
		_load_scripts()

	# Play ambient sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_ambient_mindscape"):
		audio.play_ambient_mindscape()

	print("[ScriptLab] Script Lab ready")


func _create_background() -> void:
	background = ColorRect.new()
	background.color = BG_COLOR
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# Add circuit pattern overlay
	var pattern = ColorRect.new()
	pattern.color = Color(0.1, 0.2, 0.15, 0.05)
	pattern.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_child(pattern)


func _create_main_layout() -> void:
	main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 0)
	add_child(main_container)

	_create_header()
	_create_content_area()
	_create_toolbar()


func _create_header() -> void:
	header = PanelContainer.new()
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	header_style.border_color = ACCENT_COLOR.darkened(0.5)
	header_style.border_width_bottom = 2
	header.add_theme_stylebox_override("panel", header_style)
	header.custom_minimum_size.y = 60
	main_container.add_child(header)

	var header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 20)
	header_margin.add_theme_constant_override("margin_right", 20)
	header_margin.add_theme_constant_override("margin_top", 12)
	header_margin.add_theme_constant_override("margin_bottom", 12)
	header.add_child(header_margin)

	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 20)
	header_margin.add_child(header_hbox)

	# Title
	var title = Label.new()
	title.text = "Script Lab"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	header_hbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Personal Operating System Editor"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", MUTED_COLOR)
	subtitle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header_hbox.add_child(subtitle)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	# Stats display
	var stats = ScriptManager.get_stats()
	var stats_label = Label.new()
	stats_label.text = "%d scripts | %d min focused" % [stats.total_scripts, stats.total_focus_minutes]
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", MUTED_COLOR)
	stats_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header_hbox.add_child(stats_label)


func _create_content_area() -> void:
	var content_margin = MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 20)
	content_margin.add_theme_constant_override("margin_right", 20)
	content_margin.add_theme_constant_override("margin_top", 15)
	content_margin.add_theme_constant_override("margin_bottom", 15)
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(content_margin)

	content_area = HSplitContainer.new()
	content_area.split_offset = 300
	content_margin.add_child(content_area)

	_create_script_list_panel()
	_create_editor_panel()


func _create_script_list_panel() -> void:
	script_list_panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = PANEL_COLOR
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	script_list_panel.add_theme_stylebox_override("panel", panel_style)
	script_list_panel.custom_minimum_size.x = 280
	content_area.add_child(script_list_panel)

	var list_margin = MarginContainer.new()
	list_margin.add_theme_constant_override("margin_left", 12)
	list_margin.add_theme_constant_override("margin_right", 12)
	list_margin.add_theme_constant_override("margin_top", 12)
	list_margin.add_theme_constant_override("margin_bottom", 12)
	script_list_panel.add_child(list_margin)

	var list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 10)
	list_margin.add_child(list_vbox)

	# Filter header
	var filter_header = Label.new()
	filter_header.text = "SCRIPTS"
	filter_header.add_theme_font_size_override("font_size", 12)
	filter_header.add_theme_color_override("font_color", MUTED_COLOR)
	list_vbox.add_child(filter_header)

	# Filter row
	var filter_row = HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 8)
	list_vbox.add_child(filter_row)

	# Domain filter
	domain_filter = OptionButton.new()
	domain_filter.add_item("All Domains")
	for layer in ScriptManager.DEFAULT_LAYERS:
		domain_filter.add_item(layer.name)
	domain_filter.custom_minimum_size.x = 100
	domain_filter.item_selected.connect(_on_domain_filter_changed)
	filter_row.add_child(domain_filter)

	# Operational filter
	operational_filter = OptionButton.new()
	operational_filter.add_item("All Layers")
	for op_layer in ScriptManager.OPERATIONAL_LAYERS:
		operational_filter.add_item(op_layer.name)
	operational_filter.custom_minimum_size.x = 100
	operational_filter.item_selected.connect(_on_operational_filter_changed)
	filter_row.add_child(operational_filter)

	# Scroll container for script list
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_vbox.add_child(scroll)

	script_list_container = VBoxContainer.new()
	script_list_container.add_theme_constant_override("separation", 6)
	script_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(script_list_container)


func _create_editor_panel() -> void:
	editor_panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = PANEL_COLOR
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	editor_panel.add_theme_stylebox_override("panel", panel_style)
	content_area.add_child(editor_panel)

	var editor_margin = MarginContainer.new()
	editor_margin.add_theme_constant_override("margin_left", 15)
	editor_margin.add_theme_constant_override("margin_right", 15)
	editor_margin.add_theme_constant_override("margin_top", 15)
	editor_margin.add_theme_constant_override("margin_bottom", 15)
	editor_panel.add_child(editor_margin)

	var editor_vbox = VBoxContainer.new()
	editor_vbox.add_theme_constant_override("separation", 12)
	editor_margin.add_child(editor_vbox)

	# Editor header
	editor_header = HBoxContainer.new()
	editor_header.add_theme_constant_override("separation", 15)
	editor_vbox.add_child(editor_header)

	script_name_label = Label.new()
	script_name_label.text = "Select a script to edit"
	script_name_label.add_theme_font_size_override("font_size", 20)
	script_name_label.add_theme_color_override("font_color", TEXT_COLOR)
	editor_header.add_child(script_name_label)

	var header_spacer = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor_header.add_child(header_spacer)

	script_domain_label = Label.new()
	script_domain_label.text = ""
	script_domain_label.add_theme_font_size_override("font_size", 14)
	editor_header.add_child(script_domain_label)

	script_layer_label = Label.new()
	script_layer_label.text = ""
	script_layer_label.add_theme_font_size_override("font_size", 14)
	editor_header.add_child(script_layer_label)

	# Separator
	var sep = HSeparator.new()
	editor_vbox.add_child(sep)

	# Line editors scroll
	var lines_scroll = ScrollContainer.new()
	lines_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lines_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	editor_vbox.add_child(lines_scroll)

	var lines_container = VBoxContainer.new()
	lines_container.add_theme_constant_override("separation", 4)
	lines_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines_scroll.add_child(lines_container)

	# Create 25 line editors
	for i in range(25):
		var line_row = HBoxContainer.new()
		line_row.add_theme_constant_override("separation", 8)
		lines_container.add_child(line_row)

		# Line number
		var line_num = Label.new()
		line_num.text = "%02d" % (i + 1)
		line_num.add_theme_font_size_override("font_size", 14)
		line_num.add_theme_color_override("font_color", MUTED_COLOR)
		line_num.custom_minimum_size.x = 30
		line_row.add_child(line_num)

		# Line input
		var line_edit = LineEdit.new()
		line_edit.placeholder_text = "Minute %d action..." % (i + 1)
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line_edit.add_theme_font_size_override("font_size", 14)
		line_edit.text_changed.connect(_on_line_changed.bind(i))
		line_row.add_child(line_edit)
		line_editors.append(line_edit)

		# Effectiveness indicator (will be colored based on stats)
		var effectiveness = ColorRect.new()
		effectiveness.name = "Effectiveness"
		effectiveness.custom_minimum_size = Vector2(8, 8)
		effectiveness.color = Color(0.3, 0.3, 0.3, 0.3)
		line_row.add_child(effectiveness)

	# Editor buttons
	var editor_buttons = HBoxContainer.new()
	editor_buttons.add_theme_constant_override("separation", 10)
	editor_buttons.alignment = BoxContainer.ALIGNMENT_END
	editor_vbox.add_child(editor_buttons)

	var save_button = Button.new()
	save_button.text = "Save Script"
	save_button.pressed.connect(_save_current_script)
	editor_buttons.add_child(save_button)

	var run_button = Button.new()
	run_button.text = "Run Script"
	run_button.pressed.connect(_run_current_script)
	editor_buttons.add_child(run_button)


func _create_toolbar() -> void:
	var toolbar_panel = PanelContainer.new()
	var toolbar_style = StyleBoxFlat.new()
	toolbar_style.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	toolbar_style.border_color = ACCENT_COLOR.darkened(0.5)
	toolbar_style.border_width_top = 2
	toolbar_panel.add_theme_stylebox_override("panel", toolbar_style)
	toolbar_panel.custom_minimum_size.y = 55
	main_container.add_child(toolbar_panel)

	var toolbar_margin = MarginContainer.new()
	toolbar_margin.add_theme_constant_override("margin_left", 20)
	toolbar_margin.add_theme_constant_override("margin_right", 20)
	toolbar_margin.add_theme_constant_override("margin_top", 10)
	toolbar_margin.add_theme_constant_override("margin_bottom", 10)
	toolbar_panel.add_child(toolbar_margin)

	toolbar = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 15)
	toolbar_margin.add_child(toolbar)

	# New Script button
	new_script_button = Button.new()
	new_script_button.text = "+ New Script"
	new_script_button.pressed.connect(_show_new_script_dialog)
	toolbar.add_child(new_script_button)

	# Audit Mode button
	audit_mode_button = Button.new()
	audit_mode_button.text = "Audit Mode"
	audit_mode_button.toggle_mode = true
	audit_mode_button.toggled.connect(_toggle_audit_mode)
	toolbar.add_child(audit_mode_button)

	# Packages button
	packages_button = Button.new()
	packages_button.text = "View Packages"
	packages_button.pressed.connect(_show_packages_view)
	toolbar.add_child(packages_button)

	# Templates button
	var templates_button = Button.new()
	templates_button.text = "Templates"
	templates_button.add_theme_color_override("font_color", Color(0.4, 0.8, 0.6))
	templates_button.pressed.connect(_show_templates_browser)
	toolbar.add_child(templates_button)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)

	# Help button
	var help_button = Button.new()
	help_button.text = "?"
	help_button.tooltip_text = "Show welcome cards again"
	help_button.pressed.connect(_show_welcome_overlay)
	toolbar.add_child(help_button)

	# Back button
	back_button = Button.new()
	back_button.text = "Return to Peaks"
	back_button.pressed.connect(_return_to_south)
	toolbar.add_child(back_button)


func _show_welcome_overlay() -> void:
	if welcome_overlay:
		welcome_overlay.queue_free()

	welcome_overlay = Control.new()
	welcome_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(welcome_overlay)

	# Dim background
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	welcome_overlay.add_child(dim)

	current_welcome_card = 0
	_show_welcome_card(current_welcome_card)


func _show_welcome_card(index: int) -> void:
	# Remove previous card
	for child in welcome_overlay.get_children():
		if child is PanelContainer:
			child.queue_free()

	if index >= WELCOME_CARDS.size():
		_close_welcome_overlay()
		return

	var card_data = WELCOME_CARDS[index]

	var card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.14, 0.18, 0.98)
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card_style.border_color = ACCENT_COLOR
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card.add_theme_stylebox_override("panel", card_style)
	card.custom_minimum_size = Vector2(500, 400)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-250, -200)
	welcome_overlay.add_child(card)

	var card_margin = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 30)
	card_margin.add_theme_constant_override("margin_right", 30)
	card_margin.add_theme_constant_override("margin_top", 25)
	card_margin.add_theme_constant_override("margin_bottom", 25)
	card.add_child(card_margin)

	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 15)
	card_margin.add_child(card_vbox)

	# Card indicator
	var indicator_row = HBoxContainer.new()
	indicator_row.alignment = BoxContainer.ALIGNMENT_CENTER
	indicator_row.add_theme_constant_override("separation", 8)
	card_vbox.add_child(indicator_row)

	for i in range(WELCOME_CARDS.size()):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(10, 10)
		dot.color = ACCENT_COLOR if i == index else MUTED_COLOR.darkened(0.3)
		indicator_row.add_child(dot)

	# Title
	var title = Label.new()
	title.text = card_data.title
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(title)

	# Content
	var content_box = VBoxContainer.new()
	content_box.add_theme_constant_override("separation", 6)
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_vbox.add_child(content_box)

	for line in card_data.content:
		var line_label = Label.new()
		line_label.text = line
		line_label.add_theme_font_size_override("font_size", 16)

		# Color special keywords
		if line.begins_with("Mind") or line.begins_with("Body") or line.begins_with("Soul") or \
		   line.begins_with("Social") or line.begins_with("Career") or line.begins_with("Wealth"):
			line_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.95))
		elif line.begins_with("Baseline") or line.begins_with("Update") or line.begins_with("Upgrade"):
			line_label.add_theme_color_override("font_color", ACCENT_COLOR)
		elif line.begins_with("Bloatware"):
			line_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
		elif line.begins_with("Virus"):
			line_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		else:
			line_label.add_theme_color_override("font_color", TEXT_COLOR)

		content_box.add_child(line_label)

	# Navigation buttons
	var nav_row = HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", 15)
	nav_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.add_child(nav_row)

	if index > 0:
		var prev_btn = Button.new()
		prev_btn.text = "< Previous"
		prev_btn.pressed.connect(func(): _show_welcome_card(index - 1))
		nav_row.add_child(prev_btn)

	var skip_btn = Button.new()
	skip_btn.text = "Skip Tutorial"
	skip_btn.pressed.connect(_close_welcome_overlay)
	nav_row.add_child(skip_btn)

	if index < WELCOME_CARDS.size() - 1:
		var next_btn = Button.new()
		next_btn.text = "Next >"
		next_btn.pressed.connect(func(): _show_welcome_card(index + 1))
		nav_row.add_child(next_btn)
	else:
		var start_btn = Button.new()
		start_btn.text = "Start Creating"
		start_btn.pressed.connect(_close_welcome_overlay)
		nav_row.add_child(start_btn)


func _close_welcome_overlay() -> void:
	if welcome_overlay:
		welcome_overlay.queue_free()
		welcome_overlay = null

	# Mark as seen
	GameManager.player_data["has_seen_script_lab_intro"] = true
	has_seen_intro = true

	# Load scripts
	_load_scripts()


func _load_scripts() -> void:
	# Clear existing
	for child in script_list_container.get_children():
		child.queue_free()
	script_items.clear()

	# Get scripts based on filters
	var all_scripts = ScriptManager.get_all_scripts()

	# Apply filters
	var domain_index = domain_filter.selected
	var op_index = operational_filter.selected

	var filtered_scripts = []
	for script in all_scripts:
		var domain_match = domain_index == 0 or script.layer_id == ScriptManager.DEFAULT_LAYERS[domain_index - 1].id
		var op_layer = script.get("operational_layer", "update")
		var op_match = op_index == 0 or op_layer == ScriptManager.OPERATIONAL_LAYERS[op_index - 1].id

		# In audit mode, only show bloatware and virus
		if is_audit_mode:
			if op_layer != "bloatware" and op_layer != "virus":
				continue

		if domain_match and op_match:
			filtered_scripts.append(script)

	# Sort by last executed, then by name
	filtered_scripts.sort_custom(func(a, b):
		var a_time = a.get("last_executed", 0)
		var b_time = b.get("last_executed", 0)
		if a_time != b_time:
			return a_time > b_time
		return a.name < b.name
	)

	# Create script items
	for script in filtered_scripts:
		var item = _create_script_item(script)
		script_list_container.add_child(item)
		script_items.append(item)

	# Show empty state if no scripts
	if filtered_scripts.is_empty():
		var empty_label = Label.new()
		if is_audit_mode:
			empty_label.text = "No scripts need attention.\nYour OS is clean!"
		else:
			empty_label.text = "No scripts yet.\nClick '+ New Script' to create one."
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", MUTED_COLOR)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		script_list_container.add_child(empty_label)


func _create_script_item(script: Dictionary) -> Button:
	var item = Button.new()
	item.custom_minimum_size.y = 50
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Create item layout
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(hbox)

	# Favorite/warning indicator
	var indicator = Label.new()
	indicator.custom_minimum_size.x = 20
	var op_layer = script.get("operational_layer", "update")
	if ScriptManager.is_favorite(script.id):
		indicator.text = "*"
		indicator.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	elif op_layer == "bloatware":
		indicator.text = "!"
		indicator.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
	elif op_layer == "virus":
		indicator.text = "X"
		indicator.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		indicator.text = " "
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(indicator)

	# Script info
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = script.name + ".psa"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", TEXT_COLOR)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vbox.add_child(name_label)

	var meta_label = Label.new()
	var domain_name = ""
	for layer in ScriptManager.DEFAULT_LAYERS:
		if layer.id == script.layer_id:
			domain_name = layer.name
			break
	var op_name = ScriptManager.get_operational_layer_name(op_layer)
	meta_label.text = "%s | %s" % [domain_name, op_name]
	meta_label.add_theme_font_size_override("font_size", 11)
	meta_label.add_theme_color_override("font_color", MUTED_COLOR)
	meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vbox.add_child(meta_label)

	# Store script_id in item
	item.set_meta("script_id", script.id)
	item.pressed.connect(_on_script_selected.bind(script.id))

	# Color border based on operational layer
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.16, 0.2, 0.8)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_width_left = 3
	style.border_color = ScriptManager.get_operational_layer_color(op_layer)
	item.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.2, 0.22, 0.28, 0.9)
	item.add_theme_stylebox_override("hover", hover_style)

	return item


func _on_script_selected(script_id: String) -> void:
	selected_script_id = script_id
	var script = ScriptManager.scripts.get(script_id, {})

	if script.is_empty():
		return

	# Update editor header
	script_name_label.text = script.name + ".psa"

	# Domain label
	var domain_name = ""
	for layer in ScriptManager.DEFAULT_LAYERS:
		if layer.id == script.layer_id:
			domain_name = layer.name
			break
	script_domain_label.text = domain_name
	script_domain_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.95))

	# Operational layer label
	var op_layer = script.get("operational_layer", "update")
	script_layer_label.text = ScriptManager.get_operational_layer_name(op_layer)
	script_layer_label.add_theme_color_override("font_color", ScriptManager.get_operational_layer_color(op_layer))

	# Load lines into editors
	var lines = script.get("lines", [])
	var effectiveness = ScriptManager.get_line_effectiveness(script_id)

	for i in range(25):
		if i < lines.size():
			line_editors[i].text = lines[i]
		else:
			line_editors[i].text = ""

		# Update effectiveness indicator
		var eff_rect = line_editors[i].get_parent().get_node_or_null("Effectiveness")
		if eff_rect and i < effectiveness.size():
			var eff = effectiveness[i]
			match eff.get("status", "no_data"):
				"good":
					eff_rect.color = ACCENT_COLOR
				"needs_work":
					eff_rect.color = Color(0.9, 0.7, 0.3)
				"problematic":
					eff_rect.color = Color(0.9, 0.3, 0.3)
				_:
					eff_rect.color = Color(0.3, 0.3, 0.3, 0.3)


func _on_line_changed(new_text: String, line_index: int) -> void:
	# Auto-save on edit (or mark dirty for manual save)
	pass


func _save_current_script() -> void:
	if selected_script_id.is_empty():
		return

	var lines = []
	for editor in line_editors:
		lines.append(editor.text)

	ScriptManager.update_script(selected_script_id, {"lines": lines})

	# Show confirmation
	_play_sfx("res://audio/sfx/ui_confirm.wav")


func _run_current_script() -> void:
	if selected_script_id.is_empty():
		return

	# Save first
	_save_current_script()

	# Execute and go to focus chamber
	var script = ScriptManager.execute_script(selected_script_id)
	if script:
		GameManager.player_data["pending_focus_script"] = script
		GameManager.goto_scene("res://scenes/focus_chamber/focus_chamber.tscn")


func _on_domain_filter_changed(index: int) -> void:
	_load_scripts()


func _on_operational_filter_changed(index: int) -> void:
	_load_scripts()


func _toggle_audit_mode(toggled: bool) -> void:
	is_audit_mode = toggled

	if is_audit_mode:
		audit_mode_button.text = "Exit Audit"
		script_list_panel.modulate = Color(1, 0.95, 0.9)
	else:
		audit_mode_button.text = "Audit Mode"
		script_list_panel.modulate = Color.WHITE

	_load_scripts()


func _show_new_script_dialog() -> void:
	# Create a simple dialog for new script
	var dialog = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 0.98)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = ACCENT_COLOR
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	dialog.add_theme_stylebox_override("panel", style)
	dialog.custom_minimum_size = Vector2(400, 350)
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.position = Vector2(-200, -175)
	add_child(dialog)

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
	title.text = "Create New Script"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Name input
	var name_label = Label.new()
	name_label.text = "Script Name:"
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)

	var name_input = LineEdit.new()
	name_input.placeholder_text = "e.g., morning_routine"
	vbox.add_child(name_input)

	# Domain selector
	var domain_label = Label.new()
	domain_label.text = "Domain:"
	domain_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(domain_label)

	var domain_select = OptionButton.new()
	for layer in ScriptManager.DEFAULT_LAYERS:
		domain_select.add_item(layer.name)
	vbox.add_child(domain_select)

	# Operational layer selector
	var op_label = Label.new()
	op_label.text = "Operational Layer:"
	op_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(op_label)

	var op_select = OptionButton.new()
	for op_layer in ScriptManager.OPERATIONAL_LAYERS:
		op_select.add_item(op_layer.name)
	op_select.select(1)  # Default to "Update"
	vbox.add_child(op_select)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(func(): dialog.queue_free())
	btn_row.add_child(cancel_btn)

	var create_btn = Button.new()
	create_btn.text = "Create"
	create_btn.pressed.connect(func():
		var script_name = name_input.text.strip_edges()
		if script_name.is_empty():
			script_name = "untitled"
		var domain_id = ScriptManager.DEFAULT_LAYERS[domain_select.selected].id
		var op_layer_id = ScriptManager.OPERATIONAL_LAYERS[op_select.selected].id

		var script_id = ScriptManager.create_script({
			"name": script_name,
			"layer_id": domain_id,
			"operational_layer": op_layer_id
		})

		dialog.queue_free()
		_load_scripts()

		# Select the new script
		if script_id:
			_on_script_selected(script_id)
	)
	btn_row.add_child(create_btn)


func _show_packages_view() -> void:
	_play_sfx("res://audio/sfx/ui_click.wav")
	_open_packages_panel()


# =============================================================================
# TEMPLATE LIBRARY BROWSER
# =============================================================================

var templates_panel: Control = null
var template_filter_domain: String = ""
var template_filter_operational: String = ""


func _show_templates_browser() -> void:
	_play_sfx("res://audio/sfx/ui_click.wav")

	if templates_panel:
		return

	# Create fullscreen overlay
	templates_panel = Control.new()
	templates_panel.name = "TemplatesPanel"
	templates_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(templates_panel)

	# Background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.08, 0.98)
	templates_panel.add_child(bg)

	# Main panel
	var main_panel = PanelContainer.new()
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.offset_left = -550
	main_panel.offset_right = 550
	main_panel.offset_top = -400
	main_panel.offset_bottom = 400
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	main_style.set_corner_radius_all(12)
	main_style.border_color = Color(0.3, 0.6, 0.4, 0.6)
	main_style.set_border_width_all(2)
	main_panel.add_theme_stylebox_override("panel", main_style)
	templates_panel.add_child(main_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	main_panel.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(main_vbox)

	# Header
	var header_row = HBoxContainer.new()
	main_vbox.add_child(header_row)

	var title = Label.new()
	title.text = "Script Template Library"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 0.6))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(45, 45)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_templates_browser)
	header_row.add_child(close_btn)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Choose a template to spark inspiration and accelerate your progress"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", MUTED_COLOR)
	main_vbox.add_child(subtitle)

	# Filter row
	var filter_row = HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 20)
	main_vbox.add_child(filter_row)

	# Domain filter
	var domain_label = Label.new()
	domain_label.text = "Domain:"
	domain_label.add_theme_font_size_override("font_size", 14)
	domain_label.add_theme_color_override("font_color", MUTED_COLOR)
	filter_row.add_child(domain_label)

	var domain_filter_btn = OptionButton.new()
	domain_filter_btn.name = "DomainFilter"
	domain_filter_btn.add_item("All Domains", 0)
	for i in range(ScriptManager.DEFAULT_LAYERS.size()):
		var layer = ScriptManager.DEFAULT_LAYERS[i]
		domain_filter_btn.add_item(layer.name, i + 1)
	domain_filter_btn.item_selected.connect(_on_template_domain_filter_changed)
	filter_row.add_child(domain_filter_btn)

	# Operational filter
	var op_label = Label.new()
	op_label.text = "Type:"
	op_label.add_theme_font_size_override("font_size", 14)
	op_label.add_theme_color_override("font_color", MUTED_COLOR)
	filter_row.add_child(op_label)

	var op_filter_btn = OptionButton.new()
	op_filter_btn.name = "OperationalFilter"
	op_filter_btn.add_item("All Types", 0)
	for i in range(ScriptManager.OPERATIONAL_LAYERS.size()):
		var layer = ScriptManager.OPERATIONAL_LAYERS[i]
		op_filter_btn.add_item(layer.name, i + 1)
	op_filter_btn.item_selected.connect(_on_template_op_filter_changed)
	filter_row.add_child(op_filter_btn)

	var sep = HSeparator.new()
	main_vbox.add_child(sep)

	# Template grid scroll
	var scroll = ScrollContainer.new()
	scroll.name = "TemplateScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	var grid = GridContainer.new()
	grid.name = "TemplateGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	# Populate templates
	_populate_template_grid()


func _populate_template_grid() -> void:
	if not templates_panel:
		return

	var grid = templates_panel.get_node_or_null("TemplatesPanel/PanelContainer/MarginContainer/VBoxContainer/TemplateScroll/TemplateGrid")
	if not grid:
		grid = templates_panel.find_child("TemplateGrid", true, false)
	if not grid:
		return

	# Clear existing
	for child in grid.get_children():
		child.queue_free()

	# Get all templates
	var templates = ScriptManager.get_templates()

	# Apply filters
	var filtered = []
	for t in templates:
		var domain_match = template_filter_domain == "" or t.layer_id == template_filter_domain
		var op_match = template_filter_operational == "" or t.operational_layer == template_filter_operational
		if domain_match and op_match:
			filtered.append(t)

	# Create template cards
	for template in filtered:
		var card = _create_template_card(template)
		grid.add_child(card)


func _create_template_card(template: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(500, 140)

	# Get colors based on domain and operational layer
	var domain_color = _get_domain_color(template.layer_id)
	var op_color = _get_operational_color(template.operational_layer)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.11, 0.15, 0.95)
	style.set_corner_radius_all(8)
	style.border_color = domain_color.darkened(0.3)
	style.border_width_left = 4
	style.set_border_width_all(1)
	style.border_width_left = 4
	card.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Header row
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	vbox.add_child(header_row)

	var name_label = Label.new()
	name_label.text = template.name
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(name_label)

	# Preview button - see all lines
	var preview_btn = Button.new()
	preview_btn.text = "View All Lines"
	preview_btn.add_theme_font_size_override("font_size", 12)
	preview_btn.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75))
	preview_btn.pressed.connect(_show_template_detail.bind(template))
	header_row.add_child(preview_btn)

	# Use button
	var use_btn = Button.new()
	use_btn.text = "Use"
	use_btn.add_theme_font_size_override("font_size", 13)
	use_btn.add_theme_color_override("font_color", ACCENT_COLOR)
	use_btn.pressed.connect(_use_template.bind(template.id))
	header_row.add_child(use_btn)

	# Tags row
	var tags_row = HBoxContainer.new()
	tags_row.add_theme_constant_override("separation", 8)
	vbox.add_child(tags_row)

	# Domain tag
	var domain_tag = _create_tag(template.layer_id.capitalize(), domain_color)
	tags_row.add_child(domain_tag)

	# Operational tag
	var op_tag = _create_tag(template.operational_layer.capitalize(), op_color)
	tags_row.add_child(op_tag)

	# Line count
	var line_count_tag = _create_tag(str(template.lines.size()) + " lines", Color(0.5, 0.5, 0.6))
	tags_row.add_child(line_count_tag)

	# Description
	var desc_label = Label.new()
	desc_label.text = template.description
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", MUTED_COLOR)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_label)

	# Preview of first 3 lines
	var preview = Label.new()
	var preview_text = ""
	for i in range(mini(3, template.lines.size())):
		preview_text += str(i + 1) + ". " + template.lines[i] + "\n"
	if template.lines.size() > 3:
		preview_text += "..."
	preview.text = preview_text.strip_edges()
	preview.add_theme_font_size_override("font_size", 11)
	preview.add_theme_color_override("font_color", Color(0.45, 0.5, 0.55))
	vbox.add_child(preview)

	return card


func _create_tag(text: String, color: Color) -> PanelContainer:
	var tag = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.6)
	style.bg_color.a = 0.4
	style.set_corner_radius_all(4)
	tag.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	tag.add_child(margin)

	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", color)
	margin.add_child(label)

	return tag


func _get_domain_color(domain_id: String) -> Color:
	match domain_id:
		"mind": return Color(0.5, 0.7, 0.9)
		"body": return Color(0.9, 0.5, 0.5)
		"soul": return Color(0.8, 0.6, 0.9)
		"social": return Color(0.5, 0.9, 0.7)
		"career": return Color(0.9, 0.8, 0.4)
		"wealth": return Color(0.4, 0.9, 0.6)
	return Color(0.6, 0.6, 0.7)


func _get_operational_color(op_id: String) -> Color:
	match op_id:
		"baseline": return Color(0.5, 0.7, 0.9)
		"update": return Color(0.3, 0.6, 0.9)
		"upgrade": return Color(0.4, 0.8, 0.4)
		"bloatware": return Color(0.9, 0.6, 0.2)
		"virus": return Color(0.8, 0.3, 0.3)
	return Color(0.6, 0.6, 0.7)


func _on_template_domain_filter_changed(index: int) -> void:
	if index == 0:
		template_filter_domain = ""
	else:
		template_filter_domain = ScriptManager.DEFAULT_LAYERS[index - 1].id
	_populate_template_grid()


func _on_template_op_filter_changed(index: int) -> void:
	if index == 0:
		template_filter_operational = ""
	else:
		template_filter_operational = ScriptManager.OPERATIONAL_LAYERS[index - 1].id
	_populate_template_grid()


func _use_template(template_id: String) -> void:
	_play_sfx("res://audio/sfx/ui_click.wav")

	# Create script from template
	var script_id = ScriptManager.create_script_from_template(template_id)

	if script_id != "":
		# Close templates panel
		_close_templates_browser()

		# Reload scripts and select the new one
		_load_scripts()
		_on_script_selected(script_id)

		# Show confirmation
		print("[ScriptLab] Created script from template: ", script_id)


func _show_template_detail(template: Dictionary) -> void:
	_play_sfx("res://audio/sfx/ui_click.wav")

	# Create detail overlay
	var detail_panel = Control.new()
	detail_panel.name = "TemplateDetailPanel"
	detail_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(detail_panel)

	# Dim background
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.85)
	detail_panel.add_child(dim)

	# Main card
	var card = PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -400
	card.offset_right = 400
	card.offset_top = -350
	card.offset_bottom = 350
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	card_style.set_corner_radius_all(12)
	card_style.border_color = _get_domain_color(template.layer_id)
	card_style.set_border_width_all(2)
	card.add_theme_stylebox_override("panel", card_style)
	detail_panel.add_child(card)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Header row
	var header_row = HBoxContainer.new()
	vbox.add_child(header_row)

	var title = Label.new()
	title.text = template.name
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", _get_domain_color(template.layer_id))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(func(): detail_panel.queue_free())
	header_row.add_child(close_btn)

	# Tags row
	var tags_row = HBoxContainer.new()
	tags_row.add_theme_constant_override("separation", 10)
	vbox.add_child(tags_row)

	var domain_tag = _create_tag(template.layer_id.capitalize(), _get_domain_color(template.layer_id))
	tags_row.add_child(domain_tag)

	var op_tag = _create_tag(template.operational_layer.capitalize(), _get_operational_color(template.operational_layer))
	tags_row.add_child(op_tag)

	var lines_tag = _create_tag(str(template.lines.size()) + " lines", Color(0.5, 0.6, 0.7))
	tags_row.add_child(lines_tag)

	# Description
	var desc = Label.new()
	desc.text = template.description
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", MUTED_COLOR)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# All lines header
	var lines_header = Label.new()
	lines_header.text = "FULL SCRIPT (%d minutes)" % template.lines.size()
	lines_header.add_theme_font_size_override("font_size", 12)
	lines_header.add_theme_color_override("font_color", MUTED_COLOR)
	vbox.add_child(lines_header)

	# Scrollable lines list
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var lines_vbox = VBoxContainer.new()
	lines_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(lines_vbox)

	# Display all lines with line numbers
	for i in range(template.lines.size()):
		var line_row = HBoxContainer.new()
		line_row.add_theme_constant_override("separation", 12)
		lines_vbox.add_child(line_row)

		# Line number
		var line_num = Label.new()
		line_num.text = "%02d" % (i + 1)
		line_num.add_theme_font_size_override("font_size", 13)
		line_num.add_theme_color_override("font_color", Color(0.4, 0.45, 0.5))
		line_num.custom_minimum_size.x = 28
		line_row.add_child(line_num)

		# Line content
		var line_text = Label.new()
		line_text.text = template.lines[i]
		line_text.add_theme_font_size_override("font_size", 14)
		line_text.add_theme_color_override("font_color", TEXT_COLOR)
		line_text.autowrap_mode = TextServer.AUTOWRAP_WORD
		line_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line_row.add_child(line_text)

	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	# Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Close"
	cancel_btn.custom_minimum_size = Vector2(120, 45)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(func(): detail_panel.queue_free())
	btn_row.add_child(cancel_btn)

	var use_btn = Button.new()
	use_btn.text = "Use This Template"
	use_btn.custom_minimum_size = Vector2(180, 45)
	use_btn.add_theme_font_size_override("font_size", 16)
	use_btn.add_theme_color_override("font_color", ACCENT_COLOR)
	use_btn.pressed.connect(func():
		detail_panel.queue_free()
		_use_template(template.id)
	)
	btn_row.add_child(use_btn)


func _close_templates_browser() -> void:
	if templates_panel:
		templates_panel.queue_free()
		templates_panel = null
	template_filter_domain = ""
	template_filter_operational = ""


# =============================================================================
# PACKAGE MANAGEMENT
# =============================================================================

var packages_panel: Control = null
var package_list_container: VBoxContainer = null
var package_detail_container: VBoxContainer = null
var selected_package_id: String = ""
var creating_new_package: bool = false

func _open_packages_panel() -> void:
	if packages_panel:
		return

	# Create fullscreen overlay
	packages_panel = Control.new()
	packages_panel.name = "PackagesPanel"
	packages_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(packages_panel)

	# Background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.08, 0.98)
	packages_panel.add_child(bg)

	# Main panel
	var main_panel = PanelContainer.new()
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.offset_left = -500
	main_panel.offset_right = 500
	main_panel.offset_top = -350
	main_panel.offset_bottom = 350
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	main_style.set_corner_radius_all(12)
	main_style.border_color = Color(0.3, 0.35, 0.5, 0.5)
	main_style.set_border_width_all(2)
	main_panel.add_theme_stylebox_override("panel", main_style)
	packages_panel.add_child(main_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	main_panel.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(main_vbox)

	# Header
	var header_row = HBoxContainer.new()
	main_vbox.add_child(header_row)

	var title = Label.new()
	title.text = "Script Packages"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(45, 45)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_packages_panel)
	header_row.add_child(close_btn)

	var sep = HSeparator.new()
	main_vbox.add_child(sep)

	# Content: two columns
	var content_row = HBoxContainer.new()
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 20)
	main_vbox.add_child(content_row)

	# Left column: package list
	var left_col = VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(280, 0)
	left_col.add_theme_constant_override("separation", 10)
	content_row.add_child(left_col)

	var list_header = HBoxContainer.new()
	left_col.add_child(list_header)

	var list_title = Label.new()
	list_title.text = "Packages"
	list_title.add_theme_font_size_override("font_size", 18)
	list_title.add_theme_color_override("font_color", MUTED_COLOR)
	list_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_header.add_child(list_title)

	var new_pkg_btn = Button.new()
	new_pkg_btn.text = "+ New"
	new_pkg_btn.custom_minimum_size = Vector2(80, 35)
	new_pkg_btn.add_theme_font_size_override("font_size", 14)
	new_pkg_btn.pressed.connect(_create_new_package)
	list_header.add_child(new_pkg_btn)

	# Package list scroll
	var pkg_scroll = ScrollContainer.new()
	pkg_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_col.add_child(pkg_scroll)

	package_list_container = VBoxContainer.new()
	package_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	package_list_container.add_theme_constant_override("separation", 8)
	pkg_scroll.add_child(package_list_container)

	# Right column: package details
	var right_col = PanelContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right_style = StyleBoxFlat.new()
	right_style.bg_color = Color(0.06, 0.07, 0.1, 0.8)
	right_style.set_corner_radius_all(8)
	right_col.add_theme_stylebox_override("panel", right_style)
	content_row.add_child(right_col)

	var right_margin = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 20)
	right_margin.add_theme_constant_override("margin_right", 20)
	right_margin.add_theme_constant_override("margin_top", 15)
	right_margin.add_theme_constant_override("margin_bottom", 15)
	right_col.add_child(right_margin)

	package_detail_container = VBoxContainer.new()
	package_detail_container.add_theme_constant_override("separation", 12)
	right_margin.add_child(package_detail_container)

	# Initial detail view
	_show_package_welcome()

	# Populate package list
	_refresh_package_list()


func _close_packages_panel() -> void:
	if packages_panel:
		packages_panel.queue_free()
		packages_panel = null
	package_list_container = null
	package_detail_container = null
	selected_package_id = ""
	creating_new_package = false
	_play_sfx("res://audio/sfx/ui_close.wav")


func _refresh_package_list() -> void:
	if not package_list_container:
		return

	# Clear existing
	for child in package_list_container.get_children():
		child.queue_free()

	# Get all packages organized by layer
	var all_packages = ScriptManager.packages

	if all_packages.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No packages yet.\n\nCreate packages to organize\nyour scripts into bundles."
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", MUTED_COLOR)
		package_list_container.add_child(empty_label)
		return

	# Group by layer
	var by_layer: Dictionary = {}
	for pkg_id in all_packages:
		var pkg = all_packages[pkg_id]
		var layer_id = pkg.get("layer_id", "mind")
		if not by_layer.has(layer_id):
			by_layer[layer_id] = []
		by_layer[layer_id].append(pkg)

	# Create buttons for each package
	for layer_id in by_layer:
		var layer_info = _get_layer_info(layer_id)

		var layer_header = Label.new()
		layer_header.text = layer_info.name
		layer_header.add_theme_font_size_override("font_size", 12)
		layer_header.add_theme_color_override("font_color", layer_info.color.darkened(0.2))
		package_list_container.add_child(layer_header)

		for pkg in by_layer[layer_id]:
			var btn = Button.new()
			btn.text = pkg.get("name", "Unnamed Package")
			btn.custom_minimum_size = Vector2(0, 40)
			btn.add_theme_font_size_override("font_size", 15)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			var pkg_id = pkg.get("id", "")
			btn.pressed.connect(_select_package.bind(pkg_id))
			if pkg_id == selected_package_id:
				btn.add_theme_color_override("font_color", ACCENT_COLOR)
			package_list_container.add_child(btn)


func _get_layer_info(layer_id: String) -> Dictionary:
	var layers = ScriptManager.DOMAIN_LAYERS
	for layer in layers:
		if layer.id == layer_id:
			return layer
	return {"id": "unknown", "name": "Unknown", "color": Color.WHITE}


func _show_package_welcome() -> void:
	if not package_detail_container:
		return

	for child in package_detail_container.get_children():
		child.queue_free()

	var spacer1 = Control.new()
	spacer1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	package_detail_container.add_child(spacer1)

	var welcome_title = Label.new()
	welcome_title.text = "Package Management"
	welcome_title.add_theme_font_size_override("font_size", 22)
	welcome_title.add_theme_color_override("font_color", Color(0.6, 0.65, 0.8))
	welcome_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	package_detail_container.add_child(welcome_title)

	var welcome_text = Label.new()
	welcome_text.text = "Packages bundle related scripts together.\n\nSelect a package to view its contents,\nor create a new one to organize your scripts."
	welcome_text.add_theme_font_size_override("font_size", 15)
	welcome_text.add_theme_color_override("font_color", MUTED_COLOR)
	welcome_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	package_detail_container.add_child(welcome_text)

	var spacer2 = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	package_detail_container.add_child(spacer2)


func _select_package(pkg_id: String) -> void:
	selected_package_id = pkg_id
	_play_sfx("res://audio/sfx/ui_click.wav")
	_refresh_package_list()
	_show_package_details(pkg_id)


func _show_package_details(pkg_id: String) -> void:
	if not package_detail_container:
		return

	for child in package_detail_container.get_children():
		child.queue_free()

	var pkg = ScriptManager.packages.get(pkg_id, {})
	if pkg.is_empty():
		_show_package_welcome()
		return

	var layer_info = _get_layer_info(pkg.get("layer_id", "mind"))

	# Package name
	var name_row = HBoxContainer.new()
	package_detail_container.add_child(name_row)

	var name_label = Label.new()
	name_label.text = pkg.get("name", "Unnamed")
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", layer_info.color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)

	var edit_btn = Button.new()
	edit_btn.text = "Edit"
	edit_btn.custom_minimum_size = Vector2(60, 30)
	edit_btn.pressed.connect(_edit_package.bind(pkg_id))
	name_row.add_child(edit_btn)

	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(70, 30)
	delete_btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	delete_btn.pressed.connect(_delete_package.bind(pkg_id))
	name_row.add_child(delete_btn)

	# Layer badge
	var layer_label = Label.new()
	layer_label.text = layer_info.name + " Domain"
	layer_label.add_theme_font_size_override("font_size", 14)
	layer_label.add_theme_color_override("font_color", MUTED_COLOR)
	package_detail_container.add_child(layer_label)

	# Description
	if pkg.get("description", "") != "":
		var desc_label = Label.new()
		desc_label.text = pkg.description
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		package_detail_container.add_child(desc_label)

	var sep = HSeparator.new()
	package_detail_container.add_child(sep)

	# Scripts in package
	var scripts_header = HBoxContainer.new()
	package_detail_container.add_child(scripts_header)

	var scripts_title = Label.new()
	scripts_title.text = "Scripts in Package"
	scripts_title.add_theme_font_size_override("font_size", 16)
	scripts_title.add_theme_color_override("font_color", Color(0.6, 0.65, 0.8))
	scripts_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scripts_header.add_child(scripts_title)

	var add_script_btn = Button.new()
	add_script_btn.text = "+ Add Script"
	add_script_btn.custom_minimum_size = Vector2(100, 30)
	add_script_btn.add_theme_font_size_override("font_size", 13)
	add_script_btn.pressed.connect(_add_script_to_package.bind(pkg_id))
	scripts_header.add_child(add_script_btn)

	# Script list scroll
	var scripts_scroll = ScrollContainer.new()
	scripts_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scripts_scroll.custom_minimum_size = Vector2(0, 200)
	package_detail_container.add_child(scripts_scroll)

	var scripts_list = VBoxContainer.new()
	scripts_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scripts_list.add_theme_constant_override("separation", 6)
	scripts_scroll.add_child(scripts_list)

	var script_ids = pkg.get("scripts", [])
	if script_ids.is_empty():
		var empty = Label.new()
		empty.text = "No scripts in this package yet.\nAdd scripts to bundle them together."
		empty.add_theme_font_size_override("font_size", 14)
		empty.add_theme_color_override("font_color", MUTED_COLOR)
		scripts_list.add_child(empty)
	else:
		for script_id in script_ids:
			var script = ScriptManager.get_script_by_id(script_id)
			if script.is_empty():
				continue

			var script_row = HBoxContainer.new()
			script_row.add_theme_constant_override("separation", 10)
			scripts_list.add_child(script_row)

			var script_name = Label.new()
			script_name.text = script.get("name", "Unnamed Script")
			script_name.add_theme_font_size_override("font_size", 15)
			script_name.add_theme_color_override("font_color", TEXT_COLOR)
			script_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			script_row.add_child(script_name)

			var lines_count = script.get("lines", []).size()
			var lines_label = Label.new()
			lines_label.text = "%d lines" % lines_count
			lines_label.add_theme_font_size_override("font_size", 13)
			lines_label.add_theme_color_override("font_color", MUTED_COLOR)
			script_row.add_child(lines_label)

			var remove_btn = Button.new()
			remove_btn.text = "Remove"
			remove_btn.custom_minimum_size = Vector2(70, 28)
			remove_btn.add_theme_font_size_override("font_size", 12)
			remove_btn.pressed.connect(_remove_script_from_package.bind(pkg_id, script_id))
			script_row.add_child(remove_btn)

	# Run package button
	if not script_ids.is_empty():
		var run_sep = HSeparator.new()
		package_detail_container.add_child(run_sep)

		var run_btn = Button.new()
		run_btn.text = "Run Package (Execute All Scripts)"
		run_btn.custom_minimum_size = Vector2(0, 45)
		run_btn.add_theme_font_size_override("font_size", 16)
		run_btn.pressed.connect(_run_package.bind(pkg_id))
		package_detail_container.add_child(run_btn)


func _create_new_package() -> void:
	creating_new_package = true
	_play_sfx("res://audio/sfx/ui_click.wav")

	if not package_detail_container:
		return

	for child in package_detail_container.get_children():
		child.queue_free()

	var form_title = Label.new()
	form_title.text = "Create New Package"
	form_title.add_theme_font_size_override("font_size", 22)
	form_title.add_theme_color_override("font_color", ACCENT_COLOR)
	package_detail_container.add_child(form_title)

	# Name input
	var name_label = Label.new()
	name_label.text = "Package Name"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", MUTED_COLOR)
	package_detail_container.add_child(name_label)

	var name_input = LineEdit.new()
	name_input.name = "NameInput"
	name_input.placeholder_text = "e.g., Morning Routine"
	name_input.custom_minimum_size = Vector2(0, 40)
	name_input.add_theme_font_size_override("font_size", 16)
	package_detail_container.add_child(name_input)

	# Domain selector
	var domain_label = Label.new()
	domain_label.text = "Domain"
	domain_label.add_theme_font_size_override("font_size", 14)
	domain_label.add_theme_color_override("font_color", MUTED_COLOR)
	package_detail_container.add_child(domain_label)

	var domain_select = OptionButton.new()
	domain_select.name = "DomainSelect"
	domain_select.custom_minimum_size = Vector2(0, 40)
	domain_select.add_theme_font_size_override("font_size", 16)
	for layer in ScriptManager.DOMAIN_LAYERS:
		domain_select.add_item(layer.name, domain_select.item_count)
	package_detail_container.add_child(domain_select)

	# Description
	var desc_label = Label.new()
	desc_label.text = "Description (optional)"
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", MUTED_COLOR)
	package_detail_container.add_child(desc_label)

	var desc_input = TextEdit.new()
	desc_input.name = "DescInput"
	desc_input.placeholder_text = "Brief description of this package..."
	desc_input.custom_minimum_size = Vector2(0, 80)
	desc_input.add_theme_font_size_override("font_size", 14)
	package_detail_container.add_child(desc_input)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	package_detail_container.add_child(spacer)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	package_detail_container.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(100, 45)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(func():
		creating_new_package = false
		_show_package_welcome()
	)
	btn_row.add_child(cancel_btn)

	var create_btn = Button.new()
	create_btn.text = "Create Package"
	create_btn.custom_minimum_size = Vector2(150, 45)
	create_btn.add_theme_font_size_override("font_size", 16)
	create_btn.pressed.connect(_save_new_package)
	btn_row.add_child(create_btn)


func _save_new_package() -> void:
	if not package_detail_container:
		return

	var name_input = package_detail_container.find_child("NameInput", true, false) as LineEdit
	var domain_select = package_detail_container.find_child("DomainSelect", true, false) as OptionButton
	var desc_input = package_detail_container.find_child("DescInput", true, false) as TextEdit

	if not name_input or name_input.text.strip_edges() == "":
		return

	var domain_idx = domain_select.selected if domain_select else 0
	var layer_id = ScriptManager.DOMAIN_LAYERS[domain_idx].id if domain_idx < ScriptManager.DOMAIN_LAYERS.size() else "mind"
	var description = desc_input.text.strip_edges() if desc_input else ""

	var pkg_id = ScriptManager.create_package(layer_id, name_input.text.strip_edges(), description)
	SaveManager.save_game()

	creating_new_package = false
	selected_package_id = pkg_id
	_play_sfx("res://audio/sfx/select.wav")
	_refresh_package_list()
	_show_package_details(pkg_id)


func _edit_package(pkg_id: String) -> void:
	# For now, just allow renaming
	var pkg = ScriptManager.packages.get(pkg_id, {})
	if pkg.is_empty():
		return

	_play_sfx("res://audio/sfx/ui_click.wav")

	for child in package_detail_container.get_children():
		child.queue_free()

	var form_title = Label.new()
	form_title.text = "Edit Package"
	form_title.add_theme_font_size_override("font_size", 22)
	form_title.add_theme_color_override("font_color", ACCENT_COLOR)
	package_detail_container.add_child(form_title)

	# Name input
	var name_label = Label.new()
	name_label.text = "Package Name"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", MUTED_COLOR)
	package_detail_container.add_child(name_label)

	var name_input = LineEdit.new()
	name_input.name = "NameInput"
	name_input.text = pkg.get("name", "")
	name_input.custom_minimum_size = Vector2(0, 40)
	name_input.add_theme_font_size_override("font_size", 16)
	package_detail_container.add_child(name_input)

	# Description
	var desc_label = Label.new()
	desc_label.text = "Description"
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", MUTED_COLOR)
	package_detail_container.add_child(desc_label)

	var desc_input = TextEdit.new()
	desc_input.name = "DescInput"
	desc_input.text = pkg.get("description", "")
	desc_input.custom_minimum_size = Vector2(0, 80)
	desc_input.add_theme_font_size_override("font_size", 14)
	package_detail_container.add_child(desc_input)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	package_detail_container.add_child(spacer)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	package_detail_container.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(100, 45)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(func(): _show_package_details(pkg_id))
	btn_row.add_child(cancel_btn)

	var save_btn = Button.new()
	save_btn.text = "Save Changes"
	save_btn.custom_minimum_size = Vector2(130, 45)
	save_btn.add_theme_font_size_override("font_size", 16)
	save_btn.pressed.connect(func():
		var new_name = name_input.text.strip_edges()
		var new_desc = desc_input.text.strip_edges()
		if new_name != "" and ScriptManager.packages.has(pkg_id):
			ScriptManager.packages[pkg_id].name = new_name
			ScriptManager.packages[pkg_id].description = new_desc
			SaveManager.save_game()
		_play_sfx("res://audio/sfx/select.wav")
		_refresh_package_list()
		_show_package_details(pkg_id)
	)
	btn_row.add_child(save_btn)


func _delete_package(pkg_id: String) -> void:
	# Confirm and delete
	if ScriptManager.packages.has(pkg_id):
		# Remove from layer
		var pkg = ScriptManager.packages[pkg_id]
		var layer_id = pkg.get("layer_id", "")
		if ScriptManager.personal_os.layers.has(layer_id):
			ScriptManager.personal_os.layers[layer_id].packages.erase(pkg_id)

		# Remove package
		ScriptManager.packages.erase(pkg_id)
		SaveManager.save_game()

		_play_sfx("res://audio/sfx/ui_close.wav")
		selected_package_id = ""
		_refresh_package_list()
		_show_package_welcome()


func _add_script_to_package(pkg_id: String) -> void:
	# Show script selector
	_play_sfx("res://audio/sfx/ui_click.wav")

	if not package_detail_container:
		return

	for child in package_detail_container.get_children():
		child.queue_free()

	var title = Label.new()
	title.text = "Add Script to Package"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	package_detail_container.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	package_detail_container.add_child(scroll)

	var script_list = VBoxContainer.new()
	script_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	script_list.add_theme_constant_override("separation", 6)
	scroll.add_child(script_list)

	# Get all scripts not already in this package
	var pkg = ScriptManager.packages.get(pkg_id, {})
	var existing_scripts = pkg.get("scripts", [])
	var all_scripts = ScriptManager.get_all_scripts()

	for script in all_scripts:
		if script.id in existing_scripts:
			continue

		var btn = Button.new()
		btn.text = script.get("name", "Unnamed")
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(func():
			if ScriptManager.packages.has(pkg_id):
				ScriptManager.packages[pkg_id].scripts.append(script.id)
				# Update script's package_id
				if ScriptManager.scripts.has(script.id):
					ScriptManager.scripts[script.id].package_id = pkg_id
				SaveManager.save_game()
				_play_sfx("res://audio/sfx/select.wav")
				_show_package_details(pkg_id)
		)
		script_list.add_child(btn)

	if script_list.get_child_count() == 0:
		var empty = Label.new()
		empty.text = "No more scripts available to add."
		empty.add_theme_font_size_override("font_size", 14)
		empty.add_theme_color_override("font_color", MUTED_COLOR)
		script_list.add_child(empty)

	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(100, 40)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(func(): _show_package_details(pkg_id))
	package_detail_container.add_child(back_btn)


func _remove_script_from_package(pkg_id: String, script_id: String) -> void:
	if ScriptManager.packages.has(pkg_id):
		ScriptManager.packages[pkg_id].scripts.erase(script_id)
		if ScriptManager.scripts.has(script_id):
			ScriptManager.scripts[script_id].package_id = ""
		SaveManager.save_game()
		_play_sfx("res://audio/sfx/ui_close.wav")
		_show_package_details(pkg_id)


func _run_package(pkg_id: String) -> void:
	var pkg = ScriptManager.packages.get(pkg_id, {})
	var script_ids = pkg.get("scripts", [])

	if script_ids.is_empty():
		return

	_play_sfx("res://audio/sfx/select.wav")

	# Get all scripts
	var scripts_to_run: Array = []
	for sid in script_ids:
		var script = ScriptManager.get_script_by_id(sid)
		if not script.is_empty():
			scripts_to_run.append(script)

	# Emit signal for package execution
	ScriptManager.package_executed.emit(pkg, scripts_to_run)

	# Show confirmation
	_close_packages_panel()

	# TODO: Integrate with focus session to run scripts in sequence
	# For now just show a message
	var confirm_panel = PanelContainer.new()
	confirm_panel.name = "PackageRunConfirm"
	confirm_panel.set_anchors_preset(Control.PRESET_CENTER)
	confirm_panel.offset_left = -200
	confirm_panel.offset_right = 200
	confirm_panel.offset_top = -100
	confirm_panel.offset_bottom = 100
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.98)
	style.set_corner_radius_all(12)
	style.border_color = ACCENT_COLOR
	style.set_border_width_all(2)
	confirm_panel.add_theme_stylebox_override("panel", style)
	add_child(confirm_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	confirm_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var msg = Label.new()
	msg.text = "Package '%s' Queued!\n\n%d scripts ready to run.\nStart a focus session to execute them." % [pkg.get("name", ""), scripts_to_run.size()]
	msg.add_theme_font_size_override("font_size", 16)
	msg.add_theme_color_override("font_color", TEXT_COLOR)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)

	var ok_btn = Button.new()
	ok_btn.text = "OK"
	ok_btn.custom_minimum_size = Vector2(100, 40)
	ok_btn.add_theme_font_size_override("font_size", 16)
	ok_btn.pressed.connect(func(): confirm_panel.queue_free())
	vbox.add_child(ok_btn)


func _return_to_south() -> void:
	# Return to Southern Peaks
	GameManager.goto_scene("res://scenes/mindscape/mindscape_south.tscn")


func _play_sfx(path: String) -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx_from_path"):
		audio.play_sfx_from_path(path)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if welcome_overlay:
			_close_welcome_overlay()
		else:
			_return_to_south()
		get_viewport().set_input_as_handled()
