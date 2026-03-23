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

# Import/Export dialogs
var import_dialog: PanelContainer = null
var import_text_input: TextEdit = null
var export_dialog: PanelContainer = null
var slot_select_dialog: PanelContainer = null
var pending_import_data: String = ""  # Store data while selecting slot

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

	# Always show Load Game button (for import functionality even without saves)
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
		mute_button.text = "Mute"
		mute_button.tooltip_text = "Unmute"
	else:
		mute_button.text = "Vol"
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
	load_panel.offset_left = -260
	load_panel.offset_right = 260
	load_panel.offset_top = -280
	load_panel.offset_bottom = 280

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

	# Import/Export section
	var transfer_label = Label.new()
	transfer_label.text = "Transfer Save"
	transfer_label.add_theme_font_size_override("font_size", 14)
	transfer_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	transfer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(transfer_label)

	var transfer_row = HBoxContainer.new()
	transfer_row.alignment = BoxContainer.ALIGNMENT_CENTER
	transfer_row.add_theme_constant_override("separation", 15)
	vbox.add_child(transfer_row)

	var import_btn = Button.new()
	import_btn.text = "Import Save"
	import_btn.custom_minimum_size = Vector2(130, 42)
	import_btn.add_theme_font_size_override("font_size", 15)
	import_btn.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5))
	import_btn.tooltip_text = "Import save from file/clipboard"
	import_btn.pressed.connect(_show_import_dialog)
	transfer_row.add_child(import_btn)

	var export_btn = Button.new()
	export_btn.text = "Export Save"
	export_btn.custom_minimum_size = Vector2(130, 42)
	export_btn.add_theme_font_size_override("font_size", 15)
	export_btn.add_theme_color_override("font_color", Color(0.5, 0.75, 0.9))
	export_btn.tooltip_text = "Export current save to clipboard"
	export_btn.disabled = not SaveManager.has_save()
	export_btn.pressed.connect(_show_export_dialog)
	transfer_row.add_child(export_btn)

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
	load_btn.custom_minimum_size = Vector2(70, 40)
	load_btn.add_theme_font_size_override("font_size", 14)
	load_btn.disabled = not info.exists
	load_btn.pressed.connect(_load_from_slot.bind(slot))
	row.add_child(load_btn)

	# Rename button
	var rename_btn = Button.new()
	rename_btn.text = "✏"
	rename_btn.tooltip_text = "Rename"
	rename_btn.custom_minimum_size = Vector2(40, 40)
	rename_btn.add_theme_font_size_override("font_size", 16)
	rename_btn.disabled = not info.exists
	rename_btn.pressed.connect(_show_rename_dialog.bind(slot))
	row.add_child(rename_btn)

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


# =============================================================================
# RENAME SAVE SLOT
# =============================================================================

var rename_dialog: Panel = null
var pending_rename_slot: int = 0
var rename_input: LineEdit = null

func _show_rename_dialog(slot: int) -> void:
	pending_rename_slot = slot
	var info = SaveManager.get_slot_info(slot)

	rename_dialog = Panel.new()
	rename_dialog.custom_minimum_size = Vector2(400, 200)
	rename_dialog.set_anchors_preset(Control.PRESET_CENTER)
	rename_dialog.pivot_offset = rename_dialog.custom_minimum_size / 2
	rename_dialog.position = (get_viewport_rect().size - rename_dialog.custom_minimum_size) / 2

	# Animation
	rename_dialog.scale = Vector2(0.9, 0.9)
	rename_dialog.modulate.a = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(rename_dialog, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(rename_dialog, "modulate:a", 1.0, 0.15)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	rename_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Rename Save"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Input field
	rename_input = LineEdit.new()
	rename_input.text = info.slot_name
	rename_input.placeholder_text = "Enter new name..."
	rename_input.custom_minimum_size = Vector2(0, 45)
	rename_input.add_theme_font_size_override("font_size", 18)
	rename_input.select_all_on_focus = true
	vbox.add_child(rename_input)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(120, 45)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_cancel_rename)
	btn_row.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "Rename"
	confirm_btn.custom_minimum_size = Vector2(120, 45)
	confirm_btn.add_theme_font_size_override("font_size", 16)
	confirm_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 0.6))
	confirm_btn.pressed.connect(_confirm_rename)
	btn_row.add_child(confirm_btn)

	add_child(rename_dialog)
	rename_input.grab_focus()


func _confirm_rename() -> void:
	if rename_input and rename_input.text.strip_edges() != "":
		SaveManager.rename_slot(pending_rename_slot, rename_input.text.strip_edges())

	_close_rename_dialog()

	# Refresh the panel
	if load_panel:
		load_panel.queue_free()
		load_panel = null
	_show_load_panel()


func _cancel_rename() -> void:
	_close_rename_dialog()


func _close_rename_dialog() -> void:
	if rename_dialog:
		rename_dialog.queue_free()
		rename_dialog = null
	rename_input = null
	pending_rename_slot = 0


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
		if slot_select_dialog:
			_close_slot_select_dialog()
			get_viewport().set_input_as_handled()
			return
		if import_dialog:
			_close_import_dialog()
			get_viewport().set_input_as_handled()
			return
		if export_dialog:
			_close_export_dialog()
			get_viewport().set_input_as_handled()
			return
		if delete_confirm_dialog:
			_cancel_delete_slot()
			get_viewport().set_input_as_handled()
			return
		if load_panel and load_panel.visible:
			_close_load_panel()
			get_viewport().set_input_as_handled()


# =============================================================================
# IMPORT / EXPORT
# =============================================================================

func _show_import_dialog() -> void:
	var is_web = OS.has_feature("web")
	print("[MainMenu] Import dialog - is_web: ", is_web)

	import_dialog = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.11, 0.98)
	style.border_color = Color(0.9, 0.75, 0.5, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	import_dialog.add_theme_stylebox_override("panel", style)
	import_dialog.set_anchors_preset(Control.PRESET_CENTER)
	import_dialog.offset_left = -300
	import_dialog.offset_right = 300
	import_dialog.offset_top = -260
	import_dialog.offset_bottom = 260

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	import_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Import Save Data"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Different instructions for web vs desktop
	var instructions = Label.new()
	if is_web:
		instructions.text = "Upload your save file or paste the data below.\n\nWarning: This will replace your current progress!"
	else:
		instructions.text = "Paste your save data below and click 'Import'.\n\nWarning: This will replace your current progress!"
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7))
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(instructions)

	# Upload file button (web only)
	if is_web:
		var upload_btn = Button.new()
		upload_btn.text = "Upload Save File (.json)"
		upload_btn.custom_minimum_size = Vector2(0, 45)
		upload_btn.add_theme_font_size_override("font_size", 16)
		upload_btn.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5))
		upload_btn.pressed.connect(_trigger_file_upload)
		vbox.add_child(upload_btn)

		var or_label = Label.new()
		or_label.text = "— or paste manually —"
		or_label.add_theme_font_size_override("font_size", 12)
		or_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		or_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(or_label)

	import_text_input = TextEdit.new()
	import_text_input.placeholder_text = "Paste your save data here..."
	import_text_input.custom_minimum_size = Vector2(0, 100)
	import_text_input.add_theme_font_size_override("font_size", 12)
	vbox.add_child(import_text_input)

	var paste_btn = Button.new()
	paste_btn.text = "Paste from Clipboard"
	paste_btn.custom_minimum_size = Vector2(0, 36)
	paste_btn.add_theme_font_size_override("font_size", 14)
	paste_btn.pressed.connect(func(): import_text_input.text = DisplayServer.clipboard_get())
	vbox.add_child(paste_btn)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(120, 45)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_close_import_dialog)
	btn_row.add_child(cancel_btn)

	var import_btn = Button.new()
	import_btn.text = "Import"
	import_btn.custom_minimum_size = Vector2(120, 45)
	import_btn.add_theme_font_size_override("font_size", 16)
	import_btn.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
	import_btn.pressed.connect(_do_import)
	btn_row.add_child(import_btn)

	add_child(import_dialog)

	# Animate entrance
	import_dialog.modulate.a = 0.0
	import_dialog.scale = Vector2(0.9, 0.9)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(import_dialog, "modulate:a", 1.0, 0.2)
	tween.tween_property(import_dialog, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT)


func _close_import_dialog() -> void:
	if import_dialog:
		import_dialog.queue_free()
		import_dialog = null
	import_text_input = null


func _do_import() -> void:
	if not import_text_input or import_text_input.text.strip_edges() == "":
		# Show error feedback
		if import_text_input:
			import_text_input.placeholder_text = "ERROR: Please paste your save data first!"
			import_text_input.add_theme_color_override("font_placeholder_color", Color(0.9, 0.4, 0.4))
		return

	var json_string = import_text_input.text.strip_edges()

	# Validate the data first
	var json = JSON.new()
	if json.parse(json_string) != OK:
		if import_text_input:
			import_text_input.placeholder_text = "ERROR: Invalid JSON format."
			import_text_input.add_theme_color_override("font_placeholder_color", Color(0.9, 0.4, 0.4))
			import_text_input.text = ""
		return

	var save_data = json.get_data()
	if not save_data is Dictionary or not save_data.has("player") or not save_data.has("version"):
		if import_text_input:
			import_text_input.placeholder_text = "ERROR: Invalid save data format. Make sure you copied the entire file."
			import_text_input.add_theme_color_override("font_placeholder_color", Color(0.9, 0.4, 0.4))
			import_text_input.text = ""
		return

	# Store the data and show slot selection dialog
	pending_import_data = json_string
	_close_import_dialog()
	_show_slot_select_dialog(save_data)


func _show_export_dialog() -> void:
	var export_data = SaveManager.export_save_data()
	var is_web = OS.has_feature("web")
	print("[MainMenu] Export dialog - is_web: ", is_web)

	export_dialog = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.12, 0.98)
	style.border_color = Color(0.5, 0.75, 0.9, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	export_dialog.add_theme_stylebox_override("panel", style)
	export_dialog.set_anchors_preset(Control.PRESET_CENTER)
	export_dialog.offset_left = -300
	export_dialog.offset_right = 300
	export_dialog.offset_top = -260
	export_dialog.offset_bottom = 260

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	export_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Export Save Data"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.5, 0.75, 0.9))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var instructions = Label.new()
	if is_web:
		instructions.text = "Download your save file or copy to clipboard.\n\nKeep this file safe to restore your progress later!"
	else:
		instructions.text = "Copy your save data to clipboard.\n\nPaste into a text file and save as 'mindscape_backup.json'"
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(instructions)

	# Download button (web only) - primary action
	if is_web:
		var download_btn = Button.new()
		download_btn.text = "Download Save File"
		download_btn.custom_minimum_size = Vector2(0, 50)
		download_btn.add_theme_font_size_override("font_size", 18)
		download_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 0.7))
		download_btn.pressed.connect(_trigger_file_download.bind(export_data, download_btn))
		vbox.add_child(download_btn)

		var or_label = Label.new()
		or_label.text = "— or copy manually —"
		or_label.add_theme_font_size_override("font_size", 12)
		or_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		or_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(or_label)

	var text_box = TextEdit.new()
	text_box.text = export_data
	text_box.custom_minimum_size = Vector2(0, 100)
	text_box.editable = false
	text_box.add_theme_font_size_override("font_size", 11)
	vbox.add_child(text_box)

	var copy_btn = Button.new()
	copy_btn.text = "Copy to Clipboard"
	copy_btn.custom_minimum_size = Vector2(0, 40)
	copy_btn.add_theme_font_size_override("font_size", 15)
	copy_btn.add_theme_color_override("font_color", Color(0.5, 0.75, 0.85))
	copy_btn.pressed.connect(func():
		DisplayServer.clipboard_set(export_data)
		copy_btn.text = "Copied!"
		copy_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	)
	vbox.add_child(copy_btn)

	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(0, 38)
	close_btn.add_theme_font_size_override("font_size", 15)
	close_btn.pressed.connect(_close_export_dialog)
	vbox.add_child(close_btn)

	add_child(export_dialog)

	# Animate entrance
	export_dialog.modulate.a = 0.0
	export_dialog.scale = Vector2(0.9, 0.9)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(export_dialog, "modulate:a", 1.0, 0.2)
	tween.tween_property(export_dialog, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT)


func _close_export_dialog() -> void:
	if export_dialog:
		export_dialog.queue_free()
		export_dialog = null


# =============================================================================
# SLOT SELECTION FOR IMPORT
# =============================================================================

var slot_name_input: LineEdit = null
var selected_import_slot: int = 1

func _show_slot_select_dialog(save_data: Dictionary) -> void:
	slot_select_dialog = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.1, 0.98)
	style.border_color = Color(0.9, 0.75, 0.5, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	slot_select_dialog.add_theme_stylebox_override("panel", style)
	slot_select_dialog.set_anchors_preset(Control.PRESET_CENTER)
	slot_select_dialog.offset_left = -280
	slot_select_dialog.offset_right = 280
	slot_select_dialog.offset_top = -240
	slot_select_dialog.offset_bottom = 240

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	slot_select_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Import to Slot"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Show import info
	var player_data = save_data.get("player", {})
	var import_info = Label.new()
	import_info.text = "Importing save data with Evolution level %d" % int(player_data.get("evolution_level", 1))
	import_info.add_theme_font_size_override("font_size", 13)
	import_info.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	import_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(import_info)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Slot selection buttons
	var slot_label = Label.new()
	slot_label.text = "Select Save Slot:"
	slot_label.add_theme_font_size_override("font_size", 16)
	slot_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
	vbox.add_child(slot_label)

	var slot_buttons_container = HBoxContainer.new()
	slot_buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_buttons_container.add_theme_constant_override("separation", 15)
	vbox.add_child(slot_buttons_container)

	var slot_button_group = ButtonGroup.new()
	selected_import_slot = 1  # Default to slot 1

	for i in range(1, 4):
		var slot_btn = Button.new()
		slot_btn.toggle_mode = true
		slot_btn.button_group = slot_button_group
		slot_btn.custom_minimum_size = Vector2(100, 55)
		slot_btn.add_theme_font_size_override("font_size", 14)

		var info = SaveManager.get_slot_info(i)
		if info.exists:
			slot_btn.text = "Slot %d\n(used)" % i
			slot_btn.tooltip_text = "%s - Evo %d" % [info.slot_name, int(info.evolution_level)]
		else:
			slot_btn.text = "Slot %d\n(empty)" % i
			slot_btn.tooltip_text = "Empty slot"

		if i == 1:
			slot_btn.button_pressed = true
			slot_btn.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5))
		else:
			slot_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))

		slot_btn.pressed.connect(_on_slot_button_pressed.bind(i, slot_btn, slot_buttons_container))
		slot_buttons_container.add_child(slot_btn)

	# Warning for existing slot
	var warning_label = Label.new()
	warning_label.name = "SlotWarning"
	warning_label.add_theme_font_size_override("font_size", 13)
	warning_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.4))
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_update_slot_warning(warning_label, 1)
	vbox.add_child(warning_label)

	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	# Save name input
	var name_label = Label.new()
	name_label.text = "Save Name (optional):"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
	vbox.add_child(name_label)

	slot_name_input = LineEdit.new()
	slot_name_input.placeholder_text = "e.g., My Journey, Backup..."
	slot_name_input.custom_minimum_size = Vector2(0, 40)
	slot_name_input.add_theme_font_size_override("font_size", 16)
	# Pre-fill with existing name if available
	var existing_name = save_data.get("slot_name", "")
	if existing_name != "" and not existing_name.begins_with("Slot "):
		slot_name_input.text = existing_name
	vbox.add_child(slot_name_input)

	var sep3 = HSeparator.new()
	vbox.add_child(sep3)

	# Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(120, 45)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_close_slot_select_dialog)
	btn_row.add_child(cancel_btn)

	var import_btn = Button.new()
	import_btn.text = "Import"
	import_btn.custom_minimum_size = Vector2(120, 45)
	import_btn.add_theme_font_size_override("font_size", 16)
	import_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 0.6))
	import_btn.pressed.connect(_do_slot_import)
	btn_row.add_child(import_btn)

	add_child(slot_select_dialog)

	# Animate entrance
	slot_select_dialog.modulate.a = 0.0
	slot_select_dialog.scale = Vector2(0.9, 0.9)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(slot_select_dialog, "modulate:a", 1.0, 0.2)
	tween.tween_property(slot_select_dialog, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT)


func _on_slot_button_pressed(slot: int, btn: Button, container: HBoxContainer) -> void:
	selected_import_slot = slot
	# Update button colors
	for child in container.get_children():
		if child is Button:
			if child == btn:
				child.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5))
			else:
				child.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))

	# Update warning
	if slot_select_dialog:
		var warning = slot_select_dialog.find_child("SlotWarning", true, false)
		if warning:
			_update_slot_warning(warning, slot)


func _update_slot_warning(label: Label, slot: int) -> void:
	var info = SaveManager.get_slot_info(slot)
	if info.exists:
		label.text = "Warning: This will overwrite '%s'" % info.slot_name
		label.visible = true
	else:
		label.text = ""
		label.visible = false


func _close_slot_select_dialog() -> void:
	if slot_select_dialog:
		slot_select_dialog.queue_free()
		slot_select_dialog = null
	slot_name_input = null
	pending_import_data = ""


func _do_slot_import() -> void:
	if pending_import_data == "":
		_close_slot_select_dialog()
		return

	# Get custom name
	var custom_name = ""
	if slot_name_input and slot_name_input.text.strip_edges() != "":
		custom_name = slot_name_input.text.strip_edges()
	else:
		custom_name = "Imported Save"

	# Parse the data to add the custom name
	var json = JSON.new()
	json.parse(pending_import_data)
	var save_data = json.get_data()
	save_data["slot_name"] = custom_name
	save_data["slot"] = selected_import_slot

	var updated_json = JSON.stringify(save_data, "\t")

	# Import to the selected slot
	var success = SaveManager.import_to_slot(selected_import_slot, updated_json)

	_close_slot_select_dialog()

	if success:
		print("[MainMenu] Imported to slot %d as '%s'" % [selected_import_slot, custom_name])
		# Refresh the load panel to show the new save
		if load_panel:
			load_panel.queue_free()
			load_panel = null
		_show_load_panel()
	else:
		# Show error - re-open import dialog
		_show_import_dialog()
		if import_text_input:
			import_text_input.placeholder_text = "ERROR: Failed to import save data."
			import_text_input.add_theme_color_override("font_placeholder_color", Color(0.9, 0.4, 0.4))


# =============================================================================
# WEB FILE DOWNLOAD / UPLOAD (JavaScript Bridge)
# =============================================================================

func _trigger_file_download(data: String, btn: Button) -> void:
	if not OS.has_feature("web"):
		return

	# Generate filename with timestamp
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var filename = "mindscape_save_%s.json" % timestamp

	# Escape the data for embedding in JavaScript (data is already valid JSON)
	# We need to escape backslashes and backticks for the template literal
	var escaped_data = data.replace("\\", "\\\\").replace("`", "\\`").replace("${", "\\${")

	# Use JavaScript to trigger download
	var js_code = """
		(function() {
			try {
				var data = `%s`;
				var blob = new Blob([data], {type: 'application/json'});
				var url = URL.createObjectURL(blob);
				var a = document.createElement('a');
				a.href = url;
				a.download = '%s';
				document.body.appendChild(a);
				a.click();
				setTimeout(function() {
					document.body.removeChild(a);
					URL.revokeObjectURL(url);
				}, 100);
				console.log('[GOACTO] Save file download triggered: ' + '%s');
			} catch(e) {
				console.error('[GOACTO] Download failed:', e);
			}
		})();
	""" % [escaped_data, filename, filename]

	JavaScriptBridge.eval(js_code)

	# Update button to show success
	btn.text = "Downloaded!"
	btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))


# File upload callback reference
var _file_upload_callback: JavaScriptObject = null

func _trigger_file_upload() -> void:
	if not OS.has_feature("web"):
		return

	# Create file input and set up callback
	var js_code = """
		(function() {
			// Remove any existing file input
			var existing = document.getElementById('godot-file-upload');
			if (existing) existing.remove();

			// Create file input
			var input = document.createElement('input');
			input.type = 'file';
			input.id = 'godot-file-upload';
			input.accept = '.json,application/json';
			input.style.display = 'none';

			input.onchange = function(e) {
				var file = e.target.files[0];
				if (!file) return;

				var reader = new FileReader();
				reader.onload = function(event) {
					// Store result in window for Godot to access
					window._godotUploadedFileContent = event.target.result;
					window._godotUploadReady = true;
				};
				reader.readAsText(file);
			};

			document.body.appendChild(input);
			input.click();
		})();
	"""

	JavaScriptBridge.eval(js_code)

	# Poll for file content
	_poll_for_uploaded_file()


func _poll_for_uploaded_file() -> void:
	# Check if file is ready
	var check_code = "window._godotUploadReady === true"
	var is_ready = JavaScriptBridge.eval(check_code)

	if is_ready:
		# Get the content
		var content = JavaScriptBridge.eval("window._godotUploadedFileContent")

		# Clear the JavaScript variables
		JavaScriptBridge.eval("window._godotUploadReady = false; window._godotUploadedFileContent = null;")

		# Put content in the text input
		if import_text_input and content:
			import_text_input.text = str(content)
			print("[MainMenu] File uploaded successfully")
	else:
		# Check again in 100ms
		get_tree().create_timer(0.1).timeout.connect(_poll_for_uploaded_file)
