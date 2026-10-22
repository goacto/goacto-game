extends RefCounted
## AspectLabel: turns an Aspect id or a habit domain into one of the six Aspect names.
## The session-complete screen used to print the raw domain ("Productivity"), which is not an Aspect.
## Domains map through GameManager.ASPECTS[*].domain:
##   productivity -> Discipline, growth -> Courage, learning -> Creativity,
##   social -> Compassion, mindfulness -> Wisdom, health -> Vitality.

const DEFAULT_ASPECT := "Discipline"


static func display_name(key_or_domain: String, aspects: Dictionary) -> String:
	var k := key_or_domain.strip_edges().to_lower()
	if aspects.has(k):
		return str(aspects[k].get("name", k.capitalize()))
	for aspect_key in aspects:
		if str(aspects[aspect_key].get("domain", "")).to_lower() == k:
			return str(aspects[aspect_key].get("name", str(aspect_key).capitalize()))
	return DEFAULT_ASPECT
