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
	if vp.y > vp.x:
		var ideal_y := (vp.y - stage.size.y) * 0.5
		check(absf(stage.position.y - ideal_y) <= 1.5, "letterbox vertically centered %s (y %.1f, ideal %.1f)" % [vp, stage.position.y, ideal_y])
		check(stage.has_point(title.get_center()), "title sits in the centered letterbox %s" % vp)


## HTML #rotate-hint at 390×844, mapped into a viewport that fills that window.
## top 10px, padding 8px, one 0.85rem line at 1.2, side gutters of 100px
## (max-width: calc(100vw - 200px)).
func _rotate_hint_rect(viewport: Vector2, css: Vector2) -> Rect2:
	var scale := Vector2(viewport.x / css.x, viewport.y / css.y)
	var top := 10.0 * scale.y
	var height := (8.0 + 8.0 + 0.85 * 16.0 * 1.2) * scale.y
	var gutter := 100.0 * scale.x
	var w := viewport.x - gutter * 2.0
	return Rect2((viewport.x - w) * 0.5, top, w, height)


func _assert_pill_clears_intro(viewport: Vector2, css: Vector2) -> void:
	var hint := _rotate_hint_rect(viewport, css)
	var stage := Frame.stage_rect(viewport)
	# AntennaLight is local (0, -68) and its diamond tip is 4px further up.
	var antenna_tip_y := stage.get_center().y - 72.0 * Frame.ship_scale(viewport)
	check(stage.position.y >= hint.end.y, "letterbox starts below the rotate pill %s (stage %.1f pill %.1f)" % [viewport, stage.position.y, hint.end.y])
	check(antenna_tip_y >= hint.end.y + 8.0, "ship antenna clears the rotate pill %s (tip %.1f pill %.1f)" % [viewport, antenna_tip_y, hint.end.y])
	check(not hint.intersects(Frame.back_rect(viewport)), "rotate pill clears Back %s" % viewport)
	check(not hint.intersects(Frame.skip_rect(viewport)), "rotate pill clears Skip %s" % viewport)
	check(absf(hint.get_center().x - viewport.x * 0.5) <= 1.0, "rotate pill stays horizontally centered %s" % viewport)


func _init() -> void:
	# 390 CSS-px phone → HudOverlay virtual canvas ~600×1298 portrait, ~1298×600 landscape.
	# Without that rescale, stretch aspect expand keeps width 1366 and grows height.
	var css_phone := Vector2(390, 844)
	var phone_canvas := Vector2(600, round(css_phone.y * 600.0 / css_phone.x))
	var expanded := Vector2(1366, 1366.0 * css_phone.y / css_phone.x)
	for vp in [phone_canvas, Vector2(1298, 600), Vector2(390, 844), Vector2(844, 390), Vector2(360, 740), expanded]:
		_assert_frame(vp)
	_assert_pill_clears_intro(phone_canvas, css_phone)
	_assert_pill_clears_intro(expanded, css_phone)

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
	check(html.find("top: 10px") >= 0 and html.find("left: 50%") >= 0, "rotate pill stays top center")
	check(html.find("max-width: calc(100vw - 200px)") >= 0, "rotate pill keeps side gutters for Back and Skip")
	check(html.find("padding: 8px 12px") >= 0, "rotate pill padding matches the clearance test")
	check(html.find("id=\"play-gate\"") >= 0 and html.find("id=\"play-btn\"") >= 0, "play-gate still present")
	check(html.find("loadScript('index.js')") >= 0, "WASM still loads only after Play")
	var quiet := FileAccess.get_file_as_string("res://scripts/ui/quiet_link.gd")
	check(quiet.contains("https://goacto.com/products/30-day-habit-builder-workbook"), "quiet workbook link unchanged")
	check(quiet.contains("($7)"), "quiet $7 copy unchanged")

	print("%d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)
