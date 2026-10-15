## NEONLINE — Base screen shell.
## Every gameplay screen lives inside this scaffold: safe-area padding, top bar,
## scrollable content region and a 5-tab bottom navigation bar (standard mobile
## pattern: Home / Life / Actions / Assets / Settings). Emits `tab_selected`.
extends Control

signal tab_selected(tab: String)

const P := preload("res://scripts/runtime/palette.gd")
const UI := preload("res://scripts/runtime/ui_kit.gd")

const TABS := [
	{"id": "life", "icon": "◉", "label": "Life"},
	{"id": "actions", "icon": "⚡", "label": "Actions"},
	{"id": "assets", "icon": "▣", "label": "Assets"},
	{"id": "world", "icon": "✦", "label": "World"},
	{"id": "settings", "icon": "⚙", "label": "Settings"},
]

var content_area: MarginContainer
var top_bar_host: HBoxContainer
var _tab_buttons := {}
var _current_tab := "life"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	ThemeManager.theme_changed.connect(func(_i): _restyle())
	_select("life", false)


func _build() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var col := VBoxContainer.new()
	col.name = "Shell"
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 0)
	add_child(col)

	top_bar_host = HBoxContainer.new()
	top_bar_host.name = "TopBarHost"
	col.add_child(top_bar_host)

	content_area = MarginContainer.new()
	content_area.name = "ContentArea"
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.add_theme_constant_override("margin_left", int(P.SPACE_L))
	content_area.add_theme_constant_override("margin_right", int(P.SPACE_L))
	content_area.add_theme_constant_override("margin_top", int(P.SPACE_M))
	content_area.add_theme_constant_override("margin_bottom", int(P.SPACE_S))
	col.add_child(content_area)

	col.add_child(UI.divider())
	var navbar := _build_navbar()
	col.add_child(navbar)


func _build_navbar() -> Control:
	var bar := PanelContainer.new()
	bar.name = "BottomNav"
	var layout := HBoxContainer.new()
	layout.name = "Layout"
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 0)
	for t in TABS:
		var b := _tab_button(t)
		_tab_buttons[t["id"]] = b
		layout.add_child(b)
	bar.add_child(layout)
	return bar


func _tab_button(t: Dictionary) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, P.NAV_BAR_H)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := Label.new()
	icon.text = t["icon"]
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 20)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cap := Label.new()
	cap.text = t["label"]
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", int(P.FONT_SCALE["overline"]))
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)
	v.add_child(cap)
	b.add_child(v)
	b.pressed.connect(_select.bind(t["id"], true))
	b.set_meta("icon", icon)
	b.set_meta("cap", cap)
	return b


func set_title(text: String) -> void:
	for ch in top_bar_host.get_children():
		ch.queue_free()
	top_bar_host.add_child(UI.top_bar(text))
	_restyle()


func add_header_action(b: Button) -> void:
	top_bar_host.add_child(b)


func _select(id: String, notify: bool) -> void:
	_current_tab = id
	for key in _tab_buttons:
		_style_tab(_tab_buttons[key], key == id)
	if notify:
		AudioManager.play_sfx("tap")
		tab_selected.emit(id)


func _style_tab(b: Button, active: bool) -> void:
	var icon: Label = b.get_meta("icon")
	var cap: Label = b.get_meta("cap")
	var col := UI.c("accent") if active else UI.c("text_disabled")
	icon.add_theme_color_override("font_color", col)
	cap.add_theme_color_override("font_color", col)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UI.c("accent_dim") if active else Color.TRANSPARENT
	sb.set_corner_radius_all(int(P.RADIUS_M))
	sb.content_margin_left = P.SPACE_XS
	sb.content_margin_right = P.SPACE_XS
	sb.content_margin_top = P.SPACE_S
	sb.content_margin_bottom = P.SPACE_S
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)


func _restyle() -> void:
	get_node("Background").color = UI.c("bg")
	for key in _tab_buttons:
		_style_tab(_tab_buttons[key], key == _current_tab)
	# screens rebuild their own content on theme change
	tab_selected.emit(_current_tab)
