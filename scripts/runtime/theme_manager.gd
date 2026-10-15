## NEONLINE — Autoload: ThemeManager.
## Owns the active design theme and pushes live restyles to every registered
## screen via the `theme_changed` signal. Also exposes safe-area insets so all
## screens respect notches / gesture bars on real devices.
extends Node

signal theme_changed(theme_id: int)

const P := preload("res://scripts/runtime/palette.gd")
const PREFS_PATH := "user://prefs.cfg"

var current_id: int = P.ThemeId.MIDNIGHT
var _colors: Dictionary = {}
var _prefs := ConfigFile.new()


func _ready() -> void:
	var err := _prefs.load(PREFS_PATH)
	if err == OK and _prefs.has_section_key("ui", "theme_id"):
		current_id = _prefs.get_value("ui", "theme_id", current_id)
	_apply(_resolve())


func _resolve() -> Dictionary:
	return P.colors(current_id)


func color(key: String) -> Color:
	return _colors.get(key, Color.MAGENTA)


func is_dark() -> bool:
	return current_id == P.ThemeId.MIDNIGHT


func set_theme(id: int) -> void:
	if not P.THEMES.has(id):
		return
	current_id = id
	_prefs.set_value("ui", "theme_id", id)
	_prefs.save(PREFS_PATH)
	_apply(_resolve())
	theme_changed.emit(id)


func toggle_theme() -> void:
	set_theme(P.ThemeId.DAYLIGHT if is_dark() else P.ThemeId.MIDNIGHT)


func _apply(map: Dictionary) -> void:
	_colors = map.duplicate()


## Safe area in pixels (top notch + bottom gesture bar).
func safe_margins() -> Dictionary:
	var win := get_window()
	if win == null:
		return {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	var sa := win.get_safe_area()
	var ms := win.get_visible_rect().size
	return {
		"top": sa.position.y,
		"left": sa.position.x,
		"bottom": maxf(0.0, ms.y - sa.end.y),
		"right": maxf(0.0, ms.x - sa.end.x),
	}
