extends RefCounted
## FitViewport: keeps fixed-size panels and dialogs on screen on narrow (phone) canvases.
## Desktop is unchanged: a panel keeps its designed size whenever it fits.

const NARROW_WIDTH := 900.0
const EDGE := 10.0


static func visible_size(node: Node) -> Vector2:
	var vp := node.get_viewport()
	return vp.get_visible_rect().size if vp else Vector2(1366, 768)


static func is_narrow(node: Node) -> bool:
	return visible_size(node).x < NARROW_WIDTH


## Size a center-anchored Control to `desired`, shrunk to the visible canvas minus an edge margin.
static func fitted_size(desired: Vector2, avail: Vector2, edge: float = EDGE) -> Vector2:
	return Vector2(minf(desired.x, maxf(avail.x - edge * 2.0, 0.0)), minf(desired.y, maxf(avail.y - edge * 2.0, 0.0)))


static func center(ctrl: Control, desired: Vector2, edge: float = EDGE) -> void:
	var s := fitted_size(desired, visible_size(ctrl), edge)
	ctrl.set_anchors_preset(Control.PRESET_CENTER)
	ctrl.offset_left = -s.x / 2.0
	ctrl.offset_right = s.x / 2.0
	ctrl.offset_top = -s.y / 2.0
	ctrl.offset_bottom = s.y / 2.0


## center() now and again whenever the window is resized, for as long as ctrl lives.
static func keep_centered(ctrl: Control, desired: Vector2, edge: float = EDGE) -> void:
	center(ctrl, desired, edge)
	var vp := ctrl.get_viewport()
	if vp == null:
		ctrl.ready.connect(func(): keep_centered(ctrl, desired, edge), CONNECT_ONE_SHOT)
		return
	var cb := func():
		if is_instance_valid(ctrl):
			center(ctrl, desired, edge)
	vp.size_changed.connect(cb)
	ctrl.tree_exiting.connect(func():
		if vp.size_changed.is_connected(cb):
			vp.size_changed.disconnect(cb), CONNECT_ONE_SHOT)
