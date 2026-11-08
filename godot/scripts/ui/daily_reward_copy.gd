extends RefCounted
## Honest copy for the daily login reward.
## Day 1 of a brand-new save is an arrival, not a return.


const FIRST_VISIT := "Welcome, Traveler."


## First visit (no prior login day) never uses "Welcome back".
## Later days keep the reward table's own line.
static func for_login(reward: Dictionary, total_login_days: int) -> String:
	if int(total_login_days) <= 1:
		return FIRST_VISIT
	return str(reward.get("description", ""))
