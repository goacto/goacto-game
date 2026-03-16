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
