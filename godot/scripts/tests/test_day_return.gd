extends SceneTree
## Honest day-1 reward copy + quiet return line after the first focus session.
## Run: godot --headless --path godot -s res://scripts/tests/test_day_return.gd

const Copy := preload("res://scripts/ui/daily_reward_copy.gd")
const QuietReturn := preload("res://scripts/ui/quiet_return.gd")

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
	var gm := FileAccess.get_file_as_string("res://autoload/GameManager.gd")
	var hub := FileAccess.get_file_as_string("res://scenes/mindscape/mindscape_hub.gd")
	var fm := FileAccess.get_file_as_string("res://scenes/focus_mode/focus_mode.gd")

	check(Copy.FIRST_VISIT == "Welcome, Traveler.", "first-visit line is a welcome, not a return")
	check(Copy.FIRST_VISIT != "Welcome back, Traveler!", "first-visit line is not Welcome back")
	check(not gm.contains("Welcome back, Traveler!"), "GameManager day-1 string is not Welcome back")
	check(gm.contains('"description": "Welcome, Traveler."') or gm.contains("DailyRewardCopy.FIRST_VISIT"), "day-1 table uses the first-visit line")
	check(gm.contains("DailyRewardCopy.for_login"), "daily login path asks for honest copy")
	check(hub.contains('desc_label.text = reward.get("description", "Keep coming back!")'), "hub shows the login reward description")

	var lied := {"day": 1, "description": "Welcome back, Traveler!"}
	check(Copy.for_login(lied, 1) == Copy.FIRST_VISIT, "first visit overrides a welcome-back reward")
	check(Copy.for_login(lied, 0) == Copy.FIRST_VISIT, "missing login history is still a first visit")
	check(Copy.for_login({"day": 2, "description": "Building momentum..."}, 2) == "Building momentum...", "later days keep their own line")
	check(not Copy.for_login(lied, 1).contains("Welcome back"), "shown first-visit copy has no Welcome back")

	var day_two := RegEx.new()
	day_two.compile("\\{\"day\": 2, \"type\": \"xp\", \"amount\": (\\d+)")
	var found := day_two.search(gm)
	check(found != null, "day 2 reward is in the table")
	var xp := int(found.get_string(1)) if found else 0
	check(xp > 0, "day 2 xp is a real amount")
	var rewards: Array = [{"day": 1, "amount": 25}, {"day": 2, "amount": xp}]
	check(QuietReturn.day_two_xp(rewards) == xp, "day 2 xp is read from the reward table")

	var line := QuietReturn.text(xp)
	check(QuietReturn.should_show(0), "line shows when no focus session is saved yet")
	check(not QuietReturn.should_show(1), "line stays quiet after the first saved session")
	check(not QuietReturn.should_show(4), "line does not repeat on later sessions")
	check(line.begins_with("Come back tomorrow."), "line says when to come back")
	check(line.contains("Day 2") and line.contains(str(xp)), "line says what waits on day 2")
	var lower := line.to_lower()
	for banned in ["at risk", "reset", "guilt", "email", "push", "notif", "streak"]:
		check(not lower.contains(banned), "return line has no '%s'" % banned)

	var label := QuietReturn.make(xp)
	check(label is Label and label.name == "QuietReturnLine", "session-end line is one quiet label")
	check(label.get_class() == "Label", "return line is not a button")
	check(label.text == line, "label uses the return line")
	var quiet_src := FileAccess.get_file_as_string("res://scripts/ui/quiet_return.gd")
	check(not quiet_src.contains("LinkButton") and not quiet_src.contains("uri"), "return line does not open a link")
	label.free()

	check(fm.count("QuietReturn.make(") == 1, "exactly one return line on the session summary")
	check(fm.contains("QuietReturn.should_show("), "summary shows the line only for the first session")
	check(fm.contains("QuietReturn.day_two_xp(GameManager.DAILY_REWARDS)"), "summary xp comes from the day-2 reward")
	check(fm.count("QuietLink.make()") == 1, "workbook link still appears once")

	print("RESULT day_return: %d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)
