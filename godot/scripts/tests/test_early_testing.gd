extends SceneTree
## Headless tests for the early-testing badge + feedback links.
## Run: godot --headless --path godot -s res://scripts/tests/test_early_testing.gd

const E := preload("res://scripts/ui/early_testing.gd")
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
	check(E.FEEDBACK_URL == "https://goacto.com/pages/mindscape-feedback", "feedback page url")
	check(E.NOTE == "Mindscape is in early testing. Things will break and change. Tell us what works and what doesn't. Honest feedback shapes what we build next.", "exact early-testing note")
	check(E.feedback_url("v0.1.0-prototype") == "https://goacto.com/pages/mindscape-feedback?build=v0.1.0-prototype", "build param appended")
	check(E.feedback_url("v1 beta&x").ends_with("?build=v1%20beta%26x"), "build param is url-encoded")
	for path in ["res://scenes/settings/settings.gd", "res://scenes/mindscape/mindscape_legacy.gd", "res://scenes/main_menu/main_menu.gd"]:
		var src := FileAccess.get_file_as_string(path)
		check(not src.contains("support@mindscape.game"), "%s: no placeholder support email" % path.get_file())
		check(not src.contains("feedback integration coming soon"), "%s: no 'coming soon' placeholder" % path.get_file())
	var settings := FileAccess.get_file_as_string("res://scenes/settings/settings.gd")
	check(settings.contains("EarlyTesting.feedback_url(GameManager.VERSION)"), "Report Bug uses feedback page + VERSION")
	print("%d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)
