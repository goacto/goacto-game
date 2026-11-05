extends SceneTree
## Phone first-minute layout. Run:
##   godot --headless --path godot -s res://scripts/tests/test_phone_first_minute.gd

const Frame := preload("res://scripts/ui/cutscene_frame.gd")
const Chrome := preload("res://scripts/ui/phone_chrome.gd")

var fails := 0
var passes := 0

func check(cond: bool, name: String) -> void:
	if cond:
		passes += 1
		print("  PASS ", name)
	else:
		fails += 1
		print("  FAIL ", name)


func _assert_frame(vp: Vector2) -> void:
	var block := Frame.intro_block(vp)
	var title: Rect2 = block.title
	var subtitle: Rect2 = block.subtitle
	check(Frame.needs_reflow(vp), "reflow %s" % vp)
	check(Frame.inside(vp, Frame.skip_rect(vp)), "skip inside %s" % vp)
	check(Frame.inside(vp, Frame.back_rect(vp)), "back inside %s" % vp)
	check(Frame.inside(vp, Frame.location_rect(vp)), "location inside %s" % vp)
	check(Frame.inside(vp, Frame.dialogue_rect(vp)), "dialogue inside %s" % vp)
	check(Frame.inside(vp, Frame.stage_rect(vp)), "letterbox stage inside %s" % vp)
	check(Frame.inside(vp, title), "intro title inside %s" % vp)
	check(Frame.inside(vp, subtitle), "subtitle inside %s" % vp)
	check(Frame.title_clears_skip(vp), "title and location clear Skip %s" % vp)
	check(Frame.dialogue_rect(vp).size.x <= vp.x - 16.0, "dialogue fits width %s" % vp)
	var stage := Frame.stage_rect(vp)
	var aspect := stage.size.x / maxf(stage.size.y, 1.0)
	check(absf(aspect - 16.0 / 9.0) < 0.05, "stage is 16:9 %s (got %.3f)" % [vp, aspect])


func _init() -> void:
	# 390 CSS-px phone → HudOverlay virtual canvas ~600×1298 portrait, ~1298×600 landscape.
	for vp in [Vector2(600, 1298), Vector2(1298, 600), Vector2(390, 844), Vector2(844, 390), Vector2(360, 740)]:
		_assert_frame(vp)

	check(not Frame.needs_reflow(Vector2(1366, 768)), "desktop 1366 keeps authored cutscene")
	check(not Frame.needs_reflow(Vector2(1280, 720)), "1280 screenshot keeps authored cutscene")

	check(Chrome.PROTOTYPE_TEXT == "Prototype", "one small Prototype tag")
	check(not Chrome.PROTOTYPE_TEXT.contains("202"), "tag is not the build stamp")
	check(Chrome.FEEDBACK_TEXT == "Report Bugs and Share Feedback <3", "feedback copy unchanged")
	for vp in [Vector2(600, 1298), Vector2(390, 844), Vector2(1366, 768), Vector2(1280, 720), Vector2(360, 640)]:
		check(Chrome.tag_clears_feedback(vp), "Prototype clears feedback %s" % vp)
	check(Chrome.build_stamp_line("v0.1.0-prototype", "20261029-155849", "7d ago") == "v0.1.0-prototype | 20261029-155849 (7d ago)", "settings stamp keeps version and timestamp")
	check(Chrome.build_stamp_line("v0.1.0-prototype", "LOCAL", "") == "v0.1.0-prototype | Local Dev", "local stamp")

	var menu := FileAccess.get_file_as_string("res://scenes/main_menu/main_menu.tscn")
	check(not menu.contains("TitleGlow"), "ghost TitleGlow node removed")
	check(menu.contains("text = \"MINDSCAPE\""), "real menu title remains")
	check(menu.count("MINDSCAPE") == 1, "only one MINDSCAPE label on the menu")
	check(not menu.contains("v0.1.0 - Prototype"), "menu no longer has a second Prototype line")
	var menu_gd := FileAccess.get_file_as_string("res://scenes/main_menu/main_menu.gd")
	check(not menu_gd.contains("$CenterContainer/VBox/TitleContainer/TitleGlow"), "menu script does not require TitleGlow")

	var gm := FileAccess.get_file_as_string("res://autoload/GameManager.gd")
	check(gm.contains("tag.text = PhoneChrome.PROTOTYPE_TEXT"), "overlay tag is Prototype")
	check(gm.contains("\"Report Bugs and Share Feedback <3\""), "feedback button copy kept")
	check(not gm.contains("label.text = \"%s | %s\" % [VERSION, build_info]"), "build stamp removed from the overlay")
	var settings := FileAccess.get_file_as_string("res://scenes/settings/settings.gd")
	check(settings.contains("name = \"BuildStamp\""), "settings has the build stamp")
	check(settings.contains("PhoneChrome.build_stamp_line"), "settings uses the stamp line")

	check(load("res://scenes/cutscene/cutscene.gd") != null, "cutscene script compiles")
	check(load("res://scenes/settings/settings.gd") != null, "settings script compiles")
	check(load("res://scenes/main_menu/main_menu.gd") != null, "menu script compiles")

	var cutscene := FileAccess.get_file_as_string("res://scenes/cutscene/cutscene.gd")
	check(cutscene.contains("_apply_cutscene_frame"), "cutscene applies the phone frame")
	check(cutscene.contains("CutsceneFrame.intro_block"), "intro title uses the letterbox block")

	var html_path := ProjectSettings.globalize_path("res://").path_join("../build/web/index.html").simplify_path()
	var html := FileAccess.get_file_as_string(html_path)
	check(html.length() > 500, "read play-gate shell")
	var session_at := html.find("id=\"session-what\"")
	var wifi_at := html.find("id=\"wifi-hint\"")
	var load_at := html.find("id=\"load-size\"")
	check(session_at >= 0 and wifi_at > session_at and load_at > wifi_at, "session line, then Use Wi-Fi, then the 85 MB line")
	check(html.find("A session is a few quiet minutes of real focus.") > session_at, "session copy is in the session line")
	check(html.find("Use Wi-Fi") > wifi_at - 80 and html.find("Use Wi-Fi") < load_at, "Use Wi-Fi sits on the hint, before the download size")
	check(html.find("Loads about 85 MB the first time.") > load_at, "download size still says about 85 MB")
	check(html.find("Turn your phone sideways") >= 0, "portrait rotate hint copy")
	check(html.find("orientation: portrait") >= 0 and html.find("max-width: 500px") >= 0, "hint only in phone portrait")
	check(html.find("id=\"play-gate\"") >= 0 and html.find("id=\"play-btn\"") >= 0, "play-gate still present")
	check(html.find("loadScript('index.js')") >= 0, "WASM still loads only after Play")
	var quiet := FileAccess.get_file_as_string("res://scripts/ui/quiet_link.gd")
	check(quiet.contains("https://goacto.com/products/30-day-habit-builder-workbook"), "quiet workbook link unchanged")
	check(quiet.contains("($7)"), "quiet $7 copy unchanged")

	print("%d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)
