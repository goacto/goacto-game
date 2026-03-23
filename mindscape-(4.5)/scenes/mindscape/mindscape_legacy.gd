extends Control
## Mindscape - Your personal home base with explorable zones
## Navigate with WASD, interact with zones by approaching them

# Game world
@onready var game_world: Control = $GameWorld
@onready var isometric_base: Node2D = $GameWorld/IsometricBase
@onready var growth_layer: Polygon2D = $GameWorld/IsometricBase/GrowthLayer
@onready var player: CharacterBody2D = $GameWorld/IsometricBase/Player
@onready var interaction_detector: Area2D = $GameWorld/IsometricBase/Player/InteractionDetector

# Zone references
@onready var zones_node: Node2D = $GameWorld/IsometricBase/Zones

# Gate references
@onready var gates_node: Node2D = $GameWorld/IsometricBase/Gates
@onready var north_gate: Node2D = $GameWorld/IsometricBase/Gates/NorthGate
@onready var east_gate: Node2D = $GameWorld/IsometricBase/Gates/EastGate
@onready var west_gate: Node2D = $GameWorld/IsometricBase/Gates/WestGate
@onready var south_gate: Node2D = $GameWorld/IsometricBase/Gates/SouthGate

# Center crystal for animation
@onready var center_crystal: Polygon2D = $GameWorld/IsometricBase/CenterStructure/Crystal
@onready var crystal_glow: Polygon2D = $GameWorld/IsometricBase/CenterStructure/CrystalGlow

# Minimap
@onready var minimap: PanelContainer = $Minimap
@onready var minimap_content: Control = $Minimap/MinimapVBox/MinimapContent

# Animation state
var crystal_pulse_time: float = 0.0
var minimap_initialized: bool = false

# UI
@onready var interaction_prompt: PanelContainer = $InteractionPrompt
@onready var zone_name_label: Label = $InteractionPrompt/Margin/VBox/ZoneName
@onready var prompt_text_label: Label = $InteractionPrompt/Margin/VBox/PromptText
@onready var control_hints: HBoxContainer = $ControlHints

# Zone panel
@onready var zone_panel: PanelContainer = $ZonePanel
@onready var zone_title: Label = $ZonePanel/Margin/ZoneContent/ZoneHeader/ZoneTitle
@onready var zone_body: VBoxContainer = $ZonePanel/Margin/ZoneContent/ZoneBody/ZoneBodyContent
@onready var back_button: Button = $ZonePanel/Margin/ZoneContent/ZoneHeader/BackButton

# Tutorial panel
@onready var tutorial_panel: PanelContainer = $TutorialPanel
@onready var tutorial_title: Label = $TutorialPanel/Margin/VBox/TutorialTitle
@onready var tutorial_text: Label = $TutorialPanel/Margin/VBox/TutorialText
@onready var got_it_button: Button = $TutorialPanel/Margin/VBox/GotItButton

# Header
@onready var evolution_label: Label = $Header/Margin/HBox/EvolutionContainer/EvolutionLabel
@onready var evolution_bar: ProgressBar = $Header/Margin/HBox/EvolutionContainer/EvolutionBar
@onready var chapter_button: Button = $Header/Margin/HBox/ChapterButton

# Chapter list panel
@onready var chapter_list_panel: PanelContainer = $ChapterListPanel
@onready var close_chapter_list: Button = $ChapterListPanel/Margin/VBox/Header/CloseChapterList
@onready var chapter_list_body: VBoxContainer = $ChapterListPanel/Margin/VBox/ChapterScroll/ChapterListBody
@onready var date_label: Label = $Header/Margin/HBox/DateLabel
@onready var menu_button: Button = $Header/Margin/HBox/MenuButton
@onready var settings_button: Button = $Header/Margin/HBox/SettingsButton

# Pause Menu
@onready var pause_menu: PanelContainer = $PauseMenu
@onready var close_menu_button: Button = $PauseMenu/Margin/VBox/MenuHeader/CloseMenuButton
@onready var character_tab: Button = $PauseMenu/Margin/VBox/MenuTabs/CharacterTab
@onready var aspects_tab: Button = $PauseMenu/Margin/VBox/MenuTabs/AspectsTab
@onready var progress_tab: Button = $PauseMenu/Margin/VBox/MenuTabs/ProgressTab
@onready var settings_menu_tab: Button = $PauseMenu/Margin/VBox/MenuTabs/SettingsTab
@onready var menu_body: VBoxContainer = $PauseMenu/Margin/VBox/MenuContent/MenuBody

# Settings panel
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var settings_close_button: Button = $SettingsPanel/Margin/VBox/Header/CloseButton
@onready var focus_duration_spinbox: SpinBox = $SettingsPanel/Margin/VBox/SettingsScroll/SettingsContent/GameplaySection/FocusDurationRow/SpinBox
@onready var notifications_checkbox: CheckBox = $SettingsPanel/Margin/VBox/SettingsScroll/SettingsContent/GameplaySection/NotificationsRow/CheckBox
@onready var sound_checkbox: CheckBox = $SettingsPanel/Margin/VBox/SettingsScroll/SettingsContent/GameplaySection/SoundRow/CheckBox
@onready var reset_tutorials_button: Button = $SettingsPanel/Margin/VBox/SettingsScroll/SettingsContent/DataSection/ResetTutorialsButton
@onready var clear_data_button: Button = $SettingsPanel/Margin/VBox/SettingsScroll/SettingsContent/DataSection/ClearDataButton
@onready var about_button: Button = $SettingsPanel/Margin/VBox/SettingsScroll/SettingsContent/SupportSection/AboutButton
@onready var feedback_button: Button = $SettingsPanel/Margin/VBox/SettingsScroll/SettingsContent/SupportSection/FeedbackButton

# Dialogue
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var speaker_name: Label = $DialoguePanel/Margin/VBox/SpeakerName
@onready var dialogue_text: Label = $DialoguePanel/Margin/VBox/DialogueText
@onready var dialogue_continue: Button = $DialoguePanel/Margin/VBox/ContinueButton

# Player movement
var player_speed: float = 350.0  # Faster for larger map
var player_bounds: Rect2 = Rect2(-1600, -1400, 3200, 2800)  # Expanded world bounds

# Camera/zoom
var camera_zoom: float = 0.8  # Start zoomed out to see more
var min_zoom: float = 0.25
var max_zoom: float = 1.5
var zoom_speed: float = 0.08

# Zone interaction
var nearby_zone: String = ""
var current_zone: String = ""
var in_zone_panel: bool = false

# Exit portal (center crystal)
var near_exit_portal: bool = false
const EXIT_PORTAL_POSITION = Vector2(0, -60)
const EXIT_PORTAL_RADIUS = 80.0

# Zone name mapping
var zone_names: Dictionary = {
	"FocusChamber": "Focus Chamber",
	"ReflectionPool": "Reflection Pool",
	"AspectShrine": "Aspect Shrine",
	"GoalCompass": "Goal Compass",
	"DailyRituals": "Daily Rituals",
	"TrainingArena": "Training Arena",
	"ScriptLab": "Script Lab",
	# Northern Gardens
	"DreamGarden": "Dream Garden",
	"MemoryArchive": "Memory Archive",
	# Eastern Observatory
	"Observatory": "Star Observatory",
	# Western Depths
	"ShadowWork": "Shadow Work",
	# Southern Peaks
	"Summit": "The Summit"
}

# Zone node to room ID mapping (for CampaignManager)
var zone_to_room: Dictionary = {
	"FocusChamber": "focus_chamber",
	"ReflectionPool": "reflection_pool",
	"AspectShrine": "aspect_shrine",
	"GoalCompass": "goal_compass",
	"DailyRituals": "daily_rituals",
	"TrainingArena": "training_arena",
	"ScriptLab": "script_lab",
	# Northern Gardens (Chapter 3+)
	"DreamGarden": "dream_garden",
	"MemoryArchive": "memory_archive",
	# Eastern Observatory (Chapter 5+)
	"Observatory": "observatory",
	# Western Depths (Chapter 7+)
	"ShadowWork": "shadow_work",
	# Southern Peaks (Chapter 8+)
	"Summit": "summit"
}

# Unlock requirements text for locked zones
var zone_unlock_text: Dictionary = {
	"focus_chamber": "Available from the start",
	"daily_rituals": "Complete Chapter 1:\nFinish your first focus session",
	"reflection_pool": "Complete Chapter 2:\nCreate a habit and complete 3 focus sessions",
	"goal_compass": "Complete Chapter 3:\nMaintain a 5-day streak",
	"training_arena": "Complete Chapter 4:\nSet and complete daily goals",
	"aspect_shrine": "Complete Chapter 5:\nDefeat Doubt in combat",
	"script_lab": "Complete Chapter 7:\nDefeat Fear and awaken Courage",
	# Northern Gardens (Chapter 3+)
	"dream_garden": "Complete Chapter 3:\nBegin building your momentum",
	"memory_archive": "Complete Chapter 3:\nUnlock the Northern Gardens",
	# Eastern Observatory (Chapter 5+)
	"observatory": "Complete Chapter 5:\nDefeat Doubt and awaken Discipline",
	# Western Depths (Chapter 7+)
	"shadow_work": "Complete Chapter 7:\nFace your fears and awaken Courage",
	# Southern Peaks (Chapter 8+)
	"summit": "Complete Chapter 8:\nMaster creativity and unlock advanced features"
}

# Gate unlock requirements (which zones must be unlocked to pass through each gate)
var gate_requirements: Dictionary = {
	"NorthGate": ["ReflectionPool", "AspectShrine"],  # Tier 2 zones unlock north
	"EastGate": ["ScriptLab", "TrainingArena"],       # Tier 3 zones unlock east
	"WestGate": ["DreamGarden", "Observatory"],       # Tier 4 zones unlock west
	"SouthGate": ["ShadowWork"]                       # Tier 5 zone unlocks south
}

# ============ COLLECTIBLE WISPS SYSTEM ============
# Wisps are floating collectibles that grant small XP bonuses

var wisps: Array = []  # Active wisp nodes
var collected_wisps: Dictionary = {}  # Track collected wisps per session
var wisp_respawn_time: float = 300.0  # 5 minutes to respawn

const WISP_SPAWN_LOCATIONS = [
	# Central area wisps
	{"pos": Vector2(-200, -350), "type": "focus", "xp": 5},
	{"pos": Vector2(200, -350), "type": "wisdom", "xp": 5},
	{"pos": Vector2(-350, 150), "type": "creativity", "xp": 5},
	{"pos": Vector2(350, 150), "type": "courage", "xp": 5},
	# Northern Gardens wisps
	{"pos": Vector2(-150, -700), "type": "vitality", "xp": 8},
	{"pos": Vector2(150, -700), "type": "wisdom", "xp": 8},
	{"pos": Vector2(0, -900), "type": "rare", "xp": 15},
	# Eastern Observatory wisps
	{"pos": Vector2(900, -100), "type": "focus", "xp": 8},
	{"pos": Vector2(1100, -250), "type": "creativity", "xp": 10},
	{"pos": Vector2(1300, 0), "type": "rare", "xp": 15},
	# Western Depths wisps
	{"pos": Vector2(-900, 100), "type": "courage", "xp": 10},
	{"pos": Vector2(-1100, 250), "type": "compassion", "xp": 10},
	{"pos": Vector2(-1300, 50), "type": "rare", "xp": 20},
	# Southern Peaks wisps
	{"pos": Vector2(-100, 600), "type": "discipline", "xp": 8},
	{"pos": Vector2(100, 600), "type": "vitality", "xp": 8},
	{"pos": Vector2(0, 900), "type": "legendary", "xp": 25},
]

const WISP_COLORS = {
	"focus": Color(0.4, 0.8, 0.5, 0.9),
	"wisdom": Color(0.5, 0.6, 0.9, 0.9),
	"creativity": Color(0.7, 0.5, 0.8, 0.9),
	"courage": Color(0.9, 0.5, 0.4, 0.9),
	"compassion": Color(0.9, 0.6, 0.7, 0.9),
	"discipline": Color(0.83, 0.66, 0.29, 0.9),
	"vitality": Color(0.5, 0.9, 0.6, 0.9),
	"rare": Color(0.9, 0.85, 0.4, 1.0),
	"legendary": Color(0.95, 0.95, 1.0, 1.0),
}

# ============ NPC SPIRITS SYSTEM ============
# Wandering aspect spirits that can be talked to

var npc_spirits: Array = []  # Active NPC nodes
var nearby_npc: String = ""

const NPC_DEFINITIONS = [
	{
		"id": "spirit_discipline",
		"name": "Echo of Discipline",
		"aspect": "discipline",
		"home_pos": Vector2(-400, 50),
		"wander_radius": 150.0,
		"dialogues": [
			"Consistency builds mountains, one stone at a time.",
			"The path forward is walked daily, not dreamed about.",
			"Your habits shape your destiny. Choose them wisely.",
			"I sense growing discipline in you. Keep showing up."
		]
	},
	{
		"id": "spirit_wisdom",
		"name": "Whisper of Wisdom",
		"aspect": "wisdom",
		"home_pos": Vector2(400, -100),
		"wander_radius": 120.0,
		"dialogues": [
			"Knowledge without action is merely potential.",
			"The reflection pool holds more answers than you know.",
			"Ask yourself: what did today teach you?",
			"Wisdom grows not from success, but from reflection."
		]
	},
	{
		"id": "spirit_courage",
		"name": "Flame of Courage",
		"aspect": "courage",
		"home_pos": Vector2(200, 350),
		"wander_radius": 100.0,
		"dialogues": [
			"Fear is a compass pointing toward growth.",
			"The arena awaits those ready to face themselves.",
			"Every battle won against doubt makes you stronger.",
			"Courage is not the absence of fear, but action despite it."
		]
	},
	{
		"id": "spirit_creativity",
		"name": "Spark of Creativity",
		"aspect": "creativity",
		"home_pos": Vector2(-100, 450),
		"wander_radius": 180.0,
		"dialogues": [
			"Every script you write rewrites your potential.",
			"Creation is the highest form of human expression.",
			"The Script Lab holds infinite possibilities.",
			"What will you build today?"
		]
	},
	{
		"id": "spirit_vitality",
		"name": "Pulse of Vitality",
		"aspect": "vitality",
		"home_pos": Vector2(-250, -500),
		"wander_radius": 200.0,
		"dialogues": [
			"Your body is the vessel of your dreams.",
			"Movement is medicine for the mind.",
			"The Dream Garden flourishes when you care for yourself.",
			"Rest is not laziness—it is restoration."
		]
	},
	{
		"id": "spirit_compassion",
		"name": "Heart of Compassion",
		"aspect": "compassion",
		"home_pos": Vector2(250, -500),
		"wander_radius": 130.0,
		"dialogues": [
			"Be kind to yourself. Growth takes time.",
			"The memories we cherish shape who we become.",
			"Connection is the bridge between isolation and belonging.",
			"Your story matters. Every chapter."
		]
	},
]

# ============ HIDDEN SECRETS SYSTEM ============
# Clickable objects that reveal lore or rewards

var secrets_found: Array = []  # Track discovered secrets

const SECRET_LOCATIONS = [
	{
		"id": "ancient_rune_1",
		"pos": Vector2(-700, -100),
		"name": "Ancient Rune",
		"description": "A glowing symbol etched into the platform...",
		"lore": "\"The first step is always the hardest, but it is the only one that truly matters.\" - Ancient Goactorian Proverb",
		"reward_xp": 10
	},
	{
		"id": "memory_fragment_1",
		"pos": Vector2(700, 200),
		"name": "Memory Fragment",
		"description": "A crystallized thought floats here...",
		"lore": "You see a vision: countless beings across galaxies, all working to improve themselves. You are part of something vast.",
		"reward_xp": 15
	},
	{
		"id": "hidden_shrine",
		"pos": Vector2(0, -150),
		"name": "Forgotten Shrine",
		"description": "A small shrine hidden near the center crystal...",
		"lore": "\"The mindscape reflects the mind. As within, so without.\" This place grows with you.",
		"reward_xp": 20
	},
	{
		"id": "star_map",
		"pos": Vector2(1150, -300),
		"name": "Star Map",
		"description": "A holographic map of the cosmos...",
		"lore": "You see the Stellar Wanderer's path across the galaxy. Earth is marked with a golden dot. Agent Goacto chose well.",
		"reward_xp": 25
	},
	{
		"id": "shadow_mirror",
		"pos": Vector2(-1150, 200),
		"name": "Shadow Mirror",
		"description": "A mirror that shows something different...",
		"lore": "You see your potential self—not who you are, but who you could become. The reflection smiles.",
		"reward_xp": 25
	},
	{
		"id": "summit_inscription",
		"pos": Vector2(0, 850),
		"name": "Summit Inscription",
		"description": "Words carved at the peak...",
		"lore": "\"Those who reach this summit have proven that growth is not a destination, but a way of being. Congratulations, traveler.\"",
		"reward_xp": 50
	},
]

# Animation timers
var wisp_animation_time: float = 0.0
var npc_animation_time: float = 0.0
var ambient_time: float = 0.0


func _ready() -> void:
	# Connect UI
	back_button.pressed.connect(_close_zone)
	dialogue_continue.pressed.connect(_close_dialogue)
	got_it_button.pressed.connect(_close_tutorial)

	# Connect settings
	settings_button.pressed.connect(_open_settings)
	settings_close_button.pressed.connect(_close_settings)
	reset_tutorials_button.pressed.connect(_on_reset_tutorials)
	clear_data_button.pressed.connect(_on_clear_data)
	about_button.pressed.connect(_on_about)
	feedback_button.pressed.connect(_on_feedback)

	# Connect pause menu
	menu_button.pressed.connect(_open_pause_menu)
	close_menu_button.pressed.connect(_close_pause_menu)
	character_tab.pressed.connect(_show_character_tab)
	aspects_tab.pressed.connect(_show_aspects_tab)
	progress_tab.pressed.connect(_show_progress_tab)
	settings_menu_tab.pressed.connect(_show_settings_tab)

	# Connect chapter list
	chapter_button.pressed.connect(_open_chapter_list)
	close_chapter_list.pressed.connect(_close_chapter_list)

	# Connect zone interaction areas
	_setup_zone_interactions()

	# Initialize expanded game systems
	_spawn_wisps()
	_spawn_npc_spirits()
	_spawn_secrets()

	# Connect signals
	GameManager.world_evolution_triggered.connect(_on_world_evolved)
	GameManager.aspect_leveled_up.connect(_on_aspect_leveled)
	GameManager.zone_unlocked.connect(_on_zone_unlocked)

	# Connect campaign signals for room unlocks
	CampaignManager.room_unlocked.connect(_on_room_unlocked)
	CampaignManager.chapter_completed.connect(_on_chapter_completed)
	CampaignManager.trophy_earned.connect(_on_trophy_earned)

	# Initialize
	_update_header()
	_update_base_visuals()
	_update_zone_lock_visuals()
	_update_gate_barriers()
	_setup_minimap()
	_center_base()

	# Re-center when window resizes
	get_tree().root.size_changed.connect(_center_base)

	GameManager.change_state(GameManager.GameState.MINDSCAPE)

	# Show welcome tutorial for first-time players
	if not GameManager.has_seen_tutorial("mindscape_welcome"):
		_show_tutorial("Welcome to your Mindscape!", "This is your personal sanctuary. Use WASD to move around and explore.\n\nApproach any zone structure and press SPACE to interact.")
		GameManager.mark_tutorial_seen("mindscape_welcome")

	print("[Mindscape] Home base ready - exploration mode")


func _setup_zone_interactions() -> void:
	# Connect each zone's interaction area
	for zone in zones_node.get_children():
		var area = zone.get_node_or_null("InteractionArea")
		if area:
			area.area_entered.connect(_on_zone_area_entered.bind(zone.name))
			area.area_exited.connect(_on_zone_area_exited.bind(zone.name))


func _setup_minimap() -> void:
	if not minimap_content:
		return

	# Clear existing minimap content
	for child in minimap_content.get_children():
		child.queue_free()

	# Scale factor: world coords to minimap coords
	var scale_factor = 0.04  # Shrink world by this factor
	var center = Vector2(75, 75)  # Center of minimap

	# Zone positions and their minimap representations
	var zone_positions = {
		"FocusChamber": Vector2(-500, -200),
		"ReflectionPool": Vector2(500, -200),
		"AspectShrine": Vector2(-600, 100),
		"GoalCompass": Vector2(600, 100),
		"DailyRituals": Vector2(-300, 280),
		"TrainingArena": Vector2(300, 280),
		"ScriptLab": Vector2(0, 350),
		"DreamGarden": Vector2(-300, -800),
		"MemoryArchive": Vector2(300, -800),
		"Observatory": Vector2(1200, -150),
		"ShadowWork": Vector2(-1200, 150),
		"Summit": Vector2(0, 750)
	}

	# Create zone dots on minimap
	for zone_id in zone_positions:
		var world_pos = zone_positions[zone_id]
		var minimap_pos = center + (world_pos * scale_factor)

		var dot = Polygon2D.new()
		dot.name = "Minimap_" + zone_id

		var is_locked = not GameManager.is_zone_unlocked(zone_id)
		var tier = GameManager.get_zone_tier(zone_id)

		# Dot size and color based on lock status
		var dot_size = 4 if is_locked else 6
		if is_locked:
			dot.color = Color(0.4, 0.4, 0.5, 0.6)
		else:
			# Color by tier
			var tier_colors = {
				1: Color(0.4, 0.8, 0.5, 1),   # Green
				2: Color(0.7, 0.55, 0.3, 1),  # Bronze
				3: Color(0.7, 0.7, 0.8, 1),   # Silver
				4: Color(0.9, 0.75, 0.2, 1),  # Gold
				5: Color(0.5, 0.85, 0.95, 1), # Diamond
				6: Color(0.85, 0.45, 0.95, 1) # Cosmic
			}
			dot.color = tier_colors.get(tier, Color(0.5, 0.7, 0.9, 1))

		dot.polygon = PackedVector2Array([
			Vector2(-dot_size, 0), Vector2(0, -dot_size),
			Vector2(dot_size, 0), Vector2(0, dot_size)
		])
		dot.position = minimap_pos

		minimap_content.add_child(dot)

	# Add player dot (will be updated in _process)
	var player_dot = Polygon2D.new()
	player_dot.name = "MinimapPlayer"
	player_dot.color = Color(0.9, 0.9, 1, 1)
	player_dot.polygon = PackedVector2Array([
		Vector2(-5, 0), Vector2(0, -7), Vector2(5, 0), Vector2(0, 5)
	])
	player_dot.position = center
	minimap_content.add_child(player_dot)

	minimap_initialized = true


func _update_minimap() -> void:
	if not minimap_initialized or not minimap_content or not player:
		return

	var player_dot = minimap_content.get_node_or_null("MinimapPlayer")
	if player_dot:
		var scale_factor = 0.04
		var center = Vector2(75, 75)
		player_dot.position = center + (player.position * scale_factor)


func _on_zone_area_entered(_area: Area2D, zone_id: String) -> void:
	nearby_zone = zone_id
	_show_interaction_prompt(zone_id)


func _on_zone_area_exited(_area: Area2D, zone_id: String) -> void:
	if nearby_zone == zone_id:
		nearby_zone = ""
		_hide_interaction_prompt()


func _show_interaction_prompt(zone_id: String) -> void:
	var is_locked = not _is_zone_unlocked(zone_id)
	var tier = GameManager.get_zone_tier(zone_id)

	zone_name_label.text = zone_names.get(zone_id, zone_id)

	if is_locked:
		# Show locked state with tier info
		var tier_label = "Tier " + str(tier)
		zone_name_label.text = zone_names.get(zone_id, zone_id) + " [LOCKED]"
		zone_name_label.add_theme_color_override("font_color", ThemeConfig.CHAPTER_LOCKED)

		# Get requirement from GameManager
		var requirement = GameManager.get_zone_requirement(zone_id)
		if requirement == "":
			requirement = "Complete previous chapters to unlock"
		prompt_text_label.text = requirement
		prompt_text_label.add_theme_color_override("font_color", ThemeConfig.TEXT_TERTIARY)
	else:
		zone_name_label.remove_theme_color_override("font_color")
		prompt_text_label.text = "Press SPACE or tap to enter"
		prompt_text_label.add_theme_color_override("font_color", ThemeConfig.GOACTO_GOLD)

	interaction_prompt.visible = true
	control_hints.visible = false


## Check if a zone is unlocked via GameManager tier system
func _is_zone_unlocked(zone_id: String) -> bool:
	return GameManager.is_zone_unlocked(zone_id)


func _hide_interaction_prompt() -> void:
	interaction_prompt.visible = false
	control_hints.visible = true


func _process(delta: float) -> void:
	# Animate central crystal glow (always runs)
	_animate_crystal(delta)

	# Animate wisps and NPCs (always runs for visual effect)
	_animate_wisps(delta)
	_animate_npcs(delta)
	_animate_ambient(delta)

	if in_zone_panel or not player:
		return

	# Check for wisp collection
	_check_wisp_collection()

	# Check for NPC proximity
	_check_npc_proximity()

	# Check for secret discovery
	_check_secret_discovery()

	# Check for exit portal proximity
	_check_exit_portal_proximity()

	# Handle interaction input
	if Input.is_action_just_pressed("ui_accept"):
		if near_exit_portal:
			_show_exit_portal_dialog()
			return
		elif nearby_zone != "":
			_interact_with_zone(nearby_zone)
			return
		elif nearby_npc != "":
			_talk_to_npc(nearby_npc)
			return

	# Get WASD input
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

		# Cardinal movement (W=up, S=down, A=left, D=right) - consistent with ship rooms
		var new_pos = player.position + input_dir * player_speed * delta

		# Clamp to bounds
		new_pos.x = clamp(new_pos.x, player_bounds.position.x, player_bounds.position.x + player_bounds.size.x)
		new_pos.y = clamp(new_pos.y, player_bounds.position.y, player_bounds.position.y + player_bounds.size.y)

		player.position = new_pos

	# Camera follow - keep player centered
	_update_camera()

	# Update minimap player position
	_update_minimap()


func _input(event: InputEvent) -> void:
	# ESC key toggles pause menu
	if event.is_action_pressed("ui_cancel"):
		if pause_menu.visible:
			_close_pause_menu()
		elif settings_panel.visible:
			_close_settings()
		elif zone_panel.visible:
			_close_zone()
		elif dialogue_panel.visible:
			_close_dialogue()
		else:
			_open_pause_menu()
		get_viewport().set_input_as_handled()
		return

	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(zoom_speed)
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(-zoom_speed)
			get_viewport().set_input_as_handled()
			return

	# Zoom with +/- keys
	if event.is_action_pressed("ui_page_up"):
		_apply_zoom(zoom_speed)
		return
	if event.is_action_pressed("ui_page_down"):
		_apply_zoom(-zoom_speed)
		return

	# Handle touch/click for zone/NPC/portal interaction
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if interaction_prompt.visible:
			if near_exit_portal:
				_show_exit_portal_dialog()
			elif nearby_zone != "":
				_interact_with_zone(nearby_zone)
			elif nearby_npc != "":
				_talk_to_npc(nearby_npc)


func _interact_with_zone(zone_id: String) -> void:
	# Check if zone is locked
	if not _is_zone_unlocked(zone_id):
		var zone_name = zone_names.get(zone_id, zone_id)
		var tier = GameManager.get_zone_tier(zone_id)
		var requirement = GameManager.get_zone_requirement(zone_id)
		if requirement == "":
			requirement = "Continue your journey to unlock this zone"
		_show_dialogue("Locked - Tier " + str(tier), zone_name + " is not yet accessible.\n\n" + requirement, _close_dialogue)
		return

	match zone_id:
		"FocusChamber":
			_open_focus_zone()
		"ReflectionPool":
			_open_journal_zone()
		"AspectShrine":
			_open_aspects_zone()
		"GoalCompass":
			_open_goals_zone()
		"DailyRituals":
			_open_habits_zone()
		"TrainingArena":
			_open_arena_zone()
		"ScriptLab":
			_open_script_lab()
		# Northern Gardens
		"DreamGarden":
			_open_dream_garden()
		"MemoryArchive":
			_open_memory_archive()
		# Eastern Observatory
		"Observatory":
			_open_observatory()
		# Western Depths
		"ShadowWork":
			_open_shadow_work()
		# Southern Peaks
		"Summit":
			_open_summit()


func _center_base() -> void:
	await get_tree().process_frame
	_update_camera()


func _update_camera() -> void:
	if not game_world or not isometric_base or not player:
		return

	var screen_center = game_world.size / 2

	# Position isometric_base so player appears at screen center
	# Apply zoom scaling
	var target_pos = screen_center - (player.position * camera_zoom)
	isometric_base.position = target_pos.round()
	isometric_base.scale = Vector2(camera_zoom, camera_zoom)


func _apply_zoom(zoom_delta: float) -> void:
	camera_zoom = clampf(camera_zoom + zoom_delta, min_zoom, max_zoom)
	_update_camera()


func _animate_crystal(delta: float) -> void:
	if not crystal_glow:
		return

	crystal_pulse_time += delta

	# Smooth sine wave pulse (cycle every 3 seconds)
	var pulse = (sin(crystal_pulse_time * 2.0) + 1.0) / 2.0  # 0 to 1
	var glow_alpha = 0.25 + (pulse * 0.35)  # 0.25 to 0.6

	crystal_glow.modulate.a = glow_alpha

	# Subtle color shift based on evolution
	var evolution = GameManager.get_world_evolution_normalized()
	var base_color = Color(0.92, 0.75, 0.35)  # Gold
	var evolved_color = Color(0.5, 0.9, 0.7)  # Green-cyan

	crystal_glow.color = base_color.lerp(evolved_color, evolution)
	crystal_glow.color.a = 0.5

	# Crystal also pulses slightly
	if center_crystal:
		center_crystal.modulate.a = 0.85 + (pulse * 0.15)


# ============ WISP SYSTEM FUNCTIONS ============

func _spawn_wisps() -> void:
	# Create a container for wisps
	var wisp_container = Node2D.new()
	wisp_container.name = "Wisps"
	isometric_base.add_child(wisp_container)

	for wisp_data in WISP_SPAWN_LOCATIONS:
		var wisp = _create_wisp(wisp_data)
		wisp_container.add_child(wisp)
		wisps.append(wisp)

	print("[Mindscape] Spawned ", wisps.size(), " collectible wisps")


func _create_wisp(data: Dictionary) -> Node2D:
	var wisp = Node2D.new()
	wisp.name = "Wisp_" + str(data.pos.x) + "_" + str(data.pos.y)
	wisp.position = data.pos
	wisp.set_meta("wisp_type", data.type)
	wisp.set_meta("wisp_xp", data.xp)
	wisp.set_meta("collected", false)

	var color = WISP_COLORS.get(data.type, Color(0.9, 0.9, 0.9))

	# Inner glow
	var inner = Polygon2D.new()
	inner.name = "Inner"
	inner.color = color
	var size = 8 if data.type in ["rare", "legendary"] else 6
	inner.polygon = PackedVector2Array([
		Vector2(-size, 0), Vector2(0, -size), Vector2(size, 0), Vector2(0, size)
	])
	wisp.add_child(inner)

	# Outer glow
	var outer = Polygon2D.new()
	outer.name = "Outer"
	outer.color = Color(color.r, color.g, color.b, 0.3)
	var outer_size = size * 2
	outer.polygon = PackedVector2Array([
		Vector2(-outer_size, 0), Vector2(0, -outer_size),
		Vector2(outer_size, 0), Vector2(0, outer_size)
	])
	outer.z_index = -1
	wisp.add_child(outer)

	# Particle trail
	var trail = Polygon2D.new()
	trail.name = "Trail"
	trail.color = Color(color.r, color.g, color.b, 0.15)
	trail.polygon = PackedVector2Array([
		Vector2(-3, 10), Vector2(0, 0), Vector2(3, 10)
	])
	trail.z_index = -2
	wisp.add_child(trail)

	return wisp


func _animate_wisps(delta: float) -> void:
	wisp_animation_time += delta

	for wisp in wisps:
		if not is_instance_valid(wisp) or wisp.get_meta("collected", false):
			continue

		# Floating bob animation
		var bob = sin(wisp_animation_time * 2.0 + wisp.position.x * 0.01) * 5.0
		wisp.position.y = wisp.get_meta("base_y", wisp.position.y) + bob

		# Store base position if not set
		if not wisp.has_meta("base_y"):
			wisp.set_meta("base_y", wisp.position.y)

		# Pulse glow
		var outer = wisp.get_node_or_null("Outer")
		if outer:
			var pulse = (sin(wisp_animation_time * 3.0 + wisp.position.x * 0.02) + 1.0) / 2.0
			outer.modulate.a = 0.5 + pulse * 0.5

		# Rotate slightly
		wisp.rotation = sin(wisp_animation_time * 1.5) * 0.2


func _check_wisp_collection() -> void:
	if not player:
		return

	var collection_radius = 50.0

	for wisp in wisps:
		if not is_instance_valid(wisp) or wisp.get_meta("collected", false):
			continue

		var distance = player.position.distance_to(wisp.position)
		if distance < collection_radius:
			_collect_wisp(wisp)


func _collect_wisp(wisp: Node2D) -> void:
	wisp.set_meta("collected", true)

	var wisp_type = wisp.get_meta("wisp_type", "focus")
	var xp = wisp.get_meta("wisp_xp", 5)

	# Award XP based on type
	var aspect = wisp_type
	if aspect in ["rare", "legendary"]:
		aspect = "discipline"  # Default aspect for special wisps

	GameManager.add_aspect_experience(aspect, xp)

	# Visual feedback - scale up and fade
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(wisp, "scale", Vector2(2, 2), 0.3)
	tween.tween_property(wisp, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(wisp.queue_free)

	# Show collection message
	var type_name = wisp_type.capitalize()
	if wisp_type == "legendary":
		_show_tutorial("Legendary Wisp!", "You found a rare legendary wisp!\n+" + str(xp) + " XP")
	elif wisp_type == "rare":
		print("[Mindscape] Collected rare wisp: +" + str(xp) + " XP")

	print("[Mindscape] Collected ", type_name, " wisp: +", xp, " XP")


# ============ NPC SPIRITS FUNCTIONS ============

func _spawn_npc_spirits() -> void:
	var npc_container = Node2D.new()
	npc_container.name = "NPCSpirits"
	isometric_base.add_child(npc_container)

	for npc_data in NPC_DEFINITIONS:
		var npc = _create_npc_spirit(npc_data)
		npc_container.add_child(npc)
		npc_spirits.append(npc)

	print("[Mindscape] Spawned ", npc_spirits.size(), " NPC spirits")


func _create_npc_spirit(data: Dictionary) -> Node2D:
	var npc = Node2D.new()
	npc.name = data.id
	npc.position = data.home_pos
	npc.set_meta("npc_data", data)
	npc.set_meta("wander_target", data.home_pos)
	npc.set_meta("wander_timer", randf() * 5.0)

	var aspect_colors = {
		"discipline": Color(0.83, 0.66, 0.29),
		"wisdom": Color(0.5, 0.6, 0.9),
		"courage": Color(0.9, 0.5, 0.4),
		"creativity": Color(0.7, 0.5, 0.8),
		"vitality": Color(0.5, 0.9, 0.6),
		"compassion": Color(0.9, 0.6, 0.7),
	}
	var color = aspect_colors.get(data.aspect, Color(0.8, 0.8, 0.9))

	# Spirit body (ethereal figure)
	var body = Polygon2D.new()
	body.name = "Body"
	body.color = Color(color.r, color.g, color.b, 0.7)
	body.polygon = PackedVector2Array([
		Vector2(-15, 30), Vector2(-20, 0), Vector2(-10, -30),
		Vector2(10, -30), Vector2(20, 0), Vector2(15, 30)
	])
	npc.add_child(body)

	# Spirit head
	var head = Polygon2D.new()
	head.name = "Head"
	head.color = Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, 0.8)
	head.position = Vector2(0, -40)
	head.polygon = PackedVector2Array([
		Vector2(-12, 10), Vector2(-12, -10), Vector2(12, -10), Vector2(12, 10)
	])
	npc.add_child(head)

	# Aura glow
	var aura = Polygon2D.new()
	aura.name = "Aura"
	aura.color = Color(color.r, color.g, color.b, 0.2)
	aura.polygon = PackedVector2Array([
		Vector2(-30, 40), Vector2(-35, 0), Vector2(-20, -45),
		Vector2(20, -45), Vector2(35, 0), Vector2(30, 40)
	])
	aura.z_index = -1
	npc.add_child(aura)

	# Name label
	var label = Label.new()
	label.name = "NameLabel"
	label.text = data.name
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-60, 45)
	label.visible = false  # Show on proximity
	npc.add_child(label)

	# Interaction area
	var area = Area2D.new()
	area.name = "InteractionArea"
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 60.0
	shape.shape = circle
	area.add_child(shape)
	npc.add_child(area)

	return npc


func _animate_npcs(delta: float) -> void:
	npc_animation_time += delta

	for npc in npc_spirits:
		if not is_instance_valid(npc):
			continue

		var data = npc.get_meta("npc_data", {})
		if data.is_empty():
			continue

		# Update wander timer
		var timer = npc.get_meta("wander_timer", 0.0) - delta
		npc.set_meta("wander_timer", timer)

		if timer <= 0:
			# Pick new wander target
			var home = data.get("home_pos", Vector2.ZERO)
			var radius = data.get("wander_radius", 100.0)
			var angle = randf() * TAU
			var dist = randf() * radius
			var new_target = home + Vector2(cos(angle), sin(angle)) * dist
			npc.set_meta("wander_target", new_target)
			npc.set_meta("wander_timer", 3.0 + randf() * 4.0)

		# Move toward target slowly
		var target = npc.get_meta("wander_target", npc.position)
		var direction = (target - npc.position).normalized()
		var speed = 20.0
		if npc.position.distance_to(target) > 5:
			npc.position += direction * speed * delta

		# Floating animation
		var float_offset = sin(npc_animation_time * 1.5 + npc.position.x * 0.01) * 3.0
		var body = npc.get_node_or_null("Body")
		if body:
			body.position.y = float_offset

		# Aura pulse
		var aura = npc.get_node_or_null("Aura")
		if aura:
			var pulse = (sin(npc_animation_time * 2.0) + 1.0) / 2.0
			aura.modulate.a = 0.6 + pulse * 0.4


func _check_npc_proximity() -> void:
	if not player:
		return

	var closest_npc: Node2D = null
	var closest_distance: float = 80.0  # Interaction radius

	for npc in npc_spirits:
		if not is_instance_valid(npc):
			continue

		var distance = player.position.distance_to(npc.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_npc = npc

		# Show/hide name based on proximity
		var label = npc.get_node_or_null("NameLabel")
		if label:
			label.visible = distance < 120

	if closest_npc and nearby_zone == "":
		var data = closest_npc.get_meta("npc_data", {})
		if data.has("name"):
			nearby_npc = closest_npc.name
			_show_npc_prompt(data.name)
	elif nearby_npc != "" and (not closest_npc or closest_distance >= 80):
		nearby_npc = ""
		if nearby_zone == "":
			_hide_interaction_prompt()


func _show_npc_prompt(npc_name: String) -> void:
	zone_name_label.text = npc_name
	zone_name_label.remove_theme_color_override("font_color")
	prompt_text_label.text = "Press SPACE to talk"
	prompt_text_label.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	interaction_prompt.visible = true
	control_hints.visible = false


func _talk_to_npc(npc_id: String) -> void:
	for npc in npc_spirits:
		if npc.name == npc_id:
			var data = npc.get_meta("npc_data", {})
			var dialogues = data.get("dialogues", ["..."])
			var dialogue = dialogues[randi() % dialogues.size()]

			# Record for campaign progress
			CampaignManager.record_aspect_talked(data.get("aspect", ""))

			_show_dialogue(data.get("name", "Spirit"), dialogue, _close_dialogue)
			return


# ============ SECRETS SYSTEM FUNCTIONS ============

func _spawn_secrets() -> void:
	var secrets_container = Node2D.new()
	secrets_container.name = "Secrets"
	isometric_base.add_child(secrets_container)

	for secret_data in SECRET_LOCATIONS:
		var secret = _create_secret(secret_data)
		secrets_container.add_child(secret)

	print("[Mindscape] Spawned ", SECRET_LOCATIONS.size(), " hidden secrets")


func _create_secret(data: Dictionary) -> Node2D:
	var secret = Node2D.new()
	secret.name = data.id
	secret.position = data.pos
	secret.set_meta("secret_data", data)
	secret.set_meta("discovered", data.id in secrets_found)

	# Subtle glow (more visible when not discovered)
	var glow = Polygon2D.new()
	glow.name = "Glow"
	glow.color = Color(0.9, 0.8, 0.5, 0.15)
	glow.polygon = PackedVector2Array([
		Vector2(-20, 0), Vector2(0, -20), Vector2(20, 0), Vector2(0, 20)
	])
	secret.add_child(glow)

	# Hidden marker (only visible up close)
	var marker = Polygon2D.new()
	marker.name = "Marker"
	marker.color = Color(0.9, 0.85, 0.4, 0.0)  # Start invisible
	marker.polygon = PackedVector2Array([
		Vector2(-8, 0), Vector2(0, -12), Vector2(8, 0), Vector2(0, 8)
	])
	secret.add_child(marker)

	if data.id in secrets_found:
		glow.color.a = 0.05  # Dimmer if already found
		marker.color.a = 0.3

	return secret


func _check_secret_discovery() -> void:
	if not player:
		return

	var secrets_container = isometric_base.get_node_or_null("Secrets")
	if not secrets_container:
		return

	for secret in secrets_container.get_children():
		var distance = player.position.distance_to(secret.position)
		var data = secret.get_meta("secret_data", {})

		# Show marker when close
		var marker = secret.get_node_or_null("Marker")
		if marker:
			var target_alpha = 0.8 if distance < 60 else 0.0
			marker.color.a = lerp(marker.color.a, target_alpha, 0.1)

		# Discover when very close
		if distance < 30 and data.id not in secrets_found:
			_discover_secret(secret, data)


func _discover_secret(secret: Node2D, data: Dictionary) -> void:
	secrets_found.append(data.id)
	secret.set_meta("discovered", true)

	# Award XP
	var xp = data.get("reward_xp", 10)
	GameManager.add_aspect_experience("wisdom", xp)

	# Show lore
	_show_dialogue(data.get("name", "Secret"), data.get("lore", "You found something..."), _close_dialogue)

	# Dim the glow
	var glow = secret.get_node_or_null("Glow")
	if glow:
		var tween = create_tween()
		tween.tween_property(glow, "color:a", 0.05, 1.0)

	print("[Mindscape] Discovered secret: ", data.name, " +", xp, " XP")


# ============ AMBIENT ANIMATION ============

func _animate_ambient(delta: float) -> void:
	ambient_time += delta

	# Animate ambient particles
	var particles = isometric_base.get_node_or_null("AmbientParticles")
	if particles:
		for particle in particles.get_children():
			# Gentle floating motion
			var offset = Vector2(
				sin(ambient_time * 0.5 + particle.position.x * 0.01) * 2,
				cos(ambient_time * 0.3 + particle.position.y * 0.01) * 3
			)
			if not particle.has_meta("base_pos"):
				particle.set_meta("base_pos", particle.position)
			particle.position = particle.get_meta("base_pos") + offset

			# Gentle pulse
			var pulse = (sin(ambient_time * 2.0 + particle.position.x * 0.02) + 1.0) / 2.0
			particle.modulate.a = 0.5 + pulse * 0.5


# ============ EXIT PORTAL (CENTER CRYSTAL) ============

func _check_exit_portal_proximity() -> void:
	if not player:
		return

	var distance = player.position.distance_to(EXIT_PORTAL_POSITION)
	var was_near = near_exit_portal

	near_exit_portal = distance < EXIT_PORTAL_RADIUS

	# Show/hide prompt based on proximity
	if near_exit_portal and not was_near:
		# Only show if not near zone or NPC
		if nearby_zone == "" and nearby_npc == "":
			_show_exit_portal_prompt()
	elif not near_exit_portal and was_near:
		if nearby_zone == "" and nearby_npc == "":
			_hide_interaction_prompt()


func _show_exit_portal_prompt() -> void:
	zone_name_label.text = "Neural Link Crystal"
	zone_name_label.add_theme_color_override("font_color", ThemeConfig.GOACTO_GOLD)
	prompt_text_label.text = "Press SPACE to remove headset"
	prompt_text_label.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	interaction_prompt.visible = true
	control_hints.visible = false


func _show_exit_portal_dialog() -> void:
	# Show confirmation dialog
	_show_dialogue(
		"Remove Headset?",
		"Disconnecting from the mindscape will return you to your cabin on the Stellar Wanderer.\n\nYour human's progress will be saved.",
		_confirm_exit_to_bedroom
	)


func _confirm_exit_to_bedroom() -> void:
	_close_dialogue()

	# Save game state
	SaveManager.save_game()

	# Use visual transition back to bedroom
	GameManager.player_data["entered_from_bedroom"] = false
	GameManager.player_data["transition_type"] = "exit"
	GameManager.player_data["transition_target"] = "res://scenes/bedroom/bedroom.tscn"
	get_tree().change_scene_to_file("res://scenes/transition/headset_transition.tscn")


func _update_header() -> void:
	var evolution = GameManager.player_data.world_evolution_level
	evolution_label.text = "Evolution: " + str(int(evolution)) + "%"
	evolution_bar.value = evolution
	date_label.text = Time.get_date_string_from_system()

	# Update chapter indicator
	var current_chapter = CampaignManager.get_current_chapter()
	if not current_chapter.is_empty():
		var chapter_num = current_chapter.id.split("_")[1] if "_" in current_chapter.id else "1"
		chapter_button.text = "Ch." + chapter_num + ": " + current_chapter.name
	else:
		chapter_button.text = "Chapter 1"


func _update_base_visuals() -> void:
	var evolution = GameManager.get_world_evolution_normalized()
	growth_layer.modulate.a = evolution * 0.8


## Update visual state of all zones based on lock status
func _update_zone_lock_visuals() -> void:
	for zone in zones_node.get_children():
		var is_locked = not GameManager.is_zone_unlocked(zone.name)
		var tier = GameManager.get_zone_tier(zone.name)

		# Get or create lock overlay
		var lock_overlay = zone.get_node_or_null("LockOverlay")
		if not lock_overlay:
			lock_overlay = _create_lock_overlay(zone, tier)

		if is_locked:
			# Brighter locked zones - still visible but desaturated
			var brightness = 0.6 - (tier * 0.03)  # Tier 2: 0.54, Tier 6: 0.42
			brightness = clampf(brightness, 0.4, 0.6)
			zone.modulate = Color(brightness, brightness, brightness + 0.05, 0.85)
			lock_overlay.visible = true

			# Update tier label and progress on overlay
			var tier_label = lock_overlay.get_node_or_null("TierLabel")
			if tier_label:
				tier_label.text = "Tier " + str(tier)

			# Update progress indicator
			var progress_label = lock_overlay.get_node_or_null("ProgressLabel")
			if progress_label:
				var progress_text = _get_unlock_progress_text(zone.name)
				progress_label.text = progress_text
		else:
			# Full brightness
			zone.modulate = Color(1, 1, 1, 1)
			lock_overlay.visible = false


## Create a lock overlay for a zone
func _create_lock_overlay(zone: Node2D, tier: int = 2) -> Node2D:
	var overlay = Node2D.new()
	overlay.name = "LockOverlay"

	# Tier colors (higher tiers have more prestigious colors)
	var tier_colors = {
		2: Color(0.7, 0.55, 0.3, 1),    # Bronze
		3: Color(0.75, 0.75, 0.8, 1),   # Silver
		4: Color(0.9, 0.75, 0.2, 1),    # Gold
		5: Color(0.5, 0.85, 0.95, 1),   # Diamond
		6: Color(0.85, 0.45, 0.95, 1)   # Cosmic
	}
	var lock_color = tier_colors.get(tier, ThemeConfig.CHAPTER_LOCKED)

	# Create LARGER lock icon (1.5x size)
	var lock_body = Polygon2D.new()
	lock_body.color = lock_color
	lock_body.polygon = PackedVector2Array([
		Vector2(-22, 0), Vector2(-22, 38), Vector2(22, 38), Vector2(22, 0)
	])
	lock_body.position = Vector2(0, -60)
	overlay.add_child(lock_body)

	var lock_shackle = Polygon2D.new()
	lock_shackle.color = lock_color
	lock_shackle.polygon = PackedVector2Array([
		Vector2(-15, 0), Vector2(-15, -22), Vector2(-10, -27),
		Vector2(10, -27), Vector2(15, -22), Vector2(15, 0),
		Vector2(10, 0), Vector2(10, -18), Vector2(-10, -18), Vector2(-10, 0)
	])
	lock_shackle.position = Vector2(0, -60)
	overlay.add_child(lock_shackle)

	# Tier number inside lock
	var tier_num = Label.new()
	tier_num.name = "TierNum"
	tier_num.text = str(tier)
	tier_num.add_theme_font_size_override("font_size", 20)
	tier_num.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1))
	tier_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_num.position = Vector2(-8, -52)
	overlay.add_child(tier_num)

	# Add a subtle glow/border
	var lock_glow = Polygon2D.new()
	lock_glow.color = Color(lock_color.r, lock_color.g, lock_color.b, 0.4)
	lock_glow.polygon = PackedVector2Array([
		Vector2(-30, 8), Vector2(-30, 45), Vector2(30, 45), Vector2(30, 8),
		Vector2(22, -30), Vector2(-22, -30)
	])
	lock_glow.position = Vector2(0, -60)
	lock_glow.z_index = -1
	overlay.add_child(lock_glow)

	# Add tier label
	var tier_label = Label.new()
	tier_label.name = "TierLabel"
	tier_label.text = "Tier " + str(tier)
	tier_label.add_theme_font_size_override("font_size", 16)
	tier_label.add_theme_color_override("font_color", lock_color)
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.position = Vector2(-30, -15)
	overlay.add_child(tier_label)

	# Add progress label (shows "15% / 25%")
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = ""
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 1))
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.position = Vector2(-40, 0)
	overlay.add_child(progress_label)

	zone.add_child(overlay)
	return overlay


## Get progress text for a locked zone
func _get_unlock_progress_text(zone_id: String) -> String:
	if not GameManager.ZONE_TIERS.has(zone_id):
		return ""

	var zone_info = GameManager.ZONE_TIERS[zone_id]
	var requirement = zone_info.get("requirement", "")
	var value = zone_info.get("value", 0)

	match requirement:
		"evolution":
			var current = GameManager.player_data.world_evolution_level
			return "%.0f%% / %.0f%%" % [current, value]
		"chapter":
			var chapter_id = "chapter_" + str(value)
			if CampaignManager.is_chapter_completed(chapter_id):
				return "Ready!"
			else:
				return "Ch." + str(value) + " needed"
		_:
			return ""


## Update gate barriers based on zone unlock status
func _update_gate_barriers() -> void:
	var gates = {
		"NorthGate": north_gate,
		"EastGate": east_gate,
		"WestGate": west_gate,
		"SouthGate": south_gate
	}

	for gate_name in gates:
		var gate = gates[gate_name]
		if not gate:
			continue

		var is_locked = _is_gate_locked(gate_name)

		# Get gate elements
		var door = gate.get_node_or_null("GateDoor")
		var barrier = gate.get_node_or_null("GateBarrier")
		var lock_icon = gate.get_node_or_null("GateLock")

		if is_locked:
			# Show door and enable collision
			if door:
				door.visible = true
			if barrier:
				barrier.set_collision_layer_value(1, true)
				barrier.set_collision_mask_value(1, true)
			if lock_icon:
				lock_icon.visible = true
		else:
			# Hide door and disable collision
			if door:
				door.visible = false
			if barrier:
				barrier.set_collision_layer_value(1, false)
				barrier.set_collision_mask_value(1, false)
			if lock_icon:
				lock_icon.visible = false


## Check if a gate is locked based on required zone unlocks
func _is_gate_locked(gate_name: String) -> bool:
	if not gate_requirements.has(gate_name):
		return false

	var required_zones = gate_requirements[gate_name]
	for zone_id in required_zones:
		if GameManager.is_zone_unlocked(zone_id):
			return false  # At least one required zone is unlocked

	return true  # All required zones are still locked


## Called when a room is unlocked via CampaignManager
func _on_room_unlocked(room_id: String) -> void:
	_update_zone_lock_visuals()

	# Find the zone node for this room
	var zone_node_name = ""
	for zone_id in zone_to_room:
		if zone_to_room[zone_id] == room_id:
			zone_node_name = zone_id
			break

	if zone_node_name != "":
		var zone_name = zone_names.get(zone_node_name, zone_node_name)
		_show_dialogue("Zone Unlocked!", zone_name + " is now accessible!\n\nExplore it to discover new abilities.", _close_dialogue)
		print("[Mindscape] Room unlocked: ", room_id)


## Called when a chapter is completed
func _on_chapter_completed(chapter_id: String) -> void:
	_update_header()
	_update_zone_lock_visuals()

	var chapter = CampaignManager.CHAPTERS.get(chapter_id, {})
	if not chapter.is_empty():
		_show_dialogue(
			"Chapter Complete!",
			"You completed: " + chapter.name + "\n\nYour journey continues...",
			_close_dialogue
		)
	print("[Mindscape] Chapter completed: ", chapter_id)


## Called when a trophy is earned
func _on_trophy_earned(trophy: Dictionary) -> void:
	var tier_names = {
		CampaignManager.TrophyTier.BRONZE: "Bronze",
		CampaignManager.TrophyTier.SILVER: "Silver",
		CampaignManager.TrophyTier.GOLD: "Gold",
		CampaignManager.TrophyTier.PLATINUM: "Platinum"
	}
	var tier_name = tier_names.get(trophy.tier, "")
	_show_dialogue(
		"Trophy Earned!",
		tier_name + " Trophy: " + trophy.name + "\n\n" + trophy.description,
		_close_dialogue
	)
	print("[Mindscape] Trophy earned: ", trophy.name)


func _show_zone_panel(title: String) -> void:
	current_zone = title
	zone_title.text = title
	in_zone_panel = true

	# Clear previous content
	for child in zone_body.get_children():
		child.queue_free()

	game_world.visible = false
	interaction_prompt.visible = false
	control_hints.visible = false
	zone_panel.visible = true


func _close_zone() -> void:
	current_zone = ""
	in_zone_panel = false
	zone_panel.visible = false
	game_world.visible = true
	control_hints.visible = true

	# Re-check if we're still near a zone
	if nearby_zone != "":
		_show_interaction_prompt(nearby_zone)


# ============ FOCUS CHAMBER ============
func _open_focus_zone() -> void:
	if not GameManager.has_seen_tutorial("zone_focus"):
		var tut = zone_tutorials.focus
		GameManager.mark_tutorial_seen("zone_focus")
		_show_dialogue("Focus Chamber", tut.text, func():
			_close_dialogue()
			_do_open_focus_zone()
		)
		return
	_do_open_focus_zone()


# Focus difficulty selection
var selected_focus_difficulty: int = 0  # 0 = EASY, 1 = HARD

func _do_open_focus_zone() -> void:
	_show_zone_panel("Focus Chamber")

	var desc = Label.new()
	desc.text = "Begin a focused 25-minute session."
	desc.add_theme_font_size_override("font_size", 22)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(desc)

	# Difficulty selection
	var diff_row = HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 15)

	var easy_btn = Button.new()
	easy_btn.text = "EASY (0.7x)"
	easy_btn.toggle_mode = true
	easy_btn.button_pressed = (selected_focus_difficulty == 0)
	easy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	easy_btn.custom_minimum_size = Vector2(0, 60)
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
	hard_btn.custom_minimum_size = Vector2(0, 60)
	hard_btn.add_theme_font_size_override("font_size", 18)
	hard_btn.name = "HardBtn"
	hard_btn.tooltip_text = "Must complete 90%+ of session. Higher XP rewards."
	hard_btn.pressed.connect(_select_focus_difficulty.bind(1))
	diff_row.add_child(hard_btn)

	zone_body.add_child(diff_row)

	# Quick Start section
	_add_section_label("Quick Start")

	var quick_btn = Button.new()
	quick_btn.text = "Quick 25-min Session"
	quick_btn.custom_minimum_size = Vector2(0, 70)
	quick_btn.add_theme_font_size_override("font_size", 22)
	quick_btn.pressed.connect(_start_quick_focus)
	zone_body.add_child(quick_btn)

	# Your Topics section
	_add_section_label("Your Topics")

	var all_topics = HabitManager.get_all_topics()
	for topic in all_topics:
		var is_completed = HabitManager.is_topic_completed_today(topic.id)
		var btn = Button.new()
		if is_completed:
			btn.text = topic.name + "  (Done today)"
			btn.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
		else:
			btn.text = topic.name
		btn.custom_minimum_size = Vector2(0, 60)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_start_topic_focus.bind(topic.id, topic.name))
		zone_body.add_child(btn)

	# Add new topic button
	var add_topic_btn = Button.new()
	add_topic_btn.text = "+ Add New Topic"
	add_topic_btn.custom_minimum_size = Vector2(0, 55)
	add_topic_btn.add_theme_font_size_override("font_size", 18)
	add_topic_btn.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	add_topic_btn.pressed.connect(_show_add_topic_dialog)
	zone_body.add_child(add_topic_btn)

	# Habits section
	var all_habits = HabitManager.get_all_habits()
	if all_habits.size() > 0:
		_add_section_label("Habits")

		for habit in all_habits:
			var is_completed = HabitManager.is_completed_today(habit.id)
			var btn = Button.new()
			if is_completed:
				btn.text = habit.name + "  (Done today)"
				btn.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
			else:
				btn.text = habit.name
			btn.custom_minimum_size = Vector2(0, 60)
			btn.add_theme_font_size_override("font_size", 20)
			btn.pressed.connect(_start_habit_focus.bind(habit.id, habit.name))
			zone_body.add_child(btn)

	# Scripts section (from Script Lab)
	var all_scripts = ScriptManager.scripts.values()
	if all_scripts.size() > 0:
		_add_section_label("Scripts")

		for script in all_scripts:
			var btn = Button.new()
			btn.text = script.name + ".psa"
			btn.custom_minimum_size = Vector2(0, 60)
			btn.add_theme_font_size_override("font_size", 20)
			btn.add_theme_color_override("font_color", ScriptManager.get_type_color(script.type))
			btn.pressed.connect(_start_script_focus.bind(script.id, script.name))
			zone_body.add_child(btn)


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


func _select_focus_difficulty(diff: int) -> void:
	selected_focus_difficulty = diff
	var easy_btn = zone_body.find_child("EasyBtn", true, false)
	var hard_btn = zone_body.find_child("HardBtn", true, false)
	if easy_btn: easy_btn.button_pressed = (diff == 0)
	if hard_btn: hard_btn.button_pressed = (diff == 1)


func _start_quick_focus() -> void:
	GameManager.player_data["pending_focus"] = {
		"topic": "Focus Session",
		"duration": 25,
		"difficulty": selected_focus_difficulty
	}
	GameManager.goto_scene("res://scenes/focus_mode/focus_mode.tscn")


func _start_habit_focus(habit_id: String, habit_name: String) -> void:
	GameManager.player_data["pending_focus"] = {
		"habit_id": habit_id,
		"topic": habit_name,
		"duration": 25,
		"difficulty": selected_focus_difficulty
	}
	GameManager.goto_scene("res://scenes/focus_mode/focus_mode.tscn")


func _start_topic_focus(topic_id: String, topic_name: String) -> void:
	GameManager.player_data["pending_focus"] = {
		"topic_id": topic_id,
		"topic": topic_name,
		"duration": 25,
		"difficulty": selected_focus_difficulty
	}
	GameManager.goto_scene("res://scenes/focus_mode/focus_mode.tscn")


func _start_script_focus(script_id: String, script_name: String) -> void:
	GameManager.player_data["pending_focus"] = {
		"script_id": script_id,
		"topic": script_name + ".psa",
		"duration": 25,
		"difficulty": selected_focus_difficulty
	}
	GameManager.goto_scene("res://scenes/focus_mode/focus_mode.tscn")


# Topic creation dialog
var topic_dialog: PanelContainer = null
var topic_input: LineEdit = null

func _show_add_topic_dialog() -> void:
	if topic_dialog:
		topic_dialog.queue_free()

	topic_dialog = PanelContainer.new()
	topic_dialog.custom_minimum_size = Vector2(500, 200)
	topic_dialog.anchors_preset = Control.PRESET_CENTER
	topic_dialog.set_anchors_preset(Control.PRESET_CENTER)
	add_child(topic_dialog)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	topic_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Add New Topic"
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	topic_input = LineEdit.new()
	topic_input.placeholder_text = "e.g., Guitar, Reading, Coding..."
	topic_input.custom_minimum_size = Vector2(0, 50)
	topic_input.add_theme_font_size_override("font_size", 22)
	vbox.add_child(topic_input)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.custom_minimum_size = Vector2(0, 50)
	cancel_btn.pressed.connect(_close_topic_dialog)
	btn_row.add_child(cancel_btn)

	var create_btn = Button.new()
	create_btn.text = "Create"
	create_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_btn.custom_minimum_size = Vector2(0, 50)
	create_btn.pressed.connect(_create_topic_from_dialog)
	btn_row.add_child(create_btn)

	vbox.add_child(btn_row)

	# Focus the input
	topic_input.grab_focus()


func _close_topic_dialog() -> void:
	if topic_dialog:
		topic_dialog.queue_free()
		topic_dialog = null
		topic_input = null


func _create_topic_from_dialog() -> void:
	if not topic_input or topic_input.text.strip_edges().is_empty():
		return

	var topic_name = topic_input.text.strip_edges()
	HabitManager.create_topic(topic_name)
	_close_topic_dialog()

	# Refresh the Focus Chamber
	_do_open_focus_zone()


# ============ REFLECTION POOL (Journal) ============
func _open_journal_zone() -> void:
	if not GameManager.has_seen_tutorial("zone_journal"):
		var tut = zone_tutorials.journal
		GameManager.mark_tutorial_seen("zone_journal")
		_show_dialogue("Reflection Pool", tut.text, func():
			_close_dialogue()
			_do_open_journal_zone()
		)
		return
	_do_open_journal_zone()


func _do_open_journal_zone() -> void:
	_show_zone_panel("Reflection Pool")

	var journal = _load_journal()

	if journal.is_empty():
		var empty_panel = PanelContainer.new()
		var empty_margin = MarginContainer.new()
		empty_margin.add_theme_constant_override("margin_left", 40)
		empty_margin.add_theme_constant_override("margin_right", 40)
		empty_margin.add_theme_constant_override("margin_top", 60)
		empty_margin.add_theme_constant_override("margin_bottom", 60)

		var empty_label = Label.new()
		empty_label.text = "Your journal is empty.\n\nComplete focus sessions to add entries.\nEach session ends with a reflection that gets saved here."
		empty_label.add_theme_font_size_override("font_size", 26)
		empty_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		empty_margin.add_child(empty_label)
		empty_panel.add_child(empty_margin)
		zone_body.add_child(empty_panel)
		return

	var desc = Label.new()
	desc.text = "Recent Reflections"
	desc.add_theme_font_size_override("font_size", 28)
	desc.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	zone_body.add_child(desc)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	zone_body.add_child(spacer)

	var recent = journal.slice(-5)
	recent.reverse()

	for entry in recent:
		var entry_panel = PanelContainer.new()
		var entry_margin = MarginContainer.new()
		entry_margin.add_theme_constant_override("margin_left", 25)
		entry_margin.add_theme_constant_override("margin_right", 25)
		entry_margin.add_theme_constant_override("margin_top", 20)
		entry_margin.add_theme_constant_override("margin_bottom", 20)

		var entry_vbox = VBoxContainer.new()
		entry_vbox.add_theme_constant_override("separation", 15)

		var date_label_entry = Label.new()
		date_label_entry.text = str(entry.get("date", "")) + " - " + str(entry.get("topic", "Session"))
		date_label_entry.add_theme_font_size_override("font_size", 26)
		date_label_entry.add_theme_color_override("font_color", Color(0.5, 0.75, 0.85))
		entry_vbox.add_child(date_label_entry)

		if entry.get("learned", "") != "":
			var learned_row = HBoxContainer.new()
			learned_row.add_theme_constant_override("separation", 15)

			var learned_icon = Label.new()
			learned_icon.text = "Learned:"
			learned_icon.add_theme_font_size_override("font_size", 22)
			learned_icon.add_theme_color_override("font_color", Color(0.5, 0.65, 0.55))
			learned_icon.custom_minimum_size = Vector2(130, 0)
			learned_row.add_child(learned_icon)

			var learned = Label.new()
			learned.text = entry.learned
			learned.add_theme_font_size_override("font_size", 24)
			learned.autowrap_mode = TextServer.AUTOWRAP_WORD
			learned.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			learned_row.add_child(learned)

			entry_vbox.add_child(learned_row)

		if entry.get("accomplished", "") != "":
			var done_row = HBoxContainer.new()
			done_row.add_theme_constant_override("separation", 15)

			var done_icon = Label.new()
			done_icon.text = "Done:"
			done_icon.add_theme_font_size_override("font_size", 22)
			done_icon.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
			done_icon.custom_minimum_size = Vector2(130, 0)
			done_row.add_child(done_icon)

			var done = Label.new()
			done.text = entry.accomplished
			done.add_theme_font_size_override("font_size", 24)
			done.autowrap_mode = TextServer.AUTOWRAP_WORD
			done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			done_row.add_child(done)

			entry_vbox.add_child(done_row)

		if entry.get("next_goals", "") != "":
			var next_row = HBoxContainer.new()
			next_row.add_theme_constant_override("separation", 15)

			var next_icon = Label.new()
			next_icon.text = "Next:"
			next_icon.add_theme_font_size_override("font_size", 22)
			next_icon.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5))
			next_icon.custom_minimum_size = Vector2(130, 0)
			next_row.add_child(next_icon)

			var next = Label.new()
			next.text = entry.next_goals
			next.add_theme_font_size_override("font_size", 24)
			next.autowrap_mode = TextServer.AUTOWRAP_WORD
			next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			next_row.add_child(next)

			entry_vbox.add_child(next_row)

		entry_margin.add_child(entry_vbox)
		entry_panel.add_child(entry_margin)
		zone_body.add_child(entry_panel)


func _load_journal() -> Array:
	var journal_path = SaveManager.get_journal_path()
	if not FileAccess.file_exists(journal_path):
		return []
	var file = FileAccess.open(journal_path, FileAccess.READ)
	if not file:
		return []
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return []
	var data = json.get_data()
	return data if data is Array else []


# ============ ASPECT SHRINE ============
func _open_aspects_zone() -> void:
	if not GameManager.has_seen_tutorial("zone_aspects"):
		var tut = zone_tutorials.aspects
		GameManager.mark_tutorial_seen("zone_aspects")
		_show_dialogue("Aspect Shrine", tut.text, func():
			_close_dialogue()
			_do_open_aspects_zone()
		)
		return
	_do_open_aspects_zone()


func _do_open_aspects_zone() -> void:
	_show_zone_panel("Aspect Shrine")

	var desc = Label.new()
	desc.text = "Your Aspects represent parts of yourself.\nThey grow stronger as you develop related habits."
	desc.add_theme_font_size_override("font_size", 22)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(desc)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	zone_body.add_child(spacer)

	for aspect_key in GameManager.player_data.aspects:
		var aspect = GameManager.player_data.aspects[aspect_key]
		_add_aspect_display(aspect_key, aspect)


func _add_aspect_display(key: String, aspect: Dictionary) -> void:
	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)

	var color_rect = ColorRect.new()
	color_rect.custom_minimum_size = Vector2(10, 80)
	color_rect.color = aspect.color
	hbox.add_child(color_rect)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)

	var name_label = Label.new()
	var lock_text = "" if aspect.unlocked else " [Locked]"
	name_label.text = aspect.name + " Lv." + str(aspect.level) + lock_text
	name_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(name_label)

	var domain_label = Label.new()
	domain_label.text = aspect.domain.capitalize() + " | " + aspect.personality
	domain_label.add_theme_font_size_override("font_size", 18)
	domain_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(domain_label)

	var progress = ProgressBar.new()
	progress.custom_minimum_size = Vector2(0, 18)
	progress.max_value = aspect.level * 100
	progress.value = aspect.experience
	progress.show_percentage = false
	vbox.add_child(progress)

	hbox.add_child(vbox)

	if aspect.unlocked:
		var talk_btn = Button.new()
		talk_btn.text = "Talk"
		talk_btn.custom_minimum_size = Vector2(100, 70)
		talk_btn.add_theme_font_size_override("font_size", 20)
		talk_btn.pressed.connect(_talk_to_aspect.bind(key))
		hbox.add_child(talk_btn)

	panel.add_child(hbox)
	zone_body.add_child(panel)


func _talk_to_aspect(aspect_key: String) -> void:
	var aspect = GameManager.player_data.aspects[aspect_key]
	var dialogues = {
		"discipline": "Consistency is the foundation. Show up each day, and I grow stronger.",
		"courage": "Growth lies beyond comfort. Face what scares you, and I'll be there.",
		"creativity": "Play, explore, make mistakes! That's where the magic happens.",
		"compassion": "Be gentle with yourself and others. Kindness ripples outward.",
		"wisdom": "Pause. Reflect. The answers often emerge from stillness.",
		"vitality": "Your body is the vessel. Move it, fuel it, rest it well."
	}
	_show_dialogue(aspect.name, dialogues.get(aspect_key, "..."), _close_dialogue)


# ============ GOAL COMPASS ============
var creating_goal: bool = false
var new_goal_data: Dictionary = {}

func _open_goals_zone() -> void:
	if not GameManager.has_seen_tutorial("zone_goals"):
		var tut = zone_tutorials.goals
		GameManager.mark_tutorial_seen("zone_goals")
		_show_dialogue("Goal Compass", tut.text, func():
			_close_dialogue()
			_do_open_goals_zone()
		)
		return
	_do_open_goals_zone()


func _do_open_goals_zone() -> void:
	creating_goal = false
	_show_zone_panel("Goal Compass")
	_show_goals_main_view()


func _show_goals_main_view() -> void:
	# Clear all children immediately (not deferred)
	for child in zone_body.get_children():
		child.free()

	# Tab buttons
	var tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 20)

	var daily_btn = Button.new()
	daily_btn.text = "Today"
	daily_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daily_btn.custom_minimum_size = Vector2(0, 80)
	daily_btn.add_theme_font_size_override("font_size", 26)
	daily_btn.pressed.connect(_show_daily_goals)
	tab_row.add_child(daily_btn)

	var weekly_btn = Button.new()
	weekly_btn.text = "This Week"
	weekly_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weekly_btn.custom_minimum_size = Vector2(0, 80)
	weekly_btn.add_theme_font_size_override("font_size", 26)
	weekly_btn.pressed.connect(_show_weekly_goals)
	tab_row.add_child(weekly_btn)

	var milestone_btn = Button.new()
	milestone_btn.text = "Milestones"
	milestone_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	milestone_btn.custom_minimum_size = Vector2(0, 80)
	milestone_btn.add_theme_font_size_override("font_size", 26)
	milestone_btn.pressed.connect(_show_milestone_goals)
	tab_row.add_child(milestone_btn)

	zone_body.add_child(tab_row)

	# Add new goal button
	var add_btn = Button.new()
	add_btn.text = "+ New Goal"
	add_btn.custom_minimum_size = Vector2(0, 100)
	add_btn.add_theme_font_size_override("font_size", 30)
	add_btn.pressed.connect(_show_goal_creation)
	zone_body.add_child(add_btn)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 25)
	zone_body.add_child(spacer)

	# Goal list container (so we can clear just the goals)
	var goal_list = VBoxContainer.new()
	goal_list.name = "GoalList"
	goal_list.add_theme_constant_override("separation", 15)
	zone_body.add_child(goal_list)

	_show_daily_goals()


func _show_daily_goals() -> void:
	_clear_goal_list()
	var goals = GoalManager.get_todays_goals()
	if goals.is_empty():
		_add_empty_goals_message("No daily intentions set.\nTap '+ New Goal' to add one.")
	else:
		for goal in goals:
			_add_goal_display(goal)


func _show_weekly_goals() -> void:
	_clear_goal_list()
	var goals = GoalManager.get_weekly_goals()
	if goals.is_empty():
		_add_empty_goals_message("No weekly objectives set.\nTap '+ New Goal' to add one.")
	else:
		for goal in goals:
			_add_goal_display(goal)


func _show_milestone_goals() -> void:
	_clear_goal_list()
	var goals = GoalManager.get_milestone_goals()
	if goals.is_empty():
		_add_empty_goals_message("No milestone goals set.\nThese are bigger targets you work toward over time.")
	else:
		for goal in goals:
			_add_goal_display(goal)


func _get_goal_list() -> VBoxContainer:
	return zone_body.find_child("GoalList", false, false) as VBoxContainer


func _clear_goal_list() -> void:
	var goal_list = _get_goal_list()
	if goal_list:
		for child in goal_list.get_children():
			child.free()


func _add_empty_goals_message(text: String) -> void:
	var goal_list = _get_goal_list()
	if not goal_list:
		return

	var panel = PanelContainer.new()
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)

	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	margin.add_child(label)
	panel.add_child(margin)
	goal_list.add_child(panel)


func _add_goal_display(goal: Dictionary) -> void:
	var goal_list = _get_goal_list()
	if not goal_list:
		return

	var panel = PanelContainer.new()
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 25)

	var checkbox = CheckBox.new()
	checkbox.button_pressed = goal.status == GoalManager.GoalStatus.COMPLETED
	checkbox.disabled = goal.status == GoalManager.GoalStatus.COMPLETED
	checkbox.toggled.connect(_on_goal_checked.bind(goal.id))
	checkbox.custom_minimum_size = Vector2(40, 40)
	hbox.add_child(checkbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)

	var title_label = Label.new()
	title_label.text = goal.title
	title_label.add_theme_font_size_override("font_size", 28)
	if goal.status == GoalManager.GoalStatus.COMPLETED:
		title_label.add_theme_color_override("font_color", Color(0.4, 0.75, 0.5))
	vbox.add_child(title_label)

	var aspect_data = GameManager.player_data.aspects.get(goal.aspect, {})
	var aspect_name = aspect_data.get("name", goal.aspect.capitalize())

	var meta_label = Label.new()
	meta_label.text = aspect_name + " | +" + str(goal.exp_reward) + " XP"
	meta_label.add_theme_font_size_override("font_size", 22)
	meta_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	vbox.add_child(meta_label)

	if goal.timeframe == GoalManager.GoalTimeframe.MILESTONE and goal.target_progress > 1:
		var progress_hbox = HBoxContainer.new()
		progress_hbox.add_theme_constant_override("separation", 20)

		var progress_bar = ProgressBar.new()
		progress_bar.custom_minimum_size = Vector2(0, 24)
		progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_bar.max_value = goal.target_progress
		progress_bar.value = goal.progress
		progress_bar.show_percentage = false
		progress_hbox.add_child(progress_bar)

		var progress_label = Label.new()
		progress_label.text = str(goal.progress) + "/" + str(goal.target_progress)
		progress_label.add_theme_font_size_override("font_size", 22)
		progress_hbox.add_child(progress_label)

		var increment_btn = Button.new()
		increment_btn.text = "+1"
		increment_btn.custom_minimum_size = Vector2(90, 60)
		increment_btn.add_theme_font_size_override("font_size", 24)
		increment_btn.pressed.connect(_increment_goal.bind(goal.id))
		progress_hbox.add_child(increment_btn)

		vbox.add_child(progress_hbox)

	hbox.add_child(vbox)
	margin.add_child(hbox)
	panel.add_child(margin)
	goal_list.add_child(panel)


func _on_goal_checked(toggled: bool, goal_id: String) -> void:
	if toggled:
		GoalManager.complete_goal(goal_id)
		_show_goals_main_view()


func _increment_goal(goal_id: String) -> void:
	GoalManager.increment_progress(goal_id)
	_show_goals_main_view()


func _show_goal_creation() -> void:
	creating_goal = true
	new_goal_data = {
		"timeframe": GoalManager.GoalTimeframe.DAILY,
		"aspect": "discipline",
		"target_progress": 1
	}

	for child in zone_body.get_children():
		child.queue_free()

	var title_label = Label.new()
	title_label.text = "Create New Goal"
	title_label.add_theme_font_size_override("font_size", 24)
	zone_body.add_child(title_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	zone_body.add_child(spacer)

	var title_input_label = Label.new()
	title_input_label.text = "What's your goal?"
	zone_body.add_child(title_input_label)

	var title_input = LineEdit.new()
	title_input.placeholder_text = "Enter goal title..."
	title_input.custom_minimum_size = Vector2(0, 50)
	title_input.name = "TitleInput"
	zone_body.add_child(title_input)

	var time_label = Label.new()
	time_label.text = "\nTimeframe:"
	zone_body.add_child(time_label)

	var time_row = HBoxContainer.new()
	time_row.add_theme_constant_override("separation", 10)

	var daily_opt = Button.new()
	daily_opt.text = "Daily"
	daily_opt.toggle_mode = true
	daily_opt.button_pressed = true
	daily_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daily_opt.pressed.connect(_set_timeframe.bind(GoalManager.GoalTimeframe.DAILY))
	daily_opt.name = "DailyOpt"
	time_row.add_child(daily_opt)

	var weekly_opt = Button.new()
	weekly_opt.text = "Weekly"
	weekly_opt.toggle_mode = true
	weekly_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weekly_opt.pressed.connect(_set_timeframe.bind(GoalManager.GoalTimeframe.WEEKLY))
	weekly_opt.name = "WeeklyOpt"
	time_row.add_child(weekly_opt)

	var milestone_opt = Button.new()
	milestone_opt.text = "Milestone"
	milestone_opt.toggle_mode = true
	milestone_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	milestone_opt.pressed.connect(_set_timeframe.bind(GoalManager.GoalTimeframe.MILESTONE))
	milestone_opt.name = "MilestoneOpt"
	time_row.add_child(milestone_opt)

	zone_body.add_child(time_row)

	var aspect_label = Label.new()
	aspect_label.text = "\nPowers which Aspect?"
	zone_body.add_child(aspect_label)

	var aspect_grid = GridContainer.new()
	aspect_grid.columns = 3
	aspect_grid.add_theme_constant_override("h_separation", 10)
	aspect_grid.add_theme_constant_override("v_separation", 10)

	for opt in GoalManager.get_aspect_options():
		var btn = Button.new()
		btn.text = opt.name
		btn.toggle_mode = true
		btn.button_pressed = (opt.id == "discipline")
		btn.pressed.connect(_set_aspect.bind(opt.id))
		btn.name = "Aspect_" + opt.id
		aspect_grid.add_child(btn)

	zone_body.add_child(aspect_grid)

	var target_container = VBoxContainer.new()
	target_container.name = "TargetContainer"
	target_container.visible = false

	var target_label = Label.new()
	target_label.text = "\nTarget count (for tracking progress):"
	target_container.add_child(target_label)

	var target_input = SpinBox.new()
	target_input.min_value = 1
	target_input.max_value = 100
	target_input.value = 1
	target_input.custom_minimum_size = Vector2(0, 50)
	target_input.name = "TargetInput"
	target_input.value_changed.connect(_set_target_progress)
	target_container.add_child(target_input)

	zone_body.add_child(target_container)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	zone_body.add_child(spacer2)

	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 15)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 60)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(_show_goals_main_view)
	button_row.add_child(cancel_btn)

	var create_btn = Button.new()
	create_btn.text = "Create Goal"
	create_btn.custom_minimum_size = Vector2(0, 60)
	create_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_btn.pressed.connect(_submit_new_goal)
	button_row.add_child(create_btn)

	zone_body.add_child(button_row)


func _set_timeframe(timeframe: GoalManager.GoalTimeframe) -> void:
	new_goal_data.timeframe = timeframe

	var daily = zone_body.find_child("DailyOpt", true, false)
	var weekly = zone_body.find_child("WeeklyOpt", true, false)
	var milestone = zone_body.find_child("MilestoneOpt", true, false)

	if daily: daily.button_pressed = (timeframe == GoalManager.GoalTimeframe.DAILY)
	if weekly: weekly.button_pressed = (timeframe == GoalManager.GoalTimeframe.WEEKLY)
	if milestone: milestone.button_pressed = (timeframe == GoalManager.GoalTimeframe.MILESTONE)

	var target_container = zone_body.find_child("TargetContainer", true, false)
	if target_container:
		target_container.visible = (timeframe == GoalManager.GoalTimeframe.MILESTONE)


func _set_aspect(aspect_id: String) -> void:
	new_goal_data.aspect = aspect_id
	for opt in GoalManager.get_aspect_options():
		var btn = zone_body.find_child("Aspect_" + opt.id, true, false)
		if btn: btn.button_pressed = (opt.id == aspect_id)


func _set_target_progress(value: float) -> void:
	new_goal_data.target_progress = int(value)


func _submit_new_goal() -> void:
	var title_input = zone_body.find_child("TitleInput", true, false)
	if not title_input or title_input.text.strip_edges() == "":
		_show_dialogue("Goal Compass", "Please enter a goal title.", _close_dialogue)
		return

	new_goal_data.title = title_input.text.strip_edges()
	GoalManager.create_goal(new_goal_data)

	_show_dialogue(
		"Goal Compass",
		"Goal created: \"" + new_goal_data.title + "\"\n\nComplete it to earn XP and evolve your base!",
		func(): _show_goals_main_view()
	)


# ============ DAILY RITUALS (Habits) ============
func _open_habits_zone() -> void:
	if not GameManager.has_seen_tutorial("zone_habits"):
		var tut = zone_tutorials.habits
		GameManager.mark_tutorial_seen("zone_habits")
		_show_dialogue("Daily Rituals", tut.text, func():
			_close_dialogue()
			_do_open_habits_zone()
		)
		return
	_do_open_habits_zone()


func _do_open_habits_zone() -> void:
	_show_zone_panel("Daily Rituals")

	var completion = HabitManager.get_today_completion_percentage()
	var status = Label.new()
	status.text = "Today's progress: " + str(int(completion * 100)) + "%"
	status.add_theme_font_size_override("font_size", 26)
	zone_body.add_child(status)

	var hint = Label.new()
	hint.text = "Check off habits as you complete them in real life."
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	zone_body.add_child(hint)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	zone_body.add_child(spacer)

	for habit in HabitManager.get_all_habits():
		_add_habit_display(habit)


func _add_habit_display(habit: Dictionary) -> void:
	var completed = HabitManager.is_completed_today(habit.id)

	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)

	var checkbox = CheckBox.new()
	checkbox.button_pressed = completed
	checkbox.disabled = completed
	checkbox.toggled.connect(_on_habit_checked.bind(habit.id))
	hbox.add_child(checkbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)

	var name_label = Label.new()
	name_label.text = habit.name
	name_label.add_theme_font_size_override("font_size", 22)
	if completed:
		name_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.5))
	vbox.add_child(name_label)

	var streak_label = Label.new()
	streak_label.text = str(habit.streak) + " day streak"
	streak_label.add_theme_font_size_override("font_size", 18)
	streak_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(streak_label)

	hbox.add_child(vbox)
	panel.add_child(hbox)
	zone_body.add_child(panel)


func _on_habit_checked(toggled: bool, habit_id: String) -> void:
	if toggled:
		HabitManager.complete_habit(habit_id)
		_do_open_habits_zone()


# ============ TRAINING ARENA ============
func _open_arena_zone() -> void:
	if not GameManager.has_seen_tutorial("zone_arena"):
		var tut = zone_tutorials.arena
		GameManager.mark_tutorial_seen("zone_arena")
		_show_dialogue("Training Arena", tut.text, func():
			_close_dialogue()
			_do_open_arena_zone()
		)
		return
	_do_open_arena_zone()


func _do_open_arena_zone() -> void:
	_show_zone_panel("Training Arena")

	var desc = Label.new()
	desc.text = "Face your inner resistance.\nDefeating Doubt, Fear, and Procrastination strengthens your Aspects."
	desc.add_theme_font_size_override("font_size", 22)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(desc)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	zone_body.add_child(spacer)

	var battle_btn = Button.new()
	battle_btn.text = "Enter Battle"
	battle_btn.custom_minimum_size = Vector2(0, 100)
	battle_btn.add_theme_font_size_override("font_size", 28)
	battle_btn.pressed.connect(_start_combat)
	zone_body.add_child(battle_btn)

	var hint = Label.new()
	hint.text = "\nYour Aspects will fight alongside you. Higher levels mean stronger abilities."
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(hint)


func _start_combat() -> void:
	GameManager.goto_scene("res://scenes/combat/combat.tscn")


# ============ SCRIPT LAB ============
var current_layer_id: String = ""
var current_package_id: String = ""
var editing_script_id: String = ""
var script_lines: Array = []
var selected_script_type: int = ScriptManager.ScriptType.UPDATE

func _open_script_lab() -> void:
	if not GameManager.has_seen_tutorial("zone_script_lab"):
		var tut = zone_tutorials.script_lab
		GameManager.mark_tutorial_seen("zone_script_lab")
		_show_dialogue("Script Lab", tut.text, func():
			_close_dialogue()
			_do_open_script_lab()
		)
		return
	_do_open_script_lab()


func _do_open_script_lab() -> void:
	current_layer_id = ""
	current_package_id = ""
	editing_script_id = ""
	_show_zone_panel(ScriptManager.personal_os.name + ".OS")
	_show_os_overview()


func _show_os_overview() -> void:
	for child in zone_body.get_children():
		child.queue_free()

	var stats = ScriptManager.get_stats()

	var stats_label = Label.new()
	stats_label.text = "Scripts: " + str(stats.total_scripts) + " | Executed: " + str(stats.total_executions) + " times"
	stats_label.add_theme_font_size_override("font_size", 18)
	stats_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	zone_body.add_child(stats_label)

	var desc = Label.new()
	desc.text = "\nYour Personal Operating System.\nSelect a layer to view or create scripts."
	desc.add_theme_font_size_override("font_size", 20)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(desc)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	zone_body.add_child(spacer)

	for layer in ScriptManager.get_layers():
		var layer_scripts = ScriptManager.get_layer_scripts(layer.id)
		var layer_btn = Button.new()
		layer_btn.text = layer.name + ".layer\n" + str(layer_scripts.size()) + " scripts"
		layer_btn.custom_minimum_size = Vector2(0, 90)
		layer_btn.add_theme_font_size_override("font_size", 22)
		layer_btn.pressed.connect(_open_layer.bind(layer.id))
		zone_body.add_child(layer_btn)


func _open_layer(layer_id: String) -> void:
	current_layer_id = layer_id
	current_package_id = ""

	for child in zone_body.get_children():
		child.queue_free()

	var layer = ScriptManager.personal_os.layers[layer_id]

	var back_btn = Button.new()
	back_btn.text = "< Back to OS"
	back_btn.custom_minimum_size = Vector2(0, 55)
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(_show_os_overview)
	zone_body.add_child(back_btn)

	var title = Label.new()
	title.text = "\n" + layer.name + ".layer"
	title.add_theme_font_size_override("font_size", 28)
	zone_body.add_child(title)

	var desc = Label.new()
	desc.text = layer.description
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	zone_body.add_child(desc)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	zone_body.add_child(spacer)

	var create_pkg_btn = Button.new()
	create_pkg_btn.text = "+ New Package"
	create_pkg_btn.custom_minimum_size = Vector2(0, 70)
	create_pkg_btn.add_theme_font_size_override("font_size", 22)
	create_pkg_btn.pressed.connect(_show_create_package)
	zone_body.add_child(create_pkg_btn)

	var create_script_btn = Button.new()
	create_script_btn.text = "+ New Script"
	create_script_btn.custom_minimum_size = Vector2(0, 70)
	create_script_btn.add_theme_font_size_override("font_size", 22)
	create_script_btn.pressed.connect(_show_create_script.bind(""))
	zone_body.add_child(create_script_btn)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	zone_body.add_child(spacer2)

	var packages = ScriptManager.get_layer_packages(layer_id)
	if packages.size() > 0:
		var pkg_label = Label.new()
		pkg_label.text = "Packages:"
		pkg_label.add_theme_font_size_override("font_size", 20)
		zone_body.add_child(pkg_label)

		for pkg in packages:
			var pkg_btn = Button.new()
			var pkg_scripts = ScriptManager.get_package_scripts(pkg.id)
			pkg_btn.text = pkg.name + ".pkg (" + str(pkg_scripts.size()) + " scripts)"
			pkg_btn.custom_minimum_size = Vector2(0, 75)
			pkg_btn.add_theme_font_size_override("font_size", 22)
			pkg_btn.pressed.connect(_open_package.bind(pkg.id))
			zone_body.add_child(pkg_btn)

	var scripts = ScriptManager.get_layer_scripts(layer_id)
	var standalone = scripts.filter(func(s): return s.package_id == "")

	if standalone.size() > 0:
		var script_label = Label.new()
		script_label.text = "\nStandalone Scripts:"
		script_label.add_theme_font_size_override("font_size", 20)
		zone_body.add_child(script_label)

		for script in standalone:
			_add_script_item(script)


func _open_package(package_id: String) -> void:
	current_package_id = package_id

	for child in zone_body.get_children():
		child.queue_free()

	var pkg = ScriptManager.packages[package_id]

	var back_btn = Button.new()
	back_btn.text = "< Back to " + ScriptManager.personal_os.layers[current_layer_id].name + ".layer"
	back_btn.pressed.connect(_open_layer.bind(current_layer_id))
	zone_body.add_child(back_btn)

	var title = Label.new()
	title.text = "\n" + pkg.name + ".pkg"
	title.add_theme_font_size_override("font_size", 24)
	zone_body.add_child(title)

	if pkg.description != "":
		var desc = Label.new()
		desc.text = pkg.description
		desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		zone_body.add_child(desc)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	zone_body.add_child(spacer)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)

	var create_btn = Button.new()
	create_btn.text = "+ New Script"
	create_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_btn.custom_minimum_size = Vector2(0, 50)
	create_btn.pressed.connect(_show_create_script.bind(package_id))
	btn_row.add_child(create_btn)

	var scripts = ScriptManager.get_package_scripts(package_id)
	if scripts.size() >= 2:
		var batch_btn = Button.new()
		batch_btn.text = "Run Package"
		batch_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		batch_btn.custom_minimum_size = Vector2(0, 50)
		batch_btn.pressed.connect(_run_package.bind(package_id))
		btn_row.add_child(batch_btn)

	zone_body.add_child(btn_row)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	zone_body.add_child(spacer2)

	if scripts.size() == 0:
		var empty = Label.new()
		empty.text = "No scripts yet. Create your first .psa file!"
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		zone_body.add_child(empty)
	else:
		for script in scripts:
			_add_script_item(script)


func _add_script_item(script: Dictionary) -> void:
	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)

	var type_color = ColorRect.new()
	type_color.custom_minimum_size = Vector2(8, 70)
	type_color.color = ScriptManager.get_type_color(script.type)
	hbox.add_child(type_color)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)

	var name_label = Label.new()
	name_label.text = script.name + ".psa"
	name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_label)

	var meta = Label.new()
	var type_name = ScriptManager.get_type_name(script.type)
	var filled_lines = script.lines.filter(func(l): return l != "").size()
	meta.text = type_name + ".posl | " + str(filled_lines) + "/25 lines | Run " + str(script.times_executed) + "x"
	meta.add_theme_font_size_override("font_size", 16)
	meta.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(meta)

	hbox.add_child(vbox)

	var edit_btn = Button.new()
	edit_btn.text = "Edit"
	edit_btn.custom_minimum_size = Vector2(80, 60)
	edit_btn.add_theme_font_size_override("font_size", 18)
	edit_btn.pressed.connect(_edit_script.bind(script.id))
	hbox.add_child(edit_btn)

	var run_btn = Button.new()
	run_btn.text = "Run"
	run_btn.custom_minimum_size = Vector2(80, 60)
	run_btn.add_theme_font_size_override("font_size", 18)
	run_btn.pressed.connect(_run_script.bind(script.id))
	hbox.add_child(run_btn)

	panel.add_child(hbox)
	zone_body.add_child(panel)


func _show_create_package() -> void:
	for child in zone_body.get_children():
		child.queue_free()

	var title = Label.new()
	title.text = "Create Package"
	title.add_theme_font_size_override("font_size", 24)
	zone_body.add_child(title)

	var name_label = Label.new()
	name_label.text = "\nPackage name:"
	zone_body.add_child(name_label)

	var name_input = LineEdit.new()
	name_input.placeholder_text = "e.g., morning_routine"
	name_input.custom_minimum_size = Vector2(0, 50)
	name_input.name = "PkgNameInput"
	zone_body.add_child(name_input)

	var desc_label = Label.new()
	desc_label.text = "\nDescription (optional):"
	zone_body.add_child(desc_label)

	var desc_input = LineEdit.new()
	desc_input.placeholder_text = "What is this package for?"
	desc_input.custom_minimum_size = Vector2(0, 50)
	desc_input.name = "PkgDescInput"
	zone_body.add_child(desc_input)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	zone_body.add_child(spacer)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.custom_minimum_size = Vector2(0, 60)
	cancel_btn.pressed.connect(_open_layer.bind(current_layer_id))
	btn_row.add_child(cancel_btn)

	var create_btn = Button.new()
	create_btn.text = "Create"
	create_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_btn.custom_minimum_size = Vector2(0, 60)
	create_btn.pressed.connect(_submit_create_package)
	btn_row.add_child(create_btn)

	zone_body.add_child(btn_row)


func _submit_create_package() -> void:
	var name_input = zone_body.find_child("PkgNameInput", true, false)
	var desc_input = zone_body.find_child("PkgDescInput", true, false)

	if not name_input or name_input.text.strip_edges() == "":
		_show_dialogue("Script Lab", "Please enter a package name.", _close_dialogue)
		return

	var pkg_id = ScriptManager.create_package(
		current_layer_id,
		name_input.text.strip_edges(),
		desc_input.text.strip_edges() if desc_input else ""
	)

	_open_package(pkg_id)


func _show_create_script(package_id: String) -> void:
	editing_script_id = ""
	script_lines = []
	for i in range(25):
		script_lines.append("")
	_show_script_editor(package_id, "")


func _edit_script(script_id: String) -> void:
	editing_script_id = script_id
	var script = ScriptManager.scripts[script_id]
	script_lines = script.lines.duplicate()
	_show_script_editor(script.package_id, script_id)


func _show_script_editor(package_id: String, script_id: String) -> void:
	for child in zone_body.get_children():
		child.queue_free()

	var is_edit = script_id != ""
	var script = ScriptManager.scripts.get(script_id, {})

	var title = Label.new()
	title.text = "Edit Script" if is_edit else "Create Script"
	title.add_theme_font_size_override("font_size", 24)
	zone_body.add_child(title)

	var name_label = Label.new()
	name_label.text = "\nScript name:"
	zone_body.add_child(name_label)

	var name_input = LineEdit.new()
	name_input.placeholder_text = "e.g., deep_focus"
	name_input.text = script.get("name", "")
	name_input.custom_minimum_size = Vector2(0, 50)
	name_input.name = "ScriptNameInput"
	zone_body.add_child(name_input)

	var type_label = Label.new()
	type_label.text = "\nScript type (.posl):"
	zone_body.add_child(type_label)

	var type_row = HBoxContainer.new()
	type_row.add_theme_constant_override("separation", 8)

	var current_type = script.get("type", ScriptManager.ScriptType.UPDATE)

	for type_val in [ScriptManager.ScriptType.UPDATE, ScriptManager.ScriptType.UPGRADE, ScriptManager.ScriptType.DOWNGRADE, ScriptManager.ScriptType.VIRUS]:
		var type_btn = Button.new()
		type_btn.text = ScriptManager.get_type_name(type_val)
		type_btn.toggle_mode = true
		type_btn.button_pressed = (type_val == current_type)
		type_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		type_btn.modulate = ScriptManager.get_type_color(type_val)
		type_btn.name = "TypeBtn_" + str(type_val)
		type_btn.pressed.connect(_select_script_type.bind(type_val))
		type_row.add_child(type_btn)

	zone_body.add_child(type_row)

	var lines_label = Label.new()
	lines_label.text = "\n25 lines of code (each line = 1 minute):"
	zone_body.add_child(lines_label)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var lines_container = VBoxContainer.new()
	lines_container.name = "LinesContainer"

	for i in range(25):
		var line_row = HBoxContainer.new()
		line_row.add_theme_constant_override("separation", 10)

		var line_num = Label.new()
		line_num.text = str(i + 1).pad_zeros(2) + ":"
		line_num.add_theme_font_size_override("font_size", 14)
		line_num.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		line_num.custom_minimum_size = Vector2(35, 0)
		line_row.add_child(line_num)

		var line_input = LineEdit.new()
		line_input.placeholder_text = "Action for minute " + str(i + 1) + "..."
		line_input.text = script_lines[i] if i < script_lines.size() else ""
		line_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line_input.name = "Line_" + str(i)
		line_input.text_changed.connect(_on_line_changed.bind(i))
		line_row.add_child(line_input)

		lines_container.add_child(line_row)

	scroll.add_child(lines_container)
	zone_body.add_child(scroll)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	zone_body.add_child(spacer)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.custom_minimum_size = Vector2(0, 60)
	if package_id != "":
		cancel_btn.pressed.connect(_open_package.bind(package_id))
	else:
		cancel_btn.pressed.connect(_open_layer.bind(current_layer_id))
	btn_row.add_child(cancel_btn)

	var save_btn = Button.new()
	save_btn.text = "Save Script"
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.custom_minimum_size = Vector2(0, 60)
	save_btn.pressed.connect(_submit_script.bind(package_id))
	btn_row.add_child(save_btn)

	zone_body.add_child(btn_row)


func _select_script_type(type_val: int) -> void:
	selected_script_type = type_val
	for t in [ScriptManager.ScriptType.UPDATE, ScriptManager.ScriptType.UPGRADE, ScriptManager.ScriptType.DOWNGRADE, ScriptManager.ScriptType.VIRUS]:
		var btn = zone_body.find_child("TypeBtn_" + str(t), true, false)
		if btn: btn.button_pressed = (t == type_val)


func _on_line_changed(new_text: String, line_index: int) -> void:
	if line_index < script_lines.size():
		script_lines[line_index] = new_text


func _submit_script(package_id: String) -> void:
	var name_input = zone_body.find_child("ScriptNameInput", true, false)

	if not name_input or name_input.text.strip_edges() == "":
		_show_dialogue("Script Lab", "Please enter a script name.", _close_dialogue)
		return

	if editing_script_id != "":
		ScriptManager.update_script(editing_script_id, {
			"name": name_input.text.strip_edges(),
			"type": selected_script_type,
			"lines": script_lines
		})
		_show_dialogue("Script Lab", "Script updated: " + name_input.text.strip_edges() + ".psa", func():
			if package_id != "":
				_open_package(package_id)
			else:
				_open_layer(current_layer_id)
		)
	else:
		ScriptManager.create_script({
			"name": name_input.text.strip_edges(),
			"layer_id": current_layer_id,
			"package_id": package_id,
			"type": selected_script_type,
			"lines": script_lines
		})
		_show_dialogue("Script Lab", "Script created: " + name_input.text.strip_edges() + ".psa\n\n25 lines of code ready to execute.", func():
			if package_id != "":
				_open_package(package_id)
			else:
				_open_layer(current_layer_id)
		)


func _run_script(script_id: String) -> void:
	var script = ScriptManager.execute_script(script_id)

	GameManager.player_data["pending_focus"] = {
		"script_id": script_id,
		"topic": script.name + ".psa",
		"duration": 25,
		"lines": script.lines,
		"aspect": script.aspect,
		"difficulty": selected_focus_difficulty
	}

	GameManager.goto_scene("res://scenes/focus_mode/focus_mode.tscn")


func _run_package(package_id: String) -> void:
	var scripts = ScriptManager.get_package_scripts(package_id)
	var pkg = ScriptManager.packages[package_id]

	if scripts.size() == 0:
		_show_dialogue("Script Lab", "No scripts in this package to run.", _close_dialogue)
		return

	var total_time = scripts.size() * 25
	var script_ids = []
	for s in scripts:
		script_ids.append(s.id)

	var diff_name = "Easy" if selected_focus_difficulty == 0 else "Hard"
	var xp_mult = "0.7x" if selected_focus_difficulty == 0 else "1.5x"

	GameManager.player_data["pending_batch"] = {
		"package_id": package_id,
		"package_name": pkg.name,
		"script_ids": script_ids,
		"total_duration": total_time,
		"difficulty": selected_focus_difficulty
	}

	_show_dialogue(
		"Script Lab",
		"Run " + pkg.name + ".pkg?\n\n" + str(scripts.size()) + " scripts = " + str(total_time) + " minutes\nDifficulty: " + diff_name + " (" + xp_mult + " XP)",
		func(): GameManager.goto_scene("res://scenes/focus_mode/focus_mode.tscn")
	)


# ============ NEW ZONES (Northern Gardens, Observatory, Depths, Summit) ============

func _open_dream_garden() -> void:
	_show_zone_panel("Dream Garden")

	var desc = Label.new()
	desc.text = "A tranquil garden where dreams take root.\n\nThis space connects to your sleep and rest patterns."
	desc.add_theme_font_size_override("font_size", 24)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(desc)

	var coming_soon = Label.new()
	coming_soon.text = "\n[Coming Soon]\nDream journaling and sleep tracking features."
	coming_soon.add_theme_font_size_override("font_size", 20)
	coming_soon.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
	zone_body.add_child(coming_soon)


func _open_memory_archive() -> void:
	_show_zone_panel("Memory Archive")

	var desc = Label.new()
	desc.text = "The archive of your journey.\n\nReview past entries, track your growth over time."
	desc.add_theme_font_size_override("font_size", 24)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(desc)

	# Show recent journal entries summary
	var journal_file = SaveManager.get_journal_path()
	if FileAccess.file_exists(journal_file):
		var file = FileAccess.open(journal_file, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data = json.get_data()
				if data is Dictionary and data.has("entries"):
					var entries = data.entries
					var count_label = Label.new()
					count_label.text = "\nTotal Journal Entries: " + str(entries.size())
					count_label.add_theme_font_size_override("font_size", 22)
					count_label.add_theme_color_override("font_color", ThemeConfig.GOACTO_GOLD)
					zone_body.add_child(count_label)


func _open_observatory() -> void:
	_show_zone_panel("Star Observatory")

	var desc = Label.new()
	desc.text = "Gaze upon the cosmos and visualize your future.\n\nThis is where long-term vision becomes clear."
	desc.add_theme_font_size_override("font_size", 24)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(desc)

	# Show achievement/trophy count
	var trophies = CampaignManager.get_earned_trophies()
	var trophy_label = Label.new()
	trophy_label.text = "\nTrophies Earned: " + str(trophies.size())
	trophy_label.add_theme_font_size_override("font_size", 22)
	trophy_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.8))
	zone_body.add_child(trophy_label)

	var coming_soon = Label.new()
	coming_soon.text = "\n[Coming Soon]\nVision board and long-term goal visualization."
	coming_soon.add_theme_font_size_override("font_size", 20)
	coming_soon.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	zone_body.add_child(coming_soon)


func _open_shadow_work() -> void:
	_show_zone_panel("Shadow Work")

	var desc = Label.new()
	desc.text = "Face the parts of yourself you've been avoiding.\n\nThis chamber helps you confront limiting beliefs and transform them."
	desc.add_theme_font_size_override("font_size", 24)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(desc)

	# Show virus/downgrade scripts if any exist
	var virus_scripts = ScriptManager.get_scripts_by_type(ScriptManager.ScriptType.VIRUS)
	var downgrade_scripts = ScriptManager.get_scripts_by_type(ScriptManager.ScriptType.DOWNGRADE)

	if virus_scripts.size() > 0 or downgrade_scripts.size() > 0:
		var scripts_label = Label.new()
		scripts_label.text = "\nLimiting beliefs identified: " + str(virus_scripts.size()) + "\nDowngrade routines: " + str(downgrade_scripts.size())
		scripts_label.add_theme_font_size_override("font_size", 22)
		scripts_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.5))
		zone_body.add_child(scripts_label)

	var coming_soon = Label.new()
	coming_soon.text = "\n[Coming Soon]\nShadow work exercises and belief transformation."
	coming_soon.add_theme_font_size_override("font_size", 20)
	coming_soon.add_theme_color_override("font_color", Color(0.5, 0.4, 0.5))
	zone_body.add_child(coming_soon)


func _open_summit() -> void:
	_show_zone_panel("The Summit")

	var desc = Label.new()
	desc.text = "The peak of your mindscape.\n\nFrom here, you can see how far you've come and where you're headed."
	desc.add_theme_font_size_override("font_size", 24)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	zone_body.add_child(desc)

	# Show overall stats
	var stats_label = Label.new()
	var focus_mins = GameManager.player_data.total_focus_minutes
	var evolution = GameManager.player_data.world_evolution_level
	stats_label.text = "\nTotal Focus Time: " + str(focus_mins) + " minutes\nWorld Evolution: " + str(snapped(evolution, 0.1)) + "%"
	stats_label.add_theme_font_size_override("font_size", 22)
	stats_label.add_theme_color_override("font_color", ThemeConfig.GOACTO_GOLD)
	zone_body.add_child(stats_label)

	var coming_soon = Label.new()
	coming_soon.text = "\n[Coming Soon]\nMilestone goals and legacy tracking."
	coming_soon.add_theme_font_size_override("font_size", 20)
	coming_soon.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	zone_body.add_child(coming_soon)


# ============ SIGNALS ============
func _on_world_evolved(_amount: float) -> void:
	_update_header()
	_update_base_visuals()
	_check_zone_unlocks()


func _on_aspect_leveled(aspect_name: String, new_level: int) -> void:
	_show_dialogue(
		aspect_name,
		"I've grown stronger. Level " + str(new_level) + " reached.",
		_close_dialogue
	)
	_check_zone_unlocks()


func _check_zone_unlocks() -> void:
	var newly_unlocked = GameManager.check_zone_unlocks()
	if newly_unlocked.size() > 0:
		_update_zone_lock_visuals()
		# Show unlock notification for first zone
		var zone_id = newly_unlocked[0]
		var zone_name = zone_names.get(zone_id, zone_id)
		var tier = GameManager.get_zone_tier(zone_id)
		_show_dialogue(
			"Zone Unlocked!",
			zone_name + " (Tier " + str(tier) + ") is now accessible!\n\nExplore it to discover new abilities.",
			_close_dialogue
		)


func _on_zone_unlocked(zone_id: String) -> void:
	_update_zone_lock_visuals()
	_update_gate_barriers()
	print("[Mindscape] Zone unlocked via signal: ", zone_id)


# ============ DIALOGUE ============
func _show_dialogue(speaker: String, text: String, on_continue: Callable) -> void:
	speaker_name.text = speaker
	dialogue_text.text = text
	dialogue_panel.visible = true

	for connection in dialogue_continue.pressed.get_connections():
		dialogue_continue.pressed.disconnect(connection.callable)

	dialogue_continue.pressed.connect(on_continue, CONNECT_ONE_SHOT)


func _close_dialogue() -> void:
	dialogue_panel.visible = false


# ============ TUTORIALS ============
func _show_tutorial(title: String, text: String) -> void:
	tutorial_title.text = title
	tutorial_text.text = text
	tutorial_panel.visible = true


func _close_tutorial() -> void:
	tutorial_panel.visible = false


# ============ SETTINGS ============
func _open_settings() -> void:
	var settings = GameManager.player_data.get("settings", {
		"focus_duration": 25,
		"notifications": true,
		"sound": true
	})

	focus_duration_spinbox.value = settings.get("focus_duration", 25)
	notifications_checkbox.button_pressed = settings.get("notifications", true)
	sound_checkbox.button_pressed = settings.get("sound", true)

	settings_panel.visible = true
	game_world.visible = false


func _close_settings() -> void:
	GameManager.player_data["settings"] = {
		"focus_duration": int(focus_duration_spinbox.value),
		"notifications": notifications_checkbox.button_pressed,
		"sound": sound_checkbox.button_pressed
	}
	SaveManager.save_game()

	settings_panel.visible = false
	game_world.visible = true


func _on_reset_tutorials() -> void:
	_show_dialogue("Settings", "Reset all tutorials?\n\nYou'll see introductory tips again when visiting each zone.", func():
		_close_dialogue()
		GameManager.player_data.seen_tutorials = []
		GameManager.player_data.has_completed_onboarding = false
		SaveManager.save_game()
		_show_dialogue("Settings", "Tutorials reset! You'll see tips again on your next visit.", _close_dialogue)
	)


func _on_clear_data() -> void:
	_show_dialogue("Settings", "Clear ALL game data?\n\nThis will reset your progress, habits, goals, and everything else. This cannot be undone!", func():
		_close_dialogue()
		_show_dialogue("Settings", "Are you absolutely sure?\n\nTap Continue to confirm reset.", func():
			_close_dialogue()
			GameManager.reset_player_data()
			HabitManager.reset_habits()
			GoalManager.reset_goals()
			ScriptManager.reset_scripts()
			SaveManager.save_game()
			GameManager.goto_scene("res://scenes/main_menu/main_menu.tscn")
		)
	)


func _on_about() -> void:
	_show_dialogue("About Mindscape", "Mindscape v0.1\n\nA game about growing yourself in real life.\n\nYour Aspects represent parts of you. Your habits build them. Your focus sessions deepen them. Your scripts program your days.\n\nGrow your mindscape. Grow yourself.", _close_dialogue)


func _on_feedback() -> void:
	_show_dialogue("Feedback", "We'd love to hear from you!\n\nShare ideas, report bugs, or just say hello:\n\nsupport@mindscape.game\n\n(This is a placeholder - actual feedback integration coming soon!)", _close_dialogue)


# ============ PAUSE MENU ============

var current_menu_tab: String = "character"

func _open_pause_menu() -> void:
	pause_menu.visible = true
	game_world.visible = false
	_show_character_tab()


func _close_pause_menu() -> void:
	pause_menu.visible = false
	game_world.visible = true


func _select_menu_tab(tab: String) -> void:
	current_menu_tab = tab
	character_tab.button_pressed = (tab == "character")
	aspects_tab.button_pressed = (tab == "aspects")
	progress_tab.button_pressed = (tab == "progress")
	settings_menu_tab.button_pressed = (tab == "settings")


func _clear_menu_body() -> void:
	for child in menu_body.get_children():
		child.queue_free()


func _show_character_tab() -> void:
	_select_menu_tab("character")
	_clear_menu_body()

	# Player name section
	var player_name = GameManager.player_data.get("name", "Traveler")
	var name_label = Label.new()
	name_label.text = player_name
	name_label.add_theme_font_size_override("font_size", 36)
	name_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	menu_body.add_child(name_label)

	_add_menu_spacer()

	# Stats section
	_add_menu_section_label("Statistics")

	var evolution = GameManager.player_data.get("world_evolution", 0.0)
	_add_stat_row("World Evolution", "%.1f%%" % evolution)

	var total_focus = int(GameManager.player_data.get("total_focus_minutes", 0))
	var hours = total_focus / 60
	var mins = total_focus % 60
	if hours > 0:
		_add_stat_row("Total Focus Time", "%dh %dm" % [hours, mins])
	else:
		_add_stat_row("Total Focus Time", "%d minutes" % mins)

	var total_sessions = GameManager.player_data.get("total_focus_sessions", 0)
	_add_stat_row("Focus Sessions", str(total_sessions))

	var total_habits = GameManager.player_data.get("total_habits_completed", 0)
	_add_stat_row("Habits Completed", str(total_habits))

	_add_menu_spacer()

	# Chapter info
	_add_menu_section_label("Campaign")

	var chapter_data = CampaignManager.get_current_chapter()
	_add_stat_row("Current Chapter", chapter_data.name)

	var progress = CampaignManager.get_chapter_progress()
	_add_stat_row("Chapter Progress", "%d%%" % int(progress * 100))


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

	# XP bar
	var xp = data.get("experience", 0)
	var xp_needed = data.get("next_level_xp", 100)
	var progress_ratio = float(xp) / float(xp_needed) if xp_needed > 0 else 0.0

	var bar_bg = ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(0, 20)
	bar_bg.color = Color(0.15, 0.15, 0.2)
	container.add_child(bar_bg)

	var bar_fill = ColorRect.new()
	bar_fill.custom_minimum_size = Vector2(0, 20)
	bar_fill.color = aspect_colors.get(aspect_id, Color.WHITE)
	bar_fill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bar_fill.anchor_right = progress_ratio
	container.add_child(bar_fill)

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

	# Today's Habits
	_add_menu_section_label("Today's Habits")

	var habits = HabitManager.get_all_habits()
	var completed_count = 0
	for habit in habits:
		if HabitManager.is_completed_today(habit.id):
			completed_count += 1

	_add_stat_row("Completed", "%d / %d" % [completed_count, habits.size()])

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
			goal_label.text = "- " + goal.title
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


func _show_settings_tab() -> void:
	_select_menu_tab("settings")
	_clear_menu_body()

	_add_menu_section_label("Settings")

	# Link to full settings
	var settings_btn = Button.new()
	settings_btn.text = "Open Full Settings"
	settings_btn.custom_minimum_size = Vector2(0, 70)
	settings_btn.add_theme_font_size_override("font_size", 22)
	settings_btn.pressed.connect(func():
		_close_pause_menu()
		_open_settings()
	)
	menu_body.add_child(settings_btn)

	_add_menu_spacer()

	# Quick actions
	_add_menu_section_label("Quick Actions")

	var save_btn = Button.new()
	save_btn.text = "Save Game"
	save_btn.custom_minimum_size = Vector2(0, 60)
	save_btn.add_theme_font_size_override("font_size", 20)
	save_btn.pressed.connect(func():
		SaveManager.save_game()
		_show_dialogue("Saved", "Game saved successfully!", _close_dialogue)
		_close_pause_menu()
	)
	menu_body.add_child(save_btn)

	var main_menu_btn = Button.new()
	main_menu_btn.text = "Return to Main Menu"
	main_menu_btn.custom_minimum_size = Vector2(0, 60)
	main_menu_btn.add_theme_font_size_override("font_size", 20)
	main_menu_btn.pressed.connect(func():
		SaveManager.save_game()
		GameManager.goto_scene("res://scenes/main_menu/main_menu.tscn")
	)
	menu_body.add_child(main_menu_btn)


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


# ============ CHAPTER LIST ============

func _open_chapter_list() -> void:
	chapter_list_panel.visible = true
	_populate_chapter_list()


func _close_chapter_list() -> void:
	chapter_list_panel.visible = false


func _populate_chapter_list() -> void:
	# Clear existing
	for child in chapter_list_body.get_children():
		child.queue_free()

	# Get all chapters from CampaignManager
	var chapters = CampaignManager.CHAPTERS
	var current_chapter_id = CampaignManager.campaign_state.current_chapter
	var completed_chapters = CampaignManager.campaign_state.chapters_completed

	# Chapter order
	var chapter_order = ["chapter_1", "chapter_2", "chapter_3", "chapter_4", "chapter_5", "chapter_6"]

	for chapter_id in chapter_order:
		if not chapters.has(chapter_id):
			continue

		var chapter = chapters[chapter_id]
		var is_current = (chapter_id == current_chapter_id)
		var is_completed = chapter_id in completed_chapters
		var is_unlocked = _is_chapter_unlocked(chapter_id, completed_chapters)

		_add_chapter_row(chapter_id, chapter, is_current, is_completed, is_unlocked)


func _is_chapter_unlocked(chapter_id: String, completed: Array) -> bool:
	match chapter_id:
		"chapter_1": return true
		"chapter_2": return "chapter_1" in completed
		"chapter_3": return "chapter_2" in completed
		"chapter_4": return "chapter_3" in completed
		"chapter_5": return "chapter_4" in completed
		"chapter_6": return "chapter_5" in completed
		_: return false


func _add_chapter_row(chapter_id: String, chapter: Dictionary, is_current: bool, is_completed: bool, is_unlocked: bool) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)
	chapter_list_body.add_child(row)

	# Status icon
	var icon_label = Label.new()
	icon_label.custom_minimum_size = Vector2(30, 0)
	icon_label.add_theme_font_size_override("font_size", 22)

	if is_completed:
		icon_label.text = "✓"
		icon_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	elif is_current:
		icon_label.text = "►"
		icon_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	elif is_unlocked:
		icon_label.text = "○"
		icon_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	else:
		icon_label.text = "🔒"
		icon_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))

	row.add_child(icon_label)

	# Chapter info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	row.add_child(info_vbox)

	# Chapter name
	var name_label = Label.new()
	name_label.text = chapter.name
	name_label.add_theme_font_size_override("font_size", 22)

	if is_current:
		name_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	elif is_completed:
		name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	elif is_unlocked:
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	else:
		name_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))

	info_vbox.add_child(name_label)

	# Chapter description or locked message
	var desc_label = Label.new()
	desc_label.add_theme_font_size_override("font_size", 16)

	if is_unlocked or is_completed:
		desc_label.text = chapter.get("description", "")
		desc_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
	else:
		desc_label.text = "Complete previous chapter to unlock"
		desc_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))

	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_vbox.add_child(desc_label)

	# Separator
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 5)
	chapter_list_body.add_child(sep)


## Zone tutorial helper texts
var zone_tutorials: Dictionary = {
	"focus": {
		"title": "Focus Chamber",
		"text": "This is where deep work happens. Start a 25-minute session, put your phone aside, and focus on real-world tasks.\n\nAfter each session, reflect on what you learned and accomplished."
	},
	"journal": {
		"title": "Reflection Pool",
		"text": "Your journal entries from focus sessions appear here. Reviewing past reflections helps you see how far you've come."
	},
	"aspects": {
		"title": "Aspect Shrine",
		"text": "Your six Aspects represent different parts of yourself. They grow stronger as you complete habits in their domains.\n\nTalk to them for guidance and encouragement."
	},
	"goals": {
		"title": "Goal Compass",
		"text": "Set intentions here. Daily goals reset each day, weekly goals each week, and milestones track bigger objectives.\n\nCompleting goals awards XP to your Aspects."
	},
	"habits": {
		"title": "Daily Rituals",
		"text": "Track your real-world habits here. Building streaks multiplies your rewards and powers up your Aspects."
	},
	"arena": {
		"title": "Training Arena",
		"text": "Face your inner resistance in turn-based combat. Doubt, Fear, and Procrastination await.\n\nYour Aspects fight alongside you using abilities from their domains."
	},
	"script_lab": {
		"title": "Script Lab",
		"text": "Code your Personal Operating System here. Create scripts with 25 lines - each line is one minute of focused action.\n\nOrganize scripts into packages for batch sessions."
	}
}
