extends SceneTree
## Run: godot --headless --path godot -s res://scripts/tests/test_pro_slots.gd
const P := preload("res://scripts/ui/pro_slots.gd")
var fails := 0
var passes := 0
func check(c: bool, n: String) -> void:
	if c: passes += 1; print("  PASS ", n)
	else: fails += 1; print("  FAIL ", n)
func _init() -> void:
	check(P.total() == 6, "6 slots total")
	check(not P.is_pro(1) and not P.is_pro(3), "slots 1-3 are free")
	check(P.is_pro(4) and P.is_pro(6) and not P.is_pro(7), "slots 4-6 are Pro preview")
	var sm := FileAccess.get_file_as_string("res://autoload/SaveManager.gd")
	check(sm.contains("const NUM_SAVE_SLOTS = 6"), "SaveManager allows 6 slots")
	var src := FileAccess.get_file_as_string("res://scripts/ui/pro_slots.gd")
	for bad in ["$", "stripe", "checkout", "purchase(", "http", " & "]:
		check(not src.to_lower().contains(bad), "no payment wiring or price: %s" % bad)
	check(P.CAPTION.contains("no payment is set up"), "caption says no payment")
	for f in ["res://scenes/main_menu/main_menu.gd", "res://scenes/bedroom/bedroom.gd"]:
		check(FileAccess.get_file_as_string(f).contains("ProSlots.add_header(vbox)"), "%s shows Pro preview header" % f.get_file())
	var v := VBoxContainer.new()
	P.add_header(v)
	check(v.get_child_count() == 2 and (v.get_child(0) as Label).text == P.HEADER, "header builds")
	v.free()
	print("%d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)
