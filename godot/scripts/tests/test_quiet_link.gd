extends SceneTree
## Run: godot --headless --path godot -s res://scripts/tests/test_quiet_link.gd
const Q := preload("res://scripts/ui/quiet_link.gd")
var fails := 0
var passes := 0
func check(c: bool, n: String) -> void:
	if c:
		passes += 1; print("  PASS ", n)
	else:
		fails += 1; print("  FAIL ", n)
func _init() -> void:
	check(Q.WORKBOOK_URL == "https://goacto.com/products/30-day-habit-builder-workbook", "real store URL")
	check(Q.url().begins_with(Q.WORKBOOK_URL + "?utm_source=mindscape"), "utm tagged")
	check(not Q.TEXT.contains("&"), "copy says 'and', not '&'")
	var l: LinkButton = Q.make()
	check(l is LinkButton and l.uri == Q.url(), "is a plain link, not a pop-up")
	l.free()
	var fm := FileAccess.get_file_as_string("res://scenes/focus_mode/focus_mode.gd")
	check(fm.count("QuietLink.make()") == 1, "exactly one link on session complete")
	print("RESULT quiet_link: %d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)
