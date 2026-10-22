extends RefCounted
## Early-testing badge copy + feedback page links (pure data, testable headless).

const FEEDBACK_URL := "https://goacto.com/pages/mindscape-feedback"
const BADGE_TEXT := "Early testing"
const NOTE := "Mindscape is in early testing. Things will break and change. Tell us what works and what doesn't. Honest feedback shapes what we build next."


## Feedback page tagged with the build version, e.g. ...?build=v0.1.0-prototype
## Optional type (e.g. "feature") is appended as &type=feature.
static func feedback_url(build_version: String, type: String = "") -> String:
	var url := FEEDBACK_URL + "?build=" + build_version.uri_encode()
	if type != "":
		url += "&type=" + type.uri_encode()
	return url
