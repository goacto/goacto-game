extends RefCounted
## Aspect XP routing.
## Callers pass either an Aspect id ("wisdom") or a habit domain ("mindfulness").
## Those are different strings. Matching only the domain drops the XP.


static func targets(aspect_key: String, aspect_domain: String, token: String) -> bool:
	if token == "all":
		return true
	return token == aspect_key or token == aspect_domain


## Add XP and walk every level the grant crosses.
## Level N costs N * 100. need <= 0 stops the loop (a 0 level cannot spin).
static func apply(level: int, experience: float, amount: int) -> Dictionary:
	var lvl := level
	var xp := experience + float(amount)
	var guard := 0
	while guard < 100:
		var need := lvl * 100
		if need <= 0 or xp < float(need):
			break
		xp -= float(need)
		lvl += 1
		guard += 1
	return {"level": lvl, "experience": xp}
