extends RefCounted
## Always-on chrome for the first minute on a phone.
## One small "Prototype" tag. The build stamp (version + timestamp) is Settings-only,
## so it cannot cover "Report Bugs and Share Feedback".

const PROTOTYPE_TEXT := "Prototype"
const FEEDBACK_TEXT := "Report Bugs and Share Feedback <3"
## Matches GameManager's feedback button: left 10, 270 wide, sitting on the bottom 30 px.
const FEEDBACK_LEFT := 10.0
const FEEDBACK_WIDTH := 270.0
const FEEDBACK_HEIGHT := 22.0
const FEEDBACK_BOTTOM_INSET := 30.0

const TAG_WIDTH := 88.0
const TAG_HEIGHT := 22.0
const TAG_MARGIN := 10.0


static func feedback_rect(viewport: Vector2) -> Rect2:
	return Rect2(FEEDBACK_LEFT, viewport.y - FEEDBACK_BOTTOM_INSET, FEEDBACK_WIDTH, FEEDBACK_HEIGHT)


static func prototype_rect(viewport: Vector2) -> Rect2:
	var x := viewport.x - TAG_WIDTH - TAG_MARGIN
	if x < TAG_MARGIN:
		x = TAG_MARGIN
	var w := minf(TAG_WIDTH, maxf(48.0, viewport.x - x - TAG_MARGIN))
	var rect := Rect2(x, maxf(TAG_MARGIN, viewport.y - TAG_HEIGHT - TAG_MARGIN), w, TAG_HEIGHT)
	var fb := feedback_rect(viewport)
	if rect.intersects(fb):
		rect.position.y = fb.position.y - TAG_HEIGHT - 6.0
		if rect.position.y < TAG_MARGIN or rect.intersects(fb):
			rect.position = Vector2(x, TAG_MARGIN)
	return rect


static func tag_clears_feedback(viewport: Vector2) -> bool:
	return not prototype_rect(viewport).intersects(feedback_rect(viewport)) \
		and prototype_rect(viewport).end.x <= viewport.x + 0.5 \
		and prototype_rect(viewport).position.x >= -0.5


## Full stamp shown in Settings. `relative` is "" when the timestamp does not parse.
static func build_stamp_line(version: String, timestamp: String, relative: String) -> String:
	if timestamp == "LOCAL" or timestamp == "":
		return "%s | Local Dev" % version
	if relative != "":
		return "%s | %s (%s)" % [version, timestamp, relative]
	return "%s | %s" % [version, timestamp]
