## NEONLINE — Autoload: DataService.
## Loads every JSON database once at boot and exposes typed getters.
## All gameplay content is data-driven: add events/jobs/items in res://data
## without touching code.
extends Node

const P := preload("res://scripts/runtime/palette.gd")

var world: Dictionary = {}
var stats: Array = []           # stat definitions [{id,name,color_key,default}]
var traits: Array = []          # [{id,name,desc,effects}]
var jobs: Array = []            # [{id,name,sector,min_age,salary,req_stats,...}]
var schools: Array = []         # [{id,name,tuition,years,reputation}]
var implants: Array = []        # [{id,name,cost,slot,effects,risk}]
var activities: Array = []      # [{id,name,cost,cooldown,effects,tag}]
var relationships: Array = []   # [{id,name,type,affinity}]
var events: Array = []          # event cards (see event_engine.gd doc)
var names_first: PackedStringArray = []
var names_last: PackedStringArray = []
var errors: PackedStringArray = []


func _ready() -> void:
	world = _json("res://data/world.json")
	stats = _json_array("res://data/stats.json")
	traits = _json_array("res://data/traits.json")
	jobs = _json_array("res://data/jobs.json")
	schools = _json_array("res://data/schools.json")
	implants = _json_array("res://data/implants.json")
	activities = _json_array("res://data/activities.json")
	relationships = _json_array("res://data/people.json")
	events = _json_array("res://data/events.json")
	names_first = PackedStringArray(world.get("names_first", ["Kai", "Nyx", "Rho", "Vex", "Juno", "Zed"]))
	names_last = PackedStringArray(world.get("names_last", ["Vandal", "Kestrel", "Marrow", "Synn", "Okonkwo", "Dray"]))
	if not errors.is_empty():
		push_warning("DataService loaded with issues: %s" % ", ".join(errors))


func _json(path: String) -> Dictionary:
	var raw := _read(path)
	if raw == "":
		return {}
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	errors.append(path)
	return {}


func _json_array(path: String) -> Array:
	var raw := _read(path)
	if raw == "":
		return []
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) == TYPE_ARRAY:
		return parsed
	errors.append(path)
	return []


func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		errors.append(path + " (missing)")
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		errors.append(path + " (unreadable)")
		return ""
	return f.get_as_text()


func job_by_id(id: String) -> Dictionary:
	for j in jobs:
		if j.get("id", "") == id:
			return j
	return {}


func implant_by_id(id: String) -> Dictionary:
	for it in implants:
		if it.get("id", "") == id:
			return it
	return {}


func activity_by_id(id: String) -> Dictionary:
	for a in activities:
		if a.get("id", "") == id:
			return a
	return {}


func random_name(rng: RandomNumberGenerator) -> String:
	return "%s %s" % [names_first[rng.randi_range(0, names_first.size() - 1)],
		names_last[rng.randi_range(0, names_last.size() - 1)]]
