extends RefCounted
## Grow and give framing shared by Weekly Synthesis and the Kindness Log (pure, testable headless).
## Data stays on the device (user://).

const KINDNESS_PATH := "user://kindness_log.json"
const GROW_LABEL := "🌱 Grow: what did you practice or learn this week?"
const GIVE_LABEL := "🤝 Give: who did you help or show up for?"
const OPEN_LABEL := "Anything else?"
const KINDNESS_INTRO := "🤝 Give. Small things you did for someone else. They show up in your Weekly Synthesis under Give."


## Count kindness entries dated within 7 days of now_unix.
static func give_count_this_week(entries: Array, now_unix: int) -> int:
	var week_ago := now_unix - 7 * 24 * 60 * 60
	var n := 0
	for e in entries:
		var d: String = str(e.get("date", "")) if e is Dictionary else ""
		if d.length() < 10:
			continue
		var p := d.substr(0, 10).split("-")
		if p.size() < 3:
			continue
		var u := Time.get_unix_time_from_datetime_dict({"year": int(p[0]), "month": int(p[1]), "day": int(p[2]), "hour": 0, "minute": 0, "second": 0})
		if u >= week_ago and u <= now_unix:
			n += 1
	return n


static func give_line(count: int) -> String:
	if count == 0:
		return "Kindness Log this week: nothing logged yet. That's fine."
	return "Kindness Log this week: %d %s." % [count, "act" if count == 1 else "acts"]


static func load_kindness() -> Array:
	if not FileAccess.file_exists(KINDNESS_PATH):
		return []
	var data = JSON.parse_string(FileAccess.get_file_as_string(KINDNESS_PATH))
	return data if data is Array else []
