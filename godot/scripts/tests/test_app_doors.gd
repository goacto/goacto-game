extends SceneTree
## Run: godot --headless --path godot -s res://scripts/tests/test_app_doors.gd
const D := preload("res://scripts/ui/app_doors.gd")
var fails := 0
var passes := 0
func check(c: bool, n: String) -> void:
	if c: passes += 1; print("  PASS ", n)
	else: fails += 1; print("  FAIL ", n)
func _init() -> void:
	check(D.door_url("focus").begins_with("https://focus.goacto.com/?"), "focus door url")
	check(D.door_url("scriptlabos").begins_with("https://scriptlabos.goacto.com/?"), "scriptlabos door url")
	check(D.door_url("focus").contains("utm_source=mindscape"), "utm tagged")
	check(D.door_url("nope") == "", "unknown door is empty")
	var opened := []
	var host := Node.new()
	var box: Control = D.build(host, func(u): opened.append(u))
	check(box.get_child_count() == 3, "title plus two doors")
	(box.get_node("Door_focus") as Button).pressed.emit()
	(box.get_node("Door_scriptlabos") as Button).pressed.emit()
	check(opened == [D.door_url("focus"), D.door_url("scriptlabos")], "doors open their urls")
	host.free()
	var hub := FileAccess.get_file_as_string("res://scenes/mindscape/mindscape_hub.gd")
	check(hub.contains("AppDoors.build(self"), "hub builds the doors")
	print("%d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)
