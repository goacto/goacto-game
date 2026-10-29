extends SceneTree
## Run: godot --headless --path godot -s res://scripts/tests/test_grow_give.gd
const G := preload("res://scripts/ui/grow_give.gd")
var fails := 0
var passes := 0
func check(c: bool, n: String) -> void:
	if c: passes += 1; print("  PASS ", n)
	else: fails += 1; print("  FAIL ", n)
func _init() -> void:
	var now := Time.get_unix_time_from_datetime_dict({"year": 2026, "month": 10, "day": 29, "hour": 12, "minute": 0, "second": 0})
	var entries := [{"date": "2026-10-28T09:00:00"}, {"date": "2026-10-25T09:00:00"}, {"date": "2026-10-01T09:00:00"}, {"date": ""}, "junk"]
	check(G.give_count_this_week(entries, now) == 2, "counts only the last 7 days")
	check(G.give_count_this_week([], now) == 0, "empty log is 0")
	check(G.give_line(0).contains("That's fine"), "zero copy has no guilt")
	check(G.give_line(1) == "Kindness Log this week: 1 act.", "singular")
	check(G.give_line(3) == "Kindness Log this week: 3 acts.", "plural")
	check(G.GROW_LABEL.begins_with("🌱 Grow") and G.GIVE_LABEL.begins_with("🤝 Give"), "grow and give labels")
	var hub := FileAccess.get_file_as_string("res://scenes/mindscape/mindscape_hub.gd")
	check(hub.contains('"give": give') and hub.contains("GiveInput"), "synthesis saves a give field")
	check(hub.contains("GrowGive.GROW_LABEL") and hub.contains("GrowGive.OPEN_LABEL"), "synthesis uses grow / open labels")
	var west := FileAccess.get_file_as_string("res://scenes/mindscape/mindscape_west.gd")
	check(west.contains("GrowGive.KINDNESS_INTRO"), "kindness log uses give intro")
	check(not west.contains('"Day Streak"'), "kindness log has no streak stat")
	for path in ["res://scripts/ui/grow_give.gd"]:
		check(not FileAccess.get_file_as_string(path).contains(" & "), "no ampersand copy")
	for sc in ["res://scenes/mindscape/mindscape_hub.gd", "res://scenes/mindscape/mindscape_west.gd"]:
		check(load(sc) != null, "%s compiles" % sc.get_file())
	print("%d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)
