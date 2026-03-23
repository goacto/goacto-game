class_name DialogueComponent
extends Node
## DialogueComponent - Reusable dialogue box for scenes
## Handles text display, typewriter effect, callbacks, and voice

# =============================================================================
# CONFIGURATION
# =============================================================================

const DEFAULT_BG_COLOR = Color(0.08, 0.1, 0.15, 0.95)
const DEFAULT_BORDER_COLOR = Color(0.3, 0.35, 0.5, 0.5)
const DEFAULT_TITLE_COLOR = Color(0.9, 0.85, 0.7)
const DEFAULT_TEXT_COLOR = Color(0.85, 0.88, 0.92)

# =============================================================================
# STATE
# =============================================================================

var dialogue_panel: Control = null
var dialogue_title: Label = null
var dialogue_text: Label = null
var dialogue_button: Button = null

var typing_tween: Tween = null
var dialogue_full_text: String = ""
var dialogue_callback: Callable = Callable()

var parent_scene: Control = null
var is_open: bool = false

# Auto-play support
var auto_play_enabled: bool = false
var auto_play_delay: float = 1.5
var auto_play_timer: Timer = null

# =============================================================================
# SIGNALS
# =============================================================================

signal dialogue_opened
signal dialogue_closed
signal typing_completed

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	_load_auto_play_settings()


func _load_auto_play_settings() -> void:
	var save_manager = Engine.get_singleton("SaveManager") if Engine.has_singleton("SaveManager") else null
	if not save_manager:
		# Try to get from autoload
		save_manager = Engine.get_main_loop().root.get_node_or_null("/root/SaveManager") if Engine.get_main_loop() else null

	if save_manager and save_manager.has_method("load_settings"):
		var settings = save_manager.load_settings()
		auto_play_enabled = settings.get("auto_play_cutscenes", false)
		auto_play_delay = settings.get("auto_play_delay", 1.5)


func _setup_auto_play_timer() -> void:
	if auto_play_timer:
		return  # Already set up

	auto_play_timer = Timer.new()
	auto_play_timer.one_shot = true
	auto_play_timer.timeout.connect(_on_auto_play_timeout)
	add_child(auto_play_timer)


func _on_auto_play_timeout() -> void:
	if is_open and not is_typing():
		close()


# =============================================================================
# PUBLIC API
# =============================================================================

## Show a dialogue box
func show_dialogue(
	scene: Control,
	title: String,
	text: String,
	callback: Callable = Callable(),
	voice_path: String = "",
	button_text: String = "Continue"
) -> void:
	if is_open:
		close()

	parent_scene = scene
	dialogue_callback = callback
	dialogue_full_text = text
	is_open = true

	# Re-check auto-play settings in case they changed
	_load_auto_play_settings()
	_setup_auto_play_timer()

	_create_dialogue_panel(title, text, button_text)
	dialogue_opened.emit()

	# Play voice if provided
	if voice_path != "":
		var audio = scene.get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_voice_from_path"):
			audio.play_voice_from_path(voice_path)


## Close the dialogue
func close() -> void:
	if not is_open:
		return

	_stop_typing()
	_stop_voice()
	_stop_auto_play()


func _stop_auto_play() -> void:
	if auto_play_timer and not auto_play_timer.is_stopped():
		auto_play_timer.stop()

	if dialogue_panel:
		var tween = parent_scene.create_tween()
		tween.tween_property(dialogue_panel, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func():
			dialogue_panel.queue_free()
			dialogue_panel = null
			dialogue_title = null
			dialogue_text = null
			dialogue_button = null
			is_open = false
			dialogue_closed.emit()
			if dialogue_callback.is_valid():
				dialogue_callback.call()
		)


## Close without callback (for skipping)
func close_no_callback() -> void:
	var saved_callback = dialogue_callback
	dialogue_callback = Callable()
	close()


## Skip typing animation and show full text
func skip_typing() -> void:
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
		typing_tween = null
	if dialogue_text:
		dialogue_text.visible_ratio = 1.0
		_on_typing_finished()


## Check if currently showing dialogue
func is_showing() -> bool:
	return is_open


## Check if typing animation is in progress
func is_typing() -> bool:
	return dialogue_text != null and dialogue_text.visible_ratio < 1.0

# =============================================================================
# DIALOGUE CREATION
# =============================================================================

func _create_dialogue_panel(title: String, text: String, button_text: String) -> void:
	# Create panel
	dialogue_panel = PanelContainer.new()
	dialogue_panel.name = "DialoguePanel"

	var style = StyleBoxFlat.new()
	style.bg_color = DEFAULT_BG_COLOR
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = DEFAULT_BORDER_COLOR
	dialogue_panel.add_theme_stylebox_override("panel", style)

	dialogue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_panel.custom_minimum_size = Vector2(700, 180)
	dialogue_panel.offset_top = -220
	dialogue_panel.offset_bottom = -40
	dialogue_panel.offset_left = -350
	dialogue_panel.offset_right = 350
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	parent_scene.add_child(dialogue_panel)

	# Margin container
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	dialogue_panel.add_child(margin)

	# VBox for content
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title
	dialogue_title = Label.new()
	dialogue_title.text = title
	dialogue_title.add_theme_font_size_override("font_size", 22)
	dialogue_title.add_theme_color_override("font_color", DEFAULT_TITLE_COLOR)
	vbox.add_child(dialogue_title)

	# Text with typewriter effect
	dialogue_text = Label.new()
	dialogue_text.text = text
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.add_theme_font_size_override("font_size", 16)
	dialogue_text.add_theme_color_override("font_color", DEFAULT_TEXT_COLOR)
	dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_text.visible_ratio = 0.0
	vbox.add_child(dialogue_text)

	# Button
	dialogue_button = Button.new()
	dialogue_button.text = button_text
	dialogue_button.custom_minimum_size = Vector2(120, 40)
	dialogue_button.add_theme_font_size_override("font_size", 16)
	dialogue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	dialogue_button.pressed.connect(_on_button_pressed)
	vbox.add_child(dialogue_button)

	# Start typewriter effect
	_start_typing(text)

	# Fade in
	dialogue_panel.modulate.a = 0.0
	var tween = parent_scene.create_tween()
	tween.tween_property(dialogue_panel, "modulate:a", 1.0, 0.2)


func _start_typing(text: String) -> void:
	var char_count = text.length()
	var duration = min(char_count * 0.03, 3.0)  # 30ms per char, max 3 seconds

	typing_tween = parent_scene.create_tween()
	typing_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)
	typing_tween.tween_callback(_on_typing_finished)


func _on_typing_finished() -> void:
	typing_completed.emit()
	# Start auto-play timer if enabled
	if auto_play_enabled and auto_play_timer:
		auto_play_timer.start(auto_play_delay)
		# Update button text to show auto-advance
		if dialogue_button:
			dialogue_button.text = "Auto... (%.0fs)" % auto_play_delay


func _stop_typing() -> void:
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
		typing_tween = null


func _stop_voice() -> void:
	var audio = parent_scene.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()


func _on_button_pressed() -> void:
	# Cancel any auto-play
	_stop_auto_play()

	# If still typing, skip to end
	if is_typing():
		skip_typing()
		return

	# Otherwise close
	close()

# =============================================================================
# INPUT HANDLING (optional - scene can call these)
# =============================================================================

## Handle input for dialogue (call from scene's _input)
func handle_input(event: InputEvent) -> bool:
	if not is_open:
		return false

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		# Cancel any auto-play
		_stop_auto_play()
		if is_typing():
			skip_typing()
		else:
			close()
		return true

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Cancel any auto-play
		_stop_auto_play()
		if is_typing():
			skip_typing()
		return true

	return false
