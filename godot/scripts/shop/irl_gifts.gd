extends RefCounted
## IRL Gifts catalog for the Mindscape shop (pure data, testable headless).
##
## GIFT_CODES_ENABLED is the single switch for in-game discount codes.
## The codes are hidden because they don't exist in Shopify yet. To bring them
## back: create the codes in Shopify with real amounts, fill CODES below, and
## set GIFT_CODES_ENABLED = true. While it is false the game shows no code,
## no "Unlock Code" button and no code/redeem copy; the shop links stay.

const GIFT_CODES_ENABLED := false

const PICKS_URL := "https://goacto.com/collections/goacto-picks"

## Discount code per gift id. Only used when GIFT_CODES_ENABLED is true.
const CODES := {
	"sticker_pack": "FOCUS10",
	"growth_journal": "FOCUS25",
}

const GIFTS := [
	{
		"id": "sticker_pack",
		"name": "GOACTO Sticker Pack",
		"desc": "A set of motivational GOACTO stickers delivered to your door.",
		"coins": 10,
		"url": "https://goacto.com/products/goacto-guild-sticker-pack",
		"color": Color(0.4, 0.8, 0.6),
	},
	{
		"id": "growth_journal",
		"name": "Growth Journal",
		"desc": "Physical GOACTO growth journal with guided prompts and reflection pages.",
		"coins": 25,
		"url": "https://goacto.com/products/goacto-daily-focus-hardcover-journal",
		"color": Color(0.5, 0.7, 0.9),
	},
]


static func codes_enabled() -> bool:
	return GIFT_CODES_ENABLED


## Gifts to show. Each entry gets "discount" only when codes are enabled.
static func gifts(enabled: bool = GIFT_CODES_ENABLED) -> Array:
	var out: Array = []
	for g in GIFTS:
		var item: Dictionary = g.duplicate(true)
		if enabled and CODES.has(item.id):
			item["discount"] = CODES[item.id]
		out.append(item)
	return out


static func intro_text(enabled: bool = GIFT_CODES_ENABLED) -> String:
	if enabled:
		return "Redeem focus coins for real-world rewards! Complete focus sessions to earn coins, then unlock discount codes for the GOACTO shop."
	return "Real-world GOACTO gear to keep you focused. Browse it in the GOACTO shop."


static func footer_text(enabled: bool = GIFT_CODES_ENABLED) -> String:
	if enabled:
		return "More rewards coming soon! Every focus session earns you 1 coin."
	return "Every focus session earns you 1 Focus Coin."


static func code_dialog_text(gift_name: String, code: String) -> String:
	return "Your discount code for %s:\n\n%s\n\nUse this code at goacto.com for a special discount.\n\nThe code has been copied - visit the shop to redeem!" % [gift_name, code]
