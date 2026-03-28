extends Node
## ThemeConfig - GOACTO Brand Colors and Theme Constants
## "Growing Ourselves And Contributing To Others"

# ============ PRIMARY BRAND COLORS ============
# From GOACTO logo
const GOACTO_CHARCOAL = Color(0.24, 0.24, 0.24)        # #3D3D3D - Primary text/dark elements
const GOACTO_GOLD = Color(0.83, 0.66, 0.29)            # #D4A84B - Lightning bolt accent
const GOACTO_GOLD_BRIGHT = Color(0.92, 0.75, 0.35)    # #EBC059 - Highlighted gold
const GOACTO_GOLD_DARK = Color(0.65, 0.52, 0.22)      # #A68438 - Pressed/darker gold

# ============ BACKGROUND COLORS ============
const BG_DEEP_SPACE = Color(0.04, 0.05, 0.08)          # #0A0D14 - Darkest background
const BG_SPACE = Color(0.06, 0.07, 0.10)               # #0F1219 - Main background
const BG_NEBULA = Color(0.08, 0.09, 0.14)              # #14172A - Elevated surfaces
const BG_PANEL = Color(0.10, 0.12, 0.18)               # #1A1F2E - Panel backgrounds
const BG_CARD = Color(0.12, 0.14, 0.20)                # #1F2433 - Card backgrounds

# ============ ACCENT COLORS ============
# Zone-specific accents (keeping some existing but harmonizing with gold)
const ACCENT_FOCUS = Color(0.25, 0.55, 0.40)           # Green - Focus Chamber
const ACCENT_JOURNAL = Color(0.30, 0.45, 0.65)         # Blue - Reflection Pool
const ACCENT_ASPECTS = Color(0.55, 0.35, 0.65)         # Purple - Aspect Shrine
const ACCENT_GOALS = Color(0.83, 0.66, 0.29)           # Gold - Goal Compass (brand color)
const ACCENT_HABITS = Color(0.40, 0.65, 0.50)          # Teal - Daily Rituals
const ACCENT_ARENA = Color(0.70, 0.30, 0.30)           # Red - Training Arena
const ACCENT_SCRIPTS = Color(0.55, 0.45, 0.35)         # Bronze - Script Lab

# ============ TEXT COLORS ============
const TEXT_PRIMARY = Color(0.92, 0.92, 0.94)           # Almost white
const TEXT_SECONDARY = Color(0.65, 0.67, 0.72)         # Muted
const TEXT_TERTIARY = Color(0.45, 0.47, 0.52)          # Very muted
const TEXT_GOLD = Color(0.83, 0.66, 0.29)              # Gold accent text
const TEXT_SUCCESS = Color(0.45, 0.75, 0.55)           # Green success
const TEXT_WARNING = Color(0.85, 0.65, 0.30)           # Orange warning
const TEXT_ERROR = Color(0.80, 0.35, 0.35)             # Red error

# ============ UI ELEMENT COLORS ============
const BUTTON_DEFAULT = Color(0.15, 0.17, 0.22)         # Default button bg
const BUTTON_HOVER = Color(0.20, 0.22, 0.28)           # Hovered button
const BUTTON_PRESSED = Color(0.12, 0.14, 0.18)         # Pressed button
const BUTTON_GOLD = Color(0.83, 0.66, 0.29)            # Gold CTA button
const BUTTON_GOLD_HOVER = Color(0.92, 0.75, 0.35)      # Gold hover
const BUTTON_GOLD_PRESSED = Color(0.65, 0.52, 0.22)    # Gold pressed

const BORDER_DEFAULT = Color(0.20, 0.22, 0.28)         # Default borders
const BORDER_GOLD = Color(0.83, 0.66, 0.29, 0.5)       # Gold accent border
const BORDER_HIGHLIGHT = Color(0.83, 0.66, 0.29, 0.8)  # Strong gold border

# ============ PROGRESS & STATUS ============
const PROGRESS_BG = Color(0.15, 0.17, 0.22)            # Progress bar background
const PROGRESS_FILL = Color(0.83, 0.66, 0.29)          # Progress bar fill (gold)
const PROGRESS_XP = Color(0.50, 0.70, 0.90)            # XP progress (blue)

# ============ ASPECT COLORS ============
# These tie into the story - each aspect has a signature color
const ASPECT_DISCIPLINE = Color(0.83, 0.66, 0.29)      # Gold - primary brand tie
const ASPECT_COURAGE = Color(0.75, 0.40, 0.35)         # Crimson
const ASPECT_CREATIVITY = Color(0.55, 0.45, 0.75)      # Violet
const ASPECT_COMPASSION = Color(0.45, 0.70, 0.60)      # Teal
const ASPECT_WISDOM = Color(0.40, 0.55, 0.80)          # Azure
const ASPECT_VITALITY = Color(0.50, 0.75, 0.45)        # Lime

# ============ CAMPAIGN CHAPTER COLORS ============
const CHAPTER_LOCKED = Color(0.25, 0.25, 0.28)         # Locked chapters
const CHAPTER_AVAILABLE = Color(0.83, 0.66, 0.29)      # Available to play
const CHAPTER_COMPLETE = Color(0.45, 0.75, 0.55)       # Completed chapters
const CHAPTER_CURRENT = Color(0.92, 0.75, 0.35)        # Currently active

# ============ GLOW & EFFECTS ============
const GLOW_GOLD = Color(0.83, 0.66, 0.29, 0.4)         # Gold glow effect
const GLOW_SUCCESS = Color(0.45, 0.75, 0.55, 0.4)      # Success glow
const GLOW_ENERGY = Color(0.50, 0.70, 0.90, 0.4)       # Energy/XP glow


# ============ HELPER FUNCTIONS ============

## Get zone accent color by zone ID
static func get_zone_color(zone_id: String) -> Color:
	match zone_id:
		"FocusChamber": return ACCENT_FOCUS
		"ReflectionPool": return ACCENT_JOURNAL
		"AspectShrine": return ACCENT_ASPECTS
		"GoalCompass": return ACCENT_GOALS
		"DailyRituals": return ACCENT_HABITS
		"TrainingArena": return ACCENT_ARENA
		"ScriptLab": return ACCENT_SCRIPTS
		_: return GOACTO_GOLD


## Get aspect color by aspect key
static func get_aspect_color(aspect_key: String) -> Color:
	match aspect_key:
		"discipline": return ASPECT_DISCIPLINE
		"courage": return ASPECT_COURAGE
		"creativity": return ASPECT_CREATIVITY
		"compassion": return ASPECT_COMPASSION
		"wisdom": return ASPECT_WISDOM
		"vitality": return ASPECT_VITALITY
		_: return GOACTO_GOLD


## Get chapter status color
static func get_chapter_color(status: String) -> Color:
	match status:
		"locked": return CHAPTER_LOCKED
		"available": return CHAPTER_AVAILABLE
		"complete": return CHAPTER_COMPLETE
		"current": return CHAPTER_CURRENT
		_: return CHAPTER_LOCKED


## Lighten a color
static func lighten(color: Color, amount: float = 0.1) -> Color:
	return color.lightened(amount)


## Darken a color
static func darken(color: Color, amount: float = 0.1) -> Color:
	return color.darkened(amount)


## Add transparency to a color
static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


# =============================================================================
# ACCESSIBILITY HELPERS
# =============================================================================

## Apply accessibility attributes to a button
static func make_accessible(control: Control, description: String) -> void:
	control.tooltip_text = description
	if control is Button:
		control.focus_mode = Control.FOCUS_ALL
		control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## Apply accessibility to a group of buttons in a container
static func make_container_accessible(container: Control) -> void:
	for child in container.get_children():
		if child is Button and child.tooltip_text == "":
			child.tooltip_text = child.text
			child.focus_mode = Control.FOCUS_ALL
			child.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if child is Container:
			make_container_accessible(child)


# =============================================================================
# GAMEPLAY CONSTANTS
# =============================================================================
# Centralized values used across multiple scenes

# Player movement
const PLAYER_SPEED_DEFAULT: float = 250.0
const PLAYER_SPEED_BEDROOM: float = 280.0
const MOVE_SOUND_INTERVAL: float = 0.35
const MOVE_SOUND_PATH: String = "res://audio/sfx/hover_move.wav"
const MOVE_SOUND_VOLUME: float = -12.0

# Camera
const CAMERA_ZOOM_DEFAULT: float = 1.0
const CAMERA_ZOOM_BEDROOM: float = 0.85
const CAMERA_ZOOM_MIN: float = 0.5
const CAMERA_ZOOM_MAX: float = 1.5
const CAMERA_ZOOM_SPEED: float = 0.08

# Interaction
const INTERACTION_RADIUS: float = 100.0
const INTERACTION_RADIUS_MINDSCAPE: float = 120.0

# Focus sessions
const FOCUS_DURATIONS: Array = [15, 25, 45, 60]
const DEFAULT_FOCUS_MINUTES: int = 25
const XP_PER_MINUTE: int = 2
const DIFFICULTY_MULTIPLIER_STANDARD: float = 0.7
const DIFFICULTY_MULTIPLIER_HARD: float = 1.5

# Streaks
const MAX_GRACE_DAYS: int = 3
const GRACE_DAY_EARN_INTERVAL: int = 7  # Days of streak to earn 1 grace day

# UI Animation
const FADE_DURATION_FAST: float = 0.2
const FADE_DURATION_NORMAL: float = 0.3
const FADE_DURATION_SLOW: float = 0.8
const TYPING_SPEED: float = 0.025  # Seconds per character for typewriter effect

# Companion
const COMPANION_TIP_COOLDOWN: float = 120.0  # Seconds between tips
