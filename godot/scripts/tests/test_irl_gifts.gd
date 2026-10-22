extends SceneTree
## Headless tests for the IRL Gifts catalog + GIFT_CODES_ENABLED flag.
## Run: godot --headless --path godot -s res://scripts/tests/test_irl_gifts.gd

const G := preload("res://scripts/shop/irl_gifts.gd")
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
	check(G.GIFT_CODES_ENABLED == false, "codes flag ships off")
	var off := G.gifts()
	var all_off := str(off) + G.intro_text() + G.footer_text()
	check(off.size() == 2, "two gifts: sticker pack + journal")
	for code in ["FOCUS10", "FOCUS25", "FOCUS50", "FOCUS100"]:
		check(not all_off.contains(code), "no %s when hidden" % code)
	for g in off:
		check(not g.has("discount"), "%s has no discount when hidden" % g.id)
		check(str(g.url).begins_with("https://goacto.com/"), "%s links to goacto.com" % g.id)
	var lower := all_off.to_lower()
	for phrase in ["use this code", "discount", "unlock", "redeem", "art print", "desk figure", "poster", "figure"]:
		check(not lower.contains(phrase), "no '%s' copy when hidden" % phrase)
	check(G.PICKS_URL == "https://goacto.com/collections/goacto-picks", "picks collection link kept")

	var on := G.gifts(true)
	check(on[0].discount == "FOCUS10" and on[1].discount == "FOCUS25", "codes come back when enabled")
	check(not str(on).contains("FOCUS50") and not str(on).contains("FOCUS100"), "FOCUS50/100 removed entirely")
	check(G.intro_text(true).contains("discount codes"), "enabled intro mentions codes")

	print("%d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)
