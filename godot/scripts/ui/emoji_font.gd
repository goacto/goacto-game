extends RefCounted
## EmojiFont: adds a bundled color-emoji fallback to the game's default font.
## Web builds have no system fonts, so Godot's built-in font drew every emoji as a boxed
## hex code (e.g. "01F3AF") in the HUD, milestone pedestals/pop-up and share cards.
## The bundled file is a subset of Noto Color Emoji (OFL 1.1, see OFL-NotoColorEmoji.txt)
## holding the emoji the game uses plus common extras.

const EMOJI_FONT_PATH := "res://assets/fonts/NotoColorEmoji-subset.ttf"


## Default font + emoji fallback. The base glyphs/look are unchanged.
static func with_emoji(base: Font) -> Font:
	var emoji := load(EMOJI_FONT_PATH) as FontFile
	if base == null or emoji == null:
		return base
	var v := FontVariation.new()
	v.base_font = base
	var fb: Array[Font] = []
	fb.append_array(base.fallbacks)
	fb.append(emoji)
	v.fallbacks = fb
	return v


## Install once, before the first Control is drawn (called from the ThemeConfig autoload).
static func install() -> void:
	var current := ThemeDB.fallback_font
	if current is FontVariation and current.resource_name == "GoactoEmojiFallback":
		return
	var f := with_emoji(current)
	if f == current:
		return
	f.resource_name = "GoactoEmojiFallback"
	ThemeDB.fallback_font = f
	# Controls resolve fonts through the default theme first, which holds the built-in font.
	var theme := ThemeDB.get_default_theme()
	if theme:
		theme.default_font = f


## The emoji-capable default font (installs it if needed). The share-card renderer sets this
## explicitly so a card never depends on autoload order.
static func font() -> Font:
	install()
	return ThemeDB.fallback_font
