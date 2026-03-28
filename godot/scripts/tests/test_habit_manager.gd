extends Node
## Unit tests for HabitManager
## Run from editor: attach to a Node in a test scene, or call run_all_tests()

var pass_count: int = 0
var fail_count: int = 0
var test_results: Array = []


func _ready() -> void:
	run_all_tests()


func run_all_tests() -> void:
	print("\n========================================")
	print("  HabitManager Unit Tests")
	print("========================================\n")

	pass_count = 0
	fail_count = 0
	test_results.clear()

	# Topic tests
	_test_create_topic()
	_test_complete_topic()
	_test_archive_topic()
	_test_unarchive_topic()
	_test_delete_topic()
	_test_topic_session_tracking()
	_test_archived_topics_filtered()

	# Habit tests
	_test_add_habit()
	_test_complete_habit()
	_test_habit_streak()
	_test_habit_already_completed()
	_test_get_all_habits_excludes_archived()
	_test_grace_days_tracking()

	# Save/Load tests
	_test_save_data_includes_topics()
	_test_save_data_includes_habits()

	# Edge case tests
	_test_complete_nonexistent_topic()
	_test_complete_nonexistent_habit()
	_test_delete_nonexistent_topic()
	_test_archive_nonexistent_topic()

	print("\n========================================")
	print("  Results: %d passed, %d failed" % [pass_count, fail_count])
	print("========================================\n")

	for result in test_results:
		if not result.passed:
			print("  FAIL: %s - %s" % [result.name, result.message])


# =============================================================================
# ASSERTIONS
# =============================================================================

func _assert(condition: bool, test_name: String, message: String = "") -> void:
	if condition:
		pass_count += 1
		test_results.append({"name": test_name, "passed": true, "message": ""})
		print("  PASS: %s" % test_name)
	else:
		fail_count += 1
		test_results.append({"name": test_name, "passed": false, "message": message})
		print("  FAIL: %s - %s" % [test_name, message])


func _assert_eq(actual, expected, test_name: String) -> void:
	_assert(actual == expected, test_name, "expected %s, got %s" % [str(expected), str(actual)])


func _assert_gt(actual, expected, test_name: String) -> void:
	_assert(actual > expected, test_name, "expected > %s, got %s" % [str(expected), str(actual)])


# =============================================================================
# TOPIC TESTS
# =============================================================================

func _test_create_topic() -> void:
	var before_count = HabitManager.topics.size()
	var id = HabitManager.create_topic("Test Topic")

	_assert(id != "", "create_topic returns non-empty ID")
	_assert(id.begins_with("topic_"), "create_topic ID has correct prefix")
	_assert(HabitManager.topics.has(id), "create_topic adds to topics dict")
	_assert_eq(HabitManager.topics[id].name, "Test Topic", "create_topic stores name")
	_assert_eq(HabitManager.topics[id].total_sessions, 0, "create_topic starts at 0 sessions")

	# Cleanup
	HabitManager.topics.erase(id)
	HabitManager.topics_completions.erase(id)


func _test_complete_topic() -> void:
	var id = HabitManager.create_topic("Complete Test")
	var result = HabitManager.complete_topic(id, 25)

	_assert(not result.is_empty(), "complete_topic returns topic data")
	_assert_eq(result.total_sessions, 1, "complete_topic increments sessions")
	_assert_eq(result.total_minutes, 25, "complete_topic adds minutes")
	_assert_eq(result.last_duration, 25, "complete_topic stores duration")

	# Cleanup
	HabitManager.topics.erase(id)
	HabitManager.topics_completions.erase(id)


func _test_archive_topic() -> void:
	var id = HabitManager.create_topic("Archive Test")
	HabitManager.archive_topic(id)

	_assert_eq(HabitManager.topics[id].get("archived"), true, "archive_topic sets archived=true")

	var active = HabitManager.get_all_topics()
	var found = false
	for t in active:
		if t.id == id:
			found = true
	_assert(not found, "archive_topic hides from get_all_topics")

	# Cleanup
	HabitManager.topics.erase(id)
	HabitManager.topics_completions.erase(id)


func _test_unarchive_topic() -> void:
	var id = HabitManager.create_topic("Unarchive Test")
	HabitManager.archive_topic(id)
	HabitManager.unarchive_topic(id)

	_assert_eq(HabitManager.topics[id].get("archived"), false, "unarchive_topic sets archived=false")

	var active = HabitManager.get_all_topics()
	var found = false
	for t in active:
		if t.id == id:
			found = true
	_assert(found, "unarchive_topic shows in get_all_topics")

	# Cleanup
	HabitManager.topics.erase(id)
	HabitManager.topics_completions.erase(id)


func _test_delete_topic() -> void:
	var id = HabitManager.create_topic("Delete Test")
	HabitManager.delete_topic(id)

	_assert(not HabitManager.topics.has(id), "delete_topic removes from topics dict")


func _test_topic_session_tracking() -> void:
	var id = HabitManager.create_topic("Session Track Test")
	HabitManager.complete_topic(id, 25)
	HabitManager.complete_topic(id, 15)

	# Note: second completion same day won't increment streak but will add sessions
	_assert_eq(HabitManager.topics[id].total_sessions, 2, "topic tracks multiple sessions")
	_assert_eq(HabitManager.topics[id].total_minutes, 40, "topic accumulates minutes")

	# Cleanup
	HabitManager.topics.erase(id)
	HabitManager.topics_completions.erase(id)


func _test_archived_topics_filtered() -> void:
	var id1 = HabitManager.create_topic("Active One")
	var id2 = HabitManager.create_topic("Archived One")
	HabitManager.archive_topic(id2)

	var active = HabitManager.get_all_topics()
	var archived = HabitManager.get_archived_topics()

	var active_ids = []
	for t in active:
		active_ids.append(t.id)
	var archived_ids = []
	for t in archived:
		archived_ids.append(t.id)

	_assert(id1 in active_ids, "active topic in get_all_topics")
	_assert(id2 not in active_ids, "archived topic not in get_all_topics")
	_assert(id2 in archived_ids, "archived topic in get_archived_topics")

	# Cleanup
	HabitManager.topics.erase(id1)
	HabitManager.topics.erase(id2)
	HabitManager.topics_completions.erase(id1)
	HabitManager.topics_completions.erase(id2)


# =============================================================================
# HABIT TESTS
# =============================================================================

func _test_add_habit() -> void:
	var test_habit = {
		"id": "test_habit_1",
		"name": "Test Habit",
		"domain": 0,
		"exp_reward": 10,
		"evolution_reward": 0.5,
		"streak": 0,
		"best_streak": 0,
		"total_completions": 0,
		"is_preset": false,
		"archived": false,
		"order": 0
	}
	HabitManager.add_habit(test_habit)

	_assert(HabitManager.habits.has("test_habit_1"), "add_habit adds to habits dict")
	_assert_eq(HabitManager.habits["test_habit_1"].name, "Test Habit", "add_habit stores name")

	# Cleanup
	HabitManager.habits.erase("test_habit_1")
	HabitManager.todays_completions.erase("test_habit_1")


func _test_complete_habit() -> void:
	var test_habit = {
		"id": "test_complete_1",
		"name": "Complete Test",
		"domain": 0,
		"exp_reward": 10,
		"evolution_reward": 0.5,
		"streak": 0,
		"best_streak": 0,
		"total_completions": 0,
		"is_preset": false,
		"archived": false,
		"order": 0
	}
	HabitManager.add_habit(test_habit)
	var result = HabitManager.complete_habit("test_complete_1")

	_assert(not result.is_empty(), "complete_habit returns habit data")
	_assert_eq(result.total_completions, 1, "complete_habit increments completions")
	_assert_eq(HabitManager.todays_completions["test_complete_1"], true, "complete_habit marks today done")

	# Cleanup
	HabitManager.habits.erase("test_complete_1")
	HabitManager.todays_completions.erase("test_complete_1")
	HabitManager.completion_history.erase("test_complete_1")


func _test_habit_streak() -> void:
	var test_habit = {
		"id": "test_streak_1",
		"name": "Streak Test",
		"domain": 0,
		"exp_reward": 10,
		"evolution_reward": 0.5,
		"streak": 5,
		"best_streak": 5,
		"total_completions": 5,
		"is_preset": false,
		"archived": false,
		"order": 0
	}
	HabitManager.add_habit(test_habit)
	HabitManager.complete_habit("test_streak_1")

	_assert_eq(HabitManager.habits["test_streak_1"].streak, 6, "complete_habit increments streak")
	_assert_eq(HabitManager.habits["test_streak_1"].best_streak, 6, "complete_habit updates best_streak")

	# Cleanup
	HabitManager.habits.erase("test_streak_1")
	HabitManager.todays_completions.erase("test_streak_1")
	HabitManager.completion_history.erase("test_streak_1")


func _test_habit_already_completed() -> void:
	var test_habit = {
		"id": "test_double_1",
		"name": "Double Complete Test",
		"domain": 0,
		"exp_reward": 10,
		"evolution_reward": 0.5,
		"streak": 0,
		"best_streak": 0,
		"total_completions": 0,
		"is_preset": false,
		"archived": false,
		"order": 0
	}
	HabitManager.add_habit(test_habit)
	HabitManager.complete_habit("test_double_1")
	HabitManager.complete_habit("test_double_1")  # Second time same day

	_assert_eq(HabitManager.habits["test_double_1"].total_completions, 1, "double complete doesn't double count")
	_assert_eq(HabitManager.habits["test_double_1"].streak, 1, "double complete doesn't double streak")

	# Cleanup
	HabitManager.habits.erase("test_double_1")
	HabitManager.todays_completions.erase("test_double_1")
	HabitManager.completion_history.erase("test_double_1")


func _test_get_all_habits_excludes_archived() -> void:
	var h1 = {"id": "test_active", "name": "Active", "domain": 0, "exp_reward": 10, "evolution_reward": 0.5, "streak": 0, "best_streak": 0, "total_completions": 0, "is_preset": false, "archived": false, "order": 0}
	var h2 = {"id": "test_archived", "name": "Archived", "domain": 0, "exp_reward": 10, "evolution_reward": 0.5, "streak": 0, "best_streak": 0, "total_completions": 0, "is_preset": false, "archived": true, "order": 1}
	HabitManager.add_habit(h1)
	HabitManager.add_habit(h2)

	var all_active = HabitManager.get_all_habits(false)
	var ids = []
	for h in all_active:
		ids.append(h.id)

	_assert("test_active" in ids, "get_all_habits includes active")
	_assert("test_archived" not in ids, "get_all_habits excludes archived")

	var all_including = HabitManager.get_all_habits(true)
	var all_ids = []
	for h in all_including:
		all_ids.append(h.id)
	_assert("test_archived" in all_ids, "get_all_habits(true) includes archived")

	# Cleanup
	HabitManager.habits.erase("test_active")
	HabitManager.habits.erase("test_archived")
	HabitManager.todays_completions.erase("test_active")
	HabitManager.todays_completions.erase("test_archived")


func _test_grace_days_tracking() -> void:
	var h = {"id": "test_grace", "name": "Grace Test", "domain": 0, "exp_reward": 10, "evolution_reward": 0.5, "streak": 0, "best_streak": 0, "total_completions": 0, "is_preset": false, "archived": false, "order": 0, "grace_days_used": 3}
	HabitManager.add_habit(h)

	var total = HabitManager.get_total_grace_days_used()
	_assert_gt(total, 0, "get_total_grace_days_used counts grace_days_used field")

	# Cleanup
	HabitManager.habits.erase("test_grace")
	HabitManager.todays_completions.erase("test_grace")


# =============================================================================
# SAVE/LOAD TESTS
# =============================================================================

func _test_save_data_includes_topics() -> void:
	var id = HabitManager.create_topic("Save Test Topic")
	var save = HabitManager.get_save_data()

	_assert(save.has("topics"), "save_data has topics key")
	_assert(save.topics.has(id), "save_data topics includes created topic")

	# Cleanup
	HabitManager.topics.erase(id)
	HabitManager.topics_completions.erase(id)


func _test_save_data_includes_habits() -> void:
	var save = HabitManager.get_save_data()
	_assert(save.has("habits"), "save_data has habits key")
	_assert(save.has("todays_completions"), "save_data has todays_completions key")
	_assert(save.has("grace_days_available"), "save_data has grace_days_available key")


# =============================================================================
# EDGE CASE TESTS
# =============================================================================

func _test_complete_nonexistent_topic() -> void:
	var result = HabitManager.complete_topic("nonexistent_topic_xyz")
	_assert(result.is_empty(), "complete_topic on nonexistent returns empty dict")


func _test_complete_nonexistent_habit() -> void:
	var result = HabitManager.complete_habit("nonexistent_habit_xyz")
	_assert(result.is_empty(), "complete_habit on nonexistent returns empty dict")


func _test_delete_nonexistent_topic() -> void:
	# Should not crash
	HabitManager.delete_topic("nonexistent_topic_xyz")
	_assert(true, "delete_topic on nonexistent does not crash")


func _test_archive_nonexistent_topic() -> void:
	# Should not crash
	HabitManager.archive_topic("nonexistent_topic_xyz")
	_assert(true, "archive_topic on nonexistent does not crash")
