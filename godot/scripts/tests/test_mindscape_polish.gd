extends SceneTree
## Headless tests for the Mindscape polish pass (emoji font, Aspect label, footer copy, phone fit).
## Run: godot --headless --path godot -s res://scripts/tests/test_mindscape_polish.gd

const AspectLabel := preload("res://scripts/ui/aspect_label.gd")
const FitViewport := preload("res://scripts/ui/fit_viewport.gd")
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
	var gm_src := FileAccess.get_file_as_string("res://autoload/GameManager.gd")
	# GameManager is an autoload (not loadable under -s), so read its ASPECTS table from source.
	var aspects := {}
	var re := RegEx.new()
	re.compile("\"(\\w+)\": \\{\\s*\"name\": \"(\\w+)\",\\s*\"domain\": \"(\\w+)\"")
	for m in re.search_all(gm_src):
		aspects[m.get_string(1)] = {"name": m.get_string(2), "domain": m.get_string(3)}
	check(aspects.size() == 6, "six Aspects defined")
	check(AspectLabel.display_name("productivity", aspects) == "Discipline", "productivity domain -> Discipline")
	check(AspectLabel.display_name("health", aspects) == "Vitality", "health domain -> Vitality")
	check(AspectLabel.display_name("mindfulness", aspects) == "Wisdom", "mindfulness domain -> Wisdom")
	check(AspectLabel.display_name("learning", aspects) == "Creativity", "learning domain -> Creativity")
	check(AspectLabel.display_name("social", aspects) == "Compassion", "social domain -> Compassion")
	check(AspectLabel.display_name("growth", aspects) == "Courage", "growth domain -> Courage")
	check(AspectLabel.display_name("wisdom", aspects) == "Wisdom", "aspect id passes through")
	check(AspectLabel.display_name("custom", aspects) == "Discipline", "unknown -> Discipline fallback")
	var names := []
	for k in aspects:
		names.append(aspects[k].name)
	for key in ["productivity", "health", "mindfulness", "learning", "social", "growth", "custom", "", "wisdom"]:
		check(AspectLabel.display_name(key, aspects) in names, "'%s' always names a real Aspect" % key)

	check(gm_src.contains("\"Report Bugs and Share Feedback <3\"") and not gm_src.contains("Report Bugs & Share"), "footer says 'and', not '&'")

	var EmojiFont := load("res://scripts/ui/emoji_font.gd")
	var builtin := ThemeDB.fallback_font
	var font := EmojiFont.font() as Font
	var emoji_fb: FontFile = null
	for fb in font.fallbacks:
		if fb is FontFile and fb.resource_path.contains("NotoColorEmoji"):
			emoji_fb = fb
	check(emoji_fb != null, "default font falls back to bundled emoji font (web has no system fonts)")
	check(font is FontVariation and (font as FontVariation).base_font == builtin, "base glyphs unchanged (built-in font is the base)")
	check(EmojiFont.font() == font, "install is idempotent")
	check(ThemeDB.get_default_theme().default_font == font, "default theme font is the emoji-capable font")
	var probe := Label.new()
	check(probe.get_theme_font("font") == font, "a plain Label resolves to the emoji-capable font")
	probe.free()
	if emoji_fb:
		for ch in ["🎯", "🌱", "🔥", "🏆", "✨", "🔊", "🔇"]:
			check(emoji_fb.has_char(ch.unicode_at(0)), "bundled emoji font has %s" % ch)
	check(FileAccess.get_file_as_string("res://assets/fonts/NotoColorEmoji-subset.ttf.import").contains("disable_embedded_bitmaps=false"), "emoji import keeps embedded color bitmaps (CBDT)")
	var ms_src := FileAccess.get_file_as_string("res://autoload/MilestoneShareManager.gd")
	check(ms_src.contains("EmojiFont.font()"), "share-card renderer uses the emoji font")
	check(FileAccess.get_file_as_string("res://autoload/ThemeConfig.gd").contains("EmojiFont.install()"), "theme installs the emoji font at startup")

	check(FitViewport.fitted_size(Vector2(680, 800), Vector2(1366, 768)) == Vector2(680, 748), "desktop: width kept, height clamped")
	check(FitViewport.fitted_size(Vector2(680, 800), Vector2(600, 1298)) == Vector2(580, 800), "390 phone canvas: width clamped to screen")
	check(FitViewport.fitted_size(Vector2(520, 400), Vector2(600, 1298)) == Vector2(520, 400), "small dialog unchanged on phone")

	print("\n%d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)
