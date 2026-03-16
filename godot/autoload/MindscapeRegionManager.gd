extends Node
## MindscapeRegionManager - Manages navigation between mindscape regions
## Handles region state, player positions, and portal transitions

signal region_changed(new_region: String, old_region: String)
signal portal_entered(region_id: String)

# Region definitions
const REGIONS = {
	"hub": {
		"scene": "res://scenes/mindscape/mindscape_hub.tscn",
		"name": "Central Hub",
		"zones": ["FocusChamber", "DailyRituals", "ReflectionPool"],
		"unlock_requirement": "none",
		"theme_color": Color(0.83, 0.66, 0.29)  # Gold
	},
	"north": {
		"scene": "res://scenes/mindscape/mindscape_north.tscn",
		"name": "Northern Gardens",
		"zones": ["DreamGarden", "MemoryArchive"],
		"unlock_requirement": "chapter_3",
		"theme_color": Color(0.4, 0.7, 0.5)  # Green
	},
	"east": {
		"scene": "res://scenes/mindscape/mindscape_east.tscn",
		"name": "Eastern Observatory",
		"zones": ["Observatory", "ReflectionPool"],
		"unlock_requirement": "chapter_5",
		"theme_color": Color(0.5, 0.5, 0.8)  # Purple-blue
	},
	"west": {
		"scene": "res://scenes/mindscape/mindscape_west.tscn",
		"name": "Western Depths",
		"zones": ["ShadowWork", "AspectShrine"],
		"unlock_requirement": "chapter_7",
		"theme_color": Color(0.6, 0.4, 0.7)  # Purple
	},
	"south": {
		"scene": "res://scenes/mindscape/mindscape_south.tscn",
		"name": "Southern Peaks",
		"zones": ["TrainingArena", "ScriptLab", "GoalCompass", "Summit"],
		"unlock_requirement": "chapter_4",
		"theme_color": Color(0.7, 0.55, 0.35)  # Brown/gold
	}
}

# Portal spawn positions (where player appears when entering a region)
const PORTAL_SPAWN_POSITIONS = {
	"hub": {
		"from_north": Vector2(0, -200),
		"from_east": Vector2(250, 0),
		"from_west": Vector2(-250, 0),
		"from_south": Vector2(0, 200),
		"default": Vector2(0, 50)
	},
	"north": {
		"from_hub": Vector2(0, 250),
		"default": Vector2(0, 200)
	},
	"east": {
		"from_hub": Vector2(-200, 0),
		"default": Vector2(-150, 0)
	},
	"west": {
		"from_hub": Vector2(200, 0),
		"default": Vector2(150, 0)
	},
	"south": {
		"from_hub": Vector2(0, -200),
		"default": Vector2(0, -150)
	}
}

# Current state
var current_region: String = "hub"
var player_positions: Dictionary = {}  # region_id -> Vector2
var last_portal_used: String = ""  # For determining spawn position


func _ready() -> void:
	_load_region_state()
	print("[MindscapeRegionManager] Initialized - Current region: ", current_region)


## Check if a region is unlocked
func is_region_unlocked(region_id: String) -> bool:
	# Master key unlocks everything
	if GameManager.has_master_key():
		return true

	if region_id == "hub":
		return true

	var region = REGIONS.get(region_id, {})
	var requirement = region.get("unlock_requirement", "none")

	if requirement == "none":
		return true

	# Check chapter requirements
	if requirement.begins_with("chapter_"):
		var chapter_num = int(requirement.split("_")[1])
		return CampaignManager.get_highest_completed_chapter() >= chapter_num

	return false


## Get unlock requirement text for a region
func get_unlock_requirement_text(region_id: String) -> String:
	var region = REGIONS.get(region_id, {})
	var requirement = region.get("unlock_requirement", "none")

	if requirement == "none":
		return "Available"

	if requirement.begins_with("chapter_"):
		var chapter_num = requirement.split("_")[1]
		return "Complete Chapter " + chapter_num

	return "Locked"


## Get region name
func get_region_name(region_id: String) -> String:
	var region = REGIONS.get(region_id, {})
	return region.get("name", region_id.capitalize())


## Get region theme color
func get_region_theme_color(region_id: String) -> Color:
	var region = REGIONS.get(region_id, {})
	return region.get("theme_color", Color(0.5, 0.5, 0.5))


## Save player position for current region
func save_player_position(region_id: String, position: Vector2) -> void:
	player_positions[region_id] = position


## Get saved player position for a region
func get_saved_position(region_id: String) -> Vector2:
	return player_positions.get(region_id, Vector2.ZERO)


## Get spawn position when entering a region
func get_spawn_position(target_region: String, from_region: String = "") -> Vector2:
	var positions = PORTAL_SPAWN_POSITIONS.get(target_region, {})

	if from_region != "":
		var key = "from_" + from_region
		if positions.has(key):
			return positions[key]

	return positions.get("default", Vector2.ZERO)


## Travel to a region
func travel_to_region(target_region: String, from_portal: String = "") -> void:
	if not REGIONS.has(target_region):
		push_error("[MindscapeRegionManager] Unknown region: " + target_region)
		return

	if not is_region_unlocked(target_region):
		push_warning("[MindscapeRegionManager] Region locked: " + target_region)
		return

	var old_region = current_region
	last_portal_used = from_portal if from_portal != "" else old_region

	# Emit signal before changing
	portal_entered.emit(target_region)

	# Update state
	current_region = target_region
	_save_region_state()

	# Emit change signal
	region_changed.emit(target_region, old_region)

	# Transition to region scene
	var region = REGIONS[target_region]
	GameManager.player_data["transition_type"] = "region"
	GameManager.player_data["transition_target"] = region.scene
	GameManager.player_data["transition_color"] = region.theme_color
	get_tree().change_scene_to_file("res://scenes/transition/region_transition.tscn")


## Get zones in a specific region
func get_region_zones(region_id: String) -> Array:
	var region = REGIONS.get(region_id, {})
	return region.get("zones", [])


## Get which region a zone belongs to
func get_zone_region(zone_id: String) -> String:
	for region_id in REGIONS:
		var zones = REGIONS[region_id].get("zones", [])
		if zone_id in zones:
			return region_id
	return "hub"


## Get all unlocked regions
func get_unlocked_regions() -> Array:
	var unlocked = []
	for region_id in REGIONS:
		if is_region_unlocked(region_id):
			unlocked.append(region_id)
	return unlocked


## Save region state to GameManager
func _save_region_state() -> void:
	GameManager.player_data["mindscape_region"] = current_region
	GameManager.player_data["mindscape_positions"] = player_positions


## Load region state from GameManager
func _load_region_state() -> void:
	current_region = GameManager.player_data.get("mindscape_region", "hub")
	player_positions = GameManager.player_data.get("mindscape_positions", {})


## Reset to hub (for new game)
func reset_to_hub() -> void:
	current_region = "hub"
	player_positions = {}
	last_portal_used = ""
	_save_region_state()
