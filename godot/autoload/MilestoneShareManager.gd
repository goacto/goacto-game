extends CanvasLayer
## MilestoneShareManager: offers a shareable card when a Mindscape milestone is hit (REQ v0.4 RM-B6).
##  - Milestones: achievement unlocks (AchievementManager) and chapter completions (CampaignManager).
##  - Waits while in Focus Mode; shows a small "Share / Not now" card when idle.
##  - Nothing is posted automatically. The OS share sheet (web) opens only after the player taps Share.
##  - Read-only over saves and journals (PRO-16). Book chapters are never gated by sharing.

const MS := preload("res://scripts/share/milestone_share.gd")
const CARD_SIZE := Vector2i(1080, 1080)

var _queue: Array = []
var _panel: PanelContainer


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.has_singleton("AchievementManager") or has_node("/root/AchievementManager"):
		get_node("/root/AchievementManager").achievement_unlocked.connect(_on_achievement)
	if has_node("/root/CampaignManager"):
		var cm = get_node("/root/CampaignManager")
		if cm.has_signal("chapter_completed"):
			cm.chapter_completed.connect(_on_chapter)
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").state_changed.connect(func(_n, _o): _try_show())


func _on_achievement(ach: Dictionary) -> void:
	_queue.append(MS.card_for_achievement(ach))
	_try_show()


func _on_chapter(chapter_id: String) -> void:
	var cm = get_node("/root/CampaignManager")
	var ch: Dictionary = cm.CHAPTERS.get(chapter_id, {"id": chapter_id, "name": chapter_id})
	_queue.append(MS.card_for_chapter(ch))
	_try_show()


func _in_focus_mode() -> bool:
	var gm = get_node_or_null("/root/GameManager")
	return gm != null and gm.current_state == gm.GameState.FOCUS_MODE


func _try_show() -> void:
	if _panel != null or _queue.is_empty() or not MS.should_offer_now(_in_focus_mode()):
		return
	_show_offer(_queue.pop_front())


func _show_offer(card: Dictionary) -> void:
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = MS.BG_COLOR
	sb.border_color = MS.ACCENT_COLOR
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.position = Vector2(-220, -170)
	_panel.custom_minimum_size = Vector2(440, 0)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	var head := Label.new()
	head.text = "%s  %s" % [card.mark, card.title]
	head.add_theme_color_override("font_color", MS.ACCENT_COLOR)
	head.add_theme_font_size_override("font_size", 22)
	box.add_child(head)
	var sub := Label.new()
	sub.text = card.subtitle
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(sub)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(row)
	var later := Button.new()
	later.text = "Not now"
	later.pressed.connect(_close)
	row.add_child(later)
	var share := Button.new()
	share.text = "Share card"
	share.pressed.connect(func(): _share(card))
	row.add_child(share)
	add_child(_panel)


func _close() -> void:
	if _panel:
		_panel.queue_free()
		_panel = null
	_try_show.call_deferred()


## Renders the card offscreen and hands the PNG to the OS share sheet (web) or saves it (desktop).
func _share(card: Dictionary) -> void:
	var img := await render_card_image(card)
	var png := img.save_png_to_buffer()
	var fname := MS.share_filename(card)
	if OS.has_feature("web"):
		JavaScriptBridge.eval(MS.share_js(Marshalls.raw_to_base64(png), fname, "%s · GOACTO Mindscape" % card.title))
	else:
		DirAccess.make_dir_recursive_absolute("user://milestone_cards")
		var path := "user://milestone_cards/%s" % fname
		img.save_png(path)
		OS.shell_open(ProjectSettings.globalize_path("user://milestone_cards"))
	_close()


func render_card_image(card: Dictionary) -> Image:
	var vp := SubViewport.new()
	vp.size = CARD_SIZE
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var bg := ColorRect.new()
	bg.color = MS.BG_COLOR
	bg.size = Vector2(CARD_SIZE)
	vp.add_child(bg)
	var col := VBoxContainer.new()
	col.size = Vector2(CARD_SIZE) - Vector2(160, 160)
	col.position = Vector2(80, 80)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	vp.add_child(col)
	for spec in [[card.mark, 160, Color.WHITE], [card.title, 72, MS.ACCENT_COLOR], [card.subtitle, 40, Color("#d1d5db")], [card.get("journal", ""), 32, Color("#9ca3af")], [card.footer, 30, MS.ACCENT_COLOR]]:
		if str(spec[0]) == "":
			continue
		var l := Label.new()
		l.text = str(spec[0])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(CARD_SIZE.x - 160, 0)
		l.add_theme_font_size_override("font_size", spec[1])
		l.add_theme_color_override("font_color", spec[2])
		col.add_child(l)
	add_child(vp)
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img
