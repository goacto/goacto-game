extends Node
## ShopManager - Handles shop catalog, purchases, and unlockables

signal item_purchased(item_id: String, item_data: Dictionary)
signal purchase_failed(item_id: String, reason: String)
signal catalog_updated

enum ItemCategory {
	COSMETIC_COLOR,      # Avatar colors/skins
	COSMETIC_OUTFIT,     # Outfits/accessories
	COSMETIC_HAT,        # Hats
	COSMETIC_CAPE,       # Capes
	COSMETIC_GLASSES,    # Glasses
	COSMETIC_AURA,       # Particle effects/trails
	ROOM_DECOR,          # Bedroom decorations
	FUNCTIONAL,          # Functional items
	COLLECTIBLE          # Collectibles
}

enum ItemRarity {
	COMMON,
	UNCOMMON,
	RARE,
	LEGENDARY
}

# Rarity colors for UI display
const RARITY_COLORS = {
	ItemRarity.COMMON: Color(0.7, 0.7, 0.7),
	ItemRarity.UNCOMMON: Color(0.3, 0.8, 0.3),
	ItemRarity.RARE: Color(0.3, 0.5, 1.0),
	ItemRarity.LEGENDARY: Color(1.0, 0.7, 0.2)
}

# Full catalog of purchasable items
const SHOP_CATALOG = {
	# ===== DEFAULT ITEMS (Free/Starting) =====
	"default_green": {
		"name": "Goacto Green",
		"description": "The classic green hue of a Goacto agent.",
		"category": ItemCategory.COSMETIC_COLOR,
		"rarity": ItemRarity.COMMON,
		"cost": {},
		"is_default": true,
		"preview_color": Color(0.3, 0.7, 0.4)
	},
	"default_suit": {
		"name": "Agent Suit",
		"description": "Standard issue Goacto agent attire.",
		"category": ItemCategory.COSMETIC_OUTFIT,
		"rarity": ItemRarity.COMMON,
		"cost": {},
		"is_default": true
	},

	# ===== SKIN COLORS =====
	"skin_blue": {
		"name": "Ocean Blue",
		"description": "A calming blue reminiscent of deep waters.",
		"category": ItemCategory.COSMETIC_COLOR,
		"rarity": ItemRarity.COMMON,
		"cost": {"wisdom": 100},
		"preview_color": Color(0.2, 0.4, 0.8)
	},
	"skin_purple": {
		"name": "Mystic Purple",
		"description": "A mysterious violet shade.",
		"category": ItemCategory.COSMETIC_COLOR,
		"rarity": ItemRarity.COMMON,
		"cost": {"creativity": 100},
		"preview_color": Color(0.6, 0.3, 0.8)
	},
	"skin_red": {
		"name": "Courage Crimson",
		"description": "Bold red for the brave at heart.",
		"category": ItemCategory.COSMETIC_COLOR,
		"rarity": ItemRarity.UNCOMMON,
		"cost": {"courage": 150},
		"preview_color": Color(0.8, 0.2, 0.2)
	},
	"skin_gold": {
		"name": "Golden Discipline",
		"description": "Shimmering gold earned through dedication.",
		"category": ItemCategory.COSMETIC_COLOR,
		"rarity": ItemRarity.RARE,
		"cost": {"discipline": 250},
		"preview_color": Color(0.9, 0.75, 0.3)
	},
	"skin_silver": {
		"name": "Starlight Silver",
		"description": "Gleaming like distant stars.",
		"category": ItemCategory.COSMETIC_COLOR,
		"rarity": ItemRarity.RARE,
		"cost": {"wisdom": 200, "discipline": 100},
		"preview_color": Color(0.8, 0.85, 0.9)
	},
	"skin_rainbow": {
		"name": "Prismatic Shift",
		"description": "A legendary color that shifts through the spectrum.",
		"category": ItemCategory.COSMETIC_COLOR,
		"rarity": ItemRarity.LEGENDARY,
		"cost": {"creativity": 300, "wisdom": 200, "courage": 100},
		"preview_color": Color(1.0, 0.5, 0.8),
		"animated": true
	},

	# ===== OUTFITS =====
	"outfit_explorer": {
		"name": "Explorer's Gear",
		"description": "Rugged attire for the adventurous spirit.",
		"category": ItemCategory.COSMETIC_OUTFIT,
		"rarity": ItemRarity.UNCOMMON,
		"cost": {"courage": 150, "vitality": 50}
	},
	"outfit_scholar": {
		"name": "Scholar's Robes",
		"description": "Elegant robes befitting a seeker of knowledge.",
		"category": ItemCategory.COSMETIC_OUTFIT,
		"rarity": ItemRarity.UNCOMMON,
		"cost": {"wisdom": 150, "discipline": 50}
	},
	"outfit_artist": {
		"name": "Creative Threads",
		"description": "Vibrant clothing that inspires creativity.",
		"category": ItemCategory.COSMETIC_OUTFIT,
		"rarity": ItemRarity.UNCOMMON,
		"cost": {"creativity": 150, "compassion": 50}
	},
	"outfit_warrior": {
		"name": "Warrior's Armor",
		"description": "Lightweight armor for mental battles.",
		"category": ItemCategory.COSMETIC_OUTFIT,
		"rarity": ItemRarity.RARE,
		"cost": {"discipline": 200, "courage": 150}
	},
	"outfit_cosmic": {
		"name": "Cosmic Vestments",
		"description": "Legendary attire woven from starlight.",
		"category": ItemCategory.COSMETIC_OUTFIT,
		"rarity": ItemRarity.LEGENDARY,
		"cost": {"wisdom": 250, "creativity": 200, "discipline": 150}
	},

	# ===== HATS =====
	"hat_cap": {
		"name": "Focus Cap",
		"description": "A simple cap for staying focused.",
		"category": ItemCategory.COSMETIC_HAT,
		"rarity": ItemRarity.COMMON,
		"cost": {"discipline": 50}
	},
	"hat_wizard": {
		"name": "Wisdom Hat",
		"description": "A pointed hat crackling with knowledge.",
		"category": ItemCategory.COSMETIC_HAT,
		"rarity": ItemRarity.UNCOMMON,
		"cost": {"wisdom": 120}
	},
	"hat_crown": {
		"name": "Champion's Crown",
		"description": "A crown for those who conquer their goals.",
		"category": ItemCategory.COSMETIC_HAT,
		"rarity": ItemRarity.RARE,
		"cost": {"courage": 200, "discipline": 100}
	},

	# ===== CAPES =====
	"cape_simple": {
		"name": "Traveler's Cloak",
		"description": "A modest cloak for your journeys.",
		"category": ItemCategory.COSMETIC_CAPE,
		"rarity": ItemRarity.COMMON,
		"cost": {"vitality": 60}
	},
	"cape_flowing": {
		"name": "Wind Rider Cape",
		"description": "A cape that flows with ethereal wind.",
		"category": ItemCategory.COSMETIC_CAPE,
		"rarity": ItemRarity.UNCOMMON,
		"cost": {"courage": 100, "vitality": 50}
	},
	"cape_starlight": {
		"name": "Starweave Mantle",
		"description": "A legendary cape dotted with tiny stars.",
		"category": ItemCategory.COSMETIC_CAPE,
		"rarity": ItemRarity.LEGENDARY,
		"cost": {"wisdom": 200, "creativity": 200, "courage": 100}
	},

	# ===== GLASSES =====
	"glasses_round": {
		"name": "Scholar Specs",
		"description": "Round glasses for the studious.",
		"category": ItemCategory.COSMETIC_GLASSES,
		"rarity": ItemRarity.COMMON,
		"cost": {"wisdom": 50}
	},
	"glasses_cool": {
		"name": "Cool Shades",
		"description": "Stylish sunglasses for confident agents.",
		"category": ItemCategory.COSMETIC_GLASSES,
		"rarity": ItemRarity.UNCOMMON,
		"cost": {"courage": 80, "creativity": 40}
	},
	"glasses_cyber": {
		"name": "Cyber Visor",
		"description": "Futuristic visor with glowing accents.",
		"category": ItemCategory.COSMETIC_GLASSES,
		"rarity": ItemRarity.RARE,
		"cost": {"discipline": 150, "creativity": 100}
	},

	# ===== AURAS =====
	"aura_sparkle": {
		"name": "Gentle Sparkle",
		"description": "Subtle sparkling particles around you.",
		"category": ItemCategory.COSMETIC_AURA,
		"rarity": ItemRarity.UNCOMMON,
		"cost": {"creativity": 120},
		"particle_color": Color(1.0, 1.0, 0.8, 0.6)
	},
	"aura_flame": {
		"name": "Inner Fire",
		"description": "Warm flames of determination.",
		"category": ItemCategory.COSMETIC_AURA,
		"rarity": ItemRarity.RARE,
		"cost": {"courage": 200, "vitality": 100},
		"particle_color": Color(1.0, 0.5, 0.2, 0.7)
	},
	"aura_frost": {
		"name": "Calm Frost",
		"description": "Cool mist of focused clarity.",
		"category": ItemCategory.COSMETIC_AURA,
		"rarity": ItemRarity.RARE,
		"cost": {"discipline": 200, "wisdom": 100},
		"particle_color": Color(0.6, 0.8, 1.0, 0.6)
	},
	"aura_cosmic": {
		"name": "Cosmic Radiance",
		"description": "Legendary aura of swirling stardust.",
		"category": ItemCategory.COSMETIC_AURA,
		"rarity": ItemRarity.LEGENDARY,
		"cost": {"wisdom": 250, "creativity": 200, "discipline": 150},
		"particle_color": Color(0.8, 0.6, 1.0, 0.8)
	},

	# ===== ROOM DECORATIONS =====
	"decor_plant_crystal": {
		"name": "Crystal Fern",
		"description": "A beautiful crystalline plant.",
		"category": ItemCategory.ROOM_DECOR,
		"rarity": ItemRarity.UNCOMMON,
		"cost": {"vitality": 100, "creativity": 50},
		"size": Vector2(40, 60),
		"placement_type": "floor"
	},
	"decor_lamp_orb": {
		"name": "Floating Orb Lamp",
		"description": "A softly glowing orb that hovers.",
		"category": ItemCategory.ROOM_DECOR,
		"rarity": ItemRarity.UNCOMMON,
		"cost": {"wisdom": 80, "creativity": 70},
		"size": Vector2(30, 30),
		"placement_type": "floor"
	},
	"decor_poster_stars": {
		"name": "Starmap Poster",
		"description": "A poster showing distant constellations.",
		"category": ItemCategory.ROOM_DECOR,
		"rarity": ItemRarity.COMMON,
		"cost": {"wisdom": 60},
		"size": Vector2(60, 40),
		"placement_type": "wall"
	},
	"decor_rug_meditation": {
		"name": "Meditation Rug",
		"description": "A comfortable rug for reflection.",
		"category": ItemCategory.ROOM_DECOR,
		"rarity": ItemRarity.UNCOMMON,
		"cost": {"compassion": 100, "discipline": 50},
		"size": Vector2(80, 50),
		"placement_type": "floor"
	},
	"decor_statue_mini": {
		"name": "Mini Aspect Statue",
		"description": "A small statue representing growth.",
		"category": ItemCategory.ROOM_DECOR,
		"rarity": ItemRarity.RARE,
		"cost": {"discipline": 150, "wisdom": 100},
		"size": Vector2(25, 45),
		"placement_type": "floor"
	},
	"decor_terrarium": {
		"name": "Mindscape Terrarium",
		"description": "A tiny mindscape ecosystem in a jar.",
		"category": ItemCategory.ROOM_DECOR,
		"rarity": ItemRarity.LEGENDARY,
		"cost": {"vitality": 200, "creativity": 150, "compassion": 100},
		"size": Vector2(35, 50),
		"placement_type": "floor"
	},

	# ===== FUNCTIONAL ITEMS =====
	"func_focus_boost": {
		"name": "Focus Amplifier",
		"description": "Increases focus session rewards by 10%.",
		"category": ItemCategory.FUNCTIONAL,
		"rarity": ItemRarity.RARE,
		"cost": {"discipline": 300},
		"effect": "focus_reward_bonus",
		"effect_value": 0.1
	},
	"func_streak_shield": {
		"name": "Streak Shield",
		"description": "Protects one streak from breaking (single use).",
		"category": ItemCategory.FUNCTIONAL,
		"rarity": ItemRarity.RARE,
		"cost": {"courage": 250, "discipline": 150},
		"effect": "streak_protection",
		"consumable": true
	},

	# ===== COLLECTIBLES =====
	"collect_badge_founder": {
		"name": "Founder's Badge",
		"description": "A badge marking an early Goacto adopter.",
		"category": ItemCategory.COLLECTIBLE,
		"rarity": ItemRarity.LEGENDARY,
		"cost": {"discipline": 100, "courage": 100, "creativity": 100, "compassion": 100, "wisdom": 100, "vitality": 100}
	}
}

# Player's owned items (item_id -> purchase_timestamp)
var owned_items: Dictionary = {}

# Currently equipped cosmetics
var equipped: Dictionary = {
	"skin_color": "default_green",
	"outfit": "default_suit",
	"hat": "",
	"cape": "",
	"glasses": "",
	"aura": ""
}


func _ready() -> void:
	# Initialize default items as owned
	for item_id in SHOP_CATALOG:
		var item = SHOP_CATALOG[item_id]
		if item.get("is_default", false):
			owned_items[item_id] = 0  # 0 = default/free item


## Get all items in a category
func get_catalog_by_category(category: ItemCategory) -> Array:
	var items = []
	for item_id in SHOP_CATALOG:
		var item = SHOP_CATALOG[item_id].duplicate()
		item["id"] = item_id
		if item.category == category:
			items.append(item)
	return items


## Get a specific item from catalog
func get_item(item_id: String) -> Dictionary:
	if SHOP_CATALOG.has(item_id):
		var item = SHOP_CATALOG[item_id].duplicate()
		item["id"] = item_id
		return item
	return {}


## Check if player can afford an item
func can_afford(item_id: String) -> bool:
	if not SHOP_CATALOG.has(item_id):
		return false

	var item = SHOP_CATALOG[item_id]
	var cost = item.get("cost", {})

	if cost.is_empty():
		return true  # Free item

	for aspect in cost:
		var required = cost[aspect]
		var player_xp = _get_aspect_xp(aspect)
		if player_xp < required:
			return false

	return true


## Get the cost breakdown for an item
func get_item_cost(item_id: String) -> Dictionary:
	if not SHOP_CATALOG.has(item_id):
		return {}
	return SHOP_CATALOG[item_id].get("cost", {}).duplicate()


## Check if player owns an item
func is_owned(item_id: String) -> bool:
	return owned_items.has(item_id)


## Purchase an item
func purchase_item(item_id: String) -> bool:
	if not SHOP_CATALOG.has(item_id):
		purchase_failed.emit(item_id, "Item not found")
		return false

	if is_owned(item_id):
		purchase_failed.emit(item_id, "Already owned")
		return false

	if not can_afford(item_id):
		purchase_failed.emit(item_id, "Insufficient XP")
		return false

	var item = SHOP_CATALOG[item_id]
	var cost = item.get("cost", {})

	# Deduct XP from aspects
	for aspect in cost:
		var amount = cost[aspect]
		_deduct_aspect_xp(aspect, amount)

	# Add to owned items
	owned_items[item_id] = Time.get_unix_time_from_system()

	# Handle room decor - send to mail
	if item.category == ItemCategory.ROOM_DECOR:
		if MailManager:
			MailManager.place_order([item_id])

	item_purchased.emit(item_id, item)
	SaveManager.save_game()

	return true


## Equip a cosmetic item
func equip_item(item_id: String) -> bool:
	if not is_owned(item_id) and item_id != "":
		return false

	var item = get_item(item_id)
	if item.is_empty() and item_id != "":
		return false

	var slot = _get_slot_for_category(item.get("category", -1))
	if slot == "":
		return false

	equipped[slot] = item_id
	SaveManager.save_game()
	return true


## Unequip a cosmetic slot
func unequip_slot(slot: String) -> void:
	if equipped.has(slot):
		equipped[slot] = ""
		SaveManager.save_game()


## Get currently equipped item for a slot
func get_equipped(slot: String) -> String:
	return equipped.get(slot, "")


## Get full appearance data for rendering
func get_appearance() -> Dictionary:
	var appearance = {}
	for slot in equipped:
		var item_id = equipped[slot]
		if item_id != "":
			appearance[slot] = get_item(item_id)
		else:
			appearance[slot] = {}
	return appearance


## Get rarity color for UI
func get_rarity_color(rarity: ItemRarity) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)


## Get save data
func get_save_data() -> Dictionary:
	return {
		"owned_items": owned_items.duplicate(),
		"equipped": equipped.duplicate()
	}


## Load save data
func load_save_data(data: Dictionary) -> void:
	if data.has("owned_items"):
		owned_items = data.owned_items.duplicate()
	if data.has("equipped"):
		equipped = data.equipped.duplicate()

	# Ensure defaults are owned
	for item_id in SHOP_CATALOG:
		var item = SHOP_CATALOG[item_id]
		if item.get("is_default", false) and not owned_items.has(item_id):
			owned_items[item_id] = 0


## Helper: Get aspect XP from GameManager
func _get_aspect_xp(aspect: String) -> int:
	if not GameManager:
		return 0
	var aspects = GameManager.player_data.get("aspects", {})
	if aspects.has(aspect):
		return int(aspects[aspect].get("experience", 0))
	return 0


## Helper: Deduct XP from aspect
func _deduct_aspect_xp(aspect: String, amount: int) -> void:
	if not GameManager:
		return
	var aspects = GameManager.player_data.get("aspects", {})
	if aspects.has(aspect):
		aspects[aspect].experience = max(0, aspects[aspect].experience - amount)


## Helper: Get slot name for category
func _get_slot_for_category(category: ItemCategory) -> String:
	match category:
		ItemCategory.COSMETIC_COLOR:
			return "skin_color"
		ItemCategory.COSMETIC_OUTFIT:
			return "outfit"
		ItemCategory.COSMETIC_HAT:
			return "hat"
		ItemCategory.COSMETIC_CAPE:
			return "cape"
		ItemCategory.COSMETIC_GLASSES:
			return "glasses"
		ItemCategory.COSMETIC_AURA:
			return "aura"
	return ""


## Get category display name
static func get_category_name(category: ItemCategory) -> String:
	match category:
		ItemCategory.COSMETIC_COLOR:
			return "Colors"
		ItemCategory.COSMETIC_OUTFIT:
			return "Outfits"
		ItemCategory.COSMETIC_HAT:
			return "Hats"
		ItemCategory.COSMETIC_CAPE:
			return "Capes"
		ItemCategory.COSMETIC_GLASSES:
			return "Glasses"
		ItemCategory.COSMETIC_AURA:
			return "Auras"
		ItemCategory.ROOM_DECOR:
			return "Room Decor"
		ItemCategory.FUNCTIONAL:
			return "Boosters"
		ItemCategory.COLLECTIBLE:
			return "Collectibles"
	return "Unknown"


## Get rarity display name
static func get_rarity_name(rarity: ItemRarity) -> String:
	match rarity:
		ItemRarity.COMMON:
			return "Common"
		ItemRarity.UNCOMMON:
			return "Uncommon"
		ItemRarity.RARE:
			return "Rare"
		ItemRarity.LEGENDARY:
			return "Legendary"
	return "Unknown"
