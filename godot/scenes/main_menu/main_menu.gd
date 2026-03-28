extends Control
## MainMenu - Entry point for the game
## Handles new game, continue, onboarding, and settings

# Main menu UI - updated paths for CenterContainer layout
@onready var main_vbox: VBoxContainer = $CenterContainer/VBox
@onready var start_button: Button = $CenterContainer/VBox/ButtonContainer/StartButton
@onready var continue_button: Button = $CenterContainer/VBox/ButtonContainer/ContinueButton
@onready var load_button: Button = $CenterContainer/VBox/ButtonContainer/LoadButton
@onready var settings_button: Button = $CenterContainer/VBox/ButtonContainer/SettingsButton

# Audio controls
@onready var mute_button: Button = $AudioControls/MuteButton
@onready var volume_slider: HSlider = $AudioControls/VolumeSlider

# Visual effects
@onready var stars_container: Control = $StarsContainer
@onready var glow_orb: Control = $GlowOrb
@onready var title_glow: Label = $CenterContainer/VBox/TitleContainer/TitleGlow

# Load game panel
var load_panel: PanelContainer = null

# Onboarding
@onready var onboarding_panel: PanelContainer = $OnboardingPanel
@onready var slide_title: Label = $OnboardingPanel/Margin/VBox/SlideContent/SlideTitle
@onready var slide_text: Label = $OnboardingPanel/Margin/VBox/SlideContent/SlideText
@onready var slide_icon_container: ColorRect = $OnboardingPanel/Margin/VBox/SlideContent/SlideIcon
var slide_icon_canvas: Node2D = null
@onready var page_indicator: HBoxContainer = $OnboardingPanel/Margin/VBox/PageIndicator
@onready var back_button: Button = $OnboardingPanel/Margin/VBox/ButtonRow/BackButton
@onready var skip_button: Button = $OnboardingPanel/Margin/VBox/ButtonRow/SkipButton
@onready var next_button: Button = $OnboardingPanel/Margin/VBox/ButtonRow/NextButton

var current_slide: int = 0
var is_new_player: bool = false
var current_voice_player: AudioStreamPlayer = null

# Animation state
var anim_time: float = 0.0
var stars: Array = []
const NUM_STARS: int = 80

# Onboarding slide content
var onboarding_slides: Array = [
	{
		"title": "Your Personal Sanctuary",
		"text": "This is your inner world - a place that grows and evolves as you do.\n\nEvery real-world action you take transforms this space into something beautiful.",
		"color": Color(0.3, 0.5, 0.7),
		"voice": "res://audio/voice/onboarding/slide_0.ogg"
	},
	{
		"title": "Focus Sessions",
		"text": "Enter the Focus Chamber to start 25-minute deep work sessions.\n\nPut your phone aside and do real work. When you return, reflect on what you learned and accomplished.",
		"color": Color(0.4, 0.6, 0.5),
		"voice": "res://audio/voice/onboarding/slide_1.ogg"
	},
	{
		"title": "Your Six Aspects",
		"text": "Discipline, Courage, Creativity, Compassion, Wisdom, and Vitality - these Aspects represent parts of yourself.\n\nThey grow stronger as you build habits in their domains.",
		"color": Color(0.6, 0.4, 0.7),
		"voice": "res://audio/voice/onboarding/slide_2.ogg"
	},
	{
		"title": "Code Your Life",
		"text": "In the Script Lab, you write your own Personal Operating System.\n\nCreate scripts with 25 lines of code - each line is one minute of focused action. Run them to level up.",
		"color": Color(0.7, 0.5, 0.3),
		"voice": "res://audio/voice/onboarding/slide_3.ogg"
	}
]


func _ready() -> void:
	# Stop any playing voice from previous scene
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()

	# Check if save exists
	var has_save = SaveManager.has_save()
	continue_button.visible = has_save

	# Load button is always visible (for importing saves)
	load_button.visible = true

	# For new players, show "Begin Journey" text
	if has_save:
		start_button.text = "New Journey"
	else:
		start_button.text = "Begin Journey"
		is_new_player = true

	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	back_button.pressed.connect(_prev_slide)
	skip_button.pressed.connect(_finish_onboarding)
	next_button.pressed.connect(_next_slide)

	# Set initial game state
	GameManager.change_state(GameManager.GameState.MAIN_MENU)

	# Play main menu music
	if audio and audio.has_method("play_music_main_menu"):
		audio.play_music_main_menu()

	# Setup UI sounds for all buttons
	_setup_ui_sounds()

	# Setup audio controls
	_setup_audio_controls()

	# Create animated star background
	_create_stars()

	# Defer button setup and entrance animation until layout is complete
	call_deferred("_setup_button_effects")
	call_deferred("_play_entrance_animation")

	print("[MainMenu] Ready - Welcome to Mindscape")


func _process(delta: float) -> void:
	anim_time += delta

	# Animate stars
	_update_stars(delta)

	# Animate orb glow pulsing
	_animate_orb()

	# Animate title glow
	_animate_title_glow()


func _create_stars() -> void:
	var viewport_size = get_viewport_rect().size
	for i in range(NUM_STARS):
		var star = ColorRect.new()
		var star_size = randf_range(1.0, 3.0)
		star.custom_minimum_size = Vector2(star_size, star_size)
		star.size = Vector2(star_size, star_size)
		star.position = Vector2(
			randf_range(0, viewport_size.x),
			randf_range(0, viewport_size.y)
		)

		# Random star color (white, blue-white, or gold tint)
		var color_choice = randi() % 10
		if color_choice < 6:
			star.color = Color(0.9, 0.92, 1.0, randf_range(0.3, 0.8))
		elif color_choice < 9:
			star.color = Color(0.7, 0.8, 1.0, randf_range(0.3, 0.7))
		else:
			star.color = Color(1.0, 0.9, 0.7, randf_range(0.4, 0.9))

		stars_container.add_child(star)
		stars.append({
			"node": star,
			"base_alpha": star.color.a,
			"twinkle_speed": randf_range(0.5, 2.0),
			"twinkle_offset": randf_range(0, TAU),
			"drift_speed": randf_range(2.0, 8.0),
			"drift_angle": randf_range(0, TAU)
		})


func _update_stars(delta: float) -> void:
	var viewport_size = get_viewport_rect().size
	for star_data in stars:
		var star: ColorRect = star_data.node

		# Twinkle effect
		var twinkle = sin(anim_time * star_data.twinkle_speed + star_data.twinkle_offset)
		star.color.a = star_data.base_alpha * (0.5 + 0.5 * twinkle)

		# Slow drift
		star.position.x += cos(star_data.drift_angle) * star_data.drift_speed * delta * 0.3
		star.position.y += sin(star_data.drift_angle) * star_data.drift_speed * delta * 0.3

		# Wrap around screen
		if star.position.x < -10:
			star.position.x = viewport_size.x + 5
		elif star.position.x > viewport_size.x + 10:
			star.position.x = -5
		if star.position.y < -10:
			star.position.y = viewport_size.y + 5
		elif star.position.y > viewport_size.y + 10:
			star.position.y = -5


func _animate_orb() -> void:
	if not glow_orb:
		return

	# Pulsing scale effect
	var pulse = sin(anim_time * 1.2) * 0.08 + 1.0
	glow_orb.scale = Vector2(pulse, pulse)

	# Subtle position float
	var float_y = sin(anim_time * 0.8) * 5.0
	glow_orb.position.y = -200 + float_y

	# Animate individual orb layers
	var orb_core = glow_orb.get_node_or_null("OrbCore")
	var orb_glow1 = glow_orb.get_node_or_null("OrbGlow1")
	var orb_glow2 = glow_orb.get_node_or_null("OrbGlow2")
	var orb_glow3 = glow_orb.get_node_or_null("OrbGlow3")

	if orb_core:
		var core_pulse = sin(anim_time * 2.0) * 0.15 + 0.9
		orb_core.color.a = core_pulse

	if orb_glow1:
		var glow1_pulse = sin(anim_time * 1.5 + 0.5) * 0.08 + 0.2
		orb_glow1.color.a = glow1_pulse

	if orb_glow2:
		var glow2_pulse = sin(anim_time * 1.0 + 1.0) * 0.05 + 0.12
		orb_glow2.color.a = glow2_pulse

	if orb_glow3:
		var glow3_pulse = sin(anim_time * 0.7 + 1.5) * 0.03 + 0.08
		orb_glow3.color.a = glow3_pulse


func _animate_title_glow() -> void:
	if not title_glow:
		return

	# Pulsing glow effect on title
	var glow_intensity = sin(anim_time * 1.5) * 0.15 + 0.3
	title_glow.modulate.a = glow_intensity


func _play_entrance_animation() -> void:
	# Fade in the whole menu
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_OUT)

	# Animate buttons fading in with scale (don't modify position in VBoxContainer)
	var buttons = [start_button, continue_button, load_button, settings_button]
	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn and btn.visible:
			btn.modulate.a = 0.0
			btn.scale = Vector2(0.8, 0.8)
			btn.pivot_offset = btn.size / 2  # Scale from center

			var btn_tween = create_tween()
			btn_tween.set_parallel(true)
			btn_tween.tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(0.3 + i * 0.12)
			btn_tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.4).set_delay(0.3 + i * 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _setup_button_effects() -> void:
	var buttons = [start_button, continue_button, load_button, settings_button]
	for btn in buttons:
		if btn:
			# Set pivot to center for proper scaling
			btn.pivot_offset = btn.size / 2
			btn.mouse_entered.connect(_on_button_hover.bind(btn))
			btn.mouse_exited.connect(_on_button_unhover.bind(btn))


func _on_button_hover(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15).set_ease(Tween.EASE_OUT)


func _on_button_unhover(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)


func _setup_ui_sounds() -> void:
	# Connect button sounds
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		return

	var buttons = [start_button, continue_button, load_button, settings_button, back_button, skip_button, next_button]
	for btn in buttons:
		if btn and not btn.pressed.is_connected(audio.play_ui_click):
			btn.pressed.connect(audio.play_ui_click)


func _setup_audio_controls() -> void:
	var audio = get_node_or_null("/root/AudioManager")

	# Initialize volume slider with current volume
	if volume_slider and audio:
		var current_vol = audio.master_volume if audio.get("master_volume") != null else 0.8
		volume_slider.value = current_vol * 100
		volume_slider.value_changed.connect(_on_volume_changed)

	# Initialize mute button
	if mute_button:
		mute_button.pressed.connect(_on_mute_pressed)
		_update_mute_button_icon()


func _on_volume_changed(value: float) -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("set_master_volume"):
		audio.set_master_volume(value / 100.0)
	_update_mute_button_icon()


func _on_mute_pressed() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		return

	# Toggle mute
	if audio.has_method("toggle_mute"):
		audio.toggle_mute()
	elif audio.get("is_muted") != null:
		audio.is_muted = not audio.is_muted
		if audio.has_method("_apply_mute"):
			audio._apply_mute()

	_update_mute_button_icon()


func _update_mute_button_icon() -> void:
	if not mute_button:
		return

	var audio = get_node_or_null("/root/AudioManager")
	var is_muted = false

	if audio:
		is_muted = audio.get("is_muted") if audio.get("is_muted") != null else false
		# Also consider volume at 0 as muted
		var vol = audio.get("master_volume")
		if vol != null and vol <= 0.01:
			is_muted = true

	if is_muted:
		mute_button.text = "🔇"
		mute_button.tooltip_text = "Unmute"
	else:
		mute_button.text = "🔊"
		mute_button.tooltip_text = "Mute"


func _on_start_pressed() -> void:
	print("[MainMenu] Starting new journey...")

	# Delete old save if starting fresh
	if SaveManager.has_save():
		SaveManager.delete_save()

	# Reset to default slot and clear its journal
	SaveManager.current_slot = 0
	var journal_path = SaveManager.get_journal_path()
	if FileAccess.file_exists(journal_path):
		DirAccess.remove_absolute(journal_path)
		print("[MainMenu] Cleared journal for fresh start")

	# Reset all progress for new game
	GameManager.reset_player_data()
	CampaignManager.reset_campaign()

	# For new players, go straight to intro cutscene (introduces Goacto and the mission)
	# The mindscape onboarding slides will show AFTER the intro_part2 cutscene
	_enter_cutscene("intro_part1")


func _on_continue_pressed() -> void:
	print("[MainMenu] Continuing journey...")

	# Use default slot (auto-save)
	SaveManager.current_slot = 0

	# Load saved data
	SaveManager.load_game()

	# Check if player needs to see the intro (in case of updated game flow)
	if not CampaignManager.has_seen_cutscene("intro_part1"):
		_enter_cutscene("intro_part1")
	else:
		# Set flag for wake-up animation in bedroom
		GameManager.player_data["wakeup_from_continue"] = true
		_enter_mindscape()


func _show_onboarding() -> void:
	current_slide = 0
	main_vbox.visible = false
	onboarding_panel.visible = true
	_update_slide()


func _update_slide() -> void:
	var slide = onboarding_slides[current_slide]

	slide_title.text = slide.title
	slide_text.text = slide.text

	# Create the icon for this slide
	_create_slide_icon(current_slide, slide.color)

	# Update page indicators
	for i in range(page_indicator.get_child_count()):
		var dot = page_indicator.get_child(i)
		if i == current_slide:
			dot.color = Color(0.8, 0.8, 0.9, 1)
		else:
			dot.color = Color(0.4, 0.4, 0.5, 1)

	# Show/hide back button based on slide
	back_button.visible = current_slide > 0

	# Update button text on last slide
	if current_slide == onboarding_slides.size() - 1:
		next_button.text = "Let's Go!"
	else:
		next_button.text = "Next"

	# Play voice narration for this slide
	_play_slide_voice(slide)


func _create_slide_icon(slide_index: int, base_color: Color) -> void:
	# Clear previous icon
	if slide_icon_canvas:
		slide_icon_canvas.queue_free()
		slide_icon_canvas = null

	# Set container background to transparent
	slide_icon_container.color = Color(0, 0, 0, 0)

	# Create canvas for polygon graphics
	slide_icon_canvas = Node2D.new()
	slide_icon_canvas.name = "IconCanvas"
	slide_icon_container.add_child(slide_icon_canvas)

	# Center the canvas
	slide_icon_container.resized.connect(func():
		if slide_icon_canvas:
			slide_icon_canvas.position = slide_icon_container.size / 2
	, CONNECT_ONE_SHOT)
	slide_icon_canvas.position = slide_icon_container.size / 2

	match slide_index:
		0:
			_create_sanctuary_icon(base_color)
		1:
			_create_focus_icon(base_color)
		2:
			_create_aspects_icon(base_color)
		3:
			_create_script_icon(base_color)


func _create_sanctuary_icon(base_color: Color) -> void:
	# Floating island/mindscape platform
	# Base platform
	var platform = Polygon2D.new()
	platform.polygon = PackedVector2Array([
		Vector2(-45, 10), Vector2(0, -15), Vector2(45, 10), Vector2(0, 35)
	])
	platform.color = base_color
	slide_icon_canvas.add_child(platform)

	# Platform top surface
	var surface = Polygon2D.new()
	surface.polygon = PackedVector2Array([
		Vector2(-40, 8), Vector2(0, -10), Vector2(40, 8), Vector2(0, 25)
	])
	surface.color = Color(base_color.r + 0.15, base_color.g + 0.15, base_color.b + 0.15, 1.0)
	slide_icon_canvas.add_child(surface)

	# Central crystal/tower
	var crystal = Polygon2D.new()
	crystal.polygon = PackedVector2Array([
		Vector2(-8, 5), Vector2(-6, -30), Vector2(0, -45), Vector2(6, -30), Vector2(8, 5)
	])
	crystal.color = Color(0.8, 0.7, 0.9, 0.9)
	slide_icon_canvas.add_child(crystal)

	# Crystal glow
	var glow = Polygon2D.new()
	var glow_points = PackedVector2Array()
	for i in range(12):
		var angle = (float(i) / 12.0) * TAU
		glow_points.append(Vector2(cos(angle) * 18, sin(angle) * 18 - 20))
	glow.polygon = glow_points
	glow.color = Color(0.7, 0.6, 0.9, 0.25)
	slide_icon_canvas.add_child(glow)

	# Floating particles
	for i in range(4):
		var particle = Polygon2D.new()
		var p_points = PackedVector2Array()
		for j in range(6):
			var angle = (float(j) / 6.0) * TAU
			p_points.append(Vector2(cos(angle) * 3, sin(angle) * 3))
		particle.polygon = p_points
		particle.position = Vector2(randf_range(-35, 35), randf_range(-40, -5))
		particle.color = Color(0.8, 0.8, 1.0, 0.4)
		slide_icon_canvas.add_child(particle)


func _create_focus_icon(base_color: Color) -> void:
	# Timer/hourglass design
	# Outer ring
	var ring_outer = Polygon2D.new()
	var ring_points = PackedVector2Array()
	for i in range(24):
		var angle = (float(i) / 24.0) * TAU - PI/2
		ring_points.append(Vector2(cos(angle) * 42, sin(angle) * 42))
	ring_outer.polygon = ring_points
	ring_outer.color = base_color
	slide_icon_canvas.add_child(ring_outer)

	# Inner ring (cutout effect)
	var ring_inner = Polygon2D.new()
	var inner_points = PackedVector2Array()
	for i in range(24):
		var angle = (float(i) / 24.0) * TAU - PI/2
		inner_points.append(Vector2(cos(angle) * 35, sin(angle) * 35))
	ring_inner.polygon = inner_points
	ring_inner.color = Color(0.08, 0.06, 0.12, 1)
	slide_icon_canvas.add_child(ring_inner)

	# Progress arc (showing focus progress)
	var progress = Polygon2D.new()
	var progress_points = PackedVector2Array()
	progress_points.append(Vector2(0, 0))
	for i in range(18):  # 3/4 of the circle
		var angle = (float(i) / 24.0) * TAU - PI/2
		progress_points.append(Vector2(cos(angle) * 32, sin(angle) * 32))
	progress.polygon = progress_points
	progress.color = Color(base_color.r + 0.2, base_color.g + 0.2, base_color.b, 0.8)
	slide_icon_canvas.add_child(progress)

	# Center crystal
	var crystal = Polygon2D.new()
	crystal.polygon = PackedVector2Array([
		Vector2(-10, 12), Vector2(0, -18), Vector2(10, 12)
	])
	crystal.color = Color(0.9, 0.85, 0.6, 1.0)
	slide_icon_canvas.add_child(crystal)

	# Time indicator
	var hand = Polygon2D.new()
	hand.polygon = PackedVector2Array([
		Vector2(-2, 5), Vector2(0, -25), Vector2(2, 5)
	])
	hand.color = Color(0.8, 0.9, 0.95, 0.9)
	hand.rotation = -0.5
	slide_icon_canvas.add_child(hand)


func _create_aspects_icon(base_color: Color) -> void:
	# Six gems arranged in a hexagon representing the six aspects
	var aspect_colors = [
		Color(0.83, 0.66, 0.29),  # Discipline - gold
		Color(0.8, 0.3, 0.35),    # Courage - red
		Color(0.7, 0.5, 0.8),     # Creativity - purple
		Color(0.4, 0.7, 0.5),     # Compassion - green
		Color(0.3, 0.6, 0.9),     # Wisdom - blue
		Color(0.9, 0.5, 0.3),     # Vitality - orange
	]

	# Central hexagon glow
	var center_glow = Polygon2D.new()
	var glow_points = PackedVector2Array()
	for i in range(6):
		var angle = (float(i) / 6.0) * TAU - PI/2
		glow_points.append(Vector2(cos(angle) * 22, sin(angle) * 22))
	center_glow.polygon = glow_points
	center_glow.color = Color(base_color.r, base_color.g, base_color.b, 0.3)
	slide_icon_canvas.add_child(center_glow)

	# Six aspect gems
	for i in range(6):
		var angle = (float(i) / 6.0) * TAU - PI/2
		var gem_pos = Vector2(cos(angle) * 32, sin(angle) * 32)

		# Gem shape
		var gem = Polygon2D.new()
		gem.polygon = PackedVector2Array([
			Vector2(0, -12), Vector2(8, -2), Vector2(8, 6),
			Vector2(0, 12), Vector2(-8, 6), Vector2(-8, -2)
		])
		gem.position = gem_pos
		gem.color = aspect_colors[i]
		slide_icon_canvas.add_child(gem)

		# Gem highlight
		var highlight = Polygon2D.new()
		highlight.polygon = PackedVector2Array([
			Vector2(0, -10), Vector2(5, -3), Vector2(0, -5), Vector2(-5, -3)
		])
		highlight.position = gem_pos
		highlight.color = Color(1, 1, 1, 0.3)
		slide_icon_canvas.add_child(highlight)

	# Central core
	var core = Polygon2D.new()
	var core_points = PackedVector2Array()
	for i in range(6):
		var angle = (float(i) / 6.0) * TAU - PI/2
		core_points.append(Vector2(cos(angle) * 10, sin(angle) * 10))
	core.polygon = core_points
	core.color = Color(0.9, 0.85, 0.95, 0.9)
	slide_icon_canvas.add_child(core)


func _create_script_icon(base_color: Color) -> void:
	# Code/script representation - a scroll or terminal
	# Main document frame
	var frame = Polygon2D.new()
	frame.polygon = PackedVector2Array([
		Vector2(-35, -40), Vector2(35, -40), Vector2(35, 45), Vector2(-35, 45)
	])
	frame.color = base_color
	slide_icon_canvas.add_child(frame)

	# Inner document area
	var inner = Polygon2D.new()
	inner.polygon = PackedVector2Array([
		Vector2(-30, -35), Vector2(30, -35), Vector2(30, 40), Vector2(-30, 40)
	])
	inner.color = Color(0.1, 0.08, 0.15, 1)
	slide_icon_canvas.add_child(inner)

	# Code lines
	var line_y = -28
	var line_widths = [20, 25, 15, 22, 18, 25, 12]
	var line_colors = [
		Color(0.6, 0.8, 0.6, 0.8),  # Green
		Color(0.7, 0.7, 0.9, 0.8),  # Purple
		Color(0.9, 0.8, 0.5, 0.8),  # Gold
		Color(0.6, 0.8, 0.6, 0.8),  # Green
		Color(0.8, 0.6, 0.6, 0.8),  # Red
		Color(0.7, 0.7, 0.9, 0.8),  # Purple
		Color(0.5, 0.7, 0.9, 0.8),  # Blue
	]

	for i in range(line_widths.size()):
		var code_line = Polygon2D.new()
		var indent = 0 if i == 0 or i == 6 else randi_range(0, 2) * 5
		code_line.polygon = PackedVector2Array([
			Vector2(-25 + indent, line_y), Vector2(-25 + indent + line_widths[i], line_y),
			Vector2(-25 + indent + line_widths[i], line_y + 6), Vector2(-25 + indent, line_y + 6)
		])
		code_line.color = line_colors[i]
		slide_icon_canvas.add_child(code_line)
		line_y += 10

	# Play/run button indicator
	var play_btn = Polygon2D.new()
	play_btn.polygon = PackedVector2Array([
		Vector2(-6, -8), Vector2(8, 0), Vector2(-6, 8)
	])
	play_btn.position = Vector2(20, 32)
	play_btn.color = Color(0.5, 0.9, 0.5, 0.9)
	slide_icon_canvas.add_child(play_btn)

	# Scroll curl (top right corner fold)
	var fold = Polygon2D.new()
	fold.polygon = PackedVector2Array([
		Vector2(25, -40), Vector2(35, -40), Vector2(35, -30)
	])
	fold.color = Color(base_color.r - 0.1, base_color.g - 0.1, base_color.b - 0.1, 1)
	slide_icon_canvas.add_child(fold)


func _next_slide() -> void:
	current_slide += 1

	if current_slide >= onboarding_slides.size():
		_finish_onboarding()
	else:
		_update_slide()


func _prev_slide() -> void:
	if current_slide > 0:
		current_slide -= 1
		_update_slide()


func _play_slide_voice(slide: Dictionary) -> void:
	# Stop any currently playing voice
	_stop_slide_voice()

	# Check if voice file exists
	var voice_path = slide.get("voice", "")
	if voice_path == "" or not ResourceLoader.exists(voice_path):
		return

	# Use AudioManager if available
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_voice"):
		var stream = load(voice_path)
		if stream:
			audio.play_voice(stream)
	else:
		# Fallback: create local AudioStreamPlayer
		current_voice_player = AudioStreamPlayer.new()
		current_voice_player.stream = load(voice_path)
		current_voice_player.bus = "Voice" if AudioServer.get_bus_index("Voice") >= 0 else "Master"
		add_child(current_voice_player)
		current_voice_player.play()
		current_voice_player.finished.connect(_on_voice_finished)


func _stop_slide_voice() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()

	if current_voice_player:
		current_voice_player.stop()
		current_voice_player.queue_free()
		current_voice_player = null


func _on_voice_finished() -> void:
	if current_voice_player:
		current_voice_player.queue_free()
		current_voice_player = null


func _finish_onboarding() -> void:
	# Stop any playing voice
	_stop_slide_voice()

	# Legacy - onboarding now shows in mindscape hub after intro cutscenes
	# This function is kept for skip button compatibility
	onboarding_panel.visible = false
	main_vbox.visible = true

	# Play intro cutscene
	if not CampaignManager.has_seen_cutscene("intro_part1"):
		_enter_cutscene("intro_part1")
	else:
		_enter_mindscape()


func _enter_cutscene(cutscene_id: String) -> void:
	GameManager.player_data["pending_cutscene"] = cutscene_id
	GameManager.goto_scene("res://scenes/cutscene/cutscene.tscn")


func _enter_mindscape() -> void:
	# New players start in Goacto's bedroom
	_enter_bedroom()


func _enter_bedroom() -> void:
	# Go to Goacto's cabin on the Stellar Wanderer
	GameManager.goto_scene("res://scenes/bedroom/bedroom.tscn")


func _on_settings_pressed() -> void:
	print("[MainMenu] Opening settings...")
	GameManager.goto_scene("res://scenes/settings/settings.tscn")


func _on_load_pressed() -> void:
	print("[MainMenu] Opening load game...")
	_show_load_panel()


func _show_load_panel() -> void:
	# Hide main menu buttons
	main_vbox.visible = false

	# Create load panel
	load_panel = PanelContainer.new()
	load_panel.name = "LoadPanel"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.08, 0.95)
	style.border_color = Color(0.83, 0.66, 0.29, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	load_panel.add_theme_stylebox_override("panel", style)

	load_panel.set_anchors_preset(Control.PRESET_CENTER)
	load_panel.offset_left = -250
	load_panel.offset_right = 250
	load_panel.offset_top = -200
	load_panel.offset_bottom = 200

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	load_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Load Game"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Current session (auto-save) - slot 0
	if SaveManager.has_save():
		var auto_save_row = _create_auto_save_row()
		vbox.add_child(auto_save_row)

		var sep_auto = HSeparator.new()
		vbox.add_child(sep_auto)

	# Manual save slots (1-3)
	var slots_label = Label.new()
	slots_label.text = "Manual Saves"
	slots_label.add_theme_font_size_override("font_size", 14)
	slots_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	slots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(slots_label)

	for i in range(1, 4):
		var slot_row = _create_load_slot_row(i)
		vbox.add_child(slot_row)

	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	# Save File Management section
	var save_mgmt_label = Label.new()
	save_mgmt_label.text = "Save File Management"
	save_mgmt_label.add_theme_font_size_override("font_size", 14)
	save_mgmt_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	save_mgmt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(save_mgmt_label)

	# Row 1: Download / Upload file
	var file_row = HBoxContainer.new()
	file_row.add_theme_constant_override("separation", 10)
	file_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(file_row)

	var download_btn = Button.new()
	download_btn.text = "Download Save"
	download_btn.custom_minimum_size = Vector2(150, 40)
	download_btn.add_theme_font_size_override("font_size", 14)
	download_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	download_btn.disabled = not SaveManager.has_save()
	download_btn.pressed.connect(_download_save_file)
	file_row.add_child(download_btn)

	var upload_btn = Button.new()
	upload_btn.text = "Upload Save"
	upload_btn.custom_minimum_size = Vector2(150, 40)
	upload_btn.add_theme_font_size_override("font_size", 14)
	upload_btn.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	upload_btn.pressed.connect(_upload_save_file)
	file_row.add_child(upload_btn)

	# Row 2: Clipboard copy/paste (fallback)
	var clip_row = HBoxContainer.new()
	clip_row.add_theme_constant_override("separation", 10)
	clip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(clip_row)

	var import_btn = Button.new()
	import_btn.text = "Paste JSON"
	import_btn.custom_minimum_size = Vector2(150, 35)
	import_btn.add_theme_font_size_override("font_size", 12)
	import_btn.pressed.connect(_show_import_dialog)
	clip_row.add_child(import_btn)

	var export_btn = Button.new()
	export_btn.text = "Copy JSON"
	export_btn.custom_minimum_size = Vector2(150, 35)
	export_btn.add_theme_font_size_override("font_size", 12)
	export_btn.disabled = not SaveManager.has_save()
	export_btn.pressed.connect(_show_export_dialog)
	clip_row.add_child(export_btn)

	var sep3 = HSeparator.new()
	vbox.add_child(sep3)

	# Back button
	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(160, 45)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_close_load_panel)
	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_child(back_btn)
	vbox.add_child(btn_container)

	add_child(load_panel)

	# Animate panel entrance
	load_panel.modulate.a = 0.0
	load_panel.scale = Vector2(0.9, 0.9)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(load_panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(load_panel, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _create_load_slot_row(slot: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var info = SaveManager.get_slot_info(slot)

	# Slot label
	var label = Label.new()
	label.custom_minimum_size = Vector2(240, 0)
	label.add_theme_font_size_override("font_size", 16)

	if info.exists:
		label.text = "%s\n%s • Evo %d • %d sessions" % [
			info.slot_name,
			info.date_string,
			int(info.evolution_level),
			int(info.focus_sessions)
		]
		label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	else:
		label.text = "Slot %d: Empty\nNo saved data" % slot
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))

	row.add_child(label)

	# Load button
	var load_btn = Button.new()
	load_btn.text = "Load"
	load_btn.custom_minimum_size = Vector2(80, 40)
	load_btn.add_theme_font_size_override("font_size", 14)
	load_btn.disabled = not info.exists
	load_btn.pressed.connect(_load_from_slot.bind(slot))
	row.add_child(load_btn)

	# Delete button
	var delete_btn = Button.new()
	delete_btn.text = "X"
	delete_btn.custom_minimum_size = Vector2(40, 40)
	delete_btn.add_theme_font_size_override("font_size", 14)
	delete_btn.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
	delete_btn.disabled = not info.exists
	delete_btn.pressed.connect(_delete_slot.bind(slot))
	row.add_child(delete_btn)

	return row


func _create_auto_save_row() -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	# Get auto-save info
	var label = Label.new()
	label.custom_minimum_size = Vector2(240, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.text = "Current Session\n(Auto-save)"
	label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	row.add_child(label)

	# Continue button (same as Continue Journey)
	var continue_btn = Button.new()
	continue_btn.text = "Continue"
	continue_btn.custom_minimum_size = Vector2(80, 40)
	continue_btn.add_theme_font_size_override("font_size", 14)
	continue_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.6))
	continue_btn.pressed.connect(_continue_auto_save)
	row.add_child(continue_btn)

	# Placeholder spacer (no delete for auto-save from here - use New Journey)
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(40, 40)
	row.add_child(spacer)

	return row


func _continue_auto_save() -> void:
	_close_load_panel()
	# Same logic as Continue Journey button
	if SaveManager.load_game():
		SaveManager.current_slot = 0
		GameManager.player_data["wakeup_from_continue"] = true
		_enter_mindscape()


func _load_from_slot(slot: int) -> void:
	print("[MainMenu] Loading from slot ", slot)
	if SaveManager.load_from_slot(slot):
		_close_load_panel()
		# Set flag for wake-up animation
		GameManager.player_data["wakeup_from_continue"] = true
		_enter_mindscape()
	else:
		print("[MainMenu] Failed to load slot ", slot)


var delete_confirm_dialog: PanelContainer = null
var pending_delete_slot: int = 0

func _delete_slot(slot: int) -> void:
	# Show confirmation dialog instead of deleting immediately
	pending_delete_slot = slot
	var info = SaveManager.get_slot_info(slot)

	delete_confirm_dialog = PanelContainer.new()
	delete_confirm_dialog.name = "DeleteConfirmDialog"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.06, 0.08, 0.98)
	style.border_color = Color(0.9, 0.4, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	delete_confirm_dialog.add_theme_stylebox_override("panel", style)

	delete_confirm_dialog.set_anchors_preset(Control.PRESET_CENTER)
	delete_confirm_dialog.offset_left = -220
	delete_confirm_dialog.offset_right = 220
	delete_confirm_dialog.offset_top = -130
	delete_confirm_dialog.offset_bottom = 130

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	delete_confirm_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Warning icon/title
	var title = Label.new()
	title.text = "Delete Save?"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.95, 0.4, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Save info
	var info_label = Label.new()
	info_label.text = "'%s'\n%s\n%d days completed" % [info.slot_name, info.date_string, info.days_completed]
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info_label)

	# Warning message
	var warning = Label.new()
	warning.text = "This cannot be undone!"
	warning.add_theme_font_size_override("font_size", 18)
	warning.add_theme_color_override("font_color", Color(0.9, 0.6, 0.4))
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(warning)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Keep Save"
	cancel_btn.custom_minimum_size = Vector2(130, 48)
	cancel_btn.add_theme_font_size_override("font_size", 17)
	cancel_btn.pressed.connect(_cancel_delete_slot)
	btn_row.add_child(cancel_btn)

	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(130, 48)
	delete_btn.add_theme_font_size_override("font_size", 17)
	delete_btn.add_theme_color_override("font_color", Color(0.95, 0.4, 0.35))
	delete_btn.pressed.connect(_confirm_delete_slot)
	btn_row.add_child(delete_btn)

	add_child(delete_confirm_dialog)


func _confirm_delete_slot() -> void:
	if delete_confirm_dialog:
		delete_confirm_dialog.queue_free()
		delete_confirm_dialog = null

	SaveManager.delete_slot(pending_delete_slot)
	pending_delete_slot = 0

	# Refresh the panel (immediate, no animation)
	if load_panel:
		load_panel.queue_free()
		load_panel = null
	_show_load_panel()


func _cancel_delete_slot() -> void:
	if delete_confirm_dialog:
		delete_confirm_dialog.queue_free()
		delete_confirm_dialog = null
	pending_delete_slot = 0


func _close_load_panel() -> void:
	if load_panel:
		# Animate exit
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(load_panel, "modulate:a", 0.0, 0.15)
		tween.tween_property(load_panel, "scale", Vector2(0.95, 0.95), 0.15)
		tween.tween_callback(func():
			if load_panel:
				load_panel.queue_free()
				load_panel = null
		)
	main_vbox.visible = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if json_dialog:
			_close_json_dialog()
			get_viewport().set_input_as_handled()
			return
		if delete_confirm_dialog:
			_cancel_delete_slot()
			get_viewport().set_input_as_handled()
			return
		if load_panel and load_panel.visible:
			_close_load_panel()
			get_viewport().set_input_as_handled()


# ============ JSON Import/Export ============
var json_dialog: PanelContainer = null
var json_text_edit: TextEdit = null

func _show_import_dialog() -> void:
	_create_json_dialog("Import Save Data", true)


func _show_export_dialog() -> void:
	_create_json_dialog("Export Save Data", false)


func _create_json_dialog(title_text: String, is_import: bool) -> void:
	if json_dialog:
		json_dialog.queue_free()

	json_dialog = PanelContainer.new()
	json_dialog.name = "JSONDialog"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.08, 0.98)
	style.border_color = Color(0.4, 0.6, 0.8, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	json_dialog.add_theme_stylebox_override("panel", style)

	json_dialog.set_anchors_preset(Control.PRESET_CENTER)
	json_dialog.offset_left = -320
	json_dialog.offset_right = 320
	json_dialog.offset_top = -250
	json_dialog.offset_bottom = 250

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	json_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Instructions
	var instructions = Label.new()
	if is_import:
		instructions.text = "Paste your JSON save data below:"
	else:
		instructions.text = "Copy your save data (select all, then copy):"
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instructions)

	# TextEdit for JSON
	json_text_edit = TextEdit.new()
	json_text_edit.custom_minimum_size = Vector2(580, 300)
	json_text_edit.add_theme_font_size_override("font_size", 12)
	json_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY

	if not is_import:
		# Export: populate with current save data
		var save_data = SaveManager.export_save_data()
		json_text_edit.text = save_data
		json_text_edit.editable = false
	else:
		json_text_edit.placeholder_text = '{"version": "0.3.2", "player": {...}, ...}'

	vbox.add_child(json_text_edit)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(120, 42)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_close_json_dialog)
	btn_row.add_child(cancel_btn)

	if is_import:
		var import_btn = Button.new()
		import_btn.text = "Import"
		import_btn.custom_minimum_size = Vector2(120, 42)
		import_btn.add_theme_font_size_override("font_size", 16)
		import_btn.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
		import_btn.pressed.connect(_do_import)
		btn_row.add_child(import_btn)
	else:
		var copy_btn = Button.new()
		copy_btn.text = "Copy All"
		copy_btn.custom_minimum_size = Vector2(120, 42)
		copy_btn.add_theme_font_size_override("font_size", 16)
		copy_btn.pressed.connect(_copy_export_text)
		btn_row.add_child(copy_btn)

	add_child(json_dialog)

	# Animate
	json_dialog.modulate.a = 0.0
	json_dialog.scale = Vector2(0.95, 0.95)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(json_dialog, "modulate:a", 1.0, 0.2)
	tween.tween_property(json_dialog, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT)


func _close_json_dialog() -> void:
	if json_dialog:
		json_dialog.queue_free()
		json_dialog = null
	json_text_edit = null


func _do_import() -> void:
	if not json_text_edit or json_text_edit.text.strip_edges() == "":
		_show_import_result("Please paste your save data first.", false)
		return

	var success = SaveManager.import_save_data(json_text_edit.text)
	if success:
		_show_import_result("Save data imported successfully!\nThe game will now load.", true)
		await get_tree().create_timer(1.5).timeout
		_close_json_dialog()
		_close_load_panel()
		# Load the imported data
		SaveManager.load_game()
		GameManager.player_data["wakeup_from_continue"] = true
		_enter_mindscape()
	else:
		_show_import_result("Import failed. Check that the data is valid JSON.", false)


func _copy_export_text() -> void:
	if json_text_edit:
		DisplayServer.clipboard_set(json_text_edit.text)
		_show_import_result("Copied to clipboard!", true)


func _show_import_result(message: String, success: bool) -> void:
	# Show a brief result message
	var result_label = Label.new()
	result_label.text = message
	result_label.add_theme_font_size_override("font_size", 16)
	result_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5) if success else Color(0.9, 0.4, 0.4))
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	result_label.offset_top = -60
	result_label.offset_bottom = -30

	if json_dialog:
		json_dialog.add_child(result_label)

		# Fade out after 2 seconds
		var tween = create_tween()
		tween.tween_property(result_label, "modulate:a", 0.0, 0.5).set_delay(2.0)
		tween.tween_callback(result_label.queue_free)


# =============================================================================
# SAVE FILE DOWNLOAD / UPLOAD
# =============================================================================

var upload_confirm_dialog: PanelContainer = null

func _download_save_file() -> void:
	var save_json = SaveManager.export_save_data()
	if save_json.is_empty():
		_show_toast("No save data to download.", false)
		return

	var player_name = GameManager.player_data.get("name", "Traveler").to_lower().replace(" ", "_")
	var timestamp = Time.get_datetime_string_from_system().replace(":", "").replace("-", "").substr(0, 15)
	var filename = "mindscape_save_%s_%s.json" % [player_name, timestamp]

	if OS.get_name() == "Web":
		_web_download_file(filename, save_json)
	else:
		_native_download_file(filename, save_json)


func _web_download_file(filename: String, content: String) -> void:
	# Use JavaScript to trigger a file download in the browser
	var js_code = """
	(function() {
		var data = %s;
		var blob = new Blob([JSON.stringify(data, null, 2)], {type: 'application/json'});
		var url = URL.createObjectURL(blob);
		var a = document.createElement('a');
		a.href = url;
		a.download = '%s';
		document.body.appendChild(a);
		a.click();
		document.body.removeChild(a);
		URL.revokeObjectURL(url);
	})();
	""" % [content, filename]
	JavaScriptBridge.eval(js_code)
	_show_toast("Save file downloading...", true)


func _native_download_file(filename: String, content: String) -> void:
	# Save to user's documents or downloads folder
	var path = ""
	if OS.get_name() == "macOS" or OS.get_name() == "Linux":
		path = OS.get_environment("HOME") + "/Downloads/" + filename
	elif OS.get_name() == "Windows":
		path = OS.get_environment("USERPROFILE") + "\\Downloads\\" + filename
	else:
		path = "user://" + filename

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		_show_toast("Saved to: " + path, true)
	else:
		# Fallback to user:// directory
		var fallback_path = "user://" + filename
		file = FileAccess.open(fallback_path, FileAccess.WRITE)
		if file:
			file.store_string(content)
			file.close()
			_show_toast("Saved to game data folder.", true)
		else:
			_show_toast("Failed to save file.", false)


func _upload_save_file() -> void:
	if OS.get_name() == "Web":
		_web_upload_file()
	else:
		_native_upload_file()


func _web_upload_file() -> void:
	# Create a hidden file input and trigger it via JavaScript
	# The callback stores the result in a global variable we can poll
	var js_code = """
	(function() {
		window._godotUploadedSave = null;
		window._godotUploadReady = false;
		var input = document.createElement('input');
		input.type = 'file';
		input.accept = '.json,.sav,.save,.txt';
		input.onchange = function(e) {
			var file = e.target.files[0];
			if (!file) return;
			var reader = new FileReader();
			reader.onload = function(ev) {
				window._godotUploadedSave = ev.target.result;
				window._godotUploadReady = true;
			};
			reader.readAsText(file);
		};
		input.click();
	})();
	"""
	JavaScriptBridge.eval(js_code)

	# Poll for the file content
	_poll_web_upload()


func _poll_web_upload() -> void:
	for i in range(300):  # Poll for up to 30 seconds
		await get_tree().create_timer(0.1).timeout
		var ready = JavaScriptBridge.eval("window._godotUploadReady === true")
		if ready:
			var content = JavaScriptBridge.eval("window._godotUploadedSave")
			JavaScriptBridge.eval("window._godotUploadedSave = null; window._godotUploadReady = false;")
			if content and content is String and content.length() > 0:
				_confirm_import_save(content)
			else:
				_show_toast("Failed to read file.", false)
			return
	# Timeout - user probably cancelled the file picker
	JavaScriptBridge.eval("window._godotUploadedSave = null; window._godotUploadReady = false;")


func _native_upload_file() -> void:
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.json ; JSON Save Files", "*.sav ; Save Files", "*.txt ; Text Files"])
	file_dialog.title = "Select Save File"
	file_dialog.size = Vector2(700, 500)
	file_dialog.file_selected.connect(func(path: String):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			_confirm_import_save(content)
		else:
			_show_toast("Failed to open file.", false)
		file_dialog.queue_free()
	)
	file_dialog.canceled.connect(func(): file_dialog.queue_free())
	add_child(file_dialog)
	file_dialog.popup_centered()


func _confirm_import_save(json_content: String) -> void:
	# Validate the JSON first
	var json = JSON.new()
	var parse_result = json.parse(json_content)
	if parse_result != OK:
		_show_toast("Invalid file: not valid JSON.", false)
		return

	var data = json.data
	if not data is Dictionary or not data.has("player"):
		_show_toast("Invalid save file: missing player data.", false)
		return

	# Build info about the uploaded save
	var upload_name = ""
	if data.has("player") and data.player is Dictionary:
		upload_name = data.player.get("name", "Unknown")
	var upload_version = data.get("version", "unknown")
	var upload_evo = 0
	if data.has("player") and data.player is Dictionary:
		upload_evo = int(data.player.get("world_evolution_level", 0))
	var upload_sessions = 0
	if data.has("player") and data.player is Dictionary:
		upload_sessions = int(data.player.get("total_focus_sessions", 0))

	# Check if there's an existing save that would be overwritten
	var has_existing = SaveManager.has_save()

	# Show confirmation dialog
	if upload_confirm_dialog:
		upload_confirm_dialog.queue_free()

	upload_confirm_dialog = PanelContainer.new()
	upload_confirm_dialog.name = "UploadConfirmDialog"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.1, 0.98)
	style.border_color = Color(0.8, 0.7, 0.4, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	upload_confirm_dialog.add_theme_stylebox_override("panel", style)

	upload_confirm_dialog.set_anchors_preset(Control.PRESET_CENTER)
	upload_confirm_dialog.offset_left = -260
	upload_confirm_dialog.offset_right = 260
	upload_confirm_dialog.offset_top = -200
	upload_confirm_dialog.offset_bottom = 200

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	upload_confirm_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Import Save File"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Uploaded save info
	var info_text = "Uploaded Save:\n"
	info_text += "  Player: %s\n" % upload_name
	info_text += "  Version: %s\n" % upload_version
	info_text += "  Evolution: %d\n" % upload_evo
	info_text += "  Focus Sessions: %d" % upload_sessions

	var info_label = Label.new()
	info_label.text = info_text
	info_label.add_theme_font_size_override("font_size", 15)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9))
	vbox.add_child(info_label)

	# Warning if existing save
	if has_existing:
		var existing_name = GameManager.player_data.get("name", "Unknown")
		var existing_evo = int(GameManager.player_data.get("world_evolution_level", 0))
		var existing_sessions = int(GameManager.player_data.get("total_focus_sessions", 0))

		var warn = Label.new()
		warn.text = "WARNING: This will replace your current save!\n  Current: %s (Evo %d, %d sessions)" % [existing_name, existing_evo, existing_sessions]
		warn.add_theme_font_size_override("font_size", 14)
		warn.add_theme_color_override("font_color", Color(0.9, 0.5, 0.4))
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(warn)

	# Slot selection
	var slot_label = Label.new()
	slot_label.text = "Import to:"
	slot_label.add_theme_font_size_override("font_size", 14)
	slot_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	vbox.add_child(slot_label)

	var slot_row = HBoxContainer.new()
	slot_row.add_theme_constant_override("separation", 10)
	slot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(slot_row)

	# Auto-save slot button
	var auto_btn = Button.new()
	auto_btn.text = "Auto-Save (Play Now)"
	auto_btn.custom_minimum_size = Vector2(200, 40)
	auto_btn.add_theme_font_size_override("font_size", 14)
	auto_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 0.6))
	auto_btn.pressed.connect(_do_file_import.bind(json_content, 0))
	slot_row.add_child(auto_btn)

	# Manual slot buttons
	for slot in range(1, 4):
		var slot_btn = Button.new()
		var slot_info = SaveManager.get_slot_info(slot)
		if slot_info.get("exists", false):
			slot_btn.text = "Slot %d (in use)" % slot
			slot_btn.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
		else:
			slot_btn.text = "Slot %d (empty)" % slot
		slot_btn.custom_minimum_size = Vector2(130, 40)
		slot_btn.add_theme_font_size_override("font_size", 13)
		slot_btn.pressed.connect(_do_file_import.bind(json_content, slot))
		slot_row.add_child(slot_btn)

	# Cancel button
	var cancel_row = HBoxContainer.new()
	cancel_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(cancel_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(120, 40)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(func():
		if upload_confirm_dialog:
			upload_confirm_dialog.queue_free()
			upload_confirm_dialog = null
	)
	cancel_row.add_child(cancel_btn)

	add_child(upload_confirm_dialog)

	# Animate in
	upload_confirm_dialog.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(upload_confirm_dialog, "modulate:a", 1.0, 0.25)


func _do_file_import(json_content: String, slot: int) -> void:
	var success = false
	if slot == 0:
		success = SaveManager.import_save_data(json_content)
	else:
		success = SaveManager.import_to_slot(slot, json_content)

	# Close dialog
	if upload_confirm_dialog:
		upload_confirm_dialog.queue_free()
		upload_confirm_dialog = null

	if success:
		if slot == 0:
			_show_toast("Save imported! Loading game...", true)
			await get_tree().create_timer(1.0).timeout
			_close_load_panel()
			SaveManager.load_game()
			GameManager.player_data["wakeup_from_continue"] = true
			_enter_mindscape()
		else:
			_show_toast("Save imported to Slot %d!" % slot, true)
			# Refresh the load panel to show the new slot
			await get_tree().create_timer(1.0).timeout
			_close_load_panel()
			_show_load_panel()
	else:
		_show_toast("Import failed. Save file may be corrupted.", false)


func _show_toast(message: String, success: bool) -> void:
	var toast = Label.new()
	toast.text = message
	toast.add_theme_font_size_override("font_size", 18)
	toast.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5) if success else Color(0.9, 0.4, 0.4))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.offset_top = -80
	toast.offset_bottom = -50
	toast.offset_left = -200
	toast.offset_right = 200
	add_child(toast)

	var tween = create_tween()
	tween.tween_property(toast, "modulate:a", 0.0, 0.5).set_delay(2.5)
	tween.tween_callback(toast.queue_free)
