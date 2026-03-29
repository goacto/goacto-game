extends Node
## CampaignManager - Handles story progression, unlocks, and trophies
## "Human Potential" - A Game Within A Game

signal chapter_completed(chapter_id: String)
signal chapter_unlocked(chapter_id: String)
signal trophy_earned(trophy: Dictionary)
signal room_unlocked(room_id: String)
signal aspect_awakened(aspect_id: String)
signal cutscene_requested(cutscene_id: String)
signal bedroom_item_unlocked(item_id: String)

# ============ ENUMS ============

enum RoomID {
	FOCUS_CHAMBER,
	DAILY_RITUALS,
	REFLECTION_POOL,
	GOAL_COMPASS,
	TRAINING_ARENA,
	ASPECT_SHRINE,
	SCRIPT_LAB
}

enum TrophyTier {
	BRONZE,
	SILVER,
	GOLD,
	PLATINUM
}

# ============ CHAPTER DEFINITIONS ============

const CHAPTERS = {
	"chapter_1": {
		"id": "chapter_1",
		"name": "First Contact",
		"act": 1,
		"description": "Discover the game and choose your human.",
		"unlock_conditions": [],  # Starts unlocked
		"completion_requirements": [
			{"type": "focus_sessions", "count": 1}
		],
		"rooms_to_unlock": ["focus_chamber"],
		"aspects_to_unlock": [],
		"trophies": ["first_contact", "chosen_one"],
		"cutscenes": ["intro", "earth_scan", "connection_established"]
	},
	"chapter_2": {
		"id": "chapter_2",
		"name": "The Mindscape Opens",
		"act": 1,
		"description": "Enter the human's mindscape and meet Discipline.",
		"unlock_conditions": [
			{"type": "chapter_complete", "chapter": "chapter_1"}
		],
		"completion_requirements": [
			{"type": "focus_sessions", "count": 3},
			{"type": "habits_created", "count": 1}
		],
		"rooms_to_unlock": ["daily_rituals"],
		"aspects_to_unlock": ["discipline"],
		"trophies": ["world_builder", "routine_architect", "discipline_awakened"],
		"cutscenes": ["mindscape_entry", "discipline_awakens"]
	},
	"chapter_3": {
		"id": "chapter_3",
		"name": "Growing Roots",
		"act": 1,
		"description": "The mindscape shows first signs of growth. Vitality awakens.",
		"unlock_conditions": [
			{"type": "chapter_complete", "chapter": "chapter_2"},
			{"type": "streak_days", "count": 3}
		],
		"completion_requirements": [
			{"type": "streak_days", "count": 5},
			{"type": "journal_entries", "count": 1},
			{"type": "focus_sessions", "count": 5}
		],
		"rooms_to_unlock": ["reflection_pool"],
		"aspects_to_unlock": ["vitality"],
		"trophies": ["rooted", "first_reflection", "vitality_awakened", "family_interest"],
		"cutscenes": ["growth_begins", "vitality_awakens", "family_dinner"]
	},
	"chapter_4": {
		"id": "chapter_4",
		"name": "The Compass Points",
		"act": 2,
		"description": "Learn the importance of direction. Wisdom awakens.",
		"unlock_conditions": [
			{"type": "chapter_complete", "chapter": "chapter_3"}
		],
		"completion_requirements": [
			{"type": "goals_created", "count": 3},
			{"type": "goals_completed", "count": 2},
			{"type": "focus_sessions", "count": 10}
		],
		"rooms_to_unlock": ["goal_compass"],
		"aspects_to_unlock": ["wisdom"],
		"trophies": ["navigator", "intentional", "wisdom_awakened", "ten_sessions"],
		"cutscenes": ["need_direction", "wisdom_awakens", "arctis_navigation"]
	},
	"chapter_5": {
		"id": "chapter_5",
		"name": "Shadows Stir",
		"act": 2,
		"description": "The inner resistance emerges. Face Doubt.",
		"unlock_conditions": [
			{"type": "chapter_complete", "chapter": "chapter_4"},
			{"type": "streak_broken", "count": 1}  # Triggered by first missed day
		],
		"completion_requirements": [
			{"type": "combat_victories", "enemy": "doubt", "count": 1},
			{"type": "streak_recovered", "count": 1},
			{"type": "focus_sessions", "count": 15}
		],
		"rooms_to_unlock": ["training_arena"],
		"aspects_to_unlock": [],
		"trophies": ["shadow_fighter", "resilient", "arena_warrior", "fifteen_sessions"],
		"cutscenes": ["darkness_stirs", "doubt_emerges", "first_battle"]
	},
	"chapter_6": {
		"id": "chapter_6",
		"name": "The Heart Opens",
		"act": 2,
		"description": "Learn self-compassion. Compassion awakens.",
		"unlock_conditions": [
			{"type": "chapter_complete", "chapter": "chapter_5"},
			{"type": "streak_days", "count": 7}
		],
		"completion_requirements": [
			{"type": "aspects_talked_to", "count": 3},
			{"type": "aspect_level", "aspect": "any", "level": 2},
			{"type": "weekly_goal_set", "count": 1}
		],
		"rooms_to_unlock": ["aspect_shrine"],
		"aspects_to_unlock": ["compassion"],
		"trophies": ["compassion_awakened", "self_kindness", "elder_wisdom", "aspect_harmony", "level_up"],
		"cutscenes": ["heart_glow", "compassion_awakens", "chronos_hologram"]
	},
	"chapter_7": {
		"id": "chapter_7",
		"name": "Fear's Domain",
		"act": 2,
		"description": "Face your greatest fear. Courage awakens.",
		"unlock_conditions": [
			{"type": "chapter_complete", "chapter": "chapter_6"},
			{"type": "focus_sessions", "count": 20}
		],
		"completion_requirements": [
			{"type": "combat_victories", "enemy": "fear", "count": 1},
			{"type": "focus_session_challenging", "count": 1},
			{"type": "aspect_level", "aspect": "discipline", "level": 2}
		],
		"rooms_to_unlock": [],
		"aspects_to_unlock": ["courage"],
		"trophies": ["courage_awakened", "fear_slayer", "brave_session", "disciplined_mind"],
		"cutscenes": ["fear_descends", "courage_awakens", "epic_battle"]
	},
	"chapter_8": {
		"id": "chapter_8",
		"name": "The Operating System",
		"act": 3,
		"description": "Learn to program yourself. Creativity awakens.",
		"unlock_conditions": [
			{"type": "chapter_complete", "chapter": "chapter_7"},
			{"type": "streak_days", "count": 14}
		],
		"completion_requirements": [
			{"type": "scripts_created", "count": 1},
			{"type": "scripts_executed", "count": 1},
			{"type": "focus_sessions", "count": 30}
		],
		"rooms_to_unlock": ["script_lab"],
		"aspects_to_unlock": ["creativity"],
		"trophies": ["system_architect", "creativity_awakened", "code_runner", "thirty_sessions"],
		"cutscenes": ["advanced_console", "creativity_awakens", "lumina_patterns"]
	},
	"chapter_9": {
		"id": "chapter_9",
		"name": "The Resistance Rises",
		"act": 3,
		"description": "All resistance forces combine. Prove your systems work.",
		"unlock_conditions": [
			{"type": "chapter_complete", "chapter": "chapter_8"}
		],
		"completion_requirements": [
			{"type": "all_resistance_defeated", "count": 1},
			{"type": "streak_days", "count": 21},
			{"type": "weekly_goals_complete", "count": 1}
		],
		"rooms_to_unlock": [],
		"aspects_to_unlock": [],
		"trophies": ["resistance_crusher", "twentyone_days", "weekly_warrior", "evolved_world"],
		"cutscenes": ["dark_council", "aspects_rally", "transformation"]
	},
	"chapter_10": {
		"id": "chapter_10",
		"name": "Certification",
		"act": 3,
		"description": "Complete your Contribution Certification.",
		"unlock_conditions": [
			{"type": "chapter_complete", "chapter": "chapter_9"},
			{"type": "all_aspects_level", "level": 3}
		],
		"completion_requirements": [
			{"type": "streak_days", "count": 30},
			{"type": "focus_sessions", "count": 50},
			{"type": "milestone_goal_complete", "count": 1}
		],
		"rooms_to_unlock": [],
		"aspects_to_unlock": [],
		"trophies": ["certified", "month_of_growth", "fifty_sessions", "milestone_master", "full_awakening"],
		"cutscenes": ["certification_ceremony", "family_gathering", "new_beginning"]
	}
}

# ============ TROPHY DEFINITIONS ============

const TROPHIES = {
	# Story Trophies (Bronze)
	"first_contact": {
		"id": "first_contact",
		"name": "First Contact",
		"description": "Begin your first focus session",
		"tier": TrophyTier.BRONZE,
		"category": "story"
	},
	"chosen_one": {
		"id": "chosen_one",
		"name": "Chosen One",
		"description": "Your human has been selected",
		"tier": TrophyTier.BRONZE,
		"category": "story"
	},
	"world_builder": {
		"id": "world_builder",
		"name": "World Builder",
		"description": "Complete 3 focus sessions",
		"tier": TrophyTier.BRONZE,
		"category": "story"
	},
	"routine_architect": {
		"id": "routine_architect",
		"name": "Routine Architect",
		"description": "Create your first habit",
		"tier": TrophyTier.BRONZE,
		"category": "story"
	},
	"discipline_awakened": {
		"id": "discipline_awakened",
		"name": "Discipline Awakened",
		"description": "Meet your first Aspect",
		"tier": TrophyTier.BRONZE,
		"category": "aspects"
	},

	# Streak Trophies (Silver)
	"rooted": {
		"id": "rooted",
		"name": "Rooted",
		"description": "Maintain a 5-day streak",
		"tier": TrophyTier.SILVER,
		"category": "streaks"
	},
	"twentyone_days": {
		"id": "twentyone_days",
		"name": "21 Days",
		"description": "Achieve habit transformation",
		"tier": TrophyTier.SILVER,
		"category": "streaks"
	},
	"month_of_growth": {
		"id": "month_of_growth",
		"name": "Month of Growth",
		"description": "30-day streak achieved",
		"tier": TrophyTier.GOLD,
		"category": "streaks"
	},

	# Focus Trophies
	"ten_sessions": {
		"id": "ten_sessions",
		"name": "Double Digits",
		"description": "Complete 10 focus sessions",
		"tier": TrophyTier.BRONZE,
		"category": "focus"
	},
	"fifteen_sessions": {
		"id": "fifteen_sessions",
		"name": "15 and Counting",
		"description": "Complete 15 focus sessions",
		"tier": TrophyTier.BRONZE,
		"category": "focus"
	},
	"thirty_sessions": {
		"id": "thirty_sessions",
		"name": "30 Sessions Strong",
		"description": "Complete 30 focus sessions",
		"tier": TrophyTier.SILVER,
		"category": "focus"
	},
	"fifty_sessions": {
		"id": "fifty_sessions",
		"name": "Half Century",
		"description": "Complete 50 focus sessions",
		"tier": TrophyTier.GOLD,
		"category": "focus"
	},

	# Aspect Trophies
	"vitality_awakened": {
		"id": "vitality_awakened",
		"name": "Vitality Awakened",
		"description": "Physical wellness aspect unlocked",
		"tier": TrophyTier.BRONZE,
		"category": "aspects"
	},
	"wisdom_awakened": {
		"id": "wisdom_awakened",
		"name": "Wisdom Awakened",
		"description": "Clarity aspect unlocked",
		"tier": TrophyTier.BRONZE,
		"category": "aspects"
	},
	"compassion_awakened": {
		"id": "compassion_awakened",
		"name": "Compassion Awakened",
		"description": "Kindness aspect unlocked",
		"tier": TrophyTier.BRONZE,
		"category": "aspects"
	},
	"courage_awakened": {
		"id": "courage_awakened",
		"name": "Courage Awakened",
		"description": "Face your fears",
		"tier": TrophyTier.BRONZE,
		"category": "aspects"
	},
	"creativity_awakened": {
		"id": "creativity_awakened",
		"name": "Creativity Awakened",
		"description": "Innovation aspect unlocked",
		"tier": TrophyTier.BRONZE,
		"category": "aspects"
	},
	"full_awakening": {
		"id": "full_awakening",
		"name": "Full Awakening",
		"description": "All Aspects at Level 3",
		"tier": TrophyTier.GOLD,
		"category": "aspects"
	},

	# Combat Trophies
	"shadow_fighter": {
		"id": "shadow_fighter",
		"name": "Shadow Fighter",
		"description": "Defeat Doubt for the first time",
		"tier": TrophyTier.BRONZE,
		"category": "combat"
	},
	"fear_slayer": {
		"id": "fear_slayer",
		"name": "Fear Slayer",
		"description": "Defeat Fear in combat",
		"tier": TrophyTier.SILVER,
		"category": "combat"
	},
	"resistance_crusher": {
		"id": "resistance_crusher",
		"name": "Resistance Crusher",
		"description": "Defeat all four Resistance types",
		"tier": TrophyTier.GOLD,
		"category": "combat"
	},

	# Milestone Trophies
	"certified": {
		"id": "certified",
		"name": "Certified",
		"description": "Complete the Contribution Certification",
		"tier": TrophyTier.PLATINUM,
		"category": "story"
	}
}

# ============ ROOM DEFINITIONS ============

const ROOMS = {
	"focus_chamber": {
		"id": "focus_chamber",
		"name": "Focus Chamber",
		"description": "Deep work happens here",
		"unlock_chapter": "chapter_1",
		"zone_node": "FocusChamber"
	},
	"daily_rituals": {
		"id": "daily_rituals",
		"name": "Daily Rituals",
		"description": "Build your habits",
		"unlock_chapter": "chapter_2",
		"zone_node": "DailyRituals"
	},
	"reflection_pool": {
		"id": "reflection_pool",
		"name": "Reflection Pool",
		"description": "Journal your journey",
		"unlock_chapter": "chapter_3",
		"zone_node": "ReflectionPool"
	},
	"goal_compass": {
		"id": "goal_compass",
		"name": "Goal Compass",
		"description": "Set your direction",
		"unlock_chapter": "chapter_4",
		"zone_node": "GoalCompass"
	},
	"training_arena": {
		"id": "training_arena",
		"name": "Training Arena",
		"description": "Face your resistance",
		"unlock_chapter": "chapter_5",
		"zone_node": "TrainingArena"
	},
	"aspect_shrine": {
		"id": "aspect_shrine",
		"name": "Aspect Shrine",
		"description": "Connect with your Aspects",
		"unlock_chapter": "chapter_6",
		"zone_node": "AspectShrine"
	},
	"script_lab": {
		"id": "script_lab",
		"name": "Script Lab",
		"description": "Program your potential",
		"unlock_chapter": "chapter_8",
		"zone_node": "ScriptLab"
	},
	# Northern Gardens (Chapter 3)
	"dream_garden": {
		"id": "dream_garden",
		"name": "Dream Garden",
		"description": "Where dreams take root",
		"unlock_chapter": "chapter_3",
		"zone_node": "DreamGarden"
	},
	"memory_archive": {
		"id": "memory_archive",
		"name": "Memory Archive",
		"description": "Review your journey",
		"unlock_chapter": "chapter_3",
		"zone_node": "MemoryArchive"
	},
	# Eastern Observatory (Chapter 5)
	"observatory": {
		"id": "observatory",
		"name": "Star Observatory",
		"description": "Visualize your future",
		"unlock_chapter": "chapter_5",
		"zone_node": "Observatory"
	},
	# Western Depths (Chapter 7)
	"shadow_work": {
		"id": "shadow_work",
		"name": "Shadow Work",
		"description": "Face your shadows",
		"unlock_chapter": "chapter_7",
		"zone_node": "ShadowWork"
	},
	# Southern Peaks (Chapter 8)
	"summit": {
		"id": "summit",
		"name": "The Summit",
		"description": "The peak of your journey",
		"unlock_chapter": "chapter_8",
		"zone_node": "Summit"
	}
}

# ============ STATE ============

var campaign_state: Dictionary = {
	"current_chapter": "chapter_1",
	"chapters_completed": [],
	"chapters_unlocked": ["chapter_1"],
	"trophies_earned": [],
	"rooms_unlocked": ["focus_chamber"],  # Focus Chamber starts unlocked
	"aspects_awakened": [],
	"cutscenes_seen": [],
	"combat_victories": {},
	"aspects_talked_to": [],
	"streaks_recovered": 0,
	"stats": {
		"total_focus_sessions": 0,
		"longest_streak": 0,
		"goals_completed": 0,
		"scripts_created": 0,
		"scripts_executed": 0
	}
}


func _ready() -> void:
	# Load saved campaign progress
	load_campaign()
	# Connect to game events to track progress
	_connect_game_signals()
	print("[CampaignManager] Initialized - Current chapter: ", campaign_state.current_chapter)


func _connect_game_signals() -> void:
	# These will be connected when the relevant managers are ready
	if GameManager:
		GameManager.aspect_leveled_up.connect(_on_aspect_leveled)
		GameManager.world_evolution_triggered.connect(_on_world_evolved)

	# Connect to habit and goal events for cutscene triggers
	if HabitManager:
		HabitManager.habit_completed.connect(_on_habit_completed)
	if GoalManager:
		GoalManager.goal_created.connect(_on_goal_created)


# ============ CHAPTER PROGRESS ============

## Check if a chapter is unlocked
func is_chapter_unlocked(chapter_id: String) -> bool:
	return chapter_id in campaign_state.chapters_unlocked


## Check if a chapter is completed
func is_chapter_completed(chapter_id: String) -> bool:
	return chapter_id in campaign_state.chapters_completed


## Get the highest completed chapter number (0 if none completed)
func get_highest_completed_chapter() -> int:
	var highest = 0
	for chapter_id in campaign_state.chapters_completed:
		if chapter_id.begins_with("chapter_"):
			var num = int(chapter_id.split("_")[1])
			if num > highest:
				highest = num
	return highest


## Get current chapter data
func get_current_chapter() -> Dictionary:
	return CHAPTERS.get(campaign_state.current_chapter, {})


## Get chapter progress as a ratio (0.0 - 1.0)
func get_chapter_progress() -> float:
	var chapter = get_current_chapter()
	if chapter.is_empty():
		return 0.0

	var requirements = chapter.get("completion_requirements", [])
	if requirements.size() == 0:
		return 1.0

	var completed = 0
	for req in requirements:
		if _check_requirement(req):
			completed += 1

	return float(completed) / float(requirements.size())


## Check if chapter completion requirements are met
func check_chapter_completion(chapter_id: String) -> bool:
	if not CHAPTERS.has(chapter_id):
		return false

	var chapter = CHAPTERS[chapter_id]
	for req in chapter.completion_requirements:
		if not _check_requirement(req):
			return false
	return true


## Complete a chapter and unlock the next
func complete_chapter(chapter_id: String) -> void:
	if chapter_id in campaign_state.chapters_completed:
		return

	var chapter = CHAPTERS.get(chapter_id, {})
	if chapter.is_empty():
		return

	# Mark complete
	campaign_state.chapters_completed.append(chapter_id)

	# Award trophies
	for trophy_id in chapter.get("trophies", []):
		award_trophy(trophy_id)

	# Unlock rooms
	for room_id in chapter.get("rooms_to_unlock", []):
		unlock_room(room_id)

	# Awaken aspects
	for aspect_id in chapter.get("aspects_to_unlock", []):
		awaken_aspect(aspect_id)

	chapter_completed.emit(chapter_id)

	# Check for next chapter unlock
	_check_chapter_unlocks()

	# Set next chapter as current
	var next_chapter = "chapter_" + str(int(chapter_id.split("_")[1]) + 1)
	if CHAPTERS.has(next_chapter) and is_chapter_unlocked(next_chapter):
		campaign_state.current_chapter = next_chapter

	# Evaluate ending when final chapter completes
	if chapter_id == "chapter_10":
		_evaluate_ending()

	_save_campaign()
	print("[CampaignManager] Chapter completed: ", chapter_id)


# =============================================================================
# MULTIPLE ENDINGS SYSTEM
# =============================================================================

signal ending_determined(ending: Dictionary)

const ENDINGS = {
	"transcendence": {
		"id": "transcendence",
		"name": "Transcendence",
		"title": "The Transcendent Agent",
		"description": "You achieved mastery across all aspects of growth. Your human didn't just improve - they transformed. The mindscape became a paradise, and your contribution echoes across galaxies.",
		"requirements": "All aspects level 5+, 90+ evolution, 100+ sessions",
		"color": Color(0.95, 0.85, 0.4),
		"tier": "legendary"
	},
	"balanced_growth": {
		"id": "balanced_growth",
		"name": "Balanced Growth",
		"title": "The Harmonious Guide",
		"description": "You helped your human find balance across all domains of life. No single aspect dominated - instead, a harmony emerged that made the whole greater than its parts.",
		"requirements": "All aspects level 3+, 50+ evolution, balanced XP",
		"color": Color(0.5, 0.85, 0.65),
		"tier": "gold"
	},
	"discipline_path": {
		"id": "discipline_path",
		"name": "The Disciplined Path",
		"title": "The Iron Will",
		"description": "Your human became a force of pure discipline. Habits were forged into unbreakable chains of consistency. What they lacked in breadth, they made up for in depth.",
		"requirements": "Discipline highest aspect, 60+ day streak",
		"color": Color(0.4, 0.6, 0.9),
		"tier": "gold"
	},
	"creative_spirit": {
		"id": "creative_spirit",
		"name": "The Creative Spirit",
		"title": "The Innovator",
		"description": "Your human's creativity blossomed beyond imagination. They didn't just follow scripts - they wrote entirely new ones. The Script Lab became their masterpiece.",
		"requirements": "Creativity highest aspect, 10+ scripts created",
		"color": Color(0.7, 0.4, 0.9),
		"tier": "gold"
	},
	"compassionate_heart": {
		"id": "compassionate_heart",
		"name": "The Compassionate Heart",
		"title": "The Empath",
		"description": "Your human's greatest growth was in their connections. Relationships flourished, kindness multiplied, and the ripple effects of their compassion touched everyone around them.",
		"requirements": "Compassion highest aspect, 10+ relationships nurtured",
		"color": Color(0.4, 0.8, 0.7),
		"tier": "gold"
	},
	"resilient_return": {
		"id": "resilient_return",
		"name": "The Resilient Return",
		"title": "The Phoenix",
		"description": "Your human fell. More than once. But every time, they got back up. Their story isn't one of perfection - it's one of perseverance. And that's the most human story of all.",
		"requirements": "Multiple streak recoveries, used grace days, came back from long breaks",
		"color": Color(0.9, 0.5, 0.3),
		"tier": "gold"
	},
	"steady_journey": {
		"id": "steady_journey",
		"name": "The Steady Journey",
		"title": "The Persistent One",
		"description": "Step by step, day by day, your human kept going. Not the fastest, not the most dramatic, but absolutely consistent. They proved that showing up is its own kind of magic.",
		"requirements": "Default ending - completed the certification",
		"color": Color(0.6, 0.65, 0.8),
		"tier": "silver"
	}
}


func _evaluate_ending() -> void:
	var ending_id = "steady_journey"  # Default

	var aspects = GameManager.player_data.get("aspects", {})
	var evolution = GameManager.player_data.get("world_evolution_level", 0.0)
	var sessions = int(GameManager.player_data.get("total_focus_sessions", 0))
	var streak = int(GameManager.player_data.get("current_streak_days", 0))
	var grace_used = int(HabitManager.grace_days_available) if HabitManager else 0

	# Calculate aspect levels
	var aspect_levels = {}
	var min_level = 999
	var max_level = 0
	var highest_aspect = ""
	for aspect_id in aspects:
		var level = int(aspects[aspect_id].get("level", 1))
		aspect_levels[aspect_id] = level
		if level < min_level:
			min_level = level
		if level > max_level:
			max_level = level
			highest_aspect = aspect_id

	var all_above_5 = min_level >= 5 and aspect_levels.size() >= 6
	var all_above_3 = min_level >= 3 and aspect_levels.size() >= 6

	# Check for Transcendence (legendary)
	if all_above_5 and evolution >= 90 and sessions >= 100:
		ending_id = "transcendence"
	# Check for Balanced Growth
	elif all_above_3 and evolution >= 50 and max_level - min_level <= 2:
		ending_id = "balanced_growth"
	# Check aspect-specific endings
	elif highest_aspect == "discipline" and streak >= 60:
		ending_id = "discipline_path"
	elif highest_aspect == "creativity":
		var scripts = ScriptManager.get_all_scripts() if ScriptManager else []
		if scripts.size() >= 10:
			ending_id = "creative_spirit"
	elif highest_aspect == "compassion":
		var relationships = RelationshipManager.get_all_relationships() if RelationshipManager else []
		if relationships.size() >= 10:
			ending_id = "compassionate_heart"
	# Resilient Return (came back from breaks, used grace days)
	elif HabitManager and HabitManager.get_total_grace_days_used() >= 3:
		ending_id = "resilient_return"

	# Store the ending
	campaign_state["ending"] = ending_id
	campaign_state["ending_evaluated"] = true
	_save_campaign()

	var ending = ENDINGS.get(ending_id, ENDINGS["steady_journey"])
	ending_determined.emit(ending)
	print("[CampaignManager] Ending determined: ", ending.name)


func get_ending() -> Dictionary:
	var ending_id = campaign_state.get("ending", "")
	if ending_id == "":
		return {}
	return ENDINGS.get(ending_id, {})


## Check all chapters for unlock conditions
func _check_chapter_unlocks() -> void:
	for chapter_id in CHAPTERS:
		if is_chapter_unlocked(chapter_id):
			continue

		var chapter = CHAPTERS[chapter_id]
		var all_conditions_met = true

		for condition in chapter.unlock_conditions:
			if not _check_unlock_condition(condition):
				all_conditions_met = false
				break

		if all_conditions_met:
			campaign_state.chapters_unlocked.append(chapter_id)
			chapter_unlocked.emit(chapter_id)
			print("[CampaignManager] Chapter unlocked: ", chapter_id)


func _check_unlock_condition(condition: Dictionary) -> bool:
	match condition.type:
		"chapter_complete":
			return is_chapter_completed(condition.chapter)
		"streak_days":
			return _get_current_streak() >= condition.count
		"focus_sessions":
			return campaign_state.stats.total_focus_sessions >= condition.count
		"streak_broken":
			return true  # This is triggered by event, not checked
		"all_aspects_level":
			return _check_all_aspects_level(condition.level)
		_:
			return false


func _check_requirement(req: Dictionary) -> bool:
	match req.type:
		"focus_sessions":
			return campaign_state.stats.total_focus_sessions >= req.count
		"habits_created":
			return HabitManager.get_all_habits().size() >= req.count
		"streak_days":
			return _get_current_streak() >= req.count
		"journal_entries":
			return _get_journal_count() >= req.count
		"goals_created":
			return GoalManager.get_all_goals().size() >= req.count
		"goals_completed":
			return campaign_state.stats.goals_completed >= req.count
		"combat_victories":
			var enemy = req.get("enemy", "any")
			return _get_combat_victories(enemy) >= req.count
		"streak_recovered":
			return campaign_state.streaks_recovered >= req.count
		"aspects_talked_to":
			return campaign_state.aspects_talked_to.size() >= req.count
		"aspect_level":
			return _check_aspect_level(req.get("aspect", "any"), req.level)
		"weekly_goal_set":
			return GoalManager.get_weekly_goals().size() >= req.count
		"scripts_created":
			return campaign_state.stats.scripts_created >= req.count
		"scripts_executed":
			return campaign_state.stats.scripts_executed >= req.count
		"all_resistance_defeated":
			return _check_all_resistance_defeated()
		"weekly_goals_complete":
			return _get_weekly_goals_completed() >= req.count
		"milestone_goal_complete":
			return _get_milestone_goals_completed() >= req.count
		_:
			return false


# ============ ROOM MANAGEMENT ============

## Check if a room is unlocked
func is_room_unlocked(room_id: String) -> bool:
	return room_id in campaign_state.rooms_unlocked


## Unlock a room
func unlock_room(room_id: String) -> void:
	if room_id in campaign_state.rooms_unlocked:
		return

	campaign_state.rooms_unlocked.append(room_id)
	room_unlocked.emit(room_id)
	_save_campaign()
	print("[CampaignManager] Room unlocked: ", room_id)


## Get room data
func get_room(room_id: String) -> Dictionary:
	return ROOMS.get(room_id, {})


## Get all unlocked rooms
func get_unlocked_rooms() -> Array:
	var result = []
	for room_id in campaign_state.rooms_unlocked:
		if ROOMS.has(room_id):
			result.append(ROOMS[room_id])
	return result


## Get all locked rooms
func get_locked_rooms() -> Array:
	var result = []
	for room_id in ROOMS:
		if room_id not in campaign_state.rooms_unlocked:
			result.append(ROOMS[room_id])
	return result


# ============ ASPECT MANAGEMENT ============

## Check if an aspect is awakened
func is_aspect_awakened(aspect_id: String) -> bool:
	return aspect_id in campaign_state.aspects_awakened


## Awaken an aspect
func awaken_aspect(aspect_id: String) -> void:
	if aspect_id in campaign_state.aspects_awakened:
		return

	campaign_state.aspects_awakened.append(aspect_id)
	aspect_awakened.emit(aspect_id)
	_save_campaign()
	print("[CampaignManager] Aspect awakened: ", aspect_id)


# ============ TROPHY MANAGEMENT ============

## Check if a trophy is earned
func has_trophy(trophy_id: String) -> bool:
	return trophy_id in campaign_state.trophies_earned


## Award a trophy
func award_trophy(trophy_id: String) -> void:
	if trophy_id in campaign_state.trophies_earned:
		return

	if not TROPHIES.has(trophy_id):
		return

	campaign_state.trophies_earned.append(trophy_id)
	trophy_earned.emit(TROPHIES[trophy_id])
	_save_campaign()
	print("[CampaignManager] Trophy earned: ", trophy_id)


## Get trophy data
func get_trophy(trophy_id: String) -> Dictionary:
	return TROPHIES.get(trophy_id, {})


## Get all earned trophies
func get_earned_trophies() -> Array:
	var result = []
	for trophy_id in campaign_state.trophies_earned:
		if TROPHIES.has(trophy_id):
			result.append(TROPHIES[trophy_id])
	return result


# ============ CUTSCENE MANAGEMENT ============

## Mark a cutscene as seen
func mark_cutscene_seen(cutscene_id: String) -> void:
	if cutscene_id not in campaign_state.cutscenes_seen:
		campaign_state.cutscenes_seen.append(cutscene_id)
		_save_campaign()


## Check if a cutscene has been seen
func has_seen_cutscene(cutscene_id: String) -> bool:
	return cutscene_id in campaign_state.cutscenes_seen


## Request to play a cutscene
func request_cutscene(cutscene_id: String) -> void:
	cutscene_requested.emit(cutscene_id)


## Queue a cutscene to play (sets pending_cutscene in GameManager)
func queue_cutscene(cutscene_id: String) -> void:
	if has_seen_cutscene(cutscene_id):
		return
	GameManager.player_data["pending_cutscene"] = cutscene_id
	print("[CampaignManager] Queued cutscene: ", cutscene_id)


## Check and trigger milestone cutscenes based on current progress
## Call this after focus sessions, habit completions, streak updates, etc.
func check_cutscene_triggers() -> void:
	var sessions = campaign_state.stats.total_focus_sessions
	var streak = _get_current_streak()
	var habits_count = HabitManager.get_all_habits().size()
	var goals_count = GoalManager.get_all_goals().size()

	# Chapter 2: Discipline Awakens - After first habit created and 3 sessions
	if not has_seen_cutscene("discipline_awakens"):
		if habits_count >= 1 and sessions >= 3:
			queue_cutscene("discipline_awakens")
			awaken_aspect("discipline")
			return

	# Chapter 3: Growth Begins - 3 day streak
	if not has_seen_cutscene("growth_begins"):
		if has_seen_cutscene("discipline_awakens") and streak >= 3:
			queue_cutscene("growth_begins")
			return

	# Chapter 3: Vitality Awakens - 5 day streak
	if not has_seen_cutscene("vitality_awakens"):
		if has_seen_cutscene("growth_begins") and streak >= 5:
			queue_cutscene("vitality_awakens")
			awaken_aspect("vitality")
			return

	# Chapter 3: Family Dinner - After Vitality awakens + 7 sessions
	if not has_seen_cutscene("family_dinner"):
		if has_seen_cutscene("vitality_awakens") and sessions >= 7:
			queue_cutscene("family_dinner")
			return

	# Chapter 4: Need Direction - 10 sessions completed
	if not has_seen_cutscene("need_direction"):
		if has_seen_cutscene("family_dinner") and sessions >= 10:
			queue_cutscene("need_direction")
			return

	# Chapter 4: Wisdom Awakens - First goal created
	if not has_seen_cutscene("wisdom_awakens"):
		if has_seen_cutscene("need_direction") and goals_count >= 1:
			queue_cutscene("wisdom_awakens")
			awaken_aspect("wisdom")
			return

	# Chapter 4: Arctis Navigation - After Wisdom awakens + 3 goals
	if not has_seen_cutscene("arctis_navigation"):
		if has_seen_cutscene("wisdom_awakens") and goals_count >= 3:
			queue_cutscene("arctis_navigation")
			return

	# Chapter 5: Darkness Stirs - 15 sessions (building tension)
	if not has_seen_cutscene("darkness_stirs"):
		if has_seen_cutscene("arctis_navigation") and sessions >= 15:
			queue_cutscene("darkness_stirs")
			return

	# Chapter 5/7: Courage Awakens - 20 sessions
	if not has_seen_cutscene("courage_awakens"):
		if has_seen_cutscene("darkness_stirs") and sessions >= 20:
			queue_cutscene("courage_awakens")
			awaken_aspect("courage")
			return

	# Chapter 6: Creativity Awakens - 14 day streak
	if not has_seen_cutscene("creativity_awakens"):
		if has_seen_cutscene("courage_awakens") and streak >= 14:
			queue_cutscene("creativity_awakens")
			awaken_aspect("creativity")
			return

	# Chapter 7: Compassion Awakens - 21 day streak (or 25 sessions)
	if not has_seen_cutscene("compassion_awakens"):
		if has_seen_cutscene("creativity_awakens") and (streak >= 21 or sessions >= 25):
			queue_cutscene("compassion_awakens")
			awaken_aspect("compassion")
			return

	# Finale: Certification Ceremony - 30 day streak and 50 sessions
	if not has_seen_cutscene("certification_ceremony"):
		if has_seen_cutscene("compassion_awakens") and streak >= 30 and sessions >= 50:
			queue_cutscene("certification_ceremony")
			return


## Trigger cutscene for a broken streak (darkness stirs early if conditions met)
func check_streak_broken_cutscene() -> void:
	# If they've progressed past chapter 4 and haven't seen darkness_stirs
	if has_seen_cutscene("arctis_navigation") and not has_seen_cutscene("darkness_stirs"):
		queue_cutscene("darkness_stirs")


# ============ STAT TRACKING ============

## Record a completed focus session
func record_focus_session() -> void:
	campaign_state.stats.total_focus_sessions += 1
	_check_focus_trophies()
	_check_chapter_progress()
	check_cutscene_triggers()
	check_bedroom_unlocks()  # Check for bedroom item unlocks
	_save_campaign()


## Record a combat victory
func record_combat_victory(enemy_type: String) -> void:
	if not campaign_state.combat_victories.has(enemy_type):
		campaign_state.combat_victories[enemy_type] = 0
	campaign_state.combat_victories[enemy_type] += 1
	_check_combat_trophies(enemy_type)
	_check_chapter_progress()
	_save_campaign()


## Record a completed goal
func record_goal_completed() -> void:
	campaign_state.stats.goals_completed += 1
	_check_chapter_progress()
	check_cutscene_triggers()
	_save_campaign()


## Record a created script
func record_script_created() -> void:
	campaign_state.stats.scripts_created += 1
	_check_chapter_progress()
	_save_campaign()


## Record an executed script
func record_script_executed() -> void:
	campaign_state.stats.scripts_executed += 1
	_check_chapter_progress()
	_save_campaign()


## Record talking to an aspect
func record_aspect_talked(aspect_id: String) -> void:
	if aspect_id not in campaign_state.aspects_talked_to:
		campaign_state.aspects_talked_to.append(aspect_id)
		_check_chapter_progress()
		_save_campaign()


## Record a streak recovery (rebuilding after a broken streak)
func record_streak_recovered() -> void:
	campaign_state.streaks_recovered += 1
	_check_chapter_progress()
	_save_campaign()


# ============ HELPER FUNCTIONS ============

func _get_current_streak() -> int:
	var max_streak = 0
	for habit in HabitManager.get_all_habits():
		if habit.streak > max_streak:
			max_streak = habit.streak
	return max_streak


func _get_journal_count() -> int:
	var journal_path = SaveManager.get_journal_path()
	if not FileAccess.file_exists(journal_path):
		return 0
	var file = FileAccess.open(journal_path, FileAccess.READ)
	if not file:
		return 0
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return 0
	var data = json.get_data()
	return data.size() if data is Array else 0


func _get_combat_victories(enemy_type: String) -> int:
	if enemy_type == "any":
		var total = 0
		for count in campaign_state.combat_victories.values():
			total += count
		return total
	return campaign_state.combat_victories.get(enemy_type, 0)


func _check_aspect_level(aspect_id: String, level: int) -> bool:
	if aspect_id == "any":
		for aspect in GameManager.player_data.aspects.values():
			if aspect.level >= level:
				return true
		return false

	var aspect = GameManager.player_data.aspects.get(aspect_id, {})
	return aspect.get("level", 0) >= level


func _check_all_aspects_level(level: int) -> bool:
	for aspect in GameManager.player_data.aspects.values():
		if aspect.level < level:
			return false
	return true


func _check_all_resistance_defeated() -> bool:
	var required = ["doubt", "fear", "procrastination", "distraction"]
	for enemy in required:
		if _get_combat_victories(enemy) < 1:
			return false
	return true


func _get_milestone_goals_completed() -> int:
	var count = 0
	for goal in GoalManager.get_milestone_goals():
		if goal.status == GoalManager.GoalStatus.COMPLETED:
			count += 1
	return count


func _get_weekly_goals_completed() -> int:
	var count = 0
	for goal in GoalManager.get_completed_goals(100):
		if goal.timeframe == GoalManager.GoalTimeframe.WEEKLY:
			count += 1
	return count


func _check_focus_trophies() -> void:
	var sessions = campaign_state.stats.total_focus_sessions
	if sessions >= 10:
		award_trophy("ten_sessions")
	if sessions >= 15:
		award_trophy("fifteen_sessions")
	if sessions >= 30:
		award_trophy("thirty_sessions")
	if sessions >= 50:
		award_trophy("fifty_sessions")


func _check_combat_trophies(enemy_type: String) -> void:
	match enemy_type:
		"doubt":
			if _get_combat_victories("doubt") >= 1:
				award_trophy("shadow_fighter")
		"fear":
			if _get_combat_victories("fear") >= 1:
				award_trophy("fear_slayer")

	if _check_all_resistance_defeated():
		award_trophy("resistance_crusher")


func _check_chapter_progress() -> void:
	var current = campaign_state.current_chapter
	if check_chapter_completion(current):
		complete_chapter(current)


# ============ SIGNAL HANDLERS ============

func _on_aspect_leveled(aspect_name: String, new_level: int) -> void:
	_check_chapter_progress()
	# Trigger awakening ceremony for significant levels
	if new_level in [2, 3, 5, 7, 10]:
		_show_aspect_awakening_ceremony(aspect_name, new_level)
		# Record bond increase on awakening
		if GameManager:
			var aspect_id = aspect_name.to_lower()
			GameManager.record_aspect_interaction(aspect_id, "awakening")


func _on_world_evolved(_amount: float) -> void:
	_check_chapter_progress()


func _on_habit_completed(_habit_id: String, _habit: Dictionary) -> void:
	# Check cutscene triggers after habit completion (streak updates)
	check_cutscene_triggers()
	# Check bedroom unlocks (mirror unlocks at 3-day streak)
	check_bedroom_unlocks()


func _on_goal_created(_goal: Dictionary) -> void:
	# Check cutscene triggers when a goal is created
	check_cutscene_triggers()


# ============ ASPECT AWAKENING CEREMONIES ============

const ASPECT_AWAKENING_SPEECHES = {
	"Discipline": {
		2: "The foundations strengthen. Each day you choose consistency, your Discipline grows deeper roots.",
		3: "Mastery emerges not from perfection, but from returning to the practice again and again.",
		5: "You have learned the secret: small actions, repeated with intention, build mountains.",
		7: "Your commitment speaks louder than words. Discipline has become part of who you are.",
		10: "Awakened Discipline stands within you—unshakeable, steady, a pillar of your growth."
	},
	"Courage": {
		2: "Fear still whispers, but you've learned to walk forward anyway. This is true Courage.",
		3: "Every challenge faced makes the next one smaller. Your bravery compounds.",
		5: "You no longer wait for fear to leave—you invite it along for the journey.",
		7: "The bold path is now your natural way. Courage has become instinct.",
		10: "Awakened Courage blazes within you—fearless not because danger is absent, but because you are greater."
	},
	"Creativity": {
		2: "Ideas flow more freely now. Your mind has learned to play without judgment.",
		3: "You see connections others miss. The world reveals its hidden patterns to the creative eye.",
		5: "Creation has become as natural as breathing. Every moment holds possibility.",
		7: "Your imagination shapes reality. What you envision, you can manifest.",
		10: "Awakened Creativity dances within you—infinite, playful, the spark of new worlds."
	},
	"Compassion": {
		2: "Your heart expands. In seeing others' struggles, you've found unexpected strength.",
		3: "Kindness given freely returns multiplied. You understand this truth now.",
		5: "You carry others' burdens lightly because your own heart has grown vast.",
		7: "Love flows through you like water—healing, connecting, transforming.",
		10: "Awakened Compassion radiates from you—a warmth that touches all who near."
	},
	"Wisdom": {
		2: "Reflection reveals what haste obscures. You're learning to see beneath the surface.",
		3: "Patterns emerge from chaos. Your discernment sharpens with each contemplation.",
		5: "You speak less, understand more. Wisdom grows in the spaces between thoughts.",
		7: "Others seek your counsel. Your insight illuminates paths they cannot see.",
		10: "Awakened Wisdom glows within you—ancient knowing meeting present awareness."
	},
	"Vitality": {
		2: "Your body remembers its power. Energy flows where attention goes.",
		3: "Rest and action find their balance. You honor the rhythms of your physical being.",
		5: "Health is not a destination but a practice. You've made it your way of life.",
		7: "Your vitality inspires others. The body that was burden has become ally.",
		10: "Awakened Vitality surges through you—radiant life force, grounded and boundless."
	}
}

var ceremony_overlay: CanvasLayer = null


func _show_aspect_awakening_ceremony(aspect_name: String, new_level: int) -> void:
	# Don't show if already showing or in a cutscene
	if ceremony_overlay:
		return

	# Get aspect data from GameManager
	var aspect_color = Color(0.7, 0.5, 0.9)  # Default purple
	for aspect_key in GameManager.ASPECTS:
		if GameManager.ASPECTS[aspect_key].name == aspect_name:
			aspect_color = GameManager.ASPECTS[aspect_key].color
			break

	# Get awakening speech
	var speeches = ASPECT_AWAKENING_SPEECHES.get(aspect_name, {})
	var speech = speeches.get(new_level, "Your %s grows stronger." % aspect_name)

	# Create overlay
	ceremony_overlay = CanvasLayer.new()
	ceremony_overlay.layer = 100
	add_child(ceremony_overlay)

	# Background with fade
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.05, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	ceremony_overlay.add_child(bg)

	# Center container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	ceremony_overlay.add_child(center)

	# Main panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 350)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.15, 0.95)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.border_color = aspect_color
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.shadow_color = Color(aspect_color.r, aspect_color.g, aspect_color.b, 0.3)
	style.shadow_size = 15
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 25)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# "AWAKENING" header
	var awakening_label = Label.new()
	awakening_label.text = "✦ AWAKENING ✦"
	awakening_label.add_theme_font_size_override("font_size", 14)
	awakening_label.add_theme_color_override("font_color", aspect_color)
	awakening_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(awakening_label)

	# Aspect name and level
	var title_hbox = HBoxContainer.new()
	title_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(title_hbox)

	var aspect_label = Label.new()
	aspect_label.text = aspect_name
	aspect_label.add_theme_font_size_override("font_size", 32)
	aspect_label.add_theme_color_override("font_color", aspect_color)
	title_hbox.add_child(aspect_label)

	var level_label = Label.new()
	level_label.text = "  Level %d" % new_level
	level_label.add_theme_font_size_override("font_size", 24)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	title_hbox.add_child(level_label)

	# Decorative line
	var line = ColorRect.new()
	line.color = aspect_color
	line.custom_minimum_size = Vector2(0, 2)
	line.modulate.a = 0.5
	vbox.add_child(line)

	# Speech text
	var speech_label = Label.new()
	speech_label.text = speech
	speech_label.add_theme_font_size_override("font_size", 16)
	speech_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech_label.custom_minimum_size = Vector2(420, 0)
	vbox.add_child(speech_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Continue hint
	var hint = Label.new()
	hint.text = "[ Click or press any key to continue ]"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	# Animate in
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	panel.pivot_offset = panel.size / 2

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(bg, "color:a", 0.85, 0.4)
	tween.tween_property(panel, "modulate:a", 1.0, 0.4)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Play sound if available
	if AudioManager and AudioManager.has_method("play_aspect_awaken"):
		AudioManager.play_aspect_awaken()

	# Connect input to dismiss
	bg.gui_input.connect(_on_ceremony_input)

	# Emit signal
	aspect_awakened.emit(aspect_name.to_lower())


func _on_ceremony_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_ceremony()
	elif event is InputEventKey and event.pressed:
		_close_ceremony()


func _close_ceremony() -> void:
	if not ceremony_overlay:
		return

	var tween = create_tween()
	tween.tween_property(ceremony_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		if ceremony_overlay:
			ceremony_overlay.queue_free()
			ceremony_overlay = null
	)


# ============ PERSISTENCE ============

func _save_campaign() -> void:
	var data = {
		"campaign_state": campaign_state
	}
	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open("user://campaign_progress.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		if SaveManager:
			SaveManager.sync_web_filesystem()


func load_campaign() -> void:
	if not FileAccess.file_exists("user://campaign_progress.json"):
		return

	var file = FileAccess.open("user://campaign_progress.json", FileAccess.READ)
	if not file:
		return

	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return

	var data = json.get_data()
	if data is Dictionary and data.has("campaign_state"):
		# Merge with defaults to handle new fields
		for key in data.campaign_state:
			campaign_state[key] = data.campaign_state[key]

	print("[CampaignManager] Loaded campaign progress - Chapter: ", campaign_state.current_chapter)


## Get save data for SaveManager integration
func get_save_data() -> Dictionary:
	return campaign_state.duplicate(true)


## Load save data
func load_save_data(data: Dictionary) -> void:
	for key in data:
		campaign_state[key] = data[key]


## Reset campaign
func reset_campaign() -> void:
	campaign_state = {
		"current_chapter": "chapter_1",
		"chapters_completed": [],
		"chapters_unlocked": ["chapter_1"],
		"trophies_earned": [],
		"rooms_unlocked": ["focus_chamber"],
		"aspects_awakened": [],
		"cutscenes_seen": [],
		"combat_victories": {},
		"aspects_talked_to": [],
		"streaks_recovered": 0,
		"stats": {
			"total_focus_sessions": 0,
			"longest_streak": 0,
			"goals_completed": 0,
			"scripts_created": 0,
			"scripts_executed": 0
		}
	}
	_save_campaign()
	print("[CampaignManager] Campaign reset")


# ============ BEDROOM ITEM UNLOCKS ============
# Progressive bedroom feature unlocks based on campaign milestones

## Check and trigger bedroom item unlocks based on current progress
func check_bedroom_unlocks() -> void:
	var installed = GameManager.player_data.get("bedroom_items_installed", [])

	# Wardrobe unlocks after first focus session
	if campaign_state.stats.total_focus_sessions >= 1:
		if "wardrobe" not in installed:
			unlock_bedroom_item("wardrobe")

	# Mirror unlocks at 3-day streak
	var current_streak = _get_current_streak()
	if current_streak >= 3:
		if "mirror" not in installed:
			unlock_bedroom_item("mirror")

	# Data Archive unlocks after first journal entry
	if _get_journal_count() >= 1:
		if "data_archive" not in installed:
			unlock_bedroom_item("data_archive")


## Unlock a specific bedroom item
func unlock_bedroom_item(item_id: String) -> void:
	var installed = GameManager.player_data.get("bedroom_items_installed", [])
	if item_id in installed:
		return  # Already unlocked

	installed.append(item_id)
	GameManager.player_data["bedroom_items_installed"] = installed

	# Also set the individual unlock flags for backwards compatibility
	match item_id:
		"wardrobe":
			GameManager.player_data["closet_unlocked"] = true
			print("[CampaignManager] 🎉 Wardrobe Station unlocked!")
		"mirror":
			GameManager.player_data["mirror_unlocked"] = true
			print("[CampaignManager] 🎉 Holographic Mirror unlocked!")
		"data_archive":
			GameManager.player_data["bookshelf_unlocked"] = true
			print("[CampaignManager] 🎉 Data Archive unlocked!")
		"mindscape_console":
			GameManager.player_data["console_placed_in_bedroom"] = true
			print("[CampaignManager] 🎉 Mindscape Console unlocked!")

	bedroom_item_unlocked.emit(item_id)
	SaveManager.save_game()


## Check if a bedroom item is unlocked
func is_bedroom_item_unlocked(item_id: String) -> bool:
	var installed = GameManager.player_data.get("bedroom_items_installed", [])
	return item_id in installed
