extends Node
## GameManager - Global game state singleton
## Manages overall game state, scene transitions, and coordinates between systems

# Game States
enum GameState {
	MAIN_MENU,
	MINDSCAPE,      # In the main game world
	FOCUS_MODE,     # Headset on, doing real-world task
	COMBAT,         # Fighting inner resistance
	DIALOGUE,       # Talking to Aspect or Guide
	PAUSED
}

# Signals for state changes
signal state_changed(new_state: GameState, old_state: GameState)
signal world_evolution_triggered(amount: float)
signal aspect_leveled_up(aspect_name: String, new_level: int)

# Current state
var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU

# Scene tracking for settings return
var current_scene_path: String = ""
var previous_scene_path: String = ""

# Player data (synced with SaveManager)
var player_data: Dictionary = {
	"name": "Traveler",
	"avatar": {},
	"world_evolution_level": 0.0,  # 0.0 to 100.0
	"total_focus_minutes": 0,
	"total_focus_sessions": 0,
	"total_habits_completed": 0,
	"current_streak_days": 0,
	"aspects": {},
	"unlocked_zones": ["origin"],
	"inventory": [],
	"has_completed_onboarding": false,
	"seen_tutorials": [],  # Track which zone tutorials have been shown
	"discovered_objects": [],  # Track interacted objects for shimmer hints
	"collected_decor": [],  # Room decoration items collected from mail
	"bedroom_decorations": [],  # Placed decorations: [{item_id, position, rotation}]
	# Bedroom progression - starts minimal, items unlock through campaign
	"console_placed_in_bedroom": false,
	"bedroom_items_installed": [],  # ["wardrobe", "mirror", "data_archive"]
	"closet_unlocked": false,
	"mirror_unlocked": false,
	"bookshelf_unlocked": false,
	"master_key_bedroom_notification_shown": false
}

# Zone tiers and unlock requirements
const ZONE_TIERS: Dictionary = {
	# Tier 1 - Always available
	"FocusChamber": {"tier": 1, "requirement": "none", "requirement_text": ""},
	"DailyRituals": {"tier": 1, "requirement": "none", "requirement_text": ""},
	"ReflectionPool": {"tier": 1, "requirement": "none", "requirement_text": ""},  # Journal access

	# Tier 2 - Complete Chapter 1
	"AspectShrine": {"tier": 2, "requirement": "chapter", "value": 1, "requirement_text": "Complete Chapter 1"},
	"GoalCompass": {"tier": 2, "requirement": "chapter", "value": 1, "requirement_text": "Complete Chapter 1"},
	"MemoryArchive": {"tier": 2, "requirement": "chapter", "value": 1, "requirement_text": "Complete Chapter 1"},

	# Tier 3 - 10% Evolution
	"ScriptLab": {"tier": 3, "requirement": "evolution", "value": 10.0, "requirement_text": "Reach 10% World Evolution"},
	"TrainingArena": {"tier": 3, "requirement": "evolution", "value": 10.0, "requirement_text": "Reach 10% World Evolution"},

	# Tier 4 - 25% Evolution
	"DreamGarden": {"tier": 4, "requirement": "evolution", "value": 25.0, "requirement_text": "Reach 25% World Evolution"},
	"Observatory": {"tier": 4, "requirement": "evolution", "value": 25.0, "requirement_text": "Reach 25% World Evolution"},

	# Tier 5 - 50% Evolution
	"ShadowWork": {"tier": 5, "requirement": "evolution", "value": 50.0, "requirement_text": "Reach 50% World Evolution"},

	# Tier 6 - 75% Evolution
	"Summit": {"tier": 6, "requirement": "evolution", "value": 75.0, "requirement_text": "Reach 75% World Evolution"}
}

signal zone_unlocked(zone_id: String)

# Aspect definitions
var ASPECTS: Dictionary = {
	"discipline": {
		"name": "Discipline",
		"domain": "productivity",
		"color": Color(0.2, 0.4, 0.8),
		"personality": "Stern but encouraging",
		"unlocked": true,
		"level": 1,
		"experience": 0
	},
	"courage": {
		"name": "Courage",
		"domain": "growth",
		"color": Color(0.8, 0.3, 0.2),
		"personality": "Bold and adventurous",
		"unlocked": false,
		"level": 1,
		"experience": 0
	},
	"creativity": {
		"name": "Creativity",
		"domain": "learning",
		"color": Color(0.7, 0.4, 0.9),
		"personality": "Playful and abstract",
		"unlocked": false,
		"level": 1,
		"experience": 0
	},
	"compassion": {
		"name": "Compassion",
		"domain": "social",
		"color": Color(0.3, 0.7, 0.5),
		"personality": "Warm and nurturing",
		"unlocked": false,
		"level": 1,
		"experience": 0
	},
	"wisdom": {
		"name": "Wisdom",
		"domain": "mindfulness",
		"color": Color(0.9, 0.8, 0.3),
		"personality": "Calm and insightful",
		"unlocked": false,
		"level": 1,
		"experience": 0
	},
	"vitality": {
		"name": "Vitality",
		"domain": "health",
		"color": Color(0.2, 0.8, 0.4),
		"personality": "Energetic and physical",
		"unlocked": false,
		"level": 1,
		"experience": 0
	}
}


func _ready() -> void:
	# Initialize aspects in player data
	for aspect_key in ASPECTS:
		player_data.aspects[aspect_key] = ASPECTS[aspect_key].duplicate(true)

	# Create transition overlay
	_create_transition_overlay()

	print("[GameManager] Initialized - GOACTO Mindscape ready")


# Transition overlay
var transition_overlay: CanvasLayer = null
var transition_rect: ColorRect = null
var is_transitioning: bool = false
const FADE_DURATION: float = 0.3


func _create_transition_overlay() -> void:
	transition_overlay = CanvasLayer.new()
	transition_overlay.name = "TransitionOverlay"
	transition_overlay.layer = 100  # Above everything
	add_child(transition_overlay)

	transition_rect = ColorRect.new()
	transition_rect.name = "FadeRect"
	transition_rect.color = Color(0.02, 0.03, 0.06, 0.0)
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_overlay.add_child(transition_rect)


## Change game state with signal emission
func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return

	previous_state = current_state
	current_state = new_state
	state_changed.emit(new_state, previous_state)
	print("[GameManager] State changed: ", GameState.keys()[previous_state], " -> ", GameState.keys()[new_state])


## Transition to a new scene with fade effect
func goto_scene(scene_path: String, use_fade: bool = true) -> void:
	if is_transitioning:
		return

	# Stop any playing voice audio when leaving a scene
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()

	# Track scene paths - save current as previous unless we're IN settings
	# This ensures we return to the right place when leaving settings
	if not current_scene_path.contains("settings"):
		previous_scene_path = current_scene_path
	current_scene_path = scene_path

	if use_fade and transition_rect:
		is_transitioning = true
		_fade_to_scene(scene_path)
	else:
		call_deferred("_deferred_goto_scene", scene_path)


func _fade_to_scene(scene_path: String) -> void:
	# Fade out
	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(func():
		# Change scene
		get_tree().change_scene_to_file(scene_path)
		# Fade in after a brief delay
		var fade_in_tween = create_tween()
		fade_in_tween.tween_interval(0.1)  # Brief pause
		fade_in_tween.tween_property(transition_rect, "color:a", 0.0, FADE_DURATION)
		fade_in_tween.tween_callback(func(): is_transitioning = false)
	)


func _deferred_goto_scene(scene_path: String) -> void:
	# Safe scene transition (no fade)
	get_tree().change_scene_to_file(scene_path)


## Add experience to an aspect based on habit domain
func add_aspect_experience(domain: String, amount: int) -> void:
	for aspect_key in player_data.aspects:
		var aspect = player_data.aspects[aspect_key]
		if aspect.domain == domain or domain == "all":
			aspect.experience += amount
			_check_aspect_levelup(aspect_key)


## Check if aspect should level up
func _check_aspect_levelup(aspect_key: String) -> void:
	var aspect = player_data.aspects[aspect_key]
	var exp_needed = aspect.level * 100  # Simple scaling: level 1 needs 100, level 2 needs 200, etc.

	if aspect.experience >= exp_needed:
		aspect.experience -= exp_needed
		aspect.level += 1
		aspect_leveled_up.emit(aspect.name, aspect.level)
		print("[GameManager] ", aspect.name, " leveled up to ", aspect.level, "!")


## Evolve the world based on completed actions
func evolve_world(amount: float) -> void:
	player_data.world_evolution_level = min(100.0, player_data.world_evolution_level + amount)
	world_evolution_triggered.emit(amount)
	print("[GameManager] World evolved! Level: ", player_data.world_evolution_level)


## Get current world evolution as a 0-1 float for visual effects
func get_world_evolution_normalized() -> float:
	return player_data.world_evolution_level / 100.0


## Get evolution level as an integer (1-10, each level is 10% evolution)
func get_evolution_level() -> int:
	return int(player_data.world_evolution_level / 10.0) + 1


## Get progress within current evolution level (0.0 to 1.0)
func get_evolution_progress() -> float:
	var level_progress = fmod(player_data.world_evolution_level, 10.0)
	return level_progress / 10.0


# ============== INVENTORY SYSTEM ==============

## Check if player has an item in inventory
func has_item(item_id: String) -> bool:
	return item_id in player_data.inventory


## Add an item to inventory
func add_item(item_id: String) -> void:
	if not has_item(item_id):
		player_data.inventory.append(item_id)
		print("[GameManager] Added item to inventory: ", item_id)
		SaveManager.save_game()


## Remove an item from inventory
func remove_item(item_id: String) -> void:
	if has_item(item_id):
		player_data.inventory.erase(item_id)
		print("[GameManager] Removed item from inventory: ", item_id)
		SaveManager.save_game()


## Check if player has master key (unlocks all mindscape content)
func has_master_key() -> bool:
	return has_item("master_key")


## Called when player completes a focus session
func complete_focus_session(minutes: int, habit_domain: String) -> void:
	complete_focus_session_with_multiplier(minutes, habit_domain, 1.0)


## Called when player completes a focus session with difficulty multiplier
func complete_focus_session_with_multiplier(minutes: int, habit_domain: String, xp_multiplier: float) -> void:
	player_data.total_focus_minutes += minutes
	player_data.total_focus_sessions = player_data.get("total_focus_sessions", 0) + 1

	# Award experience based on time and difficulty multiplier
	var base_exp = minutes * 2
	var exp_amount = int(base_exp * xp_multiplier)
	add_aspect_experience(habit_domain, exp_amount)

	# Evolve world (also scaled by multiplier)
	var evolution_amount = minutes * 0.1 * xp_multiplier
	evolve_world(evolution_amount)

	# Save progress
	SaveManager.save_game()


## Check if a tutorial has been shown
func has_seen_tutorial(tutorial_id: String) -> bool:
	return tutorial_id in player_data.seen_tutorials


## Mark a tutorial as seen
func mark_tutorial_seen(tutorial_id: String) -> void:
	if tutorial_id not in player_data.seen_tutorials:
		player_data.seen_tutorials.append(tutorial_id)
		SaveManager.save_game()


## Check if an object has been discovered/interacted with
func has_discovered_object(object_id: String) -> bool:
	var discovered = player_data.get("discovered_objects", [])
	return object_id in discovered


## Mark an object as discovered (removes shimmer hint)
func mark_object_discovered(object_id: String) -> void:
	if not player_data.has("discovered_objects"):
		player_data["discovered_objects"] = []
	if object_id not in player_data.discovered_objects:
		player_data.discovered_objects.append(object_id)
		# Don't auto-save for every discovery to avoid excessive saves


## Complete onboarding
func complete_onboarding() -> void:
	player_data.has_completed_onboarding = true
	SaveManager.save_game()


## Reset all player data to defaults
func reset_player_data() -> void:
	player_data = {
		"name": "Traveler",
		"avatar": {},
		"world_evolution_level": 0.0,
		"total_focus_minutes": 0,
		"total_focus_sessions": 0,
		"total_habits_completed": 0,
		"current_streak_days": 0,
		"aspects": {},
		"unlocked_zones": ["origin"],
		"inventory": [],
		"has_completed_onboarding": false,
		"seen_tutorials": [],
		"discovered_objects": [],
		"collected_decor": [],
		"bedroom_decorations": [],
		# Bedroom progression - starts minimal, items unlock through campaign
		"console_placed_in_bedroom": false,
		"bedroom_items_installed": [],  # ["wardrobe", "mirror", "data_archive"]
		"closet_unlocked": false,
		"mirror_unlocked": false,
		"bookshelf_unlocked": false,
		"master_key_bedroom_notification_shown": false,
		"settings": {
			"focus_duration": 25,
			"notifications": true,
			"sound": true
		}
	}

	# Re-initialize aspects
	for aspect_key in ASPECTS:
		player_data.aspects[aspect_key] = ASPECTS[aspect_key].duplicate(true)

	print("[GameManager] Player data reset to defaults")


## Check if a zone is unlocked
func is_zone_unlocked(zone_id: String) -> bool:
	# Master key unlocks everything
	if has_master_key():
		return true

	# Check if already in unlocked list
	if zone_id in player_data.unlocked_zones:
		return true

	# Check if zone exists in tier system
	if not ZONE_TIERS.has(zone_id):
		return true  # Unknown zones default to unlocked

	var zone_info = ZONE_TIERS[zone_id]

	# Tier 1 is always unlocked
	if zone_info.tier == 1:
		return true

	# Check requirement
	match zone_info.requirement:
		"none":
			return true
		"chapter":
			# Check if the required chapter has been completed
			var required_chapter = "chapter_" + str(zone_info.value)
			return CampaignManager.is_chapter_completed(required_chapter)
		"evolution":
			return player_data.world_evolution_level >= zone_info.value
		"aspect":
			var aspect_key = zone_info.get("aspect", "")
			if aspect_key != "" and player_data.aspects.has(aspect_key):
				return player_data.aspects[aspect_key].level >= zone_info.value
			return false
		_:
			return false


## Get the unlock requirement text for a zone
func get_zone_requirement(zone_id: String) -> String:
	if not ZONE_TIERS.has(zone_id):
		return ""
	return ZONE_TIERS[zone_id].requirement_text


## Get zone tier
func get_zone_tier(zone_id: String) -> int:
	if not ZONE_TIERS.has(zone_id):
		return 1
	return ZONE_TIERS[zone_id].tier


## Get unlock progress for a zone (0.0 to 1.0)
## Returns -1 if zone is already unlocked or has non-evolution requirement
func get_zone_unlock_progress(zone_id: String) -> float:
	if is_zone_unlocked(zone_id):
		return 1.0

	if not ZONE_TIERS.has(zone_id):
		return -1.0

	var zone_info = ZONE_TIERS[zone_id]

	match zone_info.requirement:
		"evolution":
			var required = zone_info.value
			if required <= 0:
				return 1.0
			return clampf(player_data.world_evolution_level / required, 0.0, 1.0)
		"chapter":
			# Chapter progress is binary for now
			return 0.0
		_:
			return -1.0


## Check if zone is "almost unlocked" (80%+ progress)
func is_zone_almost_unlocked(zone_id: String) -> bool:
	var progress = get_zone_unlock_progress(zone_id)
	return progress >= 0.8 and progress < 1.0


## Get "almost unlocked" text for a zone
func get_zone_almost_unlocked_text(zone_id: String) -> String:
	if not is_zone_almost_unlocked(zone_id):
		return ""

	var progress = get_zone_unlock_progress(zone_id)
	var percent = int(progress * 100)
	return "Almost there! %d%% progress" % percent


## Manually unlock a zone (for story triggers, etc.)
func unlock_zone(zone_id: String) -> void:
	if zone_id not in player_data.unlocked_zones:
		player_data.unlocked_zones.append(zone_id)
		zone_unlocked.emit(zone_id)
		SaveManager.save_game()
		print("[GameManager] Zone unlocked: ", zone_id)


## Check and unlock all zones that meet requirements
func check_zone_unlocks() -> Array:
	var newly_unlocked: Array = []

	for zone_id in ZONE_TIERS:
		if zone_id not in player_data.unlocked_zones:
			if is_zone_unlocked(zone_id):
				player_data.unlocked_zones.append(zone_id)
				newly_unlocked.append(zone_id)
				zone_unlocked.emit(zone_id)

	if newly_unlocked.size() > 0:
		SaveManager.save_game()
		print("[GameManager] Zones newly unlocked: ", newly_unlocked)

	return newly_unlocked


# ============== ASPECT SYSTEM ==============

## Get all aspects as an array of dictionaries with id included
func get_all_aspects() -> Array:
	var result: Array = []
	for aspect_key in player_data.aspects:
		var aspect = player_data.aspects[aspect_key].duplicate()
		aspect["id"] = aspect_key
		result.append(aspect)
	return result


## Get the level of a specific aspect
func get_aspect_level(aspect_id: String) -> int:
	if player_data.aspects.has(aspect_id):
		return player_data.aspects[aspect_id].get("level", 1)
	return 1


# ============== ACCESSIBILITY SYSTEM ==============

var _settings_cache: Dictionary = {}


## Load and cache accessibility settings
func _load_accessibility_settings() -> void:
	if SaveManager:
		_settings_cache = SaveManager.load_settings()
	else:
		_settings_cache = {
			"font_size": "medium",
			"high_contrast": false,
			"reduced_motion": false,
			"colorblind_mode": "none"
		}


## Get font size multiplier based on setting
func get_font_size_multiplier() -> float:
	if _settings_cache.is_empty():
		_load_accessibility_settings()

	var size = _settings_cache.get("font_size", "medium")
	match size:
		"small": return 0.85
		"medium": return 1.0
		"large": return 1.25
		_: return 1.0


## Get scaled font size
func get_scaled_font_size(base_size: int) -> int:
	return int(base_size * get_font_size_multiplier())


## Check if high contrast mode is enabled
func is_high_contrast() -> bool:
	if _settings_cache.is_empty():
		_load_accessibility_settings()
	return _settings_cache.get("high_contrast", false)


## Check if reduced motion is enabled
func is_reduced_motion() -> bool:
	if _settings_cache.is_empty():
		_load_accessibility_settings()
	return _settings_cache.get("reduced_motion", false)


## Get colorblind mode
func get_colorblind_mode() -> String:
	if _settings_cache.is_empty():
		_load_accessibility_settings()
	return _settings_cache.get("colorblind_mode", "none")


## Update accessibility setting and save
func set_accessibility_option(key: String, value) -> void:
	if _settings_cache.is_empty():
		_load_accessibility_settings()

	_settings_cache[key] = value

	if SaveManager:
		SaveManager.save_settings(_settings_cache)


## Adjust color for colorblind mode
func adjust_color_for_colorblind(color: Color) -> Color:
	var mode = get_colorblind_mode()
	if mode == "none":
		return color

	# Simple colorblind simulation adjustments
	match mode:
		"deuteranopia":  # Red-green (green weak)
			return Color(
				color.r * 0.8 + color.g * 0.2,
				color.g * 0.7 + color.b * 0.3,
				color.b,
				color.a
			)
		"protanopia":  # Red-green (red weak)
			return Color(
				color.r * 0.6 + color.g * 0.4,
				color.g * 0.8 + color.r * 0.2,
				color.b,
				color.a
			)
		"tritanopia":  # Blue-yellow
			return Color(
				color.r,
				color.g * 0.8 + color.b * 0.2,
				color.b * 0.6 + color.g * 0.4,
				color.a
			)
		_:
			return color


# ============== CHARACTER BOND SYSTEM ==============

signal character_bond_increased(character_id: String, new_level: int, amount: int)
signal character_bond_milestone(character_id: String, milestone: String)

# Character definitions
const CHARACTERS = {
	"mom": {
		"name": "Mom",
		"description": "Your Goactorian mother, guiding you from the ship",
		"color": Color(0.9, 0.7, 0.5),
		"max_bond": 100
	},
	"discipline": {
		"name": "Discipline",
		"description": "The Aspect of consistency and structure",
		"color": Color(0.2, 0.4, 0.8),
		"max_bond": 100
	},
	"courage": {
		"name": "Courage",
		"description": "The Aspect of bravery and facing fears",
		"color": Color(0.8, 0.3, 0.2),
		"max_bond": 100
	},
	"creativity": {
		"name": "Creativity",
		"description": "The Aspect of imagination and expression",
		"color": Color(0.7, 0.4, 0.9),
		"max_bond": 100
	},
	"compassion": {
		"name": "Compassion",
		"description": "The Aspect of empathy and kindness",
		"color": Color(0.3, 0.7, 0.5),
		"max_bond": 100
	},
	"wisdom": {
		"name": "Wisdom",
		"description": "The Aspect of insight and reflection",
		"color": Color(0.9, 0.8, 0.3),
		"max_bond": 100
	},
	"vitality": {
		"name": "Vitality",
		"description": "The Aspect of health and energy",
		"color": Color(0.2, 0.8, 0.4),
		"max_bond": 100
	}
}

# Bond level thresholds and titles
const BOND_LEVELS = {
	0: {"title": "Stranger", "min": 0},
	1: {"title": "Acquaintance", "min": 10},
	2: {"title": "Familiar", "min": 25},
	3: {"title": "Friend", "min": 45},
	4: {"title": "Close Friend", "min": 65},
	5: {"title": "Trusted Ally", "min": 85},
	6: {"title": "Kindred Spirit", "min": 100}
}

# Character bonds storage (in player_data)
func _ensure_character_bonds() -> void:
	if not player_data.has("character_bonds"):
		player_data["character_bonds"] = {}
		for char_id in CHARACTERS:
			player_data.character_bonds[char_id] = {
				"bond_points": 0,
				"interactions": 0,
				"last_interaction": "",
				"milestones": []
			}


## Get bond points for a character
func get_character_bond(character_id: String) -> int:
	_ensure_character_bonds()
	if player_data.character_bonds.has(character_id):
		return player_data.character_bonds[character_id].get("bond_points", 0)
	return 0


## Get bond level (0-6) for a character
func get_character_bond_level(character_id: String) -> int:
	var points = get_character_bond(character_id)
	var level = 0
	for lvl in BOND_LEVELS:
		if points >= BOND_LEVELS[lvl].min:
			level = lvl
	return level


## Get bond title for a character
func get_character_bond_title(character_id: String) -> String:
	var level = get_character_bond_level(character_id)
	return BOND_LEVELS[level].title


## Increase bond with a character
func increase_character_bond(character_id: String, amount: int, reason: String = "") -> void:
	_ensure_character_bonds()
	if not player_data.character_bonds.has(character_id):
		return

	var char_data = player_data.character_bonds[character_id]
	var old_level = get_character_bond_level(character_id)
	var max_bond = CHARACTERS.get(character_id, {}).get("max_bond", 100)

	char_data.bond_points = mini(char_data.bond_points + amount, max_bond)
	char_data.interactions += 1
	char_data.last_interaction = Time.get_datetime_string_from_system()

	if reason != "" and reason not in char_data.milestones:
		char_data.milestones.append(reason)

	var new_level = get_character_bond_level(character_id)

	if new_level > old_level:
		character_bond_increased.emit(character_id, new_level, amount)
		var milestone_name = BOND_LEVELS[new_level].title
		character_bond_milestone.emit(character_id, milestone_name)
		print("[GameManager] Bond with %s increased to level %d (%s)" % [character_id, new_level, milestone_name])


## Get all character bonds as array
func get_all_character_bonds() -> Array:
	_ensure_character_bonds()
	var result = []
	for char_id in CHARACTERS:
		var char_info = CHARACTERS[char_id].duplicate()
		char_info["id"] = char_id
		char_info["bond_points"] = get_character_bond(char_id)
		char_info["bond_level"] = get_character_bond_level(char_id)
		char_info["bond_title"] = get_character_bond_title(char_id)
		if player_data.character_bonds.has(char_id):
			char_info["interactions"] = player_data.character_bonds[char_id].get("interactions", 0)
			char_info["milestones"] = player_data.character_bonds[char_id].get("milestones", [])
		result.append(char_info)
	return result


## Get progress to next bond level (0.0 to 1.0)
func get_bond_progress(character_id: String) -> float:
	var current_level = get_character_bond_level(character_id)
	var current_points = get_character_bond(character_id)

	if current_level >= 6:
		return 1.0

	var current_min = BOND_LEVELS[current_level].min
	var next_min = BOND_LEVELS[current_level + 1].min
	var range_size = next_min - current_min

	if range_size <= 0:
		return 1.0

	return float(current_points - current_min) / float(range_size)


## Record interaction with Mom (called from cutscenes, dialogues)
func record_mom_interaction(interaction_type: String = "dialogue") -> void:
	var amount = 2
	match interaction_type:
		"cutscene": amount = 5
		"call": amount = 3
		"letter": amount = 4
		"milestone": amount = 10
		_: amount = 2
	increase_character_bond("mom", amount, interaction_type)


## Record interaction with an Aspect (called from shrine, dialogues)
func record_aspect_interaction(aspect_id: String, interaction_type: String = "dialogue") -> void:
	var amount = 2
	match interaction_type:
		"communion": amount = 3
		"advice": amount = 2
		"challenge_accepted": amount = 5
		"challenge_completed": amount = 10
		"awakening": amount = 15
		_: amount = 2
	increase_character_bond(aspect_id, amount, interaction_type)


# ============================================
# ASPECT QUEST/CHALLENGE SYSTEM
# ============================================

signal quest_accepted(quest_id: String, aspect_id: String)
signal quest_completed(quest_id: String, aspect_id: String, xp_earned: int)
signal quest_abandoned(quest_id: String)

# Quest definitions - each aspect has unique quests across 3 difficulty tiers
const ASPECT_QUESTS = {
	"discipline": {
		"disc_focus_streak": {
			"name": "Focused Intent",
			"description": "Complete 3 focus sessions of at least 15 minutes each within 24 hours.",
			"difficulty": "easy",
			"xp_reward": 25,
			"bond_reward": 5,
			"requirements": {"focus_sessions": 3, "min_duration": 15, "time_limit_hours": 24},
			"icon": "🎯"
		},
		"disc_habit_chain": {
			"name": "Chain of Will",
			"description": "Complete all your habits for 3 consecutive days.",
			"difficulty": "medium",
			"xp_reward": 50,
			"bond_reward": 8,
			"requirements": {"habit_streak_days": 3},
			"icon": "⛓️"
		},
		"disc_morning_ritual": {
			"name": "Dawn's Discipline",
			"description": "Complete 5 habits before noon for 5 days.",
			"difficulty": "hard",
			"xp_reward": 100,
			"bond_reward": 15,
			"requirements": {"morning_habits": 5, "days": 5},
			"icon": "🌅"
		}
	},
	"courage": {
		"cour_new_habit": {
			"name": "Leap of Faith",
			"description": "Create and complete a new challenging habit for the first time.",
			"difficulty": "easy",
			"xp_reward": 25,
			"bond_reward": 5,
			"requirements": {"new_habit_completed": true},
			"icon": "🦁"
		},
		"cour_shadow_work": {
			"name": "Face the Shadow",
			"description": "Complete 3 shadow work journal entries.",
			"difficulty": "medium",
			"xp_reward": 50,
			"bond_reward": 8,
			"requirements": {"shadow_entries": 3},
			"icon": "🌑"
		},
		"cour_long_focus": {
			"name": "Endurance Trial",
			"description": "Complete a single focus session of 60 minutes or more.",
			"difficulty": "hard",
			"xp_reward": 100,
			"bond_reward": 15,
			"requirements": {"single_session_minutes": 60},
			"icon": "🏔️"
		}
	},
	"creativity": {
		"crea_script_create": {
			"name": "Script Spark",
			"description": "Create a new behavioral script in the Script Lab.",
			"difficulty": "easy",
			"xp_reward": 25,
			"bond_reward": 5,
			"requirements": {"scripts_created": 1},
			"icon": "✨"
		},
		"crea_dream_journal": {
			"name": "Dream Weaver",
			"description": "Record 5 dreams in the dream journal.",
			"difficulty": "medium",
			"xp_reward": 50,
			"bond_reward": 8,
			"requirements": {"dream_entries": 5},
			"icon": "💭"
		},
		"crea_varied_focus": {
			"name": "Polymathic Path",
			"description": "Complete focus sessions in 4 different categories.",
			"difficulty": "hard",
			"xp_reward": 100,
			"bond_reward": 15,
			"requirements": {"unique_categories": 4},
			"icon": "🎨"
		}
	},
	"compassion": {
		"comp_kindness_log": {
			"name": "Ripples of Kindness",
			"description": "Log 3 acts of kindness in a single day.",
			"difficulty": "easy",
			"xp_reward": 25,
			"bond_reward": 5,
			"requirements": {"kindness_acts_daily": 3},
			"icon": "💝"
		},
		"comp_relationship": {
			"name": "Connection Builder",
			"description": "Log interactions with 3 different relationships in a week.",
			"difficulty": "medium",
			"xp_reward": 50,
			"bond_reward": 8,
			"requirements": {"relationships_contacted": 3, "time_limit_days": 7},
			"icon": "🤝"
		},
		"comp_gratitude_streak": {
			"name": "Gratitude Garden",
			"description": "Write in the gratitude journal for 7 consecutive days.",
			"difficulty": "hard",
			"xp_reward": 100,
			"bond_reward": 15,
			"requirements": {"gratitude_streak_days": 7},
			"icon": "🌸"
		}
	},
	"wisdom": {
		"wis_reflection": {
			"name": "Pool of Insight",
			"description": "Complete a weekly synthesis reflection.",
			"difficulty": "easy",
			"xp_reward": 25,
			"bond_reward": 5,
			"requirements": {"weekly_synthesis": 1},
			"icon": "🪞"
		},
		"wis_values_check": {
			"name": "Compass True",
			"description": "Complete a values alignment check with all values rated.",
			"difficulty": "medium",
			"xp_reward": 50,
			"bond_reward": 8,
			"requirements": {"values_check_complete": true},
			"icon": "🧭"
		},
		"wis_meditation": {
			"name": "Still Waters",
			"description": "Complete 10 meditation sessions total.",
			"difficulty": "hard",
			"xp_reward": 100,
			"bond_reward": 15,
			"requirements": {"meditation_sessions": 10},
			"icon": "🧘"
		}
	},
	"vitality": {
		"vita_energy_check": {
			"name": "Energy Pulse",
			"description": "Track your energy in daily check-ins for 3 days.",
			"difficulty": "easy",
			"xp_reward": 25,
			"bond_reward": 5,
			"requirements": {"energy_checkins": 3},
			"icon": "⚡"
		},
		"vita_health_habits": {
			"name": "Temple Care",
			"description": "Complete 5 health-domain habits.",
			"difficulty": "medium",
			"xp_reward": 50,
			"bond_reward": 8,
			"requirements": {"health_habits": 5},
			"icon": "💪"
		},
		"vita_full_day": {
			"name": "Peak Performance",
			"description": "Rate both mood and energy 4+ on the same day for 5 days.",
			"difficulty": "hard",
			"xp_reward": 100,
			"bond_reward": 15,
			"requirements": {"high_vitality_days": 5},
			"icon": "🌟"
		}
	}
}

## Initialize quest data in player_data
func _ensure_quest_data() -> void:
	if not player_data.has("active_quests"):
		player_data["active_quests"] = {}  # quest_id -> {accepted_at, progress, aspect_id}
	if not player_data.has("completed_quests"):
		player_data["completed_quests"] = []  # [{quest_id, completed_at, aspect_id}]
	if not player_data.has("quest_stats"):
		player_data["quest_stats"] = {
			"total_completed": 0,
			"total_xp_earned": 0,
			"quests_by_aspect": {}
		}


## Get all available quests for an aspect (not currently active or recently completed)
func get_available_quests(aspect_id: String) -> Array:
	_ensure_quest_data()

	if not ASPECT_QUESTS.has(aspect_id):
		return []

	var available = []
	var aspect_quests = ASPECT_QUESTS[aspect_id]

	for quest_id in aspect_quests:
		# Skip if already active
		if player_data.active_quests.has(quest_id):
			continue

		# Skip if completed in last 7 days (repeatable after cooldown)
		var recently_completed = false
		for completed in player_data.completed_quests:
			if completed.quest_id == quest_id:
				var completed_time = completed.get("completed_at", 0)
				var days_since = (Time.get_unix_time_from_system() - completed_time) / 86400.0
				if days_since < 7:
					recently_completed = true
					break

		if not recently_completed:
			var quest = aspect_quests[quest_id].duplicate()
			quest["id"] = quest_id
			quest["aspect_id"] = aspect_id
			available.append(quest)

	return available


## Accept a quest from an aspect
func accept_quest(quest_id: String, aspect_id: String) -> bool:
	_ensure_quest_data()

	# Validate quest exists
	if not ASPECT_QUESTS.has(aspect_id) or not ASPECT_QUESTS[aspect_id].has(quest_id):
		return false

	# Check if already active
	if player_data.active_quests.has(quest_id):
		return false

	# Limit active quests to 3 per aspect, 6 total
	var active_count = player_data.active_quests.size()
	if active_count >= 6:
		return false

	var aspect_active = 0
	for qid in player_data.active_quests:
		if player_data.active_quests[qid].aspect_id == aspect_id:
			aspect_active += 1
	if aspect_active >= 3:
		return false

	# Accept the quest
	player_data.active_quests[quest_id] = {
		"aspect_id": aspect_id,
		"accepted_at": Time.get_unix_time_from_system(),
		"progress": {},
		"quest_data": ASPECT_QUESTS[aspect_id][quest_id].duplicate()
	}

	quest_accepted.emit(quest_id, aspect_id)
	SaveManager.save_game()
	return true


## Get all active quests
func get_active_quests() -> Array:
	_ensure_quest_data()
	var result = []

	for quest_id in player_data.active_quests:
		var quest_info = player_data.active_quests[quest_id].duplicate()
		quest_info["id"] = quest_id
		result.append(quest_info)

	return result


## Get active quests for a specific aspect
func get_active_quests_for_aspect(aspect_id: String) -> Array:
	_ensure_quest_data()
	var result = []

	for quest_id in player_data.active_quests:
		if player_data.active_quests[quest_id].aspect_id == aspect_id:
			var quest_info = player_data.active_quests[quest_id].duplicate()
			quest_info["id"] = quest_id
			result.append(quest_info)

	return result


## Update quest progress (called from various game actions)
func update_quest_progress(quest_id: String, progress_key: String, value) -> void:
	_ensure_quest_data()

	if not player_data.active_quests.has(quest_id):
		return

	player_data.active_quests[quest_id].progress[progress_key] = value

	# Check if quest is now complete
	_check_quest_completion(quest_id)


## Increment quest progress counter
func increment_quest_progress(quest_id: String, progress_key: String, amount: int = 1) -> void:
	_ensure_quest_data()

	if not player_data.active_quests.has(quest_id):
		return

	var current = player_data.active_quests[quest_id].progress.get(progress_key, 0)
	player_data.active_quests[quest_id].progress[progress_key] = current + amount

	_check_quest_completion(quest_id)


## Check all active quests for a specific trigger type
func check_quests_for_trigger(trigger_type: String, data: Dictionary = {}) -> void:
	_ensure_quest_data()

	for quest_id in player_data.active_quests.keys():
		var quest = player_data.active_quests[quest_id]
		var requirements = quest.quest_data.get("requirements", {})

		match trigger_type:
			"focus_session_completed":
				if requirements.has("focus_sessions"):
					increment_quest_progress(quest_id, "focus_sessions", 1)
				if requirements.has("single_session_minutes"):
					var duration = data.get("duration_minutes", 0)
					if duration >= requirements.single_session_minutes:
						update_quest_progress(quest_id, "long_session_completed", true)
				if requirements.has("unique_categories"):
					var category = data.get("category", "")
					if category:
						var categories = quest.progress.get("categories", [])
						if category not in categories:
							categories.append(category)
							update_quest_progress(quest_id, "categories", categories)

			"habit_completed":
				var domain = data.get("domain", "")
				if domain == "health" and requirements.has("health_habits"):
					increment_quest_progress(quest_id, "health_habits", 1)
				if requirements.has("new_habit_completed") and data.get("is_first_completion", false):
					update_quest_progress(quest_id, "new_habit_completed", true)

			"habit_streak_day":
				if requirements.has("habit_streak_days"):
					var streak = data.get("streak", 0)
					update_quest_progress(quest_id, "habit_streak_days", streak)

			"journal_entry":
				var journal_type = data.get("type", "")
				if journal_type == "shadow" and requirements.has("shadow_entries"):
					increment_quest_progress(quest_id, "shadow_entries", 1)
				if journal_type == "dream" and requirements.has("dream_entries"):
					increment_quest_progress(quest_id, "dream_entries", 1)
				if journal_type == "gratitude" and requirements.has("gratitude_streak_days"):
					var streak = data.get("streak", 1)
					update_quest_progress(quest_id, "gratitude_streak_days", streak)

			"kindness_logged":
				if requirements.has("kindness_acts_daily"):
					increment_quest_progress(quest_id, "kindness_acts_daily", 1)

			"script_created":
				if requirements.has("scripts_created"):
					increment_quest_progress(quest_id, "scripts_created", 1)

			"weekly_synthesis":
				if requirements.has("weekly_synthesis"):
					update_quest_progress(quest_id, "weekly_synthesis_completed", true)

			"values_check":
				if requirements.has("values_check_complete"):
					update_quest_progress(quest_id, "values_check_completed", true)

			"meditation_completed":
				if requirements.has("meditation_sessions"):
					increment_quest_progress(quest_id, "meditation_sessions", 1)

			"checkin_completed":
				if requirements.has("energy_checkins"):
					increment_quest_progress(quest_id, "energy_checkins", 1)
				var mood = data.get("mood", 0)
				var energy = data.get("energy", 0)
				if mood >= 4 and energy >= 4 and requirements.has("high_vitality_days"):
					increment_quest_progress(quest_id, "high_vitality_days", 1)

			"relationship_interaction":
				if requirements.has("relationships_contacted"):
					var contacted = quest.progress.get("relationships", [])
					var rel_id = data.get("relationship_id", "")
					if rel_id and rel_id not in contacted:
						contacted.append(rel_id)
						update_quest_progress(quest_id, "relationships", contacted)


## Check if a quest is complete
func _check_quest_completion(quest_id: String) -> void:
	if not player_data.active_quests.has(quest_id):
		return

	var quest = player_data.active_quests[quest_id]
	var requirements = quest.quest_data.get("requirements", {})
	var progress = quest.progress

	var is_complete = true

	for req_key in requirements:
		var req_value = requirements[req_key]
		var prog_value = progress.get(req_key, progress.get(req_key + "_completed", false))

		# Handle different requirement types
		if req_key.ends_with("_hours") or req_key.ends_with("_days"):
			continue  # Time limits checked separately

		if typeof(req_value) == TYPE_BOOL:
			if prog_value != req_value:
				is_complete = false
				break
		elif typeof(req_value) == TYPE_INT or typeof(req_value) == TYPE_FLOAT:
			if typeof(prog_value) == TYPE_ARRAY:
				if prog_value.size() < req_value:
					is_complete = false
					break
			elif prog_value < req_value:
				is_complete = false
				break

	if is_complete:
		complete_quest(quest_id)


## Complete a quest and award rewards
func complete_quest(quest_id: String) -> void:
	_ensure_quest_data()

	if not player_data.active_quests.has(quest_id):
		return

	var quest = player_data.active_quests[quest_id]
	var aspect_id = quest.aspect_id
	var quest_data = quest.quest_data

	# Award XP
	var xp_reward = quest_data.get("xp_reward", 25)
	add_aspect_experience(aspect_id, xp_reward)

	# Award bond points
	var bond_reward = quest_data.get("bond_reward", 5)
	increase_character_bond(aspect_id, bond_reward, "quest_completed")

	# Record completion
	player_data.completed_quests.append({
		"quest_id": quest_id,
		"aspect_id": aspect_id,
		"completed_at": Time.get_unix_time_from_system(),
		"xp_earned": xp_reward
	})

	# Update stats
	player_data.quest_stats.total_completed += 1
	player_data.quest_stats.total_xp_earned += xp_reward
	if not player_data.quest_stats.quests_by_aspect.has(aspect_id):
		player_data.quest_stats.quests_by_aspect[aspect_id] = 0
	player_data.quest_stats.quests_by_aspect[aspect_id] += 1

	# Remove from active
	player_data.active_quests.erase(quest_id)

	quest_completed.emit(quest_id, aspect_id, xp_reward)
	SaveManager.save_game()


## Abandon a quest
func abandon_quest(quest_id: String) -> void:
	_ensure_quest_data()

	if player_data.active_quests.has(quest_id):
		player_data.active_quests.erase(quest_id)
		quest_abandoned.emit(quest_id)
		SaveManager.save_game()


## Get quest completion stats
func get_quest_stats() -> Dictionary:
	_ensure_quest_data()
	return player_data.quest_stats.duplicate()


## Get completed quests for an aspect
func get_completed_quests_for_aspect(aspect_id: String) -> Array:
	_ensure_quest_data()
	var result = []

	for completed in player_data.completed_quests:
		if completed.aspect_id == aspect_id:
			result.append(completed)

	return result


# ============================================
# DAILY LOGIN REWARDS SYSTEM
# ============================================

signal daily_reward_available(day: int, reward: Dictionary)
signal daily_reward_claimed(day: int, reward: Dictionary)
signal milestone_reached(milestone_id: String, days: int)

const DAILY_REWARDS = [
	# Day 1-7 (Week 1)
	{"day": 1, "type": "xp", "amount": 25, "description": "Welcome back, Traveler!"},
	{"day": 2, "type": "xp", "amount": 30, "description": "Building momentum..."},
	{"day": 3, "type": "xp", "amount": 35, "description": "Three days strong!"},
	{"day": 4, "type": "xp", "amount": 40, "description": "Consistency is key."},
	{"day": 5, "type": "xp", "amount": 50, "description": "Halfway through the week!"},
	{"day": 6, "type": "xp", "amount": 60, "description": "Almost there..."},
	{"day": 7, "type": "special", "amount": 100, "bonus": "lore_fragment", "description": "Week complete! Bonus lore unlocked."},
	# Day 8-14 (Week 2)
	{"day": 8, "type": "xp", "amount": 35, "description": "A new week begins."},
	{"day": 9, "type": "xp", "amount": 40, "description": "Keep going!"},
	{"day": 10, "type": "xp", "amount": 45, "description": "Double digits!"},
	{"day": 11, "type": "xp", "amount": 50, "description": "Your dedication inspires."},
	{"day": 12, "type": "xp", "amount": 55, "description": "Growth takes time."},
	{"day": 13, "type": "xp", "amount": 65, "description": "Nearly two weeks!"},
	{"day": 14, "type": "special", "amount": 150, "bonus": "cosmetic_color", "description": "Two weeks! New avatar color unlocked."},
	# Day 15-21 (Week 3)
	{"day": 15, "type": "xp", "amount": 50, "description": "Week three warrior!"},
	{"day": 16, "type": "xp", "amount": 55, "description": "Habits forming..."},
	{"day": 17, "type": "xp", "amount": 60, "description": "You're remarkable."},
	{"day": 18, "type": "xp", "amount": 65, "description": "The journey continues."},
	{"day": 19, "type": "xp", "amount": 70, "description": "Almost three weeks!"},
	{"day": 20, "type": "xp", "amount": 75, "description": "20 days of growth!"},
	{"day": 21, "type": "special", "amount": 200, "bonus": "companion_accessory", "description": "21 days! Companion accessory unlocked."},
	# Day 22-30 (Month 1)
	{"day": 22, "type": "xp", "amount": 60, "description": "The final stretch..."},
	{"day": 23, "type": "xp", "amount": 65, "description": "One week to go!"},
	{"day": 24, "type": "xp", "amount": 70, "description": "You've come so far."},
	{"day": 25, "type": "xp", "amount": 75, "description": "25 days of dedication!"},
	{"day": 26, "type": "xp", "amount": 80, "description": "Nearly a month..."},
	{"day": 27, "type": "xp", "amount": 85, "description": "Three more days!"},
	{"day": 28, "type": "xp", "amount": 90, "description": "The summit approaches."},
	{"day": 29, "type": "xp", "amount": 95, "description": "Tomorrow is special..."},
	{"day": 30, "type": "milestone", "amount": 300, "bonus": "title_dedicated", "description": "ONE MONTH! Title 'The Dedicated' earned!"},
]

# Personal milestones (major celebrations)
const PERSONAL_MILESTONES = {
	7: {"title": "Week Warrior", "message": "One week of showing up for yourself!", "xp": 100, "unlocks": "milestone_badge_week"},
	14: {"title": "Fortnight Fighter", "message": "Two weeks of consistent growth!", "xp": 150, "unlocks": "milestone_badge_fortnight"},
	30: {"title": "Monthly Master", "message": "A full month of transformation!", "xp": 300, "unlocks": "milestone_badge_month"},
	60: {"title": "Dual Moon Devotee", "message": "60 days of unwavering commitment!", "xp": 500, "unlocks": "milestone_badge_60days"},
	90: {"title": "Quarter Champion", "message": "90 days - habits are now part of you!", "xp": 750, "unlocks": "milestone_badge_quarter"},
	180: {"title": "Half-Year Hero", "message": "Six months of incredible dedication!", "xp": 1000, "unlocks": "milestone_badge_halfyear"},
	365: {"title": "Yearly Legend", "message": "One full year! You are unstoppable!", "xp": 2000, "unlocks": "milestone_badge_year", "special": "legendary_companion_form"}
}


func _ensure_login_data() -> void:
	if not player_data.has("last_login_date"):
		player_data["last_login_date"] = ""
	if not player_data.has("login_streak"):
		player_data["login_streak"] = 0
	if not player_data.has("total_login_days"):
		player_data["total_login_days"] = 0
	if not player_data.has("claimed_daily_rewards"):
		player_data["claimed_daily_rewards"] = []
	if not player_data.has("unlocked_milestones"):
		player_data["unlocked_milestones"] = []
	if not player_data.has("companion_evolution_stage"):
		player_data["companion_evolution_stage"] = 0
	if not player_data.has("companion_accessories"):
		player_data["companion_accessories"] = []


## Check and process daily login
func check_daily_login() -> Dictionary:
	_ensure_login_data()

	var today = Time.get_date_string_from_system()
	var last_login = player_data.last_login_date
	var result = {"is_new_day": false, "reward": null, "milestone": null, "streak_broken": false}

	if today == last_login:
		return result  # Already logged in today

	result.is_new_day = true

	# Check if streak continues or breaks
	if last_login != "":
		var last_date = Time.get_datetime_dict_from_datetime_string(last_login + "T00:00:00", false)
		var today_date = Time.get_datetime_dict_from_datetime_string(today + "T00:00:00", false)

		# Convert to unix timestamps for comparison
		var last_unix = Time.get_unix_time_from_datetime_dict(last_date)
		var today_unix = Time.get_unix_time_from_datetime_dict(today_date)
		var days_diff = int((today_unix - last_unix) / 86400)

		if days_diff == 1:
			# Consecutive day - continue streak
			player_data.login_streak += 1
		elif days_diff > 1:
			# Streak broken
			result.streak_broken = true
			player_data.login_streak = 1
		# days_diff == 0 handled above (same day)
	else:
		# First login ever
		player_data.login_streak = 1

	player_data.total_login_days += 1
	player_data.last_login_date = today

	# Get today's reward (cycle through rewards after 30 days)
	var reward_day = ((player_data.total_login_days - 1) % 30) + 1
	var reward = _get_daily_reward(reward_day)
	if reward:
		result.reward = reward
		daily_reward_available.emit(reward_day, reward)

	# Check for personal milestones
	var milestone = _check_milestone(player_data.total_login_days)
	if milestone:
		result.milestone = milestone

	# Update companion evolution based on total days
	_update_companion_evolution()

	SaveManager.save_game()
	return result


func _get_daily_reward(day: int) -> Dictionary:
	for reward in DAILY_REWARDS:
		if reward.day == day:
			return reward.duplicate()
	return {}


func _check_milestone(total_days: int) -> Dictionary:
	_ensure_login_data()

	if PERSONAL_MILESTONES.has(total_days):
		if total_days not in player_data.unlocked_milestones:
			var milestone = PERSONAL_MILESTONES[total_days].duplicate()
			milestone["days"] = total_days
			player_data.unlocked_milestones.append(total_days)
			milestone_reached.emit(milestone.title, total_days)
			return milestone
	return {}


## Claim the daily reward
func claim_daily_reward(day: int) -> bool:
	_ensure_login_data()

	if day in player_data.claimed_daily_rewards:
		return false  # Already claimed

	var reward = _get_daily_reward(day)
	if reward.is_empty():
		return false

	# Grant XP
	if reward.has("amount"):
		add_aspect_experience("all", reward.amount)

	# Handle special bonuses
	if reward.has("bonus"):
		match reward.bonus:
			"lore_fragment":
				if not player_data.has("unlocked_lore"):
					player_data["unlocked_lore"] = []
				player_data.unlocked_lore.append("daily_lore_" + str(day))
			"cosmetic_color":
				if not player_data.has("unlocked_colors"):
					player_data["unlocked_colors"] = []
				player_data.unlocked_colors.append("streak_gold")
			"companion_accessory":
				player_data.companion_accessories.append("star_trail")
			"title_dedicated":
				if not player_data.has("unlocked_titles"):
					player_data["unlocked_titles"] = []
				player_data.unlocked_titles.append("The Dedicated")

	player_data.claimed_daily_rewards.append(day)
	daily_reward_claimed.emit(day, reward)
	SaveManager.save_game()
	return true


# ============================================
# COMPANION EVOLUTION SYSTEM
# ============================================

signal companion_evolved(new_stage: int, stage_name: String)

const COMPANION_STAGES = {
	0: {"name": "Spark", "description": "A tiny glowing orb, curious about you.", "unlock_days": 0},
	1: {"name": "Ember", "description": "Growing brighter with your dedication.", "unlock_days": 7},
	2: {"name": "Flame", "description": "A warm presence that follows you loyally.", "unlock_days": 14},
	3: {"name": "Blaze", "description": "Radiating encouragement and wisdom.", "unlock_days": 30},
	4: {"name": "Nova", "description": "A brilliant companion reflecting your growth.", "unlock_days": 60},
	5: {"name": "Celestial", "description": "A magnificent spirit of pure potential.", "unlock_days": 90},
	6: {"name": "Eternal", "description": "An ancient form, achieved by true dedication.", "unlock_days": 180},
	7: {"name": "Legendary", "description": "The ultimate evolution - you are one.", "unlock_days": 365}
}


func _update_companion_evolution() -> void:
	_ensure_login_data()

	var total_days = player_data.total_login_days
	var current_stage = player_data.companion_evolution_stage

	# Find the highest stage unlocked
	var new_stage = 0
	for stage_num in COMPANION_STAGES:
		if total_days >= COMPANION_STAGES[stage_num].unlock_days:
			new_stage = max(new_stage, stage_num)

	if new_stage > current_stage:
		player_data.companion_evolution_stage = new_stage
		var stage_info = COMPANION_STAGES[new_stage]
		companion_evolved.emit(new_stage, stage_info.name)


func get_companion_stage() -> int:
	_ensure_login_data()
	return player_data.companion_evolution_stage


func get_companion_info() -> Dictionary:
	_ensure_login_data()
	var stage = player_data.companion_evolution_stage
	if COMPANION_STAGES.has(stage):
		var info = COMPANION_STAGES[stage].duplicate()
		info["stage"] = stage
		info["accessories"] = player_data.companion_accessories.duplicate()
		return info
	return {"stage": 0, "name": "Spark", "description": "A tiny glowing orb.", "accessories": []}


func get_next_companion_evolution() -> Dictionary:
	_ensure_login_data()
	var current_stage = player_data.companion_evolution_stage
	var next_stage = current_stage + 1

	if COMPANION_STAGES.has(next_stage):
		var info = COMPANION_STAGES[next_stage].duplicate()
		info["stage"] = next_stage
		info["days_remaining"] = max(0, info.unlock_days - player_data.total_login_days)
		return info
	return {}  # Max stage reached


func get_login_stats() -> Dictionary:
	_ensure_login_data()
	return {
		"total_days": player_data.total_login_days,
		"current_streak": player_data.login_streak,
		"last_login": player_data.last_login_date,
		"milestones_unlocked": player_data.unlocked_milestones.size(),
		"companion_stage": player_data.companion_evolution_stage
	}
