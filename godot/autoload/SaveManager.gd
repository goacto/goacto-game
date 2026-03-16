extends Node
## SaveManager - Handles game persistence
## Saves player progress, habits, world state to local storage
## Supports 3 save slots and export/import functionality

const SAVE_PATH = "user://mindscape_save.json"  # Default/auto-save
const SETTINGS_PATH = "user://mindscape_settings.json"
const SAVE_SLOT_PREFIX = "user://mindscape_save_slot_"
const JOURNAL_SLOT_PREFIX = "user://mindscape_journal_slot_"
const NUM_SAVE_SLOTS = 3

var current_slot: int = 0  # 0 = auto-save, 1-3 = manual slots

signal save_completed
signal load_completed
signal save_error(message: String)
signal slot_saved(slot: int)
signal slot_loaded(slot: int)


func _ready() -> void:
	print("[SaveManager] Initialized - Save path: ", SAVE_PATH)


## Save all game data
func save_game() -> void:
	var save_data = {
		"version": "0.3.2",
		"timestamp": Time.get_unix_time_from_system(),
		"player": GameManager.player_data,
		"habits": HabitManager.get_save_data(),
		"goals": GoalManager.get_save_data(),
		"scripts": ScriptManager.get_save_data(),
		"challenges": ChallengeManager.get_save_data() if ChallengeManager else {},
		"achievements": AchievementManager.get_save_data() if AchievementManager else {},
		"shop": ShopManager.get_save_data() if ShopManager else {},
		"mail": MailManager.get_save_data() if MailManager else {},
		"relationships": RelationshipManager.get_save_data() if RelationshipManager else {}
	}

	var json_string = JSON.stringify(save_data, "\t")

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		save_completed.emit()
		print("[SaveManager] Game saved successfully")
	else:
		var error_msg = "Failed to save game: " + str(FileAccess.get_open_error())
		save_error.emit(error_msg)
		push_error("[SaveManager] ", error_msg)


## Load game data
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] No save file found - starting fresh")
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("[SaveManager] Failed to open save file")
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("[SaveManager] Failed to parse save file")
		return false

	var save_data = json.get_data()

	# Restore player data
	if save_data.has("player"):
		_merge_dict(GameManager.player_data, save_data.player)

	# Restore habit data
	if save_data.has("habits"):
		HabitManager.load_save_data(save_data.habits)

	# Restore goal data
	if save_data.has("goals"):
		GoalManager.load_save_data(save_data.goals)

	# Restore script data
	if save_data.has("scripts"):
		ScriptManager.load_save_data(save_data.scripts)

	# Restore challenge data
	if save_data.has("challenges") and ChallengeManager:
		ChallengeManager.load_save_data(save_data.challenges)

	# Restore achievement data
	if save_data.has("achievements") and AchievementManager:
		AchievementManager.load_save_data(save_data.achievements)

	# Restore shop data
	if save_data.has("shop") and ShopManager:
		ShopManager.load_save_data(save_data.shop)

	# Restore mail data
	if save_data.has("mail") and MailManager:
		MailManager.load_save_data(save_data.mail)

	# Restore relationship data
	if save_data.has("relationships") and RelationshipManager:
		RelationshipManager.load_save_data(save_data.relationships)

	load_completed.emit()
	print("[SaveManager] Game loaded successfully")
	return true


## Delete save file (for testing or reset)
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveManager] Save file deleted")


## Check if a save exists
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Deep merge dictionary (preserves nested structure)
func _merge_dict(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.has(key) and target[key] is Dictionary and source[key] is Dictionary:
			_merge_dict(target[key], source[key])
		else:
			target[key] = source[key]


## Save settings separately (audio, preferences, etc.)
func save_settings(settings: Dictionary) -> void:
	var json_string = JSON.stringify(settings, "\t")

	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("[SaveManager] Settings saved")


## Load settings
func load_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return _get_default_settings()

	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return _get_default_settings()

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return _get_default_settings()

	return json.get_data()


func _get_default_settings() -> Dictionary:
	return {
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"notifications_enabled": true,
		"haptic_feedback": true
	}


# =============================================================================
# SAVE SLOTS
# =============================================================================

## Get the file path for a specific save slot
func _get_slot_path(slot: int) -> String:
	return SAVE_SLOT_PREFIX + str(slot) + ".json"


## Get the journal file path for the current slot
func get_journal_path() -> String:
	if current_slot == 0:
		return "user://mindscape_journal.json"  # Default/auto-save journal
	else:
		return JOURNAL_SLOT_PREFIX + str(current_slot) + ".json"


## Get the gratitude journal path for the current slot
func get_gratitude_path() -> String:
	if current_slot == 0:
		return "user://gratitude_journal.json"
	else:
		return "user://gratitude_journal_slot_" + str(current_slot) + ".json"


## Get the dream journal path for the current slot
func get_dream_path() -> String:
	if current_slot == 0:
		return "user://dream_journal.json"
	else:
		return "user://dream_journal_slot_" + str(current_slot) + ".json"


## Get the shadow journal path for the current slot
func get_shadow_path() -> String:
	if current_slot == 0:
		return "user://shadow_journal.json"
	else:
		return "user://shadow_journal_slot_" + str(current_slot) + ".json"


## Save to a specific slot (1-3) with optional custom name
func save_to_slot(slot: int, custom_name: String = "") -> bool:
	if slot < 1 or slot > NUM_SAVE_SLOTS:
		push_error("[SaveManager] Invalid slot number: ", slot)
		return false

	current_slot = slot  # Track which slot we're using

	# Check if this is a new save or updating existing
	var existing_info = get_slot_info(slot)
	var created_timestamp = existing_info.get("created_timestamp", 0)
	if created_timestamp == 0 or not existing_info.exists:
		created_timestamp = Time.get_unix_time_from_system()

	var save_data = _create_save_data()
	save_data["slot"] = slot
	save_data["slot_name"] = custom_name if custom_name != "" else "Slot " + str(slot)
	save_data["days_completed"] = _count_unique_days()
	save_data["created_timestamp"] = created_timestamp

	var json_string = JSON.stringify(save_data, "\t")
	var path = _get_slot_path(slot)

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		slot_saved.emit(slot)
		print("[SaveManager] Saved to slot ", slot, " as '", save_data["slot_name"], "'")
		return true
	else:
		push_error("[SaveManager] Failed to save to slot ", slot)
		return false


## Count unique days the player has been active (based on journal entries)
func _count_unique_days() -> int:
	var days = {}
	var journal_path = get_journal_path()
	if FileAccess.file_exists(journal_path):
		var file = FileAccess.open(journal_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data = json.get_data()
				if data is Array:
					for entry in data:
						var date = entry.get("date", "")
						if date != "":
							days[date] = true
			file.close()
	return days.size()


## Load from a specific slot (1-3)
func load_from_slot(slot: int) -> bool:
	if slot < 1 or slot > NUM_SAVE_SLOTS:
		push_error("[SaveManager] Invalid slot number: ", slot)
		return false

	var path = _get_slot_path(slot)
	if not FileAccess.file_exists(path):
		print("[SaveManager] No save file in slot ", slot)
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[SaveManager] Failed to open slot ", slot)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		push_error("[SaveManager] Failed to parse save file in slot ", slot)
		return false

	var save_data = json.get_data()
	_apply_save_data(save_data)

	current_slot = slot  # Track which slot we loaded from
	slot_loaded.emit(slot)
	print("[SaveManager] Loaded from slot ", slot)
	return true


## Delete a specific slot
func delete_slot(slot: int) -> void:
	if slot < 1 or slot > NUM_SAVE_SLOTS:
		return

	var path = _get_slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("[SaveManager] Deleted slot ", slot)


## Check if a slot has a save
func has_slot_save(slot: int) -> bool:
	if slot < 1 or slot > NUM_SAVE_SLOTS:
		return false
	return FileAccess.file_exists(_get_slot_path(slot))


## Get metadata for all slots (for displaying in UI)
func get_all_slot_info() -> Array:
	var slots = []
	for i in range(1, NUM_SAVE_SLOTS + 1):
		slots.append(get_slot_info(i))
	return slots


## Get info for a specific slot
func get_slot_info(slot: int) -> Dictionary:
	var info = {
		"slot": slot,
		"exists": false,
		"timestamp": 0,
		"created_timestamp": 0,
		"date_string": "",
		"created_date_string": "",
		"slot_name": "Empty Slot",
		"days_completed": 0,
		"evolution_level": 1,
		"focus_sessions": 0,
		"habits_completed": 0,
		"current_chapter": "chapter_1",
		"chapter_number": 1
	}

	if not has_slot_save(slot):
		return info

	var path = _get_slot_path(slot)
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return info

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return info

	var data = json.get_data()
	info["exists"] = true
	info["timestamp"] = data.get("timestamp", 0)
	info["created_timestamp"] = data.get("created_timestamp", data.get("timestamp", 0))
	info["slot_name"] = data.get("slot_name", "Slot " + str(slot))
	info["days_completed"] = data.get("days_completed", 0)

	# Format last saved date
	if info["timestamp"] > 0:
		var datetime = Time.get_datetime_dict_from_unix_time(int(info["timestamp"]))
		info["date_string"] = "%04d-%02d-%02d %02d:%02d" % [
			datetime.year, datetime.month, datetime.day,
			datetime.hour, datetime.minute
		]

	# Format creation date
	if info["created_timestamp"] > 0:
		var datetime = Time.get_datetime_dict_from_unix_time(int(info["created_timestamp"]))
		info["created_date_string"] = "%04d-%02d-%02d" % [
			datetime.year, datetime.month, datetime.day
		]

	# Get player data
	var player = data.get("player", {})
	info["evolution_level"] = player.get("evolution_level", 1)
	info["habits_completed"] = player.get("total_habits_completed", 0)

	# Get campaign data for chapter info
	var campaign = data.get("campaign", {})
	info["current_chapter"] = campaign.get("current_chapter", "chapter_1")
	# Extract chapter number from "chapter_X" format
	if info["current_chapter"].begins_with("chapter_"):
		info["chapter_number"] = int(info["current_chapter"].split("_")[1])
	else:
		info["chapter_number"] = 1

	# Count focus sessions from journal (more accurate than counter)
	info["focus_sessions"] = _count_focus_journal_entries_for_slot(slot)

	return info


## Count actual focus session entries from the journal file for a specific slot
func _count_focus_journal_entries_for_slot(slot: int) -> int:
	var path: String
	if slot == 0:
		path = "user://mindscape_journal.json"
	else:
		path = JOURNAL_SLOT_PREFIX + str(slot) + ".json"

	if not FileAccess.file_exists(path):
		return 0

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return 0

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return 0

	var data = json.get_data()
	if data is Array:
		return data.size()
	return 0


# =============================================================================
# EXPORT / IMPORT
# =============================================================================

## Get save data as a JSON string for export
func export_save_data() -> String:
	var save_data = _create_save_data()
	save_data["export_date"] = Time.get_datetime_string_from_system()
	return JSON.stringify(save_data, "\t")


## Export a specific slot as JSON string
func export_slot(slot: int) -> String:
	if slot < 1 or slot > NUM_SAVE_SLOTS:
		return ""

	var path = _get_slot_path(slot)
	if not FileAccess.file_exists(path):
		return ""

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return ""

	var content = file.get_as_text()
	file.close()
	return content


## Import save data from JSON string
func import_save_data(json_string: String) -> bool:
	var json = JSON.new()
	if json.parse(json_string) != OK:
		push_error("[SaveManager] Failed to parse imported data")
		return false

	var save_data = json.get_data()
	if not save_data is Dictionary:
		push_error("[SaveManager] Invalid import data format")
		return false

	# Validate it looks like a save file
	if not save_data.has("player") or not save_data.has("version"):
		push_error("[SaveManager] Import data missing required fields")
		return false

	_apply_save_data(save_data)
	print("[SaveManager] Imported save data successfully")
	return true


## Import save data into a specific slot
func import_to_slot(slot: int, json_string: String) -> bool:
	if slot < 1 or slot > NUM_SAVE_SLOTS:
		return false

	var json = JSON.new()
	if json.parse(json_string) != OK:
		push_error("[SaveManager] Failed to parse imported data")
		return false

	var save_data = json.get_data()
	if not save_data is Dictionary:
		return false

	# Validate it looks like a save file
	if not save_data.has("player") or not save_data.has("version"):
		return false

	# Update slot info
	save_data["slot"] = slot
	save_data["timestamp"] = Time.get_unix_time_from_system()

	var path = _get_slot_path(slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[SaveManager] Imported to slot ", slot)
		return true

	return false


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Create save data dictionary from current game state
func _create_save_data() -> Dictionary:
	return {
		"version": "0.3.2",
		"timestamp": Time.get_unix_time_from_system(),
		"player": GameManager.player_data,
		"habits": HabitManager.get_save_data(),
		"goals": GoalManager.get_save_data(),
		"scripts": ScriptManager.get_save_data(),
		"challenges": ChallengeManager.get_save_data() if ChallengeManager else {},
		"achievements": AchievementManager.get_save_data() if AchievementManager else {},
		"campaign": CampaignManager.get_save_data(),
		"shop": ShopManager.get_save_data() if ShopManager else {},
		"mail": MailManager.get_save_data() if MailManager else {},
		"relationships": RelationshipManager.get_save_data() if RelationshipManager else {}
	}


## Apply save data to game state
func _apply_save_data(save_data: Dictionary) -> void:
	# Restore player data
	if save_data.has("player"):
		_merge_dict(GameManager.player_data, save_data.player)

	# Restore habit data
	if save_data.has("habits"):
		HabitManager.load_save_data(save_data.habits)

	# Restore goal data
	if save_data.has("goals"):
		GoalManager.load_save_data(save_data.goals)

	# Restore script data
	if save_data.has("scripts"):
		ScriptManager.load_save_data(save_data.scripts)

	# Restore challenge data
	if save_data.has("challenges") and ChallengeManager:
		ChallengeManager.load_save_data(save_data.challenges)

	# Restore achievement data
	if save_data.has("achievements") and AchievementManager:
		AchievementManager.load_save_data(save_data.achievements)

	# Restore campaign progress (cutscenes seen, chapters completed, etc.)
	if save_data.has("campaign"):
		CampaignManager.load_save_data(save_data.campaign)

	# Restore shop data (owned items, equipped cosmetics)
	if save_data.has("shop") and ShopManager:
		ShopManager.load_save_data(save_data.shop)

	# Restore mail data (pending orders, available mail)
	if save_data.has("mail") and MailManager:
		MailManager.load_save_data(save_data.mail)

	# Restore relationship data
	if save_data.has("relationships") and RelationshipManager:
		RelationshipManager.load_save_data(save_data.relationships)

	load_completed.emit()
