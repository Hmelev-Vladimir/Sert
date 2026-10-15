## NEONLINE — Boot screen: splash -> main menu (Continue / New Life / Settings).
extends Control

const P := preload("res://scripts/runtime/palette.gd")
const UI := preload("res://scripts/runtime/ui_kit.gd")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	AudioManager.play_music("menu")


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = UI.c("bg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# decorative neon strips
	for i in range(3):
		var strip := ColorRect.new()
		strip.color = UI.c(["accent", "secondary", "tertiary"][i])
		strip.modulate.a = 0.12
		strip.custom_minimum_size = Vector2(0, 2)
		strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
		strip.offset_top = 60 + i * 14
		strip.offset_bottom = strip.offset_top + 2
		add_child(strip)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER_TOP)
	col.offset_left = -P.SPACE_XXL * 4
	col.offset_right = P.SPACE_XXL * 4
	col.offset_top = P.SPACE_XXL * 2
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", int(P.SPACE_L))
	add_child(col)

	var logo := UI.label("NEONLINE", "display", "accent")
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(logo)
	var sub := UI.label("Life in the Sprawl", "body", "text_secondary")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	col.add_child(UI.vgap(P.SPACE_XL))

	if SaveSystem.has_save("auto"):
		var meta := SaveSystem.slot_meta("auto")
		var cont := UI.button_filled("Continue — %s, age %s" % [meta.get("name", "?"), meta.get("age", 0)], _continue, "lg")
		cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(cont)

	var new_life := UI.button_tonal("Start a New Life", _new_life, "lg")
	new_life.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(new_life)

	var settings := UI.button_outlined("Settings", _settings)
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(settings)

	var ver := UI.label("v0.1.0 template · Neon Bay build", "caption", "text_disabled")
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(ver)


func _continue() -> void:
	SaveSystem.load_game("auto")
	_goto_game()


func _new_life() -> void:
	GameState.start_new_life()
	EventEngine.reset_for_new_life()
	Analytics.track("new_life")
	_goto_game()


func _settings() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _goto_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
