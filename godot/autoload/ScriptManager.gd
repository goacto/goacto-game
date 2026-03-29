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

	# Track for aspect quests
	if GameManager:
		GameManager.check_quests_for_trigger("script_created", {})

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


## Get a single script by ID
func get_script_by_id(script_id: String) -> Dictionary:
	if scripts.has(script_id):
		return scripts[script_id]
	return {}


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
		if SaveManager:
			SaveManager.sync_web_filesystem()


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


# ============ SCRIPT TEMPLATE LIBRARY ============

## Template library - curated scripts to inspire and guide users
const SCRIPT_TEMPLATES = [
	# ===== MIND DOMAIN =====
	{
		"id": "tpl_mind_morning_focus",
		"name": "Morning Mind Activation",
		"layer_id": "mind",
		"operational_layer": "baseline",
		"description": "Start your day with mental clarity and focus. A baseline script for daily cognitive activation.",
		"lines": [
			"Close eyes, take 3 deep breaths - arrive in the present moment",
			"Set intention: 'My mind is clear and ready to engage'",
			"Review your top 3 priorities for today",
			"Visualize successfully completing each priority",
			"Write down any lingering thoughts to clear mental RAM",
			"Read one page of something inspiring or educational",
			"Continue reading, absorbing key insights",
			"Pause and reflect - what resonated?",
			"Jot down one key takeaway",
			"Quick mental math: count backwards from 100 by 7s",
			"Word association: write 10 words related to your focus today",
			"Review your calendar - mentally prepare for each commitment",
			"Identify potential obstacles and quick solutions",
			"Gratitude moment: name 3 things you appreciate",
			"Affirmation: 'I am focused, capable, and ready'",
			"Set a micro-goal for the next hour",
			"Clear your desk/workspace of distractions",
			"Open only essential tabs/apps for first task",
			"Review first task requirements briefly",
			"Break first task into 3 small steps",
			"Write down the first step clearly",
			"Set a timer intention for 25-minute focus",
			"Final breath: inhale energy, exhale resistance",
			"Declare: 'I begin now'",
			"Start your first focused task"
		]
	},
	{
		"id": "tpl_mind_deep_learning",
		"name": "Deep Learning Session",
		"layer_id": "mind",
		"operational_layer": "update",
		"description": "Structured approach to learning new concepts with active recall and spaced repetition techniques.",
		"lines": [
			"State what you will learn today (be specific)",
			"Why does this matter to you? Write one sentence",
			"Recall what you already know about this topic",
			"Open your learning material (book, course, article)",
			"Skim headings and structure - create a mental map",
			"Read/watch the first section actively",
			"Pause - close material - recall 3 key points",
			"Write those points in your own words",
			"Continue to the next section",
			"Read/watch with full attention",
			"Pause - test yourself: what did you just learn?",
			"Write down any questions that arise",
			"Connect new info to something you already know",
			"Create a simple analogy or metaphor",
			"Continue learning the next section",
			"Pause - summarize in one sentence",
			"Look for patterns or themes emerging",
			"Identify the most counterintuitive insight",
			"How might you apply this knowledge?",
			"Write one practical application idea",
			"Review all your notes from this session",
			"Create 3 flashcard-style Q&A pairs",
			"Teach the concept out loud (to yourself or imaginary student)",
			"Schedule: when will you review this material?",
			"Close with: 'I now understand [topic] better'"
		]
	},
	{
		"id": "tpl_mind_creative_problem",
		"name": "Creative Problem Solving",
		"layer_id": "mind",
		"operational_layer": "upgrade",
		"description": "Break through mental blocks with divergent thinking, perspective shifts, and creative ideation.",
		"lines": [
			"Write the problem you're solving clearly",
			"Why hasn't this been solved yet? List obstacles",
			"What would the ideal solution look like?",
			"If money were unlimited, how would you solve it?",
			"If time were unlimited, what approach would you take?",
			"How would a child approach this problem?",
			"How would a scientist approach it?",
			"How would an artist approach it?",
			"What's the opposite of your current approach?",
			"List 10 wild, impossible solutions (don't filter)",
			"Continue listing wild ideas - aim for absurd",
			"Which impossible idea has a kernel of truth?",
			"Combine two different ideas into one hybrid",
			"What would you do if you had to solve this in 1 day?",
			"What would you do if you had 10 years?",
			"Who has solved a similar problem? What did they do?",
			"What resources/skills do you have but aren't using?",
			"Draw/sketch your problem visually",
			"Look for patterns in your sketches",
			"Write the problem as if explaining to a 5-year-old",
			"What assumptions are you making? List them",
			"Challenge each assumption - what if it's wrong?",
			"Select your most promising solution direction",
			"Write the first tiny experiment to test it",
			"Commit: I will try [solution] by [deadline]"
		]
	},
	{
		"id": "tpl_mind_overload",
		"name": "Information Overload Audit",
		"layer_id": "mind",
		"operational_layer": "bloatware",
		"description": "AUDIT SCRIPT: Identify and reduce information consumption that drains without nourishing.",
		"lines": [
			"List all information sources you consume daily",
			"Add apps, websites, newsletters, podcasts, channels",
			"Circle the ones you opened in the last 24 hours",
			"Rate each: Nourishing (N), Neutral (-), Draining (D)",
			"Count: how many are Draining?",
			"What feelings does endless scrolling create?",
			"Which sources trigger comparison or anxiety?",
			"Which sources do you consume on autopilot?",
			"What could you learn in the time spent scrolling?",
			"Calculate: hours/week on low-value consumption",
			"What's one source you could delete right now?",
			"What's one notification you could disable?",
			"Create an 'information diet' - limit to 3 sources",
			"Define specific times for consumption (not all day)",
			"What will you do instead when bored?",
			"How will you handle FOMO?",
			"Set a screen time limit on worst offender",
			"Unfollow or mute 5 accounts now",
			"Move distracting apps off home screen",
			"What book have you been meaning to read instead?",
			"Schedule a 'digital sabbath' this week",
			"Who can hold you accountable?",
			"Write commitment: 'I will reduce [source] by [amount]'",
			"Set a check-in date to review progress",
			"Take action: delete, unsubscribe, or uninstall one thing"
		]
	},

	# ===== BODY DOMAIN =====
	{
		"id": "tpl_body_morning_movement",
		"name": "Morning Movement Ritual",
		"layer_id": "body",
		"operational_layer": "baseline",
		"description": "Wake up your body with gentle movement, stretching, and energizing exercise.",
		"lines": [
			"Stand up - shake out your whole body for 30 seconds",
			"Reach arms overhead, stretch tall, breathe deep",
			"Side bend left, hold, breathe into the stretch",
			"Side bend right, hold, breathe into the stretch",
			"Roll shoulders backward 10 times slowly",
			"Roll neck gently in half circles",
			"Fold forward, let head hang, relax shoulders",
			"Rise slowly, one vertebra at a time",
			"10 arm circles forward, feeling shoulders open",
			"10 arm circles backward",
			"March in place, lifting knees high - 1 minute",
			"10 squats - focus on form, not speed",
			"10 push-ups (modify as needed - wall or knee)",
			"30-second plank hold - engage core",
			"10 lunges each leg - controlled movement",
			"10 jumping jacks (or step-touch if low impact)",
			"Hip circles - 10 each direction",
			"Cat-cow stretches on all fours - 10 cycles",
			"Child's pose - breathe deeply for 30 seconds",
			"Downward dog - pedal feet, stretch calves",
			"Standing quad stretch - each leg 20 seconds",
			"Calf stretch against wall - each leg 20 seconds",
			"Deep breath: inhale 4 counts, hold 4, exhale 8",
			"Smile and appreciate your body",
			"Set intention: 'My body is energized and ready'"
		]
	},
	{
		"id": "tpl_body_hiit",
		"name": "HIIT Energy Blast",
		"layer_id": "body",
		"operational_layer": "update",
		"description": "High-intensity interval training to boost metabolism, strength, and cardiovascular fitness.",
		"lines": [
			"Warm-up: light jogging in place - 1 minute",
			"Arm swings and shoulder rolls to loosen up",
			"ROUND 1: Jumping jacks - 45 seconds all out",
			"Rest and breathe - 15 seconds",
			"High knees - 45 seconds, pump those arms",
			"Rest and breathe - 15 seconds",
			"Burpees (modify as needed) - 45 seconds",
			"Rest and breathe - 15 seconds",
			"Mountain climbers - 45 seconds",
			"Rest and breathe - 15 seconds",
			"Squat jumps - 45 seconds, land softly",
			"Rest and breathe - 30 seconds (drink water)",
			"ROUND 2: Push-up to shoulder tap - 45 seconds",
			"Rest and breathe - 15 seconds",
			"Reverse lunges alternating - 45 seconds",
			"Rest and breathe - 15 seconds",
			"Plank jacks - 45 seconds",
			"Rest and breathe - 15 seconds",
			"Speed skaters - 45 seconds",
			"Rest and breathe - 15 seconds",
			"Bicycle crunches - 45 seconds",
			"Cool down: slow march in place - 1 minute",
			"Stretch quads, hamstrings, calves",
			"Stretch chest, shoulders, triceps",
			"Final deep breaths - celebrate completing this"
		]
	},
	{
		"id": "tpl_body_mindful_eating",
		"name": "Mindful Eating Practice",
		"layer_id": "body",
		"operational_layer": "upgrade",
		"description": "Transform your relationship with food through presence, gratitude, and conscious consumption.",
		"lines": [
			"Before eating: pause and take 3 breaths",
			"Look at your food - notice colors and textures",
			"Express gratitude for this nourishment",
			"Consider the journey this food took to reach you",
			"Check in: am I actually hungry or eating from habit?",
			"Rate your hunger on a scale of 1-10",
			"Set intention: eat slowly and taste fully",
			"Take a small first bite",
			"Put down utensils between bites",
			"Chew slowly - notice textures changing",
			"What flavors can you identify?",
			"Take another bite - notice if it tastes different",
			"Check in with your body - how full are you?",
			"Continue eating mindfully, savoring each bite",
			"Notice when you start to feel satisfied",
			"Pause at the halfway point of your meal",
			"How does your body feel now?",
			"Are you eating for hunger or pleasure now?",
			"Continue if hungry, pause if satisfied",
			"Notice any urge to finish everything",
			"What emotions arise around food?",
			"Take final bites consciously if still hungry",
			"Put down utensils and sit with the feeling of done",
			"Gratitude: thank your body for this nourishment",
			"Reflect: one thing learned about your eating pattern"
		]
	},

	# ===== SOUL DOMAIN =====
	{
		"id": "tpl_soul_meditation",
		"name": "Daily Meditation Practice",
		"layer_id": "soul",
		"operational_layer": "baseline",
		"description": "Ground yourself in stillness and presence. A foundational practice for inner peace.",
		"lines": [
			"Find a comfortable seated position",
			"Close your eyes or soften your gaze",
			"Take 3 deep breaths to arrive",
			"Feel your body making contact with the chair/floor",
			"Notice the temperature of the air",
			"Hear the sounds around you without judgment",
			"Bring attention to your breath - don't change it",
			"Notice the inhale... and the exhale...",
			"When thoughts arise, gently return to breath",
			"No need to fight thoughts - just notice and return",
			"Feel your belly rise and fall",
			"Relax your shoulders... your jaw... your forehead",
			"Continue following the breath",
			"If your mind wanders, that's okay - gently return",
			"Each return to breath is a small victory",
			"Notice any sensations in your body",
			"Send kindness to any area of tension",
			"Expand awareness to include your whole body",
			"You are here, now, breathing, alive",
			"There is nowhere else you need to be",
			"Rest in this moment of peace",
			"Begin to deepen your breaths",
			"Wiggle fingers and toes gently",
			"When ready, slowly open your eyes",
			"Carry this stillness with you into your day"
		]
	},
	{
		"id": "tpl_soul_gratitude_deep",
		"name": "Deep Gratitude Practice",
		"layer_id": "soul",
		"operational_layer": "update",
		"description": "Go beyond surface gratitude to feel genuine appreciation that transforms perspective.",
		"lines": [
			"Close eyes - center yourself with 3 breaths",
			"Think of someone who helped you recently",
			"Visualize their face clearly",
			"What did they do for you?",
			"How did their help make you feel?",
			"Send them silent gratitude",
			"Think of something your body did for you today",
			"Your heart beating, lungs breathing - appreciate it",
			"What's something small you usually take for granted?",
			"Really feel appreciation for it now",
			"Think of a challenge that taught you something",
			"What did you gain from that difficulty?",
			"Feel gratitude for the growth",
			"Think of a possession that makes your life easier",
			"Imagine life without it - then appreciate having it",
			"Who loved you when you were a child?",
			"Send them gratitude across time",
			"What about your current home brings you comfort?",
			"Appreciate that specific thing",
			"Think of an ability you have that serves you",
			"Express gratitude for being able to do that",
			"What opportunity do you have that others don't?",
			"Feel the weight of that privilege with gratitude",
			"Take a breath of pure appreciation",
			"Open eyes - commit to expressing thanks today"
		]
	},
	{
		"id": "tpl_soul_purpose",
		"name": "Purpose Discovery Session",
		"layer_id": "soul",
		"operational_layer": "upgrade",
		"description": "Explore your deeper calling and what gives your life meaning beyond daily activities.",
		"lines": [
			"Close eyes and center yourself",
			"Imagine you're 90 years old, looking back at life",
			"What do you hope you'll have accomplished?",
			"Write down what came to mind",
			"What activities make time disappear for you?",
			"When do you feel most alive and engaged?",
			"What problems in the world genuinely upset you?",
			"What would you work on if money were irrelevant?",
			"As a child, what did you love doing?",
			"What have people consistently asked you for help with?",
			"What compliments do you receive most often?",
			"When do you feel you're making a difference?",
			"What would you regret NOT doing with your life?",
			"If you could only accomplish one thing, what would it be?",
			"What values are non-negotiable for you?",
			"List 3 values that define who you are",
			"How do your daily activities reflect these values?",
			"Where is there a gap between values and actions?",
			"Write: 'My purpose is to...' (draft version)",
			"Read it aloud - how does it feel?",
			"Refine it - make it more true",
			"What's one small step toward this purpose?",
			"When will you take that step?",
			"Who could support you on this path?",
			"Commit: 'I am here to [purpose]'"
		]
	},

	# ===== SOCIAL DOMAIN =====
	{
		"id": "tpl_social_connection",
		"name": "Connection Check-In",
		"layer_id": "social",
		"operational_layer": "baseline",
		"description": "Nurture your relationships with intentional outreach and genuine connection.",
		"lines": [
			"List 5 people who matter most to you",
			"When did you last meaningfully connect with each?",
			"Circle anyone you haven't connected with recently",
			"Choose one person to reach out to today",
			"What do you genuinely appreciate about them?",
			"Draft a message - not just 'hey, how are you?'",
			"Mention something specific you remember about them",
			"Ask a question that shows you care",
			"Send the message now",
			"Think of someone who might be struggling",
			"What small gesture could brighten their day?",
			"Draft a supportive message for them",
			"Send it or schedule a call",
			"Who have you been meaning to thank?",
			"Write a genuine thank you message",
			"Send it now",
			"Is there a relationship that needs repair?",
			"What's one small step toward healing?",
			"Commit to that step with a timeline",
			"Review your calendar - when can you schedule quality time?",
			"Invite someone for coffee, a walk, or a call",
			"Send that invitation now",
			"Think of someone new you'd like to know better",
			"Plan one way to connect with them",
			"Today's social intention: [write it down]"
		]
	},
	{
		"id": "tpl_social_deep_convo",
		"name": "Deep Conversation Prep",
		"layer_id": "social",
		"operational_layer": "update",
		"description": "Prepare for meaningful dialogue that builds genuine understanding and connection.",
		"lines": [
			"Who will you have a deep conversation with?",
			"What do you already know about their current life?",
			"What don't you know that you're curious about?",
			"Write 3 open-ended questions to ask them",
			"Avoid yes/no questions - seek their stories",
			"What experience might you share vulnerably?",
			"Practice being okay with silence in conversation",
			"Remind yourself: listen to understand, not to respond",
			"Notice any assumptions you have about them",
			"Set those assumptions aside - be curious",
			"What's one thing you admire about this person?",
			"Plan to genuinely express that during the conversation",
			"What might they be struggling with?",
			"How can you create space for them to share?",
			"Remember: presence is a gift you can give",
			"Put your phone away/on silent during the conversation",
			"Body language: open posture, eye contact",
			"Practice phrases: 'Tell me more...' 'What was that like?'",
			"What do you hope to learn from this conversation?",
			"What could this conversation give them?",
			"Mutual benefit makes the best conversations",
			"Visualize the conversation going well",
			"Set intention: be fully present",
			"When will this conversation happen?",
			"Commit: calendar it now if you haven't"
		]
	},
	{
		"id": "tpl_social_boundary",
		"name": "Boundary Setting Workshop",
		"layer_id": "social",
		"operational_layer": "upgrade",
		"description": "Learn to set healthy boundaries that protect your energy while maintaining relationships.",
		"lines": [
			"Where in life do you feel drained or resentful?",
			"Which relationships take more than they give?",
			"What do you say 'yes' to when you mean 'no'?",
			"Why do you struggle to set boundaries there?",
			"What are you afraid might happen if you say no?",
			"What's the cost of NOT setting this boundary?",
			"Boundaries aren't selfish - they're self-respect",
			"Choose one boundary you need to set",
			"Write it clearly: 'I need [specific boundary]'",
			"Why is this boundary important for your wellbeing?",
			"How will you communicate it? Draft the words",
			"Keep it simple, kind, and firm",
			"You don't need to justify or over-explain",
			"Practice saying it out loud",
			"Notice any guilt - it's normal but not a stop sign",
			"What if they react badly? Plan your response",
			"You can hold the boundary AND care about them",
			"When will you communicate this boundary?",
			"What support do you need to follow through?",
			"How will you maintain the boundary consistently?",
			"What will you do instead of the thing you're stopping?",
			"Visualize successfully maintaining this boundary",
			"How will life improve with this boundary in place?",
			"Affirmation: 'My needs matter and deserve protection'",
			"Commit: 'I will set this boundary by [date]'"
		]
	},

	# ===== CAREER DOMAIN =====
	{
		"id": "tpl_career_daily_prep",
		"name": "Daily Work Preparation",
		"layer_id": "career",
		"operational_layer": "baseline",
		"description": "Set yourself up for a productive workday with clear priorities and focused intention.",
		"lines": [
			"Review your calendar - what's scheduled today?",
			"Any meetings to prepare for?",
			"List everything you could work on today",
			"Circle the 3 most important tasks (MITs)",
			"What task, if completed, would make today a win?",
			"That's your #1 priority - write it clearly",
			"What time of day is your energy highest?",
			"Schedule your #1 priority for peak energy time",
			"What might derail your focus today?",
			"Plan how to handle those interruptions",
			"Close unnecessary browser tabs and apps",
			"Set your status to minimize interruptions",
			"Review pending emails - any urgent responses needed?",
			"Handle truly urgent items in 2 minutes or less",
			"Everything else: schedule time or delegate",
			"What resources do you need for your MIT?",
			"Gather those resources now",
			"Break your MIT into first 3 concrete steps",
			"Set a 25-minute timer and begin step 1",
			"Work with full focus",
			"Continue working on the task",
			"Keep going - single-task only",
			"If interrupted, note it and return immediately",
			"Complete this focus block",
			"Quick check: MIT progress? Adjust plan if needed"
		]
	},
	{
		"id": "tpl_career_skill_build",
		"name": "Professional Skill Building",
		"layer_id": "career",
		"operational_layer": "update",
		"description": "Deliberately practice and develop skills that advance your career and expertise.",
		"lines": [
			"What skill would most advance your career?",
			"Break this skill into sub-skills",
			"Which sub-skill needs the most work?",
			"What does excellence look like in this sub-skill?",
			"Find a resource for learning (article, video, course)",
			"Study the material for 5 minutes",
			"Take notes on key concepts",
			"Continue studying, looking for actionable insights",
			"What can you practice right now?",
			"Set up a practice exercise",
			"Begin deliberate practice - focus on weakness",
			"Practice with full attention - quality over quantity",
			"Notice where you struggle - that's growth edge",
			"Adjust and try again",
			"Continue practicing - aim for small improvements",
			"What feedback can you get on your practice?",
			"If possible, get feedback now",
			"Incorporate feedback and try again",
			"What's one insight from this practice session?",
			"How will you practice this skill tomorrow?",
			"Schedule your next practice session",
			"Who could mentor you in this skill?",
			"What project could showcase this skill?",
			"Track progress: today's small win was...",
			"Commit: 'I am becoming skilled at [skill]'"
		]
	},
	{
		"id": "tpl_career_strategic",
		"name": "Strategic Career Planning",
		"layer_id": "career",
		"operational_layer": "upgrade",
		"description": "Think long-term about your career trajectory, opportunities, and professional growth.",
		"lines": [
			"Where do you want to be in 5 years professionally?",
			"Paint a vivid picture - role, responsibilities, impact",
			"What does your ideal work day look like?",
			"What skills would that version of you have?",
			"Which of those skills do you need to develop?",
			"What experiences would build those skills?",
			"What's the gap between current you and future you?",
			"What's holding you back right now?",
			"What opportunities exist in your current role?",
			"What opportunities are you not pursuing?",
			"Who is where you want to be? Study their path",
			"What can you learn from their journey?",
			"What relationships could accelerate your growth?",
			"Who should you connect with this month?",
			"What projects could showcase your abilities?",
			"Could you propose a new project or role?",
			"What's the next logical step in your career?",
			"What would make you undeniable for that step?",
			"What risks might you need to take?",
			"What's the cost of staying comfortable?",
			"Write your 1-year career goal",
			"What must happen in the next 90 days?",
			"What must happen in the next 30 days?",
			"What's the single most important action this week?",
			"Commit: 'I will [action] by [date]'"
		]
	},

	# ===== WEALTH DOMAIN =====
	{
		"id": "tpl_wealth_daily",
		"name": "Daily Financial Check-In",
		"layer_id": "wealth",
		"operational_layer": "baseline",
		"description": "Stay aware of your financial situation with quick daily monitoring habits.",
		"lines": [
			"Open your banking app or dashboard",
			"Check account balances - any surprises?",
			"Review yesterday's transactions",
			"Categorize any uncategorized spending",
			"Did any spending feel unnecessary?",
			"What's your current budget status this month?",
			"Are you on track or overspending?",
			"Check upcoming bills or subscriptions",
			"Any payments due in the next 7 days?",
			"Schedule or confirm those payments",
			"Check your credit card balance",
			"When is the payment due?",
			"Review any pending investments or savings",
			"Did market changes affect your portfolio?",
			"Note any actions needed (don't react emotionally)",
			"Any income expected soon?",
			"Track it in your system",
			"What's your financial intention for today?",
			"One money-saving choice you can make today?",
			"One money-earning opportunity to pursue?",
			"Update your budget if needed",
			"Check your financial goals progress",
			"Celebrate: one financial win this week?",
			"Set tomorrow's financial intention",
			"Close apps - money awareness complete"
		]
	},
	{
		"id": "tpl_wealth_budget",
		"name": "Monthly Budget Review",
		"layer_id": "wealth",
		"operational_layer": "update",
		"description": "Deep dive into your spending patterns and optimize your budget for your goals.",
		"lines": [
			"Pull up last month's complete spending data",
			"Categorize all transactions",
			"Calculate total income received",
			"Calculate total spending by category",
			"What % went to needs vs wants vs savings?",
			"Which category surprised you?",
			"Where did you overspend?",
			"What drove that overspending?",
			"Where could you have spent less?",
			"What purchases brought lasting value?",
			"What purchases were wasted?",
			"Are there subscriptions to cancel?",
			"Any regular expenses that could be reduced?",
			"Set next month's budget targets by category",
			"Be realistic but challenging",
			"What's your savings target for next month?",
			"What's your debt paydown target?",
			"Where will unexpected money go?",
			"Plan for known upcoming expenses",
			"Create a buffer for surprises",
			"How will you track spending daily?",
			"What's your biggest financial goal right now?",
			"How does this budget serve that goal?",
			"Commit to the budget",
			"Schedule next month's review"
		]
	},
	{
		"id": "tpl_wealth_invest",
		"name": "Investment Research Session",
		"layer_id": "wealth",
		"operational_layer": "upgrade",
		"description": "Research and evaluate investment opportunities to grow your wealth strategically.",
		"lines": [
			"What's your current investment allocation?",
			"Does it match your risk tolerance?",
			"What's your investment timeline?",
			"Review your portfolio performance",
			"Compare to relevant benchmarks",
			"Any rebalancing needed?",
			"What asset class do you want to learn about?",
			"Research: what drives returns in this class?",
			"What are the risks?",
			"What are the potential rewards?",
			"Find 3 reputable sources to study",
			"Read/watch educational content",
			"Take notes on key principles",
			"What did you learn?",
			"How might this fit your portfolio?",
			"Research specific investment options",
			"Compare fees, performance, and structure",
			"What's the minimum investment needed?",
			"What are the tax implications?",
			"Does this align with your values?",
			"What questions do you still have?",
			"Where can you find answers?",
			"Set a follow-up date to continue research",
			"Decision: invest now, wait, or pass?",
			"If investing: what amount? Document reasoning"
		]
	}
]


## Get all script templates
func get_templates() -> Array:
	return SCRIPT_TEMPLATES.duplicate()


## Get templates filtered by domain layer
func get_templates_by_domain(domain_id: String) -> Array:
	var filtered = []
	for template in SCRIPT_TEMPLATES:
		if template.layer_id == domain_id:
			filtered.append(template)
	return filtered


## Get templates filtered by operational layer
func get_templates_by_operational(operational_id: String) -> Array:
	var filtered = []
	for template in SCRIPT_TEMPLATES:
		if template.operational_layer == operational_id:
			filtered.append(template)
	return filtered


## Create a new script from a template
func create_script_from_template(template_id: String) -> String:
	var template = null
	for t in SCRIPT_TEMPLATES:
		if t.id == template_id:
			template = t
			break

	if template == null:
		push_error("[ScriptManager] Template not found: ", template_id)
		return ""

	var script_id = create_script({
		"name": template.name,
		"layer_id": template.layer_id,
		"operational_layer": template.operational_layer,
		"description": template.description,
		"lines": template.lines.duplicate()
	})

	print("[ScriptManager] Created script from template: ", template.name)
	return script_id
