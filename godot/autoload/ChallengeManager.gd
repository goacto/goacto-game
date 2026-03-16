extends Node
## ChallengeManager - Handles daily and weekly challenges
## Provides bonus objectives that reward extra XP for completion

signal challenge_completed(challenge: Dictionary)
signal challenge_progress_updated(challenge_id: String, progress: int)
signal challenges_refreshed

# Challenge types
enum ChallengeType {
	FOCUS_SESSIONS,    # Complete X focus sessions
	FOCUS_MINUTES,     # Focus for X total minutes
	HABITS_COMPLETE,   # Complete X habits
	GOALS_COMPLETE,    # Complete X goals
	COMBAT_WINS,       # Win X combat encounters
	STREAK_MAINTAIN,   # Maintain a habit streak
	ASPECT_XP          # Earn X aspect XP
}

# Challenge difficulty/rarity
enum ChallengeRarity {
	COMMON,    # Easy, smaller reward
	UNCOMMON,  # Medium difficulty
	RARE       # Hard, bigger reward
}

# Active challenges
var daily_challenges: Array = []
var weekly_challenge: Dictionary = {}

# Tracking
var last_daily_refresh: String = ""
var last_weekly_refresh: String = ""

# Challenge templates
const CHALLENGE_TEMPLATES = {
	ChallengeType.FOCUS_SESSIONS: {
		"name": "Focus Session",
		"description": "Complete {target} focus session(s)",
		"icon": "🎯",
		"targets": {"common": 1, "uncommon": 2, "rare": 3}
	},
	ChallengeType.FOCUS_MINUTES: {
		"name": "Deep Focus",
		"description": "Spend {target} minutes in focus mode",
		"icon": "⏱️",
		"targets": {"common": 25, "uncommon": 50, "rare": 75}
	},
	ChallengeType.HABITS_COMPLETE: {
		"name": "Daily Rituals",
		"description": "Complete {target} habit(s) today",
		"icon": "✅",
		"targets": {"common": 1, "uncommon": 2, "rare": 3}
	},
	ChallengeType.GOALS_COMPLETE: {
		"name": "Goal Getter",
		"description": "Complete {target} goal(s)",
		"icon": "🏆",
		"targets": {"common": 1, "uncommon": 2, "rare": 3}
	},
	ChallengeType.COMBAT_WINS: {
		"name": "Shadow Slayer",
		"description": "Win {target} combat encounter(s)",
		"icon": "⚔️",
		"targets": {"common": 1, "uncommon": 2, "rare": 3}
	},
	ChallengeType.STREAK_MAINTAIN: {
		"name": "Consistency",
		"description": "Maintain a {target}+ day streak on any habit",
		"icon": "🔥",
		"targets": {"common": 3, "uncommon": 5, "rare": 7}
	},
	ChallengeType.ASPECT_XP: {
		"name": "Growth",
		"description": "Earn {target} aspect XP",
		"icon": "✨",
		"targets": {"common": 50, "uncommon": 100, "rare": 200}
	}
}

# XP rewards by rarity
const RARITY_REWARDS = {
	ChallengeRarity.COMMON: 30,
	ChallengeRarity.UNCOMMON: 60,
	ChallengeRarity.RARE: 100
}


func _ready() -> void:
	_check_challenge_refresh()

	# Connect to game events
	if HabitManager:
		HabitManager.habit_completed.connect(_on_habit_completed)
	if GoalManager:
		GoalManager.goal_completed.connect(_on_goal_completed)

	print("[ChallengeManager] Initialized with ", daily_challenges.size(), " daily challenges")


func _check_challenge_refresh() -> void:
	var today = Time.get_date_string_from_system()
	var current_week = _get_week_string()

	# Refresh daily challenges if needed
	if last_daily_refresh != today:
		_generate_daily_challenges()
		last_daily_refresh = today

	# Refresh weekly challenge if needed
	if last_weekly_refresh != current_week:
		_generate_weekly_challenge()
		last_weekly_refresh = current_week


func _generate_daily_challenges() -> void:
	daily_challenges.clear()

	# Generate 3 daily challenges with varying rarities
	var types_used: Array = []

	# 1 common, 1 uncommon, 1 rare
	for rarity in [ChallengeRarity.COMMON, ChallengeRarity.UNCOMMON, ChallengeRarity.RARE]:
		var challenge = _create_random_challenge(rarity, types_used)
		daily_challenges.append(challenge)
		types_used.append(challenge.type)

	challenges_refreshed.emit()
	_save_challenges()
	print("[ChallengeManager] Generated ", daily_challenges.size(), " daily challenges")


func _generate_weekly_challenge() -> void:
	# Weekly challenge is always rare/epic difficulty
	weekly_challenge = _create_random_challenge(ChallengeRarity.RARE, [], true)
	weekly_challenge.is_weekly = true
	weekly_challenge.xp_reward = 200  # Bigger weekly reward

	_save_challenges()
	print("[ChallengeManager] Generated weekly challenge: ", weekly_challenge.name)


func _create_random_challenge(rarity: ChallengeRarity, exclude_types: Array, is_weekly: bool = false) -> Dictionary:
	var available_types = CHALLENGE_TEMPLATES.keys().filter(func(t): return t not in exclude_types)
	var challenge_type = available_types[randi() % available_types.size()]
	var template = CHALLENGE_TEMPLATES[challenge_type]

	var rarity_key = "common"
	match rarity:
		ChallengeRarity.UNCOMMON:
			rarity_key = "uncommon"
		ChallengeRarity.RARE:
			rarity_key = "rare"

	var target = template.targets[rarity_key]
	if is_weekly:
		target = target * 5  # Weekly targets are 5x daily

	var id = "challenge_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)

	return {
		"id": id,
		"type": challenge_type,
		"name": template.icon + " " + template.name,
		"description": template.description.replace("{target}", str(target)),
		"target": target,
		"progress": 0,
		"rarity": rarity,
		"xp_reward": RARITY_REWARDS[rarity],
		"completed": false,
		"is_weekly": is_weekly
	}


## Update challenge progress
func update_progress(challenge_type: ChallengeType, amount: int = 1) -> void:
	# Update daily challenges
	for challenge in daily_challenges:
		if challenge.type == challenge_type and not challenge.completed:
			challenge.progress = min(challenge.progress + amount, challenge.target)
			challenge_progress_updated.emit(challenge.id, challenge.progress)

			if challenge.progress >= challenge.target:
				_complete_challenge(challenge)

	# Update weekly challenge
	if weekly_challenge and weekly_challenge.type == challenge_type and not weekly_challenge.get("completed", false):
		weekly_challenge.progress = min(weekly_challenge.progress + amount, weekly_challenge.target)
		challenge_progress_updated.emit(weekly_challenge.id, weekly_challenge.progress)

		if weekly_challenge.progress >= weekly_challenge.target:
			_complete_challenge(weekly_challenge)

	_save_challenges()


func _complete_challenge(challenge: Dictionary) -> void:
	challenge.completed = true

	# Award XP to a random aspect
	var aspects = ["discipline", "courage", "creativity", "compassion", "wisdom", "vitality"]
	var random_aspect = aspects[randi() % aspects.size()]
	GameManager.add_aspect_experience(random_aspect, challenge.xp_reward)

	challenge_completed.emit(challenge)
	_save_challenges()

	print("[ChallengeManager] Challenge completed: ", challenge.name, " | +", challenge.xp_reward, " XP")


# Event handlers
func _on_habit_completed(_habit_id: String, _habit: Dictionary) -> void:
	update_progress(ChallengeType.HABITS_COMPLETE, 1)

	# Check streak challenges
	var habits = HabitManager.get_all_habits()
	var max_streak = 0
	for habit in habits:
		max_streak = max(max_streak, habit.get("streak", 0))

	if max_streak > 0:
		# Update streak challenges to current max
		for challenge in daily_challenges:
			if challenge.type == ChallengeType.STREAK_MAINTAIN and not challenge.completed:
				if max_streak >= challenge.target:
					challenge.progress = challenge.target
					_complete_challenge(challenge)


func _on_goal_completed(_goal: Dictionary) -> void:
	update_progress(ChallengeType.GOALS_COMPLETE, 1)


## Called by focus mode when a session completes
func record_focus_session(minutes: int) -> void:
	update_progress(ChallengeType.FOCUS_SESSIONS, 1)
	update_progress(ChallengeType.FOCUS_MINUTES, minutes)


## Called by combat when player wins
func record_combat_victory() -> void:
	update_progress(ChallengeType.COMBAT_WINS, 1)


## Called when aspect XP is gained
func record_aspect_xp(amount: int) -> void:
	update_progress(ChallengeType.ASPECT_XP, amount)


## Get all active daily challenges
func get_daily_challenges() -> Array:
	_check_challenge_refresh()
	return daily_challenges


## Get weekly challenge
func get_weekly_challenge() -> Dictionary:
	_check_challenge_refresh()
	return weekly_challenge


## Get completion percentage for today
func get_daily_completion_percentage() -> float:
	if daily_challenges.is_empty():
		return 0.0

	var completed = 0
	for challenge in daily_challenges:
		if challenge.completed:
			completed += 1

	return float(completed) / float(daily_challenges.size())


## Get week string for tracking
func _get_week_string() -> String:
	var date = Time.get_date_dict_from_system()
	var week_num = (date.day - 1) / 7 + 1
	return str(date.year) + "-" + str(date.month) + "-W" + str(week_num)


## Save challenges to file
func _save_challenges() -> void:
	var data = {
		"daily_challenges": daily_challenges,
		"weekly_challenge": weekly_challenge,
		"last_daily_refresh": last_daily_refresh,
		"last_weekly_refresh": last_weekly_refresh
	}

	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open("user://mindscape_challenges.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()


## Load challenges from file
func load_challenges() -> void:
	if not FileAccess.file_exists("user://mindscape_challenges.json"):
		return

	var file = FileAccess.open("user://mindscape_challenges.json", FileAccess.READ)
	if not file:
		return

	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return

	var data = json.get_data()
	if data is Dictionary:
		if data.has("daily_challenges"):
			daily_challenges = data.daily_challenges
		if data.has("weekly_challenge"):
			weekly_challenge = data.weekly_challenge
		if data.has("last_daily_refresh"):
			last_daily_refresh = data.last_daily_refresh
		if data.has("last_weekly_refresh"):
			last_weekly_refresh = data.last_weekly_refresh

	_check_challenge_refresh()
	print("[ChallengeManager] Loaded challenges")


## Get save data for SaveManager integration
func get_save_data() -> Dictionary:
	return {
		"daily_challenges": daily_challenges,
		"weekly_challenge": weekly_challenge,
		"last_daily_refresh": last_daily_refresh,
		"last_weekly_refresh": last_weekly_refresh
	}


## Load save data
func load_save_data(data: Dictionary) -> void:
	if data.has("daily_challenges"):
		daily_challenges = data.daily_challenges
	if data.has("weekly_challenge"):
		weekly_challenge = data.weekly_challenge
	if data.has("last_daily_refresh"):
		last_daily_refresh = data.last_daily_refresh
	if data.has("last_weekly_refresh"):
		last_weekly_refresh = data.last_weekly_refresh
	_check_challenge_refresh()


## Reset challenges
func reset_challenges() -> void:
	daily_challenges.clear()
	weekly_challenge = {}
	last_daily_refresh = ""
	last_weekly_refresh = ""
	_check_challenge_refresh()
	print("[ChallengeManager] Challenges reset")
