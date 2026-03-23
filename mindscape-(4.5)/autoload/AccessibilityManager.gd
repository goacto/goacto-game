extends Node
## AccessibilityManager - Screen reader support and accessibility features
## Handles text-to-speech, focus announcements, and navigation assistance

# =============================================================================
# SETTINGS
# =============================================================================

var screen_reader_enabled: bool = false
var speak_ui_elements: bool = true
var speak_game_events: bool = true
var speech_rate: float = 1.0  # 0.5 to 2.0
var speech_pitch: float = 1.0  # 0.5 to 2.0

# TTS voice ID (platform-specific)
var tts_voice_id: String = ""

# Queue for announcements (to avoid overlapping)
var announcement_queue: Array[String] = []
var is_speaking: bool = false

# Last announced element (to avoid repetition)
var last_announcement: String = ""
var announcement_cooldown: float = 0.0

# =============================================================================
# SIGNALS
# =============================================================================

signal screen_reader_toggled(enabled: bool)
signal announcement_started(text: String)
signal announcement_finished


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Load settings
	_load_settings()

	# Check if TTS is available
	if DisplayServer.tts_is_speaking():
		pass  # TTS is available

	# Get available voices
	var voices = DisplayServer.tts_get_voices()
	if voices.size() > 0:
		# Prefer English voice
		for voice in voices:
			if "en" in voice.get("language", "").to_lower():
				tts_voice_id = voice.get("id", "")
				break
		if tts_voice_id == "" and voices.size() > 0:
			tts_voice_id = voices[0].get("id", "")

	print("[AccessibilityManager] Ready. TTS available: ", DisplayServer.tts_get_voices().size() > 0)


func _process(delta: float) -> void:
	# Update cooldown
	if announcement_cooldown > 0:
		announcement_cooldown -= delta

	# Process announcement queue
	if not is_speaking and announcement_queue.size() > 0:
		var next = announcement_queue.pop_front()
		_speak_internal(next)

	# Check if TTS finished
	if is_speaking and not DisplayServer.tts_is_speaking():
		is_speaking = false
		announcement_finished.emit()


# =============================================================================
# PUBLIC API
# =============================================================================

## Enable or disable screen reader
func set_screen_reader_enabled(enabled: bool) -> void:
	screen_reader_enabled = enabled
	screen_reader_toggled.emit(enabled)

	if enabled:
		announce("Screen reader enabled")
	else:
		stop_speaking()

	_save_settings()


## Announce text immediately (interrupts current speech)
func announce(text: String, interrupt: bool = true) -> void:
	if not screen_reader_enabled:
		return

	if text == null or text.is_empty():
		return

	# Avoid repeating same announcement too quickly
	if text == last_announcement and announcement_cooldown > 0:
		return

	last_announcement = text
	announcement_cooldown = 0.5

	if interrupt:
		stop_speaking()
		announcement_queue.clear()
		_speak_internal(text)
	else:
		announcement_queue.append(text)


## Queue an announcement (doesn't interrupt)
func queue_announcement(text: String) -> void:
	announce(text, false)


## Announce a UI element when focused
func announce_focus(element_name: String, element_type: String = "", hint: String = "") -> void:
	if not screen_reader_enabled or not speak_ui_elements:
		return

	var announcement = element_name

	if element_type != "":
		announcement += ", " + element_type

	if hint != "":
		announcement += ". " + hint

	announce(announcement)


## Announce a game event
func announce_event(event_text: String) -> void:
	if not screen_reader_enabled or not speak_game_events:
		return

	announce(event_text, false)


## Announce button information
func announce_button(button: Button) -> void:
	if not screen_reader_enabled:
		return

	var text = button.text if button.text != "" else "Button"
	var hint = ""

	if button.disabled:
		hint = "Disabled"
	elif button.tooltip_text != "":
		hint = button.tooltip_text

	announce_focus(text, "button", hint)


## Announce slider value
func announce_slider(slider: Slider, label: String = "") -> void:
	if not screen_reader_enabled:
		return

	var value_text = "%d percent" % int(slider.value) if slider.max_value == 100 else str(int(slider.value))
	var name = label if label != "" else "Slider"

	announce(name + ", " + value_text)


## Announce checkbox state
func announce_checkbox(checkbox: CheckBox, label: String = "") -> void:
	if not screen_reader_enabled:
		return

	var name = label if label != "" else checkbox.text if checkbox.text != "" else "Checkbox"
	var state = "checked" if checkbox.button_pressed else "not checked"

	announce(name + ", " + state)


## Announce toggle button state
func announce_toggle(toggle: CheckButton, label: String = "") -> void:
	if not screen_reader_enabled:
		return

	var name = label if label != "" else toggle.text if toggle.text != "" else "Toggle"
	var state = "on" if toggle.button_pressed else "off"

	announce(name + ", " + state)


## Announce a scene change
func announce_scene(scene_name: String) -> void:
	if not screen_reader_enabled:
		return

	announce(scene_name + " loaded", true)


## Announce dialog content
func announce_dialog(title: String, content: String) -> void:
	if not screen_reader_enabled:
		return

	var announcement = title + ". " + content
	announce(announcement)


## Stop all speech
func stop_speaking() -> void:
	DisplayServer.tts_stop()
	is_speaking = false
	announcement_queue.clear()


## Get available TTS voices
func get_voices() -> Array:
	return DisplayServer.tts_get_voices()


## Set speech rate (0.5 to 2.0)
func set_speech_rate(rate: float) -> void:
	speech_rate = clamp(rate, 0.5, 2.0)
	_save_settings()


## Set speech pitch (0.5 to 2.0)
func set_speech_pitch(pitch: float) -> void:
	speech_pitch = clamp(pitch, 0.5, 2.0)
	_save_settings()


# =============================================================================
# ACCESSIBILITY HELPERS
# =============================================================================

## Get accessibility description for an interactive object
func get_object_description(object_name: String, object_data: Dictionary) -> String:
	var desc = object_name

	if object_data.has("accessibility_hint"):
		desc += ". " + object_data["accessibility_hint"]
	elif object_data.has("prompt"):
		desc += ". " + object_data["prompt"]

	return desc


## Announce nearby interactive object
func announce_nearby_object(object_name: String, object_data: Dictionary) -> void:
	if not screen_reader_enabled:
		return

	var desc = get_object_description(object_name, object_data)
	announce(desc)


## Announce player position/context
func announce_location(location_name: String, context: String = "") -> void:
	if not screen_reader_enabled:
		return

	var announcement = "You are in " + location_name
	if context != "":
		announcement += ". " + context

	announce(announcement)


## Announce habit completion
func announce_habit_complete(habit_name: String, streak: int) -> void:
	if not screen_reader_enabled:
		return

	var announcement = habit_name + " completed"
	if streak > 1:
		announcement += ". " + str(streak) + " day streak"

	announce_event(announcement)


## Announce XP gain
func announce_xp(aspect: String, amount: int) -> void:
	if not screen_reader_enabled:
		return

	announce_event("Plus " + str(amount) + " " + aspect + " XP")


## Announce achievement
func announce_achievement(achievement_name: String) -> void:
	if not screen_reader_enabled:
		return

	announce("Achievement unlocked: " + achievement_name)


## Announce focus session
func announce_focus_session(topic: String, minutes: int, state: String) -> void:
	if not screen_reader_enabled:
		return

	match state:
		"start":
			announce("Focus session started. " + str(minutes) + " minutes on " + topic)
		"end":
			announce("Focus session complete. " + str(minutes) + " minutes on " + topic)
		"tick":
			if minutes % 5 == 0:
				announce_event(str(minutes) + " minutes remaining")


# =============================================================================
# INTERNAL
# =============================================================================

func _speak_internal(text: String) -> void:
	if text == null or text.is_empty():
		return

	is_speaking = true
	announcement_started.emit(text)

	# Use Godot's built-in TTS
	DisplayServer.tts_speak(text, tts_voice_id, 50, speech_pitch, speech_rate)


func _save_settings() -> void:
	var settings = {
		"screen_reader_enabled": screen_reader_enabled,
		"speak_ui_elements": speak_ui_elements,
		"speak_game_events": speak_game_events,
		"speech_rate": speech_rate,
		"speech_pitch": speech_pitch
	}

	# Save to game settings
	GameManager.player_data["accessibility_tts"] = settings
	SaveManager.save_game()


func _load_settings() -> void:
	var settings = GameManager.player_data.get("accessibility_tts", {})

	screen_reader_enabled = settings.get("screen_reader_enabled", false)
	speak_ui_elements = settings.get("speak_ui_elements", true)
	speak_game_events = settings.get("speak_game_events", true)
	speech_rate = settings.get("speech_rate", 1.0)
	speech_pitch = settings.get("speech_pitch", 1.0)


# =============================================================================
# KEYBOARD NAVIGATION HELPERS
# =============================================================================

## Setup keyboard focus for a container of buttons
func setup_button_navigation(container: Control, buttons: Array[Button]) -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]

		# Set focus neighbors
		if i > 0:
			btn.focus_neighbor_top = buttons[i - 1].get_path()
		if i < buttons.size() - 1:
			btn.focus_neighbor_bottom = buttons[i + 1].get_path()

		# Connect focus signals for screen reader
		btn.focus_entered.connect(func(): announce_button(btn))


## Make a control focusable and announce on focus
func make_focusable(control: Control, description: String, control_type: String = "") -> void:
	control.focus_mode = Control.FOCUS_ALL
	control.focus_entered.connect(func(): announce_focus(description, control_type))


## Announce current focus for debugging
func debug_focus() -> void:
	var focused = get_viewport().gui_get_focus_owner()
	if focused:
		print("[Accessibility] Focused: ", focused.name, " (", focused.get_class(), ")")
	else:
		print("[Accessibility] No focus")
