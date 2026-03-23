class_name UIBuilder
## UIBuilder - Reusable UI construction utilities
## Reduces code duplication across scene scripts

# =============================================================================
# PANEL CREATION
# =============================================================================

## Create a styled panel container
static func create_panel(size: Vector2, color: Color = Color(0.1, 0.12, 0.18, 0.95)) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = size

	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.35, 0.5, 0.5)
	panel.add_theme_stylebox_override("panel", style)

	return panel


## Create a fullscreen overlay panel
static func create_fullscreen_panel(bg_color: Color = Color(0.05, 0.05, 0.1, 0.95)) -> Control:
	var panel = Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = bg_color
	panel.add_child(bg)

	return panel


## Create a centered panel with margin
static func create_centered_panel(size: Vector2, margin: int = 40) -> PanelContainer:
	var panel = create_panel(size)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -size.x / 2
	panel.offset_right = size.x / 2
	panel.offset_top = -size.y / 2
	panel.offset_bottom = size.y / 2
	return panel


# =============================================================================
# BUTTON CREATION
# =============================================================================

## Create a styled button
static func create_button(text: String, size: Vector2 = Vector2(120, 40), color: Color = Color(0.2, 0.3, 0.5)) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = size
	btn.add_theme_font_size_override("font_size", 16)

	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)

	return btn


## Create a close button (X)
static func create_close_button(size: int = 32) -> Button:
	var btn = Button.new()
	btn.text = "X"
	btn.custom_minimum_size = Vector2(size, size)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.15, 0.15, 0.8)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = Color(0.5, 0.2, 0.2)
	btn.add_theme_stylebox_override("hover", hover)

	return btn


## Create an icon button
static func create_icon_button(icon_text: String, size: int = 40, color: Color = Color(0.2, 0.25, 0.35)) -> Button:
	var btn = Button.new()
	btn.text = icon_text
	btn.custom_minimum_size = Vector2(size, size)
	btn.add_theme_font_size_override("font_size", 20)

	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = size / 2
	style.corner_radius_top_right = size / 2
	style.corner_radius_bottom_left = size / 2
	style.corner_radius_bottom_right = size / 2
	btn.add_theme_stylebox_override("normal", style)

	return btn


# =============================================================================
# LABEL CREATION
# =============================================================================

## Create a styled label
static func create_label(text: String, font_size: int = 16, color: Color = Color.WHITE) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Create a header label
static func create_header(text: String, font_size: int = 24, color: Color = Color(0.9, 0.85, 0.7)) -> Label:
	var label = create_label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


## Create a section header with separator
static func create_section_header(text: String, color: Color = Color(0.7, 0.75, 0.9)) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	var label = create_label(text, 14, color)
	label.add_theme_font_size_override("font_size", 14)
	container.add_child(label)

	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	container.add_child(sep)

	return container


# =============================================================================
# CONTAINER CREATION
# =============================================================================

## Create a VBox with margin
static func create_vbox(separation: int = 10, margin: int = 20) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", separation)

	if margin > 0:
		var margin_container = MarginContainer.new()
		margin_container.add_theme_constant_override("margin_left", margin)
		margin_container.add_theme_constant_override("margin_right", margin)
		margin_container.add_theme_constant_override("margin_top", margin)
		margin_container.add_theme_constant_override("margin_bottom", margin)
		margin_container.add_child(vbox)

	return vbox


## Create a scroll container with content
static func create_scroll_container(min_size: Vector2 = Vector2(400, 300)) -> ScrollContainer:
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = min_size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return scroll


## Create a grid container
static func create_grid(columns: int = 2, h_separation: int = 10, v_separation: int = 10) -> GridContainer:
	var grid = GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", h_separation)
	grid.add_theme_constant_override("v_separation", v_separation)
	return grid


## Create an HBox container
static func create_hbox(separation: int = 10) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", separation)
	return hbox


# =============================================================================
# STAT/INFO DISPLAYS
# =============================================================================

## Create a stat row (icon + label + value)
static func create_stat_row(icon: String, label_text: String, value_text: String, icon_color: Color = Color.WHITE) -> HBoxContainer:
	var row = create_hbox(8)

	# Icon
	var icon_label = create_label(icon, 16, icon_color)
	icon_label.custom_minimum_size = Vector2(24, 0)
	row.add_child(icon_label)

	# Label
	var label = create_label(label_text, 14, Color(0.7, 0.7, 0.8))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	# Value
	var value = create_label(value_text, 14, Color.WHITE)
	row.add_child(value)

	return row


## Create a compact stat (icon + value stacked)
static func create_compact_stat(icon: String, value: String, icon_color: Color = Color.WHITE) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var icon_label = create_label(icon, 20, icon_color)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(icon_label)

	var value_label = create_label(value, 12, Color.WHITE)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(value_label)

	return container


## Create a progress bar
static func create_progress_bar(value: float, max_value: float, size: Vector2 = Vector2(200, 20), color: Color = Color(0.3, 0.6, 0.9)) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.custom_minimum_size = size
	bar.max_value = max_value
	bar.value = value
	bar.show_percentage = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", style)

	var fill = style.duplicate()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)

	return bar


# =============================================================================
# INPUT FIELDS
# =============================================================================

## Create a styled text input
static func create_text_input(placeholder: String = "", size: Vector2 = Vector2(200, 35)) -> LineEdit:
	var input = LineEdit.new()
	input.placeholder_text = placeholder
	input.custom_minimum_size = size
	input.add_theme_font_size_override("font_size", 14)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.35, 0.5)
	input.add_theme_stylebox_override("normal", style)

	return input


## Create a styled text area
static func create_text_area(placeholder: String = "", size: Vector2 = Vector2(300, 100)) -> TextEdit:
	var text_edit = TextEdit.new()
	text_edit.placeholder_text = placeholder
	text_edit.custom_minimum_size = size
	text_edit.add_theme_font_size_override("font_size", 14)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	text_edit.add_theme_stylebox_override("normal", style)

	return text_edit


# =============================================================================
# CARDS & ITEMS
# =============================================================================

## Create a card container for items
static func create_card(size: Vector2 = Vector2(150, 100), color: Color = Color(0.15, 0.18, 0.25)) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = size

	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.3, 0.4, 0.5)
	card.add_theme_stylebox_override("panel", style)

	return card


## Create a tab bar
static func create_tab_bar(tabs: Array, selected: int = 0) -> HBoxContainer:
	var container = create_hbox(0)

	for i in range(tabs.size()):
		var btn = create_button(tabs[i], Vector2(100, 35))
		btn.name = "Tab_" + str(i)

		if i == selected:
			btn.add_theme_stylebox_override("normal", _create_selected_tab_style())

		container.add_child(btn)

	return container


static func _create_selected_tab_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.35, 0.55)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	return style


# =============================================================================
# UTILITY
# =============================================================================

## Add fade-in animation to a control
static func fade_in(control: Control, duration: float = 0.3) -> Tween:
	control.modulate.a = 0.0
	var tween = control.create_tween()
	tween.tween_property(control, "modulate:a", 1.0, duration)
	return tween


## Add fade-out animation and queue_free
static func fade_out_and_free(control: Control, duration: float = 0.2) -> void:
	var tween = control.create_tween()
	tween.tween_property(control, "modulate:a", 0.0, duration)
	tween.tween_callback(control.queue_free)


## Create a tooltip popup
static func create_tooltip(text: String, position: Vector2) -> Control:
	var tooltip = PanelContainer.new()
	tooltip.position = position

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	tooltip.add_theme_stylebox_override("panel", style)

	var label = create_label(text, 12, Color(0.9, 0.9, 0.9))
	tooltip.add_child(label)

	return tooltip
