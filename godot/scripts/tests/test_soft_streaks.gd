extends SceneTree
## Headless tests for soft streaks (days you showed up, never reset, no guilt copy).
## Run: godot --headless --path godot -s res://scripts/tests/test_soft_streaks.gd
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
	var hm := FileAccess.get_file_as_string("res://autoload/HabitManager.gd")
	check(hm.contains("const SOFT_STREAKS: bool = true"), "soft streaks on")
	check(hm.contains("if SOFT_STREAKS:\n\t\t\tbreak"), "missed day never marks a habit at risk")
	check(hm.contains("pending_streak_breaks.clear()"), "old saves: at-risk entries dropped")
	check(hm.contains("and not SOFT_STREAKS:\n\t\t\t\tvar habit"), "expiry never zeroes the count")
	check(hm.contains("SHOWED_UP_BONUS_CAP"), "bonus is capped, so the count can grow forever")
	# Save keys unchanged for compatibility
	check(hm.contains("\"streak\": 0") and hm.contains("\"best_streak\": 0"), "save keys unchanged")
	var banned := ["Streaks at Risk", "save your streak", "Streak expired", "Streak Saved!", "day streak", "Day Streak", "Current Streak", "Best Streak", "Streaks get broken"]
	var files := ["res://scenes/mindscape/mindscape_hub.gd", "res://scenes/daily_rituals/daily_rituals.gd", "res://scenes/mindscape/mindscape_west.gd", "res://scenes/mindscape/mindscape_east.gd", "res://scenes/mindscape/mindscape_legacy.gd", "res://scenes/ship/hallway.gd"]
	for f in files:
		var src := FileAccess.get_file_as_string(f)
		for b in banned:
			check(not src.contains("\"" + b) and not src.contains(b + "\"") and not src.contains(b + "!\""), "%s has no '%s' copy" % [f.get_file(), b])
	print("RESULT soft_streaks: %d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)
