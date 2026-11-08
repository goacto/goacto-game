extends RefCounted
## One quiet line on the focus-session summary, the first time a session ends.
## Says when to come back and what day 2 already holds.
## No streak guilt, no "at risk", no push, no email.


const WHEN := "Come back tomorrow."
const WHAT := "Day 2 is waiting with %d XP."


## Sessions already saved. Zero means this ending session is the first.
static func should_show(sessions_already_completed: int) -> bool:
	return sessions_already_completed == 0


static func day_two_xp(rewards: Array) -> int:
	for reward in rewards:
		if typeof(reward) != TYPE_DICTIONARY:
			continue
		if int(reward.get("day", -1)) == 2:
			return int(reward.get("amount", 0))
	return 0


static func text(day_two_xp_amount: int) -> String:
	return WHEN + " " + (WHAT % day_two_xp_amount)


## Small, muted, not a button and not a link.
static func make(day_two_xp_amount: int) -> Label:
	var label := Label.new()
	label.name = "QuietReturnLine"
	label.text = text(day_two_xp_amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2(380, 0)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label
