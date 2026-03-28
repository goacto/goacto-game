extends Control
## Kitchen - Family dining area on the Stellar Wanderer
## Part of intro flow: Kitchen -> Hallway -> Stairs -> Bedroom

# World elements
@onready var game_world: Control = $GameWorld
@onready var isometric_base: Node2D = $GameWorld/IsometricBase
@onready var player: Node2D = $GameWorld/IsometricBase/Player
@onready var mom_character: Node2D = $GameWorld/IsometricBase/Mom

# UI
@onready var interaction_prompt: PanelContainer = $InteractionPrompt
@onready var object_name_label: Label = $InteractionPrompt/Margin/VBox/ObjectName
@onready var prompt_text_label: Label = $InteractionPrompt/Margin/VBox/PromptText
@onready var control_hints: HBoxContainer = $ControlHints

# Dialogue
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var dialogue_title: Label = $DialoguePanel/Margin/VBox/DialogueTitle
@onready var dialogue_text: Label = $DialoguePanel/Margin/VBox/DialogueText
@onready var dialogue_button: Button = $DialoguePanel/Margin/VBox/DialogueButton

# Menu
@onready var menu_button: Button = $Header/Margin/HBox/MenuButton

# Header controls
var volume_button: Button = null
var save_indicator: Label = null
var volume_popup: PanelContainer = null
var is_muted: bool = false

# Fade transition
@onready var fade_overlay: ColorRect = $FadeOverlay

# Animated elements
@onready var stars_container: Node2D = $GameWorld/IsometricBase/Window/Stars
@onready var food_screen: Polygon2D = $GameWorld/IsometricBase/FoodUnit/Screen
@onready var food_screen_glow: Polygon2D = $GameWorld/IsometricBase/FoodUnit/ScreenGlow
@onready var window_light: Polygon2D = $GameWorld/IsometricBase/WindowLight

# Player movement
var player_speed: float = 250.0
var player_bounds: Rect2 = Rect2(-520, -250, 1040, 520)

# Camera
var camera_zoom: float = 1.0
var min_zoom: float = 0.6
var max_zoom: float = 1.5
var zoom_speed: float = 0.08

# Interaction state
var nearby_object: String = ""
var in_dialogue: bool = false
var dialogue_callback: Callable

# Typing effect
var typing_tween: Tween = null
var dialogue_full_text: String = ""
var voice_finished: bool = false
var has_voice: bool = false

# Animation
var animation_time: float = 0.0

# Movement sound
var move_sound_timer: float = 0.0
var move_sound_interval: float = 0.35  # Time between hover sounds
var is_moving: bool = false

# Interactive objects in kitchen
const INTERACTIVE_OBJECTS = {
	"Door": {
		"name": "Hallway Door",
		"prompt": "Press SPACE to enter hallway",
		"action": "go_hallway"
	},
	"BalconyDoor": {
		"name": "Viewing Balcony",
		"prompt": "Press SPACE to enter balcony",
		"action": "go_balcony"
	},
	"Mom": {
		"name": "Dr. Lumina (Mom)",
		"prompt": "Press SPACE to talk",
		"action": "talk_mom"
	},
	"Table": {
		"name": "Dining Table",
		"prompt": "Press SPACE to examine",
		"action": "examine_table"
	},
	"Window": {
		"name": "Viewport Window",
		"prompt": "Press SPACE to look outside",
		"action": "look_window"
	},
	"FoodUnit": {
		"name": "Food Synthesizer",
		"prompt": "Press SPACE to examine",
		"action": "examine_food"
	},
	"MasterKey": {
		"name": "Mysterious Key",
		"prompt": "Press SPACE to pick up",
		"action": "pickup_master_key"
	}
}

# Object positions for proximity detection
var object_positions: Dictionary = {
	"Door": Vector2(450, 0),
	"BalconyDoor": Vector2(-450, 0),
	"Mom": Vector2(-150, 80),
	"Table": Vector2(0, 130),
	"Window": Vector2(-380, -130),
	"FoodUnit": Vector2(260, -150),
	"MasterKey": Vector2(280, -70)
}

# Reference to key visual (set in _ready)
var master_key_visual: Node2D = null

# Background sprite reference
@onready var background_sprite: Sprite2D = $GameWorld/IsometricBase/BackgroundSprite

# Environment polygon elements (hidden when using sprite background)
const ENVIRONMENT_NODES = [
	"Floor", "FloorPattern", "WindowLight", "Rug", "BackWall", "WallTrim",
	"Window", "Table", "FoodUnit", "Counter", "Door"
]


func _ready() -> void:
	# Try to load AI-generated background
	_try_load_background()

	# Connect dialogue button
	dialogue_button.pressed.connect(_close_dialogue)

	# Connect menu button
	menu_button.pressed.connect(_open_pause_menu)

	# Setup header controls (volume, save indicator)
	_setup_header_controls()

	# Play ship music and ambient sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		if audio.has_method("play_music_ship"):
			audio.play_music_ship()
		if audio.has_method("play_ambient_ship"):
			audio.play_ambient_ship()

	# Hide UI initially
	interaction_prompt.visible = false
	dialogue_panel.visible = false

	# Setup master key visual
	master_key_visual = $GameWorld/IsometricBase.get_node_or_null("MasterKey")
	if master_key_visual:
		# Hide key if already picked up
		if GameManager.has_master_key():
			master_key_visual.visible = false
			object_positions.erase("MasterKey")

	# Center the view
	_update_camera()

	# Fade in from black
	_fade_in()

	# Show intro hint after fade completes (only for first visit)
	await get_tree().create_timer(0.6).timeout
	# Dr. Lumina's intro greeting - only plays once automatically
	if not CampaignManager.has_seen_cutscene("intro_part2") and not GameManager.player_data.get("kitchen_intro_shown", false):
		GameManager.player_data["kitchen_intro_shown"] = true
		if not GameManager.has_item("mindscape_console"):
			_show_dialogue("Dr. Lumina", "Your great-elder Zyx's Mindscape Console should be somewhere on the ship...\n\n*taps chin thoughtfully*\n\nExplore around - your father stored a lot of their old things when we moved aboard.", Callable(), "res://audio/voice/kitchen/lumina_go_find.ogg")
		else:
			_show_dialogue("Dr. Lumina", "You found Zyx's console! Now go set it up in your room.\n\n*gestures toward the door*\n\nI can't wait to hear about your first human!", Callable(), "res://audio/voice/kitchen/lumina_intro.ogg")
		SaveManager.save_game()
	# Otherwise, player can interact with Mom manually

	print("[Kitchen] Family dining area ready")


func _fade_in() -> void:
	if fade_overlay:
		var tween = create_tween()
		tween.tween_property(fade_overlay, "color:a", 0.0, 0.5).set_ease(Tween.EASE_OUT)


func _try_load_background() -> void:
	# Check if AI-generated background exists
	var bg_path = "res://assets/backgrounds/kitchen_bg.png"
	if not ResourceLoader.exists(bg_path):
		print("[Kitchen] Using polygon graphics (no background image at: ", bg_path, ")")
		return

	# Load and apply background
	var texture = load(bg_path) as Texture2D
	if not texture:
		return

	if background_sprite:
		background_sprite.texture = texture
		background_sprite.visible = true

		# Hide polygon environment elements
		for node_name in ENVIRONMENT_NODES:
			var node = isometric_base.get_node_or_null(node_name)
			if node:
				node.visible = false

		print("[Kitchen] Using AI-generated background")


func _process(delta: float) -> void:
	animation_time += delta

	# Animate mom character
	_animate_characters(delta)

	# Animate space view if visible (must be before in_dialogue check)
	if space_view_panel and space_view_panel.visible:
		_update_space_view(delta)

	if in_dialogue:
		return

	# Check object proximity
	_check_object_proximity()

	# Handle movement
	_handle_movement(delta)

	# Update camera
	_update_camera()


func _input(event: InputEvent) -> void:
	var viewport = get_viewport()
	if viewport == null:
		return

	# ESC to close panels or open pause menu
	if event.is_action_pressed("ui_cancel"):
		if volume_popup:
			_close_volume_popup()
			viewport.set_input_as_handled()
			return
		if pause_menu:
			_close_pause_menu()
			viewport.set_input_as_handled()
			return
		if space_view_panel and space_view_panel.visible:
			_close_space_view()
			viewport.set_input_as_handled()
			return
		if dialogue_panel.visible:
			_close_dialogue()
			viewport.set_input_as_handled()
			return
		# If nothing is open, open pause menu
		_open_pause_menu()
		viewport.set_input_as_handled()
		return

	# Block inputs when pause menu is open
	if pause_menu:
		return

	# Close space view with SPACE
	if space_view_panel and space_view_panel.visible:
		if event.is_action_pressed("ui_accept"):
			_close_space_view()
			viewport.set_input_as_handled()
		return

	if in_dialogue:
		if event.is_action_pressed("ui_accept"):
			# If still typing, skip to end first
			if dialogue_text.visible_ratio < 1.0:
				_skip_typing()
			else:
				_close_dialogue()
			viewport.set_input_as_handled()
		return

	# Interact with nearby object
	if event.is_action_pressed("ui_accept") and nearby_object != "":
		_interact_with_object(nearby_object)
		viewport.set_input_as_handled()

	# Touch/click interaction
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if nearby_object != "" and interaction_prompt.visible:
			_interact_with_object(nearby_object)

	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(zoom_speed)
			viewport.set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(-zoom_speed)
			viewport.set_input_as_handled()


func _handle_movement(delta: float) -> void:
	var input_dir = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()

		# Cardinal movement (W=up, S=down, A=left, D=right)
		var new_pos = player.position + input_dir * player_speed * delta

		# Clamp to room bounds
		new_pos.x = clamp(new_pos.x, player_bounds.position.x, player_bounds.position.x + player_bounds.size.x)
		new_pos.y = clamp(new_pos.y, player_bounds.position.y, player_bounds.position.y + player_bounds.size.y)

		player.position = new_pos

		# Play movement sound
		is_moving = true
		move_sound_timer += delta
		if move_sound_timer >= move_sound_interval:
			move_sound_timer = 0.0
			_play_sfx("res://audio/sfx/hover_move.wav", -12.0)
	else:
		is_moving = false
		move_sound_timer = 0.0


func _update_camera() -> void:
	if not game_world or not isometric_base or not player:
		return

	var screen_center = game_world.size / 2
	var target_pos = screen_center - (player.position * camera_zoom)
	isometric_base.position = target_pos
	isometric_base.scale = Vector2(camera_zoom, camera_zoom)


func _apply_zoom(amount: float) -> void:
	camera_zoom = clamp(camera_zoom + amount, min_zoom, max_zoom)
	_update_camera()


func _check_object_proximity() -> void:
	var closest_object: String = ""
	var closest_distance: float = 100.0  # Interaction radius

	for object_name in object_positions:
		var obj_pos = object_positions[object_name]
		var distance = player.position.distance_to(obj_pos)

		if distance < closest_distance:
			closest_distance = distance
			closest_object = object_name

	if closest_object != nearby_object:
		nearby_object = closest_object
		if nearby_object != "":
			_show_interaction_prompt(nearby_object)
		else:
			_hide_interaction_prompt()


func _show_interaction_prompt(object_id: String) -> void:
	var obj_data = INTERACTIVE_OBJECTS.get(object_id, {})
	if obj_data.is_empty():
		return

	object_name_label.text = obj_data.get("name", object_id)
	prompt_text_label.text = obj_data.get("prompt", "Press SPACE to interact")

	interaction_prompt.visible = true
	control_hints.visible = false


func _hide_interaction_prompt() -> void:
	interaction_prompt.visible = false
	control_hints.visible = true


func _interact_with_object(object_id: String) -> void:
	var obj_data = INTERACTIVE_OBJECTS.get(object_id, {})
	var action = obj_data.get("action", "")

	match action:
		"go_hallway":
			_confirm_go_hallway()
		"go_balcony":
			_confirm_go_balcony()
		"talk_mom":
			_talk_to_mom()
		"examine_table":
			_show_dialogue("Dining Table", "A sleek oval table where the family shares meals.\n\nEmpty nutrient containers from breakfast still linger.\n\nMom always says the best conversations happen here.")
		"look_window":
			_show_space_view()
		"examine_food":
			_show_dialogue("Food Synthesizer", "\"NutriMatic 5000\" - Synthesizes any meal from the Goactorian home world.\n\nCurrently set to: Morning Energy Blend\n\nYou're not hungry right now. You have a human to meet!", Callable(), "res://audio/voice/kitchen/goacto_food_synth.ogg")
		"pickup_master_key":
			_pickup_master_key()


func _talk_to_mom() -> void:
	# Different dialogue based on player progress
	var has_used_mindscape = CampaignManager.has_seen_cutscene("intro_part2")
	var total_focus_sessions = HabitManager.get_total_focus_sessions()
	var has_discipline = CampaignManager.has_seen_cutscene("discipline_awakens")
	var has_console = GameManager.has_item("mindscape_console")
	var needs_placement = GameManager.player_data.get("needs_console_placement", false)

	if not has_used_mindscape:
		if not has_console:
			# Hasn't found the console yet
			var idx = randi() % 3
			var responses = [
				"Still looking for Great-Elder Zyx's console?\n\nTry the cargo hold - there's an old storage room in the back. Your father stored a lot of family heirlooms there.\n\n*smiles warmly*",
				"The Mindscape Console... it meant so much to your great-elder.\n\nCheck the cargo hold's old storage room. That's where we put most of Zyx's belongings.\n\n*looks nostalgic*",
				"Haven't found it yet? Don't worry, it's somewhere on the ship.\n\nThe cargo hold has an old storage area - try looking there!\n\n*pats your shoulder*",
			]
			var voices = [
				"res://audio/voice/kitchen/lumina_find_cargo_0.ogg",
				"res://audio/voice/kitchen/lumina_find_cargo_1.ogg",
				"res://audio/voice/kitchen/lumina_find_cargo_2.ogg",
			]
			_show_dialogue("Dr. Lumina", responses[idx], Callable(), voices[idx])
		elif needs_placement:
			# Has console but needs to place it
			_show_dialogue("Dr. Lumina", "You found Zyx's console! Wonderful!\n\nNow go set it up in your room - down the hallway and up the stairs.\n\n*beams with pride*\n\nYour great-elder would be so proud.", Callable(), "res://audio/voice/kitchen/lumina_place_console.ogg")
		else:
			# Console placed, hasn't used it yet
			_show_dialogue("Dr. Lumina", "What are you waiting for? Go find your human!\n\nThe console is ready in your room - down the hallway and up the stairs.\n\n*smiles encouragingly*", Callable(), "res://audio/voice/kitchen/lumina_go_find.ogg")
	elif has_discipline:
		# Has met Discipline - deep into the journey
		var idx = randi() % 3
		var responses = [
			"I can see it in your eyes - your human is growing, aren't they?\n\n*proud smile*\n\nDiscipline chose well when they awakened for you.",
			"Your great-elder would be so proud. The mindscape connection suits you.\n\nRemember: growth takes patience. Both for you and your human.",
			"How is your human doing? I remember my first contribution certification...\n\n*gazes wistfully*\n\nThe bond you're building will last a lifetime.",
		]
		var voices = [
			"res://audio/voice/kitchen/lumina_discipline_0.ogg",
			"res://audio/voice/kitchen/lumina_discipline_1.ogg",
			"res://audio/voice/kitchen/lumina_discipline_2.ogg",
		]
		_show_dialogue("Dr. Lumina", responses[idx], Callable(), voices[idx])
	elif total_focus_sessions > 0:
		# Has done focus sessions but not met Discipline yet
		var idx = randi() % 3
		var responses = [
			"You're making progress! I can feel the connection strengthening.\n\n*touches your shoulder*\n\nKeep guiding them. The mindscape will reveal more soon.",
			"Tell me about your human! What have you learned about them?\n\n*listens intently*\n\nEvery focus session brings you closer.",
			"The neural link is stabilizing nicely. Your human is lucky to have you.\n\nPatience, little one. Great things are coming.",
		]
		var voices = [
			"res://audio/voice/kitchen/lumina_progress_0.ogg",
			"res://audio/voice/kitchen/lumina_progress_1.ogg",
			"res://audio/voice/kitchen/lumina_progress_2.ogg",
		]
		_show_dialogue("Dr. Lumina", responses[idx], Callable(), voices[idx])
	else:
		# Has connected but no focus sessions yet
		_show_dialogue("Dr. Lumina", "You've connected! How exciting!\n\n*beams with pride*\n\nNow help them focus. That's where the real growth begins.\n\nGo back to your room and start a Focus Session with them.", Callable(), "res://audio/voice/kitchen/lumina_connected.ogg")


func _confirm_go_hallway() -> void:
	_play_sfx("res://audio/sfx/door_interact.wav")
	_show_dialogue("Hallway Door", "Enter the hallway toward your room?", _go_to_hallway)


func _go_to_hallway() -> void:
	_play_sfx("res://audio/sfx/door_open.wav")
	GameManager.goto_scene("res://scenes/ship/hallway.tscn")


func _confirm_go_balcony() -> void:
	_play_sfx("res://audio/sfx/door_interact.wav")
	_show_dialogue("Viewing Balcony", "Step out onto the observation deck?", _go_to_balcony)


func _go_to_balcony() -> void:
	_play_sfx("res://audio/sfx/door_open.wav")
	GameManager.player_data["came_from_kitchen"] = true
	GameManager.goto_scene("res://scenes/ship/viewing_balcony.tscn")


func _show_dialogue(title: String, text: String, callback: Callable = Callable(), voice_path: String = "") -> void:
	dialogue_title.text = title
	dialogue_full_text = text
	dialogue_panel.visible = true
	in_dialogue = true
	interaction_prompt.visible = false
	dialogue_callback = callback
	voice_finished = false
	has_voice = voice_path != ""

	# Update button text based on whether there's a callback
	if callback.is_valid():
		dialogue_button.text = "Yes"
	else:
		dialogue_button.text = "Continue"

	# Start typing effect
	_start_typing_effect(text)

	# Play voice if provided
	if voice_path != "":
		_play_dialogue_voice(voice_path)


func _start_typing_effect(text: String) -> void:
	# Kill existing tween
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()

	dialogue_text.text = text
	dialogue_text.visible_ratio = 0.0

	# Calculate duration based on text length
	var duration = text.length() * 0.025  # ~25ms per character
	duration = clamp(duration, 0.5, 6.0)

	typing_tween = create_tween()
	if typing_tween:
		typing_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)


func _skip_typing() -> void:
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
	dialogue_text.visible_ratio = 1.0


func _close_dialogue() -> void:
	dialogue_panel.visible = false
	in_dialogue = false

	# Stop any playing voice
	_stop_dialogue_voice()

	# Kill typing tween
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()

	if dialogue_callback.is_valid():
		dialogue_callback.call()
		dialogue_callback = Callable()


func _play_dialogue_voice(voice_path: String) -> void:
	if not ResourceLoader.exists(voice_path):
		has_voice = false
		return

	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_voice"):
		var stream = load(voice_path)
		if stream:
			audio.play_voice(stream)
			# Connect voice_finished for auto-advance
			if audio.has_signal("voice_finished") and not audio.voice_finished.is_connected(_on_voice_finished):
				audio.voice_finished.connect(_on_voice_finished)


func _on_voice_finished() -> void:
	voice_finished = true
	# Auto-advance for non-callback dialogues
	if in_dialogue and not dialogue_callback.is_valid():
		await get_tree().create_timer(0.5).timeout
		if in_dialogue and voice_finished:
			_close_dialogue()


func _stop_dialogue_voice() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()


func _play_sfx(sfx_path: String, volume_db: float = 0.0) -> void:
	if not ResourceLoader.exists(sfx_path):
		return

	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		var stream = load(sfx_path)
		if stream:
			audio.play_sfx(stream, volume_db)
	else:
		# Fallback: create one-shot player
		var player = AudioStreamPlayer.new()
		player.stream = load(sfx_path)
		player.volume_db = volume_db
		player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(player)
		player.play()
		player.finished.connect(func(): player.queue_free())


func _animate_characters(_delta: float) -> void:
	# Gentle floating animation for mom
	if mom_character:
		var float_offset = sin(animation_time * 1.5) * 3.0
		mom_character.position.y = 80 + float_offset

	# Animate stars twinkling
	_animate_stars()

	# Animate food unit screen
	_animate_screen()

	# Animate key sparkle
	_animate_key()

	# Subtle window light pulse
	if window_light:
		var light_pulse = 0.06 + sin(animation_time * 0.5) * 0.02
		window_light.modulate.a = light_pulse


func _animate_stars() -> void:
	if not stars_container:
		return

	for i in range(stars_container.get_child_count()):
		var star = stars_container.get_child(i)
		if star is Polygon2D:
			# Each star twinkles at different rate
			var twinkle_speed = 1.5 + (i * 0.3)
			var base_alpha = 0.4 + (i % 3) * 0.2
			var twinkle = sin(animation_time * twinkle_speed + i * 1.5) * 0.3
			star.modulate.a = base_alpha + twinkle


func _animate_screen() -> void:
	if not food_screen:
		return

	# Subtle screen flicker
	var flicker = 1.0
	if fmod(animation_time, 3.0) < 0.05:
		flicker = 0.85  # Brief dim

	food_screen.modulate.a = 0.8 * flicker

	if food_screen_glow:
		var glow_pulse = 0.12 + sin(animation_time * 2.0) * 0.05
		food_screen_glow.modulate.a = glow_pulse * flicker


func _animate_key() -> void:
	if not master_key_visual or not master_key_visual.visible:
		return

	# Pulse the key glow
	var key_glow = master_key_visual.get_node_or_null("Glow")
	if key_glow:
		var pulse = 0.25 + sin(animation_time * 2.5) * 0.1
		key_glow.modulate.a = pulse

	# Rotate sparkle
	var sparkle = master_key_visual.get_node_or_null("Sparkle")
	if sparkle:
		sparkle.rotation = animation_time * 1.5
		var sparkle_alpha = 0.7 + sin(animation_time * 4.0) * 0.3
		sparkle.modulate.a = sparkle_alpha


func _pickup_master_key() -> void:
	# Play key pickup sound
	_play_sfx("res://audio/sfx/key_pickup.wav")

	# Add to inventory
	GameManager.add_item("master_key")

	# Hide the key visual
	if master_key_visual:
		master_key_visual.visible = false

	# Remove from interactive objects
	object_positions.erase("MasterKey")
	nearby_object = ""
	_hide_interaction_prompt()

	# Show pickup message with narrator voice
	_show_dialogue("Master Key", "You found a mysterious key!\n\nThis ancient artifact seems to resonate with the neural link technology.\n\n*The key glows faintly and vanishes into your inventory*\n\nWith this, all areas of your human's mindscape will be accessible.", Callable(), "res://audio/voice/kitchen/narrator_master_key.ogg")


# =============================================================================
# IMMERSIVE SPACE VIEW - Kitchen Window (Unique Scene)
# =============================================================================

var space_view_panel: Control = null
var space_view_time: float = 0.0
var space_stars: Array = []
var comet_node: Node2D = null
var space_station: Node2D = null
var stellar_wanderer: Node2D = null
var shooting_stars: Array = []

func _show_space_view() -> void:
	if space_view_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false
	space_view_time = 0.0

	# Create fullscreen space view
	space_view_panel = Control.new()
	space_view_panel.name = "SpaceView"
	space_view_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	space_view_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(space_view_panel)

	# Deep space background with slight gradient
	var bg = ColorRect.new()
	bg.name = "SpaceBackground"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.015, 0.02, 0.05)
	space_view_panel.add_child(bg)

	# Stars container
	var stars_container = Node2D.new()
	stars_container.name = "Stars"
	space_view_panel.add_child(stars_container)
	_create_space_stars(stars_container)

	# Colorful nebula (orange/teal - different from stairs)
	_create_kitchen_nebula()

	# Distant space station
	_create_space_station()

	# The Stellar Wanderer (player's ship) visible outside
	_create_stellar_wanderer()

	# Passing comet
	_create_comet()

	# Shooting stars system
	_init_shooting_stars()

	# Window frame
	_create_kitchen_window_frame()

	# Info text
	var info_label = Label.new()
	info_label.text = "Rest Stop Alpha-7 • The Stellar Wanderer refuels for the next leg of the journey..."
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9, 0.9))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	info_label.offset_top = -80
	info_label.offset_bottom = -50
	space_view_panel.add_child(info_label)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Return to Kitchen"
	close_btn.custom_minimum_size = Vector2(180, 50)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	close_btn.offset_top = -50
	close_btn.offset_left = -90
	close_btn.offset_right = 90
	close_btn.offset_bottom = 0
	close_btn.pressed.connect(_close_space_view)
	space_view_panel.add_child(close_btn)

	# Fade in
	space_view_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(space_view_panel, "modulate:a", 1.0, 0.5)

	# Play voiceover
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_voice_from_path"):
		audio.play_voice_from_path("res://audio/voice/kitchen/space_view.ogg")


func _create_space_stars(container: Node2D) -> void:
	var viewport_size = get_viewport_rect().size
	space_stars.clear()

	for i in range(180):
		var star = Polygon2D.new()
		var size = randf_range(0.8, 2.5)

		star.polygon = PackedVector2Array([
			Vector2(0, -size), Vector2(size * 0.5, 0),
			Vector2(0, size), Vector2(-size * 0.5, 0)
		])

		# Varied star colors
		var color_rand = randf()
		if color_rand < 0.6:
			star.color = Color(1, 1, 1, randf_range(0.2, 0.9))
		elif color_rand < 0.8:
			star.color = Color(0.9, 0.95, 1.0, randf_range(0.3, 0.8))
		else:
			star.color = Color(1.0, 0.9, 0.8, randf_range(0.3, 0.8))

		star.position = Vector2(
			randf_range(0, viewport_size.x),
			randf_range(0, viewport_size.y)
		)

		container.add_child(star)
		space_stars.append({
			"node": star,
			"twinkle_speed": randf_range(1.5, 5.0),
			"twinkle_offset": randf() * TAU,
			"base_alpha": star.color.a
		})


func _create_kitchen_nebula() -> void:
	var viewport_size = get_viewport_rect().size

	# Teal/cyan nebula cloud (upper left)
	var nebula1 = Polygon2D.new()
	var center1 = Vector2(viewport_size.x * 0.2, viewport_size.y * 0.3)
	var points1 = PackedVector2Array()
	for i in range(14):
		var angle = (i / 14.0) * TAU
		var r = 180.0 * (0.6 + randf() * 0.5)
		points1.append(center1 + Vector2(cos(angle), sin(angle)) * r)
	nebula1.polygon = points1
	nebula1.color = Color(0.2, 0.5, 0.6, 0.12)
	space_view_panel.add_child(nebula1)

	# Orange/gold nebula accent (lower right)
	var nebula2 = Polygon2D.new()
	var center2 = Vector2(viewport_size.x * 0.8, viewport_size.y * 0.7)
	var points2 = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		var r = 140.0 * (0.7 + randf() * 0.4)
		points2.append(center2 + Vector2(cos(angle), sin(angle)) * r)
	nebula2.polygon = points2
	nebula2.color = Color(0.7, 0.4, 0.15, 0.1)
	space_view_panel.add_child(nebula2)


func _create_space_station() -> void:
	var viewport_size = get_viewport_rect().size

	space_station = Node2D.new()
	space_station.name = "SpaceStation"
	space_station.position = Vector2(viewport_size.x * 0.75, viewport_size.y * 0.35)
	space_view_panel.add_child(space_station)

	# Central hub (hexagonal)
	var hub = Polygon2D.new()
	var hub_points = PackedVector2Array()
	for i in range(6):
		var angle = (i / 6.0) * TAU - PI/6
		hub_points.append(Vector2(cos(angle), sin(angle)) * 25)
	hub.polygon = hub_points
	hub.color = Color(0.5, 0.52, 0.55)
	space_station.add_child(hub)

	# Solar panel arrays (4 arms)
	var arm_angles = [0, PI/2, PI, 3*PI/2]
	for angle in arm_angles:
		# Arm strut
		var arm = Polygon2D.new()
		var arm_dir = Vector2(cos(angle), sin(angle))
		arm.polygon = PackedVector2Array([
			arm_dir * 25 + arm_dir.orthogonal() * 2,
			arm_dir * 70 + arm_dir.orthogonal() * 2,
			arm_dir * 70 - arm_dir.orthogonal() * 2,
			arm_dir * 25 - arm_dir.orthogonal() * 2,
		])
		arm.color = Color(0.4, 0.42, 0.45)
		space_station.add_child(arm)

		# Solar panel
		var panel = Polygon2D.new()
		var panel_center = arm_dir * 55
		var perp = arm_dir.orthogonal()
		panel.polygon = PackedVector2Array([
			panel_center + perp * 20 + arm_dir * 12,
			panel_center + perp * 20 - arm_dir * 12,
			panel_center - perp * 20 - arm_dir * 12,
			panel_center - perp * 20 + arm_dir * 12,
		])
		panel.color = Color(0.15, 0.2, 0.4)  # Dark blue solar cells
		space_station.add_child(panel)

	# Docking port
	var dock = Polygon2D.new()
	dock.polygon = PackedVector2Array([
		Vector2(-8, 25), Vector2(8, 25), Vector2(10, 40), Vector2(-10, 40)
	])
	dock.color = Color(0.55, 0.57, 0.6)
	space_station.add_child(dock)

	# Lights
	var light_positions = [Vector2(0, -20), Vector2(15, 10), Vector2(-15, 10)]
	for pos in light_positions:
		var light = Polygon2D.new()
		var light_points = PackedVector2Array()
		for j in range(6):
			var a = (j / 6.0) * TAU
			light_points.append(pos + Vector2(cos(a), sin(a)) * 3)
		light.polygon = light_points
		light.color = Color(1, 0.9, 0.7, 0.9)
		space_station.add_child(light)


func _create_stellar_wanderer() -> void:
	var viewport_size = get_viewport_rect().size

	stellar_wanderer = Node2D.new()
	stellar_wanderer.name = "StellarWanderer"
	stellar_wanderer.position = Vector2(viewport_size.x * 0.35, viewport_size.y * 0.55)
	stellar_wanderer.scale = Vector2(0.8, 0.8)
	stellar_wanderer.rotation = 0.1
	space_view_panel.add_child(stellar_wanderer)

	# Main hull (elongated ellipse shape)
	var hull = Polygon2D.new()
	var hull_points = PackedVector2Array()
	for i in range(20):
		var angle = (i / 20.0) * TAU
		var rx = 80.0
		var ry = 25.0
		hull_points.append(Vector2(cos(angle) * rx, sin(angle) * ry))
	hull.polygon = hull_points
	hull.color = Color(0.6, 0.62, 0.68)
	stellar_wanderer.add_child(hull)

	# Bridge dome
	var bridge = Polygon2D.new()
	var bridge_points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * PI  # Half circle
		bridge_points.append(Vector2(cos(angle) * 20, -sin(angle) * 12 - 15))
	bridge.polygon = bridge_points
	bridge.color = Color(0.45, 0.55, 0.7)
	stellar_wanderer.add_child(bridge)

	# Engine pods (2)
	for side in [-1, 1]:
		var pod = Polygon2D.new()
		pod.polygon = PackedVector2Array([
			Vector2(-60, side * 18), Vector2(-85, side * 15),
			Vector2(-85, side * 25), Vector2(-55, side * 28)
		])
		pod.color = Color(0.5, 0.52, 0.55)
		stellar_wanderer.add_child(pod)

		# Engine glow
		var glow = Polygon2D.new()
		glow.name = "EngineGlow" + str(side)
		glow.polygon = PackedVector2Array([
			Vector2(-85, side * 17), Vector2(-100, side * 20), Vector2(-85, side * 23)
		])
		glow.color = Color(0.3, 0.7, 1.0, 0.4)
		stellar_wanderer.add_child(glow)

	# Windows (row of lights)
	for i in range(5):
		var win = Polygon2D.new()
		var x_pos = -30 + i * 15
		win.polygon = PackedVector2Array([
			Vector2(x_pos - 2, -8), Vector2(x_pos + 2, -8),
			Vector2(x_pos + 2, -4), Vector2(x_pos - 2, -4)
		])
		win.color = Color(1, 0.95, 0.8, 0.8)
		stellar_wanderer.add_child(win)


func _create_comet() -> void:
	var viewport_size = get_viewport_rect().size

	comet_node = Node2D.new()
	comet_node.name = "Comet"
	comet_node.position = Vector2(viewport_size.x * 0.9, viewport_size.y * 0.15)
	space_view_panel.add_child(comet_node)

	# Comet tail (gradient effect with multiple polygons)
	var tail_lengths = [120, 90, 60, 30]
	var tail_widths = [25, 18, 12, 6]
	var tail_alphas = [0.1, 0.15, 0.2, 0.3]

	for i in range(tail_lengths.size()):
		var tail = Polygon2D.new()
		var length = tail_lengths[i]
		var width = tail_widths[i]
		tail.polygon = PackedVector2Array([
			Vector2(0, 0),
			Vector2(length, -width),
			Vector2(length, width)
		])
		tail.color = Color(0.6, 0.8, 1.0, tail_alphas[i])
		comet_node.add_child(tail)

	# Comet nucleus (bright core)
	var nucleus = Polygon2D.new()
	var nuc_points = PackedVector2Array()
	for i in range(10):
		var angle = (i / 10.0) * TAU
		nuc_points.append(Vector2(cos(angle), sin(angle)) * 8)
	nucleus.polygon = nuc_points
	nucleus.color = Color(0.9, 0.95, 1.0)
	comet_node.add_child(nucleus)

	# Coma (fuzzy glow around nucleus)
	var coma = Polygon2D.new()
	var coma_points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		coma_points.append(Vector2(cos(angle), sin(angle)) * 15)
	coma.polygon = coma_points
	coma.color = Color(0.7, 0.85, 1.0, 0.3)
	comet_node.add_child(coma)
	coma.z_index = -1


func _init_shooting_stars() -> void:
	shooting_stars.clear()


func _spawn_shooting_star() -> void:
	var viewport_size = get_viewport_rect().size

	var star = {
		"start": Vector2(randf_range(0, viewport_size.x * 0.7), randf_range(0, viewport_size.y * 0.5)),
		"velocity": Vector2(randf_range(400, 700), randf_range(200, 400)),
		"life": 0.0,
		"max_life": randf_range(0.4, 0.8),
		"node": null
	}

	var node = Polygon2D.new()
	node.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(-20, -1), Vector2(-35, 0), Vector2(-20, 1)
	])
	node.color = Color(1, 1, 1, 0.8)
	node.position = star["start"]
	node.rotation = star["velocity"].angle()
	space_view_panel.add_child(node)

	star["node"] = node
	shooting_stars.append(star)


func _update_space_view(delta: float) -> void:
	space_view_time += delta

	# Twinkle stars
	for star_data in space_stars:
		var star = star_data["node"] as Polygon2D
		if star:
			var twinkle = sin(space_view_time * star_data["twinkle_speed"] + star_data["twinkle_offset"])
			star.color.a = star_data["base_alpha"] * (0.5 + twinkle * 0.5)

	# Rotate space station slowly
	if space_station:
		space_station.rotation = space_view_time * 0.05

	# Gentle drift for Stellar Wanderer
	if stellar_wanderer:
		stellar_wanderer.position.y += sin(space_view_time * 0.4) * 0.1
		# Pulse engine glows
		for child in stellar_wanderer.get_children():
			if child.name.begins_with("EngineGlow"):
				child.color.a = 0.3 + sin(space_view_time * 4) * 0.15

	# Move comet slowly across screen
	if comet_node:
		comet_node.position.x -= delta * 15
		comet_node.position.y += delta * 8
		# Reset when off screen
		var viewport_size = get_viewport_rect().size
		if comet_node.position.x < -150:
			comet_node.position = Vector2(viewport_size.x + 100, randf_range(50, viewport_size.y * 0.3))

	# Spawn occasional shooting stars
	if randf() < delta * 0.3:  # ~30% chance per second
		_spawn_shooting_star()

	# Update shooting stars
	var to_remove = []
	for star in shooting_stars:
		star["life"] += delta
		if star["life"] >= star["max_life"]:
			to_remove.append(star)
		else:
			var progress = star["life"] / star["max_life"]
			star["node"].position += star["velocity"] * delta
			star["node"].color.a = 0.8 * (1.0 - progress)

	for star in to_remove:
		if star["node"]:
			star["node"].queue_free()
		shooting_stars.erase(star)


func _create_kitchen_window_frame() -> void:
	var frame = Control.new()
	frame.name = "WindowFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	space_view_panel.add_child(frame)

	# Larger vignette for more oval window feel
	var corners = [
		{"preset": Control.PRESET_TOP_LEFT, "pos": Vector2(0, 0)},
		{"preset": Control.PRESET_TOP_RIGHT, "pos": Vector2(-180, 0)},
		{"preset": Control.PRESET_BOTTOM_LEFT, "pos": Vector2(0, -180)},
		{"preset": Control.PRESET_BOTTOM_RIGHT, "pos": Vector2(-180, -180)}
	]

	for corner in corners:
		var vignette = ColorRect.new()
		vignette.color = Color(0.02, 0.025, 0.04, 0.95)
		vignette.set_anchors_preset(corner["preset"])
		vignette.size = Vector2(180, 180)
		vignette.position = corner["pos"]
		frame.add_child(vignette)

	# Window designation
	var designation = Label.new()
	designation.text = "— DECK 3 • FAMILY QUARTERS • VIEWPORT K-7 —"
	designation.add_theme_font_size_override("font_size", 14)
	designation.add_theme_color_override("font_color", Color(0.45, 0.5, 0.55, 0.7))
	designation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	designation.set_anchors_preset(Control.PRESET_TOP_WIDE)
	designation.offset_top = 20
	frame.add_child(designation)


func _close_space_view() -> void:
	if not space_view_panel:
		return

	var tween = create_tween()
	tween.tween_property(space_view_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_cleanup_space_view)


func _cleanup_space_view() -> void:
	if space_view_panel:
		space_view_panel.queue_free()
		space_view_panel = null

	space_stars.clear()
	shooting_stars.clear()
	comet_node = null
	space_station = null
	stellar_wanderer = null
	in_dialogue = false


# =============================================================================
# HEADER CONTROLS (Volume, Save Indicator)
# =============================================================================

func _setup_header_controls() -> void:
	var header_hbox = menu_button.get_parent()
	if not header_hbox:
		return
	save_indicator = Label.new()
	save_indicator.add_theme_font_size_override("font_size", 14)
	save_indicator.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	save_indicator.tooltip_text = "Current save file"
	_update_save_indicator()
	header_hbox.add_child(save_indicator)
	header_hbox.move_child(save_indicator, menu_button.get_index())
	volume_button = Button.new()
	volume_button.custom_minimum_size = Vector2(45, 45)
	volume_button.add_theme_font_size_override("font_size", 20)
	volume_button.tooltip_text = "Volume (M to mute)"
	volume_button.pressed.connect(_toggle_volume_popup)
	_update_volume_button_icon()
	header_hbox.add_child(volume_button)
	header_hbox.move_child(volume_button, menu_button.get_index())
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		is_muted = audio.master_volume <= 0.01

func _update_save_indicator() -> void:
	if not save_indicator:
		return
	var current_slot = SaveManager.current_slot
	if current_slot > 0:
		var info = SaveManager.get_slot_info(current_slot)
		save_indicator.text = info.slot_name if info.exists else "Slot %d" % current_slot
	else:
		save_indicator.text = "Auto-save"

func _update_volume_button_icon() -> void:
	if not volume_button:
		return
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.master_volume <= 0.01:
		volume_button.text = "🔇"
		is_muted = true
	else:
		volume_button.text = "🔊"
		is_muted = false

func _toggle_volume_popup() -> void:
	if volume_popup:
		_close_volume_popup()
		return
	volume_popup = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.98)
	style.border_color = Color(0.4, 0.35, 0.6, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	volume_popup.add_theme_stylebox_override("panel", style)
	volume_popup.position = volume_button.global_position + Vector2(-80, volume_button.size.y + 5)
	volume_popup.custom_minimum_size = Vector2(200, 0)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	volume_popup.add_child(margin)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	var title = Label.new()
	title.text = "Volume"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var audio = get_node_or_null("/root/AudioManager")
	for channel in ["Master", "Music", "SFX"]:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)
		var lbl = Label.new()
		lbl.text = channel
		lbl.custom_minimum_size = Vector2(55, 0)
		lbl.add_theme_font_size_override("font_size", 14)
		row.add_child(lbl)
		var slider = HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		match channel:
			"Master": slider.value = audio.master_volume * 100 if audio else 100
			"Music": slider.value = audio.music_volume * 100 if audio else 100
			"SFX": slider.value = audio.sfx_volume * 100 if audio else 100
		slider.custom_minimum_size = Vector2(100, 20)
		slider.value_changed.connect(func(val): _on_volume_changed(channel.to_lower(), val))
		row.add_child(slider)
	var mute_btn = Button.new()
	mute_btn.text = "Unmute All" if is_muted else "Mute All"
	mute_btn.custom_minimum_size = Vector2(0, 35)
	mute_btn.add_theme_font_size_override("font_size", 14)
	mute_btn.pressed.connect(_toggle_mute)
	vbox.add_child(mute_btn)
	add_child(volume_popup)

func _close_volume_popup() -> void:
	if volume_popup:
		volume_popup.queue_free()
		volume_popup = null

func _on_volume_changed(channel: String, value: float) -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		return
	var vol = value / 100.0
	match channel:
		"master": audio.set_master_volume(vol)
		"music": audio.set_music_volume(vol)
		"sfx": audio.set_sfx_volume(vol)
	_update_volume_button_icon()

func _toggle_mute() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		return
	if is_muted:
		audio.set_master_volume(1.0)
		is_muted = false
	else:
		audio.set_master_volume(0.0)
		is_muted = true
	_update_volume_button_icon()
	_close_volume_popup()


# =============================================================================
# PAUSE MENU
# =============================================================================

var pause_menu: PanelContainer = null

func _open_pause_menu() -> void:
	if pause_menu:
		return

	in_dialogue = true
	interaction_prompt.visible = false

	pause_menu = PanelContainer.new()
	pause_menu.name = "PauseMenu"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.98)
	style.border_color = Color(0.5, 0.4, 0.7, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	pause_menu.add_theme_stylebox_override("panel", style)

	pause_menu.set_anchors_preset(Control.PRESET_CENTER)
	pause_menu.offset_left = -200
	pause_menu.offset_right = 200
	pause_menu.offset_top = -200
	pause_menu.offset_bottom = 200

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	pause_menu.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Menu"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Resume button
	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.custom_minimum_size = Vector2(0, 50)
	resume_btn.add_theme_font_size_override("font_size", 20)
	resume_btn.pressed.connect(_close_pause_menu)
	vbox.add_child(resume_btn)

	# Settings button
	var settings_btn = Button.new()
	settings_btn.text = "Settings"
	settings_btn.custom_minimum_size = Vector2(0, 50)
	settings_btn.add_theme_font_size_override("font_size", 20)
	settings_btn.pressed.connect(_go_to_settings)
	vbox.add_child(settings_btn)

	# Main Menu button
	var main_menu_btn = Button.new()
	main_menu_btn.text = "Main Menu"
	main_menu_btn.custom_minimum_size = Vector2(0, 50)
	main_menu_btn.add_theme_font_size_override("font_size", 20)
	main_menu_btn.add_theme_color_override("font_color", Color(0.8, 0.6, 0.6))
	main_menu_btn.pressed.connect(_go_to_main_menu)
	vbox.add_child(main_menu_btn)

	add_child(pause_menu)


func _close_pause_menu() -> void:
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null
	in_dialogue = false


func _go_to_settings() -> void:
	_close_pause_menu()
	GameManager.goto_scene("res://scenes/settings/settings.tscn")


func _go_to_main_menu() -> void:
	_close_pause_menu()
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
