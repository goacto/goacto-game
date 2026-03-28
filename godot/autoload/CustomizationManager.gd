extends Node
## CustomizationManager - Handles avatar customization preview and application

signal cosmetic_equipped(slot: String, item_id: String)
signal cosmetic_unequipped(slot: String)
signal avatar_updated
signal preview_started
signal preview_ended

# Cosmetic slots in display order
const SLOTS = ["skin_color", "outfit", "hat", "cape", "glasses", "aura"]

# Slot display names
const SLOT_NAMES = {
	"skin_color": "Skin Color",
	"outfit": "Outfit",
	"hat": "Hat",
	"cape": "Cape",
	"glasses": "Glasses",
	"aura": "Aura Effect"
}

# Preview state
var is_previewing: bool = false
var preview_slot: String = ""
var preview_item_id: String = ""
var original_equipped: Dictionary = {}

# Multi-item preview (for wardrobe panel)
var preview_items: Dictionary = {}  # slot -> item_id


func _ready() -> void:
	pass


## Get current equipped item for a slot (from ShopManager)
func get_equipped(slot: String) -> String:
	if ShopManager:
		return ShopManager.get_equipped(slot)
	return ""


## Get full current appearance
func get_current_appearance() -> Dictionary:
	if ShopManager:
		return ShopManager.get_appearance()
	return {}


## Equip a cosmetic item
func equip(slot: String, item_id: String) -> bool:
	if not ShopManager:
		return false

	# Check ownership
	if item_id != "" and not ShopManager.is_owned(item_id):
		return false

	var item = ShopManager.get_item(item_id) if item_id != "" else {}
	ShopManager.equipped[slot] = item_id

	cosmetic_equipped.emit(slot, item_id)
	avatar_updated.emit()
	SaveManager.save_game()

	return true


## Unequip a slot
func unequip(slot: String) -> void:
	if ShopManager:
		ShopManager.equipped[slot] = ""
		cosmetic_unequipped.emit(slot)
		avatar_updated.emit()
		SaveManager.save_game()


## Start previewing (multi-item mode for wardrobe panel)
## Can be called without arguments to start multi-item preview
func start_preview(slot: String = "", item_id: String = "") -> void:
	if is_previewing:
		cancel_preview()

	# Store original state
	original_equipped = {}
	if ShopManager:
		original_equipped = ShopManager.equipped.duplicate()

	preview_slot = slot
	preview_item_id = item_id
	preview_items = original_equipped.duplicate()  # Start with current equipped
	is_previewing = true

	# Temporarily apply preview if specific item provided
	if slot != "" and item_id != "" and ShopManager:
		ShopManager.equipped[slot] = item_id
		preview_items[slot] = item_id

	preview_started.emit()
	avatar_updated.emit()


## Get preview appearance (for wardrobe panel)
func get_preview_appearance() -> Dictionary:
	if is_previewing:
		return preview_items.duplicate()
	return get_current_appearance()


## Set a preview item for a slot (wardrobe panel)
func set_preview_item(slot: String, item_id: String) -> void:
	preview_items[slot] = item_id
	avatar_updated.emit()


## Apply the preview as permanent
func apply_preview() -> void:
	if not is_previewing:
		return

	# Apply all preview items to ShopManager
	if ShopManager:
		for slot in preview_items:
			ShopManager.equipped[slot] = preview_items[slot]

	# Clear preview state
	is_previewing = false
	preview_slot = ""
	preview_item_id = ""
	preview_items.clear()
	original_equipped.clear()

	preview_ended.emit()
	avatar_updated.emit()
	SaveManager.save_game()


## Cancel preview and restore original state
func cancel_preview() -> void:
	if not is_previewing:
		return

	# Restore original equipped state
	if ShopManager and not original_equipped.is_empty():
		ShopManager.equipped = original_equipped.duplicate()

	is_previewing = false
	preview_slot = ""
	preview_item_id = ""
	preview_items.clear()
	original_equipped.clear()

	preview_ended.emit()
	avatar_updated.emit()


## Get all owned items for a slot
func get_owned_items_for_slot(slot: String) -> Array:
	if not ShopManager:
		return []

	var items = []
	var category = _get_category_for_slot(slot)

	for item_id in ShopManager.owned_items:
		var item = ShopManager.get_item(item_id)
		if item and item is Dictionary and not item.is_empty() and item.get("category", -1) == category:
			items.append(item)

	return items


## Get all purchasable (not owned) items for a slot
func get_purchasable_items_for_slot(slot: String) -> Array:
	if not ShopManager:
		return []

	var items = []
	var category = _get_category_for_slot(slot)

	for item_id in ShopManager.SHOP_CATALOG:
		if ShopManager.is_owned(item_id):
			continue

		var item = ShopManager.get_item(item_id)
		if item and item is Dictionary and not item.is_empty() and item.get("category", -1) == category:
			items.append(item)

	return items


## Get the category enum for a slot name
func _get_category_for_slot(slot: String) -> int:
	match slot:
		"skin_color":
			return ShopManager.ItemCategory.COSMETIC_COLOR
		"outfit":
			return ShopManager.ItemCategory.COSMETIC_OUTFIT
		"hat":
			return ShopManager.ItemCategory.COSMETIC_HAT
		"cape":
			return ShopManager.ItemCategory.COSMETIC_CAPE
		"glasses":
			return ShopManager.ItemCategory.COSMETIC_GLASSES
		"aura":
			return ShopManager.ItemCategory.COSMETIC_AURA
	return -1


## Get display name for a slot
func get_slot_display_name(slot: String) -> String:
	return SLOT_NAMES.get(slot, slot.capitalize())


## Build player visual data for rendering
## Returns a dictionary with all visual properties needed to render the player
func build_player_visuals() -> Dictionary:
	var appearance = get_current_appearance()
	var visuals = {
		"base_color": Color(0.3, 0.7, 0.4),  # Default green
		"outfit_id": "default_suit",
		"hat_id": "",
		"cape_id": "",
		"glasses_id": "",
		"aura_color": Color(0, 0, 0, 0),
		"aura_enabled": false,
		"animated_color": false
	}

	# Apply skin color
	if appearance.has("skin_color") and not appearance.skin_color.is_empty():
		var color_item = appearance.skin_color
		if color_item.has("preview_color"):
			visuals.base_color = color_item.preview_color
		if color_item.get("animated", false):
			visuals.animated_color = true

	# Apply outfit
	if appearance.has("outfit") and not appearance.outfit.is_empty():
		visuals.outfit_id = appearance.outfit.get("id", "default_suit")

	# Apply accessories
	if appearance.has("hat") and not appearance.hat.is_empty():
		visuals.hat_id = appearance.hat.get("id", "")

	if appearance.has("cape") and not appearance.cape.is_empty():
		visuals.cape_id = appearance.cape.get("id", "")

	if appearance.has("glasses") and not appearance.glasses.is_empty():
		visuals.glasses_id = appearance.glasses.get("id", "")

	# Apply aura
	if appearance.has("aura") and not appearance.aura.is_empty():
		var aura_item = appearance.aura
		visuals.aura_enabled = true
		visuals.aura_color = aura_item.get("particle_color", Color(1, 1, 1, 0.5))

	return visuals


## Get save data (delegates to ShopManager)
func get_save_data() -> Dictionary:
	# CustomizationManager doesn't have its own save data
	# All persistent data is in ShopManager
	return {}


## Load save data
func load_save_data(_data: Dictionary) -> void:
	# Nothing to load directly - ShopManager handles persistence
	pass
