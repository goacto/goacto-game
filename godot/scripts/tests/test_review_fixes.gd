extends SceneTree
## Headless checks for the Nov 2026 review fixes.
## Run: godot --headless --path godot -s res://scripts/tests/test_review_fixes.gd

const AspectXp := preload("res://scripts/progression/aspect_xp.gd")
const QuestRules := preload("res://scripts/progression/quest_rules.gd")
const LoginRewards := preload("res://scripts/progression/login_rewards.gd")
const EvolutionLevel := preload("res://scripts/progression/evolution_level.gd")
const HabitRules := preload("res://scripts/progression/habit_rules.gd")

var fails := 0
var passes := 0


func check(cond: bool, name: String) -> void:
	if cond:
		passes += 1
		print("  PASS ", name)
	else:
		fails += 1
		print("  FAIL ", name)


func _init() -> void:
	_test_aspect_xp()
	_test_quests()
	_test_login_and_slots()
	_test_reminders()
	_test_call_sites()
	print("RESULT review_fixes: %d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)


func _test_aspect_xp() -> void:
	check(AspectXp.targets("wisdom", "mindfulness", "wisdom"), "aspect id wisdom hits Wisdom")
	check(AspectXp.targets("wisdom", "mindfulness", "mindfulness"), "domain mindfulness hits Wisdom")
	check(not AspectXp.targets("wisdom", "mindfulness", "discipline"), "discipline does not hit Wisdom")
	check(not AspectXp.targets("wisdom", "mindfulness", "spirit"), "spirit matches no Aspect")
	check(AspectXp.targets("discipline", "productivity", "all"), "all hits every Aspect")
	var once = AspectXp.apply(1, 0.0, 100)
	check(int(once.level) == 2 and is_equal_approx(float(once.experience), 0.0), "100 XP levels 1 -> 2")
	var chained = AspectXp.apply(1, 0.0, 300)
	check(int(chained.level) == 3 and is_equal_approx(float(chained.experience), 0.0), "300 XP crosses level 2 and lands on 3")
	var held = AspectXp.apply(2, 50.0, 10)
	check(int(held.level) == 2 and is_equal_approx(float(held.experience), 60.0), "XP under the next threshold stays put")
	var zero = AspectXp.apply(0, 10.0, 50)
	check(int(zero.level) == 0, "level 0 does not spin on a zero cost")


func _test_quests() -> void:
	check(QuestRules.is_constraint("time_limit_hours"), "time limit hours is a constraint")
	check(QuestRules.is_constraint("time_limit_days"), "time limit days is a constraint")
	check(QuestRules.is_constraint("min_duration"), "min duration is a constraint")
	check(not QuestRules.is_constraint("habit_streak_days"), "habit streak days is a real counter")
	check(not QuestRules.is_constraint("gratitude_streak_days"), "gratitude streak days is a real counter")
	check(not QuestRules.is_constraint("high_vitality_days"), "high vitality days is a real counter")
	check(not QuestRules.requirement_met("habit_streak_days", 3, {"habit_streak_days": 1}), "streak of 1 does not finish a 3-day quest")
	check(QuestRules.requirement_met("habit_streak_days", 3, {"habit_streak_days": 3}), "streak of 3 finishes the quest")
	check(QuestRules.requirement_met("time_limit_hours", 24, {}), "a deadline alone does not block completion")
	check(QuestRules.requirement_met("weekly_synthesis", 1, {"weekly_synthesis_completed": true}), "old weekly synthesis flag still counts")
	check(QuestRules.requirement_met("values_check_complete", true, {"values_check_completed": true}), "old values-check flag still counts")
	check(QuestRules.requirement_met("single_session_minutes", 60, {"long_session_completed": true}), "old long-session flag still counts")
	check(not QuestRules.requirement_met("single_session_minutes", 60, {}), "a 60-minute quest does not complete with no session")
	check(QuestRules.requirement_met("unique_categories", 4, {"categories": ["a", "b", "c", "d"]}), "four categories meet the polymath quest")
	check(not QuestRules.requirement_met("unique_categories", 4, {"categories": ["a", "b"]}), "two categories do not")
	check(QuestRules.requirement_met("relationships_contacted", 3, {"relationships": ["a", "b", "c"]}), "three relationships meet the quest")
	check(QuestRules.focus_session_counts({"min_duration": 15}, 15), "15 minute session counts")
	check(not QuestRules.focus_session_counts({"min_duration": 15}, 14), "14 minute session does not count")
	check(QuestRules.focus_session_counts({}, 5), "no minimum means any session counts")


func _test_login_and_slots() -> void:
	check(LoginRewards.claim_token(1, 1) == 1, "day 1 claim id stays the integer 1")
	check(LoginRewards.claim_token(30, 30) == 30, "day 30 claim id stays an integer")
	check(LoginRewards.claim_token(31, 1) == "1:1", "day 31 is a new cycle, not day 1 again")
	check(LoginRewards.claim_token(60, 30) == "1:30", "day 60 stays in cycle 1")
	check(LoginRewards.claim_token(61, 1) == "2:1", "day 61 opens cycle 2")
	check(not (1 in [LoginRewards.claim_token(31, 1)]), "a cycle-1 token is not the old day-1 id")
	check(EvolutionLevel.level_from_percent(0.0) == 1, "0% evolution is level 1")
	check(EvolutionLevel.level_from_percent(10.0) == 2, "10% evolution is level 2")
	check(EvolutionLevel.level_from_percent(25.0) == 3, "25% evolution is level 3")
	check(EvolutionLevel.level_from_player({"world_evolution_level": 40.0}) == 5, "slot row reads the percent")
	check(EvolutionLevel.level_from_player({}) == 1, "missing save data stays level 1")
	check(EvolutionLevel.level_from_player({"evolution_level": 4}) == 4, "legacy key still reads when percent is absent")


func _test_reminders() -> void:
	var today := {"water": false, "read": true}
	check(not HabitRules.completed_today(today, "water"), "incomplete habit is not done")
	check(HabitRules.completed_today(today, "read"), "completed habit is done")
	check(not HabitRules.completed_today(today, "missing"), "unknown habit is not done")
	check("water" in today and not HabitRules.completed_today(today, "water"), "key presence is not completion")


func _test_call_sites() -> void:
	var gm := FileAccess.get_file_as_string("res://autoload/GameManager.gd")
	var habits := FileAccess.get_file_as_string("res://autoload/HabitManager.gd")
	var saves := FileAccess.get_file_as_string("res://autoload/SaveManager.gd")
	var balcony := FileAccess.get_file_as_string("res://scenes/ship/viewing_balcony.gd")
	check(gm.contains("AspectXp.targets("), "GameManager matches Aspect id or domain")
	check(gm.contains("AspectXp.apply("), "GameManager applies chained levels")
	check(gm.contains("QuestRules.requirement_met("), "quest completion uses the shared rule")
	check(gm.contains("QuestRules.focus_session_counts("), "short sessions are filtered before they count")
	check(gm.contains("LoginRewards.claim_token("), "daily claim uses a cycle-aware id")
	check(gm.contains("EvolutionLevel.level_from_percent("), "HUD evolution level uses the shared formula")
	check(habits.contains("HabitRules.completed_today("), "reminders ask whether the habit is done")
	check(not habits.contains("if habit_id in todays_completions:"), "reminders no longer treat every habit as done")
	check(saves.contains("EvolutionLevel.level_from_player("), "slot info reads world evolution percent")
	check(balcony.contains('add_aspect_experience("wisdom"'), "balcony meditation awards Wisdom")
	check(not balcony.contains('add_aspect_experience("spirit"'), "balcony no longer awards a missing spirit Aspect")
	check(balcony.contains("Wisdom XP"), "balcony completion line names Wisdom")
