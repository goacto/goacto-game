extends Node

# RelationshipManager - Tracks and nurtures important relationships
# Part of the GOACTO self-improvement system
# Integrates with Compassion aspect for XP rewards

signal relationship_added(relationship_id: String, relationship_data: Dictionary)
signal relationship_updated(relationship_id: String, relationship_data: Dictionary)
signal relationship_removed(relationship_id: String)
signal interaction_logged(relationship_id: String, interaction_data: Dictionary)
signal relationship_streak_updated(relationship_id: String, streak: int)
signal relationship_health_changed(relationship_id: String, health: int)
signal weekly_check_in_completed(relationship_id: String)

# Relationship categories
enum RelationshipCategory {
	FAMILY,
	FRIEND,
	ROMANTIC,
	PROFESSIONAL,
	MENTOR,
	COMMUNITY
}

# Interaction types with XP values
const INTERACTION_TYPES = {
	"call": {"name": "Phone/Video Call", "xp": 15, "icon": "phone"},
	"visit": {"name": "In-Person Visit", "xp": 25, "icon": "home"},
	"message": {"name": "Text/Message", "xp": 5, "icon": "chat"},
	"gift": {"name": "Gift/Surprise", "xp": 20, "icon": "gift"},
	"quality_time": {"name": "Quality Time", "xp": 30, "icon": "heart"},
	"help": {"name": "Helped Them", "xp": 20, "icon": "hands"},
	"listen": {"name": "Active Listening", "xp": 15, "icon": "ear"},
	"celebrate": {"name": "Celebrated Together", "xp": 20, "icon": "party"},
	"support": {"name": "Emotional Support", "xp": 25, "icon": "hug"},
	"shared_activity": {"name": "Shared Activity", "xp": 20, "icon": "activity"}
}

# Health level descriptions
const HEALTH_LEVELS = {
	1: {"name": "Distant", "color": Color(0.8, 0.2, 0.2), "description": "Needs attention"},
	2: {"name": "Cooling", "color": Color(0.9, 0.5, 0.2), "description": "Could use more connection"},
	3: {"name": "Stable", "color": Color(0.9, 0.8, 0.2), "description": "Maintaining well"},
	4: {"name": "Warm", "color": Color(0.5, 0.8, 0.3), "description": "Growing stronger"},
	5: {"name": "Thriving", "color": Color(0.2, 0.9, 0.4), "description": "Flourishing connection"}
}

# Storage
var relationships: Dictionary = {}
var interaction_history: Dictionary = {}  # relationship_id -> Array of interactions
var last_check_date: String = ""

# XP rewards
const BASE_INTERACTION_XP = 10
const STREAK_BONUS_PER_WEEK = 5
const WEEKLY_CHECK_IN_XP = 25
const HEALTH_IMPROVEMENT_XP = 15


func _ready() -> void:
	_check_date_change()


func _check_date_change() -> void:
	var current_date = _get_current_date()
	if last_check_date != current_date:
		last_check_date = current_date
		_update_all_relationship_health()


func _get_current_date() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [datetime.year, datetime.month, datetime.day]


func _get_current_week() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	# Simple week calculation (week of year)
	var day_of_year = Time.get_unix_time_from_datetime_dict(datetime) / 86400
	var week_num = int(day_of_year / 7)
	return "%04d-W%02d" % [datetime.year, week_num]


# ============================================================
# RELATIONSHIP MANAGEMENT
# ============================================================

func add_relationship(name: String, category: RelationshipCategory, notes: String = "") -> String:
	var id = "rel_" + str(Time.get_unix_time_from_system())

	var relationship = {
		"id": id,
		"name": name,
		"category": category,
		"notes": notes,
		"health": 3,  # Start at "Stable"
		"streak_weeks": 0,  # Consecutive weeks with interaction
		"best_streak": 0,
		"total_interactions": 0,
		"last_interaction_date": "",
		"last_interaction_week": "",
		"created_at": Time.get_unix_time_from_system(),
		"weekly_check_ins": {},  # week_string -> completed bool
		"interaction_goal": 1,  # Minimum interactions per week
		"priority": false,  # Is this a priority relationship?
		"birthday": "",  # Optional birthday tracking
		"reminders": []  # Custom reminders
	}

	relationships[id] = relationship
	interaction_history[id] = []

	relationship_added.emit(id, relationship)
	SaveManager.save_game()

	return id


func update_relationship(relationship_id: String, updates: Dictionary) -> void:
	if relationship_id not in relationships:
		return

	for key in updates:
		if key in relationships[relationship_id] and key != "id":
			relationships[relationship_id][key] = updates[key]

	relationship_updated.emit(relationship_id, relationships[relationship_id])
	SaveManager.save_game()


func remove_relationship(relationship_id: String) -> void:
	if relationship_id not in relationships:
		return

	relationships.erase(relationship_id)
	interaction_history.erase(relationship_id)

	relationship_removed.emit(relationship_id)
	SaveManager.save_game()


func get_relationship(relationship_id: String) -> Dictionary:
	return relationships.get(relationship_id, {})


func get_all_relationships() -> Array:
	var result = []
	for id in relationships:
		result.append(relationships[id])
	# Sort by priority first, then by health (lowest first - needs attention)
	result.sort_custom(func(a, b):
		if a.priority != b.priority:
			return a.priority  # Priority relationships first
		return a.health < b.health  # Lower health = needs attention
	)
	return result


func get_relationships_by_category(category: RelationshipCategory) -> Array:
	var result = []
	for id in relationships:
		if relationships[id].category == category:
			result.append(relationships[id])
	return result


func get_relationships_needing_attention() -> Array:
	var result = []
	var current_week = _get_current_week()

	for id in relationships:
		var rel = relationships[id]
		# Needs attention if: low health OR no interaction this week
		if rel.health <= 2 or rel.last_interaction_week != current_week:
			result.append(rel)

	return result


# ============================================================
# INTERACTION LOGGING
# ============================================================

func log_interaction(relationship_id: String, interaction_type: String, note: String = "") -> Dictionary:
	if relationship_id not in relationships:
		return {}

	if interaction_type not in INTERACTION_TYPES:
		interaction_type = "message"  # Default fallback

	var rel = relationships[relationship_id]
	var current_date = _get_current_date()
	var current_week = _get_current_week()
	var interaction_info = INTERACTION_TYPES[interaction_type]

	# Create interaction record
	var interaction = {
		"id": "int_" + str(Time.get_unix_time_from_system()),
		"type": interaction_type,
		"type_name": interaction_info.name,
		"note": note,
		"date": current_date,
		"week": current_week,
		"timestamp": Time.get_unix_time_from_system()
	}

	# Add to history
	if relationship_id not in interaction_history:
		interaction_history[relationship_id] = []
	interaction_history[relationship_id].append(interaction)

	# Limit history to last 100 interactions per relationship
	if interaction_history[relationship_id].size() > 100:
		interaction_history[relationship_id] = interaction_history[relationship_id].slice(-100)

	# Update relationship stats
	rel.total_interactions += 1
	rel.last_interaction_date = current_date

	# Check for streak update (new week interaction)
	if rel.last_interaction_week != current_week:
		# Check if this continues a streak (was last week active?)
		var last_week_num = _get_week_number(rel.last_interaction_week)
		var current_week_num = _get_week_number(current_week)

		if last_week_num > 0 and current_week_num - last_week_num == 1:
			# Consecutive week - streak continues
			rel.streak_weeks += 1
		elif rel.last_interaction_week == "":
			# First interaction ever
			rel.streak_weeks = 1
		else:
			# Gap in interaction - streak resets
			rel.streak_weeks = 1

		rel.best_streak = max(rel.best_streak, rel.streak_weeks)
		relationship_streak_updated.emit(relationship_id, rel.streak_weeks)

	rel.last_interaction_week = current_week

	# Update health based on interaction frequency
	_update_relationship_health(relationship_id)

	# Calculate and award XP
	var xp = _calculate_interaction_xp(rel, interaction_type)
	_award_xp(xp)

	interaction.xp_earned = xp

	interaction_logged.emit(relationship_id, interaction)
	SaveManager.save_game()

	return interaction


func get_interaction_history(relationship_id: String, limit: int = 20) -> Array:
	if relationship_id not in interaction_history:
		return []

	var history = interaction_history[relationship_id]
	if history.size() <= limit:
		return history.duplicate()
	return history.slice(-limit)


func get_recent_interactions(days: int = 7) -> Array:
	var result = []
	var cutoff_time = Time.get_unix_time_from_system() - (days * 86400)

	for rel_id in interaction_history:
		for interaction in interaction_history[rel_id]:
			if interaction.timestamp >= cutoff_time:
				var entry = interaction.duplicate()
				entry.relationship_id = rel_id
				entry.relationship_name = relationships[rel_id].name if rel_id in relationships else "Unknown"
				result.append(entry)

	# Sort by timestamp descending
	result.sort_custom(func(a, b): return a.timestamp > b.timestamp)
	return result


# ============================================================
# WEEKLY CHECK-IN
# ============================================================

func complete_weekly_check_in(relationship_id: String, reflection: String = "") -> void:
	if relationship_id not in relationships:
		return

	var rel = relationships[relationship_id]
	var current_week = _get_current_week()

	# Mark check-in complete
	rel.weekly_check_ins[current_week] = {
		"completed": true,
		"reflection": reflection,
		"timestamp": Time.get_unix_time_from_system()
	}

	# Award XP
	_award_xp(WEEKLY_CHECK_IN_XP)

	weekly_check_in_completed.emit(relationship_id)
	SaveManager.save_game()


func is_weekly_check_in_done(relationship_id: String) -> bool:
	if relationship_id not in relationships:
		return false

	var current_week = _get_current_week()
	return current_week in relationships[relationship_id].weekly_check_ins


func get_weekly_check_in_progress() -> Dictionary:
	var total = relationships.size()
	var completed = 0
	var current_week = _get_current_week()

	for id in relationships:
		if current_week in relationships[id].weekly_check_ins:
			completed += 1

	return {
		"total": total,
		"completed": completed,
		"percentage": (float(completed) / max(total, 1)) * 100
	}


# ============================================================
# HEALTH SYSTEM
# ============================================================

func _update_relationship_health(relationship_id: String) -> void:
	if relationship_id not in relationships:
		return

	var rel = relationships[relationship_id]
	var old_health = rel.health

	# Calculate new health based on:
	# - Recent interaction frequency
	# - Streak length
	# - Interaction variety

	var current_week = _get_current_week()
	var weeks_since_interaction = _weeks_since(rel.last_interaction_week, current_week)

	var new_health = 3  # Base: Stable

	if weeks_since_interaction == 0:
		# Interacted this week
		if rel.streak_weeks >= 4:
			new_health = 5  # Thriving
		elif rel.streak_weeks >= 2:
			new_health = 4  # Warm
		else:
			new_health = 3  # Stable
	elif weeks_since_interaction == 1:
		new_health = 3  # Still stable
	elif weeks_since_interaction == 2:
		new_health = 2  # Cooling
	else:
		new_health = 1  # Distant

	if new_health != old_health:
		rel.health = new_health
		relationship_health_changed.emit(relationship_id, new_health)

		# Bonus XP for health improvement
		if new_health > old_health:
			_award_xp(HEALTH_IMPROVEMENT_XP)


func _update_all_relationship_health() -> void:
	for id in relationships:
		_update_relationship_health(id)


func _weeks_since(week1: String, week2: String) -> int:
	if week1 == "" or week2 == "":
		return 99  # Very old

	var w1 = _get_week_number(week1)
	var w2 = _get_week_number(week2)

	if w1 <= 0 or w2 <= 0:
		return 99

	return w2 - w1


func _get_week_number(week_string: String) -> int:
	# Parse "2026-W12" format
	if week_string == "":
		return 0

	var parts = week_string.split("-W")
	if parts.size() != 2:
		return 0

	var year = int(parts[0])
	var week = int(parts[1])

	return year * 52 + week


# ============================================================
# XP SYSTEM
# ============================================================

func _calculate_interaction_xp(relationship: Dictionary, interaction_type: String) -> int:
	var base_xp = INTERACTION_TYPES[interaction_type].xp

	# Streak bonus
	var streak_bonus = relationship.streak_weeks * STREAK_BONUS_PER_WEEK
	streak_bonus = min(streak_bonus, 25)  # Cap at 25 bonus XP

	# Priority relationship bonus
	var priority_bonus = 10 if relationship.priority else 0

	return base_xp + streak_bonus + priority_bonus


func _award_xp(amount: int) -> void:
	# Award to Compassion aspect
	if GameManager:
		GameManager.add_aspect_experience("compassion", amount)
		GameManager.evolve_world(amount * 0.02)  # Small evolution contribution


# ============================================================
# STATISTICS
# ============================================================

func get_statistics() -> Dictionary:
	var total_relationships = relationships.size()
	var total_interactions = 0
	var healthy_count = 0
	var needs_attention = 0
	var longest_streak = 0
	var interactions_this_week = 0
	var current_week = _get_current_week()

	for id in relationships:
		var rel = relationships[id]
		total_interactions += rel.total_interactions
		longest_streak = max(longest_streak, rel.best_streak)

		if rel.health >= 4:
			healthy_count += 1
		elif rel.health <= 2:
			needs_attention += 1

		if rel.last_interaction_week == current_week:
			interactions_this_week += 1

	# Count actual interactions this week
	var weekly_interactions = get_recent_interactions(7).size()

	return {
		"total_relationships": total_relationships,
		"total_interactions": total_interactions,
		"healthy_relationships": healthy_count,
		"needs_attention": needs_attention,
		"longest_streak": longest_streak,
		"interactions_this_week": weekly_interactions,
		"relationships_contacted_this_week": interactions_this_week,
		"average_health": _calculate_average_health()
	}


func _calculate_average_health() -> float:
	if relationships.size() == 0:
		return 0.0

	var total = 0.0
	for id in relationships:
		total += relationships[id].health

	return total / relationships.size()


func get_category_name(category: RelationshipCategory) -> String:
	match category:
		RelationshipCategory.FAMILY: return "Family"
		RelationshipCategory.FRIEND: return "Friend"
		RelationshipCategory.ROMANTIC: return "Romantic"
		RelationshipCategory.PROFESSIONAL: return "Professional"
		RelationshipCategory.MENTOR: return "Mentor"
		RelationshipCategory.COMMUNITY: return "Community"
		_: return "Other"


# ============================================================
# SAVE/LOAD
# ============================================================

func get_save_data() -> Dictionary:
	return {
		"relationships": relationships,
		"interaction_history": interaction_history,
		"last_check_date": last_check_date
	}


func load_save_data(data: Dictionary) -> void:
	relationships = data.get("relationships", {})
	interaction_history = data.get("interaction_history", {})
	last_check_date = data.get("last_check_date", "")

	_check_date_change()
