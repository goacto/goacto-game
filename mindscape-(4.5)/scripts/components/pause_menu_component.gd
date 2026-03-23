class_name PauseMenuComponent
extends Node
## PauseMenuComponent - Reusable pause menu for game scenes
## Provides resume, settings, and main menu options

# =============================================================================
# CONFIGURATION
# =============================================================================

const MENU_BG = Color(0.05, 0.06, 0.1, 0.95)
const MENU_PANEL = Color(0.1, 0.12, 0.18, 0.95)
const MENU_ACCENT = Color(0.4, 0.6, 0.9)

# =============================================================================
# STATE
# =============================================================================

var menu_panel: Control = null
var parent_scene: Control = null
var is_open: bool = false

var on_resume_callback: Callable = Callable()
var on_settings_callback: Callable = Callable()
var on_main_menu_callback: Callable = Callable()

# =============================================================================
# SIGNALS
# =============================================================================

signal menu_opened
signal menu_closed
signal resume_pressed
signal settings_pressed
signal main_menu_pressed

# =============================================================================
# PUBLIC API
# =============================================================================

func show(
	scene: Control,
	on_resume: Callable = Callable(),
	on_settings: Callable = Callable(),
	on_main_menu: Callable = Callable()
) -> void:
	if is_open:
		return

	parent_scene = scene
	on_resume_callback = on_resume
	on_settings_callback = on_settings
	on_main_menu_callback = on_main_menu
	is_open = true

	_create_menu()
	menu_opened.emit()


func close() -> void:
	if not is_open:
		return

	if menu_panel:
		var tween = parent_scene.create_tween()
		tween.tween_property(menu_panel, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func():
			menu_panel.queue_free()
			menu_panel = null
			is_open = false
			menu_closed.emit()
		)


func is_showing() -> bool:
	return is_open

# =============================================================================
# MENU CREATION
# =============================================================================

func _create_menu() -> void:
	# Full screen overlay
	menu_panel = Control.new()
	menu_panel.name = "PauseMenu"
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	parent_scene.add_child(menu_panel)

	# Dim background
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_panel.add_child(dim)

	# Center panel
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = MENU_PANEL
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = MENU_ACCENT.darkened(0.3)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(300, 280)
	panel.offset_left = -150
	panel.offset_right = 150
	panel.offset_top = -140
	panel.offset_bottom = 140
	menu_panel.add_child(panel)

	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	panel.add_child(margin)

	# VBox
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", MENU_ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	vbox.add_child(spacer)

	# Buttons
	_create_menu_button(vbox, "Resume", _on_resume)
	_create_menu_button(vbox, "Settings", _on_settings)
	_create_menu_button(vbox, "Main Menu", _on_main_menu, Color(0.6, 0.3, 0.3))

	# Fade in
	menu_panel.modulate.a = 0.0
	var tween = parent_scene.create_tween()
	tween.tween_property(menu_panel, "modulate:a", 1.0, 0.2)


func _create_menu_button(parent: VBoxContainer, text: String, callback: Callable, color: Color = MENU_ACCENT) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 45)
	btn.add_theme_font_size_override("font_size", 18)

	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.5)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = color.darkened(0.3)
	btn.add_theme_stylebox_override("hover", hover)

	btn.pressed.connect(callback)
	parent.add_child(btn)

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_resume() -> void:
	resume_pressed.emit()
	close()
	if on_resume_callback.is_valid():
		on_resume_callback.call()


func _on_settings() -> void:
	settings_pressed.emit()
	if on_settings_callback.is_valid():
		on_settings_callback.call()
	else:
		# Default: go to settings scene
		GameManager.goto_scene("res://scenes/settings/settings.tscn")


func _on_main_menu() -> void:
	main_menu_pressed.emit()
	if on_main_menu_callback.is_valid():
		on_main_menu_callback.call()
	else:
		# Default: go to main menu
		GameManager.goto_scene("res://scenes/main_menu/main_menu.tscn")

# =============================================================================
# INPUT HANDLING
# =============================================================================

func handle_input(event: InputEvent) -> bool:
	if not is_open:
		return false

	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_on_resume()
		return true

	return false
