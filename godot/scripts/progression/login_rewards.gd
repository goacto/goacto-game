extends RefCounted
## Daily login reward claim ids.
## The reward table repeats every 30 days, but the first cycle stored plain day
## numbers (1-30). Later cycles need their own id or day 31 can never be claimed.
## Cycle 0 keeps the integer id so an existing save is not paid twice.


static func claim_token(total_login_days: int, cycle_day: int):
	var total := maxi(int(total_login_days), 1)
	var cycle := int((total - 1) / 30)
	if cycle <= 0:
		return int(cycle_day)
	return "%d:%d" % [cycle, int(cycle_day)]
