extends CharacterBody2D
## Player - Avatar controller for 2D movement
## Handles touch/keyboard input with cardinal directions

const SPEED = 200.0

# Touch/drag state
var touch_start_pos: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var target_position: Vector2 = Vector2.ZERO
var has_target: bool = false


func _ready() -> void:
	print("[Player] Avatar ready")


func _physics_process(_delta: float) -> void:
	var input_direction = Vector2.ZERO

	# Keyboard input (WASD and arrow keys) - cardinal directions
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"):
		input_direction.x += 1
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down"):
		input_direction.y += 1
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("ui_up"):
		input_direction.y -= 1

	# If we have keyboard input, use cardinal movement
	if input_direction != Vector2.ZERO:
		has_target = false
		velocity = input_direction.normalized() * SPEED
	# Otherwise check for tap-to-move target
	elif has_target:
		var direction = (target_position - global_position)
		if direction.length() > 10:
			velocity = direction.normalized() * SPEED
		else:
			has_target = false
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func _input(event: InputEvent) -> void:
	# Handle touch/click for tap-to-move
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Set target position (convert screen to world coords)
			var camera = get_node_or_null("Camera2D")
			if camera:
				target_position = get_global_mouse_position()
				has_target = true

	# Handle touch drag (mobile)
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start_pos = event.position
			is_dragging = true
		else:
			is_dragging = false

	if event is InputEventScreenDrag and is_dragging:
		# Virtual joystick behavior - drag from touch point
		var drag_vector = event.position - touch_start_pos
		if drag_vector.length() > 20:  # Dead zone
			velocity = drag_vector.normalized() * SPEED
			has_target = false
