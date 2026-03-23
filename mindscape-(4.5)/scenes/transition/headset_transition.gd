extends Control
## HeadsetTransition - Visual transition when putting on/removing the neural headset
## Creates an immersive first-person VR headset effect when traveling between bedroom and mindscape

@onready var background: ColorRect = $Background
@onready var vignette: ColorRect = $Vignette
@onready var center_ring: Polygon2D = $CenterEffects/Ring
@onready var center_glow: Polygon2D = $CenterEffects/Glow
@onready var particles_container: Node2D = $Particles
@onready var status_label: Label = $StatusLabel
@onready var subtitle_label: Label = $SubtitleLabel

# Transition settings
var transition_type: String = "enter"  # "enter" (to mindscape) or "exit" (to bedroom)
var target_scene: String = ""

# Animation state
var animation_time: float = 0.0
var phase: int = 0
var phase_duration: float = 0.0

# Phase timings
const HEADSET_EQUIP_TIME = 2.5  # Time for putting on/removing headset
const FADE_IN_TIME = 1.0
const HOLD_TIME = 1.2
const FADE_OUT_TIME = 0.5

# Headset container for unified movement
var headset_container: Node2D = null

# Visual settings
var ring_rotation: float = 0.0
var pulse_time: float = 0.0

# First-person headset visual elements
var headset_frame: Control = null
var left_hand: Node2D = null
var right_hand: Node2D = null
var headset_visor: Polygon2D = null
var headset_padding: Array = []


func _ready() -> void:
	# Get transition parameters
	transition_type = GameManager.player_data.get("transition_type", "enter")
	target_scene = GameManager.player_data.get("transition_target", "res://scenes/mindscape/mindscape_hub.tscn")

	# Clear the transition data
	GameManager.player_data.erase("transition_type")
	GameManager.player_data.erase("transition_target")

	# Set up visuals based on transition type
	_setup_transition()

	# Create first-person headset elements
	_create_headset_visuals()

	# Start animation
	phase = 0
	phase_duration = 0.0

	# Initial state
	if transition_type == "enter":
		# Start with visible scene, headset will come down
		modulate.a = 1.0
		_hide_neural_link_effects()
	else:
		# Start already in headset, will show neural link first
		modulate.a = 1.0
		_hide_headset_visuals()


func _process(delta: float) -> void:
	animation_time += delta
	phase_duration += delta

	if transition_type == "enter":
		_process_enter_animation(delta)
	else:
		_process_exit_animation(delta)


func _process_enter_animation(delta: float) -> void:
	## Animation sequence for ENTERING mindscape:
	## Phase 0: First-person headset equip animation
	## Phase 1: Fade in neural link effect
	## Phase 2: Hold neural link
	## Phase 3: Fade out to mindscape

	match phase:
		0:  # Headset equip animation
			var progress = phase_duration / HEADSET_EQUIP_TIME
			_animate_headset_equip(progress)

			if phase_duration >= HEADSET_EQUIP_TIME:
				phase = 1
				phase_duration = 0.0
				_show_neural_link_effects()

		1:  # Fade in neural link
			var progress = phase_duration / FADE_IN_TIME
			_animate_effects(delta, ease(progress, 0.3))

			if phase_duration >= FADE_IN_TIME:
				phase = 2
				phase_duration = 0.0

		2:  # Hold neural link
			_animate_effects(delta, 1.0)

			if phase_duration >= HOLD_TIME:
				phase = 3
				phase_duration = 0.0

		3:  # Fade out
			var progress = phase_duration / FADE_OUT_TIME
			_animate_effects(delta, 1.0 - ease(progress, 0.3))
			modulate.a = 1.0 - ease(progress, 0.5)

			if phase_duration >= FADE_OUT_TIME:
				_complete_transition()


func _process_exit_animation(delta: float) -> void:
	## Animation sequence for EXITING mindscape:
	## Phase 0: Fade in neural link disconnection
	## Phase 1: Hold neural link
	## Phase 2: Fade out neural link
	## Phase 3: Headset removal animation

	match phase:
		0:  # Fade in neural link
			var progress = phase_duration / FADE_IN_TIME
			_animate_effects(delta, ease(progress, 0.3))
			modulate.a = ease(progress, 0.3)

			if phase_duration >= FADE_IN_TIME:
				phase = 1
				phase_duration = 0.0

		1:  # Hold neural link
			_animate_effects(delta, 1.0)

			if phase_duration >= HOLD_TIME:
				phase = 2
				phase_duration = 0.0

		2:  # Fade out neural link
			var progress = phase_duration / FADE_OUT_TIME
			_animate_effects(delta, 1.0 - ease(progress, 0.3))

			if phase_duration >= FADE_OUT_TIME:
				phase = 3
				phase_duration = 0.0
				_hide_neural_link_effects()
				_show_headset_visuals()

		3:  # Headset removal animation
			var progress = phase_duration / HEADSET_EQUIP_TIME
			_animate_headset_remove(progress)

			if phase_duration >= HEADSET_EQUIP_TIME:
				_complete_transition()


func _create_headset_visuals() -> void:
	## Create first-person VR headset visual - headset held in front, brought to face
	headset_frame = Control.new()
	headset_frame.name = "HeadsetFrame"
	headset_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(headset_frame)

	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2

	# Main container that holds headset + hands together
	headset_container = Node2D.new()
	headset_container.name = "HeadsetContainer"
	headset_container.position = center
	headset_frame.add_child(headset_container)

	# The headset itself (visor)
	var visor_container = Node2D.new()
	visor_container.name = "VisorContainer"
	headset_container.add_child(visor_container)

	# Headset outer shell - the recognizable VR headset shape
	var shell_width = 400
	var shell_height = 220

	# Main body of headset
	headset_visor = Polygon2D.new()
	headset_visor.name = "Visor"
	headset_visor.polygon = _create_rounded_rect(-shell_width/2, -shell_height/2, shell_width, shell_height, 30)
	headset_visor.color = Color(0.12, 0.12, 0.15, 1.0)
	visor_container.add_child(headset_visor)

	# Front face plate (darker, where lenses would be)
	var faceplate = Polygon2D.new()
	faceplate.polygon = _create_rounded_rect(-shell_width/2 + 15, -shell_height/2 + 15, shell_width - 30, shell_height - 30, 20)
	faceplate.color = Color(0.06, 0.06, 0.08, 1.0)
	visor_container.add_child(faceplate)

	# Two eye lenses (the distinctive VR look)
	var lens_width = 120
	var lens_height = 100
	var lens_spacing = 70
	for side in [-1, 1]:
		var lens = Polygon2D.new()
		lens.name = "Lens_" + ("L" if side < 0 else "R")
		var lens_x = side * lens_spacing
		lens.polygon = _create_rounded_rect(lens_x - lens_width/2, -lens_height/2, lens_width, lens_height, 15)
		lens.color = Color(0.02, 0.03, 0.05, 1.0)
		visor_container.add_child(lens)

		# Lens glow ring
		var lens_glow = Line2D.new()
		lens_glow.name = "LensGlow_" + ("L" if side < 0 else "R")
		lens_glow.points = _create_rounded_rect(lens_x - lens_width/2, -lens_height/2, lens_width, lens_height, 15)
		lens_glow.width = 3.0
		lens_glow.default_color = Color(0.3, 0.6, 0.9, 0.6) if transition_type == "enter" else Color(0.9, 0.7, 0.3, 0.6)
		visor_container.add_child(lens_glow)

	# Head straps extending to sides
	for side in [-1, 1]:
		var strap = Polygon2D.new()
		strap.name = "Strap_" + ("L" if side < 0 else "R")
		var strap_start = side * (shell_width / 2)
		strap.polygon = PackedVector2Array([
			Vector2(strap_start, -40),
			Vector2(strap_start + side * 80, -50),
			Vector2(strap_start + side * 120, -30),
			Vector2(strap_start + side * 120, 30),
			Vector2(strap_start + side * 80, 50),
			Vector2(strap_start, 40)
		])
		strap.color = Color(0.18, 0.18, 0.22, 0.95)
		visor_container.add_child(strap)

	# LED indicators on top
	for i in range(3):
		var led = Polygon2D.new()
		led.name = "LED_" + str(i)
		led.polygon = _create_diamond(5)
		led.position = Vector2((i - 1) * 30, -shell_height/2 - 5)
		led.color = Color(0.2, 0.3, 0.35, 0.6)
		visor_container.add_child(led)

	# Brand text
	var brand = Label.new()
	brand.text = "NEURAL-VR"
	brand.position = Vector2(-45, -shell_height/2 + 25)
	brand.add_theme_font_size_override("font_size", 10)
	brand.add_theme_color_override("font_color", Color(0.3, 0.35, 0.4, 0.7))
	visor_container.add_child(brand)

	# Hands gripping the sides of the headset
	left_hand = _create_hand_visual()
	left_hand.name = "LeftHand"
	left_hand.scale = Vector2(-1.0, 1.0)
	left_hand.rotation = 0.3  # Angled to grip
	headset_container.add_child(left_hand)

	right_hand = _create_hand_visual()
	right_hand.name = "RightHand"
	right_hand.rotation = -0.3
	headset_container.add_child(right_hand)

	# Instruction label
	var instruction_label = Label.new()
	instruction_label.name = "InstructionLabel"
	instruction_label.text = "Putting on Neural Headset..." if transition_type == "enter" else "Removing Neural Headset..."
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	instruction_label.position = Vector2(-150, 30)
	instruction_label.custom_minimum_size = Vector2(300, 30)
	instruction_label.add_theme_font_size_override("font_size", 16)
	instruction_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9, 0.9))
	headset_frame.add_child(instruction_label)

	# Set initial positions based on transition type
	if transition_type == "enter":
		# Headset starts in front of view (small, as if held at arm's length)
		headset_container.scale = Vector2(0.4, 0.4)
		headset_container.position = center + Vector2(0, 50)
		# Hands positioned to grip sides
		left_hand.position = Vector2(-280, 20)
		right_hand.position = Vector2(280, 20)
		instruction_label.modulate.a = 1.0
	else:
		# Headset covers view completely
		headset_container.scale = Vector2(3.0, 3.0)
		headset_container.position = center
		left_hand.position = Vector2(-350, 30)
		right_hand.position = Vector2(350, 30)
		instruction_label.modulate.a = 0



func _create_diamond(size: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -size), Vector2(size, 0),
		Vector2(0, size), Vector2(-size, 0)
	])


func _create_hand_visual() -> Node2D:
	## Create a detailed first-person alien hand visual
	var hand_container = Node2D.new()

	# Arm/wrist section (shows it's attached to player)
	var arm = Polygon2D.new()
	arm.name = "Arm"
	arm.polygon = PackedVector2Array([
		Vector2(-35, 120), Vector2(35, 120),
		Vector2(40, 80), Vector2(40, 60),
		Vector2(-40, 60), Vector2(-40, 80)
	])
	arm.color = Color(0.35, 0.55, 0.45, 0.98)  # Goactorian skin
	hand_container.add_child(arm)

	# Sleeve cuff (shows clothing)
	var sleeve = Polygon2D.new()
	sleeve.name = "Sleeve"
	sleeve.polygon = PackedVector2Array([
		Vector2(-42, 125), Vector2(42, 125),
		Vector2(40, 115), Vector2(-40, 115)
	])
	sleeve.color = Color(0.2, 0.25, 0.35, 0.95)  # Dark fabric
	hand_container.add_child(sleeve)

	# Palm
	var palm = Polygon2D.new()
	palm.name = "Palm"
	palm.polygon = PackedVector2Array([
		Vector2(-38, 60), Vector2(38, 60),
		Vector2(42, 20), Vector2(40, -15),
		Vector2(30, -25), Vector2(-30, -25),
		Vector2(-40, -15), Vector2(-42, 20)
	])
	palm.color = Color(0.4, 0.62, 0.52, 0.98)
	hand_container.add_child(palm)

	# Palm highlight
	var palm_highlight = Polygon2D.new()
	palm_highlight.polygon = PackedVector2Array([
		Vector2(-20, 40), Vector2(15, 40),
		Vector2(20, 10), Vector2(-15, 10)
	])
	palm_highlight.color = Color(0.5, 0.7, 0.6, 0.3)
	hand_container.add_child(palm_highlight)

	# Fingers (individual for clarity)
	var finger_data = [
		{"x": 28, "len": 50, "width": 12},   # Index
		{"x": 10, "len": 60, "width": 13},   # Middle
		{"x": -10, "len": 55, "width": 12},  # Ring
		{"x": -28, "len": 45, "width": 11},  # Pinky
	]

	for i in range(finger_data.size()):
		var fd = finger_data[i]
		var finger = Polygon2D.new()
		finger.name = "Finger_" + str(i)
		var fx = fd.x
		var fl = fd.len
		var fw = fd.width
		finger.polygon = PackedVector2Array([
			Vector2(fx - fw/2, -20),
			Vector2(fx + fw/2, -20),
			Vector2(fx + fw/2 - 2, -20 - fl + 8),
			Vector2(fx, -20 - fl),  # Fingertip
			Vector2(fx - fw/2 + 2, -20 - fl + 8),
		])
		finger.color = Color(0.4, 0.62, 0.52, 0.98)
		hand_container.add_child(finger)

		# Fingernail
		var nail = Polygon2D.new()
		nail.polygon = PackedVector2Array([
			Vector2(fx - 4, -20 - fl + 12),
			Vector2(fx + 4, -20 - fl + 12),
			Vector2(fx + 3, -20 - fl + 4),
			Vector2(fx, -20 - fl + 2),
			Vector2(fx - 3, -20 - fl + 4),
		])
		nail.color = Color(0.5, 0.7, 0.6, 0.8)
		hand_container.add_child(nail)

		# Finger joint lines
		var joint = Line2D.new()
		joint.points = [Vector2(fx - fw/2 + 2, -20 - fl/3), Vector2(fx + fw/2 - 2, -20 - fl/3)]
		joint.width = 1.5
		joint.default_color = Color(0.3, 0.45, 0.4, 0.4)
		hand_container.add_child(joint)

	# Thumb (positioned to side, curved)
	var thumb = Polygon2D.new()
	thumb.name = "Thumb"
	thumb.polygon = PackedVector2Array([
		Vector2(40, 15), Vector2(48, 5),
		Vector2(60, -15), Vector2(65, -30),
		Vector2(62, -38), Vector2(55, -35),
		Vector2(48, -25), Vector2(42, -10),
		Vector2(38, 5)
	])
	thumb.color = Color(0.4, 0.62, 0.52, 0.98)
	hand_container.add_child(thumb)

	# Thumb nail
	var thumb_nail = Polygon2D.new()
	thumb_nail.polygon = PackedVector2Array([
		Vector2(58, -28), Vector2(63, -32),
		Vector2(60, -36), Vector2(55, -32)
	])
	thumb_nail.color = Color(0.5, 0.7, 0.6, 0.8)
	hand_container.add_child(thumb_nail)

	# Overall shadow
	var shadow = Polygon2D.new()
	shadow.polygon = palm.polygon
	shadow.color = Color(0.2, 0.3, 0.25, 0.25)
	shadow.position = Vector2(4, 4)
	shadow.z_index = -1
	hand_container.add_child(shadow)

	return hand_container


func _create_rounded_rect(x: float, y: float, w: float, h: float, radius: float) -> PackedVector2Array:
	## Create a rounded rectangle polygon
	var points = PackedVector2Array()
	var segments = 8

	# Top-left corner
	for i in range(segments + 1):
		var angle = PI + (i / float(segments)) * (PI / 2)
		points.append(Vector2(x + radius + cos(angle) * radius, y + radius + sin(angle) * radius))

	# Top-right corner
	for i in range(segments + 1):
		var angle = -PI/2 + (i / float(segments)) * (PI / 2)
		points.append(Vector2(x + w - radius + cos(angle) * radius, y + radius + sin(angle) * radius))

	# Bottom-right corner
	for i in range(segments + 1):
		var angle = 0 + (i / float(segments)) * (PI / 2)
		points.append(Vector2(x + w - radius + cos(angle) * radius, y + h - radius + sin(angle) * radius))

	# Bottom-left corner
	for i in range(segments + 1):
		var angle = PI/2 + (i / float(segments)) * (PI / 2)
		points.append(Vector2(x + radius + cos(angle) * radius, y + h - radius + sin(angle) * radius))

	return points


func _animate_headset_equip(progress: float) -> void:
	## Animate putting on the headset - held in front, brought to face
	if not headset_container:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2
	var instruction_label = headset_frame.get_node_or_null("InstructionLabel")
	var visor = headset_container.get_node_or_null("VisorContainer")

	# Smooth easing
	var eased = ease(progress, 0.3)

	# Instruction label fades in then out
	if instruction_label:
		if progress < 0.15:
			instruction_label.modulate.a = ease(progress / 0.15, 0.5)
		elif progress > 0.75:
			instruction_label.modulate.a = 1.0 - ease((progress - 0.75) / 0.25, 0.5)
		else:
			instruction_label.modulate.a = 1.0

	# Main animation: headset scales up as if being brought to face
	# Scale from 0.4 (arm's length) to 3.0 (covering view)
	var start_scale = 0.4
	var end_scale = 3.5
	var current_scale = lerp(start_scale, end_scale, ease(eased, 0.4))
	headset_container.scale = Vector2(current_scale, current_scale)

	# Slight vertical movement (down slightly as it approaches)
	var start_y = center.y + 50
	var end_y = center.y - 20
	headset_container.position.y = lerp(start_y, end_y, eased)
	headset_container.position.x = center.x

	# Hands move outward as headset gets closer (perspective effect)
	if left_hand and right_hand:
		# Hand positions relative to headset container
		var hand_start_x = 280  # Close together when headset is far
		var hand_end_x = 400    # Spread wide when headset is close
		var hand_x = lerp(hand_start_x, hand_end_x, eased)

		left_hand.position.x = -hand_x
		right_hand.position.x = hand_x

		# Hands move down slightly and rotate as headset approaches
		var hand_y = lerp(20.0, 60.0, eased)
		left_hand.position.y = hand_y
		right_hand.position.y = hand_y

		# Hands rotate outward as they spread
		var hand_rotation = lerp(0.3, 0.5, eased)
		left_hand.rotation = hand_rotation
		right_hand.rotation = -hand_rotation

		# Hands fade out as headset fills view (they'd be behind the headset)
		var hand_alpha = 1.0 - ease(max(0, (progress - 0.6) / 0.4), 0.5)
		left_hand.modulate.a = hand_alpha
		right_hand.modulate.a = hand_alpha

	# Animate lens glows
	if visor:
		for side in ["L", "R"]:
			var glow = visor.get_node_or_null("LensGlow_" + side)
			if glow:
				var pulse = sin(progress * PI * 5) * 0.2 + 0.8
				glow.default_color.a = pulse * min(1.0, progress * 2)
				glow.width = 2.0 + eased * 4.0

		# LEDs turn on progressively
		for i in range(3):
			var led = visor.get_node_or_null("LED_" + str(i))
			if led:
				var threshold = 0.2 + i * 0.2
				if progress > threshold:
					var intensity = min(1.0, (progress - threshold) * 5)
					led.color = Color(0.2, 0.8, 0.5, intensity)
				else:
					led.color = Color(0.2, 0.3, 0.35, 0.5)

	# Background darkens as headset covers view
	if progress > 0.5:
		var dark_progress = (progress - 0.5) / 0.5
		background.color = Color(0.05, 0.06, 0.08, 1.0).lerp(Color(0.02, 0.03, 0.05, 1.0), ease(dark_progress, 0.5))
		if vignette:
			vignette.modulate.a = ease(dark_progress, 0.3) * 0.6


func _animate_headset_remove(progress: float) -> void:
	## Animate removing the headset - pulled away from face
	if not headset_container:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2
	var instruction_label = headset_frame.get_node_or_null("InstructionLabel")
	var visor = headset_container.get_node_or_null("VisorContainer")

	# Smooth easing
	var eased = ease(progress, 0.35)

	# Instruction label
	if instruction_label:
		instruction_label.text = "Removing Neural Headset..."
		if progress < 0.15:
			instruction_label.modulate.a = ease(progress / 0.15, 0.5)
		elif progress > 0.8:
			instruction_label.modulate.a = 1.0 - ease((progress - 0.8) / 0.2, 0.5)
		else:
			instruction_label.modulate.a = 1.0

	# Headset scales down as if being pulled away from face
	var start_scale = 3.5
	var end_scale = 0.3  # Smaller than enter, as if being set aside
	var current_scale = lerp(start_scale, end_scale, ease(eased, 0.4))
	headset_container.scale = Vector2(current_scale, current_scale)

	# Move down and away
	var start_y = center.y - 20
	var end_y = center.y + 100
	headset_container.position.y = lerp(start_y, end_y, eased)
	headset_container.position.x = center.x

	# Hands come together as headset moves away
	if left_hand and right_hand:
		# Hands fade in first (they were behind the headset)
		var hand_alpha = ease(min(1.0, progress * 3), 0.5)
		left_hand.modulate.a = hand_alpha
		right_hand.modulate.a = hand_alpha

		# Hand positions - move inward as headset pulls away
		var hand_start_x = 400
		var hand_end_x = 250
		var hand_x = lerp(hand_start_x, hand_end_x, eased)

		left_hand.position.x = -hand_x
		right_hand.position.x = hand_x

		# Hands move up slightly
		var hand_y = lerp(60.0, 10.0, eased)
		left_hand.position.y = hand_y
		right_hand.position.y = hand_y

		# Hands rotate inward
		var hand_rotation = lerp(0.5, 0.2, eased)
		left_hand.rotation = hand_rotation
		right_hand.rotation = -hand_rotation

	# LEDs turn off progressively (reverse order)
	if visor:
		for side in ["L", "R"]:
			var glow = visor.get_node_or_null("LensGlow_" + side)
			if glow:
				# Flicker and fade out
				var flicker = sin(progress * 20) * 0.2
				var fade = 1.0 - eased
				glow.default_color.a = max(0, fade + flicker) * 0.8
				glow.width = 2.0 + (1.0 - eased) * 4.0

		for i in range(3):
			var led = visor.get_node_or_null("LED_" + str(2 - i))  # Reverse order
			if led:
				var threshold = 0.15 + i * 0.2
				if progress > threshold:
					# Flicker before turning off
					var flicker = sin(progress * 30 + i * 2) > 0
					var intensity = max(0, 1.0 - (progress - threshold) * 3)
					led.color = Color(0.2, 0.8 * intensity, 0.5 * intensity, 0.5 + intensity * 0.5) if flicker else Color(0.2, 0.3, 0.35, 0.5)
				else:
					led.color = Color(0.2, 0.8, 0.5, 0.95)

	# Background lightens as headset is removed
	if progress > 0.3:
		var light_progress = (progress - 0.3) / 0.7
		background.color = Color(0.02, 0.03, 0.05, 1.0).lerp(Color(0.08, 0.07, 0.06, 1.0), ease(light_progress, 0.5))
		background.modulate.a = 1.0 - ease(light_progress, 0.6) * 0.7
		if vignette:
			vignette.modulate.a = 0.5 * (1.0 - light_progress)


func _hide_headset_visuals() -> void:
	if headset_frame:
		headset_frame.visible = false


func _show_headset_visuals() -> void:
	if headset_frame:
		headset_frame.visible = true


func _hide_neural_link_effects() -> void:
	if center_ring:
		center_ring.visible = false
	if center_glow:
		center_glow.visible = false
	if particles_container:
		particles_container.visible = false
	if status_label:
		status_label.visible = false
	if subtitle_label:
		subtitle_label.visible = false


func _show_neural_link_effects() -> void:
	if center_ring:
		center_ring.visible = true
	if center_glow:
		center_glow.visible = true
	if particles_container:
		particles_container.visible = true
	if status_label:
		status_label.visible = true
	if subtitle_label:
		subtitle_label.visible = true
	_hide_headset_visuals()


func _setup_transition() -> void:
	if transition_type == "enter":
		# Entering mindscape - blue/cyan theme
		background.color = Color(0.02, 0.04, 0.08, 1)
		center_glow.color = Color(0.3, 0.6, 0.9, 0.6)
		center_ring.color = Color(0.4, 0.7, 1.0, 0.8)
		status_label.text = "NEURAL LINK ACTIVATING"
		subtitle_label.text = "Connecting to mindscape..."
		status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		subtitle_label.add_theme_color_override("font_color", Color(0.4, 0.6, 0.8))
		_create_particles(Color(0.4, 0.7, 1.0, 0.8))
	else:
		# Exiting to bedroom - gold/warm theme
		background.color = Color(0.06, 0.04, 0.02, 1)
		center_glow.color = Color(0.9, 0.7, 0.3, 0.6)
		center_ring.color = Color(1.0, 0.8, 0.4, 0.8)
		status_label.text = "NEURAL LINK DISCONNECTING"
		subtitle_label.text = "Returning to reality..."
		status_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
		subtitle_label.add_theme_color_override("font_color", Color(0.8, 0.65, 0.35))
		_create_particles(Color(1.0, 0.8, 0.4, 0.8))


func _create_particles(color: Color) -> void:
	# Create floating particles
	for i in range(20):
		var particle = Polygon2D.new()
		var size = randf_range(3, 8)
		particle.polygon = PackedVector2Array([
			Vector2(-size, 0), Vector2(0, -size),
			Vector2(size, 0), Vector2(0, size)
		])
		particle.color = Color(color.r, color.g, color.b, randf_range(0.3, 0.7))

		# Random position in a ring pattern
		var angle = randf() * TAU
		var distance = randf_range(100, 400)
		particle.position = Vector2(cos(angle), sin(angle)) * distance
		particle.set_meta("base_angle", angle)
		particle.set_meta("distance", distance)
		particle.set_meta("speed", randf_range(0.3, 0.8))

		particles_container.add_child(particle)


func _animate_effects(delta: float, intensity: float) -> void:
	pulse_time += delta
	ring_rotation += delta * 0.5

	# Rotate and pulse the ring
	if center_ring and center_ring.visible:
		center_ring.rotation = ring_rotation
		var pulse = (sin(pulse_time * 3.0) + 1.0) / 2.0
		var scale_val = 0.8 + pulse * 0.4 * intensity
		center_ring.scale = Vector2(scale_val, scale_val)

	# Pulse the glow
	if center_glow and center_glow.visible:
		var glow_pulse = (sin(pulse_time * 2.0) + 1.0) / 2.0
		center_glow.modulate.a = (0.4 + glow_pulse * 0.6) * intensity
		var glow_scale = 1.0 + glow_pulse * 0.3 * intensity
		center_glow.scale = Vector2(glow_scale, glow_scale)

	# Animate particles - spiral inward or outward
	for particle in particles_container.get_children():
		var base_angle = particle.get_meta("base_angle", 0.0)
		var base_distance = particle.get_meta("distance", 200.0)
		var speed = particle.get_meta("speed", 0.5)

		# Spiral motion
		var current_angle = base_angle + animation_time * speed
		var distance_modifier = 1.0

		if transition_type == "enter":
			# Particles spiral inward when entering mindscape
			distance_modifier = 1.0 - (intensity * 0.5)
		else:
			# Particles spiral outward when exiting
			distance_modifier = 1.0 + (intensity * 0.3)

		var current_distance = base_distance * distance_modifier
		particle.position = Vector2(cos(current_angle), sin(current_angle)) * current_distance
		particle.modulate.a = intensity
		particle.rotation = current_angle

	# Animate labels
	if status_label and status_label.visible:
		var label_pulse = (sin(pulse_time * 4.0) + 1.0) / 2.0
		status_label.modulate.a = (0.7 + label_pulse * 0.3) * intensity

	if subtitle_label and subtitle_label.visible:
		subtitle_label.modulate.a = intensity * 0.8


func _complete_transition() -> void:
	# Stop any playing voice audio when transitioning
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()

	# Transition to target scene
	if target_scene != "":
		if "mindscape" in target_scene:
			GameManager.change_state(GameManager.GameState.MINDSCAPE)
		# Bedroom/ship scenes don't need a state change - they manage their own state
		get_tree().change_scene_to_file(target_scene)
	else:
		# Fallback to mindscape hub
		GameManager.change_state(GameManager.GameState.MINDSCAPE)
		get_tree().change_scene_to_file("res://scenes/mindscape/mindscape_hub.tscn")
