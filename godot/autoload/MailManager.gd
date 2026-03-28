extends Node
## MailManager - Handles orders, delivery queue, and mail collection

signal order_placed(order_id: String, items: Array)
signal mail_arrived(order_id: String)
signal mail_collected(order_id: String, items: Array)
signal all_mail_collected
signal mail_count_changed(count: int)

enum OrderStatus {
	PENDING,      # Just ordered, being processed
	IN_TRANSIT,   # Being delivered
	ARRIVED,      # At mail room, ready for pickup
	COLLECTED     # Player picked up
}

# Delivery time range (in seconds)
const MIN_DELIVERY_TIME: float = 30.0   # 30 seconds minimum
const MAX_DELIVERY_TIME: float = 120.0  # 2 minutes maximum

# Pending orders (ordered but not yet arrived)
var pending_orders: Array = []

# Available mail (ready for pickup in mail room)
var available_mail: Array = []

# Order history (collected orders)
var order_history: Array = []

# Timer for checking deliveries
var delivery_check_timer: float = 0.0
const DELIVERY_CHECK_INTERVAL: float = 1.0


func _ready() -> void:
	# Check for any deliveries that should have arrived
	call_deferred("check_deliveries")


func _process(delta: float) -> void:
	delivery_check_timer += delta
	if delivery_check_timer >= DELIVERY_CHECK_INTERVAL:
		delivery_check_timer = 0.0
		check_deliveries()


## Place a new order
## Returns the order_id
func place_order(items: Array) -> String:
	if items.is_empty():
		return ""

	var order_id = _generate_order_id()
	var current_time = Time.get_unix_time_from_system()
	var delivery_time = current_time + randf_range(MIN_DELIVERY_TIME, MAX_DELIVERY_TIME)

	var order = {
		"id": order_id,
		"items": items.duplicate(),
		"status": OrderStatus.PENDING,
		"ordered_at": current_time,
		"delivery_time": delivery_time,
		"collected_at": 0
	}

	pending_orders.append(order)
	order_placed.emit(order_id, items)

	print("[MailManager] Order placed: ", order_id, " with ", items.size(), " items. ETA: ", int(delivery_time - current_time), "s")

	SaveManager.save_game()
	return order_id


## Check for orders that have arrived
func check_deliveries() -> void:
	var current_time = Time.get_unix_time_from_system()
	var newly_arrived = []

	for order in pending_orders:
		if current_time >= order.delivery_time:
			order.status = OrderStatus.ARRIVED
			newly_arrived.append(order)

	# Move arrived orders to available mail
	for order in newly_arrived:
		pending_orders.erase(order)
		available_mail.append(order)
		mail_arrived.emit(order.id)
		print("[MailManager] Mail arrived: ", order.id)

	if not newly_arrived.is_empty():
		mail_count_changed.emit(available_mail.size())
		SaveManager.save_game()


## Get all pending orders
func get_pending_orders() -> Array:
	return pending_orders.duplicate()


## Get all available mail (ready for pickup)
func get_available_mail() -> Array:
	return available_mail.duplicate()


## Get mail count
func get_mail_count() -> int:
	return available_mail.size()


## Check if there's mail waiting
func has_mail() -> bool:
	return not available_mail.is_empty()


## Check if there are pending orders
func has_pending_orders() -> bool:
	return not pending_orders.is_empty()


## Collect a specific mail order
## Returns the items in the order
func collect_mail(order_id: String) -> Array:
	var order_index = -1
	for i in range(available_mail.size()):
		if available_mail[i].id == order_id:
			order_index = i
			break

	if order_index == -1:
		return []

	var order = available_mail[order_index]
	available_mail.remove_at(order_index)

	order.status = OrderStatus.COLLECTED
	order.collected_at = Time.get_unix_time_from_system()
	order_history.append(order)

	# Add items to player inventory
	var items = order.items.duplicate()
	for item_id in items:
		if GameManager:
			if not GameManager.player_data.has("collected_decor"):
				GameManager.player_data["collected_decor"] = []
			GameManager.player_data["collected_decor"].append(item_id)

	mail_collected.emit(order_id, items)
	mail_count_changed.emit(available_mail.size())

	if available_mail.is_empty():
		all_mail_collected.emit()

	print("[MailManager] Mail collected: ", order_id, " - ", items.size(), " items")
	SaveManager.save_game()

	return items


## Collect all available mail
## Returns array of all items
func collect_all_mail() -> Array:
	var all_items = []

	while not available_mail.is_empty():
		var order = available_mail[0]
		var items = collect_mail(order.id)
		all_items.append_array(items)

	return all_items


## Get estimated time until next delivery (in seconds)
func get_next_delivery_eta() -> float:
	if pending_orders.is_empty():
		return -1.0

	var current_time = Time.get_unix_time_from_system()
	var earliest = INF

	for order in pending_orders:
		var eta = order.delivery_time - current_time
		if eta < earliest:
			earliest = eta

	return max(0.0, earliest)


## Get delivery progress for an order (0.0 to 1.0)
func get_order_progress(order_id: String) -> float:
	for order in pending_orders:
		if order.id == order_id:
			var current_time = Time.get_unix_time_from_system()
			var total_time = order.delivery_time - order.ordered_at
			var elapsed = current_time - order.ordered_at
			return clamp(elapsed / total_time, 0.0, 1.0)

	# Check if already delivered
	for order in available_mail:
		if order.id == order_id:
			return 1.0

	return -1.0


## Get order history
func get_order_history() -> Array:
	return order_history.duplicate()


## Generate unique order ID
func _generate_order_id() -> String:
	var timestamp = int(Time.get_unix_time_from_system() * 1000)
	var random_suffix = randi() % 10000
	return "ORD-%d-%04d" % [timestamp, random_suffix]


## Format time remaining as string
static func format_eta(seconds: float) -> String:
	if seconds < 0:
		return "Unknown"
	if seconds < 60:
		return "%ds" % int(seconds)
	else:
		var mins = int(seconds / 60)
		var secs = int(seconds) % 60
		return "%dm %ds" % [mins, secs]


## Get save data
func get_save_data() -> Dictionary:
	return {
		"pending_orders": pending_orders.duplicate(true),
		"available_mail": available_mail.duplicate(true),
		"order_history": order_history.duplicate(true)
	}


## Load save data
func load_save_data(data: Dictionary) -> void:
	if data.has("pending_orders"):
		pending_orders = data.pending_orders.duplicate(true)
	if data.has("available_mail"):
		available_mail = data.available_mail.duplicate(true)
	if data.has("order_history"):
		order_history = data.order_history.duplicate(true)

	# Emit initial count
	mail_count_changed.emit(available_mail.size())

	# Check for deliveries that happened while game was closed
	check_deliveries()
