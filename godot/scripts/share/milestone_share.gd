extends RefCounted
## MilestoneShare: pure helpers for shareable Mindscape milestone cards (REQ v0.4 RM-B6).
##
## Read-only: it builds card data from an achievement or chapter dictionary.
## It never touches save slots, journals or player_data (PRO-16).
## Journal text is only included when the player opts in for that card.

const FOOTER := "GOACTO · Mindscape"
const JOURNAL_MAX := 140
const BG_COLOR := Color("#1a1a1a")
const ACCENT_COLOR := Color("#FFD700")


static func card_for_achievement(ach: Dictionary) -> Dictionary:
	return {
		"kind": "achievement",
		"id": str(ach.get("id", "milestone")),
		"mark": str(ach.get("icon", "✦")),
		"title": str(ach.get("name", "Milestone")),
		"subtitle": str(ach.get("description", "")),
		"footer": FOOTER,
	}


static func card_for_chapter(chapter: Dictionary) -> Dictionary:
	return {
		"kind": "chapter",
		"id": str(chapter.get("id", "chapter")),
		"mark": "📖",
		"title": "Chapter complete",
		"subtitle": str(chapter.get("name", "")),
		"footer": FOOTER,
	}


## Returns a copy. Adds a journal line only if opted_in is true; capped and single-line.
static func with_journal(card: Dictionary, excerpt: String, opted_in: bool) -> Dictionary:
	var out := card.duplicate(true)
	out.erase("journal")
	if opted_in:
		var line := excerpt.strip_edges().replace("\n", " ")
		if line.length() > JOURNAL_MAX:
			line = line.substr(0, JOURNAL_MAX - 1) + "…"
		if line != "":
			out["journal"] = line
	return out


## Cards are offered only when idle (never during Focus Mode).
static func should_offer_now(in_focus_mode: bool) -> bool:
	return not in_focus_mode


static func share_filename(card: Dictionary) -> String:
	var slug := ""
	for c in str(card.get("id", "milestone")).to_lower():
		slug += c if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") else "-"
	return "goacto-mindscape-%s.png" % slug.strip_edges()


## JS for the web export. It opens the OS share sheet with the PNG, or downloads
## it if the share sheet isn't available. Only runs after the player taps Share.
static func share_js(png_base64: String, filename: String, title: String) -> String:
	var b64 := JSON.stringify(png_base64)
	var fn := JSON.stringify(filename)
	var t := JSON.stringify(title)
	return """(function(){try{var b=atob(%s);var a=new Uint8Array(b.length);for(var i=0;i<b.length;i++)a[i]=b.charCodeAt(i);
var f=new File([a],%s,{type:'image/png'});
if(navigator.canShare&&navigator.canShare({files:[f]})){navigator.share({files:[f],title:%s}).catch(function(){});return 'shared';}
var u=URL.createObjectURL(f);var l=document.createElement('a');l.href=u;l.download=%s;document.body.appendChild(l);l.click();l.remove();
setTimeout(function(){URL.revokeObjectURL(u);},5000);return 'downloaded';}catch(e){return 'error';}})()""" % [b64, fn, t, fn]
