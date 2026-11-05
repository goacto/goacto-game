extends RefCounted
## Phone framing for the intro cutscene.
## A 390 CSS-px phone becomes a ~600 px virtual canvas (see HudOverlay). Without that
## rescale, stretch aspect "expand" keeps a ~1366 px width and grows the height
## (about 1366×2956). Either canvas is portrait. The authored cutscene is 1366×768,
## so the ship sits near the top of that tall canvas and the title card (anchored to
## the viewport center) hangs in the middle, under the HTML "Turn your phone sideways"
## pill. Portrait letterboxes a 16:9 stage on the vertical center so the ship and the
## title share that stage, below the pill.
## Desktop (at least 1100×700 and landscape, including a 1280 px screenshot) keeps
## the scene file.

const DESKTOP_MIN_W := 1100.0
const DESKTOP_MIN_H := 700.0
const EDGE := 16.0


static func needs_reflow(viewport: Vector2) -> bool:
	# Portrait includes the expanded ~1366-wide phone canvas, which is taller than
	# DESKTOP_MIN_H and so used to skip this frame entirely.
	if viewport.y > viewport.x:
		return true
	return viewport.x < DESKTOP_MIN_W or viewport.y < DESKTOP_MIN_H


static func skip_rect(viewport: Vector2) -> Rect2:
	var w := minf(110.0, maxf(64.0, (viewport.x - 36.0) * 0.34))
	var x := maxf(EDGE, viewport.x - 12.0 - w)
	w = minf(w, maxf(48.0, viewport.x - x - 8.0))
	return Rect2(x, 12.0, w, 44.0)


static func back_rect(viewport: Vector2) -> Rect2:
	var skip := skip_rect(viewport)
	var room := maxf(48.0, skip.position.x - EDGE - 8.0)
	var w := minf(110.0, room)
	return Rect2(EDGE, 12.0, w, 44.0)


static func location_rect(viewport: Vector2) -> Rect2:
	var skip := skip_rect(viewport)
	var y := skip.end.y + 8.0
	return Rect2(EDGE, y, maxf(40.0, viewport.x - EDGE * 2.0), 48.0)


static func dialogue_rect(viewport: Vector2) -> Rect2:
	var loc := location_rect(viewport)
	var top_limit := loc.end.y + 8.0
	var h := minf(200.0, maxf(96.0, viewport.y * 0.28))
	var y := viewport.y - EDGE - h
	if y < top_limit:
		y = top_limit
		h = maxf(64.0, viewport.y - EDGE - y)
	return Rect2(EDGE, y, maxf(40.0, viewport.x - EDGE * 2.0), h)


## 16:9 letterbox. Vertically centered on the canvas, then clamped into the band
## between the location line and the dialogue panel so a short landscape phone
## still clears that chrome.
static func stage_rect(viewport: Vector2) -> Rect2:
	var loc := location_rect(viewport)
	var dlg := dialogue_rect(viewport)
	var top := loc.end.y + 8.0
	var bottom := dlg.position.y - 8.0
	var avail_h := maxf(48.0, bottom - top)
	var avail_w := maxf(40.0, viewport.x - EDGE * 2.0)
	var aspect := 16.0 / 9.0
	var w := avail_w
	var h := w / aspect
	if h > avail_h:
		h = avail_h
		w = h * aspect
	var y := (viewport.y - h) * 0.5
	var y_max := top + avail_h - h
	y = clampf(y, top, maxf(top, y_max))
	var x := EDGE + (avail_w - w) * 0.5
	return Rect2(x, y, w, h)


static func intro_title_font(stage_width: float) -> int:
	var size := int(maxf(32.0, stage_width) / (9.0 * 0.62))
	return clampi(size, 22, 72)


## Title card ("MINDSCAPE" + subtitle) centered in the letterbox, below Skip.
static func intro_block(viewport: Vector2) -> Dictionary:
	var stage := stage_rect(viewport)
	var font := intro_title_font(maxf(32.0, stage.size.x - 16.0))
	var text_w := minf(maxf(32.0, stage.size.x - 16.0), float(font) * 0.70 * 9.0)
	var title_h := float(font) * 1.15
	var sub_h := 28.0
	var gap := 6.0
	var block_h := title_h + gap + sub_h
	if block_h > stage.size.y and stage.size.y > 36.0:
		font = maxi(18, int(float(font) * stage.size.y / block_h))
		title_h = float(font) * 1.15
		sub_h = minf(sub_h, maxf(16.0, stage.size.y - title_h - gap))
		block_h = title_h + gap + sub_h
		text_w = minf(text_w, maxf(32.0, stage.size.x - 16.0))
	var x := stage.position.x + maxf(0.0, (stage.size.x - text_w) * 0.5)
	var y := stage.position.y + maxf(0.0, (stage.size.y - block_h) * 0.5)
	var skip_bottom := skip_rect(viewport).end.y + 4.0
	if y < skip_bottom:
		y = skip_bottom
	return {
		"font": font,
		"title": Rect2(x, y, text_w, title_h),
		"subtitle": Rect2(x, y + title_h + gap, text_w, sub_h),
	}


static func ship_scale(viewport: Vector2) -> float:
	# Hull is ~240 units wide. Authored scale 2.5 is ~600 px, wider than a phone stage.
	var fit := stage_rect(viewport).size.x * 0.62 / 240.0
	return clampf(fit, 0.6, 2.5)


## Authored character offsets reach ±350 from center. Scale them onto the safe width.
static func character_offset_scale(viewport: Vector2) -> float:
	var half := viewport.x * 0.5 - EDGE
	return clampf(half / 350.0, 0.45, 1.0)


static func inside(viewport: Vector2, rect: Rect2) -> bool:
	return rect.position.x >= -0.5 \
		and rect.position.y >= -0.5 \
		and rect.end.x <= viewport.x + 0.5 \
		and rect.end.y <= viewport.y + 0.5 \
		and rect.size.x > 1.0 \
		and rect.size.y > 1.0


static func title_clears_skip(viewport: Vector2) -> bool:
	var skip := skip_rect(viewport)
	var block := intro_block(viewport)
	return not (block.title as Rect2).intersects(skip) \
		and not (block.subtitle as Rect2).intersects(skip) \
		and not location_rect(viewport).intersects(skip) \
		and not back_rect(viewport).intersects(skip)
