extends SceneTree
## Headless tests for MilestoneShare (RM-B6).
## Run: godot --headless --path godot -s res://scripts/tests/test_milestone_share.gd

const MS := preload("res://scripts/share/milestone_share.gd")
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
	var ach := {"id": "focus_10", "name": "Getting Focused", "description": "Complete 10 focus sessions", "icon": "🎯", "xp_reward": 30}
	var before := ach.duplicate(true)
	var c := MS.card_for_achievement(ach)
	check(c.title == "Getting Focused" and c.mark == "🎯" and c.footer == "GOACTO · Mindscape", "achievement card fields")
	check(ach == before, "source achievement not mutated")
	check(not c.has("journal"), "no journal text by default")

	var ch := MS.card_for_chapter({"id": "chapter_1", "name": "First Contact", "description": "secret"})
	check(ch.subtitle == "First Contact" and ch.title == "Chapter complete", "chapter card uses chapter name")
	check(not str(ch).contains("secret"), "chapter card has no description/body text")

	var j0 := MS.with_journal(c, "my private thoughts", false)
	check(not j0.has("journal"), "journal excluded without opt-in")
	var long := "x".repeat(400)
	var j1 := MS.with_journal(c, long + "\nmore", true)
	check(j1.has("journal") and j1.journal.length() == MS.JOURNAL_MAX and not j1.journal.contains("\n"), "opt-in journal capped + single line")
	check(not c.has("journal"), "with_journal returns a copy")

	check(MS.should_offer_now(false) and not MS.should_offer_now(true), "never offered in Focus Mode")
	check(MS.share_filename({"id": "Focus 10!"}) == "goacto-mindscape-focus-10-.png", "safe filename")

	var js := MS.share_js("QUJD", "a'b.png", "T\"</script>")
	check(js.contains("navigator.share") and js.contains(JSON.stringify("a'b.png")) and js.contains(JSON.stringify("T\"</script>")), "share js escapes args via JSON")
	check(not js.contains("fetch(") and not js.contains("XMLHttpRequest"), "no network calls in share js")

	print("\nmilestone_share: %d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)
