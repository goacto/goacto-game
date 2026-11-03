extends SceneTree
## Headless source/rule tests for Mindscape QoL + movement (design 2026-11-03).
## Run: godot --headless --path godot -s res://scripts/tests/test_qol_nov3.gd

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
	var kitchen := FileAccess.get_file_as_string("res://scenes/ship/kitchen.gd")
	var kitchen_tscn := FileAccess.get_file_as_string("res://scenes/ship/kitchen.tscn")
	var hud := FileAccess.get_file_as_string("res://autoload/HudOverlay.gd")
	var settings := FileAccess.get_file_as_string("res://scenes/settings/settings.gd")
	var cutscene := FileAccess.get_file_as_string("res://scenes/cutscene/cutscene.gd")
	var menu := FileAccess.get_file_as_string("res://scenes/main_menu/main_menu.gd")
	var menu_tscn := FileAccess.get_file_as_string("res://scenes/main_menu/main_menu.tscn")
	var controls := FileAccess.get_file_as_string("res://scripts/ui/controls_help.gd")
	var ping := FileAccess.get_file_as_string("res://../build/web/goacto-ping.js") if FileAccess.file_exists("res://../build/web/goacto-ping.js") else ""

	# 2.1 Movement — no auto Lumina lock on ready; deferred to Mom interact
	var first_lumina := kitchen.find("_show_dialogue(\"Dr. Lumina\"")
	var talk_idx := kitchen.find("func _talk_to_mom")
	check(talk_idx > 0 and first_lumina > talk_idx, "2.1 first Lumina dialogue is inside _talk_to_mom (deferred)")
	check(kitchen.contains("grab_focus()"), "2.1 grab_focus for web focus hardening")
	check(kitchen.contains("in_dialogue") and kitchen.contains("if in_dialogue:\n\t\treturn"), "2.1 movement still gated by in_dialogue when modal open")

	# 2.2 Controls hint + Settings Controls
	check(kitchen_tscn.contains("WASD / Arrows move") and kitchen_tscn.contains("E or SPACE"), "2.2 ControlHints MoveHint lists WASD and E/SPACE")
	check(kitchen.contains("_refresh_control_hints_visibility"), "2.2 hints not hidden solely by prompt")
	check(settings.contains("ControlsSection") and settings.contains("WASD / Arrow keys"), "2.2 Settings Controls section with WASD")
	check(kitchen.contains("ControlsButton") and kitchen.contains("_open_controls_from_pause"), "2.2 pause menu Controls button")
	check(controls.contains("WASD") and controls.contains("SPACE"), "2.2 shared ControlsHelp copy")

	# 2.3 Nearest highlight + NPC priority
	check(kitchen.contains("ProximityHighlight") and kitchen.contains("NPC_PRIORITY"), "2.3 proximity highlight + NPC priority")
	check(kitchen.contains("\"Mom\": 40") or kitchen.contains("'Mom': 40") or kitchen.contains("\"Mom\": 40.0"), "2.3 Mom has priority over Table")

	# 2.4 Dialogue truncation
	check(kitchen_tscn.contains("custom_minimum_size = Vector2(0, 120)") or kitchen.contains("custom_minimum_size = Vector2(0, 120)"), "2.4 dialogue text min height")
	check(kitchen.contains("clip_text = false") or kitchen_tscn.contains("clip_text = false"), "2.4 dialogue does not clip_text")
	check(kitchen.contains("your father stored"), "2.4 Lumina go-find string still includes 'your father'")

	# 2.5 Faster intro / hold-FF
	check(cutscene.contains("Hold to skip") or cutscene.contains("_update_hold_skip_chip"), "2.5 hold-to-FF chip")
	check(cutscene.contains("holding_ff") or cutscene.contains("Hold SPACE"), "2.5 hold accelerates typing")
	# Dead-air cap: intro hold intervals should not be 2.0s anymore in title sequence
	check(not cutscene.contains("# Hold for dramatic effect (2 seconds)"), "2.5 dramatic 2s hold comment removed/capped")
	check(cutscene.contains("tween.tween_interval(0.4)"), "2.5 intro intervals capped to 0.4s")

	# 2.6 Menus
	check(not menu_tscn.contains("TitleGlow"), "2.6 TitleGlow duplicate removed from main_menu.tscn")
	check(menu.contains("continue_button.disabled = not has_save"), "2.6 Continue reserved in layout via disabled, not removed")
	check(cutscene.contains("PRESET_CENTER") and cutscene.contains("SkipConfirm"), "2.6 skip confirm centered with anchors")

	# 2.7 Save in pause + toast
	check(kitchen.contains("SaveButton") and kitchen.contains("_pause_save"), "2.7 pause Save button")
	check(kitchen.contains("Saved!") and kitchen.contains("_show_saved_toast"), "2.7 Saved! toast")
	check(kitchen.contains("AutoSaveNote") or kitchen.contains("auto-saves on your device"), "2.7 auto-save note in pause")
	check(kitchen.contains("SaveManager.save_game()"), "2.7 uses existing SaveManager (local)")

	# 2.8 Objective pill
	check(hud.contains("ObjectivePill") and hud.contains("StyleBoxFlat"), "2.8 objective pill panel behind label")
	check(hud.contains("font_size\", 17)"), "2.8 larger objective font")

	# COPPA: no new network in kitchen/hud/settings for this work — ping file unchanged pattern
	check(not kitchen.contains("HTTPRequest") and not kitchen.contains("siagentspace.com/api"), "COPPA kitchen adds no network")
	check(not hud.contains("HTTPRequest"), "COPPA HudOverlay adds no network")

	print("\n%d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)
