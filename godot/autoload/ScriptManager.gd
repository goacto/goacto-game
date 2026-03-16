extends Node
## ScriptManager - Personal Operating System Manager
## "Life is the result of the scripts we allow ourselves to run."
##
## Structure:
## PersonalOS (name.OS)
##   └── Layer (life domain)
##       └── Package (specific area)
##           └── PSA File (25 lines = 25 min focus session)

signal script_created(script: Dictionary)
signal script_updated(script: Dictionary)
signal script_executed(script: Dictionary, results: Dictionary)
signal package_executed(package: Dictionary, scripts: Array)
signal run_record_saved(record: Dictionary)

# Script types (legacy - kept for backwards compatibility)
enum ScriptType {
	UPDATE,     # Learning, improvement activities
	UPGRADE,    # Positive paradigm shifts
	DOWNGRADE,  # Routines/apps slowing your system (to remove)
	VIRUS       # Limiting beliefs (to debug/address)
}

# Operational layers - how the script affects your personal OS
enum OperationalLayer {
	BASELINE,    # Heartbeat scripts - daily essentials that keep you running
	UPDATE,      # Learning and improvement activities
	UPGRADE,     # Paradigm shifts that level you up
	BLOATWARE,   # Routines slowing your system (to identify/remove)
	VIRUS        # Limiting beliefs to debug/address
}

# Operational layer data
const OPERATIONAL_LAYERS = [
	{"id": "baseline", "name": "Baseline", "icon": "heartbeat", "description": "Daily essentials that keep you running", "color": Color(0.5, 0.7, 0.9)},
	{"id": "update", "name": "Update", "icon": "refresh", "description": "Learning & improvement activities", "color": Color(0.3, 0.6, 0.9)},
	{"id": "upgrade", "name": "Upgrade", "icon": "rocket", "description": "Paradigm shifts that level you up", "color": Color(0.4, 0.8, 0.4)},
	{"id": "bloatware", "name": "Bloatware", "icon": "snail", "description": "Routines slowing your system", "color": Color(0.9, 0.6, 0.2)},
	{"id": "virus", "name": "Virus", "icon": "bug", "description": "Limiting beliefs to debug", "color": Color(0.8, 0.3, 0.3)}
]

# Default layers
const DEFAULT_LAYERS = [
	{"id": "mind", "name": "Mind", "icon": "brain", "description": "Mental growth, learning, focus"},
	{"id": "body", "name": "Body", "icon": "heart", "description": "Physical health, movement, energy"},
	{"id": "soul", "name": "Soul", "icon": "star", "description": "Purpose, meaning, spirituality"},
	{"id": "social", "name": "Social", "icon": "users", "description": "Relationships, community, connection"},
	{"id": "career", "name": "Career", "icon": "briefcase", "description": "Work, craft, contribution"},
	{"id": "wealth", "name": "Wealth", "icon": "coins", "description": "Financial growth, resources"}
]

# The Personal OS
var personal_os: Dictionary = {
	"name": "Personal",
	"version": "1.0.0",
	"created_at": 0,
	"layers": {},
	"active_scripts": [],
	"execution_log": []
}

# All scripts indexed by ID
var scripts: Dictionary = {}

# All packages indexed by ID
var packages: Dictionary = {}

# Run records - detailed logs of script executions
# Key: run_id, Value: { script_id, timestamp, line_results[], reflection, completion_rate, etc. }
var run_records: Dictionary = {}

# Favorite script IDs
var favorite_scripts: Array = []


func _ready() -> void:
	_initialize_default_os()
	print("[ScriptManager] Personal OS initialized: ", personal_os.name, ".OS")


## Initialize the default OS structure
func _initialize_default_os() -> void:
	personal_os.created_at = Time.get_unix_time_from_system()

	# Create default layers
	for layer_data in DEFAULT_LAYERS:
		create_layer(layer_data.id, layer_data.name, layer_data.description)


## Set the OS name (player's name)
func set_os_name(name: String) -> void:
	personal_os.name = name
	_save_os()


## Create a new layer
func create_layer(id: String, name: String, description: String = "") -> Dictionary:
	var layer = {
		"id": id,
		"name": name,
		"description": description,
		"packages": [],
		"created_at": Time.get_unix_time_from_system()
	}
	personal_os.layers[id] = layer
	_save_os()
	return layer


## Create a new package within a layer
func create_package(layer_id: String, name: String, description: String = "") -> String:
	if not personal_os.layers.has(layer_id):
		push_error("[ScriptManager] Layer not found: ", layer_id)
		return ""

	var pkg_id = "pkg_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)

	var package = {
		"id": pkg_id,
		"layer_id": layer_id,
		"name": name,
		"description": description,
		"scripts": [],
		"created_at": Time.get_unix_time_from_system()
	}

	packages[pkg_id] = package
	personal_os.layers[layer_id].packages.append(pkg_id)
	_save_os()

	print("[ScriptManager] Package created: ", name, " in ", layer_id, ".layer")
	return pkg_id


## Create a new PSA (Personal Self Action) script
func create_script(data: Dictionary) -> String:
	var script_id = "psa_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)

	var script = {
		"id": script_id,
		"name": data.get("name", "untitled"),
		"package_id": data.get("package_id", ""),
		"layer_id": data.get("layer_id", "mind"),  # Domain layer (Mind/Body/Soul/Social/Career/Wealth)
		"operational_layer": data.get("operational_layer", "update"),  # Operational layer (baseline/update/upgrade/bloatware/virus)
		"type": data.get("type", ScriptType.UPDATE),  # Legacy type for backwards compatibility
		"lines": data.get("lines", []),  # 25 lines of code (actions)
		"description": data.get("description", ""),
		"duration_minutes": 25,  # Fixed: 25 lines = 25 minutes
		"times_executed": 0,
		"last_executed": 0,
		"created_at": Time.get_unix_time_from_system(),
		"aspect": _get_aspect_for_layer(data.get("layer_id", "mind"))
	}

	# Ensure we have exactly 25 lines (pad with empty if needed)
	while script.lines.size() < 25:
		script.lines.append("")
	if script.lines.size() > 25:
		script.lines = script.lines.slice(0, 25)

	scripts[script_id] = script

	# Add to package if specified
	if data.has("package_id") and packages.has(data.package_id):
		packages[data.package_id].scripts.append(script_id)

	script_created.emit(script)
	_save_os()

	# Track for campaign progress
	CampaignManager.record_script_created()

	# Track for achievements
	if AchievementManager:
		AchievementManager.record_script_created()

	print("[ScriptManager] Script created: ", script.name, ".psa")
	return script_id


## Update an existing script
func update_script(script_id: String, data: Dictionary) -> void:
	if not scripts.has(script_id):
		return

	var script = scripts[script_id]

	if data.has("name"):
		script.name = data.name
	if data.has("lines"):
		script.lines = data.lines
		# Ensure 25 lines
		while script.lines.size() < 25:
			script.lines.append("")
		if script.lines.size() > 25:
			script.lines = script.lines.slice(0, 25)
	if data.has("description"):
		script.description = data.description
	if data.has("type"):
		script.type = data.type
	if data.has("operational_layer"):
		script.operational_layer = data.operational_layer
	if data.has("layer_id"):
		script.layer_id = data.layer_id
		script.aspect = _get_aspect_for_layer(data.layer_id)

	script_updated.emit(script)
	_save_os()


## Execute a single script (start focus session)
## Returns the script data and creates a pending run record
func execute_script(script_id: String) -> Dictionary:
	if not scripts.has(script_id):
		return {}

	var script = scripts[script_id]
	script.times_executed += 1
	script.last_executed = Time.get_unix_time_from_system()

	# Create a run record ID for this execution
	var run_id = "run_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)

	# Initialize run record (will be completed after session)
	var run_record = {
		"id": run_id,
		"script_id": script_id,
		"script_name": script.name,
		"script_version": script.get("version", 1),
		"started_at": Time.get_unix_time_from_system(),
		"completed_at": 0,
		"lines_planned": script.lines.duplicate(),
		"line_results": [],  # Array of { status: "completed"|"partial"|"skipped", note: "" }
		"reflection": "",
		"completion_rate": 0.0,
		"overall_rating": 0,  # 1-5 stars
		"status": "in_progress"
	}

	# Initialize line results with pending status
	for i in range(25):
		run_record.line_results.append({
			"status": "pending",
			"note": ""
		})

	run_records[run_id] = run_record

	# Add to execution log
	var log_entry = {
		"script_id": script_id,
		"script_name": script.name,
		"run_id": run_id,
		"executed_at": Time.get_unix_time_from_system(),
		"type": script.type
	}
	personal_os.execution_log.append(log_entry)

	# Keep only last 100 entries
	if personal_os.execution_log.size() > 100:
		personal_os.execution_log = personal_os.execution_log.slice(-100)

	_save_os()

	# Track for campaign progress
	CampaignManager.record_script_executed()

	# Return script with run_id attached
	var result = script.duplicate()
	result["current_run_id"] = run_id
	return result


## Complete a run record after a focus session
func complete_run_record(run_id: String, data: Dictionary) -> void:
	if not run_records.has(run_id):
		return

	var record = run_records[run_id]
	record.completed_at = Time.get_unix_time_from_system()
	record.status = "completed"

	if data.has("line_results"):
		record.line_results = data.line_results
	if data.has("reflection"):
		record.reflection = data.reflection
	if data.has("overall_rating"):
		record.overall_rating = data.overall_rating

	# Calculate completion rate
	var completed_count = 0
	for result in record.line_results:
		if result.get("status", "") == "completed":
			completed_count += 1
		elif result.get("status", "") == "partial":
			completed_count += 0.5
	record.completion_rate = float(completed_count) / 25.0

	# Update script statistics
	if scripts.has(record.script_id):
		var script = scripts[record.script_id]
		if not script.has("avg_completion_rate"):
			script["avg_completion_rate"] = record.completion_rate
		else:
			# Running average
			var runs = script.get("times_executed", 1)
			script["avg_completion_rate"] = (script["avg_completion_rate"] * (runs - 1) + record.completion_rate) / runs

		# Track line effectiveness
		if not script.has("line_stats"):
			script["line_stats"] = []
			for i in range(25):
				script["line_stats"].append({"completed": 0, "partial": 0, "skipped": 0})

		for i in range(mini(record.line_results.size(), 25)):
			var status = record.line_results[i].get("status", "pending")
			if status == "completed":
				script["line_stats"][i]["completed"] += 1
			elif status == "partial":
				script["line_stats"][i]["partial"] += 1
			elif status == "skipped":
				script["line_stats"][i]["skipped"] += 1

	run_record_saved.emit(record)
	_save_os()


## Get run records for a specific script
func get_script_run_records(script_id: String) -> Array:
	var records = []
	for record in run_records.values():
		if record.get("script_id", "") == script_id and record.get("status", "") == "completed":
			records.append(record)

	# Sort by date (newest first)
	records.sort_custom(func(a, b): return a.get("completed_at", 0) > b.get("completed_at", 0))
	return records


## Get the most recent run record for a script
func get_latest_run(script_id: String) -> Dictionary:
	var records = get_script_run_records(script_id)
	if records.is_empty():
		return {}
	return records[0]


## Toggle favorite status for a script
func toggle_favorite(script_id: String) -> bool:
	if favorite_scripts.has(script_id):
		favorite_scripts.erase(script_id)
		_save_os()
		return false
	else:
		favorite_scripts.append(script_id)
		_save_os()
		return true


## Check if a script is favorited
func is_favorite(script_id: String) -> bool:
	return favorite_scripts.has(script_id)


## Get all favorite scripts
func get_favorite_scripts() -> Array:
	var favorites = []
	for script_id in favorite_scripts:
		if scripts.has(script_id):
			favorites.append(scripts[script_id])
	return favorites


## Create a new version of a script based on a run review
func create_script_iteration(original_script_id: String, new_lines: Array, notes: String = "") -> String:
	if not scripts.has(original_script_id):
		return ""

	var original = scripts[original_script_id]

	# Increment version on original or start at 1
	var new_version = original.get("version", 1) + 1

	# Create the new script
	var new_script_id = create_script({
		"name": original.name + "_v" + str(new_version),
		"layer_id": original.layer_id,
		"type": original.type,
		"lines": new_lines,
		"description": notes if notes != "" else original.get("description", ""),
		"parent_script_id": original_script_id,
		"version": new_version
	})

	# Link scripts for history
	if not original.has("child_versions"):
		original["child_versions"] = []
	original["child_versions"].append(new_script_id)

	if scripts.has(new_script_id):
		scripts[new_script_id]["parent_script_id"] = original_script_id
		scripts[new_script_id]["version"] = new_version

	_save_os()
	return new_script_id


## Get line effectiveness stats for a script (which lines are often skipped/partial)
func get_line_effectiveness(script_id: String) -> Array:
	if not scripts.has(script_id):
		return []

	var script = scripts[script_id]
	if not script.has("line_stats"):
		return []

	var effectiveness = []
	for i in range(script["line_stats"].size()):
		var stats = script["line_stats"][i]
		var total = stats.completed + stats.partial + stats.skipped
		if total == 0:
			effectiveness.append({"line": i, "rate": 0.0, "status": "no_data"})
		else:
			var rate = (stats.completed + stats.partial * 0.5) / float(total)
			var status = "good" if rate >= 0.8 else ("needs_work" if rate >= 0.5 else "problematic")
			effectiveness.append({"line": i, "rate": rate, "status": status, "stats": stats})

	return effectiveness


## Create a batch run (multiple scripts in sequence)
func create_batch(script_ids: Array, name: String = "Batch Run") -> Dictionary:
	var batch = {
		"name": name,
		"scripts": [],
		"total_duration": 0
	}

	for script_id in script_ids:
		if scripts.has(script_id):
			batch.scripts.append(scripts[script_id])
			batch.total_duration += 25

	return batch


## Get all scripts in a package
func get_package_scripts(package_id: String) -> Array:
	if not packages.has(package_id):
		return []

	var result = []
	for script_id in packages[package_id].scripts:
		if scripts.has(script_id):
			result.append(scripts[script_id])
	return result


## Get all scripts by type
func get_scripts_by_type(type: ScriptType) -> Array:
	var result = []
	for script in scripts.values():
		if script.type == type:
			result.append(script)
	return result


## Get all scripts in a layer
func get_layer_scripts(layer_id: String) -> Array:
	var result = []
	for script in scripts.values():
		if script.layer_id == layer_id:
			result.append(script)
	return result


## Get all operational layers
func get_operational_layers() -> Array:
	return OPERATIONAL_LAYERS.duplicate()


## Get scripts by operational layer
func get_scripts_by_operational_layer(op_layer: String) -> Array:
	var result = []
	for script in scripts.values():
		if script.get("operational_layer", "update") == op_layer:
			result.append(script)
	return result


## Get audit scripts (Bloatware + Virus - scripts that need attention)
func get_audit_scripts() -> Array:
	var result = []
	for script in scripts.values():
		var op_layer = script.get("operational_layer", "update")
		if op_layer == "bloatware" or op_layer == "virus":
			result.append(script)
	return result


## Get operational layer data by ID
func get_operational_layer_data(op_layer_id: String) -> Dictionary:
	for layer in OPERATIONAL_LAYERS:
		if layer.id == op_layer_id:
			return layer
	return OPERATIONAL_LAYERS[1]  # Default to "update"


## Get operational layer color
func get_operational_layer_color(op_layer_id: String) -> Color:
	var data = get_operational_layer_data(op_layer_id)
	return data.get("color", Color.WHITE)


## Get operational layer name
func get_operational_layer_name(op_layer_id: String) -> String:
	var data = get_operational_layer_data(op_layer_id)
	return data.get("name", "Update")


## Transform a script's operational layer (for audit mode)
func transform_script_layer(script_id: String, new_op_layer: String, new_lines: Array = []) -> String:
	if not scripts.has(script_id):
		return ""

	var original = scripts[script_id]

	# If no new lines provided, use the original lines
	var lines_to_use = new_lines if new_lines.size() > 0 else original.get("lines", [])

	# Create a new transformed version
	var new_script_id = create_script({
		"name": original.name + "_transformed",
		"layer_id": original.layer_id,
		"operational_layer": new_op_layer,
		"type": _get_type_for_operational_layer(new_op_layer),
		"lines": lines_to_use,
		"description": "Transformed from " + original.get("operational_layer", "update") + " to " + new_op_layer,
		"parent_script_id": original.id
	})

	# Link for history
	if not original.has("transformed_versions"):
		original["transformed_versions"] = []
	original["transformed_versions"].append(new_script_id)

	_save_os()
	return new_script_id


## Map operational layer to legacy ScriptType
func _get_type_for_operational_layer(op_layer: String) -> int:
	match op_layer:
		"baseline": return ScriptType.UPDATE
		"update": return ScriptType.UPDATE
		"upgrade": return ScriptType.UPGRADE
		"bloatware": return ScriptType.DOWNGRADE
		"virus": return ScriptType.VIRUS
		_: return ScriptType.UPDATE


## Migrate existing scripts to use operational_layer (call once on load)
func _migrate_scripts_to_operational_layers() -> void:
	var migrated_count = 0
	for script in scripts.values():
		if not script.has("operational_layer"):
			# Map legacy type to operational layer
			match script.get("type", ScriptType.UPDATE):
				ScriptType.UPDATE:
					script["operational_layer"] = "update"
				ScriptType.UPGRADE:
					script["operational_layer"] = "upgrade"
				ScriptType.DOWNGRADE:
					script["operational_layer"] = "bloatware"
				ScriptType.VIRUS:
					script["operational_layer"] = "virus"
				_:
					script["operational_layer"] = "update"
			migrated_count += 1

	if migrated_count > 0:
		print("[ScriptManager] Migrated ", migrated_count, " scripts to operational layers")
		_save_os()


## Get all scripts
func get_all_scripts() -> Array:
	return scripts.values()


## Get all packages in a layer
func get_layer_packages(layer_id: String) -> Array:
	if not personal_os.layers.has(layer_id):
		return []

	var result = []
	for pkg_id in personal_os.layers[layer_id].packages:
		if packages.has(pkg_id):
			result.append(packages[pkg_id])
	return result


## Get all layers
func get_layers() -> Array:
	return personal_os.layers.values()


## Get script type name
func get_type_name(type: ScriptType) -> String:
	match type:
		ScriptType.UPDATE:
			return "update"
		ScriptType.UPGRADE:
			return "upgrade"
		ScriptType.DOWNGRADE:
			return "downgrade"
		ScriptType.VIRUS:
			return "virus"
	return "unknown"


## Get script type description
func get_type_description(type: ScriptType) -> String:
	match type:
		ScriptType.UPDATE:
			return "Learning & improvement activities"
		ScriptType.UPGRADE:
			return "Paradigm shifts that level you up"
		ScriptType.DOWNGRADE:
			return "Routines slowing your system"
		ScriptType.VIRUS:
			return "Limiting beliefs to debug"
	return ""


## Get script type color
func get_type_color(type: ScriptType) -> Color:
	match type:
		ScriptType.UPDATE:
			return Color(0.3, 0.6, 0.9)  # Blue
		ScriptType.UPGRADE:
			return Color(0.4, 0.8, 0.4)  # Green
		ScriptType.DOWNGRADE:
			return Color(0.9, 0.6, 0.2)  # Orange
		ScriptType.VIRUS:
			return Color(0.8, 0.3, 0.3)  # Red
	return Color.WHITE


## Map layers to aspects
func _get_aspect_for_layer(layer_id: String) -> String:
	match layer_id:
		"mind": return "wisdom"
		"body": return "vitality"
		"soul": return "courage"
		"social": return "compassion"
		"career": return "discipline"
		"wealth": return "discipline"
		_: return "discipline"


## Get execution stats
func get_stats() -> Dictionary:
	var total_executions = 0
	var total_scripts = scripts.size()
	var by_type = {
		ScriptType.UPDATE: 0,
		ScriptType.UPGRADE: 0,
		ScriptType.DOWNGRADE: 0,
		ScriptType.VIRUS: 0
	}

	for script in scripts.values():
		total_executions += script.times_executed
		by_type[script.type] = by_type.get(script.type, 0) + 1

	return {
		"total_scripts": total_scripts,
		"total_executions": total_executions,
		"total_focus_minutes": total_executions * 25,
		"scripts_by_type": by_type,
		"os_name": personal_os.name + ".OS"
	}


## Delete a script
func delete_script(script_id: String) -> void:
	if not scripts.has(script_id):
		return

	var script = scripts[script_id]

	# Remove from package
	if script.package_id != "" and packages.has(script.package_id):
		packages[script.package_id].scripts.erase(script_id)

	scripts.erase(script_id)
	_save_os()


## Save the OS to file
func _save_os() -> void:
	var data = {
		"personal_os": personal_os,
		"scripts": scripts,
		"packages": packages,
		"run_records": run_records,
		"favorite_scripts": favorite_scripts
	}

	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open("user://personal_os.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()


## Load the OS from file
func load_os() -> void:
	if not FileAccess.file_exists("user://personal_os.json"):
		return

	var file = FileAccess.open("user://personal_os.json", FileAccess.READ)
	if not file:
		return

	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return

	var data = json.get_data()
	if data is Dictionary:
		if data.has("personal_os"):
			# Merge with defaults to ensure all layers exist
			var loaded_os = data.personal_os
			for key in loaded_os:
				personal_os[key] = loaded_os[key]
		if data.has("scripts"):
			scripts = data.scripts
		if data.has("packages"):
			packages = data.packages
		if data.has("run_records"):
			run_records = data.run_records
		if data.has("favorite_scripts"):
			favorite_scripts = data.favorite_scripts

	# Migrate old scripts to use operational_layer if needed
	_migrate_scripts_to_operational_layers()

	print("[ScriptManager] Loaded ", personal_os.name, ".OS with ", scripts.size(), " scripts, ", run_records.size(), " run records")


## Get save data for SaveManager
func get_save_data() -> Dictionary:
	return {
		"personal_os": personal_os,
		"scripts": scripts,
		"packages": packages,
		"run_records": run_records,
		"favorite_scripts": favorite_scripts
	}


## Load save data
func load_save_data(data: Dictionary) -> void:
	if data.has("personal_os"):
		for key in data.personal_os:
			personal_os[key] = data.personal_os[key]
	if data.has("scripts"):
		scripts = data.scripts
	if data.has("packages"):
		packages = data.packages
	if data.has("run_records"):
		run_records = data.run_records
	if data.has("favorite_scripts"):
		favorite_scripts = data.favorite_scripts


## Reset all scripts and OS to defaults
func reset_scripts() -> void:
	scripts.clear()
	packages.clear()
	run_records.clear()
	favorite_scripts.clear()

	# Reset personal_os
	personal_os = {
		"name": "Personal",
		"version": "1.0.0",
		"created_at": 0,
		"layers": {},
		"active_scripts": [],
		"execution_log": []
	}

	# Re-initialize default layers
	_initialize_default_os()
	_save_os()
	print("[ScriptManager] Personal OS reset to defaults")
