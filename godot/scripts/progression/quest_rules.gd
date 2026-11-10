extends RefCounted
## Aspect-quest completion rules.
## Some requirement keys are constraints, not counters.
## Some progress was stored under a different key than the requirement.


const PROGRESS_ALIASES := {
	"values_check_complete": "values_check_completed",
	"single_session_minutes": "long_session_completed",
	"weekly_synthesis": "weekly_synthesis_completed",
	"unique_categories": "categories",
	"relationships_contacted": "relationships",
}


static func is_constraint(req_key: String) -> bool:
	# Deadlines are not counters. min_duration is enforced when a session is counted.
	return req_key.begins_with("time_limit") or req_key == "min_duration"


static func focus_session_counts(requirements: Dictionary, duration_minutes: int) -> bool:
	return duration_minutes >= int(requirements.get("min_duration", 0))


static func requirement_met(req_key: String, req_value, progress: Dictionary) -> bool:
	if is_constraint(req_key):
		return true
	var prog_value = _progress_value(req_key, progress)
	if typeof(req_value) == TYPE_BOOL:
		return prog_value == req_value
	if typeof(req_value) == TYPE_INT or typeof(req_value) == TYPE_FLOAT:
		# Older saves stored a completion flag instead of the counter.
		if typeof(prog_value) == TYPE_BOOL:
			return prog_value
		if typeof(prog_value) == TYPE_ARRAY:
			return prog_value.size() >= int(req_value)
		return float(prog_value) >= float(req_value)
	return true


static func _progress_value(req_key: String, progress: Dictionary):
	if progress.has(req_key):
		return progress[req_key]
	if PROGRESS_ALIASES.has(req_key) and progress.has(PROGRESS_ALIASES[req_key]):
		return progress[PROGRESS_ALIASES[req_key]]
	var completed_key := req_key + "_completed"
	if progress.has(completed_key):
		return progress[completed_key]
	return false
