## NEONLINE — UIKit: imperative builders for reusable mobile components.
## Used by .tscn scenes as well as pure-code screens. All metrics come from NLPalette.
class_name NLUI
extends RefCounted

const P := preload("res://scripts/runtime/palette.gd")


static func c(key: String) -> Color:
	return ThemeManager.color(key)


static func style_box(
	bg: Color, radius: float = P.RADIUS_M, border: float = 0.0,
	border_color: Color = Color.TRANSPARENT, shadow: int = 0
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(int(radius))
	sb.content_margin_left = P.SPACE_L
	sb.content_margin_right = P.SPACE_L
	sb.content_margin_top = P.SPACE_M
	sb.content_margin_bottom = P.SPACE_M
	if border > 0.0:
		sb.set_border_width_all(int(border))
		sb.border_color = border_color
	if shadow > 0:
		sb.shadow_color = Color(0, 0, 0, 0.28 if ThemeManager.is_dark() else 0.12)
		sb.shadow_size = shadow * 3
		sb.shadow_offset = Vector2(0, shadow)
	return sb


static func label(text: String, role: String = "body", color_key: String = "text_primary") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", int(P.FONT_SCALE.get(role, 15.0)))
	l.add_theme_color_override("font_color", c(color_key))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func spacer() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return s


static func vgap(h: float = P.SPACE_M) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s


static func hgap(w: float = P.SPACE_S) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(w, 0)
	return s


## Filled button — primary action. height_key: "sm" | "md" | "lg"
static func button_filled(text: String, cb: Callable = Callable(), height_key: String = "md") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, _h(height_key))
	_apply_button(b, c("accent"), c("on_accent"), c("accent_pressed"))
	if cb.is_valid():
		b.pressed.connect(cb)
	return b


static func button_tonal(text: String, cb: Callable = Callable(), height_key: String = "md") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, _h(height_key))
	_apply_button(b, c("secondary_dim"), c("secondary"), c("secondary"))
	if cb.is_valid():
		b.pressed.connect(cb)
	return b


static func button_outlined(text: String, cb: Callable = Callable(), height_key: String = "md") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, _h(height_key))
	_apply_button(b, Color.TRANSPARENT, c("accent"), c("accent_dim"), true)
	if cb.is_valid():
		b.pressed.connect(cb)
	return b


static func button_text(text: String, cb: Callable = Callable()) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, P.TOUCH_MIN)
	b.add_theme_color_override("font_color", c("accent"))
	b.add_theme_color_override("font_hover_color", c("accent_pressed"))
	b.add_theme_color_override("font_pressed_color", c("accent_pressed"))
	b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	if cb.is_valid():
		b.pressed.connect(cb)
	return b


static func icon_button(icon_name: String, cb: Callable = Callable()) -> Button:
	var b := Button.new()
	b.text = icon_name
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(P.TOUCH_MIN, P.TOUCH_MIN)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", c("text_secondary"))
	b.add_theme_color_override("font_hover_color", c("accent"))
	b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	if cb.is_valid():
		b.pressed.connect(cb)
	return b


static func _h(k: String) -> float:
	match k:
		"sm": return P.BUTTON_H_SM
		"lg": return P.BUTTON_H_LG
		_: return P.BUTTON_H_MD


static func _apply_button(b: Button, bg: Color, fg: Color, hover: Color, outlined := false) -> void:
	var normal := style_box(bg, P.RADIUS_PILL, 1.0 if outlined else 0.0, c("accent"))
	normal.content_margin_left = P.SPACE_XL
	normal.content_margin_right = P.SPACE_XL
	normal.content_margin_top = P.SPACE_S
	normal.content_margin_bottom = P.SPACE_S
	var pressed := normal.duplicate()
	pressed.bg_color = hover if not outlined else c("accent_dim")
	var hover_sb := normal.duplicate()
	hover_sb.bg_color = hover
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover_sb)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("disabled", style_box(c("surface_alt"), P.RADIUS_PILL))
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_disabled_color", c("text_disabled"))
	b.add_theme_font_size_override("font_size", int(P.FONT_SCALE["label"]))


static func card(title: String = "", body_vbox: VBoxContainer = null) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style_box(c("surface"), P.RADIUS_M, 1.0, c("surface_hairline"), 2))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(P.SPACE_M))
	p.add_child(v)
	if title != "":
		v.add_child(label(title, "headline"))
	if body_vbox != null:
		v.add_child(body_vbox)
	return p


static func section_header(text: String) -> Control:
	return label(text.to_upper(), "overline", "text_secondary")


## Stat bar with animated fill. Returns a control you can re-read via child names.
static func stat_bar(name: String, value: float, max_value: float = 100.0, color_key: String = "accent") -> Control:
	var row := VBoxContainer.new()
	row.name = "Stat_%s" % name.replace(" ", "_")
	row.add_theme_constant_override("separation", int(P.SPACE_XS))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", int(P.SPACE_S))
	top.add_child(label(name, "caption", "text_secondary"))
	top.add_child(spacer())
	var val := label("%d" % int(value), "caption", "text_primary")
	val.name = "ValueLabel"
	top.add_child(val)
	row.add_child(top)
	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.min_value = 0
	bar.max_value = max_value
	bar.value = clampf(value, 0, max_value)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	bar.step = 0.01
	bar.add_theme_stylebox_override("background", style_box(c("surface_alt"), P.RADIUS_PILL, 0.0, Color.TRANSPARENT))
	var fill := style_box(c(color_key), P.RADIUS_PILL)
	fill.content_margin_left = 0
	fill.content_margin_right = 0
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	return row


static func set_stat_bar(bar_row: Control, value: float, animate := true) -> void:
	var pb: ProgressBar = bar_row.get_node("Bar")
	var vl: Label = bar_row.get_node_or_null("HBoxContainer/ValueLabel")
	if vl == null:
		for ch in bar_row.get_children():
			if ch is HBoxContainer:
				vl = ch.get_node_or_null("ValueLabel")
	if vl != null:
		vl.text = "%d" % int(clampf(value, 0, pb.max_value))
	if animate:
		var t := pb.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_property(pb, "value", clampf(value, 0, pb.max_value), P.MOTION_SLOW)
	else:
		pb.value = clampf(value, 0, pb.max_value)


static func chip(text: String, color_key: String = "accent", selected := false) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", style_box(c("accent_dim") if selected else c("surface_alt"), P.RADIUS_PILL))
	var l := label(text, "caption", color_key if selected else "text_secondary")
	pc.add_child(l)
	return pc


static func avatar(size: float = 56.0, initial: String = "?", ring: String = "accent") -> Control:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(size, size)
	var sb := style_box(c("surface_alt"), P.RADIUS_L)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	pc.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = initial
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", int(size * 0.42))
	l.add_theme_color_override("font_color", c(ring))
	pc.add_child(l)
	return pc


## Bottom sheet modal — standard mobile pattern for confirmations & detail views.
static func bottom_sheet(host: Node, content: Control, on_close: Callable = Callable()) -> Control:
	var overlay := Control.new()
	overlay.name = "SheetOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = c("scrim")
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input.bind(overlay, on_close))
	overlay.add_child(dim)

	var sheet := PanelContainer.new()
	sheet.name = "Sheet"
	sheet.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	sheet.offset_top = -sheet.get_combined_minimum_size().y
	sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	sheet.add_theme_stylebox_override("panel", style_box(c("bg_elevated"), P.RADIUS_L, 1.0, c("surface_hairline"), 6))
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", int(P.SPACE_M))
	var handle := Panel.new()
	handle.custom_minimum_size = Vector2(40, 4)
	var hs := StyleBoxFlat.new()
	hs.bg_color = c("surface_hairline")
	hs.set_corner_radius_all(2)
	handle.add_theme_stylebox_override("panel", hs)
	handle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wrap.add_child(handle)
	wrap.add_child(content)
	sheet.add_child(wrap)
	overlay.add_child(sheet)
	host.add_child(overlay)
	overlay.move_to_front()

	sheet.modulate.a = 0.0
	var t := overlay.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(sheet, "modulate:a", 1.0, P.MOTION_BASE)
	return overlay


static func _on_dim_input(ev: InputEvent, overlay: Node, on_close: Callable) -> void:
	if ev is InputEventScreenTouch and ev.pressed:
		dismiss_sheet(overlay, on_close)
	elif ev is InputEventMouseButton and ev.pressed:
		dismiss_sheet(overlay, on_close)


static func dismiss_sheet(overlay: Node, on_close: Callable = Callable()) -> void:
	if not is_instance_valid(overlay):
		return
	var t := overlay.create_tween()
	t.tween_property(overlay, "modulate:a", 0.0, P.MOTION_FAST)
	t.tween_callback(func():
		if on_close.is_valid():
			on_close.call()
		overlay.queue_free())


## Toast / snackbar anchored near the top, above content.
static func toast(host: Node, message: String, kind: String = "info") -> void:
	var color_key := {"info": "accent", "success": "success", "warn": "warning", "error": "error"}.get(kind, "accent")
	for old in host.get_children():
		if old.name == "Toast":
			old.queue_free()
	var pc := PanelContainer.new()
	pc.name = "Toast"
	pc.add_theme_stylebox_override("panel", style_box(c("bg_elevated"), P.RADIUS_S, 1.0, c(color_key)))
	var l := label(message, "label", "text_primary")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pc.add_child(l)
	pc.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	pc.offset_left = P.SPACE_L
	pc.offset_right = -P.SPACE_L
	pc.offset_top = P.TOP_BAR_H + P.SPACE_L
	host.add_child(pc)
	pc.modulate.a = 0.0
	pc.move_to_front()
	var t := pc.create_tween()
	t.tween_property(pc, "modulate:a", 1.0, P.MOTION_FAST)
	t.tween_interval(2.2)
	t.tween_property(pc, "modulate:a", 0.0, P.MOTION_BASE)
	t.tween_callback(pc.queue_free)


## Standard top bar with leading/trailing actions.
static func top_bar(title: String, leading: Button = null, trailing: Array = []) -> Control:
	var bar := HBoxContainer.new()
	bar.name = "TopBar"
	bar.custom_minimum_size = Vector2(0, P.TOP_BAR_H)
	bar.add_theme_constant_override("separation", int(P.SPACE_S))
	if leading != null:
		bar.add_child(leading)
	var t := label(title, "title")
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(t)
	bar.add_child(spacer())
	for b in trailing:
		bar.add_child(b)
	return bar


static func divider() -> Control:
	var r := ColorRect.new()
	r.color = c("surface_hairline")
	r.custom_minimum_size = Vector2(0, 1)
	return r
