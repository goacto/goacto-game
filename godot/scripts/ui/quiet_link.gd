extends RefCounted
## One quiet link after a Focus Chamber session (no pop-up). Pure data, testable headless.
## URL read from the live goacto.com store (products/30-day-habit-builder-workbook, $7) on Oct 29, 2026.

const WORKBOOK_URL := "https://goacto.com/products/30-day-habit-builder-workbook"
const TEXT := "Want a next step? The 30-Day Habit Builder workbook ($7)"


static func url() -> String:
	return WORKBOOK_URL + "?utm_source=mindscape&utm_medium=app&utm_campaign=focus_complete"


## Small, underlined, low-contrast link. Opens in a new tab; nothing pops up.
static func make() -> LinkButton:
	var link := LinkButton.new()
	link.name = "QuietWorkbookLink"
	link.text = TEXT
	link.uri = url()
	link.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	link.add_theme_font_size_override("font_size", 14)
	link.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	link.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return link
