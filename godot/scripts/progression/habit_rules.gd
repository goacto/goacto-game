extends RefCounted
## todays_completions holds every habit, false until it is done.
## "habit_id in todays_completions" is true for an incomplete habit.


static func completed_today(todays_completions: Dictionary, habit_id: String) -> bool:
	return bool(todays_completions.get(habit_id, false))
