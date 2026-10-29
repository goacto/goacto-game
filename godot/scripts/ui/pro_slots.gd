extends RefCounted
## Extra save slots shown as a Pro preview. No payment, no purchase flow, no account.
## Slots 1-3 stay free. Slots 4-6 are usable in this preview so we can test the feature.
## Saves stay on this device (user://).

const FREE_SLOTS := 3
const PRO_PREVIEW_SLOTS := 3
const HEADER := "✨ Extra slots (Pro preview)"
const CAPTION := "Slots 4 to 6 are a Pro preview. They're free while we test, and no payment is set up."


static func total() -> int:
	return FREE_SLOTS + PRO_PREVIEW_SLOTS


static func is_pro(slot: int) -> bool:
	return slot > FREE_SLOTS and slot <= total()


## Adds the header and caption to a VBox before the Pro preview rows.
static func add_header(vbox: Node) -> void:
	var h := Label.new()
	h.name = "ProSlotsHeader"
	h.text = HEADER
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_size_override("font_size", 14)
	h.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	vbox.add_child(h)
	var c := Label.new()
	c.text = CAPTION
	c.autowrap_mode = TextServer.AUTOWRAP_WORD
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.custom_minimum_size = Vector2(280, 0)
	c.add_theme_font_size_override("font_size", 12)
	c.add_theme_color_override("font_color", Color(0.55, 0.58, 0.62))
	vbox.add_child(c)
