extends RefCounted
## In-game doors from the Mindscape hub to the other Team GOACTO apps (pure data plus a small builder).
## Nothing is sent to the other app; the door just opens its public page.

const DOORS := [
	{"id": "focus", "icon": "🚪", "label": "Focus Log", "host": "https://focus.goacto.com/"},
	{"id": "scriptlabos", "icon": "🚪", "label": "ScriptLabOS", "host": "https://scriptlabos.goacto.com/"},
]


static func door_url(id: String) -> String:
	for d in DOORS:
		if d.id == id:
			return d.host + "?utm_source=mindscape&utm_medium=app&utm_campaign=hub_door"
	return ""


## Adds a small "Doors" panel to the right edge of the given CanvasItem parent.
static func build(parent: Node, open_url: Callable) -> Control:
	var layer := CanvasLayer.new()
	layer.name = "AppDoors"
	layer.layer = 5
	var box := VBoxContainer.new()
	box.name = "DoorsBox"
	box.anchor_left = 1.0
	box.anchor_right = 1.0
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -230
	box.offset_right = -12
	box.offset_top = -90
	box.offset_bottom = 90
	box.add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = "Doors"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.8))
	box.add_child(title)
	for d in DOORS:
		var b := Button.new()
		b.name = "Door_" + d.id
		b.text = d.icon + " " + d.label
		b.tooltip_text = "Opens " + d.host.replace("https://", "").trim_suffix("/")
		b.add_theme_font_size_override("font_size", 22)
		b.custom_minimum_size = Vector2(218, 60)
		b.pressed.connect(func(): open_url.call(door_url(d.id)))
		box.add_child(b)
	layer.add_child(box)
	parent.add_child(layer)
	return box
