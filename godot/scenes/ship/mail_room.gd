extends Control
## Mail Room - Package receiving and collection area on the Stellar Wanderer
## Players collect orders from the Experience Shop here

# World elements
@onready var game_world: Control = $GameWorld
@onready var isometric_base: Node2D = $GameWorld/IsometricBase
@onready var player: Node2D = $GameWorld/IsometricBase/Player

# UI
@onready var interaction_prompt: PanelContainer = $InteractionPrompt
@onready var object_name_label: Label = $InteractionPrompt/Margin/VBox/ObjectName
@onready var prompt_text_label: Label = $InteractionPrompt/Margin/VBox/PromptText
@onready var control_hints: HBoxContainer = $ControlHints

# Dialogue
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var dialogue_title: Label = $DialoguePanel/Margin/VBox/DialogueTitle
@onready var dialogue_text: Label = $DialoguePanel/Margin/VBox/DialogueText
@onready var dialogue_button: Button = $DialoguePanel/Margin/VBox/DialogueButton

# Menu
@onready var menu_button: Button = $Header/Margin/HBox/MenuButton

# Fade transition
@onready var fade_overlay: ColorRect = $FadeOverlay

# Header controls
var volume_button: Button = null
var save_indicator: Label = null
var volume_popup: PanelContainer = null
var is_muted: bool = false

# Player movement
var player_speed: float = 250.0
var player_bounds: Rect2 = Rect2(-400, -200, 800, 450)

# Camera
var camera_zoom: float = 1.0
var min_zoom: float = 0.6
var max_zoom: float = 1.5
var zoom_speed: float = 0.08

# Interaction state
var nearby_object: String = ""
var in_dialogue: bool = false
var dialogue_callback: Callable

# Typing effect
var typing_tween: Tween = null
var dialogue_full_text: String = ""

# Animation
var animation_time: float = 0.0

# Movement sound
var move_sound_timer: float = 0.0
var move_sound_interval: float = 0.35
var is_moving: bool = false

# Mail notification glow
var mail_notification_node: Node2D = null

# Interactive objects in mail room
const INTERACTIVE_OBJECTS = {
	"Door": {
		"name": "Cargo Hold Door",
		"prompt": "Press SPACE to return to cargo hold",
		"action": "go_cargo_hold"
	},
	"PackageShelf": {
		"name": "Package Shelf",
		"prompt": "Press SPACE to check packages",
		"action": "check_packages"
	},
	"MailTerminal": {
		"name": "Delivery Terminal",
		"prompt": "Press SPACE to check orders",
		"action": "check_orders"
	},
	"SortingBot": {
		"name": "MX-7 Sorting Unit",
		"prompt": "Press SPACE to examine",
		"action": "examine_bot"
	}
}

# Object positions for proximity detection
var object_positions: Dictionary = {
	"Door": Vector2(-320, 50),
	"PackageShelf": Vector2(200, -50),
	"MailTerminal": Vector2(-100, -100),
	"SortingBot": Vector2(50, 100)
}


func _ready() -> void:
	# Connect dialogue button
	dialogue_button.pressed.connect(_close_dialogue)

	# Connect menu button
	menu_button.pressed.connect(_open_pause_menu)

	# Setup header controls
	_setup_header_controls()

	# Play ship music and ambient
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		if audio.has_method("play_music_ship"):
			audio.play_music_ship()
		if audio.has_method("play_ambient_ship"):
			audio.play_ambient_ship()

	# Hide UI initially
	interaction_prompt.visible = false
	dialogue_panel.visible = false

	# Setup mail notification visual
	_setup_mail_notification()

	# Center the view
	_update_camera()

	# Fade in
	_fade_in()

	# Show intro dialogue on first visit
	if not CampaignManager.has_seen_cutscene("mail_room_intro"):
		await get_tree().create_timer(0.6).timeout
		_show_dialogue("Mail Room", "The ship's receiving bay. Packages ordered from the Experience Shop arrive here.\n\nCheck the terminal for pending orders, and collect packages from the shelf when they arrive!")
		CampaignManager.mark_cutscene_seen("mail_room_intro")

	print("[MailRoom] Package receiving area ready")


func _fade_in() -> void:
	if fade_overlay:
		var tween = create_tween()
		tween.tween_property(fade_overlay, "color:a", 0.0, 0.5).set_ease(Tween.EASE_OUT)


func _setup_mail_notification() -> void:
	# Create a glow effect on the package shelf when mail is available
	mail_notification_node = Node2D.new()
	mail_notification_node.name = "MailNotification"
	mail_notification_node.position = object_positions.get("PackageShelf", Vector2.ZERO)
	isometric_base.add_child(mail_notification_node)

	# Glow circle
	var glow = Polygon2D.new()
	glow.name = "Glow"
	var points = PackedVector2Array()
	for i in range(20):
		var angle = (i / 20.0) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * 60)
	glow.polygon = points
	glow.color = Color(0.4, 0.9, 1.0, 0.0)  # Starts invisible
	mail_notification_node.add_child(glow)

	# Update visibility based on mail status
	_update_mail_notification()

	# Connect to mail signals
	if MailManager:
		MailManager.mail_count_changed.connect(_on_mail_count_changed)


func _update_mail_notification() -> void:
	if not mail_notification_node:
		return

	var has_mail = MailManager.has_mail() if MailManager else false
	var glow = mail_notification_node.get_node_or_null("Glow")
	if glow:
		glow.color.a = 0.3 if has_mail else 0.0


func _on_mail_count_changed(_count: int) -> void:
	_update_mail_notification()


func _process(delta: float) -> void:
	animation_time += delta

	# Animate environment
	_animate_environment(delta)

	if in_dialogue:
		return

	# Check object proximity
	_check_object_proximity()

	# Handle movement
	_handle_movement(delta)

	# Update camera
	_update_camera()


func _input(event: InputEvent) -> void:
	var viewport = get_viewport()
	if viewport == null:
		return

	# ESC handling
	if event.is_action_pressed("ui_cancel"):
		if volume_popup:
			_close_volume_popup()
			viewport.set_input_as_handled()
			return
		if pause_menu:
			_close_pause_menu()
			viewport.set_input_as_handled()
			return
		if mail_panel:
			_close_mail_panel()
			viewport.set_input_as_handled()
			return
		if orders_panel:
			_close_orders_panel()
			viewport.set_input_as_handled()
			return
		if dialogue_panel.visible:
			_close_dialogue()
			viewport.set_input_as_handled()
			return
		_open_pause_menu()
		viewport.set_input_as_handled()
		return

	# Block inputs when pause menu is open
	if pause_menu:
		return

	if in_dialogue:
		if event.is_action_pressed("ui_accept"):
			if dialogue_text.visible_ratio < 1.0:
				_skip_typing()
			else:
				_close_dialogue()
			viewport.set_input_as_handled()
		return

	# Interact with nearby object
	if event.is_action_pressed("ui_accept") and nearby_object != "":
		_interact_with_object(nearby_object)
		viewport.set_input_as_handled()

	# Touch interaction
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if nearby_object != "" and interaction_prompt.visible:
			_interact_with_object(nearby_object)

	# Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(zoom_speed)
			viewport.set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(-zoom_speed)
			viewport.set_input_as_handled()


func _handle_movement(delta: float) -> void:
	var input_dir = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()

		# Isometric movement (W=up-left, S=down-right, A=down-left, D=up-right)
		var iso_movement = Vector2(
			input_dir.x + input_dir.y,
			(input_dir.y - input_dir.x) * 0.5
		)

		var new_pos = player.position + iso_movement * player_speed * delta

		# Clamp to room bounds
		new_pos.x = clamp(new_pos.x, player_bounds.position.x, player_bounds.position.x + player_bounds.size.x)
		new_pos.y = clamp(new_pos.y, player_bounds.position.y, player_bounds.position.y + player_bounds.size.y)

		player.position = new_pos

		# Movement sound
		is_moving = true
		move_sound_timer += delta
		if move_sound_timer >= move_sound_interval:
			move_sound_timer = 0.0
			_play_sfx("res://audio/sfx/hover_move.wav", -12.0)
	else:
		is_moving = false
		move_sound_timer = 0.0


func _update_camera() -> void:
	if not game_world or not isometric_base or not player:
		return

	var screen_center = game_world.size / 2
	var target_pos = screen_center - (player.position * camera_zoom)
	isometric_base.position = target_pos
	isometric_base.scale = Vector2(camera_zoom, camera_zoom)


func _apply_zoom(amount: float) -> void:
	camera_zoom = clamp(camera_zoom + amount, min_zoom, max_zoom)
	_update_camera()


func _check_object_proximity() -> void:
	var closest_object: String = ""
	var closest_distance: float = 100.0

	for object_name in object_positions:
		var obj_pos = object_positions[object_name]
		var distance = player.position.distance_to(obj_pos)

		if distance < closest_distance:
			closest_distance = distance
			closest_object = object_name

	if closest_object != nearby_object:
		nearby_object = closest_object
		if nearby_object != "":
			_show_interaction_prompt(nearby_object)
		else:
			_hide_interaction_prompt()


func _show_interaction_prompt(object_id: String) -> void:
	var obj_data = INTERACTIVE_OBJECTS.get(object_id, {})
	if obj_data.is_empty():
		return

	var name_text = obj_data.get("name", object_id)
	var prompt_text = obj_data.get("prompt", "Press SPACE to interact")

	# Add mail count to package shelf name
	if object_id == "PackageShelf" and MailManager and MailManager.has_mail():
		name_text += " (" + str(MailManager.get_mail_count()) + " packages)"

	object_name_label.text = name_text
	prompt_text_label.text = prompt_text

	interaction_prompt.visible = true
	control_hints.visible = false


func _hide_interaction_prompt() -> void:
	interaction_prompt.visible = false
	control_hints.visible = true


func _interact_with_object(object_id: String) -> void:
	var obj_data = INTERACTIVE_OBJECTS.get(object_id, {})
	var action = obj_data.get("action", "")

	match action:
		"go_cargo_hold":
			_play_sfx("res://audio/sfx/door_open.wav")
			GameManager.goto_scene("res://scenes/ship/cargo_hold.tscn")
		"check_packages":
			_show_mail_panel()
		"check_orders":
			_show_orders_panel()
		"examine_bot":
			_show_dialogue("MX-7 Sorting Unit", "A compact sorting robot that organizes incoming packages.\n\n*Beeps contentedly*\n\n\"All packages sorted and ready for pickup, Agent!\"\n\nIt seems to take pride in its work.")


# =============================================================================
# MAIL COLLECTION PANEL
# =============================================================================

var mail_panel: Control = null


func _show_mail_panel() -> void:
	if mail_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false

	# Create panel
	mail_panel = Panel.new()
	mail_panel.set_anchors_preset(Control.PRESET_CENTER)
	mail_panel.custom_minimum_size = Vector2(600, 500)
	mail_panel.position = Vector2(-300, -250)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.15, 0.98)
	style.border_color = Color(0.4, 0.7, 0.9, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	mail_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	mail_panel.add_child(vbox)

	# Header
	var header = Label.new()
	header.text = "Package Shelf"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	vbox.add_child(header)

	# Scroll container for packages
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var packages_vbox = VBoxContainer.new()
	packages_vbox.name = "PackagesVBox"
	packages_vbox.add_theme_constant_override("separation", 10)
	packages_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(packages_vbox)

	# Populate packages
	if MailManager and MailManager.has_mail():
		var mail = MailManager.get_available_mail()
		for order in mail:
			_create_package_entry(packages_vbox, order)
	else:
		var empty_label = Label.new()
		empty_label.text = "No packages waiting for pickup.\n\nVisit the Experience Shop in Mindscape to order items!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		packages_vbox.add_child(empty_label)

	# Bottom buttons
	var button_hbox = HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(button_hbox)

	if MailManager and MailManager.has_mail():
		var collect_all_btn = Button.new()
		collect_all_btn.text = "Collect All"
		collect_all_btn.custom_minimum_size = Vector2(150, 45)
		collect_all_btn.add_theme_font_size_override("font_size", 18)
		collect_all_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
		collect_all_btn.pressed.connect(_collect_all_mail)
		button_hbox.add_child(collect_all_btn)

	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 45)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_mail_panel)
	button_hbox.add_child(close_btn)

	add_child(mail_panel)


func _create_package_entry(container: VBoxContainer, order: Dictionary) -> void:
	var panel = PanelContainer.new()

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.15, 0.2, 1.0)
	panel_style.border_color = Color(0.3, 0.5, 0.6, 0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_child(hbox)
	panel.add_child(margin)

	# Package icon
	var icon = Label.new()
	icon.text = "📦"
	icon.add_theme_font_size_override("font_size", 32)
	hbox.add_child(icon)

	# Package info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var order_label = Label.new()
	order_label.text = "Order " + order.get("id", "Unknown")
	order_label.add_theme_font_size_override("font_size", 16)
	order_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	info_vbox.add_child(order_label)

	var items = order.get("items", [])
	var items_text = str(items.size()) + " item" + ("s" if items.size() != 1 else "")
	var items_label = Label.new()
	items_label.text = items_text
	items_label.add_theme_font_size_override("font_size", 14)
	items_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	info_vbox.add_child(items_label)

	# Collect button
	var collect_btn = Button.new()
	collect_btn.text = "Collect"
	collect_btn.custom_minimum_size = Vector2(100, 35)
	collect_btn.add_theme_font_size_override("font_size", 14)
	collect_btn.pressed.connect(_collect_single_mail.bind(order.get("id", "")))
	hbox.add_child(collect_btn)

	container.add_child(panel)


func _collect_single_mail(order_id: String) -> void:
	if MailManager:
		var items = MailManager.collect_mail(order_id)
		if not items.is_empty():
			_play_sfx("res://audio/sfx/item_pickup.wav")
			_close_mail_panel()
			_show_dialogue("Package Collected", "You received:\n" + _format_items_list(items) + "\n\nItems have been added to your bedroom inventory!")


func _collect_all_mail() -> void:
	if MailManager:
		var items = MailManager.collect_all_mail()
		if not items.is_empty():
			_play_sfx("res://audio/sfx/item_pickup.wav")
			_close_mail_panel()
			_show_dialogue("All Packages Collected", "You received " + str(items.size()) + " items!\n\nAll items have been added to your bedroom inventory!")


func _format_items_list(items: Array) -> String:
	var names = []
	for item_id in items:
		var item = ShopManager.get_item(item_id) if ShopManager else {}
		names.append("• " + item.get("name", item_id))
	return "\n".join(names)


func _close_mail_panel() -> void:
	if mail_panel:
		mail_panel.queue_free()
		mail_panel = null
	in_dialogue = false


# =============================================================================
# ORDERS PANEL (Pending Deliveries)
# =============================================================================

var orders_panel: Control = null


func _show_orders_panel() -> void:
	if orders_panel:
		return

	in_dialogue = true
	interaction_prompt.visible = false

	# Create panel
	orders_panel = Panel.new()
	orders_panel.set_anchors_preset(Control.PRESET_CENTER)
	orders_panel.custom_minimum_size = Vector2(550, 450)
	orders_panel.position = Vector2(-275, -225)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.15, 0.98)
	style.border_color = Color(0.5, 0.6, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	orders_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	orders_panel.add_child(vbox)

	# Header
	var header = Label.new()
	header.text = "Delivery Terminal"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color(0.7, 0.8, 0.4))
	vbox.add_child(header)

	# Scroll container
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var orders_vbox = VBoxContainer.new()
	orders_vbox.name = "OrdersVBox"
	orders_vbox.add_theme_constant_override("separation", 10)
	orders_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(orders_vbox)

	# Populate orders
	if MailManager and MailManager.has_pending_orders():
		var orders = MailManager.get_pending_orders()
		for order in orders:
			_create_order_entry(orders_vbox, order)
	else:
		var empty_label = Label.new()
		empty_label.text = "No pending deliveries.\n\nAll packages have arrived or no orders have been placed."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		orders_vbox.add_child(empty_label)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 45)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_orders_panel)
	vbox.add_child(close_btn)

	add_child(orders_panel)


func _create_order_entry(container: VBoxContainer, order: Dictionary) -> void:
	var panel = PanelContainer.new()

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.14, 0.1, 1.0)
	panel_style.border_color = Color(0.4, 0.5, 0.3, 0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)

	# Delivery icon
	var icon = Label.new()
	icon.text = "🚚"
	icon.add_theme_font_size_override("font_size", 28)
	hbox.add_child(icon)

	# Order info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var order_label = Label.new()
	order_label.text = "Order " + order.get("id", "Unknown")
	order_label.add_theme_font_size_override("font_size", 16)
	order_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.7))
	info_vbox.add_child(order_label)

	var items = order.get("items", [])
	var items_label = Label.new()
	items_label.text = str(items.size()) + " item" + ("s" if items.size() != 1 else "") + " in transit"
	items_label.add_theme_font_size_override("font_size", 14)
	items_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
	info_vbox.add_child(items_label)

	# ETA
	var eta_label = Label.new()
	var eta = MailManager.get_order_progress(order.get("id", ""))
	if eta >= 0:
		var remaining = order.get("delivery_time", 0) - Time.get_unix_time_from_system()
		eta_label.text = "ETA: " + MailManager.format_eta(remaining)
		eta_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	else:
		eta_label.text = "Calculating..."
		eta_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	eta_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(eta_label)

	container.add_child(panel)


func _close_orders_panel() -> void:
	if orders_panel:
		orders_panel.queue_free()
		orders_panel = null
	in_dialogue = false


# =============================================================================
# DIALOGUE SYSTEM
# =============================================================================

func _show_dialogue(title: String, text: String, callback: Callable = Callable()) -> void:
	dialogue_title.text = title
	dialogue_full_text = text
	dialogue_panel.visible = true
	in_dialogue = true
	interaction_prompt.visible = false
	dialogue_callback = callback

	if callback.is_valid():
		dialogue_button.text = "Yes"
	else:
		dialogue_button.text = "Continue"

	_start_typing_effect(text)


func _start_typing_effect(text: String) -> void:
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()

	dialogue_text.text = text
	dialogue_text.visible_ratio = 0.0

	var duration = text.length() * 0.025
	duration = clamp(duration, 0.5, 6.0)

	typing_tween = create_tween()
	if typing_tween:
		typing_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)


func _skip_typing() -> void:
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
	dialogue_text.visible_ratio = 1.0


func _close_dialogue() -> void:
	dialogue_panel.visible = false
	in_dialogue = false

	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()

	if dialogue_callback.is_valid():
		dialogue_callback.call()
		dialogue_callback = Callable()


func _play_sfx(sfx_path: String, volume_db: float = 0.0) -> void:
	if not ResourceLoader.exists(sfx_path):
		return

	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		var stream = load(sfx_path)
		if stream:
			audio.play_sfx(stream, volume_db)


# =============================================================================
# ENVIRONMENT ANIMATION
# =============================================================================

func _animate_environment(_delta: float) -> void:
	# Pulse mail notification when mail is waiting
	if mail_notification_node and MailManager and MailManager.has_mail():
		var glow = mail_notification_node.get_node_or_null("Glow")
		if glow:
			var pulse = 0.2 + sin(animation_time * 3.0) * 0.15
			glow.color.a = pulse


# =============================================================================
# HEADER CONTROLS
# =============================================================================

func _setup_header_controls() -> void:
	var header_hbox = menu_button.get_parent()
	if not header_hbox:
		return

	save_indicator = Label.new()
	save_indicator.add_theme_font_size_override("font_size", 14)
	save_indicator.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	_update_save_indicator()
	header_hbox.add_child(save_indicator)
	header_hbox.move_child(save_indicator, menu_button.get_index())

	volume_button = Button.new()
	volume_button.custom_minimum_size = Vector2(45, 45)
	volume_button.add_theme_font_size_override("font_size", 20)
	volume_button.pressed.connect(_toggle_volume_popup)
	_update_volume_button_icon()
	header_hbox.add_child(volume_button)
	header_hbox.move_child(volume_button, menu_button.get_index())


func _update_save_indicator() -> void:
	if not save_indicator:
		return
	var current_slot = SaveManager.current_slot
	if current_slot > 0:
		var info = SaveManager.get_slot_info(current_slot)
		save_indicator.text = info.slot_name if info.exists else "Slot %d" % current_slot
	else:
		save_indicator.text = "Auto-save"


func _update_volume_button_icon() -> void:
	if not volume_button:
		return
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.master_volume <= 0.01:
		volume_button.text = "🔇"
		is_muted = true
	else:
		volume_button.text = "🔊"
		is_muted = false


func _toggle_volume_popup() -> void:
	if volume_popup:
		_close_volume_popup()
		return

	volume_popup = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.98)
	style.border_color = Color(0.4, 0.35, 0.6, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	volume_popup.add_theme_stylebox_override("panel", style)
	volume_popup.position = volume_button.global_position + Vector2(-80, volume_button.size.y + 5)
	volume_popup.custom_minimum_size = Vector2(200, 0)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	volume_popup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Volume"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var audio = get_node_or_null("/root/AudioManager")
	for channel in ["Master", "Music", "SFX"]:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var lbl = Label.new()
		lbl.text = channel
		lbl.custom_minimum_size = Vector2(55, 0)
		lbl.add_theme_font_size_override("font_size", 14)
		row.add_child(lbl)

		var slider = HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		match channel:
			"Master": slider.value = audio.master_volume * 100 if audio else 100
			"Music": slider.value = audio.music_volume * 100 if audio else 100
			"SFX": slider.value = audio.sfx_volume * 100 if audio else 100
		slider.custom_minimum_size = Vector2(100, 20)
		slider.value_changed.connect(func(val): _on_volume_changed(channel.to_lower(), val))
		row.add_child(slider)

	var mute_btn = Button.new()
	mute_btn.text = "Unmute All" if is_muted else "Mute All"
	mute_btn.custom_minimum_size = Vector2(0, 35)
	mute_btn.pressed.connect(_toggle_mute)
	vbox.add_child(mute_btn)

	add_child(volume_popup)


func _close_volume_popup() -> void:
	if volume_popup:
		volume_popup.queue_free()
		volume_popup = null


func _on_volume_changed(channel: String, value: float) -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		return
	var vol = value / 100.0
	match channel:
		"master": audio.set_master_volume(vol)
		"music": audio.set_music_volume(vol)
		"sfx": audio.set_sfx_volume(vol)
	_update_volume_button_icon()


func _toggle_mute() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if not audio:
		return
	if is_muted:
		audio.set_master_volume(1.0)
	else:
		audio.set_master_volume(0.0)
	is_muted = not is_muted
	_update_volume_button_icon()
	_close_volume_popup()


# =============================================================================
# PAUSE MENU
# =============================================================================

var pause_menu: PanelContainer = null


func _open_pause_menu() -> void:
	if pause_menu:
		return

	in_dialogue = true
	interaction_prompt.visible = false

	pause_menu = PanelContainer.new()

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.98)
	style.border_color = Color(0.5, 0.4, 0.7, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	pause_menu.add_theme_stylebox_override("panel", style)

	pause_menu.set_anchors_preset(Control.PRESET_CENTER)
	pause_menu.offset_left = -200
	pause_menu.offset_right = 200
	pause_menu.offset_top = -200
	pause_menu.offset_bottom = 200

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	pause_menu.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Menu"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.29))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.custom_minimum_size = Vector2(0, 50)
	resume_btn.add_theme_font_size_override("font_size", 20)
	resume_btn.pressed.connect(_close_pause_menu)
	vbox.add_child(resume_btn)

	var settings_btn = Button.new()
	settings_btn.text = "Settings"
	settings_btn.custom_minimum_size = Vector2(0, 50)
	settings_btn.add_theme_font_size_override("font_size", 20)
	settings_btn.pressed.connect(_go_to_settings)
	vbox.add_child(settings_btn)

	var main_menu_btn = Button.new()
	main_menu_btn.text = "Main Menu"
	main_menu_btn.custom_minimum_size = Vector2(0, 50)
	main_menu_btn.add_theme_font_size_override("font_size", 20)
	main_menu_btn.add_theme_color_override("font_color", Color(0.8, 0.6, 0.6))
	main_menu_btn.pressed.connect(_go_to_main_menu)
	vbox.add_child(main_menu_btn)

	add_child(pause_menu)


func _close_pause_menu() -> void:
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null
	in_dialogue = false


func _go_to_settings() -> void:
	_close_pause_menu()
	GameManager.goto_scene("res://scenes/settings/settings.tscn")


func _go_to_main_menu() -> void:
	_close_pause_menu()
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
