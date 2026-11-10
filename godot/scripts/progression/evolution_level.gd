extends RefCounted
## One evolution level for the HUD and for save-slot rows.
## Saves store world_evolution_level as a 0-100 percent. The level is
## 1 + percent/10 (0% is level 1, 10% is level 2).


static func level_from_percent(percent: float) -> int:
	return int(percent / 10.0) + 1


static func level_from_player(player: Dictionary) -> int:
	if player.has("world_evolution_level"):
		return level_from_percent(float(player.get("world_evolution_level", 0.0)))
	return int(player.get("evolution_level", 1))
