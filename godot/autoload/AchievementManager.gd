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
		"condition": "focus_sessions >= 1"
	},
	"focus_10": {
		"id": "focus_10",
		"name": "Getting Focused",
		"description": "Complete 10 focus sessions",
		"icon": "🎯",
		"category": AchievementCategory.FOCUS,
		"condition": "focus_sessions >= 10"
	},
	"focus_50": {
		"id": "focus_50",
		"name": "Focus Master",
		"description": "Complete 50 focus sessions",
		"icon": "🏆",
		"category": AchievementCategory.FOCUS,
		"condition": "focus_sessions >= 50"
	},
	"focus_hour": {
		"id": "focus_hour",
		"name": "Hour of Power",
		"description": "Accumulate 60 minutes of focus time",
		"icon": "⏱️",
		"category": AchievementCategory.FOCUS,
		"condition": "focus_minutes >= 60"
	},
	"focus_10_hours": {
		"id": "focus_10_hours",
		"name": "Deep Worker",
		"description": "Accumulate 10 hours of focus time",
		"icon": "⏱️",
		"category": AchievementCategory.FOCUS,
		"condition": "focus_minutes >= 600"
	},

	# Habit achievements
	"first_habit": {
		"id": "first_habit",
		"name": "Building Blocks",
		"description": "Complete your first habit",
		"icon": "✅",
		"category": AchievementCategory.HABITS,
		"condition": "habits_completed >= 1"
	},
	"habits_10": {
		"id": "habits_10",
		"name": "Habit Former",
		"description": "Complete 10 habits",
		"icon": "✅",
		"category": AchievementCategory.HABITS,
		"condition": "habits_completed >= 10"
	},
	"habits_100": {
		"id": "habits_100",
		"name": "Ritual Master",
		"description": "Complete 100 habits",
		"icon": "🌟",
		"category": AchievementCategory.HABITS,
		"condition": "habits_completed >= 100"
	},
	"custom_habit": {
		"id": "custom_habit",
		"name": "Personal Touch",
		"description": "Create a custom habit",
		"icon": "✨",
		"category": AchievementCategory.HABITS,
		"condition": "custom_habits >= 1"
	},

	# Streak achievements
	"streak_3": {
		"id": "streak_3",
		"name": "On a Roll",
		"description": "Achieve a 3-day streak",
		"icon": "🔥",
		"category": AchievementCategory.STREAKS,
		"condition": "best_streak >= 3"
	},
	"streak_7": {
		"id": "streak_7",
		"name": "Week Warrior",
		"description": "Achieve a 7-day streak",
		"icon": "🔥",
		"category": AchievementCategory.STREAKS,
		"condition": "best_streak >= 7"
	},
	"streak_30": {
		"id": "streak_30",
		"name": "Monthly Champion",
		"description": "Achieve a 30-day streak",
		"icon": "🔥",
		"category": AchievementCategory.STREAKS,
		"condition": "best_streak >= 30"
	},
	"streak_100": {
		"id": "streak_100",
		"name": "Unstoppable",
		"description": "Achieve a 100-day streak",
		"icon": "💎",
		"category": AchievementCategory.STREAKS,
		"condition": "best_streak >= 100"
	},
	"grace_save": {
		"id": "grace_save",
		"name": "Second Chance",
		"description": "Use a grace day to save a streak",
		"icon": "💫",
		"category": AchievementCategory.STREAKS,
		"condition": "grace_days_used >= 1"
	},

	# Growth achievements
	"evolution_10": {
		"id": "evolution_10",
		"name": "Emerging",
		"description": "Reach 10% world evolution",
		"icon": "🌱",
		"category": AchievementCategory.GROWTH,
		"condition": "evolution >= 10"
	},
	"evolution_25": {
		"id": "evolution_25",
		"name": "Growing",
		"description": "Reach 25% world evolution",
		"icon": "🌿",
		"category": AchievementCategory.GROWTH,
		"condition": "evolution >= 25"
	},
	"evolution_50": {
		"id": "evolution_50",
		"name": "Flourishing",
		"description": "Reach 50% world evolution",
		"icon": "🌳",
		"category": AchievementCategory.GROWTH,
		"condition": "evolution >= 50"
	},
	"aspect_level_5": {
		"id": "aspect_level_5",
		"name": "Aspect Adept",
		"description": "Reach level 5 in any aspect",
		"icon": "⬆️",
		"category": AchievementCategory.GROWTH,
		"condition": "max_aspect_level >= 5"
	},

	# Exploration achievements
	"all_daily_habits": {
		"id": "all_daily_habits",
		"name": "Perfect Day",
		"description": "Complete all habits in one day",
		"icon": "⭐",
		"category": AchievementCategory.EXPLORATION,
		"condition": "perfect_days >= 1"
	},
	"first_script": {
		"id": "first_script",
		"name": "Code Writer",
		"description": "Create your first script",
		"icon": "📜",
		"category": AchievementCategory.EXPLORATION,
		"condition": "scripts_created >= 1"
	},
	"first_goal": {
		"id": "first_goal",
		"name": "Goal Setter",
		"description": "Create your first goal",
		"icon": "🎯",
		"category": AchievementCategory.EXPLORATION,
		"condition": "goals_created >= 1"
	},

	# Special achievements
	"early_bird": {
		"id": "early_bird",
		"name": "Early Bird",
		"description": "Complete a focus session before 7 AM",
		"icon": "🌅",
		"category": AchievementCategory.SPECIAL,
		"condition": "early_sessions >= 1"
	},
	"night_owl": {
		"id": "night_owl",
		"name": "Night Owl",
		"description": "Complete a focus session after 10 PM",
		"icon": "🌙",
		"category": AchievementCategory.SPECIAL,
		"condition": "late_sessions >= 1"
	}
}

# Unlocked achievements
var unlocked: Dictionary = {}  # achievement_id -> unlock_timestamp

# Stats for tracking (persisted)
var stats: Dictionary = {
	"focus_sessions": 0,
	"focus_minutes": 0,
	"habits_completed": 0,
	"custom_habits": 0,
	"best_streak": 0,
	"grace_days_used": 0,
	"evolution": 0,
	"max_aspect_level": 1,
	"perfect_days": 0,
	"scripts_created": 0,
	"goals_created": 0,
	"early_sessions": 0,
	"late_sessions": 0
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


func _on_aspect_leveled_up(_aspect_name: String, new_level: int) -> void:
	if new_level > stats.max_aspect_level:
		stats.max_aspect_level = new_level
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
	print("[AchievementManager] Achievement unlocked: ", achievement.name)

	achievement_unlocked.emit(achievement)
	SaveManager.save_game()


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
	stats.max_aspect_level = 1
	print("[AchievementManager] Achievements reset")
