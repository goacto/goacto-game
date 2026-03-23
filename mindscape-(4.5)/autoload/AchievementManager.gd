extends Node
## AchievementManager - Tracks and awards achievements/badges
## Provides milestone rewards for various accomplishments

signal achievement_unlocked(achievement: Dictionary)

# Achievement categories
enum AchievementCategory {
	FOCUS,
	HABITS,
	STREAKS,
	GROWTH,
	EXPLORATION,
	SPECIAL
}

# All achievements
const ACHIEVEMENTS = {
	# Focus achievements
	"first_focus": {
		"id": "first_focus",
		"name": "First Steps",
		"description": "Complete your first focus session",
		"icon": "🎯",
		"category": AchievementCategory.FOCUS,
		"xp_reward": 15,
		"condition": "focus_sessions >= 1"
	},
	"focus_10": {
		"id": "focus_10",
		"name": "Getting Focused",
		"description": "Complete 10 focus sessions",
		"icon": "🎯",
		"category": AchievementCategory.FOCUS,
		"xp_reward": 30,
		"condition": "focus_sessions >= 10"
	},
	"focus_50": {
		"id": "focus_50",
		"name": "Focus Master",
		"description": "Complete 50 focus sessions",
		"icon": "🏆",
		"category": AchievementCategory.FOCUS,
		"xp_reward": 100,
		"condition": "focus_sessions >= 50"
	},
	"focus_hour": {
		"id": "focus_hour",
		"name": "Hour of Power",
		"description": "Accumulate 60 minutes of focus time",
		"icon": "⏱️",
		"category": AchievementCategory.FOCUS,
		"xp_reward": 25,
		"condition": "focus_minutes >= 60"
	},
	"focus_10_hours": {
		"id": "focus_10_hours",
		"name": "Deep Worker",
		"description": "Accumulate 10 hours of focus time",
		"icon": "⏱️",
		"category": AchievementCategory.FOCUS,
		"xp_reward": 75,
		"condition": "focus_minutes >= 600"
	},

	# Habit achievements
	"first_habit": {
		"id": "first_habit",
		"name": "Building Blocks",
		"description": "Complete your first habit",
		"icon": "✅",
		"category": AchievementCategory.HABITS,
		"xp_reward": 10,
		"condition": "habits_completed >= 1"
	},
	"habits_10": {
		"id": "habits_10",
		"name": "Habit Former",
		"description": "Complete 10 habits",
		"icon": "✅",
		"category": AchievementCategory.HABITS,
		"xp_reward": 25,
		"condition": "habits_completed >= 10"
	},
	"habits_100": {
		"id": "habits_100",
		"name": "Ritual Master",
		"description": "Complete 100 habits",
		"icon": "🌟",
		"category": AchievementCategory.HABITS,
		"xp_reward": 75,
		"condition": "habits_completed >= 100"
	},
	"custom_habit": {
		"id": "custom_habit",
		"name": "Personal Touch",
		"description": "Create a custom habit",
		"icon": "✨",
		"category": AchievementCategory.HABITS,
		"xp_reward": 20,
		"condition": "custom_habits >= 1"
	},

	# Streak achievements
	"streak_3": {
		"id": "streak_3",
		"name": "On a Roll",
		"description": "Achieve a 3-day streak",
		"icon": "🔥",
		"category": AchievementCategory.STREAKS,
		"xp_reward": 15,
		"condition": "best_streak >= 3"
	},
	"streak_7": {
		"id": "streak_7",
		"name": "Week Warrior",
		"description": "Achieve a 7-day streak",
		"icon": "🔥",
		"category": AchievementCategory.STREAKS,
		"xp_reward": 35,
		"condition": "best_streak >= 7"
	},
	"streak_30": {
		"id": "streak_30",
		"name": "Monthly Champion",
		"description": "Achieve a 30-day streak",
		"icon": "🔥",
		"category": AchievementCategory.STREAKS,
		"xp_reward": 100,
		"condition": "best_streak >= 30"
	},
	"streak_100": {
		"id": "streak_100",
		"name": "Unstoppable",
		"description": "Achieve a 100-day streak",
		"icon": "💎",
		"category": AchievementCategory.STREAKS,
		"xp_reward": 250,
		"condition": "best_streak >= 100"
	},
	"grace_save": {
		"id": "grace_save",
		"name": "Second Chance",
		"description": "Use a grace day to save a streak",
		"icon": "💫",
		"category": AchievementCategory.STREAKS,
		"xp_reward": 10,
		"condition": "grace_days_used >= 1"
	},

	# Growth achievements
	"evolution_10": {
		"id": "evolution_10",
		"name": "Emerging",
		"description": "Reach 10% world evolution",
		"icon": "🌱",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 30,
		"condition": "evolution >= 10"
	},
	"evolution_25": {
		"id": "evolution_25",
		"name": "Growing",
		"description": "Reach 25% world evolution",
		"icon": "🌿",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 50,
		"condition": "evolution >= 25"
	},
	"evolution_50": {
		"id": "evolution_50",
		"name": "Flourishing",
		"description": "Reach 50% world evolution",
		"icon": "🌳",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 100,
		"condition": "evolution >= 50"
	},
	"aspect_level_5": {
		"id": "aspect_level_5",
		"name": "Aspect Adept",
		"description": "Reach level 5 in any aspect",
		"icon": "⬆️",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 50,
		"condition": "max_aspect_level >= 5"
	},

	# Exploration achievements
	"all_daily_habits": {
		"id": "all_daily_habits",
		"name": "Perfect Day",
		"description": "Complete all habits in one day",
		"icon": "⭐",
		"category": AchievementCategory.EXPLORATION,
		"xp_reward": 30,
		"condition": "perfect_days >= 1"
	},
	"first_script": {
		"id": "first_script",
		"name": "Code Writer",
		"description": "Create your first script",
		"icon": "📜",
		"category": AchievementCategory.EXPLORATION,
		"xp_reward": 20,
		"condition": "scripts_created >= 1"
	},
	"first_goal": {
		"id": "first_goal",
		"name": "Goal Setter",
		"description": "Create your first goal",
		"icon": "🎯",
		"category": AchievementCategory.EXPLORATION,
		"xp_reward": 15,
		"condition": "goals_created >= 1"
	},

	# Special achievements
	"early_bird": {
		"id": "early_bird",
		"name": "Early Bird",
		"description": "Complete a focus session before 7 AM",
		"icon": "🌅",
		"category": AchievementCategory.SPECIAL,
		"xp_reward": 25,
		"condition": "early_sessions >= 1"
	},
	"night_owl": {
		"id": "night_owl",
		"name": "Night Owl",
		"description": "Complete a focus session after 10 PM",
		"icon": "🌙",
		"category": AchievementCategory.SPECIAL,
		"xp_reward": 25,
		"condition": "late_sessions >= 1"
	},

	# ===== SELF-IMPROVEMENT ACHIEVEMENTS =====

	# Check-in achievements
	"first_checkin": {
		"id": "first_checkin",
		"name": "Self Aware",
		"description": "Complete your first daily check-in",
		"icon": "📊",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 15,
		"condition": "checkins_completed >= 1"
	},
	"checkin_7": {
		"id": "checkin_7",
		"name": "Weekly Reflector",
		"description": "Complete 7 daily check-ins",
		"icon": "📊",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 30,
		"condition": "checkins_completed >= 7"
	},
	"checkin_30": {
		"id": "checkin_30",
		"name": "Mindful Observer",
		"description": "Complete 30 daily check-ins",
		"icon": "📊",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 75,
		"condition": "checkins_completed >= 30"
	},

	# Relationship achievements
	"first_relationship": {
		"id": "first_relationship",
		"name": "Connection Started",
		"description": "Add your first relationship to track",
		"icon": "💕",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 15,
		"condition": "relationships_added >= 1"
	},
	"relationship_5": {
		"id": "relationship_5",
		"name": "Circle of Care",
		"description": "Track 5 relationships",
		"icon": "💕",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 30,
		"condition": "relationships_added >= 5"
	},
	"interaction_10": {
		"id": "interaction_10",
		"name": "Staying Connected",
		"description": "Log 10 relationship interactions",
		"icon": "💬",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 35,
		"condition": "interactions_logged >= 10"
	},
	"interaction_50": {
		"id": "interaction_50",
		"name": "Social Butterfly",
		"description": "Log 50 relationship interactions",
		"icon": "💬",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 100,
		"condition": "interactions_logged >= 50"
	},

	# Kindness achievements
	"first_kindness": {
		"id": "first_kindness",
		"name": "Spark of Kindness",
		"description": "Log your first act of kindness",
		"icon": "💝",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 15,
		"condition": "kindness_acts >= 1"
	},
	"kindness_10": {
		"id": "kindness_10",
		"name": "Generous Spirit",
		"description": "Log 10 acts of kindness",
		"icon": "💝",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 40,
		"condition": "kindness_acts >= 10"
	},
	"kindness_50": {
		"id": "kindness_50",
		"name": "Heart of Gold",
		"description": "Log 50 acts of kindness",
		"icon": "💖",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 100,
		"condition": "kindness_acts >= 50"
	},

	# Affirmation achievements
	"first_affirmation": {
		"id": "first_affirmation",
		"name": "Positive Voice",
		"description": "Complete your first daily affirmation",
		"icon": "✨",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 10,
		"condition": "affirmations_completed >= 1"
	},
	"affirmation_7": {
		"id": "affirmation_7",
		"name": "Self Believer",
		"description": "Complete 7 daily affirmations",
		"icon": "✨",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 25,
		"condition": "affirmations_completed >= 7"
	},
	"affirmation_30": {
		"id": "affirmation_30",
		"name": "Inner Champion",
		"description": "Complete 30 daily affirmations",
		"icon": "🌟",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 75,
		"condition": "affirmations_completed >= 30"
	},
	"custom_affirmation": {
		"id": "custom_affirmation",
		"name": "Your Own Words",
		"description": "Create a custom affirmation",
		"icon": "✍️",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 20,
		"condition": "custom_affirmations >= 1"
	},

	# Gratitude achievements
	"first_gratitude": {
		"id": "first_gratitude",
		"name": "Grateful Heart",
		"description": "Write your first gratitude entry",
		"icon": "🙏",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 10,
		"condition": "gratitude_entries >= 1"
	},
	"gratitude_10": {
		"id": "gratitude_10",
		"name": "Counting Blessings",
		"description": "Write 10 gratitude entries",
		"icon": "🙏",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 30,
		"condition": "gratitude_entries >= 10"
	},
	"gratitude_50": {
		"id": "gratitude_50",
		"name": "Abundance Mindset",
		"description": "Write 50 gratitude entries",
		"icon": "🌈",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 75,
		"condition": "gratitude_entries >= 50"
	},

	# Values achievements
	"values_defined": {
		"id": "values_defined",
		"name": "Know Thyself",
		"description": "Define your core values",
		"icon": "🧭",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 30,
		"condition": "values_defined >= 1"
	},
	"values_aligned": {
		"id": "values_aligned",
		"name": "Living Aligned",
		"description": "Complete 5 weekly values alignment checks",
		"icon": "🧭",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 50,
		"condition": "values_alignments >= 5"
	},

	# Weekly synthesis achievements
	"first_synthesis": {
		"id": "first_synthesis",
		"name": "Week in Review",
		"description": "Complete your first weekly synthesis",
		"icon": "📝",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 25,
		"condition": "syntheses_completed >= 1"
	},
	"synthesis_4": {
		"id": "synthesis_4",
		"name": "Monthly Reflector",
		"description": "Complete 4 weekly syntheses",
		"icon": "📝",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 50,
		"condition": "syntheses_completed >= 4"
	},

	# Mindscape exploration achievements
	"wisdom_creature": {
		"id": "wisdom_creature",
		"name": "Creature Friend",
		"description": "Discover your first wisdom creature in the Tide Pool",
		"icon": "🦀",
		"category": AchievementCategory.EXPLORATION,
		"xp_reward": 20,
		"condition": "creatures_discovered >= 1"
	},
	"wisdom_collector": {
		"id": "wisdom_collector",
		"name": "Wisdom Collector",
		"description": "Discover all 10 wisdom creatures",
		"icon": "🐚",
		"category": AchievementCategory.EXPLORATION,
		"xp_reward": 100,
		"condition": "creatures_discovered >= 10"
	},
	"first_seed": {
		"id": "first_seed",
		"name": "Seed Planter",
		"description": "Plant your first intention seed",
		"icon": "🌱",
		"category": AchievementCategory.EXPLORATION,
		"xp_reward": 15,
		"condition": "seeds_planted >= 1"
	},
	"gardener": {
		"id": "gardener",
		"name": "Mindscape Gardener",
		"description": "Plant 10 intention seeds",
		"icon": "🌻",
		"category": AchievementCategory.EXPLORATION,
		"xp_reward": 50,
		"condition": "seeds_planted >= 10"
	},
	"first_wish": {
		"id": "first_wish",
		"name": "Wish Maker",
		"description": "Cast your first wish at the fountain",
		"icon": "⭐",
		"category": AchievementCategory.EXPLORATION,
		"xp_reward": 15,
		"condition": "wishes_made >= 1"
	},
	"wish_fulfilled": {
		"id": "wish_fulfilled",
		"name": "Dream Realized",
		"description": "Mark a wish as fulfilled",
		"icon": "🌠",
		"category": AchievementCategory.EXPLORATION,
		"xp_reward": 50,
		"condition": "wishes_fulfilled >= 1"
	},
	"message_bottle": {
		"id": "message_bottle",
		"name": "Time Traveler",
		"description": "Send a message to your future self",
		"icon": "📜",
		"category": AchievementCategory.EXPLORATION,
		"xp_reward": 20,
		"condition": "bottles_sent >= 1"
	},
	"bottle_returned": {
		"id": "bottle_returned",
		"name": "Message Received",
		"description": "Receive a message from your past self",
		"icon": "💌",
		"category": AchievementCategory.EXPLORATION,
		"xp_reward": 35,
		"condition": "bottles_received >= 1"
	},
	"telescope_observer": {
		"id": "telescope_observer",
		"name": "Star Gazer",
		"description": "Observe a celestial object through the telescope",
		"icon": "🔭",
		"category": AchievementCategory.EXPLORATION,
		"xp_reward": 15,
		"condition": "telescope_views >= 1"
	},
	"meditation_first": {
		"id": "meditation_first",
		"name": "Inner Peace",
		"description": "Complete your first meditation session",
		"icon": "🧘",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 20,
		"condition": "meditations_completed >= 1"
	},
	"meditation_10": {
		"id": "meditation_10",
		"name": "Zen Mind",
		"description": "Complete 10 meditation sessions",
		"icon": "🧘",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 50,
		"condition": "meditations_completed >= 10"
	},

	# Aspect-specific achievements
	"discipline_10": {
		"id": "discipline_10",
		"name": "Disciplined Mind",
		"description": "Reach level 10 in Discipline",
		"icon": "⚔️",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 75,
		"condition": "discipline_level >= 10"
	},
	"wisdom_10": {
		"id": "wisdom_10",
		"name": "Wise Soul",
		"description": "Reach level 10 in Wisdom",
		"icon": "🦉",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 75,
		"condition": "wisdom_level >= 10"
	},
	"compassion_10": {
		"id": "compassion_10",
		"name": "Compassionate Heart",
		"description": "Reach level 10 in Compassion",
		"icon": "💗",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 75,
		"condition": "compassion_level >= 10"
	},
	"courage_10": {
		"id": "courage_10",
		"name": "Courageous Spirit",
		"description": "Reach level 10 in Courage",
		"icon": "🦁",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 75,
		"condition": "courage_level >= 10"
	},
	"vitality_10": {
		"id": "vitality_10",
		"name": "Vital Force",
		"description": "Reach level 10 in Vitality",
		"icon": "💪",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 75,
		"condition": "vitality_level >= 10"
	},
	"creativity_10": {
		"id": "creativity_10",
		"name": "Creative Spark",
		"description": "Reach level 10 in Creativity",
		"icon": "🎨",
		"category": AchievementCategory.GROWTH,
		"xp_reward": 75,
		"condition": "creativity_level >= 10"
	},

	# Milestone achievements
	"week_1": {
		"id": "week_1",
		"name": "One Week Journey",
		"description": "Play for one week",
		"icon": "📅",
		"category": AchievementCategory.SPECIAL,
		"xp_reward": 50,
		"condition": "days_played >= 7"
	},
	"month_1": {
		"id": "month_1",
		"name": "One Month Strong",
		"description": "Play for one month",
		"icon": "📅",
		"category": AchievementCategory.SPECIAL,
		"xp_reward": 150,
		"condition": "days_played >= 30"
	},
	"balanced_day": {
		"id": "balanced_day",
		"name": "Balanced Day",
		"description": "Complete habits in 3+ different aspect categories in one day",
		"icon": "⚖️",
		"category": AchievementCategory.SPECIAL,
		"xp_reward": 40,
		"condition": "balanced_days >= 1"
	},
	"total_xp_1000": {
		"id": "total_xp_1000",
		"name": "XP Hunter",
		"description": "Earn 1,000 total XP",
		"icon": "💠",
		"category": AchievementCategory.SPECIAL,
		"xp_reward": 50,
		"condition": "total_xp_earned >= 1000"
	},
	"total_xp_10000": {
		"id": "total_xp_10000",
		"name": "XP Master",
		"description": "Earn 10,000 total XP",
		"icon": "💎",
		"category": AchievementCategory.SPECIAL,
		"xp_reward": 200,
		"condition": "total_xp_earned >= 10000"
	}
}

# Unlocked achievements
var unlocked: Dictionary = {}  # achievement_id -> unlock_timestamp

# Stats for tracking (persisted)
var stats: Dictionary = {
	# Focus & Habits
	"focus_sessions": 0,
	"focus_minutes": 0,
	"habits_completed": 0,
	"custom_habits": 0,
	"best_streak": 0,
	"grace_days_used": 0,
	"perfect_days": 0,
	"balanced_days": 0,

	# Growth & Evolution
	"evolution": 0,
	"max_aspect_level": 1,
	"discipline_level": 1,
	"wisdom_level": 1,
	"compassion_level": 1,
	"courage_level": 1,
	"vitality_level": 1,
	"creativity_level": 1,
	"total_xp_earned": 0,

	# Scripts & Goals
	"scripts_created": 0,
	"goals_created": 0,

	# Self-improvement
	"checkins_completed": 0,
	"syntheses_completed": 0,
	"affirmations_completed": 0,
	"custom_affirmations": 0,
	"gratitude_entries": 0,
	"kindness_acts": 0,
	"values_defined": 0,
	"values_alignments": 0,

	# Relationships
	"relationships_added": 0,
	"interactions_logged": 0,

	# Mindscape exploration
	"creatures_discovered": 0,
	"seeds_planted": 0,
	"wishes_made": 0,
	"wishes_fulfilled": 0,
	"bottles_sent": 0,
	"bottles_received": 0,
	"telescope_views": 0,
	"meditations_completed": 0,

	# Time-based
	"early_sessions": 0,
	"late_sessions": 0,
	"days_played": 0,
	"first_play_date": 0
}


func _ready() -> void:
	# Connect to relevant signals
	if HabitManager:
		HabitManager.habit_completed.connect(_on_habit_completed)
		HabitManager.streak_recovered.connect(_on_streak_recovered)

	if GameManager:
		GameManager.aspect_leveled_up.connect(_on_aspect_leveled_up)
		GameManager.world_evolution_triggered.connect(_on_evolution_triggered)

	print("[AchievementManager] Initialized with ", unlocked.size(), " unlocked achievements")


func _on_habit_completed(_habit_id: String, habit: Dictionary) -> void:
	stats.habits_completed += 1

	# Check for custom habit
	if not habit.get("is_preset", true):
		stats.custom_habits += 1

	# Update best streak
	var streak = habit.get("streak", 0)
	if streak > stats.best_streak:
		stats.best_streak = streak

	# Check for perfect day
	_check_perfect_day()

	check_achievements()


func _on_streak_recovered(_habit_id: String, _grace_used: int) -> void:
	stats.grace_days_used += 1
	check_achievements()


func _on_aspect_leveled_up(aspect_name: String, new_level: int) -> void:
	if new_level > stats.max_aspect_level:
		stats.max_aspect_level = new_level

	# Track individual aspect levels
	var aspect_key = aspect_name.to_lower() + "_level"
	if stats.has(aspect_key):
		if new_level > stats[aspect_key]:
			stats[aspect_key] = new_level

	check_achievements()


func _on_evolution_triggered(_amount: float) -> void:
	stats.evolution = int(GameManager.player_data.get("world_evolution_level", 0))
	check_achievements()


func _check_perfect_day() -> void:
	var habits = HabitManager.get_all_habits()
	if habits.is_empty():
		return

	var all_done = true
	for habit in habits:
		if not HabitManager.is_completed_today(habit.id):
			all_done = false
			break

	if all_done:
		stats.perfect_days += 1


## Record a focus session completion
func record_focus_session(minutes: int) -> void:
	stats.focus_sessions += 1
	stats.focus_minutes += minutes

	# Check time of day
	var hour = Time.get_time_dict_from_system().hour
	if hour < 7:
		stats.early_sessions += 1
	elif hour >= 22:
		stats.late_sessions += 1

	check_achievements()


## Record script creation
func record_script_created() -> void:
	stats.scripts_created += 1
	check_achievements()


## Record goal creation
func record_goal_created() -> void:
	stats.goals_created += 1
	check_achievements()


## Record daily check-in
func record_checkin() -> void:
	stats.checkins_completed += 1
	_update_days_played()
	check_achievements()


## Record weekly synthesis
func record_synthesis() -> void:
	stats.syntheses_completed += 1
	check_achievements()


## Record affirmation completion
func record_affirmation(is_custom: bool = false) -> void:
	stats.affirmations_completed += 1
	if is_custom:
		stats.custom_affirmations += 1
	check_achievements()


## Record gratitude entry
func record_gratitude() -> void:
	stats.gratitude_entries += 1
	check_achievements()


## Record kindness act
func record_kindness() -> void:
	stats.kindness_acts += 1
	check_achievements()


## Record values definition
func record_values_defined() -> void:
	if stats.values_defined == 0:
		stats.values_defined = 1
		check_achievements()


## Record values alignment check
func record_values_alignment() -> void:
	stats.values_alignments += 1
	check_achievements()


## Record relationship added
func record_relationship_added() -> void:
	stats.relationships_added += 1
	check_achievements()


## Record relationship interaction
func record_interaction() -> void:
	stats.interactions_logged += 1
	check_achievements()


## Record creature discovered
func record_creature_discovered() -> void:
	stats.creatures_discovered += 1
	check_achievements()


## Record seed planted
func record_seed_planted() -> void:
	stats.seeds_planted += 1
	check_achievements()


## Record wish made
func record_wish_made() -> void:
	stats.wishes_made += 1
	check_achievements()


## Record wish fulfilled
func record_wish_fulfilled() -> void:
	stats.wishes_fulfilled += 1
	check_achievements()


## Record message bottle sent
func record_bottle_sent() -> void:
	stats.bottles_sent += 1
	check_achievements()


## Record message bottle received
func record_bottle_received() -> void:
	stats.bottles_received += 1
	check_achievements()


## Record telescope view
func record_telescope_view() -> void:
	stats.telescope_views += 1
	check_achievements()


## Record meditation completed
func record_meditation() -> void:
	stats.meditations_completed += 1
	check_achievements()


## Record XP earned (for tracking total XP)
func record_xp_earned(amount: int) -> void:
	stats.total_xp_earned += amount
	check_achievements()


## Record balanced day (3+ aspect categories in one day)
func record_balanced_day() -> void:
	stats.balanced_days += 1
	check_achievements()


## Update days played
func _update_days_played() -> void:
	if stats.first_play_date == 0:
		stats.first_play_date = Time.get_unix_time_from_system()
		stats.days_played = 1
	else:
		var seconds_since_start = Time.get_unix_time_from_system() - stats.first_play_date
		var days = int(seconds_since_start / 86400) + 1
		if days > stats.days_played:
			stats.days_played = days


## Check all achievements and unlock any that are newly earned
func check_achievements() -> void:
	for achievement_id in ACHIEVEMENTS:
		if unlocked.has(achievement_id):
			continue

		var achievement = ACHIEVEMENTS[achievement_id]
		if _evaluate_condition(achievement.condition):
			_unlock_achievement(achievement_id)


func _evaluate_condition(condition: String) -> bool:
	# Parse simple conditions like "focus_sessions >= 10"
	var parts = condition.split(" ")
	if parts.size() < 3:
		return false

	var stat_name = parts[0]
	var operator = parts[1]
	var value = int(parts[2])

	var current = stats.get(stat_name, 0)

	match operator:
		">=":
			return current >= value
		">":
			return current > value
		"==":
			return current == value
		"<=":
			return current <= value
		"<":
			return current < value

	return false


func _unlock_achievement(achievement_id: String) -> void:
	if unlocked.has(achievement_id):
		return

	unlocked[achievement_id] = Time.get_unix_time_from_system()

	var achievement = ACHIEVEMENTS[achievement_id]

	# Award XP reward
	var xp_reward = achievement.get("xp_reward", 0)
	if xp_reward > 0 and GameManager:
		# Award XP to the most relevant aspect based on category
		var aspect = _get_aspect_for_category(achievement.category)
		GameManager.add_aspect_experience(aspect, xp_reward)
		stats.total_xp_earned += xp_reward
		print("[AchievementManager] Achievement unlocked: ", achievement.name, " (+", xp_reward, " XP)")
	else:
		print("[AchievementManager] Achievement unlocked: ", achievement.name)

	# Trigger achievement audio moment for dynamic mixing
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("trigger_achievement_moment"):
		audio.trigger_achievement_moment(3.0)

	# Announce to screen reader
	var accessibility = get_node_or_null("/root/AccessibilityManager")
	if accessibility:
		accessibility.announce_achievement(achievement.name)

	achievement_unlocked.emit(achievement)
	SaveManager.save_game()


## Map achievement category to aspect for XP rewards
func _get_aspect_for_category(category: AchievementCategory) -> String:
	match category:
		AchievementCategory.FOCUS:
			return "discipline"
		AchievementCategory.HABITS:
			return "discipline"
		AchievementCategory.STREAKS:
			return "discipline"
		AchievementCategory.GROWTH:
			return "wisdom"
		AchievementCategory.EXPLORATION:
			return "courage"
		AchievementCategory.SPECIAL:
			return "creativity"
		_:
			return "discipline"


## Get all achievements (with unlock status)
func get_all_achievements() -> Array:
	var result: Array = []
	for achievement_id in ACHIEVEMENTS:
		var achievement = ACHIEVEMENTS[achievement_id].duplicate()
		achievement.unlocked = unlocked.has(achievement_id)
		if achievement.unlocked:
			achievement.unlock_time = unlocked[achievement_id]
		result.append(achievement)
	return result


## Get unlocked achievements only
func get_unlocked_achievements() -> Array:
	var result: Array = []
	for achievement_id in unlocked:
		if ACHIEVEMENTS.has(achievement_id):
			var achievement = ACHIEVEMENTS[achievement_id].duplicate()
			achievement.unlocked = true
			achievement.unlock_time = unlocked[achievement_id]
			result.append(achievement)
	return result


## Get achievements by category
func get_achievements_by_category(category: AchievementCategory) -> Array:
	var result: Array = []
	for achievement_id in ACHIEVEMENTS:
		var achievement = ACHIEVEMENTS[achievement_id]
		if achievement.category == category:
			var copy = achievement.duplicate()
			copy.unlocked = unlocked.has(achievement_id)
			result.append(copy)
	return result


## Get unlock percentage
func get_unlock_percentage() -> float:
	if ACHIEVEMENTS.size() == 0:
		return 0.0
	return float(unlocked.size()) / float(ACHIEVEMENTS.size())


## Get save data
func get_save_data() -> Dictionary:
	return {
		"unlocked": unlocked,
		"stats": stats
	}


## Load save data
func load_save_data(data: Dictionary) -> void:
	if data.has("unlocked"):
		unlocked = data.unlocked
	if data.has("stats"):
		for key in data.stats:
			stats[key] = data.stats[key]


## Reset achievements
func reset_achievements() -> void:
	unlocked.clear()
	for key in stats:
		stats[key] = 0
	# Reset level-based stats to 1
	stats.max_aspect_level = 1
	stats.discipline_level = 1
	stats.wisdom_level = 1
	stats.compassion_level = 1
	stats.courage_level = 1
	stats.vitality_level = 1
	stats.creativity_level = 1
	print("[AchievementManager] Achievements reset")


## Get recent achievements (for display in hub pedestals)
func get_recent_achievements(count: int = 3) -> Array:
	var unlocked_list = get_unlocked_achievements()

	# Sort by unlock time (newest first)
	unlocked_list.sort_custom(func(a, b):
		return a.get("unlock_time", 0) > b.get("unlock_time", 0)
	)

	return unlocked_list.slice(0, count)


## Get achievement progress for a specific achievement
func get_achievement_progress(achievement_id: String) -> Dictionary:
	if not ACHIEVEMENTS.has(achievement_id):
		return {}

	var achievement = ACHIEVEMENTS[achievement_id]
	var condition = achievement.condition

	# Parse condition
	var parts = condition.split(" ")
	if parts.size() < 3:
		return {"current": 0, "target": 0, "percentage": 0.0}

	var stat_name = parts[0]
	var target = int(parts[2])
	var current = stats.get(stat_name, 0)

	return {
		"current": current,
		"target": target,
		"percentage": minf(float(current) / float(target), 1.0) if target > 0 else 0.0,
		"completed": unlocked.has(achievement_id)
	}


## Get total achievement count
func get_achievement_count() -> Dictionary:
	return {
		"unlocked": unlocked.size(),
		"total": ACHIEVEMENTS.size(),
		"percentage": get_unlock_percentage()
	}
