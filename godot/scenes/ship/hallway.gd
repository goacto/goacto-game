extends Control
## Hallway - Corridor leading to Goacto's room
## Part of intro flow: Kitchen -> Hallway -> Stairs -> Bedroom

# World elements
@onready var game_world: Control = $GameWorld
@onready var isometric_base: Node2D = $GameWorld/IsometricBase
@onready var player: Node2D = $GameWorld/IsometricBase/Player

# Decorative lights
@onready var lights_container: Node2D = $GameWorld/IsometricBase/Lights

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

# Player movement
var player_speed: float = 280.0
var player_bounds: Rect2 = Rect2(-500, -100, 2000, 200)  # Extended to the right for cargo hold

# Camera follows player along the hallway
var camera_zoom: float = 1.0
var min_zoom: float = 0.6
var max_zoom: float = 1.5
var zoom_speed: float = 0.08

# Interaction state
var nearby_object: String = ""
var in_dialogue: bool = false
var dialogue_callback: Callable

# Animation
var animation_time: float = 0.0

# Movement sound
var move_sound_timer: float = 0.0
var move_sound_interval: float = 0.35

# Enhanced environment elements
var environment_container: Node2D = null
var floor_lights: Array = []
var wall_panels: Array = []
var plant_node: Node2D = null
var highlight_glows: Dictionary = {}  # object_id -> glow node

# Mail notification
var mail_notification_glow: Node2D = null
var has_mail_waiting: bool = false

# Interactive objects in hallway
const INTERACTIVE_OBJECTS = {
	"KitchenDoor": {
		"name": "Kitchen Door",
		"prompt": "Press SPACE to return to kitchen",
		"action": "go_kitchen"
	},
	"Stairs": {
		"name": "Stairway Up",
		"prompt": "Press SPACE to go upstairs",
		"action": "go_stairs"
	},
	"LivingRoomDoor": {
		"name": "Living Room",
		"prompt": "Press SPACE to enter",
		"action": "go_living_room"
	},
	"CargoHoldDoor": {
		"name": "Cargo Hold",
		"prompt": "Press SPACE to enter cargo hold",
		"action": "go_cargo_hold"
	},
	"ObservatoryDoor": {
		"name": "Observatory",
		"prompt": "Press SPACE to enter observatory",
		"action": "go_observatory"
	},
	"Painting1": {
		"name": "Family Portrait",
		"prompt": "Press SPACE to examine",
		"action": "examine_painting1"
	},
	"Painting2": {
		"name": "Goactorian Landscape",
		"prompt": "Press SPACE to examine",
		"action": "examine_painting2"
	},
	"Painting3": {
		"name": "Ancient Star Map",
		"prompt": "Press SPACE to examine",
		"action": "examine_painting3"
	},
	"PlantPot": {
		"name": "Corridor Plant",
		"prompt": "Press SPACE to examine",
		"action": "examine_plant"
	},
	"Crate1": {
		"name": "Storage Crate",
		"prompt": "Press SPACE to examine",
		"action": "examine_crate"
	},
	"EmergencyPanel": {
		"name": "Emergency Panel",
		"prompt": "Press SPACE to check status",
		"action": "examine_emergency_panel"
	},
	"HallwayWindow": {
		"name": "Observation Window",
		"prompt": "Press SPACE to look outside",
		"action": "view_hallway_window"
	},
	"VentGrate": {
		"name": "Ventilation Grate",
		"prompt": "Press SPACE to examine",
		"action": "examine_vent"
	},
	"Crate2": {
		"name": "Supply Container",
		"prompt": "Press SPACE to examine",
		"action": "examine_crate2"
	},
	"BulletinBoard": {
		"name": "Crew Bulletin Board",
		"prompt": "Press SPACE to read notices",
		"action": "read_bulletin_board"
	},
	"ShipStatus": {
		"name": "Ship Status Display",
		"prompt": "Press SPACE to check systems",
		"action": "check_ship_status"
	},
	"AchievementDisplay": {
		"name": "Achievement Display",
		"prompt": "Press SPACE to view achievements",
		"action": "view_achievements"
	},
	"MotivationalPoster": {
		"name": "Motivational Poster",
		"prompt": "Press SPACE to read",
		"action": "read_poster"
	}
}

# Object positions for proximity detection
var object_positions: Dictionary = {
	"KitchenDoor": Vector2(-450, 0),
	"Stairs": Vector2(450, 0),
	"LivingRoomDoor": Vector2(850, 0),
	"CargoHoldDoor": Vector2(1500, 0),
	"ObservatoryDoor": Vector2(250, 0),
	"Painting1": Vector2(-200, -80),
	"Painting2": Vector2(100, -80),
	"Painting3": Vector2(650, -80),
	"PlantPot": Vector2(0, 50),
	"Crate1": Vector2(1150, 60),
	"Crate2": Vector2(1220, 40),
	"EmergencyPanel": Vector2(-100, -100),
	"HallwayWindow": Vector2(300, -100),
	"VentGrate": Vector2(950, 60),
	"BulletinBoard": Vector2(-280, -100),
	"ShipStatus": Vector2(500, -100),
	"AchievementDisplay": Vector2(1100, -100),
	"MotivationalPoster": Vector2(780, -80)
}


func _ready() -> void:
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

	# Position player based on where they came from
	if GameManager.player_data.get("came_from_stairs", false):
		# Coming from stairs - spawn near stairs door
		player.position = Vector2(350, 0)
		GameManager.player_data.erase("came_from_stairs")
	elif GameManager.player_data.get("came_from_living_room", false):
		# Coming from living room - spawn near living room door (far right)
		player.position = Vector2(750, 0)
		GameManager.player_data.erase("came_from_living_room")
	elif GameManager.player_data.get("came_from_cargo_hold", false):
		# Coming from cargo hold - spawn near cargo hold door
		player.position = Vector2(1400, 0)
		GameManager.player_data.erase("came_from_cargo_hold")
	elif GameManager.player_data.get("came_from_observatory", false):
		# Coming from observatory - spawn near observatory door
		player.position = Vector2(250, 0)
		GameManager.player_data.erase("came_from_observatory")
	else:
		# Coming from kitchen - spawn near kitchen door (left side)
		player.position = Vector2(-350, 0)

	# Center the view
	_update_camera()

	# Create enhanced environment
	_create_enhanced_environment()

	# Setup discovery shimmers
	_setup_discovery_shimmers()

	# Setup mail notification
	_setup_mail_notification()

	print("[Hallway] Ship corridor ready")


func _process(delta: float) -> void:
	animation_time += delta

	# Animate hallway lights
	_animate_lights(delta)

	# Animate enhanced elements
	_animate_environment(delta)

	# Animate detail views if open
	_update_detail_views(delta)

	if in_dialogue:
		return

	# Check object proximity
	_check_object_proximity()

	# Update proximity highlights
	_update_proximity_highlights()

	# Animate mail notification
	_animate_mail_notification()

	# Update discovery shimmers
	_animate_discovery_shimmers()

	# Handle movement
	_handle_movement(delta)

	# Update camera (follows player)
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
		if plant_detail_panel:
			_close_plant_detail()
			viewport.set_input_as_handled()
			return
		if family_portrait_panel:
			_close_family_portrait_detail()
			viewport.set_input_as_handled()
			return
		if landscape_detail_panel:
			_close_landscape_detail()
			viewport.set_input_as_handled()
			return
		if space_view_panel:
			_close_hallway_space_view()
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
	if space_view_panel:
		if event.is_action_pressed("ui_accept"):
			_close_hallway_space_view()
			viewport.set_input_as_handled()
		return

	# Close detail views with SPACE
	if plant_detail_panel:
		if event.is_action_pressed("ui_accept"):
			_close_plant_detail()
			viewport.set_input_as_handled()
		return

	if family_portrait_panel:
		if event.is_action_pressed("ui_accept"):
			_close_family_portrait_detail()
			viewport.set_input_as_handled()
		return

	if landscape_detail_panel:
		if event.is_action_pressed("ui_accept"):
			_close_landscape_detail()
			viewport.set_input_as_handled()
		return

	if in_dialogue:
		if event.is_action_pressed("ui_accept"):
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

		# Hallway is mostly horizontal, favor X movement (W=up-left, S=down-right, A=down-left, D=up-right)
		var iso_movement = Vector2(
			input_dir.x + input_dir.y * 0.3,
			(input_dir.y - input_dir.x) * 0.3
		)

		var new_pos = player.position + iso_movement * player_speed * delta

		# Clamp to hallway bounds
		new_pos.x = clamp(new_pos.x, player_bounds.position.x, player_bounds.position.x + player_bounds.size.x)
		new_pos.y = clamp(new_pos.y, player_bounds.position.y, player_bounds.position.y + player_bounds.size.y)

		player.position = new_pos

		# Play movement sound
		move_sound_timer += delta
		if move_sound_timer >= move_sound_interval:
			move_sound_timer = 0.0
			_play_sfx("res://audio/sfx/hover_move.wav", -12.0)
	else:
		move_sound_timer = 0.0


func _play_sfx(sfx_path: String, volume_db: float = 0.0) -> void:
	if not ResourceLoader.exists(sfx_path):
		return
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		var stream = load(sfx_path)
		if stream:
			audio.play_sfx(stream, volume_db)
	else:
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.stream = load(sfx_path)
		sfx_player.volume_db = volume_db
		sfx_player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(sfx_player)
		sfx_player.play()
		sfx_player.finished.connect(func(): sfx_player.queue_free())


func _update_camera() -> void:
	if not isometric_base or not player:
		return

	var screen_center = get_viewport_rect().size / 2

	# Camera follows player - center player on screen
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
	# Mark object as discovered (removes shimmer hint)
	GameManager.mark_object_discovered("hallway_" + object_id)

	var obj_data = INTERACTIVE_OBJECTS.get(object_id, {})
	var action = obj_data.get("action", "")

	match action:
		"go_kitchen":
			GameManager.goto_scene("res://scenes/ship/kitchen.tscn")
		"go_stairs":
			_confirm_go_stairs()
		"go_cargo_hold":
			GameManager.goto_scene("res://scenes/ship/cargo_hold.tscn")
		"go_observatory":
			if _is_observatory_unlocked():
				GameManager.player_data["came_from_hallway"] = true
				GameManager.goto_scene("res://scenes/ship/observatory.tscn")
			else:
				_show_dialogue("Observatory Locked", "The observation deck is currently sealed.\n\n*A soft hum emanates from behind the door*\n\nPerhaps after you've established a connection with your human, this area will open up.")
		"examine_painting1":
			_show_family_portrait_detail()
		"examine_painting2":
			_show_landscape_detail()
		"examine_painting3":
			_show_dialogue("Ancient Star Map", "A detailed map of the Goactorian constellation routes.\n\nYour ancestors charted these paths thousands of years ago.\n\nThe glowing markers show your current position - so far from home.", Callable(), "res://audio/voice/hallway/painting_starmap.ogg")
		"examine_plant":
			_show_plant_detail()
		"go_living_room":
			GameManager.player_data["came_from_hallway"] = true
			GameManager.goto_scene("res://scenes/ship/living_room.tscn")
		"examine_crate":
			_show_dialogue("Storage Crate", "Standard cargo container marked 'SUPPLIES - DECK 1'.\n\nIt's sealed with a magnetic lock.\n\nThe manifest says: dried rations, water filters, spare parts.")
		"examine_crate2":
			_show_dialogue("Supply Container", "A smaller container labeled 'PERSONAL EFFECTS'.\n\nProbably Mom and Dad's extra belongings from home.\n\nYou recognize some old toys peeking out from a corner.")
		"examine_emergency_panel":
			_show_dialogue("Emergency Panel", "Ship Status: ALL SYSTEMS NOMINAL\n\n• Life Support: 100%\n• Hull Integrity: 100%\n• Navigation: AUTOPILOT ENGAGED\n• ETA to Destination: 47 years, 3 months\n\nEmergency protocols ready. No active alerts.")
		"view_hallway_window":
			_show_hallway_space_view()
		"examine_vent":
			_show_dialogue("Ventilation Grate", "The ship's ventilation system hums softly.\n\nWarm, recycled air flows through the grate.\n\nYou can hear distant mechanical sounds from deeper in the ship - the heartbeat of the Stellar Wanderer.")
		"read_bulletin_board":
			_show_bulletin_board()
		"check_ship_status":
			_show_ship_status()
		"view_achievements":
			_show_achievement_display()
		"read_poster":
			_show_motivational_poster()


func _confirm_go_stairs() -> void:
	_show_dialogue("Stairway Up", "Go upstairs to your room?", _go_to_stairs)


func _go_to_stairs() -> void:
	GameManager.goto_scene("res://scenes/ship/stairs.tscn")


func _show_dialogue(title: String, text: String, callback: Callable = Callable(), voice_path: String = "") -> void:
	dialogue_title.text = title
	dialogue_text.text = text
	dialogue_panel.visible = true
	in_dialogue = true
	interaction_prompt.visible = false
	dialogue_callback = callback

	# Play voice if provided
	if voice_path != "":
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_voice_from_path"):
			audio.play_voice_from_path(voice_path)

	# Update button text based on whether there's a callback
	if callback.is_valid():
		dialogue_button.text = "Yes"
	else:
		dialogue_button.text = "Continue"


func _close_dialogue() -> void:
	dialogue_panel.visible = false
	in_dialogue = false

	if dialogue_callback.is_valid():
		dialogue_callback.call()
		dialogue_callback = Callable()


func _is_observatory_unlocked() -> bool:
	# Master key unlocks everything
	if GameManager.has_method("has_master_key") and GameManager.has_master_key():
		return true
	# Observatory unlocks after completing Chapter 2 (met Discipline)
	if CampaignManager.is_chapter_completed("chapter_2"):
		return true
	# Also check if console is placed (started the journey)
	if GameManager.player_data.get("console_placed_in_bedroom", false):
		return true
	return false


func _show_bulletin_board() -> void:
	## Show crew bulletin board with tips and messages
	var tips = [
		"Remember to take breaks during long focus sessions!",
		"Hydration is key - drink water regularly.",
		"A 5-minute walk can boost creativity.",
		"Celebrate small wins - they add up!",
		"Today's kindness can change someone's tomorrow."
	]
	var random_tip = tips[randi() % tips.size()]

	var streak = GameManager.player_data.get("current_streak", 0)
	var streak_msg = ""
	if streak > 0:
		streak_msg = "\n\n📊 Current Streak: " + str(streak) + " days!"

	var content = "═══ CREW NOTICES ═══\n\n"
	content += "💡 Daily Tip:\n\"" + random_tip + "\"\n"
	content += streak_msg
	content += "\n\n• Ship systems: Nominal\n• Morale level: Growing\n• ETA: 47 years"

	_show_dialogue("Crew Bulletin Board", content)


func _show_ship_status() -> void:
	## Show detailed ship status display
	var focus_sessions = GameManager.player_data.get("total_focus_sessions", 0)
	var total_minutes = GameManager.player_data.get("total_focus_minutes", 0)
	var habits_completed = GameManager.player_data.get("habits_completed_today", 0)
	var evolution = GameManager.get_evolution_level() if GameManager else 1

	var status = "╔═══ STELLAR WANDERER ═══╗\n\n"
	status += "▸ Life Support: 100% ●\n"
	status += "▸ Hull Integrity: 100% ●\n"
	status += "▸ Navigation: AUTOPILOT ●\n"
	status += "▸ Mindscape Link: ACTIVE ●\n\n"
	status += "═══ CREW METRICS ═══\n\n"
	status += "Focus Sessions: " + str(focus_sessions) + "\n"
	status += "Focus Minutes: " + str(total_minutes) + "\n"
	status += "Today's Habits: " + str(habits_completed) + "\n"
	status += "Evolution Level: " + str(evolution) + "\n"
	status += "\n╚═══════════════════════╝"

	_show_dialogue("Ship Status Display", status)


func _show_achievement_display() -> void:
	## Show recent achievements
	var achievements = []

	# Check for achievements based on player progress
	var focus_sessions = GameManager.player_data.get("total_focus_sessions", 0)
	var streak = GameManager.player_data.get("current_streak", 0)
	var evolution = GameManager.get_evolution_level() if GameManager else 1

	if focus_sessions >= 1:
		achievements.append("🎯 First Focus - Complete your first session")
	if focus_sessions >= 10:
		achievements.append("🔥 Focused Ten - Complete 10 focus sessions")
	if focus_sessions >= 25:
		achievements.append("⭐ Quarter Century - Complete 25 sessions")
	if streak >= 3:
		achievements.append("📅 Three-peat - Maintain a 3-day streak")
	if streak >= 7:
		achievements.append("🌟 Week Warrior - Maintain a 7-day streak")
	if evolution >= 2:
		achievements.append("🌱 Growing - Reach Evolution Level 2")
	if evolution >= 5:
		achievements.append("🌳 Flourishing - Reach Evolution Level 5")

	var content = "═══ ACHIEVEMENT DISPLAY ═══\n\n"
	if achievements.is_empty():
		content += "No achievements yet.\n\nStart your journey by:\n• Completing focus sessions\n• Building daily habits\n• Exploring the mindscape"
	else:
		content += "Unlocked (" + str(achievements.size()) + "):\n\n"
		for achievement in achievements:
			content += achievement + "\n"

	_show_dialogue("Achievement Display", content)


func _show_motivational_poster() -> void:
	## Show a random motivational quote
	var quotes = [
		{"quote": "The journey of a thousand miles begins with a single step.", "author": "Lao Tzu"},
		{"quote": "You don't have to be great to start, but you have to start to be great.", "author": "Zig Ziglar"},
		{"quote": "Progress, not perfection.", "author": "Unknown"},
		{"quote": "Small steps every day lead to big changes over time.", "author": "Goactorian Proverb"},
		{"quote": "Your future is created by what you do today.", "author": "Robert Kiyosaki"},
		{"quote": "Discipline is choosing between what you want now and what you want most.", "author": "Abraham Lincoln"},
		{"quote": "The mind is everything. What you think, you become.", "author": "Buddha"},
		{"quote": "Every expert was once a beginner.", "author": "Helen Hayes"}
	]

	var random_quote = quotes[randi() % quotes.size()]

	var content = "╭──────────────────────────╮\n"
	content += "│                          │\n"
	content += "│  \"" + random_quote.quote + "\"  │\n"
	content += "│                          │\n"
	content += "│  — " + random_quote.author + "  │\n"
	content += "│                          │\n"
	content += "╰──────────────────────────╯"

	_show_dialogue("Motivational Poster", content)


func _animate_lights(delta: float) -> void:
	if not lights_container:
		return

	# Gentle pulsing of corridor lights
	for i in range(lights_container.get_child_count()):
		var light = lights_container.get_child(i)
		var phase_offset = float(i) * 0.5
		var pulse = (sin(animation_time * 2.0 + phase_offset) + 1.0) / 2.0
		light.modulate.a = 0.6 + pulse * 0.4


# =============================================================================
# ENHANCED ENVIRONMENT
# =============================================================================

func _create_enhanced_environment() -> void:
	environment_container = Node2D.new()
	environment_container.name = "EnhancedEnvironment"
	isometric_base.add_child(environment_container)
	isometric_base.move_child(environment_container, 1)  # After floor

	_create_floor_lights()
	_create_wall_panels()
	_create_highlight_glows()
	_enhance_plant()


func _create_floor_lights() -> void:
	floor_lights.clear()

	# Add glowing floor strips at regular intervals (extended for longer hallway)
	var light_positions = [-350, -100, 150, 400, 700, 1000, 1300]

	for x_pos in light_positions:
		# Main light
		var light = Polygon2D.new()
		light.polygon = PackedVector2Array([
			Vector2(x_pos - 40, 25), Vector2(x_pos + 40, 25),
			Vector2(x_pos + 35, 35), Vector2(x_pos - 35, 35)
		])
		light.color = Color(0.5, 0.6, 0.9, 0.2)
		environment_container.add_child(light)

		# Light glow
		var glow = Polygon2D.new()
		glow.polygon = PackedVector2Array([
			Vector2(x_pos - 60, 15), Vector2(x_pos + 60, 15),
			Vector2(x_pos + 50, 45), Vector2(x_pos - 50, 45)
		])
		glow.color = Color(0.4, 0.5, 0.8, 0.08)
		environment_container.add_child(glow)

		floor_lights.append({
			"light": light,
			"glow": glow,
			"base_x": x_pos,
			"phase": randf() * TAU
		})


func _create_wall_panels() -> void:
	wall_panels.clear()

	# Decorative wall panels between paintings (extended for longer hallway)
	var panel_positions = [-320, 300, 550, 1050, 1300]

	for x_pos in panel_positions:
		var panel = Node2D.new()
		panel.position = Vector2(x_pos, -180)
		environment_container.add_child(panel)

		# Panel frame
		var frame = Polygon2D.new()
		frame.polygon = PackedVector2Array([
			Vector2(-20, -50), Vector2(20, -50), Vector2(20, 20), Vector2(-20, 20)
		])
		frame.color = Color(0.2, 0.18, 0.28, 0.8)
		panel.add_child(frame)

		# Panel inner
		var inner = Polygon2D.new()
		inner.polygon = PackedVector2Array([
			Vector2(-15, -45), Vector2(15, -45), Vector2(15, 15), Vector2(-15, 15)
		])
		inner.color = Color(0.15, 0.12, 0.22, 0.6)
		panel.add_child(inner)

		# Panel indicator light
		var indicator = Polygon2D.new()
		indicator.name = "Indicator"
		indicator.polygon = PackedVector2Array([
			Vector2(-4, -40), Vector2(4, -40), Vector2(4, -34), Vector2(-4, -34)
		])
		indicator.color = Color(0.4, 0.8, 0.6, 0.7)
		panel.add_child(indicator)

		wall_panels.append({
			"node": panel,
			"phase": randf() * TAU
		})


func _create_highlight_glows() -> void:
	highlight_glows.clear()

	# Create glow polygons for each interactive object
	var glow_configs = {
		"Painting1": {"pos": Vector2(-200, -180), "size": Vector2(110, 90), "color": Color(0.6, 0.5, 0.4)},
		"Painting2": {"pos": Vector2(100, -180), "size": Vector2(130, 80), "color": Color(0.5, 0.4, 0.6)},
		"Painting3": {"pos": Vector2(650, -180), "size": Vector2(120, 100), "color": Color(0.4, 0.5, 0.7)},
		"PlantPot": {"pos": Vector2(0, 20), "size": Vector2(80, 100), "color": Color(0.3, 0.6, 0.4)},
		"KitchenDoor": {"pos": Vector2(-450, -40), "size": Vector2(100, 200), "color": Color(0.5, 0.4, 0.7)},
		"Stairs": {"pos": Vector2(450, -40), "size": Vector2(110, 210), "color": Color(0.5, 0.6, 0.8)},
		"ObservatoryDoor": {"pos": Vector2(250, -40), "size": Vector2(100, 200), "color": Color(0.4, 0.5, 0.8)},
		"LivingRoomDoor": {"pos": Vector2(850, -40), "size": Vector2(110, 200), "color": Color(0.5, 0.5, 0.7)},
		"CargoHoldDoor": {"pos": Vector2(1500, -40), "size": Vector2(120, 210), "color": Color(0.7, 0.5, 0.3)},
		"Crate1": {"pos": Vector2(1150, 40), "size": Vector2(70, 60), "color": Color(0.5, 0.4, 0.3)},
		"Crate2": {"pos": Vector2(1220, 30), "size": Vector2(55, 50), "color": Color(0.5, 0.4, 0.3)},
		"EmergencyPanel": {"pos": Vector2(-100, -150), "size": Vector2(60, 80), "color": Color(0.8, 0.4, 0.3)},
		"HallwayWindow": {"pos": Vector2(300, -150), "size": Vector2(100, 70), "color": Color(0.3, 0.5, 0.7)},
		"VentGrate": {"pos": Vector2(950, 40), "size": Vector2(50, 40), "color": Color(0.4, 0.4, 0.5)},
		"BulletinBoard": {"pos": Vector2(-280, -150), "size": Vector2(90, 70), "color": Color(0.6, 0.5, 0.3)},
		"ShipStatus": {"pos": Vector2(500, -150), "size": Vector2(80, 60), "color": Color(0.3, 0.7, 0.5)},
		"AchievementDisplay": {"pos": Vector2(1100, -150), "size": Vector2(70, 80), "color": Color(0.8, 0.7, 0.3)},
		"MotivationalPoster": {"pos": Vector2(780, -150), "size": Vector2(60, 80), "color": Color(0.5, 0.5, 0.8)},
	}

	for object_id in glow_configs:
		var config = glow_configs[object_id]
		var glow = Polygon2D.new()
		glow.name = object_id + "Glow"

		var half_w = config["size"].x / 2
		var half_h = config["size"].y / 2
		glow.polygon = PackedVector2Array([
			Vector2(-half_w, -half_h), Vector2(half_w, -half_h),
			Vector2(half_w, half_h), Vector2(-half_w, half_h)
		])
		glow.position = config["pos"]
		glow.color = Color(config["color"].r, config["color"].g, config["color"].b, 0.0)
		glow.z_index = -1
		environment_container.add_child(glow)

		highlight_glows[object_id] = {
			"node": glow,
			"color": config["color"],
			"current_alpha": 0.0,
			"target_alpha": 0.0
		}


func _enhance_plant() -> void:
	# Find the plant node and add swaying animation
	plant_node = isometric_base.get_node_or_null("PlantPot")
	if plant_node:
		# Add bioluminescent spores
		var spores_container = Node2D.new()
		spores_container.name = "Spores"
		plant_node.add_child(spores_container)

		for i in range(8):
			var spore = Polygon2D.new()
			var size = randf_range(2, 4)
			var points = PackedVector2Array()
			for j in range(6):
				var angle = (j / 6.0) * TAU
				points.append(Vector2(cos(angle), sin(angle)) * size)
			spore.polygon = points
			spore.position = Vector2(randf_range(-25, 25), randf_range(-60, -20))
			spore.color = Color(0.5, 0.9, 0.6, randf_range(0.2, 0.5))
			spores_container.add_child(spore)


func _animate_environment(delta: float) -> void:
	_animate_floor_lights()
	_animate_wall_panels()
	_animate_plant()


func _animate_floor_lights() -> void:
	for floor_light in floor_lights:
		var light = floor_light["light"] as Polygon2D
		var glow = floor_light["glow"] as Polygon2D
		var phase = floor_light["phase"]

		if light and glow:
			var pulse = sin(animation_time * 1.5 + phase) * 0.1 + 0.9
			light.color.a = 0.2 * pulse
			glow.color.a = 0.08 * pulse


func _animate_wall_panels() -> void:
	for panel_info in wall_panels:
		var panel = panel_info["node"] as Node2D
		var phase = panel_info["phase"]

		if panel:
			var indicator = panel.get_node_or_null("Indicator")
			if indicator:
				# Slow blink
				var blink = (sin(animation_time * 0.8 + phase) + 1.0) / 2.0
				indicator.color.a = 0.4 + blink * 0.5


func _animate_plant() -> void:
	if plant_node:
		# Gentle sway
		var sway = sin(animation_time * 1.2) * 0.03
		var plant_leaf = plant_node.get_node_or_null("Plant")
		if plant_leaf:
			plant_leaf.rotation = sway

		# Animate spores
		var spores = plant_node.get_node_or_null("Spores")
		if spores:
			for i in range(spores.get_child_count()):
				var spore = spores.get_child(i) as Polygon2D
				if spore:
					# Gentle float
					spore.position.y += sin(animation_time * 2.0 + float(i) * 0.7) * 0.02
					spore.position.x += cos(animation_time * 1.5 + float(i) * 0.5) * 0.015
					# Pulse
					var pulse = (sin(animation_time * 3.0 + float(i)) + 1.0) / 2.0
					spore.color.a = 0.25 + pulse * 0.35


func _update_proximity_highlights() -> void:
	for object_id in highlight_glows:
		var glow_data = highlight_glows[object_id]
		var glow = glow_data["node"] as Polygon2D

		if not glow:
			continue

		# Set target alpha based on proximity
		if object_id == nearby_object:
			glow_data["target_alpha"] = 0.15
		else:
			glow_data["target_alpha"] = 0.0

		# Smooth interpolation
		glow_data["current_alpha"] = lerpf(glow_data["current_alpha"], glow_data["target_alpha"], 0.15)

		# Apply with pulse when active
		var alpha = glow_data["current_alpha"]
		if alpha > 0.01:
			var pulse = sin(animation_time * 3.0) * 0.03
			alpha += pulse
		glow.color.a = alpha


# =============================================================================
# DISCOVERY SHIMMER (hints for undiscovered objects)
# =============================================================================

var discovery_shimmers: Dictionary = {}

func _setup_discovery_shimmers() -> void:
	# Create shimmer effects for undiscovered objects
	for obj_name in object_positions:
		var object_id = "hallway_" + obj_name

		# Skip if already discovered
		if GameManager.has_discovered_object(object_id):
			continue

		# Skip door/navigation objects
		if obj_name in ["KitchenDoor", "Stairs", "LivingRoomDoor"]:
			continue

		var pos = object_positions[obj_name]
		var shimmer = Node2D.new()
		shimmer.name = "DiscoveryShimmer_" + obj_name
		shimmer.position = pos

		# Create subtle sparkle points around the object
		for i in range(4):
			var sparkle = Polygon2D.new()
			var angle = (i / 4.0) * TAU
			var dist = 30.0
			sparkle.position = Vector2(cos(angle) * dist, sin(angle) * dist * 0.5 - 40)

			# Small diamond shape
			sparkle.polygon = PackedVector2Array([
				Vector2(0, -4), Vector2(3, 0), Vector2(0, 4), Vector2(-3, 0)
			])
			sparkle.color = Color(0.9, 0.85, 0.6, 0.0)
			sparkle.name = "Sparkle" + str(i)
			shimmer.add_child(sparkle)

		isometric_base.add_child(shimmer)
		discovery_shimmers[obj_name] = shimmer


func _animate_discovery_shimmers() -> void:
	if discovery_shimmers.is_empty():
		return

	var shimmers_to_remove = []

	for obj_name in discovery_shimmers:
		var object_id = "hallway_" + obj_name

		# Remove shimmer if object was just discovered
		if GameManager.has_discovered_object(object_id):
			shimmers_to_remove.append(obj_name)
			continue

		var shimmer = discovery_shimmers[obj_name] as Node2D
		if not shimmer:
			continue

		# Animate sparkles in a subtle wave pattern
		var sparkle_count = shimmer.get_child_count()
		for i in range(sparkle_count):
			var sparkle = shimmer.get_child(i) as Polygon2D
			if not sparkle:
				continue

			# Staggered pulse for each sparkle
			var phase = animation_time * 2.0 + (i * TAU / sparkle_count)
			var pulse = (sin(phase) + 1.0) / 2.0

			# Fade between visible and invisible
			sparkle.color.a = pulse * 0.4

			# Subtle scale pulse
			var scale = 0.8 + pulse * 0.4
			sparkle.scale = Vector2(scale, scale)

	# Remove discovered shimmers
	for obj_name in shimmers_to_remove:
		var shimmer = discovery_shimmers[obj_name]
		if shimmer:
			shimmer.queue_free()
		discovery_shimmers.erase(obj_name)


# =============================================================================
# MAIL NOTIFICATION (glow on cargo hold door when mail waiting)
# =============================================================================

func _setup_mail_notification() -> void:
	# Create mail notification glow around cargo hold door
	var cargo_door_pos = object_positions.get("CargoHoldDoor", Vector2(1500, 0))

	mail_notification_glow = Node2D.new()
	mail_notification_glow.name = "MailNotificationGlow"
	mail_notification_glow.position = cargo_door_pos + Vector2(0, -40)

	# Outer glow (large, soft)
	var outer_glow = Polygon2D.new()
	outer_glow.name = "OuterGlow"
	outer_glow.polygon = PackedVector2Array([
		Vector2(-80, -120), Vector2(80, -120),
		Vector2(80, 80), Vector2(-80, 80)
	])
	outer_glow.color = Color(0.9, 0.7, 0.2, 0.0)  # Golden, starts invisible
	mail_notification_glow.add_child(outer_glow)

	# Inner glow (smaller, brighter)
	var inner_glow = Polygon2D.new()
	inner_glow.name = "InnerGlow"
	inner_glow.polygon = PackedVector2Array([
		Vector2(-65, -105), Vector2(65, -105),
		Vector2(65, 65), Vector2(-65, 65)
	])
	inner_glow.color = Color(1.0, 0.85, 0.3, 0.0)  # Brighter gold
	mail_notification_glow.add_child(inner_glow)

	# Mail icon indicator (envelope shape at top)
	var mail_icon = Polygon2D.new()
	mail_icon.name = "MailIcon"
	mail_icon.polygon = PackedVector2Array([
		Vector2(-15, -130), Vector2(15, -130),  # Top
		Vector2(15, -115), Vector2(0, -105),    # Right side + bottom point
		Vector2(-15, -115)                       # Left side
	])
	mail_icon.color = Color(1.0, 0.9, 0.4, 0.0)
	mail_notification_glow.add_child(mail_icon)

	# Add sparkles around the door
	for i in range(6):
		var sparkle = Polygon2D.new()
		sparkle.name = "Sparkle%d" % i
		var angle = (i / 6.0) * TAU
		var dist = 70.0
		sparkle.position = Vector2(cos(angle) * dist, sin(angle) * dist * 0.6 - 20)
		sparkle.polygon = PackedVector2Array([
			Vector2(0, -5), Vector2(3, 0), Vector2(0, 5), Vector2(-3, 0)
		])
		sparkle.color = Color(1.0, 0.85, 0.3, 0.0)
		mail_notification_glow.add_child(sparkle)

	mail_notification_glow.z_index = -1
	isometric_base.add_child(mail_notification_glow)

	# Connect to MailManager signals
	var mail_manager = get_node_or_null("/root/MailManager")
	if mail_manager:
		mail_manager.mail_count_changed.connect(_on_mail_count_changed)
		# Check initial state
		has_mail_waiting = mail_manager.has_mail()


func _on_mail_count_changed(count: int) -> void:
	has_mail_waiting = count > 0


func _animate_mail_notification() -> void:
	if not mail_notification_glow:
		return

	var outer = mail_notification_glow.get_node_or_null("OuterGlow") as Polygon2D
	var inner = mail_notification_glow.get_node_or_null("InnerGlow") as Polygon2D
	var icon = mail_notification_glow.get_node_or_null("MailIcon") as Polygon2D

	if has_mail_waiting:
		# Pulsing glow animation
		var pulse = (sin(animation_time * 2.5) + 1.0) / 2.0
		var slow_pulse = (sin(animation_time * 1.5) + 1.0) / 2.0

		if outer:
			outer.color.a = 0.08 + pulse * 0.06
		if inner:
			inner.color.a = 0.12 + pulse * 0.08
		if icon:
			icon.color.a = 0.6 + slow_pulse * 0.4
			# Gentle bounce
			icon.position.y = -130 + sin(animation_time * 3.0) * 3.0

		# Animate sparkles
		for i in range(6):
			var sparkle = mail_notification_glow.get_node_or_null("Sparkle%d" % i) as Polygon2D
			if sparkle:
				var phase = animation_time * 2.0 + (i * TAU / 6.0)
				var sparkle_pulse = (sin(phase) + 1.0) / 2.0
				sparkle.color.a = sparkle_pulse * 0.5
				sparkle.scale = Vector2(0.8 + sparkle_pulse * 0.4, 0.8 + sparkle_pulse * 0.4)
	else:
		# Fade out all elements
		if outer:
			outer.color.a = lerpf(outer.color.a, 0.0, 0.1)
		if inner:
			inner.color.a = lerpf(inner.color.a, 0.0, 0.1)
		if icon:
			icon.color.a = lerpf(icon.color.a, 0.0, 0.1)

		for i in range(6):
			var sparkle = mail_notification_glow.get_node_or_null("Sparkle%d" % i) as Polygon2D
			if sparkle:
				sparkle.color.a = lerpf(sparkle.color.a, 0.0, 0.1)


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


# =============================================================================
# HALLWAY SPACE VIEW
# =============================================================================

var space_view_panel: Control = null

func _show_hallway_space_view() -> void:
	if space_view_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false

	# Create fullscreen space view
	space_view_panel = Control.new()
	space_view_panel.name = "HallwaySpaceView"
	space_view_panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Dark background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.05, 0.98)
	space_view_panel.add_child(bg)

	# Star field
	var stars_container = Control.new()
	stars_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	space_view_panel.add_child(stars_container)

	var viewport_size = get_viewport_rect().size
	for i in range(150):
		var star = ColorRect.new()
		var size = randf_range(1, 3)
		star.custom_minimum_size = Vector2(size, size)
		star.size = Vector2(size, size)
		star.position = Vector2(randf() * viewport_size.x, randf() * viewport_size.y)
		star.color = Color(1, 1, randf_range(0.8, 1), randf_range(0.3, 0.9))
		stars_container.add_child(star)

	# Distant nebula
	var nebula = ColorRect.new()
	nebula.set_anchors_preset(Control.PRESET_CENTER)
	nebula.custom_minimum_size = Vector2(400, 200)
	nebula.position = Vector2(-200, -150)
	nebula.color = Color(0.3, 0.15, 0.4, 0.15)
	space_view_panel.add_child(nebula)

	# Passing comet/asteroid
	var comet = Polygon2D.new()
	comet.polygon = PackedVector2Array([
		Vector2(-80, 0), Vector2(0, -8), Vector2(20, 0), Vector2(0, 8)
	])
	comet.color = Color(0.6, 0.7, 0.8, 0.6)
	comet.position = Vector2(viewport_size.x * 0.3, viewport_size.y * 0.4)
	space_view_panel.add_child(comet)

	# Text overlay
	var text_container = VBoxContainer.new()
	text_container.set_anchors_preset(Control.PRESET_CENTER)
	text_container.offset_left = -200
	text_container.offset_right = 200
	text_container.offset_top = 150
	text_container.offset_bottom = 300
	space_view_panel.add_child(text_container)

	var title = Label.new()
	title.text = "The Void Between Stars"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_container.add_child(title)

	var desc = Label.new()
	desc.text = "Endless darkness stretches in every direction.\nThe nearest star system is light-years away.\n\nYet somewhere out there, Earth waits."
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_container.add_child(desc)

	# Close hint
	var hint = Label.new()
	hint.text = "\n[Press SPACE or ESC to close]"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_container.add_child(hint)

	add_child(space_view_panel)


func _close_hallway_space_view() -> void:
	if space_view_panel:
		space_view_panel.queue_free()
		space_view_panel = null
	in_dialogue = false


# =============================================================================
# DETAIL VIEW PANELS (Split Graphics)
# =============================================================================

var plant_detail_panel: Control = null
var plant_detail_time: float = 0.0
var plant_vines: Array = []

var family_portrait_panel: Control = null
var portrait_detail_time: float = 0.0

var landscape_detail_panel: Control = null
var landscape_detail_time: float = 0.0


# -----------------------------------------------------------------------------
# STELLAR IVY (Corridor Plant) Detail View
# -----------------------------------------------------------------------------

func _show_plant_detail() -> void:
	if plant_detail_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false
	plant_detail_time = 0.0
	plant_vines.clear()

	# Play voice
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_voice_from_path"):
		audio.play_voice_from_path("res://audio/voice/hallway/plant.ogg")

	plant_detail_panel = Control.new()
	plant_detail_panel.name = "PlantDetailView"
	plant_detail_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	plant_detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(plant_detail_panel)

	# Dark background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.05, 0.08, 0.98)
	plant_detail_panel.add_child(bg)

	var viewport_size = get_viewport_rect().size

	# Plant display (left side)
	var plant_display = Node2D.new()
	plant_display.name = "PlantDisplay"
	plant_display.position = Vector2(viewport_size.x * 0.32, viewport_size.y * 0.6)
	plant_display.scale = Vector2(3.0, 3.0)
	plant_detail_panel.add_child(plant_display)

	# Create the pot
	_create_stellar_ivy_pot(plant_display)

	# Create the vines
	_create_stellar_ivy_vines(plant_display)

	# Create floating spores
	_create_stellar_ivy_spores(plant_display)

	# Text panel (right side)
	var text_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.9)
	style.border_color = Color(0.3, 0.5, 0.4, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	text_panel.add_theme_stylebox_override("panel", style)
	text_panel.set_anchors_preset(Control.PRESET_CENTER)
	text_panel.offset_left = 150
	text_panel.offset_right = 500
	text_panel.offset_top = -180
	text_panel.offset_bottom = 180
	plant_detail_panel.add_child(text_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	text_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Stellar Ivy"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Goactorian Flora - Luminescent Variety"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.65, 0.55))
	vbox.add_child(subtitle)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Description
	var desc = Label.new()
	desc.text = "A hardy Stellar Ivy that thrives in artificial light. It's been growing in this corridor since before you were born.\n\nThe bioluminescent tips glow softly in the ship's dim lighting, releasing tiny spores that float through the air.\n\nMom waters it every cycle without fail. She says it reminds her of the hanging gardens back home."
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.75, 0.8, 0.75))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 45)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_plant_detail)
	plant_detail_panel.add_child(close_btn)
	close_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	close_btn.offset_left = -160
	close_btn.offset_right = -40
	close_btn.offset_top = -70
	close_btn.offset_bottom = -25

	# Close hint
	var hint = Label.new()
	hint.text = "[SPACE or ESC to close]"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.4, 0.5, 0.45))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.offset_left = 30
	hint.offset_top = -40
	hint.offset_bottom = -20
	plant_detail_panel.add_child(hint)

	# Fade in
	plant_detail_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(plant_detail_panel, "modulate:a", 1.0, 0.5)


func _create_stellar_ivy_pot(parent: Node2D) -> void:
	# Pot body
	var pot = Polygon2D.new()
	pot.polygon = PackedVector2Array([
		Vector2(-25, 0), Vector2(25, 0),
		Vector2(20, 35), Vector2(-20, 35)
	])
	pot.color = Color(0.35, 0.25, 0.2)
	parent.add_child(pot)

	# Pot rim
	var rim = Polygon2D.new()
	rim.polygon = PackedVector2Array([
		Vector2(-28, -5), Vector2(28, -5),
		Vector2(26, 2), Vector2(-26, 2)
	])
	rim.color = Color(0.45, 0.35, 0.28)
	parent.add_child(rim)

	# Soil
	var soil = Polygon2D.new()
	soil.polygon = PackedVector2Array([
		Vector2(-22, 0), Vector2(22, 0),
		Vector2(20, 8), Vector2(-20, 8)
	])
	soil.color = Color(0.2, 0.15, 0.1)
	parent.add_child(soil)


func _create_stellar_ivy_vines(parent: Node2D) -> void:
	plant_vines.clear()

	# Create multiple cascading vines
	var vine_data = [
		{"start": Vector2(-15, -5), "segments": 8, "angle": -0.4, "color": Color(0.25, 0.5, 0.35)},
		{"start": Vector2(-5, -8), "segments": 10, "angle": -0.1, "color": Color(0.3, 0.55, 0.38)},
		{"start": Vector2(5, -7), "segments": 9, "angle": 0.15, "color": Color(0.28, 0.52, 0.36)},
		{"start": Vector2(15, -5), "segments": 7, "angle": 0.35, "color": Color(0.25, 0.48, 0.33)},
		{"start": Vector2(-10, -6), "segments": 6, "angle": -0.25, "color": Color(0.32, 0.58, 0.4)},
		{"start": Vector2(10, -6), "segments": 6, "angle": 0.25, "color": Color(0.27, 0.5, 0.35)},
	]

	for data in vine_data:
		var vine_container = Node2D.new()
		vine_container.position = data["start"]
		parent.add_child(vine_container)

		var segments = []
		var current_pos = Vector2.ZERO
		var current_angle = data["angle"]

		for i in range(data["segments"]):
			# Vine segment
			var segment = Polygon2D.new()
			var seg_length = 12 + randf() * 4
			var next_pos = current_pos + Vector2(sin(current_angle), -cos(current_angle)) * seg_length

			# Tapered segment
			var thickness = 4 - (i * 0.3)
			segment.polygon = PackedVector2Array([
				current_pos + Vector2(-thickness, 0),
				current_pos + Vector2(thickness, 0),
				next_pos + Vector2(thickness * 0.7, 0),
				next_pos + Vector2(-thickness * 0.7, 0)
			])
			segment.color = data["color"]
			vine_container.add_child(segment)
			segments.append(segment)

			# Add leaves at intervals
			if i % 2 == 1:
				var leaf = _create_ivy_leaf(next_pos, current_angle + randf_range(-0.3, 0.3))
				vine_container.add_child(leaf)

			# Add glowing tip at end
			if i == data["segments"] - 1:
				var tip_glow = Polygon2D.new()
				tip_glow.name = "TipGlow"
				var tip_size = 5
				tip_glow.polygon = _create_circle_points(tip_size, 8)
				tip_glow.position = next_pos
				tip_glow.color = Color(0.5, 0.9, 0.6, 0.7)
				vine_container.add_child(tip_glow)

			current_pos = next_pos
			current_angle += randf_range(-0.2, 0.2)

		plant_vines.append({
			"container": vine_container,
			"base_angle": data["angle"],
			"phase": randf() * TAU
		})


func _create_ivy_leaf(pos: Vector2, angle: float) -> Polygon2D:
	var leaf = Polygon2D.new()
	leaf.position = pos
	leaf.rotation = angle

	# Heart-shaped ivy leaf
	leaf.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(-6, -4),
		Vector2(-8, -10),
		Vector2(-4, -14),
		Vector2(0, -12),
		Vector2(4, -14),
		Vector2(8, -10),
		Vector2(6, -4)
	])
	leaf.color = Color(0.2, 0.45, 0.3, 0.9)
	return leaf


func _create_stellar_ivy_spores(parent: Node2D) -> void:
	# Floating bioluminescent spores
	for i in range(15):
		var spore = Polygon2D.new()
		spore.name = "Spore" + str(i)
		var size = randf_range(2, 4)
		spore.polygon = _create_circle_points(size, 6)
		spore.position = Vector2(randf_range(-50, 50), randf_range(-80, -10))
		spore.color = Color(0.5, 0.95, 0.65, randf_range(0.3, 0.6))
		parent.add_child(spore)


func _create_circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(segments):
		var angle = (i / float(segments)) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _close_plant_detail() -> void:
	if not plant_detail_panel:
		return

	var tween = create_tween()
	tween.tween_property(plant_detail_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_cleanup_plant_detail)


func _cleanup_plant_detail() -> void:
	if plant_detail_panel:
		plant_detail_panel.queue_free()
		plant_detail_panel = null
	plant_vines.clear()
	in_dialogue = false


# -----------------------------------------------------------------------------
# FAMILY PORTRAIT Detail View
# -----------------------------------------------------------------------------

func _show_family_portrait_detail() -> void:
	if family_portrait_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false
	portrait_detail_time = 0.0

	# Play voice
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_voice_from_path"):
		audio.play_voice_from_path("res://audio/voice/hallway/painting_family.ogg")

	family_portrait_panel = Control.new()
	family_portrait_panel.name = "FamilyPortraitView"
	family_portrait_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	family_portrait_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(family_portrait_panel)

	# Dark background with warm tint
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.04, 0.06, 0.98)
	family_portrait_panel.add_child(bg)

	var viewport_size = get_viewport_rect().size

	# Portrait display (left side)
	var portrait_display = Node2D.new()
	portrait_display.name = "PortraitDisplay"
	portrait_display.position = Vector2(viewport_size.x * 0.32, viewport_size.y * 0.5)
	portrait_display.scale = Vector2(2.5, 2.5)
	family_portrait_panel.add_child(portrait_display)

	# Create the holographic frame
	_create_portrait_frame(portrait_display)

	# Create the family figures
	_create_family_figures(portrait_display)

	# Create holographic particles
	_create_portrait_particles(portrait_display)

	# Text panel (right side)
	var text_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.1, 0.9)
	style.border_color = Color(0.6, 0.5, 0.4, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	text_panel.add_theme_stylebox_override("panel", style)
	text_panel.set_anchors_preset(Control.PRESET_CENTER)
	text_panel.offset_left = 150
	text_panel.offset_right = 500
	text_panel.offset_top = -200
	text_panel.offset_bottom = 200
	family_portrait_panel.add_child(text_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	text_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Family Portrait"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5))
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Holographic Memory Capture - Year 2847"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	vbox.add_child(subtitle)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Description
	var desc = Label.new()
	desc.text = "A holographic family portrait from when you were just a hatchling.\n\nMom stands tall and proud, her wings shimmering with the iridescence of a seasoned explorer. Dad's gentle smile hasn't changed in all these years.\n\nGreat-Elder Zyx towers behind you all, ancient and wise, the crystalline patterns on their scales catching the light.\n\nAnd there you are - tiny you with your first pair of wings, barely able to flutter.\n\nThose were simpler times."
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.8, 0.78, 0.75))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 45)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_family_portrait_detail)
	family_portrait_panel.add_child(close_btn)
	close_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	close_btn.offset_left = -160
	close_btn.offset_right = -40
	close_btn.offset_top = -70
	close_btn.offset_bottom = -25

	# Close hint
	var hint = Label.new()
	hint.text = "[SPACE or ESC to close]"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.offset_left = 30
	hint.offset_top = -40
	hint.offset_bottom = -20
	family_portrait_panel.add_child(hint)

	# Fade in
	family_portrait_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(family_portrait_panel, "modulate:a", 1.0, 0.5)


func _create_portrait_frame(parent: Node2D) -> void:
	# Ornate holographic frame
	var frame_outer = Polygon2D.new()
	frame_outer.polygon = PackedVector2Array([
		Vector2(-75, -95), Vector2(75, -95),
		Vector2(75, 75), Vector2(-75, 75)
	])
	frame_outer.color = Color(0.5, 0.4, 0.3, 0.8)
	parent.add_child(frame_outer)

	# Inner frame border
	var frame_inner = Polygon2D.new()
	frame_inner.polygon = PackedVector2Array([
		Vector2(-70, -90), Vector2(70, -90),
		Vector2(70, 70), Vector2(-70, 70)
	])
	frame_inner.color = Color(0.6, 0.5, 0.35, 0.6)
	parent.add_child(frame_inner)

	# Portrait background (holographic blue tint)
	var portrait_bg = Polygon2D.new()
	portrait_bg.polygon = PackedVector2Array([
		Vector2(-65, -85), Vector2(65, -85),
		Vector2(65, 65), Vector2(-65, 65)
	])
	portrait_bg.color = Color(0.15, 0.2, 0.3, 0.9)
	parent.add_child(portrait_bg)

	# Frame corner decorations
	for corner in [Vector2(-75, -95), Vector2(75, -95), Vector2(75, 75), Vector2(-75, 75)]:
		var decoration = Polygon2D.new()
		decoration.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(10, 5), Vector2(5, 10), Vector2(-5, 10), Vector2(-10, 5)
		])
		decoration.position = corner
		decoration.color = Color(0.7, 0.6, 0.4, 0.9)
		parent.add_child(decoration)


func _create_family_figures(parent: Node2D) -> void:
	# Great-Elder Zyx (back center, tall)
	var elder = _create_goactorian_figure(Vector2(0, -40), 1.3, Color(0.5, 0.55, 0.7), true)
	parent.add_child(elder)

	# Mom (left)
	var mom = _create_goactorian_figure(Vector2(-35, -10), 1.0, Color(0.6, 0.5, 0.65))
	parent.add_child(mom)

	# Dad (right)
	var dad = _create_goactorian_figure(Vector2(35, -10), 1.0, Color(0.5, 0.6, 0.55))
	parent.add_child(dad)

	# Baby Goacto (front center, small)
	var baby = _create_goactorian_figure(Vector2(0, 25), 0.5, Color(0.55, 0.6, 0.75))
	parent.add_child(baby)


func _create_goactorian_figure(pos: Vector2, scale_factor: float, tint: Color, has_crystals: bool = false) -> Node2D:
	var figure = Node2D.new()
	figure.position = pos
	figure.scale = Vector2(scale_factor, scale_factor)

	# Body
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-12, 0), Vector2(12, 0),
		Vector2(10, 35), Vector2(-10, 35)
	])
	body.color = tint
	figure.add_child(body)

	# Head
	var head = Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(-10, -25), Vector2(10, -25),
		Vector2(12, -5), Vector2(-12, -5)
	])
	head.color = Color(tint.r + 0.1, tint.g + 0.1, tint.b + 0.1)
	figure.add_child(head)

	# Eyes
	for x_offset in [-5, 5]:
		var eye = Polygon2D.new()
		eye.polygon = _create_circle_points(3, 6)
		eye.position = Vector2(x_offset, -15)
		eye.color = Color(0.9, 0.85, 0.5, 0.9)
		figure.add_child(eye)

	# Wings
	for side in [-1, 1]:
		var wing = Polygon2D.new()
		wing.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(side * 25, -15),
			Vector2(side * 30, -5), Vector2(side * 20, 10)
		])
		wing.position = Vector2(side * 8, 5)
		wing.color = Color(tint.r, tint.g, tint.b + 0.15, 0.6)
		figure.add_child(wing)

	# Elder crystals
	if has_crystals:
		for i in range(3):
			var crystal = Polygon2D.new()
			crystal.polygon = PackedVector2Array([
				Vector2(0, -8), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0)
			])
			crystal.position = Vector2(-8 + i * 8, -30)
			crystal.color = Color(0.6, 0.7, 0.9, 0.8)
			figure.add_child(crystal)

	return figure


func _create_portrait_particles(parent: Node2D) -> void:
	# Holographic scan lines and particles
	for i in range(12):
		var particle = Polygon2D.new()
		particle.name = "HoloParticle" + str(i)
		var size = randf_range(1, 3)
		particle.polygon = _create_circle_points(size, 4)
		particle.position = Vector2(randf_range(-60, 60), randf_range(-80, 60))
		particle.color = Color(0.5, 0.6, 0.9, randf_range(0.2, 0.5))
		parent.add_child(particle)


func _close_family_portrait_detail() -> void:
	if not family_portrait_panel:
		return

	var tween = create_tween()
	tween.tween_property(family_portrait_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_cleanup_family_portrait_detail)


func _cleanup_family_portrait_detail() -> void:
	if family_portrait_panel:
		family_portrait_panel.queue_free()
		family_portrait_panel = null
	in_dialogue = false


# -----------------------------------------------------------------------------
# GOACTORIAN LANDSCAPE Detail View
# -----------------------------------------------------------------------------

func _show_landscape_detail() -> void:
	if landscape_detail_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false
	landscape_detail_time = 0.0

	# Play voice
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_voice_from_path"):
		audio.play_voice_from_path("res://audio/voice/hallway/painting_landscape.ogg")

	landscape_detail_panel = Control.new()
	landscape_detail_panel.name = "LandscapeDetailView"
	landscape_detail_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	landscape_detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(landscape_detail_panel)

	# Dark background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.03, 0.06, 0.98)
	landscape_detail_panel.add_child(bg)

	var viewport_size = get_viewport_rect().size

	# Landscape display (left side)
	var landscape_display = Node2D.new()
	landscape_display.name = "LandscapeDisplay"
	landscape_display.position = Vector2(viewport_size.x * 0.32, viewport_size.y * 0.5)
	landscape_display.scale = Vector2(2.2, 2.2)
	landscape_detail_panel.add_child(landscape_display)

	# Create the painting frame
	_create_landscape_frame(landscape_display)

	# Create the landscape scene
	_create_crystal_valleys(landscape_display)

	# Create glowing particles
	_create_landscape_particles(landscape_display)

	# Text panel (right side)
	var text_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.9)
	style.border_color = Color(0.5, 0.4, 0.6, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	text_panel.add_theme_stylebox_override("panel", style)
	text_panel.set_anchors_preset(Control.PRESET_CENTER)
	text_panel.offset_left = 150
	text_panel.offset_right = 500
	text_panel.offset_top = -200
	text_panel.offset_bottom = 200
	landscape_detail_panel.add_child(text_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	text_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Crystal Valleys of Goactora"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Traditional Goactorian Rendering - Artist Unknown"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.55, 0.5, 0.65))
	vbox.add_child(subtitle)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Description
	var desc = Label.new()
	desc.text = "A beautiful rendering of the Crystal Valleys back home.\n\nThe bioluminescent forests glow in shades of purple and teal, casting ethereal light across the crystalline formations that gave the valleys their name.\n\nAt dusk, the twin moons rise over the peaks, and the whole landscape comes alive with color.\n\nEvery Goactorian child grows up playing in those glowing groves, chasing light-moths and collecting prismatic pebbles.\n\nYou'll see them again... in 47 years."
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.78, 0.75, 0.85))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 45)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_landscape_detail)
	landscape_detail_panel.add_child(close_btn)
	close_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	close_btn.offset_left = -160
	close_btn.offset_right = -40
	close_btn.offset_top = -70
	close_btn.offset_bottom = -25

	# Close hint
	var hint = Label.new()
	hint.text = "[SPACE or ESC to close]"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.45, 0.4, 0.55))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.offset_left = 30
	hint.offset_top = -40
	hint.offset_bottom = -20
	landscape_detail_panel.add_child(hint)

	# Fade in
	landscape_detail_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(landscape_detail_panel, "modulate:a", 1.0, 0.5)


func _create_landscape_frame(parent: Node2D) -> void:
	# Elegant frame
	var frame = Polygon2D.new()
	frame.polygon = PackedVector2Array([
		Vector2(-90, -70), Vector2(90, -70),
		Vector2(90, 70), Vector2(-90, 70)
	])
	frame.color = Color(0.3, 0.25, 0.35, 0.9)
	parent.add_child(frame)

	# Inner border
	var inner = Polygon2D.new()
	inner.polygon = PackedVector2Array([
		Vector2(-85, -65), Vector2(85, -65),
		Vector2(85, 65), Vector2(-85, 65)
	])
	inner.color = Color(0.4, 0.35, 0.5, 0.7)
	parent.add_child(inner)

	# Sky background
	var sky = Polygon2D.new()
	sky.polygon = PackedVector2Array([
		Vector2(-80, -60), Vector2(80, -60),
		Vector2(80, 60), Vector2(-80, 60)
	])
	sky.color = Color(0.08, 0.1, 0.2)
	parent.add_child(sky)


func _create_crystal_valleys(parent: Node2D) -> void:
	# Mountains in background
	var mountains = Polygon2D.new()
	mountains.polygon = PackedVector2Array([
		Vector2(-80, 20), Vector2(-50, -30), Vector2(-20, -10),
		Vector2(10, -45), Vector2(40, -15), Vector2(70, -35), Vector2(80, 20)
	])
	mountains.color = Color(0.2, 0.15, 0.3)
	parent.add_child(mountains)

	# Crystal formations
	var crystal_positions = [
		Vector2(-60, 10), Vector2(-35, 5), Vector2(-10, 15),
		Vector2(20, 8), Vector2(45, 12), Vector2(65, 5)
	]

	for pos in crystal_positions:
		var crystal = Polygon2D.new()
		var height = randf_range(20, 40)
		var width = randf_range(8, 15)
		crystal.polygon = PackedVector2Array([
			Vector2(0, -height), Vector2(width/2, 0), Vector2(-width/2, 0)
		])
		crystal.position = pos
		crystal.color = Color(0.5, 0.4, 0.7, 0.8)
		parent.add_child(crystal)

		# Crystal glow
		var glow = Polygon2D.new()
		glow.polygon = PackedVector2Array([
			Vector2(0, -height - 5), Vector2(width/2 + 3, 3), Vector2(-width/2 - 3, 3)
		])
		glow.position = pos
		glow.color = Color(0.6, 0.5, 0.9, 0.25)
		parent.add_child(glow)

	# Bioluminescent forest
	for i in range(12):
		var tree = Node2D.new()
		tree.position = Vector2(randf_range(-70, 70), randf_range(25, 55))
		parent.add_child(tree)

		# Tree trunk
		var trunk = Polygon2D.new()
		trunk.polygon = PackedVector2Array([
			Vector2(-3, 0), Vector2(3, 0), Vector2(2, -20), Vector2(-2, -20)
		])
		trunk.color = Color(0.25, 0.2, 0.3)
		tree.add_child(trunk)

		# Glowing canopy
		var canopy = Polygon2D.new()
		canopy.polygon = _create_circle_points(randf_range(10, 18), 8)
		canopy.position = Vector2(0, -25)
		# Alternate between purple and teal
		if i % 2 == 0:
			canopy.color = Color(0.5, 0.3, 0.6, 0.7)
		else:
			canopy.color = Color(0.2, 0.5, 0.5, 0.7)
		tree.add_child(canopy)

	# Twin moons
	var moon1 = Polygon2D.new()
	moon1.polygon = _create_circle_points(12, 16)
	moon1.position = Vector2(50, -45)
	moon1.color = Color(0.9, 0.85, 0.7, 0.9)
	parent.add_child(moon1)

	var moon2 = Polygon2D.new()
	moon2.polygon = _create_circle_points(8, 12)
	moon2.position = Vector2(35, -38)
	moon2.color = Color(0.7, 0.75, 0.9, 0.8)
	parent.add_child(moon2)

	# Ground
	var ground = Polygon2D.new()
	ground.polygon = PackedVector2Array([
		Vector2(-80, 60), Vector2(80, 60),
		Vector2(80, 45), Vector2(-80, 50)
	])
	ground.color = Color(0.15, 0.12, 0.2)
	parent.add_child(ground)


func _create_landscape_particles(parent: Node2D) -> void:
	# Floating light particles (light-moths)
	for i in range(20):
		var particle = Polygon2D.new()
		particle.name = "LightMoth" + str(i)
		var size = randf_range(1.5, 3)
		particle.polygon = _create_circle_points(size, 5)
		particle.position = Vector2(randf_range(-75, 75), randf_range(-55, 55))
		# Alternate colors
		if i % 3 == 0:
			particle.color = Color(0.6, 0.4, 0.8, randf_range(0.3, 0.6))
		elif i % 3 == 1:
			particle.color = Color(0.3, 0.7, 0.6, randf_range(0.3, 0.6))
		else:
			particle.color = Color(0.8, 0.7, 0.4, randf_range(0.3, 0.6))
		parent.add_child(particle)


func _close_landscape_detail() -> void:
	if not landscape_detail_panel:
		return

	var tween = create_tween()
	tween.tween_property(landscape_detail_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_cleanup_landscape_detail)


func _cleanup_landscape_detail() -> void:
	if landscape_detail_panel:
		landscape_detail_panel.queue_free()
		landscape_detail_panel = null
	in_dialogue = false


# -----------------------------------------------------------------------------
# DETAIL VIEW ANIMATIONS (called from _process)
# -----------------------------------------------------------------------------

func _update_detail_views(delta: float) -> void:
	if plant_detail_panel:
		_update_plant_detail(delta)
	if family_portrait_panel:
		_update_portrait_detail(delta)
	if landscape_detail_panel:
		_update_landscape_detail(delta)


func _update_plant_detail(delta: float) -> void:
	plant_detail_time += delta

	var display = plant_detail_panel.get_node_or_null("PlantDisplay")
	if not display:
		return

	# Animate vines swaying
	for vine_data in plant_vines:
		var container = vine_data["container"] as Node2D
		if container:
			var sway = sin(plant_detail_time * 1.5 + vine_data["phase"]) * 0.08
			container.rotation = vine_data["base_angle"] * 0.1 + sway

	# Animate spores floating
	for i in range(15):
		var spore = display.get_node_or_null("Spore" + str(i))
		if spore:
			spore.position.y += sin(plant_detail_time * 2.0 + i * 0.5) * delta * 3
			spore.position.x += cos(plant_detail_time * 1.2 + i * 0.7) * delta * 2
			spore.color.a = 0.35 + sin(plant_detail_time * 3.0 + i) * 0.25

	# Animate glowing tips
	for vine_data in plant_vines:
		var container = vine_data["container"] as Node2D
		if container:
			for child in container.get_children():
				if child.name == "TipGlow":
					child.color.a = 0.5 + sin(plant_detail_time * 4.0 + vine_data["phase"]) * 0.3


func _update_portrait_detail(delta: float) -> void:
	portrait_detail_time += delta

	var display = family_portrait_panel.get_node_or_null("PortraitDisplay")
	if not display:
		return

	# Animate holographic particles
	for i in range(12):
		var particle = display.get_node_or_null("HoloParticle" + str(i))
		if particle:
			# Drift upward slowly
			particle.position.y -= delta * 5
			if particle.position.y < -85:
				particle.position.y = 65
				particle.position.x = randf_range(-60, 60)

			# Pulse alpha
			particle.color.a = 0.25 + sin(portrait_detail_time * 2.5 + i * 0.8) * 0.2

			# Slight horizontal drift
			particle.position.x += sin(portrait_detail_time + i) * delta * 2


func _update_landscape_detail(delta: float) -> void:
	landscape_detail_time += delta

	var display = landscape_detail_panel.get_node_or_null("LandscapeDisplay")
	if not display:
		return

	# Animate light-moths
	for i in range(20):
		var moth = display.get_node_or_null("LightMoth" + str(i))
		if moth:
			# Gentle floating movement
			moth.position.x += sin(landscape_detail_time * 1.5 + i * 0.6) * delta * 8
			moth.position.y += cos(landscape_detail_time * 1.2 + i * 0.8) * delta * 6

			# Wrap around
			if moth.position.x > 80:
				moth.position.x = -80
			elif moth.position.x < -80:
				moth.position.x = 80

			# Pulse
			moth.color.a = 0.3 + sin(landscape_detail_time * 3.5 + i * 0.5) * 0.25
