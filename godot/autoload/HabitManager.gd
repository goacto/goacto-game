extends Node
## HabitManager - Tracks real-world habits
## Handles habit definitions, completion tracking, streaks, and rewards

signal habit_completed(habit_id: String, habit_data: Dictionary)
signal habit_streak_updated(habit_id: String, streak: int)
signal streak_recovered(habit_id: String, grace_days_used: int)
signal daily_reset_occurred
signal habit_reminder_triggered(habit_id: String, habit_name: String)

# Habit categories matching our design
enum HabitDomain {
	HEALTH,
	LEARNING,
	MINDFULNESS,
	SOCIAL,
	PRODUCTIVITY,
	CUSTOM
}

# Habit frequency options
enum HabitFrequency {
	DAILY,
	WEEKLY,
	CUSTOM
}

# All habits (preset + custom)
var habits: Dictionary = {}

# Today's completions
var todays_completions: Dictionary = {}

# Completion history (habit_id -> array of date strings)
var completion_history: Dictionary = {}

# Custom topics (lightweight - just name and tracking)
var topics: Dictionary = {}

# Today's topic completions
var topics_completions: Dictionary = {}

# Last check date for daily reset
var last_date: String = ""

# Grace days system - allows streak recovery
const MAX_GRACE_DAYS: int = 3  # Maximum grace days a player can have
const GRACE_DAY_RECHARGE_STREAK: int = 7  # Earn 1 grace day per 7-day streak
var grace_days_available: int = 1  # Start with 1 grace day
var pending_streak_breaks: Dictionary = {}  # habit_id -> { missed_date, streak_value }

# Available habit icons
const HABIT_ICONS: Dictionary = {
	"health": {"emoji": "💪", "label": "Health"},
	"mindfulness": {"emoji": "🧘", "label": "Mindfulness"},
	"learning": {"emoji": "📚", "label": "Learning"},
	"social": {"emoji": "💬", "label": "Social"},
	"productivity": {"emoji": "⚡", "label": "Productivity"},
	"custom": {"emoji": "⭐", "label": "Custom"},
	# Extended icons
	"exercise": {"emoji": "🏃", "label": "Exercise"},
	"meditation": {"emoji": "🕯️", "label": "Meditation"},
	"reading": {"emoji": "📖", "label": "Reading"},
	"writing": {"emoji": "✍️", "label": "Writing"},
	"water": {"emoji": "💧", "label": "Hydration"},
	"sleep": {"emoji": "😴", "label": "Sleep"},
	"nutrition": {"emoji": "🥗", "label": "Nutrition"},
	"creativity": {"emoji": "🎨", "label": "Creativity"},
	"music": {"emoji": "🎵", "label": "Music"},
	"gratitude": {"emoji": "🙏", "label": "Gratitude"},
	"nature": {"emoji": "🌿", "label": "Nature"},
	"family": {"emoji": "👨‍👩‍👧", "label": "Family"},
	"work": {"emoji": "💼", "label": "Work"},
	"finance": {"emoji": "💰", "label": "Finance"},
	"cleaning": {"emoji": "🧹", "label": "Cleaning"},
	"coding": {"emoji": "💻", "label": "Coding"},
	"language": {"emoji": "🗣️", "label": "Language"},
	"yoga": {"emoji": "🧘‍♀️", "label": "Yoga"},
	"journaling": {"emoji": "📝", "label": "Journaling"},
	"walking": {"emoji": "🚶", "label": "Walking"}
}

# User-defined tags for habits
var habit_tags: Dictionary = {}  # tag_name -> { color: Color, habit_ids: Array }

# Reminder system
var habit_reminders: Dictionary = {}  # habit_id -> { time: "HH:MM", enabled: bool, days: Array }
var reminder_check_timer: Timer = null
var triggered_reminders_today: Array = []  # Track which reminders already fired today
var last_reminder_check_minute: int = -1


func _ready() -> void:
	_initialize_preset_habits()
	_check_daily_reset()
	_setup_reminder_system()
	print("[HabitManager] Initialized with ", habits.size(), " habits")


## Initialize the starter habits for prototype
func _initialize_preset_habits() -> void:
	# Health habit
	add_habit({
		"id": "exercise",
		"name": "Move Your Body",
		"description": "Any form of physical activity - walking, stretching, workout",
		"domain": HabitDomain.HEALTH,
		"frequency": HabitFrequency.DAILY,
		"icon": "health",
		"exp_reward": 25,
		"evolution_reward": 0.5,
		"streak": 0,
		"best_streak": 0,
		"total_completions": 0,
		"is_preset": true
	})

	# Mindfulness habit
	add_habit({
		"id": "mindfulness",
		"name": "Mindful Moment",
		"description": "Meditation, deep breathing, or quiet reflection",
		"domain": HabitDomain.MINDFULNESS,
		"frequency": HabitFrequency.DAILY,
		"icon": "mindfulness",
		"exp_reward": 25,
		"evolution_reward": 0.5,
		"streak": 0,
		"best_streak": 0,
		"total_completions": 0,
		"is_preset": true
	})

	# Learning habit
	add_habit({
		"id": "learning",
		"name": "Learn Something",
		"description": "Read, study, practice a skill, or explore something new",
		"domain": HabitDomain.LEARNING,
		"frequency": HabitFrequency.DAILY,
		"icon": "learning",
		"exp_reward": 25,
		"evolution_reward": 0.5,
		"streak": 0,
		"best_streak": 0,
		"total_completions": 0,
		"is_preset": true
	})


## Add a new habit
func add_habit(habit_data: Dictionary) -> void:
	if not habit_data.has("id"):
		push_error("[HabitManager] Habit must have an id")
		return

	habits[habit_data.id] = habit_data
	todays_completions[habit_data.id] = false


## Complete a habit
func complete_habit(habit_id: String) -> Dictionary:
	if not habits.has(habit_id):
		push_error("[HabitManager] Unknown habit: ", habit_id)
		return {}

	if todays_completions.get(habit_id, false):
		print("[HabitManager] Habit already completed today: ", habit_id)
		return habits[habit_id]

	var habit = habits[habit_id]

	# Check if this habit had a pending streak break - auto-recover it
	var recovered_streak: bool = false
	if pending_streak_breaks.has(habit_id):
		var break_info = pending_streak_breaks[habit_id]
		# Completing the habit today saves the streak without using a grace day
		habit.streak = break_info.streak_value
		pending_streak_breaks.erase(habit_id)
		recovered_streak = true
		print("[HabitManager] Streak saved by completing today: ", habit.name)

	# Mark as complete
	todays_completions[habit_id] = true
	habit.total_completions += 1
	habit.streak += 1

	# Track completion in history
	var today = Time.get_date_string_from_system()
	if not completion_history.has(habit_id):
		completion_history[habit_id] = []
	if today not in completion_history[habit_id]:
		completion_history[habit_id].append(today)

	# Update best streak if current exceeds it
	if habit.streak > habit.get("best_streak", 0):
		habit.best_streak = habit.streak

	# Award grace day at streak milestones
	if habit.streak > 0 and int(habit.streak) % GRACE_DAY_RECHARGE_STREAK == 0:
		award_grace_day()
		print("[HabitManager] Milestone reached! ", habit.streak, " day streak - grace day earned!")

	# Calculate rewards (streaks multiply!)
	var streak_multiplier = 1.0 + (habit.streak * 0.1)  # 10% bonus per streak day
	var exp_earned = int(habit.exp_reward * streak_multiplier)
	var evolution_earned = habit.evolution_reward * streak_multiplier

	# Bonus XP for recovering a streak
	if recovered_streak:
		exp_earned += 10  # Clutch save bonus!

	# Apply rewards through GameManager
	var domain_name = _domain_to_string(habit.domain)
	GameManager.add_aspect_experience(domain_name, exp_earned)
	GameManager.evolve_world(evolution_earned)
	GameManager.player_data.total_habits_completed += 1

	# Emit signal
	habit_completed.emit(habit_id, habit)
	habit_streak_updated.emit(habit_id, habit.streak)

	# Track for aspect quests
	var is_first = habit.total_completions == 1
	GameManager.check_quests_for_trigger("habit_completed", {
		"domain": domain_name,
		"is_first_completion": is_first,
		"streak": habit.streak
	})

	# Check if all habits completed today = streak day
	if _all_habits_completed_today():
		GameManager.check_quests_for_trigger("habit_streak_day", {
			"streak": _get_consecutive_all_habits_days()
		})

	print("[HabitManager] Completed: ", habit.name, " | Streak: ", habit.streak, " | EXP: ", exp_earned)

	# Save progress
	SaveManager.save_game()

	return habit


## Check if it's a new day and reset completions
func _check_daily_reset() -> void:
	var today = Time.get_date_string_from_system()

	if last_date != "" and last_date != today:
		# New day - reset completions, check streaks
		_process_daily_reset()

	last_date = today


func _process_daily_reset() -> void:
	# Check each habit - if not completed yesterday, mark for potential recovery
	for habit_id in habits:
		if not todays_completions.get(habit_id, false):
			var habit = habits[habit_id]
			if habit.streak > 0:
				# Instead of immediately breaking, add to pending breaks for recovery
				pending_streak_breaks[habit_id] = {
					"missed_date": last_date,
					"streak_value": habit.streak,
					"habit_name": habit.name
				}
				print("[HabitManager] Streak at risk for: ", habit.name, " (", habit.streak, " days) - use grace day to recover")
				# Don't reset streak yet - give them today to recover

	# Reset today's completions
	for habit_id in todays_completions:
		todays_completions[habit_id] = false

	# Check topics - if not completed yesterday, break streak (no grace for topics)
	for topic_id in topics:
		if not topics_completions.get(topic_id, false):
			var topic = topics[topic_id]
			if topic.streak > 0:
				print("[HabitManager] Topic streak ended for: ", topic.name, " (was ", topic.streak, " days)")
				topic.streak = 0

	# Reset topic completions
	for topic_id in topics_completions:
		topics_completions[topic_id] = false

	# Clear old pending breaks (older than 1 day)
	_expire_old_pending_breaks()

	daily_reset_occurred.emit()
	print("[HabitManager] Daily reset complete - ", pending_streak_breaks.size(), " habits need attention")


## Expire pending streak breaks that are too old
func _expire_old_pending_breaks() -> void:
	var today = Time.get_date_string_from_system()
	var to_expire = []

	for habit_id in pending_streak_breaks:
		var break_data = pending_streak_breaks[habit_id]
		var missed_date = break_data.missed_date

		# Calculate days since miss (simple comparison)
		var missed_dict = Time.get_datetime_dict_from_datetime_string(missed_date + "T00:00:00", false)
		var today_dict = Time.get_datetime_dict_from_datetime_string(today + "T00:00:00", false)

		# If more than 1 day old, expire it
		var missed_day = missed_dict.day + missed_dict.month * 31 + missed_dict.year * 365
		var today_day = today_dict.day + today_dict.month * 31 + today_dict.year * 365

		if today_day - missed_day > 1:
			to_expire.append(habit_id)
			# Actually break the streak now
			if habits.has(habit_id):
				var habit = habits[habit_id]
				print("[HabitManager] Streak expired for: ", habit.name, " (was ", habit.streak, " days)")
				habit.streak = 0

	for habit_id in to_expire:
		pending_streak_breaks.erase(habit_id)


## Get all habits (excludes archived by default), sorted by order
func get_all_habits(include_archived: bool = false) -> Array:
	var result: Array
	if include_archived:
		result = habits.values()
	else:
		result = habits.values().filter(func(h): return not h.get("archived", false))

	# Sort by order field (habits without order go last)
	result.sort_custom(func(a, b):
		var order_a = a.get("order", 999)
		var order_b = b.get("order", 999)
		return order_a < order_b
	)
	return result


## Move habit up in the order
func move_habit_up(habit_id: String) -> void:
	var sorted_habits = get_all_habits()
	var index = -1
	for i in range(sorted_habits.size()):
		if sorted_habits[i].id == habit_id:
			index = i
			break

	if index <= 0:
		return  # Already at top or not found

	# Swap order with previous habit
	var current_habit_id = sorted_habits[index].id
	var prev_habit_id = sorted_habits[index - 1].id

	var current_order = habits[current_habit_id].get("order", index)
	var prev_order = habits[prev_habit_id].get("order", index - 1)

	habits[current_habit_id]["order"] = prev_order
	habits[prev_habit_id]["order"] = current_order

	SaveManager.save_game()
	print("[HabitManager] Moved habit up: ", habits[current_habit_id].name)


## Move habit down in the order
func move_habit_down(habit_id: String) -> void:
	var sorted_habits = get_all_habits()
	var index = -1
	for i in range(sorted_habits.size()):
		if sorted_habits[i].id == habit_id:
			index = i
			break

	if index < 0 or index >= sorted_habits.size() - 1:
		return  # At bottom or not found

	# Swap order with next habit
	var current_habit_id = sorted_habits[index].id
	var next_habit_id = sorted_habits[index + 1].id

	var current_order = habits[current_habit_id].get("order", index)
	var next_order = habits[next_habit_id].get("order", index + 1)

	habits[current_habit_id]["order"] = next_order
	habits[next_habit_id]["order"] = current_order

	SaveManager.save_game()
	print("[HabitManager] Moved habit down: ", habits[current_habit_id].name)


## Move habit to a specific position (0-indexed)
func move_habit_to_position(habit_id: String, new_position: int) -> void:
	var sorted_habits = get_all_habits()
	var current_index = -1

	for i in range(sorted_habits.size()):
		if sorted_habits[i].id == habit_id:
			current_index = i
			break

	if current_index < 0:
		return  # Not found

	# Clamp new position
	new_position = clampi(new_position, 0, sorted_habits.size() - 1)

	if current_index == new_position:
		return  # No change needed

	# Remove habit from current position and insert at new position
	var habit_data = sorted_habits[current_index]
	sorted_habits.remove_at(current_index)
	sorted_habits.insert(new_position, habit_data)

	# Reassign order values
	for i in range(sorted_habits.size()):
		var h_id = sorted_habits[i].id
		habits[h_id]["order"] = i

	SaveManager.save_game()
	print("[HabitManager] Moved habit to position ", new_position, ": ", habits[habit_id].name)


## Get habit index in sorted order
func get_habit_index(habit_id: String) -> int:
	var sorted_habits = get_all_habits()
	for i in range(sorted_habits.size()):
		if sorted_habits[i].id == habit_id:
			return i
	return -1


## Get archived habits only
func get_archived_habits() -> Array:
	return habits.values().filter(func(h): return h.get("archived", false))


## Archive a habit (hide without deleting)
func archive_habit(habit_id: String) -> void:
	if habits.has(habit_id):
		habits[habit_id].archived = true
		print("[HabitManager] Archived habit: ", habits[habit_id].name)
		SaveManager.save_game()


## Unarchive a habit (restore to active)
func unarchive_habit(habit_id: String) -> void:
	if habits.has(habit_id):
		habits[habit_id].archived = false
		print("[HabitManager] Unarchived habit: ", habits[habit_id].name)
		SaveManager.save_game()


## Delete a habit permanently
func delete_habit(habit_id: String) -> void:
	if habits.has(habit_id):
		var name = habits[habit_id].name
		habits.erase(habit_id)
		todays_completions.erase(habit_id)
		completion_history.erase(habit_id)
		pending_streak_breaks.erase(habit_id)
		print("[HabitManager] Deleted habit: ", name)
		SaveManager.save_game()


## Get habits by domain
func get_habits_by_domain(domain: HabitDomain) -> Array:
	var result = []
	for habit in habits.values():
		if habit.domain == domain:
			result.append(habit)
	return result


## Check if a habit is completed today
func is_completed_today(habit_id: String) -> bool:
	return todays_completions.get(habit_id, false)


## Get completion status for last N days (array of bools, index 0 = today)
func get_recent_completions(habit_id: String, days: int = 7) -> Array:
	var result: Array = []
	var history = completion_history.get(habit_id, [])

	for i in range(days):
		var date = _get_date_n_days_ago(i)
		result.append(date in history)

	return result


## Get date string for N days ago
func _get_date_n_days_ago(days_ago: int) -> String:
	var unix_now = Time.get_unix_time_from_system()
	var unix_target = unix_now - (days_ago * 86400)  # 86400 seconds per day
	var dict = Time.get_date_dict_from_unix_time(unix_target)
	return "%04d-%02d-%02d" % [dict.year, dict.month, dict.day]


## Check if a habit has a pending streak break (needs recovery)
func has_pending_streak_break(habit_id: String) -> bool:
	return pending_streak_breaks.has(habit_id)


## Get pending streak break info for a habit
func get_pending_break_info(habit_id: String) -> Dictionary:
	return pending_streak_breaks.get(habit_id, {})


## Get all habits with pending streak breaks
func get_habits_needing_recovery() -> Array:
	var result = []
	for habit_id in pending_streak_breaks:
		if habits.has(habit_id):
			result.append({
				"habit": habits[habit_id],
				"break_info": pending_streak_breaks[habit_id]
			})
	return result


## Use a grace day to recover a streak
func use_grace_day(habit_id: String) -> bool:
	if grace_days_available <= 0:
		print("[HabitManager] No grace days available")
		return false

	if not pending_streak_breaks.has(habit_id):
		print("[HabitManager] No pending break for habit: ", habit_id)
		return false

	var break_info = pending_streak_breaks[habit_id]
	var old_streak = break_info.streak_value

	# Use the grace day
	grace_days_available -= 1
	pending_streak_breaks.erase(habit_id)

	# Restore the streak (it continues from where it was)
	if habits.has(habit_id):
		habits[habit_id].streak = old_streak
		print("[HabitManager] Grace day used! Restored streak for: ", habits[habit_id].name, " (", old_streak, " days)")

	streak_recovered.emit(habit_id, 1)
	SaveManager.save_game()
	return true


## Get available grace days
func get_grace_days() -> int:
	return grace_days_available


## Award a grace day (capped at MAX_GRACE_DAYS)
func award_grace_day() -> void:
	if grace_days_available < MAX_GRACE_DAYS:
		grace_days_available += 1
		print("[HabitManager] Grace day earned! Now have: ", grace_days_available)
		SaveManager.save_game()


## Get completion percentage for today
func get_today_completion_percentage() -> float:
	if habits.is_empty():
		return 0.0

	var completed = 0
	for habit_id in todays_completions:
		if todays_completions[habit_id]:
			completed += 1

	return float(completed) / float(habits.size())


## Convert domain enum to string for GameManager
func _domain_to_string(domain: HabitDomain) -> String:
	match domain:
		HabitDomain.HEALTH: return "health"
		HabitDomain.LEARNING: return "learning"
		HabitDomain.MINDFULNESS: return "mindfulness"
		HabitDomain.SOCIAL: return "social"
		HabitDomain.PRODUCTIVITY: return "productivity"
		_: return "all"


## Create a custom habit
func create_custom_habit(name: String, description: String, domain: HabitDomain, icon: String = "custom", tags: Array = []) -> String:
	var id = "custom_" + str(Time.get_unix_time_from_system())

	# Validate icon
	var valid_icon = icon if HABIT_ICONS.has(icon) else "custom"

	add_habit({
		"id": id,
		"name": name,
		"description": description,
		"domain": domain,
		"frequency": HabitFrequency.DAILY,
		"icon": valid_icon,
		"tags": tags,
		"exp_reward": 20,
		"evolution_reward": 0.4,
		"streak": 0,
		"best_streak": 0,
		"total_completions": 0,
		"is_preset": false
	})

	# Add habit to tag references
	for tag in tags:
		add_habit_to_tag(id, tag)

	return id


## Get available icon options
func get_available_icons() -> Dictionary:
	return HABIT_ICONS


## Get icon emoji for a habit
func get_habit_emoji(habit_id: String) -> String:
	if not habits.has(habit_id):
		return "⭐"
	var icon_key = habits[habit_id].get("icon", "custom")
	if HABIT_ICONS.has(icon_key):
		return HABIT_ICONS[icon_key].emoji
	return "⭐"


## Update habit icon
func set_habit_icon(habit_id: String, icon: String) -> void:
	if habits.has(habit_id) and HABIT_ICONS.has(icon):
		habits[habit_id].icon = icon


## Get habit tags
func get_habit_tags(habit_id: String) -> Array:
	if habits.has(habit_id):
		return habits[habit_id].get("tags", [])
	return []


## Add tag to habit
func add_tag_to_habit(habit_id: String, tag: String) -> void:
	if not habits.has(habit_id):
		return

	if not habits[habit_id].has("tags"):
		habits[habit_id]["tags"] = []

	if tag not in habits[habit_id].tags:
		habits[habit_id].tags.append(tag)
		add_habit_to_tag(habit_id, tag)


## Remove tag from habit
func remove_tag_from_habit(habit_id: String, tag: String) -> void:
	if not habits.has(habit_id):
		return

	if habits[habit_id].has("tags"):
		habits[habit_id].tags.erase(tag)

	if habit_tags.has(tag):
		habit_tags[tag].habit_ids.erase(habit_id)


## Create a new tag
func create_tag(tag_name: String, color: Color = Color(0.5, 0.5, 0.7)) -> void:
	if not habit_tags.has(tag_name):
		habit_tags[tag_name] = {
			"color": color,
			"habit_ids": []
		}


## Add habit to tag tracking
func add_habit_to_tag(habit_id: String, tag_name: String) -> void:
	if not habit_tags.has(tag_name):
		create_tag(tag_name)

	if habit_id not in habit_tags[tag_name].habit_ids:
		habit_tags[tag_name].habit_ids.append(habit_id)


## Get all tags
func get_all_tags() -> Array:
	return habit_tags.keys()


## Get habits by tag
func get_habits_by_tag(tag_name: String) -> Array:
	if not habit_tags.has(tag_name):
		return []

	var result = []
	for habit_id in habit_tags[tag_name].habit_ids:
		if habits.has(habit_id):
			result.append(habits[habit_id])
	return result


## Get tag color
func get_tag_color(tag_name: String) -> Color:
	if habit_tags.has(tag_name):
		return habit_tags[tag_name].color
	return Color(0.5, 0.5, 0.7)


## Set tag color
func set_tag_color(tag_name: String, color: Color) -> void:
	if habit_tags.has(tag_name):
		habit_tags[tag_name].color = color


## Delete a tag (removes from all habits)
func delete_tag(tag_name: String) -> void:
	if not habit_tags.has(tag_name):
		return

	# Remove tag from all habits
	for habit_id in habit_tags[tag_name].habit_ids:
		if habits.has(habit_id) and habits[habit_id].has("tags"):
			habits[habit_id].tags.erase(tag_name)

	habit_tags.erase(tag_name)


# ============ TOPICS (Lightweight focus tracking) ============

## Create a new topic for focus sessions
func create_topic(name: String) -> String:
	var id = "topic_" + str(Time.get_unix_time_from_system())

	topics[id] = {
		"id": id,
		"name": name,
		"total_sessions": 0,
		"total_minutes": 0,
		"streak": 0,
		"created_at": Time.get_unix_time_from_system()
	}
	topics_completions[id] = false

	print("[HabitManager] Created topic: ", name)
	SaveManager.save_game()
	return id


## Get all active (non-archived) topics
func get_all_topics() -> Array:
	return topics.values().filter(func(t): return not t.get("archived", false))


## Get archived topics
func get_archived_topics() -> Array:
	return topics.values().filter(func(t): return t.get("archived", false))


## Archive a topic (hide from active list, keep data)
func archive_topic(topic_id: String) -> void:
	if topics.has(topic_id):
		topics[topic_id]["archived"] = true
		print("[HabitManager] Archived topic: ", topics[topic_id].name)
		SaveManager.save_game()


## Restore an archived topic to active
func unarchive_topic(topic_id: String) -> void:
	if topics.has(topic_id):
		topics[topic_id]["archived"] = false
		print("[HabitManager] Unarchived topic: ", topics[topic_id].name)
		SaveManager.save_game()


## Get total grace days used (for resilience tracking)
func get_total_grace_days_used() -> int:
	var total = 0
	for habit in habits.values():
		total += int(habit.get("grace_days_used", 0))
	return total


## Get total focus sessions across all topics
func get_total_focus_sessions() -> int:
	var total = 0
	for topic in topics.values():
		total += topic.get("total_sessions", 0)
	return total


## Complete a topic session
func complete_topic(topic_id: String, minutes: int = 25) -> Dictionary:
	if not topics.has(topic_id):
		push_error("[HabitManager] Unknown topic: ", topic_id)
		return {}

	var topic = topics[topic_id]
	topic.total_sessions += 1
	topic.total_minutes += minutes
	topic.last_duration = minutes  # Remember last used duration

	# Track daily completion
	if not topics_completions.get(topic_id, false):
		topics_completions[topic_id] = true
		topic.streak += 1

	print("[HabitManager] Completed topic session: ", topic.name, " | Total: ", topic.total_sessions)
	SaveManager.save_game()
	return topic


## Get last focus duration for a topic (defaults to 25)
func get_topic_last_duration(topic_id: String) -> int:
	if not topics.has(topic_id):
		return 25
	return topics[topic_id].get("last_duration", 25)


## Check if topic was completed today
func is_topic_completed_today(topic_id: String) -> bool:
	return topics_completions.get(topic_id, false)


## Delete a topic
func delete_topic(topic_id: String) -> void:
	if topics.has(topic_id):
		var name = topics[topic_id].name
		topics.erase(topic_id)
		topics_completions.erase(topic_id)
		print("[HabitManager] Deleted topic: ", name)
		SaveManager.save_game()


## Get weekly stats for habits
func get_weekly_stats() -> Dictionary:
	var today = Time.get_datetime_dict_from_system()
	var stats = {
		"this_week_completions": 0,
		"last_week_completions": 0,
		"active_streaks": 0,
		"perfect_days": 0
	}

	# Calculate dates for last 14 days
	var this_week_dates: Array = []
	var last_week_dates: Array = []

	for i in range(7):
		this_week_dates.append(_get_date_n_days_ago(i))
	for i in range(7, 14):
		last_week_dates.append(_get_date_n_days_ago(i))

	# Count completions per week
	for habit_id in completion_history:
		var history = completion_history[habit_id]
		for date in history:
			if date in this_week_dates:
				stats.this_week_completions += 1
			elif date in last_week_dates:
				stats.last_week_completions += 1

	# Count active streaks (habits with streak > 0)
	for habit in habits.values():
		if habit.get("streak", 0) > 0:
			stats.active_streaks += 1

	# Count perfect days (days where all habits were completed)
	var habit_count = habits.size()
	if habit_count > 0:
		for date in this_week_dates:
			var day_completions = 0
			for habit_id in completion_history:
				if date in completion_history.get(habit_id, []):
					day_completions += 1
			if day_completions >= habit_count:
				stats.perfect_days += 1

	return stats


## Get detailed stats for a specific time period
func get_period_stats(days: int = 7) -> Dictionary:
	var dates: Array = []
	for i in range(days):
		dates.append(_get_date_n_days_ago(i))

	var active_habits = get_all_habits()
	var habit_count = active_habits.size()

	var stats = {
		"period_days": days,
		"total_possible": habit_count * days,
		"total_completed": 0,
		"completion_rate": 0.0,
		"perfect_days": 0,
		"best_day_count": 0,
		"daily_counts": [],  # Array of {date, count, total}
		"per_habit_stats": [],  # Array of {habit_id, name, completed, rate, streak, best}
	}

	# Calculate daily counts
	for date in dates:
		var day_count = 0
		for habit_id in completion_history:
			if habits.has(habit_id) and not habits[habit_id].get("archived", false):
				if date in completion_history.get(habit_id, []):
					day_count += 1

		stats.daily_counts.append({
			"date": date,
			"count": day_count,
			"total": habit_count
		})
		stats.total_completed += day_count

		if day_count >= habit_count and habit_count > 0:
			stats.perfect_days += 1
		if day_count > stats.best_day_count:
			stats.best_day_count = day_count

	# Calculate completion rate
	if stats.total_possible > 0:
		stats.completion_rate = float(stats.total_completed) / float(stats.total_possible)

	# Calculate per-habit stats
	for habit in active_habits:
		var completed_in_period = 0
		for date in dates:
			if date in completion_history.get(habit.id, []):
				completed_in_period += 1

		var habit_rate = 0.0
		if days > 0:
			habit_rate = float(completed_in_period) / float(days)

		stats.per_habit_stats.append({
			"habit_id": habit.id,
			"name": habit.get("name", "Unknown"),
			"completed": completed_in_period,
			"rate": habit_rate,
			"streak": habit.get("streak", 0),
			"best_streak": habit.get("best_streak", 0),
			"total_completions": habit.get("total_completions", 0)
		})

	return stats


## Get save data
func get_save_data() -> Dictionary:
	return {
		"habits": habits,
		"todays_completions": todays_completions,
		"completion_history": completion_history,
		"topics": topics,
		"topics_completions": topics_completions,
		"last_date": last_date,
		"grace_days_available": grace_days_available,
		"pending_streak_breaks": pending_streak_breaks
	}


## Load save data
func load_save_data(data: Dictionary) -> void:
	if data.has("habits"):
		habits = data.habits
	if data.has("todays_completions"):
		todays_completions = data.todays_completions
	if data.has("completion_history"):
		completion_history = data.completion_history
	if data.has("topics"):
		topics = data.topics
	if data.has("topics_completions"):
		topics_completions = data.topics_completions
	if data.has("last_date"):
		last_date = data.last_date
	if data.has("grace_days_available"):
		grace_days_available = data.grace_days_available
	if data.has("pending_streak_breaks"):
		pending_streak_breaks = data.pending_streak_breaks

	_check_daily_reset()

	# Reconcile habit count with GameManager
	_reconcile_habit_count()


## Get the true total habit completions by summing all habit data
func get_true_total_completions() -> int:
	var total: int = 0
	for habit in habits.values():
		total += habit.get("total_completions", 0)
	return total


## Reconcile the habit count in GameManager with actual habit data
func _reconcile_habit_count() -> void:
	var true_total = get_true_total_completions()
	var history_total = get_total_from_history()
	var stored_total = GameManager.player_data.get("total_habits_completed", 0)

	# Use the higher of the two calculated totals (in case one is incomplete)
	var best_total = maxi(true_total, history_total)

	if best_total != stored_total:
		print("[HabitManager] Reconciling habit count: stored=", stored_total, " from_habits=", true_total, " from_history=", history_total, " using=", best_total)
		GameManager.player_data.total_habits_completed = best_total

		# Also fix individual habit total_completions if history shows more
		_sync_habit_totals_with_history()


## Get total completions from completion_history
func get_total_from_history() -> int:
	var total: int = 0
	for habit_id in completion_history:
		total += completion_history[habit_id].size()
	return total


## Sync individual habit total_completions with their completion history
func _sync_habit_totals_with_history() -> void:
	for habit_id in habits:
		var habit = habits[habit_id]
		var history_count = completion_history.get(habit_id, []).size()
		var stored_count = habit.get("total_completions", 0)

		if history_count > stored_count:
			print("[HabitManager] Fixing habit '", habit.get("name", habit_id), "' total: ", stored_count, " -> ", history_count)
			habit.total_completions = history_count


## Reset all habits to defaults
func reset_habits() -> void:
	habits.clear()
	todays_completions.clear()
	topics.clear()
	topics_completions.clear()
	last_date = ""
	_initialize_preset_habits()
	print("[HabitManager] Habits and topics reset to defaults")


## Check if all active habits are completed today
func _all_habits_completed_today() -> bool:
	var active_habits = get_all_habits(false)
	if active_habits.size() == 0:
		return false

	for habit in active_habits:
		if not todays_completions.get(habit.id, false):
			return false
	return true


## Get number of consecutive days with all habits completed
func _get_consecutive_all_habits_days() -> int:
	var active_habits = get_all_habits(false)
	if active_habits.size() == 0:
		return 0

	var consecutive = 0
	var day_offset = 0

	# Start from today if all completed, otherwise start from yesterday
	if _all_habits_completed_today():
		day_offset = 0
		consecutive = 1
	else:
		return 0

	# Check previous days
	for i in range(1, 30):  # Check up to 30 days back
		var check_date = _get_date_n_days_ago(i)
		var all_done_that_day = true

		for habit in active_habits:
			var history = completion_history.get(habit.id, [])
			if check_date not in history:
				all_done_that_day = false
				break

		if all_done_that_day:
			consecutive += 1
		else:
			break

	return consecutive


# =============================================================================
# REMINDER SYSTEM
# =============================================================================

func _setup_reminder_system() -> void:
	## Initialize the reminder checking system
	reminder_check_timer = Timer.new()
	reminder_check_timer.name = "ReminderCheckTimer"
	reminder_check_timer.wait_time = 30.0  # Check every 30 seconds
	reminder_check_timer.autostart = true
	reminder_check_timer.timeout.connect(_check_reminders)
	add_child(reminder_check_timer)

	# Load saved reminders
	_load_reminders()

	print("[HabitManager] Reminder system initialized")


func _check_reminders() -> void:
	## Check if any reminders should trigger now
	var now = Time.get_datetime_dict_from_system()
	var current_minute = now.hour * 60 + now.minute
	var current_day = now.weekday  # 0 = Sunday, 6 = Saturday

	# Only check once per minute
	if current_minute == last_reminder_check_minute:
		return
	last_reminder_check_minute = current_minute

	# Reset triggered reminders at midnight
	if now.hour == 0 and now.minute == 0:
		triggered_reminders_today.clear()

	# Check each habit's reminder
	for habit_id in habit_reminders:
		var reminder = habit_reminders[habit_id]

		if not reminder.get("enabled", false):
			continue

		# Check if already triggered today
		if habit_id in triggered_reminders_today:
			continue

		# Check if habit is already completed today
		if habit_id in todays_completions:
			continue

		# Parse reminder time
		var time_parts = reminder.get("time", "09:00").split(":")
		if time_parts.size() != 2:
			continue

		var reminder_minute = int(time_parts[0]) * 60 + int(time_parts[1])

		# Check if it's time (within 1 minute window)
		if abs(current_minute - reminder_minute) > 0:
			continue

		# Check if today is an enabled day
		var enabled_days = reminder.get("days", [0, 1, 2, 3, 4, 5, 6])
		if current_day not in enabled_days:
			continue

		# Trigger the reminder
		_trigger_reminder(habit_id)


func _trigger_reminder(habit_id: String) -> void:
	## Fire a reminder notification for a habit
	if habit_id in triggered_reminders_today:
		return

	var habit = habits.get(habit_id, {})
	if habit.is_empty():
		return

	triggered_reminders_today.append(habit_id)

	var habit_name = habit.get("name", "Habit")
	var habit_icon = habit.get("icon", "custom")
	var icon_info = HABIT_ICONS.get(habit_icon, HABIT_ICONS["custom"])

	print("[HabitManager] Reminder triggered for: ", habit_name)

	# Emit signal for UI to handle
	habit_reminder_triggered.emit(habit_id, habit_name)


func set_habit_reminder(habit_id: String, time: String, enabled: bool = true, days: Array = [0, 1, 2, 3, 4, 5, 6]) -> void:
	## Set or update a reminder for a habit
	## time: "HH:MM" format (24-hour)
	## days: Array of weekday numbers (0 = Sunday, 6 = Saturday)
	habit_reminders[habit_id] = {
		"time": time,
		"enabled": enabled,
		"days": days
	}
	_save_reminders()
	print("[HabitManager] Reminder set for %s at %s" % [habit_id, time])


func get_habit_reminder(habit_id: String) -> Dictionary:
	## Get reminder settings for a habit
	return habit_reminders.get(habit_id, {"time": "09:00", "enabled": false, "days": [0, 1, 2, 3, 4, 5, 6]})


func clear_habit_reminder(habit_id: String) -> void:
	## Remove a reminder for a habit
	if habit_id in habit_reminders:
		habit_reminders.erase(habit_id)
		_save_reminders()
		print("[HabitManager] Reminder cleared for ", habit_id)


func toggle_habit_reminder(habit_id: String) -> bool:
	## Toggle a reminder on/off, returns new state
	if habit_id in habit_reminders:
		habit_reminders[habit_id]["enabled"] = not habit_reminders[habit_id]["enabled"]
	else:
		habit_reminders[habit_id] = {"time": "09:00", "enabled": true, "days": [0, 1, 2, 3, 4, 5, 6]}

	_save_reminders()
	return habit_reminders[habit_id]["enabled"]


func get_all_reminders() -> Dictionary:
	## Get all habit reminders
	return habit_reminders.duplicate()


func get_next_reminder() -> Dictionary:
	## Get the next upcoming reminder (for display purposes)
	var now = Time.get_datetime_dict_from_system()
	var current_minute = now.hour * 60 + now.minute
	var current_day = now.weekday

	var next_reminder = {}
	var next_time_diff = 999999

	for habit_id in habit_reminders:
		var reminder = habit_reminders[habit_id]
		if not reminder.get("enabled", false):
			continue

		# Skip if already completed today
		if habit_id in todays_completions:
			continue

		var time_parts = reminder.get("time", "09:00").split(":")
		if time_parts.size() != 2:
			continue

		var reminder_minute = int(time_parts[0]) * 60 + int(time_parts[1])

		# Check enabled days
		var enabled_days = reminder.get("days", [0, 1, 2, 3, 4, 5, 6])

		# Calculate time until next occurrence
		var time_diff = reminder_minute - current_minute
		if time_diff <= 0 or current_day not in enabled_days:
			time_diff += 1440  # Next day

		if time_diff < next_time_diff:
			next_time_diff = time_diff
			var habit = habits.get(habit_id, {})
			next_reminder = {
				"habit_id": habit_id,
				"habit_name": habit.get("name", "Habit"),
				"time": reminder.get("time", "09:00"),
				"minutes_until": time_diff
			}

	return next_reminder


func _save_reminders() -> void:
	## Save reminders to file
	var file = FileAccess.open("user://habit_reminders.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(habit_reminders, "\t"))
		file.close()


func _load_reminders() -> void:
	## Load reminders from file
	var path = "user://habit_reminders.json"
	if not FileAccess.file_exists(path):
		return

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return

	var json = JSON.new()
	var result = json.parse(file.get_as_text())
	file.close()

	if result == OK and json.data is Dictionary:
		habit_reminders = json.data
		# Convert days arrays back to proper format
		for habit_id in habit_reminders:
			var days = habit_reminders[habit_id].get("days", [])
			var int_days = []
			for d in days:
				int_days.append(int(d))
			habit_reminders[habit_id]["days"] = int_days
		print("[HabitManager] Loaded ", habit_reminders.size(), " reminders")
