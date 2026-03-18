extends Control
## Mindscape Hub - Central area connecting to all regions
## Contains Focus Chamber, Daily Rituals, and 4 region portals

# Game world
@onready var game_world: Control = $GameWorld
@onready var isometric_base: Node2D = $GameWorld/IsometricBase
@onready var player: Node2D = $GameWorld/IsometricBase/Player

# Zone references
@onready var focus_chamber: Node2D = $GameWorld/IsometricBase/Zones/FocusChamber
@onready var daily_rituals: Node2D = $GameWorld/IsometricBase/Zones/DailyRituals
@onready var reflection_pool: Node2D = $GameWorld/IsometricBase/Zones/ReflectionPool

# Portal references
@onready var portals_node: Node2D = $GameWorld/IsometricBase/Portals
@onready var north_portal: Node2D = $GameWorld/IsometricBase/Portals/NorthPortal
@onready var east_portal: Node2D = $GameWorld/IsometricBase/Portals/EastPortal
@onready var west_portal: Node2D = $GameWorld/IsometricBase/Portals/WestPortal
@onready var south_portal: Node2D = $GameWorld/IsometricBase/Portals/SouthPortal

# Exit crystal
@onready var center_crystal: Polygon2D = $GameWorld/IsometricBase/CenterStructure/Crystal
@onready var crystal_glow: Polygon2D = $GameWorld/IsometricBase/CenterStructure/CrystalGlow

# UI
@onready var interaction_prompt: PanelContainer = $InteractionPrompt
@onready var zone_name_label: Label = $InteractionPrompt/Margin/VBox/ZoneName
@onready var prompt_text_label: Label = $InteractionPrompt/Margin/VBox/PromptText
@onready var control_hints: HBoxContainer = $ControlHints

# Zone panel (1/3 - 2/3 layout)
@onready var zone_panel: PanelContainer = $ZonePanel
@onready var zone_title: Label = $ZonePanel/HBoxLayout/MenuSection/Margin/ZoneContent/ZoneHeader/ZoneTitle
@onready var zone_body: VBoxContainer = $ZonePanel/HBoxLayout/MenuSection/Margin/ZoneContent/ZoneBody/ZoneBodyContent
@onready var back_button: Button = $ZonePanel/HBoxLayout/MenuSection/Margin/ZoneContent/ZoneHeader/BackButton
@onready var zone_graphic_container: Control = $ZonePanel/HBoxLayout/GraphicSection/GraphicContainer

# Header
@onready var save_indicator: Label = $Header/Margin/HBox/SaveIndicator
@onready var evolution_label: Label = $Header/Margin/HBox/EvolutionContainer/EvolutionLabel
@onready var evolution_bar: ProgressBar = $Header/Margin/HBox/EvolutionContainer/EvolutionBar
@onready var greeting_label: Label = $Header/Margin/HBox/GreetingLabel
@onready var date_label: Label = $Header/Margin/HBox/DateLabel
@onready var menu_button: Button = $Header/Margin/HBox/MenuButton
@onready var habits_today_label: Label = $Header/Margin/HBox/DailyProgress/HabitsToday
@onready var focus_today_label: Label = $Header/Margin/HBox/DailyProgress/FocusToday
@onready var streaks_label: Label = $Header/Margin/HBox/DailyProgress/StreaksLabel

# Dialogue
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var speaker_name: Label = $DialoguePanel/Margin/VBox/SpeakerName
@onready var dialogue_text: Label = $DialoguePanel/Margin/VBox/DialogueText
@onready var dialogue_continue: Button = $DialoguePanel/Margin/VBox/ContinueButton

# Pause Menu
@onready var pause_menu: PanelContainer = $PauseMenu
@onready var close_menu_button: Button = $PauseMenu/Margin/VBox/MenuHeader/CloseMenuButton
@onready var menu_body: VBoxContainer = $PauseMenu/Margin/VBox/MenuScroll/MenuBody
@onready var character_tab: Button = $PauseMenu/Margin/VBox/MenuTabs/CharacterTab
@onready var aspects_tab: Button = $PauseMenu/Margin/VBox/MenuTabs/AspectsTab
@onready var progress_tab: Button = $PauseMenu/Margin/VBox/MenuTabs/ProgressTab
@onready var settings_tab: Button = $PauseMenu/Margin/VBox/MenuTabs/SettingsTab

# Menu state
var current_menu_tab: String = "character"

# Header controls
var volume_button: Button = null
var volume_popup: PanelContainer = null
var is_muted: bool = false

# Player movement
var player_speed: float = 320.0
# Diamond platform bounds (half-widths) - expanded 65% for more exploration
var platform_half_width: float = 1400.0  # X extent
var platform_half_height: float = 700.0  # Y extent

# Camera/zoom
var camera_zoom: float = 1.0
var min_zoom: float = 0.4  # Allow more zoom out
var max_zoom: float = 1.5
var zoom_speed: float = 0.08

# Interaction state
var nearby_zone: String = ""
var nearby_portal: String = ""
var near_exit_crystal: bool = false
var in_zone_panel: bool = false
var current_journal_tab: String = "focus"

# Exit crystal position
const EXIT_CRYSTAL_POSITION = Vector2(0, -60)
const EXIT_CRYSTAL_RADIUS = 80.0
const INTERACTION_RADIUS = 120.0

# Proximity detection
var zone_positions: Dictionary = {}
var portal_positions: Dictionary = {}

# Animation
var crystal_pulse_time: float = 0.0

# Movement sound
var move_sound_timer: float = 0.0
var move_sound_interval: float = 0.35

# Progress indicators
var progress_container: Node2D = null
var streak_flames: Array = []
var evolution_ring: Node2D = null
var evolution_segments: Array = []
var garden_patches: Array = []

# Companion spirit
var companion_spirit: Node2D = null
var companion_tip_timer: float = 0.0
var companion_tip_cooldown: float = 30.0  # Show tip every 30 seconds
var companion_enabled: bool = true
var current_tip_bubble: Control = null
var is_onboarding_active: bool = false  # Prevent tips during onboarding

# Mini-map
var minimap_container: Control = null
var minimap_player_dot: Polygon2D = null
var minimap_scale: float = 0.08  # Scale from world to minimap

# Center status panel
var center_status_panel: PanelContainer = null
var is_near_center: bool = false

# Lore stones
var lore_stone_positions: Dictionary = {
	"LoreStone1": Vector2(-950, -150),
	"LoreStone2": Vector2(900, 300),
	"LoreStone3": Vector2(-800, 400)
}
var discovered_lore: Array = []

# Habit journal note dialog
var habit_note_dialog: PanelContainer = null
var pending_habit_id: String = ""
var habit_note_input: TextEdit = null

# Daily summary panel
var daily_summary_panel: PanelContainer = null

# Zone name mapping
var zone_names: Dictionary = {
	"FocusChamber": "Focus Chamber",
	"DailyRituals": "Daily Rituals",
	"ReflectionPool": "Reflection Pool",
	"ExperienceShop": "Experience Shop",
	"LoreStone1": "Ancient Stone",
	"LoreStone2": "Weathered Monument",
	"LoreStone3": "Mystical Rune"
}

# Portal names
var portal_names: Dictionary = {
	"NorthPortal": "Northern Gardens",
	"EastPortal": "Eastern Observatory",
	"WestPortal": "Western Depths",
	"SouthPortal": "Southern Peaks"
}

# Portal to region mapping
var portal_to_region: Dictionary = {
	"NorthPortal": "north",
	"EastPortal": "east",
	"WestPortal": "west",
	"SouthPortal": "south"
}

# Enhanced portal visuals
var portal_particles: Dictionary = {}  # portal_name -> array of particle data
var portal_energy_rings: Dictionary = {}  # portal_name -> array of ring polygons
var portal_decorations: Dictionary = {}  # portal_name -> array of decoration nodes
var portal_anim_time: float = 0.0


func _ready() -> void:
	# Connect UI
	back_button.pressed.connect(_close_zone)
	dialogue_continue.pressed.connect(_close_dialogue)

	# Play mindscape music and ambient sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		if audio.has_method("play_music_mindscape"):
			audio.play_music_mindscape()
		if audio.has_method("play_ambient_mindscape"):
			audio.play_ambient_mindscape()

	# Connect menu
	menu_button.pressed.connect(_open_pause_menu)
	close_menu_button.pressed.connect(_close_pause_menu)

	# Setup header controls (volume, save indicator)
	_setup_header_controls()

	# Add keyboard shortcut tooltips to header
	menu_button.tooltip_text = "Open Menu (P)"
	habits_today_label.tooltip_text = "Press H for Habits"
	focus_today_label.tooltip_text = "Press F for Focus Chamber"
	streaks_label.tooltip_text = "Press E for Daily Summary"

	# Connect menu tabs
	character_tab.pressed.connect(_show_character_tab)
	aspects_tab.pressed.connect(_show_aspects_tab)
	progress_tab.pressed.connect(_show_progress_tab)
	settings_tab.pressed.connect(_show_settings_tab)

	# Setup zone interactions
	_setup_zone_interactions()
	_setup_portal_interactions()

	# Setup progress indicators (streak flames, evolution ring)
	_setup_progress_indicators()

	# Position player based on where we came from
	_position_player_from_transition()

	# Initialize
	_update_header()
	_update_portal_visuals()
	_center_base()

	# Re-center when window resizes
	get_tree().root.size_changed.connect(_center_base)

	GameManager.change_state(GameManager.GameState.MINDSCAPE)

	# Connect to achievement unlocks
	if AchievementManager:
		AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

	# Show onboarding for first-time mindscape entry
	if not GameManager.player_data.get("has_completed_onboarding", false):
		_show_mindscape_onboarding()
	else:
		# Show tutorial tooltips for returning players who haven't seen them
		_check_tutorial_tooltips()

	# Setup progress indicators
	_setup_progress_indicators()
	_setup_lore_stones()
	_setup_achievement_pedestals()
	_setup_companion_spirit()
	_setup_minimap()

	# Create enhanced visuals
	_create_enhanced_hub_environment()
	_create_enhanced_portals()

	# Setup evolution stages (visual changes based on evolution level)
	_setup_evolution_stages()

	# Check daily login and show rewards
	_check_daily_login()

	# Update companion based on evolution
	_update_companion_evolution_visual()

	print("[MindscapeHub] Hub ready")


func _position_player_from_transition() -> void:
	# Check for custom spawn position override (e.g., returning from Focus Chamber)
	if GameManager.player_data.has("custom_spawn_position"):
		var custom_pos = GameManager.player_data["custom_spawn_position"]
		GameManager.player_data.erase("custom_spawn_position")
		player.position = custom_pos
		return

	var from_region = MindscapeRegionManager.last_portal_used
	var spawn_pos = MindscapeRegionManager.get_spawn_position("hub", from_region)
	player.position = spawn_pos


func _setup_zone_interactions() -> void:
	# Store zone positions for proximity detection
	zone_positions["FocusChamber"] = focus_chamber.position
	zone_positions["DailyRituals"] = daily_rituals.position
	zone_positions["ReflectionPool"] = reflection_pool.position
	# Experience Shop position (near South portal area) - expanded platform
	zone_positions["ExperienceShop"] = Vector2(380, 420)

	# Create Experience Shop visual
	_create_experience_shop_visual()


func _setup_portal_interactions() -> void:
	# Store portal positions for proximity detection
	for portal in portals_node.get_children():
		portal_positions[portal.name] = portal.position


func _check_zone_portal_proximity() -> void:
	var old_nearby_zone = nearby_zone
	var old_nearby_portal = nearby_portal

	var closest_zone: String = ""
	var closest_portal: String = ""
	var closest_distance: float = INTERACTION_RADIUS

	# Check portal proximities first
	for portal_name in portal_positions:
		var portal_pos = portal_positions[portal_name]
		var distance = player.position.distance_to(portal_pos)
		if distance < closest_distance:
			closest_distance = distance
			closest_portal = portal_name
			closest_zone = ""

	# Check zone proximities (zones can override portals if closer)
	for zone_id in zone_positions:
		var zone_pos = zone_positions[zone_id]
		var distance = player.position.distance_to(zone_pos)
		if distance < closest_distance:
			closest_distance = distance
			closest_zone = zone_id
			closest_portal = ""

	nearby_zone = closest_zone
	nearby_portal = closest_portal

	# Update prompts if changed
	if nearby_zone != old_nearby_zone or nearby_portal != old_nearby_portal:
		if nearby_zone != "":
			_show_zone_prompt(nearby_zone)
		elif nearby_portal != "":
			_show_portal_prompt(nearby_portal)
		elif old_nearby_zone != "" or old_nearby_portal != "":
			_hide_interaction_prompt()


func _show_zone_prompt(zone_id: String) -> void:
	zone_name_label.text = zone_names.get(zone_id, zone_id)

	# Zone keyboard shortcuts
	var zone_shortcuts: Dictionary = {
		"FocusChamber": "F",
		"DailyRituals": "H",
		"ReflectionPool": "J"
	}

	# Lore stones are always accessible
	if zone_id.begins_with("LoreStone"):
		var is_discovered = zone_id in discovered_lore
		if is_discovered:
			prompt_text_label.text = "Press SPACE to read again"
			zone_name_label.modulate = Color(0.7, 0.6, 0.8)
		else:
			prompt_text_label.text = "Press SPACE to discover"
			zone_name_label.modulate = Color(0.9, 0.7, 1.0)
		interaction_prompt.visible = true
		return

	var is_locked = not GameManager.is_zone_unlocked(zone_id)
	if is_locked:
		var requirement_text = GameManager.get_zone_requirement(zone_id)
		var almost_text = GameManager.get_zone_almost_unlocked_text(zone_id)
		if almost_text != "":
			prompt_text_label.text = almost_text
			zone_name_label.modulate = Color(0.8, 0.75, 0.5)  # Golden hint for almost unlocked
		else:
			prompt_text_label.text = "LOCKED - " + requirement_text
			zone_name_label.modulate = Color(0.6, 0.6, 0.7)
	else:
		var shortcut = zone_shortcuts.get(zone_id, "")
		if shortcut != "":
			prompt_text_label.text = "SPACE to enter  |  %s for quick access" % shortcut
		else:
			prompt_text_label.text = "Press SPACE to enter"
		zone_name_label.modulate = Color(1, 1, 1)

	interaction_prompt.visible = true


func _show_portal_prompt(portal_id: String) -> void:
	var region_id = portal_to_region.get(portal_id, "")
	var region_name = portal_names.get(portal_id, portal_id)

	zone_name_label.text = region_name

	if MindscapeRegionManager.is_region_unlocked(region_id):
		prompt_text_label.text = "Press SPACE to travel"
		zone_name_label.modulate = MindscapeRegionManager.get_region_theme_color(region_id)
	else:
		var unlock_text = MindscapeRegionManager.get_unlock_requirement_text(region_id)
		prompt_text_label.text = "LOCKED - " + unlock_text
		zone_name_label.modulate = Color(0.5, 0.5, 0.6)

	interaction_prompt.visible = true


func _hide_interaction_prompt() -> void:
	interaction_prompt.visible = false


func _process(delta: float) -> void:
	# Skip if in UI
	if zone_panel.visible or dialogue_panel.visible or pause_menu.visible:
		return

	# Crystal animation
	crystal_pulse_time += delta
	_animate_crystal()

	# Animate enhanced hub environment
	_animate_hub_environment(delta)

	# Animate enhanced portals
	_animate_enhanced_portals(delta)

	# Animate companion spirit
	_animate_companion(delta)

	# Animate shop visual
	_animate_shop_visual()

	# Animate progress indicators
	_animate_progress_indicators()

	# Animate evolution stage elements
	_animate_evolution_stages(delta)

	# Update minimap
	_update_minimap()

	# Check proximity to zones, portals, and exit crystal
	_check_zone_portal_proximity()
	_check_exit_crystal_proximity()

	# WASD movement
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

		# Isometric movement
		var iso_movement = Vector2(
			input_dir.x - input_dir.y,
			(input_dir.x + input_dir.y) * 0.5
		)

		var new_pos = player.position + iso_movement * player_speed * delta
		new_pos = _constrain_to_diamond(new_pos)
		player.position = new_pos

		# Play movement sound
		move_sound_timer += delta
		if move_sound_timer >= move_sound_interval:
			move_sound_timer = 0.0
			_play_sfx("res://audio/sfx/hover_move.wav", -12.0)
	else:
		move_sound_timer = 0.0

	_update_camera()


func _input(event: InputEvent) -> void:
	var viewport = get_viewport()

	# ESC key - close panels in order, then open pause menu
	if event.is_action_pressed("ui_cancel"):
		if volume_popup:
			_close_volume_popup()
		elif shortcuts_panel:
			_close_shortcuts_guide()
		elif daily_summary_panel:
			_close_daily_summary()
		elif cutscene_theater_panel:
			_close_cutscene_theater()
		elif story_panel:
			_close_story_panel()
		elif achievements_panel:
			_close_achievements_view()
		elif focus_history_panel:
			_close_focus_history()
		elif shop_panel:
			_close_experience_shop()
		elif pause_menu.visible:
			_close_pause_menu()
		elif zone_panel.visible:
			_close_zone()
		elif dialogue_panel.visible:
			_close_dialogue()
		else:
			_open_pause_menu()
		if viewport:
			viewport.set_input_as_handled()
		return

	# Handle dialogue continue with SPACE/Enter
	if event.is_action_pressed("ui_accept"):
		if dialogue_panel.visible:
			_close_dialogue_with_callback()
			if viewport:
				viewport.set_input_as_handled()
			return

		# Skip if in other UI
		if zone_panel.visible or pause_menu.visible:
			return

		if near_exit_crystal:
			_show_exit_dialog()
			if viewport:
				viewport.set_input_as_handled()
			return
		elif nearby_portal != "":
			_travel_to_region(nearby_portal)
			if viewport:
				viewport.set_input_as_handled()
			return
		elif nearby_zone != "":
			_interact_with_zone(nearby_zone)
			if viewport:
				viewport.set_input_as_handled()
			return

	# ? key for shortcuts guide
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SLASH and event.shift_pressed:
			_show_shortcuts_guide()
			if viewport:
				viewport.set_input_as_handled()
			return

		# Quick action shortcuts (only when no panels/menus are open)
		if not zone_panel.visible and not pause_menu.visible and not dialogue_panel.visible:
			if event.keycode == KEY_H:
				# H - Go to Daily Rituals (Habits)
				GameManager.goto_scene("res://scenes/daily_rituals/daily_rituals.tscn")
				if viewport:
					viewport.set_input_as_handled()
				return
			elif event.keycode == KEY_F:
				# F - Go to Focus Chamber
				_interact_with_zone("FocusChamber")
				if viewport:
					viewport.set_input_as_handled()
				return
			elif event.keycode == KEY_J:
				# J - Open Journal (Reflection Pool)
				_open_journal_viewer()
				if viewport:
					viewport.set_input_as_handled()
				return
			elif event.keycode == KEY_P:
				# P - Pause menu
				_open_pause_menu()
				if viewport:
					viewport.set_input_as_handled()
				return
			elif event.keycode == KEY_E:
				# E - Daily Summary (not D, conflicts with movement)
				_toggle_daily_summary()
				if viewport:
					viewport.set_input_as_handled()
				return
			elif event.keycode == KEY_M:
				# M - Toggle mute
				_toggle_mute()
				if viewport:
					viewport.set_input_as_handled()
				return

	# Zoom with mouse wheel (only when no UI panels are open)
	if event is InputEventMouseButton:
		# Close volume popup on click outside
		if volume_popup and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var popup_rect = Rect2(volume_popup.global_position, volume_popup.size)
			var btn_rect = Rect2(volume_button.global_position, volume_button.size)
			if not popup_rect.has_point(event.position) and not btn_rect.has_point(event.position):
				_close_volume_popup()

		# Don't process zoom if any panel is visible - let scroll containers handle it
		if zone_panel.visible or pause_menu.visible or dialogue_panel.visible:
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(zoom_speed)
			if viewport:
				viewport.set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(-zoom_speed)
			if viewport:
				viewport.set_input_as_handled()
			return


func _check_exit_crystal_proximity() -> void:
	var dist = player.position.distance_to(EXIT_CRYSTAL_POSITION)
	var was_near = near_exit_crystal
	near_exit_crystal = dist < EXIT_CRYSTAL_RADIUS

	# Check if near center area (larger radius for status panel)
	var center_radius = 180.0
	var was_near_center = is_near_center
	is_near_center = dist < center_radius

	if is_near_center and not was_near_center:
		_show_center_status_panel()
	elif not is_near_center and was_near_center:
		_hide_center_status_panel()

	if near_exit_crystal and not was_near:
		nearby_zone = ""
		nearby_portal = ""
		zone_name_label.text = "Exit Portal"
		prompt_text_label.text = "SPACE to leave  |  P for menu  |  ? for shortcuts"
		zone_name_label.modulate = Color(0.8, 0.9, 1)
		interaction_prompt.visible = true
	elif not near_exit_crystal and was_near:
		if nearby_zone == "" and nearby_portal == "":
			_hide_interaction_prompt()


func _animate_crystal() -> void:
	if center_crystal and crystal_glow:
		var pulse = sin(crystal_pulse_time * 2.0) * 0.15 + 0.85
		crystal_glow.modulate.a = pulse * 0.5

	# Animate environment elements
	_animate_environment()

	# Animate zone elements
	_animate_zones()


func _animate_environment() -> void:
	var env_node = isometric_base.get_node_or_null("Environment")
	if not env_node:
		return

	# Animate floating orbs
	for i in range(1, 4):
		var orb = env_node.get_node_or_null("FloatingOrb" + str(i))
		if orb:
			var float_offset = sin(crystal_pulse_time * 1.5 + i * 0.7) * 8
			orb.position.y = orb.position.y if not orb.has_meta("base_y") else orb.get_meta("base_y")
			if not orb.has_meta("base_y"):
				orb.set_meta("base_y", orb.position.y)
			orb.position.y = orb.get_meta("base_y") + float_offset
			orb.modulate.a = 0.3 + sin(crystal_pulse_time * 2.0 + i) * 0.15

	# Animate particles
	for i in range(1, 7):
		var particle = env_node.get_node_or_null("Particle" + str(i))
		if particle:
			var float_y = sin(crystal_pulse_time * 2.5 + i * 0.5) * 5
			var float_x = cos(crystal_pulse_time * 1.8 + i * 0.8) * 3
			if not particle.has_meta("base_pos"):
				particle.set_meta("base_pos", particle.position)
			var base = particle.get_meta("base_pos")
			particle.position = base + Vector2(float_x, float_y)
			particle.modulate.a = 0.2 + sin(crystal_pulse_time * 3.0 + i * 0.3) * 0.15

	# Animate lantern glows
	for i in range(1, 3):
		var lantern = env_node.get_node_or_null("Lantern" + str(i))
		if lantern:
			var glow = lantern.get_node_or_null("Glow")
			if glow:
				glow.modulate.a = 0.2 + sin(crystal_pulse_time * 1.2 + i) * 0.1

	# Animate progress indicators
	_animate_progress_indicators()


func _animate_zones() -> void:
	# Animate Focus Chamber elements
	if focus_chamber:
		# Hourglass glow pulse
		var timer_glow = focus_chamber.get_node_or_null("TimerGlow")
		if timer_glow:
			timer_glow.modulate.a = 0.4 + sin(crystal_pulse_time * 2.5) * 0.15

		# Energy arcs float
		var arc_left = focus_chamber.get_node_or_null("EnergyArcLeft")
		var arc_right = focus_chamber.get_node_or_null("EnergyArcRight")
		if arc_left:
			if not arc_left.has_meta("base_y"):
				arc_left.set_meta("base_y", arc_left.position.y)
			arc_left.position.y = arc_left.get_meta("base_y") + sin(crystal_pulse_time * 3.0) * 4
			arc_left.modulate.a = 0.5 + sin(crystal_pulse_time * 4.0) * 0.2
		if arc_right:
			if not arc_right.has_meta("base_y"):
				arc_right.set_meta("base_y", arc_right.position.y)
			arc_right.position.y = arc_right.get_meta("base_y") + sin(crystal_pulse_time * 3.0 + PI) * 4
			arc_right.modulate.a = 0.5 + sin(crystal_pulse_time * 4.0 + PI) * 0.2

		# Top crystal glow
		var top_crystal = focus_chamber.get_node_or_null("TopCrystal")
		if top_crystal:
			top_crystal.modulate.a = 0.85 + sin(crystal_pulse_time * 2.0) * 0.15

	# Animate Daily Rituals flames
	if daily_rituals:
		# Main flame flicker
		var flame_core = daily_rituals.get_node_or_null("FlameCore")
		var flame_inner = daily_rituals.get_node_or_null("FlameInner")
		var flame_glow = daily_rituals.get_node_or_null("FlameGlow")

		if flame_core:
			var flicker = 0.85 + sin(crystal_pulse_time * 8.0) * 0.1 + sin(crystal_pulse_time * 12.0) * 0.05
			flame_core.modulate.a = flicker
			flame_core.scale.y = 0.95 + sin(crystal_pulse_time * 6.0) * 0.08

		if flame_inner:
			var flicker = 0.8 + sin(crystal_pulse_time * 10.0) * 0.15
			flame_inner.modulate.a = flicker
			flame_inner.scale.y = 0.9 + sin(crystal_pulse_time * 7.0) * 0.1

		if flame_glow:
			flame_glow.modulate.a = 0.35 + sin(crystal_pulse_time * 5.0) * 0.1

		# Side candle flames
		var left_flame = daily_rituals.get_node_or_null("LeftFlame")
		var right_flame = daily_rituals.get_node_or_null("RightFlame")

		if left_flame:
			var flicker = 0.8 + sin(crystal_pulse_time * 9.0 + 0.5) * 0.15
			left_flame.modulate.a = flicker
			left_flame.scale.y = 0.9 + sin(crystal_pulse_time * 6.5) * 0.1

		if right_flame:
			var flicker = 0.8 + sin(crystal_pulse_time * 9.0 + 1.5) * 0.15
			right_flame.modulate.a = flicker
			right_flame.scale.y = 0.9 + sin(crystal_pulse_time * 6.5 + 1.0) * 0.1

	# Animate Reflection Pool
	if reflection_pool:
		# Ripple animations
		var ripple1 = reflection_pool.get_node_or_null("Ripple1")
		var ripple2 = reflection_pool.get_node_or_null("Ripple2")
		var ripple3 = reflection_pool.get_node_or_null("Ripple3")

		if ripple1:
			ripple1.modulate.a = 0.3 + sin(crystal_pulse_time * 1.5) * 0.1
		if ripple2:
			ripple2.modulate.a = 0.25 + sin(crystal_pulse_time * 1.5 + 0.5) * 0.1
		if ripple3:
			ripple3.modulate.a = 0.2 + sin(crystal_pulse_time * 1.5 + 1.0) * 0.1

		# Floating book gentle bob
		var floating_book = reflection_pool.get_node_or_null("FloatingBook")
		var book_glow = reflection_pool.get_node_or_null("BookGlow")
		if floating_book:
			if not floating_book.has_meta("base_y"):
				floating_book.set_meta("base_y", floating_book.position.y)
			floating_book.position.y = floating_book.get_meta("base_y") + sin(crystal_pulse_time * 1.2) * 3

		if book_glow:
			if not book_glow.has_meta("base_y"):
				book_glow.set_meta("base_y", book_glow.position.y)
			book_glow.position.y = book_glow.get_meta("base_y") + sin(crystal_pulse_time * 1.2) * 3
			book_glow.modulate.a = 0.4 + sin(crystal_pulse_time * 2.0) * 0.15

		# Side crystals glow
		var left_crystal = reflection_pool.get_node_or_null("LeftCrystal")
		var right_crystal = reflection_pool.get_node_or_null("RightCrystal")

		if left_crystal:
			left_crystal.modulate.a = 0.75 + sin(crystal_pulse_time * 2.0) * 0.15
		if right_crystal:
			right_crystal.modulate.a = 0.75 + sin(crystal_pulse_time * 2.0 + PI) * 0.15


func _setup_progress_indicators() -> void:
	# Create streak flames container
	var flames_container = Node2D.new()
	flames_container.name = "StreakFlames"
	flames_container.position = Vector2(0, 30)
	isometric_base.add_child(flames_container)

	# Streak flames label - positioned below the flames
	var flames_label = Label.new()
	flames_label.name = "FlamesLabel"
	flames_label.text = "Streaks"
	flames_label.add_theme_font_size_override("font_size", 11)
	flames_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.35, 0.9))
	flames_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flames_label.position = Vector2(-30, 20)  # Below the flames
	flames_label.size = Vector2(60, 15)
	flames_container.add_child(flames_label)

	# Create evolution ring container
	evolution_ring = Node2D.new()
	evolution_ring.name = "EvolutionRing"
	evolution_ring.position = Vector2(0, -60)

	var ring_poly = Polygon2D.new()
	ring_poly.name = "RingPoly"
	ring_poly.color = Color(0.6, 0.4, 0.8, 0.15)
	ring_poly.polygon = PackedVector2Array([
		Vector2(-60, 0), Vector2(0, -30), Vector2(60, 0), Vector2(0, 30)
	])
	evolution_ring.add_child(ring_poly)

	isometric_base.add_child(evolution_ring)
	isometric_base.move_child(evolution_ring, 3)  # After InnerRing

	# Create streak flames based on active habits
	_update_streak_flames()

	# Create garden patches
	_create_garden_patches()

	# Update evolution ring size
	_update_evolution_ring()


func _update_streak_flames() -> void:
	var flames_container = isometric_base.get_node_or_null("StreakFlames")
	if not flames_container:
		return

	# Clear existing flames
	for child in flames_container.get_children():
		child.queue_free()
	streak_flames.clear()

	# Get active habit streaks
	var habits = HabitManager.get_all_habits() if HabitManager else []
	var active_streaks = []
	for habit in habits:
		if habit.get("streak", 0) > 0 and not habit.get("archived", false):
			active_streaks.append(habit.streak)

	# Sort by streak length (descending) and take top 6
	active_streaks.sort()
	active_streaks.reverse()
	active_streaks = active_streaks.slice(0, 6)

	# Create flame for each active streak
	var flame_positions = [
		Vector2(-45, 0), Vector2(-27, -15), Vector2(-9, 0),
		Vector2(9, 0), Vector2(27, -15), Vector2(45, 0)
	]

	for i in range(active_streaks.size()):
		var streak = active_streaks[i]
		var flame = _create_flame_polygon(streak)
		flame.position = flame_positions[i]
		flames_container.add_child(flame)
		streak_flames.append(flame)


func _create_flame_polygon(streak: int) -> Polygon2D:
	var flame = Polygon2D.new()

	# Scale and color based on streak length
	var scale_factor = 1.0
	var color: Color

	if streak >= 30:
		scale_factor = 1.5
		color = Color(1.0, 0.4, 0.1, 0.9)  # Bright orange
	elif streak >= 7:
		scale_factor = 1.2
		color = Color(1.0, 0.6, 0.2, 0.8)  # Orange
	else:
		scale_factor = 1.0
		color = Color(0.9, 0.7, 0.3, 0.7)  # Yellow-orange

	flame.color = color
	flame.polygon = PackedVector2Array([
		Vector2(-5, 8) * scale_factor,
		Vector2(-8, 0) * scale_factor,
		Vector2(-4, -10) * scale_factor,
		Vector2(0, -18) * scale_factor,
		Vector2(4, -10) * scale_factor,
		Vector2(8, 0) * scale_factor,
		Vector2(5, 8) * scale_factor
	])

	return flame


func _update_evolution_ring() -> void:
	if not evolution_ring:
		return

	var evo_level = GameManager.get_evolution_level() if GameManager else 1
	var evo_progress = GameManager.get_evolution_progress() if GameManager else 0.0

	# Scale from 50% to 100% based on evolution level
	var scale_factor = 0.5 + (evo_level / 10.0) * 0.5

	# Color shifts from purple to gold as evolution increases
	var purple = Color(0.6, 0.4, 0.8, 0.2)
	var gold = Color(0.9, 0.75, 0.3, 0.3)
	var color = purple.lerp(gold, evo_level / 10.0)

	# Add inner glow for progress within level
	color.a = 0.15 + (evo_progress * 0.15)

	# Update the ring polygon child if it exists
	var ring_poly = evolution_ring.get_node_or_null("RingPoly")
	if ring_poly:
		ring_poly.color = color
	evolution_ring.scale = Vector2(scale_factor, scale_factor)


func _create_garden_patches() -> void:
	## Create garden patches around the hub that grow based on habit completion
	## Each domain (Mind, Body, Soul, etc.) gets a patch that evolves

	# Get habit stats per domain
	var domain_stats = {}
	if HabitManager:
		var habits = HabitManager.get_all_habits()
		for habit in habits:
			var domain = habit.get("domain", 0)
			var domain_name = HabitManager._domain_to_string(domain)
			if not domain_stats.has(domain_name):
				domain_stats[domain_name] = {"total_streak": 0, "count": 0, "completed_today": 0}
			domain_stats[domain_name].total_streak += habit.get("streak", 0)
			domain_stats[domain_name].count += 1
			if HabitManager.is_completed_today(habit.id):
				domain_stats[domain_name].completed_today += 1

	# Garden patch positions around the hub (isometric positions)
	var patch_configs = [
		{"name": "Mind", "pos": Vector2(-350, -100), "base_color": Color(0.3, 0.5, 0.8)},
		{"name": "Body", "pos": Vector2(350, -100), "base_color": Color(0.8, 0.4, 0.3)},
		{"name": "Soul", "pos": Vector2(-350, 150), "base_color": Color(0.6, 0.4, 0.8)},
		{"name": "Social", "pos": Vector2(350, 150), "base_color": Color(0.4, 0.7, 0.5)},
		{"name": "Career", "pos": Vector2(-180, 280), "base_color": Color(0.7, 0.6, 0.3)},
		{"name": "Wealth", "pos": Vector2(180, 280), "base_color": Color(0.8, 0.7, 0.2)}
	]

	for config in patch_configs:
		var stats = domain_stats.get(config.name, {"total_streak": 0, "count": 0, "completed_today": 0})
		var growth_level = _calculate_garden_growth(stats)

		var patch = Node2D.new()
		patch.name = "GardenPatch_" + config.name
		patch.position = config.pos

		# Create patch based on growth level
		_create_garden_patch_visual(patch, config, growth_level, stats)

		isometric_base.add_child(patch)
		garden_patches.append({
			"node": patch,
			"name": config.name,
			"growth": growth_level,
			"phase": randf() * TAU
		})


func _calculate_garden_growth(stats: Dictionary) -> int:
	## Calculate growth level 0-5 based on habit performance
	var streak = stats.get("total_streak", 0)
	var count = stats.get("count", 0)
	var completed = stats.get("completed_today", 0)

	if count == 0:
		return 0  # No habits in this domain

	var avg_streak = float(streak) / count
	var completion_rate = float(completed) / count if count > 0 else 0.0

	# Growth level based on avg streak
	if avg_streak >= 30:
		return 5  # Flourishing
	elif avg_streak >= 14:
		return 4  # Thriving
	elif avg_streak >= 7:
		return 3  # Growing
	elif avg_streak >= 3:
		return 2  # Sprouting
	elif avg_streak >= 1 or completion_rate > 0:
		return 1  # Seeded
	return 0  # Dormant


func _create_garden_patch_visual(patch: Node2D, config: Dictionary, growth: int, _stats: Dictionary) -> void:
	## Create visual elements for a garden patch based on growth level
	var base_color = config.base_color

	# Ground patch (soil)
	var ground = Polygon2D.new()
	ground.polygon = PackedVector2Array([
		Vector2(-40, 0), Vector2(0, -20), Vector2(40, 0), Vector2(0, 20)
	])
	var soil_color = Color(0.25, 0.18, 0.12) if growth == 0 else Color(0.3, 0.22, 0.15)
	ground.color = soil_color
	patch.add_child(ground)

	if growth == 0:
		# Dormant - just soil with small crack
		var crack = Polygon2D.new()
		crack.polygon = PackedVector2Array([
			Vector2(-5, 0), Vector2(0, -3), Vector2(5, 0), Vector2(0, 3)
		])
		crack.color = Color(0.15, 0.1, 0.08, 0.5)
		patch.add_child(crack)

	elif growth == 1:
		# Seeded - tiny sprout
		var sprout = Polygon2D.new()
		sprout.polygon = PackedVector2Array([
			Vector2(-2, 0), Vector2(0, -12), Vector2(2, 0)
		])
		sprout.color = Color(0.3, 0.5, 0.25)
		patch.add_child(sprout)

	elif growth == 2:
		# Sprouting - small plant
		var stem = Polygon2D.new()
		stem.polygon = PackedVector2Array([
			Vector2(-3, 0), Vector2(-1, -20), Vector2(1, -20), Vector2(3, 0)
		])
		stem.color = Color(0.3, 0.55, 0.25)
		patch.add_child(stem)

		# Two small leaves
		for side in [-1, 1]:
			var leaf = Polygon2D.new()
			leaf.polygon = PackedVector2Array([
				Vector2(0, -12), Vector2(side * 10, -8), Vector2(side * 8, -14)
			])
			leaf.color = base_color.lerp(Color(0.3, 0.6, 0.3), 0.5)
			patch.add_child(leaf)

	elif growth == 3:
		# Growing - medium plant with multiple leaves
		var stem = Polygon2D.new()
		stem.polygon = PackedVector2Array([
			Vector2(-4, 0), Vector2(-2, -30), Vector2(2, -30), Vector2(4, 0)
		])
		stem.color = Color(0.25, 0.5, 0.2)
		patch.add_child(stem)

		# Multiple leaves
		for i in range(3):
			var y_offset = -10 - i * 8
			var side = 1 if i % 2 == 0 else -1
			var leaf = Polygon2D.new()
			leaf.polygon = PackedVector2Array([
				Vector2(0, y_offset), Vector2(side * 15, y_offset + 3), Vector2(side * 12, y_offset - 5)
			])
			leaf.color = base_color.lerp(Color(0.3, 0.65, 0.3), 0.4)
			patch.add_child(leaf)

	elif growth == 4:
		# Thriving - full plant with bud
		var stem = Polygon2D.new()
		stem.polygon = PackedVector2Array([
			Vector2(-5, 0), Vector2(-3, -40), Vector2(3, -40), Vector2(5, 0)
		])
		stem.color = Color(0.2, 0.45, 0.18)
		patch.add_child(stem)

		# Leaves
		for i in range(4):
			var y_offset = -8 - i * 9
			var side = 1 if i % 2 == 0 else -1
			var leaf = Polygon2D.new()
			leaf.polygon = PackedVector2Array([
				Vector2(0, y_offset), Vector2(side * 18, y_offset + 4), Vector2(side * 15, y_offset - 6)
			])
			leaf.color = base_color.lerp(Color(0.3, 0.7, 0.3), 0.3)
			patch.add_child(leaf)

		# Flower bud
		var bud = Polygon2D.new()
		bud.polygon = PackedVector2Array([
			Vector2(-6, -38), Vector2(0, -50), Vector2(6, -38)
		])
		bud.color = base_color
		patch.add_child(bud)

	else:  # growth == 5
		# Flourishing - full bloom with glow
		var stem = Polygon2D.new()
		stem.polygon = PackedVector2Array([
			Vector2(-6, 0), Vector2(-4, -45), Vector2(4, -45), Vector2(6, 0)
		])
		stem.color = Color(0.18, 0.4, 0.15)
		patch.add_child(stem)

		# Rich foliage
		for i in range(5):
			var y_offset = -6 - i * 8
			var side = 1 if i % 2 == 0 else -1
			var leaf = Polygon2D.new()
			leaf.polygon = PackedVector2Array([
				Vector2(0, y_offset), Vector2(side * 22, y_offset + 5), Vector2(side * 18, y_offset - 8)
			])
			leaf.color = base_color.lerp(Color(0.25, 0.75, 0.25), 0.25)
			patch.add_child(leaf)

		# Full bloom flower
		var petal_count = 6
		for i in range(petal_count):
			var angle = (float(i) / petal_count) * TAU
			var petal = Polygon2D.new()
			petal.polygon = PackedVector2Array([
				Vector2(0, 0), Vector2(cos(angle) * 12, sin(angle) * 12 - 4),
				Vector2(cos(angle + 0.3) * 8, sin(angle + 0.3) * 8 - 4)
			])
			petal.position = Vector2(0, -52)
			petal.color = base_color
			patch.add_child(petal)

		# Flower center
		var center = Polygon2D.new()
		center.polygon = _create_garden_circle(5, 8)
		center.position = Vector2(0, -52)
		center.color = base_color.lightened(0.3)
		patch.add_child(center)

		# Glow effect
		var glow = Polygon2D.new()
		glow.polygon = _create_garden_circle(20, 12)
		glow.position = Vector2(0, -52)
		glow.color = Color(base_color.r, base_color.g, base_color.b, 0.15)
		glow.z_index = -1
		patch.add_child(glow)

	# Add domain label
	var label = Label.new()
	label.text = config.name
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 0.8))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-20, 25)
	patch.add_child(label)


func _create_garden_circle(radius: float, segments: int) -> PackedVector2Array:
	## Create a circular polygon for garden elements
	var points = PackedVector2Array()
	for i in range(segments):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	return points


func _animate_progress_indicators() -> void:
	# Animate streak flames
	for i in range(streak_flames.size()):
		var flame = streak_flames[i]
		if flame and is_instance_valid(flame):
			# Flicker effect
			var flicker = sin(crystal_pulse_time * 4.0 + i * 1.2) * 0.1
			flame.modulate.a = 0.8 + flicker

			# Slight sway
			var sway = sin(crystal_pulse_time * 2.5 + i * 0.8) * 2
			if not flame.has_meta("base_x"):
				flame.set_meta("base_x", flame.position.x)
			flame.position.x = flame.get_meta("base_x") + sway

	# Animate evolution ring
	if evolution_ring:
		var pulse = sin(crystal_pulse_time * 1.5) * 0.03 + 1.0
		evolution_ring.scale = evolution_ring.scale * pulse

	# Animate garden patches
	for patch_data in garden_patches:
		var patch_node = patch_data.get("node")
		if patch_node and is_instance_valid(patch_node):
			var phase = patch_data.get("phase", 0.0)
			# Gentle sway for plants
			for child in patch_node.get_children():
				if child is Polygon2D:
					var sway = sin(crystal_pulse_time * 1.2 + phase + child.position.x * 0.1) * 0.05
					child.rotation = sway


func _show_center_status_panel() -> void:
	if center_status_panel or zone_panel.visible or pause_menu.visible:
		return

	center_status_panel = PanelContainer.new()
	center_status_panel.name = "CenterStatusPanel"
	# Position at bottom-left corner, out of the way
	center_status_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	center_status_panel.offset_left = 12
	center_status_panel.offset_bottom = -12
	center_status_panel.offset_top = -50
	center_status_panel.offset_right = 320

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.75)  # More transparent
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_color = Color(0.3, 0.35, 0.5, 0.4)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	center_status_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	center_status_panel.add_child(margin)

	# Horizontal compact layout
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)

	# Get stats
	var habits = HabitManager.get_all_habits() if HabitManager else []
	var weekly_stats = HabitManager.get_weekly_stats() if HabitManager else {}
	var unlocked_achievements = AchievementManager.get_unlocked_achievements() if AchievementManager else []

	# Active Streaks
	var active_streaks = []
	for habit in habits:
		if habit.get("streak", 0) > 0:
			active_streaks.append({"name": habit.name, "streak": habit.streak})

	var streak_stat = _create_compact_stat("~", "%d" % active_streaks.size(), Color(0.95, 0.7, 0.3))
	hbox.add_child(streak_stat)

	# Weekly Completions
	var completions = weekly_stats.get("this_week_completions", 0)
	var week_stat = _create_compact_stat("*", "%d" % completions, Color(0.4, 0.75, 0.5))
	hbox.add_child(week_stat)

	# Achievements
	var ach_stat = _create_compact_stat("#", "%d" % unlocked_achievements.size(), Color(0.9, 0.8, 0.4))
	hbox.add_child(ach_stat)

	# Evolution level
	var evo_level = GameManager.get_evolution_level() if GameManager else 1
	var evo_stat = _create_compact_stat("+", "Lv%d" % evo_level, Color(0.7, 0.5, 0.9))
	hbox.add_child(evo_stat)

	add_child(center_status_panel)

	# Fade in
	center_status_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(center_status_panel, "modulate:a", 1.0, 0.2)


func _create_status_row(icon: String, label_text: String, value_text: String, icon_color: Color) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 14)
	icon_label.add_theme_color_override("font_color", icon_color)
	icon_label.custom_minimum_size = Vector2(18, 0)
	row.add_child(icon_label)

	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 13)
	value.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)

	return row


func _create_compact_stat(icon: String, value: String, icon_color: Color) -> HBoxContainer:
	var stat = HBoxContainer.new()
	stat.add_theme_constant_override("separation", 4)

	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 12)
	icon_label.add_theme_color_override("font_color", icon_color)
	stat.add_child(icon_label)

	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	stat.add_child(value_label)

	return stat


func _hide_center_status_panel() -> void:
	if not center_status_panel:
		return

	var tween = create_tween()
	tween.tween_property(center_status_panel, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		if center_status_panel:
			center_status_panel.queue_free()
			center_status_panel = null
	)


func _setup_lore_stones() -> void:
	var stones_container = Node2D.new()
	stones_container.name = "LoreStones"
	isometric_base.add_child(stones_container)

	# Load discovered lore from player data
	discovered_lore = GameManager.player_data.get("discovered_lore", [])

	for stone_id in lore_stone_positions:
		var pos = lore_stone_positions[stone_id]
		var stone = _create_lore_stone(stone_id)
		stone.position = pos
		stones_container.add_child(stone)

		# Add to zone positions for proximity detection
		zone_positions[stone_id] = pos


func _create_lore_stone(stone_id: String) -> Node2D:
	var stone = Node2D.new()
	stone.name = stone_id

	# Stone base
	var base = Polygon2D.new()
	base.color = Color(0.35, 0.3, 0.4, 0.9)
	base.polygon = PackedVector2Array([
		Vector2(-15, 5), Vector2(-12, -15), Vector2(0, -22),
		Vector2(12, -15), Vector2(15, 5), Vector2(0, 10)
	])
	stone.add_child(base)

	# Glow if undiscovered
	var is_discovered = stone_id in discovered_lore
	var glow = Polygon2D.new()
	glow.name = "Glow"
	glow.color = Color(0.7, 0.5, 0.9, 0.3) if not is_discovered else Color(0.5, 0.5, 0.5, 0.1)
	glow.polygon = PackedVector2Array([
		Vector2(-20, 8), Vector2(-18, -20), Vector2(0, -28),
		Vector2(18, -20), Vector2(20, 8), Vector2(0, 15)
	])
	stone.add_child(glow)

	return stone


func _setup_achievement_pedestals() -> void:
	var pedestals_container = Node2D.new()
	pedestals_container.name = "AchievementPedestals"
	isometric_base.add_child(pedestals_container)

	# Three pedestal positions - grouped on the right side
	var positions = [
		Vector2(220, 60),
		Vector2(260, 90),
		Vector2(300, 120)
	]

	# Section label - positioned above the pedestals
	var label = Label.new()
	label.name = "SectionLabel"
	label.text = "Achievements"
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5, 0.9))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(200, 15)  # Above the first pedestal
	label.size = Vector2(120, 15)
	pedestals_container.add_child(label)

	for i in range(3):
		var pedestal = _create_pedestal(i)
		pedestal.position = positions[i]
		pedestals_container.add_child(pedestal)

	_update_achievement_pedestals()


func _create_pedestal(index: int) -> Node2D:
	var pedestal = Node2D.new()
	pedestal.name = "Pedestal" + str(index)

	# Pedestal base
	var base = Polygon2D.new()
	base.name = "Base"
	base.color = Color(0.25, 0.22, 0.35, 0.9)
	base.polygon = PackedVector2Array([
		Vector2(-20, 10), Vector2(-25, 0), Vector2(-20, -10),
		Vector2(20, -10), Vector2(25, 0), Vector2(20, 10)
	])
	pedestal.add_child(base)

	# Pedestal pillar
	var pillar = Polygon2D.new()
	pillar.color = Color(0.3, 0.27, 0.4, 0.9)
	pillar.polygon = PackedVector2Array([
		Vector2(-15, -10), Vector2(-15, -35),
		Vector2(15, -35), Vector2(15, -10)
	])
	pedestal.add_child(pillar)

	# Achievement display area (glow)
	var glow = Polygon2D.new()
	glow.name = "Glow"
	glow.color = Color(0.9, 0.75, 0.3, 0.0)  # Gold, initially hidden
	glow.polygon = PackedVector2Array([
		Vector2(-18, -32), Vector2(0, -55),
		Vector2(18, -32), Vector2(0, -20)
	])
	pedestal.add_child(glow)

	# Achievement icon label
	var icon = Label.new()
	icon.name = "Icon"
	icon.text = ""
	icon.add_theme_font_size_override("font_size", 20)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.position = Vector2(-15, -50)
	icon.size = Vector2(30, 30)
	pedestal.add_child(icon)

	return pedestal


func _update_achievement_pedestals() -> void:
	if not AchievementManager:
		return

	var pedestals_container = isometric_base.get_node_or_null("AchievementPedestals")
	if not pedestals_container:
		return

	# Get recent unlocked achievements
	var unlocked = AchievementManager.get_unlocked_achievements()

	# Sort by unlock time (most recent first)
	unlocked.sort_custom(func(a, b): return a.get("unlocked_at", 0) > b.get("unlocked_at", 0))

	# Update each pedestal
	for i in range(3):
		var pedestal = pedestals_container.get_node_or_null("Pedestal" + str(i))
		if not pedestal:
			continue

		var glow = pedestal.get_node_or_null("Glow")
		var icon = pedestal.get_node_or_null("Icon")

		if i < unlocked.size():
			var achievement = unlocked[i]
			if icon:
				icon.text = achievement.get("icon", "")
			if glow:
				glow.color.a = 0.4
		else:
			if icon:
				icon.text = ""
			if glow:
				glow.color.a = 0.0


func _setup_companion_spirit() -> void:
	companion_spirit = Node2D.new()
	companion_spirit.name = "CompanionSpirit"
	isometric_base.add_child(companion_spirit)

	# Spirit body (small floating orb)
	var body = Polygon2D.new()
	body.name = "Body"
	body.color = Color(0.7, 0.85, 1.0, 0.8)
	body.polygon = PackedVector2Array([
		Vector2(-8, 0), Vector2(-6, -8), Vector2(0, -12),
		Vector2(6, -8), Vector2(8, 0), Vector2(6, 8),
		Vector2(0, 10), Vector2(-6, 8)
	])
	companion_spirit.add_child(body)

	# Spirit glow
	var glow = Polygon2D.new()
	glow.name = "Glow"
	glow.color = Color(0.6, 0.8, 1.0, 0.3)
	glow.polygon = PackedVector2Array([
		Vector2(-14, 0), Vector2(-10, -14), Vector2(0, -18),
		Vector2(10, -14), Vector2(14, 0), Vector2(10, 14),
		Vector2(0, 16), Vector2(-10, 14)
	])
	companion_spirit.add_child(glow)

	# Small eyes
	var left_eye = Polygon2D.new()
	left_eye.color = Color(0.2, 0.3, 0.5, 1.0)
	left_eye.polygon = PackedVector2Array([Vector2(-4, -3), Vector2(-2, -5), Vector2(-2, -1)])
	companion_spirit.add_child(left_eye)

	var right_eye = Polygon2D.new()
	right_eye.color = Color(0.2, 0.3, 0.5, 1.0)
	right_eye.polygon = PackedVector2Array([Vector2(4, -3), Vector2(2, -5), Vector2(2, -1)])
	companion_spirit.add_child(right_eye)

	# Initial position offset from player
	companion_spirit.position = player.position + Vector2(60, -40)

	# Check if this is first time (show welcome) - but not if onboarding is active
	if not GameManager.player_data.get("companion_introduced", false) and not is_onboarding_active:
		_show_companion_tip("Welcome to your Mindscape! I'm here to guide you on your journey of growth.")
		GameManager.player_data["companion_introduced"] = true


func _animate_companion(delta: float) -> void:
	if not companion_spirit or not companion_enabled:
		return

	# Target position: offset from player
	var target_pos = player.position + Vector2(60, -40)

	# Smooth follow with lerp
	companion_spirit.position = companion_spirit.position.lerp(target_pos, 5.0 * delta)

	# Float animation
	var float_offset = sin(crystal_pulse_time * 2.0) * 5
	companion_spirit.position.y += float_offset

	# Glow pulse
	var glow = companion_spirit.get_node_or_null("Glow")
	if glow:
		glow.modulate.a = 0.5 + sin(crystal_pulse_time * 1.5) * 0.2

	# Tip timer
	companion_tip_timer += delta
	if companion_tip_timer >= companion_tip_cooldown and not current_tip_bubble:
		_show_contextual_tip()
		companion_tip_timer = 0.0


func _show_contextual_tip() -> void:
	var tip = ""

	# Context-based tips
	if nearby_zone == "FocusChamber":
		tip = "Focus sessions help strengthen your mind. Try one when you're ready to concentrate!"
	elif nearby_zone == "DailyRituals":
		tip = "Building daily habits is the foundation of growth. Consistency is key!"
	elif nearby_zone == "ReflectionPool":
		tip = "Your journal captures reflections from habits and focus sessions. Review your growth!"
	elif nearby_zone == "ExperienceShop":
		tip = "Spend your Aspect XP on cosmetics, decorations, and more. Items are delivered to your ship!"
	elif near_exit_crystal:
		tip = "The exit crystal will return you to the real world. Don't forget to come back!"
	elif nearby_portal != "":
		tip = "Each region holds unique challenges and rewards. Explore when you feel ready!"
	else:
		# General tips
		var general_tips = [
			"Every focus session brings you closer to your potential.",
			"Small habits compound into big changes over time.",
			"Your Mindscape grows as you grow. Keep nurturing it!",
			"The Aspects within are awakening. Help them flourish.",
			"Don't forget to explore the edges - ancient lore awaits discovery."
		]

		# Check specific conditions for targeted tips
		var stats = HabitManager.get_weekly_stats() if HabitManager else {}
		if stats.get("active_streaks", 0) == 0:
			tip = "Start a habit streak today! Even small steps count."
		elif stats.get("this_week_completions", 0) < stats.get("last_week_completions", 1):
			tip = "You completed fewer habits this week. Let's get back on track!"
		else:
			tip = general_tips[randi() % general_tips.size()]

	if tip != "":
		_show_companion_tip(tip)


func _show_companion_tip(text: String) -> void:
	# Don't show tips during onboarding
	if is_onboarding_active:
		return

	# Play companion tip sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_companion_tip"):
		audio.play_companion_tip()

	if current_tip_bubble:
		current_tip_bubble.queue_free()

	# Create tip bubble at bottom of screen
	var bubble = PanelContainer.new()
	current_tip_bubble = bubble

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.15, 0.92)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = Color(0.83, 0.66, 0.29, 0.5)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	bubble.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	bubble.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)

	# Small companion icon
	var icon = ColorRect.new()
	icon.color = Color(0.83, 0.66, 0.29, 0.8)
	icon.custom_minimum_size = Vector2(24, 24)
	hbox.add_child(icon)

	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(400, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	# Position at bottom center of screen
	var viewport_size = get_viewport_rect().size
	bubble.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bubble.position = Vector2(
		(viewport_size.x - 500) / 2,
		viewport_size.y - 100
	)
	bubble.custom_minimum_size = Vector2(500, 0)

	add_child(bubble)

	# Fade in
	bubble.modulate.a = 0.0
	var fade_in = create_tween()
	fade_in.tween_property(bubble, "modulate:a", 1.0, 0.3)

	# Auto-dismiss after 5 seconds
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(func():
		if is_instance_valid(bubble):
			var tween = create_tween()
			tween.tween_property(bubble, "modulate:a", 0.0, 0.5)
			tween.tween_callback(func():
				if is_instance_valid(bubble):
					bubble.queue_free()
				if current_tip_bubble == bubble:
					current_tip_bubble = null
			)
	)


func _setup_minimap() -> void:
	# Create minimap container in bottom-left corner
	minimap_container = Control.new()
	minimap_container.name = "Minimap"
	minimap_container.custom_minimum_size = Vector2(150, 100)
	minimap_container.position = Vector2(20, get_viewport_rect().size.y - 120)
	add_child(minimap_container)

	# Background panel
	var bg_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.08, 0.85)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_color = Color(0.4, 0.35, 0.5, 0.6)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	bg_panel.add_theme_stylebox_override("panel", style)
	bg_panel.custom_minimum_size = Vector2(150, 100)
	minimap_container.add_child(bg_panel)

	# Minimap content
	var content = Control.new()
	content.name = "Content"
	content.custom_minimum_size = Vector2(150, 100)
	bg_panel.add_child(content)

	# Platform shape (diamond)
	var platform = Polygon2D.new()
	platform.name = "Platform"
	platform.color = Color(0.2, 0.18, 0.28, 0.8)
	platform.polygon = PackedVector2Array([
		Vector2(-50, 0), Vector2(0, -25), Vector2(50, 0), Vector2(0, 25)
	])
	platform.position = Vector2(75, 50)
	content.add_child(platform)

	# Portal dots
	var portal_colors = {
		"north": Color(0.4, 0.7, 0.5, 0.9),
		"east": Color(0.5, 0.5, 0.8, 0.9),
		"west": Color(0.6, 0.4, 0.7, 0.9),
		"south": Color(0.7, 0.55, 0.35, 0.9)
	}

	var portal_minimap_positions = {
		"north": Vector2(0, -21),   # Updated for expanded platform
		"east": Vector2(34, 0),
		"west": Vector2(-34, 0),
		"south": Vector2(0, 20)
	}

	for region in portal_colors:
		var dot = Polygon2D.new()
		dot.name = "Portal_" + region
		dot.color = portal_colors[region]
		dot.polygon = PackedVector2Array([
			Vector2(-4, 0), Vector2(0, -4), Vector2(4, 0), Vector2(0, 4)
		])
		dot.position = portal_minimap_positions[region] + Vector2(75, 50)
		content.add_child(dot)

	# Zone indicators
	var zone_minimap_positions = {
		"FocusChamber": Vector2(-25, -10),
		"DailyRituals": Vector2(25, -10)
	}

	for zone_name in zone_minimap_positions:
		var zone_dot = Polygon2D.new()
		zone_dot.name = "Zone_" + zone_name
		zone_dot.color = Color(0.5, 0.6, 0.8, 0.7)
		zone_dot.polygon = PackedVector2Array([
			Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)
		])
		zone_dot.position = zone_minimap_positions[zone_name] + Vector2(75, 50)
		content.add_child(zone_dot)

	# Player dot
	minimap_player_dot = Polygon2D.new()
	minimap_player_dot.name = "PlayerDot"
	minimap_player_dot.color = Color(0.95, 0.8, 0.3, 1.0)
	minimap_player_dot.polygon = PackedVector2Array([
		Vector2(-4, 2), Vector2(0, -5), Vector2(4, 2)
	])
	minimap_player_dot.position = Vector2(75, 50)
	content.add_child(minimap_player_dot)

	# Label
	var label = Label.new()
	label.text = "MAP"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.8))
	label.position = Vector2(60, 85)
	content.add_child(label)


func _update_minimap() -> void:
	if not minimap_player_dot or not player:
		return

	# Convert player world position to minimap position
	# World: -1060 to 1060 (x), -525 to 525 (y)
	# Minimap: -50 to 50 (x), -25 to 25 (y)
	var normalized_x = player.position.x / platform_half_width
	var normalized_y = player.position.y / platform_half_height

	var minimap_x = normalized_x * 50 + 75
	var minimap_y = normalized_y * 25 + 50

	minimap_player_dot.position = Vector2(minimap_x, minimap_y)

	# Rotate player dot based on movement direction (optional)
	# For now, point upward


func _interact_with_zone(zone_id: String) -> void:
	# Handle lore stones separately (always accessible)
	if zone_id.begins_with("LoreStone"):
		_read_lore_stone(zone_id)
		return

	if not GameManager.is_zone_unlocked(zone_id):
		var zone_name = zone_names.get(zone_id, zone_id)
		var requirement = GameManager.get_zone_requirement(zone_id)
		_show_dialogue("Locked", zone_name + " is not yet accessible.\n\n" + requirement)
		return

	match zone_id:
		"FocusChamber":
			# Transition to dedicated Focus Chamber scene
			GameManager.goto_scene("res://scenes/focus_chamber/focus_chamber.tscn")
		"DailyRituals":
			# Transition to dedicated Daily Rituals scene
			GameManager.goto_scene("res://scenes/daily_rituals/daily_rituals.tscn")
		"ReflectionPool":
			# Open journal viewer directly in hub
			_open_journal_viewer()
		"ExperienceShop":
			# Open experience shop panel
			_open_experience_shop()


func _read_lore_stone(stone_id: String) -> void:
	var lore_content = {
		"LoreStone1": {
			"title": "The Origin of Mindscapes",
			"text": "Long ago, the Goactorians discovered that every conscious being possesses an inner world - a Mindscape.\n\nThese realms reflect the true nature of their inhabitants: barren for those who neglect growth, flourishing for those who cultivate their potential.\n\nYour human's Mindscape awaits transformation.",
			"voice": "res://audio/voice/lore/origin_of_mindscapes.ogg"
		},
		"LoreStone2": {
			"title": "The First Contribution",
			"text": "The Goactorian tradition of Contribution began millennia ago, when Elder Zyphira connected with a struggling species on a distant world.\n\nThrough patience and guidance, she helped them discover their potential. That world flourished, and so the practice of Contribution was born.\n\nNow, you carry on this sacred tradition.",
			"voice": "res://audio/voice/lore/first_contribution.ogg"
		},
		"LoreStone3": {
			"title": "The Aspects Within",
			"text": "Every Mindscape contains dormant Aspects - fragments of potential waiting to be awakened.\n\nDiscipline. Courage. Creativity. Compassion. Wisdom. Vitality.\n\nAs your human grows through focus and habit, these Aspects stir. In time, they will take form and guide your human's journey.",
			"voice": "res://audio/voice/lore/aspects_within.ogg"
		}
	}

	var content = lore_content.get(stone_id, {"title": "Unknown", "text": "The stone's inscription has faded...", "voice": ""})

	# Mark as discovered
	if stone_id not in discovered_lore:
		discovered_lore.append(stone_id)
		GameManager.player_data["discovered_lore"] = discovered_lore

		# Update stone glow
		var stones_container = isometric_base.get_node_or_null("LoreStones")
		if stones_container:
			var stone = stones_container.get_node_or_null(stone_id)
			if stone:
				var glow = stone.get_node_or_null("Glow")
				if glow:
					glow.color = Color(0.5, 0.5, 0.5, 0.1)

	_show_dialogue(content.title, content.text, Callable(), content.get("voice", ""))


func _travel_to_region(portal_id: String) -> void:
	var region_id = portal_to_region.get(portal_id, "")
	if region_id == "":
		return

	if not MindscapeRegionManager.is_region_unlocked(region_id):
		var region_name = portal_names.get(portal_id, portal_id)
		var unlock_text = MindscapeRegionManager.get_unlock_requirement_text(region_id)
		_show_dialogue("Region Locked", region_name + " is not yet accessible.\n\n" + unlock_text)
		return

	# Play portal activation sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_portal_activate"):
		audio.play_portal_activate()

	# Save current position
	MindscapeRegionManager.save_player_position("hub", player.position)

	# Travel to region
	MindscapeRegionManager.travel_to_region(region_id, "hub")


func _show_exit_dialog() -> void:
	_show_dialogue("Leave Mindscape?", "Return to your room?", _exit_to_bedroom)


func _exit_to_bedroom() -> void:
	_close_dialogue()
	GameManager.player_data["transition_type"] = "exit"
	GameManager.player_data["transition_target"] = "res://scenes/bedroom/bedroom.tscn"
	get_tree().change_scene_to_file("res://scenes/transition/headset_transition.tscn")


var dialogue_callback: Callable = Callable()

func _show_dialogue(title: String, text: String, callback: Callable = Callable(), voice_path: String = "") -> void:
	speaker_name.text = title
	dialogue_text.text = text
	_hide_interaction_prompt()
	dialogue_panel.visible = true
	dialogue_callback = callback

	# Play voice if provided
	if voice_path != "":
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_voice_from_path"):
			audio.play_voice_from_path(voice_path)

	# Disconnect previous connections
	var connections = dialogue_continue.pressed.get_connections()
	for conn in connections:
		dialogue_continue.pressed.disconnect(conn.callable)

	# Always connect to close handler which will also call callback
	dialogue_continue.pressed.connect(_close_dialogue_with_callback, CONNECT_ONE_SHOT)


func _close_dialogue_with_callback() -> void:
	dialogue_panel.visible = false
	if dialogue_callback.is_valid():
		dialogue_callback.call()
		dialogue_callback = Callable()


func _close_dialogue() -> void:
	dialogue_panel.visible = false
	dialogue_callback = Callable()


var selected_focus_difficulty: int = 0  # 0 = EASY, 1 = HARD
var selected_focus_duration: int = 25  # Default 25 minutes
const FOCUS_DURATIONS = [15, 25, 45, 60]

func _open_focus_zone() -> void:
	zone_title.text = "Focus Chamber"
	_clear_zone_body()
	_create_focus_chamber_graphic()

	var desc = Label.new()
	desc.text = "Begin a focused session to grow your aspects."
	desc.add_theme_font_size_override("font_size", 20)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(desc)

	# Duration selection
	_add_section_label("Duration")

	var dur_row = HBoxContainer.new()
	dur_row.add_theme_constant_override("separation", 10)
	dur_row.name = "DurationRow"

	for dur in FOCUS_DURATIONS:
		var dur_btn = Button.new()
		dur_btn.text = str(dur) + "m"
		dur_btn.toggle_mode = true
		dur_btn.button_pressed = (selected_focus_duration == dur)
		dur_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dur_btn.custom_minimum_size = Vector2(0, 50)
		dur_btn.add_theme_font_size_override("font_size", 20)
		dur_btn.name = "Dur" + str(dur) + "Btn"
		dur_btn.pressed.connect(_select_focus_duration.bind(dur))
		dur_row.add_child(dur_btn)

	zone_body.add_child(dur_row)

	# Difficulty selection
	_add_section_label("Difficulty")

	var diff_row = HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 15)

	var easy_btn = Button.new()
	easy_btn.text = "EASY (0.7x)"
	easy_btn.toggle_mode = true
	easy_btn.button_pressed = (selected_focus_difficulty == 0)
	easy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	easy_btn.custom_minimum_size = Vector2(0, 55)
	easy_btn.add_theme_font_size_override("font_size", 18)
	easy_btn.name = "EasyBtn"
	easy_btn.tooltip_text = "Complete session anytime. Lower XP rewards."
	easy_btn.pressed.connect(_select_focus_difficulty.bind(0))
	diff_row.add_child(easy_btn)

	var hard_btn = Button.new()
	hard_btn.text = "HARD (1.5x)"
	hard_btn.toggle_mode = true
	hard_btn.button_pressed = (selected_focus_difficulty == 1)
	hard_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hard_btn.custom_minimum_size = Vector2(0, 55)
	hard_btn.add_theme_font_size_override("font_size", 18)
	hard_btn.name = "HardBtn"
	hard_btn.tooltip_text = "Must complete 90%+ of session. Higher XP rewards."
	hard_btn.pressed.connect(_select_focus_difficulty.bind(1))
	diff_row.add_child(hard_btn)

	zone_body.add_child(diff_row)

	# Quick Start section
	_add_section_label("Quick Start")

	var quick_btn = Button.new()
	quick_btn.text = "Start %d-min Session" % selected_focus_duration
	quick_btn.custom_minimum_size = Vector2(0, 70)
	quick_btn.add_theme_font_size_override("font_size", 22)
	quick_btn.name = "QuickStartBtn"
	quick_btn.pressed.connect(_start_quick_focus)
	zone_body.add_child(quick_btn)

	# Recent topics (if any)
	var recent = _get_recent_topics()
	if recent.size() > 0:
		_add_section_label("Recent")
		for topic in recent.slice(0, 3):  # Show max 3 recent
			var recent_btn = Button.new()
			recent_btn.text = topic.name
			recent_btn.custom_minimum_size = Vector2(0, 50)
			recent_btn.add_theme_font_size_override("font_size", 18)
			recent_btn.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
			recent_btn.pressed.connect(_start_topic_focus.bind(topic.id, topic.name))
			zone_body.add_child(recent_btn)

	# Your Topics section
	_add_section_label("Your Topics")

	var all_topics = HabitManager.get_all_topics()
	if all_topics.is_empty():
		var no_topics = Label.new()
		no_topics.text = "No topics yet. Create one below!"
		no_topics.add_theme_font_size_override("font_size", 18)
		no_topics.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
		zone_body.add_child(no_topics)
	else:
		for topic in all_topics:
			var is_completed = HabitManager.is_topic_completed_today(topic.id)

			var topic_row = HBoxContainer.new()
			topic_row.add_theme_constant_override("separation", 10)

			var btn = Button.new()
			if is_completed:
				btn.text = topic.name + "  (Done)"
				btn.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
			else:
				btn.text = topic.name
			btn.custom_minimum_size = Vector2(0, 55)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.add_theme_font_size_override("font_size", 20)
			btn.pressed.connect(_start_topic_focus.bind(topic.id, topic.name))
			topic_row.add_child(btn)

			# Stats button
			var stats_btn = Button.new()
			stats_btn.text = "i"
			stats_btn.custom_minimum_size = Vector2(40, 40)
			stats_btn.add_theme_font_size_override("font_size", 16)
			stats_btn.tooltip_text = "View stats"
			stats_btn.pressed.connect(_show_topic_stats.bind(topic.id))
			topic_row.add_child(stats_btn)

			zone_body.add_child(topic_row)

	# Add create topic button
	var create_topic_btn = Button.new()
	create_topic_btn.text = "+ Create New Topic"
	create_topic_btn.custom_minimum_size = Vector2(0, 50)
	create_topic_btn.add_theme_font_size_override("font_size", 18)
	create_topic_btn.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9))
	create_topic_btn.pressed.connect(_show_create_topic_dialog)
	zone_body.add_child(create_topic_btn)

	# Focus History section
	_add_section_label("History & Stats")

	var history_btn = Button.new()
	history_btn.text = "View Focus History"
	history_btn.custom_minimum_size = Vector2(0, 50)
	history_btn.add_theme_font_size_override("font_size", 18)
	history_btn.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	history_btn.pressed.connect(_show_focus_history)
	zone_body.add_child(history_btn)

	# Scripts section (from Script Lab)
	var all_scripts = ScriptManager.get_all_scripts()
	if all_scripts.size() > 0:
		_add_section_label("Your Scripts")

		for script in all_scripts:
			var script_btn = Button.new()
			var type_icon = _get_script_type_icon(script.get("type", 0))
			script_btn.text = type_icon + " " + script.name + ".psa"
			script_btn.custom_minimum_size = Vector2(0, 55)
			script_btn.add_theme_font_size_override("font_size", 18)
			script_btn.add_theme_color_override("font_color", ScriptManager.get_type_color(script.get("type", 0)))
			script_btn.pressed.connect(_run_script.bind(script.id))
			zone_body.add_child(script_btn)

			# Show execution count
			if script.times_executed > 0:
				var exec_label = Label.new()
				exec_label.text = "    Executed " + str(script.times_executed) + "x"
				exec_label.add_theme_font_size_override("font_size", 14)
				exec_label.add_theme_color_override("font_color", Color(0.45, 0.5, 0.6))
				zone_body.add_child(exec_label)

	_hide_interaction_prompt()
	zone_panel.visible = true
	in_zone_panel = true


func _get_script_type_icon(type: int) -> String:
	match type:
		ScriptManager.ScriptType.UPDATE:
			return "↑"
		ScriptManager.ScriptType.UPGRADE:
			return "⬆"
		ScriptManager.ScriptType.DOWNGRADE:
			return "↓"
		ScriptManager.ScriptType.VIRUS:
			return "⚠"
	return "•"


func _run_script(script_id: String) -> void:
	if not ScriptManager.scripts.has(script_id):
		return

	var script = ScriptManager.scripts[script_id]
	_close_zone()

	# Set up focus session with script data
	GameManager.player_data["pending_focus"] = {
		"topic": script.name + ".psa",
		"script_id": script_id,
		"lines": script.lines,
		"aspect": script.aspect,
		"duration": 25,
		"difficulty": selected_focus_difficulty
	}

	# Mark execution in ScriptManager
	ScriptManager.execute_script(script_id)

	GameManager.goto_scene("res://scenes/focus_mode/focus_mode.tscn")


func _add_section_label(text: String) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	zone_body.add_child(spacer)

	var label = Label.new()
	label.text = "── " + text + " ──"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_body.add_child(label)


func _select_focus_duration(dur: int) -> void:
	selected_focus_duration = dur

	# Update duration button states
	var dur_row = zone_body.find_child("DurationRow", true, false)
	if dur_row:
		for d in FOCUS_DURATIONS:
			var btn = dur_row.get_node_or_null("Dur" + str(d) + "Btn")
			if btn:
				btn.button_pressed = (d == dur)

	# Update quick start button text
	var quick_btn = zone_body.find_child("QuickStartBtn", true, false)
	if quick_btn:
		quick_btn.text = "Start %d-min Session" % dur


func _select_focus_difficulty(diff: int) -> void:
	selected_focus_difficulty = diff
	var easy_btn = zone_body.find_child("EasyBtn", true, false)
	var hard_btn = zone_body.find_child("HardBtn", true, false)
	if easy_btn: easy_btn.button_pressed = (diff == 0)
	if hard_btn: hard_btn.button_pressed = (diff == 1)


func _get_recent_topics() -> Array:
	# Get topics sorted by most recent session
	var all_topics = HabitManager.get_all_topics()
	var with_sessions = all_topics.filter(func(t): return t.get("total_sessions", 0) > 0)
	# Sort by total_sessions descending (most used first)
	with_sessions.sort_custom(func(a, b): return a.get("total_sessions", 0) > b.get("total_sessions", 0))
	return with_sessions


func _start_quick_focus() -> void:
	_close_zone()
	GameManager.player_data["pending_focus"] = {
		"topic": "Focus Session",
		"duration": selected_focus_duration,
		"difficulty": selected_focus_difficulty
	}
	GameManager.goto_scene("res://scenes/focus_mode/focus_mode.tscn")


func _start_topic_focus(topic_id: String, topic_name: String) -> void:
	_close_zone()
	# Use topic's last duration if available, otherwise use selected
	var duration = HabitManager.get_topic_last_duration(topic_id)
	if duration == 25:  # Default, use selected instead
		duration = selected_focus_duration
	GameManager.player_data["pending_focus"] = {
		"topic_id": topic_id,
		"topic": topic_name,
		"duration": duration,
		"difficulty": selected_focus_difficulty
	}
	GameManager.goto_scene("res://scenes/focus_mode/focus_mode.tscn")


# ============ FOCUS HISTORY ============

var focus_history_panel: PanelContainer = null

func _show_focus_history() -> void:
	_close_zone()

	var journal = _load_focus_journal()

	focus_history_panel = PanelContainer.new()
	focus_history_panel.name = "FocusHistoryPanel"
	focus_history_panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	focus_history_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	focus_history_panel.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)

	# Header
	var header = HBoxContainer.new()
	main_vbox.add_child(header)

	var title = Label.new()
	title.text = "Focus History"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(50, 50)
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.pressed.connect(_close_focus_history)
	header.add_child(close_btn)

	# Stats summary
	var stats_panel = PanelContainer.new()
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color(0.1, 0.12, 0.16, 1)
	stats_style.corner_radius_top_left = 8
	stats_style.corner_radius_top_right = 8
	stats_style.corner_radius_bottom_left = 8
	stats_style.corner_radius_bottom_right = 8
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	main_vbox.add_child(stats_panel)

	var stats_margin = MarginContainer.new()
	stats_margin.add_theme_constant_override("margin_left", 20)
	stats_margin.add_theme_constant_override("margin_right", 20)
	stats_margin.add_theme_constant_override("margin_top", 15)
	stats_margin.add_theme_constant_override("margin_bottom", 15)
	stats_panel.add_child(stats_margin)

	var stats_grid = GridContainer.new()
	stats_grid.columns = 4
	stats_grid.add_theme_constant_override("h_separation", 40)
	stats_grid.add_theme_constant_override("v_separation", 8)
	stats_margin.add_child(stats_grid)

	# Calculate stats
	var total_sessions = journal.size()
	var total_minutes = 0
	var this_week_sessions = 0
	var this_week_minutes = 0
	var topics_focused: Dictionary = {}

	var today = Time.get_date_string_from_system()
	var week_ago = _get_date_n_days_ago(7)

	for entry in journal:
		var mins = int(entry.get("duration_minutes", 25))
		total_minutes += mins

		var entry_date = entry.get("date", "")
		if entry_date >= week_ago:
			this_week_sessions += 1
			this_week_minutes += mins

		var topic = entry.get("topic", "Unknown")
		topics_focused[topic] = topics_focused.get(topic, 0) + 1

	_add_focus_stat(stats_grid, "Total Sessions", str(total_sessions))
	_add_focus_stat(stats_grid, "Total Time", "%dh %dm" % [total_minutes / 60, total_minutes % 60])
	_add_focus_stat(stats_grid, "This Week", "%d sessions" % this_week_sessions)
	_add_focus_stat(stats_grid, "Week Time", "%dh %dm" % [this_week_minutes / 60, this_week_minutes % 60])

	# Recent sessions header
	var recent_header = Label.new()
	recent_header.text = "Recent Sessions"
	recent_header.add_theme_font_size_override("font_size", 24)
	recent_header.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	main_vbox.add_child(recent_header)

	# Sessions scroll
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	var sessions_vbox = VBoxContainer.new()
	sessions_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sessions_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(sessions_vbox)

	if journal.is_empty():
		var no_sessions = Label.new()
		no_sessions.text = "No focus sessions yet. Start your first session!"
		no_sessions.add_theme_font_size_override("font_size", 20)
		no_sessions.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
		sessions_vbox.add_child(no_sessions)
	else:
		# Show sessions in reverse chronological order
		var sorted_journal = journal.duplicate()
		sorted_journal.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

		for entry in sorted_journal.slice(0, 20):  # Show last 20
			_add_focus_session_row(sessions_vbox, entry)

	add_child(focus_history_panel)


func _add_focus_stat(grid: GridContainer, label_text: String, value_text: String) -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	grid.add_child(vbox)

	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 28)
	value.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(value)

	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)


func _add_focus_session_row(container: Control, entry: Dictionary) -> void:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.16, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	card.add_theme_stylebox_override("panel", style)
	container.add_child(card)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)

	# Date
	var date_label = Label.new()
	var entry_date = entry.get("date", "Unknown")
	date_label.text = entry_date
	date_label.custom_minimum_size = Vector2(100, 0)
	date_label.add_theme_font_size_override("font_size", 16)
	date_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	hbox.add_child(date_label)

	# Topic
	var topic_label = Label.new()
	topic_label.text = entry.get("topic", "Focus Session")
	topic_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topic_label.add_theme_font_size_override("font_size", 18)
	hbox.add_child(topic_label)

	# Duration
	var dur_label = Label.new()
	dur_label.text = "%d min" % entry.get("duration_minutes", 25)
	dur_label.custom_minimum_size = Vector2(80, 0)
	dur_label.add_theme_font_size_override("font_size", 16)
	dur_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.5))
	dur_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(dur_label)

	# Difficulty badge
	var diff = entry.get("difficulty", "Easy")
	var diff_label = Label.new()
	diff_label.text = diff
	diff_label.custom_minimum_size = Vector2(50, 0)
	diff_label.add_theme_font_size_override("font_size", 14)
	if diff == "Hard":
		diff_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.4))
	else:
		diff_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(diff_label)


func _get_date_n_days_ago(n: int) -> String:
	var unix = Time.get_unix_time_from_system() - (n * 86400)
	var dict = Time.get_datetime_dict_from_unix_time(unix)
	return "%04d-%02d-%02d" % [dict.year, dict.month, dict.day]


func _load_focus_journal() -> Array:
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


func _close_focus_history() -> void:
	if focus_history_panel:
		focus_history_panel.queue_free()
		focus_history_panel = null


func _open_habits_zone() -> void:
	zone_title.text = "Daily Rituals"
	_clear_zone_body()
	_create_daily_rituals_graphic()

	# Check for habits needing recovery
	var at_risk = HabitManager.get_habits_needing_recovery()
	if at_risk.size() > 0:
		_show_streak_recovery_section(at_risk)
		_add_habit_spacer(16)

	var intro = Label.new()
	intro.text = "Your daily rituals shape who you become. Complete them to grow your aspects."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_font_size_override("font_size", 20)
	zone_body.add_child(intro)

	# Journal quick access row
	var journal_row = HBoxContainer.new()
	journal_row.add_theme_constant_override("separation", 12)

	var journal_hint = Label.new()
	journal_hint.text = "📝 Add notes when completing habits"
	journal_hint.add_theme_font_size_override("font_size", 14)
	journal_hint.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
	journal_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_row.add_child(journal_hint)

	var journal_btn = Button.new()
	var journal_count = _load_journal().size()
	journal_btn.text = "📔 Journal (" + str(journal_count) + ")"
	journal_btn.custom_minimum_size = Vector2(120, 32)
	journal_btn.add_theme_font_size_override("font_size", 14)
	journal_btn.pressed.connect(_open_journal_viewer)
	journal_row.add_child(journal_btn)

	zone_body.add_child(journal_row)
	_add_habit_spacer(8)

	# Show grace days available with progress info
	var grace_row = HBoxContainer.new()
	grace_row.add_theme_constant_override("separation", 15)

	var grace_label = Label.new()
	var grace_count = HabitManager.get_grace_days()
	grace_label.text = "💫 Grace Days: " + str(grace_count) + "/" + str(HabitManager.MAX_GRACE_DAYS)
	grace_label.add_theme_font_size_override("font_size", 16)
	if grace_count > 0:
		grace_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.5))
	else:
		grace_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	grace_row.add_child(grace_label)

	# Show next grace day progress
	var next_grace_info = _get_next_grace_day_info()
	if next_grace_info != "" and grace_count < HabitManager.MAX_GRACE_DAYS:
		var next_label = Label.new()
		next_label.text = next_grace_info
		next_label.add_theme_font_size_override("font_size", 14)
		next_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
		grace_row.add_child(next_label)

	zone_body.add_child(grace_row)

	_add_habit_spacer(8)

	# Tag filter
	var all_tags = HabitManager.get_all_tags()
	if all_tags.size() > 0:
		var filter_row = HBoxContainer.new()
		filter_row.add_theme_constant_override("separation", 8)

		var filter_label = Label.new()
		filter_label.text = "Filter:"
		filter_label.add_theme_font_size_override("font_size", 14)
		filter_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		filter_row.add_child(filter_label)

		var all_btn = Button.new()
		all_btn.text = "All"
		all_btn.toggle_mode = true
		all_btn.button_pressed = (_habit_tag_filter == "")
		all_btn.custom_minimum_size = Vector2(50, 30)
		all_btn.add_theme_font_size_override("font_size", 14)
		all_btn.pressed.connect(_filter_habits_by_tag.bind(""))
		filter_row.add_child(all_btn)

		for tag in all_tags:
			var tag_btn = Button.new()
			tag_btn.text = "#" + tag
			tag_btn.toggle_mode = true
			tag_btn.button_pressed = (_habit_tag_filter == tag)
			tag_btn.custom_minimum_size = Vector2(0, 30)
			tag_btn.add_theme_font_size_override("font_size", 14)
			var tag_color = HabitManager.get_tag_color(tag)
			tag_btn.add_theme_color_override("font_color", tag_color)
			tag_btn.pressed.connect(_filter_habits_by_tag.bind(tag))
			filter_row.add_child(tag_btn)

		zone_body.add_child(filter_row)
		_add_habit_spacer(8)

	var habits = HabitManager.get_all_habits()

	# Apply tag filter
	if _habit_tag_filter != "":
		habits = habits.filter(func(h): return _habit_tag_filter in h.get("tags", []))

	if habits.is_empty():
		var label = Label.new()
		if _habit_tag_filter != "":
			label.text = "No habits with tag #" + _habit_tag_filter + "\nTry a different filter or create new habits."
		else:
			label.text = "No habits tracked yet.\nCreate your first daily ritual!"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		zone_body.add_child(label)
	else:
		# Count incomplete habits (in current filter)
		var incomplete_count = 0
		for habit in habits:
			if not HabitManager.is_completed_today(habit.id):
				incomplete_count += 1

		# Show bulk complete button if there are incomplete habits
		if incomplete_count > 1:
			var bulk_row = HBoxContainer.new()
			bulk_row.add_theme_constant_override("separation", 10)

			var bulk_btn = Button.new()
			bulk_btn.text = "Complete All (%d remaining)" % incomplete_count
			bulk_btn.custom_minimum_size = Vector2(0, 45)
			bulk_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bulk_btn.add_theme_font_size_override("font_size", 18)
			bulk_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
			bulk_btn.pressed.connect(_bulk_complete_habits)
			bulk_row.add_child(bulk_btn)

			zone_body.add_child(bulk_row)
			_add_habit_spacer(8)

		for habit in habits:
			var is_completed = HabitManager.is_completed_today(habit.id)

			# Container for habit row + description
			var habit_container = VBoxContainer.new()
			habit_container.add_theme_constant_override("separation", 2)

			var habit_row = HBoxContainer.new()
			habit_row.add_theme_constant_override("separation", 10)

			# Icon + checkbox
			var icon_emoji = HabitManager.get_habit_emoji(habit.id)
			var checkbox = CheckBox.new()
			checkbox.text = icon_emoji + " " + habit.get("name", "Habit")
			checkbox.button_pressed = is_completed
			checkbox.add_theme_font_size_override("font_size", 22)
			checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			if is_completed:
				checkbox.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
			else:
				checkbox.add_theme_color_override("font_color", Color(1, 1, 1))

			checkbox.toggled.connect(_on_habit_toggled.bind(habit.get("id", "")))
			habit_row.add_child(checkbox)

			# Reorder buttons
			var reorder_container = VBoxContainer.new()
			reorder_container.add_theme_constant_override("separation", 0)

			var up_btn = Button.new()
			up_btn.text = "▲"
			up_btn.custom_minimum_size = Vector2(28, 18)
			up_btn.add_theme_font_size_override("font_size", 10)
			up_btn.tooltip_text = "Move up"
			up_btn.pressed.connect(_move_habit_up.bind(habit.id))
			reorder_container.add_child(up_btn)

			var down_btn = Button.new()
			down_btn.text = "▼"
			down_btn.custom_minimum_size = Vector2(28, 18)
			down_btn.add_theme_font_size_override("font_size", 10)
			down_btn.tooltip_text = "Move down"
			down_btn.pressed.connect(_move_habit_down.bind(habit.id))
			reorder_container.add_child(down_btn)

			habit_row.add_child(reorder_container)

			# Stats button
			var stats_btn = Button.new()
			stats_btn.text = "i"
			stats_btn.custom_minimum_size = Vector2(35, 35)
			stats_btn.add_theme_font_size_override("font_size", 16)
			stats_btn.tooltip_text = "View stats"
			stats_btn.pressed.connect(_show_habit_stats.bind(habit.id))
			habit_row.add_child(stats_btn)

			# Streak indicator with scaling fire
			var streak = habit.get("streak", 0)
			var best_streak = habit.get("best_streak", 0)
			if streak > 0:
				var streak_label = Label.new()
				var fire_icon = _get_streak_fire(streak)
				streak_label.text = fire_icon + " %d" % streak
				streak_label.add_theme_font_size_override("font_size", 18)
				streak_label.add_theme_color_override("font_color", _get_streak_color(streak))
				streak_label.tooltip_text = "Best: %d days" % best_streak
				habit_row.add_child(streak_label)

			habit_container.add_child(habit_row)

			# Show description if exists
			var description = habit.get("description", "")
			if description != "":
				var desc_label = Label.new()
				desc_label.text = "    " + description
				desc_label.add_theme_font_size_override("font_size", 14)
				desc_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
				desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
				habit_container.add_child(desc_label)

			# Show tags if any
			var tags = habit.get("tags", [])
			if tags.size() > 0:
				var tags_row = HBoxContainer.new()
				tags_row.add_theme_constant_override("separation", 6)

				var tags_prefix = Label.new()
				tags_prefix.text = "    "
				tags_row.add_child(tags_prefix)

				for tag in tags:
					var tag_label = Label.new()
					tag_label.text = "#" + tag
					tag_label.add_theme_font_size_override("font_size", 12)
					var tag_color = HabitManager.get_tag_color(tag)
					tag_label.add_theme_color_override("font_color", tag_color)
					tags_row.add_child(tag_label)

				habit_container.add_child(tags_row)

			zone_body.add_child(habit_container)

	_add_habit_spacer(16)

	var add_button = Button.new()
	add_button.text = "+ Create New Habit"
	add_button.custom_minimum_size = Vector2(0, 50)
	add_button.add_theme_font_size_override("font_size", 20)
	add_button.pressed.connect(_show_habit_creation_form)
	zone_body.add_child(add_button)

	# Archived habits section
	var archived = HabitManager.get_archived_habits()
	if archived.size() > 0:
		_add_section_label("Archived (" + str(archived.size()) + ")")

		for habit in archived:
			var archived_row = HBoxContainer.new()
			archived_row.add_theme_constant_override("separation", 10)

			var name_label = Label.new()
			name_label.text = habit.name
			name_label.add_theme_font_size_override("font_size", 18)
			name_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			archived_row.add_child(name_label)

			var restore_btn = Button.new()
			restore_btn.text = "Restore"
			restore_btn.custom_minimum_size = Vector2(80, 35)
			restore_btn.add_theme_font_size_override("font_size", 14)
			restore_btn.pressed.connect(_unarchive_habit.bind(habit.id))
			archived_row.add_child(restore_btn)

			var stats_btn = Button.new()
			stats_btn.text = "i"
			stats_btn.custom_minimum_size = Vector2(35, 35)
			stats_btn.add_theme_font_size_override("font_size", 14)
			stats_btn.pressed.connect(_show_habit_stats.bind(habit.id))
			archived_row.add_child(stats_btn)

			zone_body.add_child(archived_row)

	_hide_interaction_prompt()
	zone_panel.visible = true
	in_zone_panel = true


func _on_habit_toggled(toggled: bool, habit_id: String) -> void:
	if toggled:
		# Show note dialog before completing habit
		_show_habit_note_dialog(habit_id)


func _show_habit_note_dialog(habit_id: String) -> void:
	pending_habit_id = habit_id
	var habit = HabitManager.habits.get(habit_id, {})
	var habit_name = habit.get("name", "Habit")

	# Create the dialog
	habit_note_dialog = PanelContainer.new()
	habit_note_dialog.anchors_preset = Control.PRESET_CENTER
	habit_note_dialog.offset_left = -280
	habit_note_dialog.offset_top = -200
	habit_note_dialog.offset_right = 280
	habit_note_dialog.offset_bottom = 200

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.98)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.5, 0.7, 0.5, 0.9)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	habit_note_dialog.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 15)
	habit_note_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Header
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "Complete: " + habit_name
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(_cancel_habit_note)
	header.add_child(close_btn)
	vbox.add_child(header)

	# Instruction
	var instruction = Label.new()
	instruction.text = "Add a quick note about this completion (optional):"
	instruction.add_theme_font_size_override("font_size", 14)
	instruction.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	vbox.add_child(instruction)

	# Note input
	habit_note_input = TextEdit.new()
	habit_note_input.placeholder_text = "What did you do? How did it go? Any reflections..."
	habit_note_input.custom_minimum_size = Vector2(0, 120)
	habit_note_input.add_theme_font_size_override("font_size", 16)
	habit_note_input.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(habit_note_input)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var skip_btn = Button.new()
	skip_btn.text = "Skip Note"
	skip_btn.custom_minimum_size = Vector2(120, 45)
	skip_btn.add_theme_font_size_override("font_size", 16)
	skip_btn.pressed.connect(_submit_habit_note.bind(true))
	btn_row.add_child(skip_btn)

	var save_btn = Button.new()
	save_btn.text = "Save & Complete"
	save_btn.custom_minimum_size = Vector2(160, 45)
	save_btn.add_theme_font_size_override("font_size", 16)
	save_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	save_btn.pressed.connect(_submit_habit_note.bind(false))
	btn_row.add_child(save_btn)

	vbox.add_child(btn_row)

	# Tip about journal
	var tip = Label.new()
	tip.text = "Tip: View all your notes in the Journal (Menu > Progress > Journal)"
	tip.add_theme_font_size_override("font_size", 12)
	tip.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tip)

	add_child(habit_note_dialog)
	habit_note_input.grab_focus()


func _cancel_habit_note() -> void:
	if habit_note_dialog:
		habit_note_dialog.queue_free()
		habit_note_dialog = null
	pending_habit_id = ""
	habit_note_input = null
	_open_habits_zone()


func _submit_habit_note(skip_note: bool) -> void:
	var note_text = ""
	if not skip_note and habit_note_input:
		note_text = habit_note_input.text.strip_edges()

	# Complete the habit
	var habit = HabitManager.complete_habit(pending_habit_id)

	if habit:
		# Save journal entry
		var entry = {
			"type": "habit",
			"timestamp": Time.get_unix_time_from_system(),
			"date": Time.get_date_string_from_system(),
			"habit_id": pending_habit_id,
			"habit_name": habit.get("name", ""),
			"note": note_text,
			"streak": habit.get("streak", 1),
			"domain": HabitManager._domain_to_string(habit.get("domain", 0))
		}
		_save_journal_entry(entry)

		# Close dialog
		if habit_note_dialog:
			habit_note_dialog.queue_free()
			habit_note_dialog = null
		pending_habit_id = ""
		habit_note_input = null

		# Show completion message
		_close_zone()
		var streak = habit.get("streak", 1)
		var exp = habit.get("exp_reward", 25)
		var streak_bonus = int(exp * streak * 0.1)

		# Check for milestone celebration
		var milestone = _get_streak_milestone(streak)
		if milestone > 0:
			_spawn_celebration_effects(milestone)
			var msg = "🎉 " + habit.name + " MILESTONE! 🎉\n\n"
			msg += _get_milestone_message(milestone) + "\n\n"
			msg += "+" + str(exp + streak_bonus) + " XP\n🔥 " + str(streak) + " day streak!"
			if note_text != "":
				msg += "\n\n📝 Note saved to journal"
			_show_dialogue("🏆 Streak Milestone!", msg, _open_habits_zone)
		else:
			var msg = habit.name + " done!\n\n+" + str(exp + streak_bonus) + " XP (includes streak bonus)\n🔥 " + str(streak) + " day streak!"
			if note_text != "":
				msg += "\n\n📝 Note saved to journal"
			_show_dialogue("Habit Complete!", msg, _open_habits_zone)


func _move_habit_up(habit_id: String) -> void:
	HabitManager.move_habit_up(habit_id)
	_open_habits_zone()  # Refresh the list


func _move_habit_down(habit_id: String) -> void:
	HabitManager.move_habit_down(habit_id)
	_open_habits_zone()  # Refresh the list


func _bulk_complete_habits() -> void:
	var habits = HabitManager.get_all_habits()
	var completed_count = 0
	var total_xp = 0

	for habit in habits:
		if not HabitManager.is_completed_today(habit.id):
			var result = HabitManager.complete_habit(habit.id)
			if result:
				completed_count += 1
				var streak = result.get("streak", 1)
				var exp = result.get("exp_reward", 25)
				var streak_bonus = int(exp * streak * 0.1)
				total_xp += exp + streak_bonus

				# Save journal entry for bulk completed habit
				var entry = {
					"type": "habit",
					"timestamp": Time.get_unix_time_from_system(),
					"date": Time.get_date_string_from_system(),
					"habit_id": habit.id,
					"habit_name": result.get("name", ""),
					"note": "(Bulk completed)",
					"streak": streak,
					"domain": HabitManager._domain_to_string(result.get("domain", 0))
				}
				_save_journal_entry(entry)

	if completed_count > 0:
		_close_zone()
		_show_dialogue("All Habits Complete!", "%d habits completed!\n\n+%d XP total\n\n📔 All entries saved to journal\n\nKeep up the great work!" % [completed_count, total_xp], _open_habits_zone)


# Streak milestone thresholds
const STREAK_MILESTONES = [3, 7, 14, 21, 30, 60, 90, 100, 180, 365]


func _get_streak_milestone(streak: int) -> int:
	## Returns the milestone if streak exactly matches one, otherwise 0
	if streak in STREAK_MILESTONES:
		return streak
	return 0


func _get_milestone_message(milestone: int) -> String:
	## Returns a special message for each milestone
	match milestone:
		3:
			return "Three days strong!\nYou're building momentum."
		7:
			return "A FULL WEEK!\nConsistency is your superpower."
		14:
			return "TWO WEEKS!\nThis habit is becoming part of you."
		21:
			return "21 DAYS - HABIT FORMED!\nScience says you've rewired your brain!"
		30:
			return "ONE MONTH!\nYou're unstoppable now."
		60:
			return "TWO MONTHS!\nThis is who you are now."
		90:
			return "90 DAYS - LIFESTYLE ACHIEVED!\nYou've transformed."
		100:
			return "💯 ONE HUNDRED DAYS! 💯\nLEGENDARY STATUS ACHIEVED!"
		180:
			return "SIX MONTHS!\nHalf a year of dedication. Incredible."
		365:
			return "🏆 ONE FULL YEAR! 🏆\nYou are a MASTER of discipline!"
		_:
			return "Amazing milestone achieved!"


func _spawn_celebration_effects(milestone: int) -> void:
	## Spawn visual celebration effects for streak milestones
	var effect_intensity = 1.0
	if milestone >= 21:
		effect_intensity = 1.5
	if milestone >= 30:
		effect_intensity = 2.0
	if milestone >= 100:
		effect_intensity = 3.0

	# Create celebration container
	var celebration = Node2D.new()
	celebration.name = "CelebrationEffects"
	celebration.z_index = 100
	add_child(celebration)

	# Spawn confetti particles
	var num_particles = int(30 * effect_intensity)
	var colors = [
		Color(1.0, 0.8, 0.2),   # Gold
		Color(1.0, 0.4, 0.3),   # Red
		Color(0.4, 0.8, 1.0),   # Blue
		Color(0.5, 1.0, 0.5),   # Green
		Color(1.0, 0.5, 0.8),   # Pink
		Color(0.8, 0.6, 1.0)    # Purple
	]

	var viewport_size = get_viewport().get_visible_rect().size

	for i in range(num_particles):
		var confetti = Polygon2D.new()
		var size = randf_range(8, 16) * (effect_intensity * 0.5 + 0.5)
		confetti.polygon = PackedVector2Array([
			Vector2(-size/2, -size/2), Vector2(size/2, -size/2),
			Vector2(size/2, size/2), Vector2(-size/2, size/2)
		])
		confetti.color = colors[randi() % colors.size()]
		confetti.position = Vector2(
			randf_range(0, viewport_size.x),
			-randf_range(20, 100)
		)
		confetti.rotation = randf() * TAU
		celebration.add_child(confetti)

		# Animate falling with rotation
		var fall_duration = randf_range(2.0, 4.0)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(confetti, "position:y", viewport_size.y + 50, fall_duration)
		tween.tween_property(confetti, "rotation", confetti.rotation + randf_range(-TAU, TAU), fall_duration)
		tween.tween_property(confetti, "modulate:a", 0.0, fall_duration).set_delay(fall_duration * 0.7)

	# Spawn sparkle bursts
	var num_sparkles = int(8 * effect_intensity)
	for i in range(num_sparkles):
		var sparkle = Polygon2D.new()
		sparkle.polygon = PackedVector2Array([
			Vector2(-3, 0), Vector2(0, -12), Vector2(3, 0), Vector2(0, 12)
		])
		sparkle.color = Color(1.0, 1.0, 0.8, 1.0)
		sparkle.position = Vector2(
			viewport_size.x / 2 + randf_range(-200, 200),
			viewport_size.y / 2 + randf_range(-100, 100)
		)
		sparkle.scale = Vector2.ZERO
		celebration.add_child(sparkle)

		var sparkle_tween = create_tween()
		sparkle_tween.tween_property(sparkle, "scale", Vector2(1.5, 1.5), 0.3).set_ease(Tween.EASE_OUT)
		sparkle_tween.tween_property(sparkle, "scale", Vector2.ZERO, 0.3).set_delay(0.1)
		sparkle_tween.tween_property(sparkle, "modulate:a", 0.0, 0.2)

	# Play celebration sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx_from_path"):
		audio.play_sfx_from_path("res://audio/sfx/achievement_unlock.wav")

	# Clean up after animations
	var cleanup_timer = get_tree().create_timer(5.0)
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(celebration):
			celebration.queue_free()
	)


func _show_habit_stats(habit_id: String) -> void:
	if not HabitManager.habits.has(habit_id):
		return

	var habit = HabitManager.habits[habit_id]
	zone_title.text = habit.name + " Stats"
	_clear_zone_body()

	# Current streak
	var streak = habit.get("streak", 0)
	var best_streak = habit.get("best_streak", 0)
	var total = habit.get("total_completions", 0)

	# Streak section
	var streak_container = VBoxContainer.new()
	streak_container.add_theme_constant_override("separation", 8)

	var streak_row = HBoxContainer.new()
	streak_row.add_theme_constant_override("separation", 20)

	# Current streak
	var current_vbox = VBoxContainer.new()
	current_vbox.add_theme_constant_override("separation", 2)
	var current_label = Label.new()
	current_label.text = "Current Streak"
	current_label.add_theme_font_size_override("font_size", 16)
	current_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	current_vbox.add_child(current_label)
	var current_value = Label.new()
	current_value.text = _get_streak_fire(streak) + " " + str(streak) + " days"
	current_value.add_theme_font_size_override("font_size", 28)
	current_value.add_theme_color_override("font_color", _get_streak_color(streak) if streak > 0 else Color(0.5, 0.5, 0.6))
	current_vbox.add_child(current_value)
	streak_row.add_child(current_vbox)

	# Best streak
	var best_vbox = VBoxContainer.new()
	best_vbox.add_theme_constant_override("separation", 2)
	var best_label = Label.new()
	best_label.text = "Best Streak"
	best_label.add_theme_font_size_override("font_size", 16)
	best_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	best_vbox.add_child(best_label)
	var best_value = Label.new()
	best_value.text = str(best_streak) + " days"
	best_value.add_theme_font_size_override("font_size", 28)
	best_value.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	best_vbox.add_child(best_value)
	streak_row.add_child(best_vbox)

	streak_container.add_child(streak_row)
	zone_body.add_child(streak_container)

	# Monthly streak calendar
	_add_habit_spacer(10)
	var calendar_label = Label.new()
	var date = Time.get_date_dict_from_system()
	var month_names = ["", "January", "February", "March", "April", "May", "June",
						"July", "August", "September", "October", "November", "December"]
	calendar_label.text = month_names[date.month] + " " + str(date.year)
	calendar_label.add_theme_font_size_override("font_size", 18)
	calendar_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	calendar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_body.add_child(calendar_label)

	_add_habit_spacer(5)

	# Day headers
	var header_row = HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_theme_constant_override("separation", 4)
	var day_headers = ["S", "M", "T", "W", "T", "F", "S"]
	for dh in day_headers:
		var header = Label.new()
		header.text = dh
		header.custom_minimum_size = Vector2(28, 20)
		header.add_theme_font_size_override("font_size", 12)
		header.add_theme_color_override("font_color", Color(0.45, 0.5, 0.55))
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header_row.add_child(header)
	zone_body.add_child(header_row)

	# Get completions for this month (up to 31 days back)
	var recent = HabitManager.get_recent_completions(habit_id, 31)

	# Calculate first day of month and days in month
	var first_of_month = Time.get_datetime_dict_from_datetime_string(
		"%04d-%02d-01T00:00:00" % [date.year, date.month], false)
	var first_weekday = first_of_month.weekday  # 0=Sunday
	var days_in_month = _get_days_in_month(date.month, date.year)
	var today_day = date.day

	# Calendar grid
	var calendar_container = VBoxContainer.new()
	calendar_container.add_theme_constant_override("separation", 4)

	var week_container: HBoxContainer = null
	var day_counter = 1

	# Add empty cells for days before the 1st
	week_container = HBoxContainer.new()
	week_container.alignment = BoxContainer.ALIGNMENT_CENTER
	week_container.add_theme_constant_override("separation", 4)

	for _i in range(first_weekday):
		var empty = Control.new()
		empty.custom_minimum_size = Vector2(28, 28)
		week_container.add_child(empty)

	# Fill in days
	for d in range(1, days_in_month + 1):
		if week_container.get_child_count() >= 7:
			calendar_container.add_child(week_container)
			week_container = HBoxContainer.new()
			week_container.alignment = BoxContainer.ALIGNMENT_CENTER
			week_container.add_theme_constant_override("separation", 4)

		var day_cell = ColorRect.new()
		day_cell.custom_minimum_size = Vector2(28, 28)

		# Calculate days ago for this date
		var days_ago = today_day - d
		if days_ago >= 0 and days_ago < recent.size():
			if recent[days_ago]:
				day_cell.color = Color(0.35, 0.7, 0.4)  # Green for completed
			else:
				day_cell.color = Color(0.2, 0.2, 0.25)  # Gray for missed
		else:
			day_cell.color = Color(0.15, 0.15, 0.18)  # Darker for future/out of range

		# Highlight today
		if d == today_day:
			day_cell.color = day_cell.color.lightened(0.2)

		week_container.add_child(day_cell)

	# Add remaining empty cells
	while week_container.get_child_count() < 7:
		var empty = Control.new()
		empty.custom_minimum_size = Vector2(28, 28)
		week_container.add_child(empty)
	calendar_container.add_child(week_container)

	zone_body.add_child(calendar_container)

	_add_habit_spacer(15)

	# Total completions
	var total_row = HBoxContainer.new()
	total_row.add_theme_constant_override("separation", 10)
	var total_label = Label.new()
	total_label.text = "Total Completions:"
	total_label.add_theme_font_size_override("font_size", 20)
	total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_row.add_child(total_label)
	var total_value = Label.new()
	total_value.text = str(total)
	total_value.add_theme_font_size_override("font_size", 20)
	total_value.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	total_row.add_child(total_value)
	zone_body.add_child(total_row)

	# XP per completion
	var xp_row = HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 10)
	var xp_label = Label.new()
	xp_label.text = "Base XP:"
	xp_label.add_theme_font_size_override("font_size", 20)
	xp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_row.add_child(xp_label)
	var xp_value = Label.new()
	xp_value.text = str(habit.get("exp_reward", 25)) + " XP"
	xp_value.add_theme_font_size_override("font_size", 20)
	xp_value.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	xp_row.add_child(xp_value)
	zone_body.add_child(xp_row)

	# Domain
	var domain_row = HBoxContainer.new()
	domain_row.add_theme_constant_override("separation", 10)
	var domain_label = Label.new()
	domain_label.text = "Category:"
	domain_label.add_theme_font_size_override("font_size", 20)
	domain_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	domain_row.add_child(domain_label)
	var domain_value = Label.new()
	var domain_names = ["Health", "Learning", "Mindfulness", "Social", "Productivity", "Custom"]
	var domain_idx = habit.get("domain", 5)
	domain_value.text = domain_names[domain_idx] if domain_idx < domain_names.size() else "Custom"
	domain_value.add_theme_font_size_override("font_size", 20)
	domain_value.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	domain_row.add_child(domain_value)
	zone_body.add_child(domain_row)

	# Description if exists
	var description = habit.get("description", "")
	if description != "":
		_add_habit_spacer(10)
		var desc_label = Label.new()
		desc_label.text = "\"" + description + "\""
		desc_label.add_theme_font_size_override("font_size", 18)
		desc_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		zone_body.add_child(desc_label)

	_add_habit_spacer(20)

	# Progress to next grace day
	if streak > 0:
		var progress_in_cycle = streak % HabitManager.GRACE_DAY_RECHARGE_STREAK
		var days_until = HabitManager.GRACE_DAY_RECHARGE_STREAK - progress_in_cycle
		var grace_info = Label.new()
		grace_info.text = "Grace day in " + str(days_until) + " more days of streak"
		grace_info.add_theme_font_size_override("font_size", 16)
		grace_info.add_theme_color_override("font_color", Color(0.6, 0.65, 0.5))
		grace_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		zone_body.add_child(grace_info)

	_add_habit_spacer(20)

	# Action buttons row
	var action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)

	var edit_btn = Button.new()
	edit_btn.text = "Edit"
	edit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_btn.custom_minimum_size = Vector2(0, 45)
	edit_btn.add_theme_font_size_override("font_size", 18)
	edit_btn.pressed.connect(_show_edit_habit_form.bind(habit_id))
	action_row.add_child(edit_btn)

	var is_archived = habit.get("archived", false)
	var archive_btn = Button.new()
	archive_btn.text = "Restore" if is_archived else "Archive"
	archive_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	archive_btn.custom_minimum_size = Vector2(0, 45)
	archive_btn.add_theme_font_size_override("font_size", 18)
	if is_archived:
		archive_btn.pressed.connect(_unarchive_habit.bind(habit_id))
	else:
		archive_btn.pressed.connect(_archive_habit.bind(habit_id))
	action_row.add_child(archive_btn)

	zone_body.add_child(action_row)

	_add_habit_spacer(10)

	# Back button
	var back_btn = Button.new()
	back_btn.text = "Back to Habits"
	back_btn.custom_minimum_size = Vector2(0, 50)
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(_open_habits_zone)
	zone_body.add_child(back_btn)

	# Delete option (subtle, only for custom habits)
	if not habit.get("is_preset", false):
		_add_habit_spacer(10)
		var delete_btn = Button.new()
		delete_btn.text = "Delete Permanently"
		delete_btn.flat = true
		delete_btn.add_theme_font_size_override("font_size", 14)
		delete_btn.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
		delete_btn.pressed.connect(_confirm_delete_habit.bind(habit_id, habit.name))
		zone_body.add_child(delete_btn)


func _show_habit_creation_form() -> void:
	zone_title.text = "Create Habit"
	_clear_zone_body()

	# Name input
	var name_label = Label.new()
	name_label.text = "What habit do you want to build?"
	name_label.add_theme_font_size_override("font_size", 20)
	zone_body.add_child(name_label)

	var name_input = LineEdit.new()
	name_input.name = "HabitNameInput"
	name_input.placeholder_text = "e.g., Morning stretches, Read 20 pages..."
	name_input.custom_minimum_size = Vector2(0, 50)
	name_input.add_theme_font_size_override("font_size", 20)
	zone_body.add_child(name_input)

	_add_habit_spacer(12)

	# Description input
	var desc_label = Label.new()
	desc_label.text = "Description (optional):"
	desc_label.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(desc_label)

	var desc_input = LineEdit.new()
	desc_input.name = "HabitDescInput"
	desc_input.placeholder_text = "A brief reminder of what this habit involves..."
	desc_input.custom_minimum_size = Vector2(0, 45)
	desc_input.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(desc_input)

	_add_habit_spacer(12)

	# Domain selection
	var domain_label = Label.new()
	domain_label.text = "Category:"
	domain_label.add_theme_font_size_override("font_size", 20)
	zone_body.add_child(domain_label)

	var domain_grid = GridContainer.new()
	domain_grid.name = "DomainGrid"
	domain_grid.columns = 3
	domain_grid.add_theme_constant_override("h_separation", 8)
	domain_grid.add_theme_constant_override("v_separation", 8)

	var domains = [
		{"id": 0, "name": "Health", "color": Color(0.9, 0.5, 0.3)},
		{"id": 1, "name": "Learning", "color": Color(0.7, 0.5, 0.8)},
		{"id": 2, "name": "Mindfulness", "color": Color(0.3, 0.6, 0.9)},
		{"id": 3, "name": "Social", "color": Color(0.4, 0.7, 0.5)},
		{"id": 4, "name": "Productivity", "color": Color(0.83, 0.66, 0.29)},
		{"id": 5, "name": "Other", "color": Color(0.6, 0.6, 0.7)}
	]

	for i in range(domains.size()):
		var domain = domains[i]
		var btn = Button.new()
		btn.name = "Domain" + str(domain.id) + "Btn"
		btn.text = domain.name
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_select_habit_domain.bind(domain.id))
		domain_grid.add_child(btn)

	zone_body.add_child(domain_grid)

	_add_habit_spacer(12)

	# Icon selection
	var icon_label = Label.new()
	icon_label.text = "Choose Icon:"
	icon_label.add_theme_font_size_override("font_size", 20)
	zone_body.add_child(icon_label)

	var icon_scroll = ScrollContainer.new()
	icon_scroll.custom_minimum_size = Vector2(0, 55)
	icon_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	icon_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	zone_body.add_child(icon_scroll)

	var icon_grid = HBoxContainer.new()
	icon_grid.name = "IconGrid"
	icon_grid.add_theme_constant_override("separation", 6)
	icon_scroll.add_child(icon_grid)

	var icons = HabitManager.get_available_icons()
	_selected_habit_icon = "custom"  # Reset selection
	for icon_key in icons:
		var icon_data = icons[icon_key]
		var btn = Button.new()
		btn.name = "Icon_" + icon_key
		btn.text = icon_data.emoji
		btn.tooltip_text = icon_data.label
		btn.toggle_mode = true
		btn.button_pressed = (icon_key == "custom")
		btn.custom_minimum_size = Vector2(45, 45)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_select_habit_icon.bind(icon_key))
		icon_grid.add_child(btn)

	_add_habit_spacer(12)

	# Tags input
	var tags_label = Label.new()
	tags_label.text = "Tags (comma-separated, optional):"
	tags_label.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(tags_label)

	var tags_input = LineEdit.new()
	tags_input.name = "HabitTagsInput"
	tags_input.placeholder_text = "e.g., morning, quick, energizing"
	tags_input.custom_minimum_size = Vector2(0, 40)
	tags_input.add_theme_font_size_override("font_size", 16)
	zone_body.add_child(tags_input)

	_add_habit_spacer(20)

	# Action buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 15)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 50)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.pressed.connect(_open_habits_zone)
	button_row.add_child(cancel_btn)

	var create_btn = Button.new()
	create_btn.text = "Create Habit"
	create_btn.custom_minimum_size = Vector2(0, 50)
	create_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_btn.add_theme_font_size_override("font_size", 20)
	create_btn.pressed.connect(_create_habit_from_form)
	button_row.add_child(create_btn)

	zone_body.add_child(button_row)


# Habit form state
var _selected_habit_domain: int = 0  # HabitManager.HabitDomain.HEALTH
var _selected_habit_icon: String = "custom"
var _selected_habit_tags: Array = []
var _habit_tag_filter: String = ""  # Current tag filter for habits view


func _filter_habits_by_tag(tag: String) -> void:
	_habit_tag_filter = tag
	_open_habits_zone()


func _select_habit_domain(domain_id: int) -> void:
	_selected_habit_domain = domain_id
	# Update domain button states
	var grid = zone_body.find_child("DomainGrid", true, false)
	if grid:
		for i in range(6):
			var btn = grid.get_node_or_null("Domain" + str(i) + "Btn")
			if btn:
				btn.button_pressed = (i == domain_id)


func _select_habit_icon(icon_key: String) -> void:
	_selected_habit_icon = icon_key
	# Update icon button visuals
	var icon_grid = zone_body.find_child("IconGrid", true, false)
	if icon_grid:
		for child in icon_grid.get_children():
			if child is Button:
				child.button_pressed = (child.name == "Icon_" + icon_key)


func _create_habit_from_form() -> void:
	var name_input = zone_body.find_child("HabitNameInput", true, false) as LineEdit
	if not name_input or name_input.text.strip_edges() == "":
		_show_dialogue("Error", "Please enter a habit name.")
		return

	var desc_input = zone_body.find_child("HabitDescInput", true, false) as LineEdit
	var description = desc_input.text.strip_edges() if desc_input else ""

	# Parse tags from input
	var tags_input = zone_body.find_child("HabitTagsInput", true, false) as LineEdit
	var tags: Array = []
	if tags_input and tags_input.text.strip_edges() != "":
		var tag_strings = tags_input.text.split(",")
		for tag in tag_strings:
			var cleaned = tag.strip_edges().to_lower()
			if cleaned != "":
				tags.append(cleaned)

	var habit_name = name_input.text.strip_edges()
	HabitManager.create_custom_habit(habit_name, description, _selected_habit_domain, _selected_habit_icon, tags)

	_close_zone()
	var domain_names = ["Health", "Learning", "Mindfulness", "Social", "Productivity", "Custom"]
	var domain_name = domain_names[_selected_habit_domain] if _selected_habit_domain < domain_names.size() else "Custom"
	var icon_emoji = HabitManager.HABIT_ICONS.get(_selected_habit_icon, {}).get("emoji", "⭐")
	var tags_str = ", ".join(tags) if tags.size() > 0 else "none"
	_show_dialogue("Habit Created", icon_emoji + " '" + habit_name + "' has been added!\n\nCategory: " + domain_name + "\nTags: " + tags_str + "\n\nComplete it daily to build your streak.", _open_habits_zone)


func _archive_habit(habit_id: String) -> void:
	if not HabitManager.habits.has(habit_id):
		return
	var name = HabitManager.habits[habit_id].name
	HabitManager.archive_habit(habit_id)
	_close_zone()
	_show_dialogue("Archived", "'" + name + "' has been archived.\n\nYou can restore it from the Archived section.", _open_habits_zone)


func _unarchive_habit(habit_id: String) -> void:
	if not HabitManager.habits.has(habit_id):
		return
	var name = HabitManager.habits[habit_id].name
	HabitManager.unarchive_habit(habit_id)
	_close_zone()
	_show_dialogue("Restored", "'" + name + "' has been restored to your active habits.", _open_habits_zone)


func _confirm_delete_habit(habit_id: String, habit_name: String) -> void:
	_close_zone()
	_show_dialogue("Delete Habit?", "Permanently delete '" + habit_name + "'?\n\nThis will remove all history and cannot be undone.", func():
		HabitManager.delete_habit(habit_id)
		_show_dialogue("Deleted", "Habit deleted.", _open_habits_zone)
	)


var _editing_habit_id: String = ""

func _show_edit_habit_form(habit_id: String) -> void:
	if not HabitManager.habits.has(habit_id):
		return

	var habit = HabitManager.habits[habit_id]
	_editing_habit_id = habit_id

	zone_title.text = "Edit Habit"
	_clear_zone_body()

	# Name input
	var name_label = Label.new()
	name_label.text = "Habit Name"
	name_label.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(name_label)

	var name_input = LineEdit.new()
	name_input.name = "EditHabitName"
	name_input.text = habit.name
	name_input.custom_minimum_size = Vector2(0, 50)
	name_input.add_theme_font_size_override("font_size", 20)
	zone_body.add_child(name_input)

	_add_habit_spacer(10)

	# Description input
	var desc_label = Label.new()
	desc_label.text = "Description"
	desc_label.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(desc_label)

	var desc_input = LineEdit.new()
	desc_input.name = "EditHabitDesc"
	desc_input.text = habit.get("description", "")
	desc_input.placeholder_text = "Optional description..."
	desc_input.custom_minimum_size = Vector2(0, 45)
	desc_input.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(desc_input)

	_add_habit_spacer(10)

	# Domain selection
	var domain_label = Label.new()
	domain_label.text = "Category"
	domain_label.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(domain_label)

	_selected_habit_domain = habit.get("domain", 5)

	var domain_grid = GridContainer.new()
	domain_grid.name = "DomainGrid"
	domain_grid.columns = 3
	domain_grid.add_theme_constant_override("h_separation", 8)
	domain_grid.add_theme_constant_override("v_separation", 8)

	var domains = [
		{"id": 0, "name": "Health"},
		{"id": 1, "name": "Learning"},
		{"id": 2, "name": "Mindfulness"},
		{"id": 3, "name": "Social"},
		{"id": 4, "name": "Productivity"},
		{"id": 5, "name": "Other"}
	]

	for domain in domains:
		var btn = Button.new()
		btn.name = "Domain" + str(domain.id) + "Btn"
		btn.text = domain.name
		btn.toggle_mode = true
		btn.button_pressed = (_selected_habit_domain == domain.id)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_select_habit_domain.bind(domain.id))
		domain_grid.add_child(btn)

	zone_body.add_child(domain_grid)

	_add_habit_spacer(10)

	# Icon selection for edit
	var icon_label = Label.new()
	icon_label.text = "Icon"
	icon_label.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(icon_label)

	var icon_scroll = ScrollContainer.new()
	icon_scroll.custom_minimum_size = Vector2(0, 55)
	icon_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	icon_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	zone_body.add_child(icon_scroll)

	var icon_grid = HBoxContainer.new()
	icon_grid.name = "IconGrid"
	icon_grid.add_theme_constant_override("separation", 6)
	icon_scroll.add_child(icon_grid)

	var icons = HabitManager.get_available_icons()
	var current_icon = habit.get("icon", "custom")
	_selected_habit_icon = current_icon
	for icon_key in icons:
		var icon_data = icons[icon_key]
		var btn = Button.new()
		btn.name = "Icon_" + icon_key
		btn.text = icon_data.emoji
		btn.tooltip_text = icon_data.label
		btn.toggle_mode = true
		btn.button_pressed = (icon_key == current_icon)
		btn.custom_minimum_size = Vector2(45, 45)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_select_habit_icon.bind(icon_key))
		icon_grid.add_child(btn)

	_add_habit_spacer(10)

	# Tags input for edit
	var tags_label = Label.new()
	tags_label.text = "Tags (comma-separated)"
	tags_label.add_theme_font_size_override("font_size", 18)
	zone_body.add_child(tags_label)

	var tags_input = LineEdit.new()
	tags_input.name = "EditHabitTags"
	var current_tags = habit.get("tags", [])
	tags_input.text = ", ".join(current_tags) if current_tags.size() > 0 else ""
	tags_input.placeholder_text = "e.g., morning, quick, energizing"
	tags_input.custom_minimum_size = Vector2(0, 40)
	tags_input.add_theme_font_size_override("font_size", 16)
	zone_body.add_child(tags_input)

	_add_habit_spacer(20)

	# Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.custom_minimum_size = Vector2(0, 50)
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.pressed.connect(_show_habit_stats.bind(habit_id))
	btn_row.add_child(cancel_btn)

	var save_btn = Button.new()
	save_btn.text = "Save Changes"
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.custom_minimum_size = Vector2(0, 50)
	save_btn.add_theme_font_size_override("font_size", 20)
	save_btn.pressed.connect(_save_habit_edits)
	btn_row.add_child(save_btn)

	zone_body.add_child(btn_row)


func _save_habit_edits() -> void:
	if _editing_habit_id == "" or not HabitManager.habits.has(_editing_habit_id):
		return

	var name_input = zone_body.find_child("EditHabitName", true, false) as LineEdit
	var desc_input = zone_body.find_child("EditHabitDesc", true, false) as LineEdit
	var tags_input = zone_body.find_child("EditHabitTags", true, false) as LineEdit

	if not name_input or name_input.text.strip_edges() == "":
		_show_dialogue("Error", "Please enter a habit name.")
		return

	var habit = HabitManager.habits[_editing_habit_id]
	habit.name = name_input.text.strip_edges()
	habit.description = desc_input.text.strip_edges() if desc_input else ""
	habit.domain = _selected_habit_domain
	habit.icon = _selected_habit_icon

	# Update tags
	var new_tags: Array = []
	if tags_input and tags_input.text.strip_edges() != "":
		var tag_strings = tags_input.text.split(",")
		for tag in tag_strings:
			var cleaned = tag.strip_edges().to_lower()
			if cleaned != "":
				new_tags.append(cleaned)

	# Remove old tags and add new ones
	var old_tags = habit.get("tags", [])
	for old_tag in old_tags:
		HabitManager.remove_tag_from_habit(_editing_habit_id, old_tag)
	habit.tags = new_tags
	for new_tag in new_tags:
		HabitManager.add_habit_to_tag(_editing_habit_id, new_tag)

	SaveManager.save_game()

	_close_zone()
	_show_dialogue("Saved", "Habit updated successfully.", _open_habits_zone)


func _add_habit_spacer(height: int) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	zone_body.add_child(spacer)


func _get_streak_fire(streak: int) -> String:
	if streak >= 100:
		return "🔥🔥🔥🔥"  # Legendary
	elif streak >= 30:
		return "🔥🔥🔥"  # On fire
	elif streak >= 7:
		return "🔥🔥"  # Warming up
	else:
		return "🔥"  # Starting


func _get_streak_color(streak: int) -> Color:
	if streak >= 100:
		return Color(1.0, 0.3, 0.8)  # Pink/magenta for legendary
	elif streak >= 30:
		return Color(1.0, 0.5, 0.1)  # Bright orange
	elif streak >= 7:
		return Color(0.95, 0.7, 0.2)  # Golden
	else:
		return Color(0.9, 0.6, 0.2)  # Standard orange


func _get_days_in_month(month: int, year: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			# Leap year check
			if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0):
				return 29
			return 28
	return 30


func _get_next_grace_day_info() -> String:
	# Find the habit closest to earning a grace day (7-day milestone)
	var habits = HabitManager.get_all_habits()
	var best_progress = 0
	var days_until = 7

	for habit in habits:
		var streak = habit.get("streak", 0)
		var progress_in_cycle = streak % HabitManager.GRACE_DAY_RECHARGE_STREAK
		if progress_in_cycle > best_progress:
			best_progress = progress_in_cycle
			days_until = HabitManager.GRACE_DAY_RECHARGE_STREAK - progress_in_cycle

	if best_progress > 0:
		return "(Next in %d days)" % days_until
	return ""


func _show_streak_recovery_section(at_risk: Array) -> void:
	var warning_container = VBoxContainer.new()
	warning_container.add_theme_constant_override("separation", 8)

	# Warning header
	var header = Label.new()
	header.text = "⚠️ Streaks at Risk!"
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
	warning_container.add_child(header)

	var subtext = Label.new()
	subtext.text = "Complete today or use a grace day to save your streak."
	subtext.add_theme_font_size_override("font_size", 16)
	subtext.add_theme_color_override("font_color", Color(0.65, 0.6, 0.55))
	subtext.autowrap_mode = TextServer.AUTOWRAP_WORD
	warning_container.add_child(subtext)

	for item in at_risk:
		var habit = item.habit
		var break_info = item.break_info

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		# Habit name with streak
		var name_label = Label.new()
		name_label.text = habit.name + " (🔥" + str(break_info.streak_value) + ")"
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		# Use grace day button (if available)
		if HabitManager.get_grace_days() > 0:
			var grace_btn = Button.new()
			grace_btn.text = "Use Grace Day"
			grace_btn.add_theme_font_size_override("font_size", 14)
			grace_btn.pressed.connect(_use_grace_day_for_habit.bind(habit.id))
			row.add_child(grace_btn)

		warning_container.add_child(row)

	zone_body.add_child(warning_container)


func _use_grace_day_for_habit(habit_id: String) -> void:
	if HabitManager.use_grace_day(habit_id):
		var habit = HabitManager.habits.get(habit_id, {})
		var name = habit.get("name", "Habit")
		_close_zone()
		_show_dialogue("Streak Saved!", "Used 1 grace day to save your " + name + " streak!\n\nGrace days remaining: " + str(HabitManager.get_grace_days()), _open_habits_zone)
	else:
		_show_dialogue("Failed", "Could not use grace day.")


func _show_create_topic_dialog() -> void:
	zone_title.text = "Create Topic"
	_clear_zone_body()

	var desc = Label.new()
	desc.text = "Enter a name for your focus topic:"
	desc.add_theme_font_size_override("font_size", 20)
	zone_body.add_child(desc)

	var input = LineEdit.new()
	input.placeholder_text = "e.g., Study, Work, Exercise..."
	input.custom_minimum_size = Vector2(0, 50)
	input.add_theme_font_size_override("font_size", 20)
	input.name = "TopicInput"
	zone_body.add_child(input)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	zone_body.add_child(spacer)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.custom_minimum_size = Vector2(0, 50)
	cancel_btn.pressed.connect(_open_focus_zone)
	btn_row.add_child(cancel_btn)

	var create_btn = Button.new()
	create_btn.text = "Create"
	create_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_btn.custom_minimum_size = Vector2(0, 50)
	create_btn.pressed.connect(_create_topic_from_input)
	btn_row.add_child(create_btn)

	zone_body.add_child(btn_row)


func _create_topic_from_input() -> void:
	var input = zone_body.find_child("TopicInput", true, false) as LineEdit
	if input and input.text.strip_edges() != "":
		var topic_name = input.text.strip_edges()
		HabitManager.create_topic(topic_name)
		_show_dialogue("Topic Created", "'" + topic_name + "' has been created!\n\nYou can now start focus sessions with this topic.", _open_focus_zone)
	else:
		_show_dialogue("Invalid Name", "Please enter a valid topic name.")


func _show_topic_stats(topic_id: String) -> void:
	if not HabitManager.topics.has(topic_id):
		return

	var topic = HabitManager.topics[topic_id]
	zone_title.text = topic.name + " Stats"
	_clear_zone_body()

	var total_sessions = int(topic.get("total_sessions", 0))
	var total_minutes = int(topic.get("total_minutes", 0))
	var streak = int(topic.get("streak", 0))
	var last_duration = topic.get("last_duration", 25)

	# Total time focused
	var hours = total_minutes / 60
	var mins = total_minutes % 60

	var time_label = Label.new()
	if hours > 0:
		time_label.text = "%dh %dm" % [hours, mins]
	else:
		time_label.text = "%d minutes" % total_minutes
	time_label.add_theme_font_size_override("font_size", 48)
	time_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_body.add_child(time_label)

	var subtitle = Label.new()
	subtitle.text = "Total Focus Time"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_body.add_child(subtitle)

	_add_section_label("Statistics")

	# Sessions count
	var sessions_row = HBoxContainer.new()
	sessions_row.add_theme_constant_override("separation", 10)
	var sessions_label = Label.new()
	sessions_label.text = "Total Sessions:"
	sessions_label.add_theme_font_size_override("font_size", 20)
	sessions_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sessions_row.add_child(sessions_label)
	var sessions_value = Label.new()
	sessions_value.text = str(total_sessions)
	sessions_value.add_theme_font_size_override("font_size", 20)
	sessions_value.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	sessions_row.add_child(sessions_value)
	zone_body.add_child(sessions_row)

	# Average session
	if total_sessions > 0:
		var avg_minutes = total_minutes / total_sessions
		var avg_row = HBoxContainer.new()
		avg_row.add_theme_constant_override("separation", 10)
		var avg_label = Label.new()
		avg_label.text = "Average Session:"
		avg_label.add_theme_font_size_override("font_size", 20)
		avg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		avg_row.add_child(avg_label)
		var avg_value = Label.new()
		avg_value.text = str(avg_minutes) + " min"
		avg_value.add_theme_font_size_override("font_size", 20)
		avg_value.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
		avg_row.add_child(avg_value)
		zone_body.add_child(avg_row)

	# Streak
	var streak_row = HBoxContainer.new()
	streak_row.add_theme_constant_override("separation", 10)
	var streak_label = Label.new()
	streak_label.text = "Current Streak:"
	streak_label.add_theme_font_size_override("font_size", 20)
	streak_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	streak_row.add_child(streak_label)
	var streak_value = Label.new()
	if streak > 0:
		streak_value.text = _get_streak_fire(streak) + " " + str(streak) + " days"
		streak_value.add_theme_color_override("font_color", _get_streak_color(streak))
	else:
		streak_value.text = "0 days"
		streak_value.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	streak_value.add_theme_font_size_override("font_size", 20)
	streak_row.add_child(streak_value)
	zone_body.add_child(streak_row)

	# Last duration
	var dur_row = HBoxContainer.new()
	dur_row.add_theme_constant_override("separation", 10)
	var dur_label = Label.new()
	dur_label.text = "Last Duration:"
	dur_label.add_theme_font_size_override("font_size", 20)
	dur_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dur_row.add_child(dur_label)
	var dur_value = Label.new()
	dur_value.text = str(last_duration) + " min"
	dur_value.add_theme_font_size_override("font_size", 20)
	dur_value.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	dur_row.add_child(dur_value)
	zone_body.add_child(dur_row)

	_add_habit_spacer(20)

	# Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)

	var start_btn = Button.new()
	start_btn.text = "Start Session"
	start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_btn.custom_minimum_size = Vector2(0, 55)
	start_btn.add_theme_font_size_override("font_size", 20)
	start_btn.pressed.connect(_start_topic_focus.bind(topic_id, topic.name))
	btn_row.add_child(start_btn)

	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_btn.custom_minimum_size = Vector2(0, 55)
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(_open_focus_zone)
	btn_row.add_child(back_btn)

	zone_body.add_child(btn_row)

	_add_habit_spacer(10)

	# Delete option (subtle)
	var delete_btn = Button.new()
	delete_btn.text = "Delete Topic"
	delete_btn.flat = true
	delete_btn.add_theme_font_size_override("font_size", 16)
	delete_btn.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
	delete_btn.pressed.connect(_confirm_delete_topic.bind(topic_id, topic.name))
	zone_body.add_child(delete_btn)


func _confirm_delete_topic(topic_id: String, topic_name: String) -> void:
	_close_zone()
	_show_dialogue("Delete Topic?", "Delete '" + topic_name + "'?\n\nThis will remove all session history for this topic.", func():
		HabitManager.delete_topic(topic_id)
		_show_dialogue("Deleted", "Topic '" + topic_name + "' has been deleted.", _open_focus_zone)
	)


func _clear_zone_body() -> void:
	for child in zone_body.get_children():
		child.queue_free()


func _close_zone() -> void:
	zone_panel.visible = false
	in_zone_panel = false


func _open_pause_menu() -> void:
	pause_menu.visible = true
	_show_character_tab()


func _close_pause_menu() -> void:
	pause_menu.visible = false


# ============ PAUSE MENU TABS ============

func _select_menu_tab(tab: String) -> void:
	current_menu_tab = tab
	character_tab.button_pressed = (tab == "character")
	aspects_tab.button_pressed = (tab == "aspects")
	progress_tab.button_pressed = (tab == "progress")
	settings_tab.button_pressed = (tab == "settings")


func _clear_menu_body() -> void:
	for child in menu_body.get_children():
		child.queue_free()


func _show_character_tab() -> void:
	_select_menu_tab("character")
	_clear_menu_body()

	# Player name
	var player_name = GameManager.player_data.get("name", "Traveler")
	var name_label = Label.new()
	name_label.text = player_name
	name_label.add_theme_font_size_override("font_size", 36)
	name_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	menu_body.add_child(name_label)

	_add_menu_spacer()

	# Stats section
	_add_menu_section_label("Statistics")

	var evolution = GameManager.player_data.get("world_evolution_level", 0.0)
	_add_stat_row("World Evolution", "%.1f%%" % evolution)

	var total_focus = int(GameManager.player_data.get("total_focus_minutes", 0))
	var hours = total_focus / 60
	var mins = total_focus % 60
	if hours > 0:
		_add_stat_row("Total Focus Time", "%dh %dm" % [hours, mins])
	else:
		_add_stat_row("Total Focus Time", "%d minutes" % mins)

	var total_habits = GameManager.player_data.get("total_habits_completed", 0)
	_add_stat_row("Habits Completed", str(total_habits))

	_add_menu_spacer()

	# Campaign info
	_add_menu_section_label("Campaign")

	var chapter_data = CampaignManager.get_current_chapter()
	_add_stat_row("Current Chapter", chapter_data.get("name", "Chapter 1"))

	var progress = CampaignManager.get_chapter_progress()
	_add_stat_row("Chapter Progress", "%d%%" % int(progress * 100))

	_add_menu_spacer()

	# Inventory
	_add_menu_section_label("Inventory")

	if GameManager.has_master_key():
		var key_label = Label.new()
		key_label.text = "🔑 Master Key"
		key_label.add_theme_font_size_override("font_size", 22)
		key_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
		menu_body.add_child(key_label)
	else:
		var no_items = Label.new()
		no_items.text = "No special items"
		no_items.add_theme_font_size_override("font_size", 20)
		no_items.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		menu_body.add_child(no_items)


func _show_aspects_tab() -> void:
	_select_menu_tab("aspects")
	_clear_menu_body()

	_add_menu_section_label("Your Aspects")

	var aspects = GameManager.player_data.get("aspects", {})
	var aspect_order = ["discipline", "courage", "creativity", "compassion", "wisdom", "vitality"]

	for aspect_id in aspect_order:
		if aspects.has(aspect_id):
			_add_aspect_row(aspect_id, aspects[aspect_id])


func _add_aspect_row(aspect_id: String, data: Dictionary) -> void:
	var aspect_names = {
		"discipline": "Discipline",
		"courage": "Courage",
		"creativity": "Creativity",
		"compassion": "Compassion",
		"wisdom": "Wisdom",
		"vitality": "Vitality"
	}
	var aspect_colors = {
		"discipline": Color(0.83, 0.66, 0.29),
		"courage": Color(0.8, 0.3, 0.35),
		"creativity": Color(0.7, 0.5, 0.8),
		"compassion": Color(0.4, 0.7, 0.5),
		"wisdom": Color(0.3, 0.6, 0.9),
		"vitality": Color(0.9, 0.5, 0.3)
	}

	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	menu_body.add_child(container)

	# Name and level row
	var top_row = HBoxContainer.new()
	container.add_child(top_row)

	var name_label = Label.new()
	name_label.text = aspect_names.get(aspect_id, aspect_id.capitalize())
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", aspect_colors.get(aspect_id, Color.WHITE))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(name_label)

	var level = data.get("level", 1)
	var level_label = Label.new()
	level_label.text = "Level %d" % level
	level_label.add_theme_font_size_override("font_size", 22)
	level_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	top_row.add_child(level_label)

	# XP bar background
	var bar_bg = ProgressBar.new()
	bar_bg.custom_minimum_size = Vector2(0, 20)
	bar_bg.max_value = 100
	var xp = data.get("experience", 0)
	var xp_needed = level * 100  # XP needed for next level
	var progress_pct = (float(xp) / float(xp_needed)) * 100 if xp_needed > 0 else 0.0
	bar_bg.value = progress_pct
	bar_bg.show_percentage = false
	container.add_child(bar_bg)

	# XP text
	var xp_label = Label.new()
	xp_label.text = "%d / %d XP" % [xp, xp_needed]
	xp_label.add_theme_font_size_override("font_size", 18)
	xp_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	container.add_child(xp_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	menu_body.add_child(spacer)


func _show_progress_tab() -> void:
	_select_menu_tab("progress")
	_clear_menu_body()

	# Story/Chapter Progress
	_add_story_section()

	_add_menu_spacer()

	# Character Bonds section
	_add_character_bonds_section()

	_add_menu_spacer()

	# Achievements summary
	if AchievementManager:
		var unlocked = AchievementManager.get_unlocked_achievements()
		var total = AchievementManager.ACHIEVEMENTS.size()
		var percentage = int(AchievementManager.get_unlock_percentage() * 100)

		var achievements_row = HBoxContainer.new()
		achievements_row.add_theme_constant_override("separation", 15)

		var badge_label = Label.new()
		badge_label.text = "🏆 Achievements: %d/%d (%d%%)" % [unlocked.size(), total, percentage]
		badge_label.add_theme_font_size_override("font_size", 20)
		badge_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
		badge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		achievements_row.add_child(badge_label)

		var view_btn = Button.new()
		view_btn.text = "View All"
		view_btn.custom_minimum_size = Vector2(80, 35)
		view_btn.add_theme_font_size_override("font_size", 16)
		view_btn.pressed.connect(_show_achievements_view)
		achievements_row.add_child(view_btn)

		menu_body.add_child(achievements_row)

		# Show recent unlocks (up to 3)
		if unlocked.size() > 0:
			unlocked.sort_custom(func(a, b): return a.get("unlock_time", 0) > b.get("unlock_time", 0))
			var recent_label = Label.new()
			recent_label.text = "Recent:"
			recent_label.add_theme_font_size_override("font_size", 16)
			recent_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
			menu_body.add_child(recent_label)

			for achievement in unlocked.slice(0, 3):
				var ach_label = Label.new()
				ach_label.text = achievement.icon + " " + achievement.name
				ach_label.add_theme_font_size_override("font_size", 18)
				ach_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
				menu_body.add_child(ach_label)

		_add_menu_spacer()

	# Weekly Summary
	_add_menu_section_label("This Week")

	var weekly_stats = HabitManager.get_weekly_stats()

	# Completions comparison
	var this_week = weekly_stats.this_week_completions
	var last_week = weekly_stats.last_week_completions

	var comp_row = HBoxContainer.new()
	comp_row.add_theme_constant_override("separation", 10)
	menu_body.add_child(comp_row)

	var comp_label = Label.new()
	comp_label.text = "Habit Completions: %d" % this_week
	comp_label.add_theme_font_size_override("font_size", 20)
	comp_row.add_child(comp_label)

	# Comparison indicator
	if last_week > 0:
		var diff = this_week - last_week
		var diff_label = Label.new()
		if diff > 0:
			diff_label.text = "(+%d vs last week)" % diff
			diff_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		elif diff < 0:
			diff_label.text = "(%d vs last week)" % diff
			diff_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.5))
		else:
			diff_label.text = "(same as last week)"
			diff_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		diff_label.add_theme_font_size_override("font_size", 16)
		comp_row.add_child(diff_label)

	# Perfect days and streaks
	_add_stat_row("Perfect Days", "%d / 7" % weekly_stats.perfect_days)
	_add_stat_row("Active Streaks", "%d habits" % weekly_stats.active_streaks)

	# Focus time this week
	var focus_minutes = int(GameManager.player_data.get("total_focus_minutes", 0))
	var hours = focus_minutes / 60
	var mins = focus_minutes % 60
	_add_stat_row("Total Focus Time", "%dh %dm" % [hours, mins])

	_add_menu_spacer()

	# Daily Challenges
	_add_menu_section_label("Daily Challenges")

	var daily_challenges = ChallengeManager.get_daily_challenges() if ChallengeManager else []
	if daily_challenges.is_empty():
		var no_challenges = Label.new()
		no_challenges.text = "No challenges available"
		no_challenges.add_theme_font_size_override("font_size", 20)
		no_challenges.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		menu_body.add_child(no_challenges)
	else:
		for challenge in daily_challenges:
			_add_challenge_row(challenge)

	# Weekly Challenge
	var weekly = ChallengeManager.get_weekly_challenge() if ChallengeManager else {}
	if not weekly.is_empty():
		_add_menu_spacer()
		_add_menu_section_label("Weekly Challenge")
		_add_challenge_row(weekly, true)

	_add_menu_spacer()

	# Today's Habits
	_add_menu_section_label("Today's Habits")

	var habits = HabitManager.get_all_habits()
	var completed_count = 0
	for habit in habits:
		if HabitManager.is_completed_today(habit.id):
			completed_count += 1

	if habits.size() > 0:
		_add_stat_row("Completed", "%d / %d" % [completed_count, habits.size()])
	else:
		var no_habits = Label.new()
		no_habits.text = "No habits tracked yet"
		no_habits.add_theme_font_size_override("font_size", 20)
		no_habits.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		menu_body.add_child(no_habits)

	# Topics
	var topics = HabitManager.get_all_topics()
	if topics.size() > 0:
		var topic_completed = 0
		for topic in topics:
			if HabitManager.is_topic_completed_today(topic.id):
				topic_completed += 1
		_add_stat_row("Topics Done", "%d / %d" % [topic_completed, topics.size()])

	_add_menu_spacer()

	# Active Goals
	_add_menu_section_label("Active Goals")

	var goals = GoalManager.get_active_goals()
	if goals.size() == 0:
		var no_goals = Label.new()
		no_goals.text = "No active goals"
		no_goals.add_theme_font_size_override("font_size", 20)
		no_goals.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		menu_body.add_child(no_goals)
	else:
		for goal in goals.slice(0, 5):  # Show max 5
			var goal_label = Label.new()
			goal_label.text = "• " + goal.title
			goal_label.add_theme_font_size_override("font_size", 20)
			menu_body.add_child(goal_label)

	_add_menu_spacer()

	# Trophies
	_add_menu_section_label("Trophies")

	var trophies = CampaignManager.get_earned_trophies()
	_add_stat_row("Earned", "%d trophies" % trophies.size())

	if trophies.size() > 0:
		for trophy in trophies.slice(0, 3):  # Show last 3
			var trophy_label = Label.new()
			trophy_label.text = trophy.icon + " " + trophy.name
			trophy_label.add_theme_font_size_override("font_size", 18)
			trophy_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
			menu_body.add_child(trophy_label)

	_add_menu_spacer()

	# Journal / Reflection Tools
	_add_menu_section_label("Reflection Tools")

	var journal = _load_journal()
	var journal_info = Label.new()
	journal_info.text = "Track your progress with notes and reflections"
	journal_info.add_theme_font_size_override("font_size", 16)
	journal_info.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
	menu_body.add_child(journal_info)

	var journal_row = HBoxContainer.new()
	journal_row.add_theme_constant_override("separation", 15)
	menu_body.add_child(journal_row)

	var journal_btn = Button.new()
	journal_btn.text = "📔 Open Journal (" + str(journal.size()) + " entries)"
	journal_btn.custom_minimum_size = Vector2(0, 45)
	journal_btn.add_theme_font_size_override("font_size", 18)
	journal_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_btn.pressed.connect(_open_journal_from_menu)
	journal_row.add_child(journal_btn)

	# Show recent entry preview
	if journal.size() > 0:
		journal.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))
		var recent = journal[0]
		var preview_label = Label.new()
		var entry_type = recent.get("type", "focus")
		if entry_type == "habit":
			preview_label.text = "Latest: ✓ " + recent.get("habit_name", "Habit") + " - " + _format_date(recent.get("date", ""))
		else:
			preview_label.text = "Latest: 🎯 " + recent.get("topic", "Focus") + " - " + _format_date(recent.get("date", ""))
		preview_label.add_theme_font_size_override("font_size", 14)
		preview_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		menu_body.add_child(preview_label)


func _open_journal_from_menu() -> void:
	_close_pause_menu()
	in_zone_panel = true
	zone_panel.visible = true
	_open_journal_viewer()


func _add_challenge_row(challenge: Dictionary, is_weekly: bool = false) -> void:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	menu_body.add_child(container)

	# Challenge name with completion status
	var name_row = HBoxContainer.new()
	container.add_child(name_row)

	var name_label = Label.new()
	if challenge.get("completed", false):
		name_label.text = "✓ " + challenge.get("name", "Challenge")
		name_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	else:
		name_label.text = challenge.get("name", "Challenge")
		name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)

	# XP reward
	var reward_label = Label.new()
	reward_label.text = "+" + str(challenge.get("xp_reward", 30)) + " XP"
	reward_label.add_theme_font_size_override("font_size", 18)
	if challenge.get("completed", false):
		reward_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	else:
		reward_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	name_row.add_child(reward_label)

	# Progress bar
	var progress = challenge.get("progress", 0)
	var target = challenge.get("target", 1)

	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 16)
	progress_bar.max_value = target
	progress_bar.value = progress
	progress_bar.show_percentage = false
	container.add_child(progress_bar)

	# Progress text
	var progress_label = Label.new()
	progress_label.text = challenge.get("description", "") + " (" + str(progress) + "/" + str(target) + ")"
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	container.add_child(progress_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	menu_body.add_child(spacer)


func _show_settings_tab() -> void:
	_select_menu_tab("settings")
	_clear_menu_body()

	# Quick Actions
	_add_menu_section_label("Quick Actions")

	var resume_btn = Button.new()
	resume_btn.text = "Resume Game"
	resume_btn.custom_minimum_size = Vector2(0, 60)
	resume_btn.add_theme_font_size_override("font_size", 22)
	resume_btn.pressed.connect(_close_pause_menu)
	menu_body.add_child(resume_btn)

	var save_btn = Button.new()
	save_btn.text = "Save Game"
	save_btn.custom_minimum_size = Vector2(0, 60)
	save_btn.add_theme_font_size_override("font_size", 22)
	save_btn.pressed.connect(func():
		SaveManager.save_game()
		_close_pause_menu()
		_show_dialogue("Saved", "Game saved successfully!")
	)
	menu_body.add_child(save_btn)

	_add_menu_spacer()

	# Navigation
	_add_menu_section_label("Navigation")

	var exit_btn = Button.new()
	exit_btn.text = "Exit to Bedroom"
	exit_btn.custom_minimum_size = Vector2(0, 60)
	exit_btn.add_theme_font_size_override("font_size", 22)
	exit_btn.pressed.connect(func():
		_close_pause_menu()
		_exit_to_bedroom()
	)
	menu_body.add_child(exit_btn)

	var main_menu_btn = Button.new()
	main_menu_btn.text = "Return to Main Menu"
	main_menu_btn.custom_minimum_size = Vector2(0, 60)
	main_menu_btn.add_theme_font_size_override("font_size", 22)
	main_menu_btn.pressed.connect(func():
		SaveManager.save_game()
		GameManager.goto_scene("res://scenes/main_menu/main_menu.tscn")
	)
	menu_body.add_child(main_menu_btn)

	_add_menu_spacer()

	# Data
	_add_menu_section_label("Data")

	var reset_tutorials_btn = Button.new()
	reset_tutorials_btn.text = "Reset Tutorials"
	reset_tutorials_btn.custom_minimum_size = Vector2(0, 50)
	reset_tutorials_btn.add_theme_font_size_override("font_size", 20)
	reset_tutorials_btn.pressed.connect(func():
		GameManager.player_data.seen_tutorials = []
		SaveManager.save_game()
		_close_pause_menu()
		_show_dialogue("Tutorials Reset", "All tutorials have been reset.")
	)
	menu_body.add_child(reset_tutorials_btn)

	var export_btn = Button.new()
	export_btn.text = "Export Progress Data (JSON)"
	export_btn.custom_minimum_size = Vector2(0, 50)
	export_btn.add_theme_font_size_override("font_size", 20)
	export_btn.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9))
	export_btn.pressed.connect(_export_progress_data)
	menu_body.add_child(export_btn)

	_add_menu_spacer()

	# Time Settings
	_add_menu_section_label("Time Settings")

	var tz_row = HBoxContainer.new()
	tz_row.add_theme_constant_override("separation", 15)
	menu_body.add_child(tz_row)

	var tz_label = Label.new()
	tz_label.text = "Timezone Offset (hours):"
	tz_label.add_theme_font_size_override("font_size", 18)
	tz_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tz_row.add_child(tz_label)

	var current_tz = GameManager.player_data.get("timezone_offset_hours", 0)
	var tz_spinbox = SpinBox.new()
	tz_spinbox.min_value = -12
	tz_spinbox.max_value = 14
	tz_spinbox.step = 1
	tz_spinbox.value = current_tz
	tz_spinbox.custom_minimum_size = Vector2(100, 40)
	tz_spinbox.add_theme_font_size_override("font_size", 18)
	tz_spinbox.value_changed.connect(func(val):
		GameManager.player_data["timezone_offset_hours"] = int(val)
		SaveManager.save_game()
	)
	tz_row.add_child(tz_spinbox)

	var tz_hint = Label.new()
	tz_hint.text = "Adjust to match your local time (e.g., EST = -5, PST = -8)"
	tz_hint.add_theme_font_size_override("font_size", 14)
	tz_hint.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	menu_body.add_child(tz_hint)

	_add_menu_spacer()

	# Accessibility Settings
	_add_menu_section_label("Accessibility")
	_add_accessibility_settings(menu_body)

	_add_menu_spacer()

	# Reset options
	_add_menu_section_label("Reset Options")

	var reset_habits_btn = Button.new()
	reset_habits_btn.text = "Reset Habits"
	reset_habits_btn.custom_minimum_size = Vector2(0, 45)
	reset_habits_btn.add_theme_font_size_override("font_size", 18)
	reset_habits_btn.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5))
	reset_habits_btn.pressed.connect(_confirm_reset_habits)
	menu_body.add_child(reset_habits_btn)

	var reset_goals_btn = Button.new()
	reset_goals_btn.text = "Reset Goals"
	reset_goals_btn.custom_minimum_size = Vector2(0, 45)
	reset_goals_btn.add_theme_font_size_override("font_size", 18)
	reset_goals_btn.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5))
	reset_goals_btn.pressed.connect(_confirm_reset_goals)
	menu_body.add_child(reset_goals_btn)

	var reset_challenges_btn = Button.new()
	reset_challenges_btn.text = "Reset Challenges"
	reset_challenges_btn.custom_minimum_size = Vector2(0, 45)
	reset_challenges_btn.add_theme_font_size_override("font_size", 18)
	reset_challenges_btn.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5))
	reset_challenges_btn.pressed.connect(_confirm_reset_challenges)
	menu_body.add_child(reset_challenges_btn)

	_add_menu_spacer()

	# Version info
	var version = Label.new()
	version.text = "Mindscape v0.1.5\nGOACTO: Growing Ourselves And Contributing To Others"
	version.add_theme_font_size_override("font_size", 18)
	version.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_body.add_child(version)


func _add_menu_section_label(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	menu_body.add_child(label)


func _add_stat_row(label_text: String, value_text: String) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	menu_body.add_child(row)

	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 22)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 22)
	value.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	row.add_child(value)


func _add_menu_spacer() -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	menu_body.add_child(spacer)


func _add_accessibility_settings(container: VBoxContainer) -> void:
	# Font Size
	var font_row = HBoxContainer.new()
	font_row.add_theme_constant_override("separation", 15)
	container.add_child(font_row)

	var font_label = Label.new()
	font_label.text = "Font Size:"
	font_label.add_theme_font_size_override("font_size", 18)
	font_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	font_row.add_child(font_label)

	var current_font_size = "medium"
	if SaveManager:
		var settings = SaveManager.load_settings()
		current_font_size = settings.get("font_size", "medium")

	var font_options = OptionButton.new()
	font_options.add_item("Small", 0)
	font_options.add_item("Medium", 1)
	font_options.add_item("Large", 2)
	match current_font_size:
		"small": font_options.select(0)
		"medium": font_options.select(1)
		"large": font_options.select(2)
	font_options.custom_minimum_size = Vector2(120, 40)
	font_options.add_theme_font_size_override("font_size", 16)
	font_options.item_selected.connect(func(idx):
		var sizes = ["small", "medium", "large"]
		GameManager.set_accessibility_option("font_size", sizes[idx])
	)
	font_row.add_child(font_options)

	# High Contrast Toggle
	var contrast_row = HBoxContainer.new()
	contrast_row.add_theme_constant_override("separation", 15)
	container.add_child(contrast_row)

	var contrast_label = Label.new()
	contrast_label.text = "High Contrast Mode:"
	contrast_label.add_theme_font_size_override("font_size", 18)
	contrast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contrast_row.add_child(contrast_label)

	var contrast_check = CheckButton.new()
	if SaveManager:
		var settings = SaveManager.load_settings()
		contrast_check.button_pressed = settings.get("high_contrast", false)
	contrast_check.toggled.connect(func(pressed):
		GameManager.set_accessibility_option("high_contrast", pressed)
	)
	contrast_row.add_child(contrast_check)

	# Reduced Motion Toggle
	var motion_row = HBoxContainer.new()
	motion_row.add_theme_constant_override("separation", 15)
	container.add_child(motion_row)

	var motion_label = Label.new()
	motion_label.text = "Reduced Motion:"
	motion_label.add_theme_font_size_override("font_size", 18)
	motion_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	motion_row.add_child(motion_label)

	var motion_check = CheckButton.new()
	if SaveManager:
		var settings = SaveManager.load_settings()
		motion_check.button_pressed = settings.get("reduced_motion", false)
	motion_check.toggled.connect(func(pressed):
		GameManager.set_accessibility_option("reduced_motion", pressed)
	)
	motion_row.add_child(motion_check)

	# Colorblind Mode
	var cb_row = HBoxContainer.new()
	cb_row.add_theme_constant_override("separation", 15)
	container.add_child(cb_row)

	var cb_label = Label.new()
	cb_label.text = "Colorblind Mode:"
	cb_label.add_theme_font_size_override("font_size", 18)
	cb_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cb_row.add_child(cb_label)

	var current_cb_mode = "none"
	if SaveManager:
		var settings = SaveManager.load_settings()
		current_cb_mode = settings.get("colorblind_mode", "none")

	var cb_options = OptionButton.new()
	cb_options.add_item("None", 0)
	cb_options.add_item("Deuteranopia", 1)
	cb_options.add_item("Protanopia", 2)
	cb_options.add_item("Tritanopia", 3)
	match current_cb_mode:
		"none": cb_options.select(0)
		"deuteranopia": cb_options.select(1)
		"protanopia": cb_options.select(2)
		"tritanopia": cb_options.select(3)
	cb_options.custom_minimum_size = Vector2(140, 40)
	cb_options.add_theme_font_size_override("font_size", 16)
	cb_options.item_selected.connect(func(idx):
		var modes = ["none", "deuteranopia", "protanopia", "tritanopia"]
		GameManager.set_accessibility_option("colorblind_mode", modes[idx])
	)
	cb_row.add_child(cb_options)

	# Hint text
	var hint = Label.new()
	hint.text = "Note: Some changes may require restarting the scene."
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	container.add_child(hint)


# ============ STORY/CHAPTER SECTION ============

func _add_story_section() -> void:
	if not CampaignManager:
		return

	var current_chapter = CampaignManager.get_current_chapter()
	if current_chapter.is_empty():
		return

	# Section header with book icon
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	menu_body.add_child(header_row)

	var book_icon = Label.new()
	book_icon.text = "📖"
	book_icon.add_theme_font_size_override("font_size", 28)
	header_row.add_child(book_icon)

	var header = Label.new()
	header.text = "Your Journey"
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(0.7, 0.6, 0.85))
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header)

	var view_btn = Button.new()
	view_btn.text = "Full Story"
	view_btn.custom_minimum_size = Vector2(90, 35)
	view_btn.add_theme_font_size_override("font_size", 16)
	view_btn.pressed.connect(_show_story_panel)
	header_row.add_child(view_btn)

	# Current chapter card
	var chapter_card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.18, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_color = Color(0.5, 0.4, 0.7, 0.4)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	chapter_card.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	chapter_card.add_child(margin)

	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(card_vbox)

	# Chapter title and act
	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	card_vbox.add_child(title_row)

	var act_label = Label.new()
	act_label.text = "Act %d" % current_chapter.get("act", 1)
	act_label.add_theme_font_size_override("font_size", 14)
	act_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	title_row.add_child(act_label)

	var chapter_title = Label.new()
	chapter_title.text = current_chapter.get("name", "Unknown Chapter")
	chapter_title.add_theme_font_size_override("font_size", 22)
	chapter_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	title_row.add_child(chapter_title)

	# Description
	var desc = Label.new()
	desc.text = current_chapter.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	card_vbox.add_child(desc)

	# Progress bar
	var progress = CampaignManager.get_chapter_progress()
	var progress_container = VBoxContainer.new()
	progress_container.add_theme_constant_override("separation", 4)
	card_vbox.add_child(progress_container)

	var progress_label = Label.new()
	progress_label.text = "Progress: %d%%" % int(progress * 100)
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
	progress_container.add_child(progress_label)

	# Visual progress bar
	var bar_bg = ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(0, 8)
	bar_bg.color = Color(0.15, 0.12, 0.2)
	progress_container.add_child(bar_bg)

	var bar_fill = ColorRect.new()
	bar_fill.custom_minimum_size = Vector2(0, 8)
	bar_fill.color = Color(0.5, 0.7, 0.4)
	bar_fill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bar_fill.custom_minimum_size.x = max(1, progress * 300)  # Scale to container width
	progress_container.add_child(bar_fill)

	menu_body.add_child(chapter_card)


func _add_character_bonds_section() -> void:
	if not GameManager:
		return

	var bonds = GameManager.get_all_character_bonds()
	if bonds.is_empty():
		return

	# Section header
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	menu_body.add_child(header_row)

	var bond_icon = Label.new()
	bond_icon.text = "💫"
	bond_icon.add_theme_font_size_override("font_size", 28)
	header_row.add_child(bond_icon)

	var header = Label.new()
	header.text = "Character Bonds"
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(0.85, 0.7, 0.5))
	header_row.add_child(header)

	# Mom bond (featured)
	var mom_bond = bonds.filter(func(b): return b.id == "mom")
	if mom_bond.size() > 0:
		var mom = mom_bond[0]
		_add_bond_card(mom, true)

	# Aspect bonds (compact grid)
	var aspects_grid = GridContainer.new()
	aspects_grid.columns = 3
	aspects_grid.add_theme_constant_override("h_separation", 8)
	aspects_grid.add_theme_constant_override("v_separation", 8)
	menu_body.add_child(aspects_grid)

	for bond in bonds:
		if bond.id == "mom":
			continue  # Already shown

		var aspect_card = PanelContainer.new()
		aspect_card.custom_minimum_size = Vector2(130, 70)

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		style.border_color = Color(bond.color.r, bond.color.g, bond.color.b, 0.4)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		aspect_card.add_theme_stylebox_override("panel", style)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 6)
		aspect_card.add_child(margin)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		margin.add_child(vbox)

		var name_label = Label.new()
		name_label.text = bond.name
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", bond.color)
		vbox.add_child(name_label)

		var title_label = Label.new()
		title_label.text = bond.bond_title
		title_label.add_theme_font_size_override("font_size", 11)
		title_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		vbox.add_child(title_label)

		# Progress bar
		var bar_bg = ColorRect.new()
		bar_bg.custom_minimum_size = Vector2(0, 4)
		bar_bg.color = Color(0.15, 0.15, 0.2)
		vbox.add_child(bar_bg)

		var progress = GameManager.get_bond_progress(bond.id)
		var bar_fill = ColorRect.new()
		bar_fill.custom_minimum_size = Vector2(progress * 110, 4)
		bar_fill.color = bond.color
		bar_fill.position = Vector2(0, 0)
		bar_bg.add_child(bar_fill)

		aspects_grid.add_child(aspect_card)


func _add_bond_card(bond: Dictionary, featured: bool = false) -> void:
	var card = PanelContainer.new()

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.12, 0.9)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_color = Color(bond.color.r, bond.color.g, bond.color.b, 0.5)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	card.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)

	# Character info
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 4)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = bond.name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", bond.color)
	info_vbox.add_child(name_label)

	var title_label = Label.new()
	title_label.text = bond.bond_title + " (Lv " + str(bond.bond_level) + ")"
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	info_vbox.add_child(title_label)

	# Progress
	var progress_vbox = VBoxContainer.new()
	progress_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(progress_vbox)

	var points_label = Label.new()
	points_label.text = str(bond.bond_points) + " pts"
	points_label.add_theme_font_size_override("font_size", 16)
	points_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_vbox.add_child(points_label)

	var bar_bg = ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(100, 6)
	bar_bg.color = Color(0.15, 0.15, 0.2)
	progress_vbox.add_child(bar_bg)

	var progress = GameManager.get_bond_progress(bond.id)
	var bar_fill = ColorRect.new()
	bar_fill.custom_minimum_size = Vector2(progress * 100, 6)
	bar_fill.color = bond.color
	bar_bg.add_child(bar_fill)

	menu_body.add_child(card)


var story_panel: PanelContainer = null

func _show_story_panel() -> void:
	if story_panel:
		return

	_close_pause_menu()

	story_panel = PanelContainer.new()
	story_panel.name = "StoryPanel"
	story_panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.98)
	story_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	story_panel.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(main_vbox)

	# Header
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 15)
	main_vbox.add_child(header_row)

	var title = Label.new()
	title.text = "📖 Your Journey"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.7, 0.6, 0.85))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(100, 45)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_story_panel)
	header_row.add_child(close_btn)

	# Overall progress
	var completed_chapters = CampaignManager.campaign_state.chapters_completed.size()
	var total_chapters = CampaignManager.CHAPTERS.size()

	var overall = Label.new()
	overall.text = "Chapters Completed: %d / %d" % [completed_chapters, total_chapters]
	overall.add_theme_font_size_override("font_size", 20)
	overall.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	main_vbox.add_child(overall)

	# Scrollable chapter list
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP  # Capture scroll events
	main_vbox.add_child(scroll)

	var chapter_list = VBoxContainer.new()
	chapter_list.add_theme_constant_override("separation", 12)
	chapter_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chapter_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(chapter_list)

	# Build chapter cards
	for chapter_id in _get_sorted_chapter_ids():
		var chapter = CampaignManager.CHAPTERS[chapter_id]
		_add_chapter_card(chapter_list, chapter)

	# Cutscene Theater button
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	main_vbox.add_child(spacer)

	var theater_btn = Button.new()
	theater_btn.text = "🎬 Cutscene Theater - Replay Past Scenes"
	theater_btn.custom_minimum_size = Vector2(0, 50)
	theater_btn.add_theme_font_size_override("font_size", 18)
	theater_btn.pressed.connect(_show_cutscene_theater)
	main_vbox.add_child(theater_btn)

	add_child(story_panel)


func _get_sorted_chapter_ids() -> Array:
	var ids = CampaignManager.CHAPTERS.keys()
	ids.sort_custom(func(a, b):
		var num_a = int(a.replace("chapter_", ""))
		var num_b = int(b.replace("chapter_", ""))
		return num_a < num_b
	)
	return ids


func _add_chapter_card(container: Control, chapter: Dictionary) -> void:
	var chapter_id = chapter.get("id", "")
	var is_unlocked = CampaignManager.is_chapter_unlocked(chapter_id)
	var is_completed = CampaignManager.is_chapter_completed(chapter_id)
	var is_current = CampaignManager.campaign_state.current_chapter == chapter_id

	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	if is_completed:
		style.bg_color = Color(0.12, 0.15, 0.12, 0.9)
		style.border_color = Color(0.4, 0.6, 0.4, 0.5)
	elif is_current:
		style.bg_color = Color(0.15, 0.12, 0.2, 0.95)
		style.border_color = Color(0.6, 0.5, 0.8, 0.6)
	elif is_unlocked:
		style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
		style.border_color = Color(0.4, 0.4, 0.5, 0.4)
	else:
		style.bg_color = Color(0.08, 0.08, 0.1, 0.6)
		style.border_color = Color(0.25, 0.25, 0.3, 0.3)

	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	card.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)

	# Status icon
	var status_icon = Label.new()
	if is_completed:
		status_icon.text = "✓"
		status_icon.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	elif is_current:
		status_icon.text = "▶"
		status_icon.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
	elif is_unlocked:
		status_icon.text = "○"
		status_icon.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	else:
		status_icon.text = "🔒"
		status_icon.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	status_icon.add_theme_font_size_override("font_size", 24)
	hbox.add_child(status_icon)

	# Chapter info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	info_vbox.add_child(title_row)

	var act_label = Label.new()
	act_label.text = "Act %d •" % chapter.get("act", 1)
	act_label.add_theme_font_size_override("font_size", 14)
	act_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6) if is_unlocked else Color(0.35, 0.35, 0.4))
	title_row.add_child(act_label)

	var chapter_title = Label.new()
	chapter_title.text = chapter.get("name", "Unknown")
	chapter_title.add_theme_font_size_override("font_size", 20)
	if is_completed:
		chapter_title.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	elif is_current:
		chapter_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	elif is_unlocked:
		chapter_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	else:
		chapter_title.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	title_row.add_child(chapter_title)

	# Description (only for unlocked)
	if is_unlocked:
		var desc = Label.new()
		desc.text = chapter.get("description", "")
		desc.add_theme_font_size_override("font_size", 16)
		desc.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
		info_vbox.add_child(desc)

	# Current chapter shows objectives
	if is_current and not is_completed:
		var objectives_label = Label.new()
		objectives_label.text = "Objectives:"
		objectives_label.add_theme_font_size_override("font_size", 14)
		objectives_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.7))
		info_vbox.add_child(objectives_label)

		for req in chapter.get("completion_requirements", []):
			var obj_text = _format_requirement(req)
			var is_done = CampaignManager._check_requirement(req)

			var obj_row = HBoxContainer.new()
			obj_row.add_theme_constant_override("separation", 8)
			info_vbox.add_child(obj_row)

			var check = Label.new()
			check.text = "✓" if is_done else "○"
			check.add_theme_font_size_override("font_size", 14)
			check.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5) if is_done else Color(0.5, 0.5, 0.55))
			obj_row.add_child(check)

			var obj_label = Label.new()
			obj_label.text = obj_text
			obj_label.add_theme_font_size_override("font_size", 14)
			obj_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5) if is_done else Color(0.6, 0.6, 0.65))
			obj_row.add_child(obj_label)

	container.add_child(card)


func _format_requirement(req: Dictionary) -> String:
	match req.type:
		"focus_sessions":
			return "Complete %d focus sessions" % req.count
		"habits_created":
			return "Create %d habits" % req.count
		"streak_days":
			return "Reach a %d-day streak" % req.count
		"journal_entries":
			return "Write %d journal entries" % req.count
		"goals_created":
			return "Set %d goals" % req.count
		"goals_completed":
			return "Complete %d goals" % req.count
		"aspect_level":
			var aspect = req.get("aspect", "any")
			if aspect == "any":
				return "Reach level %d in any aspect" % req.level
			return "Reach level %d in %s" % [req.level, aspect.capitalize()]
		"scripts_created":
			return "Create %d scripts" % req.count
		"scripts_executed":
			return "Execute %d scripts" % req.count
		"combat_victories":
			var enemy = req.get("enemy", "any")
			return "Defeat %s" % enemy.capitalize() if enemy != "any" else "Win a battle"
		"streak_recovered":
			return "Recover a broken streak"
		"aspects_talked_to":
			return "Commune with %d aspects" % req.count
		"weekly_goal_set":
			return "Set a weekly goal"
		"all_resistance_defeated":
			return "Defeat all resistance types"
		"weekly_goals_complete":
			return "Complete %d weekly goals" % req.count
		"milestone_goal_complete":
			return "Complete a milestone goal"
		_:
			return "Complete objective"


func _close_story_panel() -> void:
	if story_panel:
		story_panel.queue_free()
		story_panel = null


# ============ CUTSCENE THEATER ============

var cutscene_theater_panel: PanelContainer = null

func _show_cutscene_theater() -> void:
	if cutscene_theater_panel:
		return

	_close_story_panel()

	cutscene_theater_panel = PanelContainer.new()
	cutscene_theater_panel.name = "CutsceneTheater"
	cutscene_theater_panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.08, 0.98)
	cutscene_theater_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	cutscene_theater_panel.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)

	# Header
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 15)
	main_vbox.add_child(header_row)

	var title = Label.new()
	title.text = "🎬 Cutscene Theater"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "Back"
	close_btn.custom_minimum_size = Vector2(100, 45)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_cutscene_theater)
	header_row.add_child(close_btn)

	var subtitle = Label.new()
	subtitle.text = "Replay scenes from your journey. Only scenes you've experienced are available."
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	main_vbox.add_child(subtitle)

	# Scrollable cutscene list
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	main_vbox.add_child(scroll)

	var cutscene_grid = GridContainer.new()
	cutscene_grid.columns = 5  # More columns to span width
	cutscene_grid.add_theme_constant_override("h_separation", 15)
	cutscene_grid.add_theme_constant_override("v_separation", 15)
	cutscene_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cutscene_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(cutscene_grid)

	# Get cutscenes from the cutscene script
	var cutscene_data = _get_available_cutscenes()

	for cs in cutscene_data:
		_add_cutscene_card(cutscene_grid, cs)

	add_child(cutscene_theater_panel)


func _get_available_cutscenes() -> Array:
	# Define cutscene metadata for theater display
	var cutscenes = [
		{"id": "intro", "title": "First Contact", "chapter": "Chapter 1", "icon": "🚀"},
		{"id": "discipline_awakens", "title": "Discipline Awakens", "chapter": "Chapter 2", "icon": "⚔️"},
		{"id": "growth_begins", "title": "Growth Begins", "chapter": "Chapter 3", "icon": "🌱"},
		{"id": "vitality_awakens", "title": "Vitality Awakens", "chapter": "Chapter 3", "icon": "💪"},
		{"id": "family_dinner", "title": "Family Dinner", "chapter": "Chapter 3", "icon": "🍽️"},
		{"id": "need_direction", "title": "Need Direction", "chapter": "Chapter 4", "icon": "🧭"},
		{"id": "wisdom_awakens", "title": "Wisdom Awakens", "chapter": "Chapter 4", "icon": "🦉"},
		{"id": "arctis_navigation", "title": "Star Navigation", "chapter": "Chapter 4", "icon": "⭐"},
		{"id": "darkness_stirs", "title": "Darkness Stirs", "chapter": "Chapter 5", "icon": "🌑"},
		{"id": "courage_awakens", "title": "Courage Awakens", "chapter": "Chapter 7", "icon": "🦁"},
		{"id": "creativity_awakens", "title": "Creativity Awakens", "chapter": "Chapter 8", "icon": "🎨"},
		{"id": "compassion_awakens", "title": "Compassion Awakens", "chapter": "Chapter 6", "icon": "💗"},
		{"id": "certification_ceremony", "title": "Certification", "chapter": "Chapter 10", "icon": "🏆"}
	]
	return cutscenes


func _add_cutscene_card(container: Control, cs: Dictionary) -> void:
	var is_seen = CampaignManager.has_seen_cutscene(cs.id)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 140)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10

	if is_seen:
		style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
		style.border_color = Color(0.5, 0.45, 0.6, 0.5)
	else:
		style.bg_color = Color(0.08, 0.08, 0.1, 0.6)
		style.border_color = Color(0.3, 0.3, 0.35, 0.3)

	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	card.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Icon
	var icon = Label.new()
	icon.text = cs.icon if is_seen else "🔒"
	icon.add_theme_font_size_override("font_size", 32)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not is_seen:
		icon.modulate = Color(0.5, 0.5, 0.55)
	vbox.add_child(icon)

	# Title
	var title = Label.new()
	title.text = cs.title if is_seen else "???"
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_seen:
		title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	else:
		title.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	vbox.add_child(title)

	# Chapter
	var chapter = Label.new()
	chapter.text = cs.chapter
	chapter.add_theme_font_size_override("font_size", 12)
	chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	vbox.add_child(chapter)

	# Play button (only if seen)
	if is_seen:
		var play_btn = Button.new()
		play_btn.text = "▶ Play"
		play_btn.custom_minimum_size = Vector2(0, 30)
		play_btn.add_theme_font_size_override("font_size", 14)
		play_btn.pressed.connect(_play_cutscene.bind(cs.id))
		vbox.add_child(play_btn)

	container.add_child(card)


func _play_cutscene(cutscene_id: String) -> void:
	_close_cutscene_theater()

	# Set replay mode and pending cutscene
	GameManager.player_data["cutscene_replay_mode"] = true
	GameManager.player_data["pending_cutscene"] = cutscene_id
	GameManager.previous_scene_path = "res://scenes/mindscape/mindscape_hub.tscn"

	GameManager.goto_scene("res://scenes/cutscene/cutscene.tscn")


func _close_cutscene_theater() -> void:
	if cutscene_theater_panel:
		cutscene_theater_panel.queue_free()
		cutscene_theater_panel = null


func _export_progress_data() -> void:
	_close_pause_menu()

	# Compile all progress data
	var export_data = {
		"export_date": Time.get_datetime_string_from_system(),
		"version": "0.1.4",
		"player": {
			"evolution_level": GameManager.get_evolution_level(),
			"total_focus_minutes": GameManager.player_data.get("total_focus_minutes", 0),
			"total_habits_completed": GameManager.player_data.get("total_habits_completed", 0)
		},
		"aspects": GameManager.player_data.get("aspects", {}),
		"habits": {},
		"goals": {},
		"achievements": {},
		"focus_sessions": _load_focus_journal(),
		"weekly_stats": HabitManager.get_weekly_stats()
	}

	# Add habit data
	for habit in HabitManager.get_all_habits(true):
		export_data.habits[habit.id] = {
			"name": habit.get("name", ""),
			"streak": habit.get("streak", 0),
			"best_streak": habit.get("best_streak", 0),
			"total_completions": habit.get("total_completions", 0)
		}

	# Add goal data
	for goal in GoalManager.get_all_goals():
		export_data.goals[goal.id] = {
			"title": goal.get("title", ""),
			"status": "completed" if goal.get("status") == GoalManager.GoalStatus.COMPLETED else "active",
			"progress": goal.get("progress", 0),
			"target": goal.get("target_progress", 1)
		}

	# Add achievement data
	if AchievementManager:
		export_data.achievements = {
			"unlocked_count": AchievementManager.get_unlocked_achievements().size(),
			"total_count": AchievementManager.ACHIEVEMENTS.size(),
			"stats": AchievementManager.stats
		}

	# Save to file
	var timestamp = Time.get_unix_time_from_system()
	var filename = "user://mindscape_export_%d.json" % timestamp
	var json_string = JSON.stringify(export_data, "\t")

	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

		# Get the actual path for display
		var actual_path = ProjectSettings.globalize_path(filename)
		_show_dialogue("Export Complete", "Progress data exported!\n\nFile: %s" % actual_path)
		print("[MindscapeHub] Progress exported to: ", actual_path)
	else:
		_show_dialogue("Export Failed", "Could not save export file.\n\nError: " + str(FileAccess.get_open_error()))


func _confirm_reset_habits() -> void:
	_close_pause_menu()
	_show_dialogue("Reset Habits?", "This will delete ALL habits and their history.\n\nPreset habits will be restored.\n\nThis cannot be undone!", func():
		HabitManager.reset_habits()
		SaveManager.save_game()
		_show_dialogue("Reset Complete", "Habits have been reset to defaults.")
	)


func _confirm_reset_goals() -> void:
	_close_pause_menu()
	_show_dialogue("Reset Goals?", "This will delete ALL goals.\n\nThis cannot be undone!", func():
		GoalManager.reset_goals()
		SaveManager.save_game()
		_show_dialogue("Reset Complete", "All goals have been cleared.")
	)


func _confirm_reset_challenges() -> void:
	_close_pause_menu()
	_show_dialogue("Reset Challenges?", "This will reset all daily and weekly challenges.\n\nNew challenges will be generated.", func():
		ChallengeManager.reset_challenges()
		SaveManager.save_game()
		_show_dialogue("Reset Complete", "Challenges have been reset.")
	)


func _setup_header_controls() -> void:
	var header_hbox = menu_button.get_parent()

	# Create save indicator (shows current save slot name)
	save_indicator = Label.new()
	save_indicator.add_theme_font_size_override("font_size", 14)
	save_indicator.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	save_indicator.tooltip_text = "Current save file"
	_update_save_indicator()
	header_hbox.add_child(save_indicator)
	header_hbox.move_child(save_indicator, menu_button.get_index())

	# Create volume button
	volume_button = Button.new()
	volume_button.custom_minimum_size = Vector2(45, 45)
	volume_button.add_theme_font_size_override("font_size", 20)
	volume_button.tooltip_text = "Volume (M to mute)"
	volume_button.pressed.connect(_toggle_volume_popup)
	_update_volume_button_icon()
	header_hbox.add_child(volume_button)
	header_hbox.move_child(volume_button, menu_button.get_index())

	# Check if currently muted
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		is_muted = audio.master_volume <= 0.01


func _update_save_indicator() -> void:
	if not save_indicator:
		return

	var current_slot = SaveManager.current_slot
	if current_slot > 0:
		var info = SaveManager.get_slot_info(current_slot)
		if info.exists:
			save_indicator.text = info.slot_name
		else:
			save_indicator.text = "Slot %d" % current_slot
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

	# Position below the volume button
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

	# Title
	var title = Label.new()
	title.text = "Volume"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var audio = get_node_or_null("/root/AudioManager")

	# Master volume slider
	var master_row = HBoxContainer.new()
	master_row.add_theme_constant_override("separation", 8)
	vbox.add_child(master_row)

	var master_label = Label.new()
	master_label.text = "Master"
	master_label.custom_minimum_size = Vector2(55, 0)
	master_label.add_theme_font_size_override("font_size", 14)
	master_row.add_child(master_label)

	var master_slider = HSlider.new()
	master_slider.min_value = 0
	master_slider.max_value = 100
	master_slider.value = audio.master_volume * 100 if audio else 100
	master_slider.custom_minimum_size = Vector2(100, 20)
	master_slider.value_changed.connect(func(val): _on_volume_changed("master", val))
	master_row.add_child(master_slider)

	# Music volume slider
	var music_row = HBoxContainer.new()
	music_row.add_theme_constant_override("separation", 8)
	vbox.add_child(music_row)

	var music_label = Label.new()
	music_label.text = "Music"
	music_label.custom_minimum_size = Vector2(55, 0)
	music_label.add_theme_font_size_override("font_size", 14)
	music_row.add_child(music_label)

	var music_slider = HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.value = audio.music_volume * 100 if audio else 100
	music_slider.custom_minimum_size = Vector2(100, 20)
	music_slider.value_changed.connect(func(val): _on_volume_changed("music", val))
	music_row.add_child(music_slider)

	# SFX volume slider
	var sfx_row = HBoxContainer.new()
	sfx_row.add_theme_constant_override("separation", 8)
	vbox.add_child(sfx_row)

	var sfx_label = Label.new()
	sfx_label.text = "SFX"
	sfx_label.custom_minimum_size = Vector2(55, 0)
	sfx_label.add_theme_font_size_override("font_size", 14)
	sfx_row.add_child(sfx_label)

	var sfx_slider = HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.value = audio.sfx_volume * 100 if audio else 100
	sfx_slider.custom_minimum_size = Vector2(100, 20)
	sfx_slider.value_changed.connect(func(val): _on_volume_changed("sfx", val))
	sfx_row.add_child(sfx_slider)

	# Mute button
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
		"master":
			audio.set_master_volume(vol)
		"music":
			audio.set_music_volume(vol)
		"sfx":
			audio.set_sfx_volume(vol)

	_update_volume_button_icon()


func _toggle_mute() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		return

	if is_muted:
		# Restore to default
		audio.set_master_volume(1.0)
		is_muted = false
	else:
		# Mute
		audio.set_master_volume(0.0)
		is_muted = true

	_update_volume_button_icon()
	_close_volume_popup()


func _update_header() -> void:
	# Save indicator
	if save_indicator and SaveManager:
		var slot = SaveManager.current_slot
		if slot == 0:
			save_indicator.text = "Auto-Save"
		else:
			var slot_info = SaveManager.get_slot_info(slot)
			var slot_name = slot_info.get("slot_name", "Slot " + str(slot))
			save_indicator.text = slot_name

	# Evolution level
	var level = GameManager.get_evolution_level()
	var progress = GameManager.get_evolution_progress()
	evolution_label.text = "Evolution " + str(level)
	evolution_bar.value = progress * 100

	# Date
	var date = Time.get_date_dict_from_system()
	var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	date_label.text = months[date.month - 1] + " " + str(date.day)

	# Dynamic greeting
	_update_greeting()

	# Daily progress indicators
	_update_daily_progress()


func _update_daily_progress() -> void:
	# Get today's habit stats
	var today = Time.get_date_string_from_system()
	var habits = HabitManager.get_all_habits() if HabitManager else []
	var habits_due = 0
	var habits_done = 0
	var active_streaks = 0

	for habit in habits:
		# Check if habit is due today (frequency is an enum: 0=DAILY, 1=WEEKLY, 2=CUSTOM)
		var is_daily = habit.get("frequency", 0) == 0  # HabitFrequency.DAILY
		if is_daily or _is_habit_due_today(habit):
			habits_due += 1
			if habit.get("last_completed", "") == today:
				habits_done += 1
		# Count active streaks
		if habit.get("streak", 0) >= 3:
			active_streaks += 1

	# Update habits label
	if habits_today_label:
		if habits_due > 0:
			habits_today_label.text = "%d/%d Habits" % [habits_done, habits_due]
			if habits_done >= habits_due:
				habits_today_label.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5, 1))  # Green when complete
		else:
			habits_today_label.text = "No habits"

	# Get today's focus time
	var focus_minutes = _get_today_focus_minutes()
	if focus_today_label:
		if focus_minutes > 0:
			focus_today_label.text = "%d min" % focus_minutes
		else:
			focus_today_label.text = "0 min"

	# Update streaks label
	if streaks_label:
		if active_streaks > 0:
			streaks_label.text = "🔥 %d" % active_streaks
		else:
			streaks_label.text = "No streaks"


func _is_habit_due_today(habit: Dictionary) -> bool:
	# frequency is an enum: 0=DAILY, 1=WEEKLY, 2=CUSTOM
	var freq = habit.get("frequency", 0)
	if freq == 0:  # DAILY
		return true
	elif freq == 1:  # WEEKLY
		# Check if today matches a scheduled day
		var weekday = Time.get_date_dict_from_system().weekday
		var days = habit.get("days", [])
		# Days might be stored as ints (0-6) or strings - handle both
		for day in days:
			if typeof(day) == TYPE_INT and day == weekday:
				return true
			elif typeof(day) == TYPE_STRING:
				var day_names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
				if day_names[weekday].to_lower() == day.to_lower():
					return true
		return false
	return false


func _get_today_focus_minutes() -> int:
	var today = Time.get_date_string_from_system()
	var total_minutes = 0

	# Check focus sessions from today
	var sessions = GameManager.player_data.get("focus_sessions", [])
	for session in sessions:
		if session.get("date", "").begins_with(today):
			total_minutes += session.get("duration_minutes", 0)

	return total_minutes


func _update_greeting() -> void:
	var time = Time.get_time_dict_from_system()
	var hour = time.hour
	var player_name = GameManager.player_data.get("name", "Traveler")

	var greeting_text: String
	var greeting_color: Color

	if hour >= 5 and hour < 12:
		# Morning greetings
		var morning_greetings = [
			"Good morning, %s!",
			"Rise and shine, %s!",
			"A new day awaits, %s",
			"Morning, %s! Ready to grow?",
		]
		greeting_text = morning_greetings[randi() % morning_greetings.size()] % player_name
		greeting_color = Color(0.9, 0.75, 0.4)  # Warm morning gold
	elif hour >= 12 and hour < 17:
		# Afternoon greetings
		var afternoon_greetings = [
			"Good afternoon, %s!",
			"Keep it up, %s!",
			"Afternoon focus, %s",
			"Making progress, %s?",
		]
		greeting_text = afternoon_greetings[randi() % afternoon_greetings.size()] % player_name
		greeting_color = Color(0.8, 0.7, 0.5)  # Soft afternoon
	elif hour >= 17 and hour < 21:
		# Evening greetings
		var evening_greetings = [
			"Good evening, %s!",
			"Evening session, %s?",
			"Winding down, %s?",
			"Evening mindscape, %s",
		]
		greeting_text = evening_greetings[randi() % evening_greetings.size()] % player_name
		greeting_color = Color(0.7, 0.55, 0.8)  # Purple evening
	else:
		# Night greetings
		var night_greetings = [
			"Night owl, %s?",
			"Burning the midnight oil, %s?",
			"Late night session, %s",
			"Can't sleep, %s?",
		]
		greeting_text = night_greetings[randi() % night_greetings.size()] % player_name
		greeting_color = Color(0.5, 0.6, 0.9)  # Night blue

	# Check for streaks at risk
	var at_risk = HabitManager.get_habits_needing_recovery()
	if at_risk.size() > 0:
		greeting_text += " ⚠️"  # Warning indicator

	# Check if all habits done today
	var habits = HabitManager.get_all_habits()
	var all_done = true
	for habit in habits:
		if not HabitManager.is_completed_today(habit.id):
			all_done = false
			break
	if habits.size() > 0 and all_done:
		greeting_text = "All done today, %s! ⭐" % player_name
		greeting_color = Color(0.5, 0.9, 0.6)  # Green for completion

	# Add total focus time milestone info
	var total_focus = int(GameManager.player_data.get("total_focus_minutes", 0))
	if total_focus >= 1000:
		var hours = total_focus / 60
		greeting_text += " [%dh focused]" % hours
	elif total_focus >= 100:
		greeting_text += " [%dm focused]" % total_focus

	greeting_label.text = greeting_text
	greeting_label.add_theme_color_override("font_color", greeting_color)


func _update_portal_visuals() -> void:
	# Update portal appearance based on unlock status
	for portal in portals_node.get_children():
		var region_id = portal_to_region.get(portal.name, "")
		var is_unlocked = MindscapeRegionManager.is_region_unlocked(region_id)

		var glow = portal.get_node_or_null("Glow")
		var lock_icon = portal.get_node_or_null("LockIcon")
		var lock_overlay = portal.get_node_or_null("LockOverlay")
		var lock_chain1 = portal.get_node_or_null("LockChain1")
		var lock_chain2 = portal.get_node_or_null("LockChain2")
		var lock_shackle = portal.get_node_or_null("LockShackle")
		var lock_keyhole = portal.get_node_or_null("LockKeyhole")

		if glow:
			if is_unlocked:
				var theme_color = MindscapeRegionManager.get_region_theme_color(region_id)
				glow.color = Color(theme_color.r, theme_color.g, theme_color.b, 0.4)
				glow.visible = true
			else:
				glow.color = Color(0.3, 0.3, 0.4, 0.2)

		# Show/hide all lock elements
		var show_lock = not is_unlocked
		if lock_icon:
			lock_icon.visible = show_lock
		if lock_overlay:
			lock_overlay.visible = show_lock
		if lock_chain1:
			lock_chain1.visible = show_lock
		if lock_chain2:
			lock_chain2.visible = show_lock
		if lock_shackle:
			lock_shackle.visible = show_lock
		if lock_keyhole:
			lock_keyhole.visible = show_lock


func _create_enhanced_portals() -> void:
	# Enhance each portal with unique themed graphics
	for portal in portals_node.get_children():
		var portal_name = portal.name
		var region_id = portal_to_region.get(portal_name, "")

		# Create enhancement container
		var enhancements = Node2D.new()
		enhancements.name = "Enhancements"
		portal.add_child(enhancements)
		portal.move_child(enhancements, 0)  # Put behind other elements

		match region_id:
			"north":
				_create_north_portal_enhancements(portal, enhancements)
			"east":
				_create_east_portal_enhancements(portal, enhancements)
			"west":
				_create_west_portal_enhancements(portal, enhancements)
			"south":
				_create_south_portal_enhancements(portal, enhancements)


func _create_north_portal_enhancements(portal: Node2D, container: Node2D) -> void:
	# Northern Gardens - Nature themed with vines, leaves, flowers
	var portal_name = portal.name
	portal_particles[portal_name] = []
	portal_energy_rings[portal_name] = []
	portal_decorations[portal_name] = []

	# Vine pillars on sides
	for side in [-1, 1]:
		var vine_pillar = Polygon2D.new()
		vine_pillar.color = Color(0.2, 0.35, 0.25, 0.9)
		vine_pillar.polygon = PackedVector2Array([
			Vector2(side * 48, -75), Vector2(side * 58, -75),
			Vector2(side * 60, 35), Vector2(side * 45, 35)
		])
		container.add_child(vine_pillar)

		# Vine tendrils
		for i in range(4):
			var tendril = Polygon2D.new()
			tendril.color = Color(0.25, 0.45, 0.3, 0.8)
			var y_pos = -60 + i * 25
			var curl = sin(i * 1.5) * 8
			tendril.polygon = PackedVector2Array([
				Vector2(side * 55, y_pos), Vector2(side * (65 + curl), y_pos + 5),
				Vector2(side * (68 + curl), y_pos + 15), Vector2(side * 55, y_pos + 10)
			])
			container.add_child(tendril)
			portal_decorations[portal_name].append({"node": tendril, "type": "tendril", "base_y": y_pos, "side": side, "index": i})

	# Arch with leaves
	var leaf_arch = Polygon2D.new()
	leaf_arch.color = Color(0.3, 0.5, 0.35, 0.95)
	leaf_arch.polygon = PackedVector2Array([
		Vector2(-52, -72), Vector2(-25, -90), Vector2(0, -95), Vector2(25, -90), Vector2(52, -72),
		Vector2(48, -68), Vector2(25, -85), Vector2(0, -90), Vector2(-25, -85), Vector2(-48, -68)
	])
	container.add_child(leaf_arch)

	# Decorative leaves on arch
	for i in range(7):
		var leaf = Polygon2D.new()
		leaf.color = Color(0.35 + randf() * 0.1, 0.55 + randf() * 0.1, 0.35, 0.85)
		var angle = -PI * 0.8 + (i / 6.0) * PI * 0.6
		var leaf_pos = Vector2(cos(angle) * 45, -82 + sin(angle) * 15)
		var leaf_size = randf_range(6, 10)
		leaf.polygon = PackedVector2Array([
			Vector2(0, -leaf_size), Vector2(leaf_size * 0.6, 0),
			Vector2(0, leaf_size * 0.3), Vector2(-leaf_size * 0.6, 0)
		])
		leaf.position = leaf_pos
		leaf.rotation = angle + PI/2
		container.add_child(leaf)
		portal_decorations[portal_name].append({"node": leaf, "type": "leaf", "base_rot": leaf.rotation, "phase": randf() * TAU})

	# Floating leaf particles
	for i in range(6):
		var particle = Polygon2D.new()
		particle.color = Color(0.4, 0.6, 0.35, 0.6)
		var size = randf_range(3, 6)
		particle.polygon = PackedVector2Array([
			Vector2(0, -size), Vector2(size * 0.5, 0),
			Vector2(0, size * 0.4), Vector2(-size * 0.5, 0)
		])
		particle.position = Vector2(randf_range(-40, 40), randf_range(-60, 20))
		container.add_child(particle)
		portal_particles[portal_name].append({
			"node": particle,
			"base_pos": particle.position,
			"phase": randf() * TAU,
			"speed": randf_range(0.5, 1.0),
			"drift": randf_range(10, 20)
		})

	# Energy vines (animated rings)
	for i in range(3):
		var ring = Polygon2D.new()
		ring.color = Color(0.4, 0.7, 0.5, 0.2 - i * 0.05)
		var ring_points = PackedVector2Array()
		var ring_size = 35 + i * 8
		for j in range(16):
			var angle = (j / 16.0) * TAU
			ring_points.append(Vector2(cos(angle) * ring_size, sin(angle) * ring_size * 0.6 - 20))
		ring.polygon = ring_points
		container.add_child(ring)
		portal_energy_rings[portal_name].append({"node": ring, "base_size": ring_size, "phase": i * 0.5})

	# Flower decorations at base
	for side in [-1, 1]:
		var flower = Polygon2D.new()
		flower.color = Color(0.8, 0.5, 0.6, 0.8)
		flower.polygon = PackedVector2Array([
			Vector2(0, -6), Vector2(4, -2), Vector2(4, 2), Vector2(0, 6),
			Vector2(-4, 2), Vector2(-4, -2)
		])
		flower.position = Vector2(side * 42, 28)
		container.add_child(flower)
		portal_decorations[portal_name].append({"node": flower, "type": "flower", "phase": randf() * TAU})


func _create_east_portal_enhancements(portal: Node2D, container: Node2D) -> void:
	# Eastern Observatory - Celestial themed with stars, constellations
	var portal_name = portal.name
	portal_particles[portal_name] = []
	portal_energy_rings[portal_name] = []
	portal_decorations[portal_name] = []

	# Elegant pillars with star motifs
	for side in [-1, 1]:
		var pillar = Polygon2D.new()
		pillar.color = Color(0.2, 0.22, 0.35, 0.95)
		pillar.polygon = PackedVector2Array([
			Vector2(side * 48, -78), Vector2(side * 56, -78),
			Vector2(side * 58, -70), Vector2(side * 58, 35),
			Vector2(side * 46, 35), Vector2(side * 46, -70)
		])
		container.add_child(pillar)

		# Star engravings on pillars
		for i in range(3):
			var star = _create_star_polygon(4, 2)
			star.color = Color(0.6, 0.65, 0.9, 0.7)
			star.position = Vector2(side * 52, -50 + i * 30)
			star.scale = Vector2(0.8, 0.8)
			container.add_child(star)
			portal_decorations[portal_name].append({"node": star, "type": "star_engraving", "phase": randf() * TAU})

	# Celestial arch with moon phases
	var arch = Polygon2D.new()
	arch.color = Color(0.25, 0.28, 0.45, 0.95)
	arch.polygon = PackedVector2Array([
		Vector2(-54, -75), Vector2(-30, -95), Vector2(0, -102), Vector2(30, -95), Vector2(54, -75),
		Vector2(50, -70), Vector2(28, -90), Vector2(0, -96), Vector2(-28, -90), Vector2(-50, -70)
	])
	container.add_child(arch)

	# Moon symbol at top
	var moon = Polygon2D.new()
	moon.color = Color(0.85, 0.88, 0.95, 0.9)
	var moon_points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		moon_points.append(Vector2(cos(angle) * 10, sin(angle) * 10 - 98))
	moon.polygon = moon_points
	container.add_child(moon)
	portal_decorations[portal_name].append({"node": moon, "type": "moon", "phase": 0})

	# Crescent shadow on moon
	var crescent = Polygon2D.new()
	crescent.color = Color(0.15, 0.18, 0.3, 0.9)
	var crescent_points = PackedVector2Array()
	for i in range(8):
		var angle = -PI/2 + (i / 7.0) * PI
		crescent_points.append(Vector2(cos(angle) * 10 + 4, sin(angle) * 10 - 98))
	crescent.polygon = crescent_points
	container.add_child(crescent)

	# Constellation lines
	var constellation_points = [
		Vector2(-30, -80), Vector2(-15, -85), Vector2(5, -78),
		Vector2(20, -88), Vector2(35, -82)
	]
	for i in range(len(constellation_points) - 1):
		var line = Polygon2D.new()
		line.color = Color(0.5, 0.55, 0.8, 0.3)
		var p1 = constellation_points[i]
		var p2 = constellation_points[i + 1]
		var dir = (p2 - p1).normalized()
		var perp = Vector2(-dir.y, dir.x) * 1
		line.polygon = PackedVector2Array([p1 - perp, p1 + perp, p2 + perp, p2 - perp])
		container.add_child(line)

	# Stars at constellation points
	for point in constellation_points:
		var star = _create_star_polygon(3, 1.5)
		star.color = Color(0.8, 0.85, 1.0, 0.9)
		star.position = point
		container.add_child(star)
		portal_decorations[portal_name].append({"node": star, "type": "constellation_star", "phase": randf() * TAU})

	# Floating star particles
	for i in range(8):
		var particle = _create_star_polygon(randf_range(2, 4), randf_range(1, 2))
		particle.color = Color(0.7, 0.75, 1.0, randf_range(0.4, 0.7))
		particle.position = Vector2(randf_range(-45, 45), randf_range(-70, 25))
		container.add_child(particle)
		portal_particles[portal_name].append({
			"node": particle,
			"base_pos": particle.position,
			"phase": randf() * TAU,
			"speed": randf_range(0.3, 0.8),
			"drift": randf_range(5, 12),
			"twinkle": true
		})

	# Cosmic energy rings
	for i in range(3):
		var ring = Polygon2D.new()
		ring.color = Color(0.5, 0.55, 0.9, 0.15 - i * 0.03)
		var ring_points = PackedVector2Array()
		var ring_size = 38 + i * 10
		for j in range(20):
			var angle = (j / 20.0) * TAU
			ring_points.append(Vector2(cos(angle) * ring_size, sin(angle) * ring_size * 0.5 - 20))
		ring.polygon = ring_points
		container.add_child(ring)
		portal_energy_rings[portal_name].append({"node": ring, "base_size": ring_size, "phase": i * 0.7})


func _create_west_portal_enhancements(portal: Node2D, container: Node2D) -> void:
	# Western Depths - Crystal/cave themed with crystals, amethyst
	var portal_name = portal.name
	portal_particles[portal_name] = []
	portal_energy_rings[portal_name] = []
	portal_decorations[portal_name] = []

	# Rocky cave entrance frame
	var cave_frame = Polygon2D.new()
	cave_frame.color = Color(0.22, 0.18, 0.28, 0.95)
	cave_frame.polygon = PackedVector2Array([
		Vector2(-60, -75), Vector2(-55, -85), Vector2(-30, -95), Vector2(0, -100),
		Vector2(30, -95), Vector2(55, -85), Vector2(60, -75), Vector2(60, 35),
		Vector2(50, 35), Vector2(50, -70), Vector2(30, -88), Vector2(0, -92),
		Vector2(-30, -88), Vector2(-50, -70), Vector2(-50, 35), Vector2(-60, 35)
	])
	container.add_child(cave_frame)

	# Crystal clusters on left
	var crystals_left = [
		{"pos": Vector2(-55, -50), "rot": -0.3, "size": 18, "color": Color(0.6, 0.4, 0.75, 0.9)},
		{"pos": Vector2(-58, -30), "rot": -0.5, "size": 14, "color": Color(0.5, 0.35, 0.7, 0.85)},
		{"pos": Vector2(-52, -65), "rot": -0.2, "size": 12, "color": Color(0.7, 0.5, 0.85, 0.8)},
		{"pos": Vector2(-60, -10), "rot": -0.4, "size": 16, "color": Color(0.55, 0.4, 0.72, 0.88)}
	]

	for data in crystals_left:
		var crystal = _create_crystal_polygon(data["size"])
		crystal.color = data["color"]
		crystal.position = data["pos"]
		crystal.rotation = data["rot"]
		container.add_child(crystal)
		portal_decorations[portal_name].append({"node": crystal, "type": "crystal", "phase": randf() * TAU})

	# Crystal clusters on right
	var crystals_right = [
		{"pos": Vector2(55, -45), "rot": 0.35, "size": 16, "color": Color(0.6, 0.4, 0.75, 0.9)},
		{"pos": Vector2(58, -25), "rot": 0.5, "size": 13, "color": Color(0.5, 0.35, 0.7, 0.85)},
		{"pos": Vector2(53, -68), "rot": 0.25, "size": 11, "color": Color(0.7, 0.5, 0.85, 0.8)},
		{"pos": Vector2(60, -5), "rot": 0.45, "size": 15, "color": Color(0.55, 0.4, 0.72, 0.88)}
	]

	for data in crystals_right:
		var crystal = _create_crystal_polygon(data["size"])
		crystal.color = data["color"]
		crystal.position = data["pos"]
		crystal.rotation = data["rot"]
		container.add_child(crystal)
		portal_decorations[portal_name].append({"node": crystal, "type": "crystal", "phase": randf() * TAU})

	# Large central crystal at top
	var top_crystal = _create_crystal_polygon(22)
	top_crystal.color = Color(0.65, 0.45, 0.8, 0.95)
	top_crystal.position = Vector2(0, -95)
	top_crystal.rotation = PI
	container.add_child(top_crystal)
	portal_decorations[portal_name].append({"node": top_crystal, "type": "crystal_main", "phase": 0})

	# Crystal glow behind top crystal
	var crystal_glow = Polygon2D.new()
	crystal_glow.color = Color(0.6, 0.4, 0.8, 0.25)
	var glow_points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		glow_points.append(Vector2(cos(angle) * 30, sin(angle) * 30 - 92))
	crystal_glow.polygon = glow_points
	container.add_child(crystal_glow)
	container.move_child(crystal_glow, 0)
	portal_decorations[portal_name].append({"node": crystal_glow, "type": "crystal_glow", "phase": 0})

	# Floating crystal shards
	for i in range(6):
		var shard = _create_crystal_polygon(randf_range(4, 8))
		shard.color = Color(0.6 + randf() * 0.15, 0.4 + randf() * 0.1, 0.75 + randf() * 0.1, randf_range(0.5, 0.75))
		shard.position = Vector2(randf_range(-40, 40), randf_range(-65, 20))
		shard.rotation = randf() * TAU
		container.add_child(shard)
		portal_particles[portal_name].append({
			"node": shard,
			"base_pos": shard.position,
			"base_rot": shard.rotation,
			"phase": randf() * TAU,
			"speed": randf_range(0.4, 0.9),
			"drift": randf_range(8, 15),
			"rotate": true
		})

	# Mystical energy rings (purple)
	for i in range(3):
		var ring = Polygon2D.new()
		ring.color = Color(0.6, 0.4, 0.8, 0.12 - i * 0.025)
		var ring_points = PackedVector2Array()
		var ring_size = 35 + i * 12
		for j in range(16):
			var angle = (j / 16.0) * TAU
			ring_points.append(Vector2(cos(angle) * ring_size, sin(angle) * ring_size * 0.55 - 18))
		ring.polygon = ring_points
		container.add_child(ring)
		portal_energy_rings[portal_name].append({"node": ring, "base_size": ring_size, "phase": i * 0.6})


func _create_south_portal_enhancements(portal: Node2D, container: Node2D) -> void:
	# Southern Peaks - Mountain/fire themed with rocky texture, warm colors, embers
	var portal_name = portal.name
	portal_particles[portal_name] = []
	portal_energy_rings[portal_name] = []
	portal_decorations[portal_name] = []

	# Rocky mountain arch frame
	var rock_frame = Polygon2D.new()
	rock_frame.color = Color(0.32, 0.26, 0.22, 0.95)
	rock_frame.polygon = PackedVector2Array([
		Vector2(-62, 35), Vector2(-58, -70), Vector2(-45, -85), Vector2(-20, -98),
		Vector2(0, -105), Vector2(20, -98), Vector2(45, -85), Vector2(58, -70),
		Vector2(62, 35), Vector2(50, 35), Vector2(48, -65), Vector2(35, -80),
		Vector2(15, -92), Vector2(0, -96), Vector2(-15, -92), Vector2(-35, -80),
		Vector2(-48, -65), Vector2(-50, 35)
	])
	container.add_child(rock_frame)

	# Rock textures/layers
	for i in range(5):
		var rock_layer = Polygon2D.new()
		rock_layer.color = Color(0.28 + randf() * 0.08, 0.22 + randf() * 0.06, 0.18 + randf() * 0.06, 0.6)
		var y_base = -60 + i * 22
		rock_layer.polygon = PackedVector2Array([
			Vector2(-55 + randf() * 5, y_base), Vector2(-50 + randf() * 5, y_base - 8),
			Vector2(-40 + randf() * 5, y_base - 3), Vector2(-55 + randf() * 5, y_base + 5)
		])
		container.add_child(rock_layer)

	for i in range(5):
		var rock_layer = Polygon2D.new()
		rock_layer.color = Color(0.28 + randf() * 0.08, 0.22 + randf() * 0.06, 0.18 + randf() * 0.06, 0.6)
		var y_base = -55 + i * 22
		rock_layer.polygon = PackedVector2Array([
			Vector2(55 - randf() * 5, y_base), Vector2(50 - randf() * 5, y_base - 8),
			Vector2(40 - randf() * 5, y_base - 3), Vector2(55 - randf() * 5, y_base + 5)
		])
		container.add_child(rock_layer)

	# Mountain peak symbol at top
	var peak = Polygon2D.new()
	peak.color = Color(0.45, 0.38, 0.32, 0.95)
	peak.polygon = PackedVector2Array([
		Vector2(-18, -88), Vector2(0, -108), Vector2(18, -88),
		Vector2(10, -90), Vector2(0, -100), Vector2(-10, -90)
	])
	container.add_child(peak)
	portal_decorations[portal_name].append({"node": peak, "type": "peak", "phase": 0})

	# Snow cap on peak
	var snow = Polygon2D.new()
	snow.color = Color(0.9, 0.92, 0.95, 0.85)
	snow.polygon = PackedVector2Array([
		Vector2(-8, -98), Vector2(0, -108), Vector2(8, -98),
		Vector2(5, -99), Vector2(0, -104), Vector2(-5, -99)
	])
	container.add_child(snow)

	# Warm glow from within (like lava/fire inside)
	var inner_glow = Polygon2D.new()
	inner_glow.color = Color(0.85, 0.5, 0.25, 0.2)
	inner_glow.polygon = PackedVector2Array([
		Vector2(-35, -55), Vector2(35, -55), Vector2(35, 25), Vector2(-35, 25)
	])
	container.add_child(inner_glow)
	portal_decorations[portal_name].append({"node": inner_glow, "type": "inner_glow", "phase": 0})

	# Torch flames on sides
	for side in [-1, 1]:
		var torch_base = Polygon2D.new()
		torch_base.color = Color(0.35, 0.28, 0.22, 0.95)
		torch_base.polygon = PackedVector2Array([
			Vector2(side * 52, -45), Vector2(side * 58, -45),
			Vector2(side * 56, -35), Vector2(side * 54, -35)
		])
		container.add_child(torch_base)

		# Flame
		var flame = Polygon2D.new()
		flame.color = Color(0.95, 0.6, 0.2, 0.85)
		flame.polygon = PackedVector2Array([
			Vector2(side * 55, -45), Vector2(side * 52, -55),
			Vector2(side * 55, -70), Vector2(side * 58, -55)
		])
		container.add_child(flame)
		portal_decorations[portal_name].append({"node": flame, "type": "flame", "side": side, "phase": randf() * TAU})

		# Inner flame
		var inner_flame = Polygon2D.new()
		inner_flame.color = Color(1.0, 0.85, 0.4, 0.9)
		inner_flame.polygon = PackedVector2Array([
			Vector2(side * 55, -48), Vector2(side * 53, -55),
			Vector2(side * 55, -62), Vector2(side * 57, -55)
		])
		container.add_child(inner_flame)
		portal_decorations[portal_name].append({"node": inner_flame, "type": "inner_flame", "side": side, "phase": randf() * TAU})

	# Ember particles floating up
	for i in range(8):
		var ember = Polygon2D.new()
		ember.color = Color(1.0, randf_range(0.4, 0.7), 0.1, randf_range(0.6, 0.9))
		var size = randf_range(2, 4)
		ember.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(0, -size), Vector2(size, 0), Vector2(0, size)
		])
		ember.position = Vector2(randf_range(-35, 35), randf_range(-50, 25))
		container.add_child(ember)
		portal_particles[portal_name].append({
			"node": ember,
			"base_pos": ember.position,
			"phase": randf() * TAU,
			"speed": randf_range(0.8, 1.5),
			"drift": randf_range(8, 15),
			"rise": true  # Embers float upward
		})

	# Warm energy rings
	for i in range(3):
		var ring = Polygon2D.new()
		ring.color = Color(0.9, 0.5, 0.25, 0.1 - i * 0.02)
		var ring_points = PackedVector2Array()
		var ring_size = 36 + i * 11
		for j in range(16):
			var angle = (j / 16.0) * TAU
			ring_points.append(Vector2(cos(angle) * ring_size, sin(angle) * ring_size * 0.5 - 15))
		ring.polygon = ring_points
		container.add_child(ring)
		portal_energy_rings[portal_name].append({"node": ring, "base_size": ring_size, "phase": i * 0.5})


func _create_star_polygon(outer_radius: float, inner_radius: float) -> Polygon2D:
	var star = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(10):
		var angle = (i / 10.0) * TAU - PI/2
		var radius = outer_radius if i % 2 == 0 else inner_radius
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	star.polygon = points
	return star


func _create_crystal_polygon(height: float) -> Polygon2D:
	var crystal = Polygon2D.new()
	var w = height * 0.35
	crystal.polygon = PackedVector2Array([
		Vector2(0, -height), Vector2(w, -height * 0.3),
		Vector2(w * 0.7, height * 0.2), Vector2(0, height * 0.3),
		Vector2(-w * 0.7, height * 0.2), Vector2(-w, -height * 0.3)
	])
	return crystal


func _animate_enhanced_portals(delta: float) -> void:
	portal_anim_time += delta

	for portal_name in portal_particles:
		# Animate particles
		for particle_data in portal_particles[portal_name]:
			var node = particle_data["node"]
			if not is_instance_valid(node):
				continue

			var base_pos = particle_data["base_pos"]
			var phase = particle_data["phase"]
			var speed = particle_data["speed"]
			var drift = particle_data["drift"]

			var offset_x = sin(portal_anim_time * speed + phase) * drift
			var offset_y = cos(portal_anim_time * speed * 0.7 + phase) * drift * 0.6

			# Rising embers for south portal
			if particle_data.get("rise", false):
				offset_y = -abs(sin(portal_anim_time * speed + phase)) * drift * 1.5
				# Cycle position when ember rises too high
				var cycle_y = fmod(portal_anim_time * speed * 0.3 + phase, 1.0) * 80 - 40
				node.position = base_pos + Vector2(offset_x * 0.5, cycle_y)
			else:
				node.position = base_pos + Vector2(offset_x, offset_y)

			# Twinkle effect for stars
			if particle_data.get("twinkle", false):
				node.modulate.a = 0.5 + sin(portal_anim_time * 3.0 + phase) * 0.4

			# Rotation for crystals
			if particle_data.get("rotate", false):
				var base_rot = particle_data.get("base_rot", 0.0)
				node.rotation = base_rot + sin(portal_anim_time * 0.5 + phase) * 0.3

		# Animate energy rings
		for ring_data in portal_energy_rings.get(portal_name, []):
			var node = ring_data["node"]
			if not is_instance_valid(node):
				continue

			var base_size = ring_data["base_size"]
			var phase = ring_data["phase"]
			var pulse = 1.0 + sin(portal_anim_time * 1.5 + phase) * 0.1
			node.scale = Vector2(pulse, pulse)
			node.modulate.a = 0.8 + sin(portal_anim_time * 2.0 + phase) * 0.2

		# Animate decorations
		for deco_data in portal_decorations.get(portal_name, []):
			var node = deco_data["node"]
			if not is_instance_valid(node):
				continue

			var deco_type = deco_data.get("type", "")
			var phase = deco_data.get("phase", 0.0)

			match deco_type:
				"leaf":
					var base_rot = deco_data.get("base_rot", 0.0)
					node.rotation = base_rot + sin(portal_anim_time * 1.2 + phase) * 0.15
				"tendril":
					var base_y = deco_data.get("base_y", 0.0)
					var idx = deco_data.get("index", 0)
					node.position.y = base_y + sin(portal_anim_time * 0.8 + idx * 0.5) * 3
				"flower":
					node.scale = Vector2(1.0, 1.0) * (1.0 + sin(portal_anim_time * 1.5 + phase) * 0.1)
				"crystal", "crystal_main":
					node.modulate.a = 0.85 + sin(portal_anim_time * 2.0 + phase) * 0.15
				"crystal_glow":
					node.modulate.a = 0.6 + sin(portal_anim_time * 1.8) * 0.3
					node.scale = Vector2(1.0, 1.0) * (1.0 + sin(portal_anim_time * 1.5) * 0.15)
				"star_engraving", "constellation_star":
					node.modulate.a = 0.7 + sin(portal_anim_time * 2.5 + phase) * 0.3
				"moon":
					node.modulate = Color(1.0, 1.0, 1.0, 0.85 + sin(portal_anim_time * 0.8) * 0.15)
				"flame", "inner_flame":
					var side = deco_data.get("side", 1)
					var flicker = sin(portal_anim_time * 8.0 + phase) * 0.15
					node.scale = Vector2(1.0 + flicker * 0.3, 1.0 + abs(flicker))
					node.position.x = side * 55 + sin(portal_anim_time * 6.0 + phase) * 1.5
				"inner_glow":
					node.modulate.a = 0.15 + sin(portal_anim_time * 1.2) * 0.08


func _center_base() -> void:
	await get_tree().process_frame
	_update_camera()


func _update_camera() -> void:
	if not game_world or not isometric_base or not player:
		return

	var screen_center = game_world.size / 2
	var target = screen_center - player.position * camera_zoom
	isometric_base.position = target
	isometric_base.scale = Vector2(camera_zoom, camera_zoom)


func _apply_zoom(amount: float) -> void:
	camera_zoom = clamp(camera_zoom + amount, min_zoom, max_zoom)
	_update_camera()


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


func _constrain_to_diamond(pos: Vector2) -> Vector2:
	# Diamond constraint: |x|/width + |y|/height <= 1
	# For our platform with half-widths of 850 and 420
	var normalized_dist = abs(pos.x) / platform_half_width + abs(pos.y) / platform_half_height

	if normalized_dist <= 1.0:
		return pos  # Inside diamond, no change needed

	# Outside diamond - push back toward center along the same direction
	# Scale the position to be on the diamond edge
	return pos / normalized_dist


# ============ MINDSCAPE ONBOARDING ============

var onboarding_panel: PanelContainer = null
var onboarding_slide_index: int = 0
var onboarding_text_label: Label = null
var onboarding_typing_tween: Tween = null
var onboarding_back_btn: Button = null
var onboarding_next_btn: Button = null
var onboarding_full_text: String = ""
var onboarding_voice_finished: bool = false

var ONBOARDING_SLIDES = [
	{
		"title": "Welcome to Your Mindscape",
		"text": "This is your inner world - a place that grows and evolves as you do.\n\nEvery real-world action you take transforms this space into something beautiful.",
		"color": Color(0.83, 0.66, 0.29),
		"voice": "res://audio/voice/onboarding/slide_0.ogg",
		"illustration": "mindscape"
	},
	{
		"title": "Focus Sessions",
		"text": "Enter the Focus Chamber to start 25-minute deep work sessions.\n\nPut your phone aside and do real work. When you return, reflect on what you learned.",
		"color": Color(0.4, 0.6, 0.5),
		"voice": "res://audio/voice/onboarding/slide_1.ogg",
		"illustration": "focus"
	},
	{
		"title": "Your Six Aspects",
		"text": "Discipline, Courage, Creativity, Compassion, Wisdom, and Vitality - these Aspects represent parts of yourself.\n\nThey grow stronger as you build habits in their domains.",
		"color": Color(0.6, 0.4, 0.7),
		"voice": "res://audio/voice/onboarding/slide_2.ogg",
		"illustration": "aspects"
	},
	{
		"title": "Explore & Grow",
		"text": "More regions will unlock as you progress. Build habits, complete focus sessions, and watch your mindscape transform.\n\nYour human is counting on you, Agent Goacto!",
		"color": Color(0.5, 0.6, 0.8),
		"voice": "res://audio/voice/onboarding/slide_3.ogg",
		"illustration": "grow"
	}
]
var onboarding_illustration_container: Node2D = null


func _show_mindscape_onboarding() -> void:
	is_onboarding_active = true
	onboarding_slide_index = 0
	_create_onboarding_panel()
	_update_onboarding_slide()


func _create_onboarding_panel() -> void:
	onboarding_panel = PanelContainer.new()
	onboarding_panel.name = "OnboardingPanel"

	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.14, 0.98)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_color = Color(0.83, 0.66, 0.29, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	onboarding_panel.add_theme_stylebox_override("panel", style)

	# Layout - larger to accommodate illustrations
	onboarding_panel.set_anchors_preset(Control.PRESET_CENTER)
	onboarding_panel.custom_minimum_size = Vector2(520, 480)
	onboarding_panel.position = Vector2(-260, -240)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	onboarding_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# Illustration area
	var illustration_center = CenterContainer.new()
	illustration_center.name = "IllustrationCenter"
	illustration_center.custom_minimum_size = Vector2(420, 120)
	vbox.add_child(illustration_center)

	var illustration_control = Control.new()
	illustration_control.name = "IllustrationControl"
	illustration_control.custom_minimum_size = Vector2(420, 120)
	illustration_center.add_child(illustration_control)

	onboarding_illustration_container = Node2D.new()
	onboarding_illustration_container.name = "IllustrationContainer"
	onboarding_illustration_container.position = Vector2(210, 60)  # Center of control
	illustration_control.add_child(onboarding_illustration_container)

	# Title
	var title = Label.new()
	title.name = "SlideTitle"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Text
	onboarding_text_label = Label.new()
	onboarding_text_label.name = "SlideText"
	onboarding_text_label.add_theme_font_size_override("font_size", 18)
	onboarding_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	onboarding_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(onboarding_text_label)

	# Page indicator
	var page_row = HBoxContainer.new()
	page_row.name = "PageIndicator"
	page_row.alignment = BoxContainer.ALIGNMENT_CENTER
	page_row.add_theme_constant_override("separation", 8)
	for i in range(ONBOARDING_SLIDES.size()):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(10, 10)
		dot.color = Color(0.4, 0.4, 0.5) if i != 0 else Color(0.8, 0.8, 0.9)
		page_row.add_child(dot)
	vbox.add_child(page_row)

	# Autoplay indicator
	var autoplay_label = Label.new()
	autoplay_label.name = "AutoplayIndicator"
	autoplay_label.text = "▶ Auto-advancing when narration finishes"
	autoplay_label.add_theme_font_size_override("font_size", 14)
	autoplay_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.6, 0.8))
	autoplay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(autoplay_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 15)
	vbox.add_child(btn_row)

	# Back button (hidden on first slide)
	onboarding_back_btn = Button.new()
	onboarding_back_btn.name = "BackButton"
	onboarding_back_btn.text = "Back"
	onboarding_back_btn.custom_minimum_size = Vector2(100, 50)
	onboarding_back_btn.add_theme_font_size_override("font_size", 18)
	onboarding_back_btn.pressed.connect(_prev_onboarding_slide)
	onboarding_back_btn.visible = false
	btn_row.add_child(onboarding_back_btn)

	var skip_btn = Button.new()
	skip_btn.text = "Skip"
	skip_btn.custom_minimum_size = Vector2(100, 50)
	skip_btn.add_theme_font_size_override("font_size", 18)
	skip_btn.pressed.connect(_finish_onboarding)
	btn_row.add_child(skip_btn)

	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer2)

	onboarding_next_btn = Button.new()
	onboarding_next_btn.name = "NextButton"
	onboarding_next_btn.text = "Next"
	onboarding_next_btn.custom_minimum_size = Vector2(150, 50)
	onboarding_next_btn.add_theme_font_size_override("font_size", 20)
	onboarding_next_btn.pressed.connect(_next_onboarding_slide)
	btn_row.add_child(onboarding_next_btn)

	add_child(onboarding_panel)


func _update_onboarding_slide() -> void:
	if not onboarding_panel:
		return

	# Stop any playing voice first
	_stop_onboarding_voice()
	onboarding_voice_finished = false

	var slide = ONBOARDING_SLIDES[onboarding_slide_index]

	# Find the VBox - it's inside MarginContainer
	var vbox: VBoxContainer = null
	for child in onboarding_panel.get_children():
		if child is MarginContainer:
			for inner in child.get_children():
				if inner is VBoxContainer:
					vbox = inner
					break
			break

	if not vbox:
		push_error("[MindscapeHub] Could not find VBox in onboarding panel")
		return

	var title = vbox.get_node_or_null("SlideTitle")
	var page_indicator = vbox.get_node_or_null("PageIndicator")

	# Update illustration
	_create_onboarding_illustration(slide.get("illustration", ""), slide.color)

	if title:
		title.text = slide.title
		title.add_theme_color_override("font_color", slide.color)

	# Store full text and start typing effect
	onboarding_full_text = slide.text
	_start_typing_effect(slide.text)

	# Update page dots
	if page_indicator:
		for i in range(page_indicator.get_child_count()):
			var dot = page_indicator.get_child(i)
			dot.color = Color(0.8, 0.8, 0.9) if i == onboarding_slide_index else Color(0.4, 0.4, 0.5)

	# Show/hide back button
	if onboarding_back_btn:
		onboarding_back_btn.visible = onboarding_slide_index > 0

	# Update button text on last slide
	if onboarding_next_btn:
		onboarding_next_btn.text = "Let's Go!" if onboarding_slide_index == ONBOARDING_SLIDES.size() - 1 else "Next"

	# Play voice narration
	_play_onboarding_voice(slide)


func _start_typing_effect(full_text: String) -> void:
	if not onboarding_text_label:
		return

	# Kill any existing tween
	if onboarding_typing_tween and onboarding_typing_tween.is_valid():
		onboarding_typing_tween.kill()

	onboarding_text_label.text = ""
	onboarding_text_label.visible_ratio = 0.0

	# Set full text but hide it
	onboarding_text_label.text = full_text

	# Animate visible_ratio from 0 to 1
	var duration = full_text.length() * 0.03  # ~30ms per character
	duration = clamp(duration, 1.0, 8.0)  # Min 1s, max 8s

	onboarding_typing_tween = create_tween()
	onboarding_typing_tween.tween_property(onboarding_text_label, "visible_ratio", 1.0, duration)


func _play_onboarding_voice(slide: Dictionary) -> void:
	var voice_path = slide.get("voice", "")
	if voice_path == "" or not ResourceLoader.exists(voice_path):
		return

	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_voice"):
		var stream = load(voice_path)
		if stream:
			audio.play_voice(stream)
			# Connect to voice finished for auto-advance
			if audio.has_signal("voice_finished") and not audio.voice_finished.is_connected(_on_onboarding_voice_finished):
				audio.voice_finished.connect(_on_onboarding_voice_finished)


func _stop_onboarding_voice() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()


func _on_onboarding_voice_finished() -> void:
	onboarding_voice_finished = true
	# Auto-advance after a short delay
	if is_onboarding_active:
		await get_tree().create_timer(0.8).timeout
		if is_onboarding_active and onboarding_voice_finished:
			_next_onboarding_slide()


func _prev_onboarding_slide() -> void:
	if onboarding_slide_index > 0:
		onboarding_slide_index -= 1
		_update_onboarding_slide()


func _next_onboarding_slide() -> void:
	onboarding_slide_index += 1
	if onboarding_slide_index >= ONBOARDING_SLIDES.size():
		_finish_onboarding()
	else:
		_update_onboarding_slide()


func _finish_onboarding() -> void:
	_stop_onboarding_voice()
	is_onboarding_active = false
	GameManager.complete_onboarding()

	# Smooth fade out
	if onboarding_panel:
		var tween = create_tween()
		tween.tween_property(onboarding_panel, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func():
			if onboarding_panel:
				onboarding_panel.queue_free()
				onboarding_panel = null
				onboarding_illustration_container = null

			# Show tutorial tooltips after onboarding completes
			_check_tutorial_tooltips()
		)


func _create_onboarding_illustration(illustration_type: String, color: Color) -> void:
	if not onboarding_illustration_container:
		return

	# Clear existing illustration
	for child in onboarding_illustration_container.get_children():
		child.queue_free()

	match illustration_type:
		"mindscape":
			_create_mindscape_illustration(color)
		"focus":
			_create_focus_illustration(color)
		"aspects":
			_create_aspects_illustration(color)
		"grow":
			_create_grow_illustration(color)


func _create_mindscape_illustration(color: Color) -> void:
	# Floating platform with glowing center crystal
	var parent = onboarding_illustration_container

	# Platform base
	var platform = Polygon2D.new()
	platform.polygon = PackedVector2Array([
		Vector2(-120, 20), Vector2(0, -15), Vector2(120, 20), Vector2(0, 45)
	])
	platform.color = Color(0.15, 0.12, 0.2)
	parent.add_child(platform)

	# Platform glow ring
	var ring = Polygon2D.new()
	ring.polygon = PackedVector2Array([
		Vector2(-80, 12), Vector2(0, -8), Vector2(80, 12), Vector2(0, 28)
	])
	ring.color = color.darkened(0.3)
	ring.modulate.a = 0.6
	parent.add_child(ring)

	# Center crystal
	var crystal = Polygon2D.new()
	crystal.polygon = PackedVector2Array([
		Vector2(0, -50), Vector2(12, -20), Vector2(8, 5),
		Vector2(-8, 5), Vector2(-12, -20)
	])
	crystal.color = color
	parent.add_child(crystal)

	# Crystal glow
	var glow = Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(0, -55), Vector2(18, -20), Vector2(12, 10),
		Vector2(-12, 10), Vector2(-18, -20)
	])
	glow.color = color
	glow.modulate.a = 0.3
	glow.z_index = -1
	parent.add_child(glow)

	# Small floating orbs
	for i in range(4):
		var orb = Polygon2D.new()
		var angle = i * TAU / 4 + 0.3
		var dist = 70
		orb.position = Vector2(cos(angle) * dist, sin(angle) * dist * 0.4 - 10)
		var orb_points = PackedVector2Array()
		for j in range(6):
			var a = j * TAU / 6
			orb_points.append(Vector2(cos(a) * 6, sin(a) * 6))
		orb.polygon = orb_points
		orb.color = color.lightened(0.2)
		orb.modulate.a = 0.7
		parent.add_child(orb)


func _create_focus_illustration(color: Color) -> void:
	# Timer ring with clock hands
	var parent = onboarding_illustration_container

	# Outer ring
	var ring_points = PackedVector2Array()
	for i in range(24):
		var angle = i * TAU / 24
		var r = 45
		ring_points.append(Vector2(cos(angle) * r, sin(angle) * r))
	var outer_ring = Polygon2D.new()
	outer_ring.polygon = ring_points
	outer_ring.color = color.darkened(0.2)
	parent.add_child(outer_ring)

	# Inner circle
	var inner_points = PackedVector2Array()
	for i in range(20):
		var angle = i * TAU / 20
		var r = 35
		inner_points.append(Vector2(cos(angle) * r, sin(angle) * r))
	var inner = Polygon2D.new()
	inner.polygon = inner_points
	inner.color = Color(0.1, 0.12, 0.15)
	parent.add_child(inner)

	# Clock marks
	for i in range(12):
		var angle = i * TAU / 12 - TAU / 4
		var mark = Polygon2D.new()
		var r1 = 38
		var r2 = 32
		var w = 2
		mark.polygon = PackedVector2Array([
			Vector2(cos(angle) * r1 - sin(angle) * w, sin(angle) * r1 + cos(angle) * w),
			Vector2(cos(angle) * r1 + sin(angle) * w, sin(angle) * r1 - cos(angle) * w),
			Vector2(cos(angle) * r2 + sin(angle) * w, sin(angle) * r2 - cos(angle) * w),
			Vector2(cos(angle) * r2 - sin(angle) * w, sin(angle) * r2 + cos(angle) * w)
		])
		mark.color = color if i % 3 == 0 else color.darkened(0.3)
		parent.add_child(mark)

	# Hour hand (pointing to ~10 o'clock for 25 min visual)
	var hour_hand = Polygon2D.new()
	hour_hand.polygon = PackedVector2Array([
		Vector2(-2, 5), Vector2(-2, -18), Vector2(2, -18), Vector2(2, 5)
	])
	hour_hand.color = color.lightened(0.1)
	hour_hand.rotation = -TAU / 4 - 0.4
	parent.add_child(hour_hand)

	# Minute hand
	var min_hand = Polygon2D.new()
	min_hand.polygon = PackedVector2Array([
		Vector2(-1.5, 5), Vector2(-1.5, -28), Vector2(1.5, -28), Vector2(1.5, 5)
	])
	min_hand.color = color
	min_hand.rotation = TAU / 4  # Pointing down (25 min)
	parent.add_child(min_hand)

	# Center dot
	var center = Polygon2D.new()
	var center_points = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		center_points.append(Vector2(cos(angle) * 4, sin(angle) * 4))
	center.polygon = center_points
	center.color = color
	parent.add_child(center)

	# "25" text indicator
	var text_bg = Polygon2D.new()
	text_bg.polygon = PackedVector2Array([
		Vector2(55, -15), Vector2(95, -15), Vector2(95, 15), Vector2(55, 15)
	])
	text_bg.color = color.darkened(0.4)
	text_bg.modulate.a = 0.8
	parent.add_child(text_bg)


func _create_aspects_illustration(color: Color) -> void:
	# Six aspect symbols in a hexagonal arrangement
	var parent = onboarding_illustration_container

	var aspect_colors = [
		Color(0.9, 0.7, 0.2),   # Discipline - Gold
		Color(0.9, 0.4, 0.3),   # Courage - Red
		Color(0.5, 0.7, 0.9),   # Creativity - Blue
		Color(0.9, 0.5, 0.7),   # Compassion - Pink
		Color(0.6, 0.5, 0.8),   # Wisdom - Purple
		Color(0.4, 0.8, 0.5)    # Vitality - Green
	]

	var aspect_shapes = ["diamond", "shield", "star", "heart", "eye", "leaf"]

	for i in range(6):
		var angle = i * TAU / 6 - TAU / 4
		var dist = 55
		var pos = Vector2(cos(angle) * dist, sin(angle) * dist * 0.6)

		var aspect = Node2D.new()
		aspect.position = pos
		parent.add_child(aspect)

		# Create shape based on aspect
		var shape = Polygon2D.new()
		match aspect_shapes[i]:
			"diamond":  # Discipline
				shape.polygon = PackedVector2Array([
					Vector2(0, -18), Vector2(12, 0), Vector2(0, 18), Vector2(-12, 0)
				])
			"shield":  # Courage
				shape.polygon = PackedVector2Array([
					Vector2(-12, -15), Vector2(12, -15), Vector2(12, 5),
					Vector2(0, 18), Vector2(-12, 5)
				])
			"star":  # Creativity
				var star_points = PackedVector2Array()
				for j in range(10):
					var a = j * TAU / 10 - TAU / 4
					var r = 16 if j % 2 == 0 else 8
					star_points.append(Vector2(cos(a) * r, sin(a) * r))
				shape.polygon = star_points
			"heart":  # Compassion
				shape.polygon = PackedVector2Array([
					Vector2(0, 16), Vector2(-14, 0), Vector2(-12, -10),
					Vector2(-6, -14), Vector2(0, -8), Vector2(6, -14),
					Vector2(12, -10), Vector2(14, 0)
				])
			"eye":  # Wisdom
				shape.polygon = PackedVector2Array([
					Vector2(-16, 0), Vector2(-8, -10), Vector2(0, -12),
					Vector2(8, -10), Vector2(16, 0), Vector2(8, 10),
					Vector2(0, 12), Vector2(-8, 10)
				])
			"leaf":  # Vitality
				shape.polygon = PackedVector2Array([
					Vector2(0, -18), Vector2(10, -8), Vector2(12, 5),
					Vector2(6, 14), Vector2(0, 18), Vector2(-6, 14),
					Vector2(-12, 5), Vector2(-10, -8)
				])

		shape.color = aspect_colors[i]
		aspect.add_child(shape)

		# Glow
		var glow = shape.duplicate()
		glow.modulate.a = 0.3
		glow.scale = Vector2(1.3, 1.3)
		glow.z_index = -1
		aspect.add_child(glow)

	# Center connection lines
	for i in range(6):
		var angle = i * TAU / 6 - TAU / 4
		var line = Polygon2D.new()
		line.polygon = PackedVector2Array([
			Vector2(-1, 0), Vector2(-1, 30), Vector2(1, 30), Vector2(1, 0)
		])
		line.color = color
		line.modulate.a = 0.3
		line.rotation = angle + TAU / 2
		parent.add_child(line)


func _create_grow_illustration(color: Color) -> void:
	# Growing tree/plant with progression
	var parent = onboarding_illustration_container

	# Ground
	var ground = Polygon2D.new()
	ground.polygon = PackedVector2Array([
		Vector2(-100, 25), Vector2(100, 25), Vector2(80, 40), Vector2(-80, 40)
	])
	ground.color = Color(0.15, 0.18, 0.12)
	parent.add_child(ground)

	# Tree trunk
	var trunk = Polygon2D.new()
	trunk.polygon = PackedVector2Array([
		Vector2(-8, 25), Vector2(-6, -20), Vector2(6, -20), Vector2(8, 25)
	])
	trunk.color = Color(0.4, 0.3, 0.2)
	parent.add_child(trunk)

	# Branches
	var branch_configs = [
		{"angle": -0.5, "length": 25, "y": -10},
		{"angle": 0.4, "length": 30, "y": -5},
		{"angle": -0.3, "length": 20, "y": 5},
		{"angle": 0.6, "length": 22, "y": 10}
	]

	for config in branch_configs:
		var branch = Polygon2D.new()
		var len = config["length"]
		branch.polygon = PackedVector2Array([
			Vector2(0, 2), Vector2(len, 0), Vector2(len, -2), Vector2(0, -2)
		])
		branch.color = Color(0.35, 0.28, 0.18)
		branch.position = Vector2(0, config["y"])
		branch.rotation = config["angle"]
		parent.add_child(branch)

	# Leaves/foliage clusters
	var leaf_positions = [
		Vector2(-35, -25), Vector2(-20, -35), Vector2(0, -45),
		Vector2(25, -30), Vector2(40, -20), Vector2(-15, -15),
		Vector2(15, -10), Vector2(-30, -5), Vector2(35, 0)
	]

	for i in range(leaf_positions.size()):
		var leaf = Polygon2D.new()
		var leaf_points = PackedVector2Array()
		var size = 12 + randf() * 8
		for j in range(6):
			var angle = j * TAU / 6
			var r = size * (0.8 + randf() * 0.4)
			leaf_points.append(Vector2(cos(angle) * r, sin(angle) * r * 0.7))
		leaf.polygon = leaf_points
		leaf.position = leaf_positions[i]
		leaf.color = color.lerp(Color(0.3, 0.6, 0.35), float(i) / leaf_positions.size())
		parent.add_child(leaf)

	# Sparkles showing growth
	for i in range(5):
		var sparkle = Polygon2D.new()
		sparkle.polygon = PackedVector2Array([
			Vector2(0, -5), Vector2(2, -2), Vector2(5, 0), Vector2(2, 2),
			Vector2(0, 5), Vector2(-2, 2), Vector2(-5, 0), Vector2(-2, -2)
		])
		sparkle.position = Vector2(randf_range(-60, 60), randf_range(-50, 10))
		sparkle.color = Color(1, 1, 0.8)
		sparkle.modulate.a = 0.5 + randf() * 0.3
		sparkle.scale = Vector2(0.6, 0.6)
		parent.add_child(sparkle)

	# Arrow showing upward growth
	var arrow = Polygon2D.new()
	arrow.polygon = PackedVector2Array([
		Vector2(0, -55), Vector2(10, -40), Vector2(4, -40),
		Vector2(4, -25), Vector2(-4, -25), Vector2(-4, -40), Vector2(-10, -40)
	])
	arrow.color = color
	arrow.position = Vector2(70, 0)
	arrow.modulate.a = 0.8
	parent.add_child(arrow)


# ============ ACHIEVEMENTS VIEW ============

var achievements_panel: PanelContainer = null

func _show_achievements_view() -> void:
	# Close pause menu first
	_close_pause_menu()

	# Create full-screen achievements panel
	achievements_panel = PanelContainer.new()
	achievements_panel.name = "AchievementsPanel"
	achievements_panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	achievements_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	achievements_panel.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)

	# Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	main_vbox.add_child(header)

	var title = Label.new()
	title.text = "Achievements"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	# Progress summary
	var unlocked_count = AchievementManager.get_unlocked_achievements().size()
	var total_count = AchievementManager.ACHIEVEMENTS.size()
	var percentage = int(AchievementManager.get_unlock_percentage() * 100)

	var progress_label = Label.new()
	progress_label.text = "%d / %d (%d%%)" % [unlocked_count, total_count, percentage]
	progress_label.add_theme_font_size_override("font_size", 24)
	progress_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	header.add_child(progress_label)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(50, 50)
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.pressed.connect(_close_achievements_view)
	header.add_child(close_btn)

	# Scrollable content
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 25)
	scroll.add_child(content)

	# Group achievements by category
	var categories = {
		AchievementManager.AchievementCategory.FOCUS: {"name": "Focus", "icon": "🎯", "achievements": []},
		AchievementManager.AchievementCategory.HABITS: {"name": "Habits", "icon": "✅", "achievements": []},
		AchievementManager.AchievementCategory.STREAKS: {"name": "Streaks", "icon": "🔥", "achievements": []},
		AchievementManager.AchievementCategory.GROWTH: {"name": "Growth", "icon": "🌱", "achievements": []},
		AchievementManager.AchievementCategory.EXPLORATION: {"name": "Exploration", "icon": "⭐", "achievements": []},
		AchievementManager.AchievementCategory.SPECIAL: {"name": "Special", "icon": "✨", "achievements": []}
	}

	# Sort achievements into categories
	var all_achievements = AchievementManager.get_all_achievements()
	for achievement in all_achievements:
		var cat = achievement.get("category", AchievementManager.AchievementCategory.SPECIAL)
		if categories.has(cat):
			categories[cat].achievements.append(achievement)

	# Display each category
	for cat_id in categories:
		var cat_data = categories[cat_id]
		if cat_data.achievements.is_empty():
			continue

		# Category header
		var cat_header = Label.new()
		cat_header.text = cat_data.icon + " " + cat_data.name
		cat_header.add_theme_font_size_override("font_size", 26)
		cat_header.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
		content.add_child(cat_header)

		# Achievement grid
		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 20)
		grid.add_theme_constant_override("v_separation", 15)
		content.add_child(grid)

		for achievement in cat_data.achievements:
			_add_achievement_card(grid, achievement)


func _add_achievement_card(container: Control, achievement: Dictionary) -> void:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(400, 80)

	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	var is_unlocked = achievement.get("unlocked", false)
	if is_unlocked:
		style.bg_color = Color(0.15, 0.18, 0.25, 1)
		style.border_color = Color(0.83, 0.66, 0.29, 0.4)
	else:
		style.bg_color = Color(0.1, 0.1, 0.12, 1)
		style.border_color = Color(0.3, 0.3, 0.35, 0.3)

	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	card.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)

	# Icon
	var icon_label = Label.new()
	icon_label.text = achievement.get("icon", "🏆")
	icon_label.add_theme_font_size_override("font_size", 36)
	if not is_unlocked:
		icon_label.modulate = Color(0.4, 0.4, 0.45)
	hbox.add_child(icon_label)

	# Text content
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var name_label = Label.new()
	name_label.text = achievement.get("name", "Achievement")
	name_label.add_theme_font_size_override("font_size", 20)
	if is_unlocked:
		name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	text_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = achievement.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 16)
	if is_unlocked:
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	else:
		desc_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	text_vbox.add_child(desc_label)

	# XP reward and progress row
	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 15)
	text_vbox.add_child(info_row)

	# XP reward
	var xp_reward = achievement.get("xp_reward", 0)
	if xp_reward > 0:
		var xp_label = Label.new()
		if is_unlocked:
			xp_label.text = "+%d XP earned" % xp_reward
			xp_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		else:
			xp_label.text = "+%d XP" % xp_reward
			xp_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
		xp_label.add_theme_font_size_override("font_size", 14)
		info_row.add_child(xp_label)

	# Progress for locked achievements
	if not is_unlocked and AchievementManager:
		var progress = AchievementManager.get_achievement_progress(achievement.id)
		if progress and progress.target > 0:
			var progress_label = Label.new()
			progress_label.text = "Progress: %d/%d" % [progress.current, progress.target]
			progress_label.add_theme_font_size_override("font_size", 14)
			progress_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
			info_row.add_child(progress_label)

	# Unlock indicator
	if is_unlocked:
		var check = Label.new()
		check.text = "✓"
		check.add_theme_font_size_override("font_size", 28)
		check.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		hbox.add_child(check)
	else:
		var lock = Label.new()
		lock.text = "🔒"
		lock.add_theme_font_size_override("font_size", 24)
		lock.modulate = Color(0.5, 0.5, 0.55)
		hbox.add_child(lock)

	container.add_child(card)


func _close_achievements_view() -> void:
	if achievements_panel:
		achievements_panel.queue_free()
		achievements_panel = null


# ============ ACHIEVEMENT NOTIFICATION ============

var achievement_notification: PanelContainer = null
var achievement_notification_queue: Array = []

func _on_achievement_unlocked(achievement: Dictionary) -> void:
	achievement_notification_queue.append(achievement)
	if not achievement_notification:
		_show_next_achievement_notification()


func _show_next_achievement_notification() -> void:
	if achievement_notification_queue.is_empty():
		return

	var achievement = achievement_notification_queue.pop_front()
	_show_achievement_notification(achievement)


func _show_achievement_notification(achievement: Dictionary) -> void:
	# Play achievement unlock sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_achievement_unlock"):
		audio.play_achievement_unlock()

	achievement_notification = PanelContainer.new()
	achievement_notification.name = "AchievementNotification"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.18, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = Color(0.83, 0.66, 0.29, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	achievement_notification.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	achievement_notification.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)

	# Icon
	var icon_label = Label.new()
	icon_label.text = achievement.get("icon", "🏆")
	icon_label.add_theme_font_size_override("font_size", 40)
	hbox.add_child(icon_label)

	# Text content
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	var header = Label.new()
	header.text = "Achievement Unlocked!"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	vbox.add_child(header)

	var name_label = Label.new()
	name_label.text = achievement.get("name", "Achievement")
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = achievement.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	vbox.add_child(desc_label)

	# XP Reward display
	var xp_reward = achievement.get("xp_reward", 0)
	if xp_reward > 0:
		var xp_label = Label.new()
		xp_label.text = "+%d XP" % xp_reward
		xp_label.add_theme_font_size_override("font_size", 16)
		xp_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		vbox.add_child(xp_label)

	# Position at top center
	achievement_notification.custom_minimum_size = Vector2(350, 0)
	add_child(achievement_notification)

	# Position after adding to get size
	await get_tree().process_frame
	var screen_width = get_viewport_rect().size.x
	achievement_notification.position = Vector2(
		(screen_width - achievement_notification.size.x) / 2,
		-achievement_notification.size.y - 10
	)

	# Animate slide in
	var tween = create_tween()
	tween.tween_property(achievement_notification, "position:y", 60.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Wait and slide out
	await get_tree().create_timer(3.5).timeout
	if achievement_notification:
		var out_tween = create_tween()
		out_tween.tween_property(achievement_notification, "position:y", -achievement_notification.size.y - 10, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		await out_tween.finished
		if achievement_notification:
			achievement_notification.queue_free()
			achievement_notification = null
			# Show next if queued
			_show_next_achievement_notification()


# ============ KEYBOARD SHORTCUTS GUIDE ============

var shortcuts_panel: PanelContainer = null

func _show_shortcuts_guide() -> void:
	if shortcuts_panel:
		_close_shortcuts_guide()
		return

	shortcuts_panel = PanelContainer.new()
	shortcuts_panel.name = "ShortcutsGuide"
	shortcuts_panel.set_anchors_preset(Control.PRESET_CENTER)
	shortcuts_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	shortcuts_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.98)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_color = Color(0.4, 0.45, 0.55, 0.5)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	shortcuts_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	shortcuts_panel.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)

	# Header
	var header = HBoxContainer.new()
	main_vbox.add_child(header)

	var title = Label.new()
	title.text = "Keyboard Shortcuts"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(45, 45)
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.pressed.connect(_close_shortcuts_guide)
	header.add_child(close_btn)

	# Shortcuts grid in two columns
	var content = HBoxContainer.new()
	content.add_theme_constant_override("separation", 60)
	main_vbox.add_child(content)

	# Left column - Navigation
	var left_col = VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 12)
	content.add_child(left_col)

	var nav_header = Label.new()
	nav_header.text = "Navigation"
	nav_header.add_theme_font_size_override("font_size", 22)
	nav_header.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	left_col.add_child(nav_header)

	_add_shortcut_row(left_col, "W / ↑", "Move up")
	_add_shortcut_row(left_col, "S / ↓", "Move down")
	_add_shortcut_row(left_col, "A / ←", "Move left")
	_add_shortcut_row(left_col, "D / →", "Move right")
	_add_shortcut_row(left_col, "Scroll", "Zoom in/out")

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 15)
	left_col.add_child(spacer1)

	var interact_header = Label.new()
	interact_header.text = "Interaction"
	interact_header.add_theme_font_size_override("font_size", 22)
	interact_header.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	left_col.add_child(interact_header)

	_add_shortcut_row(left_col, "Space", "Interact / Enter zone")
	_add_shortcut_row(left_col, "Enter", "Confirm / Continue")
	_add_shortcut_row(left_col, "Escape", "Back / Open menu")

	# Right column - Menus & Views
	var right_col = VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 12)
	content.add_child(right_col)

	var menu_header = Label.new()
	menu_header.text = "Menus & Views"
	menu_header.add_theme_font_size_override("font_size", 22)
	menu_header.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	right_col.add_child(menu_header)

	_add_shortcut_row(right_col, "?", "Show this guide")
	_add_shortcut_row(right_col, "P", "Pause menu")

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	right_col.add_child(spacer2)

	var quick_header = Label.new()
	quick_header.text = "Quick Actions"
	quick_header.add_theme_font_size_override("font_size", 22)
	quick_header.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	right_col.add_child(quick_header)

	_add_shortcut_row(right_col, "H", "Habits / Daily Rituals")
	_add_shortcut_row(right_col, "F", "Focus Chamber")
	_add_shortcut_row(right_col, "J", "Journal / Reflections")
	_add_shortcut_row(right_col, "E", "Daily Summary")
	_add_shortcut_row(right_col, "M", "Return to Hub (from regions)")

	# Spacer
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 15)
	right_col.add_child(spacer3)

	var tips_header = Label.new()
	tips_header.text = "Tips"
	tips_header.add_theme_font_size_override("font_size", 22)
	tips_header.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	right_col.add_child(tips_header)

	var tip1 = Label.new()
	tip1.text = "• Walk near zones to see interaction prompts"
	tip1.add_theme_font_size_override("font_size", 16)
	tip1.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	right_col.add_child(tip1)

	var tip2 = Label.new()
	tip2.text = "• Locked zones show unlock requirements"
	tip2.add_theme_font_size_override("font_size", 16)
	tip2.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	right_col.add_child(tip2)

	var tip3 = Label.new()
	tip3.text = "• Complete habits daily to build streaks"
	tip3.add_theme_font_size_override("font_size", 16)
	tip3.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	right_col.add_child(tip3)

	var tip4 = Label.new()
	tip4.text = "• Use portals to explore other regions"
	tip4.add_theme_font_size_override("font_size", 16)
	tip4.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	right_col.add_child(tip4)

	# Footer
	var footer = Label.new()
	footer.text = "Press ? or Escape to close"
	footer.add_theme_font_size_override("font_size", 16)
	footer.add_theme_color_override("font_color", Color(0.4, 0.45, 0.5))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)

	add_child(shortcuts_panel)

	# Position in center
	await get_tree().process_frame
	shortcuts_panel.position = (get_viewport_rect().size - shortcuts_panel.size) / 2


func _add_shortcut_row(parent: Control, key: String, description: String) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)
	parent.add_child(row)

	var key_label = Label.new()
	key_label.text = key
	key_label.custom_minimum_size = Vector2(100, 0)
	key_label.add_theme_font_size_override("font_size", 18)
	key_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	row.add_child(key_label)

	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	row.add_child(desc_label)


func _close_shortcuts_guide() -> void:
	if shortcuts_panel:
		shortcuts_panel.queue_free()
		shortcuts_panel = null


# =============================================================================
# DAILY SUMMARY PANEL
# =============================================================================

func _toggle_daily_summary() -> void:
	if daily_summary_panel:
		_close_daily_summary()
	else:
		_show_daily_summary()


func _show_daily_summary() -> void:
	if daily_summary_panel:
		return

	daily_summary_panel = PanelContainer.new()
	daily_summary_panel.name = "DailySummary"
	daily_summary_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	daily_summary_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	daily_summary_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	daily_summary_panel.offset_left = -380
	daily_summary_panel.offset_right = -20
	daily_summary_panel.offset_top = -250
	daily_summary_panel.offset_bottom = 250

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_color = Color(0.3, 0.4, 0.5, 0.5)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	daily_summary_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	daily_summary_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var title = Label.new()
	title.text = "Daily Summary"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(_close_daily_summary)
	header.add_child(close_btn)

	# Date
	var date_label = Label.new()
	date_label.text = Time.get_date_string_from_system()
	date_label.add_theme_font_size_override("font_size", 14)
	date_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	vbox.add_child(date_label)

	# Separator
	var sep1 = HSeparator.new()
	sep1.add_theme_constant_override("separation", 5)
	vbox.add_child(sep1)

	# Scroll container for content
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	# Habits section
	_add_summary_section(content, "Habits Today", _get_habits_summary())

	# Focus section
	_add_summary_section(content, "Focus Time", _get_focus_summary())

	# Streaks section
	_add_summary_section(content, "Active Streaks", _get_streaks_summary())

	# Weekly progress
	_add_summary_section(content, "This Week", _get_weekly_summary())

	add_child(daily_summary_panel)

	# Slide in animation
	daily_summary_panel.modulate.a = 0
	daily_summary_panel.position.x += 50
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(daily_summary_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(daily_summary_panel, "position:x", daily_summary_panel.position.x - 50, 0.2)


func _add_summary_section(parent: Control, title: String, items: Array) -> void:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 6)
	parent.add_child(section)

	var header = Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	section.add_child(header)

	for item in items:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		section.add_child(row)

		var icon = Label.new()
		icon.text = item.get("icon", "•")
		icon.add_theme_font_size_override("font_size", 14)
		icon.add_theme_color_override("font_color", item.get("color", Color(0.6, 0.6, 0.65)))
		row.add_child(icon)

		var text = Label.new()
		text.text = item.get("text", "")
		text.add_theme_font_size_override("font_size", 14)
		text.add_theme_color_override("font_color", item.get("color", Color(0.6, 0.6, 0.65)))
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)

		if item.has("value"):
			var value = Label.new()
			value.text = item.get("value", "")
			value.add_theme_font_size_override("font_size", 14)
			value.add_theme_color_override("font_color", item.get("value_color", Color(0.8, 0.8, 0.85)))
			row.add_child(value)


func _get_habits_summary() -> Array:
	var items = []
	var habits = HabitManager.get_all_habits()
	var completed = 0
	var total = 0

	for habit in habits:
		if _is_habit_due_today(habit):
			total += 1
			var is_done = HabitManager.is_completed_today(habit.id)
			if is_done:
				completed += 1
			items.append({
				"icon": "✓" if is_done else "○",
				"text": habit.name,
				"color": Color(0.4, 0.85, 0.5) if is_done else Color(0.5, 0.5, 0.55)
			})

	if items.is_empty():
		items.append({"icon": "—", "text": "No habits due today", "color": Color(0.5, 0.5, 0.55)})
	else:
		# Add summary at top
		items.insert(0, {
			"icon": "📊",
			"text": "Progress",
			"value": "%d/%d complete" % [completed, total],
			"value_color": Color(0.4, 0.85, 0.5) if completed == total else Color(0.8, 0.75, 0.5),
			"color": Color(0.6, 0.65, 0.7)
		})

	return items


func _get_focus_summary() -> Array:
	var items = []
	var today_minutes = _get_today_focus_minutes()
	var today_sessions = _get_today_session_count()

	items.append({
		"icon": "⏱",
		"text": "Time focused",
		"value": _format_minutes(today_minutes),
		"value_color": Color(0.6, 0.75, 0.9),
		"color": Color(0.6, 0.65, 0.7)
	})

	items.append({
		"icon": "🎯",
		"text": "Sessions",
		"value": str(today_sessions),
		"value_color": Color(0.6, 0.75, 0.9),
		"color": Color(0.6, 0.65, 0.7)
	})

	return items


func _get_streaks_summary() -> Array:
	var items = []
	var habits = HabitManager.get_all_habits()

	for habit in habits:
		var streak = habit.get("streak", 0)
		if streak > 0:
			var color = Color(0.9, 0.6, 0.3)  # Orange for active
			if streak >= 30:
				color = Color(0.9, 0.4, 0.4)  # Red for hot
			elif streak >= 7:
				color = Color(0.9, 0.7, 0.3)  # Yellow-orange for warm
			items.append({
				"icon": "🔥",
				"text": habit.name,
				"value": "%d days" % streak,
				"value_color": color,
				"color": Color(0.6, 0.65, 0.7)
			})

	if items.is_empty():
		items.append({"icon": "—", "text": "No active streaks", "color": Color(0.5, 0.5, 0.55)})

	return items


func _get_weekly_summary() -> Array:
	var items = []

	# Calculate week stats
	var week_focus = 0
	var week_habits = 0
	var journal = _load_journal()
	var today = Time.get_date_dict_from_system()
	var today_weekday = today.weekday

	# Get dates for this week (Monday to today)
	var week_dates = []
	for i in range(today_weekday + 1):
		var unix = Time.get_unix_time_from_system() - (today_weekday - i) * 86400
		var date_dict = Time.get_date_dict_from_unix_time(unix)
		week_dates.append("%04d-%02d-%02d" % [date_dict.year, date_dict.month, date_dict.day])

	for entry in journal:
		if entry.get("date", "") in week_dates:
			if entry.get("type", "") == "focus":
				week_focus += entry.get("duration_minutes", 0)
		if entry.get("type", "") == "habit":
			var habit_date = entry.get("date", "")
			if habit_date in week_dates:
				week_habits += 1

	items.append({
		"icon": "📅",
		"text": "Focus time",
		"value": _format_minutes(week_focus),
		"value_color": Color(0.6, 0.75, 0.9),
		"color": Color(0.6, 0.65, 0.7)
	})

	items.append({
		"icon": "✓",
		"text": "Habits completed",
		"value": str(week_habits),
		"value_color": Color(0.4, 0.8, 0.5),
		"color": Color(0.6, 0.65, 0.7)
	})

	return items


func _get_today_session_count() -> int:
	var journal = _load_journal()
	var today = Time.get_date_string_from_system()
	var count = 0
	for entry in journal:
		if entry.get("date", "") == today and entry.get("type", "") == "focus":
			count += 1
	return count


func _format_minutes(minutes: int) -> String:
	if minutes < 60:
		return str(minutes) + " min"
	var hours = minutes / 60
	var mins = minutes % 60
	if mins == 0:
		return str(hours) + "h"
	return str(hours) + "h " + str(mins) + "m"


func _close_daily_summary() -> void:
	if daily_summary_panel:
		daily_summary_panel.queue_free()
		daily_summary_panel = null


# =============================================================================
# JOURNAL SYSTEM
# =============================================================================

func _save_journal_entry(entry: Dictionary) -> void:
	var journal = _load_journal()
	journal.append(entry)

	var json_string = JSON.stringify(journal, "\t")
	var journal_path = SaveManager.get_journal_path()
	var file = FileAccess.open(journal_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()


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


func _open_journal_viewer() -> void:
	zone_panel.visible = true
	interaction_prompt.visible = false
	in_zone_panel = true
	zone_title.text = "Reflection Pool"
	_clear_zone_body()
	_create_journal_graphic()

	# Tab buttons row
	var tab_row = HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 8)
	zone_body.add_child(tab_row)

	var focus_tab = Button.new()
	focus_tab.text = "Focus Sessions"
	focus_tab.custom_minimum_size = Vector2(130, 40)
	focus_tab.add_theme_font_size_override("font_size", 16)
	focus_tab.pressed.connect(_show_journal_tab.bind("focus"))
	if current_journal_tab == "focus":
		focus_tab.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	tab_row.add_child(focus_tab)

	var habits_tab = Button.new()
	habits_tab.text = "Habit Log"
	habits_tab.custom_minimum_size = Vector2(110, 40)
	habits_tab.add_theme_font_size_override("font_size", 16)
	habits_tab.pressed.connect(_show_journal_tab.bind("habits"))
	if current_journal_tab == "habits":
		habits_tab.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	tab_row.add_child(habits_tab)

	var reflections_tab = Button.new()
	reflections_tab.text = "All Entries"
	reflections_tab.custom_minimum_size = Vector2(100, 40)
	reflections_tab.add_theme_font_size_override("font_size", 16)
	reflections_tab.pressed.connect(_show_journal_tab.bind("all"))
	if current_journal_tab == "all":
		reflections_tab.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	tab_row.add_child(reflections_tab)

	var checkin_tab = Button.new()
	checkin_tab.text = "Check-In"
	checkin_tab.custom_minimum_size = Vector2(90, 40)
	checkin_tab.add_theme_font_size_override("font_size", 16)
	checkin_tab.pressed.connect(_show_journal_tab.bind("checkin"))
	if current_journal_tab == "checkin":
		checkin_tab.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	tab_row.add_child(checkin_tab)

	var weekly_tab = Button.new()
	weekly_tab.text = "Weekly"
	weekly_tab.custom_minimum_size = Vector2(80, 40)
	weekly_tab.add_theme_font_size_override("font_size", 16)
	weekly_tab.pressed.connect(_show_journal_tab.bind("weekly"))
	if current_journal_tab == "weekly":
		weekly_tab.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	tab_row.add_child(weekly_tab)

	var affirm_tab = Button.new()
	affirm_tab.text = "Affirm"
	affirm_tab.custom_minimum_size = Vector2(70, 40)
	affirm_tab.add_theme_font_size_override("font_size", 16)
	affirm_tab.pressed.connect(_show_journal_tab.bind("affirm"))
	if current_journal_tab == "affirm":
		affirm_tab.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	tab_row.add_child(affirm_tab)

	_add_habit_spacer(12)

	# Build the current tab content
	match current_journal_tab:
		"focus":
			_build_focus_journal_tab()
		"habits":
			_build_habits_journal_tab()
		"all":
			_build_all_journal_tab()
		"checkin":
			_build_checkin_tab()
		"weekly":
			_build_weekly_synthesis_tab()
		"affirm":
			_build_affirmations_tab()

	_add_habit_spacer(15)

	var back_btn = Button.new()
	back_btn.text = "Close"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_close_zone)
	zone_body.add_child(back_btn)


func _show_journal_tab(tab: String) -> void:
	current_journal_tab = tab
	_open_journal_viewer()


func _create_journal_graphic() -> void:
	# Clear existing graphics
	for child in zone_graphic_container.get_children():
		child.queue_free()

	var graphic = Control.new()
	graphic.set_anchors_preset(Control.PRESET_FULL_RECT)
	zone_graphic_container.add_child(graphic)

	var canvas = Node2D.new()
	canvas.position = Vector2(140, 280)
	graphic.add_child(canvas)

	# Water pool background (dark blue)
	var pool_bg = Polygon2D.new()
	pool_bg.polygon = PackedVector2Array([
		Vector2(-100, 0), Vector2(0, -60), Vector2(100, 0), Vector2(0, 60)
	])
	pool_bg.color = Color(0.1, 0.15, 0.25, 0.9)
	canvas.add_child(pool_bg)

	# Water surface (lighter blue with transparency)
	var water = Polygon2D.new()
	water.polygon = PackedVector2Array([
		Vector2(-80, 0), Vector2(0, -45), Vector2(80, 0), Vector2(0, 45)
	])
	water.color = Color(0.25, 0.4, 0.6, 0.7)
	canvas.add_child(water)

	# Inner reflection (golden shimmer)
	var shimmer = Polygon2D.new()
	shimmer.polygon = PackedVector2Array([
		Vector2(-40, 0), Vector2(0, -22), Vector2(40, 0), Vector2(0, 22)
	])
	shimmer.color = Color(0.83, 0.66, 0.29, 0.3)
	canvas.add_child(shimmer)

	# Ripple rings
	for i in range(3):
		var ring = Polygon2D.new()
		var size = 30 + i * 25
		ring.polygon = _create_ring_polygon(size, 2)
		ring.color = Color(0.5, 0.6, 0.8, 0.15 - i * 0.04)
		canvas.add_child(ring)

	# Decorative stones around pool
	var stone_positions = [
		Vector2(-110, -20), Vector2(-95, 35), Vector2(95, -25), Vector2(105, 30)
	]
	for pos in stone_positions:
		var stone = Polygon2D.new()
		stone.polygon = PackedVector2Array([
			Vector2(-8, -5), Vector2(0, -10), Vector2(10, -3), Vector2(8, 5), Vector2(-5, 8)
		])
		stone.position = pos
		stone.color = Color(0.3, 0.28, 0.35, 0.8)
		canvas.add_child(stone)

	# Journal book floating above
	var book = Node2D.new()
	book.position = Vector2(0, -100)
	canvas.add_child(book)

	var book_cover = Polygon2D.new()
	book_cover.polygon = PackedVector2Array([
		Vector2(-25, -18), Vector2(25, -18), Vector2(25, 18), Vector2(-25, 18)
	])
	book_cover.color = Color(0.45, 0.35, 0.25, 0.9)
	book.add_child(book_cover)

	var book_spine = Polygon2D.new()
	book_spine.polygon = PackedVector2Array([
		Vector2(-25, -18), Vector2(-22, -18), Vector2(-22, 18), Vector2(-25, 18)
	])
	book_spine.color = Color(0.6, 0.5, 0.35, 0.9)
	book.add_child(book_spine)

	var book_pages = Polygon2D.new()
	book_pages.polygon = PackedVector2Array([
		Vector2(-20, -15), Vector2(22, -15), Vector2(22, 15), Vector2(-20, 15)
	])
	book_pages.color = Color(0.9, 0.88, 0.82, 0.9)
	book.add_child(book_pages)

	# Label
	var label = Label.new()
	label.text = "Reflection Pool"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-60, 120)
	label.custom_minimum_size = Vector2(120, 0)
	canvas.add_child(label)


func _create_ring_polygon(radius: float, thickness: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	var segments = 16
	# Outer edge (diamond shape for isometric look)
	points.append(Vector2(-radius, 0))
	points.append(Vector2(0, -radius * 0.6))
	points.append(Vector2(radius, 0))
	points.append(Vector2(0, radius * 0.6))
	return points


func _create_focus_chamber_graphic() -> void:
	# Clear existing graphics
	for child in zone_graphic_container.get_children():
		child.queue_free()

	var graphic = Control.new()
	graphic.set_anchors_preset(Control.PRESET_FULL_RECT)
	zone_graphic_container.add_child(graphic)

	var canvas = Node2D.new()
	canvas.position = Vector2(140, 280)
	graphic.add_child(canvas)

	# Crystal platform
	var platform = Polygon2D.new()
	platform.polygon = PackedVector2Array([
		Vector2(-70, 20), Vector2(0, -20), Vector2(70, 20), Vector2(0, 60)
	])
	platform.color = Color(0.15, 0.12, 0.2, 0.8)
	canvas.add_child(platform)

	# Main crystal
	var crystal = Polygon2D.new()
	crystal.polygon = PackedVector2Array([
		Vector2(-20, 0), Vector2(0, -80), Vector2(20, 0), Vector2(0, 20)
	])
	crystal.color = Color(0.4, 0.5, 0.8, 0.9)
	canvas.add_child(crystal)

	# Crystal glow
	var glow = Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-35, 10), Vector2(0, -100), Vector2(35, 10), Vector2(0, 40)
	])
	glow.color = Color(0.5, 0.6, 0.9, 0.2)
	canvas.add_child(glow)

	# Energy rings
	for i in range(3):
		var ring = Polygon2D.new()
		var y_offset = -30 - i * 20
		ring.polygon = PackedVector2Array([
			Vector2(-25 + i * 5, y_offset), Vector2(0, y_offset - 8),
			Vector2(25 - i * 5, y_offset), Vector2(0, y_offset + 8)
		])
		ring.color = Color(0.6, 0.7, 1.0, 0.3 - i * 0.08)
		canvas.add_child(ring)

	# Label
	var label = Label.new()
	label.text = "Focus Chamber"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.8))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-60, 100)
	label.custom_minimum_size = Vector2(120, 0)
	canvas.add_child(label)


func _create_daily_rituals_graphic() -> void:
	# Clear existing graphics
	for child in zone_graphic_container.get_children():
		child.queue_free()

	var graphic = Control.new()
	graphic.set_anchors_preset(Control.PRESET_FULL_RECT)
	zone_graphic_container.add_child(graphic)

	var canvas = Node2D.new()
	canvas.position = Vector2(140, 280)
	graphic.add_child(canvas)

	# Altar base
	var altar = Polygon2D.new()
	altar.polygon = PackedVector2Array([
		Vector2(-60, 10), Vector2(0, -20), Vector2(60, 10), Vector2(0, 40)
	])
	altar.color = Color(0.2, 0.18, 0.15, 0.9)
	canvas.add_child(altar)

	# Candle holders
	var candle_positions = [Vector2(-35, -10), Vector2(0, -25), Vector2(35, -10)]
	for pos in candle_positions:
		# Candle
		var candle = Polygon2D.new()
		candle.polygon = PackedVector2Array([
			Vector2(-5, 0), Vector2(-4, -25), Vector2(4, -25), Vector2(5, 0)
		])
		candle.position = pos
		candle.color = Color(0.9, 0.85, 0.7, 0.9)
		canvas.add_child(candle)

		# Flame
		var flame = Polygon2D.new()
		flame.polygon = PackedVector2Array([
			Vector2(-4, 0), Vector2(0, -15), Vector2(4, 0)
		])
		flame.position = pos + Vector2(0, -25)
		flame.color = Color(1.0, 0.7, 0.3, 0.9)
		canvas.add_child(flame)

		# Flame glow
		var flame_glow = Polygon2D.new()
		flame_glow.polygon = PackedVector2Array([
			Vector2(-10, 5), Vector2(0, -25), Vector2(10, 5)
		])
		flame_glow.position = pos + Vector2(0, -25)
		flame_glow.color = Color(1.0, 0.6, 0.2, 0.15)
		canvas.add_child(flame_glow)

	# Decorative scroll/book
	var scroll = Polygon2D.new()
	scroll.polygon = PackedVector2Array([
		Vector2(-20, -5), Vector2(20, -5), Vector2(18, 8), Vector2(-18, 8)
	])
	scroll.position = Vector2(0, 15)
	scroll.color = Color(0.85, 0.8, 0.7, 0.8)
	canvas.add_child(scroll)

	# Label
	var label = Label.new()
	label.text = "Daily Rituals"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-55, 100)
	label.custom_minimum_size = Vector2(110, 0)
	canvas.add_child(label)


func _build_focus_journal_tab() -> void:
	var journal = _load_journal()
	var focus_entries = journal.filter(func(e): return e.get("type", "") != "habit")
	focus_entries.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	var count_label = Label.new()
	count_label.text = "%d focus session reflections" % focus_entries.size()
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	zone_body.add_child(count_label)

	_add_habit_spacer(8)

	if focus_entries.is_empty():
		var empty = Label.new()
		empty.text = "No focus sessions recorded yet.\n\nComplete a focus session and add notes to see entries here."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		zone_body.add_child(empty)
		return

	_build_journal_entries_scroll(focus_entries, 25)


func _build_habits_journal_tab() -> void:
	var journal = _load_journal()
	var habit_entries = journal.filter(func(e): return e.get("type", "") == "habit")
	habit_entries.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	var count_label = Label.new()
	count_label.text = "%d habit completion notes" % habit_entries.size()
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	zone_body.add_child(count_label)

	_add_habit_spacer(8)

	if habit_entries.is_empty():
		var empty = Label.new()
		empty.text = "No habit notes recorded yet.\n\nAdd a note when completing a habit to see entries here."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		zone_body.add_child(empty)
		return

	_build_journal_entries_scroll(habit_entries, 25)


func _build_all_journal_tab() -> void:
	var journal = _load_journal()
	journal.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	var count_label = Label.new()
	count_label.text = "%d total entries" % journal.size()
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	zone_body.add_child(count_label)

	_add_habit_spacer(8)

	if journal.is_empty():
		var empty = Label.new()
		empty.text = "No journal entries yet.\n\nComplete habits or focus sessions to start building your reflection journal!"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		zone_body.add_child(empty)
		return

	_build_journal_entries_scroll(journal, 30)


func _build_journal_entries_scroll(entries: Array, limit: int) -> void:
	var shown = 0
	for entry in entries:
		if shown >= limit:
			break
		_add_journal_entry_card(entry)
		shown += 1

	if entries.size() > limit:
		_add_habit_spacer(8)
		var more_label = Label.new()
		more_label.text = "Showing %d of %d entries" % [limit, entries.size()]
		more_label.add_theme_font_size_override("font_size", 13)
		more_label.add_theme_color_override("font_color", Color(0.45, 0.5, 0.55))
		more_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		zone_body.add_child(more_label)


func _filter_journal(filter_type: String) -> void:
	current_journal_tab = filter_type
	_open_journal_viewer()


func _legacy_filter_journal(filter_type: String) -> void:
	zone_title.text = "Journal"
	_clear_zone_body()

	var journal = _load_journal()
	journal.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	# Filter
	var filtered = journal
	if filter_type == "habit":
		filtered = journal.filter(func(e): return e.get("type", "") == "habit")
	elif filter_type == "focus":
		filtered = journal.filter(func(e): return e.get("type", "") != "habit")

	var type_name = "All" if filter_type == "all" else ("Habit" if filter_type == "habit" else "Focus")
	var header = Label.new()
	header.text = type_name + " Entries (" + str(filtered.size()) + ")"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	zone_body.add_child(header)

	_add_habit_spacer(12)

	if filtered.is_empty():
		var empty = Label.new()
		empty.text = "No " + type_name.to_lower() + " entries yet."
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		zone_body.add_child(empty)
	else:
		var shown = 0
		for entry in filtered:
			if shown >= 30:
				break
			_add_journal_entry_card(entry)
			shown += 1

	_add_habit_spacer(15)

	var back_btn = Button.new()
	back_btn.text = "Back to Journal"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_open_journal_viewer)
	zone_body.add_child(back_btn)


func _add_journal_entry_card(entry: Dictionary) -> void:
	# Use a PanelContainer for card with custom click handling
	var card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var entry_type = entry.get("type", "focus")
	var border_color = Color(0.5, 0.7, 0.5, 0.7) if entry_type == "habit" else Color(0.5, 0.6, 0.8, 0.7)

	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.09, 0.15, 0.95)
	card_style.set_border_width_all(1)
	card_style.border_width_left = 3
	card_style.border_color = border_color
	card_style.set_corner_radius_all(8)
	card_style.set_content_margin_all(0)
	card.add_theme_stylebox_override("panel", card_style)

	# Store entry and style for hover effects
	card.set_meta("entry", entry)
	card.set_meta("normal_style", card_style)

	var hover_style = card_style.duplicate()
	hover_style.bg_color = Color(0.14, 0.12, 0.22, 0.98)
	hover_style.border_color = Color(0.65, 0.6, 0.8, 0.9)
	hover_style.border_width_left = 4
	card.set_meta("hover_style", hover_style)

	# Connect mouse events
	card.gui_input.connect(_on_journal_card_input.bind(entry))
	card.mouse_entered.connect(_on_journal_card_hover.bind(card, true))
	card.mouse_exited.connect(_on_journal_card_hover.bind(card, false))

	var margin = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Header row: type icon + title + date
	var header_row = HBoxContainer.new()
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_theme_constant_override("separation", 10)

	var icon = "✓" if entry_type == "habit" else "🎯"
	var title_text = ""

	if entry_type == "habit":
		title_text = icon + " " + entry.get("habit_name", "Habit")
	else:
		title_text = icon + " " + entry.get("topic", "Focus Session")

	var title = Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = title_text
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.85, 0.88, 0.9))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	var date_str = entry.get("date", "")
	var date_label = Label.new()
	date_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	date_label.text = _format_date(date_str)
	date_label.add_theme_font_size_override("font_size", 13)
	date_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	header_row.add_child(date_label)

	vbox.add_child(header_row)

	# Content based on type
	if entry_type == "habit":
		var streak = entry.get("streak", 0)
		if streak > 0:
			var streak_label = Label.new()
			streak_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			streak_label.text = "🔥 " + str(streak) + " day streak"
			streak_label.add_theme_font_size_override("font_size", 14)
			streak_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
			vbox.add_child(streak_label)

		var note = entry.get("note", "")
		if note == "":
			note = entry.get("text", "")
		if note != "":
			var note_label = Label.new()
			note_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			note_label.text = "📝 " + note
			note_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			note_label.add_theme_font_size_override("font_size", 15)
			note_label.add_theme_color_override("font_color", Color(0.7, 0.72, 0.75))
			vbox.add_child(note_label)
	else:
		# Focus session entry
		var info_row = HBoxContainer.new()
		info_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_row.add_theme_constant_override("separation", 20)

		var duration = entry.get("duration_minutes", 0)
		if duration > 0:
			var dur_label = Label.new()
			dur_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dur_label.text = "⏱ " + str(duration) + " min"
			dur_label.add_theme_font_size_override("font_size", 14)
			dur_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
			info_row.add_child(dur_label)

		# Show completion time if available
		var timestamp = entry.get("timestamp", 0)
		if timestamp > 0:
			var time_label = Label.new()
			time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			time_label.text = "🕐 " + _format_time_from_timestamp(timestamp)
			time_label.add_theme_font_size_override("font_size", 14)
			time_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
			info_row.add_child(time_label)

		if info_row.get_child_count() > 0:
			vbox.add_child(info_row)

		var learned = entry.get("learned", "")
		if learned != "":
			var learned_label = Label.new()
			learned_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			learned_label.text = "💡 " + learned
			learned_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			learned_label.add_theme_font_size_override("font_size", 14)
			learned_label.add_theme_color_override("font_color", Color(0.7, 0.72, 0.75))
			vbox.add_child(learned_label)

		var accomplished = entry.get("accomplished", "")
		if accomplished != "":
			var acc_label = Label.new()
			acc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			acc_label.text = "✓ " + accomplished
			acc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			acc_label.add_theme_font_size_override("font_size", 14)
			acc_label.add_theme_color_override("font_color", Color(0.65, 0.75, 0.65))
			vbox.add_child(acc_label)

		var next_goals = entry.get("next_goals", "")
		if next_goals != "":
			var next_label = Label.new()
			next_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			next_label.text = "→ " + next_goals
			next_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			next_label.add_theme_font_size_override("font_size", 14)
			next_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
			vbox.add_child(next_label)

	# Click hint
	var hint = Label.new()
	hint.text = "tap for details →"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(hint)

	card.tooltip_text = "Click to view full details"
	zone_body.add_child(card)
	_add_habit_spacer(8)


func _on_journal_card_input(event: InputEvent, entry: Dictionary) -> void:
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_show_journal_entry_detail(entry)


func _on_journal_card_hover(card: PanelContainer, hovering: bool) -> void:
	if hovering:
		var hover_style = card.get_meta("hover_style")
		if hover_style:
			card.add_theme_stylebox_override("panel", hover_style)
	else:
		var normal_style = card.get_meta("normal_style")
		if normal_style:
			card.add_theme_stylebox_override("panel", normal_style)


func _format_date(date_str: String) -> String:
	if date_str == "":
		return ""
	# date_str format: YYYY-MM-DD
	var parts = date_str.split("-")
	if parts.size() != 3:
		return date_str
	var months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month_num = int(parts[1])
	if month_num < 1 or month_num > 12:
		return date_str
	return months[month_num] + " " + str(int(parts[2]))


func _format_time_from_timestamp(timestamp: float) -> String:
	if timestamp <= 0:
		return ""

	# Get timezone offset from settings (default 0 for UTC)
	var tz_offset = GameManager.player_data.get("timezone_offset_hours", 0)

	# Convert to datetime dict
	var datetime = Time.get_datetime_dict_from_unix_time(int(timestamp))

	# Apply timezone offset
	var hour = datetime.hour + tz_offset
	if hour < 0:
		hour += 24
	elif hour >= 24:
		hour -= 24

	# Format as 12-hour time
	var period = "AM"
	var display_hour = hour
	if hour >= 12:
		period = "PM"
		if hour > 12:
			display_hour = hour - 12
	if display_hour == 0:
		display_hour = 12

	var minute_str = "%02d" % datetime.minute
	return "%d:%s %s" % [display_hour, minute_str, period]


# =============================================================================
# DAILY CHECK-IN SYSTEM
# =============================================================================

var current_checkin_mood: int = 5
var current_checkin_energy: int = 5

const MOOD_EMOJIS = ["😫", "😔", "😕", "😐", "🙂", "😊", "😄", "😁", "🤩", "🌟"]
const ENERGY_LABELS = ["Exhausted", "Very Low", "Low", "Somewhat Low", "Neutral", "Decent", "Good", "High", "Very High", "Peak"]

func _build_checkin_tab() -> void:
	## Build the daily check-in tab in the Reflection Pool
	var today = Time.get_date_string_from_system()
	var checkins = _load_checkins()
	var today_checkin = checkins.filter(func(c): return c.get("date", "") == today)

	# Header
	var header = Label.new()
	header.text = "Daily Check-In"
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_body.add_child(header)

	_add_habit_spacer(8)

	# Today's status
	if today_checkin.size() > 0:
		var status_label = Label.new()
		var latest = today_checkin[0]
		status_label.text = "Today: " + MOOD_EMOJIS[latest.get("mood", 5) - 1] + " Mood | " + ENERGY_LABELS[latest.get("energy", 5) - 1] + " Energy"
		status_label.add_theme_font_size_override("font_size", 16)
		status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		zone_body.add_child(status_label)

		_add_habit_spacer(8)

		var update_btn = Button.new()
		update_btn.text = "Update Today's Check-In"
		update_btn.custom_minimum_size = Vector2(0, 45)
		update_btn.add_theme_font_size_override("font_size", 16)
		update_btn.pressed.connect(_show_new_checkin.bind(true))
		zone_body.add_child(update_btn)
	else:
		var prompt_label = Label.new()
		prompt_label.text = "How are you feeling today?"
		prompt_label.add_theme_font_size_override("font_size", 16)
		prompt_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
		prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		zone_body.add_child(prompt_label)

		_add_habit_spacer(8)

		var checkin_btn = Button.new()
		checkin_btn.text = "Start Today's Check-In"
		checkin_btn.custom_minimum_size = Vector2(0, 50)
		checkin_btn.add_theme_font_size_override("font_size", 18)
		checkin_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
		checkin_btn.pressed.connect(_show_new_checkin.bind(false))
		zone_body.add_child(checkin_btn)

	_add_habit_spacer(12)

	# Trends button
	var trends_btn = Button.new()
	trends_btn.text = "View Check-In Trends"
	trends_btn.custom_minimum_size = Vector2(0, 45)
	trends_btn.add_theme_font_size_override("font_size", 16)
	trends_btn.pressed.connect(_show_checkin_trends)
	zone_body.add_child(trends_btn)

	_add_habit_spacer(8)

	# History button
	var history_btn = Button.new()
	history_btn.text = "Check-In History"
	history_btn.custom_minimum_size = Vector2(0, 45)
	history_btn.add_theme_font_size_override("font_size", 16)
	history_btn.pressed.connect(_show_checkin_history)
	zone_body.add_child(history_btn)

	_add_habit_spacer(12)

	# Stats summary
	if checkins.size() >= 3:
		var stats_container = VBoxContainer.new()
		stats_container.add_theme_constant_override("separation", 4)

		var stats_header = Label.new()
		stats_header.text = "7-Day Overview"
		stats_header.add_theme_font_size_override("font_size", 16)
		stats_header.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
		stats_container.add_child(stats_header)

		# Get last 7 days of data
		var recent = checkins.filter(func(c):
			var days_ago = (Time.get_unix_time_from_system() - c.get("timestamp", 0)) / 86400
			return days_ago <= 7
		)

		if recent.size() > 0:
			var avg_mood = 0.0
			var avg_energy = 0.0
			for c in recent:
				avg_mood += c.get("mood", 5)
				avg_energy += c.get("energy", 5)
			avg_mood /= recent.size()
			avg_energy /= recent.size()

			var avg_label = Label.new()
			avg_label.text = "Avg Mood: " + MOOD_EMOJIS[int(avg_mood) - 1] + " %.1f | Avg Energy: %.1f" % [avg_mood, avg_energy]
			avg_label.add_theme_font_size_override("font_size", 14)
			avg_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
			stats_container.add_child(avg_label)

		zone_body.add_child(stats_container)


func _show_new_checkin(is_update: bool) -> void:
	## Show the check-in form
	zone_title.text = "Daily Check-In" if not is_update else "Update Check-In"
	_clear_zone_body()
	_create_journal_graphic()

	# Load existing values if updating
	var today = Time.get_date_string_from_system()
	var checkins = _load_checkins()
	var today_checkin = checkins.filter(func(c): return c.get("date", "") == today)

	if today_checkin.size() > 0:
		current_checkin_mood = today_checkin[0].get("mood", 5)
		current_checkin_energy = today_checkin[0].get("energy", 5)
	else:
		current_checkin_mood = 5
		current_checkin_energy = 5

	_add_habit_spacer(10)

	# Mood section
	var mood_header = Label.new()
	mood_header.text = "How is your mood right now?"
	mood_header.add_theme_font_size_override("font_size", 18)
	mood_header.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	zone_body.add_child(mood_header)

	_add_habit_spacer(6)

	var mood_display = Label.new()
	mood_display.name = "MoodDisplay"
	mood_display.text = MOOD_EMOJIS[current_checkin_mood - 1] + " " + _get_mood_label(current_checkin_mood)
	mood_display.add_theme_font_size_override("font_size", 24)
	mood_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_body.add_child(mood_display)

	_add_habit_spacer(4)

	var mood_slider = HSlider.new()
	mood_slider.name = "MoodSlider"
	mood_slider.min_value = 1
	mood_slider.max_value = 10
	mood_slider.step = 1
	mood_slider.value = current_checkin_mood
	mood_slider.custom_minimum_size = Vector2(0, 30)
	mood_slider.value_changed.connect(_on_mood_slider_changed)
	zone_body.add_child(mood_slider)

	_add_habit_spacer(15)

	# Energy section
	var energy_header = Label.new()
	energy_header.text = "What's your energy level?"
	energy_header.add_theme_font_size_override("font_size", 18)
	energy_header.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	zone_body.add_child(energy_header)

	_add_habit_spacer(6)

	var energy_display = Label.new()
	energy_display.name = "EnergyDisplay"
	energy_display.text = _get_energy_icon(current_checkin_energy) + " " + ENERGY_LABELS[current_checkin_energy - 1]
	energy_display.add_theme_font_size_override("font_size", 22)
	energy_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_body.add_child(energy_display)

	_add_habit_spacer(4)

	var energy_slider = HSlider.new()
	energy_slider.name = "EnergySlider"
	energy_slider.min_value = 1
	energy_slider.max_value = 10
	energy_slider.step = 1
	energy_slider.value = current_checkin_energy
	energy_slider.custom_minimum_size = Vector2(0, 30)
	energy_slider.value_changed.connect(_on_energy_slider_changed)
	zone_body.add_child(energy_slider)

	_add_habit_spacer(15)

	# Intention/Notes
	var notes_header = Label.new()
	notes_header.text = "Today's intention or notes (optional):"
	notes_header.add_theme_font_size_override("font_size", 16)
	notes_header.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	zone_body.add_child(notes_header)

	_add_habit_spacer(4)

	var notes_input = TextEdit.new()
	notes_input.name = "CheckinNotes"
	notes_input.placeholder_text = "What do you want to focus on today?"
	notes_input.custom_minimum_size = Vector2(0, 70)
	notes_input.add_theme_font_size_override("font_size", 15)
	notes_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	if today_checkin.size() > 0:
		notes_input.text = today_checkin[0].get("notes", "")
	zone_body.add_child(notes_input)

	_add_habit_spacer(15)

	# Gratitude prompt section
	var gratitude_header = Label.new()
	gratitude_header.text = "What are you grateful for today?"
	gratitude_header.add_theme_font_size_override("font_size", 16)
	gratitude_header.add_theme_color_override("font_color", Color(0.75, 0.65, 0.5))
	zone_body.add_child(gratitude_header)

	_add_habit_spacer(4)

	# Show a random gratitude prompt
	var gratitude_prompt_label = Label.new()
	gratitude_prompt_label.text = _get_random_gratitude_prompt()
	gratitude_prompt_label.add_theme_font_size_override("font_size", 13)
	gratitude_prompt_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	gratitude_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(gratitude_prompt_label)

	_add_habit_spacer(4)

	var gratitude_input = TextEdit.new()
	gratitude_input.name = "GratitudeInput"
	gratitude_input.placeholder_text = "Three things I'm grateful for..."
	gratitude_input.custom_minimum_size = Vector2(0, 60)
	gratitude_input.add_theme_font_size_override("font_size", 15)
	gratitude_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	if today_checkin.size() > 0:
		gratitude_input.text = today_checkin[0].get("gratitude", "")
	zone_body.add_child(gratitude_input)

	_add_habit_spacer(15)

	# Buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)

	var back_btn = Button.new()
	back_btn.text = "Cancel"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_show_journal_tab.bind("checkin"))
	button_row.add_child(back_btn)

	var save_btn = Button.new()
	save_btn.text = "Save Check-In"
	save_btn.custom_minimum_size = Vector2(0, 45)
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.add_theme_font_size_override("font_size", 16)
	save_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	save_btn.pressed.connect(_save_checkin)
	button_row.add_child(save_btn)

	zone_body.add_child(button_row)


func _on_mood_slider_changed(value: float) -> void:
	current_checkin_mood = int(value)
	var display = zone_body.find_child("MoodDisplay", true, false) as Label
	if display:
		display.text = MOOD_EMOJIS[current_checkin_mood - 1] + " " + _get_mood_label(current_checkin_mood)


func _on_energy_slider_changed(value: float) -> void:
	current_checkin_energy = int(value)
	var display = zone_body.find_child("EnergyDisplay", true, false) as Label
	if display:
		display.text = _get_energy_icon(current_checkin_energy) + " " + ENERGY_LABELS[current_checkin_energy - 1]


func _get_mood_label(level: int) -> String:
	match level:
		1: return "Terrible"
		2: return "Very Low"
		3: return "Low"
		4: return "Below Average"
		5: return "Neutral"
		6: return "Good"
		7: return "Pretty Good"
		8: return "Great"
		9: return "Excellent"
		10: return "Amazing"
	return "Neutral"


func _get_energy_icon(level: int) -> String:
	if level <= 2: return "🔋"  # Low battery
	if level <= 4: return "⚡"  # Some energy
	if level <= 6: return "💪"  # Decent
	if level <= 8: return "🔥"  # High
	return "⚡️"  # Peak


func _get_random_gratitude_prompt() -> String:
	var prompts = [
		"What made you smile today?",
		"Who helped you recently that you're thankful for?",
		"What simple pleasure did you enjoy today?",
		"What challenge are you grateful to have faced?",
		"What's something in your life you often take for granted?",
		"What ability or skill are you thankful to have?",
		"What moment of peace did you experience recently?",
		"What's something beautiful you noticed today?",
		"Who in your life brings you comfort?",
		"What opportunity are you grateful for?",
		"What lesson did you learn recently that you're thankful for?",
		"What made you feel hopeful today?",
		"What's a small victory you achieved recently?",
		"What memory makes you feel warm inside?",
		"What part of your daily routine brings you joy?"
	]
	return prompts[randi() % prompts.size()]


func _save_checkin() -> void:
	var notes_input = zone_body.find_child("CheckinNotes", true, false) as TextEdit
	var notes = notes_input.text.strip_edges() if notes_input else ""

	var gratitude_input = zone_body.find_child("GratitudeInput", true, false) as TextEdit
	var gratitude = gratitude_input.text.strip_edges() if gratitude_input else ""

	var today = Time.get_date_string_from_system()
	var checkins = _load_checkins()

	# Remove existing today's check-in if any
	checkins = checkins.filter(func(c): return c.get("date", "") != today)

	# Add new check-in
	var entry = {
		"date": today,
		"timestamp": Time.get_unix_time_from_system(),
		"mood": current_checkin_mood,
		"energy": current_checkin_energy,
		"notes": notes,
		"gratitude": gratitude
	}
	checkins.append(entry)

	# Save
	_save_checkins(checkins)

	# Award XP for checking in (bonus XP if gratitude included)
	var xp_amount = 15
	var xp_text = "+15 Wisdom XP"
	if gratitude != "":
		xp_amount += 5
		xp_text = "+20 Wisdom XP (includes gratitude bonus!)"
	GameManager.add_aspect_experience("wisdom", xp_amount)

	# Track for aspect quests
	if GameManager:
		GameManager.check_quests_for_trigger("checkin_completed", {
			"mood": current_checkin_mood,
			"energy": current_checkin_energy
		})
		if gratitude != "":
			var gratitude_streak = _get_gratitude_streak(checkins)
			GameManager.check_quests_for_trigger("journal_entry", {
				"type": "gratitude",
				"streak": gratitude_streak
			})

	# Show confirmation and return to tab
	var confirm_text = "Your daily check-in has been recorded.\n\n" + MOOD_EMOJIS[current_checkin_mood - 1] + " Mood: " + _get_mood_label(current_checkin_mood) + "\n" + _get_energy_icon(current_checkin_energy) + " Energy: " + ENERGY_LABELS[current_checkin_energy - 1]
	if gratitude != "":
		confirm_text += "\n🙏 Gratitude: Recorded"
	confirm_text += "\n\n" + xp_text
	_show_dialogue("Check-In Saved", confirm_text)

	# Return to check-in tab after dialog closes
	await get_tree().create_timer(0.1).timeout
	current_journal_tab = "checkin"


func _load_checkins() -> Array:
	var path = "user://checkins.json"
	if not FileAccess.file_exists(path):
		return []

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return []

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return []

	var data = json.data
	if data is Array:
		return data
	return []


func _save_checkins(checkins: Array) -> void:
	var path = "user://checkins.json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(checkins, "\t"))
		file.close()


## Get consecutive days with gratitude entries
func _get_gratitude_streak(checkins: Array) -> int:
	# Sort by date descending
	var sorted = checkins.duplicate()
	sorted.sort_custom(func(a, b): return a.get("date", "") > b.get("date", ""))

	var streak = 0
	var today = Time.get_date_string_from_system()
	var expected_date = today

	for checkin in sorted:
		var checkin_date = checkin.get("date", "")
		var has_gratitude = checkin.get("gratitude", "") != ""

		if checkin_date == expected_date and has_gratitude:
			streak += 1
			# Calculate previous day
			var date_parts = expected_date.split("-")
			if date_parts.size() == 3:
				var dt = {"year": int(date_parts[0]), "month": int(date_parts[1]), "day": int(date_parts[2])}
				var unix = Time.get_unix_time_from_datetime_dict(dt)
				unix -= 86400  # Previous day
				var prev_dt = Time.get_datetime_dict_from_unix_time(unix)
				expected_date = "%04d-%02d-%02d" % [prev_dt.year, prev_dt.month, prev_dt.day]
			else:
				break
		elif checkin_date != expected_date:
			# Gap in dates or no gratitude for expected date
			break

	return streak


func _show_checkin_history() -> void:
	zone_title.text = "Check-In History"
	_clear_zone_body()
	_create_journal_graphic()

	var checkins = _load_checkins()
	checkins.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	_add_habit_spacer(10)

	var count_label = Label.new()
	count_label.text = str(checkins.size()) + " check-ins recorded"
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	zone_body.add_child(count_label)

	_add_habit_spacer(8)

	if checkins.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No check-ins yet.\n\nStart tracking your daily mood and energy to see patterns over time!"
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		zone_body.add_child(empty_label)
	else:
		# Show last 14 check-ins
		var shown = 0
		for checkin in checkins:
			if shown >= 14:
				break
			_add_checkin_card(checkin)
			shown += 1

		if checkins.size() > 14:
			_add_habit_spacer(8)
			var more_label = Label.new()
			more_label.text = "Showing 14 of " + str(checkins.size()) + " entries"
			more_label.add_theme_font_size_override("font_size", 13)
			more_label.add_theme_color_override("font_color", Color(0.45, 0.5, 0.55))
			more_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			zone_body.add_child(more_label)

	_add_habit_spacer(15)

	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_show_journal_tab.bind("checkin"))
	zone_body.add_child(back_btn)


func _add_checkin_card(checkin: Dictionary) -> void:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.09, 0.15, 0.95)
	card_style.set_border_width_all(1)
	card_style.border_width_left = 3
	card_style.border_color = Color(0.5, 0.6, 0.7, 0.6)
	card_style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", card_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)

	# Date
	var date_label = Label.new()
	date_label.text = _format_date(checkin.get("date", ""))
	date_label.add_theme_font_size_override("font_size", 14)
	date_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	date_label.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(date_label)

	# Mood
	var mood_val = checkin.get("mood", 5)
	var mood_label = Label.new()
	mood_label.text = MOOD_EMOJIS[mood_val - 1] + " " + str(mood_val)
	mood_label.add_theme_font_size_override("font_size", 16)
	mood_label.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(mood_label)

	# Energy
	var energy_val = checkin.get("energy", 5)
	var energy_label = Label.new()
	energy_label.text = _get_energy_icon(energy_val) + " " + str(energy_val)
	energy_label.add_theme_font_size_override("font_size", 16)
	energy_label.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(energy_label)

	# Notes/gratitude preview
	var notes = checkin.get("notes", "")
	var gratitude = checkin.get("gratitude", "")
	var preview_text = ""

	if gratitude != "":
		preview_text = "🙏 " + gratitude.substr(0, 25) + ("..." if gratitude.length() > 25 else "")
	elif notes != "":
		preview_text = notes.substr(0, 30) + ("..." if notes.length() > 30 else "")

	if preview_text != "":
		var preview_label = Label.new()
		preview_label.text = preview_text
		preview_label.add_theme_font_size_override("font_size", 13)
		preview_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		preview_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preview_label.clip_text = true
		hbox.add_child(preview_label)

	zone_body.add_child(card)
	_add_habit_spacer(4)


func _show_checkin_trends() -> void:
	zone_title.text = "Check-In Trends"
	_clear_zone_body()
	_create_journal_graphic()

	var checkins = _load_checkins()
	checkins.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	_add_habit_spacer(10)

	if checkins.size() < 3:
		var need_more = Label.new()
		need_more.text = "Need at least 3 check-ins to show trends.\n\nKeep checking in daily to see your patterns!"
		need_more.autowrap_mode = TextServer.AUTOWRAP_WORD
		need_more.add_theme_font_size_override("font_size", 16)
		need_more.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		zone_body.add_child(need_more)
	else:
		# 7-day trend visualization
		var last_7_days = checkins.filter(func(c):
			var days_ago = (Time.get_unix_time_from_system() - c.get("timestamp", 0)) / 86400
			return days_ago <= 7
		)

		var trend_header = Label.new()
		trend_header.text = "Last 7 Days (" + str(last_7_days.size()) + " check-ins)"
		trend_header.add_theme_font_size_override("font_size", 18)
		trend_header.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		zone_body.add_child(trend_header)

		_add_habit_spacer(8)

		# Visual bar chart for mood
		var mood_section = VBoxContainer.new()

		var mood_title = Label.new()
		mood_title.text = "Mood Trend"
		mood_title.add_theme_font_size_override("font_size", 16)
		mood_title.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
		mood_section.add_child(mood_title)

		var mood_bars = HBoxContainer.new()
		mood_bars.add_theme_constant_override("separation", 4)

		# Reverse to show oldest first
		var reversed_7 = last_7_days.duplicate()
		reversed_7.reverse()

		for i in range(min(7, reversed_7.size())):
			var c = reversed_7[i]
			var bar_container = VBoxContainer.new()
			bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bar_container.add_theme_constant_override("separation", 2)

			var bar = ColorRect.new()
			bar.custom_minimum_size = Vector2(0, c.get("mood", 5) * 8)
			bar.color = _get_mood_color(c.get("mood", 5))
			bar.size_flags_vertical = Control.SIZE_SHRINK_END
			bar_container.add_child(bar)

			var day_label = Label.new()
			day_label.text = MOOD_EMOJIS[c.get("mood", 5) - 1]
			day_label.add_theme_font_size_override("font_size", 12)
			day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bar_container.add_child(day_label)

			mood_bars.add_child(bar_container)

		mood_section.add_child(mood_bars)
		zone_body.add_child(mood_section)

		_add_habit_spacer(15)

		# Energy trend
		var energy_section = VBoxContainer.new()

		var energy_title = Label.new()
		energy_title.text = "Energy Trend"
		energy_title.add_theme_font_size_override("font_size", 16)
		energy_title.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
		energy_section.add_child(energy_title)

		var energy_bars = HBoxContainer.new()
		energy_bars.add_theme_constant_override("separation", 4)

		for i in range(min(7, reversed_7.size())):
			var c = reversed_7[i]
			var bar_container = VBoxContainer.new()
			bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bar_container.add_theme_constant_override("separation", 2)

			var bar = ColorRect.new()
			bar.custom_minimum_size = Vector2(0, c.get("energy", 5) * 8)
			bar.color = _get_energy_color(c.get("energy", 5))
			bar.size_flags_vertical = Control.SIZE_SHRINK_END
			bar_container.add_child(bar)

			var day_label = Label.new()
			day_label.text = _get_energy_icon(c.get("energy", 5))
			day_label.add_theme_font_size_override("font_size", 12)
			day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bar_container.add_child(day_label)

			energy_bars.add_child(bar_container)

		energy_section.add_child(energy_bars)
		zone_body.add_child(energy_section)

		_add_habit_spacer(15)

		# Statistics
		var stats_header = Label.new()
		stats_header.text = "All-Time Statistics"
		stats_header.add_theme_font_size_override("font_size", 18)
		stats_header.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		zone_body.add_child(stats_header)

		_add_habit_spacer(6)

		var total_checkins = checkins.size()
		var avg_mood = 0.0
		var avg_energy = 0.0
		var best_mood_day = {"mood": 0, "date": ""}
		var best_energy_day = {"energy": 0, "date": ""}

		for c in checkins:
			avg_mood += c.get("mood", 5)
			avg_energy += c.get("energy", 5)
			if c.get("mood", 0) > best_mood_day.mood:
				best_mood_day = {"mood": c.get("mood", 0), "date": c.get("date", "")}
			if c.get("energy", 0) > best_energy_day.energy:
				best_energy_day = {"energy": c.get("energy", 0), "date": c.get("date", "")}

		avg_mood /= total_checkins
		avg_energy /= total_checkins

		var stats_grid = GridContainer.new()
		stats_grid.columns = 2
		stats_grid.add_theme_constant_override("h_separation", 20)
		stats_grid.add_theme_constant_override("v_separation", 6)

		_add_grid_stat_row(stats_grid, "Total Check-ins:", str(total_checkins))
		_add_grid_stat_row(stats_grid, "Average Mood:", "%.1f " % avg_mood + MOOD_EMOJIS[int(avg_mood) - 1])
		_add_grid_stat_row(stats_grid, "Average Energy:", "%.1f" % avg_energy)
		_add_grid_stat_row(stats_grid, "Best Mood Day:", _format_date(best_mood_day.date) + " (" + str(best_mood_day.mood) + ")")
		_add_grid_stat_row(stats_grid, "Best Energy Day:", _format_date(best_energy_day.date) + " (" + str(best_energy_day.energy) + ")")

		zone_body.add_child(stats_grid)

	_add_habit_spacer(15)

	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_show_journal_tab.bind("checkin"))
	zone_body.add_child(back_btn)


func _add_grid_stat_row(grid: GridContainer, label_text: String, value_text: String) -> void:
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
	grid.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 14)
	value.add_theme_color_override("font_color", Color(0.8, 0.82, 0.85))
	grid.add_child(value)


func _get_mood_color(level: int) -> Color:
	if level <= 2: return Color(0.6, 0.2, 0.2)  # Red
	if level <= 4: return Color(0.7, 0.5, 0.3)  # Orange
	if level <= 6: return Color(0.6, 0.6, 0.4)  # Yellow
	if level <= 8: return Color(0.4, 0.6, 0.4)  # Light green
	return Color(0.3, 0.7, 0.4)  # Green


func _get_energy_color(level: int) -> Color:
	if level <= 2: return Color(0.4, 0.3, 0.5)  # Dark purple
	if level <= 4: return Color(0.5, 0.4, 0.6)  # Purple
	if level <= 6: return Color(0.5, 0.5, 0.7)  # Blue
	if level <= 8: return Color(0.4, 0.6, 0.7)  # Teal
	return Color(0.3, 0.7, 0.6)  # Bright teal


# =============================================================================
# WEEKLY SYNTHESIS RITUAL
# =============================================================================

func _build_weekly_synthesis_tab() -> void:
	## Weekly reflection and planning ritual
	var today = Time.get_date_string_from_system()
	var week_number = _get_week_number()
	var weekly_reviews = _load_weekly_reviews()
	var current_week_review = weekly_reviews.filter(func(r): return r.get("week_number", 0) == week_number)

	# Header
	var header = Label.new()
	header.text = "Weekly Synthesis"
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_body.add_child(header)

	_add_habit_spacer(6)

	var week_label = Label.new()
	week_label.text = "Week " + str(week_number) + " of " + str(Time.get_date_dict_from_system().year)
	week_label.add_theme_font_size_override("font_size", 14)
	week_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	week_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_body.add_child(week_label)

	_add_habit_spacer(10)

	# Check if already completed this week
	if current_week_review.size() > 0:
		var completed_label = Label.new()
		completed_label.text = "This week's synthesis is complete!"
		completed_label.add_theme_font_size_override("font_size", 16)
		completed_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		completed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		zone_body.add_child(completed_label)

		_add_habit_spacer(10)

		# Show summary
		var review = current_week_review[0]
		_show_weekly_summary(review)

		_add_habit_spacer(12)

		var edit_btn = Button.new()
		edit_btn.text = "Edit This Week's Review"
		edit_btn.custom_minimum_size = Vector2(0, 45)
		edit_btn.add_theme_font_size_override("font_size", 16)
		edit_btn.pressed.connect(_start_weekly_synthesis.bind(true))
		zone_body.add_child(edit_btn)
	else:
		# Show week stats preview
		_show_week_stats_preview()

		_add_habit_spacer(12)

		var start_btn = Button.new()
		start_btn.text = "Begin Weekly Synthesis"
		start_btn.custom_minimum_size = Vector2(0, 50)
		start_btn.add_theme_font_size_override("font_size", 18)
		start_btn.add_theme_color_override("font_color", Color(0.8, 0.75, 0.5))
		start_btn.pressed.connect(_start_weekly_synthesis.bind(false))
		zone_body.add_child(start_btn)

	_add_habit_spacer(12)

	# Past reviews button
	var history_btn = Button.new()
	history_btn.text = "View Past Weekly Reviews"
	history_btn.custom_minimum_size = Vector2(0, 45)
	history_btn.add_theme_font_size_override("font_size", 16)
	history_btn.pressed.connect(_show_weekly_history)
	zone_body.add_child(history_btn)


func _show_week_stats_preview() -> void:
	## Show this week's auto-collected stats
	var stats = _gather_week_stats()

	var stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 6)

	var stats_header = Label.new()
	stats_header.text = "This Week's Activity:"
	stats_header.add_theme_font_size_override("font_size", 16)
	stats_header.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	stats_container.add_child(stats_header)

	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 4)

	_add_grid_stat_row(stats_grid, "Focus Sessions:", str(stats.focus_sessions))
	_add_grid_stat_row(stats_grid, "Focus Minutes:", str(stats.focus_minutes))
	_add_grid_stat_row(stats_grid, "Habits Completed:", str(stats.habits_completed))
	_add_grid_stat_row(stats_grid, "Goals Achieved:", str(stats.goals_completed))
	_add_grid_stat_row(stats_grid, "Check-Ins:", str(stats.checkins))

	if stats.avg_mood > 0:
		_add_grid_stat_row(stats_grid, "Avg Mood:", "%.1f " % stats.avg_mood + MOOD_EMOJIS[int(stats.avg_mood) - 1])
	if stats.avg_energy > 0:
		_add_grid_stat_row(stats_grid, "Avg Energy:", "%.1f" % stats.avg_energy)

	stats_container.add_child(stats_grid)
	zone_body.add_child(stats_container)


func _gather_week_stats() -> Dictionary:
	## Gather statistics for the current week
	var now = Time.get_unix_time_from_system()
	var week_start = now - (Time.get_date_dict_from_system().weekday * 86400)

	var stats = {
		"focus_sessions": 0,
		"focus_minutes": 0,
		"habits_completed": 0,
		"goals_completed": 0,
		"checkins": 0,
		"avg_mood": 0.0,
		"avg_energy": 0.0
	}

	# Focus sessions from journal
	var journal = _load_journal()
	for entry in journal:
		var ts = entry.get("timestamp", 0)
		if ts >= week_start:
			if entry.get("type", "") != "habit":
				stats.focus_sessions += 1
				stats.focus_minutes += entry.get("duration", 0)
			else:
				stats.habits_completed += 1

	# Check-ins
	var checkins = _load_checkins()
	var week_checkins = checkins.filter(func(c): return c.get("timestamp", 0) >= week_start)
	stats.checkins = week_checkins.size()

	if week_checkins.size() > 0:
		var total_mood = 0.0
		var total_energy = 0.0
		for c in week_checkins:
			total_mood += c.get("mood", 5)
			total_energy += c.get("energy", 5)
		stats.avg_mood = total_mood / week_checkins.size()
		stats.avg_energy = total_energy / week_checkins.size()

	# Goals from GameManager
	var goals = GameManager.player_data.get("completed_goals_this_week", 0)
	stats.goals_completed = goals

	return stats


func _start_weekly_synthesis(is_edit: bool) -> void:
	## Start the weekly synthesis ritual
	zone_title.text = "Weekly Synthesis"
	_clear_zone_body()

	var week_number = _get_week_number()
	var weekly_reviews = _load_weekly_reviews()
	var existing = weekly_reviews.filter(func(r): return r.get("week_number", 0) == week_number)

	_add_habit_spacer(10)

	var intro = Label.new()
	intro.text = "Reflect on this week and set intentions for the next."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_font_size_override("font_size", 16)
	intro.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	zone_body.add_child(intro)

	_add_habit_spacer(12)

	# Wins section
	var wins_label = Label.new()
	wins_label.text = "What were your wins this week?"
	wins_label.add_theme_font_size_override("font_size", 16)
	wins_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	zone_body.add_child(wins_label)

	var wins_input = TextEdit.new()
	wins_input.name = "WinsInput"
	wins_input.placeholder_text = "Celebrate your achievements, big and small..."
	wins_input.custom_minimum_size = Vector2(0, 60)
	wins_input.add_theme_font_size_override("font_size", 14)
	wins_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	if existing.size() > 0:
		wins_input.text = existing[0].get("wins", "")
	zone_body.add_child(wins_input)

	_add_habit_spacer(10)

	# Challenges section
	var challenges_label = Label.new()
	challenges_label.text = "What challenges did you face?"
	challenges_label.add_theme_font_size_override("font_size", 16)
	challenges_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.5))
	zone_body.add_child(challenges_label)

	var challenges_input = TextEdit.new()
	challenges_input.name = "ChallengesInput"
	challenges_input.placeholder_text = "Obstacles you encountered..."
	challenges_input.custom_minimum_size = Vector2(0, 50)
	challenges_input.add_theme_font_size_override("font_size", 14)
	challenges_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	if existing.size() > 0:
		challenges_input.text = existing[0].get("challenges", "")
	zone_body.add_child(challenges_input)

	_add_habit_spacer(10)

	# Lessons section
	var lessons_label = Label.new()
	lessons_label.text = "What did you learn?"
	lessons_label.add_theme_font_size_override("font_size", 16)
	lessons_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	zone_body.add_child(lessons_label)

	var lessons_input = TextEdit.new()
	lessons_input.name = "LessonsInput"
	lessons_input.placeholder_text = "Key insights and realizations..."
	lessons_input.custom_minimum_size = Vector2(0, 50)
	lessons_input.add_theme_font_size_override("font_size", 14)
	lessons_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	if existing.size() > 0:
		lessons_input.text = existing[0].get("lessons", "")
	zone_body.add_child(lessons_input)

	_add_habit_spacer(10)

	# Next week intentions
	var intentions_label = Label.new()
	intentions_label.text = "What do you want to focus on next week?"
	intentions_label.add_theme_font_size_override("font_size", 16)
	intentions_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.5))
	zone_body.add_child(intentions_label)

	var intentions_input = TextEdit.new()
	intentions_input.name = "IntentionsInput"
	intentions_input.placeholder_text = "Set your intentions for next week..."
	intentions_input.custom_minimum_size = Vector2(0, 50)
	intentions_input.add_theme_font_size_override("font_size", 14)
	intentions_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	if existing.size() > 0:
		intentions_input.text = existing[0].get("intentions", "")
	zone_body.add_child(intentions_input)

	_add_habit_spacer(12)

	# Overall rating
	var rating_label = Label.new()
	rating_label.text = "Rate your week (1-10):"
	rating_label.add_theme_font_size_override("font_size", 16)
	zone_body.add_child(rating_label)

	var rating_row = HBoxContainer.new()
	rating_row.add_theme_constant_override("separation", 6)

	for i in range(1, 11):
		var btn = Button.new()
		btn.name = "Rating_" + str(i)
		btn.text = str(i)
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(35, 35)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_select_week_rating.bind(i))
		if existing.size() > 0 and existing[0].get("rating", 0) == i:
			btn.button_pressed = true
			btn.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
		rating_row.add_child(btn)

	zone_body.add_child(rating_row)

	_add_habit_spacer(15)

	# Buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)

	var back_btn = Button.new()
	back_btn.text = "Cancel"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(_show_journal_tab.bind("weekly"))
	button_row.add_child(back_btn)

	var save_btn = Button.new()
	save_btn.text = "Save Review"
	save_btn.custom_minimum_size = Vector2(0, 45)
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.add_theme_font_size_override("font_size", 16)
	save_btn.add_theme_color_override("font_color", Color(0.8, 0.75, 0.5))
	save_btn.pressed.connect(_save_weekly_synthesis)
	button_row.add_child(save_btn)

	zone_body.add_child(button_row)


var selected_week_rating: int = 0

func _select_week_rating(rating: int) -> void:
	selected_week_rating = rating
	# Update button states
	for i in range(1, 11):
		var btn = zone_body.find_child("Rating_" + str(i), true, false) as Button
		if btn:
			if i == rating:
				btn.button_pressed = true
				btn.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
			else:
				btn.button_pressed = false
				btn.remove_theme_color_override("font_color")


func _save_weekly_synthesis() -> void:
	var wins_input = zone_body.find_child("WinsInput", true, false) as TextEdit
	var challenges_input = zone_body.find_child("ChallengesInput", true, false) as TextEdit
	var lessons_input = zone_body.find_child("LessonsInput", true, false) as TextEdit
	var intentions_input = zone_body.find_child("IntentionsInput", true, false) as TextEdit

	var wins = wins_input.text.strip_edges() if wins_input else ""
	var challenges = challenges_input.text.strip_edges() if challenges_input else ""
	var lessons = lessons_input.text.strip_edges() if lessons_input else ""
	var intentions = intentions_input.text.strip_edges() if intentions_input else ""

	if wins == "" and challenges == "" and lessons == "" and intentions == "":
		_show_dialogue("Nothing Entered", "Please fill in at least one section of your weekly review.")
		return

	var week_number = _get_week_number()
	var stats = _gather_week_stats()
	var weekly_reviews = _load_weekly_reviews()

	# Remove existing review for this week if any
	weekly_reviews = weekly_reviews.filter(func(r): return r.get("week_number", 0) != week_number)

	# Add new review
	var review = {
		"week_number": week_number,
		"year": Time.get_date_dict_from_system().year,
		"timestamp": Time.get_unix_time_from_system(),
		"wins": wins,
		"challenges": challenges,
		"lessons": lessons,
		"intentions": intentions,
		"rating": selected_week_rating,
		"stats": stats
	}
	weekly_reviews.append(review)

	_save_weekly_reviews(weekly_reviews)

	# Award XP for completing weekly review
	var xp_reward = 50
	GameManager.add_aspect_experience("wisdom", xp_reward)

	# Track for aspect quests
	if GameManager:
		GameManager.check_quests_for_trigger("weekly_synthesis", {})

	_show_dialogue("Weekly Synthesis Complete", "Your weekly review has been saved!\n\nReflecting on your progress builds wisdom and clarity.\n\n+50 Wisdom XP")

	current_journal_tab = "weekly"
	await get_tree().create_timer(0.1).timeout


func _show_weekly_summary(review: Dictionary) -> void:
	## Show a summary of a completed weekly review
	var summary_container = VBoxContainer.new()
	summary_container.add_theme_constant_override("separation", 8)

	# Rating
	if review.get("rating", 0) > 0:
		var rating_label = Label.new()
		rating_label.text = "Week Rating: " + str(review.rating) + "/10 " + _get_rating_emoji(review.rating)
		rating_label.add_theme_font_size_override("font_size", 16)
		rating_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
		summary_container.add_child(rating_label)

	# Wins preview
	if review.get("wins", "") != "":
		var wins_preview = Label.new()
		wins_preview.text = "Wins: " + review.wins.substr(0, 50) + ("..." if review.wins.length() > 50 else "")
		wins_preview.add_theme_font_size_override("font_size", 14)
		wins_preview.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
		wins_preview.autowrap_mode = TextServer.AUTOWRAP_WORD
		summary_container.add_child(wins_preview)

	# Intentions preview
	if review.get("intentions", "") != "":
		var intentions_preview = Label.new()
		intentions_preview.text = "Next Focus: " + review.intentions.substr(0, 50) + ("..." if review.intentions.length() > 50 else "")
		intentions_preview.add_theme_font_size_override("font_size", 14)
		intentions_preview.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5))
		intentions_preview.autowrap_mode = TextServer.AUTOWRAP_WORD
		summary_container.add_child(intentions_preview)

	zone_body.add_child(summary_container)


func _get_rating_emoji(rating: int) -> String:
	if rating <= 2: return "😔"
	if rating <= 4: return "😐"
	if rating <= 6: return "🙂"
	if rating <= 8: return "😊"
	return "🌟"


func _show_weekly_history() -> void:
	zone_title.text = "Past Weekly Reviews"
	_clear_zone_body()

	var reviews = _load_weekly_reviews()
	reviews.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	_add_habit_spacer(10)

	var count_label = Label.new()
	count_label.text = str(reviews.size()) + " weekly reviews"
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	zone_body.add_child(count_label)

	_add_habit_spacer(8)

	if reviews.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No weekly reviews yet.\n\nComplete your first weekly synthesis to start tracking your progress over time!"
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		zone_body.add_child(empty_label)
	else:
		for review in reviews:
			_add_weekly_review_card(review)

	_add_habit_spacer(15)

	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_show_journal_tab.bind("weekly"))
	zone_body.add_child(back_btn)


func _add_weekly_review_card(review: Dictionary) -> void:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.09, 0.12, 0.95)
	card_style.set_border_width_all(1)
	card_style.border_width_left = 3
	card_style.border_color = Color(0.8, 0.7, 0.5, 0.6)
	card_style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", card_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Week header
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 15)

	var week_label = Label.new()
	week_label.text = "Week " + str(review.get("week_number", 0)) + ", " + str(review.get("year", 0))
	week_label.add_theme_font_size_override("font_size", 16)
	week_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6))
	week_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(week_label)

	if review.get("rating", 0) > 0:
		var rating_label = Label.new()
		rating_label.text = str(review.rating) + "/10 " + _get_rating_emoji(review.rating)
		rating_label.add_theme_font_size_override("font_size", 14)
		rating_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
		header_row.add_child(rating_label)

	vbox.add_child(header_row)

	# Stats summary
	var stats = review.get("stats", {})
	if not stats.is_empty():
		var stats_label = Label.new()
		stats_label.text = str(stats.get("focus_sessions", 0)) + " sessions | " + str(stats.get("habits_completed", 0)) + " habits"
		stats_label.add_theme_font_size_override("font_size", 12)
		stats_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		vbox.add_child(stats_label)

	zone_body.add_child(card)
	_add_habit_spacer(4)


func _get_week_number() -> int:
	## Get the current week number of the year
	var date = Time.get_date_dict_from_system()
	var day_of_year = Time.get_date_dict_from_system().day
	# Approximate - count weeks from January 1st
	for m in range(1, date.month):
		var days_in_month = 31
		if m in [4, 6, 9, 11]:
			days_in_month = 30
		elif m == 2:
			days_in_month = 28
			if date.year % 4 == 0:
				days_in_month = 29
		day_of_year += days_in_month
	return int(day_of_year / 7) + 1


func _load_weekly_reviews() -> Array:
	var path = "user://weekly_reviews.json"
	if not FileAccess.file_exists(path):
		return []

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return []

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return []

	var data = json.data
	if data is Array:
		return data
	return []


func _save_weekly_reviews(reviews: Array) -> void:
	var path = "user://weekly_reviews.json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(reviews, "\t"))
		file.close()


# =============================================================================
# JOURNAL ENTRY DETAIL
# =============================================================================

func _show_journal_entry_detail(entry: Dictionary) -> void:
	zone_title.text = "Entry Details"
	_clear_zone_body()

	var entry_type = entry.get("type", "focus")
	var is_habit = entry_type == "habit"

	# Header with type and date
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	zone_body.add_child(header)

	var type_label = Label.new()
	if is_habit:
		type_label.text = "✓ Habit Completion"
		type_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	else:
		type_label.text = "🎯 Focus Session"
		type_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	type_label.add_theme_font_size_override("font_size", 18)
	type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(type_label)

	var date_str = entry.get("date", "")
	if date_str != "":
		var date_label = Label.new()
		date_label.text = _format_date_full(date_str)
		date_label.add_theme_font_size_override("font_size", 16)
		date_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
		header.add_child(date_label)

	_add_habit_spacer(15)

	# Title/Name
	var title = Label.new()
	if is_habit:
		title.text = entry.get("habit_name", "Habit")
	else:
		title.text = entry.get("topic", "Focus Session")
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	zone_body.add_child(title)

	_add_habit_spacer(12)

	# Entry-specific details
	if is_habit:
		_build_habit_entry_details(entry)
	else:
		_build_focus_entry_details(entry)

	_add_habit_spacer(20)

	# Back button
	var back_btn = Button.new()
	back_btn.text = "← Back to Journal"
	back_btn.custom_minimum_size = Vector2(0, 45)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_open_journal_viewer)
	zone_body.add_child(back_btn)


func _build_habit_entry_details(entry: Dictionary) -> void:
	# Streak info
	var streak = entry.get("streak", 0)
	if streak > 0:
		var streak_box = _create_detail_row("🔥 Streak", "%d days" % streak, Color(0.9, 0.6, 0.3))
		zone_body.add_child(streak_box)
		_add_habit_spacer(8)

	# Time of completion
	var timestamp = entry.get("timestamp", 0)
	if timestamp > 0:
		var datetime = Time.get_datetime_dict_from_unix_time(int(timestamp))
		var time_str = "%02d:%02d" % [datetime.hour, datetime.minute]
		var time_box = _create_detail_row("⏰ Completed at", time_str, Color(0.6, 0.7, 0.8))
		zone_body.add_child(time_box)
		_add_habit_spacer(8)

	# Note (check both "note" and "text" for backwards compatibility)
	var note = entry.get("note", "")
	if note == "":
		note = entry.get("text", "")
	if note != "":
		_add_habit_spacer(8)
		var note_header = Label.new()
		note_header.text = "📝 Notes"
		note_header.add_theme_font_size_override("font_size", 16)
		note_header.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		zone_body.add_child(note_header)

		var note_panel = PanelContainer.new()
		var note_style = StyleBoxFlat.new()
		note_style.bg_color = Color(0.06, 0.05, 0.1, 0.8)
		note_style.set_corner_radius_all(6)
		note_style.content_margin_left = 12
		note_style.content_margin_right = 12
		note_style.content_margin_top = 10
		note_style.content_margin_bottom = 10
		note_panel.add_theme_stylebox_override("panel", note_style)

		var note_text = Label.new()
		note_text.text = note
		note_text.autowrap_mode = TextServer.AUTOWRAP_WORD
		note_text.add_theme_font_size_override("font_size", 16)
		note_text.add_theme_color_override("font_color", Color(0.8, 0.82, 0.85))
		note_panel.add_child(note_text)
		zone_body.add_child(note_panel)
	else:
		var no_note = Label.new()
		no_note.text = "(No notes recorded)"
		no_note.add_theme_font_size_override("font_size", 15)
		no_note.add_theme_color_override("font_color", Color(0.45, 0.5, 0.55))
		zone_body.add_child(no_note)


func _build_focus_entry_details(entry: Dictionary) -> void:
	# Duration
	var duration = int(entry.get("duration_minutes", 0))
	if duration > 0:
		var hours = duration / 60
		var mins = duration % 60
		var dur_str = ""
		if hours > 0:
			dur_str = "%dh %dm" % [hours, mins]
		else:
			dur_str = "%d minutes" % mins
		var dur_box = _create_detail_row("⏱ Duration", dur_str, Color(0.6, 0.75, 0.9))
		zone_body.add_child(dur_box)
		_add_habit_spacer(8)

	# Script used (if any)
	var script_name = entry.get("script_name", "")
	if script_name != "":
		var script_box = _create_detail_row("📜 Script", script_name, Color(0.7, 0.6, 0.85))
		zone_body.add_child(script_box)
		_add_habit_spacer(8)

	# Difficulty
	var difficulty = entry.get("difficulty", "")
	if difficulty != "":
		var diff_box = _create_detail_row("⚡ Mode", difficulty.capitalize(), Color(0.8, 0.7, 0.5))
		zone_body.add_child(diff_box)
		_add_habit_spacer(8)

	# Time of session
	var timestamp = entry.get("timestamp", 0)
	if timestamp > 0:
		var datetime = Time.get_datetime_dict_from_unix_time(int(timestamp))
		var time_str = "%02d:%02d" % [datetime.hour, datetime.minute]
		var time_box = _create_detail_row("⏰ Started at", time_str, Color(0.6, 0.65, 0.7))
		zone_body.add_child(time_box)

	_add_habit_spacer(15)

	# Reflections section
	var has_reflections = false
	var learned = entry.get("learned", "")
	var accomplished = entry.get("accomplished", "")
	var next_goals = entry.get("next_goals", "")

	if learned != "" or accomplished != "" or next_goals != "":
		has_reflections = true
		var ref_header = Label.new()
		ref_header.text = "📝 Session Reflections"
		ref_header.add_theme_font_size_override("font_size", 18)
		ref_header.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
		zone_body.add_child(ref_header)
		_add_habit_spacer(10)

	if learned != "":
		_add_reflection_section("💡 What I learned", learned, Color(0.85, 0.75, 0.5))

	if accomplished != "":
		_add_reflection_section("✓ What I accomplished", accomplished, Color(0.6, 0.8, 0.6))

	if next_goals != "":
		_add_reflection_section("→ Next steps", next_goals, Color(0.65, 0.7, 0.85))

	if not has_reflections:
		var no_ref = Label.new()
		no_ref.text = "(No reflections recorded)"
		no_ref.add_theme_font_size_override("font_size", 15)
		no_ref.add_theme_color_override("font_color", Color(0.45, 0.5, 0.55))
		zone_body.add_child(no_ref)


func _create_detail_row(label_text: String, value_text: String, value_color: Color) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	label.custom_minimum_size = Vector2(140, 0)
	row.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", value_color)
	row.add_child(value)

	return row


func _add_reflection_section(header_text: String, content: String, header_color: Color) -> void:
	var header = Label.new()
	header.text = header_text
	header.add_theme_font_size_override("font_size", 15)
	header.add_theme_color_override("font_color", header_color)
	zone_body.add_child(header)

	var content_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.7)
	style.set_corner_radius_all(5)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	content_panel.add_theme_stylebox_override("panel", style)

	var content_label = Label.new()
	content_label.text = content
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	content_label.add_theme_font_size_override("font_size", 15)
	content_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
	content_panel.add_child(content_label)
	zone_body.add_child(content_panel)

	_add_habit_spacer(10)


func _format_date_full(date_str: String) -> String:
	if date_str == "":
		return ""
	var parts = date_str.split("-")
	if parts.size() != 3:
		return date_str
	var months = ["", "January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"]
	var month_num = int(parts[1])
	if month_num < 1 or month_num > 12:
		return date_str
	return months[month_num] + " " + str(int(parts[2])) + ", " + parts[0]


# =============================================================================
# ENHANCED HUB ENVIRONMENT
# =============================================================================

var hub_env_container: Node2D = null
var hub_particles: Array = []
var hub_orbs: Array = []
var hub_env_time: float = 0.0

# Weather/atmosphere system
var weather_overlay: ColorRect = null
var weather_particles: Array = []
var atmosphere_level: int = 0  # 0-5 based on progress
const ATMOSPHERE_COLORS = [
	Color(0.05, 0.05, 0.1, 0.0),    # Level 0: No tint (starting)
	Color(0.1, 0.08, 0.15, 0.05),   # Level 1: Slight purple mist
	Color(0.08, 0.12, 0.15, 0.08),  # Level 2: Ethereal blue
	Color(0.12, 0.1, 0.18, 0.1),    # Level 3: Deeper mystical
	Color(0.15, 0.12, 0.2, 0.12),   # Level 4: Rich atmosphere
	Color(0.18, 0.15, 0.25, 0.15)   # Level 5: Full mystical realm
]

func _create_enhanced_hub_environment() -> void:
	# Create container for enhanced visuals
	hub_env_container = Node2D.new()
	hub_env_container.name = "EnhancedEnvironment"
	isometric_base.add_child(hub_env_container)
	isometric_base.move_child(hub_env_container, 1)  # After BasePlatform

	# Create floor pattern layers
	_create_hub_floor_patterns()

	# Create ambient glow orbs
	_create_hub_glow_orbs()

	# Create floating particles
	_create_hub_floating_particles()

	# Create path decorations
	_create_hub_path_decorations()

	# Create center crystal enhancement
	_create_hub_center_enhancement()

	# Create progress indicators (streak flames, evolution ring, garden patches)
	_create_progress_indicators()

	# Create weather/atmosphere effects based on progress
	_create_weather_atmosphere()


func _create_weather_atmosphere() -> void:
	## Create dynamic weather effects based on player progress
	## Higher evolution = more magical atmosphere

	# Calculate atmosphere level based on progress
	var evolution = GameManager.get_evolution_level() if GameManager else 1
	var streak = GameManager.player_data.get("current_streak", 0) if GameManager else 0
	var total_sessions = GameManager.player_data.get("total_focus_sessions", 0) if GameManager else 0

	# Determine atmosphere level (0-5)
	if evolution >= 8 or total_sessions >= 100:
		atmosphere_level = 5
	elif evolution >= 6 or total_sessions >= 50:
		atmosphere_level = 4
	elif evolution >= 4 or total_sessions >= 25:
		atmosphere_level = 3
	elif evolution >= 2 or total_sessions >= 10:
		atmosphere_level = 2
	elif total_sessions >= 3:
		atmosphere_level = 1
	else:
		atmosphere_level = 0

	# Create atmosphere overlay (subtle color tint)
	weather_overlay = ColorRect.new()
	weather_overlay.name = "AtmosphereOverlay"
	weather_overlay.color = ATMOSPHERE_COLORS[atmosphere_level]
	weather_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weather_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	weather_overlay.z_index = 100
	add_child(weather_overlay)

	# Create floating weather particles based on level
	_create_weather_particles()

	# Add streak-based aurora effect if streak is high
	if streak >= 7:
		_create_aurora_effect(streak)


func _create_weather_particles() -> void:
	## Create magical floating particles that increase with atmosphere level
	var particle_count = atmosphere_level * 8  # 0, 8, 16, 24, 32, 40 particles

	for i in range(particle_count):
		var particle = Polygon2D.new()
		particle.name = "WeatherParticle_" + str(i)

		# Random size based on atmosphere level
		var size = randf_range(2, 4 + atmosphere_level)
		particle.polygon = _create_soft_circle(size, 6)

		# Position randomly across the view
		var viewport_size = get_viewport_rect().size
		particle.position = Vector2(
			randf_range(0, viewport_size.x),
			randf_range(0, viewport_size.y)
		)

		# Color varies by atmosphere level
		var hue = randf_range(0.6, 0.8)  # Purple to blue range
		var sat = randf_range(0.3, 0.6)
		var val = randf_range(0.7, 1.0)
		var alpha = randf_range(0.1, 0.3) * (atmosphere_level / 5.0 + 0.2)
		particle.color = Color.from_hsv(hue, sat, val, alpha)

		particle.z_index = 50
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(particle)

		weather_particles.append({
			"node": particle,
			"base_y": particle.position.y,
			"speed": randf_range(0.3, 0.8),
			"drift_speed": randf_range(0.5, 1.5),
			"phase": randf() * TAU,
			"amplitude": randf_range(20, 50)
		})


func _create_aurora_effect(streak: int) -> void:
	## Create subtle aurora bands for high streaks
	var aurora_container = Node2D.new()
	aurora_container.name = "Aurora"
	aurora_container.z_index = 1

	var band_count = mini(streak / 7, 4)  # Max 4 bands

	for i in range(band_count):
		var band = Polygon2D.new()
		band.name = "AuroraBand_" + str(i)

		# Create a wide curved band shape
		var points = PackedVector2Array()
		var y_base = -300 - i * 40
		var segments = 20
		for j in range(segments + 1):
			var x = (float(j) / segments) * 2000 - 1000
			var y = y_base + sin(float(j) / segments * PI) * 30
			points.append(Vector2(x, y))
		# Close the bottom
		for j in range(segments, -1, -1):
			var x = (float(j) / segments) * 2000 - 1000
			var y = y_base + 20 + sin(float(j) / segments * PI) * 25
			points.append(Vector2(x, y))

		band.polygon = points

		# Aurora colors
		var aurora_colors = [
			Color(0.2, 0.8, 0.4, 0.08),   # Green
			Color(0.3, 0.6, 0.9, 0.06),   # Blue
			Color(0.6, 0.3, 0.8, 0.05),   # Purple
			Color(0.2, 0.7, 0.7, 0.04)    # Teal
		]
		band.color = aurora_colors[i % aurora_colors.size()]

		aurora_container.add_child(band)

	isometric_base.add_child(aurora_container)
	isometric_base.move_child(aurora_container, 0)  # Behind everything


func _animate_weather_effects(delta: float) -> void:
	## Animate weather particles with gentle floating motion
	var viewport_size = get_viewport_rect().size

	for p in weather_particles:
		if not is_instance_valid(p.node):
			continue

		# Gentle horizontal drift
		p.node.position.x += p.drift_speed * delta * 20

		# Vertical floating
		var float_offset = sin(hub_env_time * p.speed + p.phase) * p.amplitude * delta
		p.node.position.y = p.base_y + sin(hub_env_time * p.speed + p.phase) * 30

		# Wrap around screen
		if p.node.position.x > viewport_size.x + 50:
			p.node.position.x = -50
			p.base_y = randf_range(0, viewport_size.y)
		elif p.node.position.x < -50:
			p.node.position.x = viewport_size.x + 50
			p.base_y = randf_range(0, viewport_size.y)

		# Subtle alpha pulsing
		var pulse = sin(hub_env_time * 2.0 + p.phase) * 0.1 + 0.9
		p.node.modulate.a = pulse

	# Animate aurora if present
	var aurora = isometric_base.get_node_or_null("Aurora")
	if aurora:
		for band in aurora.get_children():
			# Gentle wave motion
			var wave = sin(hub_env_time * 0.3 + band.get_index() * 0.5) * 5
			band.position.y = wave

	# Subtle atmosphere overlay pulse
	if weather_overlay:
		var base_color = ATMOSPHERE_COLORS[atmosphere_level]
		var pulse = sin(hub_env_time * 0.5) * 0.02
		weather_overlay.color.a = base_color.a + pulse


func _create_hub_floor_patterns() -> void:
	# Concentric diamond rings - expanded for larger platform
	var ring_colors = [
		Color(0.15, 0.12, 0.22, 0.4),
		Color(0.16, 0.13, 0.24, 0.38),
		Color(0.18, 0.14, 0.26, 0.35),
		Color(0.19, 0.15, 0.27, 0.32),
		Color(0.2, 0.16, 0.28, 0.3),
		Color(0.22, 0.18, 0.3, 0.25)
	]
	var ring_sizes = [1300, 1100, 900, 700, 500, 300]

	for i in range(ring_sizes.size()):
		var ring = Polygon2D.new()
		var s = ring_sizes[i]
		ring.polygon = PackedVector2Array([
			Vector2(-s, 0), Vector2(0, -s * 0.5),
			Vector2(s, 0), Vector2(0, s * 0.5)
		])
		ring.color = ring_colors[i]
		hub_env_container.add_child(ring)

	# Add subtle star patterns on floor - expanded coverage
	var star_positions = [
		# Inner stars
		Vector2(-400, -150), Vector2(400, -150),
		Vector2(-350, 150), Vector2(350, 150),
		Vector2(-200, -300), Vector2(200, -300),
		Vector2(0, 350),
		# Middle ring stars
		Vector2(-750, -250), Vector2(750, -250),
		Vector2(-650, 300), Vector2(650, 300),
		Vector2(-450, -450), Vector2(450, -450),
		Vector2(0, 550),
		# Outer ring stars
		Vector2(-1000, -150), Vector2(1000, -150),
		Vector2(-900, 350), Vector2(900, 350),
		Vector2(-600, -550), Vector2(600, -550),
		Vector2(-200, 600), Vector2(200, 600)
	]
	for pos in star_positions:
		var star = Polygon2D.new()
		star.polygon = PackedVector2Array([
			Vector2(-12, 0), Vector2(-4, -4), Vector2(0, -12),
			Vector2(4, -4), Vector2(12, 0), Vector2(4, 4),
			Vector2(0, 12), Vector2(-4, 4)
		])
		star.position = pos
		star.color = Color(0.5, 0.4, 0.7, 0.2)
		hub_env_container.add_child(star)

	# Add mystical pathway markings connecting zones
	_create_pathway_markers()


func _create_pathway_markers() -> void:
	# Create glowing pathway lines connecting key zones
	var pathway_configs = [
		# Center to portals
		{"from": Vector2(0, 0), "to": Vector2(0, -550), "color": Color(0.4, 0.5, 0.8, 0.15)},  # North
		{"from": Vector2(0, 0), "to": Vector2(800, 0), "color": Color(0.7, 0.4, 0.5, 0.15)},   # East
		{"from": Vector2(0, 0), "to": Vector2(-800, 0), "color": Color(0.4, 0.7, 0.5, 0.15)},  # West
		{"from": Vector2(0, 0), "to": Vector2(0, 450), "color": Color(0.6, 0.5, 0.4, 0.15)},   # South
	]

	for config in pathway_configs:
		_create_dotted_pathway(config["from"], config["to"], config["color"])

	# Add exploration zone markers at expanded edges
	var zone_markers = [
		{"pos": Vector2(-1100, -350), "color": Color(0.5, 0.7, 0.9, 0.25), "label": "Discovery"},
		{"pos": Vector2(1100, -350), "color": Color(0.9, 0.6, 0.5, 0.25), "label": "Insight"},
		{"pos": Vector2(-1100, 400), "color": Color(0.5, 0.9, 0.6, 0.25), "label": "Serenity"},
		{"pos": Vector2(1100, 400), "color": Color(0.8, 0.5, 0.8, 0.25), "label": "Creativity"},
	]

	for marker_data in zone_markers:
		_create_exploration_zone_marker(marker_data)


func _create_dotted_pathway(from_pos: Vector2, to_pos: Vector2, color: Color) -> void:
	var direction = (to_pos - from_pos).normalized()
	var distance = from_pos.distance_to(to_pos)
	var dot_spacing = 40.0
	var num_dots = int(distance / dot_spacing)

	for i in range(1, num_dots):  # Skip first dot (at center)
		var t = float(i) / num_dots
		var pos = from_pos.lerp(to_pos, t)

		var dot = Polygon2D.new()
		var size = 4.0 - t * 2.0  # Dots get smaller toward edges
		dot.polygon = _create_soft_circle(size, 6)
		dot.position = pos
		dot.color = color
		dot.color.a = 0.3 - t * 0.2  # Fade toward edges
		hub_env_container.add_child(dot)


func _create_exploration_zone_marker(marker_data: Dictionary) -> void:
	var pos = marker_data["pos"]
	var color = marker_data["color"]

	# Outer glow ring
	var outer_ring = Polygon2D.new()
	outer_ring.polygon = _create_soft_circle(50, 12)
	outer_ring.position = pos
	outer_ring.color = color
	outer_ring.color.a = 0.1
	hub_env_container.add_child(outer_ring)

	# Inner glow
	var inner = Polygon2D.new()
	inner.polygon = _create_soft_circle(25, 10)
	inner.position = pos
	inner.color = color
	inner.color.a = 0.2
	hub_env_container.add_child(inner)

	# Center crystal
	var crystal = Polygon2D.new()
	crystal.polygon = PackedVector2Array([
		Vector2(0, -15), Vector2(8, -5), Vector2(8, 5),
		Vector2(0, 15), Vector2(-8, 5), Vector2(-8, -5)
	])
	crystal.position = pos
	crystal.color = color
	crystal.color.a = 0.4
	hub_env_container.add_child(crystal)


func _create_hub_glow_orbs() -> void:
	# Subtle floating orbs - expanded for larger platform
	var orb_positions = [
		# Inner ring
		{"pos": Vector2(-550, -180), "color": Color(0.6, 0.65, 0.95, 0.2), "size": 8},
		{"pos": Vector2(550, -180), "color": Color(0.65, 0.6, 0.9, 0.2), "size": 8},
		{"pos": Vector2(-500, 250), "color": Color(0.5, 0.75, 0.65, 0.18), "size": 7},
		{"pos": Vector2(500, 250), "color": Color(0.75, 0.55, 0.6, 0.18), "size": 7},
		{"pos": Vector2(0, -380), "color": Color(0.6, 0.6, 0.85, 0.15), "size": 6},
		# Outer ring - new exploration zones
		{"pos": Vector2(-950, -280), "color": Color(0.5, 0.7, 0.9, 0.18), "size": 9},
		{"pos": Vector2(950, -280), "color": Color(0.9, 0.6, 0.5, 0.18), "size": 9},
		{"pos": Vector2(-900, 380), "color": Color(0.5, 0.9, 0.6, 0.16), "size": 8},
		{"pos": Vector2(900, 380), "color": Color(0.8, 0.5, 0.8, 0.16), "size": 8},
		# Far corners
		{"pos": Vector2(-1200, -100), "color": Color(0.55, 0.65, 0.85, 0.12), "size": 7},
		{"pos": Vector2(1200, -100), "color": Color(0.85, 0.55, 0.6, 0.12), "size": 7},
		{"pos": Vector2(-1150, 200), "color": Color(0.55, 0.85, 0.65, 0.12), "size": 6},
		{"pos": Vector2(1150, 200), "color": Color(0.75, 0.55, 0.75, 0.12), "size": 6}
	]

	for orb_data in orb_positions:
		var orb_group = Node2D.new()
		orb_group.position = orb_data["pos"]

		# Soft outer glow - subtle
		var glow = Polygon2D.new()
		var gs = orb_data["size"] * 1.8
		glow.polygon = _create_soft_circle(gs, 10)
		var glow_color = orb_data["color"]
		glow_color.a = 0.08
		glow.color = glow_color
		orb_group.add_child(glow)

		# Inner orb - small and subtle
		var orb = Polygon2D.new()
		orb.polygon = _create_soft_circle(orb_data["size"], 8)
		orb.color = orb_data["color"]
		orb_group.add_child(orb)

		hub_env_container.add_child(orb_group)
		hub_orbs.append({
			"node": orb_group,
			"base_pos": orb_data["pos"],
			"phase": randf() * TAU,
			"speed": randf_range(0.2, 0.4),
			"range": randf_range(5, 10)
		})


func _create_soft_circle(radius: float, segments: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(segments):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	return points


func _create_hub_floating_particles() -> void:
	# Small floating sparkles/particles - expanded for larger platform
	for i in range(35):  # More particles for bigger area
		var particle = Polygon2D.new()
		var size = randf_range(2, 5)
		particle.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(0, -size),
			Vector2(size, 0), Vector2(0, size)
		])
		particle.position = Vector2(
			randf_range(-1250, 1250),
			randf_range(-620, 620)
		)
		var brightness = randf_range(0.4, 0.8)
		particle.color = Color(0.7, 0.65, 0.9, brightness)
		particle.z_index = 20
		hub_env_container.add_child(particle)

		hub_particles.append({
			"polygon": particle,
			"base_pos": particle.position,
			"base_alpha": brightness,
			"speed": randf_range(0.5, 1.5),
			"range": randf_range(15, 30),
			"phase": randf() * TAU
		})


func _create_hub_path_decorations() -> void:
	# Small glowing markers along paths - extended for larger platform
	var path_marker_positions = [
		# North path
		Vector2(0, -150), Vector2(0, -280), Vector2(0, -410), Vector2(0, -540),
		# East path
		Vector2(250, 0), Vector2(500, 0), Vector2(750, 0), Vector2(1000, 0),
		# West path
		Vector2(-250, 0), Vector2(-500, 0), Vector2(-750, 0), Vector2(-1000, 0),
		# South path
		Vector2(0, 150), Vector2(0, 280), Vector2(0, 410),
		# Diagonal paths to new zones
		Vector2(-300, -200), Vector2(-550, -350), Vector2(-800, -500),
		Vector2(300, -200), Vector2(550, -350), Vector2(800, -500),
		Vector2(-350, 180), Vector2(-600, 320), Vector2(-850, 460),
		Vector2(350, 180), Vector2(600, 320), Vector2(850, 460)
	]

	for pos in path_marker_positions:
		var marker = Polygon2D.new()
		marker.polygon = PackedVector2Array([
			Vector2(-6, 0), Vector2(0, -6), Vector2(6, 0), Vector2(0, 6)
		])
		marker.position = pos
		marker.color = Color(0.5, 0.4, 0.7, 0.35)
		hub_env_container.add_child(marker)

	# Add small lanterns near portals
	var lantern_positions = [
		Vector2(-60, -430), Vector2(60, -430),  # North
		Vector2(680, -50), Vector2(680, 50),    # East
		Vector2(-680, -50), Vector2(-680, 50),  # West
		Vector2(-60, 430), Vector2(60, 430)     # South
	]

	for pos in lantern_positions:
		_create_lantern(pos)


func _create_lantern(pos: Vector2) -> void:
	var lantern = Node2D.new()
	lantern.position = pos

	# Post
	var post = Polygon2D.new()
	post.polygon = PackedVector2Array([
		Vector2(-4, 0), Vector2(-4, -35), Vector2(4, -35), Vector2(4, 0)
	])
	post.color = Color(0.25, 0.2, 0.32, 1.0)
	lantern.add_child(post)

	# Lantern body
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-10, -35), Vector2(-8, -55), Vector2(8, -55), Vector2(10, -35)
	])
	body.color = Color(0.3, 0.25, 0.4, 0.9)
	lantern.add_child(body)

	# Lantern glow
	var glow = Polygon2D.new()
	glow.polygon = _create_soft_circle(18, 8)
	glow.position = Vector2(0, -45)
	glow.color = Color(0.9, 0.75, 0.4, 0.4)
	lantern.add_child(glow)

	hub_env_container.add_child(lantern)


func _create_hub_center_enhancement() -> void:
	# Add enhancement around center crystal
	# Rotating rune ring
	var rune_ring = Node2D.new()
	rune_ring.name = "RuneRing"
	rune_ring.position = Vector2(0, -60)

	for i in range(8):
		var angle = (float(i) / 8) * TAU
		var radius = 100
		var rune = Polygon2D.new()
		rune.polygon = PackedVector2Array([
			Vector2(-8, 0), Vector2(-3, -8), Vector2(3, -8),
			Vector2(8, 0), Vector2(3, 8), Vector2(-3, 8)
		])
		rune.position = Vector2(cos(angle) * radius, sin(angle) * radius * 0.5)
		rune.rotation = angle
		rune.color = Color(0.6, 0.5, 0.9, 0.4)
		rune_ring.add_child(rune)

	hub_env_container.add_child(rune_ring)

	# Add pulsing energy lines from center
	for i in range(4):
		var angle = (float(i) / 4) * TAU + PI/4
		var line = Polygon2D.new()
		var length = 180
		var end_x = cos(angle) * length
		var end_y = sin(angle) * length * 0.5
		line.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(end_x - 5, end_y - 2),
			Vector2(end_x, end_y), Vector2(end_x - 5, end_y + 2)
		])
		line.position = Vector2(0, -60)
		line.color = Color(0.5, 0.4, 0.8, 0.2)
		hub_env_container.add_child(line)


func _create_progress_indicators() -> void:
	## Create visual indicators for player progress: streak flames and evolution ring

	# Get current stats
	var current_streak = GameManager.player_data.get("current_streak", 0)
	var evolution_level = GameManager.get_evolution_level() if GameManager else 1
	var evolution_progress = GameManager.get_evolution_progress() if GameManager else 0.0

	# === STREAK FLAMES ===
	# Positioned around the center crystal, more flames = higher streak
	var flame_count = min(current_streak, 12)  # Max 12 flames
	var flame_radius = 140

	for i in range(flame_count):
		var angle = (float(i) / max(flame_count, 1)) * TAU - PI/2
		var flame_pos = Vector2(cos(angle) * flame_radius, sin(angle) * flame_radius * 0.5 - 60)

		var flame_container = Node2D.new()
		flame_container.name = "StreakFlame_" + str(i)
		flame_container.position = flame_pos

		# Flame base (orange/yellow gradient effect with polygons)
		var flame_height = 20 + min(current_streak, 10) * 2  # Grows with streak
		var flame_width = 8

		# Outer flame (orange)
		var outer_flame = Polygon2D.new()
		outer_flame.polygon = PackedVector2Array([
			Vector2(-flame_width, 0),
			Vector2(-flame_width * 0.6, -flame_height * 0.4),
			Vector2(-flame_width * 0.3, -flame_height * 0.7),
			Vector2(0, -flame_height),
			Vector2(flame_width * 0.3, -flame_height * 0.7),
			Vector2(flame_width * 0.6, -flame_height * 0.4),
			Vector2(flame_width, 0)
		])
		outer_flame.color = Color(0.95, 0.5, 0.1, 0.8)
		flame_container.add_child(outer_flame)

		# Inner flame (yellow)
		var inner_flame = Polygon2D.new()
		var inner_height = flame_height * 0.7
		var inner_width = flame_width * 0.5
		inner_flame.polygon = PackedVector2Array([
			Vector2(-inner_width, 0),
			Vector2(-inner_width * 0.5, -inner_height * 0.5),
			Vector2(0, -inner_height),
			Vector2(inner_width * 0.5, -inner_height * 0.5),
			Vector2(inner_width, 0)
		])
		inner_flame.color = Color(1.0, 0.85, 0.2, 0.9)
		flame_container.add_child(inner_flame)

		# Core (white-hot)
		var core = Polygon2D.new()
		var core_height = flame_height * 0.4
		var core_width = flame_width * 0.25
		core.polygon = PackedVector2Array([
			Vector2(-core_width, 0),
			Vector2(0, -core_height),
			Vector2(core_width, 0)
		])
		core.color = Color(1.0, 1.0, 0.9, 0.95)
		flame_container.add_child(core)

		flame_container.z_index = 5
		hub_env_container.add_child(flame_container)

		streak_flames.append({
			"node": flame_container,
			"base_pos": flame_pos,
			"phase": randf() * TAU,
			"flicker_speed": randf_range(8.0, 12.0)
		})

	# Streak counter display (if streak > 0)
	if current_streak > 0:
		var streak_label = Label.new()
		streak_label.name = "StreakLabel"
		streak_label.text = str(current_streak) + " day streak"
		streak_label.add_theme_font_size_override("font_size", 14)
		streak_label.add_theme_color_override("font_color", Color(0.95, 0.7, 0.3))
		streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		streak_label.position = Vector2(-60, 80)
		streak_label.z_index = 10

		var streak_bg = ColorRect.new()
		streak_bg.color = Color(0.1, 0.08, 0.15, 0.7)
		streak_bg.custom_minimum_size = Vector2(120, 24)
		streak_bg.position = Vector2(-60, 78)
		streak_bg.z_index = 9

		hub_env_container.add_child(streak_bg)
		hub_env_container.add_child(streak_label)

	# === EVOLUTION RING ===
	# A ring around the platform that fills based on evolution progress
	evolution_ring = Node2D.new()
	evolution_ring.name = "EvolutionRing"
	evolution_ring.position = Vector2(0, 0)

	var ring_radius = 200
	var ring_thickness = 6
	var segment_count = 20

	# Background ring (dark)
	for i in range(segment_count):
		var start_angle = (float(i) / segment_count) * TAU - PI/2
		var end_angle = (float(i + 1) / segment_count) * TAU - PI/2

		var segment = Polygon2D.new()
		var outer_r = ring_radius + ring_thickness
		var inner_r = ring_radius - ring_thickness

		segment.polygon = PackedVector2Array([
			Vector2(cos(start_angle) * inner_r, sin(start_angle) * inner_r * 0.5),
			Vector2(cos(start_angle) * outer_r, sin(start_angle) * outer_r * 0.5),
			Vector2(cos(end_angle) * outer_r, sin(end_angle) * outer_r * 0.5),
			Vector2(cos(end_angle) * inner_r, sin(end_angle) * inner_r * 0.5)
		])
		segment.color = Color(0.15, 0.12, 0.2, 0.5)
		evolution_ring.add_child(segment)

	# Progress ring (glowing based on evolution)
	var filled_segments = int(evolution_progress * segment_count)
	var level_colors = [
		Color(0.5, 0.5, 0.6),    # Level 1 - Gray
		Color(0.4, 0.7, 0.5),    # Level 2 - Green
		Color(0.3, 0.6, 0.9),    # Level 3 - Blue
		Color(0.7, 0.5, 0.9),    # Level 4 - Purple
		Color(0.9, 0.7, 0.3),    # Level 5 - Gold
		Color(0.95, 0.4, 0.4),   # Level 6+ - Red/Fire
	]
	var ring_color = level_colors[min(evolution_level - 1, level_colors.size() - 1)]

	for i in range(filled_segments):
		var start_angle = (float(i) / segment_count) * TAU - PI/2
		var end_angle = (float(i + 1) / segment_count) * TAU - PI/2

		var segment = Polygon2D.new()
		segment.name = "EvoSegment_" + str(i)
		var outer_r = ring_radius + ring_thickness
		var inner_r = ring_radius - ring_thickness

		segment.polygon = PackedVector2Array([
			Vector2(cos(start_angle) * inner_r, sin(start_angle) * inner_r * 0.5),
			Vector2(cos(start_angle) * outer_r, sin(start_angle) * outer_r * 0.5),
			Vector2(cos(end_angle) * outer_r, sin(end_angle) * outer_r * 0.5),
			Vector2(cos(end_angle) * inner_r, sin(end_angle) * inner_r * 0.5)
		])
		segment.color = ring_color
		evolution_ring.add_child(segment)

		evolution_segments.append({
			"polygon": segment,
			"base_color": ring_color,
			"index": i
		})

	evolution_ring.z_index = 2
	hub_env_container.add_child(evolution_ring)

	# Evolution level indicator
	var evo_label = Label.new()
	evo_label.name = "EvoLabel"
	evo_label.text = "Evo " + str(evolution_level)
	evo_label.add_theme_font_size_override("font_size", 12)
	evo_label.add_theme_color_override("font_color", ring_color)
	evo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	evo_label.position = Vector2(-25, -220)
	evo_label.z_index = 10
	hub_env_container.add_child(evo_label)


func _animate_hub_environment(delta: float) -> void:
	hub_env_time += delta

	# Animate glow orbs
	for orb in hub_orbs:
		var offset_y = sin(hub_env_time * orb.speed + orb.phase) * orb.range
		orb.node.position = orb.base_pos + Vector2(0, offset_y)

	# Animate floating particles
	for particle in hub_particles:
		var offset_x = sin(hub_env_time * particle.speed + particle.phase) * particle.range
		var offset_y = cos(hub_env_time * particle.speed * 0.7 + particle.phase) * particle.range * 0.5
		particle.polygon.position = particle.base_pos + Vector2(offset_x, offset_y)

		# Twinkle effect
		var twinkle = sin(hub_env_time * 2.0 + particle.phase)
		particle.polygon.color.a = particle.base_alpha * (0.7 + twinkle * 0.3)

	# Rotate rune ring slowly
	var rune_ring = hub_env_container.get_node_or_null("RuneRing")
	if rune_ring:
		rune_ring.rotation = hub_env_time * 0.1

	# Animate streak flames
	for flame in streak_flames:
		if is_instance_valid(flame.node):
			# Flickering movement
			var flicker_x = sin(hub_env_time * flame.flicker_speed + flame.phase) * 2
			var flicker_y = sin(hub_env_time * flame.flicker_speed * 1.3 + flame.phase) * 3
			flame.node.position = flame.base_pos + Vector2(flicker_x, flicker_y)

			# Scale pulsing
			var scale_pulse = 1.0 + sin(hub_env_time * flame.flicker_speed * 0.8) * 0.1
			flame.node.scale = Vector2(scale_pulse, scale_pulse)

	# Animate evolution ring segments (subtle glow pulse)
	for seg in evolution_segments:
		if is_instance_valid(seg.polygon):
			var pulse = 0.8 + sin(hub_env_time * 2.0 + seg.index * 0.3) * 0.2
			var color = seg.base_color
			seg.polygon.color = Color(color.r, color.g, color.b, color.a * pulse)

	# Animate weather/atmosphere effects
	_animate_weather_effects(delta)


# =============================================================================
# TUTORIAL TOOLTIPS
# =============================================================================

var tutorial_tooltip_panel: PanelContainer = null
var tutorial_tooltip_queue: Array = []
var tutorial_tooltip_active: bool = false
var tutorial_highlight: Control = null

const TUTORIAL_TIPS = {
	"hub_focus_chamber": {
		"title": "Focus Chamber",
		"text": "Start 25-minute deep work sessions here.\nPress F to quickly enter Focus Mode.",
		"position": "focus_chamber",
		"shortcut": "F"
	},
	"hub_daily_rituals": {
		"title": "Daily Rituals",
		"text": "Track your habits and build streaks.\nPress H to open your habits anywhere.",
		"position": "top_left",
		"shortcut": "H"
	},
	"hub_journal": {
		"title": "Journal",
		"text": "Review your focus session reflections.\nPress J to open your journal.",
		"position": "top_right",
		"shortcut": "J"
	},
	"hub_daily_summary": {
		"title": "Daily Summary",
		"text": "See your progress at a glance.\nPress E for a quick overview.",
		"position": "center",
		"shortcut": "E"
	},
	"hub_portals": {
		"title": "Region Portals",
		"text": "Explore different areas of your mindscape.\nMore regions unlock as you progress.",
		"position": "portal_north",
		"shortcut": ""
	}
}


func _check_tutorial_tooltips() -> void:
	# Don't show during onboarding
	if is_onboarding_active:
		return

	# Queue up unseen tutorials
	tutorial_tooltip_queue.clear()

	# Check which tutorials haven't been seen
	var tips_to_show = ["hub_focus_chamber", "hub_daily_rituals", "hub_journal", "hub_daily_summary"]

	for tip_id in tips_to_show:
		if not GameManager.has_seen_tutorial(tip_id):
			tutorial_tooltip_queue.append(tip_id)

	# Show first tooltip after a delay
	if tutorial_tooltip_queue.size() > 0:
		await get_tree().create_timer(1.5).timeout
		if not is_onboarding_active:
			_show_next_tutorial_tooltip()


func _show_next_tutorial_tooltip() -> void:
	if tutorial_tooltip_queue.is_empty():
		tutorial_tooltip_active = false
		return

	var tip_id = tutorial_tooltip_queue.pop_front()
	var tip_data = TUTORIAL_TIPS.get(tip_id, {})

	if tip_data.is_empty():
		_show_next_tutorial_tooltip()
		return

	tutorial_tooltip_active = true
	_create_tutorial_tooltip(tip_id, tip_data)


func _create_tutorial_tooltip(tip_id: String, tip_data: Dictionary) -> void:
	# Remove existing tooltip
	if tutorial_tooltip_panel:
		tutorial_tooltip_panel.queue_free()
	if tutorial_highlight:
		tutorial_highlight.queue_free()

	# Create highlight overlay (subtle darkening except around the target)
	tutorial_highlight = Control.new()
	tutorial_highlight.name = "TutorialHighlight"
	tutorial_highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tutorial_highlight)

	var dim_bg = ColorRect.new()
	dim_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_bg.color = Color(0, 0, 0, 0.3)
	dim_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_highlight.add_child(dim_bg)

	# Create tooltip panel
	tutorial_tooltip_panel = PanelContainer.new()
	tutorial_tooltip_panel.name = "TutorialTooltip"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.98)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = Color(0.5, 0.7, 0.9, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	tutorial_tooltip_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	tutorial_tooltip_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title with shortcut
	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	vbox.add_child(title_row)

	var title = Label.new()
	title.text = tip_data.get("title", "Tip")
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 0.9))
	title_row.add_child(title)

	if tip_data.get("shortcut", "") != "":
		var shortcut_badge = Label.new()
		shortcut_badge.text = "[" + tip_data.shortcut + "]"
		shortcut_badge.add_theme_font_size_override("font_size", 16)
		shortcut_badge.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
		title_row.add_child(shortcut_badge)

	# Description
	var desc = Label.new()
	desc.text = tip_data.get("text", "")
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)

	# Progress indicator
	var remaining = tutorial_tooltip_queue.size()
	if remaining > 0:
		var progress = Label.new()
		progress.text = str(remaining) + " more tip" + ("s" if remaining > 1 else "") + " to go"
		progress.add_theme_font_size_override("font_size", 13)
		progress.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		vbox.add_child(progress)

	# Button row
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(btn_row)

	if tutorial_tooltip_queue.size() > 0:
		var skip_btn = Button.new()
		skip_btn.text = "Skip All"
		skip_btn.custom_minimum_size = Vector2(80, 36)
		skip_btn.add_theme_font_size_override("font_size", 14)
		skip_btn.pressed.connect(_skip_all_tutorials)
		btn_row.add_child(skip_btn)

	var got_it_btn = Button.new()
	got_it_btn.text = "Got it!"
	got_it_btn.custom_minimum_size = Vector2(90, 40)
	got_it_btn.add_theme_font_size_override("font_size", 16)
	got_it_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	got_it_btn.pressed.connect(_dismiss_tutorial_tooltip.bind(tip_id))
	btn_row.add_child(got_it_btn)

	# Position the tooltip based on the tip type
	tutorial_tooltip_panel.custom_minimum_size = Vector2(320, 0)
	_position_tutorial_tooltip(tip_data.get("position", "center"))

	add_child(tutorial_tooltip_panel)

	# Fade in
	tutorial_tooltip_panel.modulate.a = 0.0
	tutorial_highlight.modulate.a = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(tutorial_tooltip_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(tutorial_highlight, "modulate:a", 1.0, 0.3)


func _position_tutorial_tooltip(position_hint: String) -> void:
	var viewport_size = get_viewport_rect().size

	match position_hint:
		"focus_chamber":
			# Position near focus chamber (left side of hub)
			tutorial_tooltip_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
			tutorial_tooltip_panel.position = Vector2(80, -80)
		"top_left":
			tutorial_tooltip_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
			tutorial_tooltip_panel.position = Vector2(20, 80)
		"top_right":
			tutorial_tooltip_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			tutorial_tooltip_panel.position = Vector2(-340, 80)
		"portal_north":
			tutorial_tooltip_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
			tutorial_tooltip_panel.position = Vector2(-160, 100)
		_:  # center
			tutorial_tooltip_panel.set_anchors_preset(Control.PRESET_CENTER)
			tutorial_tooltip_panel.position = Vector2(-160, -80)


func _dismiss_tutorial_tooltip(tip_id: String) -> void:
	# Mark as seen
	GameManager.mark_tutorial_seen(tip_id)

	# Fade out
	var tween = create_tween()
	tween.set_parallel(true)
	if tutorial_tooltip_panel:
		tween.tween_property(tutorial_tooltip_panel, "modulate:a", 0.0, 0.2)
	if tutorial_highlight:
		tween.tween_property(tutorial_highlight, "modulate:a", 0.0, 0.2)

	tween.tween_callback(func():
		if tutorial_tooltip_panel:
			tutorial_tooltip_panel.queue_free()
			tutorial_tooltip_panel = null
		if tutorial_highlight:
			tutorial_highlight.queue_free()
			tutorial_highlight = null

		# Show next tooltip after brief delay
		await get_tree().create_timer(0.5).timeout
		_show_next_tutorial_tooltip()
	)


func _skip_all_tutorials() -> void:
	# Mark all remaining tutorials as seen
	for tip_id in tutorial_tooltip_queue:
		GameManager.mark_tutorial_seen(tip_id)
	tutorial_tooltip_queue.clear()

	# Dismiss current tooltip
	if tutorial_tooltip_panel:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(tutorial_tooltip_panel, "modulate:a", 0.0, 0.2)
		if tutorial_highlight:
			tween.tween_property(tutorial_highlight, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func():
			if tutorial_tooltip_panel:
				tutorial_tooltip_panel.queue_free()
				tutorial_tooltip_panel = null
			if tutorial_highlight:
				tutorial_highlight.queue_free()
				tutorial_highlight = null
		)

	tutorial_tooltip_active = false


# =============================================================================
# EXPERIENCE SHOP VISUAL
# =============================================================================

var shop_visual: Node2D = null

func _create_experience_shop_visual() -> void:
	# Create shop kiosk/stand visual at the shop position
	var shop_pos = zone_positions.get("ExperienceShop", Vector2(300, 350))

	shop_visual = Node2D.new()
	shop_visual.name = "ExperienceShopVisual"
	shop_visual.position = shop_pos

	# Base platform (circular)
	var platform = Polygon2D.new()
	platform.name = "Platform"
	var platform_points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		platform_points.append(Vector2(cos(angle) * 50, sin(angle) * 25))
	platform.polygon = platform_points
	platform.color = Color(0.3, 0.25, 0.5, 0.8)
	shop_visual.add_child(platform)

	# Platform glow ring
	var glow_ring = Polygon2D.new()
	glow_ring.name = "GlowRing"
	var ring_points = PackedVector2Array()
	for i in range(16):
		var angle = (i / 16.0) * TAU
		ring_points.append(Vector2(cos(angle) * 55, sin(angle) * 28))
	glow_ring.polygon = ring_points
	glow_ring.color = Color(0.9, 0.7, 0.3, 0.15)
	shop_visual.add_child(glow_ring)

	# Shop stand/kiosk
	var stand = Polygon2D.new()
	stand.name = "Stand"
	stand.polygon = PackedVector2Array([
		Vector2(-25, -60), Vector2(25, -60),
		Vector2(30, 0), Vector2(-30, 0)
	])
	stand.color = Color(0.4, 0.35, 0.6, 0.9)
	shop_visual.add_child(stand)

	# Stand front panel
	var front_panel = Polygon2D.new()
	front_panel.name = "FrontPanel"
	front_panel.polygon = PackedVector2Array([
		Vector2(-20, -55), Vector2(20, -55),
		Vector2(22, -10), Vector2(-22, -10)
	])
	front_panel.color = Color(0.15, 0.12, 0.25, 0.95)
	shop_visual.add_child(front_panel)

	# XP display area (glowing screen)
	var display = Polygon2D.new()
	display.name = "Display"
	display.polygon = PackedVector2Array([
		Vector2(-15, -50), Vector2(15, -50),
		Vector2(15, -20), Vector2(-15, -20)
	])
	display.color = Color(0.4, 0.8, 0.6, 0.7)
	shop_visual.add_child(display)

	# Shop sign floating above
	var sign_base = Polygon2D.new()
	sign_base.name = "SignBase"
	sign_base.polygon = PackedVector2Array([
		Vector2(-35, -100), Vector2(35, -100),
		Vector2(35, -75), Vector2(-35, -75)
	])
	sign_base.color = Color(0.5, 0.4, 0.7, 0.9)
	shop_visual.add_child(sign_base)

	# Sign glow
	var sign_glow = Polygon2D.new()
	sign_glow.name = "SignGlow"
	sign_glow.polygon = PackedVector2Array([
		Vector2(-40, -105), Vector2(40, -105),
		Vector2(40, -70), Vector2(-40, -70)
	])
	sign_glow.color = Color(0.9, 0.7, 0.3, 0.1)
	sign_glow.z_index = -1
	shop_visual.add_child(sign_glow)

	# Floating coins/gems decoration
	for i in range(3):
		var gem = Polygon2D.new()
		gem.name = "Gem%d" % i
		var offset_x = (i - 1) * 25
		gem.position = Vector2(offset_x, -115 - i * 5)
		gem.polygon = PackedVector2Array([
			Vector2(0, -8), Vector2(6, 0),
			Vector2(0, 8), Vector2(-6, 0)
		])
		var gem_colors = [
			Color(0.9, 0.3, 0.3, 0.8),  # Red (courage)
			Color(0.3, 0.9, 0.5, 0.8),  # Green (vitality)
			Color(0.4, 0.5, 0.9, 0.8)   # Blue (wisdom)
		]
		gem.color = gem_colors[i]
		shop_visual.add_child(gem)

	# Add sparkle particles
	for i in range(5):
		var sparkle = Polygon2D.new()
		sparkle.name = "Sparkle%d" % i
		var angle = (i / 5.0) * TAU
		sparkle.position = Vector2(cos(angle) * 40, sin(angle) * 20 - 35)
		sparkle.polygon = PackedVector2Array([
			Vector2(0, -3), Vector2(2, 0),
			Vector2(0, 3), Vector2(-2, 0)
		])
		sparkle.color = Color(1.0, 0.9, 0.5, 0.0)  # Starts invisible, animated
		shop_visual.add_child(sparkle)

	# Add to the zones container
	var zones_node = isometric_base.get_node_or_null("Zones")
	if zones_node:
		zones_node.add_child(shop_visual)
	else:
		isometric_base.add_child(shop_visual)


func _animate_shop_visual() -> void:
	if not shop_visual:
		return

	# Animate display glow
	var display = shop_visual.get_node_or_null("Display") as Polygon2D
	if display:
		var pulse = (sin(crystal_pulse_time * 2.0) + 1.0) / 2.0
		display.color.a = 0.5 + pulse * 0.3

	# Animate sign glow
	var sign_glow = shop_visual.get_node_or_null("SignGlow") as Polygon2D
	if sign_glow:
		var slow_pulse = (sin(crystal_pulse_time * 1.5) + 1.0) / 2.0
		sign_glow.color.a = 0.1 + slow_pulse * 0.1

	# Animate glow ring
	var glow_ring = shop_visual.get_node_or_null("GlowRing") as Polygon2D
	if glow_ring:
		var ring_pulse = (sin(crystal_pulse_time * 3.0) + 1.0) / 2.0
		glow_ring.color.a = 0.1 + ring_pulse * 0.1

	# Animate floating gems
	for i in range(3):
		var gem = shop_visual.get_node_or_null("Gem%d" % i) as Polygon2D
		if gem:
			var base_y = -115 - i * 5
			gem.position.y = base_y + sin(crystal_pulse_time * 2.0 + i * 0.8) * 4
			gem.rotation = sin(crystal_pulse_time * 1.5 + i * 1.2) * 0.15

	# Animate sparkles
	for i in range(5):
		var sparkle = shop_visual.get_node_or_null("Sparkle%d" % i) as Polygon2D
		if sparkle:
			var phase = crystal_pulse_time * 2.5 + (i * TAU / 5.0)
			var sparkle_pulse = (sin(phase) + 1.0) / 2.0
			sparkle.color.a = sparkle_pulse * 0.6
			sparkle.scale = Vector2(0.7 + sparkle_pulse * 0.5, 0.7 + sparkle_pulse * 0.5)


# =============================================================================
# EXPERIENCE SHOP
# =============================================================================

var shop_panel: Control = null
var shop_current_category: int = 0
var shop_item_grid: GridContainer = null
var shop_detail_panel: Control = null


func _open_experience_shop() -> void:
	if shop_panel:
		return

	interaction_prompt.visible = false
	in_zone_panel = true

	# Create main shop panel
	shop_panel = Panel.new()
	shop_panel.set_anchors_preset(Control.PRESET_CENTER)
	shop_panel.custom_minimum_size = Vector2(1000, 650)
	shop_panel.position = Vector2(-500, -325)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	style.border_color = Color(0.6, 0.5, 0.3, 0.8)
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	shop_panel.add_theme_stylebox_override("panel", style)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 15)
	main_vbox.offset_left = 25
	main_vbox.offset_top = 25
	main_vbox.offset_right = -25
	main_vbox.offset_bottom = -25
	shop_panel.add_child(main_vbox)

	# Header with title and XP display
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(header_hbox)

	var title = Label.new()
	title.text = "Experience Shop"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)

	# XP display
	var xp_hbox = HBoxContainer.new()
	xp_hbox.add_theme_constant_override("separation", 15)
	header_hbox.add_child(xp_hbox)
	_create_xp_display(xp_hbox)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(_close_experience_shop)
	header_hbox.add_child(close_btn)

	# Content area (sidebar + items)
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(content_hbox)

	# Category sidebar
	var sidebar = VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(180, 0)
	sidebar.add_theme_constant_override("separation", 8)
	content_hbox.add_child(sidebar)

	var categories = [
		{"id": ShopManager.ItemCategory.COSMETIC_COLOR, "name": "Skin Colors", "icon": "🎨"},
		{"id": ShopManager.ItemCategory.COSMETIC_OUTFIT, "name": "Outfits", "icon": "👕"},
		{"id": ShopManager.ItemCategory.COSMETIC_HAT, "name": "Hats", "icon": "🎩"},
		{"id": ShopManager.ItemCategory.COSMETIC_CAPE, "name": "Capes", "icon": "🦸"},
		{"id": ShopManager.ItemCategory.COSMETIC_GLASSES, "name": "Glasses", "icon": "👓"},
		{"id": ShopManager.ItemCategory.COSMETIC_AURA, "name": "Auras", "icon": "✨"},
		{"id": ShopManager.ItemCategory.ROOM_DECOR, "name": "Room Decor", "icon": "🏠"},
	]

	for cat in categories:
		var btn = Button.new()
		btn.text = cat.icon + " " + cat.name
		btn.custom_minimum_size = Vector2(0, 45)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_shop_category_selected.bind(cat.id))
		btn.name = "CategoryBtn_" + str(cat.id)
		sidebar.add_child(btn)

	# Items scroll area
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_hbox.add_child(scroll)

	shop_item_grid = GridContainer.new()
	shop_item_grid.name = "ShopGrid"
	shop_item_grid.columns = 4
	shop_item_grid.add_theme_constant_override("h_separation", 15)
	shop_item_grid.add_theme_constant_override("v_separation", 15)
	scroll.add_child(shop_item_grid)

	add_child(shop_panel)

	# Load first category
	_on_shop_category_selected(ShopManager.ItemCategory.COSMETIC_COLOR)


func _create_xp_display(container: HBoxContainer) -> void:
	var aspect_xp = GameManager.player_data.get("aspect_xp", {})
	var aspects = ["discipline", "courage", "creativity"]

	for aspect in aspects:
		var xp_value = aspect_xp.get(aspect, 0)
		var label = Label.new()
		label.text = aspect.capitalize() + ": " + str(xp_value)
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", _get_aspect_color(aspect))
		container.add_child(label)


func _get_aspect_color(aspect: String) -> Color:
	match aspect:
		"discipline": return Color(0.4, 0.6, 0.9)
		"courage": return Color(0.9, 0.5, 0.3)
		"creativity": return Color(0.7, 0.4, 0.9)
		"compassion": return Color(0.5, 0.8, 0.6)
		"wisdom": return Color(0.9, 0.8, 0.4)
		"vitality": return Color(0.4, 0.9, 0.5)
	return Color(0.7, 0.7, 0.7)


func _on_shop_category_selected(category: int) -> void:
	shop_current_category = category

	# Update button styles
	if shop_panel:
		var sidebar = shop_panel.get_node_or_null("VBoxContainer/HBoxContainer/VBoxContainer")
		if sidebar:
			for child in sidebar.get_children():
				if child is Button:
					var btn_cat = int(child.name.replace("CategoryBtn_", ""))
					if btn_cat == category:
						child.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
					else:
						child.remove_theme_color_override("font_color")

	# Clear and populate items grid
	if not shop_item_grid:
		return

	for child in shop_item_grid.get_children():
		child.queue_free()

	if not ShopManager:
		return

	var items = ShopManager.get_catalog_by_category(category)
	for item in items:
		var item_id = item.get("id", "")
		_create_shop_item_card(item_id, item)


func _create_shop_item_card(item_id: String, item: Dictionary) -> void:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(165, 180)

	var is_owned = ShopManager.is_owned(item_id)
	var rarity = item.get("rarity", ShopManager.ItemRarity.COMMON)

	# Card style based on rarity
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.12, 0.18, 1.0)

	match rarity:
		ShopManager.ItemRarity.UNCOMMON:
			card_style.border_color = Color(0.3, 0.6, 0.3, 0.8)
		ShopManager.ItemRarity.RARE:
			card_style.border_color = Color(0.3, 0.5, 0.9, 0.8)
		ShopManager.ItemRarity.LEGENDARY:
			card_style.border_color = Color(0.9, 0.6, 0.2, 0.9)
		_:
			card_style.border_color = Color(0.3, 0.35, 0.4, 0.6)

	if is_owned:
		card_style.bg_color = Color(0.15, 0.2, 0.15, 1.0)

	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", card_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Preview color for skin colors
	if item.has("preview_color"):
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(50, 50)
		color_rect.color = item.preview_color
		color_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(color_rect)

	# Item name
	var name_label = Label.new()
	name_label.text = item.get("name", item_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	# Rarity label
	var rarity_names = ["Common", "Uncommon", "Rare", "Legendary"]
	var rarity_label = Label.new()
	rarity_label.text = rarity_names[rarity] if rarity < rarity_names.size() else "Common"
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 11)
	rarity_label.add_theme_color_override("font_color", card_style.border_color)
	vbox.add_child(rarity_label)

	# Status or cost
	if is_owned:
		var owned_label = Label.new()
		owned_label.text = "Owned"
		owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		owned_label.add_theme_font_size_override("font_size", 12)
		owned_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
		vbox.add_child(owned_label)
	else:
		var cost = item.get("cost", {})
		if cost.is_empty():
			var free_label = Label.new()
			free_label.text = "Free"
			free_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			free_label.add_theme_font_size_override("font_size", 12)
			free_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
			vbox.add_child(free_label)
		else:
			var cost_label = Label.new()
			var cost_parts = []
			for aspect in cost:
				cost_parts.append(str(cost[aspect]) + " " + aspect.substr(0, 3).capitalize())
			cost_label.text = ", ".join(cost_parts)
			cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cost_label.add_theme_font_size_override("font_size", 11)
			cost_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
			vbox.add_child(cost_label)

		# Buy button
		var buy_btn = Button.new()
		buy_btn.text = "Buy"
		buy_btn.custom_minimum_size = Vector2(80, 30)
		buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		buy_btn.add_theme_font_size_override("font_size", 12)
		buy_btn.pressed.connect(_on_shop_buy_pressed.bind(item_id))

		var can_afford = ShopManager.can_afford(item_id)
		if not can_afford:
			buy_btn.disabled = true
			buy_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

		vbox.add_child(buy_btn)

	shop_item_grid.add_child(card)


func _on_shop_buy_pressed(item_id: String) -> void:
	if not ShopManager:
		return

	var success = ShopManager.purchase_item(item_id)
	if success:
		var item = ShopManager.get_item(item_id)
		var item_name = item.get("name", item_id)

		# Check if it's a room decor item - these go to mail
		var category = item.get("category", -1)
		if category == ShopManager.ItemCategory.ROOM_DECOR:
			# Place order via MailManager
			if MailManager:
				MailManager.place_order([item_id])
			_show_dialogue("Order Placed!", item_name + " has been ordered!\n\nCheck the mail room on your ship when the package arrives.")
		else:
			_show_dialogue("Purchase Complete!", "You purchased " + item_name + "!\n\nYou can equip it from the wardrobe in your bedroom.")

		# Refresh the shop view
		_on_shop_category_selected(shop_current_category)

		# Refresh XP display
		_close_experience_shop()
		_open_experience_shop()
	else:
		_show_dialogue("Cannot Purchase", "You don't have enough Aspect XP for this item.")


func _close_experience_shop() -> void:
	if shop_panel:
		shop_panel.queue_free()
		shop_panel = null
		shop_item_grid = null
	in_zone_panel = false


# ============ AFFIRMATIONS SYSTEM ============

const DEFAULT_AFFIRMATIONS = [
	"I am capable of achieving my goals.",
	"I embrace challenges as opportunities for growth.",
	"I am worthy of success and happiness.",
	"I choose to focus on what I can control.",
	"I am becoming a better version of myself each day.",
	"I have the power to create positive change.",
	"I am resilient and can overcome obstacles.",
	"I trust in my ability to learn and adapt.",
	"I am grateful for this moment.",
	"I deserve peace and inner calm.",
	"My potential is limitless.",
	"I am in charge of my own happiness.",
	"I release what no longer serves me.",
	"I attract positivity into my life.",
	"I am enough, exactly as I am."
]

var _editing_affirmation_index: int = -1


func _build_affirmations_tab() -> void:
	## Build the affirmations tab in the Reflection Pool

	var affirmations = _load_affirmations()
	var today = Time.get_date_string_from_system()
	var affirmed_today = GameManager.player_data.get("last_affirmation_date", "") == today

	# Header
	var header = Label.new()
	header.text = "Daily Affirmations"
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_body.add_child(header)

	var desc = Label.new()
	desc.text = "Speak positive truths to yourself. What you believe, you become."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_body.add_child(desc)

	_add_habit_spacer(12)

	# Today's affirmation card
	var today_card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.15, 0.18, 0.25, 0.9)
	card_style.set_corner_radius_all(10)
	card_style.set_content_margin_all(15)
	today_card.add_theme_stylebox_override("panel", card_style)

	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 10)

	var today_label = Label.new()
	today_label.text = "Today's Affirmation"
	today_label.add_theme_font_size_override("font_size", 14)
	today_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	today_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(today_label)

	# Get today's affirmation (rotate based on day of year)
	var day_of_year = _get_day_of_year()
	var active_affirmations = affirmations.custom if not affirmations.custom.is_empty() else DEFAULT_AFFIRMATIONS
	var today_index = day_of_year % active_affirmations.size()
	var todays_affirmation = active_affirmations[today_index]

	var affirmation_text = Label.new()
	affirmation_text.text = "\"" + todays_affirmation + "\""
	affirmation_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	affirmation_text.add_theme_font_size_override("font_size", 18)
	affirmation_text.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	affirmation_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(affirmation_text)

	# Affirm button
	if affirmed_today:
		var affirmed_label = Label.new()
		affirmed_label.text = "✓ Affirmed today"
		affirmed_label.add_theme_font_size_override("font_size", 16)
		affirmed_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
		affirmed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_vbox.add_child(affirmed_label)
	else:
		var affirm_btn = Button.new()
		affirm_btn.text = "I Affirm This"
		affirm_btn.custom_minimum_size = Vector2(0, 45)
		affirm_btn.add_theme_font_size_override("font_size", 16)
		affirm_btn.pressed.connect(_affirm_today)
		card_vbox.add_child(affirm_btn)

	today_card.add_child(card_vbox)
	zone_body.add_child(today_card)

	_add_habit_spacer(16)

	# Stats
	var stats_row = HBoxContainer.new()
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.add_theme_constant_override("separation", 30)

	var streak = affirmations.get("streak", 0)
	var total = affirmations.get("total_affirmed", 0)

	var streak_stat = _create_affirmation_stat("Streak", str(streak) + " days", Color(0.9, 0.6, 0.3))
	stats_row.add_child(streak_stat)

	var total_stat = _create_affirmation_stat("Total", str(total), Color(0.5, 0.7, 0.9))
	stats_row.add_child(total_stat)

	zone_body.add_child(stats_row)

	_add_habit_spacer(16)

	# Action buttons
	var button_row = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 10)

	var manage_btn = Button.new()
	manage_btn.text = "Manage Affirmations"
	manage_btn.custom_minimum_size = Vector2(0, 40)
	manage_btn.add_theme_font_size_override("font_size", 14)
	manage_btn.pressed.connect(_show_affirmation_manager)
	button_row.add_child(manage_btn)

	var random_btn = Button.new()
	random_btn.text = "Random Inspiration"
	random_btn.custom_minimum_size = Vector2(0, 40)
	random_btn.add_theme_font_size_override("font_size", 14)
	random_btn.pressed.connect(_show_random_affirmation)
	button_row.add_child(random_btn)

	zone_body.add_child(button_row)


func _create_affirmation_stat(label_text: String, value_text: String, color: Color) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var value_label = Label.new()
	value_label.text = value_text
	value_label.add_theme_font_size_override("font_size", 22)
	value_label.add_theme_color_override("font_color", color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(value_label)

	var text_label = Label.new()
	text_label.text = label_text
	text_label.add_theme_font_size_override("font_size", 12)
	text_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(text_label)

	return container


func _affirm_today() -> void:
	var affirmations = _load_affirmations()
	var today = Time.get_date_string_from_system()
	var yesterday = _get_yesterday_date()

	# Update streak
	var last_date = affirmations.get("last_date", "")
	if last_date == yesterday:
		affirmations.streak = affirmations.get("streak", 0) + 1
	elif last_date != today:
		affirmations.streak = 1

	affirmations.last_date = today
	affirmations.total_affirmed = affirmations.get("total_affirmed", 0) + 1

	_save_affirmations(affirmations)

	# Mark as affirmed today
	GameManager.player_data["last_affirmation_date"] = today

	# Award XP
	var xp_amount = 10
	if GameManager and GameManager.has_method("add_aspect_experience"):
		GameManager.add_aspect_experience("wisdom", xp_amount)

	# Refresh view
	_open_journal_viewer()


func _show_random_affirmation() -> void:
	var affirmations = _load_affirmations()
	var all_affirmations = DEFAULT_AFFIRMATIONS.duplicate()
	all_affirmations.append_array(affirmations.get("custom", []))

	var random_index = randi() % all_affirmations.size()
	var random_affirmation = all_affirmations[random_index]

	_show_dialogue("Random Inspiration", "\"" + random_affirmation + "\"\n\nLet this truth guide your day.")


func _show_affirmation_manager() -> void:
	zone_title.text = "Manage Affirmations"
	_clear_zone_body()

	var affirmations = _load_affirmations()
	var custom = affirmations.get("custom", [])

	var intro = Label.new()
	intro.text = "Create personal affirmations that resonate with you. Custom affirmations will be included in your daily rotation."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	zone_body.add_child(intro)

	_add_habit_spacer(12)

	# Custom affirmations list
	if custom.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No custom affirmations yet. Add your own below!"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		zone_body.add_child(empty_label)
	else:
		var list_header = Label.new()
		list_header.text = "Your Custom Affirmations:"
		list_header.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
		zone_body.add_child(list_header)

		_add_habit_spacer(6)

		for i in range(custom.size()):
			var affirmation = custom[i]
			_add_affirmation_row(affirmation, i)

	_add_habit_spacer(16)

	# Add new affirmation
	var add_btn = Button.new()
	add_btn.text = "+ Add New Affirmation"
	add_btn.custom_minimum_size = Vector2(0, 45)
	add_btn.add_theme_font_size_override("font_size", 16)
	add_btn.pressed.connect(_show_affirmation_editor.bind(-1))
	zone_body.add_child(add_btn)

	_add_habit_spacer(12)

	var back_btn = Button.new()
	back_btn.text = "← Back to Affirmations"
	back_btn.pressed.connect(_show_journal_tab.bind("affirm"))
	zone_body.add_child(back_btn)


func _add_affirmation_row(affirmation: String, index: int) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var text_label = Label.new()
	text_label.text = "\"" + affirmation + "\""
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.add_theme_font_size_override("font_size", 14)
	row.add_child(text_label)

	var edit_btn = Button.new()
	edit_btn.text = "✎"
	edit_btn.tooltip_text = "Edit"
	edit_btn.custom_minimum_size = Vector2(35, 0)
	edit_btn.pressed.connect(_show_affirmation_editor.bind(index))
	row.add_child(edit_btn)

	var delete_btn = Button.new()
	delete_btn.text = "✕"
	delete_btn.tooltip_text = "Delete"
	delete_btn.custom_minimum_size = Vector2(35, 0)
	delete_btn.pressed.connect(_delete_affirmation.bind(index))
	row.add_child(delete_btn)

	zone_body.add_child(row)
	_add_habit_spacer(4)


func _show_affirmation_editor(edit_index: int) -> void:
	_editing_affirmation_index = edit_index
	var is_edit = edit_index >= 0

	zone_title.text = "Edit Affirmation" if is_edit else "Add Affirmation"
	_clear_zone_body()

	var existing_text = ""
	if is_edit:
		var affirmations = _load_affirmations()
		var custom = affirmations.get("custom", [])
		if edit_index < custom.size():
			existing_text = custom[edit_index]

	var prompt = Label.new()
	prompt.text = "Write a positive statement that empowers you:"
	zone_body.add_child(prompt)

	_add_habit_spacer(8)

	var input = TextEdit.new()
	input.name = "AffirmationInput"
	input.placeholder_text = "I am..."
	input.text = existing_text
	input.custom_minimum_size = Vector2(0, 80)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_body.add_child(input)

	_add_habit_spacer(12)

	# Tips
	var tips_label = Label.new()
	tips_label.text = "Tips: Start with \"I am\", \"I can\", or \"I choose\". Keep it positive and present-tense."
	tips_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	tips_label.add_theme_font_size_override("font_size", 12)
	tips_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	zone_body.add_child(tips_label)

	_add_habit_spacer(16)

	# Action buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(_show_affirmation_manager)
	button_row.add_child(cancel_btn)

	var save_btn = Button.new()
	save_btn.text = "Save Affirmation"
	save_btn.pressed.connect(_save_affirmation_from_editor)
	button_row.add_child(save_btn)

	zone_body.add_child(button_row)


func _save_affirmation_from_editor() -> void:
	var input = zone_body.find_child("AffirmationInput", true, false) as TextEdit
	if not input or input.text.strip_edges() == "":
		_show_dialogue("Error", "Please enter an affirmation.")
		return

	var affirmations = _load_affirmations()
	if not affirmations.has("custom"):
		affirmations.custom = []

	var text = input.text.strip_edges()

	if _editing_affirmation_index >= 0 and _editing_affirmation_index < affirmations.custom.size():
		affirmations.custom[_editing_affirmation_index] = text
	else:
		affirmations.custom.append(text)

	_save_affirmations(affirmations)
	_editing_affirmation_index = -1

	_show_affirmation_manager()


func _delete_affirmation(index: int) -> void:
	var affirmations = _load_affirmations()
	if affirmations.has("custom") and index < affirmations.custom.size():
		affirmations.custom.remove_at(index)
		_save_affirmations(affirmations)

	_show_affirmation_manager()


func _get_day_of_year() -> int:
	var date = Time.get_datetime_dict_from_system()
	var day_of_year = date["day"]
	for m in range(1, date["month"]):
		var days_in_month = 31
		if m in [4, 6, 9, 11]:
			days_in_month = 30
		elif m == 2:
			days_in_month = 29 if date["year"] % 4 == 0 else 28
		day_of_year += days_in_month
	return day_of_year


func _get_yesterday_date() -> String:
	var today_dict = Time.get_datetime_dict_from_system()
	var today_unix = Time.get_unix_time_from_datetime_dict(today_dict)
	var yesterday_unix = today_unix - (24 * 60 * 60)
	var yesterday_dict = Time.get_datetime_dict_from_unix_time(yesterday_unix)
	return "%04d-%02d-%02d" % [yesterday_dict.year, yesterday_dict.month, yesterday_dict.day]


func _load_affirmations() -> Dictionary:
	var path = "user://affirmations.json"
	if not FileAccess.file_exists(path):
		return {"custom": [], "streak": 0, "total_affirmed": 0, "last_date": ""}

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {"custom": [], "streak": 0, "total_affirmed": 0, "last_date": ""}

	var json = JSON.new()
	var result = json.parse(file.get_as_text())
	file.close()

	if result == OK and json.data is Dictionary:
		return json.data
	return {"custom": [], "streak": 0, "total_affirmed": 0, "last_date": ""}


func _save_affirmations(data: Dictionary) -> void:
	var file = FileAccess.open("user://affirmations.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


# =============================================================================
# MINDSCAPE EVOLUTION STAGES
# =============================================================================
# Visual transformation of the mindscape based on evolution level
# 5 tiers that progressively enhance the environment

var evolution_stage_container: Node2D = null
var current_evolution_tier: int = 0
var evolution_stage_elements: Array = []
var floating_islands: Array = []
var platform_crystals: Array = []
var ancient_runes: Array = []
var mystical_aura: Node2D = null

# Evolution tier thresholds
const EVOLUTION_TIERS = {
	1: {"min_level": 1, "name": "Awakening", "color": Color(0.4, 0.35, 0.5)},
	2: {"min_level": 3, "name": "Growing", "color": Color(0.5, 0.4, 0.6)},
	3: {"min_level": 5, "name": "Flourishing", "color": Color(0.6, 0.5, 0.7)},
	4: {"min_level": 7, "name": "Transcending", "color": Color(0.7, 0.6, 0.8)},
	5: {"min_level": 9, "name": "Ascended", "color": Color(0.85, 0.75, 0.95)}
}

# Tier-specific visual configurations
const TIER_VISUALS = {
	1: {  # Awakening - Basic platform
		"edge_crystals": 0,
		"floating_islands": 0,
		"rune_count": 0,
		"aura_intensity": 0.0,
		"particle_density": 0.2
	},
	2: {  # Growing - Edge crystals emerge
		"edge_crystals": 4,
		"floating_islands": 0,
		"rune_count": 0,
		"aura_intensity": 0.1,
		"particle_density": 0.4
	},
	3: {  # Flourishing - Floating islands appear
		"edge_crystals": 6,
		"floating_islands": 3,
		"rune_count": 0,
		"aura_intensity": 0.2,
		"particle_density": 0.6
	},
	4: {  # Transcending - Ancient runes manifest
		"edge_crystals": 8,
		"floating_islands": 4,
		"rune_count": 6,
		"aura_intensity": 0.35,
		"particle_density": 0.8
	},
	5: {  # Ascended - Full mystical transformation
		"edge_crystals": 12,
		"floating_islands": 6,
		"rune_count": 12,
		"aura_intensity": 0.5,
		"particle_density": 1.0
	}
}


func _setup_evolution_stages() -> void:
	## Initialize the evolution stage visual system
	var evolution_level = GameManager.get_evolution_level() if GameManager else 1

	# Determine current tier
	current_evolution_tier = 1
	for tier in range(5, 0, -1):
		if evolution_level >= EVOLUTION_TIERS[tier]["min_level"]:
			current_evolution_tier = tier
			break

	# Create container for evolution stage visuals
	evolution_stage_container = Node2D.new()
	evolution_stage_container.name = "EvolutionStages"
	isometric_base.add_child(evolution_stage_container)
	isometric_base.move_child(evolution_stage_container, 2)  # After platform

	# Build visuals for current tier
	_build_evolution_tier_visuals(current_evolution_tier)

	print("[MindscapeHub] Evolution stage initialized: Tier %d (%s)" % [
		current_evolution_tier,
		EVOLUTION_TIERS[current_evolution_tier]["name"]
	])


func _build_evolution_tier_visuals(tier: int) -> void:
	## Build all visual elements for the given evolution tier
	var config = TIER_VISUALS.get(tier, TIER_VISUALS[1])
	var tier_color = EVOLUTION_TIERS[tier]["color"]

	# Create edge crystals
	if config["edge_crystals"] > 0:
		_create_platform_edge_crystals(config["edge_crystals"], tier_color)

	# Create floating islands
	if config["floating_islands"] > 0:
		_create_floating_islands(config["floating_islands"], tier_color)

	# Create ancient runes
	if config["rune_count"] > 0:
		_create_ancient_runes(config["rune_count"], tier_color)

	# Create mystical aura
	if config["aura_intensity"] > 0:
		_create_mystical_aura(config["aura_intensity"], tier_color)

	# Enhance existing elements based on tier
	_enhance_platform_for_tier(tier, tier_color)


func _create_platform_edge_crystals(count: int, base_color: Color) -> void:
	## Create crystals around the platform edge
	var platform_radius = 450  # Main platform radius

	for i in range(count):
		var angle = (float(i) / count) * TAU
		var distance = platform_radius + randf_range(-20, 20)
		var pos = Vector2(cos(angle) * distance, sin(angle) * distance * 0.5)  # Isometric adjustment

		var crystal = Node2D.new()
		crystal.name = "EdgeCrystal_" + str(i)
		crystal.position = pos

		# Crystal body - tall hexagonal shape
		var body = Polygon2D.new()
		var height = randf_range(25, 45)
		var width = randf_range(8, 15)
		body.polygon = PackedVector2Array([
			Vector2(0, -height),
			Vector2(width * 0.6, -height * 0.7),
			Vector2(width, -height * 0.2),
			Vector2(width * 0.8, height * 0.3),
			Vector2(0, height * 0.5),
			Vector2(-width * 0.8, height * 0.3),
			Vector2(-width, -height * 0.2),
			Vector2(-width * 0.6, -height * 0.7)
		])
		body.color = base_color.lightened(randf_range(0.1, 0.3))
		body.color.a = 0.85
		crystal.add_child(body)

		# Crystal glow
		var glow = Polygon2D.new()
		glow.polygon = body.polygon
		glow.scale = Vector2(1.3, 1.3)
		glow.color = base_color.lightened(0.4)
		glow.color.a = 0.2
		glow.z_index = -1
		crystal.add_child(glow)

		# Inner highlight
		var highlight = Polygon2D.new()
		highlight.polygon = PackedVector2Array([
			Vector2(-width * 0.3, -height * 0.6),
			Vector2(width * 0.2, -height * 0.4),
			Vector2(width * 0.1, -height * 0.1),
			Vector2(-width * 0.2, -height * 0.3)
		])
		highlight.color = Color(1, 1, 1, 0.3)
		crystal.add_child(highlight)

		evolution_stage_container.add_child(crystal)
		platform_crystals.append({
			"node": crystal,
			"glow": glow,
			"base_height": height,
			"phase": randf() * TAU
		})


func _create_floating_islands(count: int, base_color: Color) -> void:
	## Create small floating islands around the main platform
	var positions = [
		Vector2(-550, -200),
		Vector2(550, -150),
		Vector2(-480, 300),
		Vector2(520, 280),
		Vector2(-300, -350),
		Vector2(350, -320)
	]

	for i in range(mini(count, positions.size())):
		var island = Node2D.new()
		island.name = "FloatingIsland_" + str(i)
		island.position = positions[i]

		# Island base - irregular rocky platform
		var base = Polygon2D.new()
		var size = randf_range(40, 70)
		var points = PackedVector2Array()
		var segments = randi_range(6, 10)
		for j in range(segments):
			var a = (float(j) / segments) * TAU
			var r = size * randf_range(0.7, 1.0)
			points.append(Vector2(cos(a) * r, sin(a) * r * 0.5))
		base.polygon = points
		base.color = Color(0.25, 0.2, 0.3, 0.9)
		island.add_child(base)

		# Top surface - grass/energy layer
		var surface = Polygon2D.new()
		var surface_points = PackedVector2Array()
		for j in range(segments):
			var a = (float(j) / segments) * TAU
			var r = size * 0.8 * randf_range(0.8, 1.0)
			surface_points.append(Vector2(cos(a) * r, sin(a) * r * 0.5 - 5))
		surface.polygon = surface_points
		surface.color = base_color.darkened(0.2)
		surface.color.a = 0.8
		island.add_child(surface)

		# Small crystal or plant on top
		if randf() > 0.3:
			var decoration = Polygon2D.new()
			var dec_height = randf_range(15, 25)
			decoration.polygon = PackedVector2Array([
				Vector2(0, -dec_height),
				Vector2(5, -dec_height * 0.3),
				Vector2(3, 5),
				Vector2(-3, 5),
				Vector2(-5, -dec_height * 0.3)
			])
			decoration.color = base_color.lightened(0.3)
			decoration.color.a = 0.7
			decoration.position = Vector2(randf_range(-10, 10), -8)
			island.add_child(decoration)

		# Shadow beneath island
		var shadow = Polygon2D.new()
		shadow.polygon = base.polygon
		shadow.scale = Vector2(1.2, 0.3)
		shadow.position = Vector2(0, 40)
		shadow.color = Color(0, 0, 0, 0.15)
		shadow.z_index = -2
		island.add_child(shadow)

		evolution_stage_container.add_child(island)
		floating_islands.append({
			"node": island,
			"base_y": island.position.y,
			"phase": randf() * TAU,
			"amplitude": randf_range(8, 15),
			"speed": randf_range(0.3, 0.6)
		})


func _create_ancient_runes(count: int, base_color: Color) -> void:
	## Create glowing ancient runes on the platform surface
	var rune_patterns = [
		# Rune 1: Diamond with cross
		[Vector2(0, -15), Vector2(10, 0), Vector2(0, 15), Vector2(-10, 0)],
		# Rune 2: Triangle
		[Vector2(0, -12), Vector2(12, 10), Vector2(-12, 10)],
		# Rune 3: Circle with dot (represented as hexagon)
		[Vector2(8, 0), Vector2(4, 7), Vector2(-4, 7), Vector2(-8, 0), Vector2(-4, -7), Vector2(4, -7)],
		# Rune 4: Arrow pointing up
		[Vector2(0, -15), Vector2(8, -5), Vector2(3, -5), Vector2(3, 12), Vector2(-3, 12), Vector2(-3, -5), Vector2(-8, -5)],
		# Rune 5: Infinity-like shape
		[Vector2(-8, 0), Vector2(-4, -6), Vector2(0, 0), Vector2(4, -6), Vector2(8, 0), Vector2(4, 6), Vector2(0, 0), Vector2(-4, 6)],
		# Rune 6: Star
		[Vector2(0, -12), Vector2(3, -4), Vector2(12, -4), Vector2(5, 2), Vector2(7, 12), Vector2(0, 6), Vector2(-7, 12), Vector2(-5, 2), Vector2(-12, -4), Vector2(-3, -4)]
	]

	# Position runes in a circular pattern on the platform
	var radius = 280
	for i in range(count):
		var angle = (float(i) / count) * TAU + PI / 6  # Offset to avoid portals
		var pos = Vector2(cos(angle) * radius, sin(angle) * radius * 0.5)

		var rune = Node2D.new()
		rune.name = "AncientRune_" + str(i)
		rune.position = pos

		# Rune symbol
		var symbol = Polygon2D.new()
		var pattern_idx = i % rune_patterns.size()
		symbol.polygon = PackedVector2Array(rune_patterns[pattern_idx])
		symbol.color = base_color.lightened(0.5)
		symbol.color.a = 0.6
		rune.add_child(symbol)

		# Outer glow
		var glow = Polygon2D.new()
		glow.polygon = symbol.polygon
		glow.scale = Vector2(1.5, 1.5)
		glow.color = base_color.lightened(0.3)
		glow.color.a = 0.2
		glow.z_index = -1
		rune.add_child(glow)

		# Ground circle beneath rune
		var circle = Polygon2D.new()
		circle.polygon = _create_soft_circle(18, 12)
		circle.color = base_color.darkened(0.3)
		circle.color.a = 0.15
		circle.z_index = -2
		rune.add_child(circle)

		evolution_stage_container.add_child(rune)
		ancient_runes.append({
			"node": rune,
			"symbol": symbol,
			"glow": glow,
			"phase": randf() * TAU,
			"pulse_speed": randf_range(0.8, 1.5)
		})


func _create_mystical_aura(intensity: float, base_color: Color) -> void:
	## Create a mystical aura effect around the center of the platform
	mystical_aura = Node2D.new()
	mystical_aura.name = "MysticalAura"
	mystical_aura.position = Vector2.ZERO

	# Multiple aura rings at different sizes
	var ring_count = int(intensity * 6) + 1
	for i in range(ring_count):
		var ring = Polygon2D.new()
		ring.name = "AuraRing_" + str(i)

		var radius = 150 + i * 80
		ring.polygon = _create_evolution_ring_polygon(radius, radius - 8, 32)

		var ring_color = base_color.lightened(0.2 - i * 0.03)
		ring_color.a = intensity * 0.15 * (1.0 - float(i) / ring_count * 0.5)
		ring.color = ring_color
		ring.z_index = -3

		mystical_aura.add_child(ring)

	# Central glow spot
	var center_glow = Polygon2D.new()
	center_glow.polygon = _create_soft_circle(100, 24)
	center_glow.color = base_color.lightened(0.4)
	center_glow.color.a = intensity * 0.1
	center_glow.z_index = -4
	mystical_aura.add_child(center_glow)

	evolution_stage_container.add_child(mystical_aura)


func _create_evolution_ring_polygon(outer_radius: float, inner_radius: float, segments: int) -> PackedVector2Array:
	## Create a ring shape polygon for evolution stages
	var points = PackedVector2Array()

	# Outer edge
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle) * outer_radius, sin(angle) * outer_radius * 0.5))

	# Inner edge (reverse direction)
	for i in range(segments, -1, -1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle) * inner_radius, sin(angle) * inner_radius * 0.5))

	return points


func _enhance_platform_for_tier(tier: int, tier_color: Color) -> void:
	## Enhance existing platform elements based on evolution tier

	# Add edge glow to platform at higher tiers
	if tier >= 3:
		var edge_glow = Polygon2D.new()
		edge_glow.name = "PlatformEdgeGlow"

		var radius = 460
		var points = PackedVector2Array()
		var segments = 48
		for i in range(segments + 1):
			var angle = (float(i) / segments) * TAU
			points.append(Vector2(cos(angle) * radius, sin(angle) * radius * 0.5))
		for i in range(segments, -1, -1):
			var angle = (float(i) / segments) * TAU
			var inner_r = radius - 15
			points.append(Vector2(cos(angle) * inner_r, sin(angle) * inner_r * 0.5))

		edge_glow.polygon = points
		edge_glow.color = tier_color.lightened(0.3)
		edge_glow.color.a = 0.15 + (tier - 3) * 0.05
		edge_glow.z_index = -1

		evolution_stage_container.add_child(edge_glow)
		evolution_stage_elements.append(edge_glow)

	# Add center pillar enhancement at tier 4+
	if tier >= 4:
		var pillar_glow = Polygon2D.new()
		pillar_glow.name = "CenterPillarGlow"
		pillar_glow.polygon = _create_soft_circle(80, 16)
		pillar_glow.position = Vector2(0, -40)
		pillar_glow.color = tier_color.lightened(0.5)
		pillar_glow.color.a = 0.2 + (tier - 4) * 0.1
		pillar_glow.z_index = 5

		evolution_stage_container.add_child(pillar_glow)
		evolution_stage_elements.append(pillar_glow)


func _animate_evolution_stages(delta: float) -> void:
	## Animate all evolution stage elements
	var time = hub_env_time

	# Animate platform crystals
	for crystal_data in platform_crystals:
		if not is_instance_valid(crystal_data.node):
			continue

		var crystal = crystal_data.node
		var glow = crystal_data.glow
		var phase = crystal_data.phase

		# Gentle vertical bob
		crystal.position.y += sin(time * 1.5 + phase) * 0.1

		# Glow pulsing
		if is_instance_valid(glow):
			var pulse = sin(time * 2.0 + phase) * 0.1 + 0.9
			glow.modulate.a = pulse

	# Animate floating islands
	for island_data in floating_islands:
		if not is_instance_valid(island_data.node):
			continue

		var island = island_data.node
		var base_y = island_data.base_y
		var phase = island_data.phase
		var amp = island_data.amplitude
		var speed = island_data.speed

		# Gentle floating motion
		island.position.y = base_y + sin(time * speed + phase) * amp

		# Slight rotation
		island.rotation = sin(time * speed * 0.5 + phase) * 0.03

	# Animate ancient runes
	for rune_data in ancient_runes:
		if not is_instance_valid(rune_data.node):
			continue

		var symbol = rune_data.symbol
		var glow = rune_data.glow
		var phase = rune_data.phase
		var speed = rune_data.pulse_speed

		# Symbol brightness pulsing
		if is_instance_valid(symbol):
			var pulse = sin(time * speed + phase) * 0.3 + 0.7
			symbol.modulate.a = pulse

		# Glow expansion/contraction
		if is_instance_valid(glow):
			var scale_pulse = sin(time * speed * 0.7 + phase) * 0.1 + 1.0
			glow.scale = Vector2(1.5 * scale_pulse, 1.5 * scale_pulse)
			glow.modulate.a = sin(time * speed + phase) * 0.15 + 0.85

	# Animate mystical aura
	if is_instance_valid(mystical_aura):
		for ring in mystical_aura.get_children():
			var idx = ring.get_index()
			var ring_pulse = sin(time * 0.5 + idx * 0.5) * 0.1 + 1.0
			ring.scale = Vector2(ring_pulse, ring_pulse)
			ring.rotation = time * 0.05 * (1 if idx % 2 == 0 else -1)


func check_evolution_tier_change() -> void:
	## Check if player has reached a new evolution tier and trigger celebration
	var evolution_level = GameManager.get_evolution_level() if GameManager else 1

	var new_tier = 1
	for tier in range(5, 0, -1):
		if evolution_level >= EVOLUTION_TIERS[tier]["min_level"]:
			new_tier = tier
			break

	if new_tier > current_evolution_tier:
		_trigger_evolution_tier_celebration(new_tier)
		current_evolution_tier = new_tier

		# Rebuild visuals for new tier
		_clear_evolution_visuals()
		_build_evolution_tier_visuals(new_tier)


func _trigger_evolution_tier_celebration(new_tier: int) -> void:
	## Trigger a celebration effect when reaching a new evolution tier
	var tier_info = EVOLUTION_TIERS[new_tier]
	var tier_color = tier_info["color"]

	# Flash effect
	var flash = ColorRect.new()
	flash.name = "TierCelebrationFlash"
	flash.color = tier_color.lightened(0.5)
	flash.color.a = 0.4
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 200
	add_child(flash)

	# Fade out flash
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 1.5)
	tween.tween_callback(flash.queue_free)

	# Show tier announcement
	var announcement = _create_tier_announcement(new_tier, tier_info)
	add_child(announcement)

	# Play celebration sound (use achievement unlock sound)
	_play_sfx("res://audio/sfx/achievement_unlock.wav")

	# Trigger achievement audio moment
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("trigger_achievement_moment"):
		audio.trigger_achievement_moment(4.0)

	print("[MindscapeHub] Evolution tier up! Now at Tier %d: %s" % [new_tier, tier_info["name"]])


func _create_tier_announcement(tier: int, tier_info: Dictionary) -> Control:
	## Create the tier-up announcement UI
	var container = Control.new()
	container.name = "TierAnnouncement"
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.z_index = 150

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.95)
	style.border_color = tier_info["color"]
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(-180, -100)
	panel.custom_minimum_size = Vector2(360, 200)
	container.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	# Header
	var header = Label.new()
	header.text = "MINDSCAPE EVOLUTION"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", tier_info["color"].lightened(0.3))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	# Tier name
	var tier_label = Label.new()
	tier_label.text = "Tier %d: %s" % [tier, tier_info["name"]]
	tier_label.add_theme_font_size_override("font_size", 28)
	tier_label.add_theme_color_override("font_color", tier_info["color"])
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tier_label)

	# Description
	var descriptions = {
		1: "Your mindscape begins to take form...",
		2: "Crystals emerge from the depths!",
		3: "New islands rise from the void!",
		4: "Ancient wisdom reveals itself!",
		5: "You have achieved full ascension!"
	}
	var desc = Label.new()
	desc.text = descriptions.get(tier, "Your mindscape evolves!")
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)

	# Dismiss button
	var dismiss_btn = Button.new()
	dismiss_btn.text = "Continue"
	dismiss_btn.custom_minimum_size = Vector2(120, 40)
	dismiss_btn.pressed.connect(func(): container.queue_free())
	vbox.add_child(dismiss_btn)

	# Center the button
	var btn_container = CenterContainer.new()
	vbox.remove_child(dismiss_btn)
	btn_container.add_child(dismiss_btn)
	vbox.add_child(btn_container)

	# Animate in
	panel.modulate.a = 0
	panel.scale = Vector2(0.8, 0.8)
	var intro_tween = container.create_tween()
	intro_tween.set_parallel(true)
	intro_tween.tween_property(panel, "modulate:a", 1.0, 0.4)
	intro_tween.tween_property(panel, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BACK)

	return container


func _clear_evolution_visuals() -> void:
	## Remove all current evolution stage visuals for rebuild
	for crystal_data in platform_crystals:
		if is_instance_valid(crystal_data.node):
			crystal_data.node.queue_free()
	platform_crystals.clear()

	for island_data in floating_islands:
		if is_instance_valid(island_data.node):
			island_data.node.queue_free()
	floating_islands.clear()

	for rune_data in ancient_runes:
		if is_instance_valid(rune_data.node):
			rune_data.node.queue_free()
	ancient_runes.clear()

	if is_instance_valid(mystical_aura):
		mystical_aura.queue_free()
		mystical_aura = null

	for element in evolution_stage_elements:
		if is_instance_valid(element):
			element.queue_free()
	evolution_stage_elements.clear()


# ============================================
# DAILY LOGIN REWARDS UI
# ============================================

var daily_reward_panel: Control = null

func _check_daily_login() -> void:
	var result = GameManager.check_daily_login()

	if result.is_new_day:
		# Show daily reward popup
		if result.reward and not result.reward.is_empty():
			await get_tree().create_timer(1.0).timeout  # Brief delay after entering
			_show_daily_reward_popup(result)


func _show_daily_reward_popup(login_result: Dictionary) -> void:
	if daily_reward_panel:
		return

	var reward = login_result.reward
	var streak = GameManager.player_data.get("login_streak", 1)
	var total_days = GameManager.player_data.get("total_login_days", 1)

	# Create fullscreen overlay
	daily_reward_panel = Control.new()
	daily_reward_panel.name = "DailyRewardPanel"
	daily_reward_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(daily_reward_panel)

	# Dim background
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	daily_reward_panel.add_child(dim)

	# Main panel
	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.12, 0.98)
	panel_style.border_color = Color(0.9, 0.75, 0.3, 0.9)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(450, 380)
	panel.offset_left = -225
	panel.offset_right = 225
	panel.offset_top = -190
	panel.offset_bottom = 190
	daily_reward_panel.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Daily Reward!"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Day counter
	var day_label = Label.new()
	day_label.text = "Day " + str(total_days) + " • Streak: " + str(streak) + " days"
	day_label.add_theme_font_size_override("font_size", 16)
	day_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(day_label)

	# Reward icon/visual
	var reward_container = CenterContainer.new()
	reward_container.custom_minimum_size = Vector2(0, 100)
	vbox.add_child(reward_container)

	var reward_visual = Node2D.new()
	reward_container.add_child(reward_visual)

	# XP orb visual
	var orb = Polygon2D.new()
	orb.color = Color(0.95, 0.85, 0.4, 0.9)
	orb.polygon = PackedVector2Array([
		Vector2(-30, 0), Vector2(-21, -21), Vector2(0, -30),
		Vector2(21, -21), Vector2(30, 0), Vector2(21, 21),
		Vector2(0, 30), Vector2(-21, 21)
	])
	reward_visual.add_child(orb)

	var orb_glow = Polygon2D.new()
	orb_glow.color = Color(1.0, 0.9, 0.5, 0.3)
	orb_glow.polygon = PackedVector2Array([
		Vector2(-45, 0), Vector2(-32, -32), Vector2(0, -45),
		Vector2(32, -32), Vector2(45, 0), Vector2(32, 32),
		Vector2(0, 45), Vector2(-32, 32)
	])
	reward_visual.add_child(orb_glow)
	orb_glow.z_index = -1

	# Reward amount
	var amount_label = Label.new()
	amount_label.text = "+" + str(reward.get("amount", 0)) + " XP"
	amount_label.add_theme_font_size_override("font_size", 32)
	amount_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.5))
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(amount_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = reward.get("description", "Keep coming back!")
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.8))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)

	# Special bonus indicator
	if reward.has("bonus"):
		var bonus_label = Label.new()
		bonus_label.text = "Bonus: " + _format_bonus_name(reward.bonus)
		bonus_label.add_theme_font_size_override("font_size", 16)
		bonus_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.7))
		bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(bonus_label)

	# Claim button
	var claim_btn = Button.new()
	claim_btn.text = "Claim Reward"
	claim_btn.custom_minimum_size = Vector2(200, 50)
	claim_btn.add_theme_font_size_override("font_size", 18)
	claim_btn.pressed.connect(_claim_daily_reward.bind(((total_days - 1) % 30) + 1))
	vbox.add_child(claim_btn)

	# Center the button
	var btn_container = CenterContainer.new()
	claim_btn.reparent(btn_container)
	vbox.add_child(btn_container)

	# Milestone celebration if applicable
	if login_result.has("milestone") and not login_result.milestone.is_empty():
		await get_tree().create_timer(0.5).timeout
		_show_milestone_celebration(login_result.milestone)

	# Fade in
	daily_reward_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(daily_reward_panel, "modulate:a", 1.0, 0.4)


func _format_bonus_name(bonus: String) -> String:
	match bonus:
		"lore_fragment": return "Lore Fragment Unlocked"
		"cosmetic_color": return "New Avatar Color"
		"companion_accessory": return "Companion Accessory"
		"title_dedicated": return "Title: The Dedicated"
		_: return bonus.capitalize()


func _claim_daily_reward(day: int) -> void:
	GameManager.claim_daily_reward(day)

	# Play reward sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx_from_path"):
		audio.play_sfx_from_path("res://audio/sfx/achievement.wav")

	# Close panel with animation
	if daily_reward_panel:
		var tween = create_tween()
		tween.tween_property(daily_reward_panel, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func():
			if daily_reward_panel:
				daily_reward_panel.queue_free()
				daily_reward_panel = null
		)

	# Update header stats
	_update_header()


# ============================================
# MILESTONE CELEBRATION
# ============================================

var milestone_panel: Control = null

func _show_milestone_celebration(milestone: Dictionary) -> void:
	if milestone_panel:
		return

	milestone_panel = Control.new()
	milestone_panel.name = "MilestoneCelebration"
	milestone_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(milestone_panel)

	# Golden overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0.9, 0.75, 0.2, 0.15)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	milestone_panel.add_child(overlay)

	# Centered celebration panel
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.05, 0.98)
	style.border_color = Color(1.0, 0.85, 0.3)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(500, 350)
	panel.offset_left = -250
	panel.offset_right = 250
	panel.offset_top = -175
	panel.offset_bottom = 175
	milestone_panel.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# Milestone badge
	var badge_label = Label.new()
	badge_label.text = "MILESTONE ACHIEVED"
	badge_label.add_theme_font_size_override("font_size", 14)
	badge_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(badge_label)

	# Title
	var title = Label.new()
	title.text = milestone.get("title", "Milestone!")
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Days achieved
	var days_label = Label.new()
	days_label.text = str(milestone.get("days", 0)) + " Days of Growth"
	days_label.add_theme_font_size_override("font_size", 20)
	days_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	days_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(days_label)

	# Message
	var message = Label.new()
	message.text = milestone.get("message", "Congratulations on your journey!")
	message.add_theme_font_size_override("font_size", 16)
	message.add_theme_color_override("font_color", Color(0.8, 0.82, 0.9))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(message)

	# XP reward
	var xp_label = Label.new()
	xp_label.text = "+" + str(milestone.get("xp", 0)) + " Bonus XP"
	xp_label.add_theme_font_size_override("font_size", 24)
	xp_label.add_theme_color_override("font_color", Color(0.5, 0.95, 0.6))
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(xp_label)

	# Continue button
	var btn_container = CenterContainer.new()
	vbox.add_child(btn_container)

	var continue_btn = Button.new()
	continue_btn.text = "Continue Journey"
	continue_btn.custom_minimum_size = Vector2(200, 50)
	continue_btn.add_theme_font_size_override("font_size", 18)
	continue_btn.pressed.connect(_close_milestone_celebration)
	btn_container.add_child(continue_btn)

	# Grant milestone XP
	GameManager.add_aspect_experience("all", milestone.get("xp", 0))

	# Fade in with celebration
	milestone_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(milestone_panel, "modulate:a", 1.0, 0.5)

	# Play celebration sound
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx_from_path"):
		audio.play_sfx_from_path("res://audio/sfx/level_up.wav")


func _close_milestone_celebration() -> void:
	if milestone_panel:
		var tween = create_tween()
		tween.tween_property(milestone_panel, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func():
			if milestone_panel:
				milestone_panel.queue_free()
				milestone_panel = null
		)


# ============================================
# COMPANION EVOLUTION VISUALS
# ============================================

const COMPANION_COLORS = {
	0: Color(0.6, 0.7, 0.9, 0.7),   # Spark - pale blue
	1: Color(0.8, 0.6, 0.4, 0.8),   # Ember - orange
	2: Color(0.9, 0.5, 0.3, 0.85),  # Flame - bright orange
	3: Color(0.95, 0.7, 0.2, 0.9),  # Blaze - golden
	4: Color(0.9, 0.4, 0.8, 0.9),   # Nova - magenta
	5: Color(0.5, 0.9, 0.95, 0.95), # Celestial - cyan
	6: Color(0.95, 0.95, 0.6, 1.0), # Eternal - bright yellow
	7: Color(1.0, 1.0, 1.0, 1.0)    # Legendary - pure white
}

const COMPANION_SIZES = {
	0: 1.0,   # Spark
	1: 1.1,   # Ember
	2: 1.2,   # Flame
	3: 1.35,  # Blaze
	4: 1.5,   # Nova
	5: 1.7,   # Celestial
	6: 1.9,   # Eternal
	7: 2.2    # Legendary
}


func _update_companion_evolution_visual() -> void:
	if not companion_spirit:
		return

	var stage = GameManager.get_companion_stage()
	var info = GameManager.get_companion_info()

	# Update color
	var body = companion_spirit.get_node_or_null("Body")
	var glow = companion_spirit.get_node_or_null("Glow")

	if body and COMPANION_COLORS.has(stage):
		body.color = COMPANION_COLORS[stage]

	if glow and COMPANION_COLORS.has(stage):
		var glow_color = COMPANION_COLORS[stage]
		glow_color.a = 0.4
		glow.color = glow_color

	# Update size
	if COMPANION_SIZES.has(stage):
		companion_spirit.scale = Vector2.ONE * COMPANION_SIZES[stage]

	# Add accessories if unlocked
	_update_companion_accessories(info.get("accessories", []))

	# Add special effects for higher stages
	if stage >= 4:  # Nova and above
		_add_companion_particles(stage)


func _update_companion_accessories(accessories: Array) -> void:
	# Remove old accessories
	var old_acc = companion_spirit.get_node_or_null("Accessories")
	if old_acc:
		old_acc.queue_free()

	if accessories.is_empty():
		return

	var acc_container = Node2D.new()
	acc_container.name = "Accessories"
	companion_spirit.add_child(acc_container)

	for acc in accessories:
		match acc:
			"star_trail":
				# Add trailing stars effect
				for i in range(3):
					var star = Polygon2D.new()
					star.color = Color(1.0, 0.95, 0.6, 0.6 - i * 0.15)
					star.polygon = PackedVector2Array([
						Vector2(-3, 0), Vector2(0, -4), Vector2(3, 0), Vector2(0, 4)
					])
					star.position = Vector2(-15 - i * 12, 5 + i * 3)
					acc_container.add_child(star)


func _add_companion_particles(stage: int) -> void:
	# Check if particles already exist
	var particles = companion_spirit.get_node_or_null("EvolutionParticles")
	if particles:
		return

	particles = Node2D.new()
	particles.name = "EvolutionParticles"
	companion_spirit.add_child(particles)

	# Add orbiting sparkles
	var particle_count = min(stage - 3, 4) * 2  # 2, 4, 6, 8 particles
	for i in range(particle_count):
		var sparkle = Polygon2D.new()
		sparkle.color = COMPANION_COLORS.get(stage, Color.WHITE)
		sparkle.color.a = 0.7
		sparkle.polygon = PackedVector2Array([
			Vector2(-2, 0), Vector2(0, -2), Vector2(2, 0), Vector2(0, 2)
		])
		sparkle.name = "Sparkle" + str(i)
		particles.add_child(sparkle)

		# Position in orbit
		var angle = (TAU / particle_count) * i
		sparkle.position = Vector2(cos(angle) * 20, sin(angle) * 15)
