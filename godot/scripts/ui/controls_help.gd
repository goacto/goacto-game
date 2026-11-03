extends RefCounted
## Shared keyboard + touch controls copy for Settings and pause menu.

static func keyboard_and_touch_text() -> String:
	return (
		"Keyboard\n"
		+ "• WASD / Arrow keys — move\n"
		+ "• E or SPACE — interact / continue\n"
		+ "• ESC — pause menu\n"
		+ "• Click does not walk — use WASD to reach distant doors\n"
		+ "\n"
		+ "Touch\n"
		+ "• On-screen D-pad — move\n"
		+ "• Tap Interact — talk / examine\n"
	)


static func short_hint() -> String:
	return "WASD / Arrows move · E or SPACE interact · ESC menu"
