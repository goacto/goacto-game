extends Control
## HeadsetTransition - Visual transition when putting on/removing the neural headset
## First-person VR goggles: two hands raise headset from below, dual lenses narrow to black

@onready var background: ColorRect = $Background
@onready var vignette: ColorRect = $Vignette
@onready var center_ring: Polygon2D = $CenterEffects/Ring
@onready var center_glow: Polygon2D = $CenterEffects/Glow
@onready var particles_container: Node2D = $Particles
@onready var status_label: Label = $StatusLabel
@onready var subtitle_label: Label = $SubtitleLabel

# Transition settings
var transition_type: String = "enter"
var target_scene: String = ""

# Animation state
var animation_time: float = 0.0
var phase: int = 0
var phase_duration: float = 0.0

# Phase timings
const HEADSET_ON_TIME = 2.6
const FADE_IN_TIME = 1.0
const HOLD_TIME = 1.8
const FADE_OUT_TIME = 0.8
const HEADSET_OFF_TIME = 2.2

# Visual settings
var ring_rotation: float = 0.0
var pulse_time: float = 0.0

# Headset nodes
var headset_container: Node2D = null
var headset_frame_pieces: Array = []  # The dark mask pieces around lenses
var left_lens_rim: Node2D = null
var right_lens_rim: Node2D = null
var left_hand: Node2D = null
var right_hand: Node2D = null
var strap_left: Polygon2D = null
var strap_right: Polygon2D = null
var nose_bridge_visual: Polygon2D = null
var light_leak_top: Polygon2D = null

var vp_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	transition_type = GameManager.player_data.get("transition_type", "enter")
	target_scene = GameManager.player_data.get("transition_target", "res://scenes/mindscape/mindscape_hub.tscn")
	GameManager.player_data.erase("transition_type")
	GameManager.player_data.erase("transition_target")

	vp_size = get_viewport_rect().size
	var center = vp_size / 2.0
	$CenterEffects.position = center
	$Particles.position = center
	status_label.offset_top = center.y + 120
	status_label.offset_bottom = center.y + 160
	subtitle_label.offset_top = center.y + 170
	subtitle_label.offset_bottom = center.y + 210

	_build_headset()
	_setup_transition()

	phase = 0
	phase_duration = 0.0

	if transition_type == "enter":
		modulate.a = 1.0
		_set_portal_visible(false)
		_position_headset(0.0)
		background.color = Color(0, 0, 0, 0)
	else:
		modulate.a = 1.0
		_set_portal_visible(true)
		headset_container.visible = false


func _process(delta: float) -> void:
	animation_time += delta
	phase_duration += delta
	if transition_type == "enter":
		_process_enter(delta)
	else:
		_process_exit(delta)


func _process_enter(delta: float) -> void:
	match phase:
		0:  # Headset rising from below
			var progress = clamp(phase_duration / HEADSET_ON_TIME, 0.0, 1.0)
			_position_headset(_ease_in_out(progress))
			if phase_duration >= HEADSET_ON_TIME:
				phase = 1
				phase_duration = 0.0
				_set_portal_visible(true)
				_setup_transition_colors()
				headset_container.visible = false
				background.color = Color(0.02, 0.04, 0.08, 1)
		1:
			var progress = clamp(phase_duration / FADE_IN_TIME, 0.0, 1.0)
			_animate_effects(delta, ease(progress, 0.3))
			status_label.modulate.a = progress
			subtitle_label.modulate.a = progress * 0.8
			if phase_duration >= FADE_IN_TIME:
				phase = 2
				phase_duration = 0.0
		2:
			_animate_effects(delta, 1.0)
			if phase_duration >= HOLD_TIME:
				phase = 3
				phase_duration = 0.0
		3:
			var progress = clamp(phase_duration / FADE_OUT_TIME, 0.0, 1.0)
			_animate_effects(delta, 1.0 - progress)
			status_label.modulate.a = 1.0 - progress
			subtitle_label.modulate.a = (1.0 - progress) * 0.8
			if phase_duration >= FADE_OUT_TIME:
				_complete_transition()


func _process_exit(delta: float) -> void:
	match phase:
		0:
			var progress = clamp(phase_duration / FADE_IN_TIME, 0.0, 1.0)
			_animate_effects(delta, ease(progress, 0.3))
			status_label.modulate.a = progress
			subtitle_label.modulate.a = progress * 0.8
			if phase_duration >= FADE_IN_TIME:
				phase = 1
				phase_duration = 0.0
		1:
			_animate_effects(delta, 1.0)
			if phase_duration >= HOLD_TIME:
				phase = 2
				phase_duration = 0.0
		2:
			var progress = clamp(phase_duration / FADE_OUT_TIME, 0.0, 1.0)
			_animate_effects(delta, 1.0 - progress)
			status_label.modulate.a = 1.0 - progress
			subtitle_label.modulate.a = (1.0 - progress) * 0.8
			if phase_duration >= FADE_OUT_TIME:
				phase = 3
				phase_duration = 0.0
				_set_portal_visible(false)
				headset_container.visible = true
				_position_headset(1.0)
				background.color = Color(0, 0, 0, 0)
		3:
			var progress = clamp(phase_duration / HEADSET_OFF_TIME, 0.0, 1.0)
			_position_headset(1.0 - _ease_in_out(progress))
			if phase_duration >= HEADSET_OFF_TIME:
				_complete_transition()


# ===========================================================================
# HEADSET CONSTRUCTION
# ===========================================================================

func _build_headset() -> void:
	var vw = vp_size.x
	var vh = vp_size.y
	var cx = vw / 2.0
	var cy = vh / 2.0

	headset_container = Node2D.new()
	headset_container.name = "HeadsetContainer"
	headset_container.z_index = 50
	add_child(headset_container)

	# Lens parameters
	var lens_rx = vw * 0.19      # lens horizontal radius
	var lens_ry = vh * 0.30      # lens vertical radius
	var lens_gap = vw * 0.04     # half-gap between lenses (nose bridge)
	var left_cx = cx - lens_rx - lens_gap
	var right_cx = cx + lens_rx + lens_gap
	var lens_cy = cy * 0.92      # slightly above center

	var shell = Color(0.03, 0.03, 0.05, 1.0)
	var foam = Color(0.06, 0.05, 0.08, 1.0)

	# --- FRAME MASK: 5 dark regions around the two lens openings ---
	# Top bar (above both lenses)
	_add_frame_rect(0, 0, vw, lens_cy - lens_ry - 12, shell)
	# Bottom bar (below both lenses)
	_add_frame_rect(0, lens_cy + lens_ry + 12, vw, vh - (lens_cy + lens_ry + 12), shell)
	# Left bar (left of left lens)
	_add_frame_rect(0, lens_cy - lens_ry - 12, left_cx - lens_rx - 8, lens_ry * 2 + 24, shell)
	# Right bar (right of right lens)
	var right_start = right_cx + lens_rx + 8
	_add_frame_rect(right_start, lens_cy - lens_ry - 12, vw - right_start, lens_ry * 2 + 24, shell)
	# Nose bridge (between lenses)
	var bridge_left = left_cx + lens_rx + 4
	var bridge_right = right_cx - lens_rx - 4
	_add_frame_rect(bridge_left, lens_cy - lens_ry * 0.55, bridge_right - bridge_left, lens_ry * 1.1, shell)

	# --- FOAM PADDING around each lens (thick rings) ---
	left_lens_rim = _create_oval_ring(left_cx, lens_cy, lens_rx, lens_ry, lens_rx + 14, lens_ry + 14, foam, 48)
	headset_container.add_child(left_lens_rim)
	right_lens_rim = _create_oval_ring(right_cx, lens_cy, lens_rx, lens_ry, lens_rx + 14, lens_ry + 14, foam, 48)
	headset_container.add_child(right_lens_rim)

	# Inner lens tint (very faint blue glow inside each lens)
	var lens_screen = Color(0.08, 0.14, 0.22, 0.35)
	var left_lens_fill = _create_oval(left_cx, lens_cy, lens_rx - 2, lens_ry - 2, lens_screen, 48)
	headset_container.add_child(left_lens_fill)
	var right_lens_fill = _create_oval(right_cx, lens_cy, lens_rx - 2, lens_ry - 2, lens_screen, 48)
	headset_container.add_child(right_lens_fill)

	# Lens fresnel rim (bright inner edge)
	var fresnel = Color(0.2, 0.35, 0.55, 0.2)
	var l_fresnel = _create_oval_ring(left_cx, lens_cy, lens_rx - 6, lens_ry - 6, lens_rx, lens_ry, fresnel, 48)
	headset_container.add_child(l_fresnel)
	var r_fresnel = _create_oval_ring(right_cx, lens_cy, lens_rx - 6, lens_ry - 6, lens_rx, lens_ry, fresnel, 48)
	headset_container.add_child(r_fresnel)

	# --- NOSE BRIDGE detail ---
	var bridge_cx = cx
	var bridge_cy = lens_cy + lens_ry * 0.15
	nose_bridge_visual = _create_oval(bridge_cx, bridge_cy, lens_gap + 8, lens_ry * 0.25, Color(0.05, 0.04, 0.07, 0.9), 24)
	headset_container.add_child(nose_bridge_visual)

	# --- HEADSET STRAP hints at top corners ---
	var strap_color = Color(0.07, 0.06, 0.09, 0.8)
	var strap_w = 30.0
	# Left strap
	strap_left = Polygon2D.new()
	strap_left.polygon = PackedVector2Array([
		Vector2(vw * 0.12, 0), Vector2(vw * 0.12 + strap_w, 0),
		Vector2(vw * 0.18 + strap_w, lens_cy - lens_ry - 10),
		Vector2(vw * 0.18, lens_cy - lens_ry - 10)
	])
	strap_left.color = strap_color
	headset_container.add_child(strap_left)
	# Right strap
	strap_right = Polygon2D.new()
	strap_right.polygon = PackedVector2Array([
		Vector2(vw * 0.88 - strap_w, 0), Vector2(vw * 0.88, 0),
		Vector2(vw * 0.82, lens_cy - lens_ry - 10),
		Vector2(vw * 0.82 - strap_w, lens_cy - lens_ry - 10)
	])
	strap_right.color = strap_color
	headset_container.add_child(strap_right)

	# --- HANDS gripping the sides of the headset (not blocking lenses) ---
	var hand_color = Color(0.83, 0.66, 0.29, 0.9)  # Match player character gold
	var wrist_color = Color(0.65, 0.50, 0.20, 0.9)  # Darker gold for sleeve

	# Position hands at outer edges of headset frame, gripping the sides
	var hand_y = lens_cy + lens_ry * 0.3  # mid-lower area of headset
	left_hand = _build_side_hand(left_cx - lens_rx - 40, hand_y, true, hand_color, wrist_color, vw, vh)
	headset_container.add_child(left_hand)

	right_hand = _build_side_hand(right_cx + lens_rx + 40, hand_y, false, hand_color, wrist_color, vw, vh)
	headset_container.add_child(right_hand)

	# --- SCAN LINES inside lenses (subtle digital screen effect) ---
	for lens_cx_pos in [left_cx, right_cx]:
		for j in range(12):
			var line_y = lens_cy - lens_ry * 0.8 + j * (lens_ry * 1.6 / 12)
			# Calculate width at this y position using ellipse equation
			var dy = abs(line_y - lens_cy)
			if dy >= lens_ry - 4:
				continue
			var half_w = lens_rx * sqrt(1.0 - (dy * dy) / ((lens_ry - 4) * (lens_ry - 4)))
			var scan = Polygon2D.new()
			scan.polygon = PackedVector2Array([
				Vector2(lens_cx_pos - half_w * 0.9, line_y),
				Vector2(lens_cx_pos + half_w * 0.9, line_y),
				Vector2(lens_cx_pos + half_w * 0.9, line_y + 1.5),
				Vector2(lens_cx_pos - half_w * 0.9, line_y + 1.5)
			])
			scan.color = Color(0.15, 0.22, 0.35, 0.08)
			headset_container.add_child(scan)

	# --- LIGHT LEAK at top edge (visible when headset is partially on) ---
	light_leak_top = Polygon2D.new()
	light_leak_top.polygon = PackedVector2Array([
		Vector2(vw * 0.15, 0), Vector2(vw * 0.85, 0),
		Vector2(vw * 0.80, 10), Vector2(vw * 0.20, 10)
	])
	light_leak_top.color = Color(0.6, 0.65, 0.75, 0.0)
	headset_container.add_child(light_leak_top)


func _build_side_hand(anchor_x: float, anchor_y: float, is_left: bool, skin: Color, sleeve: Color, vw: float, vh: float) -> Node2D:
	# Blocky geometric hand matching the character's low-poly style
	# Grips the side of the headset, turned sideways
	var hand_group = Node2D.new()
	var d = 1.0 if is_left else -1.0
	var sc = 1.6
	var lighter = Color(skin.r * 1.08, skin.g * 1.05, skin.b * 0.95, skin.a)
	var darker = Color(skin.r * 0.85, skin.g * 0.80, skin.b * 0.65, skin.a)

	# --- Forearm (blocky trapezoid from bottom corner) ---
	var arm_base_x = anchor_x - 80 * d
	var arm_base_y = vh + 120
	var arm = Polygon2D.new()
	arm.polygon = PackedVector2Array([
		Vector2(arm_base_x - 28 * sc, arm_base_y),
		Vector2(arm_base_x + 28 * sc, arm_base_y),
		Vector2(anchor_x + 20 * sc, anchor_y + 55 * sc),
		Vector2(anchor_x - 20 * sc, anchor_y + 55 * sc),
	])
	arm.color = sleeve
	hand_group.add_child(arm)

	# --- Wrist band (geometric transition) ---
	var wrist = Polygon2D.new()
	wrist.polygon = PackedVector2Array([
		Vector2(anchor_x - 22 * sc, anchor_y + 57 * sc),
		Vector2(anchor_x + 22 * sc, anchor_y + 57 * sc),
		Vector2(anchor_x + 20 * sc, anchor_y + 44 * sc),
		Vector2(anchor_x - 20 * sc, anchor_y + 44 * sc),
	])
	wrist.color = darker
	hand_group.add_child(wrist)

	# --- Palm (blocky rectangle, seen from the side/edge) ---
	var palm = Polygon2D.new()
	palm.polygon = PackedVector2Array([
		Vector2(anchor_x - 18 * sc, anchor_y + 46 * sc),
		Vector2(anchor_x + 18 * sc, anchor_y + 46 * sc),
		Vector2(anchor_x + 16 * sc, anchor_y - 25 * sc),
		Vector2(anchor_x - 16 * sc, anchor_y - 20 * sc),
	])
	palm.color = skin
	hand_group.add_child(palm)

	# --- Side edge highlight (to show the hand is turned) ---
	var edge = Polygon2D.new()
	var edge_x = anchor_x + 16 * sc * d
	edge.polygon = PackedVector2Array([
		Vector2(edge_x, anchor_y + 46 * sc),
		Vector2(edge_x + 6 * sc * d, anchor_y + 44 * sc),
		Vector2(edge_x + 5 * sc * d, anchor_y - 22 * sc),
		Vector2(edge_x, anchor_y - 25 * sc),
	])
	edge.color = lighter
	hand_group.add_child(edge)

	# --- Fingers: 3 blocky rectangles wrapping over the frame ---
	for i in range(3):
		var finger = Polygon2D.new()
		var fy = anchor_y - 22 * sc + i * 18 * sc
		var fx = anchor_x + 14 * sc * d
		var fl = 35.0 * sc
		var fw = 13.0 * sc

		# Blocky finger - simple rectangle curling inward
		finger.polygon = PackedVector2Array([
			Vector2(fx, fy - fw/2),
			Vector2(fx, fy + fw/2),
			Vector2(fx + fl * d, fy + fw/2),
			Vector2(fx + fl * d, fy - fw/2),
		])
		finger.color = lighter if i % 2 == 0 else skin
		hand_group.add_child(finger)

		# Finger tip (slightly darker block at end)
		var tip = Polygon2D.new()
		tip.polygon = PackedVector2Array([
			Vector2(fx + fl * d, fy - fw/2),
			Vector2(fx + fl * d, fy + fw/2),
			Vector2(fx + (fl + 8 * sc) * d, fy + fw/2 - 2 * sc),
			Vector2(fx + (fl + 8 * sc) * d, fy - fw/2 + 2 * sc),
		])
		tip.color = darker
		hand_group.add_child(tip)

	# --- Thumb (blocky block below palm on outside) ---
	var thumb = Polygon2D.new()
	var tx = anchor_x - 10 * sc * d
	var ty = anchor_y + 20 * sc
	thumb.polygon = PackedVector2Array([
		Vector2(tx, ty),
		Vector2(tx - 16 * sc * d, ty),
		Vector2(tx - 18 * sc * d, ty + 32 * sc),
		Vector2(tx - 2 * sc * d, ty + 35 * sc),
	])
	thumb.color = lighter
	hand_group.add_child(thumb)

	return hand_group


func _add_frame_rect(x: float, y: float, w: float, h: float, color: Color) -> void:
	if w <= 0 or h <= 0:
		return
	var rect = Polygon2D.new()
	rect.polygon = PackedVector2Array([
		Vector2(x, y), Vector2(x + w, y),
		Vector2(x + w, y + h), Vector2(x, y + h)
	])
	rect.color = color
	headset_frame_pieces.append(rect)
	headset_container.add_child(rect)


func _create_oval(cx: float, cy: float, rx: float, ry: float, color: Color, segments: int) -> Polygon2D:
	var poly = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(segments):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cx + cos(angle) * rx, cy + sin(angle) * ry))
	poly.polygon = points
	poly.color = color
	return poly


func _create_oval_ring(cx: float, cy: float, inner_rx: float, inner_ry: float, outer_rx: float, outer_ry: float, color: Color, segments: int) -> Node2D:
	# Individual quads forming a ring between inner and outer ovals
	var parent = Node2D.new()
	parent.name = "OvalRing"
	for i in range(segments):
		var a1 = (float(i) / segments) * TAU
		var a2 = (float(i + 1) / segments) * TAU
		var quad = Polygon2D.new()
		quad.polygon = PackedVector2Array([
			Vector2(cx + cos(a1) * outer_rx, cy + sin(a1) * outer_ry),
			Vector2(cx + cos(a2) * outer_rx, cy + sin(a2) * outer_ry),
			Vector2(cx + cos(a2) * inner_rx, cy + sin(a2) * inner_ry),
			Vector2(cx + cos(a1) * inner_rx, cy + sin(a1) * inner_ry),
		])
		quad.color = color
		parent.add_child(quad)
	# Return the parent Node2D (caller should add_child this)
	return parent


# ===========================================================================
# HEADSET ANIMATION
# ===========================================================================

func _position_headset(progress: float) -> void:
	# progress: 0 = headset below screen (hands + headset off-screen)
	#           1 = headset fully on face (lenses darkened, frame covers screen)
	if not headset_container:
		return

	headset_container.visible = true
	var vh = vp_size.y

	# Slide: at 0% the whole container is shifted down below screen
	# At ~50% the headset is in front of eyes (lenses visible)
	# At 100% the headset is fully seated

	var slide_y = (1.0 - progress) * vh * 1.1  # vertical offset
	headset_container.position = Vector2(0, slide_y)

	# Hand animation: hands grip the headset then slowly release and drop away
	# First 80%: hands stay with headset, slight inward grip
	# Last 20%: hands spread outward and drop as they let go
	var release_t = clamp((progress - 0.8) / 0.2, 0.0, 1.0)
	var grip_ease = release_t * release_t  # accelerate away
	var hand_spread = grip_ease * vp_size.x * 0.12
	var hand_drop = grip_ease * 120
	if left_hand:
		left_hand.position = Vector2(-hand_spread, hand_drop)
	if right_hand:
		right_hand.position = Vector2(hand_spread, hand_drop)

	# Hands fade out only in final 15%
	var hand_alpha = clamp(1.0 - (progress - 0.85) / 0.15, 0.0, 1.0)
	if left_hand:
		left_hand.modulate.a = hand_alpha
	if right_hand:
		right_hand.modulate.a = hand_alpha

	# Light leak: visible when headset is partially on (30-80%)
	if light_leak_top:
		var leak_alpha = 0.0
		if progress > 0.25 and progress < 0.85:
			leak_alpha = sin((progress - 0.25) / 0.6 * PI) * 0.35
		light_leak_top.color = Color(0.6, 0.65, 0.75, leak_alpha)

	# Frame opacity: darken as headset seats (lens fill gets more opaque)
	var darken = clamp((progress - 0.7) / 0.3, 0.0, 1.0)
	background.color = Color(0, 0, 0, darken * 0.95)


func _ease_in_out(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


# ===========================================================================
# PORTAL ANIMATION
# ===========================================================================

func _set_portal_visible(vis: bool) -> void:
	center_ring.visible = vis
	center_glow.visible = vis
	particles_container.visible = vis
	status_label.visible = vis
	subtitle_label.visible = vis


func _setup_transition() -> void:
	if transition_type == "enter":
		_setup_transition_colors()
	else:
		background.color = Color(0.06, 0.04, 0.02, 1)
		center_glow.color = Color(0.9, 0.7, 0.3, 0.6)
		center_ring.color = Color(1.0, 0.8, 0.4, 0.8)
		status_label.text = "NEURAL LINK DISCONNECTING"
		subtitle_label.text = "Returning to reality..."
		status_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
		subtitle_label.add_theme_color_override("font_color", Color(0.8, 0.65, 0.35))
		_create_particles(Color(1.0, 0.8, 0.4, 0.8))


func _setup_transition_colors() -> void:
	background.color = Color(0.02, 0.04, 0.08, 1)
	center_glow.color = Color(0.3, 0.6, 0.9, 0.6)
	center_ring.color = Color(0.4, 0.7, 1.0, 0.8)
	status_label.text = "NEURAL LINK ACTIVATING"
	subtitle_label.text = "Connecting to mindscape..."
	status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	subtitle_label.add_theme_color_override("font_color", Color(0.4, 0.6, 0.8))
	_create_particles(Color(0.4, 0.7, 1.0, 0.8))


func _create_particles(color: Color) -> void:
	for child in particles_container.get_children():
		child.queue_free()
	for i in range(20):
		var particle = Polygon2D.new()
		var s = randf_range(3, 8)
		particle.polygon = PackedVector2Array([
			Vector2(-s, 0), Vector2(0, -s), Vector2(s, 0), Vector2(0, s)
		])
		particle.color = Color(color.r, color.g, color.b, randf_range(0.3, 0.7))
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

	if center_ring:
		center_ring.rotation = ring_rotation
		var pulse = (sin(pulse_time * 3.0) + 1.0) / 2.0
		var scale_val = 0.8 + pulse * 0.4 * intensity
		center_ring.scale = Vector2(scale_val, scale_val)

	if center_glow:
		var glow_pulse = (sin(pulse_time * 2.0) + 1.0) / 2.0
		center_glow.modulate.a = (0.4 + glow_pulse * 0.6) * intensity
		var glow_scale = 1.0 + glow_pulse * 0.3 * intensity
		center_glow.scale = Vector2(glow_scale, glow_scale)

	for particle in particles_container.get_children():
		var base_angle = particle.get_meta("base_angle", 0.0)
		var base_distance = particle.get_meta("distance", 200.0)
		var speed = particle.get_meta("speed", 0.5)
		var current_angle = base_angle + animation_time * speed
		var dm = 1.0 - (intensity * 0.5) if transition_type == "enter" else 1.0 + (intensity * 0.3)
		particle.position = Vector2(cos(current_angle), sin(current_angle)) * base_distance * dm
		particle.modulate.a = intensity
		particle.rotation = current_angle

	if status_label:
		var lp = (sin(pulse_time * 4.0) + 1.0) / 2.0
		status_label.modulate.a = (0.7 + lp * 0.3) * intensity
	if subtitle_label:
		subtitle_label.modulate.a = intensity * 0.8


func _complete_transition() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_voice"):
		audio.stop_voice()
	if target_scene != "":
		if "mindscape" in target_scene:
			GameManager.change_state(GameManager.GameState.MINDSCAPE)
		get_tree().change_scene_to_file(target_scene)
	else:
		GameManager.change_state(GameManager.GameState.MINDSCAPE)
		get_tree().change_scene_to_file("res://scenes/mindscape/mindscape_hub.tscn")
