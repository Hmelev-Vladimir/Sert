## NEONLINE — Autoload: SaveSystem.
## JSON saves in user:// with versioning + atomic write (tmp -> rename).
## Slots: "auto" plus 3 manual slots. Stores meta for the load screen.
extends Node

const SLOT_COUNT := 4
const VERSION := 1


func _ready() -> void:
	# Autosave on suspend so mobile backgrounding never loses progress.
	get_tree().set_auto_accept_quit(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if GameState.alive or GameState.age > 0:
			save_game("auto")
		if what == NOTIFICATION_WM_CLOSE_REQUEST:
			get_tree().quit()


func slot_path(slot: String) -> String:
	return "user://save_%s.json" % slot


func save_game(slot: String = "auto") -> bool:
	var data := _serialize()
	var tmp := slot_path(slot) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: cannot open %s (%s)" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot)))
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(slot_path(slot))) == OK


func load_game(slot: String) -> bool:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	if int(parsed.get("version", 0)) > VERSION:
		push_warning("Save from newer version — attempting best-effort load")
	_deserialize(parsed)
	return true


func has_save(slot: String) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func slot_meta(slot: String) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return {}
	return d.get("meta", {})


func delete_slot(slot: String) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot)))


func _serialize() -> Dictionary:
	var gs := GameState
	return {
		"version": VERSION,
		"meta": {
			"name": gs.character_name, "age": gs.age, "job": gs.job_title,
			"credits": gs.credits, "alive": gs.alive,
			"saved_at": Time.get_unix_time_from_system(),
		},
		"state": {
			"character_name": gs.character_name, "district": gs.district, "sex": gs.sex,
			"age": gs.age, "alive": gs.alive, "cause_of_death": gs.cause_of_death,
			"stats": gs.stats, "credits": gs.credits, "karma": gs.karma,
			"happiness": gs.happiness, "education_level": gs.education_level,
			"enrolled_in": gs.enrolled_in, "job_id": gs.job_id, "job_title": gs.job_title,
			"job_level": gs.job_level, "job_performance": gs.job_performance,
			"retired": gs.retired, "traits": gs.traits, "implants": gs.implants,
			"cooldowns": gs.cooldowns, "history": gs.history, "people": gs.people,
			"rng_state": gs.rng.state,
		},
	}


func _deserialize(root: Dictionary) -> void:
	var s: Dictionary = root.get("state", {})
	var gs := GameState
	gs.character_name = s.get("character_name", "")
	gs.district = s.get("district", "")
	gs.sex = s.get("sex", "F")
	gs.age = int(s.get("age", 0))
	gs.alive = bool(s.get("alive", true))
	gs.cause_of_death = s.get("cause_of_death", "")
	gs.stats = _num_dict(s.get("stats", {}))
	gs.credits = int(s.get("credits", 0))
	gs.karma = int(s.get("karma", 0))
	gs.happiness = float(s.get("happiness", 50.0))
	gs.education_level = int(s.get("education_level", 0))
	gs.enrolled_in = s.get("enrolled_in", "")
	gs.job_id = s.get("job_id", "")
	gs.job_title = s.get("job_title", "Unemployed")
	gs.job_level = int(s.get("job_level", 1))
	gs.job_performance = float(s.get("job_performance", 50.0))
	gs.retired = bool(s.get("retired", false))
	gs.traits = s.get("traits", [])
	gs.implants = s.get("implants", [])
	gs.cooldowns = _int_dict(s.get("cooldowns", {}))
	gs.history = s.get("history", [])
	gs.people = s.get("people", [])
	gs.rng.state = int(s.get("rng_state", 0))
	SignalBus.year_advanced.emit(gs.age)
	SignalBus.credits_changed.emit(0, gs.credits)


func _num_dict(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[k] = float(d[k])
	return out


func _int_dict(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[k] = int(d[k])
	return out
