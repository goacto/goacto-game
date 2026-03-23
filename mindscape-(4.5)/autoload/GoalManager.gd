extends Node
## GoalManager - Tracks player goals and intentions
## Handles daily, weekly, and milestone goals with Aspect integration

signal goal_created(goal: Dictionary)
signal goal_completed(goal: Dictionary)
signal goal_updated(goal: Dictionary)
signal daily_goals_reset

# Goal timeframes
enum GoalTimeframe {
	DAILY,      # Resets each day, quick intentions
	WEEKLY,     # Resets each week
	MILESTONE   # No reset, tracked until complete
}

# Goal status
enum GoalStatus {
	ACTIVE,
	COMPLETED,
	ARCHIVED
}

# All goals
var goals: Dictionary = {}  # id -> goal data

# Track reset dates
var last_daily_reset: String = ""
var last_weekly_reset: String = ""


func _ready() -> void:
	_check_resets()
	print("[GoalManager] Initialized with ", goals.size(), " goals")


## Create a new goal
func create_goal(data: Dictionary) -> String:
	var id = "goal_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)

	var goal = {
		"id": id,
		"title": data.get("title", "Untitled Goal"),
		"description": data.get("description", ""),
		"timeframe": data.get("timeframe", GoalTimeframe.DAILY),
		"status": GoalStatus.ACTIVE,
		"aspect": data.get("aspect", "discipline"),  # Which aspect this powers
		"progress": 0,
		"target_progress": data.get("target_progress", 1),  # For milestone goals
		"created_at": Time.get_unix_time_from_system(),
		"created_date": Time.get_date_string_from_system(),
		"completed_at": 0,
		"exp_reward": _calculate_exp_reward(data.get("timeframe", GoalTimeframe.DAILY)),
		"evolution_reward": _calculate_evolution_reward(data.get("timeframe", GoalTimeframe.DAILY))
	}

	goals[id] = goal
	goal_created.emit(goal)
	_save_goals()

	# Track for achievements
	if AchievementManager:
		AchievementManager.record_goal_created()

	print("[GoalManager] Created goal: ", goal.title)
	return id


## Update goal progress (for milestone goals)
func update_progress(goal_id: String, progress: int) -> void:
	if not goals.has(goal_id):
		return

	var goal = goals[goal_id]
	goal.progress = min(progress, goal.target_progress)

	goal_updated.emit(goal)

	# Auto-complete if target reached
	if goal.progress >= goal.target_progress:
		complete_goal(goal_id)
	else:
		_save_goals()


## Increment goal progress by 1
func increment_progress(goal_id: String) -> void:
	if not goals.has(goal_id):
		return

	var goal = goals[goal_id]
	update_progress(goal_id, goal.progress + 1)


## Complete a goal
func complete_goal(goal_id: String) -> void:
	if not goals.has(goal_id):
		return

	var goal = goals[goal_id]
	if goal.status == GoalStatus.COMPLETED:
		return

	goal.status = GoalStatus.COMPLETED
	goal.completed_at = Time.get_unix_time_from_system()
	goal.progress = goal.target_progress

	# Award rewards
	GameManager.add_aspect_experience(goal.aspect, goal.exp_reward)
	GameManager.evolve_world(goal.evolution_reward)

	# Track for campaign progress
	CampaignManager.record_goal_completed()

	goal_completed.emit(goal)
	_save_goals()
	SaveManager.save_game()

	print("[GoalManager] Completed goal: ", goal.title, " | +", goal.exp_reward, " XP")


## Archive a goal (remove from active without completing)
func archive_goal(goal_id: String) -> void:
	if not goals.has(goal_id):
		return

	goals[goal_id].status = GoalStatus.ARCHIVED
	_save_goals()


## Delete a goal entirely
func delete_goal(goal_id: String) -> void:
	if goals.has(goal_id):
		goals.erase(goal_id)
		_save_goals()


## Get goals by timeframe
func get_goals_by_timeframe(timeframe: GoalTimeframe) -> Array:
	var result = []
	for goal in goals.values():
		if goal.timeframe == timeframe and goal.status == GoalStatus.ACTIVE:
			result.append(goal)
	return result


## Get all active goals
func get_active_goals() -> Array:
	var result = []
	for goal in goals.values():
		if goal.status == GoalStatus.ACTIVE:
			result.append(goal)
	return result


## Get all goals (active and completed)
func get_all_goals() -> Array:
	return goals.values()


## Get completed goals (for review)
func get_completed_goals(limit: int = 20) -> Array:
	var result = []
	for goal in goals.values():
		if goal.status == GoalStatus.COMPLETED:
			result.append(goal)

	# Sort by completion date, most recent first
	result.sort_custom(func(a, b): return a.completed_at > b.completed_at)

	return result.slice(0, limit)


## Get daily goals for today
func get_todays_goals() -> Array:
	return get_goals_by_timeframe(GoalTimeframe.DAILY)


## Get weekly goals
func get_weekly_goals() -> Array:
	return get_goals_by_timeframe(GoalTimeframe.WEEKLY)


## Get milestone goals
func get_milestone_goals() -> Array:
	return get_goals_by_timeframe(GoalTimeframe.MILESTONE)


## Check completion percentage for today's goals
func get_daily_completion_percentage() -> float:
	var daily = get_todays_goals()
	if daily.is_empty():
		return 0.0

	var completed = 0
	for goal in daily:
		if goal.status == GoalStatus.COMPLETED:
			completed += 1

	return float(completed) / float(daily.size())


## Calculate XP reward based on timeframe
func _calculate_exp_reward(timeframe: GoalTimeframe) -> int:
	match timeframe:
		GoalTimeframe.DAILY:
			return 15
		GoalTimeframe.WEEKLY:
			return 50
		GoalTimeframe.MILESTONE:
			return 100
		_:
			return 10


## Calculate evolution reward based on timeframe
func _calculate_evolution_reward(timeframe: GoalTimeframe) -> float:
	match timeframe:
		GoalTimeframe.DAILY:
			return 0.3
		GoalTimeframe.WEEKLY:
			return 1.0
		GoalTimeframe.MILESTONE:
			return 2.5
		_:
			return 0.2


## Check if daily/weekly resets are needed
func _check_resets() -> void:
	var today = Time.get_date_string_from_system()
	var week_number = _get_week_number()

	# Daily reset
	if last_daily_reset != "" and last_daily_reset != today:
		_reset_daily_goals()
	last_daily_reset = today

	# Weekly reset (simplified - just check if week changed)
	var current_week = str(week_number)
	if last_weekly_reset != "" and last_weekly_reset != current_week:
		_reset_weekly_goals()
	last_weekly_reset = current_week


## Reset daily goals (archive incomplete ones)
func _reset_daily_goals() -> void:
	for goal_id in goals.keys():
		var goal = goals[goal_id]
		if goal.timeframe == GoalTimeframe.DAILY and goal.status == GoalStatus.ACTIVE:
			goal.status = GoalStatus.ARCHIVED

	daily_goals_reset.emit()
	_save_goals()
	print("[GoalManager] Daily goals reset")


## Reset weekly goals
func _reset_weekly_goals() -> void:
	for goal_id in goals.keys():
		var goal = goals[goal_id]
		if goal.timeframe == GoalTimeframe.WEEKLY and goal.status == GoalStatus.ACTIVE:
			goal.status = GoalStatus.ARCHIVED

	_save_goals()
	print("[GoalManager] Weekly goals reset")


## Get current week number (ISO week number)
func _get_week_number() -> int:
	var datetime = Time.get_datetime_dict_from_system()
	# Calculate day of year properly
	var days_in_months = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

	# Check for leap year
	var year = datetime.year
	if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
		days_in_months[2] = 29

	var day_of_year = datetime.day
	for i in range(1, datetime.month):
		day_of_year += days_in_months[i]

	# ISO week: week 1 is the week containing Jan 4th
	# Simplified: just divide day of year by 7
	return (day_of_year - 1) / 7 + 1


## Save goals to file
func _save_goals() -> void:
	var data = {
		"goals": goals,
		"last_daily_reset": last_daily_reset,
		"last_weekly_reset": last_weekly_reset
	}

	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open("user://mindscape_goals.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()


## Load goals from file
func load_goals() -> void:
	if not FileAccess.file_exists("user://mindscape_goals.json"):
		return

	var file = FileAccess.open("user://mindscape_goals.json", FileAccess.READ)
	if not file:
		return

	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return

	var data = json.get_data()
	if data is Dictionary:
		if data.has("goals"):
			goals = data.goals
		if data.has("last_daily_reset"):
			last_daily_reset = data.last_daily_reset
		if data.has("last_weekly_reset"):
			last_weekly_reset = data.last_weekly_reset

	_check_resets()
	print("[GoalManager] Loaded ", goals.size(), " goals")


## Get save data for SaveManager integration
func get_save_data() -> Dictionary:
	return {
		"goals": goals,
		"last_daily_reset": last_daily_reset,
		"last_weekly_reset": last_weekly_reset
	}


## Load save data
func load_save_data(data: Dictionary) -> void:
	if data.has("goals"):
		goals = data.goals
	if data.has("last_daily_reset"):
		last_daily_reset = data.last_daily_reset
	if data.has("last_weekly_reset"):
		last_weekly_reset = data.last_weekly_reset
	_check_resets()


## Get aspect options for goal creation
static func get_aspect_options() -> Array:
	return [
		{"id": "discipline", "name": "Discipline", "domain": "Productivity"},
		{"id": "courage", "name": "Courage", "domain": "Growth"},
		{"id": "creativity", "name": "Creativity", "domain": "Learning"},
		{"id": "compassion", "name": "Compassion", "domain": "Social"},
		{"id": "wisdom", "name": "Wisdom", "domain": "Mindfulness"},
		{"id": "vitality", "name": "Vitality", "domain": "Health"}
	]


## Get timeframe display name
static func get_timeframe_name(timeframe: GoalTimeframe) -> String:
	match timeframe:
		GoalTimeframe.DAILY:
			return "Daily"
		GoalTimeframe.WEEKLY:
			return "Weekly"
		GoalTimeframe.MILESTONE:
			return "Milestone"
		_:
			return "Goal"


## Reset all goals
func reset_goals() -> void:
	goals.clear()
	last_daily_reset = ""
	last_weekly_reset = ""
	_save_goals()
	print("[GoalManager] Goals reset")
